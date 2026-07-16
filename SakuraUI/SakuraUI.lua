--[[
    Sakura UI Library
    A modern Roblox UI library with sidebar tabs, collapsible modules, and smooth animations
    Created with love for scripting enthusiasts
]]--

local SakuraUI = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Constants
local SIDEBAR_WIDTH = 250
local MAIN_CONTENT_WIDTH = 750
local MODULE_HEADER_HEIGHT = 45
local PADDING = 10
local ANIMATION_SPEED = 0.3
local RIPPLE_DURATION = 0.6

-- Default Theme
local DEFAULT_THEME = {
	Primary = Color3.fromRGB(255, 105, 180), -- Hot Pink
	Background = Color3.fromRGB(245, 230, 240), -- Light Pink
	Border = Color3.fromRGB(200, 150, 180),
	Text = Color3.fromRGB(128, 80, 120),
	Icon = Color3.fromRGB(200, 100, 150),
	Secondary = Color3.fromRGB(220, 120, 180),
	Hover = Color3.fromRGB(255, 140, 200),
}

local LIGHT_THEME = {
	Primary = Color3.fromRGB(255, 105, 180), -- Hot Pink
	Background = Color3.fromRGB(245, 230, 240), -- Light Pink
	Border = Color3.fromRGB(200, 150, 180),
	Text = Color3.fromRGB(128, 80, 120),
	Icon = Color3.fromRGB(200, 100, 150),
	Secondary = Color3.fromRGB(220, 120, 180),
	Hover = Color3.fromRGB(255, 140, 200),
}

local DARK_THEME = {
	Primary = Color3.fromRGB(255, 105, 180),
	Background = Color3.fromRGB(25, 15, 20),
	Border = Color3.fromRGB(100, 50, 80),
	Text = Color3.fromRGB(220, 180, 200),
	Icon = Color3.fromRGB(200, 100, 150),
	Secondary = Color3.fromRGB(60, 30, 50),
	Hover = Color3.fromRGB(100, 50, 80),
}

-- Utility Functions
local function CreateRounded(name, parent, size, position, color, radius)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Parent = parent
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = frame
	
	return frame
end

