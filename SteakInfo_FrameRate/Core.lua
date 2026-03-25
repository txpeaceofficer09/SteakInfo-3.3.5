local function ColorFPS(fps)
	if fps <= 15 then
		return string.format("|cFFFF0000%.0f|r FPS", fps)
	elseif fps <= 30 then
		return string.format("|cFFFF8000%.0f|r FPS", fps)
	elseif fps <= 45 then
		return string.format("|cFFFFFF00%.0f|r FPS", fps)
	else
		return string.format("|cFF00FF00%.0f|r FPS", fps)
	end
end

local function OnUpdate(self, elapsed)
	self.timer = (self.timer or 0) + elapsed
	if self.timer < 1 then return end
	self.timer = 0

	self:SetText(ColorFPS(GetFramerate()))
end

local function OnPlayerEnteringWorld(self)
	self:SetText(ColorFPS(GetFramerate()))
end

local events = {
	PLAYER_ENTERING_WORLD = OnPlayerEnteringWorld
}

local scripts = {
	OnUpdate = OnUpdate
}

SteakInfo_AddModule(events, scripts, "FPS")
