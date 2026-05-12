local dropdown = CreateFrame("Frame", "SteakInfoRDFDropdown", UIParent, "UIDropDownMenuTemplate")

local function ShowMenu(self)
	local inQueue = GetLFGQueueStats()
	local inDungeon = IsInLFGDungeon()
	local mode = GetLFGMode()

	local menu = {}

	if inQueue then
		table.insert(menu, {
			text = "Leave Queue",
			func = function()
				LeaveLFG()
			end,
		})
	end

	if mode and mode == "lfgparty" then
		if inDungeon then
			table.insert(menu, {
				text = "Teleport Out",
				func = function()
					LFGTeleport(true)
				end,
			})
		else
			table.insert(menu, {
				text = "Teleport In",
				func = function()
					LFGTeleport()
				end,
			})
		end
	end

	EasyMenu(menu, dropdown, "cursor", 0, 0, "MENU", 2)
end

local function OnMouseUp(self, button)
	if button == "RightButton" then
		ShowMenu(self)
	else
		if PVEFrame:IsShown() then
			HideUIPanel(PVEFrame)
		else
			ShowUIPanel(PVEFrame)
		end
	end
end

local function OnEnter(self)
	if UnitAffectingCombat("player") then return end

	SteakInfoTooltip:SetOwner(self, "ANCHOR_NONE")
	SteakInfoTooltip:ClearAllPoints()
	SteakInfoTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)

	local inQueue, needLead, needTank, needHeal, needDPS, dungeonID, dungeonName = GetLFGQueueStats()
	local inDungeon = IsInLFGDungeon()

	if inDungeon then
		SteakInfoTooltip:AddLine("In Dungeon")
		SteakInfoTooltip:AddLine(GetRealZoneText())
	elseif inQueue then
		--local name = dungeonID and GetLFGDungeonInfo(dungeonID) or "Queued"
		local name = dungeonName or "Queued"

		--SteakInfoTooltip:AddLine("Queued For:")
		--SteakInfoTooltip:AddLine(name)
		--SteakInfoTooltip:AddLine(" ")
		SteakInfoTooltip:AddLine("Random Dungeon Finder")
		SteakInfoTooltip:AddDoubleLine("Tank", ("%d / 1"):format(1-needTank))
		SteakInfoTooltip:AddDoubleLine("Healer", ("%d / 1"):format(1-needHeal))
		SteakInfoTooltip:AddDoubleLine("DPS", ("%d / 3"):format(3-needDPS))
	else
		SteakInfoTooltip:AddLine("Not in RDF")
	end

	SteakInfoTooltip:Show()
end

local function OnLeave(self)
	SteakInfoTooltip:Hide()
	SteakInfoTooltip:ClearLines()
end

--local queueStart = nil
--local lastDungeonID = nil

local function FormatTime(sec)
	if not sec or sec <= 0 then return "0:00" end

	local m = floor(sec / 60)
	local s = sec % 60

	return string.format("%d:%02d", m, s)
end

local function OnUpdate(self, elapsed)
	self.timer = (self.timer or 0) + elapsed
	if self.timer < 1 then return end
	self.timer = 0

	local inQueue, needLead, needTank, needHeal, needDPS, dungeonID, dungeonName, _, _, _, _, _, queueStart = GetLFGQueueStats()
	local inDungeon = IsInLFGDungeon()

	if inDungeon then
		--self:SetText("RDF: " .. GetRealZoneText())
		self:SetText("RDF: -")
		return
	end

	if inQueue then
		--if not queueStart then queueStart = time() end

		--lastDungeonID = dungeonName or lastDungeonID

		--local name = lastDungeonID or "Queued"
		--local name = dungeonName or "Queued"
		local elapsed = FormatTime(GetTime() - queueStart)

		--self:SetText(("RDF: |cffaaccff%d|r |cff00ff00%d|r |cffffff00%d|r - %s - %s"):format(1-needTank, 1-needHeal, 3-needDPS, name, elapsed))
		self:SetText(("RDF: |cff8080ff%d|r |cff00ff00%d|r |cffffff00%d|r - %s"):format(1-needTank, 1-needHeal, 3-needDPS, elapsed))

		return
	end

	--queueStart = nil
	--lastDungeonID = nil

	self:SetText("RDF: -")
end

local events = {
	PLAYER_ENTERING_WORLD = function(self) end,
	LFG_UPDATE = function(self) end,
	LFG_QUEUE_STATUS_UPDATE = function(self) end,
	LFG_ROLE_UPDATE = function(self) end,
	LFG_PROPOSAL_SHOW = function(self) end,
	LFG_PROPOSAL_FAILED = function(self) end,
	LFG_PROPOSAL_SUCCEEDED = function(self) end,
	LFG_COMPLETION_REWARD = function(self) end,
}

local scripts = {
	OnEnter = OnEnter,
	OnLeave = OnLeave,
	OnMouseUp = OnMouseUp,
	OnUpdate = OnUpdate
}

SteakInfo_AddModule(events, scripts, "RDF")
