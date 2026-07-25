local PREFIX = "|cffC495DDCoARU|r: "
local function msg(text) print(PREFIX .. text) end

CoARU_DB = CoARU_DB or {}

local DONATE_URL = "https://www.donationalerts.com/r/locativeasc"

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

    local head = f:CreateTexture(nil, "ARTWORK")
    head:SetTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.13)
    head:SetPoint("TOPLEFT", 5, -5)
    head:SetPoint("TOPRIGHT", -5, -5)
    head:SetHeight(58)

    local headLine = f:CreateTexture(nil, "OVERLAY")
    headLine:SetTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.75)
    headLine:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, 0)
    headLine:SetPoint("TOPRIGHT", head, "BOTTOMRIGHT", 0, 0)
    headLine:SetHeight(2)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 22, -16)
    title:SetText(titleText)
    title:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])

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
    b:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    local function idle(self)
        if primary then
            self:SetBackdropColor(ACCENT[1] * 0.42, ACCENT[2] * 0.42, ACCENT[3] * 0.42, 1)
            self:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
        else
            self:SetBackdropColor(0.13, 0.13, 0.16, 1)
            self:SetBackdropBorderColor(ACCENT[1] * 0.5, ACCENT[2] * 0.5, ACCENT[3] * 0.5, 1)
        end
    end
    idle(b)

    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER")
    fs:SetText(text)
    local baseR, baseG, baseB = 0.88, 0.88, 0.92
    if primary then baseR, baseG, baseB = 1, 1, 1 end
    fs:SetTextColor(baseR, baseG, baseB)

    b:SetScript("OnEnter", function(self)
        local k = primary and 0.62 or 0.3
        self:SetBackdropColor(ACCENT[1] * k, ACCENT[2] * k, ACCENT[3] * k, 1)
        self:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
        fs:SetTextColor(1, 1, 1)
    end)
    b:SetScript("OnLeave", function(self)
        idle(self)
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

local function styledCheck(parent, text)
    local cb = CreateFrame("CheckButton", nil, parent)
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
    cb:SetScript("OnEnter", function()
        for i = 1, #edges do edges[i]:SetTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1) end
        lbl:SetTextColor(1, 1, 1)
    end)
    cb:SetScript("OnLeave", function()
        for i = 1, #edges do
            edges[i]:SetTexture(ACCENT[1] * 0.6, ACCENT[2] * 0.6, ACCENT[3] * 0.6, 1)
        end
        lbl:SetTextColor(0.8, 0.8, 0.85)
    end)

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

local donateFrame
local function ensureDonateFrame()
    if donateFrame then return donateFrame end

    local PAD = 24
    local GAP_HEAD = 6
    local GAP_CTRL = 10

    local GAP_SECT = 12
    local CTRL_H = 26
    local BTN_W = 148
    local FOOTER_H = 52
    local INNER = 480 - PAD * 2

    local f = makePanel("CoARUDonateFrame", "FULLSCREEN_DIALOG", 480, 376,

        "Поддержать автора", "CoARU, русификатор Conquest of Azeroth")

    local dHead = f:Divider(-72)

    local thanks = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    thanks:SetPoint("TOPLEFT", dHead, "BOTTOMLEFT", 2, -GAP_SECT)
    thanks:SetWidth(INNER)
    thanks:SetJustifyH("LEFT")

    thanks:SetText("Спасибо, что пользуешься аддоном!\n\n"
        .. "Я разрабатываю CoARU один и занимаюсь им в свободное время. "
        .. "Поддержка поможет быстрее выпускать обновления.")
    thanks:SetTextColor(0.84, 0.84, 0.88)

    local dMoney = f:DividerUnder(thanks, GAP_SECT)

    local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", dMoney, "BOTTOMLEFT", 2, -GAP_SECT)
    label:SetText("Поддержать деньгами")
    label:SetTextColor(ACCENT_LIGHT[1], ACCENT_LIGHT[2], ACCENT_LIGHT[3])

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -GAP_HEAD)

    hint:SetText("Нажми на ссылку, затем скопируй ее через |cffffd100Ctrl+C|r.")
    hint:SetTextColor(0.82, 0.82, 0.86)

    local eb = CreateFrame("EditBox", "CoARUDonateEdit", f, "InputBoxTemplate")
    eb:SetWidth(INNER - 12)
    eb:SetHeight(CTRL_H)
    eb:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 6, -GAP_CTRL)
    eb:SetAutoFocus(false)

    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(self) self:HighlightText() end)

    eb:SetScript("OnMouseUp", function(self) self:HighlightText() end)
    eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    local restoring = false
    eb:SetScript("OnTextChanged", function(self)
        if restoring then return end
        if self:GetText() ~= DONATE_URL then
            restoring = true
            self:SetText(DONATE_URL)
            self:SetCursorPosition(0)
            self:HighlightText()
            restoring = false
        end
    end)

    local dHelp = f:DividerUnder(eb, GAP_SECT)

    local altHead = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    altHead:SetPoint("TOPLEFT", dHelp, "BOTTOMLEFT", 2, -GAP_SECT)

    altHead:SetText("Помочь переводу")
    altHead:SetTextColor(ACCENT_LIGHT[1], ACCENT_LIGHT[2], ACCENT_LIGHT[3])

    local altText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    altText:SetPoint("TOPLEFT", altHead, "BOTTOMLEFT", 0, -GAP_HEAD)
    altText:SetWidth(INNER - BTN_W - 20)
    altText:SetJustifyH("LEFT")

    altText:SetText("Встретил непереведенное или ошибку?\n"
        .. "Собери отчет и пришли файл в Discord |cffC495DDlocativeds|r.")
    altText:SetTextColor(0.82, 0.82, 0.86)

    local report = styledButton(f, BTN_W, CTRL_H, "Собрать отчет", false,
        "CoARUDonateReportButton")
    report:SetPoint("TOPRIGHT", dHelp, "BOTTOMRIGHT", -2, -GAP_SECT - 8)
    report:SetScript("OnClick", runStatusReport)

    local dFoot = f:DividerUnder(altText, GAP_SECT)

    local btn = styledButton(f, BTN_W, CTRL_H, "Закрыть")
    btn:SetPoint("BOTTOMRIGHT", -PAD, (FOOTER_H - CTRL_H) / 2)
    btn:SetScript("OnClick", function() f:Hide() end)

    local sized = false
    local function fitHeight(self)
        if sized then return end
        local top, bottom = self:GetTop(), dFoot:GetBottom()
        if top and bottom then
            self:SetHeight(top - bottom + FOOTER_H)
            sized = true
        end
    end

    f:SetScript("OnHide", function()
        if welcomeSuspended then
            welcomeSuspended = false
            if welcomeFrame then welcomeFrame:Show() end
        end
    end)

    f:SetScript("OnShow", function(self)
        fitHeight(self)
        eb:SetText(DONATE_URL)
        eb:SetCursorPosition(0)
        eb:HighlightText()
        eb:SetFocus()
    end)

    donateFrame = f
    return f
