SteakInfoDB = SteakInfoDB or {
	order = {},
	side  = {},
}

local SteakInfoFrame = CreateFrame("Frame", "SteakInfoFrame", UIParent)
local _, class = UnitClass("player")
local borderColor = RAID_CLASS_COLORS[class]
local SteakInfoModuleDragging = false

SteakInfoFrame.fontFile = "Interface\\AddOns\\SteakInfo\\Audiowide-Regular.ttf"
SteakInfoFrame.bgFile = "Interface\\ChatFrame\\ChatFrameBackground"
SteakInfoFrame.edgeFile = "Interface\\Buttons\\WHITE8x8"
SteakInfoFrame.StatusBarFile = "Interface\\TARGETINGFRAME\\UI-TargetingFrame-BarFill"

SteakInfoFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 1, 20)
SteakInfoFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -1, 0)

SteakInfoFrame:SetBackdrop( { bgFile   = SteakInfoFrame.StatusBarFile, edgeFile = SteakInfoFrame.edgeFile, tile = true, tileSize = 32, edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 } } )
SteakInfoFrame:SetBackdropColor(0.2, 0.2, 0.2, 1)
SteakInfoFrame:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, 1)

SteakInfoFrame.modules = {}
SteakInfoFrame.modulesByName = {}

local SteakInfoTooltip = CreateFrame("GameTooltip", "SteakInfoTooltip", UIParent, "GameTooltipTemplate")
SteakInfoTooltip:SetOwner(UIParent, "ANCHOR_NONE")

SteakInfoTooltip:SetBackdrop( { bgFile   = SteakInfoFrame.bgFile, edgeFile = SteakInfoFrame.edgeFile, edgeSize = 1, insets   = { left = 0, right = 0, top = 0, bottom = 0 } } )

for i=1,5 do
	local left = _G["SteakInfoTooltipTextLeft"..i]
	local right = _G["SteakInfoTooltipTextRight"..i]

	if left then left:SetFont(SteakInfoFrame.fontFile, 10, "OUTLINE") end
	if right then right:SetFont(SteakInfoFrame.fontFile, 10, "OUTLINE") end
end

SteakInfoTooltip:HookScript("OnShow", function(self)
	for i=6,70 do
		local left = _G["SteakInfoTooltipTextLeft"..i]
		local right = _G["SteakInfoTooltipTextRight"..i]

		if left then left:SetFont(SteakInfoFrame.fontFile, 10, "OUTLINE") end
		if right then right:SetFont(SteakInfoFrame.fontFile, 10, "OUTLINE") end
	end

	SteakInfoTooltip:SetBackdropColor(0, 0, 0, 0.9)
	SteakInfoTooltip:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, 1)
end)

function SteakInfoFrame:LayoutModules()
	if SteakInfoModuleDragging then return end

	local leftAnchor = nil
	local rightAnchor = nil

	for i=#SteakInfoDB.order,1,-1 do
		local name = SteakInfoDB.order[i]
		local module = self.modulesByName[name]

		if module then
			if SteakInfoDB.side[name] == "RIGHT" then
				module:ClearAllPoints()

				if not rightAnchor then
					module:SetPoint("RIGHT", self, "RIGHT", 0, 0)
				else
					module:SetPoint("RIGHT", rightAnchor, "LEFT", 0, 0)
				end
				rightAnchor = module
			end
		end	
	end

	for i=1,#SteakInfoDB.order,1 do
		local name = SteakInfoDB.order[i]
		local module = self.modulesByName[name]

		if module then
			if SteakInfoDB.side[name] == "LEFT" then
				module:ClearAllPoints()

				if not leftAnchor then
					module:SetPoint("LEFT", self, "LEFT", 0, 0)
				else
					module:SetPoint("LEFT", leftAnchor, "RIGHT", 0, 0)
				end
				leftAnchor = module
			end
		end
	end
end

local function Module_SetText(self, text)
	self.text:SetJustifyH(SteakInfoDB.side[self.name] or "CENTER")
	self.text:SetText(text or "")
	self:SetWidth(math.max(self:GetWidth(), self.text:GetStringWidth() + 30))
	SteakInfoFrame:LayoutModules()
end

