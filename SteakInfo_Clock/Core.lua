local function OnEnter(self)
	if UnitAffectingCombat("player") then return end

	SteakInfoTooltip:SetOwner(self, "ANCHOR_NONE")
	SteakInfoTooltip:ClearAllPoints()
	SteakInfoTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)

	local hour, minute = GetGameTime()

	SteakInfoTooltip:AddLine("Server Time")
	SteakInfoTooltip:AddLine(("%02d:%02d"):format(hour, minute))

	SteakInfoTooltip:Show()
end

local function OnLeave(self)
	SteakInfoTooltip:Hide()
	SteakInfoTooltip:ClearLines()
end

local function OnPlayerEnteringWorld(self)
	TimeManagerClockButton:HookScript("OnShow", function(self) self:Hide() end)
	TimeManagerClockButton:Hide()
end

local function OnUpdate(self, elapsed)
	self.timer = ( self.timer or 0 ) + elapsed
	if self.timer < 1 then return end
	self.timer = 0

	local timestamp = date("*t", time())

	self:SetText(("[%02d:%02d:%02d]"):format(timestamp.hour, timestamp.min, timestamp.sec))
end

local events = {
	PLAYER_ENTERING_WORLD = OnPlayerEnteringWorld
}

local scripts = {
	OnEnter = OnEnter,
	OnLeave = OnLeave,
	OnUpdate = OnUpdate
}

SteakInfo_AddModule(events, scripts, "Clock")
