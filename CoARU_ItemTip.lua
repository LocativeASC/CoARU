local RU = CoARU_ItemTipRU or {}
local SUB = CoARU_ItemTipSubclass or {}
local OWN = CoARU_ItemTipOwn or {}

local function unsupported(fmt)
    for c in fmt:gmatch("%%(.)") do
        if c ~= "c" and c ~= "d" and c ~= "s" and c ~= "%" then return true end
    end
    return false
end

local function buildEn(fmt, sign)
    local out = fmt:gsub("%%%%", "\1")
    out = out:gsub("%%c", sign)
    out = out:gsub("%%[ds]", "#")
    return (out:gsub("\1", "%%"))
end

local function buildRu(fmt, sign)
    local out = fmt:gsub("%%%%", "\1")
    out = out:gsub("%%c", sign)
    local i = 0
    out = out:gsub("%%[ds]", function()
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
    local en = _G[key]
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
        local en = _G[key]
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

local errWaiter = CreateFrame("Frame")
errWaiter:RegisterEvent("PLAYER_LOGIN")
errWaiter:SetScript("OnEvent", function() hookErrors() end)
hookErrors()

local PREFIX_RULES = {
    { "^Unique%-Equipped: ", "Уникальная экипировка: " },

    { "^Transmogrified to: ", "Внешность предмета: " },
}

local PATTERN_RULES = {
    {
        "^Use: Returns you to (.-)%.%s*Speak to an Innkeeper in a different place to change your "
            .. "home location%.%s*%((%d+) Min Cooldown%)$",
        "Использование: переносит вас в {1}. Чтобы сменить дом, поговорите с трактирщиком в "
            .. "другом месте. (Восстановление: {2} мин.)",
    },

    {
        "^Use: Use this whistle to tame an? (.-)%.?$",
        "Использование: приручает существо {1} с помощью свистка.",
    },

    {
        "^<Made by (.-)>$",
        "<Изготовитель: {1}>",
    },
}

function CoARU_TranslateItemPrefix(line)
    if not line then return nil end
    local color = line:match("^(|[cC]%x%x%x%x%x%x%x%x)")
    local plain = line
    if color then
        plain = plain:gsub("^|[cC]%x%x%x%x%x%x%x%x", "", 1):gsub("|r$", "")
    end

    local ru
    for _, rule in ipairs(PREFIX_RULES) do
        if plain:find(rule[1]) then
            ru = (plain:gsub(rule[1], rule[2], 1))
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
                break
            end
        end
    end
    if not ru then return nil end
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
