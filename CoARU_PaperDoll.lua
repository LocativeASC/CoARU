local KEYS = {

    CHARACTER_INFO          = "Информация о персонаже",
    PLAYERSTAT_DEFENSES     = "Защита",
    PLAYERSTAT_MELEE_COMBAT = "Ближний бой",
    PLAYERSTAT_RANGED_COMBAT= "Дальний бой",
    PLAYERSTAT_SPELL_COMBAT = "Магия",
    STAT_ATTRIBUTES_LABEL   = "Характеристики",
    PLAYERSTAT_RESISTANCES  = "Сопротивления",
    STAT_ENHANCEMENTS       = "Улучшения",

    CHARACTER  = "Персонаж",
    PET        = "Питомец",
    PETS       = "Питомцы",
    REPUTATION = "Репутация",
    SKILLS     = "Навыки",
    CURRENCY   = "Валюта",
    COMPANIONS = "Спутники",
    MOUNTS     = "Транспорт",
    SEARCH     = "Поиск",

    TRADE_SKILLS     = "Профессии",
    SECONDARY_SKILLS = "Вспомогательные навыки:",

    WORLD_MAP        = "Карта мира",
    WORLDMAP_BUTTON  = "Карта мира",
    ZONE             = "Игровая зона",
    CONTINENT        = "Континент",
    ZOOM_OUT         = "Отдалить",
    QUEST_OBJECTIVES = "Цели задания",
    ABANDON_QUEST    = "Отменить задание",
    SHARE_QUEST      = "Предложить другу",
    TRACK_QUEST      = "Отслеживать",
    QUEST_LOG        = "Журнал заданий",
    QUESTS_LABEL     = "Задания",
    QUEST_DESCRIPTION = "Описание",
    QUEST_REWARDS    = "Награды",
    REWARD_ITEMS     = "Вы также получите:",
    REWARD_ITEMS_ONLY = "Вы получите:",
    COMPLETE_QUEST   = "Завершить",
    ACCEPT           = "Принять",
    DECLINE          = "Отказаться",
    CONTINUE         = "Продолжить",
    MINIMAP_LABEL    = "Миникарта",
    MINIMAP_TRACKING_TOOLTIP_NONE = "Щелкните, чтобы выбрать объекты слежения",
    BATTLEFIELDS     = "Поля боя",

    REWARDS          = "Награды",
    OBJECTIVES       = "Цели",
    TURN_IN_QUEST    = "Сдать",
    SHOW_QUEST_OBJECTIVES_ON_MAP_TEXT = "Показывать цели заданий",

    CLOSE                = "Закрыть",
    CANCEL               = "Отмена",
    COMPLETE             = "Выполнено",
    FAILED               = "Неудача",
    DAILY                = "Ежедневно",
    FLOOR                = "Уровни",
    EXPERIENCE_COLON     = "Опыт:",
    CURRENT_QUESTS       = "Текущие задания",
    AVAILABLE_QUESTS     = "Доступные задания",
    QUEST_COMPLETE       = "Задание выполнено",
    QUESTLOG_NO_QUESTS_TEXT = "Задания отсутствуют.",
    TURN_IN_ITEMS        = "Требующиеся предметы:",
    REQUIRED_MONEY       = "Требующаяся сумма денег:",
    LOCK_WINDOW          = "Зафиксировать окно",

    BATTLEFIELD_MINIMAP  = "Карта игровой зоны",
    BATTLEFIELD_MINIMAP_SHOW_NEVER        = "Не отображать",
    BATTLEFIELD_MINIMAP_SHOW_ALWAYS       = "Всегда отображать",
    BATTLEFIELD_MINIMAP_SHOW_BATTLEGROUNDS = "Отображать на поле боя",

    ABANDON_QUEST_ABBREV = "Отменить",
    SHARE_QUEST_ABBREV   = "Предложить",
    TRACK_QUEST_ABBREV   = "Отслеживать",

    UNTRACK_QUEST_ABBREV = "Не отслеж.",
    REWARD_CHOICES       = "Вы сможете выбрать одну из наград:",

    TIMEMANAGER_24HOURMODE     = "24 часа",
    TIMEMANAGER_SHOW_STOPWATCH = "Таймер",
    TIMEMANAGER_ALARM_TIME     = "Время будильника",
    TIMEMANAGER_ALARM_MESSAGE  = "Сообщение",
    TIMEMANAGER_ALARM_ENABLED  = "Вкл. напоминание",
    TIMEMANAGER_ALARM_DISABLED = "Откл. напоминание",
    TIMEMANAGER_LOCALTIME      = "Использовать местное время",
    TIMEMANAGER_TOOLTIP_TITLE  = "Информация о времени",
    TIMEMANAGER_TITLE          = "Часы",
    TIMEMANAGER_ALARM_TOOLTIP_TURN_OFF = "Щелкните, чтобы отключить напоминание.",
    STOPWATCH_TITLE            = "Таймер",

    FACTION_STANDING_LABEL1 = "Ненависть",
    FACTION_STANDING_LABEL2 = "Враждебность",
    FACTION_STANDING_LABEL3 = "Неприязнь",
    FACTION_STANDING_LABEL4 = "Равнодушие",
    FACTION_STANDING_LABEL5 = "Дружелюбие",
    FACTION_STANDING_LABEL6 = "Уважение",
    FACTION_STANDING_LABEL7 = "Почтение",
    FACTION_STANDING_LABEL8 = "Превознесение",
}

