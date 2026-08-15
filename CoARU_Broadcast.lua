local function broadcastOn()
    return not CoARU_ModOn or CoARU_ModOn("speech")
end

local function linkText(s, fn)
    return (s:gsub("(|H(.-)|h%[)([^%]]+)(%]|h)", function(a, spec, name, b)
        local ru = fn(name, spec)
        return a .. (ru or name) .. b
    end))
end

local function resolveName(name, spec)
    if CoARU_HasCyrillic and CoARU_HasCyrillic(name) then return nil end

    local ru = (spec and CoARU_ItemLinkNameRU) and CoARU_ItemLinkNameRU(spec, name) or nil
    if not ru then ru = CoARU_ItemNameEN and CoARU_ItemNameEN[name] end
    if not ru and CoARU_UNIT_N2R then ru = CoARU_UNIT_N2R[name] end
    if not ru and CoARU_SPELL_NAME_RU then ru = CoARU_SPELL_NAME_RU[name] end

    if not ru and CoARU_ASCUI then ru = CoARU_ASCUI[name] end
    if ru and ru ~= name then return ru end
    return nil
end

local LODE_KIND = {
    Mining = "горная", Herbalism = "травяная", Skinning = "звериная", Fishing = "рыбная",
    Woodcutting = "лесная", Bushcraft = "лесная",
}

local LODE_RISK = {
    ["(No Risk)"] = "(без риска)",
    ["(High Risk)"] = "(высокий риск)",
    ["(Low Risk)"] = "(низкий риск)",
}

local function lotteryRU(name)
    local ru = CoARU_ITEM_NAME_RU and CoARU_ITEM_NAME_RU[name]
    if not ru and CoARU_SPELL_NAME_RU then ru = CoARU_SPELL_NAME_RU[name] end
    if ru and ru ~= "" and ru ~= name then return ru end
    return name
end

local function namesRU(text)
    if type(text) ~= "string" or text == "" then return text end
    if not CoARU_LocalizeNames then return text end
    local ok, out = pcall(CoARU_LocalizeNames, text)
    if ok and out and out ~= "" then return out end
    return text
end

local function zoneRU(name)
    if type(name) ~= "string" or name == "" then return nil end
    if CoARU_HasCyrillic and CoARU_HasCyrillic(name) then return nil end
    local ru = CoARU_ZONE and CoARU_ZONE[name]
    if not ru and CoARU_ZONE_INST then ru = CoARU_ZONE_INST[name] end
    if ru and ru ~= "" and ru ~= name then return ru end
    return nil
end

local function unitRU(name)
    if CoARU_HasCyrillic and CoARU_HasCyrillic(name) then return nil end
    local ru = CoARU_UNIT_N2R and CoARU_UNIT_N2R[name]
    if not ru and CoARU_UnitN2R then ru = CoARU_UnitN2R(name) end
    if ru and ru ~= name then return ru end
    return nil
end

