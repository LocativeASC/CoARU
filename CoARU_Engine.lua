local MAX_DESC_RECURSION = 2

local OFFSET_BITS = 17
local LEN_BITS = 13
local OFFSET_MOD = 2 ^ OFFSET_BITS
local LEN_MOD = 2 ^ LEN_BITS

local function unpackLoc(v)
    local length = v % LEN_MOD
    v = (v - length) / LEN_MOD
    local offset = v % OFFSET_MOD
    local chunkId = (v - offset) / OFFSET_MOD
    return chunkId, offset, length
end

local CoARU_Deflate
do
    if _G.LibStub then
        local ok, lib = pcall(function() return _G.LibStub:GetLibrary("LibDeflate", true) end)
        if ok and lib then CoARU_Deflate = lib end
    end
    if not CoARU_Deflate then CoARU_Deflate = _G.LibDeflate end
end

local CHUNK_CAP = 320

local enSlot = { cache = {}, old = {}, n = 0 }
local ruSlot = { cache = {}, old = {}, n = 0 }
local questSlot = { cache = {}, old = {}, n = 0 }

function CoARU_ChunkCacheStat()
    return enSlot.n, ruSlot.n, questSlot.n, CHUNK_CAP
end

local function rotate(slot)
    slot.old = slot.cache
    slot.cache = {}
    slot.n = 0
end

local function remember(slot, chunkId, value)
    if slot.n >= CHUNK_CAP then rotate(slot) end
    slot.cache[chunkId] = value
    slot.n = slot.n + 1
end

local function decompressChunk(chunkTable, slot, chunkId)
    local hit = slot.cache[chunkId]
    if hit == nil and slot.old then
        hit = slot.old[chunkId]
        if hit ~= nil then remember(slot, chunkId, hit) end
    end
    if hit ~= nil then
        if hit == false then return nil end
        return hit
    end
    local raw = chunkTable and chunkTable[chunkId]
    if not raw then

        remember(slot, chunkId, false)
        return nil
    end
    local text = CoARU_Deflate and CoARU_Deflate:DecompressZlib(raw)
    remember(slot, chunkId, text or false)
    return text
end

local function sliceLoc(chunkTable, slot, packed)
    local chunkId, offset, length = unpackLoc(packed)
    local text = decompressChunk(chunkTable, slot, chunkId)
    if not text then return nil end
    return text:sub(offset + 1, offset + length)
end

local function fetchText(locTable, chunkTable, slot, id)
    local loc = locTable and locTable[id]
    if not loc then return nil end
    if type(loc) == "table" then
        local out = {}
        for i, packed in ipairs(loc) do
            out[i] = sliceLoc(chunkTable, slot, packed)
        end
        return out
    end
    return sliceLoc(chunkTable, slot, loc)
end

function CoARU_GetEN(id)
    return fetchText(CoARU_LOC_EN, CoARU_CHUNK_EN, enSlot, id)
end

function CoARU_GetRU(id)
    return fetchText(CoARU_LOC_RU, CoARU_CHUNK_RU, ruSlot, id)
end

function CoARU_DeflateStatus()
    if not CoARU_Deflate then return false, "no LibDeflate instance resolved" end
    if type(CoARU_Deflate.DecompressZlib) ~= "function" then
        return false, "resolved object has no DecompressZlib"
    end
    return true, CoARU_Deflate._VERSION or "?"
end

local function fetchOneRU(packed)
    return sliceLoc(CoARU_CHUNK_RU, ruSlot, packed)
end

local function fetchQuestRU(packed)
    return sliceLoc(CoARU_QUEST_CHUNK, questSlot, packed)
end

function CoARU_EN(key)
    local snap = CoARU_GS_EN
    if snap and snap[key] ~= nil then return snap[key] end
    return _G[key]
end

function CoARU_StripCodes(text)
    if not text then return nil end
    local s = text

    s = s:gsub("|[cC]%x%x%x%x%x%x%x%x", "")

    s = s:gsub("|[rR]", "")

    for _ = 1, 6 do
        local a1, a2, a3
        s, a1 = s:gsub("|%d+(%b[])%b[]", function(a) return a:sub(2, -2) end)
        s, a2 = s:gsub("|%d+(%b[])", function(a) return a:sub(2, -2) end)
        s, a3 = s:gsub("s%d+(%b[])", function(a) return (a:sub(2, -2):gsub("%b[]", "")) end)
        if a1 == 0 and a2 == 0 and a3 == 0 then break end
    end
    s = s:gsub("|T.-|t", "")
    s = s:gsub("|n", " ")

    s = s:gsub("@ext:(.-):ext@", "%1")
    return s
end

