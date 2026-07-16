--[[
    Bobit UI Library (merged build)
    ------------------------------------------------
    Visuals: 100% Bobit (black/blue theme, topbar shimmer, sidebar tabs,
             minimize-to-mini, draggable window, rounded corners/strokes).
    Logic:   Ported from Sakura UI's architecture -
             - Expandable "Module" boxes (header + auto-resizing body)
             - Master enable-toggle + optional Keybind per module
             - Rich sub-controls inside a module: Label, Paragraph,
               Divider, Button, Toggle, Slider, Dropdown, Textbox, Keybind
             - JSON settings persistence (writefile/readfile, guarded)
    No Sakura visuals are used anywhere - every color/shape below is Bobit's.
--]]

local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library

----------------------------------------------------------------
-- SCALING (Bobit)
----------------------------------------------------------------
local function getMobileScale()
    local viewport = workspace.CurrentCamera.ViewportSize
    local isMobile = UIS.TouchEnabled and viewport.X < 1024
    if isMobile then
        return 0.8
    end
    return 1
end

local scale = getMobileScale()

local BASE_W, BASE_H = 580, 340
local BASE_MINI_W, BASE_MINI_H = 135, 42

local FullSize = UDim2.new(0, BASE_W * scale, 0, BASE_H * scale)
local MiniSize = UDim2.new(0, BASE_MINI_W * scale, 0, BASE_MINI_H * scale)

local function s(n)
    return math.round(n * scale)
end

