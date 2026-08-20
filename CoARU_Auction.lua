local BROWSE, BID, OWNED = 8, 9, 9

local function itemIdFromLink(link)
    if not link then return nil end
    local id = link:match("item:(%d+)")
    return id and tonumber(id) or nil
end

function CoARU_AuctionNameRU(listType, index, en)
    if not GetAuctionItemLink then return nil end
    local id = itemIdFromLink(GetAuctionItemLink(listType, index))
    if not id then return nil end
    if GetAuctionItemInfo then
        local ok, name = pcall(GetAuctionItemInfo, listType, index)
        if ok and type(name) == "string" and name ~= "" then en = name end
    end
    local ru = CoARU_ItemNameRowRU and CoARU_ItemNameRowRU(id, en)
        or (CoARU_ItemName and CoARU_ItemName[id])
    if not ru or ru == "" then return nil end
    return ru
end

local prof = { calls = 0, ms = 0, max = 0, rows = 0, miss = 0, fast = 0,
               byList = {}, stacks = {}, stackN = 0,
               frames = 0, inFrame = 0, maxInFrame = 0, frameAt = nil,
               events = 0, coalesced = 0 }

local function retextBody(prefix, listType, scroll, count)
    if CoARU_ModOn and not CoARU_ModOn("itemnames") then return end
    local offset = 0
    if scroll and FauxScrollFrame_GetOffset then
        offset = FauxScrollFrame_GetOffset(scroll) or 0
    end
    for i = 1, count do
        local fs = _G[prefix .. i .. "Name"]
        if fs and fs.GetText then
            local cur = fs:GetText()

            local seenEn, seenRu = fs.coaruAucEn, fs.coaruAucRu
            if cur and cur ~= "" and seenEn == cur then
                prof.fast = prof.fast + 1

                if seenRu then fs:SetText(CoARU_OriginalMode and cur or seenRu) end
            elseif cur and cur ~= "" and cur == seenRu then

                prof.fast = prof.fast + 1
            elseif cur and cur ~= "" then
                prof.rows = prof.rows + 1

                local ru = CoARU_AuctionNameRU(listType, offset + i, cur)
                if ru and ru ~= cur then
                    if CoARU_SetTranslated then
                        CoARU_SetTranslated(fs, cur, ru)
                    else
                        fs:SetText(ru)
                    end
                elseif not ru and CoARU_NoteMiss and not (CoARU_HasCyrillic and CoARU_HasCyrillic(cur)) then

                    prof.miss = prof.miss + 1
                    CoARU_NoteMiss("itemname", cur, "AuctionFrame")
                end

                fs.coaruAucEn = cur
                fs.coaruAucRu = (ru and ru ~= cur) and ru or false
            end
        end
    end
end

local STACK_EVERY, STACK_KEEP = 500, 20

local function retext(prefix, listType, scroll, count)
    local dps = debugprofilestop
    if not dps then return retextBody(prefix, listType, scroll, count) end
    local t0 = dps()
    retextBody(prefix, listType, scroll, count)
    local dt = dps() - t0
    if dt < 0 then return end
    prof.calls = prof.calls + 1
    prof.ms = prof.ms + dt
    if dt > prof.max then prof.max = dt end

    prof.byList[listType] = (prof.byList[listType] or 0) + 1

    if GetTime then
        local now = GetTime()
        if now ~= prof.frameAt then
            prof.frameAt = now
            prof.frames = prof.frames + 1
            prof.inFrame = 0
        end
        prof.inFrame = prof.inFrame + 1
        if prof.inFrame > prof.maxInFrame then prof.maxInFrame = prof.inFrame end
    end
    if debugstack and prof.stackN < STACK_KEEP
       and prof.calls % STACK_EVERY == 0 then
        prof.stackN = prof.stackN + 1
        prof.stacks[prof.stackN] = listType .. " @" .. prof.calls .. "\n"
            .. (debugstack(3, 4, 0) or "?")
    end
end

