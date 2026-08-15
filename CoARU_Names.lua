local SEEN_PLAYER, SEEN_GUILD = {}, {}
local nPlayer, nGuild = 0, 0

local function addPlayer(name)
    if type(name) ~= "string" or name == "" then return end

    if not SEEN_PLAYER[name] then
        SEEN_PLAYER[name] = true
        nPlayer = nPlayer + 1
    end
    local short = name:match("^([^%-]+)%-")
    if short and not SEEN_PLAYER[short] then
        SEEN_PLAYER[short] = true
        nPlayer = nPlayer + 1
    end
end

local function addGuild(name)
    if type(name) ~= "string" or name == "" then return end
    if not SEEN_GUILD[name] then
        SEEN_GUILD[name] = true
        nGuild = nGuild + 1
    end
end

CoARU_NotePlayerName = addPlayer
CoARU_NoteGuildName = addGuild

local function noteUnit(unit)
    if not unit then return end
    if UnitExists and not UnitExists(unit) then return end

    if UnitIsPlayer and not UnitIsPlayer(unit) then return end
    if UnitName then
        local ok, n = pcall(UnitName, unit)
        if ok then addPlayer(n) end
    end
    if GetGuildInfo then
        local ok, g = pcall(GetGuildInfo, unit)
        if ok then addGuild(g) end
    end
end

CoARU_NoteUnitName = noteUnit

function CoARU_NoteAuraCaster(unit, index, filter)
    if not UnitAura or not unit or not index then return end
    local ok, _, _, _, _, _, _, _, caster = pcall(UnitAura, unit, index, filter)
    if ok and caster then noteUnit(caster) end
end

local function scanRoster()
    noteUnit("player")
    local n = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    if n > 0 then
        for i = 1, n do noteUnit("raid" .. i) end
    else
        n = (GetNumPartyMembers and GetNumPartyMembers()) or 0
        for i = 1, n do noteUnit("party" .. i) end
    end

    if GetNumGuildMembers and GetGuildRosterInfo then
        local ok, total = pcall(GetNumGuildMembers, true)
        if ok and type(total) == "number" then
            for i = 1, total do
                local ok2, name = pcall(GetGuildRosterInfo, i)
                if ok2 then addPlayer(name) end
            end
        end
    end
    if GetNumFriends and GetFriendInfo then
        local ok, total = pcall(GetNumFriends)
        if ok and type(total) == "number" then
            for i = 1, total do
                local ok2, name = pcall(GetFriendInfo, i)
                if ok2 then addPlayer(name) end
            end
        end
    end
end

function CoARU_NoteChatPlayers(msg)
    if type(msg) ~= "string" then return end
    for name in msg:gmatch("|Hplayer:([^|:]+)") do addPlayer(name) end
end

function CoARU_IsPlayerName(t)
    if type(t) ~= "string" or t == "" then return false end
    local plain = CoARU_StripCodes and CoARU_StripCodes(t) or t
    return SEEN_PLAYER[plain] == true or SEEN_PLAYER[t] == true
end

function CoARU_IsGuildName(t)
    if type(t) ~= "string" or t == "" then return false end
    local plain = CoARU_StripCodes and CoARU_StripCodes(t) or t
    return SEEN_GUILD[plain] == true or SEEN_GUILD[t] == true
end

local SEEN_ADDON, nAddon = {}, 0

local function scanAddons()
    if not (GetNumAddOns and GetAddOnInfo) then return end
    for i = 1, GetNumAddOns() do
        local ok, name, title = pcall(GetAddOnInfo, i)
        if ok and type(name) == "string" and name ~= "" and not SEEN_ADDON[name] then
            SEEN_ADDON[name] = true
            nAddon = nAddon + 1
        end

        if ok and type(title) == "string" and title ~= "" then
            local plain = CoARU_StripCodes and CoARU_StripCodes(title) or title
            plain = plain:gsub("^%s+", ""):gsub("%s+$", "")
            if plain ~= "" and not SEEN_ADDON[plain] then
                SEEN_ADDON[plain] = true
                nAddon = nAddon + 1
            end
        end
    end
end

function CoARU_IsAddonName(t)
    if type(t) ~= "string" or t == "" then return false end
    if nAddon == 0 then scanAddons() end
    local plain = CoARU_StripCodes and CoARU_StripCodes(t) or t
    return SEEN_ADDON[plain] == true or SEEN_ADDON[t] == true
end

function CoARU_IsPersonLine(t)
    return CoARU_IsPlayerName(t) or CoARU_IsGuildName(t) or CoARU_IsAddonName(t)
end

function CoARU_NamesSeen()
    return nPlayer, nGuild
end

if CreateFrame then
    local f = CreateFrame("Frame")
    for _, ev in ipairs({ "PLAYER_ENTERING_WORLD", "GUILD_ROSTER_UPDATE", "FRIENDLIST_UPDATE",
                          "RAID_ROSTER_UPDATE", "PARTY_MEMBERS_CHANGED", "PLAYER_GUILD_UPDATE" }) do
        pcall(f.RegisterEvent, f, ev)
    end

    for _, ev in ipairs({ "UPDATE_MOUSEOVER_UNIT", "PLAYER_TARGET_CHANGED",
                          "PLAYER_FOCUS_CHANGED" }) do
        pcall(f.RegisterEvent, f, ev)
    end
    f:SetScript("OnEvent", function(_, event)
        if event == "UPDATE_MOUSEOVER_UNIT" then
            noteUnit("mouseover")
        elseif event == "PLAYER_TARGET_CHANGED" then
            noteUnit("target")
        elseif event == "PLAYER_FOCUS_CHANGED" then
            noteUnit("focus")
        else
            scanRoster()
        end
    end)

    if GuildRoster then pcall(GuildRoster) end
end
