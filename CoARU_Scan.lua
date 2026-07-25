local scanTip

local tipLeft, tipRight = {}, nil
local function getScanTip()
    if not scanTip then
        scanTip = CreateFrame("GameTooltip", "CoARUScanTip", UIParent, "GameTooltipTemplate")
        scanTip:SetFrameStrata("TOOLTIP")

        scanTip:SetOwner(UIParent, "ANCHOR_NONE")
        scanTip:Hide()
    end
    return scanTip
end

local function leftLine(i)
    local fs = tipLeft[i]
    if not fs then
        fs = _G["CoARUScanTipTextLeft" .. i]
        if fs then tipLeft[i] = fs end
    end
    return fs
end

function CoARU_CaptureSpell(id, knownDesc)
    local tip = getScanTip()

    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:ClearLines()
    tip:SetHyperlink("spell:" .. id)
    tip:Show()

    local n = tip:NumLines()
    if not n or n == 0 then tip:Hide(); return nil end

    local first = leftLine(1)
    local name = first and first:GetText()
    if not tipRight then tipRight = _G["CoARUScanTipTextRight1"] end
    local rank = tipRight and tipRight:GetText()
    local lines = {}
    for i = 2, n do
        local left = leftLine(i)
        local t = left and left:GetText()
        if t and t ~= " " then
            lines[#lines + 1] = t
        end
    end
    tip:Hide()
    if not name then return nil end

    local desc = knownDesc
    if not desc and GetSpellDescription then
        local ok, d = pcall(GetSpellDescription, id)
        if ok and d and d ~= "" then desc = d end
    end
    return name, rank, table.concat(lines, "\n"), desc
end

function CoARU_CaptureItem(id)
    local tip = getScanTip()
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:ClearLines()
    tip:SetHyperlink("item:" .. id)
    tip:Show()

    local n = tip:NumLines()
    if not n or n == 0 then tip:Hide(); return nil, nil, "empty" end

    local name = _G["CoARUScanTipTextLeft1"] and _G["CoARUScanTipTextLeft1"]:GetText()
    local lines = {}
    for i = 2, n do
        local left = _G["CoARUScanTipTextLeft" .. i]
        local t = left and left:GetText()
        if t and t:find("%S") then lines[#lines + 1] = t end
    end
    tip:Hide()
    if not name or not name:find("%S") then return nil, nil, "empty" end
    if name:find("Retrieving item information") then return name, nil, "pending" end
    return name, table.concat(lines, "\n"), "ok"
end

local function needsDump(id, text, includeAll)
    if not text or #text < 12 then return false end

    if text:find("%$@spelldesc") or text:find("@%a+:?%d*") then
        if includeAll or not CoARU_IsTranslated(id) then return true end
    end

    for line in text:gmatch("[^\n]+") do
        local plain = CoARU_StripCodes(line)
        if #plain >= 12 and not CoARU_HasCyrillic(plain) and plain:find("%a%a%a") then
            if includeAll or not CoARU_LineTranslated(id, line) then return true end
        end
    end
    return false
end

function CoARU_RecordSpell(id, includeAll, knownDesc)
    if not id then return false, "нет ID" end
    CoARU_DB.dump = CoARU_DB.dump or {}
    local name, rank, text, desc = CoARU_CaptureSpell(id, knownDesc)
    if not name then return false, "пустой тултип" end
    if not needsDump(id, text, includeAll) then return false, "нечего брать: все строки переводятся" end
    local old = CoARU_DB.dump[id]
    if old and old.x == text and old.d == desc then return false, "уже в дампе, без изменений" end
    CoARU_DB.dump[id] = { n = name, r = rank, x = text, d = desc }
    return true
end

local function resolvePlural(text)
    if not text or not text:find("|4", 1, true) then return text end
    return (text:gsub("(%d+)(%s*)|4([^:;]*):([^;]*);", function(num, sp, sing, plur)
        return num .. sp .. (tonumber(num) == 1 and sing or plur)
    end))
end

function CoARU_RecordDesc(id, desc, includeAll)
    if not id or not desc or desc == "" then return false end
    CoARU_DB.dump = CoARU_DB.dump or {}

    desc = resolvePlural(desc)
    if not needsDump(id, desc, includeAll) then return false end
    local old = CoARU_DB.dump[id]
    if old and old.x == desc then return false end
    local name = GetSpellInfo and GetSpellInfo(id) or nil
    CoARU_DB.dump[id] = { n = name, x = desc, d = desc }
    return true
end

function CoARU_CollectCAIds()
    local ids, seen, entries = {}, {}, 0
    if not (C_CharacterAdvancement and C_CharacterAdvancement.GetSpellsByClass) then
        return ids, 0
    end

    local classFile = C_Player and C_Player.GetClass and C_Player:GetClass()
        or select(2, UnitClass("player"))
    local class = CharacterAdvancementUtil and CharacterAdvancementUtil.GetClassDBCByFile
        and CharacterAdvancementUtil.GetClassDBCByFile(classFile) or classFile

    local specs = { "None" }
    if C_ClassInfo and C_ClassInfo.GetAllSpecs then
        local ok, all = pcall(C_ClassInfo.GetAllSpecs, C_ClassInfo, classFile)
        if not (ok and type(all) == "table") then
            ok, all = pcall(C_ClassInfo.GetAllSpecs, classFile)
        end
        if ok and type(all) == "table" then
            for _, s in ipairs(all) do
                if type(s) == "table" then s = s.Name or s.ID end
                if s then specs[#specs + 1] = s end
            end
        end
    end

    local function harvest(list)
        if type(list) ~= "table" then return end
        for _, entry in ipairs(list) do
            entries = entries + 1
            for _, spellId in ipairs(CoARU_EntrySpells(entry)) do
                if not seen[spellId] then
                    seen[spellId] = true
                    ids[#ids + 1] = spellId
                end
            end
        end
    end

    for _, spec in ipairs(specs) do
        local ok, list = pcall(C_CharacterAdvancement.GetSpellsByClass, class, spec, true)
        if ok then harvest(list) end
        if C_CharacterAdvancement.GetTalentsByClass then
            local ok2, list2 = pcall(C_CharacterAdvancement.GetTalentsByClass, class, spec, true)
            if ok2 then harvest(list2) end
        end
    end
    return ids, entries
end

function CoARU_EntrySpells(entry)
    local out = {}
    if type(entry) ~= "table" then return out end
    local sp = entry.Spells
    if type(sp) == "table" then
        for _, x in ipairs(sp) do
            local id = tonumber(x)
            if not id and type(x) == "table" then
                id = tonumber(x.SpellID or x.ID or x.Spell)
            end
            if id then out[#out + 1] = id end
        end
    elseif type(sp) == "string" or type(sp) == "number" then
        for d in tostring(sp):gmatch("%d+") do out[#out + 1] = tonumber(d) end
    end
    return out
end

local PROBE_IDS = { 520353, 504329, 573057, 560341, 560340, 707380 }

function CoARU_ProbeClasses()
    local api = C_CharacterAdvancement
    if not (api and api.GetAllEntries) then
        print("|cffff0000CoARU|r: C_CharacterAdvancement.GetAllEntries в этом клиенте нет. Сообщи — будем искать обход.")
        return
    end

    local ok, all = pcall(api.GetAllEntries)
    if not (ok and type(all) == "table") then
        local err = all
        ok, all = pcall(api.GetAllEntries, api)
        if not (ok and type(all) == "table") then
            print("|cffff0000CoARU|r: GetAllEntries не отдала таблицу: " .. tostring(err))
            return
        end
    end

    local ids, seen, dumped, sigs = {}, {}, {}, {}
    local byClass, byType, byFlag = {}, {}, {}
    local entries, noSpells = 0, 0

    for _, e in ipairs(all) do
        if type(e) == "table" then
            entries = entries + 1
            local cls = tostring(e.Class or "?")
            local ty = tostring(e.Type or "?")
            local fl = tonumber(e.Flags) or 0
            local spells = CoARU_EntrySpells(e)
            if #spells == 0 then noSpells = noSpells + 1 end
            byClass[cls] = (byClass[cls] or 0) + #spells
            byType[ty] = (byType[ty] or 0) + 1
            byFlag[fl] = (byFlag[fl] or 0) + 1

            if entries <= 3 then
                local ks = {}
                for k, v in pairs(e) do ks[#ks + 1] = tostring(k) .. ":" .. type(v) end
                table.sort(ks)
                sigs[#sigs + 1] = table.concat(ks, " ")
            end
            for _, id in ipairs(spells) do
                if not seen[id] then
                    seen[id] = true
                    ids[#ids + 1] = id
                end
            end
            dumped[#dumped + 1] = {
                i = tonumber(e.ID) or 0, c = cls, t = tostring(e.Tab or "?"),
                y = ty, f = fl, s = spells,
            }
        end
    end

    local hits = {}
    for _, id in ipairs(PROBE_IDS) do
        if seen[id] then hits[#hits + 1] = id end
    end

    CoARU_DB.classids = {
        ids = ids, entries = dumped, sigs = sigs,
        byClass = byClass, byType = byType, byFlag = byFlag,
        player = { class = tostring(select(2, UnitClass("player"))), name = tostring(UnitName("player")) },
    }

    local nClasses = 0
    for _ in pairs(byClass) do nClasses = nClasses + 1 end

    print(("|cffC495DDCoARU|r: GetAllEntries вернула записей |cffffd100%d|r (в файле клиента 23709), классов %d (в файле 44)."):format(
        entries, nClasses))
    print(("|cffC495DDCoARU|r: уникальных spell ID |cffffd100%d|r (в файле 21063), записей без Spells %d."):format(
        #ids, noSpells))
    if #hits > 0 then
        print(("|cff00ff00CoARU|r: маркеров-талантов %d из %d (%s) — их в файле клиента НЕТ, значит записи шире файла."):format(
            #hits, #PROBE_IDS, table.concat(hits, ", ")))
    else
        print("|cffffd100CoARU|r: маркеров-талантов ноль — похоже, записи = файл клиента. Решится диффом офлайн.")
    end
    print("|cffC495DDCoARU|r: сделай /reload и пришли SavedVariables. Вердикт считается диффом по файлу, а не на глаз.")
end

local function collectBookIds()
    local ids, seen = {}, {}
    local function addRange(offset, numSpells)
        if not (offset and numSpells) then return end
        for slot = offset + 1, offset + numSpells do
            local link = GetSpellLink and GetSpellLink(slot, BOOKTYPE_SPELL or "spell")
            local id = link and tonumber(link:match("Hspell:(%d+)"))
            if id and not seen[id] then
                seen[id] = true
                ids[#ids + 1] = id
            end
        end
    end
    local tabs = GetNumSpellTabs and GetNumSpellTabs() or 0
    for t = 1, tabs do

        local _, _, offset, numSpells, hrOffset, hrNum = GetSpellTabInfo(t)
        addRange(offset, numSpells)
        addRange(hrOffset, hrNum)
    end
    return ids
end

local scanQueue, scanPos, scanFound, scanAll = nil, 0, 0, false
local scanRanges, scanRi, scanCur, scanSeen, scanTotal = nil, 0, 0, 0, 0

local scanDeep, scanSkipped = false, 0

local scanProbe = false

local scanReal = 0

local scanGhost = 0

function CoARU_SetScanDeep(v)
    scanDeep = v and true or false
end

function CoARU_SetScanProbe(v)
    scanProbe = v and true or false
end

local scanDesc = false
function CoARU_SetScanDesc(v)
    scanDesc = v and true or false
end
local nextTick = 0

local scanTick, scanBatch, scanBudget = 0.05, 50, nil
local scanStart = 0

local scanMin = 0

local scanMax = 0

local function nextId()
    if scanQueue then
        scanPos = scanPos + 1
        if scanPos > #scanQueue then return nil end
        return scanQueue[scanPos]
    end
    if not scanRanges then return nil end
    while true do
        local r = scanRanges[scanRi]
        if not r then return nil end

        if r[2] < scanMin then
            scanRi = scanRi + 1
            local nr = scanRanges[scanRi]
            if not nr then return nil end
            scanCur = math.max(nr[1], scanMin)
        elseif scanCur <= r[2] then
            if scanMax > 0 and scanCur > scanMax then return nil end
            local id = scanCur
            scanCur = scanCur + 1
            return id
        else
            scanRi = scanRi + 1
            local nr = scanRanges[scanRi]
            if not nr then return nil end
            scanCur = math.max(nr[1], scanMin)
        end
    end
end

local scanFrame = CreateFrame("Frame")
scanFrame:Hide()
local elapsed = 0
scanFrame:SetScript("OnUpdate", function(self, delta)
    elapsed = elapsed + delta
    if elapsed < scanTick then return end
    elapsed = 0

    local t0 = (scanBudget and debugprofilestop) and debugprofilestop() or nil
    local n = 0
    while true do
        local id = nextId()
        if not id then
            self:Hide()
            local total = 0
            for _ in pairs(CoARU_DB.dump or {}) do total = total + 1 end
            local secs = math.max(1, GetTime() - scanStart)
            print(("|cffC495DDCoARU|r: скан завершен за %d:%02d. Просмотрено %d (%d ID/сек), новых непереведенных: %d, всего в дампе: %d."):format(
                math.floor(secs / 60), math.floor(secs % 60), scanSeen,
                math.floor(scanSeen / secs), scanFound, total))

            if scanSkipped > 0 then
                print(("|cffC495DDCoARU|r: пропущено без тултипа (нет в клиентском DBC): %d. Полный проход: /coaru scanall deep"):format(scanSkipped))
            end

            if scanDeep then
                print(("|cffC495DDCoARU|r: ПРИЗРАКОВ (нет в клиентском DBC, но тултип есть): %d. Если ноль, дешевый отсев ничего не теряет."):format(scanGhost))
            end
            if scanReal > 0 then
                print(("|cffC495DDCoARU|r: спеллов с тултипом: %d, из них с непереведенными строками: %d. ПОКРЫТИЕ ПО ЖИВОМУ ТЕКСТУ: %.1f%%"):format(
                    scanReal, scanFound, 100 * (scanReal - scanFound) / scanReal))
            end
            print("|cffC495DDCoARU|r: сделай /reload (или выйди из игры), чтобы дамп записался в SavedVariables.")
            return
        end

        if scanDesc then

            local d
            if GetSpellDescription then
                local ok, r = pcall(GetSpellDescription, id)
                if ok and r and r ~= "" then d = r end
            end
            if d then
                scanReal = scanReal + 1
                if CoARU_RecordDesc(id, d, scanAll) then scanFound = scanFound + 1 end
            end
        else
            local desc, known = nil, true
            if scanProbe and not scanDeep then
                if GetSpellDescription then
                    local ok, d = pcall(GetSpellDescription, id)
                    if ok and d and d ~= "" then desc = d end
                end
                known = desc ~= nil or (not GetSpellInfo) or GetSpellInfo(id) ~= nil
            end
            if known then
                local ok, why = CoARU_RecordSpell(id, scanAll, desc)
                local hadTip = ok or why ~= "пустой тултип"
                if ok then scanFound = scanFound + 1 end
                if hadTip then
                    scanReal = scanReal + 1
                    if scanDeep and GetSpellInfo and GetSpellInfo(id) == nil then
                        scanGhost = scanGhost + 1
                    end
                end
            else
                scanSkipped = scanSkipped + 1
            end
        end
        scanSeen = scanSeen + 1
        n = n + 1
        if t0 then

            if n % 64 == 0 then
                local dt = debugprofilestop() - t0
                if dt < 0 or dt >= scanBudget then break end
            end
        elseif n >= scanBatch then
            break
        end
    end

    if scanTotal > 0 and scanSeen >= nextTick then
        nextTick = nextTick + math.floor(scanTotal / 20)
        local secs = math.max(1, GetTime() - scanStart)
        local rate = math.max(1, scanSeen / secs)
        print(("|cffC495DDCoARU|r: скан %d%%  (%d из %d, найдено %d, %d ID/сек, осталось ~%d мин)"):format(
            math.floor(scanSeen * 100 / scanTotal), scanSeen, scanTotal, scanFound,
            math.floor(rate), math.ceil((scanTotal - scanSeen) / rate / 60)))
    end
end)

local function beginScan(includeAll, total, fastMs, minId, maxId)
    scanFound, scanSeen, scanAll = 0, 0, includeAll or false
    scanSkipped, scanReal, scanGhost = 0, 0, 0
    scanMin = minId or 0
    scanMax = maxId or 0
    scanTotal = total or 0
    nextTick = math.floor((total or 0) / 20)
    scanStart = GetTime()
    if fastMs then
        scanTick, scanBudget = 0, fastMs
        scanBatch = 2000
    else
        scanTick, scanBudget, scanBatch = 0.05, nil, 50
    end
    scanFrame:Show()
end

function CoARU_StartScan(ids, includeAll)
    if #ids == 0 then
        print("|cffC495DDCoARU|r: список спеллов для сканирования пуст. Пришли вывод /coaru probe.")
        return
    end
    scanQueue, scanPos = ids, 0
    scanRanges = nil
    beginScan(includeAll, #ids)
    print(("|cffC495DDCoARU|r: сканирую %d спеллов..."):format(#ids))
end

function CoARU_StartScanRanges(ranges, includeAll, fastMs, minId, maxId)
    if type(ranges) ~= "table" or #ranges == 0 then
        print("|cffC495DDCoARU|r: нет CoARU_ScanRanges. Перегенерируй tools/Build-ScanIds.py.")
        return
    end
    minId = minId or 0
    local hiCap = (maxId and maxId > 0) and maxId or math.huge

    local total, startRi, startCur = 0, nil, nil
    for i, r in ipairs(ranges) do
        local lo = math.max(r[1], minId)
        local hi = math.min(r[2], hiCap)
        if lo <= hi then
            total = total + (hi - lo + 1)
            if not startRi then startRi, startCur = i, lo end
        end
    end
    if total == 0 then
        print(("|cffC495DDCoARU|r: в окне ID [%d, %s] сканировать нечего."):format(
            minId, (maxId and maxId > 0) and tostring(maxId) or "∞"))
        return
    end
    scanQueue = nil
    scanRanges, scanRi, scanCur = ranges, startRi, startCur
    beginScan(includeAll, total, fastMs, minId, maxId)
    local thr = minId > 0 and (", только ID >= " .. minId) or ""
    if maxId and maxId > 0 then thr = thr .. " и <= " .. maxId end
    if fastMs then
        print(("|cffC495DDCoARU|r: сканирую %d ID%s, |cffff0000БЫСТРЫЙ РЕЖИМ|r (%d мс на кадр)."):format(
            total, thr, fastMs))
        print("|cffC495DDCoARU|r: играть нельзя, картинка будет дергаться. Скорость покажет первый отчет о прогрессе.")
    else
        print(("|cffC495DDCoARU|r: сканирую %d ID%s (~%d мин). Можно играть, клиент не виснет."):format(
            total, thr, math.floor(total / 60000) + 1))
        print("|cffC495DDCoARU|r: если не играешь — |cffffd100/coaru scanall fast|r будет заметно быстрее.")
    end
end

function CoARU_ScanBook(includeAll)

    local ids, entries = CoARU_CollectCAIds()
    if #ids > 0 then
        print(("|cffC495DDCoARU|r: Character Advancement: %d записей, %d уникальных спеллов."):format(entries, #ids))
    else
        ids = collectBookIds()
        print(("|cffC495DDCoARU|r: CA API недоступен, беру книгу заклинаний: %d спеллов."):format(#ids))
    end
    CoARU_StartScan(ids, includeAll)
end

function CoARU_Probe()
    local out = {}
    local function chk(name)
        local v = _G[name]
        if v ~= nil then out[#out + 1] = name .. " = " .. type(v) end
    end
    for _, name in ipairs({
        "C_Spellbook", "C_SpellBook", "C_Collections", "C_CharacterAdvancement",
        "C_Vault", "C_MysticEnchant", "CollectionsFrame", "AscensionSpellbookFrame",
        "AscensionCollectionsFrame", "SpellBookFrame", "CoASpellbookFrame",
        "GetSpellLink", "GetNumSpellTabs", "GetSpellTabInfo", "GetSpellBookItemInfo",
        "GetSpellBookItemName", "GetSpellInfo", "GetSpellBaseCooldown",
    }) do chk(name) end

    local hits, cap = {}, 0
    for k, v in pairs(_G) do
        if type(k) == "string" and (k:find("Spellbook") or k:find("SpellBook") or k:find("Collection")) then
            local ty = type(v)
            if ty == "table" or ty == "function" then
                hits[#hits + 1] = k .. ":" .. ty
                cap = cap + 1
                if cap >= 80 then break end
            end
        end
    end
    table.sort(hits)

    local tabs = GetNumSpellTabs and GetNumSpellTabs() or 0
    local slots = 0
    for t = 1, tabs do
        local _, _, offset, numSpells = GetSpellTabInfo(t)
        slots = slots + numSpells
    end
    out[#out + 1] = ("spellTabs=%d totalSlots=%d"):format(tabs, slots)
    out[#out + 1] = "build=" .. table.concat({ GetBuildInfo() }, "|")
    out[#out + 1] = "class=" .. (select(2, UnitClass("player")) or "?") .. " locale=" .. GetLocale()

    CoARU_DB.probe = { info = out, frames = hits }
    for _, line in ipairs(out) do print("|cffC495DDCoARU probe|r: " .. line) end
    print(("|cffC495DDCoARU probe|r: найдено %d фреймов/таблиц Spellbook/Collection (в CoARU_DB.probe.frames, попадут в SavedVariables после /reload)."):format(#hits))
end