local function Module_OnEvent(self, event, ...)
	local handler = self.handlers[event]

	if handler then
		handler(self, event, ...)
	end
end

function SteakInfo_Reorder(name, target)
	local order = SteakInfoDB.order

	for i, v in ipairs(order) do
		if v == name then
			table.remove(order, i)
			break
		end
	end

	for i, v in ipairs(order) do
		if v == target then
			table.insert(order, i, name)
			return
		end
	end

	table.insert(order, name)
	
	SteakInfoFrame:LayoutModules()
end

function SteakInfo_DropModule(module)
	local droppedX = module:GetCenter()
	local frameLeft = SteakInfoFrame:GetLeft()
	local frameRight = SteakInfoFrame:GetRight()
	local frameCenter = (frameLeft + frameRight) / 2

	if droppedX < frameCenter then
		SteakInfoDB.side[module.name] = "LEFT"
	else
		SteakInfoDB.side[module.name] = "RIGHT"
	end

	local closest, closestDist = nil, math.huge

	for _, other in ipairs(SteakInfoFrame.modules) do
		if other ~= module then
			local ox = other:GetCenter()
			local dist = math.abs(droppedX - ox)

			if dist < closestDist then
				closest = other
				closestDist = dist
			end
		end
	end

	if closest then
		SteakInfo_Reorder(module.name, closest.name)
	end

	SteakInfoFrame:LayoutModules()
end

function SteakInfo_AddModule(events, scripts, moduleName)
	assert(moduleName, "SteakInfo_AddModule requires a module name")

	local module = CreateFrame("Button", nil, SteakInfoFrame)
	module:SetHeight(SteakInfoFrame:GetHeight())
	module.name = moduleName

	local text = module:CreateFontString(nil, "OVERLAY")
	text:SetFont("Interface\\AddOns\\SteakInfo\\Audiowide-Regular.ttf", 9, "OUTLINE")
	text:SetPoint("CENTER", module, "CENTER", 0, 0)
	module.text = text

	module:SetMovable(true)
	module:EnableMouse(true)
	module:RegisterForDrag("LeftButton")

	module:SetScript("OnDragStart", function(self)
		SteakInfoModuleDragging = true

		local lp, anchor, rp = self:GetPoint()

		for _, module in pairs(SteakInfoFrame.modules) do
			if select(2, module:GetPoint()) == self then
				module:ClearAllPoints()
				module:SetPoint(lp, anchor, rp, 0, 0)
				break
			end
		end

		self:StartMoving()
	end)

	module:SetScript("OnDragStop", function(self)
		SteakInfoModuleDragging = false
		self:StopMovingOrSizing()
		SteakInfo_DropModule(self)
	end)


	if not SteakInfoDB.side[moduleName] then
		SteakInfoDB.side[moduleName] = "LEFT"
	end

	local exists = false

	for _, name in ipairs(SteakInfoDB.order) do
		if name == moduleName then
			exists = true
			break
		end
	end
	if not exists then
		table.insert(SteakInfoDB.order, moduleName)
	end

	table.insert(SteakInfoFrame.modules, module)
	SteakInfoFrame.modulesByName[moduleName] = module

	module.handlers = {}

	if events then
		for event, func in pairs(events) do
			module:RegisterEvent(event)
			module.handlers[event] = func
		end
		module:SetScript("OnEvent", Module_OnEvent)
	end

	if scripts then
		for name, func in pairs(scripts) do
			module:SetScript(name, func)
		end
	end

	module.SetText = Module_SetText

	SteakInfoFrame:LayoutModules()

	return module
end

local function OnEvent(self, event, ...)
	SteakInfoDB = SteakInfoDB or {}
	SteakInfoDB[UnitName("player")] = SteakInfoDB[UnitName("player")] or {}
	SteakInfoDB.order = SteakInfoDB.order or {}
	SteakInfoDB.side = SteakInfoDB.side or {}
end

SteakInfoFrame:RegisterEvent("VARIABLES_LOADED")

SteakInfoFrame:SetScript("OnEvent", OnEvent)

hooksecurefunc("UIParent_ManageFramePositions", function()
	local bar = MainMenuBar
	local height = SteakInfoFrame:GetHeight()

	if not bar:IsShown() then return end

	bar:ClearAllPoints()
	bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, height + 2)
end)
