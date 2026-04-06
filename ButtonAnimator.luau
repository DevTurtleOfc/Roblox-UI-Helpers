-->> Services
local TweenService = game:GetService("TweenService")

-->> Variables
local ButtonAnimator = {}
ButtonAnimator.__index = ButtonAnimator

local ClickStyles = {}
local HoverStyles = {}

-- // Constructor
function ButtonAnimator.new(config, tweenInfoConfig)
	local self = setmetatable({}, ButtonAnimator)

	self.Config = config or {}
	self.Config.Intensity = self.Config.Intensity or 1
	self.Config.ClickStyle = self.Config.ClickStyle or "default"
	self.Config.HoverStyle = self.Config.HoverStyle or "default"

	self.TweenInfoConfig = tweenInfoConfig or {}

	self.TweenInfoConfig.MouseDown = self.TweenInfoConfig.MouseDown
		or TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	self.TweenInfoConfig.MouseUp = self.TweenInfoConfig.MouseUp
		or TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	self.TweenInfoConfig.MouseEnter = self.TweenInfoConfig.MouseEnter
		or TweenInfo.new(0.03, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	self.TweenInfoConfig.MouseLeave = self.TweenInfoConfig.MouseLeave
		or TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)


	self.BoundButtons = {}

	return self
end

--// Getters
function ButtonAnimator:_getClickStyle()
	return ClickStyles[self.Config.ClickStyle] or ClickStyles.default
end

function ButtonAnimator:_getHoverStyle()
	return HoverStyles[self.Config.HoverStyle] or HoverStyles.default
end

--// Functions
local function tweenUIScale(buttonData, targetScale: number, tweenInfo)
	if not buttonData.UIScale then return end

	if buttonData.ScaleTween then
		buttonData.ScaleTween:Cancel()
		buttonData.ScaleTween = nil
	end

	local tween = TweenService:Create(
		buttonData.UIScale,
		tweenInfo,
		{Scale = targetScale}
	)

	buttonData.ScaleTween = tween
	
	tween.Completed:Connect(function()
		if buttonData.ScaleTween == tween then
			buttonData.ScaleTween = nil
		end
	end)
	
	tween:Play()
end

local function getScaleFromPixels(button: GuiButton, pixelAmount: number)
	local absoluteSize = button.AbsoluteSize
	local baseSize = math.min(absoluteSize.X, absoluteSize.Y)

	if baseSize <= 0 then
		return 0
	end

	return math.clamp(pixelAmount / baseSize, 0.01, 0.5)
end

--// ClickStyles
ClickStyles.default = {
	MouseDown = function(buttonData, tweenInfo)
		local amount = getScaleFromPixels(buttonData.Button, 3 * buttonData.Intensity)
		tweenUIScale(buttonData, buttonData.UIScaleOriginScale - amount, tweenInfo)
	end,

	MouseUp = function(buttonData, tweenInfo)
		if buttonData.IsHovering then
			local amount = getScaleFromPixels(buttonData.Button, 2 * buttonData.Intensity)
			tweenUIScale(buttonData, buttonData.UIScaleOriginScale + amount, tweenInfo)
		else
			tweenUIScale(buttonData, buttonData.UIScaleOriginScale, tweenInfo)
		end
	end,
}

ClickStyles.cartoony = {
	MouseDown = function(buttonData, tweenInfo)
		local amount = getScaleFromPixels(buttonData.Button, 8 * buttonData.Intensity)
		tweenUIScale(buttonData, buttonData.UIScaleOriginScale - amount, tweenInfo)
	end,

	MouseUp = function(buttonData, tweenInfo)
		if buttonData.IsHovering then
			local amount = getScaleFromPixels(buttonData.Button, 4 * buttonData.Intensity)
			tweenUIScale(buttonData, buttonData.UIScaleOriginScale + amount, tweenInfo)
		else
			tweenUIScale(buttonData, buttonData.UIScaleOriginScale, tweenInfo)
		end
	end,
}

--// HoverStyles
HoverStyles.default = {
	MouseEnter = function(buttonData, tweenInfo)
		buttonData.IsHovering = true
		local amount = getScaleFromPixels(buttonData.Button, 2 * buttonData.Intensity)
		tweenUIScale(buttonData, buttonData.UIScaleOriginScale + amount, tweenInfo)
	end,

	MouseLeave = function(buttonData, tweenInfo)
		buttonData.IsHovering = false
		tweenUIScale(buttonData, buttonData.UIScaleOriginScale, tweenInfo)
	end,
}

HoverStyles.cartoony = {
	MouseEnter = function(buttonData, tweenInfo)
		buttonData.IsHovering = true
		local amount = getScaleFromPixels(buttonData.Button, 4 * buttonData.Intensity)
		tweenUIScale(buttonData, buttonData.UIScaleOriginScale + amount, tweenInfo)
	end,

	MouseLeave = function(buttonData, tweenInfo)
		buttonData.IsHovering = false
		tweenUIScale(buttonData, buttonData.UIScaleOriginScale, tweenInfo)
	end,
}

