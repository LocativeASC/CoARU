local PREFIX = "|cffC495DDCoARU|r: "
local function msg(text) print(PREFIX .. text) end

CoARU_DB = CoARU_DB or {}

CoARU_DB.ver = (GetAddOnMetadata and GetAddOnMetadata("CoARU", "Version")) or "?"
CoARU_DB.verat = (date and date("%d.%m.%Y %H:%M")) or nil

local function unmask(s)
    local out = {}
    for i = 1, #s do out[i] = string.char((s:byte(i) - 90) % 256) end
    return table.concat(out)
end

local DONATE_URL = unmask("\194\206\206\202\205\148\137\137\190\187\198\195\200\197\136\206\201\137\198\201\189\187\206\195\208\191\187\205\189")

CoARU_GITHUB_URL = unmask("\194\206\206\202\205\148\137\137\193\195\206\194\207\188\136\189\201\199\137\166\201\189\187\206\195\208\191\155\173\157\137\157\201\155\172\175")

CoARU_DISCORD_URL = unmask("\194\206\206\202\205\148\137\137\190\195\205\189\201\204\190\136\193\193\137\146\204\211\178\207\168\180\199\145\165")

local UNOFFICIAL = "|cffff4040В этой сборке CoARU подменены ссылки. Она НЕ официальная.|r"
local function official(kind, url)
    if CoARU_LinkOK and CoARU_LinkOK(kind, url) then return url end
    return nil
end
local DONATE_OK = official("donate", DONATE_URL)
local GITHUB_OK = official("github", CoARU_GITHUB_URL)

CoARU_DISCORD_OK = official("discord", CoARU_DISCORD_URL)

CoARU_UNOFFICIAL = not (DONATE_OK and GITHUB_OK)

local function whereOriginal()
    if GITHUB_OK then return "Оригинал: |cffffd100" .. GITHUB_OK .. "|r" end
    return "Оригинал ищите у автора аддона (Locative, учетная запись LocativeASC)."
end

local DONATE_TEXT = DONATE_OK or UNOFFICIAL
local GITHUB_TEXT = GITHUB_OK or UNOFFICIAL

local DONATE_LINK = "|cffffd100|Hcoaru:donate|h[/coaru donate]|h|r"

local ACCENT = { 0.77, 0.58, 0.87 }

local ACCENT_LIGHT = { 0.88, 0.76, 0.96 }

local function groupNum(n)
    local s, out, c = tostring(n), "", 0
    for i = #s, 1, -1 do
        out = s:sub(i, i) .. out
        c = c + 1
        if c % 3 == 0 and i > 1 then out = " " .. out end
    end
    return out
end

local nLines
local function countLines()
    if nLines then return nLines end
    local single = { "CoARU_LOC_RU", "CoARU_QUEST", "CoARU_SPELL_NAME_RU", "CoARU_UNIT_SUB",
        "CoARU_ItemDesc", "CoARU_ZONE", "CoARU_TUT", "CoARU_ASCUI", "CoARU_ItemTipRU",
        "CoARU_ErrorsRU", "CoARU_EMOTE", "CoARU_TITLE_PRE", "CoARU_ITEM_SUFFIX_TEXT" }

    local pairsOfMaps = { { "CoARU_ItemNameEN", "CoARU_ItemName" },
        { "CoARU_UNIT_RU", "CoARU_UNIT_N2R" } }
    local function size(name)
        local t = _G[name]
        if type(t) ~= "table" then return 0 end
        local n = 0
        for _ in pairs(t) do n = n + 1 end
        return n
    end
    local total = 0
    for _, name in ipairs(single) do total = total + size(name) end
    for _, two in ipairs(pairsOfMaps) do
        local a, b = size(two[1]), size(two[2])
        total = total + (a > b and a or b)
    end
    nLines = total
    return nLines
end
CoARU_CountLines = countLines

local function runStatusReport()
    local fn = SlashCmdList and SlashCmdList["COARU"]
    if fn then fn("status") end
end

local function styledClose(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(20)
    b:SetHeight(20)
    b:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    local function idle(self)
        self:SetBackdropColor(0.13, 0.13, 0.16, 1)
        self:SetBackdropBorderColor(ACCENT[1] * 0.5, ACCENT[2] * 0.5, ACCENT[3] * 0.5, 1)
    end
    idle(b)

    local mark = b:CreateTexture(nil, "OVERLAY")
    local loaded = mark:SetTexture("Interface\\AddOns\\CoARU\\Textures\\close.tga")
    mark:SetWidth(10)
    mark:SetHeight(10)
    mark:SetPoint("CENTER", 0, 0)
    mark:SetVertexColor(0.8, 0.8, 0.85, 1)

    local fs
    if loaded == false then
        mark:Hide()
        fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("CENTER", 1, 0)
        fs:SetText("\195\151")
        fs:SetTextColor(0.8, 0.8, 0.85)
    end

    local function paint(r, g, bb)
        if fs then fs:SetTextColor(r, g, bb) else mark:SetVertexColor(r, g, bb, 1) end
    end

    b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.45, 0.12, 0.12, 1)
        self:SetBackdropBorderColor(0.9, 0.3, 0.3, 1)
        paint(1, 1, 1)
    end)
    b:SetScript("OnLeave", function(self)
        idle(self)
        paint(0.8, 0.8, 0.85)
    end)
    return b
end

local function makePanel(name, strata, w, h, titleText, subText, showAuthor)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetFrameStrata(strata)
    f:SetToplevel(true)
    f:SetWidth(w)
    f:SetHeight(h)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0.05, 0.05, 0.07, 0.97)
    f:SetBackdropBorderColor(ACCENT[1] * 0.55, ACCENT[2] * 0.55, ACCENT[3] * 0.55, 1)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    local HEAD_H = 65
    local head, headLine
    if CoARU_SkinFrame9 and CoARU_SKIN and CoARU_SKIN.layer then
        CoARU_SkinFrame9(f, CoARU_SKIN.layer.window)
        head = CoARU_SkinGradient(f, "ARTWORK", ACCENT[1], ACCENT[2], ACCENT[3], 0.16, 0, true)
        head:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
        head:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
        head:SetHeight(HEAD_H)
    else

        head = f:CreateTexture(nil, "ARTWORK")
        head:SetTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.13)
        head:SetPoint("TOPLEFT", 5, -5)
        head:SetPoint("TOPRIGHT", -5, -5)
        head:SetHeight(HEAD_H - 7)
    end

    headLine = f:CreateTexture(nil, "OVERLAY")
    headLine:SetTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.30)
    headLine:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -HEAD_H)
    headLine:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -HEAD_H)
    headLine:SetHeight(1)
    f.coaruHead, f.coaruHeadLine = head, headLine

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 22, -16)
    title:SetText(titleText)
    title:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])

    if CoARU_SkinFont then CoARU_SkinFont(title, 20, nil, true) end

    local verStr = (GetAddOnMetadata and GetAddOnMetadata("CoARU", "Version")) or "?"
    local verFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    verFS:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 8, 2)
    verFS:SetText("v" .. verStr)
    verFS:SetTextColor(0.62, 0.62, 0.68)

    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -3)
    sub:SetText(subText)
    sub:SetTextColor(0.76, 0.76, 0.82)

    local x = styledClose(f)
    x:SetPoint("TOPRIGHT", -8, -8)
    x:SetScript("OnClick", function() f:Hide() end)

    if showAuthor then
        local author = (GetAddOnMetadata and GetAddOnMetadata("CoARU", "Author")) or "Locative"
        local authFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        authFS:SetPoint("BOTTOMLEFT", verFS, "BOTTOMRIGHT", 10, 0)
        authFS:SetText("автор |cffC495DD" .. author .. "|r")
        authFS:SetTextColor(0.6, 0.6, 0.66)
    end

    function f:Divider(y)
        local d = self:CreateTexture(nil, "ARTWORK")
        d:SetTexture(1, 1, 1, 0.07)
        d:SetPoint("TOPLEFT", 22, y)
        d:SetPoint("TOPRIGHT", -22, y)
        d:SetHeight(1)
        return d
    end

    function f:DividerUnder(region, gap)
        local d = self:CreateTexture(nil, "ARTWORK")
        d:SetTexture(1, 1, 1, 0.07)
        d:SetPoint("TOP", region, "BOTTOM", 0, -gap)
        d:SetPoint("LEFT", self, "LEFT", 22, 0)
        d:SetPoint("RIGHT", self, "RIGHT", -22, 0)
        d:SetHeight(1)
        return d
    end

    f:Hide()
    return f, verStr
end

local function styledButton(parent, w, h, text, primary, name)
    local b = CreateFrame("Button", name, parent)
    b:SetWidth(w)
    b:SetHeight(h)

    local px = CoARU_Px and CoARU_Px(1) or 1
    local edgePaint = CoARU_SkinRounded(b, ACCENT, "BACKGROUND", 0, 5)
    local fillPaint = CoARU_SkinRounded(b, { 1, 1, 1 }, "BORDER", px, 5 - px)
    local function idle()
        if primary then
            fillPaint({ ACCENT[1] * 0.42, ACCENT[2] * 0.42, ACCENT[3] * 0.42 }, 1)
            edgePaint(ACCENT, 1)
        else
            fillPaint({ 0.13, 0.13, 0.16 }, 1)
            edgePaint({ ACCENT[1] * 0.5, ACCENT[2] * 0.5, ACCENT[3] * 0.5 }, 1)
        end
    end
    idle(b)

    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER")
    fs:SetText(text)
    local baseR, baseG, baseB = 0.88, 0.88, 0.92
    if primary then baseR, baseG, baseB = 1, 1, 1 end
    fs:SetTextColor(baseR, baseG, baseB)

    b:SetScript("OnEnter", function()
        local k = primary and 0.62 or 0.3
        fillPaint({ ACCENT[1] * k, ACCENT[2] * k, ACCENT[3] * k }, 1)
        edgePaint(ACCENT, 1)
        fs:SetTextColor(1, 1, 1)
    end)
    b:SetScript("OnLeave", function()
        idle()
        fs:SetTextColor(baseR, baseG, baseB)
    end)

    b:SetScript("OnMouseDown", function()
        fs:ClearAllPoints()
        fs:SetPoint("CENTER", 1, -1)
    end)
    b:SetScript("OnMouseUp", function()
        fs:ClearAllPoints()
        fs:SetPoint("CENTER", 0, 0)
    end)
    return b
end

local function styledCheck(parent, text, name)
    local cb = CreateFrame("CheckButton", name, parent)
    cb:SetWidth(18)
    cb:SetHeight(18)

    local box = cb:CreateTexture(nil, "BACKGROUND")
    box:SetTexture(0.1, 0.1, 0.13, 1)
    box:SetAllPoints(cb)

    local function edge(p1, p2, w, h)
        local t = cb:CreateTexture(nil, "BORDER")
        t:SetTexture(ACCENT[1] * 0.6, ACCENT[2] * 0.6, ACCENT[3] * 0.6, 1)
        t:SetPoint(p1, cb, p1, 0, 0)
        t:SetPoint(p2, cb, p2, 0, 0)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
        return t
    end
    local edges = {
        edge("TOPLEFT", "TOPRIGHT", nil, 1),
        edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1),
        edge("TOPLEFT", "BOTTOMLEFT", 1, nil),
        edge("TOPRIGHT", "BOTTOMRIGHT", 1, nil),
    }

    local mark = cb:CreateTexture(nil, "OVERLAY")
    mark:SetTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)
    mark:SetPoint("TOPLEFT", 4, -4)
    mark:SetPoint("BOTTOMRIGHT", -4, 4)
    mark:Hide()

    local lbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    lbl:SetText(text)
    lbl:SetTextColor(0.8, 0.8, 0.85)

    local function repaint(self)
        if self:GetChecked() then mark:Show() else mark:Hide() end
    end
    cb:SetScript("OnClick", repaint)

    cb.blocked = false
    local DIM = 0.28
    local function paintIdle()
        local k = cb.blocked and DIM or 0.6
        for i = 1, #edges do
            edges[i]:SetTexture(ACCENT[1] * k, ACCENT[2] * k, ACCENT[3] * k, 1)
        end
        if cb.blocked then
            lbl:SetTextColor(0.42, 0.42, 0.45)
            mark:SetTexture(ACCENT[1] * DIM, ACCENT[2] * DIM, ACCENT[3] * DIM, 1)
        else
            lbl:SetTextColor(0.8, 0.8, 0.85)
            mark:SetTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)
        end
    end
    cb:SetScript("OnEnter", function(self)
        if not self.blocked then
            for i = 1, #edges do edges[i]:SetTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1) end
            lbl:SetTextColor(1, 1, 1)
        end
        if self.ShowHint then self:ShowHint() end
    end)
    cb:SetScript("OnLeave", function(self)
        paintIdle()
        GameTooltip:Hide()
    end)

    cb.SetBlocked = function(self, why)
        self.blocked = (why ~= nil)
        self.blockWhy = why
        if why then self:Disable() else self:Enable() end
        paintIdle()
    end

    local rawSet = cb.SetChecked
    cb.SetChecked = function(self, v)
        rawSet(self, v)
        repaint(self)
    end
    cb:SetChecked(false)

    cb:SetHitRectInsets(0, -(lbl:GetStringWidth() + 10), 0, 0)
    return cb
end

local welcomeFrame
local welcomeSuspended = false

local optionsSuspended = false
local function restoreOptions()
    if not optionsSuspended then return end
    optionsSuspended = false
    if CoARU_ShowOptions then CoARU_ShowOptions() end
end

local donateFrame
local function ensureDonateFrame()
    if donateFrame then return donateFrame end

    local PAD = 24
    local GAP_HEAD = 6
    local GAP_CTRL = 10
    local GAP_SECT = 12
    local CARD_PAD = 16
    local CTRL_H = 26
    local BTN_W = 148
    local FOOTER_H = 52

    local W = 560
    local INNER = W - PAD * 2

    local f = makePanel("CoARUDonateFrame", "FULLSCREEN_DIALOG", W, 376,

        "Поддержать автора", "CoARU, русификатор Conquest of Azeroth")

    local LAYER = (CoARU_SKIN and CoARU_SKIN.layer) or {}
    local CARD = LAYER.card or { 0.135, 0.135, 0.155 }
    local INK_HEAD = { 0.95, 0.95, 0.97 }
    local INK_BODY = { 0.80, 0.80, 0.86 }

    local thanks = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    thanks:SetPoint("TOPLEFT", PAD, -84)
    thanks:SetWidth(INNER)
    thanks:SetJustifyH("LEFT")
    thanks:SetText("Спасибо, что пользуешься аддоном! Я разрабатываю CoARU один и занимаюсь "
        .. "им в свободное время. Поддержка поможет быстрее выпускать обновления.")
    thanks:SetTextColor(INK_BODY[1], INK_BODY[2], INK_BODY[3])
    if CoARU_SkinFont then CoARU_SkinFont(thanks, 13) end

    local function makeCard(anchorTo, title)
        local c = CreateFrame("Frame", nil, f)
        c:SetWidth(INNER)
        c:SetHeight(60)
        if anchorTo then
            c:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -GAP_SECT)
        else
            c:SetPoint("TOPLEFT", thanks, "BOTTOMLEFT", 0, -GAP_SECT - 4)
        end
        if CoARU_SkinRounded then CoARU_SkinRounded(c, CARD) end
        local h = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h:SetPoint("TOPLEFT", CARD_PAD, -14)
        h:SetText(title)
        h:SetTextColor(INK_HEAD[1], INK_HEAD[2], INK_HEAD[3])
        if CoARU_SkinFont then CoARU_SkinFont(h, 14) end
        c.head = h
        return c
    end

    local money = makeCard(nil, "Поддержать деньгами")

    local hint = money:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", money.head, "BOTTOMLEFT", 0, -GAP_HEAD)

    hint:SetText("Нажми на ссылку, затем скопируй ее через |cffffd100Ctrl+C|r.")
    hint:SetTextColor(0.66, 0.66, 0.72)
    if CoARU_SkinFont then CoARU_SkinFont(hint, 11) end

    local ebBg = CreateFrame("Frame", nil, money)
    ebBg:SetHeight(CTRL_H)
    ebBg:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -GAP_CTRL)
    ebBg:SetPoint("RIGHT", money, "RIGHT", -CARD_PAD, 0)
    if CoARU_SkinRounded then
        CoARU_SkinRounded(ebBg, { 0.075, 0.075, 0.09 }, "BACKGROUND", 0, 5)
    end

    local eb = CreateFrame("EditBox", "CoARUDonateEdit", ebBg)
    eb:SetAllPoints(ebBg)
    eb:SetTextInsets(10, 10, 0, 0)

    if CoARU_SkinFont then CoARU_SkinFont(eb, 12) end
    eb:SetTextColor(0.88, 0.88, 0.94)
    eb:SetAutoFocus(false)

    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(self) self:HighlightText() end)

    eb:SetScript("OnMouseUp", function(self) self:HighlightText() end)
    eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    local restoring = false
    eb:SetScript("OnTextChanged", function(self)
        if restoring then return end
        if self:GetText() ~= DONATE_TEXT then
            restoring = true
            self:SetText(DONATE_TEXT)
            self:SetCursorPosition(0)
            self:HighlightText()
            restoring = false
        end
    end)

    local help = makeCard(money, "Помочь переводу")

    local altText = help:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    altText:SetPoint("TOPLEFT", help.head, "BOTTOMLEFT", 0, -GAP_HEAD)
    altText:SetWidth(INNER - CARD_PAD * 2 - BTN_W - 16)
    altText:SetJustifyH("LEFT")

    altText:SetText("Встретил непереведенное или ошибку?")
    altText:SetTextColor(0.66, 0.66, 0.72)
    if CoARU_SkinFont then CoARU_SkinFont(altText, 11) end

    local a2 = help:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    a2:SetPoint("TOPLEFT", altText, "BOTTOMLEFT", 0, -2)
    a2:SetText("Собери отчет и пришли файл в ")
    a2:SetTextColor(0.66, 0.66, 0.72)
    if CoARU_SkinFont then CoARU_SkinFont(a2, 11) end

    local dBtn = CreateFrame("Button", "CoARUDonateDiscordLink", help)
    dBtn:SetPoint("LEFT", a2, "RIGHT", 0, 0)
    dBtn:SetHeight(14)

    local dLink = dBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dLink:SetPoint("LEFT", dBtn, "LEFT", 0, 0)
    dLink:SetText("Discord")

    dLink:SetTextColor(0.77, 0.58, 0.87)
    if CoARU_SkinFont then CoARU_SkinFont(dLink, 11) end

    dBtn:SetWidth((dLink:GetStringWidth() or 40) + 1)

    local dUnder = dBtn:CreateTexture(nil, "ARTWORK")
    dUnder:SetTexture(0.77, 0.58, 0.87, 0.5)
    dUnder:SetHeight(1)
    dUnder:SetPoint("TOPLEFT", dLink, "BOTTOMLEFT", 0, 1)
    dUnder:SetPoint("TOPRIGHT", dLink, "BOTTOMRIGHT", 0, 1)

    dBtn:SetScript("OnEnter", function() dLink:SetTextColor(0.90, 0.76, 0.98) end)
    dBtn:SetScript("OnLeave", function() dLink:SetTextColor(0.77, 0.58, 0.87) end)
    dBtn:SetScript("OnClick", function() CoARU_ShowDiscord() end)

    local a3 = help:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    a3:SetPoint("LEFT", dBtn, "RIGHT", 0, 0)
    a3:SetText(", канал |cffC495DD#обсуждение-coaru|r.")
    a3:SetTextColor(0.66, 0.66, 0.72)
    if CoARU_SkinFont then CoARU_SkinFont(a3, 11) end

    local report = styledButton(help, BTN_W, CTRL_H, "Собрать отчет", false,
        "CoARUDonateReportButton")
    report:SetPoint("RIGHT", help, "RIGHT", -CARD_PAD, 0)
    report:SetScript("OnClick", runStatusReport)

    local lastCard = help

    local stateLast = iconRow
    local stateLinkFirst, stateLinkPrev
    local total = CoARU_ThanksCount and CoARU_ThanksCount() or 0
    if total > 0 then

        local who = CreateFrame("Frame", nil, f)
        who:SetWidth(INNER)
        who:SetHeight(CTRL_H + CARD_PAD * 2)
        who:SetPoint("TOPLEFT", help, "BOTTOMLEFT", 0, -GAP_SECT)
        if CoARU_SkinRounded then CoARU_SkinRounded(who, CARD) end

        local thText = who:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        thText:SetPoint("LEFT", who, "LEFT", CARD_PAD, 0)

        local n10, n100 = total % 10, total % 100
        local word = "человек"
        if n10 >= 2 and n10 <= 4 and (n100 < 12 or n100 > 14) then word = "человека" end
        thText:SetText(("Переводу помогли |cffffd100%d|r %s"):format(total, word))
        thText:SetTextColor(INK_HEAD[1], INK_HEAD[2], INK_HEAD[3])
        if CoARU_SkinFont then CoARU_SkinFont(thText, 14) end

        local thBtn = styledButton(who, BTN_W, CTRL_H, "Кто помог", false,
            "CoARUDonateThanksButton")
        thBtn:SetPoint("RIGHT", who, "RIGHT", -CARD_PAD, 0)
        thBtn:SetScript("OnClick", function() CoARU_ShowThanks() end)
        lastCard = who
    end

    local fline = f:CreateTexture(nil, "ARTWORK")
    fline:SetTexture(1, 1, 1, 0.08)
    fline:SetHeight(1)
    fline:SetPoint("BOTTOMLEFT", PAD, FOOTER_H)
    fline:SetPoint("BOTTOMRIGHT", -PAD, FOOTER_H)

    local btn = styledButton(f, BTN_W, CTRL_H, "Закрыть", true)
    btn:SetPoint("BOTTOMRIGHT", -PAD, (FOOTER_H - CTRL_H) / 2)
    btn:SetScript("OnClick", function() f:Hide() end)

    local sized = false

    local CARD_TOP = 14
    local function fitHeight(self)
        if sized then return end

        local hLead = thanks:GetStringHeight() or 0
        local hHint = hint:GetStringHeight() or 0

        local hAlt = (altText:GetStringHeight() or 0) + (a2:GetStringHeight() or 0) + 2
        local hH1 = money.head:GetStringHeight() or 0
        local hH2 = help.head:GetStringHeight() or 0
        if hLead <= 0 or hHint <= 0 or hAlt <= 0 or hH1 <= 0 or hH2 <= 0 then return end

        local hMoney = CARD_TOP + hH1 + GAP_HEAD + hHint + GAP_CTRL + CTRL_H + CARD_TOP
        local hHelp = CARD_TOP + hH2 + GAP_HEAD + hAlt + CARD_TOP

        local minHelp = CTRL_H + CARD_TOP * 2
        if hHelp < minHelp then hHelp = minHelp end
        money:SetHeight(hMoney)
        help:SetHeight(hHelp)

        local y = 84 + hLead + (GAP_SECT + 4) + hMoney + GAP_SECT + hHelp
        if lastCard ~= help then y = y + GAP_SECT + lastCard:GetHeight() end
        self:SetHeight(y + FOOTER_H + PAD)
        sized = true
    end

    f:SetScript("OnHide", function()
        restoreOptions()
        if welcomeSuspended then
            welcomeSuspended = false
            if welcomeFrame then welcomeFrame:Show() end
        end
    end)

    f:SetScript("OnUpdate", function(self)
        fitHeight(self)
        if sized then self:SetScript("OnUpdate", nil) end
    end)

    f:SetScript("OnShow", function(self)
        fitHeight(self)
        eb:SetText(DONATE_TEXT)
        eb:SetCursorPosition(0)
        eb:HighlightText()
        eb:SetFocus()
    end)

    donateFrame = f
    return f
