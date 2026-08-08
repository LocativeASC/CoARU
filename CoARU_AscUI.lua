local MAX_DEPTH = 12

local TICK = 0

local ROOTS = { "CallBoardUI", "PathToAscensionFrame", "TradeSkillFrame", "ChallengesFrame",
                "ProgressionFrame", "KeyboundDialog" }

local PANELS = { "Collections", "ToastContainer", "CoAClassBundleStore", "RestartTimerFrame" }

local POOL = {}
for i = 1, 8 do
    POOL[#POOL + 1] = "UIParentPoolFrameKeywordTooltipTemplate" .. i
end

local MISS_CAP = 3000

local function noteMiss(t)
    if not CoARU_DB then return false end
    CoARU_DB.uimiss = CoARU_DB.uimiss or {}
    local m = CoARU_DB.uimiss
    if m[t] then return false end
    local n = 0
    for _ in pairs(m) do n = n + 1 end
    if n >= MISS_CAP then return false end

    m[t] = (date and date("%d.%m %H:%M")) or true
    return true
end

local function looksEnglish(t)
    if CoARU_HasCyrillic and CoARU_HasCyrillic(t) then return false end
    return t:find("%a%a%a") ~= nil
end

local function zoneRU(name)
    if type(name) ~= "string" or name == "" or not CoARU_ZONE then return nil end
    local key
    if CoARU_ZONE[name] then
        key = name
    elseif CoARU_ZONE["The " .. name] then
        key = "The " .. name
    else
        return nil
    end
    local inst = CoARU_ZONE_INST and (CoARU_ZONE_INST[key] or CoARU_ZONE_INST[name])
    if inst then
        if not CoARU_ModOn("dungeons") then return nil end
    else
        if not CoARU_ModOn("zones") then return nil end
    end
    return CoARU_ZONE[key]
end

local function expandCaps(rep, ...)
    local caps, n = { ... }, select("#", ...)
    return (rep:gsub("%%(.)", function(c)
        if c == "%" then return "%" end
        local i = tonumber(c)
        if not i or i < 1 or i > n then return "%" .. c end
        local v = caps[i]
        if type(v) ~= "string" then return tostring(v) end
        return zoneRU(v) or v
    end))
end

local lookupCache, lookupN = {}, 0

local DIFFICULTY = {

    Heroic = "героический",
    Mythic = "эпохальный",
    Normal = "обычный",
}

local function wrapNameRU(n)
    if type(n) ~= "string" or n == "" then return nil end

    if n:find("%.$") or not n:find("^[A-Z]") then return nil end
    local words = 0
    for _ in n:gmatch("%S+") do
        words = words + 1
        if words > 5 then return nil end
    end
    local ru = (CoARU_ItemNameEN and CoARU_ItemNameEN[n])
        or (CoARU_UNIT_N2R and CoARU_UNIT_N2R[n])
        or (CoARU_OBJ_N2R and CoARU_OBJ_N2R[n])
        or (CoARU_SPELL_NAME_RU and CoARU_SPELL_NAME_RU[n])
    if ru and ru ~= n then return ru end
    return nil
end

local function nameInWrapper(t)

    local head, body = t:match("^(%s*%-%s+)(.+)$")
    if body then
        local ru = wrapNameRU(body)
        if ru then return head .. ru end
    end

    body = t:match("^Defeat:%s+(.+)$")
    if body then
        local ru = wrapNameRU(body)
        if ru then return "Победить: " .. ru end
    end

    body = t:match("^Slay%s+(.+)$")
    if body then
        local suffix = ""
        local d, tail = body:match("^(%a+)%s+(.+)$")
        if d and DIFFICULTY[d] then
            body, suffix = tail, " (" .. DIFFICULTY[d] .. ")"
        end
        local ru = wrapNameRU(body)
        if ru then return "Убить: " .. ru .. suffix end
    end

    local pre, core, post = t:match("^(.-)%[(.-)%](.-)$")
    if core and core ~= ""
       and (pre == "" or pre:find("^|[cC]%x%x%x%x%x%x%x%x$"))
       and (post == "" or post:find("^|[rR]$")) then
        local ru = wrapNameRU(core)
        if ru then return pre .. "[" .. ru .. "]" .. post end
    end
    return nil
end

local function lookupUncached(t)

    local ru = CoARU_TUT and CoARU_TUT[t]
    if ru then return ru end

    ru = CoARU_ASCUI and CoARU_ASCUI[t]
    if ru then return ru end

    local trimmed = t:match("^%s*(.-)%s*$")
    if trimmed ~= t and CoARU_ASCUI then
        ru = CoARU_ASCUI[trimmed]
        if ru then return ru end
    end

    if CoARU_ASCUI_P then
        for i = 1, #CoARU_ASCUI_P do
            local e = CoARU_ASCUI_P[i]
            if trimmed:find(e.p) then
                local out = trimmed:gsub(e.p, function(...)
                    return expandCaps(e.r, ...)
                end)
                if out and out ~= trimmed then return out end
            end
        end
    end

    if CoARU_TranslateBlock then
        local ok, res = pcall(CoARU_TranslateBlock, nil, t)
        if ok and res and res ~= t then return res end
    end

    if CoARU_SpecNameRU then
        local ru = CoARU_SpecNameRU(trimmed)
        if ru then return ru end
    end

    local wrapped = nameInWrapper(t)
    if wrapped then return wrapped end
    return nil
end

local LOOKUP_CAP = 4000

local function lookup(t)
    local hit = lookupCache[t]
    if hit ~= nil then
        if hit == false then return nil end
        return hit
    end
    local ru = lookupUncached(t)
    if lookupN >= LOOKUP_CAP then
        lookupCache, lookupN = {}, 0
    end
    lookupCache[t] = ru or false
    lookupN = lookupN + 1
    return ru
end

local function chunkKey(s)
    s = s:gsub("|[cC]%x%x%x%x%x%x%x%x", ""):gsub("|[rR]", ""):gsub("|T[^|]*|t", "")
    s = s:gsub("|H[^|]*|h", ""):gsub("|h", "")
    return (s:match("^%s*(.-)%s*$"):gsub("%s+", " "))
end

local TUT_LOW
local function tutChunk(body)
    local ru = CoARU_TUT_CHUNK[body]
    if ru then return ru end
    if not TUT_LOW then
        TUT_LOW = {}
        for en, r in pairs(CoARU_TUT_CHUNK) do TUT_LOW[en:lower()] = r end
    end
    return TUT_LOW[body:lower()]
end

local function nextTag(t, pos)
    local best, bestE

    for _, pat in ipairs({ "<[^>]->", "{[^}]-}" }) do
        local s1, e1 = t:find(pat, pos)
        if s1 and (not best or s1 < best) then best, bestE = s1, e1 end
    end
    return best, bestE
end

local LINK = "|c%x%x%x%x%x%x%x%x|Hkeyword:%d+|h.-|h|r"

local function cyrTail(s, pos)
    while pos <= #s do
        local b = s:byte(pos)
        if (b == 208 or b == 209) and pos + 1 <= #s then pos = pos + 2 else break end
    end
    return pos - 1
end

local function atWordStart(s, a)
    if a <= 2 then return true end
    local b = s:byte(a - 2)
    return not (b == 208 or b == 209)
end

local function findForm(ru, entry)
    for _, f in ipairs(entry.f or {}) do
        local a, b = ru:find(f, 1, true)

        if a and atWordStart(ru, a) then return a, cyrTail(ru, b + 1) end
    end
    for _, st in ipairs(entry.s or {}) do
        local a, b = ru:find(st, 1, true)
        if a and atWordStart(ru, a) then return a, cyrTail(ru, b + 1) end
    end

    if entry.w1 and entry.w2 then
        for _, head in ipairs(entry.w1) do
            local a = ru:find(head, 1, true)
            if a then
                local c, d = ru:find(entry.w2, a, true)
                if c and d - a < 60 then return a, cyrTail(ru, d + 1) end
            end
        end
    end
    return nil
end

local function relink(src, ru)
    if not CoARU_TUT_KW or not src:find("|Hkeyword:", 1, true) then return ru end
    for link in src:gmatch(LINK) do
        local color = link:match("^(|c%x%x%x%x%x%x%x%x)")
        local id = link:match("|Hkeyword:(%d+)|h")
        local word = link:match("|h(.-)|h|r$")
        local entry = word and CoARU_TUT_KW[word]
        if entry and not ru:find("|Hkeyword:" .. id .. "|h", 1, true) then
            local a, b = findForm(ru, entry)
            if a then
                ru = ru:sub(1, a - 1) .. color .. "|Hkeyword:" .. id .. "|h"
                     .. ru:sub(a, b) .. "|h|r" .. ru:sub(b + 1)
            end
        end
    end
    return ru
end

local function translateHtml(t)
    if not CoARU_TUT_CHUNK then return nil end
    local out, changed, pos = {}, false, 1
    while true do
        local s, e = nextTag(t, pos)
        local text = t:sub(pos, (s or #t + 1) - 1)
        if text ~= "" then
            local lead = text:match("^(%s*)") or ""
            local tail = text:match("(%s*)$") or ""
            local body = chunkKey(text)
            local ru = body ~= "" and tutChunk(body) or nil
            if ru then
                out[#out + 1] = lead .. relink(text, ru) .. tail
                changed = true
            else
                out[#out + 1] = text

                if body ~= "" and looksEnglish(body) then noteMiss("[chunk] " .. text) end
            end
        end
        if not s then break end
        out[#out + 1] = t:sub(s, e)
        pos = e + 1
    end
    if not changed then return nil end
    return table.concat(out)
end

local PARA_SEP = { "|n|n", "\r\n\r\n", "\n\n" }
local function nextSep(t, pos)
    local best, bestE
    for _, sep in ipairs(PARA_SEP) do
        local a, b = t:find(sep, pos, true)
        if a and (not best or a < best) then best, bestE = a, b end
    end
    return best, bestE
end

local function tutParagraphs(t)
    local out, changed, pos = {}, false, 1
    while true do
        local s, e = nextSep(t, pos)
        local part = t:sub(pos, (s or #t + 1) - 1)
        if part:find("%S") then
            local lead = part:match("^(%s*)") or ""
            local tail = part:match("(%s*)$") or ""
            local body = chunkKey(part)
            local ru = body ~= "" and tutChunk(body) or nil
            if ru then
                out[#out + 1] = lead .. relink(part, ru) .. tail
                changed = true
            else
                out[#out + 1] = part

                if body ~= "" and looksEnglish(body) then noteMiss("[para] " .. part) end
            end
        else
            out[#out + 1] = part
        end
        if not s then break end
        out[#out + 1] = t:sub(s, e)
        pos = e + 1
    end
    if not changed then return nil end
    return table.concat(out)
end

local function setText(fs, s, en)
    if fs.SetDynamicText then
        local ok = pcall(fs.SetDynamicText, fs, s)
        if ok then return true end
    end
    if en and CoARU_SetTranslated then
        return (pcall(CoARU_SetTranslated, fs, en, s))
    end
    return (pcall(fs.SetText, fs, s))
end

local tradeMode = false

local function retextOne(fs)
    local ok, t = pcall(fs.GetText, fs)
    if not ok or type(t) ~= "string" or t == "" then return end
    if not t:find("%S") then return end
    if not looksEnglish(t) then return end

    if tradeMode and CoARU_TRADE_FILTER then
        local ru = CoARU_TRADE_FILTER[t:match("^%s*(.-)%s*$")]
        if ru then
            setText(fs, ru, t)
            return
        end
    end

    if t:find("<[^>]->") or t:find("{[^}]-}") then
        local html = translateHtml(t)
        if html then
            setText(fs, html, t)
            return
        end
    end

    local ru = lookup(t)

    if not ru and CoARU_TUT_CHUNK then ru = tutParagraphs(t) end
    if ru then
        setText(fs, ru, t)
    else

        if noteMiss(t) and CoARU_DB then
            CoARU_DB.uimissrc = CoARU_DB.uimissrc or {}
            local root = fs
            for _ = 1, 12 do
                local p2 = root.GetParent and root:GetParent()
                if not p2 then break end
                root = p2
            end
            local rn = root.GetName and root:GetName()
            CoARU_DB.uimissrc[t] = rn or "?"
        end
    end
end

local hookedHtml = setmetatable({}, { __mode = "k" })
local inHtmlHook = false

local function htmlRu(t)
    if type(t) ~= "string" or t == "" or not t:find("%S") then return nil end
    if not looksEnglish(t) then return nil end
    local ru = lookup(t)
    if not ru and CoARU_TUT_CHUNK then ru = tutParagraphs(t) end
    if ru and ru ~= t then return ru end
    return nil
end

local function hookHtml(f)
    if hookedHtml[f] or type(f) ~= "table" or not f.SetText then return end
    hookedHtml[f] = true

    local ok = pcall(hooksecurefunc, f, "SetText", function(self, txt)
        if inHtmlHook then return end
        local ru = htmlRu(txt)
        if not ru then return end
        inHtmlHook = true
        pcall(self.SetText, self, ru)
        inHtmlHook = false
    end)
    if not ok then hookedHtml[f] = nil end
end

local function stillEnglish(html)
    local ok, regions = pcall(function() return { html:GetRegions() } end)
    if not ok then return false end
    for _, r in ipairs(regions) do
        if r and r.GetObjectType and r:GetObjectType() == "FontString" and r ~= html.HiddenText then
            local o, t = pcall(r.GetText, r)
            if o and type(t) == "string" and looksEnglish(t) then return true end
        end
    end
    return false
end

local retext

local function doRegions(...)
    for i = 1, select("#", ...) do
        local r = select(i, ...)
        if r and r.GetObjectType and r:GetObjectType() == "FontString" then
            retextOne(r)
        end
    end
end

local function regionsOf(frame)
    return doRegions(frame:GetRegions())
end

local function objType(o)
    return o.GetObjectType and o:GetObjectType()
end

local function isShown(o)
    if not o.IsShown then return nil end
    return o:IsShown() and true or false
end

local function doChildren(depth, ...)
    for i = 1, select("#", ...) do
        local c = select(i, ...)

        local shownOk, shown = pcall(isShown, c)
        if shownOk and shown == false then

        else
        local o, kind = pcall(objType, c)
        if o and kind == "SimpleHTML" then

            hookHtml(c)
            retextOne(c)

            if stillEnglish(c) then retext(c, depth + 1) end
        else
            retext(c, depth + 1)
        end
        end
    end
end

local function childrenOf(frame, depth)
    return doChildren(depth, frame:GetChildren())
end

retext = function(frame, depth)
    if not frame or depth > MAX_DEPTH then return end
    if frame.GetRegions then pcall(regionsOf, frame) end
    if frame.GetChildren then pcall(childrenOf, frame, depth) end
end

function CoARU_AscUI_Probe()
    CoARU_DB = CoARU_DB or {}
    local out = {}
    local function look(f, depth, path)
        if not f or depth > 6 then return end
        local ok, shown = pcall(function() return f:IsShown() end)
        if not ok or not shown then return end
        local name = (f.GetName and f:GetName()) or "(без имени)"
        local kind = (f.GetObjectType and f:GetObjectType()) or "?"
        if kind == "SimpleHTML" or kind == "ScrollFrame" or kind == "FontString" then
            local txt = nil
            pcall(function() txt = f.GetText and f:GetText() end)
            out[#out + 1] = {
                path = path .. "/" .. name, kind = kind,
                readable = txt ~= nil and #tostring(txt) > 0,

                sample = txt and CoARU_Utf8Sub(tostring(txt), 60) or nil,
            }
        end
        if f.GetRegions then
            local o, rs = pcall(function() return { f:GetRegions() } end)
            if o then for _, r in ipairs(rs) do look(r, depth + 1, path .. "/" .. name) end end
        end
        if f.GetChildren then
            local o, cs = pcall(function() return { f:GetChildren() } end)
            if o then for _, c in ipairs(cs) do look(c, depth + 1, path .. "/" .. name) end end
        end
    end
    for name, obj in pairs(_G) do
        if type(name) == "string" and type(obj) == "table" and obj.IsShown and obj.GetObjectType then
            local ok, kind = pcall(function() return obj:GetObjectType() end)
            if ok and kind == "Frame" then
                local o, shown = pcall(function() return obj:IsShown() end)
                if o and shown and obj:GetParent() == UIParent then look(obj, 0, name) end
            end
        end
    end
    CoARU_DB.tutprobe = out
    local html, readable = 0, 0
    for _, e in ipairs(out) do
        if e.kind == "SimpleHTML" then
            html = html + 1
            if e.readable then readable = readable + 1 end
        end
    end
    print(("CoARU: снято элементов %d, из них SimpleHTML %d (читается текст у %d)."):format(
        #out, html, readable))
    print("Полный список в SavedVariables после /reload: CoARU_DB.tutprobe")
end

function CoARU_AscUI_Nameplates()
    CoARU_DB = CoARU_DB or {}
    local out, seen = {}, 0
    local ok, kids = pcall(function() return { WorldFrame:GetChildren() } end)
    if not ok then
        print("CoARU: WorldFrame недоступен")
        return
    end
    for _, f in ipairs(kids) do
        local o, shown = pcall(function() return f:IsShown() end)
        if o and shown then
            local regions = {}
            local o2, rs = pcall(function() return { f:GetRegions() } end)
            if o2 then
                for _, r in ipairs(rs) do
                    if r and r.GetObjectType and r:GetObjectType() == "FontString" then
                        local t = r:GetText()
                        if t and t ~= "" then regions[#regions + 1] = t end
                    end
                end
            end

            if #regions > 0 then
                seen = seen + 1
                out[#out + 1] = { name = f:GetName() or "(без имени)", texts = regions }
            end
        end
    end
    CoARU_DB.nameplates = out
    print(("CoARU: плашек с надписями найдено %d."):format(seen))
    for i = 1, math.min(3, #out) do
        print("   " .. table.concat(out[i].texts, " | "):sub(1, 70))
    end
    if seen == 0 then
        print("Ноль значит: либо неймплейты выключены (клавиша V), либо имя рисует C и Lua его не видит.")
    else
        print("Имя читается — ретекст дотянется. Полный список в SavedVariables после /reload.")
    end
end

function CoARU_AscUI_Sweep()
    if not CoARU_ModOn("ascui") then return end
    for _, name in ipairs(ROOTS) do
        local f = _G[name]
        if f and f.IsShown and f:IsShown() then retext(f, 0) end
    end
    for _, name in ipairs(PANELS) do
        local f = _G[name]
        if f and f.IsShown and f:IsShown() then retext(f, 0) end
    end
    for _, name in ipairs(POOL) do
        local f = _G[name]
        if f and f.IsShown and f:IsShown() then retext(f, 0) end
    end
end

function CoARU_TradeSkillRetext()
    if not CoARU_ModOn("ascui") then return end
    local f = _G.TradeSkillFrame
    if not f or not f.IsShown or not f:IsShown() then return end
    tradeMode = true
    retext(f, 0)
    for i = 1, 2 do
        local d = _G["DropDownList" .. i]
        if d and d.IsShown and d:IsShown() then retext(d, 0) end
    end
    tradeMode = false
end

for _, fn in ipairs({ "TradeSkillFrame_Update", "TradeSkillFrame_SetSelection",
                      "TradeSkillFrame_Show", "UIDropDownMenu_Refresh", "ToggleDropDownMenu" }) do
    if type(_G[fn]) == "function" then
        pcall(hooksecurefunc, fn, CoARU_TradeSkillRetext)
    end
end

local function popupOne(dialog)
    if not dialog or not dialog.GetName then return end
    local ok, name = pcall(dialog.GetName, dialog)
    if not ok or type(name) ~= "string" then return end
    local fs = _G[name .. "Text"]
    if not fs or not fs.GetText then return end
    local ok2, t = pcall(fs.GetText, fs)
    if not ok2 or type(t) ~= "string" or not t:find("%S") then return end

    if not looksEnglish(t) then return end

    local ru = lookup(t)
    if not ru or ru == t then
        noteMiss(t)
        if CoARU_DB then
            CoARU_DB.uimissrc = CoARU_DB.uimissrc or {}
            CoARU_DB.uimissrc[t] = name
        end
        return
    end

    if not CoARU_SetTranslated then return end
    CoARU_SetTranslated(fs, t, ru)

    if dialog.which and type(_G.StaticPopup_Resize) == "function" then
        pcall(_G.StaticPopup_Resize, dialog, dialog.which)
    end
end

function CoARU_StaticPopupRetext()
    if not CoARU_ModOn("ascui") then return end

    local n = _G.STATICPOPUP_NUMDIALOGS or 4
    for i = 1, n do
        local d = _G["StaticPopup" .. i]
        if d and d.IsShown and d:IsShown() then popupOne(d) end
    end
end

for _, fn in ipairs({ "StaticPopup_Show", "StaticPopup_UpdateText", "StaticPopup_OnShow" }) do
    if type(_G[fn]) == "function" then
        pcall(hooksecurefunc, fn, CoARU_StaticPopupRetext)
    end
end

local REC_TICK, REC_REWALK, REC_BUDGET, REC_DEPTH = 0.5, 3, 6, 8
local recDone, recShown, recAcc, recRe = {}, {}, 0, 0

local REC_SKIP = {
    ChatFrame1 = true, ChatFrame2 = true, ChatFrame3 = true, ChatFrame4 = true,
    ChatFrame5 = true, ChatFrame6 = true, ChatFrame7 = true, ChatFrame8 = true,
    ChatFrame9 = true, ChatFrame10 = true,
    CombatLogQuickButtonFrame_Custom = true, WorldFrame = true,
}

local function recNote(t, owner)
    if type(t) ~= "string" or t == "" or not t:find("%S") then return end

    if recDone[t] then return end
    recDone[t] = true
    if not looksEnglish(t) then return end

    if lookup(t) then return end
    if (t:find("<[^>]->") or t:find("{[^}]-}")) and translateHtml(t) then return end
    if CoARU_TUT_CHUNK then
        local body = chunkKey(t)
        if body ~= "" and tutChunk(body) then return end
    end

    if owner == "GameTooltip" or owner == "ItemRefTooltip"
       or owner == "GameTooltipTextLeft" or owner == "ShoppingTooltip1"
       or owner == "ShoppingTooltip2" then
        return
    end
    noteMiss(t)
    CoARU_DB.uimissrc = CoARU_DB.uimissrc or {}
    CoARU_DB.uimissrc[t] = owner
end

local recWalk

local function recRegions(owner, ...)
    for i = 1, select("#", ...) do
        local r = select(i, ...)
        if r and r.GetObjectType and r:GetObjectType() == "FontString" then
            local o, t = pcall(r.GetText, r)
            if o then recNote(t, owner) end
        end
    end
end

local function recRegionsOf(f, owner)
    return recRegions(owner, f:GetRegions())
end

local function recKids(depth, owner, t0, ...)
    for i = 1, select("#", ...) do
        local c = select(i, ...)
        local shownOk, shown = pcall(isShown, c)
        if shownOk and shown == false then

        else
            local o, kind = pcall(objType, c)
            if o and kind == "SimpleHTML" then
                local o2, t = pcall(c.GetText, c)
                if o2 then recNote(t, owner) end
            end
            recWalk(c, depth + 1, owner, t0)
        end
    end
end

local function recKidsOf(f, depth, owner, t0)
    return recKids(depth, owner, t0, f:GetChildren())
end

recWalk = function(f, depth, owner, t0)
    if not f or depth > REC_DEPTH then return end
    local dt = debugprofilestop() - t0
    if dt < 0 or dt > REC_BUDGET then return end
    if f.GetRegions then pcall(recRegionsOf, f, owner) end
    if f.GetChildren then pcall(recKidsOf, f, depth, owner, t0) end
end

function CoARU_AscUI_Record(frame, owner)
    recWalk(frame, 0, owner or "(стенд)", debugprofilestop())
end

local recFrame = CreateFrame("Frame")
recFrame:SetScript("OnUpdate", function(_, elapsed)
    if not CoARU_DB or not CoARU_DB.uirec then return end
    recAcc = recAcc + (elapsed or 0)
    if recAcc < REC_TICK then return end
    recRe = recRe + recAcc
    recAcc = 0
    local rewalk = recRe >= REC_REWALK
    if rewalk then recRe = 0 end
    local ok, kids = pcall(function() return { UIParent:GetChildren() } end)
    if not ok then return end
    for _, f in ipairs(kids) do
        local o, shown = pcall(function() return f.IsShown and f:IsShown() end)
        if o then
            local name = (f.GetName and f:GetName()) or nil
            local key = name or tostring(f)
            if name and REC_SKIP[name] then shown = false end
            if shown and (not recShown[key] or rewalk) then
                recShown[key] = true
                recWalk(f, 0, name or "(без имени)", debugprofilestop())
            elseif not shown then
                recShown[key] = nil
            end
        end
    end
end)

local scrollHooked = {}
local function hookChallengeScroll(f, depth)
    if not f or (depth or 0) > 5 then return end
    if type(f.RefreshScrollFrame) == "function" and not scrollHooked[f] then
        scrollHooked[f] = true
        pcall(hooksecurefunc, f, "RefreshScrollFrame", function()
            if CoARU_ModOn("ascui") then retext(_G.ChallengesFrame, 0) end
        end)
    end
    if f.GetChildren then
        local ok, cnt = pcall(function() return select("#", f:GetChildren()) end)
        if ok then
            for i = 1, cnt do hookChallengeScroll(select(i, f:GetChildren()), (depth or 0) + 1) end
        end
    end
end

local hooked = {}
local function tryHook()
    for _, name in ipairs(ROOTS) do
        local f = _G[name]
        if f and not hooked[name] and f.HookScript then
            hooked[name] = true

            local trade = (name == "TradeSkillFrame")
            local isChallenges = (name == "ChallengesFrame")
            f:HookScript("OnShow", function(self)
                if not CoARU_ModOn("ascui") then return end
                if trade then CoARU_TradeSkillRetext() else retext(self, 0) end

                if isChallenges then hookChallengeScroll(self, 0) end
            end)
            local acc = 0
            f:HookScript("OnUpdate", function(self, elapsed)
                acc = acc + (elapsed or 0)
                if acc >= TICK then
                    acc = 0
                    if CoARU_ModOn("ascui") then
                        if trade then CoARU_TradeSkillRetext() else retext(self, 0) end

                        for i = 1, #POOL do
                            local p = _G[POOL[i]]
                            if p and p.IsShown and p:IsShown() then retext(p, 0) end
                        end

                        local tip = _G.GameTooltip
                        if tip and tip.IsShown and tip:IsShown() then retext(tip, 0) end
                    end
                end
            end)
            if f:IsShown() then
                if trade then CoARU_TradeSkillRetext() else retext(f, 0) end
            end
        end
    end

    for _, name in ipairs(PANELS) do
        local f = _G[name]
        if f and not hooked[name] and f.HookScript then
            hooked[name] = true
            f:HookScript("OnShow", function(self)
                if CoARU_ModOn("ascui") then retext(self, 0) end
            end)
            local acc = 0
            f:HookScript("OnUpdate", function(self, elapsed)
                acc = acc + (elapsed or 0)
                if acc >= TICK then
                    acc = 0
                    if CoARU_ModOn("ascui") then retext(self, 0) end
                end
            end)
            if f:IsShown() then retext(f, 0) end
        end
    end
end

local waiter = CreateFrame("Frame")
local acc = 0
waiter:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + (elapsed or 0)
    if acc < 1 then return end
    acc = 0
    tryHook()

    local all = true
    for _, name in ipairs(ROOTS) do if not hooked[name] then all = false end end
    for _, name in ipairs(PANELS) do if not hooked[name] then all = false end end
    if all then waiter:SetScript("OnUpdate", nil) end
end)
