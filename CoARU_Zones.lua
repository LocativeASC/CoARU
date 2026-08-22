local ZONE = CoARU_ZONE or {}

ZONE["Eastern Kingdoms"] = "Восточные королевства"
ZONE["Kalimdor"]         = "Калимдор"
ZONE["Outland"]          = "Запределье"
ZONE["Northrend"]        = "Нордскол"

local STATUS = {
    ["Horde Territory"]     = "Территория Орды",
    ["Alliance Territory"]  = "Территория Альянса",
    ["Contested Territory"] = "Спорная территория",
    ["Combat Zone"]         = "Зона боя",
    ["Sanctuary"]           = "Святилище",
}

local NAMES = {
    "MinimapZoneText",
    "ZoneTextString",
    "SubZoneTextString",
    "WorldMapFrameAreaLabel",
    "WorldMapContinentDropDownText",
    "WorldMapZoneDropDownText",
}

local function zoneAllowed(name)
    local inst = CoARU_ZONE_INST and CoARU_ZONE_INST[name]
    if inst then return CoARU_ModOn("dungeons") end
    return CoARU_ModOn("zones")
end

local function xlate(fs)
    if not fs or not fs.GetText then return end
    local t = fs:GetText()
    if not t or t == "" then return end
    if not zoneAllowed(t) then return end
    local ru = ZONE[t]
    if ru and ru ~= t then
        fs:SetText(ru)
    end
end

local function xlateStatus(fs)
    if not CoARU_ModOn("zones") then return end
    if not fs or not fs.GetText then return end
    local t = fs:GetText()
    if not t or t == "" then return end
    local new = t
    for en, ru in pairs(STATUS) do
        new = new:gsub(en, ru)
    end
    if new ~= t then fs:SetText(new) end
end

local hookedLabel = false
local function hookAreaLabel()
    if hookedLabel then return end
    local lbl = _G.WorldMapFrameAreaLabel
    if lbl and lbl.SetText then
        hookedLabel = true
        local busy = false
        hooksecurefunc(lbl, "SetText", function(self, text)
            if busy or not text or text == "" then return end
            if not zoneAllowed(text) then return end
            local ru = ZONE[text]

            if not ru and CoARU_ZoneLineRU then
                ru = CoARU_ZoneLineRU(text)
            end

            if not ru then
                local head = text:match("^([^|(]+)")
                if head then
                    local bare = head:match("^%s*(.-)%s*$")
                    local hit = bare ~= "" and ZONE[bare]
                    if hit and hit ~= bare and zoneAllowed(bare) then
                        ru = hit .. text:sub(#head + 1)
                        if head:sub(-1) == " " then ru = hit .. " " .. text:sub(#head + 1) end
                    end
                end
            end
            if ru and ru ~= text then
                busy = true
                self:SetText(ru)
                busy = false
            end
        end)
    end
end

local acc = 0
local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + elapsed
    if acc < 0.4 then return end
    acc = 0
    hookAreaLabel()
    for i = 1, #NAMES do
        xlate(_G[NAMES[i]])
    end
    xlateStatus(_G.PVPInfoTextString)
end)

driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:SetScript("OnEvent", function()
    for i = 1, #NAMES do xlate(_G[NAMES[i]]) end
    xlateStatus(_G.PVPInfoTextString)
end)

CoARU_HookAreaLabelForTest = hookAreaLabel

function CoARU_ZoneProbe()
    local out = {}
    local function walk(f, path, depth)
        if not f or depth > 7 then return end
        if f.GetRegions then
            local regs = { f:GetRegions() }
            for _, r in ipairs(regs) do
                if r and r.GetObjectType and r:GetObjectType() == "FontString" then
                    local t = r:GetText()
                    if t and t ~= "" then
                        out[#out + 1] = (r.GetName and r:GetName() or (path .. "?")) .. " = " .. t
                    end
                end
            end
        end
        if f.GetChildren then
            local ch = { f:GetChildren() }
            for i, c in ipairs(ch) do walk(c, path .. "/" .. i, depth + 1) end
        end
    end
    if WorldMapFrame then walk(WorldMapFrame, "WMF", 0) end
    if WorldMapDetailFrame then walk(WorldMapDetailFrame, "WMD", 0) end
    for _, n in ipairs({ "WorldMapFrameAreaLabel", "WorldMapFrameAreaDescription",
                         "WorldMapZoneMinimapDropDown", "WorldMapFrameTitle" }) do
        local g = _G[n]
        if g and g.GetText then out[#out + 1] = "G:" .. n .. " = " .. (g:GetText() or "nil") end
    end

    if CoARU_DB then
        CoARU_DB.zoneprobe = {}
        for i = 1, #out do
            CoARU_DB.zoneprobe[i] = (out[i]:gsub("|", "||"))
        end
    end
    return out
end

function CoARU_ZoneStatus()
    local n = 0
    for _ in pairs(ZONE) do n = n + 1 end
    return n, n > 0
end
