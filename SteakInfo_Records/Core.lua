local playerName = UnitName("player")
local _, playerClass = UnitClass("player")
local classColor = RAID_CLASS_COLORS[playerClass] or { r = 1, g = 1, b = 1 }

SteakInfoDB = SteakInfoDB or {}
SteakInfoDB.Records = SteakInfoDB.Records or {}
SteakInfoDB.Records[playerName] = SteakInfoDB.Records[playerName] or {}

local DB = SteakInfoDB.Records[playerName]
local mode = "damage" -- "damage", "healing", "absorbs"

local SCHOOL_COLORS = {
	[1] = { r = 0.80, g = 0.80, b = 0.80 }, -- Physical
	[2] = { r = 1.00, g = 0.90, b = 0.50 }, -- Holy
	[4] = { r = 1.00, g = 0.50, b = 0.00 }, -- Fire
	[8] = { r = 0.30, g = 1.00, b = 0.30 }, -- Nature
	[16] = { r = 0.50, g = 1.00, b = 1.00 }, -- Frost
	[32] = { r = 0.70, g = 0.30, b = 0.90 }, -- Shadow
	[64] = { r = 0.60, g = 0.80, b = 1.00 }, -- Arcane
}

local function GetSchoolColor(school)
	return SCHOOL_COLORS[school] or { r = 0.8, g = 0.8, b = 0.8 }
end

local function EnsureSpellRecord(event, spellID, spellName, spellSchool)
	--local key = ("%d:%s"):format(spellID, event)
	local key = event:match("_PERIODIC_DAMAGE$") and spellName.." (DoT)" or event:match("_PERIODIC_HEAL$") and spellName.." (HoT)" or spellName
	local record = DB[key]

	if not record then
		record = {
			--spellID = spellID,
			name = spellName or ("Spell "..spellID),
			school = spellSchool or 1,
			damage = { normal = 0, crit = 0 },
			healing = { normal = 0, crit = 0 },
			absorbs = { normal = 0, crit = 0 },
		}
		DB[key] = record
	end

	return record
end

local function UpdateRecord(event, spellID, spellName, spellSchool, kind, amount, critical)
	if not spellID or not amount or amount <= 0 then return end
	if not IsSpellKnown(spellID) then return end

	local record = EnsureSpellRecord(event, spellID, spellName, spellSchool)
	local data = record[kind]

	if not data then return end

	if critical then
		data.crit = math.max(amount, data.crit)
	else
		data.normal = math.max(amount, data.normal)
	end
end

local function OnCombatEvent(self, event, ...)
	local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...

	if sourceGUID ~= UnitGUID("player") then return end

	if event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" then
		local _, _, _, _, _, _, _, _, spellID, spellName, spellSchool, amount, _, _, _, _, _, critical = ...

		if event:match("periodic") then spellName = spellName.." (DoT)" end

		UpdateRecord(event, spellID, spellName, spellSchool, "damage", amount, critical)
	elseif event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
		local _, _, _, _, _, _, _, _, spellID, spellName, spellSchool, amount, _, _, critical = ...

		if event:match("periodic") then spellName = spellName.." (HoT)" end

		UpdateRecord(event, spellID, spellName, spellSchool, "healing", amount, critical)
	elseif event == "SPELL_ABSORBED" then
		local _, _, _, _, _, _, _, _, spellID, spellName, spellSchool, amount = ...

		if type(spellID) == "number" and type(amount) == "number" then
			UpdateRecord(event, spellID, spellName, spellSchool, "absorbs", amount, false)
		end
	end
end

local fontPath = "Interface\\AddOns\\SteakInfo\\Audiowide-Regular.ttf"

local recordsFrame = CreateFrame("Frame", "SteakInfoRecordsFrame", UIParent)
recordsFrame:SetClampedToScreen(true)
recordsFrame:SetBackdrop( { bgFile = SteakInfoFrame.bgFile, edgeFile = SteakInfoFrame.edgeFile, edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 } } )
recordsFrame:SetBackdropColor(0, 0, 0, 0.9)
recordsFrame:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 1)
recordsFrame:SetFrameStrata("TOOLTIP")
recordsFrame:Hide()