local BG_NODE = {
    ["mine"] = "Рудник",
    ["blacksmith"] = "Кузница",
    ["lumber mill"] = "Лесопилка",
    ["farm"] = "Ферма",
    ["stables"] = "Стойла",
}
local BG_SIDE = { ["Alliance"] = "Альянса", ["Horde"] = "Орды" }
local BG_SIDE_NOM = { ["Alliance"] = "Альянс", ["Horde"] = "Орда" }
local BG_TIME = { ["1 minute"] = "1 минуту" }
local LOCK_DIFF = { ["Normal"] = "обычный", ["Heroic"] = "героический", ["Mythic"] = "эпохальный" }

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
      function(head, who) return ("%sСокровище воронов достается: %s"):format(head, who) end },

    { "^(.-)has ended, but unfortunately none survived!$",
      function(head) return ("%sзавершилось, и не выжил никто!"):format(head) end },
    { "^(.-)has ended!$",
      function(head) return ("%sзавершилось!"):format(head) end },

    { "^(.-)has spawned in (.+)!$",
      function(head, where) return ("%sпоявляется в зоне %s!"):format(head, where) end },

    { "^Server uptime: (.+)$",
      function(rest)
          rest = rest:gsub("%.%s*$", "")
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
      function(head, where)
          local place, mode = where:match("^(.-)%s*(%(.+%))$")
          local ru = zoneRU(place or where)
          if ru then where = ru .. (mode and (" " .. mode) or "") end
          return ("%sпогибает в зоне %s!"):format(head, where)
      end },

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

    { "^(.+) has assaulted the (.+)$",
      function(who, node)
          local ru = BG_NODE[node]
          if not ru then return nil end
          return ("%s: атакует %s"):format(ru, who)
      end },
    { "^(.+) has defended the (.+)$",
      function(who, node)
          local ru = BG_NODE[node]
          if not ru then return nil end
          return ("%s: защищает %s"):format(ru, who)
      end },

    { "^(.+) claims the (.+)! If left unchallenged, the (.+) will control it in (.+)!$",
      function(who, node, side, when)
          local ru, sd = BG_NODE[node], BG_SIDE[side]
          if not (ru and sd) then return nil end
          return ("%s: захватывает %s. Если не помешать, через %s точка перейдет под контроль %s!")
              :format(ru, who, BG_TIME[when] or when, sd)
      end },
    { "^The (.+) has taken the (.+)$",
      function(side, node)
          local ru, sd = BG_NODE[node], BG_SIDE[side]
          if not (ru and sd) then return nil end
          return ("%s: под контролем %s"):format(ru, sd)
      end },

    { "^(.+) has been taken by the (.+)!$",
      function(place, side)
          local sd = BG_SIDE[side]
          if not sd then return nil end
          local ru = zoneRU(place) or zoneRU((place:gsub("^The ", "")))
          return ("%s: под контролем %s!"):format(ru or place, sd)
      end },
    { "^The (.+) has gathered (%d+) resources, and is near victory!$",
      function(side, n)
          local sd = BG_SIDE_NOM[side]
          if not sd then return nil end
          return ("%s набирает %s ед. ресурсов и близок к победе!"):format(sd, n)
      end },
    { "^The (.+) wins!$",
      function(side)
          local sd = BG_SIDE_NOM[side]
          if not sd then return nil end
          return ("Побеждает %s!"):format(sd)
      end },

    { "^The Battle for (.+) begins in (%d+) seconds%. Prepare yourselves!$",
      function(place, n)
          return ("%s: битва начнется через %s сек. Готовьтесь!"):format(zoneRU(place) or place, n)
      end },

    { "^(%s*%[Criminal Intent%]%s*)(.+) has slain (.+) near you at (.+)!$",
      function(head, who, whom, where)
          return ("%s%s убивает игрока %s рядом с вами: %s!")
              :format(head, who, whom, zoneRU(where) or where)
      end },
    { "^(%s*%[Honorable Combat%]%s*)You have entered an Honorable Combat Zone%.$",
      function(head) return head .. "Вы вошли в зону честного боя." end },
    { "^(%s*%[Honorable Combat%]%s*)You have exited an Honorable Combat Zone%.$",
      function(head) return head .. "Вы вышли из зоны честного боя." end },
    { "^(%s*%[Honorable Combat%]%s*)You have been engaged by (.+)%.$",
      function(head, who) return ("%sВас вызывает на бой %s."):format(head, who) end },
    { "^(%s*%[Honorable Combat%]%s*)You have engaged (.+)%.$",
      function(head, who) return ("%sВы вызвали на бой %s."):format(head, who) end },
    { "^(%s*%[Honorable Combat%]%s*)You have been slain by (.+)%. They must wait (%d+) seconds before attacking you again!$",
      function(head, who, n)
          return ("%sВас убивает %s. Следующее нападение на вас возможно через %s сек.!")
              :format(head, who, n)
      end },
    { "^(%s*%[Honorable Combat%]%s*)You have slain (.+)%. You must wait (%d+) seconds before attacking again!$",
      function(head, who, n)
          return ("%sВы убиваете игрока %s. Следующее нападение возможно через %s сек.!")
              :format(head, who, n)
      end },
    { "^(%s*%[Honorable Combat%]%s*)with (.+) has expired!$",
      function(head, who) return ("%sбой с %s окончен!"):format(head, who) end },

    { "^(%s*%[High%-Risk%] %[Crow's Cache%]%s*)The Crow's Treasure has begun to materialize near (.+)! It will completely manifest in (.+)%. Consult your map for its location!$",
      function(head, where, when)
          local a, b = where:match("^(.-) %- (.+)$")
          if a then where = (zoneRU(a) or a) .. " - " .. (zoneRU(b) or b) end
          local w = (when:gsub("(%d+) minutes", "%1 мин."):gsub("(%d+) minute", "%1 мин."))
          local dot = w:sub(-1) == "." and "" or "."
          return ("%sСокровище воронов начало проявляться: %s! Полностью проявится через %s%s Смотрите карту!")
              :format(head, where, w, dot)
      end },
    { "^(%s*%[High%-Risk%] %[Crow's Cache%]%s*)The Crow's Treasure has materialized! Consult your map for it's location%.$",
      function(head) return head .. "Сокровище воронов проявилось! Смотрите карту." end },

    { "^(.+) %((%a+)%) Loot Lockouts:$",
      function(place, diff)
          local d = LOCK_DIFF[diff]
          if not d then return nil end
          return ("%s (%s): блокировки добычи"):format(zoneRU(place) or place, d)
      end },
    { "^>> No loot lockouts for this map and difficulty%.$",
      function() return ">> Блокировок добычи для этой карты и сложности нет." end },

    { "^>> (.+)$", function(rest) return ">> " .. rest end },

    { "^%[SERVER%] %[The Motherlode%] A (%a+) Motherlode (%b()) has appeared in (.+)%. Requires level (%d+)%.$",
      function(prof, mode, where, lvl)
          local kind = LODE_KIND[prof] or prof

          local risk = LODE_RISK[mode] or mode
          return ("[СЕРВЕР] [Жила] В зоне «%s» появилась %s жила %s. Требуется уровень %s.")
              :format(zoneRU(where) or where, kind, risk, lvl)
      end },
    { "^%[SERVER%] %[Lottery%] %- (.+) ends in (%d+) hours?%.$",
      function(what, n)
          return ("[СЕРВЕР] [Лотерея] %s заканчивается через %s ч."):format(lotteryRU(what), n)
      end },
    { "^%[SERVER%] %[Lottery%] %- (.+) ends in (%d+) minutes?%.$",
      function(what, n)
          return ("[СЕРВЕР] [Лотерея] %s заканчивается через %s мин."):format(lotteryRU(what), n)
      end },

    { "^You can now pick your first talents!$",
      function() return "Теперь вы можете выбрать первые таланты!" end },
    { "^You are getting more Ability Essence now%.$",
      function() return "Теперь вы получаете больше Ability Essence." end },

    { "^The Horde [Ff]lag was picked up by (.+)!$",
      function(who) return ("Флаг Орды в руках у %s!"):format(who) end },
    { "^The Alliance [Ff]lag was picked up by (.+)!$",
      function(who) return ("Флаг Альянса в руках у %s!"):format(who) end },
    { "^The Horde [Ff]lag was dropped by (.+)!$",
      function(who) return ("Флаг Орды выронен: %s!"):format(who) end },
    { "^The Alliance [Ff]lag was dropped by (.+)!$",
      function(who) return ("Флаг Альянса выронен: %s!"):format(who) end },
    { "^The Horde [Ff]lag was returned to its base by (.+)!$",
      function(who) return ("Флаг Орды возвращен на базу: %s!"):format(who) end },
    { "^The Alliance [Ff]lag was returned to its base by (.+)!$",
      function(who) return ("Флаг Альянса возвращен на базу: %s!"):format(who) end },
    { "^(.+) captured the Horde [Ff]lag!$",
      function(who) return ("Флаг Орды захвачен: %s!"):format(who) end },
    { "^(.+) captured the Alliance [Ff]lag!$",
      function(who) return ("Флаг Альянса захвачен: %s!"):format(who) end },
    { "^(.+) has taken the flag!$",
      function(who) return ("Флаг взят: %s!"):format(who) end },
    { "^The flag has been dropped%.$", function() return "Флаг выронен." end },
    { "^The flag has been returned%.$", function() return "Флаг возвращен на базу." end },

    { "^The [Bb]attle for (.+) begins in (%d+) minutes?%.$",
      function(where, n)
          return ("Битва за %s начнется через %s мин."):format(zoneRU(where) or where, n)
      end },
    { "^The [Bb]attle for (.+) begins in (%d+) seconds?%.$",
      function(where, n)
          return ("Битва за %s начнется через %s сек."):format(zoneRU(where) or where, n)
      end },
    { "^The [Bb]attle for (.+) has begun!$",
      function(where) return ("Битва за %s началась!"):format(zoneRU(where) or where) end },

    { "^PvE Mode has been removed because you joined a Battleground%.$",
      function() return "Режим PvE снят: вы вошли на поле боя." end },
    { "^PvE Mode has been removed because you joined an Arena%.$",
      function() return "Режим PvE снят: вы вошли на арену." end },
    { "^(.+) has fled from (.+) in a duel$",
      function(a, b) return ("%s сбегает с дуэли против %s"):format(a, b) end },

    { "^You gained (%d+) Glory for winning a battleground%. (%d+) Glory needed to reach the next rank%.$",
      function(n, need)
          return ("Вы получаете %s ед. славы за победу на поле боя. До следующего звания: %s.")
              :format(n, need)
      end },
    { "^You gained (%d+) Glory for an honorable kill%. (%d+) Glory needed to reach the next rank%.$",
      function(n, need)
          return ("Вы получаете %s ед. славы за честное убийство. До следующего звания: %s.")
              :format(n, need)
      end },
    { "^You gained (%d+) Glory%. (%d+) Glory needed to reach the next rank%.$",
      function(n, need)
          return ("Вы получаете %s ед. славы. До следующего звания: %s."):format(n, need)
      end },
    { "^You've received (%d+) Arena Points%. Current Points: %((%d+)%) Cap: %((%d+)/(%d+)%)$",
      function(n, cur, cap, total)
          return ("Вы получаете %s очков арены. Сейчас: (%s). Предел: (%s/%s)")
              :format(n, cur, cap, total)
      end },
    { "^You have (%d+) unspent Ability Essence%.$",
      function(n) return ("У вас %s нераспределенных Ability Essence."):format(n) end },
    { "^You've successfully changed to Specialization (.+)%.$",
      function(n) return ("Вы перешли на специализацию %s."):format(n) end },
}