local SHORT = {

    CHARACTER_INFO      = "Информация о перс.",
    ATTACK_SPEED        = "Скор. атаки",
    ATTACK_POWER        = "Сила атк.",
    MELEE_ATTACK_POWER  = "Сила атк. бл.",
    RANGED_ATTACK_POWER = "Сила атк. дал.",
    ARMOR_PENETRATION   = "Пробив. брони",
    DODGE_CHANCE        = "Уклонение",
    PARRY_CHANCE        = "Парирование",
    BLOCK_CHANCE        = "Блок",
    MANA_REGEN          = "Восп. маны",
    BONUS_HEALING       = "Доп. исцеление",
    SPELL_PENETRATION   = "Проникновение",
    DAMAGE_PER_SECOND   = "Урон в сек.",
    RESISTANCE1_NAME    = "Сопр. светлой",
    RESISTANCE2_NAME    = "Сопр. огню",
    RESISTANCE3_NAME    = "Сопр. природе",
    RESISTANCE4_NAME    = "Сопр. льду",
    RESISTANCE5_NAME    = "Сопр. тьме",
    RESISTANCE6_NAME    = "Сопр. тайной",
}

local SHORT_PLAIN = {
    ["Off-Hand Hit"]        = "Меткость л.р.",
    ["Item Level"]          = "Ур. предметов",
    ["Prestige Level"]      = "Ур. престижа",
    ["Average Item Level"]  = "Ср. ур. предметов",
    ["Secondary Skills"]    = "Вспом. навыки",
}

local PLAIN = {
    ["Class Skills"]         = "Классовые навыки",

    ["Armor Proficiencies"]  = "Владение доспехами",
    ["Languages"]            = "Языки",
    ["Weapon Skills"]   = "Владение оружием",
    ["Armor Skills"]    = "Владение доспехами",
    ["Secondary Skills"]= "Вспомогательные навыки",
    ["Professions"]     = "Профессии",
    ["Dismiss"]         = "Отпустить",
    ["Summon"]          = "Призвать",
    ["Classic"]         = "Классика",
    ["Other"]           = "Прочее",
    ["Horde"]           = "Орда",
    ["Alliance"]        = "Альянс",
    ["Attributes"]      = "Характеристики",
    ["Resistances"]     = "Сопротивления",
    ["Enhancements"]    = "Улучшения",
    ["Item Level"]      = "Уровень предметов",
    ["Prestige Level"]  = "Уровень престижа",
}

