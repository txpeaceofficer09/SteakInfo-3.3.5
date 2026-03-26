local function GetCoinTextureString(copper)
	local gold = math.floor(copper / 10000)
	local silver = math.floor((copper % 10000) / 100)
	local remainingCopper = copper % 100

	local goldTexture   = "Interface\\MoneyFrame\\UI-GoldIcon"
	local silverTexture = "Interface\\MoneyFrame\\UI-SilverIcon"
	local copperTexture = "Interface\\MoneyFrame\\UI-CopperIcon"

	return ("%d|T%s:0|t %d|T%s:0|t %d|T%s:0|t"):format(gold, goldTexture, silver, silverTexture, remainingCopper, copperTexture)
end

local function OnEnter(self)
	if UnitAffectingCombat("player") then return end

	SteakInfoTooltip:SetOwner(self, "ANCHOR_NONE")
	SteakInfoTooltip:ClearAllPoints()
	SteakInfoTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)

	SteakInfoTooltip:AddLine("Money:")
	SteakInfoTooltip:AddLine(" ")

	local Money = 0

	for character, copper in pairs(SteakInfoDB.Money) do
		SteakInfoTooltip:AddDoubleLine(character, GetCoinTextureString(copper or 0))
		Money = Money + (copper or 0)
	end

	SteakInfoTooltip:AddLine("-----------------------")
	SteakInfoTooltip:AddDoubleLine("Total", GetCoinTextureString(Money))
	SteakInfoTooltip:Show()
end

local function OnLeave(self)
	SteakInfoTooltip:Hide()
	SteakInfoTooltip:ClearLines()
end

local function UpdateMoney(self)
	self:SetText(GetCoinTextureString(GetMoney()))
	SteakInfoDB.Money[UnitName("player")] = GetMoney()
end

local function OnVariablesLoaded(self)
	SteakInfoDB.Money = SteakInfoDB.Money or {}
end

local function OnClick(self, button)
	ToggleCharacter("TokenFrame")
end

local events = {
	PLAYER_ENTERING_WORLD = UpdateMoney,
	PLAYER_MONEY = UpdateMoney,
	VARIABLES_LOADED = OnVariablesLoaded
}

local scripts = {
	OnEnter = OnEnter,
	OnLeave = OnLeave,
	OnClick = OnClick
}

SteakInfo_AddModule(events, scripts, "Money")