local TIPS = {

    ["You queued for LFG as a tank! Make sure to use Bear Form, Defensive Stance, or Righteous Fury!"] =
        'Вы встали в очередь как танк! Не забудьте включить «Bear Form», «Defensive Stance» или «Righteous Fury»!',
    ["You've entered a battlegrounds, but you dont have much PvP power. Increasing your PvP power will increase the damage you deal to others. You can obtain items by searching PvP on the Auction House, or visiting an Honor NPC in capital cities. Ask a guard to mark the location on your map!"] =
        'Вы вошли на поле боя, но силы PvP у вас маловато. Чем она выше, тем больше урона вы наносите другим игрокам. Вещи ищите по запросу PvP на аукционе или у торговца за честь в столице: спросите стражника, и он отметит место на карте!',
    ["As a Starcaller, you will find strength in your mana pool. Try using Starsunder or Huntress Shot to quickly expend mana to devastate your foes and then cast Lunar Shock to consume Scattered Stars and quickly regain your mana."] =
        'Сила Starcaller в запасе маны. Тратьте ее «Starsunder» или «Huntress Shot», чтобы крушить врагов, а потом читайте «Lunar Shock»: он поглощает «Scattered Stars» и быстро возвращает ману.',
    ["You've obtained a Mystic Enchanting Altar! Mystic Runes are used to reroll a Mystic Scroll, and gain progress towards an Extract. Extracting an enchant from a Mystic Scroll will consume it, saving it to your collection. Orbs are used to apply enchants from your collection to your Active Enchants!"] =
        'У вас появился «Mystic Enchanting Altar»! Мистические руны перебрасывают мистический свиток и приближают извлечение. Извлечение зачарования тратит свиток, но сохраняет зачарование в вашу коллекцию. Сферы переносят зачарования из коллекции в активные!',
    ["You have acquired your second Aspect. Switching between Aspects can be key for unlocking your true potential."] =
        'Вы получили второй «Aspect». Переключение между ними бывает ключом к вашему настоящему потенциалу.',
    ["Your Infernal Strike ability generates Demonfire! Other spells consume these stacks for increased effectiveness."] =
        'Способность «Infernal Strike» дает «Demonfire»! Другие заклинания тратят эти заряды и работают сильнее.',

    ["When you are low on Mystic Resources, Guardian of Time will offer you these resources in exchange for Marks of Ascension."] =
        "Когда мистических ресурсов мало, Guardian of Time обменяет их на «Marks of Ascension».",
    ["Please select a target."] = "Выберите цель.",

    ["Any mail sent or received from your guildmates is instant! Just one of the many advantages of collaboration."] =
        "Почта между согильдийцами приходит мгновенно. Одно из многих преимуществ игры сообща.",
    ["The last boss of Blackrock Depths - Prison is the Ring of Law!"] =
        "Последний босс подземелья Blackrock Depths - Prison это Ring of Law!",
    ["You can reset your instances by right clicking your character portrait and selecting reset all instances. This also allows you to reset heroic and mythic vanilla dungeon!"] =
        "Подземелья сбрасываются щелчком правой кнопки по портрету персонажа и выбором сброса всех подземелий. Так же сбрасываются героические и эпохальные подземелья классической игры.",

    ["Guardian of Time is the bearer of the Path to Ascension quest chain. This main quest will take you on a journey to explore the different parts of Ascension and grant you amazing rewards!"] =
        "Guardian of Time ведет цепочку заданий «Путь к Вознесению». Это основное задание проведет вас по разным сторонам Ascension и даст щедрые награды!",

    ["Chromie allows you to access various time related activities such as Timewalking and Prestige (Converting your character back to level 1."] =
        "Chromie открывает дела, связанные со временем: путешествие во времени и престиж (возврат персонажа на 1-й уровень).",

    ["Hello, at the Ethereal Recovery Services we help you correct tragic error.r"] =
        "Здравствуйте! Служба Ethereal Recovery Services поможет исправить трагическую ошибку.",
}