local function CreateStroke(parent, thickness, color, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Parent = parent
	stroke.Thickness = thickness or 1
	stroke.Color = color or Color3.new(1, 1, 1)
	stroke.Transparency = transparency or 0
	return stroke
end

local function Tween(object, tweenInfo, properties)
	local tween = TweenService:Create(object, tweenInfo, properties)
	tween:Play()
	return tween
end

local function SaveSettings(filename, data)
	if writefile then
		writefile(filename, game:GetService("HttpService"):JSONEncode(data))
	end
end

local function LoadSettings(filename)
	if readfile and pcall(function() readfile(filename) end) then
		return game:GetService("HttpService"):JSONDecode(readfile(filename))
	end
	return nil
end

-- Library Class
function SakuraUI.new(config)
	local self = {}
	self.Title = config.Title or "Sakura UI"
	self.Theme = config.Theme or "Sakura Light"
	self.Tabs = {}
	self.CurrentTab = nil
	self.Minimized = false
	self.SettingsFile = "SakuraUI_Settings.json"
	
	-- Load or create theme
	self.Colors = self.Theme == "Sakura Dark" and DARK_THEME or LIGHT_THEME
	self:LoadSettings()
	
	-- Create main GUI
	self:CreateMainGUI()
	
	return self
end

function SakuraUI:CreateMainGUI()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SakuraUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	self.ScreenGui = screenGui
	
	-- Main Container
	local mainContainer = CreateRounded("MainContainer", screenGui, UDim2.new(0, SIDEBAR_WIDTH + MAIN_CONTENT_WIDTH, 0, 600), UDim2.new(0.5, -((SIDEBAR_WIDTH + MAIN_CONTENT_WIDTH) / 2), 0.5, -300), self.Colors.Background, 15)
	self.MainContainer = mainContainer
	
	-- Add Shadow Effect
	local shadow = Instance.new("UIStroke")
	shadow.Parent = mainContainer
	shadow.Thickness = 2
	shadow.Color = self.Colors.Border
	shadow.Transparency = 0.3
	
	-- Sidebar
	self:CreateSidebar(mainContainer)
	
	-- Content Area
	self:CreateContentArea(mainContainer)
	
	-- Add Settings Tab automatically
	self:CreateSettingsTab()
end

function SakuraUI:CreateSidebar(parent)
	local sidebar = CreateRounded("Sidebar", parent, UDim2.new(0, SIDEBAR_WIDTH, 1, 0), UDim2.new(0, 0, 0, 0), self.Colors.Secondary, 15)
	self.Sidebar = sidebar
	
	-- Top Section with Logo and Minimize Button
	local topSection = Instance.new("Frame")
	topSection.Name = "TopSection"
	topSection.Parent = sidebar
	topSection.Size = UDim2.new(1, 0, 0, 70)
	topSection.Position = UDim2.new(0, 0, 0, 0)
	topSection.BackgroundTransparency = 1
	
	-- Minimize Button
	local minimizeBtn = CreateRounded("MinimizeBtn", topSection, UDim2.new(0, 30, 0, 30), UDim2.new(0, PADDING, 0.5, -15), self.Colors.Primary, 6)
	local minBtnCorner = Instance.new("UICorner")
	minBtnCorner.CornerRadius = UDim.new(0, 6)
	minBtnCorner.Parent = minimizeBtn
	
	local minBtnText = Instance.new("TextLabel")
	minBtnText.Parent = minimizeBtn
	minBtnText.Size = UDim2.new(1, 0, 1, 0)
	minBtnText.BackgroundTransparency = 1
	minBtnText.Text = "−"
	minBtnText.TextColor3 = Color3.new(1, 1, 1)
	minBtnText.TextSize = 24
	
	minimizeBtn.MouseButton1Click:Connect(function()
		self:ToggleMinimize()
	end)
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Parent = topSection
	titleLabel.Size = UDim2.new(1, -50, 1, 0)
	titleLabel.Position = UDim2.new(0, 45, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = self.Title
	titleLabel.TextColor3 = self.Colors.Text
	titleLabel.TextSize = 18
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	
	-- Tab List Container
	local tabListContainer = Instance.new("ScrollingFrame")
	tabListContainer.Name = "TabListContainer"
	tabListContainer.Parent = sidebar
	tabListContainer.Size = UDim2.new(1, 0, 1, -70)
	tabListContainer.Position = UDim2.new(0, 0, 0, 70)
	tabListContainer.BackgroundTransparency = 1
	tabListContainer.BorderSizePixel = 0
	tabListContainer.ScrollBarThickness = 4
	tabListContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	
	self.TabListContainer = tabListContainer
	
	-- UIListLayout for auto-sizing
	local tabListLayout = Instance.new("UIListLayout")
	tabListLayout.Parent = tabListContainer
	tabListLayout.Padding = UDim.new(0, 5)
	tabListLayout.FillDirection = Enum.FillDirection.Vertical
	
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Parent = tabListContainer
	uiPadding.PaddingLeft = UDim.new(0, PADDING)
	uiPadding.PaddingRight = UDim.new(0, PADDING)
	uiPadding.PaddingTop = UDim.new(0, PADDING)
	uiPadding.PaddingBottom = UDim.new(0, PADDING)
end

function SakuraUI:CreateContentArea(parent)
	local contentArea = CreateRounded("ContentArea", parent, UDim2.new(0, MAIN_CONTENT_WIDTH, 1, 0), UDim2.new(0, SIDEBAR_WIDTH, 0, 0), self.Colors.Background, 0)
	self.ContentArea = contentArea
	
	-- Top Selection Indicator
	local topIndicator = Instance.new("Frame")
	topIndicator.Name = "TopIndicator"
	topIndicator.Parent = contentArea
	topIndicator.Size = UDim2.new(0, 0, 0, 3)
	topIndicator.Position = UDim2.new(0, 0, 0, 0)
	topIndicator.BackgroundColor3 = self.Colors.Primary
	topIndicator.BorderSizePixel = 0
	self.TopIndicator = topIndicator
	
	-- Content Holder
	local contentHolder = Instance.new("Frame")
	contentHolder.Name = "ContentHolder"
	contentHolder.Parent = contentArea
	contentHolder.Size = UDim2.new(1, 0, 1, -3)
	contentHolder.Position = UDim2.new(0, 0, 0, 3)
	contentHolder.BackgroundTransparency = 1
	
	self.ContentHolder = contentHolder
end

function SakuraUI:CreateTab(tabName, icon)
	local tab = {}
	tab.Name = tabName
	tab.Icon = icon or "📁"
	tab.Modules = {}
	tab.LeftSection = nil
	tab.RightSection = nil
	tab.TabButton = nil
	tab.ContentFrame = nil
	
	-- Create Tab Button in Sidebar
	local tabButton = CreateRounded("TabButton", self.TabListContainer, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 0), self.Colors.Hover, 8)
	tab.TabButton = tabButton
	
	local tabButtonText = Instance.new("TextLabel")
	tabButtonText.Parent = tabButton
	tabButtonText.Size = UDim2.new(1, -40, 1, 0)
	tabButtonText.Position = UDim2.new(0, 35, 0, 0)
	tabButtonText.BackgroundTransparency = 1
	tabButtonText.Text = tabName
	tabButtonText.TextColor3 = self.Colors.Text
	tabButtonText.TextSize = 14
	tabButtonText.Font = Enum.Font.Gotham
	tabButtonText.TextXAlignment = Enum.TextXAlignment.Left
	
	local tabIcon = Instance.new("TextLabel")
	tabIcon.Parent = tabButton
	tabIcon.Size = UDim2.new(0, 30, 0, 30)
	tabIcon.Position = UDim2.new(0, 5, 0.5, -15)
	tabIcon.BackgroundTransparency = 1
	tabIcon.Text = tab.Icon
	tabIcon.TextSize = 16
	
	-- Create Content Frame
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = tabName
	contentFrame.Parent = self.ContentHolder
	contentFrame.Size = UDim2.new(1, 0, 1, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Visible = false
	tab.ContentFrame = contentFrame
	
	-- Create Two Column Layout
	local leftSection = Instance.new("ScrollingFrame")
	leftSection.Name = "LeftSection"
	leftSection.Parent = contentFrame
	leftSection.Size = UDim2.new(0.5, -5, 1, 0)
	leftSection.Position = UDim2.new(0, 0, 0, 0)
	leftSection.BackgroundTransparency = 1
	leftSection.BorderSizePixel = 0
	leftSection.ScrollBarThickness = 3
	leftSection.CanvasSize = UDim2.new(0, 0, 0, 0)
	tab.LeftSection = leftSection
	
	local leftLayout = Instance.new("UIListLayout")
	leftLayout.Parent = leftSection
	leftLayout.Padding = UDim.new(0, 10)
	leftLayout.FillDirection = Enum.FillDirection.Vertical
	
	local leftPadding = Instance.new("UIPadding")
	leftPadding.Parent = leftSection
	leftPadding.PaddingLeft = UDim.new(0, PADDING)
	leftPadding.PaddingRight = UDim.new(0, PADDING)
	leftPadding.PaddingTop = UDim.new(0, PADDING)
	
	local rightSection = Instance.new("ScrollingFrame")
	rightSection.Name = "RightSection"
	rightSection.Parent = contentFrame
	rightSection.Size = UDim2.new(0.5, -5, 1, 0)
	rightSection.Position = UDim2.new(0.5, 5, 0, 0)
	rightSection.BackgroundTransparency = 1
	rightSection.BorderSizePixel = 0
	rightSection.ScrollBarThickness = 3
	rightSection.CanvasSize = UDim2.new(0, 0, 0, 0)
	tab.RightSection = rightSection
	
	local rightLayout = Instance.new("UIListLayout")
	rightLayout.Parent = rightSection
	rightLayout.Padding = UDim.new(0, 10)
	rightLayout.FillDirection = Enum.FillDirection.Vertical
	
	local rightPadding = Instance.new("UIPadding")
	rightPadding.Parent = rightSection
	rightPadding.PaddingLeft = UDim.new(0, PADDING)
	rightPadding.PaddingRight = UDim.new(0, PADDING)
	rightPadding.PaddingTop = UDim.new(0, PADDING)
	
	-- Tab Button Click Handler
	tabButton.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)
	
	table.insert(self.Tabs, tab)
	return tab
end

function SakuraUI:AddModule(module, tab)
	-- Determine parent section
	local parent = module.Side == "Right" and tab.RightSection or tab.LeftSection
	
	-- Create Module Container
	local moduleFrame = CreateRounded("ModuleFrame", parent, UDim2.new(1, 0, 0, MODULE_HEADER_HEIGHT), UDim2.new(0, 0, 0, 0), self.Colors.Secondary, 10)
	module.Frame = moduleFrame
	
	-- Add Shadow
	CreateStroke(moduleFrame, 1, self.Colors.Border, 0.5)
	
	-- Header Container
	local headerFrame = Instance.new("Frame")
	headerFrame.Name = "Header"
	headerFrame.Parent = moduleFrame
	headerFrame.Size = UDim2.new(1, 0, 0, MODULE_HEADER_HEIGHT)
	headerFrame.BackgroundTransparency = 1
	
	-- Toggle Button
	local toggleBtn = CreateRounded("ToggleBtn", headerFrame, UDim2.new(0, 20, 0, 20), UDim2.new(1, -30, 0.5, -10), module.Enabled and self.Colors.Primary or self.Colors.Hover, 4)
	
	local toggleLabel = Instance.new("TextLabel")
	toggleLabel.Parent = toggleBtn
	toggleLabel.Size = UDim2.new(1, 0, 1, 0)
	toggleLabel.BackgroundTransparency = 1
	toggleLabel.Text = module.Enabled and "✓" or ""
	toggleLabel.TextColor3 = Color3.new(1, 1, 1)
	toggleLabel.TextSize = 14
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Parent = headerFrame
	titleLabel.Size = UDim2.new(1, -100, 1, 0)
	titleLabel.Position = UDim2.new(0, PADDING, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = module.Title
	titleLabel.TextColor3 = self.Colors.Text
	titleLabel.TextSize = 13
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	
	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Parent = headerFrame
	descLabel.Size = UDim2.new(1, -100, 1, 0)
	descLabel.Position = UDim2.new(0, PADDING, 0, 20)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = module.Description
	descLabel.TextColor3 = self.Colors.Icon
	descLabel.TextSize = 10
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextTransparency = 0.5
	
	-- Content Frame
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.Parent = moduleFrame
	contentFrame.Size = UDim2.new(1, 0, 0, 0)
	contentFrame.Position = UDim2.new(0, 0, 0, MODULE_HEADER_HEIGHT)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Visible = module.Enabled
	module.ContentFrame = contentFrame
	
	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Parent = contentFrame
	contentLayout.Padding = UDim.new(0, 8)
	contentLayout.FillDirection = Enum.FillDirection.Vertical
	
	local contentPadding = Instance.new("UIPadding")
	contentPadding.Parent = contentFrame
	contentPadding.PaddingLeft = UDim.new(0, PADDING)
	contentPadding.PaddingRight = UDim.new(0, PADDING)
	contentPadding.PaddingTop = UDim.new(0, 8)
	contentPadding.PaddingBottom = UDim.new(0, 8)
	
	module.ContentLayout = contentLayout
	
	-- Toggle Functionality
	toggleBtn.MouseButton1Click:Connect(function()
		module.Enabled = not module.Enabled
		self:UpdateModuleState(module, toggleBtn, toggleLabel, moduleFrame, contentFrame, headerFrame)
	end)
	
	-- Add methods to module
	function module:CreateToggle(config)
		return self:AddControl("Toggle", config)
	end
	
	function module:CreateSlider(config)
		return self:AddControl("Slider", config)
	end
	
	function module:CreateDropdown(config)
		return self:AddControl("Dropdown", config)
	end
	
	function module:CreateColorPicker(config)
		return self:AddControl("ColorPicker", config)
	end
	
	function module:CreateButton(config)
		return self:AddControl("Button", config)
	end
	
	function module:CreateLabel(config)
		return self:AddControl("Label", config)
	end
	
	function module:CreateTextbox(config)
		return self:AddControl("Textbox", config)
	end
	
	function module:CreateKeybind(config)
		return self:AddControl("Keybind", config)
	end
	
	function module:CreateDivider()
		return self:AddControl("Divider", {})
	end
	
	function module:AddControl(controlType, config)
		local control = self:CreateControl(controlType, config, self.ContentFrame)
		table.insert(self.Controls, control)
		self:UpdateModuleHeight()
		return control
	end
	
	function module:CreateControl(controlType, config, parent)
		local control = {}
		
		if controlType == "Toggle" then
			control = self:CreateToggleControl(config, parent, self)
		elseif controlType == "Slider" then
			control = self:CreateSliderControl(config, parent, self)
		elseif controlType == "Dropdown" then
			control = self:CreateDropdownControl(config, parent, self)
		elseif controlType == "ColorPicker" then
			control = self:CreateColorPickerControl(config, parent, self)
		elseif controlType == "Button" then
			control = self:CreateButtonControl(config, parent, self)
		elseif controlType == "Label" then
			control = self:CreateLabelControl(config, parent, self)
		elseif controlType == "Textbox" then
			control = self:CreateTextboxControl(config, parent, self)
		elseif controlType == "Keybind" then
			control = self:CreateKeybindControl(config, parent, self)
		elseif controlType == "Divider" then
			control = self:CreateDividerControl(config, parent, self)
		end
		
		return control
	end
	
	function module:CreateToggleControl(config, parent, module)
		local control = {}
		control.Type = "Toggle"
		control.Name = config.Name or "Toggle"
		control.Callback = config.Callback or function() end
		control.Default = config.Default or false
		control.Value = control.Default
		
		local frame = CreateRounded("ToggleControl", parent, UDim2.new(1, 0, 0, 35), UDim2.new(0, 0, 0, 0), self.Colors.Hover, 8)
		control.Frame = frame
		
		local label = Instance.new("TextLabel")
		label.Parent = frame
		label.Size = UDim2.new(1, -50, 1, 0)
		label.Position = UDim2.new(0, PADDING, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = control.Name
		label.TextColor3 = self.Colors.Text
		label.TextSize = 12
		label.Font = Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		
		local toggleBox = CreateRounded("ToggleBox", frame, UDim2.new(0, 30, 0, 18), UDim2.new(1, -40, 0.5, -9), self.Colors.Secondary, 4)
		
		local toggleCircle = CreateRounded("Circle", toggleBox, UDim2.new(0, 14, 0, 14), control.Value and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), Color3.new(1, 1, 1), 7)
		control.Circle = toggleCircle
		
		frame.MouseButton1Click:Connect(function()
			control.Value = not control.Value
			local newPos = control.Value and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
			Tween(toggleCircle, TweenInfo.new(ANIMATION_SPEED), {Position = newPos})
			Tween(toggleBox, TweenInfo.new(ANIMATION_SPEED), {BackgroundColor3 = control.Value and self.Colors.Primary or self.Colors.Secondary})
			control.Callback(control.Value)
		end)
		
		return control
	end
	
	function module:CreateSliderControl(config, parent, module)
		local control = {}
		control.Type = "Slider"
		control.Name = config.Name or "Slider"
		control.Callback = config.Callback or function() end
		control.Min = config.Min or 0
		control.Max = config.Max or 100
		control.Default = config.Default or 50
		control.Value = control.Default
		
		local frame = CreateRounded("SliderControl", parent, UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0, 0), self.Colors.Hover, 8)
		control.Frame = frame
		
		local label = Instance.new("TextLabel")
		label.Parent = frame
		label.Size = UDim2.new(0.5, 0, 0, 20)
		label.Position = UDim2.new(0, PADDING, 0, PADDING)
		label.BackgroundTransparency = 1
		label.Text = control.Name
		label.TextColor3 = self.Colors.Text
		label.TextSize = 12
		label.Font = Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Parent = frame
		valueLabel.Size = UDim2.new(0.5, 0, 0, 20)
		valueLabel.Position = UDim2.new(0.5, 0, 0, PADDING)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = tostring(math.floor(control.Value))
		valueLabel.TextColor3 = self.Colors.Icon
		valueLabel.TextSize = 11
		valueLabel.Font = Enum.Font.Gotham
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		
		local sliderBg = CreateRounded("SliderBg", frame, UDim2.new(1, -2*PADDING, 0, 6), UDim2.new(0, PADDING, 0, 35), self.Colors.Secondary, 3)
		
		local sliderFill = CreateRounded("SliderFill", sliderBg, UDim2.new((control.Value - control.Min) / (control.Max - control.Min), 0, 1, 0), UDim2.new(0, 0, 0, 0), self.Colors.Primary, 3)
		control.Fill = sliderFill
		
		local sliderKnob = CreateRounded("Knob", frame, UDim2.new(0, 14, 0, 14), UDim2.new(0, PADDING + ((control.Value - control.Min) / (control.Max - control.Min)) * (sliderBg.AbsoluteSize.X - 14) - 7, 0, 30), self.Colors.Primary, 7)
		control.Knob = sliderKnob
		
		local dragging = false
		
		sliderKnob.MouseButton1Down:Connect(function()
			dragging = true
		end)
		
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
		
		UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local mouseX = UserInputService:GetMouseLocation().X
				local sliderX = sliderBg.AbsolutePosition.X
				local sliderWidth = sliderBg.AbsoluteSize.X
				
				local percentage = math.clamp((mouseX - sliderX) / sliderWidth, 0, 1)
				control.Value = control.Min + (control.Max - control.Min) * percentage
				
				valueLabel.Text = tostring(math.floor(control.Value))
				
				Tween(sliderFill, TweenInfo.new(0.1), {Size = UDim2.new(percentage, 0, 1, 0)})
				Tween(sliderKnob, TweenInfo.new(0.1), {Position = UDim2.new(0, sliderX + percentage * sliderWidth - 7, 0, 30)})
				
				control.Callback(control.Value)
			end
		end)
		
		return control
	end
	
	function module:CreateDropdownControl(config, parent, module)
		local control = {}
		control.Type = "Dropdown"
		control.Name = config.Name or "Dropdown"
		control.Options = config.Options or {}
		control.Callback = config.Callback or function() end
		control.Default = config.Default or control.Options[1] or ""
		control.Value = control.Default
		control.Open = false
		
		local frame = CreateRounded("DropdownControl", parent, UDim2.new(1, 0, 0, 35), UDim2.new(0, 0, 0, 0), self.Colors.Hover, 8)
		control.Frame = frame
		
		local label = Instance.new("TextLabel")
		label.Parent = frame
		label.Size = UDim2.new(0.5, 0, 1, 0)
		label.Position = UDim2.new(0, PADDING, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = control.Name
		label.TextColor3 = self.Colors.Text
		label.TextSize = 12
		label.Font = Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		
		local valueBtn = CreateRounded("ValueBtn", frame, UDim2.new(0.4, -PADDING, 0.6, 0), UDim2.new(1, -0.4*frame.AbsoluteSize.X - PADDING, 0.2, 0), self.Colors.Secondary, 6)
		
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Parent = valueBtn
		valueLabel.Size = UDim2.new(1, 0, 1, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = control.Value
		valueLabel.TextColor3 = self.Colors.Text
		valueLabel.TextSize = 11
		valueLabel.Font = Enum.Font.Gotham
		valueLabel.TextXAlignment = Enum.TextXAlignment.Center
		
		-- Dropdown List
		local dropdownList = Instance.new("ScrollingFrame")
		dropdownList.Name = "DropdownList"
		dropdownList.Parent = frame
		dropdownList.Size = UDim2.new(0.4, -PADDING, 0, 0)
		dropdownList.Position = UDim2.new(1, -0.4*frame.AbsoluteSize.X - PADDING, 1, 5)
		dropdownList.BackgroundColor3 = self.Colors.Secondary
		dropdownList.BorderSizePixel = 0
		dropdownList.ScrollBarThickness = 2
		dropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
		dropdownList.Visible = false
		control.DropdownList = dropdownList
		
		local dropdownCorner = Instance.new("UICorner")
		dropdownCorner.CornerRadius = UDim.new(0, 6)
		dropdownCorner.Parent = dropdownList
		
		CreateStroke(dropdownList, 1, self.Colors.Border, 0.5)
		
		local dropdownLayout = Instance.new("UIListLayout")
		dropdownLayout.Parent = dropdownList
		dropdownLayout.Padding = UDim.new(0, 2)
		dropdownLayout.FillDirection = Enum.FillDirection.Vertical
		
		for _, option in ipairs(control.Options) do
			local optionBtn = CreateRounded("OptionBtn", dropdownList, UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 0), self.Colors.Secondary, 0)
			
			local optionLabel = Instance.new("TextLabel")
			optionLabel.Parent = optionBtn
			optionLabel.Size = UDim2.new(1, 0, 1, 0)
			optionLabel.BackgroundTransparency = 1
			optionLabel.Text = option
			optionLabel.TextColor3 = self.Colors.Text
			optionLabel.TextSize = 11
			optionLabel.Font = Enum.Font.Gotham
			
			optionBtn.MouseButton1Click:Connect(function()
				control.Value = option
				valueLabel.Text = option
				control.Open = false
				Tween(dropdownList, TweenInfo.new(ANIMATION_SPEED), {Size = UDim2.new(0.4, -PADDING, 0, 0)})
				dropdownList.Visible = false
				control.Callback(option)
			end)
			
			optionBtn.MouseEnter:Connect(function()
				Tween(optionBtn, TweenInfo.new(0.1), {BackgroundColor3 = self.Colors.Hover})
			end)
			
			optionBtn.MouseLeave:Connect(function()
				Tween(optionBtn, TweenInfo.new(0.1), {BackgroundColor3 = self.Colors.Secondary})
			end)
		end
		
		valueBtn.MouseButton1Click:Connect(function()
			control.Open = not control.Open
			if control.Open then
				dropdownList.Visible = true
				local listHeight = math.min(#control.Options * 25 + 4, 150)
				Tween(dropdownList, TweenInfo.new(ANIMATION_SPEED), {Size = UDim2.new(0.4, -PADDING, 0, listHeight)})
				dropdownList.CanvasSize = UDim2.new(0, 0, 0, #control.Options * 25 + 4)
			else
				Tween(dropdownList, TweenInfo.new(ANIMATION_SPEED), {Size = UDim2.new(0.4, -PADDING, 0, 0)})
				dropdownList.Visible = false
			end
		end)
		
		return control
	end
	
	function module:CreateColorPickerControl(config, parent, module)
		local control = {}
		control.Type = "ColorPicker"
		control.Name = config.Name or "Color"
		control.Callback = config.Callback or function() end
		control.Default = config.Default or Color3.new(1, 0, 0)
		control.Value = control.Default
		
		local frame = CreateRounded("ColorPickerControl", parent, UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 0), self.Colors.Hover, 8)
		control.Frame = frame
		
		local label = Instance.new("TextLabel")
		label.Parent = frame
		label.Size = UDim2.new(0.6, 0, 0, 20)
		label.Position = UDim2.new(0, PADDING, 0, PADDING)
		label.BackgroundTransparency = 1
		label.Text = control.Name
		label.TextColor3 = self.Colors.Text
		label.TextSize = 12
		label.Font = Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		
		local colorBox = CreateRounded("ColorBox", frame, UDim2.new(0.3, -PADDING, 0, 20), UDim2.new(1, -0.3*frame.AbsoluteSize.X - 2*PADDING, 0, PADDING), control.Value, 6)
		control.ColorBox = colorBox
		
		-- HSV Picker Area
		local pickerArea = CreateRounded("PickerArea", frame, UDim2.new(1, -2*PADDING, 0, 25), UDim2.new(0, PADDING, 0, 30), Color3.new(1, 1, 1), 4)
		control.PickerArea = pickerArea
		pickerArea.Visible = false
		
		-- Hue Bar
		local hueBar = CreateRounded("HueBar", pickerArea, UDim2.new(0.15, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.new(1, 0, 0), 3)
		
		colorBox.MouseButton1Click:Connect(function()
			-- Toggle picker visibility
			pickerArea.Visible = not pickerArea.Visible
		end)
		
		return control
	end
	
	function module:CreateButtonControl(config, parent, module)
		local control = {}
		control.Type = "Button"
		control.Name = config.Name or "Button"
		control.Callback = config.Callback or function() end
		
		local btn = CreateRounded("ButtonControl", parent, UDim2.new(1, 0, 0, 35), UDim2.new(0, 0, 0, 0), self.Colors.Primary, 8)
		control.Frame = btn
		
		local btnLabel = Instance.new("TextLabel")
		btnLabel.Parent = btn
		btnLabel.Size = UDim2.new(1, 0, 1, 0)
		btnLabel.BackgroundTransparency = 1
		btnLabel.Text = control.Name
		btnLabel.TextColor3 = Color3.new(1, 1, 1)
		btnLabel.TextSize = 12
		btnLabel.Font = Enum.Font.GothamBold
		
		btn.MouseButton1Click:Connect(function()
			control.Callback()
		end)
		
		btn.MouseEnter:Connect(function()
			Tween(btn, TweenInfo.new(0.1), {BackgroundColor3 = self.Colors.Hover})
		end)
		
		btn.MouseLeave:Connect(function()
			Tween(btn, TweenInfo.new(0.1), {BackgroundColor3 = self.Colors.Primary})
		end)
		
		return control
	end
	
	function module:CreateLabelControl(config, parent, module)
		local control = {}
		control.Type = "Label"
		control.Name = config.Name or "Label"
		
		local labelFrame = Instance.new("Frame")
		labelFrame.Name = "LabelControl"
		labelFrame.Parent = parent
		labelFrame.Size = UDim2.new(1, 0, 0, 25)
		labelFrame.BackgroundTransparency = 1
		control.Frame = labelFrame
		
		local label = Instance.new("TextLabel")
		label.Parent = labelFrame
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = control.Name
		label.TextColor3 = self.Colors.Text
		label.TextSize = 12
		label.Font = Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		
		return control
	end
	
	function module:CreateTextboxControl(config, parent, module)
		local control = {}
		control.Type = "Textbox"
		control.Name = config.Name or "Textbox"
		control.Callback = config.Callback or function() end
		control.Default = config.Default or ""
		control.Value = control.Default
		
		local frame = CreateRounded("TextboxControl", parent, UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 0), self.Colors.Hover, 8)
		control.Frame = frame
		
		local label = Instance.new("TextLabel")
		label.Parent = frame
		label.Size = UDim2.new(1, 0, 0, 20)
		label.Position = UDim2.new(0, PADDING, 0, PADDING)
		label.BackgroundTransparency = 1
		label.Text = control.Name
		label.TextColor3 = self.Colors.Text
		label.TextSize = 12
		label.Font = Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		
		local textbox = Instance.new("TextBox")
		textbox.Parent = frame
		textbox.Size = UDim2.new(1, -2*PADDING, 0, 20)
		textbox.Position = UDim2.new(0, PADDING, 0, 30)
		textbox.BackgroundColor3 = self.Colors.Secondary
		textbox.TextColor3 = self.Colors.Text
		textbox.Text = control.Default
		textbox.TextSize = 11
		textbox.Font = Enum.Font.Gotham
		textbox.BorderSizePixel = 0
		
		local textboxCorner = Instance.new("UICorner")
		textboxCorner.CornerRadius = UDim.new(0, 6)
		textboxCorner.Parent = textbox
		
		textbox.FocusLost:Connect(function()
			control.Value = textbox.Text
			control.Callback(control.Value)
		end)
		
		return control
	end
	
	function module:CreateKeybindControl(config, parent, module)
		local control = {}
		control.Type = "Keybind"
		control.Name = config.Name or "Keybind"
		control.Callback = config.Callback or function() end
		control.Default = config.Default or Enum.KeyCode.F
		control.Value = control.Default
		control.Listening = false
		
		local frame = CreateRounded("KeybindControl", parent, UDim2.new(1, 0, 0, 35), UDim2.new(0, 0, 0, 0), self.Colors.Hover, 8)
		control.Frame = frame
		
		local label = Instance.new("TextLabel")
		label.Parent = frame
		label.Size = UDim2.new(0.5, 0, 1, 0)
		label.Position = UDim2.new(0, PADDING, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = control.Name
		label.TextColor3 = self.Colors.Text
		label.TextSize = 12
		label.Font = Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		
		local keybindBtn = CreateRounded("KeybindBtn", frame, UDim2.new(0.35, -PADDING, 0.6, 0), UDim2.new(1, -0.35*frame.AbsoluteSize.X - PADDING, 0.2, 0), self.Colors.Primary, 6)
		
		local keybindLabel = Instance.new("TextLabel")
		keybindLabel.Parent = keybindBtn
		keybindLabel.Size = UDim2.new(1, 0, 1, 0)
		keybindLabel.BackgroundTransparency = 1
		keybindLabel.Text = control.Value.Name
		keybindLabel.TextColor3 = Color3.new(1, 1, 1)
		keybindLabel.TextSize = 11
		keybindLabel.Font = Enum.Font.Gotham
		keybindLabel.TextXAlignment = Enum.TextXAlignment.Center
		
		keybindBtn.MouseButton1Click:Connect(function()
			control.Listening = true
			keybindLabel.Text = "..."
		end)
		
		UserInputService.InputBegan:Connect(function(input)
			if control.Listening then
				control.Value = input.KeyCode
				keybindLabel.Text = control.Value.Name
				control.Listening = false
			end
		end)
		
		return control
	end
	
	function module:CreateDividerControl(config, parent, module)
		local control = {}
		control.Type = "Divider"
		
		local divider = Instance.new("Frame")
		divider.Name = "Divider"
		divider.Parent = parent
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.BackgroundColor3 = self.Colors.Border
		divider.BorderSizePixel = 0
		control.Frame = divider
		
		return control
	end
	
	function module:UpdateModuleHeight()
		local totalHeight = MODULE_HEADER_HEIGHT
		
		for _, control in ipairs(self.Controls) do
			if control.Frame then
				totalHeight = totalHeight + control.Frame.AbsoluteSize.Y + 10
			end
		end
		
		Tween(self.Frame, TweenInfo.new(ANIMATION_SPEED), {Size = UDim2.new(1, 0, 0, totalHeight)})
		Tween(self.ContentFrame, TweenInfo.new(ANIMATION_SPEED), {Size = UDim2.new(1, 0, 0, totalHeight - MODULE_HEADER_HEIGHT)})
	end
	
	table.insert(tab.Modules, module)
	module.Controls = {}
	module.Parent = self
end

function SakuraUI:UpdateModuleState(module, toggleBtn, toggleLabel, moduleFrame, contentFrame, headerFrame)
	if module.Enabled then
		toggleLabel.Text = "✓"
		Tween(toggleBtn, TweenInfo.new(ANIMATION_SPEED), {BackgroundColor3 = self.Colors.Primary})
		contentFrame.Visible = true
		local contentHeight = contentFrame.AbsoluteSize.Y
		Tween(moduleFrame, TweenInfo.new(ANIMATION_SPEED), {Size = UDim2.new(1, 0, 0, MODULE_HEADER_HEIGHT + contentHeight)})
	else
		toggleLabel.Text = ""
		Tween(toggleBtn, TweenInfo.new(ANIMATION_SPEED), {BackgroundColor3 = self.Colors.Hover})
		Tween(moduleFrame, TweenInfo.new(ANIMATION_SPEED), {Size = UDim2.new(1, 0, 0, MODULE_HEADER_HEIGHT)})
		contentFrame.Visible = false
	end
end

function SakuraUI:SelectTab(tab)
	if self.CurrentTab then
		self.CurrentTab.ContentFrame.Visible = false
		Tween(self.CurrentTab.TabButton, TweenInfo.new(ANIMATION_SPEED), {BackgroundColor3 = self.Colors.Hover})
	end
	
	self.CurrentTab = tab
	tab.ContentFrame.Visible = true
	Tween(tab.TabButton, TweenInfo.new(ANIMATION_SPEED), {BackgroundColor3 = self.Colors.Primary})
	Tween(self.TopIndicator, TweenInfo.new(ANIMATION_SPEED), {Size = UDim2.new(0, tab.TabButton.AbsoluteSize.X - 10, 0, 3)})
end

function SakuraUI:ToggleMinimize()
	self.Minimized = not self.Minimized
	
	if self.Minimized then
		Tween(self.MainContainer, TweenInfo.new(ANIMATION_SPEED), {Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0)})
		Tween(self.ContentArea, TweenInfo.new(ANIMATION_SPEED), {Size = UDim2.new(0, 0, 1, 0)})
	else
		Tween(self.MainContainer, TweenInfo.new(ANIMATION_SPEED), {Size = UDim2.new(0, SIDEBAR_WIDTH + MAIN_CONTENT_WIDTH, 1, 0)})
		Tween(self.ContentArea, TweenInfo.new(ANIMATION_SPEED), {Size = UDim2.new(0, MAIN_CONTENT_WIDTH, 1, 0)})
	end
end

function SakuraUI:CreateSettingsTab()
	local settingsTab = self:CreateTab("Settings", "⚙️")
	
	local settingsModule = settingsTab:CreateModule({
		Title = "Appearance",
		Description = "Customize UI colors",
		Side = "Left"
	})
	
	-- Primary Color Picker
	settingsModule:CreateColorPicker({
		Name = "Primary Color",
		Default = self.Colors.Primary,
		Callback = function(color)
			self.Colors.Primary = color
			self:ApplyTheme()
		end
	})
	
	-- Background Color Picker
	settingsModule:CreateColorPicker({
		Name = "Background",
		Default = self.Colors.Background,
		Callback = function(color)
			self.Colors.Background = color
			self:ApplyTheme()
		end
	})
	
	-- Border Color Picker
	settingsModule:CreateColorPicker({
		Name = "Border Color",
		Default = self.Colors.Border,
		Callback = function(color)
			self.Colors.Border = color
			self:ApplyTheme()
		end
	})
	
	-- Text Color Picker
	settingsModule:CreateColorPicker({
		Name = "Text Color",
		Default = self.Colors.Text,
		Callback = function(color)
			self.Colors.Text = color
			self:ApplyTheme()
		end
	})
	
	-- Theme Selector
	local themeModule = settingsTab:CreateModule({
		Title = "Themes",
		Description = "Select a theme",
		Side = "Right"
	})
	
	themeModule:CreateButton({
		Name = "Sakura Light",
		Callback = function()
			self.Colors = LIGHT_THEME
			self.Theme = "Sakura Light"
			self:ApplyTheme()
			self:SaveSettings()
		end
	})
	
	themeModule:CreateButton({
		Name = "Sakura Dark",
		Callback = function()
			self.Colors = DARK_THEME
			self.Theme = "Sakura Dark"
			self:ApplyTheme()
			self:SaveSettings()
		end
	})
	
	-- Save Settings
	themeModule:CreateButton({
		Name = "Save Settings",
		Callback = function()
			self:SaveSettings()
		end
	})
end

function SakuraUI:ApplyTheme()
	-- Update main container colors
	self.MainContainer.BackgroundColor3 = self.Colors.Background
	
	-- Update sidebar colors
	self.Sidebar.BackgroundColor3 = self.Colors.Secondary
	
	-- Update content area colors
	self.ContentArea.BackgroundColor3 = self.Colors.Background
	self.TopIndicator.BackgroundColor3 = self.Colors.Primary
	
	-- Update shadow
	for _, child in pairs(self.MainContainer:GetChildren()) do
		if child:IsA("UIStroke") then
			child.Color = self.Colors.Border
		end
	end
	
	-- Update all tab buttons
	for _, tab in ipairs(self.Tabs) do
		if tab.TabButton then
			if tab == self.CurrentTab then
				tab.TabButton.BackgroundColor3 = self.Colors.Primary
			else
				tab.TabButton.BackgroundColor3 = self.Colors.Hover
			end
			
			-- Update tab button text colors
			for _, child in pairs(tab.TabButton:GetChildren()) do
				if child:IsA("TextLabel") then
					child.TextColor3 = self.Colors.Text
				end
			end
		end
		
		-- Update modules in tab
		for _, module in ipairs(tab.Modules) do
			if module.Frame then
				module.Frame.BackgroundColor3 = self.Colors.Secondary
				
				-- Update module header
				local headerFrame = module.Frame:FindFirstChild("Header")
				if headerFrame then
					for _, child in pairs(headerFrame:GetChildren()) do
						if child:IsA("TextLabel") then
							if child.Name == "Title" then
								child.TextColor3 = self.Colors.Text
							elseif child.Name == "Description" then
								child.TextColor3 = self.Colors.Icon
							end
						elseif child:IsA("Frame") and child.Name == "ToggleBtn" then
							child.BackgroundColor3 = module.Enabled and self.Colors.Primary or self.Colors.Hover
						end
					end
				end
				
				-- Update content frame
				if module.ContentFrame then
					for _, control in pairs(module.ContentFrame:GetChildren()) do
						if control:IsA("Frame") then
							control.BackgroundColor3 = self.Colors.Hover
							
							-- Update nested labels
							for _, label in pairs(control:GetChildren()) do
								if label:IsA("TextLabel") and label.Name ~= "UICorner" then
									if not label.BackgroundTransparency or label.BackgroundTransparency < 1 then
										label.BackgroundColor3 = self.Colors.Hover
									end
									label.TextColor3 = self.Colors.Text
								end
							end
						end
					end
				end
			end
		end
	end
end

function SakuraUI:SaveSettings()
	local settings = {
		Theme = self.Theme,
		Colors = {
			Primary = self.Colors.Primary,
			Background = self.Colors.Background,
			Border = self.Colors.Border,
			Text = self.Colors.Text,
			Icon = self.Colors.Icon,
			Secondary = self.Colors.Secondary,
			Hover = self.Colors.Hover,
		}
	}
	SaveSettings(self.SettingsFile, settings)
end

function SakuraUI:LoadSettings()
	local saved = LoadSettings(self.SettingsFile)
	if saved then
		self.Theme = saved.Theme or self.Theme
		if saved.Colors then
			self.Colors = saved.Colors
		end
	end
end

return SakuraUI

