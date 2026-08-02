local WARNED = {}

function CoARU_CacheRu()
    return CoARU_DB and CoARU_DB.opts and CoARU_DB.opts.cacheRu
end

local function sample(unit)
    if not UnitExists or not UnitExists(unit) then return end
    if UnitIsPlayer and UnitIsPlayer(unit) then return end
    local n = UnitName and UnitName(unit)
    if not n or n == "" then return end
    if not CoARU_HasCyrillic then return end

    if CoARU_HasCyrillic(n) then
        if not CoARU_CacheRu() then
            CoARU_DB.opts = CoARU_DB.opts or {}
            CoARU_DB.opts.cacheRu = true
        end
    end
end

local probe = CreateFrame("Frame")
probe:RegisterEvent("PLAYER_TARGET_CHANGED")
probe:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
probe:SetScript("OnEvent", function(_, ev)
    sample(ev == "PLAYER_TARGET_CHANGED" and "target" or "mouseover")
end)

function CoARU_ModBlocked(key)
    if (key == "names" or key == "nameplates") and CoARU_CacheRu() then

        return "имена стоят из пропатченного кэша, тумблер их не вернет"
    end
    return nil
end

function CoARU_RuMaps()
    return CoARU_DB and CoARU_DB.opts and CoARU_DB.opts.ruMaps
end

function CoARU_SetRuMaps(v)
    if not CoARU_DB then return end
    CoARU_DB.opts = CoARU_DB.opts or {}
    CoARU_DB.opts.ruMaps = v
end

function CoARU_Inconsistencies()
    local out = {}
    if not CoARU_ModOn then return out end
    local zones = CoARU_ModOn("zones")
    local maps = CoARU_RuMaps()

    if maps == true and not zones then
        out[#out + 1] = {
            key = "zones-vs-map",
            text = "У вас стоят русские карты мира, но перевод названий зон выключен.\n"
                .. "В заданиях зоны будут английскими, а на карте русскими: искать по названию неудобно.",
            fixLabel = "Включить зоны",
            fix = function() CoARU_SetMod("zones", true) end,
        }
    elseif maps == false and zones then
        out[#out + 1] = {
            key = "map-vs-zones",
            text = "В заданиях зоны переводятся, а карты мира у вас английские.\n"
                .. "Название из задания на карте не найдется. Поставьте русские карты\n"
                .. "(архив CoARU-maps-ru.zip) или выключите перевод зон.",
            fixLabel = "Выключить зоны",
            fix = function() CoARU_SetMod("zones", false) end,
        }
    end

    if not CoARU_ModOn("names") then
        out[#out + 1] = {
            key = "names-vs-cache",
            text = "Имена существ в тултипе выключены.\n"
                .. "Надпись под самим НПС в мире этой галке не подчиняется: ее рисует движок\n"
                .. "из кэша, и если вы запускали «Русские имена.bat», она останется русской.\n"
                .. "Вернуть английскую — «Английские имена обратно.bat» в папке CoARU-Cache.",
            fixLabel = nil,
        }
    end
    return out
end

function CoARU_WarnInconsistent(force)
    local list = CoARU_Inconsistencies()
    for i = 1, #list do
        local w = list[i]
        if force or not WARNED[w.key] then
            WARNED[w.key] = true
            if CoARU_SkinAsk then
                CoARU_SkinAsk({
                    text = "Настройки расходятся между собой.\n\n" .. w.text,
                    accept = w.fixLabel or "Понятно",
                    cancel = w.fixLabel and "Оставить как есть" or nil,
                    OnAccept = function() if w.fix then w.fix() end end,
                })
            elseif StaticPopupDialogs and StaticPopup_Show then
                local name = "COARU_INCONSISTENT_" .. w.key:upper():gsub("%-", "_")
                StaticPopupDialogs[name] = {
                    text = "CoARU: настройки расходятся между собой.\n\n" .. w.text,
                    button1 = w.fixLabel or "Понятно",
                    button2 = w.fixLabel and "Оставить как есть" or nil,
                    OnAccept = function() if w.fix then w.fix() end end,
                    timeout = 0, whileDead = 1, hideOnEscape = 1, preferredIndex = 3,
                }
                StaticPopup_Show(name)
            end
            return w.key
        end
    end
    return nil
end

function CoARU_AskRuMaps()
    if CoARU_RuMaps() ~= nil then return false end
    if not CoARU_ModOn or not CoARU_ModOn("zones") then return false end
    local askText = "У вас установлены русские карты мира?\n\n"
        .. "Это отдельный архив, аддон их не видит и определить не может.\n"
        .. "Ответ нужен, чтобы предупредить, если названия зон в заданиях\n"
        .. "и на карте разойдутся."
    if CoARU_SkinAsk then
        CoARU_SkinAsk({
            text = askText,
            accept = "Да, стоят",
            cancel = "Нет, карты английские",
            OnAccept = function()
                CoARU_SetRuMaps(true)
                CoARU_WarnInconsistent()
            end,
            OnCancel = function()
                CoARU_SetRuMaps(false)
                CoARU_WarnInconsistent()
            end,
        })
        return true
    end
    if not StaticPopupDialogs or not StaticPopup_Show then return false end
    StaticPopupDialogs["COARU_ASK_RUMAPS"] = {
        text = "CoARU: у вас установлены русские карты мира?\n\n"
            .. "Это отдельный архив, аддон их не видит и определить не может.\n"
            .. "Ответ нужен, чтобы предупредить, если названия зон в заданиях\n"
            .. "и на карте разойдутся.",
        button1 = "Да, стоят",
        button2 = "Нет, карты английские",
        OnAccept = function()
            CoARU_SetRuMaps(true)
            CoARU_WarnInconsistent()
        end,
        OnCancel = function()
            CoARU_SetRuMaps(false)
            CoARU_WarnInconsistent()
        end,
        timeout = 0, whileDead = 1, hideOnEscape = 0, preferredIndex = 3,
    }
    StaticPopup_Show("COARU_ASK_RUMAPS")
    return true
end
