local function nameRU(n)
    if not n or n == "" then return nil end
    if CoARU_ModOn and not CoARU_ModOn("spellnames") then return nil end
    if CoARU_HasCyrillic and CoARU_HasCyrillic(n) then return nil end
    local ru = CoARU_SPELL_NAME_RU and CoARU_SPELL_NAME_RU[n]
    if ru and ru ~= n then return ru end
    return nil
end

CoARU_CastNameRU = nameRU

local function fixCastInfo(...)
    local n = select('#', ...)
    local name = ...
    if not name then return ... end
    local ru = nameRU(name)
    if not ru then return ... end
    local t = { ... }
    t[1] = ru
    if t[3] == name then t[3] = ru end
    return unpack(t, 1, n)
end

do
    local orig = UnitCastingInfo
    if orig then
        function UnitCastingInfo(unit)
            return fixCastInfo(orig(unit))
        end
    end
end

do
    local orig = UnitChannelInfo
    if orig then
        function UnitChannelInfo(unit)
            return fixCastInfo(orig(unit))
        end
    end
end