end

local function showDonate()
    msg("поддержать автора: " .. DONATE_URL)
    if welcomeFrame and welcomeFrame:IsShown() then
        welcomeSuspended = true
        welcomeFrame:Hide()
    end
    ensureDonateFrame():Show()
end

local function ensureWelcomeFrame()
    if welcomeFrame then return welcomeFrame end

    local PAD = 24
    local CTRL_H = 26
    local BTN_W = 148
    local FOOTER_H = 52

    local f, verStr = makePanel("CoARUWelcomeFrame", "DIALOG", 560, 442,
        "CoARU", "русификатор Conquest of Azeroth", true)
    local divider = function(y) f:Divider(y) end

    local function bullet(y, head2, text)
        local dot = f:CreateTexture(nil, "OVERLAY")
        dot:SetTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.95)
        dot:SetWidth(4)
        dot:SetHeight(4)
        dot:SetPoint("TOPLEFT", 26, y - 7)
        local h = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h:SetPoint("TOPLEFT", 38, y)
        h:SetText(head2)
        h:SetTextColor(ACCENT_LIGHT[1], ACCENT_LIGHT[2], ACCENT_LIGHT[3])
        local b = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b:SetPoint("TOPLEFT", 38, y - 18)
        b:SetWidth(486)
        b:SetJustifyH("LEFT")
        b:SetText(text)
        b:SetTextColor(0.82, 0.82, 0.87)
    end

    divider(-72)

    local key = ({ ALT = "Alt", CTRL = "Ctrl", SHIFT = "Shift" })[
        CoARU_OriginalMod and CoARU_OriginalMod() or "ALT"] or "Alt"

    bullet(-86, "Зажми " .. key .. " над тултипом",
        "Покажет исходное английское описание. Пригодится, чтобы описать способность в чате\n"
        .. "или найти ее в гайде. Сменить клавишу: |cffffd100/coaru original ctrl|r")
    bullet(-144, "Имена способностей оставлены латиницей",
        "Так их проще связать с тем, что пишут в чате и показывает интерфейс игры.")
    bullet(-190, "Числа берутся из живого тултипа",
        "Урон и проценты не устаревают после правок баланса на сервере.")

    divider(-238)

    local plate = f:CreateTexture(nil, "ARTWORK")
    plate:SetTexture(1, 1, 1, 0.045)
    plate:SetPoint("TOPLEFT", 22, -250)
    plate:SetPoint("TOPRIGHT", -22, -250)

    local nTr = 0
    for _ in pairs(CoARU_LOC_EN or {}) do nTr = nTr + 1 end

    local statNum = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    statNum:SetPoint("TOP", f, "TOP", 0, -258)
    statNum:SetText(groupNum(nTr))
    statNum:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])

    local statLbl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statLbl:SetPoint("TOP", statNum, "BOTTOM", 0, -3)
    statLbl:SetText("переводов в базе")
    statLbl:SetTextColor(0.72, 0.72, 0.78)

    plate:SetPoint("BOTTOM", statLbl, "BOTTOM", 0, -8)

    local helpHead = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    helpHead:SetPoint("TOPLEFT", 26, -318)
    helpHead:SetText("Нашел непереведенное или ошибку?")
    helpHead:SetTextColor(ACCENT_LIGHT[1], ACCENT_LIGHT[2], ACCENT_LIGHT[3])

    local help = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", 26, -336)
    help:SetWidth(330)
    help:SetJustifyH("LEFT")
    help:SetText("Собери отчет и пришли файл в Discord |cffC495DDlocativeds|r.\n"
        .. "Именно из них собирается следующая волна перевода.")
    help:SetTextColor(0.82, 0.82, 0.87)

    local report = styledButton(f, BTN_W, CTRL_H, "Собрать отчет", false,
        "CoARUWelcomeReportButton")
    report:SetPoint("TOPRIGHT", -PAD, -332)
    report:SetScript("OnClick", runStatusReport)

    local cmdHint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    cmdHint:SetPoint("TOP", report, "BOTTOM", 0, -6)
    cmdHint:SetText("то же самое: /coaru status")
    cmdHint:SetTextColor(0.5, 0.5, 0.55)

    divider(-386)

    local cb = styledCheck(f, "Не показывать при запуске")

    cb:SetPoint("BOTTOMLEFT", PAD, (FOOTER_H - CTRL_H) / 2 + (CTRL_H - 18) / 2)

    local donate = styledButton(f, BTN_W, CTRL_H, "Поддержать автора", true)
    donate:SetPoint("BOTTOMRIGHT", -(PAD + BTN_W + 12), (FOOTER_H - CTRL_H) / 2)
    donate:SetScript("OnClick", function() showDonate() end)

    local btn = styledButton(f, BTN_W, CTRL_H, "Закрыть")
    btn:SetPoint("BOTTOMRIGHT", -PAD, (FOOTER_H - CTRL_H) / 2)
    btn:SetScript("OnClick", function() f:Hide() end)

    f:SetScript("OnHide", function()
        CoARU_DB.opts = CoARU_DB.opts or {}
        if cb:GetChecked() then CoARU_DB.opts.welcomeVer = verStr end
    end)

    f:Hide()
    welcomeFrame = f
    return f
