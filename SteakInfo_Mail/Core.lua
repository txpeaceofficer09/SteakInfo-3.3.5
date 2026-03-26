local function UpdateMailText(self)
	local formatStr = "|TInterface\\Minimap\\Tracking\\Mailbox:14:14|t |cff%s%s|r"

	if HasNewMail() then
		self:SetText(formatStr:format("00ff00", "New"))
	else
		self:SetText(formatStr:format("ff8000", "None"))
	end
end

local events = {
	PLAYER_ENTERING_WORLD = UpdateMailText,
	UPDATE_PENDING_MAIL = UpdateMailText
}

local scripts = {}

SteakInfo_AddModule(events, scripts, "Mail")
