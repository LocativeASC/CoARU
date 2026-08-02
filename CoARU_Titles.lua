local function titlesOn()
    return not CoARU_ModOn or CoARU_ModOn("titles")
end

function CoARU_TitleRU(full)
    if not full or full == "" or not titlesOn() then return nil end
    if CoARU_HasCyrillic and CoARU_HasCyrillic(full) then return nil end

    if CoARU_TITLE_PRE then
        for en, ru in pairs(CoARU_TITLE_PRE) do
            if full:sub(1, #en) == en then
                return ru .. full:sub(#en + 1)
            end
        end
    end
    if CoARU_TITLE_POST then
        for en, ru in pairs(CoARU_TITLE_POST) do
            if #full > #en and full:sub(-#en) == en then
                return full:sub(1, #full - #en) .. ru
            end
        end
    end
    return nil
end

if type(UnitPVPName) == "function" then
    local orig = UnitPVPName
    function UnitPVPName(unit)
        local n = orig(unit)
        local ru = n and CoARU_TitleRU(n)
        return ru or n
    end
end

if type(GetTitleName) == "function" then
    local orig = GetTitleName
    function GetTitleName(i)
        local n, on = orig(i)
        local ru = n and CoARU_TitleRU(n)
        return ru or n, on
    end
end

local function tooltipTitle(tip)
    if not titlesOn() then return end
    if not tip or not tip.GetUnit then return end
    local ok, unit = pcall(tip.GetUnit, tip)
    if not ok or not unit then return end
    local fs = _G["GameTooltipTextLeft1"]
    local t = fs and fs.GetText and fs:GetText()
    local ru = t and CoARU_TitleRU(t)
    if ru and ru ~= t then fs:SetText(ru) end
end

if GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetUnit", tooltipTitle)
end

function CoARU_TitleStatus()
    local n = 0
    for _ in pairs(CoARU_TITLE_PRE or {}) do n = n + 1 end
    for _ in pairs(CoARU_TITLE_POST or {}) do n = n + 1 end
    return n
end
