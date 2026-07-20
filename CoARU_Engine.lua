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

local enChunkCache, ruChunkCache = {}, {}

local function decompressChunk(chunkTable, cache, chunkId)
    local hit = cache[chunkId]
    if hit ~= nil then
        if hit == false then return nil end
        return hit
    end
    local raw = chunkTable and chunkTable[chunkId]
    if not raw then
        cache[chunkId] = false
        return nil
    end
    local text = CoARU_Deflate and CoARU_Deflate:DecompressZlib(raw)
    cache[chunkId] = text or false
    return text
end

local function sliceLoc(chunkTable, cache, packed)
    local chunkId, offset, length = unpackLoc(packed)
    local text = decompressChunk(chunkTable, cache, chunkId)
    if not text then return nil end
    return text:sub(offset + 1, offset + length)
end

local function fetchText(locTable, chunkTable, cache, id)
    local loc = locTable and locTable[id]
    if not loc then return nil end
    if type(loc) == "table" then
        local out = {}
        for i, packed in ipairs(loc) do
            out[i] = sliceLoc(chunkTable, cache, packed)
        end
        return out
    end
    return sliceLoc(chunkTable, cache, loc)
end

function CoARU_GetEN(id)
    return fetchText(CoARU_LOC_EN, CoARU_CHUNK_EN, enChunkCache, id)
end

function CoARU_GetRU(id)
    return fetchText(CoARU_LOC_RU, CoARU_CHUNK_RU, ruChunkCache, id)
end

function CoARU_DeflateStatus()
    if not CoARU_Deflate then return false, "no LibDeflate instance resolved" end
    if type(CoARU_Deflate.DecompressZlib) ~= "function" then
        return false, "resolved object has no DecompressZlib"
    end
    return true, CoARU_Deflate._VERSION or "?"
end

local function fetchOneRU(packed)
    return sliceLoc(CoARU_CHUNK_RU, ruChunkCache, packed)
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

