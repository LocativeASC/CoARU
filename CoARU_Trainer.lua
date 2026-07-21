CoARU_TrainerSkip = false

local function fsApply(fs)
    if CoARU_TrainerSkip then return end
    local t = fs and fs.GetText and fs:GetText()
    if not t or #t < 2 then return end
    local ru = CoARU_TranslateBlock(nil, t)
    if ru and ru ~= t then
        fs:SetText(ru)
    end
end

local function scanFrame(fr, depth)
    if not fr or depth > 8 then return end
    if fr.GetRegions then
        for i = 1, select("#", fr:GetRegions()) do
            local r = select(i, fr:GetRegions())
            if r and r.GetObjectType and r:GetObjectType() == "FontString" then
                fsApply(r)
            end
        end
    end
    if fr.GetChildren then
        for i = 1, select("#", fr:GetChildren()) do
            scanFrame(select(i, fr:GetChildren()), depth + 1)
        end
    end
end

local MONEY_FRAMES = { "ClassTrainerMoneyFrame", "ClassTrainerDetailMoneyFrame" }
local COIN = { "Gold", "Silver", "Copper" }
local function fixMoneyTokens()
    for _, mf in ipairs(MONEY_FRAMES) do
        for _, coin in ipairs(COIN) do
            local fs = _G[mf .. coin .. "ButtonText"]
            local t = fs and fs.GetText and fs:GetText()
            if t then
                local num = t:match("^@%a+:(%d+)$")
                if num then
                    fs:SetText(num)

                    if fs.SetTextColor then fs:SetTextColor(1, 1, 1) end
                end
            end
        end
    end
end

local function translateTrainer()
    if ClassTrainerFrame and ClassTrainerFrame:IsShown() then
        scanFrame(ClassTrainerFrame, 0)
        fixMoneyTokens()
    end
end

local function translateDropDowns()
    if not (ClassTrainerFrame and ClassTrainerFrame:IsShown()) then return end
    for i = 1, 2 do
        local list = _G["DropDownList" .. i]
        if list and list:IsShown() then scanFrame(list, 0) end
    end
end

function CoARU_DumpTrainer()
    local res = {}
    local function grab(r, depth)
        if not (r and r.GetObjectType and r:GetObjectType() == "FontString") then return end
        local t = r.GetText and r:GetText()

        local raw = t and t:gsub("|", "/") or "<nil>"
        local cr, cg, cb
        if r.GetTextColor then
            local ok, a, b, c = pcall(r.GetTextColor, r)
            if ok then cr, cg, cb = a, b, c end
        end
        res[#res + 1] = {
            name  = (r.GetName and r:GetName()) or "<безымянный>",
            raw   = raw,
            color = cr and string.format("%.2f/%.2f/%.2f", cr, cg or 0, cb or 0) or "?",
            embedded = t and t:find("|c") ~= nil or false,
            shown = r.IsShown and r:IsShown() or false,
            depth = depth,
        }
    end
    local function walk(fr, depth)
        if not fr or depth > 12 then return end
        if fr.GetRegions then
            local ok, cnt = pcall(function() return select("#", fr:GetRegions()) end)
            if ok then for i = 1, cnt do grab(select(i, fr:GetRegions()), depth) end end
        end
        if fr.GetChildren then
            local ok, cnt = pcall(function() return select("#", fr:GetChildren()) end)
            if ok then for i = 1, cnt do walk(select(i, fr:GetChildren()), depth + 1) end end
        end
    end
    walk(ClassTrainerFrame, 0)

    for _, nm in ipairs({
        "ClassTrainerSkillName", "ClassTrainerSkillDescription", "ClassTrainerSkillRequirements",
        "ClassTrainerSkillCost", "ClassTrainerSkillPointCost", "ClassTrainerSkillProfession",
        "ClassTrainerDetailScrollChildTextlineText", "ClassTrainerDetailScrollFrame",
    }) do
        if _G[nm] then grab(_G[nm], -1) end
    end
    return res
end

local waiter = CreateFrame("Frame")
waiter:Hide()
waiter:SetScript("OnUpdate", function(self)
    self:Hide()
    translateTrainer()
    translateDropDowns()
end)

for i = 1, 2 do
    local list = _G["DropDownList" .. i]
    if list and list.HookScript then
        list:HookScript("OnShow", function() waiter:Show() end)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("TRAINER_SHOW")
f:RegisterEvent("TRAINER_UPDATE")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_TrainerUI" then
            if type(ClassTrainer_SetSelection) == "function" then
                hooksecurefunc("ClassTrainer_SetSelection", function() waiter:Show() end)
            end
            if type(ClassTrainerFrame_Update) == "function" then
                hooksecurefunc("ClassTrainerFrame_Update", function() waiter:Show() end)
            end
        end
    else
        waiter:Show()
    end
end)
