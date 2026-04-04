local frame = CreateFrame("Frame", nil, UIParent)
local borderColor = RAID_CLASS_COLORS[select(2, UnitClass("player"))]

frame:EnableMouse(false)
frame:SetClampedToScreen(true)
frame:SetBackdrop( { bgFile = SteakInfoFrame.bgFile, edgeFile = SteakInfoFrame.edgeFile, edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 } } )
frame:SetBackdropColor(0, 0, 0, 0.8)
frame:SetBackdropBorderColor(borderColor.r or 1, borderColor.g or 0.5, borderColor.b or 0, 1)
frame:SetFrameStrata("TOOLTIP")

frame:Hide()

local bars = {}
local header

local function ShowRoster()
	local rows = {}

	local maxName  = 0
	local maxLevel = 0
	local maxRank  = 0
	local maxZone  = 0
	local maxNote  = 0

	local temp = UIParent:CreateFontString(nil, "OVERLAY")
	temp:SetFont("Interface\\AddOns\\SteakInfo\\Audiowide-Regular.ttf", 8, "OUTLINE")

	local i = 1

	while GetGuildRosterInfo(i) ~= nil do
		local name, rank, rankIndex, level, class, zone, note, officerNote, online, _, classFileName = GetGuildRosterInfo(i)

		if online then
			table.insert(rows, { name, tostring(level), rank, zone, note, class, classFileName })

			temp:SetText(name or "")
			maxName = math.max(maxName, temp:GetStringWidth())

			temp:SetText(level or "")
			maxLevel = math.max(maxLevel, temp:GetStringWidth())

			temp:SetText(rank or "")
			maxRank = math.max(maxRank, temp:GetStringWidth())

			temp:SetText(zone or "")
			maxZone = math.max(maxZone, temp:GetStringWidth())

			temp:SetText(note or "")
			maxNote = math.max(maxNote, temp:GetStringWidth())
		end

		i = i + 1
	end

	local PAD = 10

	--[[
	maxName  = maxName  + PAD
	maxLevel = maxLevel + PAD
	maxRank  = maxRank  + PAD
	maxZone  = maxZone  + PAD
	maxNote  = maxNote  + PAD
	]]

	for _, bar in ipairs(bars) do bar:Hide() end

	if not header then
		header = CreateFrame("Frame", nil, frame)
		header:SetHeight(16)
		header:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
		header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)

		header.name = header:CreateFontString(nil, "OVERLAY")
		header.name:SetFont("Interface\\AddOns\\SteakInfo\\Audiowide-Regular.ttf", 8, "OUTLINE")
		header.name:SetText("Name")
		header.name:SetJustifyH("LEFT")
		header.name:SetPoint("LEFT", header, "LEFT", 0, 0)

		header.level = header:CreateFontString(nil, "OVERLAY")
		header.level:SetFont("Interface\\AddOns\\SteakInfo\\Audiowide-Regular.ttf", 8, "OUTLINE")
		header.level:SetText("Level")
		header.level:SetJustifyH("LEFT")
		header.level:SetPoint("LEFT", header.name, "RIGHT", 0, 0)

		header.rank = header:CreateFontString(nil, "OVERLAY")
		header.rank:SetFont("Interface\\AddOns\\SteakInfo\\Audiowide-Regular.ttf", 8, "OUTLINE")
		header.rank:SetText("Rank")
		header.rank:SetJustifyH("LEFT")
		header.rank:SetPoint("LEFT", header.level, "RIGHT", 0, 0)

		header.zone = header:CreateFontString(nil, "OVERLAY")
		header.zone:SetFont("Interface\\AddOns\\SteakInfo\\Audiowide-Regular.ttf", 8, "OUTLINE")
		header.zone:SetText("Zone")
		header.zone:SetJustifyH("LEFT")
		header.zone:SetPoint("LEFT", header.rank, "RIGHT", 0, 0)

		header.note = header:CreateFontString(nil, "OVERLAY")
		header.note:SetFont("Interface\\AddOns\\SteakInfo\\Audiowide-Regular.ttf", 8, "OUTLINE")
		header.note:SetText("Note")
		header.note:SetJustifyH("LEFT")
		header.note:SetPoint("LEFT", header.zone, "RIGHT", 0, 0)
	end
	--[[
	else
		header.name:SetWidth(maxName)
		header.level:SetWidth(maxLevel)
		header.rank:SetWidth(maxRank)
		header.zone:SetWidth(maxZone)
		header.note:SetWidth(maxNote)
		header:Show()
	end
	]]

	maxName = math.max(header.name:GetStringWidth(), maxName) + PAD
	maxLevel = math.max(header.level:GetStringWidth(), maxLevel) + PAD
	maxRank = math.max(header.rank:GetStringWidth(), maxRank) + PAD
	maxZone = math.max(header.zone:GetStringWidth(), maxZone) + PAD
	maxNote = math.max(header.note:GetStringWidth(), maxNote) + PAD

	header.name:SetWidth(maxName)
	header.level:SetWidth(maxLevel)
	header.rank:SetWidth(maxRank)
	header.zone:SetWidth(maxZone)
	header.note:SetWidth(maxNote)

	local rowIndex = 1

	for _, data in ipairs(rows) do
		local name, level, rank, zone, note, class, classFileName = unpack(data)
		local bar = bars[rowIndex]

		if not bar then
			bar = CreateFrame("StatusBar", nil, frame)
			bar:SetMinMaxValues(1, 80)
			bar:SetHeight(16)
			bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
			bars[rowIndex] = bar

			bar.nameText  = bar:CreateFontString(nil, "OVERLAY")
			bar.nameText:SetFont(SteakInfoFrame.fontFile, 8, "OUTLINE")
			bar.nameText:SetJustifyH("LEFT")

			bar.levelText = bar:CreateFontString(nil, "OVERLAY")
			bar.levelText:SetFont(SteakInfoFrame.fontFile, 8, "OUTLINE")
			bar.levelText:SetJustifyH("LEFT")

			bar.rankText  = bar:CreateFontString(nil, "OVERLAY")
			bar.rankText:SetFont(SteakInfoFrame.fontFile, 8, "OUTLINE")
			bar.rankText:SetJustifyH("LEFT")

			bar.zoneText  = bar:CreateFontString(nil, "OVERLAY")
			bar.zoneText:SetFont(SteakInfoFrame.fontFile, 8, "OUTLINE")
			bar.zoneText:SetJustifyH("LEFT")

			bar.noteText  = bar:CreateFontString(nil, "OVERLAY")
			bar.noteText:SetFont(SteakInfoFrame.fontFile, 8, "OUTLINE")
			bar.noteText:SetJustifyH("LEFT")
		end

		bar:ClearAllPoints()

		if rowIndex == 1 then
			bar:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -1)
			bar:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -1)
		else
			bar:SetPoint("TOPLEFT", bars[rowIndex - 1], "BOTTOMLEFT", 0, -1)
			bar:SetPoint("TOPRIGHT", bars[rowIndex - 1], "BOTTOMRIGHT", 0, -1)
		end

		bar.nameText:SetPoint("LEFT", bar, "LEFT", 0, 0)
		bar.nameText:SetWidth(maxName)
		bar.nameText:SetText(name)

		bar.levelText:SetPoint("LEFT", bar.nameText, "RIGHT", 0, 0)
		bar.levelText:SetWidth(maxLevel)
		bar.levelText:SetText(level)

		bar.rankText:SetPoint("LEFT", bar.levelText, "RIGHT", 0, 0)
		bar.rankText:SetWidth(maxRank)
		bar.rankText:SetText(rank)

		bar.zoneText:SetPoint("LEFT", bar.rankText, "RIGHT", 0, 0)
		bar.zoneText:SetWidth(maxZone)
		bar.zoneText:SetText(zone)

		bar.noteText:SetPoint("LEFT", bar.zoneText, "RIGHT", 0, 0)
		bar.noteText:SetWidth(maxNote)
		bar.noteText:SetText(note)

		bar:SetStatusBarColor(RAID_CLASS_COLORS[classFileName].r or 1, RAID_CLASS_COLORS[classFileName].g or 1, RAID_CLASS_COLORS[classFileName].b or 1)

		bar:Show()

		rowIndex = rowIndex + 1
	end

	frame:SetSize(maxName + maxLevel + maxRank + maxZone + maxNote + 4, (rowIndex - 1) * 17 + 20)
