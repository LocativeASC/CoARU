local PREFIX = "|cffC495DDCoARU|r: "
local function msg(t) print(PREFIX .. t) end

local tip
local function getTip()
    if not tip then
        tip = CreateFrame("GameTooltip", "CoARUQuestScanTip", UIParent, "GameTooltipTemplate")
        tip:SetFrameStrata("TOOLTIP")
        tip:SetOwner(UIParent, "ANCHOR_NONE")
        tip:Hide()
    end
    return tip
end

local titleFS

local function questLines(id)
    local t = getTip()
    t:SetOwner(UIParent, "ANCHOR_NONE")
    t:ClearLines()

    local ok = pcall(t.SetHyperlink, t, "quest:" .. id .. ":70")
    if not ok then t:Hide(); return nil end
    t:Show()

    local n = t.NumLines and t:NumLines() or 0
    if not n or n == 0 then t:Hide(); return nil end
    titleFS = titleFS or _G["CoARUQuestScanTipTextLeft1"]
    local title = titleFS and titleFS:GetText()
    local lines = {}
    for i = 1, n do
        local fs = _G["CoARUQuestScanTipTextLeft" .. i]
        local s = fs and fs:GetText()
        if s and s ~= "" and s ~= " " then lines[#lines + 1] = s end
    end
    t:Hide()
    if not title or title == "" then return nil, lines end
    return title, lines
end

local function questTitle(id)
    local title = questLines(id)
    return title
end

function CoARU_QuestProbe(id)
    local title, lines = questLines(id)
    msg(("проба квеста %d: заголовок %s, строк %d"):format(
        id, title and ("«" .. title .. "»") or "нет", lines and #lines or 0))
    for i = 1, (lines and #lines or 0) do
        print(("   %d: %s"):format(i, lines[i]))
    end
    return title
end

local ranges, ri, cur = nil, 0, 0
local asked, found, startAt = 0, 0, 0
local perSec, acc = 10, 0
local active = false
local pass, passOne = 1, nil

local PASS_GAP = 5
local gapLeft = 0

local frame = CreateFrame("Frame")
frame:Hide()

local function nextId()
    while ranges do
        local r = ranges[ri]
        if not r then return nil end
        if cur <= r[2] then
            local id = cur
            cur = cur + 1
            return id
        end
        ri = ri + 1
        local nr = ranges[ri]
        if not nr then return nil end
        cur = nr[1]
    end
    return nil
end

local function finish()
    active = false
    frame:Hide()
    local secs = math.max(1, (GetTime and GetTime() or 0) - startAt)
    if pass == 1 and passOne then

        msg(("проход 1 завершен за %d:%02d: спрошено %d, сразу ответили %d. Жду ответы %d сек, потом второй проход.")
            :format(math.floor(secs / 60), math.floor(secs % 60), asked, found, PASS_GAP))
        pass, asked, found = 2, 0, 0
        ranges, ri, cur = passOne, 1, passOne[1][1]
        startAt = GetTime and GetTime() or 0
        gapLeft = PASS_GAP
        active = true
        frame:Show()
        return
    end
    local total = 0
    for _ in pairs(CoARU_DB.questscan or {}) do total = total + 1 end
    msg(("скан квестов завершен за %d:%02d. Спрошено %d, найдено %d, всего в списке %d.")
        :format(math.floor(secs / 60), math.floor(secs % 60), asked, found, total))
    print("  дальше: |cffffd100выйди из игры полностью|r (кэш квестов клиент пишет на выходе),")
    print("  затем разбор: |cffffd100python tools/Parse-WdbCache.py|r")
end

frame:SetScript("OnUpdate", function(self, delta)
    if not active then return end
    if gapLeft > 0 then
        gapLeft = gapLeft - (delta or 0)
        return
    end

    acc = acc + (delta or 0) * perSec
    local n = math.floor(acc)
    if n < 1 then return end
    acc = acc - n
    for _ = 1, n do
        local id = nextId()
        if not id then
            finish()
            return
        end
        asked = asked + 1
        local title = questTitle(id)
        if title then
            found = found + 1
            CoARU_DB.questscan = CoARU_DB.questscan or {}
            CoARU_DB.questscan[id] = title
        end

        if asked % 500 == 0 then
            msg(("проход %d: спрошено %d, найдено %d (номер %d)"):format(pass, asked, found, id))
        end
    end
end)

function CoARU_StartQuestScan(rs, rate)
    if not (rs and rs[1]) then
        msg("нечего сканировать: не задан диапазон номеров.")
        return false
    end
    CoARU_DB.questscan = CoARU_DB.questscan or {}
    ranges, ri, cur = rs, 1, rs[1][1]
    passOne = rs
    pass, asked, found, acc, gapLeft = 1, 0, 0, 0, 0
    perSec = math.max(1, math.min(tonumber(rate) or 10, 100))
    startAt = GetTime and GetTime() or 0
    active = true
    frame:Show()
    local total = 0
    for _, r in ipairs(rs) do total = total + (r[2] - r[1] + 1) end
    msg(("скан квестов: %d номеров, %d запросов в секунду, примерно %d мин на проход.")
        :format(total, perSec, math.max(1, math.floor(total / perSec / 60))))
    print("  каждый номер это запрос к серверу, поэтому скорость намеренно скромная. Играть можно.")
    return true
end

function CoARU_StopQuestScan()
    if not active then return false end
    active = false
    frame:Hide()
    msg(("скан квестов остановлен: спрошено %d, найдено %d."):format(asked, found))
    return true
end

function CoARU_QuestScanCount()
    local n = 0
    for _ in pairs(CoARU_DB and CoARU_DB.questscan or {}) do n = n + 1 end
    return n, active
end

function CoARU_QuestScanTick(delta)
    local fn = frame:GetScript("OnUpdate")
    if fn then fn(frame, delta or 1) end
end
