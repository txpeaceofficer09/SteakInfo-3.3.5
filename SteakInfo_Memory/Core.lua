local function FormatMemory(kb)
	if kb >= 1024 then
		return string.format("%.2f MB", kb / 1024)
	else
		return string.format("%.2f KB", kb)
	end
end

local function BuildTooltip(self)
	if UnitAffectingCombat("player") then return end

	SteakInfoTooltip:ClearLines()
	SteakInfoTooltip:SetOwner(self, "ANCHOR_TOPLEFT")

	SteakInfoTooltip:AddLine("AddOn Memory Usage:")
	SteakInfoTooltip:AddLine(" ")

	UpdateAddOnMemoryUsage()

	local list = {}

	for i = 1, GetNumAddOns() do
		local name, title, notes, enabled = GetAddOnInfo(i)

		if enabled then
			local mem = GetAddOnMemoryUsage(i)

			if mem and mem > 0 then
				table.insert(list, { title = title or name, memory = mem })
			end
		end
	end

	table.sort(list, function(a, b) return a.memory > b.memory end)

	for i, v in ipairs(list) do
		SteakInfoTooltip:AddDoubleLine(("%d. %s"):format(i, v.title), FormatMemory(v.memory))
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

	UpdateAddOnMemoryUsage()

	local total = 0

	for i = 1, GetNumAddOns() do
		total = total + GetAddOnMemoryUsage(i)
	end

	self:SetText("Memory: " .. FormatMemory(total))
end

local function OnPlayerEnteringWorld(self)
	UpdateAddOnMemoryUsage()

	local total = 0

	for i = 1, GetNumAddOns() do
		total = total + GetAddOnMemoryUsage(i)
	end

	self:SetText("Memory: " .. FormatMemory(total))
end

local events = {
	PLAYER_ENTERING_WORLD = OnPlayerEnteringWorld
}

local scripts = {
	OnEnter  = BuildTooltip,
	OnLeave  = OnLeave,
	OnUpdate = OnUpdate
}

SteakInfo_AddModule(events, scripts, "Memory")
