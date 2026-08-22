CoARU_FLAGS = {
    { key = "ru",   label = "Россия",     tex = "flag-ru" },
    { key = "by",   label = "Беларусь",   tex = "flag-by" },
    { key = "ua",   label = "Украина",    tex = "flag-ua" },
    { key = "kz",   label = "Казахстан",  tex = "flag-kz" },
    { key = "none", label = "Без флага",  tex = "flag-none" },
}

local DEFAULT_FLAG = "ru"

local TEX = {}
for i = 1, #CoARU_FLAGS do

    TEX[CoARU_FLAGS[i].key] =
        "|TInterface\\AddOns\\CoARU\\Textures\\" .. CoARU_FLAGS[i].tex .. ":12:12:0:-1|t "
end

CoARU_PEER_FLAG = CoARU_PEER_FLAG or {}

function CoARU_NotePeerFlag(name, flag)
    if type(name) ~= "string" or name == "" then return end
    if type(flag) ~= "string" or not TEX[flag] then return end
    CoARU_PEER_FLAG[name] = flag
end

function CoARU_MyFlag()
    if CoARU_ModOn and not CoARU_ModOn("chatmark") then return "none" end
    local v = CoARU_DB and CoARU_DB.opts and CoARU_DB.opts.flag
    if type(v) == "string" and TEX[v] then return v end
    return DEFAULT_FLAG
end

function CoARU_SetMyFlag(key)
    if not (CoARU_DB and TEX[key]) then return end
    CoARU_DB.opts = CoARU_DB.opts or {}
    CoARU_DB.opts.flag = key

    if CoARU_AnnounceFlagChange then pcall(CoARU_AnnounceFlagChange) end
end

local function isMe(name)
    if not name or name == "" then return false end
    local ok, me = pcall(UnitName, "player")
    return ok and me == name
end

local function markFor(name)
    if not name or name == "" then return nil end
    if isMe(name) then return TEX[CoARU_MyFlag()] end
    if not CoARU_SEEN then return nil end
    local short = name:match("^([^%-]+)%-")
    if not (CoARU_SEEN[name] or (short and CoARU_SEEN[short])) then return nil end

    local flag = CoARU_PEER_FLAG[name] or (short and CoARU_PEER_FLAG[short]) or "none"
    return TEX[flag] or TEX["none"]
end

local function anyMarkIn(text)
    for _, t in pairs(TEX) do
        if text:find(t, 1, true) then return true end
    end
    return false
end

function CoARU_MarkChatLine(text)
    if type(text) ~= "string" then return text end
    if not (CoARU_ModOn and CoARU_ModOn("chatmark")) then return text end
    if not text:find("|Hplayer:", 1, true) then return text end

    if anyMarkIn(text) then return text end
    local out = text:gsub("|Hplayer:([^:|]+)", function(who)
        local mark = markFor(who)
        if mark then return mark .. "|Hplayer:" .. who end
        return "|Hplayer:" .. who
    end)
    return out
end

function CoARU_MarkUnitName(tip, name)
    if not (tip and tip.GetName and name and name ~= "") then return end
    local okN, frameName = pcall(tip.GetName, tip)
    if not okN or type(frameName) ~= "string" then return end
    local fs = _G[frameName .. "TextLeft1"]
    if not fs or not fs.GetText then return end
    local ok, cur = pcall(fs.GetText, fs)
    if not ok or type(cur) ~= "string" or cur == "" then return end
    if anyMarkIn(cur) then return end
    local mark = markFor(name)
    if not mark then return end
    pcall(fs.SetText, fs, mark .. cur)
end

local hooked = {}
local function hookFrame(frame)
    if not frame or hooked[frame] or type(frame.AddMessage) ~= "function" then return end
    hooked[frame] = true
    local orig = frame.AddMessage
    frame.AddMessage = function(self, text, ...)
        local ok, marked = pcall(CoARU_MarkChatLine, text)
        return orig(self, (ok and marked) or text, ...)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    for i = 1, 10 do hookFrame(_G["ChatFrame" .. i]) end
end)

local watch = CreateFrame("Frame")
local acc = 0
watch:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + (elapsed or 0)
    if acc < 30 then return end
    acc = 0
    for i = 1, 10 do hookFrame(_G["ChatFrame" .. i]) end
end)

CoARU_FlagTexture = function(key) return TEX[key] end
