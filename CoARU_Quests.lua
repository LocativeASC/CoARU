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
}

local function byPattern(t)
    for i = 1, #PATTERNS do
        local got = t:gsub(PATTERNS[i][1], PATTERNS[i][2])
        if got ~= t then return got end
    end
    return nil
end

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

local function expand(ru)
    ru = ru:gsub("%$[Bb]", "\n")
    local sex = UnitSex and UnitSex("player")
    ru = ru:gsub("%$[Gg]([^:]*):([^;]*);", sex == 3 and "%2" or "%1")
    local pname = UnitName and UnitName("player")
    if pname then
        ru = ru:gsub("<name>", pname):gsub("%$[Nn]", pname)
    end
    local cls = UnitClass and UnitClass("player")
    if cls then ru = ru:gsub("<class>", cls):gsub("%$[Cc]", cls) end
    local rc = UnitRace and UnitRace("player")
    if rc then ru = ru:gsub("<race>", rc):gsub("%$[Rr]", rc) end
    return ru
end

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

    local ru = qlookup(t) or UI[t] or byPattern(t)
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

local function questXlate(fs)
    if not CoARU_ModOn("quests") then return end
    if not fs or not fs.GetText then return end
    local t = fs:GetText()
    if not t or #t < 2 then return end
    if CoARU_HasCyrillic and CoARU_HasCyrillic(t) and not hasEnglishTail(t) then return end
    local ru = qlookup(t) or (CoARU_ZONE and CoARU_ZONE[t]) or UI[t] or byPattern(t)
    if ru and ru ~= t then
        fs:SetText(expand(ru)); translated = translated + 1

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

local function doLogListNow()
    if not CoARU_ModOn("quests") then return end
    local ok = pcall(doLogList)
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
            local ru = qlookup(t)
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
    hooksecurefunc("WatchFrame_Update", function() arm("tracker") end)
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
