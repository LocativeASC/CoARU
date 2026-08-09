local function broadcastOn()
    return not CoARU_ModOn or CoARU_ModOn("speech")
end

local function linkText(s, fn)
    return (s:gsub("(|h%[)([^%]]+)(%]|h)", function(a, name, b)
        local ru = fn(name)
        return a .. (ru or name) .. b
    end))
end

local function resolveName(name)
    if CoARU_HasCyrillic and CoARU_HasCyrillic(name) then return nil end
    local ru = CoARU_ItemNameEN and CoARU_ItemNameEN[name]
    if not ru and CoARU_UNIT_N2R then ru = CoARU_UNIT_N2R[name] end
    if not ru and CoARU_SPELL_NAME_RU then ru = CoARU_SPELL_NAME_RU[name] end
    if ru and ru ~= name then return ru end
    return nil
end

local function unitRU(name)
    if CoARU_HasCyrillic and CoARU_HasCyrillic(name) then return nil end
    local ru = CoARU_UNIT_N2R and CoARU_UNIT_N2R[name]
    if not ru and CoARU_UnitN2R then ru = CoARU_UnitN2R(name) end
    if ru and ru ~= name then return ru end
    return nil
end

local PATTERNS = {

    { "^(.-)%(Level (%d+)%) has been killed by Suicide%.$",
      function(head, lvl)
          return ("%s(уровень %s) покончил с собой."):format(head, lvl)
      end },
    { "^(.-)%(Level (%d+)%) has been killed by (.+)%.$",
      function(head, lvl, killer)
          return ("%s(уровень %s) погибает от рук: %s."):format(head, lvl,
              unitRU(killer) or killer)
      end },
    { "^(.+) has unlocked all of their bank tabs by using their (.+)!$",
      function(who, what) return ("%s открывает все вкладки банка: %s!"):format(who, what) end },
    { "^(.+) has unlocked all of his bank tabs by using his (.+)!$",
      function(who, what) return ("%s открывает все вкладки банка: %s!"):format(who, what) end },
    { "^(.+) has unlocked all of her bank tabs by using her (.+)!$",
      function(who, what) return ("%s открывает все вкладки банка: %s!"):format(who, what) end },
    { "^(.+) has earned the achievement (.+)!$",
      function(who, ach) return ("%s получает достижение %s!"):format(who, ach) end },
    { "^(.+) has unlocked h[ie][sr] (.+)!$",
      function(who, what) return ("%s открывает: %s!"):format(who, what) end },
    { "^(.+) has unlocked their (.+)!$",
      function(who, what) return ("%s открывает: %s!"):format(who, what) end },
    { "^(.+) has completed the quest (.+)!$",
      function(who, q) return ("%s выполняет задание %s!"):format(who, q) end },
    { "^(.+) has reached level (%d+)!$",
      function(who, lvl) return ("%s достигает %s уровня!"):format(who, lvl) end },
    { "^(.+) has learned the (.+)!$",
      function(who, what) return ("%s изучает: %s!"):format(who, what) end },

    { "^(.-) used their (.+) to buff the zone with (.+)!$",
      function(head, item, buff)
          return ("%s применяет %s и усиливает зону: %s!"):format(head, item, buff)
      end },

    { "^(.-)The Crow's Treasure has been looted by (.+)$",
      function(head, who) return ("%sСокровище Ворона достается: %s"):format(head, who) end },

    { "^(.-)has ended, but unfortunately none survived!$",
      function(head) return ("%sзавершилось, и не выжил никто!"):format(head) end },
    { "^(.-)has ended!$",
      function(head) return ("%sзавершилось!"):format(head) end },

    { "^(.-)has spawned in (.+)!$",
      function(head, where) return ("%sпоявляется в зоне %s!"):format(head, where) end },

    { "^Server uptime: (.+)%.$",
      function(rest)
          local ru = rest:gsub("(%d+) Day%(s%)", "%1 дн.")
                         :gsub("(%d+) Hour%(s%)", "%1 ч.")
                         :gsub("(%d+) Minute%(s%)", "%1 мин.")
                         :gsub("(%d+) Second%(s%)", "%1 сек.")

          if ru:find("%(s%)") then return nil end
          return "Время работы сервера: " .. ru
      end },

    { "^%[SERVER%] Restart in (.-)%s*%-%s*Updates! (%d+)min downtime!$",
      function(left, mins)
          local ru = left:gsub("(%d+) Minute%(s%)", "%1 мин."):gsub("(%d+) Second%(s%)", "%1 сек.")
          if ru:find("%(s%)") then return nil end

          ru = ru:gsub("[%.%s]+$", "")
          return ("[SERVER] Перезапуск через %s. Обновления, простой %s мин."):format(ru, mins)
      end },

    { "^%[SERVER%] Restart in (.-)%s*%-%s*(.+)$",
      function(left, tail)
          local ru = left:gsub("(%d+) Minute%(s%)", "%1 мин."):gsub("(%d+) Second%(s%)", "%1 сек.")
          if ru:find("%(s%)") then return nil end
          ru = ru:gsub("[%.%s]+$", "")
          return ("[SERVER] Перезапуск через %s. %s"):format(ru, tail)
      end },

    { "^(.-)has completed their Trial!$",
      function(head) return ("%sзавершает испытание!"):format(head) end },

    { "^(.-)has died in (.+)!$",
      function(head, where) return ("%sпогибает в зоне %s!"):format(head, where) end },

    { "^(.-) has been captured by (.+)!$",
      function(head, who) return ("%s теперь у %s!"):format(head, who) end },

    { "^(|Huierror:|h.-)UI Error:(.-)an interface error occured%. Click here and send the error to a developer%.(|h)$",
      function(a, b, c)
          return ("%sОшибка интерфейса:%sнажмите здесь, чтобы отправить отчет разработчику.%s")
              :format(a, b, c)
      end },

    { "^(.-)|h%[You died%.%]|h(.*)$",
      function(a, b) return ("%s|h[Вы погибли.]|h%s"):format(a, b) end },

    { "^(.+) has selected Greed for: (.+)$",
      function(who, item) return ("Разыгрывается: %s. %s: «Не откажусь»."):format(item, who) end },
    { "^(.+) has selected Need for: (.+)$",
      function(who, item) return ("Разыгрывается: %s. %s: «Мне это нужно»."):format(item, who) end },
    { "^Greed Roll %- (%d+) for (.+) by (.+)$",
      function(n, item, who)
          return ("Результат броска %s («Не откажусь») за предмет %s: %s."):format(who, item, n)
      end },
    { "^Need Roll %- (%d+) for (.+) by (.+)$",
      function(n, item, who)
          return ("Результат броска %s («Нужно») за предмет %s: %s."):format(who, item, n)
      end },

    { "^Received (%d+) of item: (.+)%.$",
      function(n, item) return ("Вы получаете предмет: %sx%s."):format(item, n) end },

    { "^%[BAN%] (.+) has been permanently banned%. Reason: (.+)$",
      function(who, why) return ("[BAN] %s забанен навсегда. Причина: %s"):format(who, why) end },
    { "^%[BAN%] (.+) has been banned for (.+)%. Reason: (.+)$",
      function(who, term, why)
          return ("[BAN] %s забанен на %s. Причина: %s"):format(who, term, why)
      end },

    { "^Welcome to Ascension!$", function() return "Добро пожаловать в Ascension!" end },
}