local TIPS = {
    TIP_CLICK                  = "Щелкните здесь",
    NEW_TUTORIAL_TIP           = "Появились новые сведения",
    TIP_QUEST_FRAME_SELECT     = "Выберите это задание",
    TIP_QUEST_FRAME_ACCEPT     = "Примите задание",
    TIP_QUEST_FRAME_COMPLETE   = "Завершите задание!",
    TIP_QUEST_LOG_OPEN         = "Щелкните здесь или нажмите |cffFFFF00L|r, чтобы открыть журнал заданий",
    TIP_QUEST_LOG_TRACK        = "Щелкните здесь, чтобы отслеживать выбранное задание",
    TIP_QUEST_POI_GO_TO        = "Отправляйтесь в эту область",
    TIP_SPELLBOOK_OPEN         = "Щелкните здесь или нажмите |cffFFFF00P|r, чтобы открыть книгу заклинаний",
    TIP_USE_ABILITIES          = "Чтобы применить способность, нажмите цифру, указанную на ее значке",
    TIP_WATCH_FRAME_PING       = "Здесь виден ваш прогресс по заданиям!",
    ERR_LFG_NO_ROLES_SELECTED  = "Нужно выбрать хотя бы одну роль.",
    ERR_QUEST_MUST_CHOOSE      = "Нужно выбрать награду.",
    FORCED_PRIMARY_STAT_HELP_TIP = "Сменить путь развития характеристик можно в окне развития персонажа.",
    HELP_TIP_UNSPENT_ESSENCE_CUSTOM_CLASS_TEXT  = "У вас есть нераспределенные очки!",
    HELP_TIP_UNSPENT_ESSENCE_DEFAULT_CLASS_TEXT = "У вас есть нераспределенные очки талантов!",
    HELP_TIP_UNSPENT_ESSENCE_TEXT = "За повышение уровня вы получили |n|cffFFFF00[Ability Essence]|r! Щелкните здесь, чтобы изучить новую способность!",
    TIP_UNSPENT_ABILITY_ESSENCE = "У вас есть нераспределенная |cffffd100[Ability Essence]|r.|nЩелкните здесь, чтобы изучить новое заклинание!",
    TIP_UNSPENT_TALENT_ESSENCE  = "У вас есть нераспределенная |cffffd100[Talent Essence]|r.|nЩелкните здесь, чтобы изучить новый талант!",

    SPELL_HINT_LEARN_HOTKEYS1  = "Изучайте заклинания быстрее: |cffffd100Shift+клик|r или |cffffd100двойной клик|r по значку.",
    SPELL_HINT_LEARN_HOTKEYS2  = "Забыть заклинание быстрее: |cffffd100Alt+клик|r по значку.",
    SPELL_HINT_LEARN_HOTKEYS3  = "Изучить все ранги таланта разом: |cffffd100Ctrl+клик|r по значку.",
    TIP_HARDCAST_EQUIP_STAFF   = "Для заклинаний со временем произнесения стоит взять |cff71d5ffпосох|r: он сокращает время произнесения!",
    TIP_LAYER_PICKER           = "Вы в отдельной копии зоны!|nЩелкните, чтобы перейти в другую копию.|n|nКопии — это отдельные слои одной зоны, чтобы игра оставалась комфортной.",
    TIP_OPEN_WARDROBE_TO_CHANGE_TRANSMOG = "Настройку показа трансмогрификации можно изменить в гардеробе в любой момент!",
    TIP_WARDROBE_CHANGE_TRANSMOG = "Здесь настраивается показ трансмогрификации!",
    TIP_SHOW_MINIMAP_MAIL      = "Этот значок означает, что вам пришла почта! Заберите ее у почтового ящика.\n\nНайти ближайший поможет значок с лупой слева от миникарты.",

    TIP_UNANSWERED_PLAYER_POLL_QUESTIONS = "В опросе остались вопросы без ответа!|nЩелкните и выскажитесь о будущем Ascension!",
    BUILD_CREATOR_FEATURED_HINT = "Рекомендованные сборки сами применяют способности, таланты и мистические чары по мере роста уровня.\n\nВсе рекомендованные сборки входят в лучший 1% — это и есть условие попадания в список.\n\nВключить их можно только до 10 уровня.",
}

local TIP_BUTTONS = {
    OKAY            = "ОК",
    NEXT            = "Далее",
    CLOSE           = "Закрыть",
    GOT_IT          = "Понятно",
    DONT_SHOW_AGAIN = "Больше не показывать",
}

local MAP