local bars = {}
local header

local function BuildAbilityList()
	local list = {}

	for spellID, record in pairs(DB) do
		local data = record[mode]

		if data and (data.normal > 0 or data.crit > 0) then
			list[#list+1] = {
				spellID = spellID,
				name = record.name,
				school = record.school,
				normal = data.normal,
				crit = data.crit,
			}
		end
	end

	table.sort(list, function(a, b)
		if a.crit ~= b.crit then
			return a.crit > b.crit
		end

		return a.normal > b.normal
	end)

	return list
end

local function ShowRecords(anchorFrame)
	local abilities = BuildAbilityList()

	if #abilities == 0 then
		recordsFrame:Hide()
		return
	end

	local temp = UIParent:CreateFontString(nil, "OVERLAY")
	temp:SetFont(fontPath, 8, "OUTLINE")

	local maxName, maxNormal, maxCrit = 0, 0, 0
	local PAD = 10

	for _, a in ipairs(abilities) do
		temp:SetText(a.name or "")
		maxName = math.max(maxName, temp:GetStringWidth())

		temp:SetText(a.normal > 0 and tostring(a.normal) or "-")
		maxNormal = math.max(maxNormal, temp:GetStringWidth())

		temp:SetText(a.crit > 0 and tostring(a.crit) or "-")
		maxCrit = math.max(maxCrit, temp:GetStringWidth())
	end

	temp:SetText("Ability")
	maxName = math.max(maxName, temp:GetStringWidth()) + PAD

	temp:SetText("Normal")
	maxNormal = math.max(maxNormal, temp:GetStringWidth()) + PAD

	temp:SetText("Critical")
	maxCrit = math.max(maxCrit, temp:GetStringWidth()) + PAD

	for _, bar in ipairs(bars) do bar:Hide() end

	if not header then
		header = CreateFrame("Frame", nil, recordsFrame)
		header:SetHeight(16)
		header:SetPoint("TOPLEFT", recordsFrame, "TOPLEFT", 2, -2)
		header:SetPoint("TOPRIGHT", recordsFrame, "TOPRIGHT", -2, -2)

		header.name = header:CreateFontString(nil, "OVERLAY")
		header.name:SetFont(fontPath, 8, "OUTLINE")
		header.name:SetText("Ability")
		header.name:SetJustifyH("LEFT")
		header.name:SetWidth(maxName)
		header.name:SetPoint("LEFT", header, "LEFT", 0, 0)

		header.normal = header:CreateFontString(nil, "OVERLAY")
		header.normal:SetFont(fontPath, 8, "OUTLINE")
		header.normal:SetText("Normal")
		header.normal:SetJustifyH("RIGHT")
		header.normal:SetWidth(maxName)
		header.normal:SetPoint("LEFT", header.name, "RIGHT", 0, 0)

		header.crit = header:CreateFontString(nil, "OVERLAY")
		header.crit:SetFont(fontPath, 8, "OUTLINE")
		header.crit:SetText("Critical")
		header.crit:SetJustifyH("RIGHT")
		header.crit:SetWidth(maxCrit)
		header.crit:SetPoint("LEFT", header.normal, "RIGHT", 0, 0)
	else
		header.name:SetWidth(maxName)
		header.normal:SetWidth(maxNormal)
		header.crit:SetWidth(maxCrit)
		header:Show()
	end

	local maxValue = 0

	for _, a in ipairs(abilities) do
		local v = math.max(a.normal or 0, a.crit or 0)

		if v > maxValue then maxValue = v end
	end
	if maxValue <= 0 then maxValue = 1 end

	local rowIndex = 1

	for _, a in ipairs(abilities) do
		local bar = bars[rowIndex]

		if not bar then
			bar = CreateFrame("StatusBar", nil, recordsFrame)
			bar:SetMinMaxValues(0, 1)
			bar:SetHeight(16)
			bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
			bars[rowIndex] = bar

			bar.nameText = bar:CreateFontString(nil, "OVERLAY")
			bar.nameText:SetFont(fontPath, 8, "OUTLINE")
			bar.nameText:SetJustifyH("LEFT")

			bar.normalText = bar:CreateFontString(nil, "OVERLAY")
			bar.normalText:SetFont(fontPath, 8, "OUTLINE")
			bar.normalText:SetJustifyH("RIGHT")

			bar.critText = bar:CreateFontString(nil, "OVERLAY")
			bar.critText:SetFont(fontPath, 8, "OUTLINE")
			bar.critText:SetJustifyH("RIGHT")
		end

		bar:ClearAllPoints()

		if rowIndex == 1 then
			bar:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -1)
			bar:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -1)
		else
			bar:SetPoint("TOPLEFT", bars[rowIndex - 1], "BOTTOMLEFT", 0, -1)
			bar:SetPoint("TOPRIGHT", bars[rowIndex - 1], "BOTTOMRIGHT", 0, -1)
		end

		local schoolColor = GetSchoolColor(a.school)
		bar:SetStatusBarColor(schoolColor.r, schoolColor.g, schoolColor.b, 0.8)

		local value = math.max(a.normal or 0, a.crit or 0)
		bar:SetMinMaxValues(0, maxValue)
		bar:SetValue(value)

		bar.nameText:SetPoint("LEFT", bar, "LEFT", 0, 0)
		bar.nameText:SetWidth(maxName)
		bar.nameText:SetText(a.name or ("Spell "..a.spellID))

		bar.normalText:SetPoint("LEFT", bar.nameText, "RIGHT", 0, 0)
		bar.normalText:SetWidth(maxNormal)
		bar.normalText:SetText(a.normal > 0 and tostring(a.normal) or "-")

		bar.critText:SetPoint("LEFT", bar.normalText, "RIGHT", 0, 0)
		bar.critText:SetWidth(maxCrit)
		bar.critText:SetText(a.crit > 0 and tostring(a.crit) or "-")

		bar:Show()
		rowIndex = rowIndex + 1
	end

	local totalRows = rowIndex - 1
	local totalWidth = maxName + maxNormal + maxCrit + 4
	local totalHeight = 16 + 2 + totalRows * 17 + 4

	recordsFrame:SetSize(totalWidth, totalHeight)
	recordsFrame:ClearAllPoints()
	recordsFrame:SetPoint("BOTTOM", anchorFrame, "TOP", 0, 4)
	recordsFrame:Show()