end

local function OnEnter(self)
	if UnitAffectingCombat("player") then return end

	frame:ClearAllPoints()
	frame:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)

	ShowRoster()
	frame:Show()
end

local function OnLeave(self)
	frame:Hide()
end

local function UpdateGuildCount(self)
	local online = 0
	local i = 1

	while GetGuildRosterInfo(i) ~= nil do
		local _, _, _, _, _, _, _, _, onlineStatus = GetGuildRosterInfo(i)

		if onlineStatus then online = online + 1 end

		i = i + 1
	end

	self:SetText(("Guild: %d / %d"):format(online, i - 1))
end

local function OnPlayerEnteringWorld(self)
	GuildRoster()
	UpdateGuildCount(self)
end

local function OnSystemMessage(self, msg)
	local patterns = {
		"has come online",
		"has gone offline",
		"has joined the guild",
		"has left the guild"
	}

	for _, pattern in ipairs(patterns) do
		if msg:find(pattern) then
			GuildRoster()
			break
		end
	end

	--if msg:find("has come online") or msg:find("has gone offline") then
	--	GuildRoster()
	--end
end

local function OnClick(self, button)
	PanellTemplates_SetTab(FriendsFrame, 3)
	ShowUIPanel(FriendsFrame)
end

local events = {
	PLAYER_ENTERING_WORLD = OnPlayerEnteringWorld,
	CHAT_MSG_SYSTEM = OnSystemMessage,
	GUILD_ROSTER_UPDATE = UpdateGuildCount
}

local scripts = {
	OnEnter = OnEnter,
	OnLeave = OnLeave,
	OnClick = OnClick
}

SteakInfo_AddModule(events, scripts, "Guild")
