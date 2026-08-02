CoARU_TrainerSkip = false

local DESC_FS = {
    ClassTrainerSkillDescription = true,
    ClassTrainerSkillRequirements = true,
    ClassTrainerDetailScrollChildTextlineText = true,
}

local NAME_FS = { ClassTrainerSkillName = true, ClassTrainerSubSkillName = true }
local function isNameFS(nm)
    if not nm then return false end
    return NAME_FS[nm] or nm:match("^ClassTrainerSkill%d+Text$") ~= nil
end

local function fsApply(fs)
    if CoARU_TrainerSkip then return end
    if not CoARU_ModOn("trainer") then return end
    local t = fs and fs.GetText and fs:GetText()
    if not t or #t < 2 then return end

    if isNameFS(fs.GetName and fs:GetName()) then
        if CoARU_ModOn("spellnames") and CoARU_SPELL_NAME_RU then
            local nm = CoARU_StripCodes(t):gsub("^%s+", ""):gsub("%s+$", "")
            if CoARU_IsSpecName and CoARU_IsSpecName(nm) then return end
            local ru = nm ~= "" and CoARU_SPELL_NAME_RU[nm]

            if ru and ru ~= nm then
                local s, e = t:find(nm, 1, true)
                if s then fs:SetText(t:sub(1, s - 1) .. ru .. t:sub(e + 1)) end
            end
        end
        return
    end

    if CoARU_NoteBlockMisses then
        local nm = fs.GetName and fs:GetName()
        if nm and DESC_FS[nm] then CoARU_NoteBlockMisses("trainer", nil, t) end
    end
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

local function grabTipLines(tip)
    local nm = tip:GetName()
    local out = {}
    for k = 1, tip:NumLines() do
        for _, side in ipairs({ "TextLeft", "TextRight" }) do
            local fs = _G[nm .. side .. k]
            local t = fs and fs.GetText and fs:GetText()
            if t and t:find("%S") then
                local cr, cg, cb
                if fs.GetTextColor then
                    local ok, a, b, c = pcall(fs.GetTextColor, fs)
                    if ok then cr, cg, cb = a, b, c end
                end
                out[#out + 1] = string.format("%s%d [%s] = [[%s]]", side, k,
                    cr and string.format("%.2f/%.2f/%.2f", cr, cg or 0, cb or 0) or "?",
                    (t:gsub("|", "/")))
            end
        end
    end
    return out
end

function CoARU_ScanTrainer()
    if not (ClassTrainerFrame and ClassTrainerFrame:IsShown()) then
        return nil, "окно тренера закрыто"
    end
    local n = (GetNumTrainerServices and GetNumTrainerServices()) or 0
    if n == 0 then return nil, "услуг у тренера нет (0)" end
    local raw, misses, spells = {}, 0, 0
    local tip = GameTooltip
    for i = 1, n do
        local sname, _, stype = GetTrainerServiceInfo(i)
        if stype ~= "header" then
            spells = spells + 1

            CoARU_ScanRaw = true
            tip:SetOwner(UIParent, "ANCHOR_NONE"); tip:ClearLines(); tip:SetTrainerService(i); tip:Show()
            local en = grabTipLines(tip)
            tip:Hide()

            local savedOrig = CoARU_OriginalMode
            CoARU_OriginalMode = false
            CoARU_ScanRaw = false
            tip:SetOwner(UIParent, "ANCHOR_NONE"); tip:ClearLines(); tip:SetTrainerService(i); tip:Show()
            local ru = grabTipLines(tip)
            CoARU_OriginalMode = savedOrig
            tip:Hide()
            raw[#raw + 1] = { name = sname, en = en, ru = ru }
        end
    end
    CoARU_ScanRaw = false

    CoARU_ScanRaw = true
    for i = 1, n do
        local _, _, stype = GetTrainerServiceInfo(i)
        if stype ~= "header" then
            tip:SetOwner(UIParent, "ANCHOR_NONE"); tip:ClearLines(); tip:SetTrainerService(i); tip:Show()
            local nm = tip:GetName()
            for k = 2, tip:NumLines() do
                for _, side in ipairs({ "TextLeft", "TextRight" }) do
                    local fs = _G[nm .. side .. k]
                    local t = fs and fs.GetText and fs:GetText()
                    if t and t:find("%S") and CoARU_NoteBlockMisses then
                        local pre = 0
                        if CoARU_DB and CoARU_DB.miss then for _ in pairs(CoARU_DB.miss) do pre = pre + 1 end end
                        CoARU_NoteBlockMisses("trainer", nil, t)
                        if CoARU_DB and CoARU_DB.miss then
                            local post = 0
                            for _ in pairs(CoARU_DB.miss) do post = post + 1 end
                            misses = misses + (post - pre)
                        end
                    end
                end
            end
            tip:Hide()
        end
    end
    CoARU_ScanRaw = false
    if CoARU_DB then CoARU_DB.trainerscan = raw end
    return spells, misses
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