end

local function GetTopAbilityForMode()
	local abilities = BuildAbilityList()
	return abilities[1]
end

local function UpdateModuleText(self)
	local top = GetTopAbilityForMode()
	local label = (mode == "damage" and "Damage") or (mode == "healing" and "Healing") or "Absorbs"

	if top then
		local best = math.max(top.normal or 0, top.crit or 0)

		self:SetText(string.format("%s: %s (%s)", label, top.name, best))
	else
		self:SetText(label..": -")
	end
end

local function OnEnter(self)
	if UnitAffectingCombat("player") then return end
	ShowRecords(self)
end

local function OnLeave(self)
	recordsFrame:Hide()
end

local function OnClick(self, button)
	if button == "LeftButton" then
		if mode == "damage" then
			mode = "healing"
		elseif mode == "healing" then
			mode = "absorbs"
		else
			mode = "damage"
		end

		UpdateModuleText(self)

		if recordsFrame:IsShown() then
			ShowRecords(self)
		end
	end
end

local events = {
	COMBAT_LOG_EVENT_UNFILTERED = OnCombatEvent,
	PLAYER_ENTERING_WORLD = UpdateModuleText
}

local scripts = {
	OnEnter = OnEnter,
	OnLeave = OnLeave,
	OnClick = OnClick
}

SteakInfo_AddModule(events, scripts, "Records")