local function buildMap()
    if MAP then return MAP end
    MAP = {}
    local function put(en, ru)
        if type(en) ~= "string" or type(ru) ~= "string" then return end
        if en == "" or en:find("%%") then return end
        if MAP[en] == nil then MAP[en] = ru end
    end

    for key, ru in pairs(SHORT) do put(_G[key], ru) end
    for en, ru in pairs(SHORT_PLAIN) do put(en, ru) end

    for en, ru in pairs(PLAIN) do put(en, ru) end
    for key, ru in pairs(KEYS) do put(_G[key], ru) end

    for en, ru in pairs(CoARU_SkillRU or {}) do put(en, ru) end

    for key, ru in pairs(CoARU_StatLabelRU or {}) do put(_G[key], ru) end
    for en, ru in pairs(CoARU_StatLabelOwn or {}) do put(en, ru) end

    for en in pairs(CoARU_SkillNever or {}) do MAP[en] = nil end

    local fmt = _G["STAT_FORMAT"]
    if type(fmt) == "string" and fmt:find("%%s") then
        local pairsCopy = {}
        for en, ru in pairs(MAP) do pairsCopy[en] = ru end
        for en, ru in pairs(pairsCopy) do
            local okEn, decorEn = pcall(string.format, fmt, en)
            local okRu, decorRu = pcall(string.format, fmt, ru)
            if okEn and okRu and decorEn ~= en then put(decorEn, decorRu) end
        end
    end
    return MAP
end

local function stripColor(t)
    local c = t:match("^(|[cC]%x%x%x%x%x%x%x%x)")
    local base = t
    if c then base = base:gsub("^|[cC]%x%x%x%x%x%x%x%x", "", 1):gsub("|r$", "") end
    return base, c
end

local MENU = {
    ["Unlock Frame"]          = "Открепить рамку",
    ["Unlock Frame Position"] = "Открепить рамку",
    ["Lock Frame"]            = "Закрепить рамку",
    ["Lock Frame Position"]   = "Закрепить рамку",
    ["Lock Objectives Frame"] = "Закрепить рамку целей",
    ["Scale"]          = "Масштаб",
    ["Reset Position"] = "Сбросить положение",
    ["Hide"]           = "Скрыть",
    ["Show"]           = "Показать",
    ["Close"]          = "Закрыть",
    ["Cancel"]         = "Отмена",

}

local scopeCache = {}
local function scopedMap(name)
    return function()
        if scopeCache[name] then return scopeCache[name] end
        local m = {}
        for key, ru in pairs((CoARU_ScopedRU or {})[name] or {}) do
            local en = _G[key]
            if type(en) == "string" and en ~= "" and m[en] == nil then
                m[en] = ru
            end
        end
        scopeCache[name] = m
        return m
    end
end

local BINDINGS
local function bindingMap()
    if BINDINGS then return BINDINGS end
    BINDINGS = {}
    for key, ru in pairs(CoARU_BindingRU or {}) do
        local en = _G[key]
        if type(en) == "string" and en ~= "" and BINDINGS[en] == nil then
            BINDINGS[en] = ru
        end
    end
    return BINDINGS
end

local TARGETS = {
    { name = "AscensionCharacterFrame", perFrame = true },
    { name = "WorldMapFrame",           perFrame = false },
    { name = "QuestLogFrame",           perFrame = false },

    { name = "TimeManagerClockButton",  perFrame = false },

    { name = "TimeManagerFrame",        perFrame = false },
    { name = "StopwatchFrame",          perFrame = false },

    { name = "DropDownList1",           perFrame = true,  map = MENU },
    { name = "DropDownList2",           perFrame = true,  map = MENU },

    { name = "KeyBindingFrame",         perFrame = true,  map = bindingMap },

    { name = "CalendarFrame",  perFrame = true,  map = scopedMap("calendar") },
    { name = "HelpFrame",      perFrame = false, map = scopedMap("help") },
    { name = "TutorialFrame",  perFrame = false, map = scopedMap("tutorial") },

    { name = "PVPFrame",       perFrame = false, map = scopedMap("pvp") },
    { name = "PVPParentFrame", perFrame = false, map = scopedMap("pvp") },
    { name = "AuctionFrame",   perFrame = true,  map = scopedMap("auction") },
    { name = "LootFrame",      perFrame = true,  map = scopedMap("loot") },
    { name = "FriendsFrame",   perFrame = true,  map = scopedMap("social") },
}