end

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
    return n
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

local MISS_CAP = 3000

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

local function noteOneLine(kind, line, owner)
    if not line or not CoARU_DB or not CoARU_DB.miss then return end

    if CoARU_DeflateStatus and not CoARU_DeflateStatus() then return end
    if skipByOwner(owner, line) then return end
    if CoARU_HasCyrillic(line) then return end
    local plain = CoARU_StripCodes(line)
    if not plain or not plain:find("%a") then return end
    local norm = CoARU_Norm(plain)
    if not norm or #norm < 4 then return end
    local m = CoARU_DB.miss
    local rec = m[norm]
    if rec then
        rec.n = (rec.n or 1) + 1
        return
    end
    local n = 0
    for _ in pairs(m) do n = n + 1 end
    if n >= MISS_CAP then

        n = n - purgeSent()
        if n >= MISS_CAP then return end
    end

    m[norm] = { n = 1, k = kind, ex = plain, own = owner, ts = (time and time()) or 0 }
end

function CoARU_NoteMiss(kind, text, owner)
    if not text then return end
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

local function onTooltipSetSpell(tip)

    if CoARU_ScanRaw then return end
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

local function colorizeDelta(ru)

    local body = ru:match("^|[cC]%x%x%x%x%x%x%x%x(.*)$") or ru
    body = body:gsub("|r$", "")
    local sign, num, rest = body:match("^([%+%-])([%d%.,]+)(.*)$")
    if not sign then return ru end
    local hex = (sign == "+") and "ff1eff00" or "ffff2020"
    return "|c" .. hex .. sign .. num .. "|r|cffffffff" .. rest .. "|r"