local TIPS = {
    ["When you are low on Mystic Resources, Guardian of Time will offer you these resources in exchange for Marks of Ascension."] =
        "Когда мистических ресурсов мало, Guardian of Time обменяет их на «Marks of Ascension».",
    ["Please select a target."] = "Выберите цель.",

    ["Hello, at the Ethereal Recovery Services we help you correct tragic error.r"] =
        "Здравствуйте! Служба Ethereal Recovery Services поможет исправить трагическую ошибку.",
}

local function tipsRU(msg)
    local head, body = msg:match("^(.-Tips & Tricks: )(.+)$")
    if not head then return nil end
    local tail = ""
    if body:sub(-2) == "|r" then tail = "|r"; body = body:sub(1, -3) end
    local ru = TIPS[body]
    if not ru then return nil end
    return head .. ru .. tail
end

local FIXED = {
    ["You are not in a guild."] = "Вы не состоите в гильдии.",

    ["You have unspent Ability Essence!"] = "У вас остались нераспределенные Ability Essence!",
    ["You have unspent Talent Essence!"] = "У вас остались нераспределенные Talent Essence!",

    ["You can recover items you have lost, characters deleted, items you've vendored and much, much morer"] =
        "Вы можете вернуть потерянные предметы, удаленных персонажей, проданные торговцу вещи и многое, многое другое",
    ["For the small price. . |r"] = "За небольшую плату. . |r",
    ["Transfers from Voljin to Rexxar are now live on the website!"] =
        "Перенос персонажей с Voljin на Rexxar открыт на сайте!",
}

