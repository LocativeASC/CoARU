local ORIG = setmetatable({}, { __mode = "k" })

CoARU_OriginalMode = false

local TIPS = { "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2",
               "WorldMapTooltip" }

local MOD_CHECK = {
    ALT   = function() return IsAltKeyDown() end,
    CTRL  = function() return IsControlKeyDown() end,
    SHIFT = function() return IsShiftKeyDown() end,
    NONE  = function() return false end,
}

local DEFAULT_MOD = "ALT"

local function opts()
    CoARU_DB = CoARU_DB or {}
    CoARU_DB.opts = CoARU_DB.opts or {}
    return CoARU_DB.opts
end

function CoARU_OriginalMod()
    local m = opts().origMod
    return MOD_CHECK[m] and m or DEFAULT_MOD
end

local function wantOriginal()
    local held = MOD_CHECK[CoARU_OriginalMod()]() and true or false
    local sticky = opts().origSticky and true or false
    return held ~= sticky
end

local function grabColor(fs)
    if not fs.GetTextColor then return nil end
    local ok, r, g, b, a = pcall(fs.GetTextColor, fs)
    if not ok or not r then return nil end
    return { r, g, b, a or 1 }
end

function CoARU_ReapplyColor(fs)
    local rec = fs and ORIG[fs]
    local c = rec and rec.rgb
    if not (c and fs.SetTextColor) then return end

    local ok, cur = pcall(fs.GetText, fs)
    if not ok or (cur ~= rec.ru and cur ~= rec.en) then return end
    pcall(fs.SetTextColor, fs, c[1], c[2], c[3], c[4])
end

local clientOriginal

function CoARU_SetTranslated(fs, en, ru)
    if not fs then return end

    if en and en:find("[\208\209]") then
        local full = clientOriginal(en)
        if full then en = full end
    end

    local prev = ORIG[fs]
    if prev and prev.ru == en and prev.en and prev.en ~= en then
        en = prev.en
    end
    local rgb = grabColor(fs)

    ORIG[fs] = { en = en, ru = ru, rgb = rgb, src = CoARU_LastSource }
    CoARU_LastSource = nil
    fs:SetText(CoARU_OriginalMode and en or ru)
    CoARU_ReapplyColor(fs)
end

