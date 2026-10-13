local function OnUpdate(self, elapsed)
	self.timer = (self.timer or 0) + elapsed
	if self.timer < 0.1 then return end
	self.timer = 0

	local speed = GetUnitSpeed(self.currentUnit or "player")

	if speed and speed >= 0 then
		if not (IsSwimming() or IsFlying()) then
			currentSpeed = ("%.0f%%"):format(speed/7 * 100)
		else
			currentSpeed = ("%.0f%%"):format((speed/7 * 100) * math.cos(GetUnitPitch(self.currentUnit or "player")))
		end
	end

	self:SetText(("Speed: %s"):format(currentSpeed))
end

local function OnUnitEnteredVehicle(self, unit)
	if unit == "player" then self.currentUnit = "vehicle" end
end

local function OnUnitExitedVehicle(self, unit)
	if unit == "player" then self.currentUnit = "player" end
end

local events = {
	UNIT_ENTERED_VEHICLE = OnUnitEnteredVehicle,
	UNIT_EXITED_VEHICLE = OnUnitExitedVehicle
}

local scripts = {
	OnUpdate = OnUpdate
}

SteakInfo_AddModule(events, scripts, "Speed")
