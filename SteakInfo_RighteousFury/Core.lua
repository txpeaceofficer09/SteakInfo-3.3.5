local units = {}

local function numUnits()
	local i = 0

	for _ in pairs(units) do
		i = i + 1
	end

	return i
end

local function OnEnter(self)
	if UnitAffectingCombat("player") then return end

	SteakInfoTooltip:SetOwner(self, "ANCHOR_NONE")
	SteakInfoTooltip:ClearAllPoints()
	SteakInfoTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)

	SteakInfoTooltip:AddLine("Righteous Fury:")
	SteakInfoTooltip:AddLine(" ")

	for name, status in pairs(units) do
		if status then
			SteakInfoTooltip:AddLine(name)
		end
	end

	SteakInfoTooltip:Show()
end

local function OnLeave(self)
	SteakInfoTooltip:Hide()
	SteakInfoTooltip:ClearLines()
end

local function UnitHasRF(unit)
	if not unit then return nil end
	if not UnitExists(unit) then return nil end
	if select(2, UnitClass(unit)) ~= "PALADIN" then return nil end

	local hasRF = false

	for i=1,40 do
		local name, _, _, _, _, _, _, _, _, _, spellID = UnitBuff(unit, i)
		if not name then break end

		if spellID == 25780 then
			hasRF = true
			break
		end
	end

	return hasRF and true or nil
end

local function ScanUnits(self)
	units[UnitName("player")] = UnitHasRF("player")

	for i=1,4 do
		local unit = ("party%d"):format(i)

		if unit and UnitName(unit) then
			units[UnitName(unit)] = UnitHasRF(unit)
		end
	end

	for i=1,40 do
		local unit = ("raid%d"):format(i)

		if unit and UnitName(unit) then
			units[UnitName(unit)] = UnitHasRF(unit)
		end
	end

	self:SetText(("Righteous Fury: %d"):format(numUnits()))
end

local events = {
	PLAYER_ENTERING_WORLD = ScanUnits,
	UNIT_AURA = ScanUnits
}

local scripts = {
	OnEnter = OnEnter,
	OnLeave = OnLeave
}

SteakInfo_AddModule(events, scripts, "RighteousFury")
