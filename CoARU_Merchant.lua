local ITEMS_PER_PAGE = 10

local function itemIdFromLink(link)
    if not link then return nil end
    local id = link:match("item:(%d+)")
    return id and tonumber(id) or nil
end

function CoARU_MerchantNameRU(index)
    if not CoARU_ItemName then return nil end
    if not GetMerchantItemLink then return nil end
    local id = itemIdFromLink(GetMerchantItemLink(index))
    if not id then return nil end
    local ru = CoARU_ItemName[id]
    if not ru or ru == "" then return nil end
    return ru
end

local function noteName(en)
    if not en or en == "" or not CoARU_NoteMiss then return end
    if CoARU_HasCyrillic and CoARU_HasCyrillic(en) then return end
    CoARU_NoteMiss("itemname", en, "MerchantFrame")
end

local function updateNames()
    if CoARU_ModOn and not CoARU_ModOn("itemnames") then return end
    local page = (MerchantFrame and MerchantFrame.page) or 1
    for i = 1, ITEMS_PER_PAGE do
        local fs = _G["MerchantItem" .. i .. "Name"]

        if fs and fs.GetText and fs:GetText() and fs:GetText() ~= "" then
            local index = (page - 1) * ITEMS_PER_PAGE + i
            local ru = CoARU_MerchantNameRU(index)
            if ru and ru ~= fs:GetText() then
                if CoARU_SetTranslated then

                    CoARU_SetTranslated(fs, fs:GetText(), ru)
                else
                    fs:SetText(ru)
                end
            elseif not ru then

                noteName(fs:GetText())
            end
        end
    end

    local bb = _G["MerchantBuyBackItemName"]
    if bb and bb.GetText and bb:GetText() and bb:GetText() ~= "" and GetBuybackItemLink then
        local id = itemIdFromLink(GetBuybackItemLink(GetNumBuybackItems and GetNumBuybackItems() or 1))
        local ru = id and CoARU_ItemName and CoARU_ItemName[id]
        if ru and ru ~= "" and ru ~= bb:GetText() then
            if CoARU_SetTranslated then
                CoARU_SetTranslated(bb, bb:GetText(), ru)
            else
                bb:SetText(ru)
            end
        end
    end
end

CoARU_MerchantUpdate = updateNames

if type(MerchantFrame_UpdateMerchantInfo) == "function" then
    hooksecurefunc("MerchantFrame_UpdateMerchantInfo", updateNames)
end

if type(MerchantFrame_Update) == "function" then
    hooksecurefunc("MerchantFrame_Update", updateNames)
end

local f = CreateFrame("Frame")
f:RegisterEvent("MERCHANT_SHOW")
f:RegisterEvent("MERCHANT_UPDATE")
f:SetScript("OnEvent", function() updateNames() end)