local PATTERNS = {

    {
        "^Quests:%s*(%d+)/(%d+)$",
        function(a, b) return ("Задания: %s/%s"):format(a, b) end,
    },
}

local BUTTON_PADDING = 24

local function padFor(w)
    local p = w * 0.25
    if p > BUTTON_PADDING then p = BUTTON_PADDING end
    return p
end

local grown = {}

local applyTo
local inHook = false

local function hookFS(r)
    if r.__coaruHooked then return end
    r.__coaruHooked = true

    local ok = pcall(hooksecurefunc, r, "SetText", function(self)
        if inHook then return end
        inHook = true
        pcall(applyTo, self)
        inHook = false
    end)
    if not ok then r.__coaruHooked = nil end
end

local function hookButton(f)
    if f.__coaruBtnHooked or not f.GetFontString or not f.SetText then return end
    f.__coaruBtnHooked = true
    local ok = pcall(hooksecurefunc, f, "SetText", function(self)
        if inHook then return end
        inHook = true
        local okFS, fs = pcall(self.GetFontString, self)
        if okFS and fs then pcall(applyTo, fs) end
        inHook = false
    end)
    if not ok then f.__coaruBtnHooked = nil end
end

local function collect(frame, depth, out, map)
    if not frame or depth > 12 then return end
    hookButton(frame)
    if frame.GetRegions then
        local ok, regions = pcall(function() return { frame:GetRegions() } end)
        if ok then
            for _, r in ipairs(regions) do
                if r and r.GetObjectType and r:GetObjectType() == "FontString" then
                    out[#out + 1] = r

                    r.__coaruMap = map
                    hookFS(r)
                end
            end
        end
    end
    if frame.GetChildren then
        local ok, children = pcall(function() return { frame:GetChildren() } end)
        if ok then
            for _, c in ipairs(children) do collect(c, depth + 1, out, map) end
        end
    end
end

local MIN_BUTTON = 40

local function fitButton(fs)
    local okP, p = pcall(fs.GetParent, fs)
    if not okP or not p or not p.GetFontString or not p.SetWidth then return end
    local okT, ot = pcall(p.GetObjectType, p)
    if not okT or ot ~= "Button" then return end
    local okF, own = pcall(p.GetFontString, p)
    if not okF or own ~= fs then return end

    local okS, sw = pcall(fs.GetStringWidth, fs)
    local okW, w = pcall(p.GetWidth, p)
    if not (okS and okW and sw and w) or w <= 1 then return end
    if sw <= 0 then return end

    if w < MIN_BUTTON then return end
    local need = sw + padFor(w)
    if need < MIN_BUTTON then need = MIN_BUTTON end

    if need > w - 1 and need < w + 1 then return end

    local okN, n = pcall(p.GetNumPoints, p)
    if not okN or not n or n < 1 then return end
    local hasLeft, hasRight = false, false
    for i = 1, n do
        local okPt, pt = pcall(p.GetPoint, p, i)
        if okPt and pt then
            if pt:find("LEFT") then hasLeft = true end
            if pt:find("RIGHT") then hasRight = true end
        end
    end
    if hasLeft and hasRight then return end

    pcall(p.SetWidth, p, need)
    local okNm, nm = pcall(p.GetName, p)
    grown[(okNm and nm) or tostring(p)] = { w, need }
end

applyTo = function(r)

    local map = r.__coaruMap or buildMap()
    local ok, t = pcall(r.GetText, r)
    if not ok or not t or not t:find("%S") then return end
    local base, color = stripColor(t)
    local ru = map[base]
    if not ru then

        for _, rule in ipairs(PATTERNS) do
            local a, b = base:match(rule[1])
            if a then
                local ok, res = pcall(rule[2], a, b)
                if ok and res and res ~= base then ru = res end
                break
            end
        end
    end
    if not ru then return end
    if color then ru = color .. ru .. "|r" end
    pcall(r.SetText, r, ru)

    local okP, p = pcall(r.GetParent, r)
    if okP and p and p.UpdateWidth and p.Text == r then
        pcall(p.UpdateWidth, p)
    end

    if okP and p and PanelTemplates_TabResize then
        local okN, nm = pcall(p.GetName, p)
        local okT, ot = pcall(p.GetObjectType, p)

        if okN and nm and okT and ot == "Button" and nm:match("Tab%d+$")
           and _G[nm .. "Text"] == r and _G[nm .. "Left"] then
            pcall(PanelTemplates_TabResize, p, 0)
        end
    end

end

local function apply(t)
    for i = 1, t.n or 0 do
        applyTo(t.cache[i])
    end
end

local function rebuild(t, frame)

    if type(t.map) == "function" then t.map = t.map() end
    t.cache = {}
    collect(frame, 0, t.cache, t.map)
    t.n = #t.cache
    t.age = 0
end

local function retext(t, frame)
    rebuild(t, frame)
    apply(t)
end

local hookedCount = 0
local function tryHook()
    local pending = 0
    for _, t in ipairs(TARGETS) do
        if not t.hooked then
            local f = _G[t.name]
            if f and f.HookScript then
                t.hooked, t.cache, t.n, t.age = true, {}, 0, 0
                hookedCount = hookedCount + 1
                f:HookScript("OnShow", function(self) retext(t, self) end)
                if t.perFrame then
                    f:HookScript("OnUpdate", function(self, elapsed)
                        t.age = (t.age or 0) + (elapsed or 0)
                        if t.age >= 0.5 then rebuild(t, self) end
                        apply(t)
                    end)
                end
                if f:IsShown() then retext(t, f) end
            else
                pending = pending + 1
            end
        end
    end
    return pending == 0
end

local tipsDone = false
local function translateTips()
    if tipsDone then return end
    local tips = _G["HelpTips"]
    if type(tips) ~= "table" then return end
    tipsDone = true
    local n = 0
    for key, ru in pairs(TIPS) do
        local en = _G[key]
        if type(en) == "string" and en ~= "" then

            for _, info in pairs(tips) do
                if type(info) == "table" and info.text == en then
                    info.text = ru
                    n = n + 1
                end
            end
        end
    end

    local buttons = _G["HelpTip"] and _G["HelpTip"].Buttons
    if type(buttons) == "table" then
        for key, ru in pairs(TIP_BUTTONS) do
            local en = _G[key]
            if type(en) == "string" and en ~= "" then
                for _, style in pairs(buttons) do
                    if type(style) == "table" and style.text == en then
                        style.text = ru
                        n = n + 1
                    end
                end
            end
        end
    end
    CoARU_TipsTranslated = n
end

local waiter = CreateFrame("Frame")
waiter:RegisterEvent("PLAYER_LOGIN")
waiter:RegisterEvent("ADDON_LOADED")
local pacc = 0
local allHooked = false
local function stopIfHooked()
    if allHooked then
        waiter:UnregisterAllEvents()
        waiter:SetScript("OnUpdate", nil)
    end
end
waiter:SetScript("OnEvent", function() translateTips(); allHooked = tryHook(); stopIfHooked() end)
waiter:SetScript("OnUpdate", function(_, elapsed)
    pacc = pacc + (elapsed or 0)
    if pacc >= 1 then pacc = 0; translateTips(); allHooked = tryHook(); stopIfHooked() end
end)

function CoARU_PaperDollFit()
    local bad, checked, total = 0, 0, 0
    for _, tgt in ipairs(TARGETS) do
    for i = 1, tgt.n or 0 do
        local r = tgt.cache[i]
        total = total + 1
        local okT, t = pcall(r.GetText, r)
        local okW, w = pcall(r.GetWidth, r)
        local okS, sw = pcall(r.GetStringWidth, r)
        local okH, h = pcall(r.GetHeight, r)
        local okF, _, size = pcall(r.GetFont, r)
        if okT and okW and okS and okH and okF and t and t:find("%S")
            and w and sw and h and size and size > 0 and w > 1 then
            checked = checked + 1
            local singleLine = h < size * 1.6

            local limit, what = w, "поле"
            local okP, p = pcall(r.GetParent, r)
            if okP and p then

                local okT, ot = pcall(p.GetObjectType, p)
                local okFS, fs = pcall(p.GetFontString, p)
                local okPW, pw = pcall(p.GetWidth, p)
                if okT and ot == "Button" and okFS and fs == r and okPW and pw and pw > 1 then
                    limit, what = pw - padFor(pw), "кнопка (с отступами)"
                elseif p.UpdateWidth and p.Text == r then
                    if okPW and pw and pw > 1 then limit, what = pw, "вкладка" end
                end
            end

            if singleLine and sw > limit + 0.5 then
                bad = bad + 1
                print(("|cffff8800CoARU|r обрезано: %q (текст %.0f > %s %.0f)")
                      :format(t, sw, what, limit))
            end
        end
    end
    end
    print(("|cffff8800CoARU|r однострочных проверено %d из %d, не влезает %d")
          :format(checked, total, bad))

    local anyGrown = false
    for name, wh in pairs(grown) do
        anyGrown = true
        print(("|cffff8800CoARU|r расширена кнопка %s: %.0f -> %.0f"):format(name, wh[1], wh[2]))
    end
    if not anyGrown then print("|cffff8800CoARU|r кнопок не расширяли") end
    return bad
end

function CoARU_PaperDollGeom()
    local seen, n = {}, 0
    CoARU_DB = CoARU_DB or {}
    CoARU_DB.geom = {}
    for _, tgt in ipairs(TARGETS) do
        for i = 1, tgt.n or 0 do
            local r = tgt.cache[i]
            local okP, p = pcall(r.GetParent, r)
            if okP and p and not seen[p] then
                local okT, ot = pcall(p.GetObjectType, p)
                if okT and ot == "Button" then
                    seen[p] = true
                    local okNm, nm = pcall(p.GetName, p)
                    local okL, l = pcall(p.GetLeft, p)
                    local okR, rr = pcall(p.GetRight, p)
                    local okW, w = pcall(p.GetWidth, p)
                    local okS, sw = pcall(r.GetStringWidth, r)
                    local okTx, tx = pcall(r.GetText, r)
                    if okL and okR and l and rr then
                        n = n + 1

                        CoARU_DB.geom[n] = ("%s | лев %.1f прав %.1f шир %.1f текст %.1f | %s")
                            :format((okNm and nm) or "?", l, rr,
                                    (okW and w) or -1, (okS and sw) or -1,
                                    (okTx and tx) or "")
                    end
                end
            end
        end
    end
    print(("|cffff8800CoARU|r кнопок записано: %d. Сделай /reload и пришли SavedVariables"):format(n))
    if n == 0 then print("|cffff8800CoARU|r окна закрыты — открой журнал (L) и повтори") end
    return n
end

function CoARU_PaperDollFrames()
    CoARU_DB = CoARU_DB or {}
    CoARU_DB.frames = CoARU_DB.frames or {}
    local n = 0
    for name, obj in pairs(_G) do
        if type(name) == "string" and type(obj) == "table" then

            local ok, isFrame = pcall(function()
                return obj.GetObjectType and obj.IsShown and obj:IsShown()
                       and obj:GetObjectType() == "Frame"
            end)
            if ok and isFrame then

                local labels, kids = {}, nil
                local okk = pcall(function() kids = { obj:GetRegions() } end)
                if okk then
                    for _, r in ipairs(kids) do
                        local okt, txt = pcall(function()
                            return r.GetText and r:IsShown() and r:GetText()
                        end)
                        if okt and type(txt) == "string" and txt:find("%S") and #labels < 6 then
                            labels[#labels + 1] = txt
                        end
                    end
                end
                if #labels > 0 then
                    n = n + 1
                    CoARU_DB.frames[name] = table.concat(labels, " | ")
                end
            end
        end
    end
    print(("|cffff8800CoARU|r показанных окон с текстом: %d. /reload и пришли SavedVariables"):format(n))
    return n
end

function CoARU_PaperDollStatus()
    local n = 0
    for _ in pairs(buildMap()) do n = n + 1 end

    local parts, fs = {}, 0
    for _, t in ipairs(TARGETS) do
        parts[#parts + 1] = ("%s:%s"):format(t.name:gsub("Frame$", ""), t.hooked and "да" or "НЕТ")
        fs = fs + (t.n or 0)
    end
    return n, table.concat(parts, " "), fs
end
