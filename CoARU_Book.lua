local ROOTS = {
    "AscensionSpellbookFrame", "SpellBookFrame", "CoASpellbookFrame",
    "SpellBookSpellIconsFrame", "SpellBookProfessionFrame",
}

local seen = 0

local function swapPlain(t, from, to)
    local s, e = t:find(from, 1, true)
    if not s then return nil end
    return t:sub(1, s - 1) .. to .. t:sub(e + 1)
end

CoARU_NAME_SEEN = CoARU_NAME_SEEN or {}

CoARU_SUB_SEEN = CoARU_SUB_SEEN or {}

local function nameRU(t)
    if not t or t == "" then return nil end
    if not CoARU_SPELL_NAME_RU then return nil end
    local nm = CoARU_StripCodes(t):gsub("^%s+", ""):gsub("%s+$", "")
    if nm == "" or not nm:find("^[A-Za-z]") then return nil end

    if CoARU_IsSpecName and CoARU_IsSpecName(nm) then return nil end
    local ru = CoARU_SPELL_NAME_RU[nm]
    if not ru or ru == nm then return nil end
    CoARU_NAME_SEEN[ru] = nm
    return swapPlain(t, nm, ru), nm
end

local SUB_RU = {
    ["Passive"] = "Пассивная",
    ["Racial"] = "Расовая",
    ["Racial Passive"] = "Расовая пассивная",
    ["Spec"] = "Специализация",
    ["Spec Passive"] = "Пассивная специализации",
    ["Talent"] = "Талант",
    ["Talent Passive"] = "Пассивный талант",
    ["Apprentice"] = "Ученик",
    ["Journeyman"] = "Подмастерье",
    ["Expert"] = "Специалист",
    ["Artisan"] = "Мастер",
    ["Master"] = "Великий мастер",
}

local function subRU(t)
    if not t or t == "" then return nil end
    local s = t:match("^%s*(.-)%s*$")
    local ru = SUB_RU[s]
    if ru then
        CoARU_SUB_SEEN[ru] = s
        return (t:gsub(s, ru, 1))
    end

    local n = s:match("^Rank%s+(%d+)$")
    if n then
        CoARU_SUB_SEEN["Ранг " .. n] = s
        return "Ранг " .. n
    end
    return nil
end

local cache, cached = {}, false

local function collect(fr, depth)
    if not fr or depth > 8 or not fr.GetRegions then return end
    for i = 1, select("#", fr:GetRegions()) do
        local r = select(i, fr:GetRegions())
        if r and r.GetObjectType and r:GetObjectType() == "FontString" and r.GetText
                and not (CoARU_InEditBox and CoARU_InEditBox(r)) then
            cache[#cache + 1] = r
        end
    end
    if fr.GetChildren then
        for i = 1, select("#", fr:GetChildren()) do
            collect(select(i, fr:GetChildren()), depth + 1)
        end
    end
end

local function apply()
    for i = 1, #cache do
        local r = cache[i]
        local t = r.GetText and r:GetText()
        local ru = nameRU(t) or subRU(t)
        if ru then
            seen = seen + 1

            if CoARU_SetTranslated then CoARU_SetTranslated(r, t, ru) else r:SetText(ru) end
        end
    end
end

function CoARU_BookRescan()
    cache, cached = {}, false
end

function CoARU_BookApply()
    if not CoARU_ModOn or not CoARU_ModOn("spellnames") then return end
    if not cached then
        for _, n in ipairs(ROOTS) do
            local f = _G[n]
            if f and f.IsShown and f:IsShown() then collect(f, 0) end
        end
        cached = #cache > 0
    end
    apply()
end

function CoARU_BookDump()
    local msg = "|cffC495DDCoARU|r книга: "
    local found = {}
    for _, n in ipairs(ROOTS) do
        local f = _G[n]
        if f then
            found[#found + 1] = n .. (f.IsShown and f:IsShown() and " (открыт)" or " (скрыт)")
        end
    end
    if #found == 0 then
        print(msg .. "НИ ОДИН из известных фреймов не найден — окно рисуется чем-то другим.")
        print(msg .. "Список корней: " .. table.concat(ROOTS, ", "))
        return
    end
    print(msg .. table.concat(found, ", "))
    print(msg .. "подмен имен за сессию: " .. seen)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("LEARNED_SPELL_IN_TAB")
f:RegisterEvent("SPELLS_CHANGED")
f:SetScript("OnEvent", function() CoARU_BookRescan() CoARU_BookApply() end)
f:SetScript("OnUpdate", function()
    for _, n in ipairs(ROOTS) do
        local fr = _G[n]
        if fr and fr.IsShown and fr:IsShown() then CoARU_BookApply() return end
    end
end)

local hooked = false
local function hookShow()
    if hooked then return end
    for _, n in ipairs(ROOTS) do
        local fr = _G[n]
        if fr and fr.HookScript then

            fr:HookScript("OnShow", function() CoARU_BookRescan() CoARU_BookApply() end)
            hooked = true
        end
    end
end
f:HookScript("OnEvent", function() hookShow() end)
hookShow()
