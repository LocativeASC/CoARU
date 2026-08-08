local INFO_FS = {
    "QuestInfoTitleHeader",
    "QuestInfoDescriptionHeader",
    "QuestInfoDescriptionText",
    "QuestInfoObjectivesHeader",
    "QuestInfoObjectivesText",
    "QuestInfoRewardsHeader",
    "QuestInfoRewardText",
    "QuestInfoItemChooseText",
    "QuestInfoItemReceiveText",
    "QuestInfoGroupSize",
}
local PROGRESS_FS = { "QuestProgressTitleText", "QuestProgressText" }
local GREETING_FS = { "GreetingText" }

local UI = {
    ["Description"] = "Описание",
    ["Quest Objectives"] = "Цели задания",
    ["Objectives"] = "Цели",
    ["Rewards"] = "Награда",
    ["Rewards:"] = "Награда:",
    ["Reward"] = "Награда",
    ["Choose your reward:"] = "Выберите награду:",
    ["You will be able to choose one of these rewards:"] = "Вы сможете выбрать одну из этих наград:",
    ["You will also receive:"] = "Вы также получите:",
    ["You will receive:"] = "Вы получите:",
    ["Quest Completed"] = "Задание выполнено",
    ["(Complete)"] = "(Выполнено)",
    ["Complete"] = "Выполнено",

    ["Dungeon"] = "Подземелье",
    ["(Dungeon)"] = "(Подземелье)",
    ["Elite"] = "Высокий уровень",
    ["(Elite)"] = "(Высокий уровень)",
    ["Raid"] = "Рейд",
    ["(Raid)"] = "(Рейд)",
    ["Group"] = "Группа",
    ["(Group)"] = "(Группа)",
    ["Heroic"] = "Героический",
    ["(Heroic)"] = "(Героический)",
    ["Daily"] = "Ежедневное",
    ["(Daily)"] = "(Ежедневное)",
    ["Raid (10)"] = "Рейд (10)",
    ["Raid (25)"] = "Рейд (25)",
    ["Legendary"] = "Легендарное",
    ["(Legendary)"] = "(Легендарное)",

    ["Ascension Main Quest"] = "Основная линия Ascension",
    ["Ascension Main Quests"] = "Основная линия Ascension",
    ["Call Board"] = "Доска вызовов",
    ["Callboard"] = "Доска вызовов",

    ["Quest Details"] = "Задание",
    ["Show Map"] = "Показать карту",
    ["Experience"] = "Опыт",
    ["Experience:"] = "Опыт:",
    ["Money"] = "Деньги",
    ["Abandon"] = "Отменить",
    ["Share"] = "Поделиться",
    ["Track"] = "Отслеживать",
    ["Untrack"] = "Не отслеживать",
}

local translated = 0

local function hasEnglishTail(t)
    return t:find("%(Complete%)%s*$") ~= nil
end

local PATTERNS = {
    { "^Suggested Players %[(%d+)%]$", "Рекомендуется игроков [%1]" },
    { "^Suggested Players: (%d+)$",    "Рекомендуется игроков: %1" },

    { "^Objectives %((%d+)%)$",        "Задания (%1)" },
    { "^Objectives%s*%((%d+)/(%d+)%)$", "Задания (%1/%2)" },

    { "^#(%d+) (%S+) Rating: (%d+) | Wins: (%d+) | Losses: (%d+) | Win Rate: (%d+)%%$",
      "№%1 %2 Рейтинг: %3 | Победы: %4 | Поражения: %5 | Процент побед: %6%%" },

    { "^Top (%d+) %- (%d+)v(%d+) Arena Champions$", "Топ-%1 чемпионов арены %2х%3" },
    { "^Spectate (%d+)v(%d+) Arena$",               "Смотреть арену %1х%2" },
}

local function byPattern(t)
    for i = 1, #PATTERNS do
        local got = t:gsub(PATTERNS[i][1], PATTERNS[i][2])
        if got ~= t then return got end
    end
    return nil
end

local ITEM_OBJ = {
    "^(%s*%-?%s*)(.-)(%s+[xX]%s*)(%d+)%s*$",
    "^(%s*%-?%s*)(.-)(:%s*)(%d+%s*/%s*%d+)%s*$",
}

