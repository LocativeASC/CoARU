CoARU_SUBORDER = { "ПРЕДМЕТЫ И СПОСОБНОСТИ", "МИР", "СУЩЕСТВА", "ИГРОКИ" }

CoARU_GROUPS = {
    { key = "text",  label = "Текст",
      hint = "то, что читают: описания, задания, реплики" },
    { key = "names", label = "Имена и названия",
      hint = "выключите то, что ищете по-английски в чате и гайдах" },

    { key = "ui",    label = "Окна и панели", column = 2,
      hint = "интерфейс клиента и сервера" },
}

CoARU_MODULES = {
    { key = "spells", group = "text",  label = "Описания способностей",
      hint = "тултипы и книга заклинаний; имена — отдельной галкой" },

    { key = "items", group = "text",   label = "Описания предметов",
      hint = "строки тултипа: эффекты, «Использование», художественный текст" },
    { key = "itemnames", group = "names", sub = "ПРЕДМЕТЫ И СПОСОБНОСТИ", label = "Имена предметов",
      hint = "выключите, если ищете вещи по английским именам на аукционе и в гайдах" },
    { key = "stats", group = "ui",   label = "Окно персонажа",
      hint = "характеристики, подписи вкладок и тултипы статов" },
    { key = "quests", group = "text",  label = "Задания",              hint = "текст, цели, журнал" },

    { key = "speech", group = "text",  label = "Речь персонажей",      hint = "реплики НПС в чате и в пузырях над ними" },

    { key = "titles", group = "names", sub = "ИГРОКИ",  label = "Звания игроков",
      hint = "в тултипе, рамке цели и окне выбора; ванильные звания переводит пакет" },
    { key = "zones", group = "names", sub = "МИР",   label = "Названия зон",
      hint = "в заданиях, тултипах и подсказках; сами картинки карты ставятся архивом" },

    { key = "dungeons", group = "names", sub = "МИР", label = "Подземелья и поля боя",
      hint = "названия подземелий, рейдов, полей боя и арен" },

    { key = "names", group = "names", sub = "СУЩЕСТВА",   label = "Имена существ в тултипе",
      hint = "тултип наведения и рамка цели; над головой — отдельно, см. ниже" },

    { key = "nameplates", group = "names", sub = "СУЩЕСТВА", label = "Имена на плашках",
      off = true,
      hint = "плашка с полоской здоровья; надпись под НПС меняет батник, а не галка" },
    { key = "ca", group = "ui",      label = "Экран развития",       hint = "специализации Character Advancement" },
    { key = "trainer", group = "ui", label = "Окно тренера",         hint = "список умений у учителя" },
    { key = "spellnames", group = "names", sub = "ПРЕДМЕТЫ И СПОСОБНОСТИ", label = "Имена способностей",
      hint = "выключите, если ищете способности по английским названиям в чате и гайдах" },

    { key = "classes", group = "names", sub = "ПРЕДМЕТЫ И СПОСОБНОСТИ", label = "Названия классов",
      hint = "Necromancer, Tinker, Ranger и остальные 18 классов CoA" },

    { key = "ascui", group = "ui",   label = "Интерфейс Ascension",
      hint = "окна сервера: доска заданий" },
}

CoARU_PRESETS = {
    { key = "all", label = "Всё по-русски", off = {},
      hint = "перевод везде, где он есть" },

    { key = "textonly", label = "Имена английские",
      off = { "spellnames", "classes", "names", "zones", "dungeons", "nameplates" },
      hint = "описания и задания переведены, названия оставлены как в чате и гайдах" },
    { key = "ui", label = "Только интерфейс",
      off = { "spells", "items", "quests", "speech", "spellnames", "classes", "names",
              "zones", "dungeons", "nameplates", "titles" },
      hint = "переведены только окна: персонаж, тренер, развитие, Ascension" },
}

function CoARU_MatchPreset()
    for i = 1, #CoARU_PRESETS do
        local p = CoARU_PRESETS[i]
        local off = {}
        for j = 1, #p.off do off[p.off[j]] = true end
        local same = true
        for j = 1, #CoARU_MODULES do
            local k = CoARU_MODULES[j].key
            if (CoARU_ModOn(k) and true or false) ~= (not off[k]) then
                same = false
                break
            end
        end
        if same then return p.key end
    end
    return nil
end

function CoARU_ApplyPreset(key)
    local p
    for i = 1, #CoARU_PRESETS do
        if CoARU_PRESETS[i].key == key then p = CoARU_PRESETS[i] end
    end
    if not p then return false end
    local off = {}
    for i = 1, #p.off do off[p.off[i]] = true end

    CoARU_ReloadAskSuppressed = true
    local anyOff = false
    for i = 1, #CoARU_MODULES do
        local k = CoARU_MODULES[i].key
        local want = not off[k]
        if not want then anyOff = true end
        CoARU_SetMod(k, want)
    end
    CoARU_ReloadAskSuppressed = false
    if anyOff and CoARU_AskReload then CoARU_AskReload("preset", false) end
    if CoARU_WarnInconsistent then pcall(CoARU_WarnInconsistent) end
    return true
end

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
    CoARU_AskReload(key, on and true or false)

    if CoARU_WarnInconsistent and not CoARU_ReloadAskSuppressed then
        pcall(CoARU_WarnInconsistent)
    end
    return CoARU_ModOn(key)
end

CoARU_ReloadNeeded = CoARU_ReloadNeeded or {}

function CoARU_AskReload(key, on)
    if key == "all" or key == "preset" then return end
    if on then
        CoARU_ReloadNeeded[key] = nil
    else
        CoARU_ReloadNeeded[key] = true
    end
    if CoARU_ReloadNoteChanged then CoARU_ReloadNoteChanged() end
end

function CoARU_ReloadList()
    local names, n = {}, 0
    for i = 1, #CoARU_MODULES do
        local m = CoARU_MODULES[i]
        if CoARU_ReloadNeeded[m.key] then
            n = n + 1
            names[n] = m.label
        end
    end
    return n, names
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
