local PREFIX = "|cffC495DDCoARU|r: "
local function msg(text) print(PREFIX .. text) end

CoARU_DB = CoARU_DB or {}

local DONATE_URL = "https://www.donationalerts.com/r/locativeasc"

local DONATE_LINK = "|cffffd100|Hcoaru:donate|h[/coaru donate]|h|r"

local donateFrame
local function ensureDonateFrame()
    if donateFrame then return donateFrame end
    local f = CreateFrame("Frame", "CoARUDonateFrame", UIParent)
    f:SetFrameStrata("DIALOG")
    f:SetWidth(470)
    f:SetHeight(185)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    title:SetText("|cffC495DDCoARU|r")

    local desc = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOP", 0, -46)
    desc:SetWidth(420)
    desc:SetJustifyH("CENTER")
    desc:SetText("Спасибо, что пользуешься аддоном! Ссылка уже выделена — нажми Ctrl+C и открой в браузере:")

    local eb = CreateFrame("EditBox", "CoARUDonateEdit", f, "InputBoxTemplate")
    eb:SetWidth(400)
    eb:SetHeight(22)
    eb:SetPoint("TOP", 0, -108)
    eb:SetAutoFocus(false)
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    eb:SetScript("OnEnterPressed", function(self) self:HighlightText() end)

    local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn:SetWidth(120)
    btn:SetHeight(24)
    btn:SetPoint("BOTTOM", 0, 18)
    btn:SetText("Закрыть")
    btn:SetScript("OnClick", function() f:Hide() end)

    f:SetScript("OnShow", function()
        eb:SetText(DONATE_URL)
        eb:SetCursorPosition(0)
        eb:HighlightText()
        eb:SetFocus()
    end)

    tinsert(UISpecialFrames, "CoARUDonateFrame")
    f:Hide()
    donateFrame = f
    return f
end

local function showDonate()
    msg("поддержать автора: " .. DONATE_URL)
    ensureDonateFrame():Show()
end

local function purgeSent()
    local m = CoARU_DB.miss
    if type(m) ~= "table" then return 0 end
    local n = 0
    for norm, rec in pairs(m) do
        if type(rec) == "table" and rec.sent then
            m[norm] = nil
            n = n + 1
        end
    end
    return n
end

local function initDB()
    CoARU_DB.dump = CoARU_DB.dump or {}
    CoARU_DB.opts = CoARU_DB.opts or {}
    CoARU_DB.miss = CoARU_DB.miss or {}
    if CoARU_DB.opts.hover == nil then CoARU_DB.opts.hover = false end
    purgeSent()
end

local MISS_CAP = 3000

local FOREIGN_OWNERS = {
    "Bagnon", "AtlasLoot", "Details", "LibDBIcon", "ErrorHandler", "pfQuest", "Decursive",
    "Bartender", "BT4Button", "Skada", "Recount", "WeakAuras", "TitanPanel", "OmniCC",
    "XPerl", "Quartz", "DragonUI", "AceGUI", "Postal", "Auctionator", "Dominos", "ElvUI",
}

local QUEST_OWNERS = { "WorldMapFrame", "WatchFrame", "QuestLogScrollFrame" }

local function skipByOwner(owner, line)
    if type(owner) ~= "string" or owner == "" then return false end
    for _, frag in ipairs(FOREIGN_OWNERS) do
        if owner:find(frag, 1, true) then return true end
    end
    if line and line:sub(1, 2) == "- " then
        for _, frag in ipairs(QUEST_OWNERS) do
            if owner:find(frag, 1, true) then return true end
        end
    end
    return false
end

local function noteOneLine(kind, line, owner)
    if not line or not CoARU_DB or not CoARU_DB.miss then return end
    if skipByOwner(owner, line) then return end
    if CoARU_HasCyrillic(line) then return end
    local plain = CoARU_StripCodes(line)
    if not plain or not plain:find("%a") then return end
    local norm = CoARU_Norm(plain)
    if not norm or #norm < 4 then return end
    local m = CoARU_DB.miss
    local rec = m[norm]
    if rec then
        rec.n = (rec.n or 1) + 1
        return
    end
    local n = 0
    for _ in pairs(m) do n = n + 1 end
    if n >= MISS_CAP then return end

    m[norm] = { n = 1, k = kind, ex = plain, own = owner }
