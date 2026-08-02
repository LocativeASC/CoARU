local BROWSE, BID, OWNED = 8, 9, 9

local function itemIdFromLink(link)
    if not link then return nil end
    local id = link:match("item:(%d+)")
    return id and tonumber(id) or nil
end

function CoARU_AuctionNameRU(listType, index)
    if not CoARU_ItemName or not GetAuctionItemLink then return nil end
    local id = itemIdFromLink(GetAuctionItemLink(listType, index))
    if not id then return nil end
    local ru = CoARU_ItemName[id]
    if not ru or ru == "" then return nil end
    return ru
end

local function retext(prefix, listType, scroll, count)
    if CoARU_ModOn and not CoARU_ModOn("itemnames") then return end
    local offset = 0
    if scroll and FauxScrollFrame_GetOffset then
        offset = FauxScrollFrame_GetOffset(scroll) or 0
    end
    for i = 1, count do
        local fs = _G[prefix .. i .. "Name"]
        if fs and fs.GetText then
            local cur = fs:GetText()
            if cur and cur ~= "" then

                local ru = CoARU_AuctionNameRU(listType, offset + i)
                if ru and ru ~= cur then
                    if CoARU_SetTranslated then
                        CoARU_SetTranslated(fs, cur, ru)
                    else
                        fs:SetText(ru)
                    end
                elseif not ru and CoARU_NoteMiss and not (CoARU_HasCyrillic and CoARU_HasCyrillic(cur)) then

                    CoARU_NoteMiss("itemname", cur, "AuctionFrame")
                end
            end
        end
    end
end

local function updateBrowse() retext("BrowseButton", "list", _G["BrowseScrollFrame"], BROWSE) end
local function updateBid()    retext("BidButton", "bidder", _G["BidScrollFrame"], BID) end
local function updateOwned()  retext("AuctionsButton", "owner", _G["AuctionsScrollFrame"], OWNED) end

CoARU_AuctionUpdateBrowse = updateBrowse
CoARU_AuctionUpdateBid = updateBid
CoARU_AuctionUpdateOwned = updateOwned

local revMap, revBuilt = nil, false

local function buildRev()
    revBuilt = true
    if not CoARU_ItemNameEN then return end
    revMap = {}
    for en, ru in pairs(CoARU_ItemNameEN) do
        if type(ru) == "string" and ru ~= "" then
            if revMap[ru] == nil then
                revMap[ru] = en
            elseif revMap[ru] ~= en then
                revMap[ru] = false
            end
        end
    end
end

function CoARU_AuctionSearchEN(text)
    if not text or text == "" then return nil end
    if not (CoARU_HasCyrillic and CoARU_HasCyrillic(text)) then return nil end
    if not revBuilt then buildRev() end
    if not revMap then return nil end
    local exact = revMap[text]
    if exact then return exact, true end
    if exact == false then return nil end

    local hit, n = nil, 0
    local pat = "^" .. text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    for ru, en in pairs(revMap) do
        if en and ru:find(pat) then
            if hit and hit ~= en then return nil end
            hit = en
            n = n + 1
        end
    end
    if hit then return hit, false end
    return nil
end

function CoARU_AuctionFixSearchBox()
    local box = _G["BrowseName"]
    if not box or not box.GetText then return nil end
    local t = box:GetText()
    local en = CoARU_AuctionSearchEN(t)
    if not en or en == t then return nil end
    box:SetText(en)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffC495DDCoARU|r поиск по-русски: «" .. t
            .. "» ищем как «" .. en .. "»")
    end
    return en
end

local function wrapPre(frame, script)
    if not frame or not frame.GetScript then return end
    local key = "__coaru_" .. script
    if frame[key] then return end
    frame[key] = true
    local old = frame:GetScript(script)
    frame:SetScript(script, function(...)
        pcall(CoARU_AuctionFixSearchBox)
        if old then return old(...) end
    end)
end

local function hookSearch()
    wrapPre(_G["BrowseSearchButton"], "OnClick")
    wrapPre(_G["BrowseName"], "OnEnterPressed")
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
f:RegisterEvent("AUCTION_BIDDER_LIST_UPDATE")
f:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= "Blizzard_AuctionUI" then return end
        if type(AuctionFrameBrowse_Update) == "function" then
            hooksecurefunc("AuctionFrameBrowse_Update", updateBrowse)
        end
        if type(AuctionFrameBid_Update) == "function" then
            hooksecurefunc("AuctionFrameBid_Update", updateBid)
        end
        if type(AuctionFrameAuctions_Update) == "function" then
            hooksecurefunc("AuctionFrameAuctions_Update", updateOwned)
        end
        hookSearch()
        return
    end
    if event == "AUCTION_ITEM_LIST_UPDATE" then updateBrowse()
    elseif event == "AUCTION_BIDDER_LIST_UPDATE" then updateBid()
    else updateOwned() end
end)