local OBJ_VERBS = {
    { "^(.-)%s+[Ss]lain$",        "убито" },
    { "^(.-)%s+Put to Rest$",     "упокоено" },
    { "^(.-)%s+[Dd]efeated$",     "побеждено" },
}

local function objNameRU(name)
    local ru = CoARU_ItemNameEN and CoARU_ItemNameEN[name]
    if not ru then ru = CoARU_UNIT_N2R and CoARU_UNIT_N2R[name] end
    if ru and ru ~= name then return ru end
    return nil
end

local function objectiveItemRU(t)
    if not CoARU_ItemNameEN and not CoARU_UNIT_N2R then return nil end
    for i = 1, #ITEM_OBJ do
        local head, body, sep, cnt = t:match(ITEM_OBJ[i])
        if body and body ~= "" then
            local ru = objNameRU(body)
            if ru then return head .. ru .. sep .. cnt end

            for k = 1, #OBJ_VERBS do
                local name = body:match(OBJ_VERBS[k][1])
                if name and name ~= "" then
                    return head .. (objNameRU(name) or name) .. " " .. OBJ_VERBS[k][2]
                        .. sep .. cnt
                end
            end

            local qru = CoARU_QuestLookup and CoARU_QuestLookup(body)
            if qru and qru ~= body then return head .. qru .. sep .. cnt end
        end
    end
    return nil
end

CoARU_TranslateObjectiveLine = objectiveItemRU

local lookupCache, lookupN = {}, 0

local function qlookupUncached(t)
    local ru = CoARU_QuestLookup and CoARU_QuestLookup(t)
    if ru then return ru end
    local core = t:match("^(.-)%s*%(Complete%)$")
    if core then
        local r = CoARU_QuestLookup and CoARU_QuestLookup(core)
        if r then return r .. " (Выполнено)" end
    end

    if core and CoARU_HasCyrillic and CoARU_HasCyrillic(core) then
        return core .. " (Выполнено)"
    end
    local base, cnt = t:match("^(.-)(:%s*%d+%s*/%s*%d+)$")
    if base then
        local r = CoARU_QuestLookup and CoARU_QuestLookup(base)
        if r then return r .. cnt end
    end
    return nil
end

local function qlookup(t)
    local hit = lookupCache[t]
    if hit ~= nil then
        return hit or nil
    end
    local ru = qlookupUncached(t)

    if lookupN > 4000 then
        lookupCache, lookupN = {}, 0
    end
    lookupCache[t] = ru or false
    lookupN = lookupN + 1
    return ru
end

local RACE_RU = {
    ["Human"] = "человек", ["Dwarf"] = "дворф", ["Night Elf"] = "ночной эльф",
    ["Gnome"] = "гном", ["Draenei"] = "дреней", ["Worgen"] = "ворген",
    ["Orc"] = "орк", ["Undead"] = "нежить", ["Scourge"] = "нежить",
    ["Tauren"] = "таурен", ["Troll"] = "тролль", ["Blood Elf"] = "эльф крови",
    ["Goblin"] = "гоблин", ["Pandaren"] = "пандарен",
}

local CLASS_RU_ONE = {
    ["Warrior"] = "воин", ["Paladin"] = "паладин", ["Hunter"] = "охотник",
    ["Rogue"] = "разбойник", ["Priest"] = "жрец", ["Shaman"] = "шаман",
    ["Mage"] = "маг", ["Warlock"] = "чернокнижник", ["Druid"] = "друид",
    ["Death Knight"] = "рыцарь смерти",
}

local function capFirst(s)
    local b1, b2 = s:byte(1, 2)
    if b1 == 208 and b2 and b2 >= 176 and b2 <= 191 then
        return string.char(208, b2 - 32) .. s:sub(3)
    elseif b1 == 209 and b2 and b2 >= 128 and b2 <= 143 then
        return string.char(208, b2 + 32) .. s:sub(3)
    end
    return s
