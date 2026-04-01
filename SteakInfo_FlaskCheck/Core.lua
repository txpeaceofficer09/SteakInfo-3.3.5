local flaskIDs = {
	[53755] = "Frost Wyrm",
	[53758] = "Stoneblood",
	[53760] = "Endless Rage",
	[53752] = "Pure Mojo"
}

local function GetUnitFlask(unit)
	for i = 1, 40 do
		local name, _, _, _, _, duration, expirationTime, _, _, _, spellID = UnitAura(unit, i)

		if not name then break end

		if flaskIDs[spellID] then
			local remaining = expirationTime - GetTime()

			if remaining < 0 then remaining = 0 end

			return flaskIDs[spellID], remaining
		end
	end

	return nil, 0
end

local function FormatTime(sec)
	if sec <= 0 then return "0m" end

	return math.floor(sec / 60) .. "m"
end

local function BuildFlaskList()
	local list = {}
	local groupType = GetNumRaidMembers() > 0 and "raid" or "party"
	local numGroupMembers = groupType == "raid" and GetNumRaidMembers() or GetNumPartyMembers()

	for i=1,numGroupMembers do
		local unit = groupType..i
		local _, class = UnitClass(unit)

		if UnitExists(unit) then
			local name = UnitName(unit)
			local flask, remaining = GetUnitFlask(unit)

			if flask then
				table.insert(list, {
					name = name,
					class = class,
					flask = flask,
					remaining = FormatTime(remaining)
				})
			else
				table.insert(list, {
					name = name,
					class = class,
					flask = "NONE",
					remaining = "0m"
				})
			end
		end
	end

	if groupType == "party" then
		local name = UnitName("player")
		local _, class = UnitClass("player")
		local flask, remaining = GetUnitFlask("player")

		if flask then
			table.insert(list, {
				name = name,
				class = class,
				flask = flask,
				remaining = FormatTime(remaining)
			})
		else
			table.insert(list, {
				name = name,
				class = class,
				flask = "NONE",
				remaining = "0m"
			})
		end
	end

	return list
end

local function OnEnter(self)
	if UnitAffectingCombat("player") then return end

	SteakInfoTooltip:SetOwner(self, "ANCHOR_NONE")
	SteakInfoTooltip:ClearAllPoints()
	SteakInfoTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
	SteakInfoTooltip:ClearLines()

	SteakInfoTooltip:AddLine("Flask Check")
	SteakInfoTooltip:AddLine(" ")

	local list = BuildFlaskList()

	for _, member in ipairs(list) do
		SteakInfoTooltip:AddDoubleLine(("|cff%02x%02x%02x%s|r"):format(RAID_CLASS_COLORS[member.class].r*255, RAID_CLASS_COLORS[member.class].g*255, RAID_CLASS_COLORS[member.class].b*255, member.name), ("%s (%s)"):format(member.flask, member.remaining))
	end

	SteakInfoTooltip:Show()
end

local function OnLeave(self)
	SteakInfoTooltip:Hide()
	SteakInfoTooltip:ClearLines()
end

local function OnUpdate(self, elapsed)
	self.timer = (self.timer or 0) + elapsed
	if self.timer < 5 then return end
	self.timer = 0

	local missing = 0

	local groupType = GetNumRaidMembers() > 0 and "raid" or "party"
	local numGroupMembers = groupType == "raid" and GetNumRaidMembers() or GetNumPartyMembers()

	for i=1,numGroupMembers do
		local unit = groupType..i

		if UnitExists(unit) then
			local flask = GetUnitFlask(unit)

			if not flask then missing = missing + 1 end
		end
	end

	if groupType == "party"then
		if not GetUnitFlask("player") then missing = missing + 1 end

		numGroupMembers = numGroupMembers + 1
	end

	self:SetText(("Flasks: %d / %d"):format((numGroupMembers - missing), numGroupMembers))
end

local events = {
	PLAYER_ENTERING_WORLD = function(self)
		self.timer = 5
	end,
	RAID_ROSTER_UPDATE = function(self)
		self.timer = 5
	end,
	PARTY_MEMBERS_CHANGED = function(self)
		self.timer = 5
	end,
	UNIT_AURA = function(self, unit)
		if unit and (UnitInRaid(unit) or UnitInParty(unit) or unit == "player") then
			self.timer = 5
		end
	end
}

local scripts = {
	OnEnter = OnEnter,
	OnLeave = OnLeave,
	OnUpdate = OnUpdate
}

SteakInfo_AddModule(events, scripts, "Flask Check")