local FMT = "%%[%-%d%.]*[dsfgi]"
local function toPattern(ru)
    local out, n, pos = {}, 0, 1
    while true do
        local s, e = ru:find(FMT, pos)
        if not s then
            out[#out + 1] = ru:sub(pos):gsub("[%^%$%(%)%.%[%]%*%+%-%?]", "%%%0")
            break
        end
        out[#out + 1] = ru:sub(pos, s - 1):gsub("[%^%$%(%)%.%[%]%*%+%-%?]", "%%%0")
        local t = ru:sub(e, e)
        n = n + 1

        if t == "d" or t == "i" then
            out[#out + 1] = "(%-?%d+)"
        elseif t == "f" or t == "g" then
            out[#out + 1] = "([%d%.%-]+)"
        else
            out[#out + 1] = "([^\n]-)"
        end
        pos = e + 1
    end
    return table.concat(out), n
end

local REV, REVP

local RESOLVED = {}

local RESOLVED_CAP = 2000
local RESOLVED_N = 0

local function buildReverse()
    REV, REVP = {}, {}
    if type(CoARU_GS_EN) ~= "table" then return end
    for key, en in pairs(CoARU_GS_EN) do
        local ru = _G[key]
        if type(en) == "string" and type(ru) == "string" and en ~= "" and ru ~= "" and en ~= ru then
            if not ru:find("%%") then

                if REV[ru] == nil then
                    REV[ru] = en
                elseif REV[ru] ~= en then
                    REV[ru] = false
                end
            elseif not ru:find("%%%d+%$") and not en:find("%%%d+%$") then

                local pat, n = toPattern(ru)
                local i = 0
                local rep = en:gsub(FMT, function()
                    i = i + 1
                    return "%" .. i
                end)

                local literal = #(ru:gsub(FMT, ""))
                if n > 0 and n == i and literal >= 6 then
                    REVP[#REVP + 1] = { pat = "^" .. pat .. "$", rep = rep, w = literal }
                end
            end
        end
    end
end

local FRAG_RULES = {
    { pat = "^INVTYPE_" },
    { pat = "^ITEM_MOD_" },
    { pat = "^ITEM_SUBCLASS_" },
    { pat = "^ITEM_SOULBOUND$" },
    { pat = "^ITEM_BIND" },
    { pat = "^SPEED$" },
    { pat = "^REQUIRES$" },
    { pat = "^ARMOR$" },

    { pat = "^SPELL_CAST_TIME_INSTANT", pick = "Instant" },
}

local FRAGS

local function fragRank(key)
    for i = 1, #FRAG_RULES do
        if key:find(FRAG_RULES[i].pat) then return i, FRAG_RULES[i].pick end
    end
    return nil
end

local function isLetterByte(b)
    if not b then return false end
    if b >= 128 then return true end
    return (b >= 65 and b <= 90) or (b >= 97 and b <= 122)
end

local function buildFrags()
    FRAGS = {}
    if type(CoARU_GS_EN) ~= "table" then return end
    local best = {}
    for key, en in pairs(CoARU_GS_EN) do
        local ru = _G[key]
        if type(en) == "string" and type(ru) == "string" and en ~= "" and ru ~= ""
           and en ~= ru and not ru:find("%%") and not en:find("%%") and ru:find("[\208\209]") then
            local rank, pick = fragRank(key)
            if rank then
                local val = pick or en
                local cur = best[ru]
                if not cur or rank < cur.rank then
                    best[ru] = { en = val, rank = rank, alt = nil }
                elseif rank == cur.rank and cur.en ~= val then
                    cur.alt = val
                end
            end
        end
    end
    for ru, v in pairs(best) do
        local en = v.en
        if v.alt then

            local a = CoARU_TranslateByIndex and CoARU_TranslateByIndex(v.en)
            local b = CoARU_TranslateByIndex and CoARU_TranslateByIndex(v.alt)
            if a and not b then en = v.en
            elseif b and not a then en = v.alt
            else en = nil end
        end
        if en then FRAGS[#FRAGS + 1] = { ru = ru, en = en } end
    end

    if type(CoARU_REQ_TERMS) == "table" then
        for _, pair in ipairs(CoARU_REQ_TERMS) do
            local pat, ru = pair[1], pair[2]
            if type(pat) == "string" and type(ru) == "string"
               and not pat:find("%%[^%-]") and ru:find("[\208\209]") then
                FRAGS[#FRAGS + 1] = { ru = ru, en = (pat:gsub("%%%-", "-")) }
            end
        end
    end

    table.sort(FRAGS, function(a, b) return #a.ru > #b.ru end)
end

local function decompose(ru)
    if not FRAGS then buildFrags() end
    if #FRAGS == 0 then return nil end
    local out, i, n, hitAny = {}, 1, #ru, false
    while i <= n do
        local hit
        for k = 1, #FRAGS do
            local f = FRAGS[k]
            local len = #f.ru
            if ru:sub(i, i + len - 1) == f.ru
               and not isLetterByte(i > 1 and ru:byte(i - 1) or nil)
               and not isLetterByte(ru:byte(i + len)) then
                hit = f
                break
            end
        end
        if hit then
            out[#out + 1] = hit.en
            i = i + #hit.ru
            hitAny = true
        elseif isLetterByte(ru:byte(i)) then
            return nil
        else
            out[#out + 1] = ru:sub(i, i)
            i = i + 1
        end
    end
    if not hitAny then return nil end
    local res = table.concat(out)
    if res == ru then return nil end
    return res
end

function CoARU_OriginalRebuild()
    buildReverse()
    FRAGS = nil
    RESOLVED = {}

    table.sort(REVP, function(a, b) return (a.w or 0) > (b.w or 0) end)
end

local TRIGGER_KEYS = { "ITEM_SPELL_TRIGGER_ONEQUIP", "ITEM_SPELL_TRIGGER_ONUSE",
                       "ITEM_SPELL_TRIGGER_ONPROC" }
local function triggers()
    local out = {}
    for _, key in ipairs(TRIGGER_KEYS) do
        local en = (CoARU_GS_EN and CoARU_GS_EN[key]) or _G[key]
        if type(en) == "string" and en ~= "" then
            local forms = { en }
            local g = _G[key]
            if type(g) == "string" and g ~= "" and g ~= en then forms[#forms + 1] = g end
            local own = CoARU_ItemTipRU and CoARU_ItemTipRU[key]
            if type(own) == "string" and own ~= "" and own ~= en then forms[#forms + 1] = own end
            out[#out + 1] = { en = en, forms = forms }
        end
    end
    return out
end

local resolveCore

function clientOriginal(ru)
    if not REV then CoARU_OriginalRebuild() end
    local memo = RESOLVED[ru]
    if memo ~= nil then
        return memo or nil
    end
    local res = resolveCore(ru)
    if not res then
        for _, t in ipairs(triggers()) do
            for _, pre in ipairs(t.forms) do
                if #pre > 0 and ru:sub(1, #pre) == pre then

                    local gap, body = ru:sub(#pre + 1):match("^(%s*)(.*)$")
                    local got = body ~= "" and resolveCore(body)

                    if got and got ~= body then
                        res = t.en .. gap .. got
                        break
                    end
                end
            end
            if res then break end
        end
    end

    if res and res:find("[\208\209]") then res = nil end
    if RESOLVED[ru] == nil then
        if RESOLVED_N >= RESOLVED_CAP then
            RESOLVED, RESOLVED_N = {}, 0
        end
        RESOLVED_N = RESOLVED_N + 1
    end
    RESOLVED[ru] = res or false
    return res
end

function resolveCore(ru)
    local en = REV[ru]

    if en == false then en = nil end
    if en then return en end

    for i = 1, #REVP do
        local e = REVP[i]
        if ru:find(e.pat) then
            local out = ru:gsub(e.pat, e.rep)
            if out and out ~= ru and not out:find("[\208\209]") then return out end
        end
    end

    return decompose(ru)
end

function CoARU_OriginalPair(fs)
    local rec = fs and ORIG[fs]
    if not rec then return nil end
    return rec.en, rec.ru, rec.src
end

function CoARU_ClientOriginal(ru)
    if type(ru) ~= "string" or ru == "" then return nil end
    return clientOriginal(ru)
end

function CoARU_RegisterClientLine(fs, ru)
    if not fs or type(ru) ~= "string" or ru == "" then return false end
    local en = clientOriginal(ru)
    if not en or en == ru then return false end

    local rec = ORIG[fs]
    if rec and rec.en == en and rec.src and rec.src ~= "пакет интерфейса" then

        local want = CoARU_OriginalMode and rec.en or rec.ru
        local ok, cur = pcall(fs.GetText, fs)
        if ok and cur ~= want then
            fs:SetText(want)
            CoARU_ReapplyColor(fs)
        end
        return true
    end

    CoARU_LastSource = "пакет интерфейса"
    CoARU_SetTranslated(fs, en, ru)
    return true
end

local SWAP_MISS_CAP = 60
local function noteSwapMiss(cur, rec)
    if not CoARU_DB then return end
    CoARU_DB.origmiss = CoARU_DB.origmiss or {}
    local m = CoARU_DB.origmiss
    if #m >= SWAP_MISS_CAP then return end
    m[#m + 1] = { mode = CoARU_OriginalMode and "en" or "ru",
                  cur = cur, en = rec and rec.en, ru = rec and rec.ru,
                  why = rec and "форма не та" or "пары нет" }
end

local function swapOne(fs)
    if not fs then return false end
    local ok, cur = pcall(fs.GetText, fs)
    if not ok or type(cur) ~= "string" or cur == "" then return false end

    local rec = ORIG[fs]

    if rec and cur ~= rec.en and cur ~= rec.ru then rec = nil end

    if not rec and CoARU_OriginalMode and CoARU_GS_EN then
        local en = clientOriginal(cur)
        if en then
            rec = { en = en, ru = cur, rgb = grabColor(fs) }
            ORIG[fs] = rec
        end
    end

    if not rec then

        if CoARU_OriginalMode and cur:find("[\208\209]") then noteSwapMiss(cur, nil) end
        return false
    end
    local want  = CoARU_OriginalMode and rec.en or rec.ru
    local other = CoARU_OriginalMode and rec.ru or rec.en
    if want == other then return false end

    if cur == want then return false end

    if cur ~= other then
        if #cur > #other and cur:sub(1, #other) == other then
            fs:SetText(want .. cur:sub(#other + 1))
            return true
        end
        noteSwapMiss(cur, rec)
        return false
    end
    fs:SetText(want)
    return true
end

local dumpFrame = CreateFrame("Frame")
dumpFrame:Hide()
local dumpPending
dumpFrame:SetScript("OnUpdate", function(self)
    self:Hide()
    if not dumpPending then return end
    for i = 1, #dumpPending do
        local e = dumpPending[i]
        local ok, cur = pcall(e.fs.GetText, e.fs)
        e.rec[5] = ok and cur or "?"
    end
    dumpPending = nil
end)

local function dumpOn()
    return CoARU_DB and CoARU_DB.opts and CoARU_DB.opts.altdump
end

local function dumpStart()
    if not dumpOn() then return nil end
    CoARU_DB.altdump = CoARU_DB.altdump or {}
    if #CoARU_DB.altdump >= 40 then return nil end
    local shot = { mode = CoARU_OriginalMode and "en" or "ru", lines = {} }
    CoARU_DB.altdump[#CoARU_DB.altdump + 1] = shot
    return shot
end

local function dumpLine(shot, tag, fs)
    if not shot or not fs then return nil end
    local ok, cur = pcall(fs.GetText, fs)
    if not ok or type(cur) ~= "string" or cur == "" or not cur:find("%S") then return nil end
    local rec = { tag, cur }
    shot.lines[#shot.lines + 1] = rec
    return rec
end

local function swapTip(tip, allowShow)
    local name = tip.GetName and tip:GetName()
    if not name then return end

    local ok, owner = pcall(function() return tip.GetOwner and tip:GetOwner() end)
    if ok and owner and owner.GetName then
        local oname = owner:GetName()
        if type(oname) == "string" and oname:find("^CoARU") then return end
    end
    local changed = false
    local mine, nmine = {}, 0
    local shot = allowShow and dumpStart() or nil
    local watched = shot and {} or nil
    local function remember(fs)
        local rec = dumpLine(shot, nil, fs)
        local swapped = swapOne(fs)
        if rec then
            local ok, cur = pcall(fs.GetText, fs)
            rec[3] = ok and cur or "?"
            rec[1] = swapped and "подменили" or "не тронули"
            watched[#watched + 1] = { fs = fs, rec = rec }
        end
        if not swapped then return false end
        changed = true
        local ok, txt = pcall(fs.GetText, fs)
        if ok and type(txt) == "string" then
            nmine = nmine + 1
            mine[nmine] = { fs = fs, t = txt }
        end
        return true
    end
    local n = tip.NumLines and tip:NumLines() or 0
    for i = 1, n do
        remember(_G[name .. "TextLeft" .. i])
        remember(_G[name .. "TextRight" .. i])
    end

    for i = 1, 4 do
        remember(_G[name .. "MoneyFrame" .. i .. "PrefixText"])
    end

    if changed and allowShow and tip.Show then
        tip:Show()
        if watched then
            for i = 1, #watched do
                local w = watched[i]
                local ok, cur = pcall(w.fs.GetText, w.fs)
                w.rec[4] = ok and cur or "?"
            end
        end

        for i = 1, nmine do
            local e = mine[i]
            local ok, cur = pcall(e.fs.GetText, e.fs)
            if ok and cur ~= e.t then pcall(e.fs.SetText, e.fs, e.t) end
        end

        if CoARU_RefreshTooltip then CoARU_RefreshTooltip(tip) end
        if watched then
            for i = 1, #watched do
                local w = watched[i]
                local ok, cur = pcall(w.fs.GetText, w.fs)
                w.rec[5] = ok and cur or "?"
            end
            dumpPending = watched
            dumpFrame:Show()
        end
    end

    return changed
end

local function applyMode(allowShow)
    local any = false
    for _, n in ipairs(TIPS) do
        local tip = _G[n]
        if tip and tip.IsShown and tip:IsShown() then
            if swapTip(tip, allowShow) then any = true end
        end
    end
    return any
end

local GEOM_KEYS = 80
local GEOM_TOL  = 0.5

local function geomEdges(f)
    if not f or not f.GetLeft then return nil end
    local okL, l = pcall(f.GetLeft, f)
    local okR, r = pcall(f.GetRight, f)
    local okT, t = pcall(f.GetTop, f)
    local okB, b = pcall(f.GetBottom, f)

    if not (okL and okR and okT and okB and l and r and t and b) then return nil end
    return l, r, t, b
end

local function geomScale(f)
    if not f or not f.GetEffectiveScale then return nil end
    local ok, sc = pcall(f.GetEffectiveScale, f)
    if ok and type(sc) == "number" and sc > 0 then return sc end
    return nil
end

local function geomKey(name, head)
    local plain = head:gsub("|[cC]%x%x%x%x%x%x%x%x", ""):gsub("|[rR]", "")

    return name .. " | " .. CoARU_Utf8Sub(plain, 40)
end

local function geomSampleTip(tip)
    local name = tip.GetName and tip:GetName()
    if not name then return end
    local h1 = _G[name .. "TextLeft1"]
    local head = h1 and h1.GetText and h1:GetText()
    if not head or head == "" then return end

    local rec1 = ORIG[h1]
    if rec1 and (head == rec1.en or head == rec1.ru) then head = rec1.en end
    local tl, tr, tt, tb = geomEdges(tip)
    if not tl then return end

    local db = CoARU_DB.tipgeom
    local key = geomKey(name, head)
    local rec = db[key]
    if not rec then
        local n = 0
        for _ in pairs(db) do n = n + 1 end
        if n >= GEOM_KEYS then return end
        rec = { ru = {}, en = {} }
        db[key] = rec
    end

    local ts = geomScale(tip) or 1
    local m = CoARU_OriginalMode and rec.en or rec.ru
    local w, h = (tr - tl) * ts, (tt - tb) * ts
    m.n = (m.n or 0) + 1
    if not m.minW or w < m.minW then m.minW = w end
    if not m.maxW or w > m.maxW then m.maxW = w end
    if not m.minH or h < m.minH then m.minH = h end
    if not m.maxH or h > m.maxH then m.maxH = h end
    if m.lastW and math.abs(m.lastW - w) > GEOM_TOL then m.jumps = (m.jumps or 0) + 1 end
    m.lastW, m.lastH = w, h

    local nl = tip.NumLines and tip:NumLines() or 0
    for i = 1, nl do
        local sides = { "TextLeft", "TextRight" }
        for si = 1, 2 do
            local fs = _G[name .. sides[si] .. i]
            local txt = fs and fs.GetText and fs:GetText()
            if txt and txt ~= "" and txt:find("%S")
               and (not fs.IsShown or fs:IsShown()) then
                local l, r, t, b = geomEdges(fs)
                if l then

                    local outR, outB = (r - tr) * ts, (tb - b) * ts
                    local out = outR > outB and outR or outB
                    if out > GEOM_TOL and out > (rec.outMax or 0) then
                        rec.outMax   = out
                        rec.outLine  = sides[si] .. i
                        rec.outMode  = CoARU_OriginalMode and "en" or "ru"
                        rec.outWhere = outB > outR and "ниже рамки" or "правее рамки"
                        rec.outText  = CoARU_Utf8Sub(txt, 60)

                        rec.suspect  = (out > w) or nil
                    end

                    if not rec.scales then
                        rec.scales = ("тултип %.3f / надпись %s")
                            :format(ts, geomScale(fs) and ("%.3f"):format(geomScale(fs)) or "нет")
                    end
                end
            end
        end
    end
end

local function geomTick()
    if not CoARU_DB then return end
    CoARU_DB.tipgeom = CoARU_DB.tipgeom or {}
    for _, n in ipairs(TIPS) do
        local tip = _G[n]
        if tip and tip.IsShown and tip:IsShown() then geomSampleTip(tip) end
    end
end

local watcher = CreateFrame("Frame")
local acc, last = 0, nil
local function pulse()
    local want = wantOriginal()
    CoARU_OriginalMode = want
    if want == last then

        if want then applyMode(false) end
        return
    end
    last = want
    local swapped = applyMode(true)

    if want and swapped then
        local o = opts()
        o.origUsed = (tonumber(o.origUsed) or 0) + 1
    end
end

watcher:SetScript("OnUpdate", function(self, elapsed)
    acc = acc + elapsed
    if acc < 0.05 then return end
    acc = 0
    pulse()

    if CoARU_DB and CoARU_DB.opts and CoARU_DB.opts.tipgeom then geomTick() end
end)

local KEY_NAME = { ALT = "Alt", CTRL = "Ctrl", SHIFT = "Shift" }
local HINT_USES = 3

function CoARU_HintText()
    local o = opts()
    if o.hint == false then return nil end
    if (tonumber(o.origUsed) or 0) >= HINT_USES then return nil end
    local name = KEY_NAME[CoARU_OriginalMod()]
    if not name then return nil end
    return "Зажмите " .. name .. ", чтобы увидеть оригинал"
end

function CoARU_AddHint(tip)
    local text = CoARU_HintText()
    if not text or not tip or not tip.AddLine or not tip.NumLines then return false end
    local name = tip.GetName and tip:GetName()
    if not name then return false end
    for i = 1, (tip:NumLines() or 0) do
        local fs = _G[name .. "TextLeft" .. i]
        if fs and fs:GetText() == text then return false end
    end
    tip:AddLine(text, 0.5, 0.5, 0.5)
    return true
end

function CoARU_OriginalStatus()
    local n = 0
    for _ in pairs(ORIG) do n = n + 1 end

    return n, CoARU_OriginalMod(), opts().origSticky and true or false, RESOLVED_N
end

function CoARU_SetOriginalMod(word)
    local key = (word or ""):upper()
    if key == "OFF" then key = "NONE" end
    if not MOD_CHECK[key] then return nil end
    opts().origMod = key
    last = nil
    return key
end

function CoARU_ToggleOriginalSticky()
    local o = opts()
    o.origSticky = not o.origSticky
    last = nil
    return o.origSticky
end

local function geomFmt(m)
    if not m or not m.n then return "нет замеров" end
    local w = ("шир %.1f"):format(m.maxW or 0)
    if (m.maxW or 0) - (m.minW or 0) > GEOM_TOL then
        w = ("шир %.1f..%.1f"):format(m.minW or 0, m.maxW or 0)
    end
    return ("%s выс %.1f, смен ширины %d, замеров %d")
        :format(w, m.maxH or 0, m.jumps or 0, m.n)
end

function CoARU_TipGeom(arg)
    CoARU_DB = CoARU_DB or {}
    CoARU_DB.opts = CoARU_DB.opts or {}
    local pre = "|cffff8800CoARU|r "
    if arg == "on" or arg == "off" then
        CoARU_DB.opts.tipgeom = (arg == "on") or nil
        if arg == "on" then CoARU_DB.tipgeom = CoARU_DB.tipgeom or {} end
        print(pre .. "замер геометрии тултипа: " .. (arg == "on" and "|cff00ff00включен|r"
              or "|cffff0000выключен|r"))
        if arg == "on" then
            print(pre .. "наводи мышь на предметы и способности, жми и отпускай клавишу оригинала, потом /coaru tipgeom")
        end
        return
    end

    local db = CoARU_DB.tipgeom or {}
    local keys, out, split, suspect = 0, {}, {}, 0
    for k, rec in pairs(db) do
        keys = keys + 1
        if rec.suspect then suspect = suspect + 1 end
        if rec.outMax then out[#out + 1] = { k = k, r = rec } end

        local ru, en = rec.ru, rec.en
        if ru and en and ru.maxW and en.maxW then
            local d = math.abs(ru.maxW - en.maxW)
            if d > GEOM_TOL then split[#split + 1] = { k = k, d = d, r = rec } end
        end
    end
    table.sort(out,   function(a, b) return (a.r.outMax or 0) > (b.r.outMax or 0) end)
    table.sort(split, function(a, b) return a.d > b.d end)

    print(("%sтултипов замерено: %d, с вылетом за рамку: %d, ширина ru≠en: %d%s")
        :format(pre, keys, #out, #split,
                CoARU_DB.opts.tipgeom and "" or " |cffff0000(запись ВЫКЛЮЧЕНА)|r"))

    if suspect > 0 then
        print(("%s|cffff0000ЗАМЕР СОМНИТЕЛЕН|r: у %d тултипов вылет больше собственной ширины окна. Это поломка прибора, а не верстки.")
            :format(pre, suspect))
    end
    for i = 1, math.min(6, #out) do
        local e = out[i]
        print(("  вылет %.1f пикс %s (%s, %s): %s")
            :format(e.r.outMax, e.r.outWhere or "?", e.r.outMode or "?",
                    e.r.outLine or "?", (e.r.outText or ""):gsub("|", "||")))
    end
    for i = 1, math.min(6, #split) do
        local e = split[i]
        print(("  ru≠en на %.1f пикс — %s"):format(e.d, e.k))
        print("    ru: " .. geomFmt(e.r.ru))
        print("    en: " .. geomFmt(e.r.en))
    end
    if keys == 0 then
        print(pre .. "замеров нет: либо запись выключена, либо мышь не наводили на тултип.")
    else
        print(pre .. "полная таблица уедет в SavedVariables (CoARU_DB.tipgeom) после /reload.")
    end
    return keys, #out, #split
end
