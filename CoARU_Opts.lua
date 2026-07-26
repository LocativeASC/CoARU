CoARU_MODULES = {
    { key = "spells",  label = "Заклинания и таланты", hint = "описания в тултипах и книге" },
    { key = "items",   label = "Предметы",             hint = "имена и строки тултипа вещей" },
    { key = "stats",   label = "Окно персонажа",       hint = "характеристики и подписи" },
    { key = "quests",  label = "Задания",              hint = "текст, цели, журнал" },
    { key = "zones",   label = "Зоны и карта",         hint = "названия местностей" },
    { key = "names",   label = "Имена существ",        hint = "тултип и рамка цели" },
    { key = "ca",      label = "Экран развития",       hint = "специализации Character Advancement" },
    { key = "trainer", label = "Окно тренера",         hint = "список умений у учителя" },
    { key = "spellnames", label = "Имена способностей", off = true,
      hint = "по умолчанию латиницей: так их проще найти в чате и гайдах" },
}

local DEFAULT_OFF = {}
for i = 1, #CoARU_MODULES do
    if CoARU_MODULES[i].off then DEFAULT_OFF[CoARU_MODULES[i].key] = true end
end

CoARU_OptHooks = {}

function CoARU_ModOn(key)
    local m = CoARU_DB and CoARU_DB.opts and CoARU_DB.opts.mod
    local v = m and m[key]
    if v ~= nil then return v ~= false end
    return not DEFAULT_OFF[key]
end

function CoARU_SetMod(key, on)
    if not CoARU_DB then return end
    CoARU_DB.opts = CoARU_DB.opts or {}
    CoARU_DB.opts.mod = CoARU_DB.opts.mod or {}

    if DEFAULT_OFF[key] then
        if on then
            CoARU_DB.opts.mod[key] = true
        else
            CoARU_DB.opts.mod[key] = nil
        end
    elseif on then
        CoARU_DB.opts.mod[key] = nil
    else
        CoARU_DB.opts.mod[key] = false
    end
    local fn = CoARU_OptHooks[key]
    if fn then pcall(fn, on and true or false) end
    return CoARU_ModOn(key)
end

function CoARU_ModsOff()
    local n, names = 0, {}
    for i = 1, #CoARU_MODULES do
        local m = CoARU_MODULES[i]
        if not CoARU_ModOn(m.key) then
            n = n + 1
            names[#names + 1] = m.label
        end
    end
    return n, names
end
