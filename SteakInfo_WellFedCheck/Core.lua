local wellFedIDs = {
	[57399] = "Fish Feast",
	[34753] = "Great Feast",
}

local function SendList(prefix, list, chatType)
	local max = 245 
	local msg = prefix
	local first = true

	for index, name in ipairs(list) do
		local add = first and name or (", "..name)
		first = false

		if #msg + #add >= max then
			SendChatMessage(msg, chatType)
			msg = prefix..name
		else
			msg = msg..add

			if index == #list then
				SendChatMessage(msg, chatType)
			end
		end
	end
end

local function GetUnitWellFed(unit)
	for i = 1, 40 do
		local name, _, _, _, _, duration, expirationTime, _, _, _, spellID = UnitAura(unit, i)

		if not name then break end

		--if wellFedIDs[spellID] then
		if name == "Well Fed" then
			local remaining = expirationTime - GetTime()

			if remaining < 0 then remaining = 0 end

			return wellFedIDs[spellID] or "Well Fed ("..spellID..")", remaining
		end
	end

	return nil, 0
end

local function FormatTime(sec)
	if sec <= 0 then return "0m" end

	return math.floor(sec / 60) .. "m"
end

local function BuildWellFedList()
	local list = {}
	local groupType = GetNumRaidMembers() > 0 and "raid" or "party"
	local numGroupMembers = groupType == "raid" and GetNumRaidMembers() or GetNumPartyMembers()

	for i=1,numGroupMembers do
		local unit = groupType..i
		local _, class = UnitClass(unit)

		if UnitExists(unit) then
			local name = UnitName(unit)
			local WellFed, remaining = GetUnitWellFed(unit)

			if WellFed then
				table.insert(list, {
					name = name,
					class = class,
					WellFed = WellFed,
					remaining = FormatTime(remaining)
				})
			else
				table.insert(list, {
					name = name,
					class = class,
					WellFed = "NONE",
					remaining = "0m"
				})
			end
		end
	end

	if groupType == "party" then
		local name = UnitName("player")
		local _, class = UnitClass("player")
		local WellFed, remaining = GetUnitWellFed("player")

		if WellFed then
			table.insert(list, {
				name = name,
				class = class,
				WellFed = WellFed,
				remaining = FormatTime(remaining)
			})
		else
			table.insert(list, {
				name = name,
				class = class,
				WellFed = "NONE",
				remaining = "0m"
			})
		end
	end

	return list
end

local function OnClick(self, button)
	local list = BuildWellFedList()
	local chatType = GetNumRaidMembers() > 0 and "RAID" or GetNumPartyMembers() > 0 and "PARTY" or "YELL"

	SendChatMessage("Well Feds:", chatType)

	for _, data in ipairs(list) do
		local message = ("%s %s (%s)"):format(data.name, data.WellFed or "NONE", data.remaining)
		SendChatMessage(message, chatType)
	end
end

local function OnEnter(self)
	if UnitAffectingCombat("player") then return end

	SteakInfoTooltip:SetOwner(self, "ANCHOR_NONE")
	SteakInfoTooltip:ClearAllPoints()
	SteakInfoTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
	SteakInfoTooltip:ClearLines()

	SteakInfoTooltip:AddLine("WellFed Check")
	SteakInfoTooltip:AddLine(" ")

	local list = BuildWellFedList()

	for _, member in ipairs(list) do
		SteakInfoTooltip:AddDoubleLine(("|cff%02x%02x%02x%s|r"):format(RAID_CLASS_COLORS[member.class].r*255, RAID_CLASS_COLORS[member.class].g*255, RAID_CLASS_COLORS[member.class].b*255, member.name), ("%s (%s)"):format(member.WellFed, member.remaining))
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
			local WellFed = GetUnitWellFed(unit)

			if not WellFed then missing = missing + 1 end
		end
	end

	if groupType == "party"then
		if not GetUnitWellFed("player") then missing = missing + 1 end

		numGroupMembers = numGroupMembers + 1
	end

	self:SetText(("WellFeds: %d / %d"):format((numGroupMembers - missing), numGroupMembers))
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
	end,
	READY_CHECK = function(self, sender, id)
		local groupType = GetNumRaidMembers() > 0 and "raid" or "party"
		local numGroupMembers = gropType == "raid" and GetNumRaidMembers() or GetNumPartyMembers()
		local chatType = GetNumRaidMembers() > 0 and "RAID" or GetNumPartyMembers() > 0 and "PARTY" or "YELL"

		local missing = {}

		for i=1,numGroupMembers do
			local unit = groupType..i
			local unitName = UnitName(unit)

			if UnitExists(unit) and not GetUnitWellFed(unit) then table.insert(missing, unitName) end
		end

		if groupType == "party" then
			local unitName = UnitName("player")
			if not GetUnitWellFed("player") then table.insert(missing, unitName) end
		end

		if #missing == 0 then
			SendChatMessage("All group members are Well Fed.", chatType)
		else
			--SendChatMessage(("Missing Well Fed: %s"):format(table.concat(missing, ", ")))
			SendList("Missing Well Fed: ", missing, chatType)
		end
	end
}

local scripts = {
	OnEnter = OnEnter,
	OnLeave = OnLeave,
	OnUpdate = OnUpdate,
	OnClick = OnClick
}

SteakInfo_AddModule(events, scripts, "WellFedCheck")
