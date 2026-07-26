CoARU_THANKS = {

    donate = {
        "Zazer",
        "nikonavr",
    },

    data = {
        "Vivi",
        "Seesky",
        "FinnickJas",
        "Mobius",
        "Razered",
        "LDS31",
        "Leitz",
        "Даниил",
        "Volpik",
        "Billy Butcher",
        "Chuffa",
        "Renzy",
        "Kronk",
        "Leor",
        "Кабан",
        "Анарх",
        "Tankred",
    },

    bugs = {
        "FinnickJas",
        "Leitz",
        "Даниил",
        "Renzy",
        "Razered",
        "Leor",
        "Sanek",
        "LDS31",
        "Volpik",
        "twista",
        "yхеррu",
        "Seesky",
        "Кабан",
        "Chuffa",
        "Tankred",
        "parallax_xxx",
    },
}

CoARU_THANKS_ANON = 4

function CoARU_ThanksCount()
    local seen, n = {}, 0
    for _, list in pairs(CoARU_THANKS or {}) do
        for i = 1, #list do
            if not seen[list[i]] then
                seen[list[i]] = true
                n = n + 1
            end
        end
    end
    return n + (tonumber(CoARU_THANKS_ANON) or 0), n
end

function CoARU_ThanksFor(name)
    if not name or name == "" then return nil end
    local low = name:lower()
    for _, kind in ipairs({ "donate", "data", "bugs" }) do
        local list = (CoARU_THANKS or {})[kind] or {}
        for i = 1, #list do
            if list[i]:lower() == low then return kind end
        end
    end
    return nil
end
