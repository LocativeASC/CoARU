local RU  = CoARU_UNIT_RU  or {}
local SUB = CoARU_UNIT_SUB or {}
local N2R = CoARU_UNIT_N2R or {}

local function npcID(guid)
    if not guid then return nil end
    if guid:find("-", 1, true) then
        local ut, rest = strsplit("-", guid, 2)
        if ut == "Creature" or ut == "Vehicle" or ut == "Pet" then
            return tonumber((select(5, strsplit("-", rest))))
        end
    elseif guid:sub(1, 2) == "0x" then
        local hex = guid:sub(3)
        if #hex == 16 and hex:match("^F1[345]") then
            return tonumber(hex:sub(5, 10), 16)
        end
    end
    return nil
end

local hasCyr = CoARU_HasCyrillic or function(s) return s and s:find("[Ѐ-ӿ]") end

local function tipUnit(tip)
    local _, unit = tip:GetUnit()
    if not unit then return end
    local id = npcID(UnitGUID and UnitGUID(unit))
    if not id then return end
    local name = tip:GetName()
    local l1 = _G[name .. "TextLeft1"]
    local t1 = l1 and l1:GetText()
    if t1 and RU[id] and not hasCyr(t1) then l1:SetText(RU[id]) end
    if SUB[id] then
        local l2 = _G[name .. "TextLeft2"]
        local t2 = l2 and l2:GetText()

        if t2 and not hasCyr(t2) and not t2:match("^Level") and not t2:match("^%-?Уровень") then
            l2:SetText(SUB[id])
        end
    end
end
if GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetUnit", tipUnit)
end

local function unitFrame(unit, fs)
    if not unit or (UnitExists and not UnitExists(unit)) then return end
    local id = npcID(UnitGUID and UnitGUID(unit))
    if not id then return end
    local ru = RU[id]
    if not ru then return end
    local en = UnitName and UnitName(unit)
    if en and not N2R[en] then N2R[en] = ru end
    if fs and fs.GetText then
        local t = fs:GetText()
        if t and t ~= "" and not hasCyr(t) then fs:SetText(ru) end
    end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_TARGET_CHANGED")
ev:RegisterEvent("PLAYER_FOCUS_CHANGED")
ev:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
ev:SetScript("OnEvent", function(_, e)
    if e == "UPDATE_MOUSEOVER_UNIT" then unitFrame("mouseover", nil)
    elseif e == "PLAYER_FOCUS_CHANGED" then unitFrame("focus", _G.FocusFrameTextureFrameName)
    else unitFrame("target", _G.TargetFrameTextureFrameName) end
end)

local acc = 0
local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function(_, e)
    acc = acc + e
    if acc < 0.3 then return end
    acc = 0
    unitFrame("target", _G.TargetFrameTextureFrameName)
    unitFrame("focus",  _G.FocusFrameTextureFrameName)
    unitFrame("targettarget", _G.TargetFrameToTTextureFrameName)

end)

function CoARU_UnitN2R(en) return N2R[en] end

function CoARU_UnitStatus()
    local a, b, c = 0, 0, 0
    for _ in pairs(RU) do a = a + 1 end
    for _ in pairs(SUB) do b = b + 1 end
    for _ in pairs(N2R) do c = c + 1 end
    return a, b, c
end