local function matchOne(en, ru, id, norm, plain)
    if not en or not ru then return nil end
    if norm ~= en then return nil end
    local nums = extractNumbers(plain)
    local r = ru:gsub("{(%d+)}", function(n)
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

    if type(en) == "table" then
        for i, e in ipairs(en) do
            local r = matchOne(e, type(ru) == "table" and ru[i] or nil, id, norm, plain)
            if r then return r end
        end
        return nil
    end

    return matchOne(en, ru, id, norm, plain)
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
    ["Generates # Heat Per Enemy Hit"] = "Генерирует {1} ед. Жара за каждого поражённого врага",
    ["Generates # additional Rage"] = "Генерирует дополнительно {1} ед. ярости",
    ["# Mana, plus # per sec"] = "{1} ед. маны + {2} в секунду",
    ["Hold SHIFT for more information"] = "Удерживайте SHIFT для подробностей",
    ["Only # Ascension spell can be active at a time."] = "Одновременно может быть активно только {1} заклинание Вознесения.",

    ["Cannot be cast when in combat."] = "Нельзя применять в бою.",
    ["Hello! Ready for some training?"] = "Привет! Готов подучиться?",
    ["Greetings! Take my trial!"] = "Приветствую! Пройди моё испытание!",
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
    ["Spend # more points to unlock this row"] = "Чтобы открыть этот ряд, потратьте ещё очков: {1}",
    ["Unlocks at level #."] = "Открывается на уровне {1}.",
    ["Unlocks at level: #"] = "Открывается на уровне: {1}",

    ["Spend # more Talent Essence in current tree to unlock this row"] =
        "Чтобы открыть этот ряд, потратьте в текущем дереве ещё эссенции талантов: {1}",
    ["Spend # more Talent Essence points in any tree to unlock rows below"] =
        "Чтобы открыть ряды ниже, потратьте в любом дереве ещё эссенции талантов: {1}",
    ["Spend # more Ability Essence in any class to unlock this ability."] =
        "Чтобы открыть эту способность, потратьте в любом классе ещё эссенции способностей: {1}.",
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

local CLASS_RU = {

    ["Warriors"] = "Воины", ["Paladins"] = "Паладины", ["Hunters"] = "Охотники",
    ["Rogues"] = "Разбойники", ["Priests"] = "Жрецы", ["Shamans"] = "Шаманы",
    ["Mages"] = "Маги", ["Warlocks"] = "Чернокнижники", ["Druids"] = "Друиды",
    ["Death Knights"] = "Рыцари смерти", ["Monks"] = "Монахи",

    ["Necromancers"] = "Некроманты",
    ["Sun Clerics"] = "Солнечные клирики",
    ["Chronomancers"] = "Хрономанты",
    ["Pyromancers"] = "Пироманты",
    ["Primalists"] = "Первобытники",
    ["Barbarians"] = "Варвары",
    ["Reapers"] = "Жнецы",
    ["Tinkers"] = "Механики",
    ["Rangers"] = "Следопыты",
    ["Witch Doctors"] = "Знахари",
    ["Demon Hunters"] = "Охотники на демонов",
    ["Cultists"] = "Культисты",

}

function CoARU_TranslateClass(line)
    if not line then return nil end
    local en = CoARU_Norm(CoARU_StripCodes(line))
    local cls = en:match("^(.+) cannot use this Mystic Enchant$")
    if not cls then return nil end
    local ru = CLASS_RU[cls]
    if not ru then return nil end
    return ru .. " не могут использовать эти Мистические чары"
end

function CoARU_TranslateRequires(line)
    if not line or not line:find("Requires") then return nil end
    local s = line
    s = s:gsub("Requires:%s*", "Требуется: ")
    s = s:gsub("Requires%s+", "Требуется ")
    s = s:gsub("Level", "уровень")
    s = s:gsub("%(Rank (%d+)%)", "(ранг %1)")
    s = s:gsub("%(Rank (|[cC]%x%x%x%x%x%x%x%x)(%d+)(|r)%)", "(ранг %1%2%3)")

    local PROF = {
        { "Fishing Poles", "Удочки" }, { "Fist Weapons", "Кистевое оружие" },
        { "One%-Handed Swords", "Одноручные мечи" }, { "Two%-Handed Swords", "Двуручные мечи" },
        { "One%-Handed Axes", "Одноручные топоры" }, { "Two%-Handed Axes", "Двуручные топоры" },
        { "One%-Handed Maces", "Одноручные палицы" }, { "Two%-Handed Maces", "Двуручные палицы" },
        { "Crossbows", "Арбалеты" }, { "Polearms", "Древковое оружие" }, { "Warglaives", "Глефы" },
        { "Daggers", "Кинжалы" }, { "Staves", "Посохи" }, { "Shields", "Щиты" },
        { "Thrown", "Метательное оружие" }, { "Wands", "Жезлы" },
        { "Bows", "Луки" }, { "Guns", "Ружья" },

        { "Advantage", "Преимущество" }, { "Insanity", "Безумие" },
        { "Felfury", "Ярость Скверны" }, { "Demonfire", "Демонический огонь" },
        { "Reaped Souls", "Пожатые души" }, { "Reaped Soul", "Пожатая душа" },
    }
    for _, p in ipairs(PROF) do s = s:gsub(p[1], p[2]) end
    if s ~= line then return s end
    return nil
end

function CoARU_TranslateReagents(line)
    if not line or not line:find("Reagents:", 1, true) then return nil end
    local s = line:gsub("Reagents:%s*", "Реагенты: ")
    if s ~= line then return s end
    return nil
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

function CoARU_TranslateByIndex(liveText)
    if not liveText then return nil end
    local plain = CoARU_StripCodes(liveText)
    local norm = CoARU_Norm(plain)
    if not norm or norm == "" then return nil end

    local packed = CoARU_HASH and CoARU_HASH[hashText(norm)]
    if not packed then return nil end
    local ru = fetchOneRU(packed)
    if not ru then return nil end

    local nums = {}
    for m in plain:gmatch("%d[%d%.,]*") do
        nums[#nums + 1] = (m:gsub("[%.,]+$", ""))
    end
    return (ru:gsub("{(%d+)}", function(n) return nums[tonumber(n)] or "?" end))
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
    return (ru:gsub("{(%d+)}", function(n) return nums[tonumber(n)] or "?" end))
end

local TERM_FORMS = {
    ["Advantage"]    = { "Преимуществом", "Преимущества", "Преимуществу", "Преимуществе",
                         "Преимущество" },
    ["Heat"]         = { "Жаром", "Жара", "Жару", "Жаре", "Жар" },
    ["Insanity"]     = { "Безумием", "Безумия", "Безумию", "Безумии", "Безумие" },
    ["Static"]       = { "Статическим зарядом", "Статического заряда", "Статическому заряду",
                         "Статическом заряде", "Статический заряд" },
    ["Felfury"]      = { "Яростью Скверны", "Ярости Скверны", "Ярость Скверны" },
    ["Demonfire"]    = { "Демоническим огнём", "Демоническим огнем", "Демонического огня",
                         "Демоническому огню", "Демоническом огне", "Демонический огонь" },
    ["Reaped Souls"] = { "Пожатыми душами", "Пожатых душ", "Пожатым душам", "Пожатые души" },
    ["Life Force"]   = { "жизненной силой", "жизненную силу", "жизненной силы",
                         "жизненная сила" },
    ["Embers"]       = { "Углями", "Углей", "Углям", "Угли" },
    ["Ember"]        = { "Углём", "Углем", "Угля", "Углю", "Уголь" },
    ["Runic Power"]  = { "силой рун", "силы рун", "силу рун", "силе рун", "сила рун" },
    ["Focus"]        = { "концентрацией", "концентрации", "концентрацию", "концентрация" },
    ["Rage"]         = { "яростью", "ярости", "ярость" },
    ["Energy"]       = { "энергией", "энергии", "энергию", "энергия" },
    ["Mana"]         = { "маной", "маны", "мане", "ману", "мана" },
}

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

local function wrapFirst(ru, needle, color, restore)
    local s, e = ru:find(needle, 1, true)
    if not s then
        local alt = flipFirstCase(needle)
        if not alt then return nil end
        s, e = ru:find(alt, 1, true)
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

local function reapplyInnerColors(line, ru, restore, unwrapped)
    if ru:find("|c", 1, true) then return ru end
    local pos = 1
    while true do
        local s, e, color, body = line:find("(|[cC]%x%x%x%x%x%x%x%x)(.-)|r", pos)
        if not s then break end
        pos = e + 1

        if (unwrapped or s > 1) and body and body ~= "" then
            local term = CoARU_StripCodes(body)
            term = term and term:match("^%s*(.-)%s*$")
            if term and #term > 1 then
                local done = wrapFirst(ru, term, color, restore)
                if not done then
                    for _, form in ipairs(TERM_FORMS[term] or {}) do
                        done = wrapFirst(ru, form, color, restore)
                        if done then break end
                    end
                end
                ru = done or ru
            end
        end
    end
    return ru
end

local PROF = {
    ["Blacksmithing"] = { "Кузнечному делу",     "кузнечного дела" },
    ["Alchemy"]       = { "Алхимии",             "алхимии" },
    ["Enchanting"]    = { "Наложению чар",       "наложения чар" },
    ["Engineering"]   = { "Инженерному делу",    "инженерного дела" },
    ["Leatherworking"]= { "Кожевничеству",       "кожевничества" },
    ["Tailoring"]     = { "Портняжному делу",    "портняжного дела" },
    ["Herbalism"]     = { "Травничеству",        "травничества" },
    ["Mining"]        = { "Горному делу",        "горного дела" },
    ["Skinning"]      = { "Снятию шкур",         "снятия шкур" },
    ["Cooking"]       = { "Кулинарии",           "кулинарии" },
    ["First Aid"]     = { "Первой помощи",       "первой помощи" },
    ["Fishing"]       = { "Рыбной ловле",        "рыбной ловли" },
    ["Inscription"]   = { "Начертанию",          "начертания" },
    ["Jewelcrafting"] = { "Ювелирному делу",     "ювелирного дела" },
    ["Woodworking"]   = { "Деревообработке",     "деревообработки" },
    ["Woodcutting"]   = { "Заготовке древесины", "заготовки древесины" },
}

function CoARU_TranslateProfession(line)
    if not line then return nil end
    local name = line:match("^You can learn (.-) from a .- Trainer, which can be found by "
                            .. "speaking to a Guard in most capital cities%.")
    if not name then return nil end
    local f = PROF[name]
    if not f then return nil end
    return ("Обучиться %s можно у учителя %s — найти его поможет стражник в большинстве "
            .. "столиц. Также %s можно обучиться по «Book of Artisans»!")
           :format(f[1], f[2], f[1])
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

    for key, ru in pairs(CoARU_StatLabelRU or {}) do add(_G[key], ru) end

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

local function translateLineKeepColor(id, line)
    local ru = (id and CoARU_TranslateText(id, line)) or CoARU_TranslateGlobal(line)
        or CoARU_TranslateByIndex(line) or CoARU_TranslateClass(line)
        or CoARU_TranslateRequires(line) or CoARU_TranslateReagents(line)
        or CoARU_TranslateProfession(line) or CoARU_TranslateStatLine(line)

        or (CoARU_TranslateItemPrefix and CoARU_TranslateItemPrefix(line))

        or (CoARU_TranslateStatCombo and CoARU_TranslateStatCombo(line))
    if not ru then return nil end
    if ru:find("|c", 1, true) then return ru end

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

    local lbl, rest = line:match("^|[cC]%x%x%x%x%x%x%x%x(.-)|r:%s*(.+)$")
    local colonInside = false
    if not lbl then
        lbl, rest = line:match("^|[cC]%x%x%x%x%x%x%x%x(.-):|r%s*(.+)$")
        colonInside = true
    end
    if lbl and rest then

        local ruLabel, ruRest = ru:match("^(.-):%s*(.+)$")
        if ruLabel and ruRest then
            if colonInside then
                return color .. ruLabel .. ":|r " .. ruRest
            end
            return color .. ruLabel .. "|r: " .. ruRest
        end
    end

    if not leadingSpanCoversAll(line) then
        local painted = reapplyInnerColors(line, ru, nil, true)

        if painted ~= ru then return painted end
    end

    local inner = line:gsub("^|[cC]%x%x%x%x%x%x%x%x", "", 1):gsub("|r$", "")
    return color .. reapplyInnerColors(inner, ru, color, true) .. "|r"
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

function CoARU_TranslateBlock(id, text)
    if not text then return nil end
    if not text:find("\n") then
        return translateLineKeepColor(id, text)
    end
    text = closeColorsAtBreaks(text)
    local out, any = {}, false
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        local ru = translateLineKeepColor(id, line)
        if ru then any = true end
        out[#out + 1] = ru or line
    end
    if not any then return nil end
    return table.concat(out, "\n")
end

function CoARU_IsTranslated(id)
    if CoARU_LOC_EN and CoARU_LOC_EN[id] then return true end
    return false
end

function CoARU_LineTranslated(id, line)
    return translateLineKeepColor(id, line) ~= nil
end