--// Methods
function ButtonAnimator:Bind(button: GuiButton)
	if not button then
		error("Did you forget to add a button? button is nil")
	end

	if self.BoundButtons[button] then -- clean up previous connections if it exists
		self:Unbind(button)
	end

	local scale = button:FindFirstChildOfClass("UIScale")

	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = button
	end

	self.BoundButtons[button] = {
		Button = button,
		Connections = {},
		UIScale = scale,
		IsHovering = false,
		UIScaleOriginScale = scale.Scale,
		Intensity = self.Config.Intensity,
	}

	local buttonData = self.BoundButtons[button]

	local clickStyle = self:_getClickStyle()
	local hoverStyle = self:_getHoverStyle()

	table.insert(buttonData.Connections, button.MouseButton1Down:Connect(function()
		if clickStyle.MouseDown then
			clickStyle.MouseDown(buttonData, self.TweenInfoConfig.MouseDown)
		end
	end))

	table.insert(buttonData.Connections, button.MouseButton1Up:Connect(function()
		if clickStyle.MouseUp then
			clickStyle.MouseUp(buttonData, self.TweenInfoConfig.MouseUp)
		end
	end))

	table.insert(buttonData.Connections, button.MouseEnter:Connect(function()
		if hoverStyle.MouseEnter then
			hoverStyle.MouseEnter(buttonData, self.TweenInfoConfig.MouseEnter)
		end
	end))

	table.insert(buttonData.Connections, button.MouseLeave:Connect(function()
		if hoverStyle.MouseLeave then
			hoverStyle.MouseLeave(buttonData, self.TweenInfoConfig.MouseLeave)
		end
	end))
end

function ButtonAnimator:Unbind(button: GuiButton)
	if not button then
		error("You didn't specify a button. button is nil")
	end

	local buttonData = self.BoundButtons[button]

	if buttonData then
		for _, connection in ipairs(buttonData.Connections) do
			connection:Disconnect()
		end

		if buttonData.ScaleTween then
			buttonData.ScaleTween:Cancel()
			buttonData.ScaleTween = nil
		end

		if buttonData.UIScale and buttonData.UIScaleOriginScale then
			buttonData.UIScale.Scale = buttonData.UIScaleOriginScale
		end

		self.BoundButtons[button] = nil
	else
		warn("Button was not bound yet nothing changed.")
	end
end

function ButtonAnimator:UnbindAll()
	for button, _ in pairs(self.BoundButtons) do
		self:Unbind(button)
	end
end

function ButtonAnimator:SetOriginScale(button: GuiButton, newOriginScale: number)
	local buttonData = self.BoundButtons[button]
	
	if not buttonData then
		warn("Button was not bound yet nothing changed.")
		return
	end
	
	buttonData.UIScaleOriginScale = newOriginScale
end

function ButtonAnimator:ResetScale(button: GuiButton, newScale: number)
	local buttonData = self.BoundButtons[button]

	if not buttonData then
		warn("Button was not bound yet nothing changed.")
		return
	end
	
	if buttonData.ScaleTween then
		buttonData.ScaleTween:Cancel()
		buttonData.ScaleTween = nil
	end
	
	buttonData.UIScale.Scale = newScale
	buttonData.UIScaleOriginScale = newScale
	buttonData.IsHovering = false
end

function ButtonAnimator:SetIntensity(button: GuiButton, intensity: number)
	if typeof(intensity) ~= "number" then
		warn("Intensity must be a number.")
		return
	end
	
	local buttonData = self.BoundButtons[button]
	
	if not buttonData then
		warn("Button was not bound yet nothing changed.")
		return
	end
	
	buttonData.Intensity = math.max(0, intensity)
end

function ButtonAnimator:SetAllIntensity(intensity: number)
	if typeof(intensity) ~= "number" then
		warn("Intensity must be a number.")
		return
	end
	
	for button, _ in pairs(self.BoundButtons) do
		self:SetIntensity(button, intensity)
	end
end

function ButtonAnimator:SetDefaultIntensity(intensity: number)
	if typeof(intensity) ~= "number" then
		warn("Intensity must be a number.")
		return
	end
	
	self.Config.Intensity = math.max(0, intensity)
end

function ButtonAnimator:SetDefaultIntensityAndApply(intensity: number)
	if typeof(intensity) ~= "number" then
		warn("Intensity must be a number.")
		return
	end

	self.Config.Intensity = math.max(0, intensity)
	self:SetAllIntensity(intensity)
end

function ButtonAnimator:GetButtonData(button: GuiButton)
	local buttonData = self.BoundButtons[button]

	if buttonData then
		return buttonData
	else
		warn("Button was not bound yet no data was found.")
		return nil
	end
end

return ButtonAnimator