function CoARU_AucProf() return prof.calls, prof.ms, prof.max, prof.rows, prof.miss, prof.fast end
function CoARU_AucProfByList() return prof.byList end
function CoARU_AucProfFrames() return prof.frames, prof.maxInFrame end
function CoARU_AucProfStacks() return prof.stacks, prof.stackN end
function CoARU_AucProfReset()
    prof.calls, prof.ms, prof.max, prof.rows, prof.miss, prof.fast = 0, 0, 0, 0, 0, 0
    prof.byList = {}
    prof.stacks, prof.stackN = {}, 0
    prof.frames, prof.inFrame, prof.maxInFrame, prof.frameAt = 0, 0, 0, nil
    prof.events, prof.coalesced = 0, 0
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

local gate = CreateFrame("Frame")
local pending, pendingFor = nil, 0

local function canQuery()

    if type(CanSendAuctionQuery) ~= "function" then return true end
    local ok, can = pcall(CanSendAuctionQuery, "list")
    if not ok then return true end
    return can and true or false
end

gate:Hide()
gate:SetScript("OnUpdate", function(self, elapsed)
    if not pending then self:Hide(); return end
    pendingFor = pendingFor + (elapsed or 0)
    if pendingFor > 5 then pending = nil; self:Hide(); return end
    if canQuery() then
        local run = pending
        pending = nil
        self:Hide()
        pcall(run)
    end
end)

function CoARU_AucGatePending() return pending ~= nil end
function CoARU_AucGateTick(dt)
    local fn = gate:GetScript("OnUpdate")
    if fn then fn(gate, dt or 0) end
end

local function wrapGate(frame, script)
    if not frame or not frame.GetScript or not frame.SetScript then return end
    local key = "__coaru_gate_" .. script
    if frame[key] then return end
    local old = frame:GetScript(script)
    if not old then return end
    frame[key] = true
    frame:SetScript(script, function(a1, a2, a3, a4)
        if not CoARU_ModOn("aucfix") then return old(a1, a2, a3, a4) end
        if canQuery() then return old(a1, a2, a3, a4) end
        pending = function() old(a1, a2, a3, a4) end
        pendingFor = 0
        gate:Show()
    end)
end

local function hookGate()
    wrapGate(_G["BrowseSearchButton"], "OnClick")
    wrapGate(_G["BrowseName"], "OnEnterPressed")
    wrapGate(_G["BrowsePrevPageButton"], "OnClick")
    wrapGate(_G["BrowseNextPageButton"], "OnClick")
end
CoARU_AucHookGate = hookGate

local COALESCE = {
    AUCTION_ITEM_LIST_UPDATE = true,
    AUCTION_BIDDER_LIST_UPDATE = true,
    AUCTION_OWNED_LIST_UPDATE = true,
}

local dirty = {}
local pump = CreateFrame("Frame")
pump:Hide()
pump:SetScript("OnUpdate", function(self)
    self:Hide()
    for f, ev in pairs(dirty) do
        dirty[f] = nil
        local orig = f.coaruOrigOnEvent
        if orig then pcall(orig, f, ev) end
    end
end)

function CoARU_AucEventCount() return prof.events, prof.coalesced end
function CoARU_AucPumpTick()
    local fn = pump:GetScript("OnUpdate")
    if fn then fn(pump) end
end

local function wrapEvents(frame)
    if not frame or not frame.GetScript or not frame.SetScript then return end
    if frame.coaruOrigOnEvent then return end
    local orig = frame:GetScript("OnEvent")
    if not orig then return end
    frame.coaruOrigOnEvent = orig
    frame:SetScript("OnEvent", function(self, event, a1, a2, a3, a4)
        prof.events = prof.events + 1
        if COALESCE[event] and CoARU_ModOn("aucfix") then

            if dirty[self] == nil then dirty[self] = event else prof.coalesced = prof.coalesced + 1 end
            pump:Show()
            return
        end
        return orig(self, event, a1, a2, a3, a4)
    end)
end

local function hookEvents()
    wrapEvents(_G["AuctionFrameBrowse"])
    wrapEvents(_G["AuctionFrameBid"])
    wrapEvents(_G["AuctionFrameAuctions"])
end
CoARU_AucHookEvents = hookEvents

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, arg1)
    if event ~= "ADDON_LOADED" or arg1 ~= "Blizzard_AuctionUI" then return end
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
    hookGate()
    hookEvents()
end)
