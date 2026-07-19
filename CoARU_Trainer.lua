local function fsApply(fs)
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

local function translateTrainer()
    if ClassTrainerFrame and ClassTrainerFrame:IsShown() then
        scanFrame(ClassTrainerFrame, 0)
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
    local function walk(fr, depth)
        if not fr or depth > 8 then return end
        if fr.GetRegions then
            for i = 1, select("#", fr:GetRegions()) do
                local r = select(i, fr:GetRegions())
                if r and r.GetObjectType and r:GetObjectType() == "FontString" then
                    local t = r.GetText and r:GetText()
                    local point, _, _, x, y = nil, nil, nil, nil, nil
                    if r.GetPoint then point, _, _, x, y = r:GetPoint(1) end
                    res[#res + 1] = {
                        name  = (r.GetName and r:GetName()) or "<безымянный>",
                        text  = t and t:sub(1, 60) or "<nil>",

                        empty = (not t) or (not t:find("%S")),
                        h     = r.GetHeight and r:GetHeight() or 0,
                        sh    = r.GetStringHeight and r:GetStringHeight() or 0,
                        shown = r.IsShown and r:IsShown() or false,
                        lines = r.GetNumLines and r:GetNumLines() or 0,
                        point = point, x = x, y = y,
                    }
                end
            end
        end
        if fr.GetChildren then
            for i = 1, select("#", fr:GetChildren()) do
                walk(select(i, fr:GetChildren()), depth + 1)
            end
        end
    end
    walk(ClassTrainerFrame, 0)
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