local ANNOUNCE = {
    ['The "char list" command was removed. You can activate and deactivate characters on your character selection screen!'] =
        'Команда «char list» убрана. Включать и отключать персонажей теперь можно прямо на экране выбора персонажа!',
    ['Over 1,800 hidden treasures scattered across Azeroth! Venture off the beaten path to discover Worldforged gear tucked away in forgotten caves, ancient towers, and remote corners of the world. Treasure Spoils and Adventure awaits the bold!'] =
        'По Азероту разбросано больше 1800 тайников! Сойдите с торной тропы: снаряжение Worldforged спрятано в забытых пещерах, древних башнях и глухих углах мира. Смелых ждут добыча и приключения!',
    ['Group Experience Rates are boosted and Quest Items are shared to all party members! Grouping up together will allow you to progress together and have friends to enjoy the journey.'] =
        'В группе опыт идет быстрее, а предметы заданий достаются всем участникам! Вместе вы продвигаетесь дальше, и дорога веселее.',
    ["Every creature drops the exact gear they're wearing with matching stats! Want spell power? Slay casters. Need defense? Take down armored warriors with shields. The gear has the stats you'd expect from that creature type, letting you look EXACTLY like the enemies you defeat!"] =
        'С каждого существа падает ровно то снаряжение, которое на нем надето, и с теми же характеристиками! Нужна сила заклинаний? Бейте заклинателей. Нужна защита? Валите бронированных воинов со щитами. Характеристики вещи соответствуют типу существа, так что вы можете выглядеть В ТОЧНОСТИ как побежденные враги!',
    ['You can queue for Battlegrounds and Dungeons at the same time on Ascension!'] =
        'На Ascension можно одновременно стоять в очереди на поля сражений и в подземелья!',
    ['Crafting on Ascension has been overhauled! Every crafted item gains bonus affix stats and you can upgrade ALL crafted gear by using crafting upgrade kits taught from trainers!'] =
        'Ремесло на Ascension переработано! Каждая созданная вещь получает дополнительные характеристики от аффиксов, а ЛЮБОЕ созданное снаряжение улучшается наборами для улучшения, которым учат тренеры!',
    ["Mystic Runes and Mystic Orbs can be used to Reroll Enchants on your Items at a Mystic Enchanting Altar. If you don't have Mystic Runes or Mystic Orbs, you can use gold instead!"] =
        'Мистические руны и мистические сферы перебрасывают зачарования на ваших вещах у алтаря мистического зачарования. Нет ни рун, ни сфер? Можно заплатить золотом!',
    ["If you're experiencing FPS issues or lag, Third-Party Addons are the primary cause of these issues. Try updating your addons on the launcher or disabling them."] =
        'Если у вас падает частота кадров или идут лаги, главная причина этого сторонние аддоны. Обновите их в лаунчере или отключите.',
    ['If you are experiencing FPS drops, try toggling Hardware Cursor in video settings. A recent Nvidia driver update caused this issue.'] =
        'Если частота кадров падает, попробуйте переключить аппаратный курсор в настройках графики. Причина в недавнем обновлении драйверов Nvidia.',
    ['Looking for a place to enable or disable level scaling? The Destiny Weaver can help you, located in Capital City Banks and starting areas. Ask a guard for directions!'] =
        'Ищете, где включить или выключить масштабирование уровней? Вам поможет Destiny Weaver: он стоит в банках столиц и в стартовых зонах. Дорогу спросите у стражника!',
    ['Testing of Wrath of the Lich King is underway! If you want access to WOTLK Alpha you can buy a Northrend Travel Guide from players or grab the Wotlk Alpha Bundle from the Ascension Store!'] =
        'Идет тестирование Wrath of the Lich King! Чтобы получить доступ к альфе WOTLK, купите «Northrend Travel Guide» у игроков или возьмите «Wotlk Alpha Bundle» в магазине Ascension.',
    ['Keep up with the latest news, changes and events by following us on Facebook: https://facebook.com/OfficialAscension - X: https://x.com/AscensionFeed - Discord: https://discord.gg/classless'] =
        'Свежие новости, изменения и события: Facebook https://facebook.com/OfficialAscension, X https://x.com/AscensionFeed, Discord https://discord.gg/classless',

    ['Did you know that you can now join our discord by clicking this chat link? Join and chat with the community! |Hdiscord:mm6YC9zpqV|h[Discord: Ascension]|h'] =
        'Знаете ли вы, что теперь в наш Discord можно зайти прямо по ссылке в чате? Заходите и общайтесь с сообществом! |cff5865f2|Hdiscord:mm6YC9zpqV|h[Discord: Ascension]|h|r',

    ["|Hdiscord:2AVAEzpWgr|h[Newcomer's Corner]|h Looking for some answers? Join The Ascension discord and read through our Newcomer's Corner guides and frequently asked questions! |Hdiscord:2AVAEzpWgr|h[Discord: Newcomer's FAQ]|h"] =
        "|Hdiscord:2AVAEzpWgr|h[Newcomer's Corner]|h Ищете ответы? Загляните в Discord Ascension и почитайте руководства раздела Newcomer's Corner и ответы на частые вопросы! |Hdiscord:2AVAEzpWgr|h[Discord: Newcomer's FAQ]|h",

    ['To join the discord go to https://ascension.gg/user/discord OR join directly at discord.gg/ascensiondisc'] =
        'Зайти в наш Discord можно по ссылке https://ascension.gg/user/discord или напрямую discord.gg/ascensiondisc',
    ["Did you know all quest drops are shared in parties and you lose significantly less experience for grouping on Ascension? It's always worth questing and leveling with friends!"] =
        'Знаете ли вы, что на Ascension добыча с заданий общая для всей группы, а опыта за игру в группе теряется заметно меньше? Проходить задания и качаться с друзьями всегда выгодно!',

    ['Need a break? Rested Experience accumulates much faster on Ascension. Resting in an inn for 15 minutes will grant you a small experience boost for 2 hours! Safe Travels!'] =
        'Нужен перерыв? Отдых на Ascension копится гораздо быстрее. Отдохните на постоялом дворе 15 минут и получите небольшую прибавку к опыту на 2 часа. Доброго пути!',
}

