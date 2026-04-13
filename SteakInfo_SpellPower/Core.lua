local function OnEnter(self)
	if UnitAffectingCombat("player") then return end

	SteakInfoTooltip:SetOwner(self, "ANCHOR_NONE")
	SteakInfoTooltip:ClearAllPoints()
	SteakInfoTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)

	SteakInfoTooltip:AddLine("Spell Stats:")
	SteakInfoTooltip:AddLine(" ")

	local sp = SteakInfoDB.SpellPower[UnitName("player")].maxSP or 0
	local crit = SteakInfoDB.SpellPower[UnitName("player")].maxCrit or 0
	local haste = SteakInfoDB.SpellPower[UnitName("player")].maxHaste or 0

	SteakInfoTooltip:AddDoubleLine("Highest Spell Power", sp)
	SteakInfoTooltip:AddDoubleLine("Highest Crit Chance", ("%.2f%%"):format(crit))
	SteakInfoTooltip:AddDoubleLine("Highest Haste", ("%.2f%%"):format(haste))

	SteakInfoTooltip:Show()
end

local function OnLeave(self)
	SteakInfoTooltip:Hide()
	SteakInfoTooltip:ClearLines()
end

local function GetStats()
	local sp, crit, haste = 0, 0, 0

	for school=2,7 do
		sp = GetSpellBonusDamage(school) or 0
		crit = GetSpellCritChance(school) or 0
	end

	haste = GetCombatRating(CR_HASTE_SPELL) / 32.79 or 0

	return sp, crit, haste
end

local function UpdateSpell(self)
	local sp, crit, haste = GetStats()

	SteakInfoDB.SpellPower[UnitName("player")].maxSP = math.max(sp, SteakInfoDB.SpellPower[UnitName("player")].maxSP or 0)
	SteakInfoDB.SpellPower[UnitName("player")].maxCrit = math.max(crit, SteakInfoDB.SpellPower[UnitName("player")].maxCrit or 0)
	SteakInfoDB.SpellPower[UnitName("player")].maxHaste = math.max(haste, SteakInfoDB.SpellPower[UnitName("player")].maxHaste or 0)

	self:SetText(("SP: %d  Crit: %.2f%%  Haste: %.2f%%"):format(sp, crit, haste))
end

local function OnVariablesLoaded(self)
	SteakInfoDB.SpellPower = SteakInfoDB.SpellPower or {}
	SteakInfoDB.SpellPower[UnitName("player")] = SteakInfoDB.SpellPower[UnitName("player")] or { maxSP = 0, maxCrit = 0 , maxHaste = 0 }
end

local events = {
    PLAYER_ENTERING_WORLD = UpdateSpell,
    UNIT_STATS = UpdateSpell,
    UNIT_AURA = UpdateSpell,
    PLAYER_EQUIPMENT_CHANGED = UpdateSpell,
    PLAYER_DAMAGE_DONE_MODS = UpdateSpell,
    VARIABLES_LOADED = OnVariablesLoaded,
}

local scripts = {
    OnEnter = OnEnter,
    OnLeave = OnLeave
}

SteakInfo_AddModule(events, scripts, "SpellPower")