----------------------------------------------------------------
-- SMALL HELPERS (glue code, not a "style")
----------------------------------------------------------------
local function New(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    if parent then inst.Parent = parent end
    return inst
end

local function Round(inst, radius)
    return New("UICorner", {CornerRadius = UDim.new(0, radius)}, inst)
end

local function Stroke(inst, thickness, transparency)
    return New("UIStroke", {
        Color = Color3.fromRGB(0, 80, 255),
        Thickness = thickness or 1.2,
        Transparency = transparency or 0.6,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, inst)
end

local function Tween(inst, props, dur, style)
    local tw = TweenService:Create(inst, TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quart), props)
    tw:Play()
    return tw
end

----------------------------------------------------------------
-- SETTINGS PERSISTENCE (logic ported from Sakura)
----------------------------------------------------------------
local SETTINGS_FOLDER = "BobitUI"
local SETTINGS_FILE = "BobitUI/Settings.json"

local function SaveJSON(data)
    local ok = pcall(function()
        if not isfolder or not isfolder(SETTINGS_FOLDER) then
            if makefolder then makefolder(SETTINGS_FOLDER) end
        end
        writefile(SETTINGS_FILE, HttpService:JSONEncode(data))
    end)
    return ok
end

local function LoadJSON()
    local result
    pcall(function()
        if isfile and isfile(SETTINGS_FILE) then
            result = HttpService:JSONDecode(readfile(SETTINGS_FILE))
        end
    end)
    return result
end

----------------------------------------------------------------
-- WINDOW (Bobit visuals)
----------------------------------------------------------------
function Library:CreateWindow(config)
    config = config or {}
    local Window = {}
    Window.Tabs = {}
    Window.FirstTab = nil
    Window.Flags = {} -- Sakura-style flag store for settings persistence

    local ParentUI
    local success, coregui = pcall(function() return game:GetService("CoreGui") end)
    if success and coregui then
        ParentUI = coregui
    else
        ParentUI = LocalPlayer:WaitForChild("PlayerGui")
    end

    local OldUI = ParentUI:FindFirstChild("Bobit_UI")
    if OldUI then OldUI:Destroy() end

    local ScreenGui = New("ScreenGui", {Name = "Bobit_UI", ResetOnSpawn = false}, ParentUI)

    local MainFrame = New("Frame", {
        Name = "MainFrame",
        BackgroundColor3 = Color3.fromRGB(15, 15, 18),
        Position = UDim2.new(0.5, -s(BASE_W / 2), 0.5, -s(BASE_H / 2)),
        Size = FullSize,
        BorderSizePixel = 0,
        Active = true,
        ClipsDescendants = false,
    }, ScreenGui)
    Round(MainFrame, s(14))
    Stroke(MainFrame, 1.5, 0)

    local Topbar = New("Frame", {
        Name = "Topbar",
        BackgroundColor3 = Color3.fromRGB(22, 22, 26),
        Size = UDim2.new(1, 0, 0, s(42)),
        BorderSizePixel = 0,
    }, MainFrame)
    Round(Topbar, s(14))

    local Title = New("TextLabel", {
        Text = config.Title or "Bobit Free",
        TextColor3 = Color3.fromRGB(0, 120, 255),
        Font = Enum.Font.GothamBold,
        TextSize = s(15),
        Size = UDim2.new(0, s(140), 1, 0),
        Position = UDim2.new(0, s(17), 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
    }, Topbar)

    local Shimmer = New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 80, 80)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 120, 255)),
        }),
    }, Title)

    task.spawn(function()
        while ScreenGui.Parent do
            local tween = TweenService:Create(Shimmer, TweenInfo.new(2, Enum.EasingStyle.Linear), {Offset = Vector2.new(1, 0)})
            Shimmer.Offset = Vector2.new(-1, 0)
            tween:Play()
            tween.Completed:Wait()
        end
    end)

    local MinBtn = New("ImageButton", {
        Name = "MinBtn",
        BackgroundColor3 = Color3.fromRGB(35, 35, 40),
        Size = UDim2.new(0, s(26), 0, s(26)),
        Position = UDim2.new(1, -s(35), 0.5, -s(13)),
        ZIndex = 3,
        Image = "rbxassetid://74409172057180",
        ScaleType = Enum.ScaleType.Fit,
    }, Topbar)
    Round(MinBtn, s(8))

    local TopOverlap = New("Frame", {
        Name = "TopOverlap",
        BackgroundColor3 = Color3.fromRGB(22, 22, 26),
        Size = UDim2.new(1, 0, 0, s(6)),
        Position = UDim2.new(0, 0, 0, s(36)),
        BorderSizePixel = 0,
        ZIndex = 0,
    }, MainFrame)

    -- Drag (Bobit)
    local dragging, dragStart, startPos, dragTouchObject
    Topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = MainFrame.Position; dragTouchObject = input
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input == dragTouchObject then
            local delta = input.Position - dragStart
            local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            Tween(MainFrame, {Position = targetPos}, 0.4, Enum.EasingStyle.Quart)
        end
    end)

    local SidebarWidth = s(120)
    local Container = New("Frame", {
        Size = UDim2.new(1, -2, 1, -s(44)),
        Position = UDim2.new(0, 1, 0, s(43)),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, MainFrame)

    local Sidebar = New("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, SidebarWidth, 1, 0),
        BackgroundTransparency = 1,
    }, Container)
    New("UIListLayout", {
        Padding = UDim.new(0, s(5)),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, Sidebar)
    New("UIPadding", {PaddingTop = UDim.new(0, s(10))}, Sidebar)

    local Pages = New("Frame", {
        Name = "Pages",
        Size = UDim2.new(1, -SidebarWidth, 1, -2),
        Position = UDim2.new(0, SidebarWidth, 0, 1),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, Container)

    New("Frame", {
        BackgroundColor3 = Color3.fromRGB(0, 80, 255),
        BackgroundTransparency = 0.8,
        Position = UDim2.new(0, SidebarWidth, 0, s(10)),
        Size = UDim2.new(0, 1, 1, -s(20)),
        BorderSizePixel = 0,
    }, Container)

    local isMainOpen = true
    MinBtn.MouseButton1Click:Connect(function()
        isMainOpen = not isMainOpen
        Tween(MainFrame, {Size = isMainOpen and FullSize or MiniSize}, 0.5)
        Container.Visible = isMainOpen
        TopOverlap.Visible = isMainOpen
    end)

    Window.ScreenGui = ScreenGui
    Window.MainFrame = MainFrame
    Window.Sidebar = Sidebar
    Window.Pages = Pages

    ------------------------------------------------------------
    -- SETTINGS LOGIC (Sakura) - hooked onto the window
    ------------------------------------------------------------
    function Window:SaveSettings()
        return SaveJSON(self.Flags)
    end

    function Window:LoadSettings()
        local saved = LoadJSON()
        if not saved then return false end
        for flag, value in pairs(saved) do
            self.Flags[flag] = value
            local setter = self._FlagSetters and self._FlagSetters[flag]
            if setter then setter(value) end
        end
        return true
    end
    Window._FlagSetters = {}

    local function registerFlag(win, flag, setter, default)
        if not flag then return end
        win._FlagSetters[flag] = setter
        if win.Flags[flag] == nil then
            win.Flags[flag] = default
        end
    end

    ------------------------------------------------------------
    -- TAB (Bobit visuals)
    ------------------------------------------------------------
    
function Window:CreateTab(title)
    if type(title)=="string" then
        return self:Tab({Title=title})
    else
        return self:Tab(title)
    end
end

function Window:Tab(config)
        config = config or {}
        local Tab = {}
        local tabName = config.Title or "Tab"
        local imageId = config.Icon or "rbxassetid://76499042599127"

        local TabBtn = New("TextButton", {
            Name = tabName .. "_Tab",
            Size = UDim2.new(0.9, 0, 0, s(35)),
            BackgroundColor3 = Color3.fromRGB(15, 15, 18),
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = #Window.Tabs + 1,
        }, Sidebar)
        Round(TabBtn, s(6))

        local Indicator = New("Frame", {
            Name = "Indicator",
            Size = UDim2.new(0, s(2), 0, s(16)),
            Position = UDim2.new(0, s(6), 0.5, -s(8)),
            BackgroundColor3 = Color3.fromRGB(0, 80, 255),
            BorderSizePixel = 0,
            Visible = false,
        }, TabBtn)
        Round(Indicator, s(999))

        local TabIcon = New("ImageLabel", {
            Size = UDim2.new(0, s(18), 0, s(18)),
            Position = UDim2.new(0, s(16), 0.5, -s(9)),
            BackgroundTransparency = 1,
            Image = imageId,
            ImageColor3 = Color3.fromRGB(150, 150, 150),
        }, TabBtn)

        local TabText = New("TextLabel", {
            Text = tabName,
            Size = UDim2.new(1, -s(40), 1, 0),
            Position = UDim2.new(0, s(40), 0, 0),
            TextColor3 = Color3.fromRGB(150, 150, 150),
            Font = Enum.Font.GothamBold,
            TextSize = s(11),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, TabBtn)

        local function UpdateTabVisuals(selected)
            local accent = selected and Color3.fromRGB(0, 80, 255) or Color3.fromRGB(150, 150, 150)
            local bg = selected and Color3.fromRGB(17, 17, 22) or Color3.fromRGB(15, 15, 18)
            Tween(TabBtn, {BackgroundColor3 = bg}, 0.2)
            Tween(TabIcon, {ImageColor3 = accent}, 0.2)
            Tween(TabText, {TextColor3 = accent}, 0.2)
            Indicator.Visible = selected
        end

        local Page = New("Frame", {
            Name = tabName .. "_Page",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
        }, Pages)

        local LeftCol = New("ScrollingFrame", {
            Name = "Left",
            Size = UDim2.new(0.5, -s(12), 1, 0),
            Position = UDim2.new(0, s(6), 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            ScrollBarImageTransparency = 1,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
        }, Page)

        local RightCol = New("ScrollingFrame", {
            Name = "Right",
            Size = UDim2.new(0.5, -s(12), 1, 0),
            Position = UDim2.new(0.5, s(6), 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            ScrollBarImageTransparency = 1,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
        }, Page)

        for _, col in ipairs({LeftCol, RightCol}) do
            New("UIListLayout", {
                Padding = UDim.new(0, s(12)),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, col)
            New("UIPadding", {PaddingTop = UDim.new(0, s(15))}, col)
        end

        TabBtn.MouseButton1Click:Connect(function()
            for _, v in pairs(Window.Tabs) do
                v.Page.Visible = false
                v.Update(false)
            end
            Page.Visible = true
            UpdateTabVisuals(true)
        end)

        Window.Tabs[#Window.Tabs + 1] = {Btn = TabBtn, Page = Page, Update = UpdateTabVisuals, Name = tabName}

        if not Window.FirstTab then
            Window.FirstTab = tabName
            Page.Visible = true
            UpdateTabVisuals(true)
        end

        Tab.LeftCol = LeftCol
        Tab.RightCol = RightCol

        function Tab:GetSide(section)
            if section and section:lower() == "right" then return self.RightCol end
            return self.LeftCol
        end

        --------------------------------------------------------
        -- MODULE (Sakura logic, Bobit visuals) - expandable box
        --------------------------------------------------------
        function Tab:CreateModule(mConfig)
            mConfig = mConfig or {}
            local parent = self:GetSide(mConfig.Section)
            local HEADER_H, DIVIDER_H = s(40), s(7)

            local ModuleFrame = New("Frame", {
                BackgroundColor3 = Color3.fromRGB(20, 20, 24),
                Size = UDim2.new(0.94, 0, 0, HEADER_H),
                ClipsDescendants = true,
            }, parent)
            Round(ModuleFrame, s(14))
            Stroke(ModuleFrame, 1.2, 0.6)

            local Header = New("Frame", {
                Size = UDim2.new(0.94, 0, 0, HEADER_H),
                BackgroundTransparency = 1,
            }, ModuleFrame)

            local hasKeybind = mConfig.Keybind ~= nil
            local titleWidth = hasKeybind and s(150) or s(190)

            local TitleLbl = New("TextLabel", {
                Text = " " .. (mConfig.Title or "Module"),
                Size = UDim2.new(0, titleWidth, 0, s(18)),
                Position = UDim2.new(0, s(10), 0, s(4)),
                TextColor3 = Color3.fromRGB(0, 120, 255),
                Font = Enum.Font.GothamBold,
                TextSize = s(12),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, Header)

            local DescLbl = New("TextLabel", {
                Text = " " .. (mConfig.Description or ""),
                Size = UDim2.new(0, titleWidth, 0, s(14)),
                Position = UDim2.new(0, s(10), 0, s(21)),
                TextColor3 = Color3.fromRGB(0, 80, 255),
                Font = Enum.Font.Gotham,
                TextSize = s(9),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, Header)

            -- optional per-module keybind capture (Sakura logic)
            local KeybindBtn
            if hasKeybind then
                KeybindBtn = New("TextButton", {
                    Size = UDim2.new(0, s(46), 0, s(20)),
                    Position = UDim2.new(1, -s(84), 0, s(10)),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 35),
                    AutoButtonColor = false,
                    Text = typeof(mConfig.Keybind) == "EnumItem" and mConfig.Keybind.Name or "None",
                    TextColor3 = Color3.fromRGB(0, 120, 255),
                    Font = Enum.Font.Gotham,
                    TextSize = s(10),
                }, Header)
                Round(KeybindBtn, s(6))
            end

            -- master enable toggle
            local ToggleBg = New("Frame", {
                Size = UDim2.new(0, s(34), 0, s(18)),
                Position = UDim2.new(1, -s(46), 0, s(11)),
                BackgroundColor3 = Color3.fromRGB(40, 40, 45),
            }, Header)
            Round(ToggleBg, s(999))
            local ToggleDot = New("Frame", {
                Size = UDim2.new(0, s(14), 0, s(14)),
                Position = UDim2.new(0, s(2), 0.5, -s(7)),
                BackgroundColor3 = Color3.fromRGB(120, 120, 125),
            }, ToggleBg)
            Round(ToggleDot, s(999))

            New("Frame", {
                Size = UDim2.new(1, -s(20), 0, 1),
                Position = UDim2.new(0, s(10), 0, HEADER_H),
                BackgroundColor3 = Color3.fromRGB(0, 80, 255),
                BackgroundTransparency = 0.6,
                BorderSizePixel = 0,
            }, ModuleFrame)

            local Options = New("Frame", {
                Name = "Options",
                Size = UDim2.new(1, -s(20), 0, 0),
                Position = UDim2.new(0, s(10), 0, HEADER_H + DIVIDER_H),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
            }, ModuleFrame)
            local OptLayout = New("UIListLayout", {
                Padding = UDim.new(0, s(8)),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, Options)

            local ModuleObj = {
                Options = Options,
                Enabled = false,
                _callback = mConfig.Callback,
            }

            local function recalc(animate)
                local target
                if ModuleObj.Enabled then
                    target = HEADER_H + DIVIDER_H + OptLayout.AbsoluteContentSize.Y + s(6)
                else
                    target = HEADER_H
                end
                if animate then
                    Tween(ModuleFrame, {Size = UDim2.new(1, 0, 0, target)}, 0.3)
                else
                    ModuleFrame.Size = UDim2.new(1, 0, 0, target)
                end
            end
            OptLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                recalc(ModuleObj.Enabled)
            end)

            local function setEnabled(state, fromUser)
                ModuleObj.Enabled = state
                Tween(ToggleDot, {
                    Position = state and UDim2.new(0, s(18), 0.5, -s(7)) or UDim2.new(0, s(2), 0.5, -s(7)),
                    BackgroundColor3 = state and Color3.fromRGB(0, 80, 255) or Color3.fromRGB(120, 120, 125),
                }, 0.2)
                recalc(true)
                if fromUser then
                    Window.Flags[mConfig.Flag] = state
                    if ModuleObj._callback then task.spawn(ModuleObj._callback, state) end
                end
            end
            ModuleObj._SetEnabled = setEnabled

            local ClickArea = New("TextButton", {
                Size = UDim2.new(1, -s(90), 0, HEADER_H),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 2,
            }, Header)
            ClickArea.MouseButton1Click:Connect(function()
                setEnabled(not ModuleObj.Enabled, true)
            end)
            ToggleBg.InputBegan:Connect(function(input)
                if input.UserInputType.Name:find("Mouse") or input.UserInputType.Name=="Touch" then
                    setEnabled(not ModuleObj.Enabled,true)
                end
            end)

            if KeybindBtn then
                local listening = false
                KeybindBtn.MouseButton1Click:Connect(function()
                    listening = true
                    KeybindBtn.Text = "..."
                end)
                UIS.InputBegan:Connect(function(input, gpe)
                    if listening and not gpe and input.UserInputType == Enum.UserInputType.Keyboard then
                        mConfig.Keybind = input.KeyCode
                        KeybindBtn.Text = input.KeyCode.Name
                        listening = false
                    elseif not listening and input.UserInputType == Enum.UserInputType.Keyboard
                        and mConfig.Keybind and input.KeyCode == mConfig.Keybind then
                        setEnabled(not ModuleObj.Enabled, true)
                    end
                end)
            end

            registerFlag(Window, mConfig.Flag, function(v) setEnabled(v, false) end, ModuleObj.Enabled)
            setEnabled(false, false)

            setmetatable(ModuleObj, {__index = Library.ModuleMeta})
            return ModuleObj
        end

        return Tab
    end

    return Window
end

----------------------------------------------------------------
-- MODULE SUB-CONTROLS (Sakura logic, Bobit visuals)
----------------------------------------------------------------
Library.ModuleMeta = {}
Library.ModuleMeta.__index = Library.ModuleMeta

function Library.ModuleMeta:CreateLabel(config)
    config = config or {}
    return New("TextLabel", {
        Text = config.Text or "Label",
        Size = UDim2.new(1, 0, 0, s(16)),
        TextColor3 = Color3.fromRGB(0, 120, 255),
        Font = Enum.Font.Gotham,
        TextSize = s(11),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, self.Options)
end

function Library.ModuleMeta:CreateParagraph(config)
    config = config or {}
    return New("TextLabel", {
        Text = (config.Title and (config.Title .. "\n") or "") .. (config.Content or ""),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextColor3 = Color3.fromRGB(0, 80, 255),
        Font = Enum.Font.Gotham,
        TextSize = s(10),
        TextWrapped = true,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, self.Options)
end

function Library.ModuleMeta:CreateDivider()
    return New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.fromRGB(0, 80, 255),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
    }, self.Options)
end

function Library.ModuleMeta:CreateButton(config)
    config = config or {}
    local Btn = New("TextButton", {
        Size = UDim2.new(1, 0, 0, s(26)),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        AutoButtonColor = false,
        Text = config.Text or "Button",
        TextColor3 = Color3.fromRGB(0, 120, 255),
        Font = Enum.Font.GothamBold,
        TextSize = s(11),
    }, self.Options)
    Round(Btn, s(6))
    Stroke(Btn, 1, 0.6)
    Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundColor3 = Color3.fromRGB(38, 38, 44)}, 0.15) end)
    Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}, 0.15) end)
    Btn.MouseButton1Click:Connect(function()
        if config.Callback then task.spawn(config.Callback) end
    end)
    return Btn
end

function Library.ModuleMeta:CreateToggle(config)
    config = config or {}
    local state = config.Default or false
    local Row = New("Frame", {Size = UDim2.new(1, 0, 0, s(22)), BackgroundTransparency = 1}, self.Options)
    New("TextLabel", {
        Text = config.Text or "Toggle",
        Size = UDim2.new(1, -s(40), 1, 0),
        TextColor3 = Color3.fromRGB(0, 120, 255),
        Font = Enum.Font.Gotham,
        TextSize = s(11),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Row)
    local Bg = New("Frame", {
        Size = UDim2.new(0, s(30), 0, s(16)),
        Position = UDim2.new(1, -s(30), 0.5, -s(8)),
        BackgroundColor3 = state and Color3.fromRGB(0, 80, 255) or Color3.fromRGB(40, 40, 45),
    }, Row)
    Round(Bg, s(999))
    local Dot = New("Frame", {
        Size = UDim2.new(0, s(12), 0, s(12)),
        Position = state and UDim2.new(1, -s(14), 0.5, -s(6)) or UDim2.new(0, s(2), 0.5, -s(6)),
        BackgroundColor3 = Color3.fromRGB(230, 230, 230),
    }, Bg)
    Round(Dot, s(999))

    local Click = New("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = ""}, Row)
    Click.MouseButton1Click:Connect(function()
        state = not state
        Tween(Bg, {BackgroundColor3 = state and Color3.fromRGB(0, 80, 255) or Color3.fromRGB(40, 40, 45)}, 0.15)
        Tween(Dot, {Position = state and UDim2.new(1, -s(14), 0.5, -s(6)) or UDim2.new(0, s(2), 0.5, -s(6))}, 0.15)
        if config.Callback then task.spawn(config.Callback, state) end
    end)

    return {
        Set = function(_, v)
            state = v
            Tween(Bg, {BackgroundColor3 = state and Color3.fromRGB(0, 80, 255) or Color3.fromRGB(40, 40, 45)}, 0.15)
            Tween(Dot, {Position = state and UDim2.new(1, -s(14), 0.5, -s(6)) or UDim2.new(0, s(2), 0.5, -s(6))}, 0.15)
        end,
        Get = function() return state end,
    }
end

function Library.ModuleMeta:CreateSlider(config)
    config = config or {}
    local min, max = config.Min or 0, config.Max or 100
    local value = math.clamp(config.Default or min, min, max)
    local suffix = config.Suffix or ""

    local Row = New("Frame", {Size = UDim2.new(1, 0, 0, s(32)), BackgroundTransparency = 1}, self.Options)
    New("TextLabel", {
        Text = config.Text or "Slider",
        Size = UDim2.new(1, -s(45), 0, s(14)),
        TextColor3 = Color3.fromRGB(0, 120, 255),
        Font = Enum.Font.Gotham,
        TextSize = s(11),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Row)
    local ValLbl = New("TextLabel", {
        Text = tostring(value) .. suffix,
        Size = UDim2.new(0, s(45), 0, s(14)),
        Position = UDim2.new(1, -s(45), 0, 0),
        TextColor3 = Color3.fromRGB(0, 80, 255),
        Font = Enum.Font.GothamBold,
        TextSize = s(10),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, Row)
    local Track = New("Frame", {
        Size = UDim2.new(1, 0, 0, s(4)),
        Position = UDim2.new(0, 0, 0, s(22)),
        BackgroundColor3 = Color3.fromRGB(40, 40, 45),
    }, Row)
    Round(Track, s(999))
    local Fill = New("Frame", {
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 80, 255),
    }, Track)
    Round(Fill, s(999))
    local Dot = New("Frame", {
        Size = UDim2.new(0, s(12), 0, s(12)),
        Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(0, 80, 255),
        ZIndex = 11,
    }, Track)
    Round(Dot, s(999))

    local dragging = false
    local function update(input)
        local pct = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * pct)
        Tween(Fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.15)
        Tween(Dot, {Position = UDim2.new(pct, 0, 0.5, 0)}, 0.15)
        ValLbl.Text = tostring(value) .. suffix
        if config.Callback then task.spawn(config.Callback, value) end
    end
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return {
        Set = function(_, v)
            value = math.clamp(v, min, max)
            local pct = (value - min) / (max - min)
            Tween(Fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.15)
            Tween(Dot, {Position = UDim2.new(pct, 0, 0.5, 0)}, 0.15)
            ValLbl.Text = tostring(value) .. suffix
        end,
        Get = function() return value end,
    }
end

function Library.ModuleMeta:CreateDropdown(config)
    config = config or {}
    local options = config.Options or {"Option 1"}
    local selected = config.Default or options[1]

    local Row = New("Frame", {
        Size = UDim2.new(1, 0, 0, s(38)),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = 5,
    }, self.Options)

    New("TextLabel", {
        Text = config.Text or "Dropdown",
        Size = UDim2.new(1, 0, 0, s(14)),
        TextColor3 = Color3.fromRGB(0, 120, 255),
        Font = Enum.Font.Gotham,
        TextSize = s(11),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    }, Row)

    local Selected = New("Frame", {
        Size = UDim2.new(1, 0, 0, s(18)),
        Position = UDim2.new(0, 0, 0, s(16)),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        ZIndex = 6,
    }, Row)
    Round(Selected, s(6))

    local SelectedText = New("TextLabel", {
        Text = selected,
        Size = UDim2.new(1, -s(10), 1, 0),
        Position = UDim2.new(0, s(8), 0, 0),
        TextColor3 = Color3.fromRGB(200, 200, 200),
        Font = Enum.Font.GothamBold,
        TextSize = s(10),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7,
    }, Selected)

    local DropBtn = New("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 11}, Selected)

    local Holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, s(37)),
        BackgroundColor3 = Color3.fromRGB(15, 15, 18),
        Visible = false,
        ZIndex = 100,
        ClipsDescendants = true,
    }, Row)
    Round(Holder, s(8))
    Stroke(Holder, 1.2, 0)

    local Scroll = New("ScrollingFrame", {
        Size = UDim2.new(1, -s(10), 1, -s(10)),
        Position = UDim2.new(0, s(5), 0, s(5)),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        ZIndex = 101,
        CanvasSize = UDim2.new(0, 0, 0, #options * s(25)),
    }, Holder)
    New("UIListLayout", {Padding = UDim.new(0, s(3))}, Scroll)

    local isOpen = false
    for _, option in ipairs(options) do
        local OptBtn = New("TextButton", {
            Size = UDim2.new(1, 0, 0, s(22)),
            BackgroundColor3 = Color3.fromRGB(15, 15, 18),
            Text = "  " .. option,
            TextColor3 = Color3.fromRGB(0, 80, 255),
            Font = Enum.Font.GothamBold,
            TextSize = s(10),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 102,
        }, Scroll)
        Round(OptBtn, s(4))
        OptBtn.MouseButton1Click:Connect(function()
            selected = option
            SelectedText.Text = option
            isOpen = false
            Holder.Visible = false
            Tween(Holder, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
            if config.Callback then task.spawn(config.Callback, option) end
        end)
    end

    DropBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        Holder.Visible = isOpen
        Tween(Holder, {Size = isOpen and UDim2.new(1, 0, 0, math.min(s(110), #options * s(25) + s(10))) or UDim2.new(1, 0, 0, 0)}, 0.2)
    end)

    return {
        Set = function(_, v)
            selected = v
            SelectedText.Text = v
        end,
        Get = function() return selected end,
    }
end

function Library.ModuleMeta:CreateTextbox(config)
    config = config or {}
    local Row = New("Frame", {Size = UDim2.new(1, 0, 0, s(36)), BackgroundTransparency = 1}, self.Options)
    if config.Text then
        New("TextLabel", {
            Text = config.Text,
            Size = UDim2.new(1, 0, 0, s(12)),
            TextColor3 = Color3.fromRGB(0, 120, 255),
            Font = Enum.Font.Gotham,
            TextSize = s(9),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, Row)
    end
    local Wrapper = New("Frame", {
        Size = UDim2.new(1, 0, 0, s(22)),
        Position = UDim2.new(0, 0, 0, config.Text and s(14) or 0),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
    }, Row)
    Round(Wrapper, s(6))
    Stroke(Wrapper, 1, 0)

    local Box = New("TextBox", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = config.Default or "",
        PlaceholderText = config.Placeholder or "Type here...",
        PlaceholderColor3 = Color3.fromRGB(0, 80, 255),
        TextColor3 = Color3.fromRGB(0, 120, 255),
        Font = Enum.Font.Gotham,
        TextSize = s(11),
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    }, Wrapper)
    New("UIPadding", {PaddingLeft = UDim.new(0, s(8))}, Box)

    Box.FocusLost:Connect(function(enterPressed)
        if config.Callback then task.spawn(config.Callback, Box.Text, enterPressed) end
    end)

    return {
        Set = function(_, v) Box.Text = v end,
        Get = function() return Box.Text end,
    }
end

function Library.ModuleMeta:CreateKeybind(config)
    config = config or {}
    local bound = config.Default
    local listening = false

    local Row = New("Frame", {Size = UDim2.new(1, 0, 0, s(22)), BackgroundTransparency = 1}, self.Options)
    New("TextLabel", {
        Text = config.Text or "Keybind",
        Size = UDim2.new(1, -s(50), 1, 0),
        TextColor3 = Color3.fromRGB(0, 120, 255),
        Font = Enum.Font.Gotham,
        TextSize = s(11),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Row)
    local Btn = New("TextButton", {
        Size = UDim2.new(0, s(46), 0, s(18)),
        Position = UDim2.new(1, -s(46), 0.5, -s(9)),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        AutoButtonColor = false,
        Text = typeof(bound) == "EnumItem" and bound.Name or "None",
        TextColor3 = Color3.fromRGB(0, 120, 255),
        Font = Enum.Font.Gotham,
        TextSize = s(9),
    }, Row)
    Round(Btn, s(6))

    Btn.MouseButton1Click:Connect(function()
        listening = true
        Btn.Text = "..."
    end)
    UIS.InputBegan:Connect(function(input, gpe)
        if listening and not gpe and input.UserInputType == Enum.UserInputType.Keyboard then
            bound = input.KeyCode
            Btn.Text = input.KeyCode.Name
            listening = false
            if config.Callback then task.spawn(config.Callback, bound) end
        elseif not listening and bound and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bound then
            if config.Pressed then task.spawn(config.Pressed) end
        end
    end)

    return {
        Set = function(_, key) bound = key; Btn.Text = key and key.Name or "None" end,
        Get = function() return bound end,
    }
end

return Library
