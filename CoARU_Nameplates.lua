local function namesOn()
    return CoARU_ModOn and CoARU_ModOn("nameplates")
end

local function npcID(guid)
    if type(guid) ~= "string" then return nil end
    if guid:sub(1, 2) == "0x" then
        local hex = guid:sub(3)
        if #hex >= 10 then return tonumber(hex:sub(5, 10), 16) end
    end
    return nil
end

local function ruFor(unit, text)
    local ru
    local id = unit and npcID(UnitGUID and UnitGUID(unit))
    if id and CoARU_UNIT_RU then ru = CoARU_UNIT_RU[id] end
    if not ru and text and CoARU_UnitN2R then ru = CoARU_UnitN2R(text) end
    return ru
end

local hooked = false

local function install()
    if hooked then return end

    if type(CompactUnitMixin) ~= "table" or type(CompactUnitMixin.UpdateName) ~= "function" then
        return
    end
    hooksecurefunc(CompactUnitMixin, "UpdateName", function(self)
        if not namesOn() then return end
        local fs = self and self.Elements and self.Elements.name
        if not fs or not fs.GetText then return end
        local t = fs:GetText()
        if not t or t == "" or CoARU_HasCyrillic(t) then return end
        local ru = ruFor(self.unit or self.displayedUnit, t)
        if ru and ru ~= t then fs:SetText(ru) end
    end)
    hooked = true
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", install)
install()

function CoARU_NameplateStatus()
    return hooked
end