local function tipsRU(msg)
    local head, body = msg:match("^(.-)Tips & Tricks: (.+)$")
    if not head then return nil end
    head = head .. "Советы и хитрости: "
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

    ["You haven't unlocked your Realm Bank! You can unlock it with a Realm Bank Voucher from the Auction House or Shop!"] =
        "Realm Bank еще не открыт! Открыть его можно с помощью Realm Bank Voucher с аукциона или из магазина!",

    ["You haven't unlocked your Personal Bank! You can unlock it with a Personal Bank Voucher from the Auction House or Shop!"] =
        "Personal Bank еще не открыт! Открыть его можно с помощью Personal Bank Voucher с аукциона или из магазина!",
    ["You don't own a Personal Bank."] = "У вас нет Personal Bank.",
    ["Please relog to load your Personal Bank!"] =
        "Перезайдите в игру, чтобы загрузить Personal Bank!",
    ["Please relog in order to use your personal bank storage!"] =
        "Перезайдите в игру, чтобы пользоваться личным банком!",
    ["Level Scaling has been enabled."] = "Масштабирование уровней включено.",
    ["Level Scaling has been disabled."] = "Масштабирование уровней выключено.",
    ["You cannot slot a normal card into a golden slot!"] =
        "Обычную карту нельзя вставить в золотой слот!",
    ["You do not know how to tame a pet."] = "Вы не умеете приручать питомцев.",
    ["You received the following rewards for helping new players:"] =
        "За помощь новичкам вы получаете:",
    ["You must be standing in the center of the First-Class Experimental Teleporter to use it!"] =
        "Чтобы воспользоваться «First-Class Experimental Teleporter», встаньте в его центр!",
    ["You haven't allocated your primary stat. Go to the top right of your Character Advancement and pick between Strength, Agility, Duality, Intellect or Healing."] =
        "Основная характеристика не выбрана. Откройте развитие персонажа и выберите в правом верхнем углу силу, ловкость, двойственность, интеллект или исцеление.",
    ["Done flushing Arena points."] = "Начисление очков арены завершено.",
    ["Flushing Arena points based on team ratings, this may take a few minutes. Please stand by..."] =
        "Идет начисление очков арены по рейтингам команд, это займет несколько минут. Подождите...",
    ["LFG System: You were ineligible for the luck of the draw buff because you didn't select a random dungeon."] =
        "Система поиска группы: положительный эффект за случайное подземелье не начислен, потому что подземелье выбрано вручную.",
}

