-->> Services
local TweenService = game:GetService("TweenService")

-->> Variables
local FrameAnimator = {}
FrameAnimator.__index = FrameAnimator

local AnimationStyles = {}

--// Constructor
function FrameAnimator.new(frame, AnimationStyle: string, tweenInfoConfig)
	if not frame then
		error("given Frame is nil")
	end
	
	local self = setmetatable({}, FrameAnimator)
	
	self.Frame = frame
	self.UIScale = frame:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", frame)
	self.AnimationStyle = AnimationStyle or "default"
	
	self.OpenButtons = {}
	self.CloseButtons = {}
	self.ToggleButtons = {}
	
	self.TweenInfoConfig = tweenInfoConfig or {}
	
	self.TweenInfoConfig.Open = self.TweenInfoConfig.Open or TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	self.TweenInfoConfig.Close = self.TweenInfoConfig.Close or TweenInfo.new(0.17, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	
	self.isOpen = frame.Visible
	self.isAnimating = false
	
	return self
end

--// Getters
function FrameAnimator:_getAnimationStyle()
	return AnimationStyles[self.AnimationStyle] or AnimationStyles.default
end

--// Functions
local function tweenUIScale(tweenInfo, uiScale: UIScale, targetScale: number)
	local tween = TweenService:Create(uiScale, tweenInfo, {Scale = targetScale})
	tween:Play()
	return tween
end

--// AnimationStyles
AnimationStyles.default = {
	Open = function(selfData)
		if selfData.isAnimating then return end
		selfData.isAnimating = true
		
		selfData.Frame.Visible = true
		selfData.UIScale.Scale = 0.5
		
		local tween = tweenUIScale(selfData.TweenInfoConfig.Open, selfData.UIScale, 1)
		tween.Completed:Once(function()
			selfData.isAnimating = false
		end)
		tween = nil
	end,

	Close = function(selfData)
		if selfData.isAnimating then return end
		selfData.isAnimating = true

		local tween = tweenUIScale(selfData.TweenInfoConfig.Close, selfData.UIScale, 0.8)
		tween.Completed:Once(function()
			selfData.Frame.Visible = false
			selfData.isAnimating = false
		end)
		tween = nil
	end,
}

AnimationStyles.cartoony = {
	Open = function(selfData)
		if selfData.isAnimating then return end
		selfData.isAnimating = true

		selfData.Frame.Visible = true
		selfData.UIScale.Scale = 0

		local tween = tweenUIScale(selfData.TweenInfoConfig.Open, selfData.UIScale, 1)
		tween.Completed:Once(function()
			selfData.isAnimating = false
		end)
		tween = nil
	end,

	Close = function(selfData)
		if selfData.isAnimating then return end
		selfData.isAnimating = true

		local tween = tweenUIScale(selfData.TweenInfoConfig.Close, selfData.UIScale, 0)
		tween.Completed:Once(function()
			selfData.Frame.Visible = false
			selfData.isAnimating = false
		end)
		tween = nil
	end,
}

--// Methods
function FrameAnimator:Open()
	if self.isOpen or self.isAnimating then return end

	self.isOpen = true
	self:_getAnimationStyle().Open(self)
end

function FrameAnimator:Close()
	if not self.isOpen or self.isAnimating then return end

	self.isOpen = false
	self:_getAnimationStyle().Close(self)
end

function FrameAnimator:Toggle()
	if self.isOpen then
		self:Close()
	else
		self:Open()
	end
end

function FrameAnimator:BindOpenButton(button: GuiButton)
	self.OpenButtons[button] = button.MouseButton1Click:Connect(function()
		self:Open()
	end)
end

function FrameAnimator:BindCloseButton(button: GuiButton)
	self.CloseButtons[button] = button.MouseButton1Click:Connect(function()
		self:Close()
	end)
end

function FrameAnimator:BindToggleButton(button: GuiButton)
	self.ToggleButtons[button] = button.MouseButton1Click:Connect(function()
		self:Toggle()
	end)
end


function FrameAnimator:UnbindOpenButton(button: GuiButton)
	if self.OpenButtons[button] then
		self.OpenButtons[button]:Disconnect()
		self.OpenButtons[button] = nil
	else
		warn("This button is not binded to open so nothing changed.")
	end
end

function FrameAnimator:UnbindCloseButton(button: GuiButton)
	if self.CloseButtons[button] then
		self.CloseButtons[button]:Disconnect()
		self.CloseButtons[button] = nil
	else
		warn("This button is not binded to close so nothing changed.")
	end
end

function FrameAnimator:UnbindToggleButton(button: GuiButton)
	if self.ToggleButtons[button] then
		self.ToggleButtons[button]:Disconnect()
		self.ToggleButtons[button] = nil
	else
		warn("This button is not binded to toggle so nothing changed.")
	end
end

return FrameAnimator
