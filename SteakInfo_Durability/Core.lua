local slots = {
	[1]  = "Head",
	[2]  = "Neck",
	[3]  = "Shoulder",
	[5]  = "Chest",
	[6]  = "Waist",
	[7]  = "Legs",
	[8]  = "Feet",
	[9]  = "Wrist",
	[10] = "Hands",
	[16] = "Main Hand",
	[17] = "Off Hand",
	[18] = "Ranged",
}

local function GetDurabilityData()
	local totalCur, totalMax = 0, 0
	local perSlot = {}

	for slotID, slotName in pairs(slots) do
		local cur, max = GetInventoryItemDurability(slotID)

		if cur and max then
			totalCur = totalCur + cur
			totalMax = totalMax + max

			perSlot[#perSlot+1] = {
				name = slotName,
				cur = cur,
				max = max,
				pct = (cur / max) * 100
			}
		end
	end

	local pct = totalMax > 0 and (totalCur / totalMax) * 100 or 100

	return pct, perSlot
end

local function OnEnter(self)
	local pct, perSlot = GetDurabilityData()

	SteakInfoTooltip:SetOwner(self, "ANCHOR_NONE")
	SteakInfoTooltip:ClearAllPoints()
	SteakInfoTooltip:SetPoint("BOTTOM", self, "TOP", 0, 4)

	SteakInfoTooltip:ClearLines()
	SteakInfoTooltip:AddLine("Durability")

	for _, data in ipairs(perSlot) do
		local colorStr

		if data.pct > 70 then
			colorStr = "|cff00ff00%.0f%%|r"
		elseif pct > 40 then
			colorStr = "|cffffff00%.0f%%|r"
		else
			colorStr = "|cffff0000%.0f%%|r"
		end

		SteakInfoTooltip:AddDoubleLine(data.name, colorStr:format(data.pct))
	end

	SteakInfoTooltip:Show()
end

local function OnLeave(self)
	SteakInfoTooltip:Hide()
end

local function UpdateDurability(self)
	local pct, perSlot = GetDurabilityData()
	local colorStr

	if pct > 70 then
		colorStr = "Durability: |cff00ff00%.0f%%|r"
	elseif pct > 40 then
		colorStr = "Durability: |cffffff00%.0f%%|r"
	else
		colorStr = "Durability: |cffff0000%.0f%%|r"
	end

	self:SetText(colorStr:format(pct))
end

local events = {
	UPDATE_INVENTORY_DURABILITY = UpdateDurability,
	PLAYER_ENTERING_WORLD = UpdateDurability
}

local scripts = {
	OnEnter = OnEnter,
	OnLeave = OnLeave
}

SteakInfo_AddModule(events, scripts, "Durability")
