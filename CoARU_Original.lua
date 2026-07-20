local ORIG = setmetatable({}, { __mode = "k" })

CoARU_OriginalMode = false

local TIPS = { "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2",
               "WorldMapTooltip" }

local MOD_CHECK = {
    ALT   = function() return IsAltKeyDown() end,
    CTRL  = function() return IsControlKeyDown() end,
    SHIFT = function() return IsShiftKeyDown() end,
    NONE  = function() return false end,
}

local DEFAULT_MOD = "ALT"

local function opts()
    CoARU_DB = CoARU_DB or {}
    CoARU_DB.opts = CoARU_DB.opts or {}
    return CoARU_DB.opts
end

function CoARU_OriginalMod()
    local m = opts().origMod
    return MOD_CHECK[m] and m or DEFAULT_MOD
end

local function wantOriginal()
    local held = MOD_CHECK[CoARU_OriginalMod()]() and true or false
    local sticky = opts().origSticky and true or false
    return held ~= sticky
end

local function grabColor(fs)
    if not fs.GetTextColor then return nil end
    local ok, r, g, b, a = pcall(fs.GetTextColor, fs)
    if not ok or not r then return nil end
    return { r, g, b, a or 1 }
end

function CoARU_ReapplyColor(fs)
    local rec = fs and ORIG[fs]
    local c = rec and rec.rgb
    if not (c and fs.SetTextColor) then return end

    local ok, cur = pcall(fs.GetText, fs)
    if not ok or (cur ~= rec.ru and cur ~= rec.en) then return end
    pcall(fs.SetTextColor, fs, c[1], c[2], c[3], c[4])
end

function CoARU_SetTranslated(fs, en, ru)
    if not fs then return end
    local rgb = grabColor(fs)
    ORIG[fs] = { en = en, ru = ru, rgb = rgb }
    fs:SetText(CoARU_OriginalMode and en or ru)
    CoARU_ReapplyColor(fs)
end

local function swapOne(fs)
    if not fs then return false end
    local rec = ORIG[fs]
    if not rec then return false end
    local want  = CoARU_OriginalMode and rec.en or rec.ru
    local other = CoARU_OriginalMode and rec.ru or rec.en
    if want == other then return false end
    local ok, cur = pcall(fs.GetText, fs)
    if not ok or cur ~= other then return false end
    fs:SetText(want)
    return true
end

local function swapTip(tip)
    local name = tip.GetName and tip:GetName()
    if not name then return end
    local changed = false
    local n = tip.NumLines and tip:NumLines() or 0
    for i = 1, n do
        if swapOne(_G[name .. "TextLeft" .. i]) then changed = true end
        if swapOne(_G[name .. "TextRight" .. i]) then changed = true end
    end

    for i = 1, 4 do
        if swapOne(_G[name .. "MoneyFrame" .. i .. "PrefixText"]) then changed = true end
    end
    if changed and tip.Show then tip:Show() end
end

local function applyMode()
    for _, n in ipairs(TIPS) do
        local tip = _G[n]
        if tip and tip.IsShown and tip:IsShown() then swapTip(tip) end
    end
end

local watcher = CreateFrame("Frame")
local acc, last = 0, nil
watcher:SetScript("OnUpdate", function(self, elapsed)
    acc = acc + elapsed
    if acc < 0.05 then return end
    acc = 0
    local want = wantOriginal()
    if want == last then return end
    last = want
    CoARU_OriginalMode = want
    applyMode()
end)

function CoARU_OriginalStatus()
    local n = 0
    for _ in pairs(ORIG) do n = n + 1 end
    return n, CoARU_OriginalMod(), opts().origSticky and true or false
end

function CoARU_SetOriginalMod(word)
    local key = (word or ""):upper()
    if key == "OFF" then key = "NONE" end
    if not MOD_CHECK[key] then return nil end
    opts().origMod = key
    last = nil
    return key
end

function CoARU_ToggleOriginalSticky()
    local o = opts()
    o.origSticky = not o.origSticky
    last = nil
    return o.origSticky
end
