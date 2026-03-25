local currencyLines = {}
local _, playerClass = UnitClass("player")
local classColor = RAID_CLASS_COLORS[playerClass]

local SteakInfoCurrencyFrame = CreateFrame("Frame", "SteakInfoCurrencyFrame", UIParent)
SteakInfoCurrencyFrame:SetBackdrop( { bgFile = SteakInfoFrame.bgFile, edgeFile = SteakInfoFrame.edgeFile, edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 } } )
SteakInfoCurrencyFrame:SetBackdropColor(0, 0, 0, 0.9)
SteakInfoCurrencyFrame:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 1)
SteakInfoCurrencyFrame:SetClampedToScreen(true)
SteakInfoCurrencyFrame:SetFrameStrata("TOOLTIP")
SteakInfoCurrencyFrame:Hide()

local function FormatNumber(n)
	if not n then return "0" end

	local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')

	return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

local function BuildCurrencyList()
	local list = {}
	local size = GetCurrencyListSize()

	if size == 0 then return list end

	local collapsed = {}

	for i = 1, size do
		local name, isHeader, isExpanded = GetCurrencyListInfo(i)

		if isHeader and not isExpanded then
			collapsed[i] = true
			ExpandCurrencyList(i, 1)
		end
	end

	for i = 1, GetCurrencyListSize() do
		local name, isHeader, isExpanded, isUnused, isWatched, count, _, icon = GetCurrencyListInfo(i)

		if not isHeader and name and count then
			list[#list+1] = {
				name = name,
				count = count,
				icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark",
			}
		end
	end

	for i = 1, GetCurrencyListSize() do
		if collapsed[i] then
			ExpandCurrencyList(i, 0)
		end
	end

	return list
end

local function ShowCurrencyPopup(anchorFrame)
	local list = BuildCurrencyList()

	if #list == 0 then
		SteakInfoCurrencyFrame:Hide()
		return
	end

	for _, line in ipairs(currencyLines) do line:Hide() end

	local y = -6
	local maxName = 0
	local maxValue = 0

	local temp = UIParent:CreateFontString(nil, "OVERLAY")
	temp:SetFont(SteakInfoFrame.fontFile, 12, "OUTLINE")

	for _, data in ipairs(list) do
		temp:SetText(data.name)
		maxName = math.max(maxName, temp:GetStringWidth())

		temp:SetText(FormatNumber(data.count))
		maxValue = math.max(maxValue, temp:GetStringWidth())
	end

	maxName = maxName + 10
	maxValue = maxValue + 10

	local index = 1

	for _, data in ipairs(list) do
		local line = currencyLines[index]

		if not line then
			line = CreateFrame("Frame", nil, SteakInfoCurrencyFrame)

			line.icon = line:CreateTexture(nil, "ARTWORK")
			line.icon:SetSize(14, 14)
			line.icon:SetPoint("LEFT", line, "LEFT", 4, 0)

			line.name = line:CreateFontString(nil, "OVERLAY")
			line.name:SetFont(SteakInfoFrame.fontFile, 12, "OUTLINE")
			line.name:SetJustifyH("LEFT")

			line.value = line:CreateFontString(nil, "OVERLAY")
			line.value:SetFont(SteakInfoFrame.fontFile, 12, "OUTLINE")
			line.value:SetJustifyH("RIGHT")

			currencyLines[index] = line
		end

		line.icon:SetTexture(data.icon)
		line.name:SetText(data.name)
		line.value:SetText(FormatNumber(data.count))

		line:SetPoint("TOPLEFT", SteakInfoCurrencyFrame, "TOPLEFT", 4, y)
		line:SetSize(maxName + maxValue + 40, 16)

		line.name:SetPoint("LEFT", line.icon, "RIGHT", 6, 0)
		line.name:SetWidth(maxName)

		line.value:SetPoint("LEFT", line.name, "RIGHT", 10, 0)
		line.value:SetWidth(maxValue)

		line:Show()

		y = y - 18
		index = index + 1
	end

	local height = math.abs(y) + 6
	local width = maxName + maxValue + 40

	SteakInfoCurrencyFrame:SetSize(width, height)
	SteakInfoCurrencyFrame:ClearAllPoints()
	SteakInfoCurrencyFrame:SetPoint("BOTTOM", anchorFrame, "TOP", 0, 4)
	SteakInfoCurrencyFrame:Show()
end

local function GetBagSpace()
	local free, total = 0, 0

	for bag = 0, 4 do
		local slots = GetContainerNumSlots(bag)
		if slots and slots > 0 then
			total = total + slots
			free  = free + GetContainerNumFreeSlots(bag)
		end
	end

	return free, total
end

local function FormatBagString(free, total)
	return ("|T%s:12:12:0:0|t %d / %d"):format("Interface\\Buttons\\Button-Backpack-Up", free, total)
end

local function UpdateBags(self)
	local free, total = GetBagSpace()

	self:SetText(FormatBagString(free, total))
end

local function OnLeave(self)
	SteakInfoCurrencyFrame:Hide()
end

local events = {
	PLAYER_ENTERING_WORLD = UpdateBags,
	BAG_UPDATE = UpdateBags,
	BAG_UPDATE_DELAYED = UpdateBags
}

local scripts = {
	OnClick = OpenAllBags,
	OnEnter = ShowCurrencyPopup,
	OnLeave = OnLeave
}

SteakInfo_AddModule(events, scripts, "Bags")
