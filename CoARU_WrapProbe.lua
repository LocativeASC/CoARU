local PROBE_DEFAULT = "Показывать подсказки для всех элементов интерфейса, включая описания "
	.. "настроек, названия способностей и сведения о предметах, находящихся под курсором."

local WRAP_WIDTH = 260

local function probeText()

	return (CoARU_SYS_PROBE and CoARU_SYS_PROBE ~= "" and CoARU_SYS_PROBE) or PROBE_DEFAULT
end

function CoARU_Utf8Sub(s, chars)
	local bytes, len, pos = #s, 0, 1
	while pos <= bytes do
		local c = s:byte(pos)
		if c <= 127 then pos = pos + 1
		elseif c >= 240 then pos = pos + 4
		elseif c >= 224 then pos = pos + 3
		elseif c >= 192 then pos = pos + 2
		else pos = pos + 1 end
		len = len + 1
		if len >= chars then break end
	end
	return s:sub(1, pos - 1)
end

function CoARU_WrapText(text, width, fontString)
	if not fontString then return text end
	local out, line = {}, ""
	for word in text:gmatch("%S+") do
		local try = (line == "") and word or (line .. " " .. word)
		fontString:SetText(try)
		if fontString:GetStringWidth() > width and line ~= "" then
			out[#out + 1] = line
			line = word
		else
			line = try
		end
	end
	if line ~= "" then out[#out + 1] = line end
	return table.concat(out, "\n")
end

local measure

local function measureFS()
	if not measure then

		local f = CreateFrame("Frame", nil, UIParent)
		f:SetAlpha(0)
		f:SetSize(1, 1)
		f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -1000, 1000)
		measure = f:CreateFontString(nil, "ARTWORK", "GameTooltipText")
		measure:SetPoint("TOPLEFT")
	end
	return measure
end

local probeFrame, probeFS

local function probeStrip()
	if not probeFS then
		probeFrame = CreateFrame("Frame", nil, UIParent)
		probeFrame:SetFrameStrata("TOOLTIP")
		probeFrame:SetSize(WRAP_WIDTH, 400)
		probeFrame:SetPoint("CENTER")
		probeFS = probeFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
		probeFS:SetPoint("TOPLEFT")
		probeFS:SetWidth(WRAP_WIDTH)
		probeFS:SetJustifyH("LEFT")
		if probeFS.SetWordWrap then probeFS:SetWordWrap(true) end
	end
	return probeFS
end

function CoARU_WrapProbeStrip(show)
	local fs = probeStrip()
	if not show then
		probeFrame:Hide()
		return 0
	end
	fs:SetText(probeText())
	probeFrame:Show()

	return fs:GetHeight() or 0
end

function CoARU_WrapProbe(stage)
	local text = probeText()
	local tip = GameTooltip
	tip:SetOwner(UIParent, "ANCHOR_PRESERVE")
	tip:ClearLines()

	local allowWrap = (stage == 1)
	for i = 1, 5 do
		local fs = _G["GameTooltipTextLeft" .. i]
		if fs and fs.SetWordWrap then fs:SetWordWrap(allowWrap) end

		if fs then fs:SetWidth(allowWrap and WRAP_WIDTH or 0) end
	end

	if stage == 3 then

		text = CoARU_WrapText(text, WRAP_WIDTH, measureFS())
		tip:SetText(text, 1, 1, 1, 1, false)
	else

		tip:SetText(text, 1, 1, 1, 1, true)
	end

	tip:Show()

	local fs = _G["GameTooltipTextLeft1"]
	local mine = 1
	for _ in text:gmatch("\n") do mine = mine + 1 end
	return mine, (tip.NumLines and tip:NumLines()) or 0,
	       (fs and fs:GetStringWidth()) or 0
end

function CoARU_WrapProbeInfo()
	local fs = _G["GameTooltipTextLeft1"]

	local m = measureFS()
	m:SetText("Каждый раз, когда вы")
	return (fs and fs.SetWordWrap) and true or false, #probeText(), m:GetStringWidth()
end
