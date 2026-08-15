local ACCENT      = { 0.77, 0.58, 0.87 }
local BG          = { 0.06, 0.06, 0.08, 0.96 }
local BORDER      = { 0.20, 0.20, 0.22, 1 }
local TEX         = "Interface\\AddOns\\CoARU\\Textures\\"
local WHITE       = "Interface\\Buttons\\WHITE8X8"

CoARU_SKIN = { accent = ACCENT, bg = BG, border = BORDER, tex = TEX }

local mult = 1
local function recalcMult()
    local h = select(2, GetPhysicalScreenSize and GetPhysicalScreenSize() or nil, nil)
    if not h then

        local res = GetCVar and GetCVar("gxResolution")
        h = res and tonumber(res:match("%d+x(%d+)")) or 768
    end

    local scale = 1
    if UIParent and type(UIParent.GetScale) == "function" then
        local ok, v = pcall(UIParent.GetScale, UIParent)
        if ok and type(v) == "number" and v > 0 then scale = v end
    end
    mult = 768 / h / scale
    if mult <= 0 then mult = 1 end
end

function CoARU_Px(x)

    return mult * math.floor((x or 0) / mult + 0.5)
end

CoARU_SkinRecalc = recalcMult

local C10 = 0.625
local CORNER = 10

local function corner(f, layer, point, flipH, flipV)
    local t = f:CreateTexture(nil, layer)
    t:SetTexture(TEX .. "corner10.tga")
    t:SetWidth(CORNER)
    t:SetHeight(CORNER)
    t:SetPoint(point, f, point, 0, 0)
    local l, r2 = 0, C10
    local tp, b = 0, C10
    if flipH then l, r2 = r2, l end
    if flipV then tp, b = b, tp end
    t:SetTexCoord(l, r2, tp, b)
    return t
end

