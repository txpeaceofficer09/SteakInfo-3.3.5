local function ColorForLatency(ms)
	if ms <= 200 then
		return 0, 255, 0       -- green
	elseif ms <= 300 then
		return 255, 255, 0     -- yellow
	elseif ms <= 400 then
		return 255, 128, 0     -- orange
	else
		return 255, 0, 0       -- red
	end
end

local function OnUpdate(self, elapsed)
	self.timer = (self.timer or 0) + elapsed
	if self.timer < 1 then return end
	self.timer = 0

	local _, _, home = GetNetStats()
	local r, g, b = ColorForLatency(home)

	self:SetText(("|cff%02x%02x%02x%d|r MS"):format(r, g, b, home))
end

local function OnPlayerEnteringWorld(self)
	local _, _, home = GetNetStats()
	local r, g, b = ColorForLatency(home)

	self:SetText(("|cff%02x%02x%02x%d|r MS"):format(r, g, b, home))
end

local events = {
	PLAYER_ENTERING_WORLD = OnPlayerEnteringWorld
}

local scripts = {
	OnUpdate = OnUpdate
}

SteakInfo_AddModule(events, scripts, "Latency")