local ANNOUNCE = {
    ["Have questions about different aspects of Ascension? We post feature videos on our youtube that dive into the nitty gritty of every system. Just search for 'Ascension Features: And the feature you're looking to learn more about on youtube."] =
        'Есть вопросы о том, как устроен Ascension? На нашем youtube выходят ролики, разбирающие каждую систему до мелочей. Ищите «Ascension Features:» и название того, о чем хотите узнать.',

    ['The "char list" command was removed. You can activate and deactivate characters on your character selection screen!'] =
        'Команда «char list» убрана. Включать и отключать персонажей теперь можно прямо на экране выбора персонажа!',
    ['Over 1,800 hidden treasures scattered across Azeroth! Venture off the beaten path to discover Worldforged gear tucked away in forgotten caves, ancient towers, and remote corners of the world. Treasure Spoils and Adventure awaits the bold!'] =
        'По Азероту разбросано больше 1800 тайников! Сойдите с торной тропы: снаряжение, выкованное миром, спрятано в забытых пещерах, древних башнях и глухих углах мира. Смелых ждут добыча и приключения!',
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

    ['Honorable Combat Zones are places where you can engage in 1v1 Combat, no strings attached. Ashenvale, Desolace, Feralas are all Honorable Combat zones when in High-Risk. Winterspring is always an Honorable Combat zone.'] =
        'Зоны честного боя это места, где можно драться один на один без последствий. Ясеневый лес, Пустоши и Фералас становятся зонами честного боя в режиме высокого риска. Зимние Ключи остаются такой зоной всегда.',
    ['You can submit bugs on the bugtracker! Visit https://ascension.gg/bugtracker or Bugtracker on the Launcher. Searching for an existing report and upvoting/commenting will help us prioritize bugs affecting the most people. Avoid submitting bugs in GM tickets, as these will take longer to reach the bugtracker.'] =
        'Об ошибках можно сообщать в багтрекер: https://ascension.gg/bugtracker или кнопка Bugtracker в лаунчере. Найдите похожий отчет и поддержите его голосом или комментарием, так мы быстрее возьмемся за самые массовые ошибки. Через обращения к GM отчет идет дольше.',
    ['Stumbled across a bug? Report it to the bugtracker on the Ascension Launcher, or https://ascension.gg/bugtracker This helps us squash the bug as fast as possible, and makes sure no information gets lost in translation if it were posted to a ticket.'] =
        'Наткнулись на ошибку? Сообщите о ней через багтрекер в лаунчере Ascension или на https://ascension.gg/bugtracker Так мы починим ее быстрее, и ничего не потеряется по дороге, как бывает с обращениями.',
    ['Make sure you have access to the recovery email on your account in case you ever need to reset your password!'] =
        'Проверьте, что у вас есть доступ к почте для восстановления: она понадобится, если придется менять пароль.',

    ['Heroes! Have any questions about Ascension? Check out our Wiki which features over hundreds of different articles! https://project-ascension.fandom.com/wiki/Home'] =
        'Герои! Есть вопросы об Ascension? Загляните в нашу вики: там сотни статей. https://project-ascension.fandom.com/wiki/Home',
    ['When making a ticket in any language other than English. Write the language of your ticket at the beginning. This helps us sort your request and service you faster!'] =
        'Пишете обращение не на английском? Укажите язык в самом начале. Так мы быстрее разберем обращение и ответим!',

    ['You can Transmog your items in any capital city. Transmogrifying them allows them to take the appearance of any other item from the world or our cosmetic shop. For each item you transmogrify you will need a rune of transmogrification. You can obtain them in capitial cities, The Mage Tower in Stormwind City and the Drag of Orgrimmar!'] =
        'Вещи можно преобразить (Transmog) в любой столице: вещь принимает вид любой другой вещи из мира или из магазина обликов. На каждое преображение нужна руна преображения: их продают в столицах, в Башне Магов Штормграда и в Волоке Оргриммара!',
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

    local guard, tookLabel, peeled = 0, false, ""
    while guard < 8 do
        guard = guard + 1
        local lead, rest = body:match("^(%s*|[cC]%x%x%x%x%x%x%x%x)(.*)$")
        if not lead then lead, rest = body:match("^(%s*|[rR])(.*)$") end
        if not lead and not tookLabel then
            lead, rest = body:match("^(%s*|H.-|h%b[]|h%s*)(.*)$")
            if not lead then lead, rest = body:match("^(%s*%b[]%s*)(.*)$") end
            if lead then tookLabel = true end
        end
        if not lead or rest == "" then break end
        head, body, peeled = head .. lead, rest, peeled .. lead
    end

    local gap = body:match("^%s+")
    if gap then head, body, peeled = head .. gap, body:sub(#gap + 1), peeled .. gap end

    local tail = ""
    if body:sub(-2) == "|r" then tail = "|r"; body = body:sub(1, -3) end

    local c = body:match("^|[cC]%x%x%x%x%x%x%x%x")
    if c then head, body = head .. c, body:sub(#c + 1) end

    local key = announceKey(body)
    local ru = ANNOUNCE[key] or FIXED[key]
    if not ru and peeled ~= "" then

        local k2 = announceKey(peeled .. body)
        ru = ANNOUNCE[k2] or FIXED[k2]
        if ru then head = head:sub(1, #head - #peeled) end
    end
    if not ru then return nil end
    return head .. ru .. tail
end

local MODE_LABELS = {
    ["[Ascension Autobroadcast]"] = "[Объявление Ascension]",
    ["[Criminal Intent]"]         = "[Преступный умысел]",
    ["[High-Risk]"]               = "[Высокий риск]",
    ["[Honorable Combat]"]        = "[Честный бой]",
    ["[Crow's Cache]"]            = "[Сокровище воронов]",

    ["[Worldforged]"]             = "[Выкованный миром]",
    ["[Immersive Gear Drops]"]    = "[Снаряжение с врага]",
    ["[Crafting Overhaul]"]       = "[Ремесло переработано]",
    ["[Level Scaling]"]           = "[Масштабирование уровней]",
    ["[Group Up!]"]               = "[Собирайтесь в группы!]",
    ["[Resting]"]                 = "[Отдых]",
}

local MODE_PAREN = {
    ["(No Risk)"]    = "(без риска)",
    ["(High Risk)"]  = "(высокий риск)",
    ["(High-Risk)"]  = "(высокий риск)",
}

local function replaceAll(s, from, to)
    local pos = 1
    while true do
        local a = s:find(from, pos, true)
        if not a then return s end
        s = s:sub(1, a - 1) .. to .. s:sub(a + #from)
        pos = a + #to
    end
end

local function modeLabels(ru)
    if not ru then return ru end
    if ru:find("[", 1, true) then
        for en, rep in pairs(MODE_LABELS) do
            ru = replaceAll(ru, en, rep)
        end
    end

    if ru:find("(", 1, true) then
        for en, rep in pairs(MODE_PAREN) do
            ru = replaceAll(ru, en, rep)
        end
    end
    return ru
end

function CoARU_BroadcastRU(msg)
    if not msg or msg == "" then return nil end
    if CoARU_HasCyrillic and CoARU_HasCyrillic(msg) then return nil end

    local fixed = announceRU(msg)
    if fixed then return namesRU(modeLabels(fixed)) end
    if FIXED[msg] then return namesRU(modeLabels(FIXED[msg])) end
    local tip = tipsRU(msg)
    if tip then return namesRU(modeLabels(tip)) end

    local s = linkText(msg, resolveName)
    for i = 1, #PATTERNS do
        local pat, build = PATTERNS[i][1], PATTERNS[i][2]
        local a, b, c, d = s:match(pat)
        if a then
            local ok, ru = pcall(build, a, b, c, d)
            if ok and ru and ru ~= "" then return namesRU(modeLabels(ru)) end
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

    if CoARU_NoteChatPlayers then CoARU_NoteChatPlayers(msg) end
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