end

CoARU_BuildDonateFrame = ensureDonateFrame

local function showDonate()
    msg("поддержать автора: " .. DONATE_TEXT)
    if welcomeFrame and welcomeFrame:IsShown() then
        welcomeSuspended = true
        welcomeFrame:Hide()
    end
    ensureDonateFrame():Show()
end

local linkFrame
local function ensureLinkFrame()
    if linkFrame then return linkFrame end
    local PAD, CTRL_H, BTN_W, FOOTER_H = 24, 26, 148, 52
    local INNER = 480 - PAD * 2

    local f = makePanel("CoARULinkFrame", "FULLSCREEN_DIALOG", 480, 232,
        "Где взять аддон", "CoARU, русификатор Conquest of Azeroth")

    local d = f:Divider(-72)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hint:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 2, -12)
    hint:SetWidth(INNER)
    hint:SetJustifyH("LEFT")
    hint:SetText("Свежая сборка лежит в разделе Releases. Нажми на ссылку, "
        .. "затем скопируй ее через |cffffd100Ctrl+C|r.")
    hint:SetTextColor(0.84, 0.84, 0.88)

    local eb = CreateFrame("EditBox", "CoARULinkEdit", f, "InputBoxTemplate")
    eb:SetWidth(INNER - 12)
    eb:SetHeight(CTRL_H)
    eb:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 6, -10)
    eb:SetAutoFocus(false)

    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    eb:SetScript("OnTextChanged", function(self)
        if self:GetText() ~= GITHUB_TEXT then
            self:SetText(GITHUB_TEXT)
            self:HighlightText()
        end
    end)
    eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    local note = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", eb, "BOTTOMLEFT", -6, -12)
    note:SetWidth(INNER)
    note:SetJustifyH("LEFT")
    note:SetText("Обновлять только заменой папки целиком, и заходить в игру заново, "
        .. "а не через /reload.")
    note:SetTextColor(0.72, 0.72, 0.78)

    local btn = styledButton(f, BTN_W, CTRL_H, "Закрыть")
    btn:SetPoint("BOTTOMRIGHT", -PAD, (FOOTER_H - CTRL_H) / 2)
    btn:SetScript("OnClick", function() f:Hide() end)

    f:SetScript("OnShow", function()
        eb:SetText(GITHUB_TEXT)
        eb:SetCursorPosition(0)
        eb:HighlightText()
        eb:SetFocus()
    end)

    f:Hide()
    f:SetScript("OnHide", restoreOptions)
    linkFrame = f
    return f
end

CoARU_BuildLinkFrame = ensureLinkFrame

local function showLink()
    msg("аддон и обновления: " .. GITHUB_TEXT)
    ensureLinkFrame():Show()
end

local discordFrame
local function ensureDiscordFrame()
    if discordFrame then return discordFrame end
    local PAD, CTRL_H, BTN_W, FOOTER_H = 24, 26, 148, 52
    local INNER = 480 - PAD * 2

    local f = makePanel("CoARUDiscordFrame", "FULLSCREEN_DIALOG", 480, 232,
        "Discord", "CoARU, русификатор Conquest of Azeroth")

    local d = f:Divider(-72)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hint:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 2, -12)
    hint:SetWidth(INNER)
    hint:SetJustifyH("LEFT")
    hint:SetText("Новости, багрепорты и помощь. Нажми на ссылку, "
        .. "затем скопируй ее через |cffffd100Ctrl+C|r.")
    hint:SetTextColor(0.84, 0.84, 0.88)

    local eb = CreateFrame("EditBox", "CoARUDiscordEdit", f, "InputBoxTemplate")
    eb:SetWidth(INNER - 12)
    eb:SetHeight(CTRL_H)
    eb:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 6, -10)
    eb:SetAutoFocus(false)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    eb:SetScript("OnTextChanged", function(self)
        if self:GetText() ~= CoARU_DISCORD_URL then
            self:SetText(CoARU_DISCORD_URL)
            self:HighlightText()
        end
    end)
    eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    local note = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", eb, "BOTTOMLEFT", -6, -12)
    note:SetWidth(INNER)
    note:SetJustifyH("LEFT")
    note:SetText("Отчеты о непереведенном и ошибках — канал "
        .. "|cffC495DD#обсуждение-coaru|r.")
    note:SetTextColor(0.72, 0.72, 0.78)

    local btn = styledButton(f, BTN_W, CTRL_H, "Закрыть")
    btn:SetPoint("BOTTOMRIGHT", -PAD, (FOOTER_H - CTRL_H) / 2)
    btn:SetScript("OnClick", function() f:Hide() end)

    f:SetScript("OnShow", function()
        eb:SetText(CoARU_DISCORD_URL)
        eb:SetCursorPosition(0)
        eb:HighlightText()
        eb:SetFocus()
    end)

    f:Hide()
    f:SetScript("OnHide", restoreOptions)
    discordFrame = f
    return f
end

CoARU_BuildDiscordFrame = ensureDiscordFrame

function CoARU_ShowDiscord()
    ensureDiscordFrame():Show()
end

local function ensureWelcomeFrame()
    if welcomeFrame then return welcomeFrame end

    local PAD = 24
    local CTRL_H = 26
    local BTN_W = 148
    local FOOTER_H = 52

    local f, verStr = makePanel("CoARUWelcomeFrame", "DIALOG", 560, 288,
        "CoARU", "Русификатор Conquest of Azeroth", false)
    local LAYER = (CoARU_SKIN and CoARU_SKIN.layer) or {}
    local CARD = LAYER.card or { 0.135, 0.135, 0.155 }
    local W = 560 - PAD * 2
    local CMD = "|cffffd100"

    local INK_HEAD = { 0.95, 0.95, 0.97 }
    local INK_BODY = { 0.74, 0.74, 0.81 }

    local nTr = countLines()

    local lead = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lead:SetPoint("TOPLEFT", PAD, -84)
    lead:SetWidth(W)
    lead:SetJustifyH("LEFT")
    lead:SetText("Переведено: |cffC495DD" .. groupNum(nTr) .. "|r строк.")
    lead:SetTextColor(INK_BODY[1], INK_BODY[2], INK_BODY[3])
    if CoARU_SkinFont then CoARU_SkinFont(lead, 13) end

    local key = ({ ALT = "Alt", CTRL = "Ctrl", SHIFT = "Shift" })[
        CoARU_OriginalMod and CoARU_OriginalMod() or "ALT"] or "Alt"

    local card = CreateFrame("Frame", nil, f)
    card:SetWidth(W)
    card:SetHeight(78)
    card:SetPoint("TOPLEFT", PAD, -116)
    if CoARU_SkinRounded then CoARU_SkinRounded(card, CARD) end

    local ch = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ch:SetPoint("TOPLEFT", 16, -14)
    ch:SetText("Зажми " .. key .. " над спеллом или предметом и увидишь оригинальный текст")
    ch:SetTextColor(INK_HEAD[1], INK_HEAD[2], INK_HEAD[3])
    if CoARU_SkinFont then CoARU_SkinFont(ch, 14) end

    local cd = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cd:SetPoint("TOPLEFT", ch, "BOTTOMLEFT", 0, -7)
    cd:SetWidth(W - 32)
    cd:SetJustifyH("LEFT")

    cd:SetText("Пригодится, чтобы находить предмет на аукционе или найти спелл в гайдах. "
        .. "Сменить клавишу можно по команде: " .. CMD .. "/coaru original ctrl|r")
    cd:SetTextColor(INK_BODY[1], INK_BODY[2], INK_BODY[3])
    if CoARU_SkinFont then CoARU_SkinFont(cd, 11) end

    local cardSized = false
    local function fitCard()
        if cardSized then return end
        local h1 = ch:GetStringHeight() or 0
        local h2 = cd:GetStringHeight() or 0
        if h1 <= 0 or h2 <= 0 then return end
        card:SetHeight(14 + h1 + 7 + h2 + 14)
        cardSized = true
    end

    local where = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    where:SetPoint("TOPLEFT", PAD, -206)
    where:SetWidth(W)
    where:SetJustifyH("LEFT")

    where:SetText("Значок у миникарты: левый клик " .. CMD .. "настройки|r, правый "
        .. CMD .. "отчет для переводчика|r")
    where:SetTextColor(0.60, 0.60, 0.67)
    if CoARU_SkinFont then CoARU_SkinFont(where, 11) end

    local fline = f:CreateTexture(nil, "ARTWORK")
    fline:SetTexture(1, 1, 1, 0.08)
    fline:SetHeight(1)
    fline:SetPoint("BOTTOMLEFT", PAD, FOOTER_H)
    fline:SetPoint("BOTTOMRIGHT", -PAD, FOOTER_H)

    local cb = styledCheck(f, "Не показывать при запуске")

    cb:SetPoint("BOTTOMLEFT", PAD, (FOOTER_H - CTRL_H) / 2 + (CTRL_H - 18) / 2)

    local donate = styledButton(f, BTN_W, CTRL_H, "Поддержать автора", false,
        "CoARUWelcomeDonateButton")
    donate:SetPoint("BOTTOMRIGHT", -(PAD + BTN_W + 10), (FOOTER_H - CTRL_H) / 2)
    donate:SetScript("OnClick", function() showDonate() end)

    local btn = styledButton(f, BTN_W, CTRL_H, "Понятно", true)
    btn:SetPoint("BOTTOMRIGHT", -PAD, (FOOTER_H - CTRL_H) / 2)
    btn:SetScript("OnClick", function() f:Hide() end)

    f:SetScript("OnShow", fitCard)
    f:SetScript("OnUpdate", function(self)
        fitCard()
        if cardSized then self:SetScript("OnUpdate", nil) end
    end)

    f:SetScript("OnHide", function()
        restoreOptions()
        CoARU_DB.opts = CoARU_DB.opts or {}
        if cb:GetChecked() then CoARU_DB.opts.welcomeVer = verStr end
    end)

    f:Hide()
    welcomeFrame = f
    return f
end

CoARU_BuildWelcomeFrame = ensureWelcomeFrame

local function showWelcome()
    local ok, err = pcall(function() ensureWelcomeFrame():Show() end)
    if not ok then
        msg("окно приветствия не открылось: " .. tostring(err))
        return false
    end

    if welcomeFrame and welcomeFrame.IsShown and not welcomeFrame:IsShown() then
        msg("окно приветствия создано, но клиент его не показывает.")
        return false
    end
    return true
end

local function maybeShowWelcome()
    CoARU_DB.opts = CoARU_DB.opts or {}
    local ver = (GetAddOnMetadata and GetAddOnMetadata("CoARU", "Version")) or "?"
    if CoARU_DB.opts.welcomeVer == ver then return end
    showWelcome()
end

local thanksFrame

local thanksParent
local function ensureThanksFrame()
    if thanksFrame then return thanksFrame end

    local PAD, GAP_HEAD = 24, 6
    local CTRL_H, BTN_W, FOOTER_H, W, LIST_H = 26, 150, 52, 560, 260
    local INNER = W - PAD * 2

    local SURF_PAD = 16
    local COL_GAP = 12
    local COL_W = math.floor((INNER - SURF_PAD * 2 - COL_GAP * 2) / 3)

    local MEDIA_H = ((CoARU_THANKS or {}).media and #CoARU_THANKS.media > 0) and 22 or 0

    local f = makePanel("CoARUThanksFrame", "FULLSCREEN_DIALOG", W,
        76 + LIST_H + SURF_PAD * 2 + MEDIA_H + FOOTER_H,
        "Кто помог переводу", "Спасибо каждому из этого списка", true)

    local LAYER = (CoARU_SKIN and CoARU_SKIN.layer) or {}
    local SURFACE = LAYER.surface or { 0.105, 0.105, 0.122 }

    local SECTIONS = {
        { key = "donate", head = "ПОДДЕРЖАЛИ РУБЛЕМ" },
        { key = "data",   head = "ПРИСЛАЛИ ДАННЫЕ",   note = "дампы, базы, скриншоты" },
        { key = "bugs",   head = "НАШЛИ ОШИБКИ",      note = "и вычитали перевод" },
    }

    local pad = CreateFrame("Frame", nil, f)
    pad:SetPoint("TOPLEFT", PAD, -70)
    pad:SetPoint("TOPRIGHT", -PAD, -70)
    pad:SetHeight(LIST_H + SURF_PAD * 2)
    if CoARU_SkinRounded then CoARU_SkinRounded(pad, SURFACE) end

    local scroll = CreateFrame("ScrollFrame", "CoARUThanksScroll", pad)
    scroll:SetPoint("TOPLEFT", SURF_PAD, -SURF_PAD)
    scroll:SetPoint("TOPRIGHT", -SURF_PAD, -SURF_PAD)
    scroll:SetHeight(LIST_H)

    local content = CreateFrame("Frame", "CoARUThanksContent", scroll)
    content:SetWidth(INNER - SURF_PAD * 2)
    content:SetHeight(LIST_H)
    scroll:SetScrollChild(content)

    local maxRows, tallest, tallestRows = 0, nil, 0
    for i = 1, #SECTIONS do
        local s = SECTIONS[i]
        local list = (CoARU_THANKS or {})[s.key] or {}
        local extra = (s.key == "donate") and (tonumber(CoARU_THANKS_ANON) or 0) or 0
        local x = (i - 1) * (COL_W + COL_GAP)

        local head = CoARU_SkinSubHeader and CoARU_SkinSubHeader(content, s.head)
            or content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        if not CoARU_SkinSubHeader then head:SetText(s.head) end
        head:SetPoint("TOPLEFT", x, 0)
        head:SetJustifyH("LEFT")

        if head.line then head.line:Hide() end

        local note = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        note:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -4)
        note:SetWidth(COL_W)
        note:SetJustifyH("LEFT")
        note:SetText(s.note or "")
        note:SetTextColor(0.5, 0.5, 0.55)
        if CoARU_SkinFont then CoARU_SkinFont(note, 10) end

        local names = {}
        for k = 1, #list do
            names[#names + 1] = list[k]
        end
        if extra > 0 then
            local n10, n100 = extra % 10, extra % 100
            local word = "анонимов"
            if n10 == 1 and n100 ~= 11 then
                word = "аноним"
            elseif n10 >= 2 and n10 <= 4 and (n100 < 12 or n100 > 14) then
                word = "анонима"
            end
            names[#names + 1] = ("и еще %d %s"):format(extra, word)
        end
        if #names == 0 then names[1] = "пока никого" end

        local body = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        body:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -(GAP_HEAD + 16))
        body:SetWidth(COL_W)
        body:SetJustifyH("LEFT")
        body:SetJustifyV("TOP")
        body:SetText("|cffC495DD" .. table.concat(names, "|r\n|cffC495DD") .. "|r")
        body:SetTextColor(0.84, 0.84, 0.88)

        if #names > maxRows then maxRows = #names end
        if not tallest or #names > tallestRows then tallest, tallestRows = body, #names end
    end

    local contentH = 34 + maxRows * 14
    content:SetHeight(contentH)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", PAD, (FOOTER_H - CTRL_H) / 2 + 6)
    hint:SetText("колесо мыши прокручивает список")
    hint:SetTextColor(0.5, 0.5, 0.55)
    hint:Hide()

    local measured = false
    local function fitContent()
        if measured then return end
        local hb = tallest and tallest:GetStringHeight() or 0
        if hb <= 0 then return end
        contentH = 12 + (GAP_HEAD + 16) + hb + 4
        content:SetHeight(contentH)
        if contentH > LIST_H then hint:Show() end
        measured = true
    end

    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local limit = contentH - LIST_H
        if limit <= 0 then return end
        local pos = self:GetVerticalScroll() - delta * 24
        if pos < 0 then pos = 0 elseif pos > limit then pos = limit end
        self:SetVerticalScroll(pos)
    end)

    local media = (CoARU_THANKS or {}).media or {}
    if #media > 0 then
        local m = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        m:SetPoint("BOTTOMLEFT", PAD, FOOTER_H + 6)
        m:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
        m:SetJustifyH("LEFT")

        m:SetText("Сняли ролики про русификатор: |cffC495DD"
            .. table.concat(media, "|r, |cffC495DD") .. "|r")
        m:SetTextColor(0.68, 0.68, 0.74)
        if CoARU_SkinFont then CoARU_SkinFont(m, 11) end
    end

    local fline = f:CreateTexture(nil, "ARTWORK")
    fline:SetTexture(1, 1, 1, 0.08)
    fline:SetHeight(1)
    fline:SetPoint("BOTTOMLEFT", PAD, FOOTER_H)
    fline:SetPoint("BOTTOMRIGHT", -PAD, FOOTER_H)

    local close = styledButton(f, BTN_W, CTRL_H, "Закрыть", true, "CoARUThanksCloseButton")
    close:SetPoint("BOTTOMRIGHT", -PAD, (FOOTER_H - CTRL_H) / 2)
    close:SetScript("OnClick", function() f:Hide() end)

    f:SetScript("OnShow", fitContent)
    f:SetScript("OnUpdate", function(self)
        fitContent()
        if measured then self:SetScript("OnUpdate", nil) end
    end)

    f:SetScript("OnHide", function()
        restoreOptions()
        if thanksParent then
            local p = thanksParent
            thanksParent = nil
            if p.Show then p:Show() end
        end
    end)

    f:Hide()
    thanksFrame = f
    return f
end

CoARU_BuildThanksFrame = ensureThanksFrame

local OUR_WINDOWS = { "CoARUWelcomeFrame", "CoARUDonateFrame", "CoARUOptionsFrame" }

function CoARU_ShowThanks()
    local ok, err = pcall(function()
        local f = ensureThanksFrame()
        thanksParent = nil

        for _ = 1, 3 do
            local any = false
            for i = 1, #OUR_WINDOWS do
                local w = _G[OUR_WINDOWS[i]]
                if w and w.IsShown and w:IsShown() then

                    thanksParent = thanksParent or w
                    w:Hide()
                    any = true
                end
            end
            if not any then break end
        end
        f:Show()
    end)
    if not ok then
        msg("окно благодарностей не открылось: " .. tostring(err))
        return false
    end
    return true
end