local function lastPlain(s, needle)
    local last, i = nil, 1
    while true do
        local a, b = s:find(needle, i, true)
        if not a then break end
        last, i = b, a + 1
    end
    return last
end

local function announceKey(s)
    return (s:gsub("|[cC]%x%x%x%x%x%x%x%x", ""):gsub("|[rR]", "")
             :gsub("|T.-|t", ""):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", ""))
end

local function announceRU(msg)
    if not msg:find("Autobroadcast", 1, true) then return nil end
    local cut = select(2, msg:find("]: ", 1, true))
    if not cut then return nil end

    local icon = lastPlain(msg, "|t ")
    if icon and icon > cut then cut = icon end
    local head, body = msg:sub(1, cut), msg:sub(cut + 1)

    local tail = ""
    if body:sub(-2) == "|r" then tail = "|r"; body = body:sub(1, -3) end

    local c = body:match("^|[cC]%x%x%x%x%x%x%x%x")
    if c then head, body = head .. c, body:sub(#c + 1) end
    local ru = ANNOUNCE[announceKey(body)]
    if not ru then return nil end
    return head .. ru .. tail
end

function CoARU_BroadcastRU(msg)
    if not msg or msg == "" then return nil end
    if CoARU_HasCyrillic and CoARU_HasCyrillic(msg) then return nil end

    local fixed = announceRU(msg)
    if fixed then return fixed end
    if FIXED[msg] then return FIXED[msg] end
    local tip = tipsRU(msg)
    if tip then return tip end

    local s = linkText(msg, resolveName)
    for i = 1, #PATTERNS do
        local pat, build = PATTERNS[i][1], PATTERNS[i][2]
        local a, b, c, d = s:match(pat)
        if a then
            local ok, ru = pcall(build, a, b, c, d)
            if ok and ru and ru ~= "" then return ru end
        end
    end

    if s ~= msg then return s, true end
    return nil
end

local EVENTS = {
    "CHAT_MSG_SYSTEM",
    "CHAT_MSG_ACHIEVEMENT",
    "CHAT_MSG_GUILD_ACHIEVEMENT",
    "CHAT_MSG_LOOT",
    "CHAT_MSG_BG_SYSTEM_NEUTRAL",
    "CHAT_MSG_BG_SYSTEM_ALLIANCE",
    "CHAT_MSG_BG_SYSTEM_HORDE",
}

local RAW_CAP = 60

local function noteRaw(event, msg)
    if not CoARU_DB then return end
    CoARU_DB.bcraw = CoARU_DB.bcraw or {}
    local t = CoARU_DB.bcraw
    if #t >= RAW_CAP then return end
    t[#t + 1] = tostring(event) .. "\t" .. msg
end

local function filter(_frame, event, msg, ...)
    if not broadcastOn() then return false end
    local ru, partial = CoARU_BroadcastRU(msg)
    if ru and not partial then
        return false, ru, ...
    end

    if msg and #msg > 12 and CoARU_NoteMiss
        and not (CoARU_HasCyrillic and CoARU_HasCyrillic(msg)) then
        CoARU_NoteMiss("broadcast", msg, event)
        noteRaw(event, msg)
    end
    if ru then return false, ru, ... end
    return false
end

CoARU_BroadcastFilter = filter

if type(ChatFrame_AddMessageEventFilter) == "function" then
    for i = 1, #EVENTS do
        ChatFrame_AddMessageEventFilter(EVENTS[i], filter)
    end
end
