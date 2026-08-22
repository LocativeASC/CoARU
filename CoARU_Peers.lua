local CHANNEL = "CoARUru"
local PREFIX = "CoARU:"

local channelId = 0
local announced = false

local function myVersion()
    return (GetAddOnMetadata and GetAddOnMetadata("CoARU", "Version")) or ""
end

local function channelFilter(_, _, msg, author, _, _, _, _, _, _, chanName)
    if type(chanName) ~= "string" or chanName:upper() ~= CHANNEL:upper() then
        return false
    end
    if type(msg) == "string" and msg:sub(1, #PREFIX) == PREFIX then

        local body = msg:sub(#PREFIX + 1)
        local ver = body:match("^([%d%.]+)")
        local flag = body:match("^[%d%.]+:(%a+)")
        if ver and author and author ~= "" and CoARU_NoticePeerVersion then
            pcall(CoARU_NoticePeerVersion, ver, author)
            if flag and CoARU_NotePeerFlag then pcall(CoARU_NotePeerFlag, author, flag) end
        end
    end
    return true
end

local function hideFromChat()
    for i = 1, 10 do
        local frame = _G["ChatFrame" .. i]
        if frame and ChatFrame_RemoveChannel then
            pcall(ChatFrame_RemoveChannel, frame, CHANNEL)
        end
    end
end

local function joinChannel()
    if not (JoinChannelByName and GetChannelName) then return false end
    local id = GetChannelName(CHANNEL)
    if not (id and id > 0) then
        pcall(JoinChannelByName, CHANNEL)
        id = GetChannelName(CHANNEL)
    end
    channelId = id or 0
    hideFromChat()
    return channelId > 0
end

local function announce()
    if announced or channelId <= 0 or not SendChatMessage then return end
    local v = myVersion()
    if v == "" then return end
    announced = true

    local flag = CoARU_MyFlag and CoARU_MyFlag() or nil
    local text = PREFIX .. v
    if flag and flag ~= "" then text = text .. ":" .. flag end
    pcall(SendChatMessage, text, "CHANNEL", nil, channelId)
end

local f = CreateFrame("Frame")
local waited = 0
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self)
    self:SetScript("OnUpdate", function(_, elapsed)
        waited = waited + (elapsed or 0)
        if waited < 8 then return end
        self:SetScript("OnUpdate", nil)
        if joinChannel() then announce() end
    end)
end)

local watch = CreateFrame("Frame")
local acc = 0
watch:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + (elapsed or 0)
    if acc < 60 then return end
    acc = 0
    if channelId > 0 then
        local id = GetChannelName and GetChannelName(CHANNEL)
        if id and id > 0 then return end
        announced = false
    end
    joinChannel()
    announce()
end)

if type(ChatFrame_AddMessageEventFilter) == "function" then

    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", channelFilter)
end

CoARU_PeerJoinForTest = joinChannel
CoARU_PeerChannel = CHANNEL
CoARU_PeerChannelFilter = channelFilter
function CoARU_PeerChannelId() return channelId end

function CoARU_AnnounceFlagChange()
    announced = false
    if channelId > 0 then announce() end
end