end

local function clientRewritesLine(t)
    if not t then return false end
    local plain = CoARU_StripCodes(t)
    if not plain or plain == "" then return false end
    if plain:sub(1, 2) == '"@' then return true end
    local heroic = _G.ITEM_HEROIC
    if heroic and heroic ~= "" and plain:sub(1, #heroic) == heroic then
        return true
    end
    return false
end

local function onTooltipSetItem(tip)
    local name = tip:GetName()
    if not name or not tip.GetItem then return end
    local ok, itemName, link = pcall(tip.GetItem, tip)
    if not ok or not link then return end
    local id = tonumber(link:match("item:(%d+)"))
    if not id then return end

    local snapFS = snapshotTip(tip, name, id)

    local changed = false

    local suffixID = tonumber(link:match(
        "item:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:(%-?%d+)"))
    local hasSuffix = suffixID ~= nil and suffixID ~= 0

    local ru = (not hasSuffix) and CoARU_ItemName and CoARU_ItemName[id] or nil
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
    end

    local desc = CoARU_ItemDesc and CoARU_ItemDesc[id]

    local inDelta = false
    for i = 2, tip:NumLines() do
        for _, side in ipairs({ "TextLeft", "TextRight" }) do
            local fs = _G[name .. side .. i]
            local t = fs and fs:GetText()
            if t and side == "TextLeft" and t:find("%S")
                and (t:find(DELTA_HEADER_EN, 1, true) or t:find(DELTA_HEADER_RU, 1, true)) then
                inDelta = true
            end
            if t and #t > 2 and t:find("%S") and not CoARU_HasCyrillic(t)
                and not clientRewritesLine(t) then

                if desc and side == "TextLeft" and t:match('^".*"$') then
                    CoARU_SetTranslated(fs, t, '"' .. desc .. '"')
                    changed = true
                else

                    if t ~= itemName then
                        CoARU_NoteBlockMisses("item", nil, t)
                    end
                    local r = CoARU_TranslateBlock(nil, t)

                    if not (r and r ~= t) and CoARU_TranslateItemPrefix then
                        r = CoARU_TranslateItemPrefix(t)
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

    for i = 1, 4 do
        local pf = _G[name .. "MoneyFrame" .. i .. "PrefixText"]
        local t = pf and pf:GetText()
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

    local itemName
    if tip.GetItem then
        local ok, n = pcall(tip.GetItem, tip)
        if ok then itemName = n end
    end

    local isSpellTip = false
    if tip.GetSpell then
        local ok, sn = pcall(tip.GetSpell, tip)
        if ok and sn then isSpellTip = true end
    end

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

    local isSchoolTip = isResistTip
        or (ownerName ~= nil and ownerName:find(SCHOOL_OWNER, 1, true) ~= nil)
    local changed = false
    local inDelta = false
    for i = 1, tip:NumLines() do
        for _, side in ipairs({ "TextLeft", "TextRight" }) do
            local fs = _G[name .. side .. i]
            local t = fs and fs:GetText()
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
                elseif #t > 2 and not CoARU_HasCyrillic(t) and not clientRewritesLine(t)
                    and not (i == 1 and side == "TextLeft" and isSpellTip) then

                    local ru

                    if side == "TextLeft" and CoARU_ItemNameEN then
                        ru = CoARU_ItemNameEN[CoARU_StripCodes(t)]
                    end
                    if not ru then ru = CoARU_TranslateBlock(nil, t) end

                    if not (ru and ru ~= t) and CoARU_TranslateItemPrefix then
                        ru = CoARU_TranslateItemPrefix(t)
                    end
                    if ru and ru ~= t then
                        if inDelta then ru = colorizeDelta(ru) end
                        CoARU_SetTranslated(fs, t, ru)
                        changed = true
                    elseif t ~= itemName and (i > 1 or isSchoolTip) then

                        CoARU_NoteMiss("tip", t, ownerName)
                    end
                end
            end
        end
    end

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

    for i = 2, tip:NumLines() do
        for _, side in ipairs({ "TextLeft", "TextRight" }) do
            local fs = _G[name .. side .. i]
            local t = fs and fs:GetText()
            if t and #t > 2 and t:find("%S") and not CoARU_HasCyrillic(t) then

                CoARU_NoteBlockMisses("aura", id, t)
                local ru = CoARU_TranslateBlock(id, t)
                if ru and ru ~= t then
                    CoARU_SetTranslated(fs, t, ru)
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
            if ok then translateAuraTip(self, tonumber(id)) end
        end)
    end
    if tip.SetUnitBuff then
        hooksecurefunc(tip, "SetUnitBuff", function(self, unit, index, filter)
            local ok, id = pcall(function() return select(11, UnitBuff(unit, index, filter)) end)
            if ok then translateAuraTip(self, tonumber(id)) end
        end)
    end
    if tip.SetUnitDebuff then
        hooksecurefunc(tip, "SetUnitDebuff", function(self, unit, index, filter)
            local ok, id = pcall(function() return select(11, UnitDebuff(unit, index, filter)) end)
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

                      welcome = true, ["привет"] = true, hint = true,
                      ["hint off"] = true, ["hint on"] = true }

