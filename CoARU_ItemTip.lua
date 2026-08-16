local RU = CoARU_ItemTipRU or {}
local SUB = CoARU_ItemTipSubclass or {}
local OWN = CoARU_ItemTipOwn or {}

do
    local mirrored = 0
    for en, ru in pairs(OWN) do
        local head, school = en:match("^(.-) %((Melee)%)$")
        if not head then head, school = en:match("^(.-) %((Ranged)%)$") end
        if not head then head, school = en:match("^(.-) %((Spell)%)$") end
        if head then

            local sign, rest = head:match("^([%+%-]#) (.+)$")
            local alt = sign and (sign .. " " .. school .. " " .. rest)
            if alt and OWN[alt] == nil then
                OWN[alt] = ru
                mirrored = mirrored + 1
            end
        end
    end
    CoARU_ItemTipMirrored = mirrored
end

local NUMFMT = "%%[%-%+ #0-9%.]*[dfsi]"

local function unsupported(fmt)

    if fmt:find("%%%d+%$") then return true end
    local rest = fmt:gsub("%%%%", ""):gsub("%%c", ""):gsub(NUMFMT, "")
    return rest:find("%%") ~= nil
end

local function buildEn(fmt, sign)
    local out = fmt:gsub("%%%%", "\1")
    out = out:gsub("%%c", sign)

    out = out:gsub(NUMFMT, "#")
    return (out:gsub("\1", "%%"))
end

local function buildRu(fmt, sign)
    local out = fmt:gsub("%%%%", "\1")
    out = out:gsub("%%c", sign)
    local i = 0
    out = out:gsub(NUMFMT, function()
        i = i + 1
        return "{" .. i .. "}"
    end)
    return (out:gsub("\1", "%%"))
end

local function countHashes(s)
    local n = 0
    for _ in s:gmatch("#") do n = n + 1 end
    return n
end

local function countSlots(s)
    local n = 0
    for _ in s:gmatch("{%d+}") do n = n + 1 end
    return n
end

local added, skipped = 0, 0

local function put(enKey, ruTmpl)
    if not enKey or enKey == "" or not ruTmpl then return end
    local key = CoARU_Norm(enKey)
    if key == "" then return end

    if countHashes(key) ~= countSlots(ruTmpl) then
        skipped = skipped + 1
        return
    end

    if CoARU_G[key] ~= nil then return end
    CoARU_G[key] = ruTmpl
    added = added + 1

    local alt
    if key:find('%."$') then
        alt = key:gsub('%."$', '"')
    elseif key:find('[^%.]"$') then
        alt = key:gsub('"$', '."')
    end
    if alt and alt ~= key and CoARU_G[alt] == nil and countHashes(alt) == countSlots(ruTmpl) then
        CoARU_G[alt] = ruTmpl
        added = added + 1
    end
end

for key, ru in pairs(RU) do
    local en = CoARU_EN(key)
    if type(en) == "string" and type(ru) == "string" and en ~= ""
        and not unsupported(en) and not unsupported(ru) then
        if en:find("%%c") then

            put(buildEn(en, "+"), buildRu(ru, "+"))
            put(buildEn(en, "-"), buildRu(ru, "-"))
        else
            put(buildEn(en, ""), buildRu(ru, ""))
        end
    else
        skipped = skipped + 1
    end
end

for en, ru in pairs(SUB) do
    put(en, ru)
end

for en, ru in pairs(OWN) do
    put(en, ru)
end

CoARU_ItemTipAdded = added
CoARU_ItemTipSkipped = skipped

local ERR_EXACT, ERR_PATTERNS