end

function CoARU_NoteMiss(kind, text, owner)
    if not text then return end
    if not text:find("\n") then
        noteOneLine(kind, text, owner)
        return
    end

    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        if line:find("%S") then noteOneLine(kind, line, owner) end
    end
end

function CoARU_NoteItemMiss(text)
    CoARU_NoteMiss("item", text)
end

function CoARU_NoteBlockMisses(kind, id, text)
    if not text then return end
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        if line:find("%S") and not CoARU_LineTranslated(id, line) then
            CoARU_NoteMiss(kind, line)
        end
    end
end

local function onTooltipSetSpell(tip)
    local ok, id = pcall(function() return select(3, tip:GetSpell()) end)
    if not ok or not id then return end
    id = tonumber(id)
    if not id then return end

    if CoARU_DB.opts.hover then
        local ok, why = CoARU_RecordSpell(id)
        if ok then
            msg("записал в дамп: " .. id)
        else
            msg("не записал " .. id .. ": " .. (why or "?"))
        end
    end

    local name = tip:GetName()
    if not name then return end

    CoARU_LastTip = { id = id }
    for i = 1, tip:NumLines() do
        for _, side in ipairs({ "TextLeft", "TextRight" }) do
            local fs = _G[name .. side .. i]
            local t = fs and fs:GetText()
            if t and t ~= " " then
                CoARU_LastTip[#CoARU_LastTip + 1] = side .. i .. " = [[" .. t:gsub("\n", "\\n") .. "]]"
            end
        end
    end

    local changed = false
    local function handle(fs)
        local t = fs and fs:GetText()

        if not (t and #t > 2 and t:find("%S")) then return end

        CoARU_NoteBlockMisses("spell", id, t)
        local ru = CoARU_TranslateBlock(id, t)
        if ru and ru ~= t then
            CoARU_SetTranslated(fs, t, ru)
            changed = true
        else
            local cleaned = CoARU_CleanMarkers(t, 0, id)
            if cleaned and cleaned ~= t then
                fs:SetText(cleaned)
                changed = true
            end
        end
    end
    for i = 2, tip:NumLines() do
        handle(_G[name .. "TextLeft" .. i])
        handle(_G[name .. "TextRight" .. i])
    end
    if changed then
        tip:Show()
    end
end

local DELTA_HEADER_EN = "If you replace this item"
local DELTA_HEADER_RU = "Если заменить этот предмет"

local function colorizeDelta(ru)

    local body = ru:match("^|[cC]%x%x%x%x%x%x%x%x(.*)$") or ru
    body = body:gsub("|r$", "")
    local sign, num, rest = body:match("^([%+%-])([%d%.,]+)(.*)$")
    if not sign then return ru end
    local hex = (sign == "+") and "ff1eff00" or "ffff2020"
    return "|c" .. hex .. sign .. num .. "|r|cffffffff" .. rest .. "|r"
end

local function clientRewritesLine(t)
    if not t then return false end
    local plain = CoARU_StripCodes(t)
    if not plain or plain == "" then return false end
    if plain:sub(1, 2) == '"@' then return true end
    local heroic = _G.ITEM_HEROIC
    if heroic and heroic ~= "" and plain:sub(1, #heroic) == heroic then
        return true
    end
    return false
end

local function onTooltipSetItem(tip)
    local name = tip:GetName()
    if not name or not tip.GetItem then return end
    local ok, itemName, link = pcall(tip.GetItem, tip)
    if not ok or not link then return end
    local id = tonumber(link:match("item:(%d+)"))
    if not id then return end

    local changed = false

    local ru = CoARU_ItemName and CoARU_ItemName[id]
    if ru and type(itemName) == "string" and itemName ~= "" then
        local last = math.min(tip:NumLines() or 1, 3)
        for i = 1, last do
            local fs = _G[name .. "TextLeft" .. i]
            local t = fs and fs:GetText()
            if t and not CoARU_HasCyrillic(t) and CoARU_StripCodes(t) == itemName then
                CoARU_SetTranslated(fs, t, ru)
                changed = true
                break
            end
        end
    end

    local desc = CoARU_ItemDesc and CoARU_ItemDesc[id]

    local inDelta = false
    for i = 2, tip:NumLines() do
        for _, side in ipairs({ "TextLeft", "TextRight" }) do
            local fs = _G[name .. side .. i]
            local t = fs and fs:GetText()
            if t and side == "TextLeft" and t:find("%S")
                and (t:find(DELTA_HEADER_EN, 1, true) or t:find(DELTA_HEADER_RU, 1, true)) then
                inDelta = true
            end
            if t and #t > 2 and t:find("%S") and not CoARU_HasCyrillic(t)
                and not clientRewritesLine(t) then

                if desc and side == "TextLeft" and t:match('^".*"$') then
                    CoARU_SetTranslated(fs, t, '"' .. desc .. '"')
                    changed = true
                else

                    if t ~= itemName then
                        CoARU_NoteBlockMisses("item", nil, t)
                    end
                    local r = CoARU_TranslateBlock(nil, t)

                    if not (r and r ~= t) and CoARU_TranslateItemPrefix then
                        r = CoARU_TranslateItemPrefix(t)
                    end
                    if r and r ~= t then
                        if inDelta then r = colorizeDelta(r) end
                        CoARU_SetTranslated(fs, t, r)
                        changed = true
                    else

                        if t ~= itemName then
                            CoARU_NoteItemMiss(t)
                        end
                    end
                end
            end
        end
    end

    for i = 1, 4 do
        local pf = _G[name .. "MoneyFrame" .. i .. "PrefixText"]
        local t = pf and pf:GetText()
        if t and t:find("%S") and not CoARU_HasCyrillic(t) then
            local r = CoARU_TranslateBlock(nil, t)
            if r and r ~= t then
                CoARU_SetTranslated(pf, t, r)
                changed = true
            else
                CoARU_NoteMiss("money", t)
            end
        end
    end

    if changed then tip:Show() end
end

local CoARU_SCHOOL_RU = {
    Arcane = "Тайная магия",
    Fire = "Огонь",
    Nature = "Природа",
    Frost = "Лёд",
    Shadow = "Тень",
    Holy = "Свет",
}

local CoARU_SCHOOL_DATIVE = {
    Arcane = "тайной магии",
    Fire = "огню",
    Nature = "природе",
    Frost = "льду",
    Shadow = "тьме",
    Holy = "свету",
}

local RESIST_ANCHOR = "based attacks, spells and abilities"

local SCHOOL_OWNER = "AscensionCharacterStatsPanel"

local inReprocess = false
local function onTooltipShow(tip)
    if inReprocess then return end
    local name = tip:GetName()
    if not name then return end

    local isResistTip = false
    for i = 1, tip:NumLines() do
        local fs = _G[name .. "TextLeft" .. i]
        local t = fs and fs:GetText()
        if t and t:find(RESIST_ANCHOR, 1, true) then
            isResistTip = true
            break
        end
    end

    local itemName
    if tip.GetItem then
        local ok, n = pcall(tip.GetItem, tip)
        if ok then itemName = n end
    end

    local ownerName
    if tip.GetOwner then
        local ok, of = pcall(tip.GetOwner, tip)
        if ok and of then
            ownerName = of.GetName and of:GetName()
            if not ownerName and of.GetParent then
                local p = of:GetParent()
                ownerName = p and p.GetName and p:GetName()
            end
        end
    end

    local isSchoolTip = isResistTip
        or (ownerName ~= nil and ownerName:find(SCHOOL_OWNER, 1, true) ~= nil)
    local changed = false
    local inDelta = false
    for i = 1, tip:NumLines() do
        for _, side in ipairs({ "TextLeft", "TextRight" }) do
            local fs = _G[name .. side .. i]
            local t = fs and fs:GetText()
            if t and t:find("%S") then

                if side == "TextLeft" and (t:find(DELTA_HEADER_EN, 1, true)
                    or t:find(DELTA_HEADER_RU, 1, true)) then
                    inDelta = true
                end

                local schoolRu
                if isSchoolTip then
                    local plain = CoARU_StripCodes(t):gsub("^%s+", ""):gsub("%s+$", "")
                    schoolRu = CoARU_SCHOOL_RU[plain]
                    if not schoolRu then
                        local sch, rest = plain:match("^(%a+) Resistance%s*(.*)$")
                        local dat = sch and CoARU_SCHOOL_DATIVE[sch]
                        if dat then
                            schoolRu = "Сопротивление " .. dat
                            if rest ~= "" then schoolRu = schoolRu .. " " .. rest end
                        end
                    end
                end
                if not CoARU_HasCyrillic(t) and schoolRu then
                    CoARU_SetTranslated(fs, t, schoolRu)
                    changed = true
                elseif #t > 2 and not CoARU_HasCyrillic(t) and not clientRewritesLine(t) then
                    local ru = CoARU_TranslateBlock(nil, t)

                    if not (ru and ru ~= t) and CoARU_TranslateItemPrefix then
                        ru = CoARU_TranslateItemPrefix(t)
                    end
                    if ru and ru ~= t then
                        if inDelta then ru = colorizeDelta(ru) end
                        CoARU_SetTranslated(fs, t, ru)
                        changed = true
                    elseif t ~= itemName and (i > 1 or isSchoolTip) then

                        CoARU_NoteMiss("tip", t, ownerName)
                    end
                end
            end
        end
    end
    if changed then
        inReprocess = true
        tip:Show()
        inReprocess = false
    end
end

local function translateAuraTip(tip, id)
    local name = tip and tip:GetName()
    if not name or not id then return end
    local changed = false

    for i = 2, tip:NumLines() do
        for _, side in ipairs({ "TextLeft", "TextRight" }) do
            local fs = _G[name .. side .. i]
            local t = fs and fs:GetText()
            if t and #t > 2 and t:find("%S") and not CoARU_HasCyrillic(t) then

                CoARU_NoteBlockMisses("aura", id, t)
                local ru = CoARU_TranslateBlock(id, t)
                if ru and ru ~= t then
                    CoARU_SetTranslated(fs, t, ru)
                    changed = true
                end
            end
        end
    end
    if changed then tip:Show() end
end

local function hookAura(tip)
    if not tip then return end
    if tip.SetUnitAura then
        hooksecurefunc(tip, "SetUnitAura", function(self, unit, index, filter)
            local ok, id = pcall(function() return select(11, UnitAura(unit, index, filter)) end)
            if ok then translateAuraTip(self, tonumber(id)) end
        end)
    end
    if tip.SetUnitBuff then
        hooksecurefunc(tip, "SetUnitBuff", function(self, unit, index, filter)
            local ok, id = pcall(function() return select(11, UnitBuff(unit, index, filter)) end)
            if ok then translateAuraTip(self, tonumber(id)) end
        end)
    end
    if tip.SetUnitDebuff then
        hooksecurefunc(tip, "SetUnitDebuff", function(self, unit, index, filter)
            local ok, id = pcall(function() return select(11, UnitDebuff(unit, index, filter)) end)
            if ok then translateAuraTip(self, tonumber(id)) end
        end)
    end
end

local function installHooks()

    if LinkUtil and LinkUtil.AddHandler and not LinkUtil:GetHandler("coaru", "onClick") then
        LinkUtil:AddHandler("coaru", function(link)
            if link:GetArg(1) == "donate" then showDonate() end
        end)
    end
    GameTooltip:HookScript("OnTooltipSetSpell", onTooltipSetSpell)
    hooksecurefunc(GameTooltip, "Show", onTooltipShow)
    hookAura(GameTooltip)
    hookAura(ItemRefTooltip)
    if ItemRefTooltip then
        ItemRefTooltip:HookScript("OnTooltipSetSpell", onTooltipSetSpell)
        hooksecurefunc(ItemRefTooltip, "Show", onTooltipShow)
    end

    if WorldMapTooltip then
        WorldMapTooltip:HookScript("OnTooltipSetSpell", onTooltipSetSpell)
        hooksecurefunc(WorldMapTooltip, "Show", onTooltipShow)
        hookAura(WorldMapTooltip)
    end

    for _, f in ipairs({ GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2,
                         WorldMapTooltip }) do
        if f and f.HookScript then
            f:HookScript("OnTooltipSetItem", onTooltipSetItem)
        end
    end

    for _, f in ipairs({ ShoppingTooltip1, ShoppingTooltip2 }) do
        if f then hooksecurefunc(f, "Show", onTooltipShow) end
    end
end

local function countDump()
    local c = 0
    for _ in pairs(CoARU_DB.dump or {}) do c = c + 1 end
    return c
end

local RELEASE = true

local PLAYER_CMDS = { [""] = true, status = true, donate = true, support = true,
                      ["спасибо"] = true, ["донат"] = true }

local function isOriginalCmd(cmd)
    return cmd:match("^original") or cmd:match("^оригинал") or cmd:match("^англ")
end

local function slash(cmd)
    cmd = (cmd or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
    if RELEASE and not PLAYER_CMDS[cmd] and not isOriginalCmd(cmd) then
        msg("доступна команда /coaru status — она показывает, что собрал аддон.")
        return
    end
    if cmd == "" then
        local t = 0
        for _ in pairs(CoARU_T or {}) do t = t + 1 end
        msg(("русификатор описаний Conquest of Azeroth. Переводит спеллы автоматически. Переводов в базе: %d."):format(t))

        local key = CoARU_OriginalMod and CoARU_OriginalMod() or "ALT"
        key = key:sub(1, 1) .. key:sub(2):lower()
        print(("  |cffffd100%s|r над тултипом — показать оригинал на английском (сменить клавишу: /coaru original ctrl)"):format(key))
        print("  поддержать автора: " .. DONATE_LINK)
        return
    end
    if cmd == "donate" or cmd == "support" or cmd == "спасибо" or cmd == "донат" then
        showDonate()
        return
    end

    if isOriginalCmd(cmd) then
        local arg = cmd:match("%s+(%a+)$")
        if arg then
            local set = CoARU_SetOriginalMod and CoARU_SetOriginalMod(arg)
            if not set then
                msg("не знаю такую клавишу. Доступны: alt, ctrl, shift, off.")
                return
            end
            msg(set == "NONE"
                and "показ оригинала по клавише |cffff0000выключен|r."
                or ("оригинал показывается, пока зажат |cffffd100%s|r."):format(
                    set:sub(1, 1) .. set:sub(2):lower()))
            return
        end
        local sticky = CoARU_ToggleOriginalSticky and CoARU_ToggleOriginalSticky()
        local key = CoARU_OriginalMod and CoARU_OriginalMod() or "ALT"
        key = key:sub(1, 1) .. key:sub(2):lower()
        if sticky then
            msg(("постоянный английский: |cff00ff00ВКЛ|r. Зажми |cffffd100%s|r, чтобы увидеть русский."):format(key))
        else
            msg(("постоянный английский: |cffff0000ВЫКЛ|r. Зажми |cffffd100%s|r над тултипом, чтобы увидеть оригинал."):format(key))
        end
        return
    end
    if cmd == "book" then
        CoARU_ScanBook(false)
    elseif cmd == "book all" then
        CoARU_ScanBook(true)
    elseif cmd:match("^scanall") then

        local ms, minId, maxId = nil, nil, nil
        local a, b = cmd:match("(%d+)%s*%-%s*(%d+)")
        if a then
            minId, maxId = tonumber(a), tonumber(b)

            local rest = cmd:gsub("%d+%s*%-%s*%d+", " ")
            for d in rest:gmatch("%d+") do
                d = tonumber(d)
                if d <= 1000 and not ms then ms = d end
            end
        else

            for d in cmd:gmatch("%d+") do
                d = tonumber(d)
                if d > 1000 then
                    if not minId then minId = d elseif not maxId then maxId = d end
                elseif not ms then
                    ms = d
                end
            end
        end
        local fast = cmd:match("%f[%a]fast") ~= nil

        if fast then ms = math.min(math.max(ms or 100, 1), 1000) else ms = nil end
        CoARU_StartScanRanges(CoARU_ScanRanges or {}, cmd:match("%f[%a]all%f[%A]") ~= nil, ms, minId, maxId)
    elseif cmd == "hover" then
        CoARU_DB.opts.hover = not CoARU_DB.opts.hover
        msg("режим записи при наведении: " .. (CoARU_DB.opts.hover and "|cff00ff00ВКЛ|r — наводи мышь на спеллы, непереведённые попадут в дамп" or "|cffff0000ВЫКЛ|r"))
    elseif cmd == "probe" then
        CoARU_Probe()
    elseif cmd == "classes" then
        CoARU_ProbeClasses()
    elseif cmd == "status" then

        if RELEASE then
            local mn = 0
            for _ in pairs(CoARU_DB.miss or {}) do mn = mn + 1 end
            if mn == 0 then
                msg("непереведённых строк пока не встретилось.")
                return
            end

            for _, rec in pairs(CoARU_DB.miss) do
                if type(rec) == "table" then rec.sent = true end
            end

            msg(("непереведённых строк собрано: |cffffd100%d|r"):format(mn))
            print("  |cffffd1001.|r сделай |cffffd100/reload|r")
            print("  |cffffd1002.|r найди файл: |cff00ff00WTF\\Account\\<аккаунт>"
                  .. "\\SavedVariables\\CoARU.lua|r")
            print("  |cffffd1003.|r пришли его в Discord: |cffC495DDlocativeds|r")
            print("  |cff888888Список уже помечен и очистится при следующем входе в игру.|r")
            print("  |cff888888В следующий раз пришлёшь только новое.|r")
            return
        end
        local t, iname, idesc = 0, 0, 0
        for _ in pairs(CoARU_T or {}) do t = t + 1 end
        for _ in pairs(CoARU_ItemName or {}) do iname = iname + 1 end
        for _ in pairs(CoARU_ItemDesc or {}) do idesc = idesc + 1 end
        msg(("переводов в базе: %d, спеллов в дампе: %d, hover: %s"):format(t, countDump(), CoARU_DB.opts.hover and "вкл" or "выкл"))
        msg(("предметы: имён %d, описаний %d"):format(iname, idesc))

        msg(("строк тултипа предмета: %d (пропущено %d)"):format(
            CoARU_ItemTipAdded or 0, CoARU_ItemTipSkipped or 0))

        if CoARU_PaperDollStatus then
            local n, where, fs = CoARU_PaperDollStatus()
            msg(("текст окон: строк %d, FontString в кэше %d | %s"):format(n, fs or 0, where))
        end

        if CoARU_OriginalStatus then
            local n, key, sticky = CoARU_OriginalStatus()
            msg(("оригинал: клавиша %s, постоянный английский %s, строк в кэше %d"):format(
                key, sticky and "вкл" or "выкл", n))
        else
            msg("|cffff0000CoARU_Original.lua не загружен|r — нужен полный перезапуск игры, не /reload.")
        end

        local mn, byKind = 0, {}
        for _, r in pairs(CoARU_DB.miss or {}) do
            mn = mn + 1
            local k = r.k or "?"
            byKind[k] = (byKind[k] or 0) + 1
        end
        local parts = {}
        for k, v in pairs(byKind) do parts[#parts + 1] = k .. " " .. v end
        msg(("|cffffd100непереведённых строк собрано: %d|r%s"):format(
            mn, #parts > 0 and (" (" .. table.concat(parts, ", ") .. ")") or ""))
        if mn > 0 then
            print("  это уникальные НОРМЫ живого текста. /reload и пришли SavedVariables — переведём волной.")
        end
    elseif cmd == "clear" then

        CoARU_DB.dump = {}
        CoARU_DB.classids = nil
        CoARU_DB.probe = nil
        CoARU_DB.castrings = nil
        CoARU_DB.specinfo = nil
        CoARU_DB.catext = nil
        CoARU_DB.trainerdump = nil
        CoARU_DB.geom = nil
        CoARU_DB.frames = nil
        CoARU_DB.miss = {}
        msg("дамп очищен (включая собранные дыры).")
    elseif cmd == "trainerdump" then

        if not (ClassTrainerFrame and ClassTrainerFrame:IsShown()) then
            msg("окно тренера закрыто — открой его и повтори.")
        else
            CoARU_DB.trainerdump = CoARU_DumpTrainer()
            local n, empty, h = 0, 0, 0
            for _, e in ipairs(CoARU_DB.trainerdump) do
                n = n + 1
                if e.empty then empty = empty + 1 end
                h = h + (e.h or 0)
            end
            msg(("FontString'ов: %d, из них пустых: %d, суммарная высота: %.1f")
                :format(n, empty, h))
            msg("подробности в SavedVariables (CoARU_DB.trainerdump) — /reload и пришли файл.")
        end
    elseif cmd == "lines" then

        if not CoARU_LastTip then
            msg("ещё не было ни одного спелл-тултипа.")
        else
            msg("последний тултип, id=" .. tostring(CoARU_LastTip.id) .. ":")
            for _, line in ipairs(CoARU_LastTip) do print("  " .. line) end
        end
    elseif cmd == "frames" then

        if CoARU_PaperDollFrames then
            CoARU_PaperDollFrames()
        else
            msg("окна не подключены (нужен полный перезапуск игры, не /reload)")
        end
    elseif cmd == "geom" then

        if CoARU_PaperDollGeom then
            CoARU_PaperDollGeom()
        else
            msg("окна не подключены (нужен полный перезапуск игры, не /reload)")
        end
    elseif cmd == "fit" then

        if CoARU_PaperDollFit then
            CoARU_PaperDollFit()
        else
            msg("окно персонажа не подключено (нужен полный перезапуск игры, не /reload)")
        end
    elseif cmd == "cafit" then

        if CoARU_CA_Fit then
            CoARU_CA_Fit()
        else
            msg("CoARU_CA.lua не загружен — проверь .toc.")
        end
    elseif cmd == "ca" then

        CoARU_DB = CoARU_DB or {}
        local dump, seen, n = {}, {}, 0
        local fr = EnumerateFrames()
        while fr do
            local shown = fr.IsShown and fr:IsShown()
            if shown and fr.GetRegions then
                local ok, regions = pcall(function() return { fr:GetRegions() } end)
                if ok then
                    for _, r in ipairs(regions) do
                        if r and r.GetObjectType and r:GetObjectType() == "FontString" then
                            local t = r:GetText()
                            if t and #t >= 2 and t:find("%S") and not CoARU_HasCyrillic(t) then
                                if not seen[t] then
                                    seen[t] = true
                                    n = n + 1
                                    dump[n] = {
                                        text = t,
                                        region = (r.GetName and r:GetName()) or "?",
                                        frame = (fr.GetName and fr:GetName()) or "?",
                                    }
                                end
                            end
                        end
                    end
                end
            end
            fr = EnumerateFrames(fr)
        end
        CoARU_DB.castrings = dump
        print("CoARU: снято " .. n .. " англ. строк экрана. Сделай /reload и пришли WTF\\...\\SavedVariables\\CoARU.lua")
    elseif cmd == "arch" or cmd == "specs" then

        CoARU_DB = CoARU_DB or {}
        local order = CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER
        local gsi = C_ClassInfo and C_ClassInfo.GetSpecInfo
        if not (order and gsi) then
            msg("CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER / C_ClassInfo.GetSpecInfo недоступны. Напиши.")
        else
            local out, nc, ns = {}, 0, 0
            for classFile, specs in pairs(order) do
                nc = nc + 1
                if type(specs) == "table" then
                    for _, spec in ipairs(specs) do
                        local ok, info = pcall(gsi, classFile, spec)
                        if ok and type(info) == "table" then
                            local flat = {}
                            for k, v in pairs(info) do
                                local tv = type(v)
                                if tv == "string" or tv == "number" or tv == "boolean" then
                                    flat[tostring(k)] = v
                                end
                            end
                            ns = ns + 1
                            out[#out + 1] = { class = tostring(classFile), spec = tostring(spec), info = flat }
                        end
                    end
                end
            end
            CoARU_DB.specinfo = out
            print("CoARU: снято классов " .. nc .. ", спеков " .. ns ..
                ". /reload и пришли SavedVariables\\CoARU.lua")
        end
    elseif cmd:match("^id%s+%d+$") then
        local id = tonumber(cmd:match("%d+"))
        local n, r, x = CoARU_CaptureSpell(id)
        if n then
            msg(("[%d] %s (%s)"):format(id, n, r or "-"))
            print(x)
        else
            msg("спелл " .. id .. " не найден.")
        end
    elseif cmd:match("^item%s+%d+$") then

        local id = tonumber(cmd:match("%d+"))
        local function report(tag)
            local n, x, st = CoARU_CaptureItem(id)
            local ii = GetItemInfo and GetItemInfo(id)
            if st == "ok" then
                msg(("[%d] %s — |cff00ff00РЕЗОЛВИТСЯ|r (%s), GetItemInfo: %s"):format(
                    id, n, tag, ii or "nil"))
                if x then print(x) end
            elseif st == "pending" then
                msg(("[%d] нет в кэше, клиент запросил у сервера (%s)..."):format(id, tag))
            else
                msg(("[%d] |cffff0000тултип пуст|r (%s) — такого предмета у сервера нет"):format(id, tag))
            end
            return st
        end
        if report("сразу") == "pending" then
            local f = CreateFrame("Frame")
            local t = 0
            f:SetScript("OnUpdate", function(self, elapsed)
                t = t + elapsed
                if t < 1.5 then return end
                self:SetScript("OnUpdate", nil)
                report("повтор через 1.5 сек")
            end)
        end
    elseif cmd == "dev" or cmd == "help" then
        msg("команды разработчика (сбор данных для перевода):")
        print("  /coaru book — сканировать книгу заклинаний, собрать непереведённое")
        print("  /coaru book all — то же, включая уже переведённые")
        print("  /coaru scanall — сплошной скан ID по диапазонам, ловит таланты ВСЕХ классов (можно играть)")
        print("  /coaru scanall fast [мс] <A-B> — окно ID через дефис, напр. |cffffd100/coaru scanall fast 100 1-60000|r")
        print("      (дефис — надёжный синтаксис: нижняя граница < 1000 иначе неотличима от мс)")
        print("      без пауз, играть нельзя. Память: дамп >120k записей вешает клиент — сканируй КУСКАМИ.")
        print("  /coaru hover — вкл/выкл запись спеллов при наведении мыши")
        print("  /coaru probe — диагностика API клиента")
        print("  /coaru classes — снять все записи Character Advancement (список игрового контента + флаги мусора)")
        print("  /coaru status — счётчики базы и дампа")
        print("  /coaru clear — очистить дамп")
        print("  /coaru lines — сырые строки последнего тултипа")
        print("  /coaru ca — снять англ. текст экрана Character Advancement (открой экран спеков, потом команду)")
        print("  /coaru arch — снять описания ВСЕХ спеков всех классов через API (с одного перса, без прокачки)")
        print("  /coaru fit — какие строки окна персонажа не влезают в своё поле (открой C)")
        print("  /coaru geom — координаты кнопок в пикселях (открой журнал L)")
        print("  /coaru frames — имена ОТКРЫТЫХ окон (открой нужные окна и повтори)")
        print("  /coaru cafit — проверить вёрстку русских описаний спеков (все 70, альты не нужны)")
        print("  /coaru id <spellId> — показать, что видит сканер")
        print("  /coaru item <itemId> — резолвится ли тултип предмета по ID (проверка перед волной предметов)")
        print("  после сканирования: /reload, затем отдать WTF\\...\\SavedVariables\\CoARU.lua переводчику")
    else
        msg("русификатор работает автоматически. Команды разработчика: /coaru dev")
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "CoARU" then
        initDB()
        SLASH_COARU1 = "/coaru"
        SlashCmdList["COARU"] = slash
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        installHooks()
        local t = 0
        for _ in pairs(CoARU_T or {}) do t = t + 1 end
        local ver = (GetAddOnMetadata and GetAddOnMetadata("CoARU", "Version")) or ""
        local author = (GetAddOnMetadata and GetAddOnMetadata("CoARU", "Author")) or "Locative"
        print(("|cffC495DDCoARU|r%s |cffaaaaaa—|r русификатор описаний CoA. Автор: |cffC495DD%s|r. Переводов: |cffffd100%d|r."):format(
            ver ~= "" and (" |cff888888v" .. ver .. "|r") or "", author, t))
        print("|cffC495DDCoARU|r|cffaaaaaa:|r нравится аддон? Поддержать автора: " .. DONATE_LINK)
    end
end)