local function isOriginalCmd(cmd)
    return cmd:match("^original") or cmd:match("^оригинал") or cmd:match("^англ")
end

local function slash(cmd)
    cmd = (cmd or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
    if RELEASE and not PLAYER_CMDS[cmd] and not isOriginalCmd(cmd) then
        msg("доступна команда /coaru status — она показывает, что собрал аддон.")
        return
    end
    if cmd == "" then
        local t = 0
        for _ in pairs(CoARU_LOC_EN or {}) do t = t + 1 end
        msg(("русификатор описаний Conquest of Azeroth. Переводит спеллы автоматически. Переводов в базе: %d."):format(t))

        local key = CoARU_OriginalMod and CoARU_OriginalMod() or "ALT"
        key = key:sub(1, 1) .. key:sub(2):lower()
        print(("  |cffffd100%s|r над тултипом — показать оригинал на английском (сменить клавишу: /coaru original ctrl)"):format(key))
        print("  поддержать автора: " .. DONATE_LINK)
        return
    end
    if cmd == "donate" or cmd == "support" or cmd == "спасибо" or cmd == "донат" then
        showDonate()
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

        if CoARU_SetScanDesc then CoARU_SetScanDesc(cmd:match("%f[%a]desc%f[%A]") ~= nil) end
        local fast = cmd:match("%f[%a]fast") ~= nil

        if fast then ms = math.min(math.max(ms or 100, 1), 1000) else ms = nil end
        CoARU_StartScanRanges(CoARU_ScanRanges or {}, cmd:match("%f[%a]all%f[%A]") ~= nil, ms, minId, maxId)
    elseif cmd == "hover" then
        CoARU_DB.opts.hover = not CoARU_DB.opts.hover
        msg("режим записи при наведении: " .. (CoARU_DB.opts.hover and "|cff00ff00ВКЛ|r — наводи мышь на спеллы, непереведенные попадут в дамп" or "|cffff0000ВЫКЛ|r"))
    elseif cmd == "probe" then
        CoARU_Probe()
    elseif cmd == "classes" then
        CoARU_ProbeClasses()
    elseif cmd == "status" then

        if RELEASE then

            local nsp, nit, nbt, nq = 0, 0, 0, 0
            for _ in pairs(CoARU_LOC_EN or {}) do nsp = nsp + 1 end
            for _ in pairs(CoARU_ItemName or {}) do nit = nit + 1 end
            for _ in pairs(CoARU_ItemNameEN or {}) do nbt = nbt + 1 end
            for _ in pairs(CoARU_QUEST or {}) do nq = nq + 1 end
            msg(("загружено: спеллов %d, предметов %d (+%d по имени), заданий %d")
                :format(nsp, nit, nbt, nq))

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
            print("  |cffffd1003.|r пришли его в Discord: |cffC495DDlocativeds|r")

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

        if CoARU_PaperDollStatus then
            local n, where, fs = CoARU_PaperDollStatus()
            msg(("текст окон: строк %d, FontString в кэше %d | %s"):format(n, fs or 0, where))
        end

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

        CoARU_DB.dump = {}
        CoARU_DB.classids = nil
        CoARU_DB.probe = nil
        CoARU_DB.castrings = nil
        CoARU_DB.specinfo = nil
        CoARU_DB.catext = nil
        CoARU_DB.trainerdump = nil
        CoARU_DB.trainercolor = nil
        CoARU_DB.trainerscan = nil
        CoARU_DB.lines = nil
        CoARU_DB.questdump = nil
        CoARU_DB.geom = nil
        CoARU_DB.frames = nil
        CoARU_DB.miss = {}
        msg("дамп очищен (включая собранные дыры).")
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
        print("  /coaru frames — имена ОТКРЫТЫХ окон (открой нужные окна и повтори)")
        print("  /coaru cafit — проверить верстку русских описаний спеков (все 70, альты не нужны)")
        print("  /coaru id <spellId> — показать, что видит сканер")
        print("  /coaru item <itemId> — резолвится ли тултип предмета по ID (проверка перед волной предметов)")
        print("  после сканирования: /reload, затем отдать WTF\\...\\SavedVariables\\CoARU.lua переводчику")
    else
        msg("русификатор работает автоматически. Команды разработчика: /coaru dev")
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")

f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "CoARU" then
        initDB()
        SLASH_COARU1 = "/coaru"
        SlashCmdList["COARU"] = slash
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_ENTERING_WORLD" then
        armWelcome()
    elseif event == "PLAYER_LOGIN" then
        installHooks()
        local t = 0
        for _ in pairs(CoARU_LOC_EN or {}) do t = t + 1 end
        local ver = (GetAddOnMetadata and GetAddOnMetadata("CoARU", "Version")) or ""
        local author = (GetAddOnMetadata and GetAddOnMetadata("CoARU", "Author")) or "Locative"

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
            print(("|cffC495DDCoARU|r%s |cffaaaaaa-|r русификатор описаний CoA. Автор: |cffC495DD%s|r. Переводов: |cffffd100%d|r."):format(
                ver ~= "" and (" |cff888888v" .. ver .. "|r") or "", author, t))
            print("|cffC495DDCoARU|r|cffaaaaaa:|r нравится аддон? Поддержать автора: " .. DONATE_LINK)

            armWelcome()
        end
    end
end)