local function extractNumbers(s)
    local nums = {}
    for m in s:gmatch("%d[%d%.,]*") do
        m = m:gsub("[%.,]+$", "")
        nums[#nums + 1] = m
    end
    return nums
end

local function ruPlural(num, one, few, many)
    local n = tonumber((tostring(num):gsub("[,.].*$", ""))) or 0
    if n < 0 then n = -n end
    if (tostring(num):find("[.,]")) then return few end
    local n10, n100 = n % 10, n % 100
    if n10 == 1 and n100 ~= 11 then return one end
    if n10 >= 2 and n10 <= 4 and (n100 < 12 or n100 > 14) then return few end
    return many
end

function CoARU_RuPlural(num, one, few, many)
    return ruPlural(num, one, few, many)
end

local function applyPlurals(ru, nums)
    return (ru:gsub("{(%d+)|([^|{}]*)|([^|{}]*)|([^|{}]*)}", function(n, a, b, c)
        return ruPlural(nums[tonumber(n)] or "0", a, b, c)
    end))
end

function CoARU_NumbersOf(text)
    if type(text) ~= "string" then return nil end
    return extractNumbers(CoARU_StripCodes(text))
end

function CoARU_Norm(text)
    if not text then return nil end
    local s = CoARU_StripCodes(text)
    s = s:gsub("%d[%d%.,]*", function(m)
        local trail = m:match("([%.,]+)$") or ""
        return "#" .. trail
    end)
    s = s:gsub("%s+", " ")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s
end

function CoARU_HasCyrillic(text)

    return text and text:find("[\208\209]") ~= nil
end

function CoARU_ExpandMarkers(text, spellID)
    if not text or not text:find("%b@@") then return nil end
    if not (C_Format and C_Format.Format) then return nil end
    local ok, newText, lines = pcall(C_Format.Format, text, false, 0, spellID or 0)
    if ok and newText then return newText, lines end
    return nil
end

function CoARU_CleanMarkers(text, depth, spellID)
    if not text then return nil end
    depth = depth or 0
    local s = text

    s = s:gsub("%$?%$@spelldesc(%d+)", function(refId)
        if depth < MAX_DESC_RECURSION then
            local sub = CoARU_ResolveDescription(tonumber(refId), depth + 1)
            if sub then return sub end
        end
        return ""
    end)

    if s:find("%b@@") then
        local expanded, extra = CoARU_ExpandMarkers(s, spellID)
        if expanded then
            s = expanded
            if extra then
                for _, line in ipairs(extra) do
                    s = s .. "\n" .. line
                end
            end
        else
            s = s:gsub("@ext:(.-):ext@", "%1")
            s = s:gsub("@(%a+):.-:%1@", "")
            s = s:gsub("@%a+:?%d*:?%-?%d*@", "")
        end
    end
    s = s:gsub("@%a+:?%d*", "")

    s = s:gsub("[ \t]+\n", "\n")
    s = s:gsub("\n\n\n+", "\n\n")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s
end

function CoARU_ResolveDescription(id, depth)
    depth = depth or 0
    local ru = CoARU_GetRU(id)
    if not ru then return nil end

    if type(ru) == "table" then
        for _, v in ipairs(ru) do
            if v and not v:find("{%d+}") then
                return CoARU_CleanMarkers(v, depth, id)
            end
        end
        return nil
    end

    if not ru:find("{%d+}") then
        return CoARU_CleanMarkers(ru, depth, id)
    end
    return nil
end

local UNIT_SEC = { min = 60, mins = 60, minute = 60, minutes = 60,
                   hr = 3600, hrs = 3600, hour = 3600, hours = 3600,
                   day = 86400, days = 86400 }
local UNIT_RU = { min = "мин.", mins = "мин.", minute = "мин.", minutes = "мин.",
                  hr = "ч.", hrs = "ч.", hour = "ч.", hours = "ч.",
                  day = "дн.", days = "дн." }

local function slotAt(plain, pos)
    local n = 0
    for at in plain:gmatch("()%d[%d%.,]*") do
        if at >= pos then break end
        n = n + 1
    end
    return n + 1
end

local function fmtSeconds(value, mult)
    local v = tonumber((value:gsub(",", "")))
    if not v then return nil end
    v = v * mult
    if v == math.floor(v) then return string.format("%d", v) end
    return (string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", ""))
end

local function fixUnit(ru, slot, unitRu)
    local out, n = ru:gsub("{" .. slot .. "}(%s*)сек%.?", function(sp)
        return "{" .. slot .. "}" .. (sp ~= "" and sp or " ") .. unitRu
    end)
    if n == 0 then return nil end
    return out
end

local function rawRuns(raw)
    local out, i, n = {}, 1, #raw
    while i <= n do
        local start, j, seen, stop = i, i, 0, nil
        while true do
            local c = raw:match("^|[cC]%x%x%x%x%x%x%x%x", j)
            if c then j = j + #c end
            local num = raw:match("^%d[%d%.,]*", j)
            if not num then break end
            j = j + #num
            local r = raw:match("^|[rR]", j)
            if r then j = j + #r end
            seen, stop = seen + 1, j

            local save = j
            local c2 = raw:match("^|[cC]%x%x%x%x%x%x%x%x", j)
            if c2 then j = j + #c2 end
            if raw:sub(j, j) ~= "/" then
                j = save
                break
            end
            j = j + 1
            local r2 = raw:match("^|[rR]", j)
            if r2 then j = j + #r2 end
        end
        if seen >= 2 and stop then
            out[#out + 1] = raw:sub(start, stop - 1)
            i = stop
        else
            i = i + 1
        end
    end
    return out
end

local function buildAttempts(plain, raw)
    local out = {}

    local s, e, a, b = plain:find("(%d[%d%.,]*)%s+to%s+(%d[%d%.,]*)")
    if s then
        local np = plain:sub(1, s - 1) .. a .. plain:sub(e + 1)
        out[#out + 1] = { plain = np, slot = slotAt(plain, s), value = a .. "-" .. b }
    end

    local i = plain:find("%$")
    while i do
        local nxt = plain:sub(i + 1, i + 1)
        if not nxt:match("[%w{@]") then
            local np = plain:sub(1, i - 1) .. "0" .. plain:sub(i + 1)
            out[#out + 1] = { plain = np, slot = slotAt(plain, i), value = "$" }
            break
        end
        i = plain:find("%$", i + 1)
    end

    local function findStepRun(str, from)
        local i, n = from, #str
        while i <= n do
            local s, e, run = str:find("([%d%-][%d%.,%-/]*[%d%-])", i)
            if not s then return nil end
            if run:find("/", 1, true) and run:find("%d") then return s, e, run end
            i = e + 1
        end
        return nil
    end
    do
        local parts, multi, slot, i, n, found = {}, {}, 0, 1, #plain, false
        local rawList, nrun = raw and rawRuns(raw) or nil, 0
        while i <= n do
            local s, e, run = findStepRun(plain, i)
            local s2, e2 = plain:find("%d[%d%.,]*", i)
            if s and s2 and s <= s2 then

                parts[#parts + 1] = plain:sub(i, s - 1) .. run:match("(%d[%d%.,]*)")
                slot = slot + 1

                nrun = nrun + 1
                local coloured = run
                local cand = rawList and rawList[nrun]

                if cand and CoARU_StripCodes(cand) == run then coloured = cand end
                multi[slot] = coloured
                found, i = true, e + 1
            elseif s2 then
                parts[#parts + 1] = plain:sub(i, e2)
                slot = slot + 1
                i = e2 + 1
            else
                break
            end
        end
        if found then
            parts[#parts + 1] = plain:sub(i)
            out[#out + 1] = { plain = table.concat(parts), multi = multi }
        end
    end

    do
        local parts, multi, slot, i, n, found = {}, {}, 0, 1, #plain, false
        while i <= n do
            local ps, pe, paren = plain:find("(%s*%(%+[%d%.,]+%%?%))", i)
            local s2, e2 = plain:find("%d[%d%.,]*", i)
            if ps and (not s2 or ps < s2) then
                if slot > 0 then
                    parts[#parts + 1] = plain:sub(i, ps - 1)
                    multi[slot] = (multi[slot] or "") .. paren
                    found = true
                    i = pe + 1
                else
                    parts[#parts + 1] = plain:sub(i, pe)
                    i = pe + 1
                end
            elseif s2 then
                parts[#parts + 1] = plain:sub(i, e2)
                slot = slot + 1
                multi[slot] = plain:sub(s2, e2)
                i = e2 + 1
            else
                break
            end
        end
        if found then
            parts[#parts + 1] = plain:sub(i)
            out[#out + 1] = { plain = table.concat(parts), multi = multi }
        end
    end

    do
        local np, n = plain:gsub("([^%d])%-(%d)", "%1%2")
        if np:sub(1, 1) == "-" and np:sub(2, 2):match("%d") then
            np, n = np:sub(2), n + 1
        end
        if n > 0 and np ~= plain then
            out[#out + 1] = { plain = np }
        end
    end

    for at, num, word in plain:gmatch("()(%d[%d%.,]*)%s+(%a+)") do
        local mult = UNIT_SEC[word:lower()]
        if mult then
            local secs = fmtSeconds(num, mult)
            if secs then
                local head = plain:sub(1, at - 1)
                local tail = plain:sub(at + #num):gsub("^%s*" .. word, " sec", 1)
                out[#out + 1] = { plain = head .. secs .. tail, slot = slotAt(plain, at),
                                  value = num, unit = UNIT_RU[word:lower()] }
            end
            break
        end
    end

    return out
end

local function matchOne(en, ru, id, norm, plain, try)
    if not en or not ru then return nil end
    if norm ~= en then return nil end
    if try and try.unit then
        ru = fixUnit(ru, try.slot, try.unit)
        if not ru then return nil end
    end
    local nums = extractNumbers(plain)

    if try then
        if try.slot then nums[try.slot] = try.value end
        if try.multi then for k, v in pairs(try.multi) do nums[k] = v end end
    end
    local r = applyPlurals(ru, nums):gsub("{(%d+)}", function(n)
        return nums[tonumber(n)] or "?"
    end)
    return CoARU_CleanMarkers(r, 0, id)
end

function CoARU_TranslateText(id, liveText)
    if not liveText then return nil end
    local en = CoARU_GetEN(id)
    if not en then return nil end
    local ru = CoARU_GetRU(id)

    local plain = CoARU_StripCodes(liveText)
    local norm = CoARU_Norm(plain)

    local function pass(try, p, n)
        if type(en) == "table" then
            for i, e in ipairs(en) do
                local r = matchOne(e, type(ru) == "table" and ru[i] or nil, id, n, p, try)
                if r then return r end
            end
            return nil
        end
        return matchOne(en, ru, id, n, p, try)
    end

    local direct = pass(nil, plain, norm)
    if direct then return direct end
    for _, try in ipairs(buildAttempts(plain, liveText)) do
        local r = pass(try, try.plain, CoARU_Norm(try.plain))
        if r then return r end
    end

    return nil
end

CoARU_G = {
    ["Instant"] = "Мгновенно",
    ["Instant cast"] = "Мгновенное применение",
    ["Passive"] = "Пассивный",
    ["Channeled"] = "Поддерживаемое заклинание",
    ["Unlimited range"] = "Неограниченная дальность",
    ["Melee Range"] = "Ближний бой",
    ["# yd range"] = "Дальность {1} м",
    ["#-# yd range"] = "Дальность {1}-{2} м",
    ["Requires Level #"] = "Требуется уровень: {1}",
    ["# Mana"] = "{1} ед. маны",
    ["#% of base mana"] = "{1}% от базовой маны",
    ["# Energy"] = "{1} ед. энергии",
    ["# Rage"] = "{1} ед. ярости",
    ["# Focus"] = "{1} ед. концентрации",
    ["# Runic Power"] = "{1} ед. силы рун",
    ["# sec cast"] = "Применение: {1} сек.",
    ["#. sec cast"] = "Применение: {1} сек.",
    ["# sec cooldown"] = "Восстановление: {1} сек.",
    ["# min cooldown"] = "Восстановление: {1} мин.",
    ["Generates # Heat Per Target"] = "Генерирует {1} ед. Жара за каждую цель",
    ["Generates # Heat Per Tick"] = "Генерирует {1} ед. Жара за каждый тик",
    ["Generates # Heat Each Tick"] = "Генерирует {1} ед. Жара за каждый тик",
    ["Generates # Heat Per Enemy Hit"] = "Генерирует {1} ед. Жара за каждого пораженного врага",
    ["Generates # additional Rage"] = "Генерирует дополнительно {1} ед. ярости",
    ["# Mana, plus # per sec"] = "{1} ед. маны + {2} в секунду",
    ["Hold SHIFT for more information"] = "Удерживайте SHIFT для подробностей",
    ["Only # Ascension spell can be active at a time."] = "Одновременно может быть активно только {1} заклинание Вознесения.",

    ["Cannot be cast when in combat."] = "Нельзя применять в бою.",
    ["Hello! Ready for some training?"] = "Привет! Готов подучиться?",
    ["Greetings! Take my trial!"] = "Приветствую! Пройди мое испытание!",
    ["All"] = "Все",
    ["Filter"] = "Фильтр",
    ["Train"] = "Обучиться",
    ["Exit"] = "Выход",
    ["Cost:"] = "Цена:",
    ["(Rank #)"] = "(Ранг {1})",
    ["Rank #"] = "Ранг {1}",
    ["Rank #/#"] = "Ранг {1}/{2}",
    ["Requires: Level #"] = "Требуется уровень: {1}",

    ["Spend more points to unlock this talent"] = "Потратьте больше очков, чтобы открыть этот талант.",
    ["Spend # more points to unlock this row"] = "Чтобы открыть этот ряд, потратьте еще очков: {1}",
    ["Unlocks at level #."] = "Открывается на уровне {1}.",
    ["Unlocks at level: #"] = "Открывается на уровне: {1}",

    ["Spend # more Talent Essence in current tree to unlock this row"] =
        "Чтобы открыть этот ряд, потратьте в текущем дереве еще эссенции талантов: {1}",
    ["Spend # more Talent Essence points in any tree to unlock rows below"] =
        "Чтобы открыть ряды ниже, потратьте в любом дереве еще эссенции талантов: {1}",
    ["Spend # more Ability Essence in any class to unlock this ability."] =
        "Чтобы открыть эту способность, потратьте в любом классе еще эссенции способностей: {1}.",
    ["Ability Essence: #"] = "Эссенция способностей: {1}",
    ["Talent Essence: #"] = "Эссенция талантов: {1}",
    ["Not enough Ability Essence"] = "Не хватает эссенции способностей",
    ["Not enough Talent Essence"] = "Не хватает эссенции талантов",
    ["Available"] = "Доступно",
    ["Unavailable"] = "Недоступно",
    ["Used"] = "Изучено",

    ["id-спела:"] = "ID спелла:",
}

do
    local RES = {
        ["Heat"] = "Жара",
        ["Ember"] = "Углей", ["Embers"] = "Углей",
        ["Advantage"] = "Преимущества",
        ["Insanity"] = "Безумия",
        ["Rage"] = "ярости",
        ["Felfury"] = "Ярости Скверны",
        ["Demonfire"] = "Демонического огня",
        ["Reaped Soul"] = "Пожатых душ", ["Reaped Souls"] = "Пожатых душ",
        ["Static"] = "Статического заряда",
        ["Runic Power"] = "силы рун",
        ["Soul Fragment"] = "Осколков души", ["Soul Fragments"] = "Осколков души",
        ["Energy"] = "энергии",
        ["Mana"] = "маны",
    }
    for en, ru in pairs(RES) do
        CoARU_G["Generates # " .. en] = "Генерирует {1} ед. " .. ru
        CoARU_G["Consumes # " .. en] = "Расходует {1} ед. " .. ru
        CoARU_G["Costs # " .. en] = "Стоимость: {1} ед. " .. ru
    end
end

local CLASS_NAME = {}
for _, n in ipairs({
    "Necromancer", "Pyromancer", "Cultist", "Starcaller", "Sun Cleric", "Tinker",
    "Runemaster", "Primalist", "Reaper", "Venomancer", "Chronomancer", "Bloodmage",
    "Guardian", "Stormbringer", "Felsworn", "Barbarian", "Witch Doctor", "Witch Hunter",
    "Knight of Xoroth", "Templar", "Ranger",
}) do
    CLASS_NAME[n] = true
    CLASS_NAME[n .. "s"] = true
end
CLASS_NAME["Knights of Xoroth"] = true

function CoARU_IsClassName(n)
    return CLASS_NAME[n] == true
end

function CoARU_TranslateClass(line)
    if not line then return nil end
    local en = CoARU_Norm(CoARU_StripCodes(line))
    local cls = en:match("^(.+) cannot use this Mystic Enchant$")
    if not cls then return nil end

    if not CLASS_NAME[cls] then return nil end
    return cls .. " не могут использовать эти Мистические чары"
end

CoARU_REQ_TERMS = {

        { "One%-Handed Melee Weapon", "одноручное оружие ближнего боя" },
        { "Two%-Handed Melee Weapon", "двуручное оружие ближнего боя" },

        { "Recently Avoided", "недавнее уклонение" },
        { "Fishing Poles", "Удочки" }, { "Fist Weapons", "Кистевое оружие" },
        { "One%-Handed Swords", "Одноручные мечи" }, { "Two%-Handed Swords", "Двуручные мечи" },
        { "One%-Handed Axes", "Одноручные топоры" }, { "Two%-Handed Axes", "Двуручные топоры" },

        { "One%-Handed Maces", "Одноручное дробящее оружие" },
        { "Two%-Handed Maces", "Двуручное дробящее оружие" },
        { "Crossbows", "Арбалеты" }, { "Polearms", "Древковое оружие" }, { "Warglaives", "Глефы" },
        { "Daggers", "Кинжалы" }, { "Staves", "Посохи" }, { "Shields", "Щиты" },
        { "Thrown", "Метательное оружие" }, { "Wands", "Жезлы" },
        { "Bows", "Луки" }, { "Guns", "Ружья" },

        { "Melee Weapon", "оружие ближнего боя" },
        { "Ranged Weapon", "оружие дальнего боя" },
        { "One%-Handed Exotics", "Одноручное экзотическое оружие" },

        { "Two%-Handed Exotics", "Двуручное экзотическое оружие" },
        { "Exotics", "Экзотическое оружие" },
        { "Spears", "Копья" },
        { "Poisons", "Яды" }, { "Shield", "Щит" },

        { "Blacksmithing", "кузнечное дело" }, { "Leatherworking", "кожевничество" },
        { "Jewelcrafting", "ювелирное дело" }, { "Engineering", "инженерное дело" },
        { "Enchanting", "наложение чар" }, { "Inscription", "начертание" },
        { "Alchemy", "алхимия" }, { "Tailoring", "портняжное дело" },
        { "Herbalism", "травничество" }, { "Skinning", "снятие шкур" },
        { "Mining", "горное дело" }, { "Cooking", "кулинария" },
        { "First Aid", "первая помощь" }, { "Fishing", "рыбная ловля" },
        { "Woodworking", "столярное дело" }, { "Woodcutting", "лесозаготовка" },

        { "Primary Stat:", "основная характеристика:" },
        { "Spirit", "дух" }, { "Intellect", "интеллект" }, { "Agility", "ловкость" },
        { "Strength", "сила" }, { "Stamina", "выносливость" },

        { "Advantage", "Преимущество" }, { "Insanity", "Безумие" },
        { "Static", "Статический заряд" },
        { "Felfury", "Ярость Скверны" }, { "Demonfire", "Демонический огонь" },
        { "Reaped Souls", "Пожатые души" }, { "Reaped Soul", "Пожатая душа" },
    }

local TIME_UNITS = {

    { ru = { "минута", "минуты", "минут" }, en = { "minute", "minutes" }, pat = "^мин" },
    { ru = { "час", "часа", "часов" },      en = { "hour", "hours" },     pat = "^час" },
    { ru = { "день", "дня", "дней" },       en = { "day", "days" },       pat = "^д[ен]" },
    { ru = { "секунда", "секунды", "секунд" }, en = { "second", "seconds" }, pat = "^сек" },
}

local function ruPlural(n, forms)
    local n100, n10 = n % 100, n % 10
    if n100 >= 11 and n100 <= 14 then return forms[3] end
    if n10 == 1 then return forms[1] end
    if n10 >= 2 and n10 <= 4 then return forms[2] end
    return forms[3]
end

local PLURAL_MID = {
    ["единиц"] = "единицы", ["очков"] = "очка", ["часов"] = "часа", ["минут"] = "минуты",
    ["дней"] = "дня", ["камней"] = "камня", ["предметов"] = "предмета", ["рун"] = "руны",
    ["секунд"] = "секунды", ["игроков"] = "игрока", ["приемов"] = "приема",
    ["ячеек"] = "ячейки", ["запросов"] = "запроса", ["заданий"] = "задания",
    ["выстрелов"] = "выстрела", ["зарядов"] = "заряда", ["попыток"] = "попытки",
    ["раза"] = "раза",
}

local REST_RU = {
    ["Rested"] = "Отдохнувший", ["Normal"] = "Нормальный",
    ["Tired"] = "Усталый", ["Exhausted"] = "Изнуренный",
}

function CoARU_FixLogLine(msg)
    if type(msg) ~= "string" then return nil end
    local out = msg

    if out:find("%d") then
        local parts, pos = {}, 1
        while true do
            local a, b, num, sp = out:find("(%d+)(%s+)", pos)
            if not a then break end
            local e = b
            while true do
                local c = out:byte(e + 1)
                if c == 208 or c == 209 then e = e + 2 else break end
            end
            local word = out:sub(b + 1, e)
            local mid = PLURAL_MID[word]
            local n = tonumber(num)
            local n100, n10 = n and n % 100 or 0, n and n % 10 or 0
            if mid and n and not (n100 >= 11 and n100 <= 14) and n10 >= 2 and n10 <= 4 then
                parts[#parts + 1] = out:sub(pos, a - 1) .. num .. sp .. mid
            else
                parts[#parts + 1] = out:sub(pos, e)
            end
            pos = e + 1
        end
        if #parts > 0 then
            parts[#parts + 1] = out:sub(pos)
            out = table.concat(parts)
        end
    end
    for en, ru in pairs(REST_RU) do
        out = out:gsub("%(" .. en .. ":", "(" .. ru .. ":")
    end
    if out == msg then return nil end
    return out
end

local CLIENT_TIME_UNITS = {
    { "(%d+)%s+Second%(s%)", "%1 сек." },
    { "(%d+)%s+Minute%(s%)", "%1 мин." },
    { "(%d+)%s+Hour%(s%)",   "%1 ч." },
    { "(%d+)%s+Day%(s%)",    "%1 дн." },
    { "(%d+)%s+[Ss]ecs?%f[%W]",  "%1 сек." },
    { "(%d+)%s+[Mm]ins?%f[%W]",  "%1 мин." },
    { "(%d+)%s+[Hh]rs?%f[%W]",   "%1 ч." },
    { "(%d+)%s+[Ss]econds?%f[%W]", "%1 сек." },
    { "(%d+)%s+[Mm]inutes?%f[%W]", "%1 мин." },
    { "(%d+)%s+[Hh]ours?%f[%W]",   "%1 ч." },
    { "(%d+)%s+[Dd]ays?%f[%W]",    "%1 дн." },
}

function CoARU_FixTimeUnits(line)
    if not line or not CoARU_HasCyrillic or not CoARU_HasCyrillic(line) then return nil end
    local out = line
    for i = 1, #CLIENT_TIME_UNITS do
        out = out:gsub(CLIENT_TIME_UNITS[i][1], CLIENT_TIME_UNITS[i][2])
    end
    if out == line then return nil end

    out = out:gsub("%.%.", ".")
    return out
end

local UNFIX_TIME_UNITS = {
    { { "(%d+)%s+сек%.", "%1 sec" },     { "(%d+)%s+мин%.", "%1 min" },
      { "(%d+)%s+ч%.",   "%1 hour" },    { "(%d+)%s+дн%.",  "%1 day" } },
    { { "(%d+)%s+сек%.", "%1 seconds" }, { "(%d+)%s+мин%.", "%1 minutes" },
      { "(%d+)%s+ч%.",   "%1 hours" },   { "(%d+)%s+дн%.",  "%1 days" } },
    { { "(%d+)%s+сек%.", "%1 sec." },    { "(%d+)%s+мин%.", "%1 min." },
      { "(%d+)%s+ч%.",   "%1 hr" },      { "(%d+)%s+дн%.",  "%1 day" } },
}

local EN_TIME_DOT = {
    { "(%d+%s+sec)([,%s])", "%1.%2" },   { "(%d+%s+min)([,%s])",  "%1.%2" },
    { "(%d+%s+sec)%.([,%s])", "%1%2" },  { "(%d+%s+min)%.([,%s])", "%1%2" },
}

function CoARU_UnfixEnTimeDot(line)
    local out = {}
    if not line or not line:find("%d%s+%a") then return out end
    for i = 1, #EN_TIME_DOT do
        local cand = line:gsub(EN_TIME_DOT[i][1], EN_TIME_DOT[i][2])
        if cand ~= line then out[#out + 1] = cand end
    end
    return out
end

function CoARU_UnfixTimeUnits(line)
    local out = {}
    if not line or not CoARU_HasCyrillic or not CoARU_HasCyrillic(line) then return out end
    if not (line:find("сек%.") or line:find("мин%.") or line:find("ч%.") or line:find("дн%.")) then
        return out
    end
    for i = 1, #UNFIX_TIME_UNITS do
        local cand = line
        for j = 1, #UNFIX_TIME_UNITS[i] do
            cand = cand:gsub(UNFIX_TIME_UNITS[i][j][1], UNFIX_TIME_UNITS[i][j][2])
        end
        if cand ~= line then out[#out + 1] = cand end
    end
    return out
end

function CoARU_TimeRemaining(line)
    if not line then return nil end

    local enNum, enWord = line:match("^(%d+)%s+(%a+)%s+remaining%.?$")
    if enNum then
        local n = tonumber(enNum)
        for _, u in ipairs(TIME_UNITS) do
            if enWord:lower():find("^" .. u.en[1]) then
                return "Осталось: " .. enNum .. " " .. ruPlural(n, u.ru), line
            end
        end
        return nil
    end
    local num, word = line:match("^Осталось:%s*(%d+)%s+([^%s%.]+)%.?$")
    if not num then return nil end
    local n = tonumber(num)
    if not n then return nil end
    for _, u in ipairs(TIME_UNITS) do
        if word:find(u.pat) then
            local ru = "Осталось: " .. num .. " " .. ruPlural(n, u.ru)
            local en = num .. " " .. (n == 1 and u.en[1] or u.en[2]) .. " remaining"
            return ru, en
        end
    end
    return nil
end

local DISPEL_RU = {
    Magic = "Магия", Curse = "Проклятие", Disease = "Болезнь", Poison = "Яд",
}

function CoARU_DispelType(word)
    if type(word) ~= "string" then return nil end
    return DISPEL_RU[(word:gsub("^%s+", ""):gsub("%s+$", ""))]
end

local function requiredTalents(s)
    if not s or not (s:find("талантов", 1, true) or s:find("talents", 1, true)) then return s end
    local tabs, classes = CoARU_TAB_RU, CoARU_CLASS_VANILLA_RU
    if type(tabs) ~= "table" or type(classes) ~= "table" then return s end

    local cls, clsRU, clsLen = nil, nil, -1
    for en, ru in pairs(classes) do
        if #en > clsLen and s:find("%f[%a]" .. en .. "%f[%A]") then
            cls, clsRU, clsLen = en, ru, #en
        end
    end
    if not cls then return s end

    local found = {}
    for en in pairs(tabs) do
        if s:find("%f[%a]" .. en .. "%f[%A]") then found[#found + 1] = en end
    end
    if #found == 0 then return s end

    local out = s
    for i = 1, #found do
        out = out:gsub("%f[%a]" .. found[i] .. "%f[%A]", "«" .. tabs[found[i]] .. "»")
    end

    out = out:gsub("%f[%a]or%f[%A]", "или")

    out = out:gsub("%s*%f[%a]" .. cls .. "%f[%A]", " (" .. clsRU .. ")")

    local head = out:match("талантов:(.-)%(") or out:match("talents:(.-)%(")
    if head then
        local bare = head:gsub("«[^»]*»", " ")
        if bare:find("[A-Za-z][A-Za-z]") then return s end
    end
    return out
end

function CoARU_TranslateRequires(line)

    if not line then return nil end
    if not (line:find("Requires") or line:find("Требуется")) then return nil end
    local s = line

    s = s:gsub("Requires talents:%s*", "Требуется талантов: ")
    s = s:gsub("Requires:%s*", "Требуется: ")

    local function pointsWord(chunk)
        local n = tonumber((chunk:gsub("|[cC]%x%x%x%x%x%x%x%x", ""):gsub("|[rR]", "")))
        if not n then return "очков" end
        local last, tens = n % 10, n % 100
        if last == 1 and tens ~= 11 then return "очко" end
        if last >= 2 and last <= 4 and (tens < 12 or tens > 14) then return "очка" end
        return "очков"
    end
    s = s:gsub("Requires%s+(%S+)%s+more%s+(%S+)%s+Class Points%.?",
               function(num, cls)
                   return ("Требуется еще %s %s класса «%s»."):format(num, pointsWord(num), cls)
               end)
    s = s:gsub("Requires%s+(%S+)%s+points%s+in%s+(.-)%s+Talents",
               function(num, tree)
                   return ("Требуется %s %s в ветке «%s»"):format(num, pointsWord(num), tree)
               end)
    s = s:gsub("Requires%s+", "Требуется ")

    s = s:gsub("At Least%s+(%d+)%s+Felfury", "не менее %1 ед. Ярости Скверны")
    s = s:gsub("At Least%s+", "не менее ")

    s = s:gsub("Enraged", "«Enrage»")

    s = s:gsub("%f[%a]Level%f[%A]", "уровень")

    if CoARU_FactionLineRU then
        local head, rest = s:match("^(Требуется:?%s+)(.+)$")
        if head and rest and rest:find("%-") then
            local ru = CoARU_FactionLineRU(rest)
            if ru then s = head .. ru end
        end
    end
    s = requiredTalents(s)
    s = s:gsub("%(Rank (%d+)%)", "(ранг %1)")
    s = s:gsub("%(Rank (|[cC]%x%x%x%x%x%x%x%x)(%d+)(|[rR])%)", "(ранг %1%2%3)")

    local PROF = CoARU_REQ_TERMS

    local function subTerm(str, pat, rep)
        local out, pos = {}, 1
        while true do
            local a, b = str:find(pat, pos)
            if not a then
                out[#out + 1] = str:sub(pos)
                break
            end
            local before = str:sub(1, a - 1):match("([%a'%-]+)%s*$")

            local afterCh = str:sub(b + 1, b + 1)
            local blocked = (before ~= nil and before:find("^[A-Z]") ~= nil)
                or (afterCh ~= "" and afterCh:find("^[A-Za-z]") ~= nil)
                or str:sub(b + 1):find("^%s+of%s") ~= nil
            out[#out + 1] = str:sub(pos, a - 1) .. (blocked and str:sub(a, b) or rep)
            pos = b + 1
        end
        return table.concat(out)
    end
    for _, p in ipairs(PROF) do s = subTerm(s, p[1], p[2]) end

    local function unwrapColor(piece)
        local pre, body, post = piece:match("^(|[cC]%x%x%x%x%x%x%x%x)(.*)(|[rR])$")
        if pre then return pre, body, post end
        return "", piece, ""
    end
    local function nameHead(piece)
        return (piece:gsub("%s*%b()%s*$", ""):gsub("!+$", ""):gsub("%s+%d+$", ""))
    end

    local function rankTail(piece)
        local core = piece:match("^(.-)%s*%(ранг %d+%)$")
        if core then return core, piece:sub(#core + 1) end
        return piece, ""
    end
    local head, tail = s:match("^(Требуется:?%s*)(.+)$")
    if head and tail and not tail:find("%.%s*$") then
        local parts, ok = {}, true
        for piece in (tail .. ","):gmatch("%s*(.-)%s*,") do
            if piece == "" then
                ok = false
                break

            else

                local pre, body, post = unwrapColor(piece)
                if CoARU_HasCyrillic(nameHead(body)) or body:find("«") then
                    parts[#parts + 1] = piece

                elseif nameHead(body):find("^%u[%a'%-]*[%a'%- :]*$")
                    and select(2, nameHead(body):gsub("%S+", "")) <= 5 then
                    local core, rest = rankTail(body)

                    parts[#parts + 1] = pre .. "«" .. core .. "»" .. rest .. post
                else
                    ok = false
                    break
                end
            end
        end
        if ok and #parts > 0 then
            s = head .. table.concat(parts, ", ")
        end
    end

    if s ~= line and not s:find("талантов") and CoARU_LatinIsLegit then
        local probe = CoARU_StripCodes and CoARU_StripCodes(s) or s
        probe = probe:gsub("«[^»]*»", " ")
        if not CoARU_LatinIsLegit(probe) then return nil end
    end
    if s ~= line then return s end
    return nil
end

function CoARU_TranslateIconItemName(line)
    if type(line) ~= "string" or not CoARU_ItemNameEN then return nil end
    local icon, color, name = line:match("^(|T.-|t%s*)(|[cC]%x%x%x%x%x%x%x%x)(.-)|[rR]%s*$")
    if not (icon and name) or name == "" then return nil end
    if name:find("|", 1, true) then return nil end
    local key = name:match("^%s*(.-)%s*$")
    local ru = CoARU_ItemNameEN[key]
    if not ru or ru == key then return nil end

    return icon .. color .. ru .. "|r"
end

function CoARU_TranslateTransmog(line)
    if not line or not CoARU_ItemNameEN then return nil end
    local head, name = line:match("^(Трансмогрификация в:%s*)(.+)$")
    if not head then
        head, name = line:match("^(Transmogrified into:%s*)(.+)$")
        if head then head = "Трансмогрификация в: " end
    end
    if not head or not name then return nil end

    local icon = name:match("^(|T.-|t%s*)") or ""
    local rest = name:sub(#icon + 1)
    local color = rest:match("^(|[cC]%x%x%x%x%x%x%x%x)") or ""
    local tail = ""
    if color ~= "" then
        rest = rest:sub(#color + 1)
        local body, close = rest:match("^(.-)(|[rR])%s*$")
        if body then rest, tail = body, close end
    end
    name = rest:match("^%s*(.-)%s*$")
    local ru = CoARU_ItemNameEN[name]

    if not ru or ru == name then return nil end
    return head .. icon .. color .. ru .. tail
end

local LIST_LABELS = {
    { "Reagents:", "Реагенты: " },
    { "Tools:", "Инструменты: " },
}

function CoARU_TranslateReagents(line)
    if not line then return nil end
    local s, head_ru
    for i = 1, #LIST_LABELS do
        local en, ru = LIST_LABELS[i][1], LIST_LABELS[i][2]
        if line:find(en, 1, true) then
            s = line:gsub(en .. "%s*", ru)
            head_ru = ru
            break
        end
    end
    if not s or s == line then return nil end
    if CoARU_ItemNameEN then
        local head, list = s:match("^(" .. head_ru:gsub("%s+$", "") .. "%s*)(.+)$")
        if list then
            local out, any = {}, false
            for part in (list .. ","):gmatch("(.-),%s*") do
                local name, tail = part:match("^%s*(.-)%s*(%(%d+%))%s*$")
                if not name then name, tail = part:match("^%s*(.-)%s*$"), nil end
                local ru = name and CoARU_ItemNameEN[name]
                if ru then
                    any = true
                    out[#out + 1] = tail and (ru .. " " .. tail) or ru
                else
                    out[#out + 1] = tail and (name .. " " .. tail) or (name or part)
                end
            end
            if any then s = head .. table.concat(out, ", ") end
        end
    end
    return s
end

local HASH_K = 131
local HASH_MOD = 2 ^ 45

local function hashText(s)
    local h = 0
    for i = 1, #s do
        h = (h * HASH_K + s:byte(i)) % HASH_MOD
    end
    return h
end

local LINK_FP = { donate = 1455939105, github = 1410064090, discord = 2963082712 }

function CoARU_LinkOK(kind, s)
    local want = LINK_FP[kind]
    if not want or want == 0 or not s or s == "" then return false end
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967291 end
    return h == want
end

function CoARU_TranslateByIndex(liveText)
    if not liveText then return nil end
    local plain = CoARU_StripCodes(liveText)
    local norm = CoARU_Norm(plain)
    if not norm or norm == "" then return nil end

    local function look(p, n, try)
        if not n or n == "" then return nil end
        local packed = CoARU_HASH and CoARU_HASH[hashText(n)]
        if not packed then return nil end
        local ru = fetchOneRU(packed)
        if not ru then return nil end
        if try and try.unit then
            ru = fixUnit(ru, try.slot, try.unit)
            if not ru then return nil end
        end
        local nums = extractNumbers(p)

    if try then
        if try.slot then nums[try.slot] = try.value end
        if try.multi then for k, v in pairs(try.multi) do nums[k] = v end end
    end
        return (applyPlurals(ru, nums):gsub("{(%d+)}", function(k)
            return nums[tonumber(k)] or "?"
        end))
    end

    local r = look(plain, norm, nil)
    if r then return r end
    for _, try in ipairs(buildAttempts(plain, liveText)) do
        r = look(try.plain, CoARU_Norm(try.plain), try)
        if r then return r end
    end
    return nil
end

function CoARU_QuestNorm(t)
    if not t then return nil end
    t = t:gsub("%$[Bb]", " ")
    local pname = UnitName and UnitName("player")
    if pname and #pname >= 2 and not pname:find("[^%w']") then
        t = t:gsub(pname, "$N")
    end
    t = t:gsub("<[Nn]ame>", "$N")
    t = t:gsub("<[Cc]lass>", "$c"):gsub("<[Rr]ace>", "$r")
    t = t:gsub("%$[Cc]", "$c"):gsub("%$[Rr]", "$r")

    t = t:gsub("\226\128\152", "'"):gsub("\226\128\153", "'")
    t = t:gsub("\226\128\156", '"'):gsub("\226\128\157", '"')
    t = t:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return t
end

local function escPat(w)
    return (w:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1"))
end
function CoARU_QuestReverseCR(s)
    if not s then return nil end
    local c = UnitClass and UnitClass("player")
    if c and #c >= 3 then local p = escPat(c); s = s:gsub(p, "$c"):gsub(escPat(c:lower()), "$c") end
    local r = UnitRace and UnitRace("player")
    if r and #r >= 3 then local p = escPat(r); s = s:gsub(p, "$r"):gsub(escPat(r:lower()), "$r") end
    return s
end

function CoARU_QuestLookup(t)
    if not t or not CoARU_QUEST then return nil end
    local norm = CoARU_QuestNorm(t)
    if not norm or #norm < 3 then return nil end
    local packed = CoARU_QUEST[hashText(norm)]
    if packed then return fetchQuestRU(packed) end

    local norm2 = CoARU_QuestReverseCR(norm)
    if norm2 and norm2 ~= norm then
        packed = CoARU_QUEST[hashText(norm2)]
        if packed then return fetchQuestRU(packed) end
    end
    return nil
end

function CoARU_QuestCount()
    local n = 0
    for _ in pairs(CoARU_QUEST or {}) do n = n + 1 end
    return n
end

function CoARU_TranslateGlobal(liveText)
    if not liveText then return nil end
    local plain = CoARU_StripCodes(liveText)
    local ru = CoARU_G[CoARU_Norm(plain)]
    if not ru then return nil end
    local nums = {}
    for m in plain:gmatch("%d[%d%.,]*") do
        nums[#nums + 1] = (m:gsub("[%.,]+$", ""))
    end
    return (applyPlurals(ru, nums):gsub("{(%d+)}", function(n) return nums[tonumber(n)] or "?" end))
end

local TERM_FORMS = {
    ["Advantage"]    = { "Преимуществом", "Преимущества", "Преимуществу", "Преимуществе",
                         "Преимущество" },
    ["Heat"]         = { "Жаром", "Жара", "Жару", "Жаре", "Жар" },
    ["Insanity"]     = { "Безумием", "Безумия", "Безумию", "Безумии", "Безумие" },
    ["Static"]       = { "Статическим зарядом", "Статического заряда", "Статическому заряду",
                         "Статическом заряде", "Статический заряд",

                         "статикой", "статики", "статику", "статике", "статика" },
    ["Felfury"]      = { "Яростью Скверны", "Ярости Скверны", "Ярость Скверны" },
    ["Demonfire"]    = { "Демоническим огнем", "Демоническим огнем", "Демонического огня",
                         "Демоническому огню", "Демоническом огне", "Демонический огонь" },
    ["Reaped Souls"] = { "Пожатыми душами", "Пожатых душ", "Пожатым душам", "Пожатые души" },
    ["Life Force"]   = { "жизненной силой", "жизненную силу", "жизненной силы",
                         "жизненная сила" },
    ["Embers"]       = { "Углями", "Углей", "Углям", "Угли" },
    ["Ember"]        = { "Углем", "Углем", "Угля", "Углю", "Уголь" },
    ["Runic Power"]  = { "силой рун", "силы рун", "силу рун", "силе рун", "сила рун" },
    ["Focus"]        = { "концентрацией", "концентрации", "концентрацию", "концентрация" },
    ["Rage"]         = { "яростью", "ярости", "ярость" },
    ["Energy"]       = { "энергией", "энергии", "энергию", "энергия" },
    ["Mana"]         = { "маной", "маны", "мане", "ману", "мана" },

    ["Undead"]       = { "нежити", "нежитью", "нежитей", "нежить" },
    ["Raised"]       = { "поднятыми", "поднятого", "поднятому", "поднятых", "поднятые",
                         "поднятой", "поднятым", "поднятый" },
    ["Command"]      = { "приказом", "приказа", "приказу", "приказе", "приказ" },
    ["Glacial Ward"] = { "ледникового оберега", "ледниковым оберегом", "ледниковом обереге",
                         "ледниковому оберегу", "ледниковый оберег" },
    ["Lesser Skeletal Warrior"] = { "малым скелетом-воином", "малого скелета-воина",
                         "малом скелете-воине", "малому скелету-воину", "малый скелет-воин" },
    ["Greater Skeletal Warrior"] = { "большим скелетом-воином", "большого скелета-воина",
                         "большом скелете-воине", "большому скелету-воину", "большой скелет-воин" },
    ["Crypt Fiend"]  = { "порождением склепа", "порождения склепа", "порождению склепа",
                         "порождении склепа", "порождений склепа", "порождениям склепа",
                         "порождение склепа" },
    ["Bone Reliquary"] = { "костяными реликвариями", "костяных реликвариев", "костяные реликварии",
                         "костяному реликварию", "костяным реликварием", "костяном реликварии",
                         "костяного реликвария", "костяной реликварий" },
    ["Corpse Dust"]  = { "Трупным прахом", "Трупного праха", "Трупному праху", "Трупном прахе",
                         "Трупный прах" },
    ["Skeletal Rogue"] = { "скелетом-разбойником", "скелета-разбойника", "скелету-разбойнику",
                         "скелете-разбойнике", "скелет-разбойник" },
    ["Gravebound Champion"] = { "могильным воителем", "могильного воителя", "могильному воителю",
                         "могильном воителе", "могильный воитель" },
    ["Bone Ward"]    = { "костяным оберегом", "костяного оберега", "костяному оберегу",
                         "костяном обереге", "костяной оберег" },

    ["Weak Thunder Ale"] = { "слабым громовым элем", "слабого громового эля", "слабому громовому элю",
                         "слабом громовом эле", "слабый громовой эль" },

    ["Tankard"]      = { "кружкам", "кружках", "кружкой", "кружки", "кружку", "кружке", "кружка",
                         "кружек" },

    ["Effigy"]       = { "изваяниями", "изваяниях", "изваяниям", "изваянием", "изваяния", "изваяний",
                         "изваянию", "изваянии", "изваяние" },
    ["Effigies"]     = { "изваяниями", "изваяниях", "изваяниям", "изваяния", "изваяний", "изваяние" },
    ["Idol"]         = { "идолами", "идолах", "идолам", "идолов", "идолом", "идолы", "идола", "идолу",
                         "идоле", "идол" },
    ["Idols"]        = { "идолами", "идолах", "идолам", "идолов", "идолы", "идол" },
    ["Ward"]         = { "оберегами", "оберегах", "оберегам", "оберегов", "оберегом", "оберега",
                         "оберегу", "обереги", "обереге", "оберег" },
    ["Wards"]        = { "оберегами", "оберегах", "оберегам", "оберегов", "обереги", "оберег" },
    ["Cauldron"]     = { "котлами", "котлах", "котлам", "котлов", "котлом", "котла", "котлу", "котле",
                         "котел", "котел" },
    ["Ingredients"]  = { "ингредиентами", "ингредиентах", "ингредиентам", "ингредиентов",
                         "ингредиенты", "ингредиент" },
    ["Jinx"]         = { "сглазами", "сглазах", "сглазам", "сглазов", "сглазом", "сглаза", "сглазу",
                         "сглазе", "сглазы", "сглаз" },
    ["Spirit"]       = { "духами", "духах", "духам", "духов", "духом", "духа", "духу", "духе",
                         "духи", "дух" },
    ["Spirits"]      = { "духами", "духах", "духам", "духов", "духи", "дух" },
    ["Potion"]       = { "зельями", "зельях", "зельям", "зелья", "зелий", "зелью", "зелье" },
    ["Shadow Effigy"] = { "теневым изваянием", "теневого изваяния", "теневому изваянию",
                          "теневом изваянии", "теневое изваяние" },
    ["Hexing Effigy"] = { "колдовским изваянием", "колдовского изваяния", "колдовскому изваянию",
                          "колдовском изваянии", "колдовское изваяние" },
    ["Graven Effigy"] = { "резным изваянием", "резного изваяния", "резному изваянию",
                          "резном изваянии", "резное изваяние" },
    ["Jungle Idol"]   = { "идолом джунглей", "идола джунглей", "идолу джунглей", "идоле джунглей",
                          "идол джунглей" },
    ["Dark Idol"]     = { "темным идолом", "темного идола", "темному идолу", "темном идоле",
                          "темный идол" },
    ["Serene Idol"]   = { "безмятежным идолом", "безмятежного идола", "безмятежному идолу",
                          "безмятежном идоле", "безмятежный идол" },
    ["Sentry Ward"]   = { "сторожевым оберегом", "сторожевого оберега", "сторожевому оберегу",
                          "сторожевом обереге", "сторожевой оберег" },
    ["Shadow Puppet"] = { "теневой марионеткой", "теневую марионетку", "теневой марионетки",
                          "теневой марионетке", "теневая марионетка" },

    ["Blacksmithing Forge"] = { "кузнечным горном", "кузнечного горна", "кузнечному горну",
                          "кузнечном горне", "кузнечный горн" },
    ["Anvil"]        = { "наковальней", "наковальню", "наковальни", "наковальне", "наковальня" },

    ["Libram"]       = { "манускриптами", "манускриптах", "манускриптам", "манускриптов",
                         "манускриптом", "манускрипта", "манускрипту", "манускрипте", "манускрипты",
                         "манускрипт" },
    ["Sacred Restraint"] = { "Священным сдерживанием", "Священного сдерживания",
                         "Священному сдерживанию", "Священном сдерживании", "Священное сдерживание" },

    ["Champion"]     = { "воителями", "воителях", "воителям", "воителем", "воителей",
                         "воители", "воителю", "воителя", "воитель" },
    ["Undead Stance"]= { "стойкой нежити", "стойки нежити", "стойку нежити", "стойке нежити",
                         "стойка нежити" },
    ["Skeletal Smith"] = { "Скелетом-кузнецом", "Скелета-кузнеца", "Скелету-кузнецу",
                         "Скелете-кузнеце", "Скелет-кузнец" },
    ["Ward"]         = { "оберегами", "оберегах", "оберегам", "оберегом", "оберегов",
                         "оберегу", "обереге", "оберега", "обереги", "оберег" },

    ["Tonic"]        = { "тониками", "тониках", "тоникам", "тоником", "тоников", "тонику",
                         "тонике", "тоника", "тоники", "тоник" },

    ["Brand"]        = { "клеймами", "клеймах", "клеймам", "клеймом", "клейму", "клейме",
                         "клейма", "клеймо", "клейм" },

    ["Ascension"]    = { "Вознесениями", "Вознесениях", "Вознесениям", "Вознесением",
                         "Вознесений", "Вознесению", "Вознесении", "Вознесения", "Вознесение" },

    ["Presence"]     = { "присутствием", "присутствии", "присутствию", "присутствия",
                         "присутствие", "обликами", "обликах", "обликам", "обликом",
                         "облике", "облику", "облика", "облик" },
    ["Ritual Stone"] = { "ритуальными камнями", "ритуальных камней", "ритуальным камнем",
                         "ритуального камня", "ритуальному камню", "ритуальном камне",
                         "ритуальные камни", "ритуальный камень" },
    ["Tentacles"]    = { "щупальцами", "щупальцах", "щупальцам", "щупалец", "щупальца" },

    ["Aspect"]       = { "аспектами", "аспектах", "аспектам", "аспектов", "аспектом",
                         "аспекту", "аспекте", "аспекта", "аспекты", "аспект" },
    ["Aspects"]      = { "аспектами", "аспектах", "аспектам", "аспектов", "аспектом",
                         "аспекту", "аспекте", "аспекта", "аспекты", "аспект" },

    ["Blast Mine"]   = { "взрывной миной", "взрывную мину", "взрывной мины", "взрывной мине",
                         "взрывные мины", "взрывная мина" },
    ["Parachute"]    = { "парашютами", "парашютах", "парашютам", "парашютом", "парашютов",
                         "парашюту", "парашюте", "парашюты", "парашюта", "парашют" },
    ["Nanobots"]     = { "нанороботами", "нанороботах", "нанороботам", "нанороботов", "нанороботы" },
    ["Beacons"]      = { "маяками", "маяках", "маякам", "маяком", "маяков", "маяку", "маяке",
                         "маяки", "маяка", "маяк" },
    ["Beacon"]       = { "маяками", "маяках", "маякам", "маяком", "маяков", "маяку", "маяке",
                         "маяки", "маяка", "маяк" },
    ["Freezing"]     = { "замораживая", "замораживает" },

    ["Glyph"]        = { "символами", "символах", "символам", "символом", "символов", "символу",
                         "символе", "символа", "символы", "символ" },
    ["Scrying Orb"]  = { "гадальными шарами", "гадальным шаром", "гадального шара",
                         "гадальному шару", "гадальном шаре", "гадальные шары", "гадальный шар" },

    ["Replenishment"] = { "Восполнением", "Восполнении", "Восполнению", "Восполнения", "Восполнение" },

    ["Seismic"]      = { "сейсмическими", "сейсмических", "сейсмическим", "сейсмическую",
                         "сейсмической", "сейсмическое", "сейсмические", "сейсмическая",
                         "сейсмический" },

    ["Venom Spitter"] = { "ядовитым плевателем", "ядовитого плевателя", "ядовитому плевателю",
                          "ядовитом плевателе", "ядовитые плеватели", "ядовитый плеватель" },
    ["Mushroom"]     = { "грибами", "грибах", "грибам", "грибом", "грибов", "грибу", "грибе",
                         "гриба", "грибы", "гриб" },

    ["Frozen"]       = { "замороженного", "замороженному", "замороженным", "замороженном",
                         "замороженные", "замороженных", "замороженными", "замороженный",
                         "замороженная", "замороженной", "замороженную", "замороженное" },
    ["Frozen Target"] = { "замороженную цель", "замороженной цели", "замороженной целью",
                          "замороженная цель" },

    ["Raise"]        = { "поднятия", "поднятий", "поднятиями", "поднятиям", "поднятии",
                         "поднятие" },
    ["Animates"]     = { "оживления", "оживлений", "оживлениями", "оживлениям", "оживлении",
                         "оживление" },
    ["Animate"]      = { "оживления", "оживлений", "оживлениями", "оживлениям", "оживлении",
                         "оживление" },
    ["Standard"]     = { "штандартом", "штандарта", "штандарту", "штандарте", "штандарты",
                         "штандартов", "штандарт" },

    ["War Falcons"] = { "боевыми соколами", "боевых соколов", "боевым соколом",
                        "боевого сокола", "боевому соколу", "боевом соколе",
                        "боевые соколы", "боевой сокол" },
    ["War Falcon"]  = { "боевыми соколами", "боевых соколов", "боевым соколом",
                        "боевого сокола", "боевому соколу", "боевом соколе",
                        "боевые соколы", "боевой сокол" },
    ["Quivers"] = { "колчанами", "колчанов", "колчаны", "колчаном", "колчана",
                    "колчану", "колчане", "колчан" },
    ["Quiver"]  = { "колчанами", "колчанов", "колчаны", "колчаном", "колчана",
                    "колчану", "колчане", "колчан" },
    ["Crude Leather"]  = { "Сырую кожу", "сырую кожу", "Сырая кожа", "сырой кожи", "сырая кожа" },
    ["Light Leather"]  = { "Легкая кожа", "легкой кожи", "легкая кожа" },
    ["Medium Leather"] = { "Кожа средней плотности", "кожи средней плотности" },
    ["Heavy Leather"]  = { "Плотная кожа", "плотной кожи", "плотная кожа" },
    ["Thick Leather"]  = { "Толстая кожа", "толстой кожи", "толстая кожа" },
    ["Rugged Leather"] = { "Грубая кожа", "грубой кожи", "грубая кожа" },

    ["Glider"]  = { "планерами", "планерах", "планерам", "планером", "планеров", "планеру",
                    "планере", "планеры", "планера", "планер" },
    ["Gliders"] = { "планерами", "планерах", "планерам", "планером", "планеров", "планеры", "планер" },
    ["Map"]     = { "картами", "картах", "картам", "картой", "карту", "карты", "карте", "карта" },
    ["Campsite"]= { "стоянками", "стоянках", "стоянкам", "стоянкой", "стоянку", "стоянки",
                    "стоянке", "стоянка" },
    ["Campfire"]= { "костром", "костра", "костру", "костре", "костры", "костер", "костер" },
    ["Twineweave Line"] = { "плетеную леску", "плетеную леску", "плетеной лески", "плетеной лески",
                    "плетеная леска", "плетеная леска" },
    ["Rider's Harness"] = { "наезднической упряжью", "наездническую упряжь", "наезднической упряжи",
                    "наездническая упряжь" },
    ["Skinner's Grip"]  = { "захватом снятия шкур", "захвата снятия шкур", "захвату снятия шкур",
                    "захвате снятия шкур", "захват снятия шкур" },

    ["Horn"]    = { "рогами", "рогах", "рогам", "рогом", "рогов", "рогу", "роге", "рога", "рог" },

    ["Shadowgem"] = { "Тенемелом", "Тенемела", "Тенемелу", "Тенемеле", "Тенемел" },
    ["Faceless Destroyer"] = { "безликим разрушителем", "безликого разрушителя",
                         "безликому разрушителю", "безликом разрушителе", "безликий разрушитель" },
    ["Tentacle of the Old Gods"] = { "щупальцем Древних богов", "щупальца Древних богов",
                         "щупальцу Древних богов", "щупальце Древних богов" },
    ["Tentacle of Yogg-Saron"] = { "щупальцем Йогг-Сарона", "щупальца Йогг-Сарона",
                         "щупальцу Йогг-Сарона", "щупальце Йогг-Сарона" },
    ["Madness"]  = { "Безумием", "Безумия", "Безумию", "Безумии", "Безумие" },

    ["Elemental Fire"] = { "Огнем стихий", "Огнем стихий", "Огня стихий", "Огню стихий",
                         "Огне стихий", "Огонь стихий" },
}

local function mergeForms(src)
    if not src then return end
    for en, gen in pairs(src) do
        local cur = TERM_FORMS[en]
        if not cur then
            TERM_FORMS[en] = gen
        else
            local seen = {}
            for _, f in ipairs(cur) do seen[f] = true end
            for _, f in ipairs(gen) do
                if not seen[f] then cur[#cur + 1] = f; seen[f] = true end
            end
        end
    end
end

mergeForms(CoARU_SKILL_TERMS)

mergeForms(CoARU_NAME_FORMS)

mergeForms(CoARU_TERM_WAVE)

mergeForms(CoARU_TERM_GROW)

function CoARU_TermForms(en)
    return TERM_FORMS[en]
end

local function flipFirstCase(s)
    local b1, b2 = s:byte(1), s:byte(2)
    if not b2 then return nil end
    if b1 == 208 then
        if b2 >= 144 and b2 <= 159 then return string.char(208, b2 + 32) .. s:sub(3) end
        if b2 >= 160 and b2 <= 175 then return string.char(209, b2 - 32) .. s:sub(3) end
        if b2 >= 176 and b2 <= 191 then return string.char(208, b2 - 32) .. s:sub(3) end
    elseif b1 == 209 and b2 >= 128 and b2 <= 143 then
        return string.char(208, b2 + 32) .. s:sub(3)
    end
    return nil
end

local function letterByteAt(s, i)
    local b = s:byte(i)
    if not b then return false end
    if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) then return true end
    if b == 208 or b == 209 then return true end
    if b >= 128 and b <= 191 then
        local lead = s:byte(i - 1)
        return lead == 208 or lead == 209
    end
    return false
end

local function digitByteAt(s, i)
    local b = s:byte(i)
    return b ~= nil and b >= 48 and b <= 57
end

local function wholeWord(s, first, last)
    if digitByteAt(s, first) and digitByteAt(s, first - 1) then return false end
    if digitByteAt(s, last) and digitByteAt(s, last + 1) then return false end
    if letterByteAt(s, first - 1) then

        if s:sub(first - 2, first - 2) ~= "|" then return false end
    end
    return not letterByteAt(s, last + 1)
end

local function findOutsideColor(ru, needle, start)
    local from = start or 1
    while true do
        local s, e = ru:find(needle, from, true)
        if not s then return nil end
        local before = ru:sub(1, s - 1)
        local _, opens = before:gsub("|[cC]%x%x%x%x%x%x%x%x", "")
        local _, closes = before:gsub("|[rR]", "")
        if opens <= closes and wholeWord(ru, s, e) then return s, e end
        from = e + 1
    end
end

local function countOutside(ru, needle)
    local n, pos = 0, 1
    while true do
        local s, e = findOutsideColor(ru, needle, pos)
        if not s then return n end
        n = n + 1
        pos = e + 1
    end
end

local function stemForms(nm)
    local n = #nm - 2
    if n < 8 then return {} end
    return { nm:sub(1, n) }
end

local function wordStem(w)
    local n = #w - 6
    if n < 8 then return w end
    return w:sub(1, n)
end

local function matchPhrase(ru, pos, words)
    local p = pos
    for i = 1, #words do
        if i > 1 then
            if ru:sub(p, p) ~= " " then return nil end
            p = p + 1
        end
        local stem = wordStem(words[i])
        if ru:sub(p, p + #stem - 1) ~= stem then return nil end
        p = p + #stem

        local extra = 0
        while extra < 4 do
            local b = ru:byte(p)
            if b == 208 or b == 209 then p = p + 2; extra = extra + 1 else break end
        end
    end
    return p - 1
end

local function wrapByStem(ru, nm, color, restore)

    if nm:find(" ", 1, true) then
        local words = {}
        for w in nm:gmatch("[^ ]+") do words[#words + 1] = w end
        local head = wordStem(words[1])
        if #head < 6 then return nil end
        local pos = 1
        while true do
            local s = ru:find(head, pos, true)
            if not s then return nil end
            local before = ru:sub(1, s - 1)
            local _, opens = before:gsub("|[cC]%x%x%x%x%x%x%x%x", "")
            local _, closes = before:gsub("|[rR]", "")
            local last = matchPhrase(ru, s, words)
            if last and opens <= closes and not letterByteAt(ru, s - 1)
               and not letterByteAt(ru, last + 1) then
                return ru:sub(1, s - 1) .. color .. ru:sub(s, last) .. "|r"
                       .. (restore or "") .. ru:sub(last + 1)
            end
            pos = s + 1
        end
    end
    for _, stem in ipairs(stemForms(nm)) do
        local pos = 1
        while true do
            local s, e = ru:find(stem, pos, true)
            if not s then break end
            local before = ru:sub(1, s - 1)
            local _, opens = before:gsub("|[cC]%x%x%x%x%x%x%x%x", "")
            local _, closes = before:gsub("|[rR]", "")

            local last = e
            for _ = 1, 3 do
                local b = ru:byte(last + 1)
                if b == 208 or b == 209 then last = last + 2 else break end
            end
            if opens <= closes and not letterByteAt(ru, s - 1)
               and not letterByteAt(ru, last + 1) then
                return ru:sub(1, s - 1) .. color .. ru:sub(s, last) .. "|r"
                       .. (restore or "") .. ru:sub(last + 1)
            end
            pos = e + 1
        end
    end
    return nil
end

local function wrapFirst(ru, needle, color, restore)
    local s, e = findOutsideColor(ru, needle)
    if not s then
        local alt = flipFirstCase(needle)
        if not alt then return nil end
        s, e = findOutsideColor(ru, alt)
        if not s then return nil end
        needle = alt
    end
    return ru:sub(1, s - 1) .. color .. needle .. "|r" .. (restore or "") .. ru:sub(e + 1)
end

local function leadingSpanCoversAll(line)
    local pos, depth, n = 1, 0, #line
    while true do
        local cs, ce = line:find("|[cC]%x%x%x%x%x%x%x%x", pos)
        local rs, re = line:find("|[rR]", pos)
        if not cs and not rs then return false end
        if cs and (not rs or cs < rs) then
            depth = depth + 1
            pos = ce + 1
        else
            depth = depth - 1
            if depth <= 0 then

                return line:sub(re + 1):find("%S") == nil
            end
            pos = re + 1
        end
    end
end

local VALUE_UNITS = {
    ["sec"]     = { "сек.", "сек" },
    ["secs"]    = { "сек.", "сек" },
    ["second"]  = { "секунду", "сек.", "сек" },
    ["seconds"] = { "секунды", "секунд", "сек.", "сек" },
    ["min"]     = { "мин.", "мин" },
    ["mins"]    = { "мин.", "мин" },
    ["minute"]  = { "минуту", "мин.", "мин" },
    ["minutes"] = { "минуты", "минут", "мин.", "мин" },
    ["hour"]    = { "часа", "час", "ч.", "ч" },
    ["hours"]   = { "часов", "часа", "ч.", "ч" },
    ["hr"]      = { "ч.", "ч" },
    ["hrs"]     = { "ч.", "ч" },
    ["day"]     = { "день", "дня", "дн.", "д." },
    ["days"]    = { "дней", "дня", "дн.", "д." },
}

local function countValueSpans(line, term, unwrapped)
    local n, p = 0, 1
    while true do
        local s, e, _, body = line:find("(|[cC]%x%x%x%x%x%x%x%x)(.-)|[rR]", p)
        if not s then return n end
        p = e + 1
        if (unwrapped or s > 1) and body and body ~= "" then
            local t = CoARU_StripCodes(body)
            t = t and t:match("^%s*(.-)%s*$")
            if t == term then n = n + 1 end
        end
    end
end

local function reapplyInnerColors(line, ru, restore, unwrapped)
    if ru:find("|c", 1, true) then return ru end

    local ru0 = ru
    local pos = 1

    local pendColor, pendCount = nil, 0
    while true do

        local s, e, color, body = line:find("(|[cC]%x%x%x%x%x%x%x%x)(.-)|[rR]", pos)
        if not s then break end
        pos = e + 1

        if (unwrapped or s > 1) and body and body ~= "" then
            local term = CoARU_StripCodes(body)
            term = term and term:match("^%s*(.-)%s*$")

            if term and (#term > 1 or term:match("^%d$")) then

                local isNum = term:match("^[%d%.,]+%%?$") ~= nil
                local done = (not isNum) and wrapFirst(ru, term, color, restore) or nil
                if not done then
                    for _, form in ipairs(TERM_FORMS[term] or {}) do
                        done = wrapFirst(ru, form, color, restore)
                        if done then break end
                    end
                end
                if not done and CoARU_SPELL_NAME_RU then

                    local nm = CoARU_SPELL_NAME_RU[term]
                    if nm and nm ~= term
                       and not (term:find(" ", 1, true) and not nm:find(" ", 1, true)) then
                        done = wrapFirst(ru, nm, color, restore)
                    end
                end
                if not done and CoARU_ItemNameEN then

                    local it = CoARU_ItemNameEN[term]
                    if it and it ~= term
                       and not (term:find(" ", 1, true) and not it:find(" ", 1, true)) then
                        done = wrapFirst(ru, it, color, restore)
                    end
                end
                if not done then

                    local one = term:match("^(.-[^sS])s$")
                    if one and #one > 1 then done = wrapFirst(ru, one, color, restore) end
                end
                if not done then

                    local base = term:match("^(.-)%s*%(%d+%)$")
                    if base and #base > 1 then
                        for _, form in ipairs(TERM_FORMS[base] or {}) do
                            done = wrapFirst(ru, form, color, restore)
                            if done then break end
                        end
                    end
                end
                if not done and CoARU_SPELL_NAME_RU then

                    local one = term:match("^(.-[^sS])s$")
                    local nm = CoARU_SPELL_NAME_RU[term]
                              or (one and CoARU_SPELL_NAME_RU[one])
                    if nm and nm ~= term then
                        done = wrapByStem(ru, nm, color, restore)
                    end

                    if not done and not one then
                        done = wrapFirst(ru, term .. "s", color, restore)
                        if not done then
                            local many = CoARU_SPELL_NAME_RU[term .. "s"]
                            if many and many ~= term then
                                done = wrapByStem(ru, many, color, restore)
                            end
                        end
                    end
                end
                if not done then

                    local num, unit = term:match("^([%d%.,]+)%s+(%a+)$")
                    if num then
                        for _, form in ipairs(VALUE_UNITS[unit:lower()] or {}) do
                            done = wrapFirst(ru, num .. " " .. form, color, restore)
                            if done then break end
                        end
                    end
                end
                if not done then

                    local a, b, pct = term:match("^([%d%.,]+)%s+to%s+([%d%.,]+)(%%?)$")
                    if a then
                        local seps = pct == "%" and { "–", "-", " до " } or { " до ", "–", "-" }
                        for _, s in ipairs(seps) do
                            done = wrapFirst(ru, a .. s .. b .. pct, color, restore)
                            if done then break end
                        end
                    end
                end
                if not done then

                    local only = term:match("^([%d%.,]+%%?)$")
                    if only and countValueSpans(line, only, unwrapped) == countOutside(ru0, only) then
                        done = wrapFirst(ru, only, color, restore)
                    end
                end
                if done then ru = done else pendColor, pendCount = color, pendCount + 1 end
            end
        end
    end

    if pendCount == 1 and not ru:find("|c", 1, true) then

        local qs, qe, inner = ru:find("(«.-»)")
        if qs and inner and #inner > 4 and not ru:find("«", qe + 1) then
            ru = ru:sub(1, qs - 1) .. pendColor .. inner .. "|r" .. (restore or "") .. ru:sub(qe + 1)
        end
    end
    return ru
end

local PROF = {
    ["Blacksmithing"]  = { "Кузнечному делу", "кузнечного дела", "Кузнечное дело", "кузнечному делу" },
    ["Alchemy"]        = { "Алхимии", "алхимии", "Алхимия", "алхимии" },
    ["Enchanting"]     = { "Наложению чар", "наложения чар", "Наложение чар", "наложению чар" },
    ["Engineering"]    = { "Инженерному делу", "инженерного дела", "Инженерное дело", "инженерному делу" },
    ["Leatherworking"] = { "Кожевничеству", "кожевничества", "Кожевничество", "кожевничеству" },
    ["Tailoring"]      = { "Портняжному делу", "портняжного дела", "Портняжное дело", "портняжному делу" },
    ["Herbalism"]      = { "Травничеству", "травничества", "Травничество", "травничеству" },
    ["Mining"]         = { "Горному делу", "горного дела", "Горное дело", "горному делу" },
    ["Skinning"]       = { "Снятию шкур", "снятия шкур", "Снятие шкур", "снятию шкур" },
    ["Cooking"]        = { "Кулинарии", "кулинарии", "Кулинария", "кулинарии" },
    ["First Aid"]      = { "Первой помощи", "первой помощи", "Первая помощь", "первой помощи" },
    ["Fishing"]        = { "Рыбной ловле", "рыбной ловли", "Рыбная ловля", "рыбной ловле" },
    ["Inscription"]    = { "Начертанию", "начертания", "Начертание", "начертанию" },
    ["Jewelcrafting"]  = { "Ювелирному делу", "ювелирного дела", "Ювелирное дело", "ювелирному делу" },
    ["Woodworking"]    = { "Столярному делу", "столярного дела", "Столярное дело", "столярному делу" },
    ["Woodcutting"]    = { "Лесозаготовке", "лесозаготовки", "Лесозаготовка", "лесозаготовке" },
    ["Bushcraft"]      = { "Лесному ремеслу", "лесного ремесла", "Лесное ремесло", "лесному ремеслу" },
}

local PROF_RU = {}
for _, f in pairs(PROF) do PROF_RU[f[3]] = f end

local CLASS_TRAINER = {
    ["Ranger"] = "наставника следопытов",
}

local function classTrainerRU(cls)
    if not cls or cls == "" then return "наставника класса" end
    cls = CoARU_StripCodes(cls)
    return CLASS_TRAINER[cls] or ("наставника класса «" .. cls .. "»")
end

function CoARU_TranslateProfession(line)
    if not line then return nil end

    local name, cls = line:match("^You can learn (.-) crafts from an? (.-) Trainer, which can "
                                 .. "be found by speaking to a Guard in most capital cities%.")
    local crafts = name ~= nil
    if not name then
        name = line:match("^You can learn (.-) from a .- Trainer, which can be found by "
                          .. "speaking to a Guard in most capital cities%.")
    end
    if not name then return nil end

    name = CoARU_StripCodes(name)
    local f = PROF[name] or PROF_RU[name]
    if not f then return nil end
    if crafts then

        return ("Рецептам %s можно обучиться у %s: его подскажет стражник почти в любой "
                .. "столице."):format(f[2], classTrainerRU(cls))
    end

    return ("Обучиться %s можно у соответствующего учителя: его подскажет стражник почти "
            .. "в любой столице. Кроме того, %s можно обучиться с помощью "
            .. "«Book of Artisans»."):format(f[4], f[4])
end

local STAT_PREFIX
local function statPrefixes()
    if STAT_PREFIX then return STAT_PREFIX end
    STAT_PREFIX = {}
    local seen = {}
    local function add(en, ru)
        if type(en) ~= "string" or type(ru) ~= "string" then return end
        if en == "" or #en < 3 or en:find("%%") or seen[en] then return end
        seen[en] = true
        STAT_PREFIX[#STAT_PREFIX + 1] = { en = en, ru = ru }
    end

    for key, ru in pairs(CoARU_StatLabelRU or {}) do add(CoARU_EN(key), ru) end

    for en, ru in pairs(CoARU_StatLabelOwn or {}) do add(en, ru) end

    table.sort(STAT_PREFIX, function(a, b) return #a.en > #b.en end)
    return STAT_PREFIX
end

function CoARU_TranslateStatLine(line)
    if not line then return nil end
    local plain = CoARU_StripCodes(line)
    if not plain or not plain:find("%d") then return nil end
    plain = plain:match("^%s*(.-)%s*$")
    for _, e in ipairs(statPrefixes()) do
        if plain:sub(1, #e.en) == e.en then
            local tail = plain:sub(#e.en + 1)

            if tail:find("^%s+[%d%s%+%-%(%)%/%.,%%]*$") and tail:find("%d") then
                return e.ru .. tail
            end
        end
    end
    return nil
end

local UNIT_KIND = {
    ["Beast"] = "животное", ["Humanoid"] = "гуманоид", ["Undead"] = "нежить",
    ["Demon"] = "демон", ["Elemental"] = "элементаль", ["Giant"] = "великан",
    ["Dragonkin"] = "дракон", ["Mechanical"] = "механизм", ["Critter"] = "существо",
    ["Totem"] = "тотем", ["Uncategorized"] = "без категории",
    ["Not specified"] = "не указано", ["Gas Cloud"] = "облако газа",
}

local UNIT_RACE = {
    ["Human"] = "человек", ["Orc"] = "орк", ["Dwarf"] = "дворф",
    ["Night Elf"] = "ночной эльф", ["Undead"] = "нежить", ["Tauren"] = "таурен",
    ["Gnome"] = "гном", ["Troll"] = "тролль", ["Blood Elf"] = "эльф крови",
    ["Draenei"] = "дреней", ["Goblin"] = "гоблин", ["Worgen"] = "ворген",
    ["Pandaren"] = "пандарен", ["Scourge"] = "нежить", ["Forsaken"] = "нежить",
    ["High Elf"] = "высший эльф", ["Naga"] = "нага", ["Vrykul"] = "врайкул",
    ["Broken"] = "сломленный", ["Felblood Elf"] = "эльф Скверны",
}

local UNIT_TAG = {
    ["Elite"] = "элитный", ["Rare"] = "редкий", ["Rare Elite"] = "редкий элитный",
    ["Player"] = "игрок", ["Boss"] = "босс", ["Player Corpse"] = "труп игрока",
    ["элитный"] = "элитный", ["редкий"] = "редкий", ["игрок"] = "игрок",
    ["босс"] = "босс",
}

local function isPlayerTag(tag)
    return tag == "Player" or tag == "игрок"
end

function CoARU_UnitWordRU(en)
    if type(en) ~= "string" or en == "" then return nil end
    return UNIT_KIND[en] or UNIT_RACE[en] or UNIT_TAG[en]
end

local function levelSplit(plain)
    local lvl, rest = plain:match("^Level%s+(%d+)%s+(.+)$")
    if lvl then return lvl .. "-й уровень", rest end
    rest = plain:match("^Level%s+%?%?%s+(.+)$")
    if rest then return "уровень ??", rest end
    lvl, rest = plain:match("^Уровень%s+(%d+),?%s+(.+)$")
    if lvl then return lvl .. "-й уровень", rest end
    rest = plain:match("^Уровень%s+%?%?,?%s+(.+)$")
    if rest then return "уровень ??", rest end
    return nil, nil
end

local function raceClassSplit(rest)
    local best, bestRu
    for en, ru in pairs(UNIT_RACE) do
        if rest:sub(1, #en) == en and (not best or #en > #best) then
            best, bestRu = en, ru
        end
    end
    if not best then return nil end
    local cls = rest:sub(#best + 1):match("^%s*(.-)%s*$")
    return bestRu, cls
end

function CoARU_TranslateRaceClass(line)
    if type(line) ~= "string" or line == "" then return nil end
    local plain = CoARU_StripCodes(line):match("^%s*(.-)%s*$")
    if not plain or plain == "" then return nil end

    local tag
    local body = plain:match("^(.-)%s*%(.-%)$")
    if body then
        tag = plain:match("%((.-)%)$")
        plain = body
    end

    local lvl, rest = levelSplit(plain)
    if not rest then rest = plain end

    local ru, cls = raceClassSplit(rest)

    if not ru or cls == "" or not CLASS_NAME[cls] then return nil end

    if tag and not isPlayerTag(tag) then return nil end

    local out
    if lvl then
        out = lvl .. ", " .. ru .. " " .. cls
    else

        out = (flipFirstCase(ru) or ru) .. " " .. cls
    end
    if tag then out = out .. " (игрок)" end
    return out
end

function CoARU_TranslateUnitLine(line)
    if not line or line == "" then return nil end
    local plain = CoARU_StripCodes(line):match("^%s*(.-)%s*$")
    if not plain or plain == "" then return nil end

    local thr = plain:match("^(%d+)%%%s+Threat$")
    if thr then return thr .. "% угрозы" end

    local pName, pLvl, pCls =
        line:match("^%s*(.-)%s%s+Level (%d+)%s+(|[cC]%x%x%x%x%x%x%x%x.+|[rR])%s*$")
    if pName and pName ~= "" then
        return pName .. "  " .. pLvl .. "-й уровень " .. pCls
    end

    local tgt = plain:match("^Targeting:%s*(.+)$")
    if tgt then
        local ru = CoARU_UNIT_N2R and CoARU_UNIT_N2R[tgt]
        return "Цель: " .. ((ru and ru ~= tgt) and ru or tgt)
    end

    local killer, klvl = plain:match("^Killer:%s*(.+)%s+%(Level%s+(%d+)%)$")
    if killer then
        local ru = CoARU_UNIT_N2R and CoARU_UNIT_N2R[killer]
        if ru and ru ~= killer then
            return ("Убийца: %s (уровень %s)"):format(ru, klvl)
        end
        return nil
    end

    local abil, by = plain:match("^([%a%s'%-]+)%s+by%s+([%a%s'%-]+)$")
    if abil then
        local aru = (abil == "Melee") and "Удар в ближнем бою"
            or (CoARU_SPELL_NAME_RU and CoARU_SPELL_NAME_RU[abil])
        local uru = CoARU_UNIT_N2R and CoARU_UNIT_N2R[by]
        if aru and aru ~= abil and uru and uru ~= by then
            return ("%s: %s"):format(aru, uru)
        end
        return nil
    end

    local owner = plain:match("^([%a%d]+)'s Guardian$")
    if owner then return "Страж " .. owner end

    local lvl, rest = levelSplit(plain)
    if lvl then
        local tag
        local body = rest:match("^(.-)%s*%((.-)%)$")
        if body then
            tag = rest:match("%((.-)%)$")
            rest = body
        end

        if isPlayerTag(tag) then
            local ru = CoARU_TranslateRaceClass(plain)
            if ru then return ru end

            local bestRu, cls = raceClassSplit(rest)
            if not bestRu then return nil end
            local out = lvl .. ", " .. bestRu
            if cls ~= "" then out = out .. " " .. cls end
            return out .. " (игрок)"
        end

        local ru = UNIT_KIND[rest]
        if not ru and CoARU_HasCyrillic(rest) then
            ru = flipFirstCase(rest) or rest
        end
        if not ru then return nil end
        local out = lvl .. ", " .. ru
        if tag then
            out = out .. " (" .. (UNIT_TAG[tag] or tag) .. ")"
        end
        return out
    end
    return nil
end

local LABEL_HEAD = {
    ["Upgrades"] = "Апгрейды",
    ["Strength"] = "Сила",
    ["Agility"] = "Ловкость",
    ["Stamina"] = "Выносливость",
    ["Intellect"] = "Интеллект",
    ["Spirit"] = "Дух",
}

function CoARU_TranslateLabelHead(line)
    if not line then return nil end
    local label, tail = line:match("^(%a[%a%s]*):%s(.+)$")
    if not label then return nil end
    local ru = LABEL_HEAD[label]
    if not ru then return nil end
    return ru .. ": " .. tail
end

CoARU_STANDING_RU = { "Ненависть", "Враждебность", "Неприязнь", "Равнодушие",
                      "Дружелюбие", "Уважение", "Почтение", "Превознесение" }
local STANDING_EN = { "Hated", "Hostile", "Unfriendly", "Neutral",
                      "Friendly", "Honored", "Revered", "Exalted" }
local standingMap

local function standingRU(word)
    if standingMap == nil then
        standingMap = {}
        for i = 1, #STANDING_EN do
            local ru = CoARU_STANDING_RU[i]
            if type(ru) == "string" and ru ~= "" then standingMap[STANDING_EN[i]] = ru end
        end
    end
    return standingMap[word]
end

function CoARU_FactionNameRU(name)
    if type(name) ~= "string" or name == "" or type(CoARU_FACTION_RU) ~= "table" then
        return nil
    end
    local ru = CoARU_FACTION_RU[name]

    if type(ru) ~= "string" or ru == "" or ru == name then return nil end
    return ru
end

function CoARU_BracketItemLineRU(line)
    if type(line) ~= "string" or type(CoARU_ItemNameEN) ~= "table" then return nil end
    local name, tail = line:match("^%s*%[(.+)%](%s*x%s*%d+%s*)$")
    if not name then return nil end
    local ru = CoARU_ItemNameEN[name]
    local qual = ""
    if not ru then
        local core, paren = name:match("^(.-)%s*(%(.+%))$")
        if core then
            ru = CoARU_ItemNameEN[core]
            qual = " " .. paren
        end
    end
    if not ru or ru == "" or ru == name then return nil end
    return "[" .. ru .. qual .. "]" .. tail
end

function CoARU_ObjectiveCountLineRU(line, ask)
    if type(line) ~= "string" then return nil end
    local core, tail = line:match("^%s*%-%s*(.-)%s*(x%s*%d+)%s*$")

    local sep = " "
    if not core or core == "" then
        core, tail = line:match("^%s*%-%s*(.-):%s*(%d+/%d+)%s*$")
        if not core or core == "" then
            local pct
            core, tail, pct = line:match("^%s*%-%s*(.-):%s*(%d+/%d+)%s*(%[%d+%%%])%s*$")
            if core and core ~= "" then tail = tail .. " " .. pct end
        end
        if core and core ~= "" then sep = ": " end
    end
    if not core or core == "" then return nil end
    local ru
    if type(ask) == "function" then ru = ask(core) end
    if not ru and CoARU_UNIT_N2R then ru = CoARU_UNIT_N2R[core] end
    if not ru and CoARU_ItemNameEN then ru = CoARU_ItemNameEN[core] end
    if not ru and CoARU_QuestLookup then
        local ok, got = pcall(CoARU_QuestLookup, core)
        if ok then ru = got end
    end
    if not ru or ru == "" or ru == core then return nil end
    return "- " .. ru .. sep .. tail
end

function CoARU_InEditBox(obj)
    if not obj or not obj.GetParent then return false end
    local ok, p = pcall(obj.GetParent, obj)
    local depth = 0
    while ok and p and depth < 6 do
        local kind = p.GetObjectType and p:GetObjectType()
        if kind == "EditBox" then return true end
        ok, p = pcall(p.GetParent, p)
        depth = depth + 1
    end
    return false
end

local REGION_NAMES = { "Eastern Kingdoms", "Kalimdor", "Outland", "Northrend" }

local function zoneRU(name)
    if not CoARU_ZONE or name == "" then return nil end

    local cands = { name, "The " .. name, name .. " City", "The " .. name .. " City" }
    for i = 1, #cands do
        local ru = CoARU_ZONE[cands[i]]
        if ru and ru ~= "" and ru ~= name then return ru end
    end
    return nil
end

local function regionListMultiline(text, one)
    if not text:find("\n", 1, true) then return nil end
    local out, changed = {}, false
    for part in (text .. "\n"):gmatch("(.-)\n") do
        local ru = one(part)
        if ru then
            out[#out + 1] = ru
            changed = true
        else
            if part:find("%S") and not CoARU_HasCyrillic(part) then return nil end
            out[#out + 1] = part
        end
    end
    if not changed then return nil end
    return table.concat(out, "\n")
end

function CoARU_RegionZoneListRU(line)
    if type(line) ~= "string" or not CoARU_ZONE then return nil end
    if not line:find(":", 1, true) then return nil end
    if line:find("\n", 1, true) then
        return regionListMultiline(line, CoARU_RegionZoneListRU)
    end

    local pre, mid, post = line:match("^(|c%x%x%x%x%x%x%x%x)(.*)(|[rR])$")
    if pre and not mid:find("|c", 1, true) then
        local ru = CoARU_RegionZoneListRU(mid)
        return ru and (pre .. ru .. post) or nil
    end

    local hdrColor = line:match("|c(%x%x%x%x%x%x%x%x)[^|:]-:|[rR]")
    if hdrColor then
        line = line:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|[rR]", "")
    end

    if line:find("|c", 1, true) then return nil end

    local marks = {}
    for i = 1, #REGION_NAMES do
        local at, name = 1, REGION_NAMES[i]
        while true do
            local s, e = line:find(name .. ":", at, true)
            if not s then break end
            marks[#marks + 1] = { s = s, e = e, name = name }
            at = e + 1
        end
    end
    if #marks == 0 then return nil end
    table.sort(marks, function(a, b) return a.s < b.s end)

    if line:sub(1, marks[1].s - 1):find("%S") then return nil end

    local out, ok = {}, true
    for i = 1, #marks do
        local m = marks[i]
        local stop = (marks[i + 1] and marks[i + 1].s - 1) or #line
        local body = line:sub(m.e + 1, stop)

        local core, tail = body, ""
        while true do
            local cut = core:match("(|[nN])$") or core:match("(%s)$")
            if not cut then break end
            tail = cut .. tail
            core = core:sub(1, #core - #cut)
        end
        local dot = ""
        local trimmed = core:match("^(.-)%.%s*$")
        if trimmed then core, dot = trimmed, "." end

        local region = zoneRU(m.name)
        if not region then ok = false break end

        local places = {}
        for piece in (core .. ","):gmatch("%s*(.-)%s*,") do
            if piece ~= "" then
                local ru = zoneRU(piece)
                if not ru then ok = false break end
                places[#places + 1] = ru
            end
        end
        if not ok or #places == 0 then ok = false break end
        local head = region .. ":"
        if hdrColor then head = "|c" .. hdrColor .. head .. "|r" end
        out[#out + 1] = head .. " " .. table.concat(places, ", ") .. dot .. tail
    end
    if not ok then return nil end
    return table.concat(out)
end

local DUR_UNIT = {
    sec = "сек.", secs = "сек.", second = "сек.", seconds = "сек.",
    min = "мин.", mins = "мин.", minute = "мин.", minutes = "мин.",
    hr = "ч.", hrs = "ч.", hour = "ч.", hours = "ч.",
}

function CoARU_BuffDurationLineRU(line)
    if type(line) ~= "string" then return nil end
    local name, num, unit = line:match("^%s*(.-)%s*%((%d+)%s+([^()]+)%)%s*$")
    if not name or name == "" then return nil end

    local ru_unit
    if CoARU_HasCyrillic(unit) then
        ru_unit = unit
    else
        ru_unit = DUR_UNIT[unit:lower()]
    end
    if not ru_unit then return nil end
    local ru = CoARU_SPELL_NAME_RU and CoARU_SPELL_NAME_RU[name]
    if not ru and CoARU_TranslateByIndex then
        local ok, res = pcall(CoARU_TranslateByIndex, name)
        if ok then ru = res end
    end

    if type(ru) ~= "string" or ru == "" or ru == name or not CoARU_HasCyrillic(ru) then
        return nil
    end
    return ru .. " (" .. num .. " " .. ru_unit .. ")"
end

function CoARU_FactionLineRU(line)
    if type(line) ~= "string" or line == "" then return nil end
    local whole = CoARU_FactionNameRU(line)
    if whole then return whole end
    local name, gap, standing = line:match("^(.-)(%s*%-%s*)(%S.*)$")
    if not name then return nil end
    local ruName = CoARU_FactionNameRU(name)
    if not ruName then return nil end
    local ruStanding = standingRU(standing) or (CoARU_HasCyrillic(standing) and standing)
    if not ruStanding then return nil end
    return ruName .. gap .. ruStanding
end

local inLabelBody = false

local function labelBodyStage(line)
    if inLabelBody then return nil end
    inLabelBody = true
    local r
    if CoARU_TranslateItemLabelBody then
        local ok, res = pcall(CoARU_TranslateItemLabelBody, line)
        if ok and res and res ~= line then r = res end
    end
    if not r and CoARU_TranslateItemLabel then
        local ok, res = pcall(CoARU_TranslateItemLabel, line)
        if ok and res and res ~= line then r = res end
    end
    inLabelBody = false
    return r
end

local LINE_STAGES = {

    { "правило движка", function(_, line) return CoARU_TranslateRaceClass(line) end },
    { "база",          function(id, line) return id and CoARU_TranslateText(id, line) end },
    { "карта аддона",  function(_, line) return CoARU_TranslateGlobal(line) end },
    { "база",          function(_, line) return CoARU_TranslateByIndex(line) end },

    { "база",          function(_, line)
        if not CoARU_UnfixTimeUnits then return nil end
        local cands = CoARU_UnfixTimeUnits(line)
        if CoARU_UnfixEnTimeDot then
            local dot = CoARU_UnfixEnTimeDot(line)
            for i = 1, #dot do cands[#cands + 1] = dot[i] end
        end
        for i = 1, #cands do
            local ru = CoARU_TranslateByIndex and CoARU_TranslateByIndex(cands[i])
            if ru and ru ~= cands[i] then return ru end
        end
        return nil
    end },

    { "база",          function(_, line) return labelBodyStage(line) end },

    { "карта аддона",  function(_, line)
        return CoARU_FactionLineRU and CoARU_FactionLineRU(line) end },

    { "карта аддона",  function(_, line)
        return CoARU_BracketItemLineRU and CoARU_BracketItemLineRU(line) end },

    { "правило движка", function(_, line)
        return CoARU_ObjectiveCountLineRU and CoARU_ObjectiveCountLineRU(line, function(core)
            local ru = CoARU_TranslateGlobal and CoARU_TranslateGlobal(core)
            if not ru and CoARU_TranslateByIndex then ru = CoARU_TranslateByIndex(core) end
            return ru
        end) end },

    { "правило движка", function(_, line)
        return CoARU_BuffDurationLineRU and CoARU_BuffDurationLineRU(line) end },

    { "правило движка", function(_, line)
        return CoARU_RegionZoneListRU and CoARU_RegionZoneListRU(line) end },

    { "правило движка", function(_, line)
        return CoARU_FixTimeUnits and CoARU_FixTimeUnits(line) end },

    { "правило движка", function(_, line)
        if not CoARU_TimeRemaining then return nil end
        local ru = CoARU_TimeRemaining(line)
        return ru
    end },
    { "правило движка", function(_, line) return CoARU_TranslateClass(line) end },
    { "правило движка", function(_, line) return CoARU_TranslateRequires(line) end },
    { "правило движка", function(_, line) return CoARU_TranslateReagents(line) end },
    { "правило движка", function(_, line) return CoARU_TranslateTransmog(line) end },
    { "правило движка", function(_, line) return CoARU_TranslateIconItemName(line) end },
    { "правило движка", function(_, line) return CoARU_TranslateProfession(line) end },
    { "правило движка", function(_, line) return CoARU_TranslateStatLine(line) end },
    { "правило движка", function(_, line) return CoARU_TranslateUnitLine(line) end },
    { "карта аддона",  function(_, line)
        return CoARU_TranslateItemPrefix and CoARU_TranslateItemPrefix(line) end },

    { "карта аддона",  function(_, line)
        return CoARU_TranslateStatCombo and CoARU_TranslateStatCombo(line) end },

    { "правило движка", function(_, line) return CoARU_TranslateLabelHead(line) end },
}

local lastSource

function CoARU_TakeSource()
    local s = lastSource
    lastSource = nil
    return s
end

function CoARU_SetSource(s)
    lastSource = s
end

local function translateLineInner(id, line)
    local ru, echo, echoSource
    lastSource = nil
    for i = 1, #LINE_STAGES do
        local stage = LINE_STAGES[i]
        local got = stage[2](id, line)
        if got and got ~= line then
            ru = got
            lastSource = stage[1]
            break
        elseif got and echo == nil then
            echo, echoSource = got, stage[1]
        end
    end
    if not ru and echo then
        ru = echo
        lastSource = echoSource
    end
    if not ru then return nil end

    if ru:find("|c", 1, true) then
        local base = line and line:match("^(|[cC]%x%x%x%x%x%x%x%x)")

        if base and line:match("|[rR]%s*$") then
            local _, n = line:gsub(base, "")
            if n > 1 then
                return base .. ru:gsub("|[rR]", "%0" .. base) .. "|r"
            end
        end
        return ru
    end

    local color = line:match("^(|[cC]%x%x%x%x%x%x%x%x)")

    if color then
        local pos = #color + 1
        while true do
            local nxt = line:match("^(|[cC]%x%x%x%x%x%x%x%x)", pos)
            if not nxt then break end
            color = nxt
            pos = pos + #nxt
        end
    end

    if not color then return reapplyInnerColors(line, ru) end

    local lbl, rest = line:match("^|[cC]%x%x%x%x%x%x%x%x(.-)|[rR]:%s*(.+)$")
    local colonInside = false
    if not lbl then
        lbl, rest = line:match("^|[cC]%x%x%x%x%x%x%x%x(.-):|[rR]%s*(.+)$")
        colonInside = true
    end

    if lbl and (lbl:find("|[cC]") or lbl:find("|[rR]")) then
        lbl, rest = nil, nil
    end
    if lbl and rest then

        local ruLabel, ruRest = ru:match("^(.-):%s*(.+)$")
        if ruLabel and ruRest then

            ruRest = reapplyInnerColors(rest, ruRest)
            if colonInside then
                return color .. ruLabel .. ":|r " .. ruRest
            end
            return color .. ruLabel .. "|r: " .. ruRest
        end
    end

    local baseColorReopened = false
    if color then
        local _, n = line:gsub(color, "")
        baseColorReopened = n > 1 and line:match("|[rR]%s*$") ~= nil
    end
    if not leadingSpanCoversAll(line) and not baseColorReopened then
        local painted = reapplyInnerColors(line, ru, nil, true)

        if painted ~= ru then return painted end
    end

    local inner = line:gsub("^|[cC]%x%x%x%x%x%x%x%x", "", 1):gsub("|r$", "")

    local itex = ""
    while true do
        local t = inner:match("^|T.-|t%s*")
        if not t then break end
        itex, inner = itex .. t, inner:sub(#t + 1)
    end
    return color .. itex .. reapplyInnerColors(inner, ru, color, true) .. "|r"
end

local function countNums(s)
    local n = 0
    for _ in (s:gsub("|[cC]%x%x%x%x%x%x%x%x", ""):gsub("|[rR]", "")):gmatch("%d+") do
        n = n + 1
    end
    return n
end

local function peelIcons(line)
    local body, icons, pos, num = {}, {}, 1, 0
    while true do
        local s, e = line:find("|T.-|t", pos)
        if not s then
            body[#body + 1] = line:sub(pos)
            break
        end

        local gap = line:sub(1, s - 1):match("(%s*)$") or ""
        local head = line:sub(pos, s - 1 - #gap)
        body[#body + 1] = head
        num = num + countNums(head)
        local text = gap .. line:sub(s, e)
        pos = e + 1

        if head == "" and num == 0 then
            local after = line:match("^(%s+)", pos)
            if after then
                text = text .. after
                pos = pos + #after
            end
        end
        icons[#icons + 1] = { after = num, text = text }
    end
    return table.concat(body), icons
end

local function putIcons(ru, icons)
    local out, pos, num, idx = {}, 1, 0, 1
    while idx <= #icons and icons[idx].after == 0 do
        out[#out + 1] = icons[idx].text
        idx = idx + 1
    end
    while idx <= #icons do
        local s, e = ru:find("%d+", pos)
        if not s then break end

        local chunk = ru:sub(pos, e)
        out[#out + 1] = chunk
        num = num + countNums(chunk)
        pos = e + 1
        while idx <= #icons and icons[idx].after <= num do
            out[#out + 1] = icons[idx].text
            idx = idx + 1
        end
    end
    out[#out + 1] = ru:sub(pos)

    while idx <= #icons do
        out[#out + 1] = icons[idx].text
        idx = idx + 1
    end
    return table.concat(out)
end

local function peelLinkColors(line)
    if not line:find("|Hitem:", 1, true) then return line, nil, nil end
    local head = line:match("^(|[cC]%x%x%x%x%x%x%x%x)")
    if head then line = line:sub(#head + 1) end
    local tailR = line:match("(|[rR])%s*$")
    if tailR then line = line:sub(1, #line - #tailR) end

    local linkColor = line:match("(|[cC]%x%x%x%x%x%x%x%x)|Hitem:")
    if linkColor then line = line:gsub("(|[cC]%x%x%x%x%x%x%x%x)(|Hitem:)", "%2", 1) end
    return line, head, tailR, linkColor
end

local function peelQuotes(line)
    local body = line:match('^"(.*)"$')
    if body and body ~= "" and not body:find('"', 1, true) then return body, '"', '"' end
    body = line:match('^"([^"]*)$')
    if body and body ~= "" then return body, '"', "" end
    body = line:match('^([^"]*)"$')
    if body and body ~= "" then return body, "", '"' end
    return line, nil, nil
end

local function translateLineKeepColorCore(id, line)
    if not line then return translateLineInner(id, line) end
    local head, tailR, linkColor
    line, head, tailR, linkColor = peelLinkColors(line)
    if head or tailR or linkColor then
        local ru
        if line:find("|T", 1, true) then
            local bare, icons = peelIcons(line)
            if not bare:find("[%a\208\209]") then return nil end
            ru = translateLineInner(id, bare)
            if ru ~= nil then ru = putIcons(ru, icons) end
        else
            ru = translateLineInner(id, line)
        end
        if ru == nil then return nil end
        if linkColor then ru = ru:gsub("|Hitem:", linkColor .. "|Hitem:", 1) end
        return (head or "") .. ru .. (tailR or "")
    end
    if not line:find("|T", 1, true) then return translateLineInner(id, line) end
    local bare, icons = peelIcons(line)

    if not bare:find("[%a\208\209]") then return nil end
    local ru = translateLineInner(id, bare)
    if ru == nil then return nil end
    return putIcons(ru, icons)
end

local function translateLineKeepColor(id, line)
    local ru = translateLineKeepColorCore(id, line)
    if ru ~= nil or not line then return ru end
    local body, open, close = peelQuotes(line)
    if not open then return nil end
    ru = translateLineKeepColorCore(id, body)
    if ru == nil then return nil end
    return open .. ru .. close
end

local function closeColorsAtBreaks(text)
    if not (text:find("\n") and text:find("|[cC]")) then return text end
    local open, out, i, n = {}, {}, 1, #text
    while i <= n do
        local c = text:sub(i, i)
        if c == "|" then
            local nxt = text:sub(i + 1, i + 1)
            local code = text:sub(i, i + 9)
            if (nxt == "c" or nxt == "C") and code:match("^|[cC]%x%x%x%x%x%x%x%x$") then
                open[#open + 1] = code
                out[#out + 1] = code
                i = i + 10
            elseif nxt == "r" or nxt == "R" then
                open[#open] = nil
                out[#out + 1] = text:sub(i, i + 1)
                i = i + 2
            else
                out[#out + 1] = c
                i = i + 1
            end
        elseif c == "\n" then
            for _ = 1, #open do out[#out + 1] = "|r" end
            out[#out + 1] = "\n"
            for k = 1, #open do out[#out + 1] = open[k] end
            i = i + 1
        else
            out[#out + 1] = c
            i = i + 1
        end
    end
    return table.concat(out)
end

local function neutralizeDarkColors(text)
    if not text or not text:find("|[cC]") then return text end
    return (text:gsub("|[cC]%x%x(%x%x)(%x%x)(%x%x)", function(rr, gg, bb)
        if tonumber(rr, 16) <= 32 and tonumber(gg, 16) <= 32 and tonumber(bb, 16) <= 32 then
            return "|cffffffff"
        end
    end))
end

local ZONE_INLINE_SKIP = {

    ["Serpent's Coil"] = true,
}

local NAME_LOWER
function CoARU_NameByLower(n)
    if not CoARU_SPELL_NAME_RU then return nil end
    if not NAME_LOWER then
        NAME_LOWER = {}
        for k, v in pairs(CoARU_SPELL_NAME_RU) do
            local lk = k:lower()
            if NAME_LOWER[lk] == nil then NAME_LOWER[lk] = v end
        end
    end
    return NAME_LOWER[n:lower()]
end

function CoARU_Unlocalize(text)
    if type(text) ~= "string" or text == "" then return text end
    if not CoARU_HasCyrillic(text) then return text end

    local subs = CoARU_SUB_SEEN
    if subs then
        local trimmed = text:match("^%s*(.-)%s*$")
        local en = subs[trimmed]
        if en then

            local s, e = text:find(trimmed, 1, true)
            if s then return text:sub(1, s - 1) .. en .. text:sub(e + 1) end
        end
    end

    local seen = CoARU_NAME_SEEN
    if not seen then return text end
    for ru, en in pairs(seen) do
        local pos = 1
        while true do
            local s, e = text:find(ru, pos, true)
            if not s then break end
            text = text:sub(1, s - 1) .. en .. text:sub(e + 1)
            pos = s + #en
        end
    end
    return text
end

local localizeOne

local function nameHit(map, key)
    if not map then return nil end
    local v = map[key]
    if v == nil or v == key or v == "" then return nil end
    return v
end

local function singularsOf(n)
    local last = n:sub(-1)
    if last ~= "s" and last ~= "S" then return nil end
    local out = { n:sub(1, #n - 1) }
    if #n > 2 and n:sub(-2):lower() == "es" then
        out[#out + 1] = n:sub(1, #n - 2)
    end
    if #n > 3 and n:sub(-3):lower() == "ies" then
        out[#out + 1] = n:sub(1, #n - 3) .. "y"
    end
    return out
end

local function mapHit(map, n, cands)
    local ru = nameHit(map, n)
    if ru or not cands then return ru end
    for i = 1, #cands do
        ru = nameHit(map, cands[i])
        if ru then return ru end
    end
    return nil
end

local function spellNameRU(n)

    if CLASS_NAME[n] then return nil end
    local ru = nameHit(CoARU_SPELL_NAME_RU, n) or nameHit(CoARU_ItemNameEN, n)
    if not ru then ru = CoARU_NameByLower(n) end
    if ru then return ru end
    local cands = singularsOf(n)
    if not cands then return nil end
    for i = 1, #cands do
        local one = cands[i]
        ru = nameHit(CoARU_SPELL_NAME_RU, one) or nameHit(CoARU_ItemNameEN, one)
             or CoARU_NameByLower(one)
        if ru then return ru end
    end
    return nil
end

function CoARU_LocalizeNames(text)
    if not text then return text end
    if not text:find("«", 1, true) then return text end
    local okNames = CoARU_ModOn and CoARU_ModOn("spellnames") and CoARU_SPELL_NAME_RU
    local okZones = CoARU_ModOn and CoARU_ModOn("zones") and CoARU_ZONE

    local okInst = CoARU_ModOn and CoARU_ModOn("dungeons") and CoARU_ZONE

    local okUnits = CoARU_ModOn and CoARU_ModOn("names") and CoARU_UNIT_N2R
    if not okNames and not okZones and not okInst and not okUnits then
        return text
    end

    do
        local total, known = 0, 0
        for raw in text:gmatch("«(.-)»") do
            local pre, core = raw:match("^(|[cC]%x%x%x%x%x%x%x%x)(.-)|[rR]$")
            local n = core or raw
            if n:find("|[cC]") then n = CoARU_StripCodes(n) end
            if n:find("^[A-Za-z]") then
                total = total + 1

                local ru = nil
                if CLASS_NAME[n] then
                    known = known + 1
                else
                    if okNames then ru = spellNameRU(n) end
                    if not ru and (okZones or okInst) and CoARU_ZONE then
                        ru = nameHit(CoARU_ZONE, n) or nameHit(CoARU_ZONE, "The " .. n)
                                 or nameHit(CoARU_ZONE, n:match("^The (.+)$") or n)
                    end

                    if not ru and CoARU_SPEC_RU then
                        ru = CoARU_SPEC_RU[n:match("^(.-)%s*%(%d+%)$") or n]
                    end
                    local cands = singularsOf(n)
                    if not ru and okUnits then ru = mapHit(CoARU_UNIT_N2R, n, cands) end
                    if not ru and okUnits then ru = mapHit(CoARU_OBJ_N2R, n, cands) end

                    if not ru and CoARU_FactionNameRU then
                        ru = CoARU_FactionNameRU(n) or CoARU_FactionNameRU("The " .. n)
                             or CoARU_FactionNameRU(n:match("^The (.+)$") or n)
                    end

                    if not ru and CoARU_TERM_RU then
                        local t = CoARU_TERM_RU[n]
                        if type(t) == "string" and t ~= "" and t ~= n then ru = t end
                    end
                    if ru then known = known + 1 end
                end
            end
        end
        if total > 1 and known < total then return text end
    end

    return (text:gsub("«(.-)»", function(raw)
        return localizeOne(raw, okNames, okZones, okInst, okUnits)
    end))
end

localizeOne = function(raw, okNames, okZones, okInst, okUnits)
    local keep = "«" .. raw .. "»"
    do

        local pre, core, post = raw:match("^(|[cC]%x%x%x%x%x%x%x%x)(.-)(|[rR])$")
        local n = core or raw

        if n:find("|[cC]") then
            if not pre then
                pre = n:match("(|[cC]%x%x%x%x%x%x%x%x)")
                post = "|r"
            end
            n = CoARU_StripCodes(n)
        end
        local ru, quoted
        if CLASS_NAME[n] then

            return keep
        end
        if okNames then

            ru = spellNameRU(n)

            if ru then quoted = true end
        end

        if not ru and CoARU_SpecNameRU then
            local base, num = n:match("^(.-)%s*%((%d+)%)$")
            local sru = CoARU_SpecNameRU(base or n)
            if sru then
                ru = num and (sru .. " (" .. num .. ")") or sru
                quoted = true
            end
        end
        if not ru and (okZones or okInst) and not ZONE_INLINE_SKIP[n]
           and not nameHit(CoARU_SPELL_NAME_RU, n) then

            local bare = n:match("^The (.+)$")
            local key = nil
            for _, cand in ipairs({ n, "The " .. n, n .. " City", "The " .. n .. " City",
                                    bare, bare and (bare .. " City") }) do
                if cand and CoARU_ZONE[cand] then key = cand break end
            end
            if key then

                local inst = CoARU_ZONE_INST and (CoARU_ZONE_INST[key] or CoARU_ZONE_INST[n])
                if (inst and okInst) or (not inst and okZones) then
                    ru = CoARU_ZONE[key]
                end
            end
        end
        if not ru and okUnits then ru = mapHit(CoARU_UNIT_N2R, n, singularsOf(n)) end

        if not ru and CoARU_FactionNameRU then
            ru = CoARU_FactionNameRU(n) or CoARU_FactionNameRU("The " .. n)
                             or CoARU_FactionNameRU(n:match("^The (.+)$") or n)
        end

        if not ru and CoARU_TERM_RU then
            local t = CoARU_TERM_RU[n]
            if type(t) == "string" and t ~= "" and t ~= n then ru = t end
        end

        if not ru and okUnits and CoARU_OBJ_N2R then
            ru = mapHit(CoARU_OBJ_N2R, n, singularsOf(n))
            if ru then quoted = true end
        end
        if not ru then return keep end
        if quoted then

            return "«" .. (pre and (pre .. ru .. post) or ru) .. "»"
        end
        return pre and (pre .. ru .. post) or ru
    end
end

function CoARU_IsSpecName(s)
    return s ~= nil and CoARU_SPEC_NAME ~= nil and CoARU_SPEC_NAME[s] == true
end

local SPEC_UPPER

function CoARU_SpecNameRU(s)
    if s == nil or CoARU_SPEC_RU == nil then return nil end
    if CoARU_ModOn and not CoARU_ModOn("specnames") then return nil end
    local ru = CoARU_SPEC_RU[s]
    if ru == nil and s:find("^[A-Z][A-Z '%-]*$") then
        if SPEC_UPPER == nil then
            SPEC_UPPER = {}
            for en, v in pairs(CoARU_SPEC_RU) do
                SPEC_UPPER[en:upper()] = v
            end
        end
        ru = SPEC_UPPER[s]
    end

    if ru == nil or ru == "" or ru == s then return nil end
    return ru
end

local function nameLineRU(line)
    if not CoARU_SPELL_NAME_RU or not line then return nil end
    if CoARU_ModOn and not CoARU_ModOn("spellnames") then return nil end
    if CoARU_HasCyrillic(line) then return nil end
    local icon, rest = line:match("^(%s*|T[^|]*|t%s*)(.*)$")
    if not icon then icon, rest = line:match("^(%s*)(.*)$") end
    if not rest or rest == "" then return nil end
    local color, body, close = rest:match("^(|[cC]%x%x%x%x%x%x%x%x)(.-)(|[rR]%s*)$")
    if not color then color, close, body = "", "", rest end
    local name = CoARU_StripCodes(body):gsub("^%s+", ""):gsub("%s+$", "")
    if CoARU_IsSpecName(name) then
        local spec = CoARU_SpecNameRU(name)
        if not spec then return nil end
        return icon .. color .. spec .. close
    end
    local ru = name ~= "" and CoARU_SPELL_NAME_RU[name]
    if not ru then return nil end
    return icon .. color .. ru .. close
end

local function lineRU(id, line)
    local ru = translateLineKeepColor(id, line)
    if not ru or ru == line then
        local byName = nameLineRU(line)
        if byName then return byName end
        return ru
    end
    return ru
end

local function bareLinkNames(s)
    if not s or not s:find("|h[", 1, true) then return s end
    return (s:gsub("(|h%[)«(.-)»(%]|h)", "%1%2%3"))
end

function CoARU_TranslateBlock(id, text)
    if not text then return nil end
    if not text:find("\n") then
        local one = lineRU(id, text)
        return bareLinkNames(CoARU_LocalizeNames(neutralizeDarkColors(one)))
    end
    text = closeColorsAtBreaks(text)
    local out, any = {}, false
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        local ru = lineRU(id, line)
        if ru then any = true end
        out[#out + 1] = ru or line
    end
    if not any then return nil end

    return bareLinkNames(CoARU_LocalizeNames(neutralizeDarkColors(table.concat(out, "\n"))))
end

function CoARU_IsTranslated(id)
    if CoARU_LOC_EN and CoARU_LOC_EN[id] then return true end
    return false
end

function CoARU_LineTranslated(id, line)
    local ru = lineRU(id, line)
    return ru ~= nil and ru ~= line
end

local function ruDiffers(packed, n)
    if not packed then return false end
    local ru = fetchOneRU(packed)
    return ru ~= nil and ru ~= "" and ru ~= n
end

function CoARU_LineKnown(id, line)
    if not line or line == "" then return false end
    local plain = CoARU_StripCodes(line)
    local n = CoARU_Norm(plain)
    if not n or n == "" then return false end
    if id and id > 0 and CoARU_LOC_EN and CoARU_LOC_EN[id] then
        local en = CoARU_GetEN(id)
        local hit = false
        if type(en) == "table" then
            for i = 1, #en do
                if en[i] == n then hit = true break end
            end
        elseif en == n then
            hit = true
        end

        if hit then
            local ru = CoARU_GetRU(id)
            if type(ru) == "table" then ru = ru[1] end
            if ru and ru ~= "" and ru ~= n then return true end
        end
    end
    return ruDiffers(CoARU_HASH and CoARU_HASH[hashText(n)], n)
end
