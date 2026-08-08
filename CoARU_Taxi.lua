local function zoneRU(name)
    if not name or name == "" then return nil end
    local Z = CoARU_ZONE
    if not Z then return nil end

    return Z[name] or Z["The " .. name] or Z[name .. " City"]
end

local function xlateNode(text)
    if not text or text == "" then return nil end
    if CoARU_ModOn and not CoARU_ModOn("zones") then return nil end
    if CoARU_HasCyrillic and CoARU_HasCyrillic(text) then return nil end
    local out, n = {}, 0
    for part in (text .. ","):gmatch("%s*(.-)%s*,") do
        if part == "" then return nil end
        local ru = zoneRU(part)
        if not ru then return nil end
        n = n + 1
        out[n] = ru
    end
    if n == 0 then return nil end
    return table.concat(out, ", ")
end

CoARU_TaxiNodeRU = xlateNode

do
    local orig = TaxiNodeName
    if orig then
        function TaxiNodeName(i)
            local text = orig(i)
            local ok, ru = pcall(xlateNode, text)
            if ok and ru then return ru end
            return text
        end
    end
end