end
local function lowFirst(s)
    local b1, b2 = s:byte(1, 2)
    if b1 == 208 and b2 and b2 >= 144 and b2 <= 159 then
        return string.char(208, b2 + 32) .. s:sub(3)
    elseif b1 == 208 and b2 and b2 >= 160 and b2 <= 175 then
        return string.char(209, b2 - 32) .. s:sub(3)
    end
    return s
end

local function expand(ru)
    ru = ru:gsub("%$[Bb]", "\n")
    local sex = UnitSex and UnitSex("player")

    ru = ru:gsub("%$[Gg]([^:;]*):([^:;]*):[^;]*;", sex == 3 and "%2" or "%1")
    ru = ru:gsub("%$[Gg]([^:]*):([^;]*);", sex == 3 and "%2" or "%1")

    ru = ru:gsub("|3%-%d+%((.-)%)", function(inner) return inner end)
    local pname = UnitName and UnitName("player")
    if pname then
        ru = ru:gsub("<name>", pname):gsub("%$[Nn]", pname)
    end

    local cls = UnitClass and UnitClass("player")
    if cls then

        local one = CLASS_RU_ONE[cls]
        if CoARU_IsClassName and CoARU_IsClassName(cls) then one = nil end
        local low = one and lowFirst(one) or cls
        local up = one and capFirst(lowFirst(one)) or cls
        ru = ru:gsub("<class>", function() return low end)
        ru = ru:gsub("%$c", function() return low end)
        ru = ru:gsub("%$C", function() return up end)
    end
    local rc = UnitRace and UnitRace("player")
    if rc then
        local one = RACE_RU[rc]
        local low = one or rc
        local up = one and capFirst(one) or rc
        ru = ru:gsub("<race>", function() return low end)
        ru = ru:gsub("%$r", function() return low end)
        ru = ru:gsub("%$R", function() return up end)
    end

    if CoARU_LocalizeNames then ru = CoARU_LocalizeNames(ru) end
    return ru
end

function CoARU_QuestTestExpand(s) return expand(s) end

