local ALIAS = {

    ["Arathi"] = "Arathi Highlands",
    ["Borean"] = "Borean Tundra",
    ["Elwynn"] = "Elwynn Forest",
    ["Redridge"] = "Redridge Mountains",
    ["Stranglethorn"] = "Stranglethorn Vale",
    ["Theramore"] = "Theramore Isle",
    ["Tirisfal"] = "Tirisfal Glades",
    ["Feathermoon"] = "Feathermoon Stronghold",
    ["Moa'ki"] = "Moa'ki Harbor",
    ["Northshire"] = "Northshire Valley",
    ["Westfall Brigade"] = "Westfall Brigade Encampment",

    ["Dun Nifflelem"] = "Dun Niffelem",
    ["Kor'koron Vanguard"] = "Kor'kron Vanguard",
    ["Valgarde Port"] = "Valgarde",
}

local OWN = {
    ["Warsong Camp"] = "Лагерь Песни Войны",
    ["Valiance Landing Camp"] = "Лагерь высадки Отваги",
    ["Spinebreaker Ridge"] = "Гряда Хребтолома",
    ["Coldarra Ledge"] = "Уступ Хладарры",
    ["Camp Onequah"] = "Лагерь Онекуа",
    ["Dun Kazad"] = "Дун Казад",
    ["Fishing Village"] = "Рыбацкая деревня",
}

CoARU_TaxiOwn = OWN

local function zoneRU(name)
    if not name or name == "" then return nil end
    local Z = CoARU_ZONE
    if not Z then return nil end

    local ru = Z[name] or Z["The " .. name] or Z[name .. " City"]
    if ru then return ru end
    local full = ALIAS[name]
    if full then
        ru = Z[full] or Z["The " .. full] or Z[full .. " City"]
        if ru then return ru end
    end
    return OWN[name]
end

local function xlateNode(text)
    if not text or text == "" then return nil end
    if CoARU_ModOn and not CoARU_ModOn("zones") then return nil end
    if CoARU_HasCyrillic and CoARU_HasCyrillic(text) then return nil end
    local out, n = {}, 0
    for part in (text .. ","):gmatch("%s*(.-)%s*,") do
        if part == "" then return nil end
        local ru = zoneRU(part)
        if not ru then return nil end
        n = n + 1
        out[n] = ru
    end
    if n == 0 then return nil end
    return table.concat(out, ", ")
end

CoARU_TaxiNodeRU = xlateNode

do
    local orig = TaxiNodeName
    if orig then
        function TaxiNodeName(i)
            local text = orig(i)
            local ok, ru = pcall(xlateNode, text)
            if ok and ru then return ru end
            return text
        end
    end
end
