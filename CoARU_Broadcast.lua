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

    { "^(.-)has ended, but unfortunately none survived!$",
      function(head) return ("%sзавершилось, и не выжил никто!"):format(head) end },
    { "^(.-)has ended!$",
      function(head) return ("%sзавершилось!"):format(head) end },

    { "^(.-)has spawned in (.+)!$",
      function(head, where) return ("%sпоявляется в зоне %s!"):format(head, where) end },

    { "^Server uptime: (%d+) Hour%(s%) (%d+) Minute%(s%) (%d+) Second%(s%)%.$",
      function(h, m, s)
          return ("Время работы сервера: %s ч. %s мин. %s сек."):format(h, m, s)
      end },
    { "^Welcome to Ascension!$", function() return "Добро пожаловать в Ascension!" end },
}

local ANNOUNCE = {
    ['The "char list" command was removed. You can activate and deactivate characters on your character selection screen!'] =
        'Команда «char list» убрана. Включать и отключать персонажей теперь можно прямо на экране выбора персонажа!',
    ['[Worldforged] Over 1,800 hidden treasures scattered across Azeroth! Venture off the beaten path to discover Worldforged gear tucked away in forgotten caves, ancient towers, and remote corners of the world. Treasure Spoils and Adventure awaits the bold!'] =
        '[Worldforged] По Азероту разбросано больше 1800 тайников! Сойдите с торной тропы: снаряжение Worldforged спрятано в забытых пещерах, древних башнях и глухих углах мира. Смелых ждут добыча и приключения!',
    ['[Group Up!] Group Experience Rates are boosted and Quest Items are shared to all party members! Grouping up together will allow you to progress together and have friends to enjoy the journey.'] =
        '[Group Up!] В группе опыт идет быстрее, а предметы заданий достаются всем участникам! Вместе вы продвигаетесь дальше, и дорога веселее.',
}

local function announceRU(msg)
    local body = msg:match("^%[Ascension Autobroadcast%]:%s*(.+)$")
    if not body then return nil end
    local ru = ANNOUNCE[(body:gsub("%s+", " "):gsub("%s+$", ""))]
    if not ru then return nil end
    return "[Ascension Autobroadcast]: " .. ru
end

function CoARU_BroadcastRU(msg)
    if not msg or msg == "" then return nil end
    if CoARU_HasCyrillic and CoARU_HasCyrillic(msg) then return nil end

    local fixed = announceRU(msg)
    if fixed then return fixed end

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
