local function nameRU(n)
    if type(n) ~= "string" or n == "" then return nil end
    if CoARU_ModOn and not CoARU_ModOn("spellnames") then return nil end
    if CoARU_HasCyrillic and CoARU_HasCyrillic(n) then return nil end
    local ru = CoARU_SPELL_NAME_RU and CoARU_SPELL_NAME_RU[n]
    if ru and ru ~= n then return ru end
    return nil
end

CoARU_CastNameRU = nameRU

local function barText(bar)
    if type(bar) ~= "table" then return nil end
    local n = bar.GetName and bar:GetName()
    local fs = (n and _G[n .. "Text"]) or bar.Text or bar.text
    if type(fs) == "table" and fs.GetText and fs.SetText then return fs end
    return nil
end

CoARU_CastBarFix = function(bar)
    local fs = barText(bar)
    if not fs then return end
    local ru = nameRU(fs:GetText())
    if ru then fs:SetText(ru) end
end

if type(CastingBarFrame_OnEvent) == "function" then
    hooksecurefunc("CastingBarFrame_OnEvent", function(bar)

        pcall(CoARU_CastBarFix, bar)
    end)
end

do
    local FOREIGN = {

        DragonUI = function()
            local m = DragonUI and DragonUI.CastbarModule
            local frames = m and m.frames
            if type(frames) ~= "table" then return nil end
            local out = {}
            for _, set in pairs(frames) do
                if type(set) == "table" then
                    out[#out + 1] = set.castText
                    out[#out + 1] = set.castTextCentered
                end
            end
            return out
        end,
    }

    local hooked = setmetatable({}, { __mode = "k" })
    local inHook = false

    local function hookOne(fs)
        if type(fs) ~= "table" or hooked[fs] or not fs.SetText or not fs.GetText then return end
        hooked[fs] = true
        local ok = pcall(hooksecurefunc, fs, "SetText", function(self, txt)
            if inHook then return end
            local ru = nameRU(txt)
            if not ru then return end
            inHook = true
            pcall(self.SetText, self, ru)
            inHook = false
        end)
        if not ok then hooked[fs] = nil end
    end

    local acc = 0
    local waiter = CreateFrame("Frame")
    waiter:SetScript("OnUpdate", function(self, elapsed)
        acc = acc + (elapsed or 0)
        if acc < 2 then return end
        acc = 0
        for _, get in pairs(FOREIGN) do
            local ok, list = pcall(get)
            if ok and list then
                for i = 1, #list do hookOne(list[i]) end
            end
        end
    end)
end