local function process(fs, field)
    if not CoARU_ModOn("quests") then return end
    if not fs or not fs.GetText then return end
    local t = fs:GetText()
    if not t or #t < 2 then return end

    if CoARU_HasCyrillic and CoARU_HasCyrillic(t) and not hasEnglishTail(t) then return end

    if CoARU_DB and CoARU_DB.opts and CoARU_DB.opts.questdump then
        CoARU_DB.questdump = CoARU_DB.questdump or {}
        local d = CoARU_DB.questdump
        local dup = false
        for i = 1, #d do if d[i].raw == t then dup = true; break end end
        if not dup then d[#d + 1] = { field = field, raw = t } end
    end

    local ru = qlookup(t) or UI[t] or byPattern(t) or objectiveItemRU(t)
    if ru and ru ~= t then
        fs:SetText(expand(ru))
        translated = translated + 1
    end
end

local function processUI(fs)
    if not CoARU_ModOn("quests") then return end
    if not fs or not fs.GetText then return end
    local t = fs:GetText()
    local ru = t and UI[t]
    if ru and ru ~= t then fs:SetText(ru) end
end

local function walkUI(frame, depth)
    if not frame or (depth or 0) > 4 then return end
    if frame.GetRegions then
        local ok, cnt = pcall(function() return select("#", frame:GetRegions()) end)
        if ok then
            for i = 1, cnt do
                local r = select(i, frame:GetRegions())
                if r and r.GetObjectType and r:GetObjectType() == "FontString" then processUI(r) end
            end
        end
    end
    if frame.GetChildren then
        local ok, cnt = pcall(function() return select("#", frame:GetChildren()) end)
        if ok then
            for i = 1, cnt do walkUI(select(i, frame:GetChildren()), (depth or 0) + 1) end
        end
    end
end

local function doInfo()
    for _, n in ipairs(INFO_FS) do process(_G[n], n) end
    for i = 1, (MAX_OBJECTIVES or 10) do process(_G["QuestInfoObjective" .. i], "objective") end
    walkUI(_G["QuestInfoRewardsFrame"], 0)
end

local function doLogChrome()
    processUI(_G["QuestLogFrameAbandonButton"])
    processUI(_G["QuestLogFramePushQuestButton"])
    processUI(_G["QuestLogFrameTrackButton"])
    processUI(_G["QuestLogFrameCancelButton"])
    local mapBtn = _G["QuestLogFrameShowMapButton"]
    if mapBtn then processUI(mapBtn.text or mapBtn:GetName() and _G[mapBtn:GetName() .. "Text"]) end
    processUI(_G["QuestLogDetailTitleText"])
end
local function doProgress() for _, n in ipairs(PROGRESS_FS) do process(_G[n], n) end end
local function doGreeting() for _, n in ipairs(GREETING_FS) do process(_G[n], n) end end

local function directQuestRU(s)
    local ru = qlookup(s) or (CoARU_ZONE and CoARU_ZONE[s]) or UI[s] or byPattern(s)
             or objectiveItemRU(s)
    if ru and ru ~= s then return expand(ru) end
    return nil
end

local function xlateQuestText(t)
    if not CoARU_ModOn("quests") then return nil end
    if not t or #t < 2 then return nil end
    if CoARU_HasCyrillic and CoARU_HasCyrillic(t) and not hasEnglishTail(t) then return nil end
    local ru = directQuestRU(t)
    if ru then return ru end

    local head, num = t:match("^(.-)%s+%-%s+(%d+)%s*$")
    if head and head ~= "" then
        local inner = directQuestRU(head)
        if inner then return inner .. " - " .. num end
    end

    local body, punct = t:match("^(.-)([%.!%?]+)$")
    if body and #body > 1 then
        local inner = directQuestRU(body) or directQuestRU(body .. ".")
        if inner then
            return (inner:gsub("[%.!%?]+$", "")) .. punct
        end
    end

    if t:find(" and ", 1, true) then
        local alt = directQuestRU((t:gsub(" and ", " & ")))
        if alt then return alt end
    elseif t:find(" & ", 1, true) then
        local alt = directQuestRU((t:gsub(" & ", " and ")))
        if alt then return alt end
    end
    return nil
end

CoARU_QuestTextRU = xlateQuestText

local function questXlate(fs)
    if not CoARU_ModOn("quests") then return end
    if not fs or not fs.GetText then return end
    local ru = xlateQuestText(fs:GetText())
    if ru then
        fs:SetText(ru); translated = translated + 1

        local p = fs.GetParent and fs:GetParent()
        local pn = p and p.GetName and p:GetName()
        if pn and pn:find("QuestLogTitle") and fs.SetWidth then fs:SetWidth(0) end
    end
end

function CoARU_QuestTestXlate(fs) return questXlate(fs) end

local function walkXlate(frame, depth)
    if not frame or (depth or 0) > 6 then return end
    if frame.IsShown and not frame:IsShown() then return end
    if frame.GetRegions then
        local ok, cnt = pcall(function() return select("#", frame:GetRegions()) end)
        if ok then
            for i = 1, cnt do
                local r = select(i, frame:GetRegions())
                if r and r.GetObjectType and r:GetObjectType() == "FontString" then questXlate(r) end
            end
        end
    end
    if frame.GetChildren then
        local ok, cnt = pcall(function() return select("#", frame:GetChildren()) end)
        if ok then
            for i = 1, cnt do walkXlate(select(i, frame:GetChildren()), (depth or 0) + 1) end
        end
    end
end

local function doLogList() walkXlate(_G.QuestLogFrame, 0) end

local function fitLogTitle(btn)
    if not btn or not btn.GetName then return end
    local name = btn:GetName()
    if not name then return end
    local fs = _G[name .. "NormalText"] or (btn.GetFontString and btn:GetFontString())
    if not fs or not fs.GetText or not fs.GetStringWidth then return end
    local text = fs:GetText()
    if not text or text == "" then return end
    if fs.SetWidth then fs:SetWidth(0) end
    local left = fs.GetLeft and fs:GetLeft()
    if not left then return end

    local right
    local tag = _G[name .. "Tag"]
    if tag and tag.GetText and (tag:GetText() or "") ~= "" and tag.GetLeft and tag:GetLeft() then
        right = tag:GetLeft()
    elseif btn.GetRight and btn:GetRight() then
        right = btn:GetRight()
    end
    if not right then return end

    local reserve = 6
    local chk = _G[name .. "Check"]
    if chk and chk.IsShown and chk:IsShown() then reserve = reserve + 18 end
    local avail = right - left - reserve
    if avail <= 24 then return end

    local w = fs:GetStringWidth() or 0
    if w <= 0 or w <= avail then return end

    local chars, i = {}, 1
    while i <= #text do
        local b = string.byte(text, i)
        local n = 1
        if b >= 240 then n = 4 elseif b >= 224 then n = 3 elseif b >= 192 then n = 2 end
        chars[#chars + 1] = text:sub(i, i + n - 1)
        i = i + n
    end

    local keep = math.floor(#chars * avail / w)
    if keep >= #chars then keep = #chars - 1 end
    while keep > 1 do
        fs:SetText(table.concat(chars, "", 1, keep) .. "...")
        if (fs:GetStringWidth() or 0) <= avail then return end
        keep = keep - 1
    end
    fs:SetText(text)
end

CoARU_QuestTestFitTitle = fitLogTitle

local function fitLogTitles()
    for i = 1, (QUESTS_DISPLAYED or 25) do
        local btn = _G["QuestLogTitle" .. i]
        if not btn then break end
        if not btn.IsShown or btn:IsShown() then fitLogTitle(btn) end
    end
end

local function doLogListNow()
    if not CoARU_ModOn("quests") then return end
    local ok = pcall(doLogList)

    pcall(fitLogTitles)
    return ok
end
local function doTracker() walkXlate(_G.WatchFrame, 0) end

local _sm = strmatch or string.match
local function xlateLeaderBoard(text)
    if not text or text == "" then return text end
    if not CoARU_ModOn("quests") then return text end

    if CoARU_HasCyrillic and CoARU_HasCyrillic(text) and not hasEnglishTail(text) then
        return text
    end
    local ru = qlookup(text)
    if ru then return expand(ru) end
    ru = objectiveItemRU(text)
    if ru then return ru end
    local body, cnt = _sm(text, "^(.-)(:%s*%d+%s*/%s*%d+)$")
    if not body then body, cnt = text, "" end
    local nm = _sm(body, "^(.+) slain$")
    if nm then return nm .. " убито" .. cnt end
    return text
end
if type(GetQuestLogLeaderBoard) == "function" then
    local orig = GetQuestLogLeaderBoard
    function GetQuestLogLeaderBoard(i, q)
        local text, typ, fin = orig(i, q)
        local ok, r = pcall(xlateLeaderBoard, text)
        return (ok and r) or text, typ, fin
    end
end

if type(GetQuestLogTitle) == "function" then
    local orig = GetQuestLogTitle
    local function fixTitle(title, ...)
        local ok, ru = pcall(xlateQuestText, title)
        if ok and ru then return ru, ... end
        return title, ...
    end
    function GetQuestLogTitle(i)
        return fixTitle(orig(i))
    end
end

if type(GetQuestLogCompletionText) == "function" then
    local origDone = GetQuestLogCompletionText
    function GetQuestLogCompletionText(idx)
        local t = origDone(idx)
        local ok, ru = pcall(xlateQuestText, t)
        if ok and ru then return ru end
        return t
    end
end

if type(GetQuestLogQuestText) == "function" then
    local origText = GetQuestLogQuestText
    function GetQuestLogQuestText()
        local desc, obj = origText()
        local ok, ru = pcall(xlateQuestText, desc)
        if ok and ru then desc = ru end
        ok, ru = pcall(xlateQuestText, obj)
        if ok and ru then obj = ru end
        return desc, obj
    end
end

local _qttBusy = false
local function questTooltipXlate(tip)
    if not CoARU_ModOn("quests") then return end
    if _qttBusy or not tip or not tip.NumLines or not tip.GetOwner then return end
    local owner = tip:GetOwner()
    local on = owner and owner.GetName and owner:GetName()
    if not on then return end
    if not (on:find("QuestLog") or on:find("WatchFrame") or on:find("QuestWatch")) then return end
    local changed = false
    for i = 1, tip:NumLines() do
        local fs = _G["GameTooltipTextLeft" .. i]
        local t = fs and fs.GetText and fs:GetText()
        if t and #t > 1 and (hasEnglishTail(t)
            or not (CoARU_HasCyrillic and CoARU_HasCyrillic(t))) then
            local ru = qlookup(t) or objectiveItemRU(t)
            if ru and ru ~= t then fs:SetText(expand(ru)); changed = true end
        end
    end
    if changed then _qttBusy = true; tip:Show(); _qttBusy = false end
end
if GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript("OnShow", questTooltipXlate)
end

local BTN = {
    QuestFrameAcceptButton        = "Принять",
    QuestFrameDeclineButton       = "Отказаться",
    QuestFrameCompleteButton      = "Продолжить",
    QuestFrameGoodbyeButton       = "До встречи",
    QuestFrameCompleteQuestButton = "Завершить",
    QuestFrameCancelButton        = "Отмена",
    QuestFrameGreetingGoodbyeButton = "До встречи",
    GossipFrameGreetingGoodbyeButton = "До встречи",
}
local function doButtons()
    if not CoARU_ModOn("quests") then return end
    for name, ru in pairs(BTN) do
        local b = _G[name]
        if b and b.SetText and b:IsShown() then b:SetText(ru) end
    end
end

local pending = {}
local waiter = CreateFrame("Frame")
waiter:Hide()
waiter:SetScript("OnUpdate", function(self)
    self:Hide()
    if pending.info     then doInfo();     pending.info = nil end
    if pending.progress then doProgress(); pending.progress = nil end
    if pending.greeting then doGreeting(); pending.greeting = nil end
    if pending.loglist  then doLogList();  pending.loglist = nil end
    if pending.tracker  then doTracker();  pending.tracker = nil end
    doButtons()
    pending.gossip = nil
end)

local function arm(key) pending[key] = true; waiter:Show() end

if type(QuestInfo_Display) == "function" then
    hooksecurefunc("QuestInfo_Display", function() arm("info") end)
end
if type(QuestFrameProgressPanel_OnShow) == "function" then
    hooksecurefunc("QuestFrameProgressPanel_OnShow", function() arm("progress") end)
end
if type(QuestFrameGreetingPanel_OnShow) == "function" then
    hooksecurefunc("QuestFrameGreetingPanel_OnShow", function() arm("greeting") end)
end

if type(QuestFrameRewardPanel_OnShow) == "function" then
    hooksecurefunc("QuestFrameRewardPanel_OnShow", function() arm("gossip") end)
end
if type(GossipFrameUpdate) == "function" then
    hooksecurefunc("GossipFrameUpdate", function() arm("gossip") end)
end

CoARU_GOSSIP_DBG = false

local function splitChrome(t)

    local pre, core = "", t
    while true do
        local piece = core:match("^(|T[^|]*|t)") or core:match("^(|[rR])") or core:match("^(%s+)")
        if not piece then break end
        pre, core = pre .. piece, core:sub(#piece + 1)
    end

    local c, inner = core:match("^(|[cC]%x%x%x%x%x%x%x%x)(.*)|[rR]$")
    local wrap = ""
    if c then core, wrap = inner, c end

    local tail = ""
    local body, tcolor, ttext = core:match("^(.-)%s*(|[cC]%x%x%x%x%x%x%x%x)(%(.-%))|[rR]%s*$")
    if body then
        core, tail = body, " " .. tcolor .. ttext .. "|r"
    end
    core = core:match("^%s*(.-)%s*$") or core
    return pre, wrap, core, tail
end

local function tailRU(tail)
    if tail == "" then return tail end
    local n = tail:match("Requires a level (%d+)")
    if not n then return tail end
    return (tail:gsub("%(.-%)", "(Требуется " .. n .. " уровень)", 1))
end

local shownPairs, shownN = {}, 0

local function notePair(en, ru)
    if type(en) ~= "string" or type(ru) ~= "string" or en == ru or ru == "" then return end

    if shownN >= 64 then shownPairs, shownN = {}, 0 end
    shownN = shownN + 1
    shownPairs[shownN] = { en, ru }
end

local function replacePlain(s, from, to)
    local a, b = s:find(from, 1, true)
    if not a then return nil end
    return s:sub(1, a - 1) .. to .. s:sub(b + 1)
end

local function bindOriginal(fs)
    if not CoARU_SetTranslated then return end
    if not fs or not fs.GetText then return end
    local ok, t = pcall(fs.GetText, fs)
    if not ok or not t or t == "" then return end

    local best, bestLen = nil, -1
    for i = 1, shownN do
        local ru = shownPairs[i][2]
        if #ru > bestLen then
            local en = replacePlain(t, ru, shownPairs[i][1])
            if en then best, bestLen = en, #ru end
        end
    end
    if best then CoARU_SetTranslated(fs, best, t) end
end

function CoARU_GossipLog(line)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffC495DDgossip|r " .. line)
    end
    if not CoARU_DB then return end
    CoARU_DB.gossipdbg = CoARU_DB.gossipdbg or {}
    if #CoARU_DB.gossipdbg < 400 then
        table.insert(CoARU_DB.gossipdbg, line)
    end
end

local function gossipRU(t, isOption)
    if not t or #t < 3 then return nil end
    local pre, wrap, core, tail = splitChrome(t)
    local ok, ru = pcall(xlateQuestText, core)
    if CoARU_GOSSIP_DBG then
        local mod = CoARU_ModOn and CoARU_ModOn("quests")
        local raw = CoARU_QuestLookup and CoARU_QuestLookup(core)
        CoARU_GossipLog(("[%s] len=%d ядро=[%s] mod=%s lookup=%s xlate=%s")
            :format(tostring(t), #t, tostring(core), tostring(mod), tostring(raw),
                    tostring(ok and ru)))
    end
    if ok and ru then

        local full = pre .. wrap .. ru .. (wrap ~= "" and "|r" or "") .. tailRU(tail)
        notePair(core, ru)
        return full
    end

    if not isOption and core:find("\r?\n") then
        local out, any, miss = {}, false, false
        for part, sep in core:gmatch("([^\r\n]*)(\r?\n?)") do
            if part ~= "" then
                local pok, pru = pcall(xlateQuestText, part)
                if pok and pru then
                    out[#out + 1], any = pru, true
                else
                    out[#out + 1], miss = part, true
                end
            end
            out[#out + 1] = sep
        end

        if any and not miss then
            local body = table.concat(out)
            notePair(core, body)
            return pre .. wrap .. body .. (wrap ~= "" and "|r" or "") .. tailRU(tail)
        end
    end
    t = core

    if CoARU_NoteMiss and not (CoARU_HasCyrillic and CoARU_HasCyrillic(t))
       and (isOption or #t > 25) then
        CoARU_NoteMiss(isOption and "gossipopt" or "gossip", t)
    end
    return nil
end

if type(GetGossipText) == "function" then
    local orig = GetGossipText
    function GetGossipText()
        local t = orig()
        return gossipRU(t) or t
    end
end

local function xlateVarargs(step, ...)
    local n = select('#', ...)
    if n == 0 then return end
    local out = {}
    for i = 1, n do
        local v = select(i, ...)
        if type(v) == "string" and (i % step) == 1 then
            v = gossipRU(v, true) or v
        end
        out[i] = v
    end
    return unpack(out, 1, n)
end

if type(GetGossipOptions) == "function" then
    local orig = GetGossipOptions
    function GetGossipOptions()
        return xlateVarargs(2, orig())
    end
end

local function questTitleRU(t)
    if type(t) ~= "string" or #t < 2 then return nil end
    local pre, wrap, core, tail = splitChrome(t)
    local ok, ru = pcall(xlateQuestText, core)
    if ok and ru then
        notePair(core, ru)
        return pre .. wrap .. ru .. (wrap ~= "" and "|r" or "") .. tailRU(tail)
    end

    if CoARU_NoteMiss and not (CoARU_HasCyrillic and CoARU_HasCyrillic(core)) then
        CoARU_NoteMiss("questtitle", core)
    end
    return nil
end

local function xlateTitleList(step, ...)
    local n = select('#', ...)
    if n == 0 then return end
    local out = {}
    for i = 1, n do
        local v = select(i, ...)
        if type(v) == "string" and (i % step) == 1 then
            v = questTitleRU(v) or v
        end
        out[i] = v
    end
    return unpack(out, 1, n)
end

if type(GetGossipAvailableQuests) == "function" then
    local orig = GetGossipAvailableQuests
    function GetGossipAvailableQuests() return xlateTitleList(5, orig()) end
end
if type(GetGossipActiveQuests) == "function" then
    local orig = GetGossipActiveQuests
    function GetGossipActiveQuests() return xlateTitleList(4, orig()) end
end

local function fixFirstTitle(t, ...)
    if type(t) == "string" then return questTitleRU(t) or t, ... end
    return t, ...
end
if type(GetAvailableTitle) == "function" then
    local orig = GetAvailableTitle
    function GetAvailableTitle(i) return fixFirstTitle(orig(i)) end
end
if type(GetActiveTitle) == "function" then
    local orig = GetActiveTitle
    function GetActiveTitle(i) return fixFirstTitle(orig(i)) end
end

if type(GetGreetingText) == "function" then
    local orig = GetGreetingText
    function GetGreetingText()
        local t = orig()
        return gossipRU(t) or t
    end
end

local function bindButtons(prefix, limit)
    for i = 1, limit do
        local b = _G[prefix .. i]
        if not b then break end
        if (not b.IsShown or b:IsShown()) and b.GetFontString then
            local ok, fs = pcall(b.GetFontString, b)
            if ok then bindOriginal(fs) end
        end
    end
end

if type(GossipFrameUpdate) == "function" then
    hooksecurefunc("GossipFrameUpdate", function()
        if not CoARU_ModOn("quests") then return end
        bindOriginal(_G.GossipGreetingText)
        bindButtons("GossipTitleButton", NUMGOSSIPBUTTONS or 32)
        shownPairs, shownN = {}, 0
    end)
end
if type(QuestFrameGreetingPanel_OnShow) == "function" then
    hooksecurefunc("QuestFrameGreetingPanel_OnShow", function()
        if not CoARU_ModOn("quests") then return end
        bindOriginal(_G.GreetingText)
        bindButtons("QuestTitleButton", MAX_NUM_QUESTS or 32)
        shownPairs, shownN = {}, 0
    end)
end

if type(QuestLogTitleButton_Resize) == "function" then
    hooksecurefunc("QuestLogTitleButton_Resize", function(qlt)
        local nt = qlt and qlt.normalText

        if nt then questXlate(nt) end

        local cur = nt and nt.GetText and nt:GetText()
        if nt and nt.SetWidth and cur and CoARU_HasCyrillic and CoARU_HasCyrillic(cur) then
            nt:SetWidth(0)
        end
    end)
end

if type(QuestLog_Update) == "function" then
    hooksecurefunc("QuestLog_Update", doLogChrome)

    hooksecurefunc("QuestLog_Update", function()
        doLogListNow()
        arm("loglist")
    end)
end
if type(QuestLog_UpdateTrackButton) == "function" then
    hooksecurefunc("QuestLog_UpdateTrackButton", doLogChrome)
end

if type(WatchFrame_Update) == "function" then
    hooksecurefunc("WatchFrame_Update", function()
        pcall(doTracker)
        arm("tracker")
    end)
end

local qevents = CreateFrame("Frame")
qevents:RegisterEvent("QUEST_LOG_UPDATE")
qevents:RegisterEvent("QUEST_WATCH_UPDATE")
qevents:RegisterEvent("PLAYER_ENTERING_WORLD")
qevents:RegisterEvent("ZONE_CHANGED_NEW_AREA")

qevents:SetScript("OnEvent", function()
    doLogListNow()
    pcall(doTracker)
    arm("loglist")
    arm("tracker")
end)

function CoARU_QuestTranslatedCount() return translated end
function CoARU_QuestDumpCount()
    return CoARU_DB and CoARU_DB.questdump and #CoARU_DB.questdump or 0
end