local optionsFrame
local function ensureOptionsFrame()
    if optionsFrame then return optionsFrame end

    if not (CoARU_SkinToggle and CoARU_SkinTab and CoARU_SkinDivider) then
        msg("окно настроек обновилось и требует ПОЛНОГО перезапуска игры:"
            .. " выйдите из клиента и зайдите заново. Команда /reload тут не поможет,"
            .. " новые файлы аддона она не подхватывает.")
        return nil
    end

    local W, H = 860, 690
    local HEAD_BOTTOM = 65

    local EDGE = 5
    local SIDE_W, SIDE_X = 186, EDGE
    local PANE_X = SIDE_X + SIDE_W + 20

    local PANE_W = W - PANE_X
    local PAD = 16
    local FOOTER_H = 52
    local CTRL_H, BTN_W = 26, 140
    local ROW_STEP = 30

    local f = makePanel("CoARUOptionsFrame", "FULLSCREEN_DIALOG", W, H,
        "Настройки", "Что переводить", true)

    local side = CreateFrame("Frame", nil, f)
    side:SetPoint("TOPLEFT", SIDE_X, -(HEAD_BOTTOM + 6))
    side:SetPoint("BOTTOMLEFT", SIDE_X, FOOTER_H + 4)
    side:SetWidth(SIDE_W)

    CoARU_SkinRounded(side, CoARU_SKIN.layer.side)

    local rows, panes, tabs = {}, {}, {}

    local syncPresets = function() end

    local function newPane()
        local p = CreateFrame("Frame", nil, f)
        p:SetPoint("TOPLEFT", PANE_X - 10, -(HEAD_BOTTOM + 8))
        p:SetPoint("BOTTOMRIGHT", -10, FOOTER_H + 4)
        CoARU_SkinRounded(p, CoARU_SKIN.layer.surface)
        p:Hide()
        panes[#panes + 1] = p
        return p
    end

    local function selectPane(i)
        for k = 1, #panes do
            panes[k]:Hide()
            if tabs[k] then tabs[k]:SetActive(false) end
        end
        if panes[i] then

            panes[i]:SetAlpha(1)
            panes[i]:Show()
        end
        if tabs[i] then tabs[i]:SetActive(true) end
        CoARU_DB.opts = CoARU_DB.opts or {}
        CoARU_DB.opts.optTab = i
    end

    local TAB_ICON = {
        ["Быстрый выбор"]    = "INV_Misc_PocketWatch_01",
        ["Текст"]            = "INV_Misc_Book_09",
        ["Имена и названия"] = "INV_Misc_Note_01",
        ["Окна и панели"]    = "INV_Misc_Spyglass_02",
        ["Состояние"]        = "INV_Misc_Gear_01",
        ["Прочее"]           = "INV_Misc_Wrench_01",
    }
    local function addTab(label, idx)

        local b = CoARU_SkinTab(side, label, SIDE_W - 2, 28, TAB_ICON[label])
        if idx == 1 then
            b:SetPoint("TOPLEFT", side, "TOPLEFT", 1, -6)
        else
            b:SetPoint("TOPLEFT", tabs[idx - 1], "BOTTOMLEFT", 0, -2)
        end
        b:SetScript("OnClick", function() selectPane(idx) end)
        tabs[idx] = b
        return b
    end

    local ROW_H = 44
    local function addModule(pane, m, prev, paneW)
        local r = CoARU_SkinRow2(pane, paneW - 36, ROW_H, m.label, m.hint,
            "CoARUOptionCheck_" .. m.key)
        if prev then
            r:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -4)
        else
            r:SetPoint("TOPLEFT", pane, "TOPLEFT", 18, -6)
        end
        local row = { key = m.key, cb = r.toggle, card = r, hint = m.hint }

        local function apply(self)
            CoARU_SetMod(row.key, r.toggle:GetChecked() and true or false)

            syncPresets()
        end
        r.toggle.OnRowClick = apply
        r.toggle:HookScript("OnClick", apply)
        rows[#rows + 1] = row
        return r
    end

    local function paneTitle(pane, text, sub)
        local h = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        h:SetPoint("TOPLEFT", pane, "TOPLEFT", 18, -16)
        h:SetText(text)
        h:SetTextColor(0.92, 0.84, 1)

        if CoARU_SkinFont then CoARU_SkinFont(h, 18, nil, true) end
        local s = pane:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        s:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -4)
        s:SetText(sub or "")
        s:SetTextColor(0.46, 0.46, 0.52)
        if CoARU_SkinFont then CoARU_SkinFont(s, 10) end
        local d = CoARU_SkinDivider(pane)
        d:SetPoint("TOPLEFT", s, "BOTTOMLEFT", 0, -10)
        d:SetPoint("RIGHT", pane, "RIGHT", -18, 0)
        return d
    end

    local placed = {}
    local order = {}
    for gi = 1, #CoARU_GROUPS do
        local g = CoARU_GROUPS[gi]
        local any = false
        for i = 1, #CoARU_MODULES do
            if CoARU_MODULES[i].group == g.key then any = true break end
        end
        if any then
            local pane = newPane()
            local a = paneTitle(pane, g.label, g.hint)

            local mine = {}
            for i = 1, #CoARU_MODULES do
                if CoARU_MODULES[i].group == g.key then mine[#mine + 1] = CoARU_MODULES[i] end
            end
            local rank = {}
            for i = 1, #(CoARU_SUBORDER or {}) do rank[CoARU_SUBORDER[i]] = i end
            table.sort(mine, function(x, y)
                local rx, ry = rank[x.sub] or 99, rank[y.sub] or 99
                if rx ~= ry then return rx < ry end
                return false
            end)
            local prev, lastSub
            for i = 1, #mine do
                local m = mine[i]
                if m.group == g.key then

                    if m.sub and m.sub ~= lastSub then
                        lastSub = m.sub
                        local sh = CoARU_SkinSubHeader(pane, m.sub, PANE_W - 240)
                        if prev then
                            sh:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 2, -11)
                        else
                            sh:SetPoint("TOPLEFT", a, "BOTTOMLEFT", 2, -9)
                        end
                        prev = nil
                        a = sh
                    end
                    local cb = addModule(pane, m, prev, PANE_W)

                    if not prev then
                        cb:SetPoint("TOPLEFT", a, "BOTTOMLEFT", lastSub and -2 or 0, -9)
                    end
                    prev = cb
                    placed[m.key] = true
                end
            end
            order[#order + 1] = g
        end
    end

    local orphan = {}
    for i = 1, #CoARU_MODULES do
        if not placed[CoARU_MODULES[i].key] then orphan[#orphan + 1] = CoARU_MODULES[i] end
    end
    if #orphan > 0 then
        local pane = newPane()
        local a = paneTitle(pane, "Прочее", "модули без раздела")
        local prev
        for i = 1, #orphan do
            local cb = addModule(pane, orphan[i], prev, PANE_W)
            if not prev then cb:SetPoint("TOPLEFT", a, "BOTTOMLEFT", 0, -12) end
            prev = cb
        end
        order[#order + 1] = { label = "Прочее" }
    end

    local pState = newPane()
    local sa = paneTitle(pState, "Состояние", "что стоит вне аддона")

    local CARD_W = math.floor((PANE_W - 36 - 12) / 2)
    local packCard = CoARU_SkinStatCard(pState, CARD_W, 84, "ПАКЕТ ИНТЕРФЕЙСА", "...",
        { 0.7, 0.7, 0.7 }, "переводит окна клиента до загрузки аддона")
    packCard:SetPoint("TOPLEFT", sa, "BOTTOMLEFT", 0, -14)
    local cacheCard = CoARU_SkinStatCard(pState, CARD_W, 84, "КЭШ ИМЕН СУЩЕСТВ", "...",
        { 0.7, 0.7, 0.7 }, "имена над головой рисует движок из этого файла")
    cacheCard:SetPoint("TOPLEFT", packCard, "TOPRIGHT", 12, 0)

    local function refreshState()
        if CoARU_PACK_VERSION then
            packCard.valueFS:SetText("установлен " .. tostring(CoARU_PACK_VERSION))
            packCard.valueFS:SetTextColor(0.35, 0.85, 0.4)
        else
            packCard.valueFS:SetText("не установлен")
            packCard.valueFS:SetTextColor(0.9, 0.35, 0.35)
        end
        if CoARU_CacheRu and CoARU_CacheRu() then
            cacheCard.valueFS:SetText("русский")
            cacheCard.valueFS:SetTextColor(0.35, 0.85, 0.4)
        else
            cacheCard.valueFS:SetText("английский")
            cacheCard.valueFS:SetTextColor(0.75, 0.72, 0.4)
            if cacheCard.noteFS then
                cacheCard.noteFS:SetText("либо еще не встречен ни один НПС")
            end
        end
    end
    refreshState()

    local sub2 = CoARU_SkinSubHeader(pState, "НАСТРОЙКИ ВНЕ ПЕРЕВОДА", PANE_W - 240)
    sub2:SetPoint("TOPLEFT", packCard, "BOTTOMLEFT", 2, -18)

    local mapsRow = CoARU_SkinRow2(pState, PANE_W - 36, 52, "У меня стоят русские карты мира",
        "аддон их не видит, а от ответа зависит предупреждение про зоны",
        "CoARUOptionCheck_rumaps")
    mapsRow:SetPoint("TOPLEFT", sub2, "BOTTOMLEFT", -2, -10)
    local mapsCB = mapsRow.toggle
    mapsCB.OnRowClick = function(self)
        if CoARU_SetRuMaps then CoARU_SetRuMaps(self:GetChecked() and true or false) end
        if CoARU_WarnInconsistent then pcall(CoARU_WarnInconsistent) end
    end
    mapsCB:HookScript("OnClick", function(self)
        if CoARU_SetRuMaps then CoARU_SetRuMaps(self:GetChecked() and true or false) end
        if CoARU_WarnInconsistent then pcall(CoARU_WarnInconsistent) end
    end)

    local iconRow = CoARU_SkinRow2(pState, PANE_W - 36, 52, "Значок у миникарты",
        "кнопка CoARU рядом с миникартой", "CoARUOptionCheck_minimap")
    iconRow:SetPoint("TOPLEFT", mapsRow, "BOTTOMLEFT", 0, -6)
    local iconCB = iconRow.toggle
    iconCB.OnRowClick = function(self)
        CoARU_DB.opts = CoARU_DB.opts or {}
        CoARU_DB.opts.minimapHide = (not self:GetChecked()) and true or nil
        if CoARU_UpdateMinimapButton then CoARU_UpdateMinimapButton() end
    end
    iconCB:HookScript("OnClick", function(self)
        CoARU_DB.opts = CoARU_DB.opts or {}
        CoARU_DB.opts.minimapHide = (not self:GetChecked()) and true or nil
        if CoARU_UpdateMinimapButton then CoARU_UpdateMinimapButton() end
    end)

    local total = CoARU_ThanksCount and CoARU_ThanksCount() or 0
    if total > 0 then
        local hlp = pState:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hlp:SetPoint("TOPLEFT", iconRow, "BOTTOMLEFT", 4, -20)
        local n10, n100 = total % 10, total % 100
        local word = "человек"
        if n10 >= 2 and n10 <= 4 and (n100 < 12 or n100 > 14) then word = "человека" end
        hlp:SetText(("Переводу помогли |cffffd100%d|r %s"):format(total, word))
        hlp:SetTextColor(0.68, 0.68, 0.74)
        if CoARU_SkinFont then CoARU_SkinFont(hlp, 12) end
        local who = styledButton(pState, 130, 26, "Кто помог", false,
            "CoARUOptionsThanksButton")
        who:SetPoint("LEFT", hlp, "RIGHT", 14, 0)
        who:SetScript("OnClick", function()
            if f and f.IsShown and f:IsShown() then
                optionsSuspended = true
                f:Hide()
            end
            CoARU_ShowThanks()
        end)
        stateLast = hlp
    end

    local sub3 = CoARU_SkinSubHeader(pState, "ОКНА И ССЫЛКИ", PANE_W - 240)
    sub3:SetPoint("TOPLEFT", stateLast, "BOTTOMLEFT", stateLast == iconRow and -2 or -4, -18)

    local LINK_W, LINK_H, LINK_GAP = 168, 26, 10
    local links = {
        { "Поддержать автора", showDonate,  "CoARUOptionsDonateButton" },
        { "Discord",           CoARU_ShowDiscord, "CoARUOptionsDiscordButton" },
        { "Обновления",        showLink,    "CoARUOptionsUpdateButton" },
        { "Приветствие",       showWelcome, "CoARUOptionsWelcomeButton" },
        { "Собрать отчет",     runStatusReport,   "CoARUOptionsReportButton" },
    }

    local function openFromOptions(open)
        return function()
            if f and f.IsShown and f:IsShown() then
                optionsSuspended = true
                f:Hide()
            end
            open()
        end
    end

    for i = 1, #links do
        local b = styledButton(pState, LINK_W, LINK_H, links[i][1], i == 1, links[i][3])
        if i == 1 then
            b:SetPoint("TOPLEFT", sub3, "BOTTOMLEFT", 2, -12)
        elseif i == 4 then
            b:SetPoint("TOPLEFT", stateLinkFirst, "BOTTOMLEFT", 0, -LINK_GAP)
        else
            b:SetPoint("LEFT", stateLinkPrev, "RIGHT", LINK_GAP, 0)
        end

        b:SetScript("OnClick", links[i][3] == "CoARUOptionsReportButton"
            and links[i][2] or openFromOptions(links[i][2]))
        if i == 1 then stateLinkFirst = b end
        stateLinkPrev = b
    end
    order[#order + 1] = { label = "Состояние" }

    for i = 1, #order do addTab(order[i].label, i) end

    local close = styledButton(f, BTN_W, CTRL_H, "Закрыть", true)
    close:SetPoint("BOTTOMRIGHT", -PAD, (FOOTER_H - CTRL_H) / 2)
    close:SetScript("OnClick", function() f:Hide() end)

    local allOn = styledButton(f, BTN_W, CTRL_H, "Включить все", false,
        "CoARUOptionsAllOnButton")
    allOn:SetPoint("BOTTOMRIGHT", -(PAD + BTN_W + 10), (FOOTER_H - CTRL_H) / 2)
    allOn:SetScript("OnClick", function()
        CoARU_ReloadAskSuppressed = true
        for i = 1, #rows do
            CoARU_SetMod(rows[i].key, true)
            rows[i].cb:SetChecked(true)
        end
        CoARU_ReloadAskSuppressed = false
        syncPresets()
        if CoARU_AskReload then CoARU_AskReload("all", true) end
    end)

    local allOff = styledButton(f, BTN_W, CTRL_H, "Выключить все", false,
        "CoARUOptionsAllOffButton")
    allOff:SetPoint("BOTTOMRIGHT", -(PAD + (BTN_W + 10) * 2), (FOOTER_H - CTRL_H) / 2)
    allOff:SetScript("OnClick", function()
        CoARU_ReloadAskSuppressed = true
        for i = 1, #rows do
            CoARU_SetMod(rows[i].key, false)
            rows[i].cb:SetChecked(false)
        end
        CoARU_ReloadAskSuppressed = false
        syncPresets()
        if CoARU_AskReload then CoARU_AskReload("all", false) end
    end)

    local reloadBtn = styledButton(f, 150, CTRL_H, "Перезагрузить", true,
        "CoARUOptionsReloadButton")
    reloadBtn:SetPoint("BOTTOMLEFT", PAD, (FOOTER_H - CTRL_H) / 2)
    reloadBtn:SetScript("OnClick", function() ReloadUI() end)

    local reloadNote = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    reloadNote:SetPoint("LEFT", reloadBtn, "RIGHT", 12, 0)
    reloadNote:SetPoint("RIGHT", allOff, "LEFT", -12, 0)
    reloadNote:SetJustifyH("LEFT")
    reloadNote:SetTextColor(0.62, 0.62, 0.68)
    if CoARU_SkinFont then CoARU_SkinFont(reloadNote, 11) end

    local function refreshReload()
        local n, names = CoARU_ReloadList()
        if n == 0 then
            reloadBtn:Hide()
            reloadNote:Hide()
            return
        end
        reloadBtn:Show()
        reloadNote:Show()
        local short = ("Ждут перезагрузки: %d"):format(n)
        reloadNote:SetText("Ждут перезагрузки: " .. table.concat(names, ", "))

        local avail = (reloadNote.GetWidth and reloadNote:GetWidth()) or 0
        local need = (reloadNote.GetStringWidth and reloadNote:GetStringWidth()) or 0

        if avail <= 0 or need <= 0 or need > avail then reloadNote:SetText(short) end
    end

    reloadBtn:SetScript("OnEnter", function(self)
        local n, names = CoARU_ReloadList()
        if n == 0 then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")

        GameTooltip:AddLine("Перезагрузка интерфейса")
        GameTooltip:AddLine("Тултипы станут английскими сразу, при следующем наведении."
            .. " Надписи окон уже нарисованы, поэтому английский появится в них только"
            .. " после перезагрузки.", 0.8, 0.8, 0.85, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(table.concat(names, ", "), 1, 0.5, 0.5, true)
        GameTooltip:Show()
    end)
    reloadBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    CoARU_ReloadNoteChanged = refreshReload
    refreshReload()

    f:SetScript("OnShow", function(self)
        for i = 1, #rows do
            local r = rows[i]
            r.cb:SetChecked(CoARU_ModOn(r.key))

            r.card:SetBlocked(CoARU_ModBlocked and CoARU_ModBlocked(r.key) or nil)
        end
        refreshState()
        refreshReload()
        mapsCB:SetChecked(CoARU_RuMaps and CoARU_RuMaps() == true)
        iconCB:SetChecked(not (CoARU_DB.opts and CoARU_DB.opts.minimapHide))

        self:SetAlpha(1)
        selectPane((CoARU_DB.opts and CoARU_DB.opts.optTab) or 1)
    end)

    f.coaruPanes, f.coaruSelectPane = panes, selectPane

    f:Hide()
    optionsFrame = f
    return f
end

CoARU_BuildOptionsFrame = ensureOptionsFrame

function CoARU_ShowOptions()

    local ok, err = pcall(function()
        local f = ensureOptionsFrame()
        if f then f:Show() end
    end)
    if not ok then
        msg("окно настроек не открылось: " .. tostring(err))
        return false
    end
    return true
end

local minimapButton
local MM_RADIUS = 80

local function minimapAngle()
    local a = CoARU_DB and CoARU_DB.opts and CoARU_DB.opts.minimapAngle
    return tonumber(a) or 200
end

local function placeMinimapButton()
    if not minimapButton then return end
    local a = math.rad(minimapAngle())
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(a) * MM_RADIUS, math.sin(a) * MM_RADIUS)
end

local function ensureMinimapButton()
    if minimapButton then return minimapButton end
    if not Minimap or not CreateFrame then return nil end

    local b = CreateFrame("Button", "CoARUMinimapButton", Minimap)
    b:SetWidth(33)
    b:SetHeight(33)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetMovable(true)

    local icon = b:CreateTexture(nil, "BACKGROUND")
    icon:SetPoint("CENTER", 0, 1)

    local own = icon:SetTexture("Interface\\AddOns\\CoARU\\Textures\\minimap.tga") and true or false
    if own then

        icon:SetWidth(34)
        icon:SetHeight(34)
    else
        icon:SetWidth(20)
        icon:SetHeight(20)

        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        local border = b:CreateTexture(nil, "OVERLAY")
        border:SetWidth(53)
        border:SetHeight(53)
        border:SetPoint("TOPLEFT")
        border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    end

    local loadedCount
    local function loaded()
        if not loadedCount then
            loadedCount = 0
            for _ in pairs(CoARU_LOC_EN or {}) do loadedCount = loadedCount + 1 end
        end
        return loadedCount
    end

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        local ver = (GetAddOnMetadata and GetAddOnMetadata("CoARU", "Version")) or ""
        GameTooltip:AddLine("|cffC495DDCoARU|r"
            .. (ver ~= "" and ("  |cff888888v" .. ver .. "|r") or ""))
        GameTooltip:AddLine("русификатор Conquest of Azeroth", 0.7, 0.7, 0.75)

        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Переводов в базе", groupNum(loaded()),
            0.8, 0.8, 0.85, 1, 0.82, 0)

        local miss = CoARU_MissCount and CoARU_MissCount() or 0
        if miss > 0 then
            GameTooltip:AddDoubleLine("Собрано для перевода", groupNum(miss),
                0.8, 0.8, 0.85, 1, 0.82, 0)
        end

        local offN, offList = CoARU_ModsOff()
        if offN > 0 then
            GameTooltip:AddDoubleLine("Выключено",
                ("%d из %d"):format(offN, #CoARU_MODULES),
                0.8, 0.8, 0.85, 1, 0.5, 0.5)
            if offN <= 4 then
                GameTooltip:AddLine(table.concat(offList, ", "), 1, 0.5, 0.5, true)
            end
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Левый клик: настройки", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("Правый клик: отчет для переводчика", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("Shift + клик: окно приветствия", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("Ctrl + клик: кто помог переводу", 0.9, 0.9, 0.9)

        GameTooltip:AddLine("Где взять аддон и обновления: /coaru link", 0.72, 0.72, 0.78)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local function toggle(frameName, open)
        local w = _G[frameName]
        if w and w.IsShown and w:IsShown() then
            w:Hide()
            return
        end
        open()
    end

    b:SetScript("OnClick", function(_, button)

        if IsShiftKeyDown and IsShiftKeyDown() then
            toggle("CoARUWelcomeFrame", function()
                local fn = SlashCmdList and SlashCmdList["COARU"]
                if fn then fn("welcome") end
            end)
        elseif IsControlKeyDown and IsControlKeyDown() then
            toggle("CoARUThanksFrame", CoARU_ShowThanks)
        elseif button == "RightButton" then

            runStatusReport()
        else
            toggle("CoARUOptionsFrame", CoARU_ShowOptions)
        end
    end)

    local function dragUpdate()
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local s = Minimap:GetEffectiveScale()
        if not (mx and my and px and py and s and s > 0) then return end
        px, py = px / s, py / s
        CoARU_DB.opts = CoARU_DB.opts or {}
        CoARU_DB.opts.minimapAngle = math.deg(math.atan2(py - my, px - mx))
        placeMinimapButton()
    end
    b:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", dragUpdate)
    end)
    b:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    minimapButton = b
    placeMinimapButton()
    return b
end

function CoARU_UpdateMinimapButton()
    local hide = CoARU_DB and CoARU_DB.opts and CoARU_DB.opts.minimapHide
    if hide then
        if minimapButton then minimapButton:Hide() end
        return
    end
    local b = ensureMinimapButton()
    if b then
        placeMinimapButton()
        b:Show()
    end
end

local welcomeTimer = CreateFrame("Frame")
welcomeTimer:Hide()
local welcomeWait, welcomeArmed = 0, false
welcomeTimer:SetScript("OnUpdate", function(self, elapsed)
    welcomeWait = welcomeWait + elapsed
    if welcomeWait < 3 then return end
    self:Hide()
    maybeShowWelcome()
end)

local function armWelcome()
    if welcomeArmed then return end
    welcomeArmed = true
    welcomeWait = 0
    welcomeTimer:Show()
end

local missTbl, missN = nil, 0

local function missCount(m)
    if m ~= missTbl then
        missTbl, missN = m, 0
        for _ in pairs(m) do missN = missN + 1 end
    end
    return missN
end

local function purgeSent()
    local m = CoARU_DB.miss
    if type(m) ~= "table" then return 0 end
    local n = 0
    for norm, rec in pairs(m) do
        if type(rec) == "table" and rec.sent then
            m[norm] = nil
            n = n + 1
        end
    end

    if m == missTbl then missN = missN - n end
    return n
end

function CoARU_MissCount()
    return missCount(CoARU_DB and CoARU_DB.miss or {})
end

function CoARU_PurgeSentForTest()
    return purgeSent()
end

local function initDB()
    CoARU_DB.dump = CoARU_DB.dump or {}
    CoARU_DB.opts = CoARU_DB.opts or {}
    CoARU_DB.miss = CoARU_DB.miss or {}
    if CoARU_DB.opts.hover == nil then CoARU_DB.opts.hover = false end
    if CoARU_DB.opts.questdump == nil then CoARU_DB.opts.questdump = false end

    CoARU_DB.ver = (GetAddOnMetadata and GetAddOnMetadata("CoARU", "Version")) or "?"
end

function CoARU_LoadReport()
    if not CoARU_DeflateStatus or CoARU_DeflateStatus() then return "ok" end
    if CoARU_CHUNK_EN ~= nil then return "stale" end
    return "broken"
end

local MISS_CAP_DEFAULT = 15000

CoARU_MissCap = function() return MISS_CAP_DEFAULT end
local function missCap()
    if CoARU_DB and CoARU_DB.opts and CoARU_DB.opts.misscap then
        return CoARU_DB.opts.misscap
    end
    return MISS_CAP_DEFAULT
end
CoARU_MissDropped = 0

local FOREIGN_OWNERS = {
    "Bagnon", "AtlasLoot", "Details", "LibDBIcon", "ErrorHandler", "pfQuest", "Decursive",
    "Bartender", "BT4Button", "Skada", "Recount", "WeakAuras", "TitanPanel", "OmniCC",
    "XPerl", "Quartz", "DragonUI", "AceGUI", "Postal", "Auctionator", "Dominos", "ElvUI",
}

local QUEST_OWNERS = { "WorldMapFrame", "WatchFrame", "QuestLogScrollFrame" }

local NOISE_OWNERS = { "Toast" }

local function skipByOwner(owner, line)
    if type(owner) ~= "string" or owner == "" then return false end
    for _, frag in ipairs(FOREIGN_OWNERS) do
        if owner:find(frag, 1, true) then return true end
    end
    for _, frag in ipairs(NOISE_OWNERS) do
        if owner:find(frag, 1, true) then return true end
    end
    if line and line:sub(1, 2) == "- " then
        for _, frag in ipairs(QUEST_OWNERS) do
            if owner:find(frag, 1, true) then return true end
        end
    end
    return false
end

local function foldPlayerName(s)
    local p = UnitName and UnitName("player")
    if not p or #p < 4 or p:find("[^%a]") then return s end
    return (s:gsub("%f[%a]" .. p .. "%f[%A]", "$N"))
end

local function noteOneLine(kind, line, owner)
    if not line or not CoARU_DB or not CoARU_DB.miss then return end

    if CoARU_DeflateStatus and not CoARU_DeflateStatus() then return end
    if skipByOwner(owner, line) then return end

    if kind ~= "mixed" and CoARU_HasCyrillic(line) then return end
    local plain = CoARU_StripCodes(line)
    if not plain or not plain:find("%a") then return end

    if #plain <= 24 and plain:find("%d") and CoARU_LatinIsLegit
       and CoARU_LatinIsLegit(plain) then
        return
    end
    plain = foldPlayerName(plain)
    local norm = CoARU_Norm(plain)
    if not norm or #norm < 4 then return end
    local m = CoARU_DB.miss
    local rec = m[norm]
    if rec then
        rec.n = (rec.n or 1) + 1

        rec.at = (date and date("%d.%m %H:%M")) or rec.at
        return
    end
    local n = missCount(m)
    local cap = missCap()
    if n >= cap then

        purgeSent()
        n = missCount(m)
        if n >= cap then

            CoARU_MissDropped = (CoARU_MissDropped or 0) + 1
            if CoARU_MissDropped == 1 or CoARU_MissDropped % 500 == 0 then
                print(("|cffC495DDCoARU|r: |cffff0000копилка переполнена|r (%d записей), потеряно уже %d. Подними потолок: /coaru misscap 20000")
                    :format(cap, CoARU_MissDropped))
            end
            return
        end
    end

    m[norm] = { n = 1, k = kind, ex = plain, own = owner, ts = (time and time()) or 0,
                at = (date and date("%d.%m %H:%M")) or nil }
    missN = missN + 1
end

local GUILD_UNITS = { "mouseover", "target", "focus", "player",
                      "mouseovertarget", "targettarget" }

local SEEN_GUILD = {}

local function rememberGuild(unit)
    if not GetGuildInfo then return end
    if UnitExists and not UnitExists(unit) then return end
    local ok, g = pcall(GetGuildInfo, unit)
    if ok and type(g) == "string" and g ~= "" then SEEN_GUILD[g] = true end
end

local function scanGroupGuilds()
    rememberGuild("player")
    local n = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    if n > 0 then
        for i = 1, n do rememberGuild("raid" .. i) end
        return
    end
    n = (GetNumPartyMembers and GetNumPartyMembers()) or 0
    for i = 1, n do rememberGuild("party" .. i) end
end

if CreateFrame then
    local gf = CreateFrame("Frame")
    for _, ev in ipairs({ "PLAYER_ENTERING_WORLD", "RAID_ROSTER_UPDATE",
                          "PARTY_MEMBERS_CHANGED", "PLAYER_GUILD_UPDATE" }) do
        pcall(gf.RegisterEvent, gf, ev)
    end
    gf:SetScript("OnEvent", scanGroupGuilds)
end

function CoARU_IsGuildLine(t)
    if type(t) ~= "string" or t == "" or not GetGuildInfo then return false end
    local plain = CoARU_StripCodes and CoARU_StripCodes(t) or t
    if SEEN_GUILD[plain] or SEEN_GUILD[t] then return true end
    for i = 1, #GUILD_UNITS do
        local u = GUILD_UNITS[i]
        if not UnitExists or UnitExists(u) then
            local ok, g = pcall(GetGuildInfo, u)
            if ok and type(g) == "string" and g ~= "" then
                SEEN_GUILD[g] = true

                if CoARU_NoteGuildName then CoARU_NoteGuildName(g) end
                if g == plain or g == t then return true end
            end
        end
    end
    return false
end

function CoARU_GuildsSeen()
    local n = 0
    for _ in pairs(SEEN_GUILD) do n = n + 1 end
    return n
end

function CoARU_NoteMiss(kind, text, owner)
    if not text then return end

    if CoARU_IsGuildLine(text) then return end

    if CoARU_IsPersonLine and CoARU_IsPersonLine(text) then return end
    if not text:find("\n") then
        noteOneLine(kind, text, owner)
        return
    end

    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        if line:find("%S") then noteOneLine(kind, line, owner) end
    end
end

function CoARU_NoteItemMiss(text)
    CoARU_NoteMiss("item", text)
end

function CoARU_NoteBlockMisses(kind, id, text)
    if not text then return end
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        if line:find("%S") and not CoARU_LineTranslated(id, line) then
            CoARU_NoteMiss(kind, line)
        end
    end
end

local function colorOf(fs)
    if not (fs and fs.GetTextColor) then return "?" end
    local ok, r, g, b = pcall(fs.GetTextColor, fs)
    if not ok or not r then return "?" end
    return string.format("%.2f/%.2f/%.2f", r, g, b)
end

local function showCodes(s)
    if type(s) ~= "string" then return tostring(s) end
    return (s:gsub("|", "||"):gsub("\n", "\\n"))
end

local EARLY = setmetatable({}, { __mode = "k" })

local function noteEarlyColor(fs, t)
    if not (fs and t) then return end
    local rec = EARLY[fs]
    if rec and rec.t == t then return end
    EARLY[fs] = { t = t, c = colorOf(fs) }
end

local lateFrame = CreateFrame("Frame")
lateFrame:Hide()
local latePending
lateFrame:SetScript("OnUpdate", function(self)
    self:Hide()
    local p = latePending
    latePending = nil
    if not (p and CoARU_LastTip) then return end
    for k, fs in pairs(p) do
        if CoARU_LastTip[k] then
            CoARU_LastTip[k] = CoARU_LastTip[k] .. "  -> через кадр: [" .. colorOf(fs) .. "]"
        end
    end

    if CoARU_RecLines then CoARU_RecordLines() end
end)

local function snapshotTip(tip, name, id)
    CoARU_LastTip = { id = id }
    local fsByKey = {}
    for i = 1, tip:NumLines() do
        for _, side in ipairs({ "TextLeft", "TextRight" }) do
            local fs = _G[name .. side .. i]
            local t = fs and fs:GetText()
            if t and t ~= " " then
                local k = #CoARU_LastTip + 1
                local early = EARLY[fs]
                local pre = (early and early.t == t) and ("рано: [" .. early.c .. "] ") or ""
                CoARU_LastTip[k] = side .. i .. " " .. pre .. "[" .. colorOf(fs) .. "] = [["
                    .. showCodes(t) .. "]]"
                fsByKey[k] = fs
            end
        end
    end
    return fsByKey
end

local function snapshotAfter(fsByKey)
    if not fsByKey then return end
    for k, fs in pairs(fsByKey) do
        if CoARU_ReapplyColor then CoARU_ReapplyColor(fs) end
        if CoARU_LastTip and CoARU_LastTip[k] then

            local ok, cur = pcall(fs.GetText, fs)
            CoARU_LastTip[k] = CoARU_LastTip[k] .. "  -> стало: [" .. colorOf(fs) .. "] = [["
                .. (ok and showCodes(cur) or "?") .. "]]"
        end
    end

    latePending = fsByKey
    lateFrame:Show()
end

function CoARU_RecordLines()
    if not (CoARU_LastTip and CoARU_DB) then return 0 end
    CoARU_DB.lines = CoARU_DB.lines or {}
    local rec = { id = CoARU_LastTip.id }
    for k, v in ipairs(CoARU_LastTip) do rec[k] = v end
    if rec.id ~= nil then
        for i, e in ipairs(CoARU_DB.lines) do
            if e.id == rec.id then CoARU_DB.lines[i] = rec; return #CoARU_DB.lines end
        end
    end
    table.insert(CoARU_DB.lines, rec)
    return #CoARU_DB.lines
end

local function translateSpellName(fs)
    if not CoARU_ModOn("spellnames") or not CoARU_SPELL_NAME_RU then return false end
    local t = fs and fs.GetText and fs:GetText()
    if not t or t == "" or CoARU_HasCyrillic(t) then return false end
    local plain = CoARU_StripCodes(t):gsub("^%s+", ""):gsub("%s+$", "")
    local ru = plain ~= "" and CoARU_SPELL_NAME_RU[plain]
    if not ru then return false end
    CoARU_SetTranslated(fs, t, ru)
    return true
end

local function translateIconName(fs)
    if not CoARU_ModOn("spellnames") or not CoARU_SPELL_NAME_RU then return false end
    local t = fs and fs.GetText and fs:GetText()
    if not t or CoARU_HasCyrillic(t) then return false end
    local lead, body = t:match("^([%s]*|T[^|]*|t%s*)(.+)$")
    if not lead then lead, body = t:match("^(%s*)(.+)$") end
    if not body then return false end
    local tail = body:match("(%s*)$") or ""
    local name = CoARU_StripCodes(body):gsub("^%s+", ""):gsub("%s+$", "")
    local ru = name ~= "" and CoARU_SPELL_NAME_RU[name]
    if not ru then return false end
    CoARU_SetTranslated(fs, t, lead .. ru .. tail)
    return true
end

local function onTooltipSetSpell(tip)

    if CoARU_ScanRaw then return end
    if not CoARU_ModOn("spells") then return end
    local ok, id = pcall(function() return select(3, tip:GetSpell()) end)
    if not ok or not id then return end
    id = tonumber(id)
    if not id then return end

    if CoARU_DB.opts.hover then
        local ok, why = CoARU_RecordSpell(id)
        if ok then
            msg("записал в дамп: " .. id)
        else
            msg("не записал " .. id .. ": " .. (why or "?"))
        end
    end

    local name = tip:GetName()
    if not name then return end

    local snapFS = snapshotTip(tip, name, id)

    local changed = false
    local function handle(fs)
        local t = fs and fs:GetText()

        if not (t and #t > 2 and t:find("%S")) then return end

        if translateIconName(fs) then changed = true return end

        CoARU_NoteBlockMisses("spell", id, t)
        local ru = CoARU_TranslateBlock(id, t)
        if ru and ru ~= t then
            CoARU_SetTranslated(fs, t, ru)
            changed = true
        else
            local cleaned = CoARU_CleanMarkers(t, 0, id)
            if cleaned and cleaned ~= t then
                fs:SetText(cleaned)
                changed = true
            end
        end
    end

    if translateSpellName(_G[name .. "TextLeft1"]) then changed = true end
    for i = 2, tip:NumLines() do
        handle(_G[name .. "TextLeft" .. i])
        handle(_G[name .. "TextRight" .. i])
    end
    if changed then
        tip:Show()
    end

    snapshotAfter(snapFS)
end

local DELTA_HEADER_EN = "If you replace this item"
local DELTA_HEADER_RU = "Если заменить этот предмет"

local FOREIGN_BLOCK = { "Stat Summary", "Сводка характеристик" }

local FOREIGN_LABELS = {
    ["Stat Summary"] = "Сводка характеристик",
    ["Health"] = "Здоровье",
    ["Mana"] = "Мана",
    ["Armor"] = "Броня",
    ["Attack Power"] = "Сила атаки",
    ["Feral Attack Power"] = "Сила атаки в облике зверя",
    ["Spell Power"] = "Сила заклинаний",
    ["Spell Damage"] = "Урон от заклинаний",
    ["Healing"] = "Исцеление",
    ["Mana Regen"] = "Восполнение маны",
    ["Health Regen"] = "Восстановление здоровья",
    ["Strength"] = "Сила",
    ["Agility"] = "Ловкость",
    ["Stamina"] = "Выносливость",
    ["Intellect"] = "Интеллект",
    ["Spirit"] = "Дух",
    ["Defense"] = "Защита",
    ["Expertise"] = "Мастерство",
    ["Resilience"] = "Устойчивость",
    ["Armor Penetration"] = "Пробивание брони",

    ["Spell Penetration"] = "Проникающая способность заклинаний",
    ["Block Value"] = "Блокирование",
    ["Weapon Skill"] = "Владение оружием",

    ["Feral Сила атаки"] = "Сила атаки в облике зверя",
    ["Hit Chance(%)"] = "Меткость(%)",
    ["Магия Hit Chance(%)"] = "Меткость заклинаний(%)",
    ["Магия Урон"] = "Урон заклинаниями",
    ["Магия Крит. удар(%)"] = "Крит. удар заклинаний(%)",
    ["Магия Исцеление"] = "Исцеление заклинаниями",
}

local function foreignBlockLine(t)
    if not t then return false end
    for i = 1, #FOREIGN_BLOCK do
        if t:find(FOREIGN_BLOCK[i], 1, true) then return true end
    end
    return false
end

local function foreignLabelRU(t)
    if not t then return nil end
    local plain = CoARU_StripCodes and CoARU_StripCodes(t) or t
    plain = plain:match("^%s*(.-)%s*$")
    local ru = FOREIGN_LABELS[plain]
    if ru and ru ~= plain then return ru end

    local bare = plain:gsub("^[^A-Za-z]+", "")
    if bare ~= plain then
        ru = FOREIGN_LABELS[bare]
        if ru and ru ~= bare then
            local head = plain:sub(1, #plain - #bare)
            return head .. ru
        end
    end
    return nil
end

local function translateForeignBlock(tip, name)
    if not tip or not name or not tip.NumLines then return false end
    local seen, changed = false, false
    for i = 1, tip:NumLines() do
        local fs = _G[name .. "TextLeft" .. i]
        local t = fs and fs.GetText and fs:GetText()
        if t and t ~= "" then
            if not seen and foreignBlockLine(t) then seen = true end
            if seen then
                local ru = foreignLabelRU(t)
                if ru then
                    CoARU_SetTranslated(fs, t, ru)
                    changed = true
                elseif CoARU_NoteMiss and not (CoARU_HasCyrillic and CoARU_HasCyrillic(t))
                    and t:find("%a%a%a") then

                    CoARU_NoteMiss("tip", t, "StatSummary")
                end
            end
        end
    end
    return changed
end

local function colorizeDelta(ru)

    local body = ru:match("^|[cC]%x%x%x%x%x%x%x%x(.*)$") or ru
    body = body:gsub("|r$", "")
    local sign, num, rest = body:match("^([%+%-])([%d%.,]+)(.*)$")
    if not sign then return ru end
    local hex = (sign == "+") and "ff1eff00" or "ffff2020"
    return "|c" .. hex .. sign .. num .. "|r|cffffffff" .. rest .. "|r"
end

local LEGIT_LATIN = {
    Shift = true, SHIFT = true, Ctrl = true, CTRL = true, Alt = true, ALT = true,
    PvE = true, PvP = true, DPS = true, LFG = true, RP = true, AoE = true, ID = true,

    PVE = true, PVP = true, PVM = true,
    XP = true, HP = true, MP = true, NPC = true, UI = true, FPS = true, Enter = true,

    RaF = true, CD = true, AFK = true, DND = true, BG = true,

    Ascension = true, Discord = true, Facebook = true, Nvidia = true,
    YouTube = true, Twitch = true, WOTLK = true,
    I = true, II = true, III = true, IV = true, V = true, VI = true, VII = true,
    VIII = true, IX = true, X = true, XI = true, XII = true,
}

local TLD = { "gg", "com", "net", "org", "io", "tv", "me", "ru", "dev" }

function CoARU_StripUrls(t)
    if type(t) ~= "string" or t == "" then return t end
    if not (t:find("//", 1, true) or t:find(".", 1, true)) then return t end
    t = t:gsub("%a+://%S+", " ")
    for i = 1, #TLD do
        t = t:gsub("[%w%-%.]+%." .. TLD[i] .. "%f[%W]%S*", " ")
    end
    return t
end

local function latinRuns(t)
    local out = {}
    for run in t:gmatch("[A-Za-z][A-Za-z'%-]*[A-Za-z0-9]*[ A-Za-z'%-0-9]*") do
        run = run:match("^%s*(.-)%s*$")

        run = run:gsub("^[%-']+", ""):gsub("[%-']+$", "")
        if run ~= "" then out[#out + 1] = run end
    end
    return out
end

local function knownLatin(run)
    if LEGIT_LATIN[run] then return true end
    if CoARU_ZONE and CoARU_ZONE[run] then return true end
    if CoARU_SPELL_NAME_RU and CoARU_SPELL_NAME_RU[run] then return true end
    if CoARU_ItemNameEN and CoARU_ItemNameEN[run] then return true end

    local all = true
    local any = false
    for w in run:gmatch("[A-Za-z][A-Za-z'%-]*") do
        any = true
        if not (LEGIT_LATIN[w] or (CoARU_ZONE and CoARU_ZONE[w])) then all = false end
    end
    return any and all
end

function CoARU_LatinIsAbbrev(word)
    return type(word) == "string" and LEGIT_LATIN[word] == true
end

function CoARU_LatinIsLegit(t)
    if type(t) ~= "string" then return false end
    t = CoARU_StripUrls(t)
    for _, run in ipairs(latinRuns(t)) do
        if #run >= 2 and not knownLatin(run) then

            if not t:find("«" .. run .. "»", 1, true) then return false end
        end
    end
    return true
end

local function clientRewritesLine(t)
    if not t then return false end
    local plain = CoARU_StripCodes(t)
    if not plain or plain == "" then return false end
    if plain:sub(1, 2) == '"@' then return true end

    local heroic = (CoARU_EN and CoARU_EN("ITEM_HEROIC")) or _G.ITEM_HEROIC
    if heroic and heroic ~= "" and plain:sub(1, #heroic) == heroic then
        return true
    end
    return false
end

local onTooltipSetItem

function CoARU_RefreshTooltip(tip)
    if not tip or not tip.GetName or not tip:GetName() then return end
    local ok, link = pcall(function() return tip.GetItem and select(2, tip:GetItem()) end)
    if ok and link and onTooltipSetItem then pcall(onTooltipSetItem, tip) end
end

local orderHooked
local function orderPut(line)
    if not (CoARU_DB and CoARU_DB.opts and CoARU_DB.opts.order) then return end
    CoARU_DB.order = CoARU_DB.order or {}
    if #CoARU_DB.order >= 400 then return end
    CoARU_DB.order[#CoARU_DB.order + 1] = line
end

function CoARU_NoteOrder(stage, tip)
    if not (CoARU_DB and CoARU_DB.opts and CoARU_DB.opts.order) then return end
    local name = tip and tip.GetName and tip:GetName()
    if not name then return end
    local fs = _G[name .. "TextLeft2"]
    orderPut(("CoARU %s %s: строка2=[%s]"):format(name, stage, tostring(fs and fs:GetText())))
end

function CoARU_HookOrderChat()
    if orderHooked or not DEFAULT_CHAT_FRAME or not DEFAULT_CHAT_FRAME.AddMessage then return end
    orderHooked = true
    hooksecurefunc(DEFAULT_CHAT_FRAME, "AddMessage", function(_, msg)
        if type(msg) == "string" then orderPut("ЧУЖОЕ " .. msg) end
    end)
end

function CoARU_SplitItemSuffix(itemName, suffixID)
    if type(itemName) ~= "string" or itemName == "" then return nil end
    if not (CoARU_ITEM_SUFFIX and CoARU_ITEM_SUFFIX_TEXT) then return nil end
    local pair = CoARU_ITEM_SUFFIX_TEXT[CoARU_ITEM_SUFFIX[suffixID] or 0]
    if not pair then return nil end

    local tail = " " .. pair[1]
    if #itemName <= #tail then return nil end
    if itemName:sub(-#tail):lower() ~= tail:lower() then return nil end
    return itemName:sub(1, #itemName - #tail), pair[2]
end

function onTooltipSetItem(tip)
    CoARU_NoteOrder("OnTooltipSetItem вход", tip)
    if not CoARU_ModOn("items") then return end
    local name = tip:GetName()
    if not name or not tip.GetItem then return end
    local ok, itemName, link = pcall(tip.GetItem, tip)
    if not ok or not link then return end
    local id = tonumber(link:match("item:(%d+)"))
    if not id then return end

    tip.coaruSetItemDone = link

    local snapFS = snapshotTip(tip, name, id)

    local changed = false

    local suffixID = tonumber(link:match(
        "item:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:(%-?%d+)"))
    local hasSuffix = suffixID ~= nil and suffixID ~= 0

    local askName, suffRU = itemName, nil
    if hasSuffix and CoARU_ModOn("itemnames") then
        local baseEN, suff = CoARU_SplitItemSuffix(itemName, suffixID)
        if baseEN then askName, suffRU = baseEN, suff end
    end

    local nameOK = (not hasSuffix) or (suffRU ~= nil)
    local ru = nameOK and CoARU_ModOn("itemnames")
        and CoARU_ItemName and CoARU_ItemName[id] or nil

    if not ru and nameOK and CoARU_ModOn("itemnames")
        and CoARU_ItemNameEN and type(askName) == "string" and askName ~= "" then
        local byText = CoARU_ItemNameEN[askName]
        if byText and byText ~= askName then ru = byText end
    end

    if ru and suffRU then ru = ru .. " " .. suffRU end
    if ru and type(itemName) == "string" and itemName ~= "" then
        local last = math.min(tip:NumLines() or 1, 3)
        for i = 1, last do
            local fs = _G[name .. "TextLeft" .. i]
            local t = fs and fs:GetText()
            if t and not CoARU_HasCyrillic(t) and CoARU_StripCodes(t) == itemName then
                CoARU_SetTranslated(fs, t, ru)
                changed = true
                break
            end
        end

    elseif CoARU_NoteMiss and nameOK and CoARU_ModOn("itemnames")
        and type(askName) == "string" and askName ~= ""
        and not CoARU_HasCyrillic(askName) and askName:find("%a%a%a") then
        CoARU_NoteMiss("itemname", askName)
    end

    local desc = CoARU_ItemDesc and CoARU_ItemDesc[id]

    local inDelta = false
    local foreign = false
    for i = 2, tip:NumLines() do

        if foreign then break end
        for _, side in ipairs({ "TextLeft", "TextRight" }) do
            local fs = _G[name .. side .. i]
            local t = fs and fs:GetText()
            if t and side == "TextLeft" and foreignBlockLine(t) then foreign = true end
            if foreign then break end

            if t and CoARU_IsGuildLine and CoARU_IsGuildLine(t) then t = nil end
            if t and side == "TextLeft" and t:find("%S")
                and (t:find(DELTA_HEADER_EN, 1, true) or t:find(DELTA_HEADER_RU, 1, true)) then
                inDelta = true
            end

            if t and #t > 2 and t:find("%S") and CoARU_HasCyrillic(t) then

                local lab = CoARU_TranslateItemLabel and CoARU_TranslateItemLabel(t)

                if not (lab and lab ~= t) and CoARU_TranslateItemPrefix then
                    lab = CoARU_TranslateItemPrefix(t)
                end
                if lab and lab ~= t then
                    CoARU_SetTranslated(fs, t, lab)
                    changed = true
                    t = lab
                elseif CoARU_RegisterClientLine then
                    CoARU_RegisterClientLine(fs, t)
                end

                if CoARU_NoteMiss and t:find("%a") and t:find("[A-Za-z][A-Za-z][A-Za-z]")
                    and not (lab and lab ~= t) and not CoARU_LatinIsLegit(t) then
                    CoARU_NoteMiss("mixed", t)
                end
            end
            if t and #t > 2 and t:find("%S") and not CoARU_HasCyrillic(t)
                and not clientRewritesLine(t) then

                if desc and side == "TextLeft" and t:match('^".*"$') then
                    CoARU_SetTranslated(fs, t, '"' .. desc .. '"')
                    changed = true
                else

                    local nameLine
                    if side == "TextLeft" and CoARU_ItemNameLine and CoARU_ModOn("itemnames") then
                        nameLine = CoARU_ItemNameLine(CoARU_StripCodes(t))
                    end

                    if not nameLine and side == "TextLeft" and CoARU_ZoneLineRU then
                        nameLine = CoARU_ZoneLineRU(CoARU_StripCodes(t))
                    end
                    if not nameLine and side == "TextLeft" and CoARU_SummonTitleRU then
                        nameLine = CoARU_SummonTitleRU(CoARU_StripCodes(t))
                    end

                    if not nameLine and CoARU_ItemLinkLineRU then
                        nameLine = CoARU_ItemLinkLineRU(t)
                    end

                    if t ~= itemName and not nameLine then
                        CoARU_NoteBlockMisses("item", nil, t)
                    end
                    local r = nameLine or CoARU_TranslateBlock(nil, t)

                    if not (r and r ~= t) and CoARU_TranslateItemPrefix then
                        r = CoARU_TranslateItemPrefix(t)
                    end

                    if not (r and r ~= t) and CoARU_TranslateItemLabelBody then
                        r = CoARU_TranslateItemLabelBody(t)
                    end
                    if r and r ~= t then
                        if inDelta then r = colorizeDelta(r) end
                        CoARU_SetTranslated(fs, t, r)
                        changed = true
                    else

                        if t ~= itemName then
                            CoARU_NoteItemMiss(t)
                        end
                    end
                end
            end
        end
    end

    if translateForeignBlock(tip, name) then changed = true end

    for i = 1, 4 do
        local pf = _G[name .. "MoneyFrame" .. i .. "PrefixText"]
        local t = pf and pf:GetText()

        if t and t:find("%S") and CoARU_HasCyrillic(t) and CoARU_SetTranslated then
            local ruSell = _G["SELL_PRICE"]
            local enSell = CoARU_EN and CoARU_EN("SELL_PRICE")
            if ruSell and enSell and enSell ~= ruSell and t == ruSell .. ":" then
                CoARU_SetTranslated(pf, enSell .. ":", t)
            elseif CoARU_RegisterClientLine then
                CoARU_RegisterClientLine(pf, t)
            end
        end
        if t and t:find("%S") and not CoARU_HasCyrillic(t) then
            local r = CoARU_TranslateBlock(nil, t)
            if r and r ~= t then
                CoARU_SetTranslated(pf, t, r)
                changed = true
            else
                CoARU_NoteMiss("money", t)
            end
        end
    end

    if changed then tip:Show() end
    snapshotAfter(snapFS)
end

local CoARU_SCHOOL_RU = {
    Arcane = "Тайная магия",
    Fire = "Огонь",
    Nature = "Природа",
    Frost = "Лед",
    Shadow = "Тень",
    Holy = "Свет",
}

local CoARU_SCHOOL_DATIVE = {
    Arcane = "тайной магии",
    Fire = "огню",
    Nature = "природе",
    Frost = "льду",
    Shadow = "тьме",
    Holy = "свету",
}

local RESIST_ANCHOR = "based attacks, spells and abilities"

local SCHOOL_OWNER = "AscensionCharacterStatsPanel"

local inReprocess = false
local function onTooltipShow(tip)
    CoARU_NoteOrder("Show вход", tip)
    if inReprocess then return end
    if CoARU_ScanRaw then return end
    local name = tip:GetName()
    if not name then return end

    local isResistTip = false
    for i = 1, tip:NumLines() do
        local fs = _G[name .. "TextLeft" .. i]
        local t = fs and fs:GetText()
        noteEarlyColor(fs, t)
        noteEarlyColor(_G[name .. "TextRight" .. i], _G[name .. "TextRight" .. i]
            and _G[name .. "TextRight" .. i]:GetText())
        if t and t:find(RESIST_ANCHOR, 1, true) then
            isResistTip = true
            break
        end
    end

    local itemName, itemLink
    if tip.GetItem then
        local ok, n, l = pcall(tip.GetItem, tip)
        if ok then itemName, itemLink = n, l end
    end

    if itemLink and tip.coaruSetItemDone ~= itemLink then return end

    local isSpellTip = false
    if tip.GetSpell then
        local ok, sn = pcall(tip.GetSpell, tip)
        if ok and sn then isSpellTip = true end
    end

    if isSpellTip and not CoARU_ModOn("spells") then return end
    if itemName and itemName ~= "" and not CoARU_ModOn("items") then return end

    local ownerName
    if tip.GetOwner then
        local ok, of = pcall(tip.GetOwner, tip)
        if ok and of then
            ownerName = of.GetName and of:GetName()
            if not ownerName and of.GetParent then
                local p = of:GetParent()
                ownerName = p and p.GetName and p:GetName()
            end
        end
    end

    local isSchoolTip = CoARU_ModOn("stats") and (isResistTip
        or (ownerName ~= nil and ownerName:find(SCHOOL_OWNER, 1, true) ~= nil))
    local changed = false
    local inDelta = false
    local foreign = false
    for i = 1, tip:NumLines() do

        if foreign then break end
        for _, side in ipairs({ "TextLeft", "TextRight" }) do
            local fs = _G[name .. side .. i]
            local t = fs and fs:GetText()
            if t and side == "TextLeft" and foreignBlockLine(t) then foreign = true end
            if foreign then break end

            if t and CoARU_IsGuildLine and CoARU_IsGuildLine(t) then t = nil end
            local polluted

            if t and CoARU_Unlocalize and CoARU_HasCyrillic(t)
               and not (CoARU_OriginalPair and select(2, CoARU_OriginalPair(fs)) == t) then
                local clean = CoARU_Unlocalize(t)
                if clean ~= t then

                    fs:SetText(clean)
                    polluted, t = t, clean
                end
            end
            if t and t:find("%S") then

                if side == "TextLeft" and (t:find(DELTA_HEADER_EN, 1, true)
                    or t:find(DELTA_HEADER_RU, 1, true)) then
                    inDelta = true
                end

                local schoolRu
                if isSchoolTip then
                    local plain = CoARU_StripCodes(t):gsub("^%s+", ""):gsub("%s+$", "")
                    schoolRu = CoARU_SCHOOL_RU[plain]
                    if not schoolRu then
                        local sch, rest = plain:match("^(%a+) Resistance%s*(.*)$")
                        local dat = sch and CoARU_SCHOOL_DATIVE[sch]
                        if dat then
                            schoolRu = "Сопротивление " .. dat
                            if rest ~= "" then schoolRu = schoolRu .. " " .. rest end
                        end
                    end
                end
                if not CoARU_HasCyrillic(t) and schoolRu then
                    CoARU_SetTranslated(fs, t, schoolRu)
                    changed = true
                elseif i == 1 and side == "TextLeft" and isSpellTip then

                    if translateSpellName(fs) then changed = true end
                elseif isSpellTip and translateIconName(fs) then

                    changed = true
                elseif #t > 2 and not CoARU_HasCyrillic(t) and not clientRewritesLine(t) then

                    local ru

                    if side == "TextLeft" and CoARU_ItemNameLine
                       and CoARU_ModOn("itemnames") then
                        ru = CoARU_ItemNameLine(CoARU_StripCodes(t))
                    end

                    if not ru and side == "TextLeft" and CoARU_ZoneLineRU then
                        ru = CoARU_ZoneLineRU(CoARU_StripCodes(t))
                    end
                    if not ru and side == "TextLeft" and CoARU_SummonTitleRU then
                        ru = CoARU_SummonTitleRU(CoARU_StripCodes(t))
                    end

                    if not ru and CoARU_ItemLinkLineRU then ru = CoARU_ItemLinkLineRU(t) end

                    if not ru and side == "TextLeft" and CoARU_AchievementLineRU then
                        ru = CoARU_AchievementLineRU(CoARU_StripCodes(t))
                    end
                    if not ru then ru = CoARU_TranslateBlock(nil, t) end

                    if not (ru and ru ~= t) and CoARU_TranslateItemPrefix then
                        ru = CoARU_TranslateItemPrefix(t)
                    end

                    if not (ru and ru ~= t) and CoARU_TranslateItemLabelBody then
                        ru = CoARU_TranslateItemLabelBody(t)
                    end

                    if not (ru and ru ~= t) and CoARU_TranslateObjectiveLine then
                        ru = CoARU_TranslateObjectiveLine(t)
                    end

                    if not (ru and ru ~= t) and CoARU_ItemSourceGlueRU then
                        ru = CoARU_ItemSourceGlueRU(CoARU_StripCodes(t))
                    end
                    if not (ru and ru ~= t) and CoARU_UnitNameLineRU then
                        ru = CoARU_UnitNameLineRU(CoARU_StripCodes(t))
                    end

                    if not (ru and ru ~= t) and CoARU_QuestLookup then
                        local okq, rq = pcall(CoARU_QuestLookup, CoARU_StripCodes(t))
                        if okq and type(rq) == "string" and rq ~= "" then ru = rq end
                    end

                    if not (ru and ru ~= t) and CoARU_TranslateUnitLine then
                        ru = CoARU_TranslateUnitLine(t)
                    end

                    if not (ru and ru ~= t) and CoARU_TranslateObjectiveLine then
                        ru = CoARU_TranslateObjectiveLine(t)
                    end

                    if not (ru and ru ~= t) and CoARU_UnitNameLineRU then
                        ru = CoARU_UnitNameLineRU(CoARU_StripCodes(t))
                    end
                    if ru and ru ~= t then
                        if inDelta then ru = colorizeDelta(ru) end
                        CoARU_SetTranslated(fs, t, ru)
                        changed = true
                    elseif t ~= itemName and (i > 1 or isSchoolTip) then

                        CoARU_NoteMiss("tip", t, ownerName)
                    end
                elseif CoARU_HasCyrillic(t) and CoARU_TranslateRequires then

                    local ru = CoARU_TranslateRequires(t)

                    if not (ru and ru ~= t) and CoARU_TranslateItemPrefix then
                        ru = CoARU_TranslateItemPrefix(t)
                    end

                    if not (ru and ru ~= t) and CoARU_TranslateProfession then
                        ru = CoARU_TranslateProfession(t)
                    end

                    if not (ru and ru ~= t) and CoARU_TranslateItemLabel then
                        ru = CoARU_TranslateItemLabel(t)
                    end
                    local ten
                    if not (ru and ru ~= t) and CoARU_TimeRemaining then
                        ru, ten = CoARU_TimeRemaining(t)
                    end

                    if not (ru and ru ~= t) and CoARU_FixTimeUnits then
                        ru = CoARU_FixTimeUnits(t)
                    end
                    if ru and ru ~= t then
                        CoARU_SetTranslated(fs, ten or t, ru)
                        changed = true

                    elseif CoARU_RegisterClientLine and CoARU_RegisterClientLine(fs, t) then
                        changed = true
                    end
                end
            end

            if polluted and fs
               and not (CoARU_OriginalPair and CoARU_OriginalPair(fs) == t) then
                CoARU_SetTranslated(fs, t, polluted)
                changed = true
            end
        end
    end

    if translateForeignBlock(tip, name) then changed = true end

    if changed and CoARU_AddHint and name == "GameTooltip" then
        CoARU_AddHint(tip)
    end
    if changed then
        inReprocess = true
        tip:Show()
        inReprocess = false
    end
end

local function translateAuraTip(tip, id)
    local name = tip and tip:GetName()
    if not name or not id then return end
    local changed = false

    local l1 = _G[name .. "TextLeft1"]
    local t1 = l1 and l1:GetText()
    if t1 and t1 ~= "" and not CoARU_HasCyrillic(t1) and CoARU_ModOn("spellnames") then
        local ru = CoARU_SPELL_NAME_RU and CoARU_SPELL_NAME_RU[t1]
        if ru and ru ~= "" and ru ~= t1 then
            CoARU_SetTranslated(l1, t1, ru)
            changed = true
        end
    end

    for i = 1, tip:NumLines() do
        for _, side in ipairs({ "TextLeft", "TextRight" }) do
            local fs = (not (i == 1 and side == "TextLeft")) and _G[name .. side .. i]
            local t = fs and fs:GetText()
            if t and #t > 2 and t:find("%S") and not CoARU_HasCyrillic(t) then

                local dis = side == "TextRight" and CoARU_DispelType and CoARU_DispelType(t)
                if dis then
                    CoARU_SetTranslated(fs, t, dis)
                    changed = true
                else

                    CoARU_NoteBlockMisses("aura", id, t)
                    local ru = CoARU_TranslateBlock(id, t)
                    if ru and ru ~= t then
                        CoARU_SetTranslated(fs, t, ru)
                        changed = true
                    end
                end
            elseif t and CoARU_TimeRemaining then

                local ru, en = CoARU_TimeRemaining(t)
                if ru then
                    CoARU_SetTranslated(fs, en or t, ru)
                    changed = true
                end
            end
        end
    end
    if changed then tip:Show() end
end

local function hookAura(tip)
    if not tip then return end
    if tip.SetUnitAura then
        hooksecurefunc(tip, "SetUnitAura", function(self, unit, index, filter)
            local ok, id = pcall(function() return select(11, UnitAura(unit, index, filter)) end)

            if CoARU_NoteAuraCaster then CoARU_NoteAuraCaster(unit, index, filter) end
            if ok then translateAuraTip(self, tonumber(id)) end
        end)
    end
    if tip.SetUnitBuff then
        hooksecurefunc(tip, "SetUnitBuff", function(self, unit, index, filter)
            local ok, id = pcall(function() return select(11, UnitBuff(unit, index, filter)) end)

            if CoARU_NoteAuraCaster then CoARU_NoteAuraCaster(unit, index, filter) end
            if ok then translateAuraTip(self, tonumber(id)) end
        end)
    end
    if tip.SetUnitDebuff then
        hooksecurefunc(tip, "SetUnitDebuff", function(self, unit, index, filter)
            local ok, id = pcall(function() return select(11, UnitDebuff(unit, index, filter)) end)

            if CoARU_NoteAuraCaster then CoARU_NoteAuraCaster(unit, index, filter) end
            if ok then translateAuraTip(self, tonumber(id)) end
        end)
    end
end

local function installHooks()

    if LinkUtil and LinkUtil.AddHandler and not LinkUtil:GetHandler("coaru", "onClick") then
        LinkUtil:AddHandler("coaru", function(link)
            if link:GetArg(1) == "donate" then showDonate() end
        end)
    end
    GameTooltip:HookScript("OnTooltipSetSpell", onTooltipSetSpell)
    hooksecurefunc(GameTooltip, "Show", onTooltipShow)
    hookAura(GameTooltip)
    hookAura(ItemRefTooltip)
    if ItemRefTooltip then
        ItemRefTooltip:HookScript("OnTooltipSetSpell", onTooltipSetSpell)
        hooksecurefunc(ItemRefTooltip, "Show", onTooltipShow)
    end

    if WorldMapTooltip then
        WorldMapTooltip:HookScript("OnTooltipSetSpell", onTooltipSetSpell)
        hooksecurefunc(WorldMapTooltip, "Show", onTooltipShow)
        hookAura(WorldMapTooltip)
    end

    for _, f in ipairs({ GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2,
                         WorldMapTooltip }) do
        if f and f.HookScript then
            f:HookScript("OnTooltipSetItem", onTooltipSetItem)

            f:HookScript("OnTooltipCleared", function(self) self.coaruSetItemDone = nil end)
        end
    end

    for _, f in ipairs({ ShoppingTooltip1, ShoppingTooltip2 }) do
        if f then hooksecurefunc(f, "Show", onTooltipShow) end
    end
end

local function countDump()
    local c = 0
    for _ in pairs(CoARU_DB.dump or {}) do c = c + 1 end
    return c
end

local RELEASE = true

local PLAYER_CMDS = { [""] = true, status = true, donate = true, support = true,
                      ["спасибо"] = true, ["донат"] = true,

                      thanks = true, ["помогли"] = true, ["кто помог"] = true,

                      welcome = true, ["привет"] = true, hint = true,
                      ["hint off"] = true, ["hint on"] = true,

                      link = true, github = true, ["гит"] = true, ["ссылка"] = true,
                      update = true, ["обновление"] = true, ["обновления"] = true }

local function isOriginalCmd(cmd)
    return cmd:match("^original") or cmd:match("^оригинал") or cmd:match("^англ")
end

local function isNamesCmd(cmd)
    return cmd:match("^names") or cmd:match("^имена")
end

local function isOptionsCmd(cmd)
    return cmd == "options" or cmd == "config" or cmd == "opt"
        or cmd == "настройки" or cmd == "опции"
end

local function slash(cmd)

    cmd = (cmd or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("[A-Z]", string.lower)
    if RELEASE and not PLAYER_CMDS[cmd] and not isOriginalCmd(cmd) and not isNamesCmd(cmd)
        and not isOptionsCmd(cmd) then
        msg("доступна команда /coaru status — она показывает, что собрал аддон.")
        return
    end
    if cmd == "" then
        local t = CoARU_CountLines and CoARU_CountLines() or 0

        msg(("русификатор Conquest of Azeroth. Переведено строк: %d."):format(t))

        local key = CoARU_OriginalMod and CoARU_OriginalMod() or "ALT"
        key = key:sub(1, 1) .. key:sub(2):lower()
        print(("  |cffffd100%s|r над тултипом — показать оригинал на английском (сменить клавишу: /coaru original ctrl)"):format(key))
        print("  |cffffd100/coaru options|r — что переводить: предметы, статы, задания, имена (или значок у миникарты)")
        print("  |cffffd100/coaru link|r — где взять аддон и обновления")
        print("  |cffffd100/coaru discord|r — сервер: новости, багрепорты, помощь")
        print("  поддержать автора: " .. DONATE_LINK)
        return
    end
    if cmd == "donate" or cmd == "support" or cmd == "спасибо" or cmd == "донат" then
        showDonate()
        return
    end

    if cmd == "link" or cmd == "github" or cmd == "гит" or cmd == "ссылка"
       or cmd == "update" or cmd == "обновление" or cmd == "обновления" then
        showLink()
        return
    end

    if cmd == "discord" or cmd == "дискорд" or cmd == "сервер" or cmd == "чат"
       or cmd == "баг" or cmd == "багрепорт" or cmd == "помощь" then
        msg("Discord-сервер: новости, багрепорты, предложения по переводу, помощь.")
        if CoARU_DISCORD_OK then
            print("|cff00ff00" .. CoARU_DISCORD_OK .. "|r")
        else

            print("  сервер |cffC495DDAscension Addons RU|r")
        end
        print("  отчёты о непереведённом: канал |cffC495DD#обсуждение-coaru|r")
        return
    end
    if isOptionsCmd(cmd) then
        CoARU_ShowOptions()
        return
    end
    if cmd == "thanks" or cmd == "кто помог" or cmd == "помогли" then
        CoARU_ShowThanks()
        return
    end
    if cmd == "welcome" or cmd == "привет" then

        CoARU_DB.opts = CoARU_DB.opts or {}
        CoARU_DB.opts.welcomeVer = nil
        showWelcome()
        return
    end

    if cmd:match("^hint") then
        CoARU_DB.opts = CoARU_DB.opts or {}
        local arg = cmd:match("^hint%s+(%S+)")
        if arg == "off" or arg == "выкл" then
            CoARU_DB.opts.hint = false
            msg("подсказка про оригинал выключена.")
        elseif arg == "on" or arg == "вкл" then
            CoARU_DB.opts.hint = nil
            CoARU_DB.opts.origUsed = 0
            msg("подсказка про оригинал включена.")
        else

            local state
            if CoARU_DB.opts.hint == false then
                state = "выключена"
            elseif CoARU_HintText and not CoARU_HintText() then
                state = "погасла сама (клавишей уже пользуются)"
            else
                state = "включена"
            end
            msg("подсказка: " .. state .. ". Команды: /coaru hint on|off")
        end
        return
    end

    if isNamesCmd(cmd) then
        local arg = cmd:match("%s+(%S+)$")
        if arg == "off" or arg == "выкл" then
            CoARU_SetNames(false)
            msg("имена существ: |cffff2020английские|r. Описания, предметы и задания переводятся как прежде.")
        elseif arg == "on" or arg == "вкл" then
            CoARU_SetNames(true)
            msg("имена существ: |cff00ff00русские|r (наведи мышь заново, чтобы увидеть).")
        else
            msg(("имена существ: %s. Команды: /coaru names on|off"):format(
                (CoARU_NamesOn and CoARU_NamesOn()) and "|cff00ff00русские|r" or "|cffff2020английские|r"))
        end
        return
    end

    if isOriginalCmd(cmd) then
        local arg = cmd:match("%s+(%a+)$")
        if arg then
            local set = CoARU_SetOriginalMod and CoARU_SetOriginalMod(arg)
            if not set then
                msg("не знаю такую клавишу. Доступны: alt, ctrl, shift, off.")
                return
            end
            msg(set == "NONE"
                and "показ оригинала по клавише |cffff0000выключен|r."
                or ("оригинал показывается, пока зажат |cffffd100%s|r."):format(
                    set:sub(1, 1) .. set:sub(2):lower()))
            return
        end
        local sticky = CoARU_ToggleOriginalSticky and CoARU_ToggleOriginalSticky()
        local key = CoARU_OriginalMod and CoARU_OriginalMod() or "ALT"
        key = key:sub(1, 1) .. key:sub(2):lower()
        if sticky then
            msg(("постоянный английский: |cff00ff00ВКЛ|r. Зажми |cffffd100%s|r, чтобы увидеть русский."):format(key))
        else
            msg(("постоянный английский: |cffff0000ВЫКЛ|r. Зажми |cffffd100%s|r над тултипом, чтобы увидеть оригинал."):format(key))
        end
        return
    end
    if cmd == "book" then
        CoARU_ScanBook(false)
    elseif cmd == "book all" then
        CoARU_ScanBook(true)
    elseif cmd == "scanca" or cmd == "scanca all" then

        CoARU_ScanCA(cmd == "scanca all")
    elseif cmd:match("^scanall") then

        local ms, minId, maxId = nil, nil, nil
        local a, b = cmd:match("(%d+)%s*%-%s*(%d+)")
        if a then
            minId, maxId = tonumber(a), tonumber(b)

            local rest = cmd:gsub("%d+%s*%-%s*%d+", " ")
            for d in rest:gmatch("%d+") do
                d = tonumber(d)
                if d <= 1000 and not ms then ms = d end
            end
        else

            for d in cmd:gmatch("%d+") do
                d = tonumber(d)
                if d > 1000 then
                    if not minId then minId = d elseif not maxId then maxId = d end
                elseif not ms then
                    ms = d
                end
            end
        end

        if CoARU_SetScanDeep then CoARU_SetScanDeep(cmd:match("%f[%a]deep%f[%A]") ~= nil) end

        if CoARU_SetScanProbe then CoARU_SetScanProbe(cmd:match("%f[%a]probe%f[%A]") ~= nil) end

        if CoARU_SetScanTrace then
            CoARU_SetScanTrace(cmd:match("%f[%a]trace%f[%A]") and 200 or 0)
        end

        if cmd:match("%f[%a]list%f[%A]") then
            if type(CoARU_ScanIdList) ~= "table" or #CoARU_ScanIdList == 0 then
                msg("нет CoARU_ScanIdList. Сгенерируй: python tools/Build-ScanList.py, потом ПОЛНЫЙ перезаход (новый файл /reload не подхватывает)")
                return
            end

            local sel = CoARU_ScanIdList
            if (minId and minId > 0) or maxId then
                sel = {}
                local lo, hi = minId or 0, maxId or math.huge
                for i = 1, #CoARU_ScanIdList do
                    local v = CoARU_ScanIdList[i]
                    if v >= lo and v <= hi then sel[#sel + 1] = v end
                end
            end
            msg(("скан по СПИСКУ: %d id (перебор был бы %d)"):format(#sel, 9538420))
            CoARU_StartScan(sel, cmd:match("%f[%a]all%f[%A]") ~= nil, ms)
            return
        end

        if CoARU_SetScanDesc then CoARU_SetScanDesc(cmd:match("%f[%a]desc%f[%A]") ~= nil) end

        if CoARU_SetScanColor then CoARU_SetScanColor(cmd:match("%f[%a]color%f[%A]") ~= nil) end
        local fast = cmd:match("%f[%a]fast") ~= nil

        if fast then ms = math.min(math.max(ms or 100, 1), 1000) else ms = nil end
        CoARU_StartScanRanges(CoARU_ScanRanges or {}, cmd:match("%f[%a]all%f[%A]") ~= nil, ms, minId, maxId)
    elseif cmd == "hover" then
        CoARU_DB.opts.hover = not CoARU_DB.opts.hover
        msg("режим записи при наведении: " .. (CoARU_DB.opts.hover and "|cff00ff00ВКЛ|r — наводи мышь на спеллы, непереведенные попадут в дамп" or "|cffff0000ВЫКЛ|r"))
    elseif cmd == "gossipdbg" then

        CoARU_GOSSIP_DBG = not CoARU_GOSSIP_DBG
        msg("лог окна разговора: " .. (CoARU_GOSSIP_DBG and
            "|cff00ff00ВКЛ|r — открой окно НПС, строки напечатаются сюда" or "|cffff0000ВЫКЛ|r"))
    elseif cmd == "callboard" then

        local B = _G["CallBoardUI"]
        if not B then
            msg("окно доски не найдено. Подойди к доске заданий, ОТКРОЙ её и повтори команду.")
        else
            local d = { opts = {}, internal = {}, seen = {}, quests = {}, cats = {} }
            local function grab(fn) local ok, v = pcall(fn) if ok then return v end return nil end
            for k, v in pairs(B.gossipOptions or {}) do d.opts[k] = v end
            for k, v in pairs(B.internalGossipOptions or {}) do d.internal[k] = v end

            local seen = grab(function() return { GetGossipOptions() } end) or {}
            for i = 1, #seen, 2 do d.seen[#d.seen + 1] = tostring(seen[i]) end
            d.raw = {}
            if CoARU_GossipOptionsOrig then
                local raw = grab(function() return { CoARU_GossipOptionsOrig() } end) or {}
                for i = 1, #raw, 2 do d.raw[#d.raw + 1] = tostring(raw[i]) end
            end
            d.numAvail = grab(GetNumGossipAvailableQuests)
            d.numActive = grab(GetNumGossipActiveQuests)
            for i, q in ipairs(B.questList or {}) do
                d.quests[i] = ("%s | id=%s | active=%s"):format(
                    tostring(q.name), tostring(q.ID), tostring(q.isActive))
            end
            for cat in pairs(B.TemporalContractsMap or {}) do d.cats[#d.cats + 1] = tostring(cat) end
            local page = B.content and B.content.ExtraSlotsCategorized
            d.pageShown = page and grab(function() return page:IsVisible() end)
            d.pageItems = 0
            for _ in pairs((page and page.items) or {}) do d.pageItems = d.pageItems + 1 end
            for _ in pairs(B.categorizedQuestList or {}) do d.catQuests = (d.catQuests or 0) + 1 end
            d.category = tostring(page and page.category)
            d.delayed = tostring(B.delayedOption)
            d.tab = grab(function() return B.CurrentTabButton:GetName() end)
            d.version = GetAddOnMetadata and GetAddOnMetadata("CoARU", "Version")
            CoARU_DB.callboard = d
            msg(("снято: вариантов %d (до обёртки %d), заданий %d, категорий %d, страница %s.")
                :format(#d.seen, #d.raw, #d.quests, #d.cats, tostring(d.pageShown)))
            msg("сделай |cffffd100/reload|r и пришли SavedVariables\\CoARU.lua")
        end
    elseif cmd == "probe" then
        CoARU_Probe()
    elseif cmd == "classes" then
        CoARU_ProbeClasses()
    elseif cmd == "status" then

        local nnames = 0
        for _ in pairs(CoARU_SPELL_NAME_RU or {}) do nnames = nnames + 1 end

        local one = CoARU_TranslateBlock(nil, "|cffFFFFFFFalconstrike|r")
        local many = CoARU_TranslateBlock(nil,
            "|TInterface\\Common\\ui-tooltipdivider:12:180:0:0|t\n"

            .. "|TInterface\\Icons\\ability_felarakkoa_focusedblast:20:20:0:0|t "
            .. "|cffFFFFFFFalconstrike|r\n|cff8fff7aGenerates 2 Advantage|r")
        local function mark(v)
            return (v and CoARU_HasCyrillic(v)) and "|cff40ff40да|r" or "|cffff4040НЕТ|r"
        end
        msg(("самопроверка: карта имен %d, имя одной строкой %s, имя в блоке %s")
            :format(nnames, mark(one), mark(many)))

        CoARU_DB.selfcheck = { names = nnames, one = one, many = many }

        if RELEASE then

            local nsp, nit, nbt, nq = 0, 0, 0, 0
            for _ in pairs(CoARU_LOC_EN or {}) do nsp = nsp + 1 end
            for _ in pairs(CoARU_ItemName or {}) do nit = nit + 1 end
            for _ in pairs(CoARU_ItemNameEN or {}) do nbt = nbt + 1 end
            for _ in pairs(CoARU_QUEST or {}) do nq = nq + 1 end
            msg(("загружено: спеллов %d, предметов %d (+%d по имени), заданий %d")
                :format(nsp, nit, nbt, nq))

            local offN, offList = CoARU_ModsOff()
            if offN > 0 then
                msg(("выключено в настройках: |cffffd100%s|r (вернуть: /coaru options)")
                    :format(table.concat(offList, ", ")))
            end

            local mn, newN = 0, 0
            for _, rec in pairs(CoARU_DB.miss or {}) do
                mn = mn + 1
                if not (type(rec) == "table" and rec.sent) then newN = newN + 1 end
            end
            if mn == 0 then
                msg("строк для перевода пока не собралось.")
                return
            end

            for _, rec in pairs(CoARU_DB.miss) do
                if type(rec) == "table" then rec.sent = true end
            end

            msg(("строк для перевода собрано: |cffffd100%d|r (новых с прошлой отправки: %d)"):format(mn, newN))
            print("  |cffffd1001.|r сделай |cffffd100/reload|r")

            print("  |cffffd1002.|r найди файл в папке игры:")
            print("|cff00ff00resources\\ascension-live\\WTF\\Account\\<аккаунт>"
                  .. "\\SavedVariables\\CoARU.lua|r")

            if CoARU_DISCORD_OK then
                print("  |cffffd1003.|r пришли его в Discord, канал "
                      .. "|cffC495DD#обсуждение-coaru|r:")
                print("|cff00ff00" .. CoARU_DISCORD_OK .. "|r")
            else
                print("  |cffffd1003.|r пришли его в Discord, канал "
                      .. "|cffC495DD#обсуждение-coaru|r (сервер Ascension Addons RU)")
            end

            return
        end
        local t, iname, idesc, ibytext = 0, 0, 0, 0
        for _ in pairs(CoARU_LOC_EN or {}) do t = t + 1 end
        for _ in pairs(CoARU_ItemName or {}) do iname = iname + 1 end
        for _ in pairs(CoARU_ItemDesc or {}) do idesc = idesc + 1 end

        for _ in pairs(CoARU_ItemNameEN or {}) do ibytext = ibytext + 1 end
        msg(("переводов в базе: %d, спеллов в дампе: %d, hover: %s"):format(t, countDump(), CoARU_DB.opts.hover and "вкл" or "выкл"))
        msg(("предметы: имен %d, описаний %d, имен по тексту %d"):format(iname, idesc, ibytext))

        msg(("строк тултипа предмета: %d (пропущено %d)"):format(
            CoARU_ItemTipAdded or 0, CoARU_ItemTipSkipped or 0))

        msg(("пакет интерфейса: %s"):format(
            CoARU_PACK_VERSION
                and ("%s, ключей %s, отпечаток %s"):format(
                    CoARU_PACK_VERSION, CoARU_INTERFACE_PACK or "?",
                    CoARU_PACK_STAMP or "|cffff0000нет (пакет старой сборки)|r")
                or "|cffff0000не установлен|r"))

        if CoARU_ChunkCacheStat then
            local en, ru, q, cap = CoARU_ChunkCacheStat()
            msg(("кэш кусков базы: описания %d+%d, задания %d, потолок %d на ячейку")
                :format(en, ru, q, cap))
        end

        if CoARU_PaperDollStatus then
            local n, where, fs = CoARU_PaperDollStatus()
            msg(("текст окон: строк %d, FontString в кэше %d | %s"):format(n, fs or 0, where))
        end

        msg(("Lua всего: %.1f МБ"):format(collectgarbage("count") / 1024))
        local st = 0
        for _ in pairs(CoARU_SKILL_TERMS or {}) do st = st + 1 end
        msg(("терминов подсветки (авто): %d%s"):format(st,
            st == 0 and " |cffff0000(CoARU_SkillTerms.lua не загружен — нужен полный перезапуск)|r" or ""))

        if CoARU_OriginalStatus then
            local n, key, sticky = CoARU_OriginalStatus()
            msg(("оригинал: клавиша %s, постоянный английский %s, строк в кэше %d"):format(
                key, sticky and "вкл" or "выкл", n))
        else
            msg("|cffff0000CoARU_Original.lua не загружен|r — нужен полный перезапуск игры, не /reload.")
        end

        if CoARU_QuestCount and CoARU_QuestTranslatedCount then
            local qn = CoARU_QuestCount()
            msg(("квесты: в базе %d, переведено за сессию %d, снято в дамп %d%s%s"):format(
                qn, CoARU_QuestTranslatedCount(),
                CoARU_QuestDumpCount and CoARU_QuestDumpCount() or 0,
                (CoARU_DB.opts and CoARU_DB.opts.questdump) and ", запись |cff00ff00вкл|r" or "",
                qn == 0 and " |cffff0000(CoARU_QuestData.lua не загружен — полный перезапуск)|r" or ""))
        else
            msg("|cffff0000CoARU_Quests.lua не загружен|r — нужен полный перезапуск игры, не /reload.")
        end

        if CoARU_ZoneStatus then
            local zn, active = CoARU_ZoneStatus()
            msg(("зоны: в базе %d, слой %s"):format(zn,
                active and "|cff00ff00активен|r" or "|cffff0000нет (CoARU_ZoneData.lua не загружен)|r"))
        else
            msg("|cffff0000CoARU_Zones.lua не загружен|r — нужен полный перезапуск игры, не /reload.")
        end

        if CoARU_UnitStatus then
            local nru, nsub, nn2r = CoARU_UnitStatus()
            msg(("имена НПС: id→RU %d, подтайтлов %d, EN→RU %d"):format(nru, nsub, nn2r))
        else
            msg("|cffff0000CoARU_Units.lua не загружен|r — нужен полный перезапуск игры, не /reload.")
        end

        local mn, byKind = 0, {}
        for _, r in pairs(CoARU_DB.miss or {}) do
            mn = mn + 1
            local k = r.k or "?"
            byKind[k] = (byKind[k] or 0) + 1
        end
        local parts = {}
        for k, v in pairs(byKind) do parts[#parts + 1] = k .. " " .. v end
        msg(("|cffffd100непереведенных строк собрано: %d|r%s"):format(
            mn, #parts > 0 and (" (" .. table.concat(parts, ", ") .. ")") or ""))
        if mn > 0 then
            print("  это уникальные НОРМЫ живого текста. /reload и пришли SavedVariables — переведем волной.")
        end
    elseif cmd == "clear" then

        local KEEP = {
            opts = true,
            ver = true,
            uirec = true,
            hitch = true,
        }
        local wiped = {}
        for k in pairs(CoARU_DB) do
            if not KEEP[k] then wiped[#wiped + 1] = k end
        end
        table.sort(wiped)

        for i = 1, #wiped do CoARU_DB[wiped[i]] = nil end
        CoARU_DB.dump = {}
        CoARU_DB.miss = {}
        msg(("дамп очищен: секций %d (%s), собранные дыры тоже.")
            :format(#wiped, table.concat(wiped, ", ")))
    elseif cmd == "plates" then

        if CoARU_AscUI_Nameplates then
            CoARU_AscUI_Nameplates()
        else
            msg("|cffff0000CoARU_AscUI.lua не загружен|r — нужен полный перезапуск клиента.")
        end
    elseif cmd == "titleprobe" then

        if not UnitExists or not UnitExists("target") then
            msg("наведи цель на игрока со званием и повтори команду.")
        else
            local n = UnitName("target")
            local p = UnitPVPName and UnitPVPName("target")
            msg("UnitName:    " .. tostring(n))
            msg("UnitPVPName: " .. tostring(p))
            if p and n and p ~= n then
                msg("|cff00ff00звание СКЛЕИВАЕТ клиент|r — значит форма берется из CharTitles.dbc")
            elseif p and n and p == n then
                msg("|cffffd100звание ПРИШЛО В ИМЕНИ|r — CharTitles.dbc тут ни при чем")
            end

            if CoARU_TitleRU then
                msg("наш перевод формы: " .. tostring(CoARU_TitleRU(p or n or "")))
            end
        end
    elseif cmd == "worldnames" or cmd:find("^worldnames ") then

        local needle = cmd:match("^worldnames%s+(.+)$") or "Founder"
        local seen, shown, hits = 0, 0, 0
        local function walk(f, depth)
            if not f or depth > 6 then return end
            if f.GetRegions then
                local ok, cnt = pcall(function() return select("#", f:GetRegions()) end)
                if ok then
                    for i = 1, cnt do
                        local r = select(i, f:GetRegions())
                        if r and r.GetObjectType and r:GetObjectType() == "FontString" then
                            local t = r.GetText and r:GetText()
                            if t and t ~= "" then
                                seen = seen + 1
                                if t:find(needle, 1, true) then
                                    hits = hits + 1
                                    msg("|cff00ff00НАЙДЕНО|r [" .. (f:GetName() or "без имени")
                                        .. "] " .. t)
                                elseif shown < 12 then
                                    shown = shown + 1
                                    msg("  " .. t)
                                end
                            end
                        end
                    end
                end
            end
            if f.GetChildren then
                local ok, cnt = pcall(function() return select("#", f:GetChildren()) end)
                if ok then
                    for i = 1, cnt do walk(select(i, f:GetChildren()), depth + 1) end
                end
            end
        end
        walk(_G.WorldFrame, 0)
        local wf = seen

        if type(EnumerateFrames) == "function" then
            local f = EnumerateFrames()
            local guard = 0
            while f and guard < 20000 do
                guard = guard + 1
                if f ~= _G.WorldFrame then walk(f, 5) end
                f = EnumerateFrames(f)
            end
            msg(("фреймов просмотрено: %d"):format(guard))
        end

        msg(("надписей: %d (в мире %d), с «%s»: %d"):format(seen, wf, needle, hits))
        if hits == 0 then
            msg("|cffffd100ноль совпадений: надпись рисует движок, Lua ее не видит|r")
        end
    elseif cmd == "tutprobe" then

        if CoARU_AscUI_Probe then
            CoARU_AscUI_Probe()
        else
            msg("|cffff0000CoARU_AscUI.lua не загружен|r — нужен полный перезапуск клиента.")
        end
    elseif cmd == "mixed" then

        local n, shown = 0, 0
        for t, rec in pairs(CoARU_DB.miss or {}) do
            if type(rec) == "table" and rec.k == "mixed" then
                n = n + 1
                if shown < 15 then
                    shown = shown + 1
                    msg("  " .. t:gsub("\n", " "):sub(1, 90))
                end
            end
        end
        msg(("смешанных строк собрано: %d (показал %d)."):format(n, shown))
        msg("Полный список уедет в SavedVariables после /reload.")
    elseif cmd:match("^uimiss") then

        local a1, a2 = cmd:match("^uimiss%s+(%S+)%s*(%S*)")
        if a1 == "rec" then
            CoARU_DB.uirec = (a2 ~= "off")
            msg("фоновая запись непереведенных надписей: " ..
                (CoARU_DB.uirec and "включена" or "выключена"))
        elseif not CoARU_AscUI_Sweep then
            msg("|cffff0000CoARU_AscUI.lua не загружен|r — нужен полный перезапуск клиента.")
        else
            CoARU_AscUI_Sweep()
            local src = CoARU_DB.uimissrc or {}

            local byOwner, n = {}, 0
            for t in pairs(CoARU_DB.uimiss or {}) do
                n = n + 1
                local o = src[t] or "(обход корней)"
                byOwner[o] = (byOwner[o] or 0) + 1
            end
            local owners = {}
            for o, c in pairs(byOwner) do owners[#owners + 1] = { o = o, c = c } end
            table.sort(owners, function(a, b) return a.c > b.c end)
            for i = 1, math.min(12, #owners) do
                msg(("  %s — %d"):format(owners[i].o, owners[i].c))
            end
            msg(("непереведенных надписей: %d в %d окнах%s."):format(
                n, #owners, CoARU_DB.uirec and "" or " (фоновая запись ВЫКЛЮЧЕНА)"))
            msg("Полный список уедет в SavedVariables после /reload.")
        end
    elseif cmd == "bookdump" then

        if CoARU_BookDump then CoARU_BookDump() else msg("модуль книги не загружен") end
    elseif cmd == "trainerdump" then

        if not (ClassTrainerFrame and ClassTrainerFrame:IsShown()) then
            msg("окно тренера закрыто — открой его и повтори.")
        else
            CoARU_DB.trainerdump = CoARU_DumpTrainer()
            local n, dark = 0, 0
            for _, e in ipairs(CoARU_DB.trainerdump) do
                n = n + 1
                local a = tonumber((e.color or ""):match("^([%d%.]+)"))
                if a and a < 0.15 then dark = dark + 1 end
            end
            msg(("FontString'ов снято: %d (темных: %d). ПОЛНОЕ сырье каждого в SavedVariables."):format(n, dark))
            msg("Сделай /reload и пришли WTF\\...\\SavedVariables\\CoARU.lua — увижу точные байты.")
        end
    elseif cmd == "zoneprobe" then

        if not (WorldMapFrame and WorldMapFrame:IsShown()) then
            msg("карта закрыта — открой карту мира (M), наведись на зону и повтори.")
        elseif not CoARU_ZoneProbe then
            msg("|cffff0000CoARU_Zones.lua не загружен|r — нужен полный перезапуск.")
        else
            CoARU_DB.zoneprobe = CoARU_ZoneProbe()
            msg(("FontString'ов на карте снято: %d. Сделай /reload и пришли SavedVariables."):format(
                #CoARU_DB.zoneprobe))
        end
    elseif cmd == "trainerscan" then

        local spells, misses = CoARU_ScanTrainer()
        if not spells then
            msg((misses or "не вышло") .. " — открой тренера и повтори.")
        else
            msg(("тренер просканирован: спеллов %d, новых промахов %d. Сырье с цветом — в "
                .. "SavedVariables (CoARU_DB.trainerscan)."):format(spells, misses))
            msg("Сделай /reload и пришли WTF\\...\\SavedVariables\\CoARU.lua.")
        end
    elseif cmd:match("^questdump") then

        local arg = cmd:match("^questdump%s+(%a+)")
        if arg == "off" then
            CoARU_DB.opts.questdump = false
            msg("запись текста квестов: |cffff0000ВЫКЛ|r")
        elseif arg == "clear" then
            CoARU_DB.questdump = {}
            msg("дамп квестов очищен.")
        else
            CoARU_DB.opts.questdump = true
            msg("запись текста квестов: |cff00ff00ВКЛ|r — открывай квесты (у NPC и в журнале P), "
                .. "текст копится. Потом /coaru questdump off, /reload и пришли SavedVariables.")
            msg(("сейчас снято блоков: %d"):format(CoARU_QuestDumpCount and CoARU_QuestDumpCount() or 0))
        end
    elseif cmd:match("^questprobe") then

        local id = tonumber(cmd:match("(%d+)"))
        if not id then
            msg("нужен номер: /coaru questprobe 254045 (номера своих квестов: /coaru questids)")
            return
        end
        if CoARU_QuestProbe then CoARU_QuestProbe(id) end
    elseif cmd:match("^questscan") then

        if cmd:match("stop") then
            if not (CoARU_StopQuestScan and CoARU_StopQuestScan()) then
                msg("скан квестов и так не идет.")
            end
            return
        end

        local rs = {}
        for a, b in cmd:gmatch("(%d+)%s*%-%s*(%d+)") do
            rs[#rs + 1] = { tonumber(a), tonumber(b) }
        end
        local a = rs[1] and rs[1][1]
        if not a then
            local n, active = CoARU_QuestScanCount and CoARU_QuestScanCount()
            msg(("скан квестов: %s, в списке %d номеров."):format(
                active and "|cff00ff00идет|r" or "не идет", n or 0))
            print("  запуск: |cffffd100/coaru questscan 254000-255000|r [запросов/сек, по умолчанию 10]")
            print("  остановить: |cffffd100/coaru questscan stop|r")
            return
        end

        local rest = cmd:gsub("%d+%s*%-%s*%d+", " ")
        local rate = tonumber(rest:match("(%d+)"))
        CoARU_StartQuestScan(rs, rate)
    elseif cmd:match("^questids") then

        local n = GetNumQuestLogEntries and GetNumQuestLogEntries() or 0
        local found = 0
        msg(("квестов в журнале: %d"):format(n))
        for i = 1, n do
            local title, _, _, isHeader = GetQuestLogTitle(i)
            if not isHeader then
                local link = GetQuestLink and GetQuestLink(i)
                local id = link and link:match("quest:(%d+)")
                if id then
                    found = found + 1
                    print(("  |cffffd100%s|r  %s"):format(id, title or "?"))
                else
                    print(("  |cffff2020без номера|r  %s"):format(title or "?"))
                end
            end
        end
        if found == 0 then
            msg("номеров не видно: журнал пуст либо клиент не отдает ссылку квеста.")
        end
    elseif cmd == "trainerskip" then

        CoARU_TrainerSkip = not CoARU_TrainerSkip
        msg("перевод окна тренера: " .. (CoARU_TrainerSkip
            and "|cffff0000ВЫКЛЮЧЕН|r — закрой и открой тренера, затем /coaru trainercolor"
            or "|cff00ff00включен|r"))
    elseif cmd == "trainercolor" then

        if not (ClassTrainerFrame and ClassTrainerFrame:IsShown()) then
            msg("окно тренера закрыто — открой его и повтори.")
        else

            CoARU_DB.trainercolor = {}
            local n = 0
            local function walk(fr, depth)
                if not fr or depth > 8 then return end
                if fr.GetRegions then
                    local ok, cnt = pcall(function() return select("#", fr:GetRegions()) end)
                    if ok then
                        for i = 1, cnt do
                            local r = select(i, fr:GetRegions())
                            local isFS = r and r.GetObjectType and r:GetObjectType() == "FontString"
                            local t = isFS and r.GetText and r:GetText()
                            if t and #t > 1 then
                                local cr, cg, cb = 1, 1, 1
                                if r.GetTextColor then
                                    local ok2, a, b, c = pcall(function() return r:GetTextColor() end)
                                    if ok2 then cr, cg, cb = a or 1, b or 1, c or 1 end
                                end
                                n = n + 1
                                table.insert(CoARU_DB.trainercolor, {
                                    rgb = ("%.2f/%.2f/%.2f"):format(cr, cg, cb),
                                    emb = t:find("|c", 1, true) ~= nil,
                                    raw = t,
                                })
                                print(("  %.2f/%.2f/%.2f %s| %s"):format(
                                    cr, cg, cb,
                                    t:find("|c") and "ВШИТЫЙ ЦВЕТ " or "",
                                    t:sub(1, 60)))
                            end
                        end
                    end
                end
                if fr.GetChildren then
                    local ok, cnt = pcall(function() return select("#", fr:GetChildren()) end)
                    if ok then
                        for i = 1, cnt do walk(select(i, fr:GetChildren()), depth + 1) end
                    end
                end
            end
            msg("строки окна тренера (RGB объекта, затем текст):")
            walk(ClassTrainerFrame, 0)
            msg(("всего строк: %d. Полное сырье в SavedVariables (CoARU_DB.trainercolor) — "
                 .. "сделай /reload и пришли CoARU.lua."):format(n))
        end
    elseif cmd:match("^uidump") then

        local name = cmd:match("^uidump%s+(%S+)")
        if not CoARU_AscUI_Dump then
            msg("|cffff0000CoARU_AscUI.lua не загружен|r — нужен полный перезапуск игры.")
        elseif name == "rec" then

            CoARU_DB.uidumprec = true
            CoARU_DB.uidump = CoARU_DB.uidump or { lines = {} }
            msg("запись снимков ВКЛючена: открой окно, поводи мышью по строкам. "
                .. "Копится в CoARU_DB.uidump. Выключить: /coaru uidump off")
        elseif name == "off" then
            CoARU_DB.uidumprec = nil
            local c = (CoARU_DB.uidump and CoARU_DB.uidump.lines
                       and #CoARU_DB.uidump.lines) or 0
            msg(("запись снимков выключена. В копилке строк: %d — /reload и пришли "
                 .. "CoARU.lua."):format(c))
        else
            local n, out, frames
            if name then
                n, out = CoARU_AscUI_Dump(name)
                frames = { name }
            else
                n, out, frames = CoARU_AscUI_DumpAll()
            end
            if n == 0 then
                msg(("окно не найдено или пустое: %s. Открой окно и повтори.")
                    :format(name or "(открытых окон Ascension нет)"))
            else

                CoARU_DB.uidump = CoARU_DB.uidump or { lines = {} }
                local acc = CoARU_DB.uidump.lines
                for _, row in ipairs(out) do acc[#acc + 1] = row end
                CoARU_DB.uidump.frames = frames
                msg(("снято строк: %d, всего в копилке %d (окна: %s). Лежит в "
                     .. "CoARU_DB.uidump — /reload и пришли CoARU.lua."):format(
                     n, #acc, table.concat(frames, ", ")))
            end
        end
    elseif cmd == "lines rec" then

        CoARU_RecLines = true
        CoARU_DB.lines = CoARU_DB.lines or {}
        msg("запись строк ВКЛючена: наводи на скиллы, они копятся в CoARU_DB.lines. "
            .. "Потом /reload и пришли CoARU.lua. Выключить: /coaru lines off")
    elseif cmd == "lines off" then
        CoARU_RecLines = false
        local c = 0
        if CoARU_DB.lines then for _ in ipairs(CoARU_DB.lines) do c = c + 1 end end
        msg(("запись выключена. В копилке тултипов: %d (в SavedVariables)."):format(c))
    elseif cmd == "lines" then

        if not CoARU_LastTip then
            msg("еще не было ни одного тултипа.")
        else
            local total = CoARU_RecordLines()
            msg(("тултип id=%s (R/G/B). В копилке: %d — /reload и пришли CoARU.lua."):format(
                tostring(CoARU_LastTip.id), total))
            for _, line in ipairs(CoARU_LastTip) do print("  " .. line) end
        end
    elseif cmd:match("^wraptest") then

        if not CoARU_WrapProbe then
            msg("|cffff0000CoARU_WrapProbe.lua не загружен|r — нужен полный перезапуск игры.")
        else
            local can, len, ruler = CoARU_WrapProbeInfo()
            local args = cmd:match("^wraptest%s+(.+)") or ""
            local n = tonumber(args:match("^(%d)"))
            if not n then
                msg(("проба переноса. SetWordWrap у тултипа: %s, строка %d байт, линейка %s")
                    :format(can and "|cff00ff00есть|r" or "|cffff0000нет|r", len,
                            (ruler or 0) > 0 and ("|cff00ff00%.0f|r пикс."):format(ruler)
                            or "|cffff00000 — ширину посчитать нечем|r"))
                print("  |cffffd1001|r — как есть (перенос включен, защиты нет): |cffff0000может уронить клиент|r")
                print("  |cffffd1002|r — то же, но перенос запрещен через SetWordWrap(false)")
                print("  |cffffd1003|r — перенос делаем сами, клиенту переносить нечего")
                print("  запуск: /coaru wraptest 2   (для первой ступени: /coaru wraptest 1 force)")
            elseif n == 1 and not args:find("force") then
                msg("ступень 1 воспроизводит падение НАМЕРЕННО. Выйди из боя и подземелья, потом: /coaru wraptest 1 force")
            elseif n == 1 then

                msg("ступень 1: своя строка шириной 260, перенос разрешен. Если запись верна — вылет здесь.")
                local h = CoARU_WrapProbeStrip(true)
                msg(("клиент выжил. Высота строки: %.0f (одна строка это ~14, значит перенос %s)")
                    :format(h, h > 25 and "|cff00ff00сработал|r" or "|cffff0000не сработал|r"))
                print("  убрать с экрана: /coaru wraptest 0")
            elseif n == 0 then
                CoARU_WrapProbeStrip(false)
                msg("строка убрана.")
            else
                msg(("ступень %d пошла."):format(n))
                local mine, lines, w = CoARU_WrapProbe(n)
                msg(("клиент выжил. Отдано строк: %d, тултип насчитал: %d, ширина первой: %.0f")
                    :format(mine, lines, w))
                if n == 3 and mine < 2 then
                    msg("|cffff0000разбивка не сработала|r — текст ушел одной строкой, замер ширины подвел.")
                end
            end
        end
    elseif cmd == "frames" then

        if CoARU_PaperDollFrames then
            CoARU_PaperDollFrames()
        else
            msg("окна не подключены (нужен полный перезапуск игры, не /reload)")
        end
    elseif cmd == "geom" then

        if CoARU_PaperDollGeom then
            CoARU_PaperDollGeom()
        else
            msg("окна не подключены (нужен полный перезапуск игры, не /reload)")
        end
    elseif cmd:match("^altdump") then

        CoARU_DB.opts = CoARU_DB.opts or {}
        local a = cmd:match("^altdump%s+(%S+)")
        if a == "off" then
            CoARU_DB.opts.altdump = nil
            msg("запись перехода Alt выключена")
        elseif a == "on" then
            CoARU_DB.opts.altdump = true
            CoARU_DB.altdump = {}
            msg("запись перехода Alt включена. Наведи мышь, нажми и отпусти Alt, потом /reload")
        else
            local n = 0
            for _ in pairs(CoARU_DB.altdump or {}) do n = n + 1 end
            msg(("снимков перехода: %d%s"):format(n,
                CoARU_DB.opts.altdump and "" or " (запись ВЫКЛЮЧЕНА)"))
            msg("после /reload файл: WTF\\Account\\<acc>\\SavedVariables\\CoARU.lua, ключ altdump")
        end
    elseif cmd:match("^hitch") then

        local a = cmd:match("^hitch%s+(%S+)")
        if a == "off" then
            CoARU_DB.opts.hitch = nil
            msg("запись замираний выключена")
        elseif a == "on" then
            CoARU_DB.opts.hitch = true
            CoARU_DB.hitch = {}
            msg("запись замираний включена (порог 1 сек). После замирания — /reload")
        else
            local h = CoARU_DB.hitch or {}
            msg(("замираний записано: %d%s"):format(#h,
                CoARU_DB.opts.hitch and "" or " (запись ВЫКЛЮЧЕНА, включи: /coaru hitch on)"))
            for i = math.max(1, #h - 9), #h do
                local r = h[i]
                msg(("  %.1f сек | скан: %s | Lua: %.0f МБ | %s"):format(
                    r.gap, r.scan or "нет", r.mem, r.zone or "?"))
            end
        end
    elseif cmd == "packnew" then

        local new = CoARU_PACK_NEW
        if not new then
            msg("пакет не загружен либо он старее 2026-08-04 (нет CoARU_PACK_NEW)")
            msg("скопируй свежий: Interface\\PTRXML и Interface\\CoARU_Loc, потом полный перезаход")
        else
            CoARU_DB.packnew = {}
            for i = 1, #new do CoARU_DB.packnew[i] = new[i] end
            msg(("ключей, которых у клиента НЕТ (пакет их НЕ ставит): %d"):format(#new))
            for i = 1, math.min(#new, 20) do
                msg(("  %s = %q"):format(new[i], tostring(_G[new[i]])))
            end
            if #new > 20 then msg(("  ... ещё %d, полный список в SavedVariables"):format(#new - 20)) end
        end
    elseif cmd:match("^order") then

        local a = cmd:match("^order%s+(%S+)")
        if a == "off" then
            CoARU_DB.opts.order = nil
            msg("запись порядка хуков выключена")
        elseif a == "on" then
            CoARU_DB.opts.order = true
            CoARU_DB.order = {}
            CoARU_HookOrderChat()
            msg("запись порядка хуков включена. Наведи мышь на предмет, потом /reload")
            msg("строки соседа тоже попадут в запись — включи его отладку (/lcwf debug)")
            msg("выхлоп: SavedVariables, ключ order. Выключить: /coaru order off")
        else
            local n = #(CoARU_DB.order or {})
            msg(("запись порядка хуков: %s, строк %d"):format(
                CoARU_DB.opts.order and "ВКЛ" or "выкл", n))
            for i = 1, math.min(n, 12) do msg("  " .. CoARU_DB.order[i]) end
        end
    elseif cmd == "foreign" then

        local tip = CoARU_ForeignTip
        if not tip then
            tip = CreateFrame("GameTooltip", "CoARU_ForeignTip", nil, "GameTooltipTemplate")
            CoARU_ForeignTip = tip
        end

        local function pat(s)
            if type(s) ~= "string" then return nil end
            local ok, p = pcall(string.format, s, "")
            return ok and p or nil
        end
        local ruPat = pat(ITEM_CLASSES_ALLOWED)
        local enPat = pat(CoARU_EN and CoARU_EN("ITEM_CLASSES_ALLOWED"))
        local function hit(text, p)
            if not text or not p then return false end
            local ok, m = pcall(strmatch, text, p)

            if not ok then return nil end
            return m and true or false
        end
        CoARU_DB.foreigntip = {}
        local items, withNil, reached, drawnEn, drawnRu, patErr = 0, 0, 0, 0, 0, 0
        for bag = 0, NUM_BAG_FRAMES do
            for slot = 1, (GetContainerNumSlots(bag) or 0) do
                local id = GetContainerItemID and GetContainerItemID(bag, slot)
                local link, ty
                if id then

                    local _, l, _, _, _, t6 = GetItemInfo(id)
                    link, ty = l, t6
                end
                if link and (ty == "Armor" or ty == "Weapon") then
                    items = items + 1
                    tip:SetOwner(UIParent, "ANCHOR_NONE")
                    tip:SetHyperlink(link)
                    local n = tip:NumLines()
                    local nils, firstNil, ruAt, enAt, clsText = {}, nil, nil, nil, nil
                    for i = 1, n do
                        local fs = _G["CoARU_ForeignTipTextLeft" .. i]
                        local t = fs and fs:GetText()
                        if t == nil then
                            nils[#nils + 1] = i
                            firstNil = firstNil or i
                        else
                            local r, e = hit(t, ruPat), hit(t, enPat)
                            if r == nil or e == nil then patErr = patErr + 1 end
                            if r and not ruAt then ruAt, clsText = i, t end
                            if e and not enAt then enAt, clsText = i, clsText or t end
                        end
                    end
                    if #nils > 0 then withNil = withNil + 1 end
                    if enAt and not ruAt then drawnEn = drawnEn + 1 end
                    if ruAt then drawnRu = drawnRu + 1 end

                    if firstNil and (not ruAt or ruAt > firstNil) then reached = reached + 1 end
                    if #nils > 0 or (enAt and not ruAt) then

                        local txt = {}
                        for i = 1, n do
                            local lf = _G["CoARU_ForeignTipTextLeft" .. i]
                            local rf = _G["CoARU_ForeignTipTextRight" .. i]
                            local lt = lf and lf:GetText()
                            local rt = rf and rf:GetText()
                            txt[#txt + 1] = ("%d L=%s%s"):format(
                                i, lt == nil and "<НЕТ ТЕКСТА>" or ("[" .. lt .. "]"),
                                rt and (" R=[" .. rt .. "]") or "")
                        end
                        CoARU_DB.foreigntip[#CoARU_DB.foreigntip + 1] = {
                            link = link, lines = n, nils = table.concat(nils, ","),
                            ruAt = ruAt, enAt = enAt, cls = clsText,
                            text = table.concat(txt, " | "),
                        }
                    end
                end
            end
        end
        msg(("предметов брони и оружия в сумках: %d"):format(items))
        msg(("  со строкой БЕЗ текста: %d (у соседа это nil в strmatch)"):format(withNil))
        msg(("  сосед реально дойдёт до неё: %d"):format(reached))
        msg(("  строку «Классы» клиент нарисовал по-русски: %d, по-английски: %d")
            :format(drawnRu, drawnEn))
        if patErr > 0 then
            msg(("  ОТДЕЛЬНО: strmatch упал на %d строках — в надписи магия шаблона Lua")
                :format(patErr))
        end
        msg(("шаблон соседа: %q | английский эталон: %q"):format(
            tostring(ruPat), tostring(enPat)))

        if ruPat == enPat then
            msg("эталон совпал с текущей глобалкой: снимка пакета нет, деление по языку не мерено")
        end
        if items == 0 then
            msg("сумок не видно или брони с оружием в них нет — это НЕ «дефекта нет»")
        end
        msg("подробности после /reload: SavedVariables, ключ foreigntip")
    elseif cmd == "who" then

        local tip = GameTooltip
        if not (tip and tip.IsShown and tip:IsShown() and tip.NumLines) then
            msg("наведи мышь на предмет или способность и повтори (тултип должен быть на экране)")
            return
        end
        local name = tip:GetName()
        local n = tip:NumLines() or 0
        msg(("строк в тултипе: %d"):format(n))
        for i = 1, n do
            for _, side in ipairs({ "TextLeft", "TextRight" }) do
                local fs = _G[name .. side .. i]
                local t = fs and fs.GetText and fs:GetText()
                if t and t ~= "" and t:find("%S") then
                    local en, ru, srcTag = nil, nil, nil
                    if CoARU_OriginalPair then en, ru, srcTag = CoARU_OriginalPair(fs) end
                    local src
                    if en and ru == t then

                        local COLOR = { ["база"] = "|cff00ff00", ["карта аддона"] = "|cff00ffff",
                                        ["правило движка"] = "|cffffff00",
                                        ["пакет интерфейса"] = "|cffC495DD" }
                        local tag = srcTag or "источник не записан"
                        src = (COLOR[tag] or "|cffaaaaaa") .. tag .. "|r"
                    elseif not CoARU_HasCyrillic(t) then
                        src = "|cffff0000не переведено|r"
                    elseif CoARU_ClientOriginal and CoARU_ClientOriginal(t) then
                        src = "|cffC495DDпакет интерфейса|r"
                    else
                        src = "|cffaaaaaaклиент или сервер|r"
                    end
                    msg(("  %s%d %s |cff888888%s|r"):format(side == "TextRight" and "R" or "L",
                        i, src, t:gsub("|", "||"):sub(1, 60)))
                end
            end
        end
        msg("вердикт «база» значит, что строку поставил аддон из мастер-базы; «карта аддона» — из CoARU_G/ItemTip")
    elseif cmd:match("^tipgeom") then

        local a = cmd:match("^tipgeom%s+(%S+)")
        if CoARU_TipGeom then
            CoARU_TipGeom(a)
        else
            msg("|cffff0000CoARU_Original.lua не загружен|r — нужен полный перезапуск клиента.")
        end
    elseif cmd == "fit" then

        if CoARU_PaperDollFit then
            CoARU_PaperDollFit()
        else
            msg("окно персонажа не подключено (нужен полный перезапуск игры, не /reload)")
        end
    elseif cmd == "cafit" then

        if CoARU_CA_Fit then
            CoARU_CA_Fit()
        else
            msg("CoARU_CA.lua не загружен — проверь .toc.")
        end
    elseif cmd == "ca" then

        CoARU_DB = CoARU_DB or {}
        local dump, seen, n = {}, {}, 0
        local fr = EnumerateFrames()
        while fr do
            local shown = fr.IsShown and fr:IsShown()
            if shown and fr.GetRegions then
                local ok, regions = pcall(function() return { fr:GetRegions() } end)
                if ok then
                    for _, r in ipairs(regions) do
                        if r and r.GetObjectType and r:GetObjectType() == "FontString" then
                            local t = r:GetText()
                            if t and #t >= 2 and t:find("%S") and not CoARU_HasCyrillic(t) then
                                if not seen[t] then
                                    seen[t] = true
                                    n = n + 1
                                    dump[n] = {
                                        text = t,
                                        region = (r.GetName and r:GetName()) or "?",
                                        frame = (fr.GetName and fr:GetName()) or "?",
                                    }
                                end
                            end
                        end
                    end
                end
            end
            fr = EnumerateFrames(fr)
        end
        CoARU_DB.castrings = dump
        print("CoARU: снято " .. n .. " англ. строк экрана. Сделай /reload и пришли WTF\\...\\SavedVariables\\CoARU.lua")
    elseif cmd == "arch" or cmd == "specs" then

        CoARU_DB = CoARU_DB or {}
        local order = CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER
        local gsi = C_ClassInfo and C_ClassInfo.GetSpecInfo
        if not (order and gsi) then
            msg("CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER / C_ClassInfo.GetSpecInfo недоступны. Напиши.")
        else
            local out, nc, ns = {}, 0, 0
            for classFile, specs in pairs(order) do
                nc = nc + 1
                if type(specs) == "table" then
                    for _, spec in ipairs(specs) do
                        local ok, info = pcall(gsi, classFile, spec)
                        if ok and type(info) == "table" then
                            local flat = {}
                            for k, v in pairs(info) do
                                local tv = type(v)
                                if tv == "string" or tv == "number" or tv == "boolean" then
                                    flat[tostring(k)] = v
                                end
                            end
                            ns = ns + 1
                            out[#out + 1] = { class = tostring(classFile), spec = tostring(spec), info = flat }
                        end
                    end
                end
            end
            CoARU_DB.specinfo = out
            print("CoARU: снято классов " .. nc .. ", спеков " .. ns ..
                ". /reload и пришли SavedVariables\\CoARU.lua")
        end
    elseif cmd:match("^id%s+%d+$") then
        local id = tonumber(cmd:match("%d+"))
        local n, r, x = CoARU_CaptureSpell(id)
        if n then
            msg(("[%d] %s (%s)"):format(id, n, r or "-"))
            print(x)
        else
            msg("спелл " .. id .. " не найден.")
        end
    elseif cmd:match("^misscap") then

        local n = tonumber(cmd:match("(%d+)"))
        CoARU_DB.opts = CoARU_DB.opts or {}
        if n then
            CoARU_DB.opts.misscap = math.max(1000, math.min(60000, n))
            msg("потолок копилки: " .. CoARU_DB.opts.misscap)
        else
            CoARU_DB.opts.misscap = nil
            msg("потолок копилки вернулся к умолчанию (3000)")
        end
    elseif cmd:match("^itemscan") then

        if cmd:match("stop") then
            if CoARU_ItemScanStop then CoARU_ItemScanStop() end
        elseif CoARU_ItemScanStart then
            CoARU_ItemScanStart(tonumber(cmd:match("(%d+)")))
        end
    elseif cmd:match("^item%s+%d+$") then

        local id = tonumber(cmd:match("%d+"))
        local function report(tag)
            local n, x, st = CoARU_CaptureItem(id)
            local ii = GetItemInfo and GetItemInfo(id)
            if st == "ok" then
                msg(("[%d] %s — |cff00ff00РЕЗОЛВИТСЯ|r (%s), GetItemInfo: %s"):format(
                    id, n, tag, ii or "nil"))
                if x then print(x) end
            elseif st == "pending" then
                msg(("[%d] нет в кэше, клиент запросил у сервера (%s)..."):format(id, tag))
            else
                msg(("[%d] |cffff0000тултип пуст|r (%s) — такого предмета у сервера нет"):format(id, tag))
            end
            return st
        end
        if report("сразу") == "pending" then
            local f = CreateFrame("Frame")
            local t = 0
            f:SetScript("OnUpdate", function(self, elapsed)
                t = t + elapsed
                if t < 1.5 then return end
                self:SetScript("OnUpdate", nil)
                report("повтор через 1.5 сек")
            end)
        end
    elseif cmd == "dev" or cmd == "help" then
        msg("команды разработчика (сбор данных для перевода):")
        print("  /coaru book — сканировать книгу заклинаний, собрать непереведенное")
        print("  /coaru book all — то же, включая уже переведенные")
        print("  /coaru scanall — сплошной скан ID по диапазонам, ловит таланты ВСЕХ классов (можно играть)")
        print("  /coaru scanall fast [мс] <A-B> — окно ID через дефис, напр. |cffffd100/coaru scanall fast 100 1-60000|r")
        print("  /coaru scanall color fast [мс] — ищет строки, где перевод ПОТЕРЯЛ подсветку; в дамп идут только дефекты")
        print("      (дефис — надежный синтаксис: нижняя граница < 1000 иначе неотличима от мс)")
        print("      без пауз, играть нельзя. Память: дамп >120k записей вешает клиент — сканируй КУСКАМИ.")
        print("  /coaru hover — вкл/выкл запись спеллов при наведении мыши")
        print("  /coaru probe — диагностика API клиента")
        print("  /coaru classes — снять все записи Character Advancement (список игрового контента + флаги мусора)")
        print("  /coaru status — счетчики базы и дампа")
        print("  /coaru clear — очистить дамп")
        print("  /coaru lines — сырые строки последнего тултипа")
        print("  /coaru ca — снять англ. текст экрана Character Advancement (открой экран спеков, потом команду)")
        print("  /coaru arch — снять описания ВСЕХ спеков всех классов через API (с одного перса, без прокачки)")
        print("  /coaru fit — какие строки окна персонажа не влезают в свое поле (открой C)")
        print("  /coaru geom — координаты кнопок в пикселях (открой журнал L)")
        print("  /coaru tipgeom on|off — замер геометрии ТУЛТИПА: вылет текста за рамку и ширина ru против en")
        print("  /coaru who — кто перевел каждую строку тултипа: база, карта аддона, пакет или никто")
        print("  /coaru frames — имена ОТКРЫТЫХ окон (открой нужные окна и повтори)")
        print("  /coaru callboard — снимок доски заданий: варианты разговора, список заданий, категории (открой доску)")
        print("  /coaru cafit — проверить верстку русских описаний спеков (все 70, альты не нужны)")
        print("  /coaru questscan <A-B> [зап/сек] — спросить у сервера текст квестов по номерам (кэш -> Parse-WdbCache.py)")
        print("  /coaru questprobe <id> — сырые строки тултипа одного квеста (диагностика скана)")
        print("  /coaru questids — номера всех квестов журнала (нужны, чтобы украсть текст с базы сайта)")
        print("  /coaru id <spellId> — показать, что видит сканер")
        print("  /coaru item <itemId> — резолвится ли тултип предмета по ID (проверка перед волной предметов)")
        print("  после сканирования: /reload, затем отдать WTF\\...\\SavedVariables\\CoARU.lua переводчику")
    else
        msg("русификатор работает автоматически. Команды разработчика: /coaru dev")
    end
end

local ADDON_PREFIX = "CoARU"

local function myVersion()
    return (GetAddOnMetadata and GetAddOnMetadata("CoARU", "Version")) or ""
end

local VER_MAX = 9999

local function verNum(s)
    if not s then return nil end
    local a, b, c = s:match("^(%d+)%.(%d+)%.(%d+)")
    if not a then
        a, b = s:match("^(%d+)%.(%d+)")
        c = 0
    end
    if not a then a, b, c = s:match("^(%d+)%s*$"), 0, 0 end
    if not a then return nil end
    a, b, c = tonumber(a), tonumber(b) or 0, tonumber(c) or 0

    if a > VER_MAX or b > VER_MAX or c > VER_MAX then return nil end
    return (a * (VER_MAX + 1) + b) * (VER_MAX + 1) + c
end

local told = false
CoARU_SEEN = {}
local answered = {}

local function replyVersion(who)
    if not who or who == "" or answered[who] or not SendAddonMessage then return end
    answered[who] = true
    pcall(SendAddonMessage, ADDON_PREFIX, "V:" .. myVersion(), "WHISPER", who)
end

local function noticeVersion(theirs, sender)
    local mine, other = verNum(myVersion()), verNum(theirs)
    if not mine or not other then return end
    if sender and sender ~= "" then CoARU_SEEN[sender] = theirs end
    if other < mine then

        replyVersion(sender)
        return
    end
    if other == mine or told then return end
    told = true
    print(("|cffC495DDCoARU|r|cffaaaaaa:|r вышла версия |cffffd100%s|r, у тебя |cff888888%s|r.")
        :format(theirs, myVersion()))
    print("|cffffd100Обновиться:|r " .. GITHUB_TEXT)
end

local VER_SAME, VER_OLD, VER_NEW = "|cffC495DD", "|cffff6060", "|cffffd100"

local function unitVersionLine(tip)
    if not tip or not tip.GetUnit then return end
    local name = tip:GetUnit()
    local ver = name and CoARU_SEEN[name]
    if not ver then return end
    local mine, other = verNum(myVersion()), verNum(ver)
    local color, tail = VER_SAME, ""
    if mine and other and other < mine then
        color, tail = VER_OLD, " |cff888888устарела|r"
    elseif mine and other and other > mine then
        color, tail = VER_NEW, " |cff888888новее|r"
    end
    tip:AddDoubleLine("|cffC495DDCoARU|r", color .. ver .. "|r" .. tail)
    tip:Show()
end

local function unitTooltip(tip)
    if not tip then return end
    if CoARU_TranslateUnitLine then
        local name = tip.GetName and tip:GetName() or "GameTooltip"
        local n = tip.NumLines and tip:NumLines() or 0
        for i = 2, n do
            local fs = _G[name .. "TextLeft" .. i]
            local t = fs and fs.GetText and fs:GetText()
            if t and t ~= "" then
                local ru = CoARU_TranslateUnitLine(t)
                if ru and ru ~= t then CoARU_SetTranslated(fs, t, ru) end
            end
        end
    end
    unitVersionLine(tip)
end
if GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetUnit", unitTooltip)
end

local function announceVersion()
    local v = myVersion()
    if v == "" or not SendAddonMessage then return end
    local function say(ch)
        pcall(SendAddonMessage, ADDON_PREFIX, "V:" .. v, ch)
    end

    if GetNumRaidMembers and GetNumRaidMembers() > 0 then say("RAID")
    elseif GetNumPartyMembers and GetNumPartyMembers() > 0 then say("PARTY") end
    if IsInGuild and IsInGuild() then say("GUILD") end
end

CoARU_InstallHooks = installHooks

local hookTimer
function CoARU_DeferHooks()
    if hookTimer then return end
    hookTimer = CreateFrame("Frame")
    local left = 2
    hookTimer:SetScript("OnUpdate", function(self)
        left = left - 1
        if left > 0 then return end
        self:SetScript("OnUpdate", nil)
        CoARU_InstallHooks()
    end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("CHAT_MSG_ADDON")

f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
    if event == "CHAT_MSG_ADDON" then

        if arg1 == ADDON_PREFIX and arg2 and arg2:sub(1, 2) == "V:" then
            noticeVersion(arg2:sub(3), arg4)
        end
        return
    end
    if event == "ADDON_LOADED" and arg1 == "CoARU" then
        initDB()

        if CoARU_DB.uirec == nil then CoARU_DB.uirec = not RELEASE end
        SLASH_COARU1 = "/coaru"
        SlashCmdList["COARU"] = slash
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_ENTERING_WORLD" then
        armWelcome()

        pcall(CoARU_UpdateMinimapButton)

        pcall(announceVersion)
    elseif event == "PLAYER_LOGIN" then
        CoARU_DeferHooks()
        local t = CoARU_CountLines and CoARU_CountLines() or 0
        local ver = (GetAddOnMetadata and GetAddOnMetadata("CoARU", "Version")) or ""
        local author = (GetAddOnMetadata and GetAddOnMetadata("CoARU", "Author")) or "Locative"

        if CoARU_UNOFFICIAL then
            print(UNOFFICIAL)
            print(whereOriginal())
        end
        local report = CoARU_LoadReport()
        if report == "stale" then

            print("|cffff0000CoARU: переводы НЕ работают.|r")
            print("|cffffd100Похоже, аддон обновляли, не выходя из игры полностью.|r")
            print("|cffffd100Выйди на рабочий стол и запусти игру заново|r (не /reload, не выход к выбору персонажа).")
        elseif report == "broken" then
            print("|cffff0000CoARU: переводы НЕ работают.|r")
            print("|cffffd100Файлы аддона загрузились не полностью.|r Выйди на рабочий стол, запусти игру заново.")
            print("|cff888888Если не помогло: проверь, что путь ...\\AddOns\\CoARU\\CoARU.toc, а не CoARU\\CoARU\\CoARU.toc.|r")
        else
            print(("|cffC495DDCoARU|r%s |cffaaaaaa-|r русификатор CoA. Автор: |cffC495DD%s|r. Переведено строк: |cffffd100%d|r."):format(
                ver ~= "" and (" |cff888888v" .. ver .. "|r") or "", author, t))

            if not CoARU_PACK_VERSION then
                print("|cffC495DDCoARU|r|cffaaaaaa:|r интерфейс игры можно перевести тоже — " ..
                      "в архиве есть папки |cffffd100PTRXML|r и |cffffd100CoARU_Loc|r. /coaru link")
            elseif ver ~= "" and CoARU_PACK_VERSION ~= ver then
                print(("|cffC495DDCoARU|r|cffaaaaaa:|r пакет интерфейса версии |cffffd100%s|r, " ..
                       "а аддон |cffffd100%s|r. Скачай архив заново: /coaru link"):format(
                       CoARU_PACK_VERSION, ver))
            end

            local me = UnitName and UnitName("player")
            local kind = CoARU_ThanksFor and CoARU_ThanksFor(me)
            if kind then
                local why = ({ donate = "за поддержку", data = "за присланные данные",
                               bugs = "за найденные ошибки" })[kind] or "за помощь"
                print(("|cffC495DDCoARU|r|cffaaaaaa:|r спасибо %s, |cffC495DD%s|r. Ты в списке: /coaru thanks"):format(why, me))
            else
                print("|cffC495DDCoARU|r|cffaaaaaa:|r нравится аддон? Поддержать автора: " .. DONATE_LINK)
            end

            armWelcome()
        end
    end
end)

local HITCH_MIN = 1.0
local HITCH_CAP = 60
local hitchFrame = CreateFrame("Frame")
local lastFrameAt
hitchFrame:SetScript("OnUpdate", function()
    local now = GetTime()
    if lastFrameAt then
        local gap = now - lastFrameAt
        if gap >= HITCH_MIN and CoARU_DB and CoARU_DB.opts and CoARU_DB.opts.hitch then
            local h = CoARU_DB.hitch
            if not h then h = {}; CoARU_DB.hitch = h end
            if #h < HITCH_CAP then
                h[#h + 1] = {
                    gap = gap,
                    mem = collectgarbage("count") / 1024,
                    scan = CoARU_ScanProgress and CoARU_ScanProgress() or nil,
                    zone = GetRealZoneText and GetRealZoneText() or nil,
                    at = date and date("%H:%M:%S") or nil,
                }
            end
        end
    end
    lastFrameAt = now
end)