function CoARU_SkinFrame9(f, bg, border)
    bg, border = bg or BG, border or BORDER

    if f.SetBackdrop then f:SetBackdrop(nil) end

    local shadow = f:CreateTexture(nil, "BACKGROUND")
    shadow:SetTexture(TEX .. "glow.tga")
    shadow:SetPoint("TOPLEFT", f, "TOPLEFT", -14, 14)
    shadow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 14, -14)
    shadow:SetVertexColor(0, 0, 0, 0.55)

    local parts = { shadow = shadow, fill = {}, edge = {} }

    local function fill(layer)
        local mid = f:CreateTexture(nil, layer)
        mid:SetTexture(WHITE)
        mid:SetPoint("TOPLEFT", f, "TOPLEFT", CORNER, -CORNER)
        mid:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -CORNER, CORNER)
        local top = f:CreateTexture(nil, layer)
        top:SetTexture(WHITE)
        top:SetPoint("TOPLEFT", f, "TOPLEFT", CORNER, 0)
        top:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -CORNER, -CORNER)
        local bot = f:CreateTexture(nil, layer)
        bot:SetTexture(WHITE)
        bot:SetPoint("TOPLEFT", f, "BOTTOMLEFT", CORNER, CORNER)
        bot:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -CORNER, 0)
        local lf = f:CreateTexture(nil, layer)
        lf:SetTexture(WHITE)
        lf:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -CORNER)
        lf:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", CORNER, CORNER)
        local rt = f:CreateTexture(nil, layer)
        rt:SetTexture(WHITE)
        rt:SetPoint("TOPLEFT", f, "TOPRIGHT", -CORNER, -CORNER)
        rt:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, CORNER)
        return { mid, top, bot, lf, rt,
                 corner(f, layer, "TOPLEFT", false, false),
                 corner(f, layer, "TOPRIGHT", true, false),
                 corner(f, layer, "BOTTOMLEFT", false, true),
                 corner(f, layer, "BOTTOMRIGHT", true, true) }
    end
    parts.fill = fill("BACKGROUND")
    for i = 1, #parts.fill do
        parts.fill[i]:SetVertexColor(bg[1], bg[2], bg[3], bg[4] or 1)
    end

    local px = CoARU_Px(1)
    local function line(p1, p2, w, h)
        local t = f:CreateTexture(nil, "BORDER")
        t:SetTexture(WHITE)
        t:SetPoint(p1, f, p1, (p1:find("LEFT") and CORNER) or -CORNER, 0)
        t:SetPoint(p2, f, p2, (p2:find("LEFT") and CORNER) or -CORNER, 0)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
        return t
    end
    parts.edge = {
        line("TOPLEFT", "TOPRIGHT", nil, px),
        line("BOTTOMLEFT", "BOTTOMRIGHT", nil, px),
    }
    local lft = f:CreateTexture(nil, "BORDER")
    lft:SetTexture(WHITE)
    lft:SetWidth(px)
    lft:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -CORNER)
    lft:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, CORNER)
    local rgt = f:CreateTexture(nil, "BORDER")
    rgt:SetTexture(WHITE)
    rgt:SetWidth(px)
    rgt:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -CORNER)
    rgt:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, CORNER)
    parts.edge[#parts.edge + 1] = lft
    parts.edge[#parts.edge + 1] = rgt
    for i = 1, #parts.edge do
        parts.edge[i]:SetVertexColor(border[1], border[2], border[3], border[4] or 1)
    end
    return parts
end

function CoARU_SkinHighlight(btn, alpha)
    local t = btn:CreateTexture(nil, "HIGHLIGHT")
    t:SetTexture(TEX .. "glow.tga")
    t:SetVertexColor(ACCENT[1], ACCENT[2], ACCENT[3])
    t:SetAlpha(alpha or 0.3)
    t:SetAllPoints(btn)
    t:SetBlendMode("ADD")
    return t
end

function CoARU_SkinDivider(parent, w)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture(TEX .. "divider.tga")
    t:SetVertexColor(ACCENT[1], ACCENT[2], ACCENT[3])
    t:SetAlpha(0.35)
    t:SetHeight(CoARU_Px(1))
    if w then t:SetWidth(w) end
    return t
end

local TRACK_W, TRACK_H = 34, 18
local KNOB = 14
local TRACK_COORD = { 0, 0.5625, 0, 0.625 }

function CoARU_SkinToggle(parent, label, name)
    local cb = CreateFrame("CheckButton", name, parent)
    cb:SetWidth(TRACK_W)
    cb:SetHeight(TRACK_H)

    local track = cb:CreateTexture(nil, "BACKGROUND")
    track:SetTexture(TEX .. "toggle-track.tga")
    track:SetTexCoord(TRACK_COORD[1], TRACK_COORD[2], TRACK_COORD[3], TRACK_COORD[4])
    track:SetAllPoints(cb)

    local knob = cb:CreateTexture(nil, "ARTWORK")
    knob:SetTexture(TEX .. "toggle-knob.tga")
    knob:SetWidth(KNOB)
    knob:SetHeight(KNOB)
    knob:SetPoint("LEFT", cb, "LEFT", 2, 0)

    local lbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", cb, "RIGHT", 10, 0)
    lbl:SetText(label)
    cb.label = lbl

    local function paint()
        local on, blocked = cb.on, cb.blocked
        local a = blocked and 0.25 or 1
        if on then
            track:SetVertexColor(ACCENT[1] * a, ACCENT[2] * a, ACCENT[3] * a, blocked and 0.5 or 0.9)
            knob:SetVertexColor(1 * a, 1 * a, 1 * a, 1)
        else
            track:SetVertexColor(0.22 * a, 0.22 * a, 0.26 * a, blocked and 0.5 or 1)
            knob:SetVertexColor(0.45 * a, 0.45 * a, 0.5 * a, 1)
        end
        lbl:SetTextColor(blocked and 0.42 or 0.86, blocked and 0.42 or 0.86,
            blocked and 0.46 or 0.9)
        knob:ClearAllPoints()
        knob:SetPoint(on and "RIGHT" or "LEFT", cb, on and "RIGHT" or "LEFT", on and -2 or 2, 0)
    end

    local rawSet = cb.SetChecked
    cb.SetChecked = function(self, v)
        v = v and true or false
        self.on = v
        if rawSet then rawSet(self, v) end
        paint()
    end
    cb.GetChecked = function(self) return self.on end

    cb:SetScript("OnClick", function(self)
        if self.blocked then return end
        self:SetChecked(not self.on)
    end)

    cb.SetBlocked = function(self, why)
        self.blocked = (why ~= nil)
        self.blockWhy = why
        if why then self:Disable() else self:Enable() end
        paint()
    end

    CoARU_SkinHighlight(cb, 0.18)

    cb:SetHitRectInsets(0, -(lbl:GetStringWidth() + 14), -4, -4)
    cb:SetChecked(false)
    return cb
end

function CoARU_SkinTab(parent, label, w, h, icon)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(w or 136)
    b:SetHeight(h or 26)

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetAllPoints(b)
    bg:SetVertexColor(1, 1, 1, 0)

    local bar = b:CreateTexture(nil, "ARTWORK")
    bar:SetTexture(WHITE)
    bar:SetWidth(CoARU_Px(3))
    bar:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    bar:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
    bar:SetVertexColor(ACCENT[1], ACCENT[2], ACCENT[3], 0)

    local ic
    if icon then
        ic = b:CreateTexture(nil, "ARTWORK")

        ic:SetTexture("Interface\\Icons\\" .. icon)
        ic:SetWidth(15)
        ic:SetHeight(15)
        ic:SetPoint("LEFT", b, "LEFT", 13, 0)
        ic:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        ic:SetDesaturated(true)
        ic:SetVertexColor(0.62, 0.62, 0.68)
    end

    local lbl = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", b, "LEFT", icon and 36 or 14, 0)
    lbl:SetText(label)
    lbl:SetTextColor(0.62, 0.62, 0.68)
    CoARU_SkinFont(lbl, 12)
    b.label = lbl

    b.SetActive = function(self, on)
        self.active = on and true or false
        bar:SetVertexColor(ACCENT[1], ACCENT[2], ACCENT[3], on and 1 or 0)
        bg:SetVertexColor(ACCENT[1], ACCENT[2], ACCENT[3], on and 0.10 or 0)
        lbl:SetTextColor(on and 0.95 or 0.62, on and 0.9 or 0.62, on and 1 or 0.68)
        if ic then
            ic:SetDesaturated(not on)
            ic:SetVertexColor(on and 1 or 0.55, on and 1 or 0.55, on and 1 or 0.6)
        end
    end
    CoARU_SkinHighlight(b, 0.12)
    b:SetActive(false)
    return b
end

local function centerStack(owner, ownerH, x, list)
    local function place()
        local block, n = 0, 0
        for i = 1, #list do
            local e = list[i]
            if e.fs and (e.fs:GetText() or "") ~= "" then
                local hgt = e.fs:GetStringHeight() or 0
                if hgt <= 0 then hgt = e.fallback or 13 end
                if n > 0 then block = block + (e.gap or 0) end
                block = block + hgt
                n = n + 1
            end
        end
        local H = owner:GetHeight() or 0
        if H <= 0 then H = ownerH end

        local top = math.floor((H - block) / 2 + 0.5)
        if top < 0 then top = 0 end
        list[1].fs:ClearAllPoints()
        list[1].fs:SetPoint("TOPLEFT", owner, "TOPLEFT", x, -top)
    end
    place()
    owner:HookScript("OnShow", place)
    return place
end

local function centerRowText(row, rowH, lbl, sub, x, gap, fallbackL, fallbackS)
    return centerStack(row, rowH, x, {
        { fs = lbl, fallback = fallbackL or 15 },
        { fs = sub, gap = gap or 3, fallback = fallbackS or 12 },
    })
end

function CoARU_SkinButton(parent, w, h, text, accent, name)
    local b = CreateFrame("Button", name, parent)
    b:SetWidth(w)
    b:SetHeight(h)

    local px = CoARU_Px(1)
    local R = 5
    local edge = CoARU_SkinRounded(b, ACCENT, "BACKGROUND", 0, R)
    local fill = CoARU_SkinRounded(b, { 1, 1, 1 }, "BORDER", px, R - px)

    local lbl = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("CENTER", b, "CENTER", 0, 0)
    lbl:SetText(text)
    CoARU_SkinFont(lbl, 13)
    b.label = lbl

    if accent then
        fill({ ACCENT[1] * 0.42, ACCENT[2] * 0.42, ACCENT[3] * 0.42 }, 1)
        edge(ACCENT, 0.9)
        lbl:SetTextColor(1, 1, 1)
    else
        fill({ 0.13, 0.13, 0.155 }, 1)
        edge({ ACCENT[1] * 0.5, ACCENT[2] * 0.5, ACCENT[3] * 0.5 }, 1)
        lbl:SetTextColor(0.84, 0.84, 0.9)
    end

    local hl = CoARU_SkinHighlight(b, 0.18)
    hl:ClearAllPoints()
    hl:SetPoint("TOPLEFT", b, "TOPLEFT", px, -px)
    hl:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -px, px)
    return b
end

function CoARU_SkinGradient(parent, layer, r, g, b, a1, a2, vertical)
    local t = parent:CreateTexture(nil, layer or "ARTWORK")
    t:SetTexture(WHITE)
    if t.SetGradientAlpha then
        t:SetGradientAlpha(vertical and "VERTICAL" or "HORIZONTAL",
            r, g, b, a1, r, g, b, a2)
    else
        t:SetVertexColor(r, g, b, (a1 + a2) / 2)
    end
    return t
end

local FONT = "Interface\\AddOns\\CoARU\\Fonts\\PTSansNarrow.ttf"
local FONT_BOLD = "Interface\\AddOns\\CoARU\\Fonts\\PTSansNarrow-Bold.ttf"
function CoARU_SkinFont(fs, size, outline, bold)
    if not (fs and fs.SetFont) then return fs end

    local ok = fs:SetFont(bold and FONT_BOLD or FONT, size, outline)
    if ok == false then
        fs:SetFont("Fonts\\FRIZQT__.TTF", size, outline)
    end
    return fs
end

local w = CreateFrame("Frame")
w:RegisterEvent("PLAYER_LOGIN")
w:RegisterEvent("DISPLAY_SIZE_CHANGED")
w:RegisterEvent("UI_SCALE_CHANGED")
w:SetScript("OnEvent", recalcMult)
recalcMult()

local LAYER = {
    window  = { 0.055, 0.055, 0.070 },
    side    = { 0.085, 0.085, 0.100 },
    surface = { 0.105, 0.105, 0.122 },
    card    = { 0.135, 0.135, 0.155 },
}
CoARU_SKIN.layer = LAYER

local C6 = 0.75

function CoARU_SkinRounded(f, color, layer, inset, radius)
    layer = layer or "BACKGROUND"
    local R = radius or 6
    local i = inset or 0
    local px = {}
    local function tex(p1, p2, dx1, dy1, dx2, dy2)
        local t = f:CreateTexture(nil, layer)
        t:SetTexture(WHITE)
        t:SetPoint("TOPLEFT", f, p1, dx1, dy1)
        t:SetPoint("BOTTOMRIGHT", f, p2, dx2, dy2)
        px[#px + 1] = t
        return t
    end
    local IR = i + R
    tex("TOPLEFT", "BOTTOMRIGHT", IR, -IR, -IR, IR)
    tex("TOPLEFT", "TOPRIGHT", IR, -i, -IR, -IR)
    tex("BOTTOMLEFT", "BOTTOMRIGHT", IR, IR, -IR, i)
    tex("TOPLEFT", "BOTTOMLEFT", i, -IR, IR, IR)
    tex("TOPRIGHT", "BOTTOMRIGHT", -IR, -IR, -i, IR)
    local function cor(point, fh, fv, dx, dy)
        local t = f:CreateTexture(nil, layer)
        t:SetTexture(TEX .. "corner6.tga")
        t:SetWidth(R)
        t:SetHeight(R)
        t:SetPoint(point, f, point, dx, dy)
        local l, r = 0, C6
        local tp, b = 0, C6
        if fh then l, r = r, l end
        if fv then tp, b = b, tp end
        t:SetTexCoord(l, r, tp, b)
        px[#px + 1] = t
    end
    cor("TOPLEFT", false, false, i, -i)
    cor("TOPRIGHT", true, false, -i, -i)
    cor("BOTTOMLEFT", false, true, i, i)
    cor("BOTTOMRIGHT", true, true, -i, i)

    local function paint(c, a)
        for i = 1, #px do px[i]:SetVertexColor(c[1], c[2], c[3], a or 1) end
    end
    paint(color or LAYER.card)
    return paint
end

function CoARU_SkinSubHeader(parent, text, w)
    local h = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h:SetText(text)
    h:SetTextColor(ACCENT[1] * 0.95, ACCENT[2] * 0.9, ACCENT[3])
    CoARU_SkinFont(h, 10, nil, true)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture(TEX .. "divider.tga")
    line:SetHeight(CoARU_Px(1))
    line:SetPoint("LEFT", h, "RIGHT", 8, 0)
    line:SetVertexColor(ACCENT[1], ACCENT[2], ACCENT[3])
    line:SetAlpha(0.18)
    if w then line:SetWidth(w) end
    h.line = line
    return h
end

function CoARU_SkinRow2(parent, w, h, label, hint, name)
    local row = CreateFrame("Button", nil, parent)
    row:SetWidth(w)
    row:SetHeight(h or 44)

    local paintBg = CoARU_SkinRounded(row, LAYER.card)

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", row, "TOPLEFT", 16, -7)
    lbl:SetText(label)
    lbl:SetTextColor(0.95, 0.95, 0.98)
    CoARU_SkinFont(lbl, 14)

    local sub = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sub:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -3)
    sub:SetPoint("RIGHT", row, "RIGHT", -74, 0)
    sub:SetJustifyH("LEFT")
    sub:SetText(hint or "")
    sub:SetTextColor(0.58, 0.58, 0.64)
    CoARU_SkinFont(sub, 11)
    local recenter = centerRowText(row, h or 44, lbl, sub, 16, 3, 16, 13)
    row.Recenter = recenter

    local tg = CoARU_SkinToggle(row, "", name)
    tg:SetPoint("RIGHT", row, "RIGHT", -16, 0)
    tg:SetHitRectInsets(0, 0, 0, 0)

    row.toggle, row.labelFS, row.hintFS = tg, lbl, sub
    row.blocked = false

    local function repaint(hover)
        local c = LAYER.card
        if row.blocked then
            paintBg({ c[1] * 0.7, c[2] * 0.7, c[3] * 0.7 })
        elseif hover then
            paintBg({ c[1] + 0.06, c[2] + 0.06, c[3] + 0.07 })
        else
            paintBg(c)
        end
    end
    repaint(false)
    row:SetScript("OnEnter", function() repaint(true) end)
    row:SetScript("OnLeave", function() repaint(false) end)
    row:SetScript("OnClick", function()
        if tg.blocked then return end
        tg:SetChecked(not tg:GetChecked())
        if tg.OnRowClick then tg.OnRowClick(tg) end
    end)
    row.SetBlocked = function(self, why)
        self.blocked = (why ~= nil)
        tg:SetBlocked(why)
        lbl:SetTextColor(why and 0.45 or 0.95, why and 0.45 or 0.95, why and 0.5 or 0.98)
        sub:SetText(why or hint or "")
        sub:SetTextColor(why and 0.78 or 0.58, why and 0.54 or 0.58, why and 0.28 or 0.64)

        recenter()
        repaint(false)
    end
    return row
end

function CoARU_SkinStatCard(parent, w, h, caption, value, color, note)
    local c = CreateFrame("Frame", nil, parent)
    c:SetWidth(w)
    c:SetHeight(h)
    CoARU_SkinRounded(c, LAYER.card)

    local cap = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cap:SetPoint("TOPLEFT", c, "TOPLEFT", 14, -12)
    cap:SetText(caption)
    cap:SetTextColor(0.52, 0.52, 0.58)
    CoARU_SkinFont(cap, 10, nil, true)

    local val = c:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    val:SetPoint("TOPLEFT", cap, "BOTTOMLEFT", 0, -6)
    val:SetText(value)
    val:SetTextColor(color[1], color[2], color[3])
    CoARU_SkinFont(val, 17, nil, true)

    local nt
    if note then
        nt = c:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        nt:SetPoint("TOPLEFT", val, "BOTTOMLEFT", 0, -5)
        nt:SetPoint("RIGHT", c, "RIGHT", -14, 0)
        nt:SetJustifyH("LEFT")
        nt:SetText(note)
        nt:SetTextColor(0.5, 0.5, 0.56)
        CoARU_SkinFont(nt, 10)
    end
    centerStack(c, h, 14, {
        { fs = cap, fallback = 12 },
        { fs = val, gap = 6, fallback = 20 },
        { fs = nt, gap = 5, fallback = 12 },
    })
    c.valueFS, c.noteFS = val, nt
    return c
end

local askFrame
function CoARU_SkinAsk(opts)
    if not opts or not opts.text then return end
    if not askFrame then
        local f = CreateFrame("Frame", "CoARUAskFrame", UIParent)
        f:SetWidth(470)
        f:SetHeight(160)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetToplevel(true)
        f:EnableMouse(true)
        CoARU_SkinFrame9(f)

        local cap = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cap:SetPoint("TOP", f, "TOP", 0, -16)
        cap:SetText("CoARU")
        cap:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
        CoARU_SkinFont(cap, 11, nil, true)

        local body = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        body:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -40)
        body:SetPoint("TOPRIGHT", f, "TOPRIGHT", -24, -40)
        body:SetJustifyH("CENTER")
        body:SetTextColor(0.88, 0.88, 0.92)
        CoARU_SkinFont(body, 13)

        f.ok = CoARU_SkinButton(f, 150, 26, "", true)
        f.no = CoARU_SkinButton(f, 150, 26, "", false)
        f.capFS, f.bodyFS = cap, body
        f:Hide()
        askFrame = f
    end

    local f = askFrame
    f.bodyFS:SetText(opts.text)
    f.ok.label:SetText(opts.accept or "Да")
    f.no.label:SetText(opts.cancel or "Позже")

    if opts.cancel then f.no:Show() else f.no:Hide() end

    f.ok:SetScript("OnClick", function()
        f:Hide()
        if opts.OnAccept then opts.OnAccept() end
    end)
    f.no:SetScript("OnClick", function()
        f:Hide()
        if opts.OnCancel then opts.OnCancel() end
    end)

    f:Show()
    local th = f.bodyFS:GetStringHeight() or 0
    if th <= 0 then th = 48 end
    f:SetHeight(math.floor(40 + th + 20 + 26 + 20 + 0.5))

    local single = (opts.cancel == nil)
    f.ok:ClearAllPoints()
    f.no:ClearAllPoints()
    if single then
        f.ok:SetPoint("BOTTOM", f, "BOTTOM", 0, 20)
    else
        f.ok:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -8, 20)
        f.no:SetPoint("BOTTOMLEFT", f, "BOTTOM", 8, 20)
    end
    return f
end
