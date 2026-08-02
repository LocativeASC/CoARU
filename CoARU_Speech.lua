local function speechOn()
    return not CoARU_ModOn or CoARU_ModOn("speech")
end

local function expand(ru, who)
    ru = ru:gsub("%$[Bb]", "\n")
    local sex = UnitSex and UnitSex("player")
    ru = ru:gsub("%$[Gg]([^:]*):([^;]*);", sex == 3 and "%2" or "%1")
    local name = who or (UnitName and UnitName("player"))
    if name then ru = ru:gsub("<name>", name):gsub("%$[Nn]", name) end
    return ru
end

local NAME = "[A-Z][a-z][a-z]+"

local function tryLookup(t)
    local ok, ru = pcall(CoARU_QuestLookup, t)
    if ok and ru and ru ~= t then return ru end
    return nil
end

local function lookup(t)
    if not t or #t < 3 then return nil end
    if not CoARU_QuestLookup then return nil end
    local ru = tryLookup(t)
    if ru then return expand(ru) end

    local tried = 0
    local pos = 1
    while tried < 3 do
        local s, e = t:find(NAME, pos)
        if not s then break end
        pos = e + 1

        local before = t:sub(1, s - 1):gsub("%s+$", "")
        local head = before == "" or before:sub(-1) == "." or before:sub(-1) == "!"
                     or before:sub(-1) == "?"
        if not head then
            tried = tried + 1
            ru = tryLookup(t:sub(1, s - 1) .. "$N" .. t:sub(e + 1))

            if ru then return expand(ru, t:sub(s, e)) end
        end
    end
    return nil
end

local function nameRU(n)
    if not n or n == "" then return nil end
    if CoARU_HasCyrillic and CoARU_HasCyrillic(n) then return nil end
    local ru = CoARU_UNIT_N2R and CoARU_UNIT_N2R[n]
    if not ru and CoARU_UnitN2R then ru = CoARU_UnitN2R(n) end
    if ru and ru ~= n then return ru end
    return nil
end

local function tplToPattern(tpl)

    local p = tpl:gsub("%%s", "\1")
    p = p:gsub("([%^%$%(%)%.%[%]%*%+%-%?%%])", "%%%1")
    p = p:gsub("\1", "(%%S+)")
    return "^" .. p .. "$"
end

local function emoteRU(msg)
    if not msg or msg == "" then return nil end
    if CoARU_EMOTE then
        local direct = CoARU_EMOTE[msg]
        if direct then return direct end
    end
    if not CoARU_EMOTE_BY_WORD then return nil end

    for word in msg:gmatch("[A-Za-z']+") do
        local list = CoARU_EMOTE_BY_WORD[word:lower()]
        if list then
            for i = 1, #list do
                local en, ru = list[i][1], list[i][2]
                local a, b = msg:match(tplToPattern(en))
                if a then
                    local out = ru:gsub("%%s", function() local v = a; a = b; return v end)
                    return out
                end
            end
        end
    end
    return nil
end

local EVENTS = {
    "CHAT_MSG_MONSTER_SAY",
    "CHAT_MSG_MONSTER_YELL",
    "CHAT_MSG_MONSTER_EMOTE",
    "CHAT_MSG_MONSTER_WHISPER",
    "CHAT_MSG_RAID_BOSS_EMOTE",
    "CHAT_MSG_RAID_BOSS_WHISPER",

    "CHAT_MSG_TEXT_EMOTE",
}

local function filter(_frame, _event, msg, author, ...)
    if not speechOn() then return false end
    local ru = emoteRU(msg) or lookup(msg)
    local who = nameRU(author)
    if not ru and not who then

        if msg and #msg > 25 and CoARU_NoteMiss
            and not (CoARU_HasCyrillic and CoARU_HasCyrillic(msg)) then
            CoARU_NoteMiss("speech", msg)
        end
        return false
    end
    return false, ru or msg, who or author, ...
end

if type(ChatFrame_AddMessageEventFilter) == "function" then
    for i = 1, #EVENTS do
        ChatFrame_AddMessageEventFilter(EVENTS[i], filter)
    end
end

local pending, ticks = nil, 0

local function bubbleText(frame)
    if not frame.GetRegions then return nil end
    local ok, cnt = pcall(function() return select("#", frame:GetRegions()) end)
    if not ok then return nil end
    local fs
    for i = 1, cnt do
        local r = select(i, frame:GetRegions())
        if r and r.GetObjectType and r:GetObjectType() == "FontString" then
            if fs then return nil end
            fs = r
        end
    end
    return fs
end

local function walkBubbles(en, ru)
    local wf = _G.WorldFrame
    if not wf or not wf.GetChildren then return end
    local ok, cnt = pcall(function() return select("#", wf:GetChildren()) end)
    if not ok then return end
    for i = 1, cnt do
        local child = select(i, wf:GetChildren())
        if child and not (child.GetName and child:GetName()) then
            local fs = bubbleText(child)
            local t = fs and fs.GetText and fs:GetText()

            if t and t == en then fs:SetText(ru) end
        end
    end
end

local watcher = CreateFrame("Frame")
watcher:SetScript("OnUpdate", function(_self, elapsed)
    if not pending then return end
    ticks = ticks + 1
    walkBubbles(pending[1], pending[2])
    if ticks > 20 then pending, ticks = nil, 0 end
end)

local function noteBubble(msg)
    if not speechOn() then return end
    local ru = lookup(msg)
    if ru then pending, ticks = { msg, ru }, 0 end
end

local ev = CreateFrame("Frame")
for i = 1, #EVENTS do ev:RegisterEvent(EVENTS[i]) end
ev:SetScript("OnEvent", function(_self, _event, msg) noteBubble(msg) end)

function CoARU_SpeechStatus()
    return type(ChatFrame_AddMessageEventFilter) == "function"
end