local function buildErrors()
    if ERR_EXACT then return end
    ERR_EXACT, ERR_PATTERNS = {}, {}
    for key, ru in pairs(CoARU_ErrorsRU or {}) do
        local en = CoARU_EN(key)
        if type(en) == "string" and en ~= "" then
            if not en:find("%%") then
                ERR_EXACT[en] = ru
            else

                local tmp = en:gsub("%%[sd]", "\1")
                tmp = tmp:gsub("([%^%$%(%)%.%[%]%*%+%-%?%%])", "%%%1")
                local i = 0
                local pat = "^" .. tmp:gsub("\1", function()
                    i = i + 1
                    return "(.-)"
                end) .. "$"
                if i > 0 then
                    ERR_PATTERNS[#ERR_PATTERNS + 1] = { pat = pat, ru = ru, n = i }
                end
            end
        end
    end
end

function CoARU_TranslateError(msg)
    if type(msg) ~= "string" or msg == "" then return nil end
    buildErrors()
    local hit = ERR_EXACT[msg]
    if hit then return hit end
    for _, r in ipairs(ERR_PATTERNS) do
        local caps = { msg:match(r.pat) }
        if caps[1] ~= nil then
            local j = 0

            return (r.ru:gsub("%%[sd]", function()
                j = j + 1
                return caps[j] or ""
            end))
        end
    end

    if CoARU_QuestLookup then
        local head, cnt = msg:match("^(.-):%s*(%d+/%d+)%s*$")
        if head and head ~= "" then
            local ok, ru = pcall(CoARU_QuestLookup, head)
            if ok and ru and ru ~= head then return ru .. ": " .. cnt end
        end
    end
    if CoARU_QuestLookup then
        local ok, ru = pcall(CoARU_QuestLookup, msg)

        if ok and ru then
            if CoARU_LocalizeNames then
                local lok, lru = pcall(CoARU_LocalizeNames, ru)
                if lok and lru then ru = lru end
            end
            return ru
        end
    end

    local zone, boss = msg:match("^You have entered (.+)%. Slay (.+) to complete the dungeon%.$")
    if zone and boss then
        return ("Вы вошли в подземелье %s. Цель: убить %s."):format(zone, boss)
    end

    if CoARU_TranslateObjectiveLine then
        local ok, ru = pcall(CoARU_TranslateObjectiveLine, msg)
        if ok and ru and ru ~= msg then return ru end
    end

    if CoARU_TranslateBlock then
        local ok, ru = pcall(CoARU_TranslateBlock, nil, msg)
        if ok and ru and ru ~= msg then return ru end
    end

    if CoARU_BroadcastRU then
        local ok, ru = pcall(CoARU_BroadcastRU, msg)
        if ok and ru and ru ~= msg then return ru end
    end
    if #msg > 12 and CoARU_NoteMiss and not (CoARU_HasCyrillic and CoARU_HasCyrillic(msg)) then
        CoARU_NoteMiss("uierror", msg)
    end
    return nil
end

local function hookErrors()
    local f = _G["UIErrorsFrame"]
    if not f or not f.AddMessage or f.__coaruErrHooked then return end
    f.__coaruErrHooked = true
    local orig = f.AddMessage
    f.AddMessage = function(self, msg, ...)
        local ok, ru = pcall(CoARU_TranslateError, msg)
        return orig(self, (ok and ru) or msg, ...)
    end
end

local function hookChat()
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local f = _G["ChatFrame" .. i]
        if f and f.AddMessage and not f.__coaruLogHooked then
            f.__coaruLogHooked = true
            local orig = f.AddMessage
            f.AddMessage = function(self, msg, ...)
                local ok, ru = pcall(CoARU_FixLogLine, msg)
                return orig(self, (ok and ru) or msg, ...)
            end
        end
    end
end

local errWaiter = CreateFrame("Frame")
errWaiter:RegisterEvent("PLAYER_LOGIN")
errWaiter:SetScript("OnEvent", function() hookErrors() hookChat() end)
hookErrors()
hookChat()

local LABEL_RULES = {
    { "^Equip: ", "Если на персонаже: " },
    { "^Use: ", "Использование: " },
    { "^Chance on hit: ", "Шанс при попадании: " },
    { "^Set: ", "Комплект: " },
}

function CoARU_TranslateItemLabel(line)
    if not line or line == "" then return nil end
    local color = line:match("^(|[cC]%x%x%x%x%x%x%x%x)")
    local plain = line
    if color then
        plain = plain:gsub("^|[cC]%x%x%x%x%x%x%x%x", "", 1):gsub("|r$", "")
    end
    if not plain:find("[\208\209]") then return nil end
    for _, rule in ipairs(LABEL_RULES) do
        if plain:find(rule[1]) then
            local ru = (plain:gsub(rule[1], rule[2], 1))
            if color then ru = color .. ru .. "|r" end
            return ru
        end
    end

    for _, rule in ipairs(LABEL_RULES) do
        local head, tail = plain:match("^(" .. rule[2] .. ")(.+)$")

        if head and tail and tail:find("%a%a%a") and not tail:find("[\208\209]")
           and CoARU_TranslateBlock then
            local ok, res = pcall(CoARU_TranslateBlock, nil, tail)
            if ok and res and res ~= tail then
                local ru = head .. res
                if color then ru = color .. ru .. "|r" end
                return ru
            end
        end
    end
    return nil
end

function CoARU_TranslateItemLabelBody(line)
    if not line or line == "" or not CoARU_TranslateBlock then return nil end
    local color = line:match("^(|[cC]%x%x%x%x%x%x%x%x)")
    local plain = line
    if color then
        plain = plain:gsub("^|[cC]%x%x%x%x%x%x%x%x", "", 1):gsub("|r$", "")
    end

    if plain:find("[\208\209]") then return nil end

    local cnt, setBody = plain:match("^%((%d+)%) Set: (.+)$")
    if cnt and setBody and setBody:find("%a%a%a") then
        local okS, resS = pcall(CoARU_TranslateBlock, nil, setBody)
        if okS and resS and resS ~= setBody then
            local ru = "(" .. cnt .. ") Комплект: " .. resS
            if color then ru = color .. ru .. "|r" end
            return ru
        end
        return nil
    end
    for _, rule in ipairs(LABEL_RULES) do
        local tail = plain:match(rule[1] .. "(.+)$")
        if tail and tail:find("%a%a%a") then
            local ok, res = pcall(CoARU_TranslateBlock, nil, tail)
            if ok and res and res ~= tail then
                local ru = rule[2] .. res
                if color then ru = color .. ru .. "|r" end
                return ru
            end

            local body, num, unit = tail:match("^(.-)%s*%((%d+)%s+([MmSs]%a+)%s+[Cc]ooldown%)%s*$")
            if body and body:find("%a%a%a") then
                local ok2, res2 = pcall(CoARU_TranslateBlock, nil, body)
                if ok2 and res2 and res2 ~= body then
                    local u = unit:lower():sub(1, 1) == "m" and "мин." or "сек."
                    local ru = rule[2] .. res2 .. " (время восстановления " .. num .. " " .. u .. ")"
                    if color then ru = color .. ru .. "|r" end
                    return ru
                end
            end
        end
    end
    return nil
end

function CoARU_ItemNameLine(plain)
    if not plain or not CoARU_ItemNameEN then return nil end
    local ru = CoARU_ItemNameEN[plain]
    if ru then return ru end
    local pad, core = plain:match("^(%s+)(%S.-)%s*$")
    ru = core and CoARU_ItemNameEN[core]
    if ru then return pad .. ru end

    local name, cnt = plain:match("^(%S.-)%s*(%(%d+/%d+%))$")
    ru = name and CoARU_ItemNameEN[name]

    if not ru and CoARU_ItemSetRU then ru = CoARU_ItemSetRU[name] end
    if ru then return ru .. " " .. cnt end

    if CoARU_ItemSetRU then
        local only = CoARU_ItemSetRU[plain]
        if only then return only end
    end
    return nil
end

function CoARU_ItemNameRowRU(id, en)
    local ru = id and CoARU_ItemName and CoARU_ItemName[id]
    if ru and ru ~= "" then return ru end
    if type(en) ~= "string" or en == "" or not CoARU_ItemNameEN then return nil end
    local byText = CoARU_ItemNameEN[en]
    if byText and byText ~= "" and byText ~= en then return byText end
    return nil
end

function CoARU_ZoneLineRU(plain)
    if type(plain) ~= "string" or plain == "" or not CoARU_ZONE then return nil end
    local pad, core = plain:match("^(%s*)(%S.-)%s*$")
    if not core then return nil end
    local key = CoARU_ZONE[core] and core or (CoARU_ZONE["The " .. core] and ("The " .. core))
    if not key then return nil end
    local inst = CoARU_ZONE_INST and (CoARU_ZONE_INST[key] or CoARU_ZONE_INST[core])
    local ok = inst and CoARU_ModOn("dungeons") or (not inst and CoARU_ModOn("zones"))
    if not ok then return nil end
    local ru = CoARU_ZONE[key]
    if not ru or ru == "" or ru == core then return nil end
    return pad .. ru
end

function CoARU_ItemLinkNameRU(spec, name)
    if type(spec) ~= "string" or type(name) ~= "string" or name == "" then return nil end
    local id = tonumber(spec:match("^item:(%d+)"))
    if not id then return nil end
    local suffixID = tonumber(spec:match(
        "^item:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:(%-?%d+)"))
    if suffixID and suffixID ~= 0 then
        if not CoARU_SplitItemSuffix then return nil end
        local baseEN, suffRU = CoARU_SplitItemSuffix(name, suffixID)
        if not (baseEN and suffRU) then return nil end
        local ru = CoARU_ItemNameRowRU(id, baseEN)
        return ru and (ru .. " " .. suffRU) or nil
    end
    return CoARU_ItemNameRowRU(id, name)
end

function CoARU_AchievementLineRU(plain)
    if type(plain) ~= "string" or #plain < 3 or not CoARU_ACHIEVEMENT_RU then return nil end
    local pad, core = plain:match("^(%s*)(%S.-)%s*$")
    if not core then return nil end
    local ru = CoARU_ACHIEVEMENT_RU[core]
    if not ru or ru == "" or ru == core then return nil end
    return pad .. ru
end

local SOURCE_TAIL = {
    ["Heroic Dungeon"] = "героическое подземелье",
    ["Normal Dungeon"] = "обычное подземелье",
    ["Mythic Dungeon"] = "эпохальное подземелье",
    ["Heroic Raid"] = "героический рейд",
    ["Normal Raid"] = "обычный рейд",
}

function CoARU_ItemSourceGlueRU(plain)
    if type(plain) ~= "string" or plain == "" then return nil end
    for tail, ru in pairs(SOURCE_TAIL) do
        local name = plain:match("^(.-)" .. tail:gsub("%s", "%%s") .. "$")

        if name and name ~= "" and name:sub(-1) ~= " " then
            local nameRU = CoARU_ItemNameLine and CoARU_ItemNameLine(name)
            if not nameRU and CoARU_ItemNameEN then nameRU = CoARU_ItemNameEN[name] end

            if nameRU and nameRU ~= name then return nameRU .. " (" .. ru .. ")" end
            return nil
        end
    end
    return nil
end

function CoARU_UnitNameLineRU(plain)
    if type(plain) ~= "string" or #plain < 3 then return nil end
    if not CoARU_ModOn("names") then return nil end
    local pad, core = plain:match("^(%s*)(%S.-)%s*$")
    if not core then return nil end
    local ru = CoARU_UNIT_N2R and CoARU_UNIT_N2R[core]

    if not ru and CoARU_UNIT_SUB_N2R then ru = CoARU_UNIT_SUB_N2R[core] end
    if not ru or ru == "" or ru == core then return nil end
    return pad .. ru
end

function CoARU_ItemLinkLineRU(text)
    if type(text) ~= "string" or not text:find("|Hitem:", 1, true) then return nil end
    local changed = false
    local out = text:gsub("(|H(item:[^|]*)|h%[)([^%]]+)(%]|h)", function(a, spec, name, b)
        local ru = CoARU_ItemLinkNameRU(spec, name)
        if ru and ru ~= name then
            changed = true
            return a .. ru .. b
        end
        return a .. name .. b
    end)
    if not changed then return nil end
    return out
end

local PREFIX_RULES = {

    { "^Unique%-Equipped: ", "Уникальный использующийся: " },

    { "^Transmogrified to: ", "Внешность предмета: ", tail = true },

    { "^Loot: ", "Добыча: " },
}

local PATTERN_RULES = {
    {
        "^Use: Returns you to (.-)%.%s*Speak to an Innkeeper in a different place to change your "
            .. "home location%.%s*%((%d+) Min Cooldown%)$",
        "Использование: переносит вас в {1}. Чтобы сменить дом, поговорите с трактирщиком в "
            .. "другом месте. (Восстановление: {2} мин.)",
    },

    {
        "^Returns you to (.-)%.%s*Speak to an Innkeeper in a different place to change your "
            .. "home location%.%s*$",
        "Возвращает вас в {1}. Чтобы сменить дом, поговорите с трактирщиком в другом месте.",
    },

    {
        "^Use: Use this whistle to tame an? (.-)%.?$",
        "Использование: приручает существо {1} с помощью свистка.",
    },

    {
        "^<Made by (.-)>$",
        "<Изготовитель: {1}>",
    },

    { "^Alt%-Click to send this item to (.-)%.$",
      "Alt-клик, чтобы отправить предмет игроку {1}." },
    { "^Recipe could be learned by: (.+)$",
      "Рецепт может изучить: {1}" },

    { "^Cost: (%d+)%s*$",           "Стоимость: {1}" },
    { "^Class Points: (%d+)%s*$",   "Очки класса: {1}" },
    { "^Ability Essence Spent: (%d+)%s*$",
      "Потрачено эссенции способностей: {1}" },
    { "^(%d+)%% Threat$",           "{1}% угрозы" },

    { "^Cast By (.+)$",             "Наложил: «{1}»", true },

    { "^Target: YOU$",              "Цель: Вы" },
    { "^Target: (.+)$",             "Цель: «{1}»", true },

    { "^Not eligible %((%d+) Hr (%d+) Min%)$",
      "Недоступно (через {1} ч {2} мин)" },
    { "^Not eligible %((%d+) Hr (%d+) Sec%)$",
      "Недоступно (через {1} ч {2} сек)" },
    { "^Not eligible %((%d+) Min (%d+) Sec%)$",
      "Недоступно (через {1} мин {2} сек)" },
    { "^Not eligible for loot from this encounter%.$",
      "Добыча с этого боя вам не положена." },
}

for _, s in ipairs({
    { "Fire",   "от магии огня" },
    { "Frost",  "от магии льда" },
    { "Shadow", "от магии тьмы" },
    { "Nature", "от магии природы" },
    { "Arcane", "от тайной магии" },
    { "Holy",   "от светлой магии" },
    { "Physical", "физического урона" },
}) do
    PATTERN_RULES[#PATTERN_RULES + 1] = {
        "^%+(%d+) %- (%d+) " .. s[1] .. " Damage$",
        s[1] == "Physical" and ("+{1}-{2} ед. " .. s[2])
                            or ("+{1}-{2} ед. урона " .. s[2]),
    }
end

function CoARU_TranslateItemPrefix(line)
    if not line then return nil end
    local color = line:match("^(|[cC]%x%x%x%x%x%x%x%x)")
    local plain = line
    if color then
        plain = plain:gsub("^|[cC]%x%x%x%x%x%x%x%x", "", 1):gsub("|r$", "")
    end

    do
        local head, tail = plain:match("^(.+) %(([^()]*)%)$")
        if head and tail and tail:find("[\208\209]") and not head:find("[\208\209]") then
            local ok, ru = pcall(CoARU_TranslateBlock, nil, head)
            if ok and type(ru) == "string" and ru ~= "" and ru ~= head then
                return ru .. " (" .. tail .. ")"
            end
        end
    end

    do
        local head, sub = plain:match("^(.-,%s*)([%a][%a%-' ]*)$")
        if head and sub and SUB[sub] and head:find("[\208\209]") then
            return head .. SUB[sub]
        end
    end
    do
        local head, tail = plain:match("^(%a[%a%-' ]-) (%(.*)$")
        local sru = head and SUB[head]
        if sru then

            local n = tail:match("^%((%d+) [Ss]lots?%)$")
            if n then
                local word = CoARU_RuPlural and CoARU_RuPlural(n, "ячейка", "ячейки", "ячеек")
                if word then tail = "(" .. n .. " " .. word .. ")" end
            end
            local out = sru .. " " .. tail
            return color and (color .. out .. "|r") or out
        end
    end

    local ru
    for _, rule in ipairs(PREFIX_RULES) do
        if plain:find(rule[1]) then
            ru = (plain:gsub(rule[1], rule[2], 1))

            if rule.tail and CoARU_ItemNameEN then
                local head, name = ru:match("^(.-: )(.+)$")
                if name then
                    local nameRU = CoARU_ItemNameEN[name]
                    if type(nameRU) == "string" and nameRU ~= "" and nameRU ~= name then
                        ru = head .. nameRU
                    end
                end
            end
            break
        end
    end
    if not ru then
        for _, rule in ipairs(PATTERN_RULES) do
            local caps = { plain:match(rule[1]) }
            if caps[1] ~= nil then
                ru = (rule[2]:gsub("{(%d+)}", function(n)
                    return caps[tonumber(n)] or "?"
                end))

                if rule[3] and CoARU_LocalizeNames then
                    local ok, res = pcall(CoARU_LocalizeNames, ru)
                    if ok and type(res) == "string" and res ~= "" then ru = res end
                end
                break
            end
        end
    end

    if not ru and CoARU_ItemNameLine and plain:find("[\208\209]") then
        local head, name, cnt = plain:match("^(.-[\208\209][^:]*: )([^:]+) (%(%d+%))$")
        if head and name and not name:find("[\208\209]") then
            local rn = CoARU_ItemNameLine(name)
            if rn then ru = head .. rn .. " " .. cnt end
        end
    end
    if not ru then return nil end

    if CoARU_ItemNameLine then
        ru = (ru:gsub("^(.-: )(.+) (%(%d+%))$", function(head, name, cnt)
            local rn = CoARU_ItemNameLine(name)
            return head .. (rn or name) .. " " .. cnt
        end))
    end
    if color then ru = color .. ru .. "|r" end
    return ru
end

local STAT_LC

local function statIndex()
    if STAT_LC then return STAT_LC end
    STAT_LC = {}
    for k, v in pairs(CoARU_G or {}) do
        local name = k:match("^%+# (.+)$")
        if name then STAT_LC[name:lower()] = v end
    end
    return STAT_LC
end

function CoARU_TranslateStatCombo(line)
    if not line then return nil end
    local color = line:match("^(|[cC]%x%x%x%x%x%x%x%x)")
    local plain = line
    if color then
        plain = plain:gsub("^|[cC]%x%x%x%x%x%x%x%x", "", 1):gsub("|r$", "")
    end
    plain = plain:match("^%s*(.-)%s*$")

    if not plain:find("^[+-]%d") then return nil end

    local pos = {}
    for p in plain:gmatch("()[+-]%d+") do pos[#pos + 1] = p end

    if #pos < 1 then return nil end

    local idx, out = statIndex(), {}
    for i = 1, #pos do
        local chunk = plain:sub(pos[i], (pos[i + 1] and pos[i + 1] - 1) or #plain)
        local sign, num, name = chunk:match("^([+-])(%d+)%s+(.-)%s*$")
        if not sign then return nil end
        name = name:gsub("%.$", ""):gsub("%s+$", "")
        local ru = idx[name:lower()]
        if not ru then return nil end
        ru = ru:gsub("{1}", num)
        if sign == "-" then ru = ru:gsub("%+" .. num, "-" .. num, 1) end
        out[#out + 1] = ru
    end

    local res = table.concat(out, " ")
    if plain:find("%.$") and not res:find("%.$") then res = res .. "." end
    if color then res = color .. res .. "|r" end
    return res
end
