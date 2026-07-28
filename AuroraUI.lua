--[[
    Aurora UI Framework
    Version: 1.0.0
    Platform: Roblox (Luau)
    Mobile-first · Glassmorphism · Futurista
    Single-file distribution build.

    Usage:
      local Aurora = loadstring(game:HttpGet("<url>/AuroraUI.lua"))()
      local Window = Aurora:CreateWindow({ Title = "Aurora", SubTitle = "v1.0" })
      local Tab = Window:CreateTab({ Name = "Main", Icon = "rbxassetid://0" })
      Tab:CreateButton({ Name = "Click me", Callback = function() print("hi") end })
      Tab:CreateToggle({ Name = "Toggle", Default = false, Callback = function(v) end })
      Tab:CreateSlider({ Name = "Speed", Min = 0, Max = 100, Default = 16, Callback = function(v) end })
      Tab:CreateDropdown({ Name = "Mode", Options = {"A","B"}, Default = "A", Callback = function(v) end })
      Tab:CreateTextbox({ Name = "Name", Placeholder = "...", Callback = function(v) end })
      Tab:CreateColorPicker({ Name = "Color", Default = Color3.fromRGB(168,85,247), Callback = function(c) end })
      Tab:CreateKeybind({ Name = "Toggle UI", Default = Enum.KeyCode.RightShift, Callback = function() end })
      Tab:CreateLabel("Label"); Tab:CreateParagraph({ Title = "T", Content = "..." })
      Tab:CreateSection("Section"); Tab:CreateSeparator()
      Aurora:Notify({ Title = "Hola", Content = "Cargado", Duration = 3 })
]]

local Aurora = {}
Aurora.__index = Aurora
Aurora._VERSION = "1.0.0"
Aurora._WINDOWS = {}

-- ============================================================
-- Services
-- ============================================================
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer and LocalPlayer:GetMouse()

-- ============================================================
-- Theme (Aurora "Nebula Purple")
-- ============================================================
local Theme = {
    Background = Color3.fromRGB(18, 16, 28),
    Window     = Color3.fromRGB(24, 20, 38),
    Panel      = Color3.fromRGB(28, 24, 45),
    Header     = Color3.fromRGB(32, 27, 50),
    Elevated   = Color3.fromRGB(38, 32, 60),
    Primary    = Color3.fromRGB(168, 85, 247),
    Secondary  = Color3.fromRGB(139, 92, 246),
    Glow       = Color3.fromRGB(192, 132, 252),
    Accent     = Color3.fromRGB(217, 70, 239),
    Border     = Color3.fromRGB(78, 60, 120),
    BorderSoft = Color3.fromRGB(60, 48, 96),
    Text       = Color3.fromRGB(240, 235, 255),
    SubText    = Color3.fromRGB(170, 160, 200),
    Muted      = Color3.fromRGB(120, 110, 150),
    Success    = Color3.fromRGB(74, 222, 128),
    Warning    = Color3.fromRGB(250, 204, 21),
    Error      = Color3.fromRGB(248, 113, 113),
    Font       = Enum.Font.GothamMedium,
    FontBold   = Enum.Font.GothamBold,
    FontLight  = Enum.Font.Gotham,
}
Aurora.Theme = Theme

-- ============================================================
-- Utility
-- ============================================================
local Util = {}

function Util.new(className, props, children)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then inst[k] = v end
        end
        if props.Parent then inst.Parent = props.Parent end
    end
    if children then
        for _, c in ipairs(children) do c.Parent = inst end
    end
    return inst
end

function Util.corner(parent, radius)
    return Util.new("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

function Util.stroke(parent, color, thickness, transparency)
    return Util.new("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

function Util.padding(parent, all)
    return Util.new("UIPadding", {
        PaddingTop    = UDim.new(0, all),
        PaddingBottom = UDim.new(0, all),
        PaddingLeft   = UDim.new(0, all),
        PaddingRight  = UDim.new(0, all),
        Parent = parent,
    })
end

function Util.list(parent, padding, dir)
    return Util.new("UIListLayout", {
        Padding = UDim.new(0, padding or 6),
        FillDirection = dir or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Parent = parent,
    })
end

function Util.tween(inst, time, props, style, dir)
    local t = TweenService:Create(inst, TweenInfo.new(
        time or 0.2,
        style or Enum.EasingStyle.Quart,
        dir or Enum.EasingDirection.Out
    ), props)
    t:Play()
    return t
end

function Util.gradient(parent, colors, rotation, transparency)
    return Util.new("UIGradient", {
        Color = typeof(colors) == "ColorSequence" and colors or ColorSequence.new(colors),
        Rotation = rotation or 0,
        Transparency = transparency or NumberSequence.new(0),
        Parent = parent,
    })
end

function Util.isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function Util.protectGui(gui)
    if syn and syn.protect_gui then syn.protect_gui(gui) end
    if (gethui and gethui()) then
        gui.Parent = gethui()
    elseif CoreGui then
        pcall(function() gui.Parent = CoreGui end)
    end
end

function Util.makeDraggable(topBar, frame)
    local dragging, dragStart, startPos, dragInput
    topBar.Active = true
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos  = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            Util.tween(frame, 0.08, {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                     startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            })
        end
    end)
end

Aurora.Util = Util

-- ============================================================
-- Notifications
-- ============================================================
local NotifyGui
local function ensureNotifyGui()
    if NotifyGui and NotifyGui.Parent then return NotifyGui end
    NotifyGui = Util.new("ScreenGui", {
        Name = "AuroraNotify",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    Util.protectGui(NotifyGui)
    local holder = Util.new("Frame", {
        Name = "Holder",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 320, 1, -32),
        Parent = NotifyGui,
    })
    Util.new("UIListLayout", {
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = holder,
    })
    return NotifyGui
end

function Aurora:Notify(opts)
    opts = opts or {}
    local title    = opts.Title or "Aurora"
    local content  = opts.Content or ""
    local duration = opts.Duration or 4
    local kind     = opts.Type or "info" -- info | success | warning | error

    local accent = Theme.Primary
    if kind == "success" then accent = Theme.Success
    elseif kind == "warning" then accent = Theme.Warning
    elseif kind == "error" then accent = Theme.Error end

    local gui = ensureNotifyGui()
    local holder = gui:FindFirstChild("Holder")

    local card = Util.new("Frame", {
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.05,
        Size = UDim2.new(1, 0, 0, 70),
        Position = UDim2.new(1, 40, 0, 0),
        Parent = holder,
    })
    Util.corner(card, 12)
    Util.stroke(card, Theme.Border, 1, 0.3)

    local bar = Util.new("Frame", {
        BackgroundColor3 = accent,
        Size = UDim2.new(0, 3, 1, -14),
        Position = UDim2.new(0, 8, 0, 7),
        BorderSizePixel = 0,
        Parent = card,
    })
    Util.corner(bar, 4)

    local titleLbl = Util.new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 22, 0, 8),
        Size = UDim2.new(1, -32, 0, 20),
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })
    local contentLbl = Util.new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 22, 0, 30),
        Size = UDim2.new(1, -32, 1, -38),
        Font = Theme.FontLight,
        Text = content,
        TextColor3 = Theme.SubText,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = card,
    })

    Util.tween(card, 0.35, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)

    task.delay(duration, function()
        Util.tween(card, 0.25, { Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1 })
        for _, d in ipairs(card:GetDescendants()) do
            pcall(function()
                if d:IsA("TextLabel") then Util.tween(d, 0.25, { TextTransparency = 1 })
                elseif d:IsA("UIStroke") then Util.tween(d, 0.25, { Transparency = 1 })
                elseif d:IsA("Frame") then Util.tween(d, 0.25, { BackgroundTransparency = 1 }) end
            end)
        end
        task.wait(0.28)
        card:Destroy()
    end)
end

-- ============================================================
-- Component factory helpers (used by Tabs)
-- ============================================================
local function makeRow(parent, height)
    local row = Util.new("Frame", {
        BackgroundColor3 = Theme.Elevated,
        BackgroundTransparency = 0.15,
        Size = UDim2.new(1, 0, 0, height or 44),
        Parent = parent,
    })
    Util.corner(row, 10)
    Util.stroke(row, Theme.BorderSoft, 1, 0.4)
    return row
end

local function rowLabel(row, text)
    return Util.new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -140, 1, 0),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
end

-- ============================================================
-- Component: Button
-- ============================================================
local function CreateButton(parent, opts)
    opts = opts or {}
    local row = makeRow(parent, 44)
    rowLabel(row, opts.Name or "Button")

    -- Chevron on the right side to hint the row is clickable
    local chevron = Util.new("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 16, 0, 16),
        Image = "rbxassetid://6031091004", -- chevron-right style arrow (down)
        Rotation = -90,
        ImageColor3 = Theme.SubText,
        Parent = row,
    })

    -- Whole-row invisible clickable overlay
    local btn = Util.new("TextButton", {
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.new(1, 0, 1, 0),
        AutoButtonColor = false,
        Parent = row,
    })

    btn.MouseEnter:Connect(function()
        Util.tween(row, 0.15, { BackgroundTransparency = 0 })
        Util.tween(chevron, 0.15, { ImageColor3 = Theme.Glow, Position = UDim2.new(1, -8, 0.5, 0) })
    end)
    btn.MouseLeave:Connect(function()
        Util.tween(row, 0.15, { BackgroundTransparency = 0.15 })
        Util.tween(chevron, 0.15, { ImageColor3 = Theme.SubText, Position = UDim2.new(1, -12, 0.5, 0) })
    end)
    btn.MouseButton1Click:Connect(function()
        Util.tween(row, 0.08, { BackgroundColor3 = Theme.Primary, BackgroundTransparency = 0.5 })
        task.wait(0.1)
        Util.tween(row, 0.15, { BackgroundColor3 = Theme.Elevated, BackgroundTransparency = 0.15 })
        if opts.Callback then pcall(opts.Callback) end
    end)

    return { Instance = row }
end

-- ============================================================
-- Component: Toggle
-- ============================================================
local function CreateToggle(parent, opts)
    opts = opts or {}
    local state = opts.Default and true or false
    local row = makeRow(parent, 44)
    rowLabel(row, opts.Name or "Toggle")

    local track = Util.new("Frame", {
        BackgroundColor3 = Theme.Header,
        Position = UDim2.new(1, -58, 0.5, -12),
        Size = UDim2.new(0, 48, 0, 24),
        Parent = row,
    })
    Util.corner(track, 12)
    Util.stroke(track, Theme.BorderSoft, 1, 0.3)

    local knob = Util.new("Frame", {
        BackgroundColor3 = Theme.SubText,
        Position = UDim2.new(0, 3, 0.5, -9),
        Size = UDim2.new(0, 18, 0, 18),
        Parent = track,
    })
    Util.corner(knob, 10)

    local btn = Util.new("TextButton", {
        BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 1, 0), Parent = row,
    })

    local api = {}
    function api:Set(v)
        state = v and true or false
        if state then
            Util.tween(track, 0.2, { BackgroundColor3 = Theme.Primary })
            Util.tween(knob, 0.2, { Position = UDim2.new(1, -21, 0.5, -9), BackgroundColor3 = Theme.Text })
        else
            Util.tween(track, 0.2, { BackgroundColor3 = Theme.Header })
            Util.tween(knob, 0.2, { Position = UDim2.new(0, 3, 0.5, -9), BackgroundColor3 = Theme.SubText })
        end
        if opts.Callback then pcall(opts.Callback, state) end
    end
    btn.MouseButton1Click:Connect(function() api:Set(not state) end)
    api:Set(state)
    api.Instance = row
    return api
end

-- ============================================================
-- Component: Slider
-- ============================================================
local function CreateSlider(parent, opts)
    opts = opts or {}
    local min = opts.Min or 0
    local max = opts.Max or 100
    local default = math.clamp(opts.Default or min, min, max)
    local decimals = opts.Decimals or 0

    local row = makeRow(parent, 62)
    local label = Util.new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 8),
        Size = UDim2.new(1, -28, 0, 18),
        Font = Theme.Font,
        Text = opts.Name or "Slider",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local valueLbl = Util.new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -70, 0, 8),
        Size = UDim2.new(0, 60, 0, 18),
        Font = Theme.FontBold,
        Text = tostring(default),
        TextColor3 = Theme.Glow,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })

    local bar = Util.new("Frame", {
        BackgroundColor3 = Theme.Header,
        Position = UDim2.new(0, 14, 1, -18),
        Size = UDim2.new(1, -28, 0, 6),
        Parent = row,
    })
    Util.corner(bar, 4)

    local fill = Util.new("Frame", {
        BackgroundColor3 = Theme.Primary,
        Size = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0,
        Parent = bar,
    })
    Util.corner(fill, 4)
    Util.gradient(fill, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Primary),
        ColorSequenceKeypoint.new(1, Theme.Glow),
    }), 0)

    local knob = Util.new("Frame", {
        BackgroundColor3 = Theme.Text,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        Parent = bar,
    })
    Util.corner(knob, 8)
    Util.stroke(knob, Theme.Primary, 2, 0)

    local dragging = false
    local function updateFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local raw = min + (max - min) * rel
        local mult = 10 ^ decimals
        local val = math.floor(raw * mult + 0.5) / mult
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        valueLbl.Text = tostring(val)
        if opts.Callback then pcall(opts.Callback, val) end
    end

    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- set initial visual
    task.defer(function()
        local rel = (default - min) / (max - min)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
    end)

    return { Instance = row }
end

-- ============================================================
-- Component: Dropdown
-- ============================================================
local function CreateDropdown(parent, opts)
    opts = opts or {}
    local options = opts.Options or {}
    local current = opts.Default or options[1]
    local open = false

    local row = makeRow(parent, 44)
    rowLabel(row, opts.Name or "Dropdown")

    local selector = Util.new("TextButton", {
        BackgroundColor3 = Theme.Header,
        Position = UDim2.new(1, -138, 0.5, -14),
        Size = UDim2.new(0, 128, 0, 28),
        Font = Theme.Font,
        Text = "  " .. tostring(current or "—"),
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        Parent = row,
    })
    Util.corner(selector, 8)
    Util.stroke(selector, Theme.BorderSoft, 1, 0.3)

    local arrow = Util.new("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        Image = "rbxassetid://6031091004", -- chevron down
        ImageColor3 = Theme.SubText,
        Parent = selector,
    })

    -- Overlay ScreenGui so the list is never clipped by the ScrollingFrame
    local overlayGui = selector:FindFirstAncestorOfClass("ScreenGui")
    -- Full-screen invisible catcher so tapping outside closes the dropdown
    local catcher = Util.new("TextButton", {
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.fromOffset(0, 0),
        Visible = false,
        ZIndex = 49,
        Parent = overlayGui or row,
    })
    local list = Util.new("ScrollingFrame", {
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.new(0, 128, 0, 0),
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 50,
        Active = true,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Primary,
        ScrollingEnabled = true,
        Parent = overlayGui or row,
    })
    Util.corner(list, 8)
    Util.stroke(list, Theme.Border, 1, 0.2)
    local listLayout = Util.list(list, 2)
    Util.padding(list, 4)

    local function reposition()
        local ap = selector.AbsolutePosition
        local as = selector.AbsoluteSize
        list.Position = UDim2.fromOffset(ap.X, ap.Y + as.Y + 4)
    end

    -- Keep list glued to the selector while the parent scrolls / resizes
    local RunService = game:GetService("RunService")
    local followConn
    local function startFollow()
        if followConn then return end
        followConn = RunService.RenderStepped:Connect(function()
            if not list.Visible then return end
            reposition()
        end)
    end
    local function stopFollow()
        if followConn then followConn:Disconnect(); followConn = nil end
    end

    local function closeList()
        if not open then return end
        open = false
        catcher.Visible = false
        Util.tween(list, 0.18, { Size = UDim2.new(0, 128, 0, 0) })
        Util.tween(arrow, 0.15, { Rotation = 0 })
        task.delay(0.2, function() if not open then list.Visible = false; stopFollow() end end)
    end
    catcher.MouseButton1Click:Connect(closeList)

    local function rebuild()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, opt in ipairs(options) do
            local o = Util.new("TextButton", {
                BackgroundColor3 = Theme.Elevated,
                BackgroundTransparency = 0.4,
                Size = UDim2.new(1, 0, 0, 26),
                Font = Theme.Font,
                Text = "  " .. tostring(opt),
                TextColor3 = Theme.Text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                ZIndex = 51,
                Parent = list,
            })
            Util.corner(o, 6)
            o.MouseEnter:Connect(function() Util.tween(o, 0.12, { BackgroundColor3 = Theme.Primary, BackgroundTransparency = 0.2 }) end)
            o.MouseLeave:Connect(function() Util.tween(o, 0.12, { BackgroundColor3 = Theme.Elevated, BackgroundTransparency = 0.4 }) end)
            o.MouseButton1Click:Connect(function()
                current = opt
                selector.Text = "  " .. tostring(opt)
                closeList()
                if opts.Callback then pcall(opts.Callback, opt) end
            end)
        end
    end
    rebuild()

    selector.MouseButton1Click:Connect(function()
        open = not open
        if open then
            reposition()
            list.Visible = true
            catcher.Visible = true
            startFollow()
            local h = math.min(#options * 28 + 8, 180)
            list.CanvasPosition = Vector2.new(0, 0)
            Util.tween(list, 0.2, { Size = UDim2.new(0, 128, 0, h) })
            Util.tween(arrow, 0.15, { Rotation = 180 })
        else
            open = true -- closeList expects open==true
            closeList()
        end
    end)

    local api = { Instance = row }
    function api:Refresh(newOpts, keep)
        options = newOpts or {}
        if not keep then current = options[1]; selector.Text = "  " .. tostring(current or "—") end
        rebuild()
    end

    -- Fire callback with the default so scripts that read the selection
    -- from the callback (instead of reading opts.Default themselves) start
    -- with a valid choice — otherwise features like "Auto Farm Level" have
    -- no weapon selected when toggled on.
    if current ~= nil and opts.Callback then
        task.defer(function() pcall(opts.Callback, current) end)
    end

    return api
end

-- ============================================================
-- Component: Textbox
-- ============================================================
local function CreateTextbox(parent, opts)
    opts = opts or {}
    local row = makeRow(parent, 44)
    rowLabel(row, opts.Name or "Textbox")
    local box = Util.new("TextBox", {
        BackgroundColor3 = Theme.Header,
        Position = UDim2.new(1, -168, 0.5, -14),
        Size = UDim2.new(0, 158, 0, 28),
        Font = Theme.Font,
        PlaceholderText = opts.Placeholder or "",
        PlaceholderColor3 = Theme.Muted,
        Text = opts.Default or "",
        TextColor3 = Theme.Text,
        TextSize = 13,
        ClearTextOnFocus = false,
        Parent = row,
    })
    Util.corner(box, 8)
    Util.stroke(box, Theme.BorderSoft, 1, 0.3)
    Util.padding(box, 8)
    box.FocusLost:Connect(function(enter)
        if opts.Callback then pcall(opts.Callback, box.Text, enter) end
    end)
    return { Instance = row }
end

-- ============================================================
-- Component: Label / Paragraph / Section / Separator
-- ============================================================
local function CreateLabel(parent, text)
    local l = Util.new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Font = Theme.Font,
        Text = tostring(text or ""),
        TextColor3 = Theme.SubText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent,
    })
    return { Instance = l, Set = function(_, v) l.Text = tostring(v) end }
end

local function CreateParagraph(parent, opts)
    opts = opts or {}
    local box = Util.new("Frame", {
        BackgroundColor3 = Theme.Elevated,
        BackgroundTransparency = 0.2,
        Size = UDim2.new(1, 0, 0, 60),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = parent,
    })
    Util.corner(box, 10)
    Util.stroke(box, Theme.BorderSoft, 1, 0.4)
    Util.padding(box, 10)
    Util.list(box, 4)
    local titleLbl = Util.new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Theme.FontBold,
        Text = opts.Title or "Título",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = box,
    })
    local contentLbl = Util.new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Theme.FontLight,
        Text = opts.Content or "",
        TextColor3 = Theme.SubText,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = box,
    })
    local api = { Instance = box, Title = titleLbl, Content = contentLbl }
    function api:SetDesc(v) contentLbl.Text = tostring(v or "") end
    function api:SetTitle(v) titleLbl.Text = tostring(v or "") end
    function api:Set(v) contentLbl.Text = tostring(v or "") end
    return api
end

local function CreateSection(parent, text)
    local wrap = Util.new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Parent = parent,
    })
    Util.new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Theme.FontBold,
        Text = string.upper(tostring(text or "SECTION")),
        TextColor3 = Theme.Glow,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = wrap,
    })
    return { Instance = wrap }
end

local function CreateSeparator(parent)
    local sep = Util.new("Frame", {
        BackgroundColor3 = Theme.BorderSoft,
        BackgroundTransparency = 0.4,
        Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0,
        Parent = parent,
    })
    return { Instance = sep }
end

-- ============================================================
-- Component: ColorPicker (compact HSV)
-- ============================================================
local function CreateColorPicker(parent, opts)
    opts = opts or {}
    local color = opts.Default or Color3.fromRGB(168, 85, 247)
    local row = makeRow(parent, 44)
    rowLabel(row, opts.Name or "Color")

    local swatch = Util.new("TextButton", {
        BackgroundColor3 = color,
        Position = UDim2.new(1, -46, 0.5, -14),
        Size = UDim2.new(0, 36, 0, 28),
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    Util.corner(swatch, 8)
    Util.stroke(swatch, Theme.BorderSoft, 1, 0.2)

    local panel = Util.new("Frame", {
        BackgroundColor3 = Theme.Panel,
        Position = UDim2.new(1, -220, 1, 4),
        Size = UDim2.new(0, 210, 0, 0),
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 8,
        Parent = row,
    })
    Util.corner(panel, 10)
    Util.stroke(panel, Theme.Border, 1, 0.2)

    local h, s, v = 0.75, 0.7, 0.9
    local function apply()
        color = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = color
        if opts.Callback then pcall(opts.Callback, color) end
    end

    local sv = Util.new("ImageLabel", {
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(0, 150, 0, 100),
        Image = "",
        ZIndex = 9,
        Parent = panel,
    })
    Util.corner(sv, 6)
    local svGrad = Util.new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(h,1,1)),
        }),
        Parent = sv,
    })
    local svDark = Util.new("Frame", {
        BackgroundColor3 = Color3.new(0,0,0), Size = UDim2.new(1,0,1,0), BorderSizePixel = 0, ZIndex = 10, Parent = sv,
    })
    Util.corner(svDark, 6)
    Util.new("UIGradient", {
        Color = ColorSequence.new(Color3.new(0,0,0)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Rotation = 90,
        Parent = svDark,
    })

    local hueBar = Util.new("Frame", {
        Position = UDim2.new(0, 170, 0, 10),
        Size = UDim2.new(0, 20, 0, 100),
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel = 0,
        ZIndex = 9,
        Parent = panel,
    })
    Util.corner(hueBar, 6)
    Util.new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0,1,1)),
            ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17,1,1)),
            ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33,1,1)),
            ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50,1,1)),
            ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67,1,1)),
            ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83,1,1)),
            ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1,1,1)),
        }),
        Rotation = 90,
        Parent = hueBar,
    })

    local svCursor = Util.new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 8, 0, 8),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = sv,
    })
    Util.stroke(svCursor, Color3.new(1,1,1), 2, 0)
    Util.corner(svCursor, 4)

    local hueCursor = Util.new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, 4, 0, 4),
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = hueBar,
    })
    Util.corner(hueCursor, 2)

    local function updateCursors()
        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
        hueCursor.Position = UDim2.new(0.5, 0, h, 0)
        svGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(h,1,1)),
        })
    end
    updateCursors()

    local svDrag, hueDrag = false, false
    sv.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then svDrag = true end
    end)
    hueBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then hueDrag = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            svDrag, hueDrag = false, false
        end
    end)
    RunService.RenderStepped:Connect(function()
        if svDrag then
            local ap, as = sv.AbsolutePosition, sv.AbsoluteSize
            local mx = UserInputService:GetMouseLocation().X
            local my = UserInputService:GetMouseLocation().Y
            s = math.clamp((mx - ap.X) / as.X, 0, 1)
            v = 1 - math.clamp((my - ap.Y) / as.Y, 0, 1)
            updateCursors(); apply()
        elseif hueDrag then
            local ap, as = hueBar.AbsolutePosition, hueBar.AbsoluteSize
            local my = UserInputService:GetMouseLocation().Y
            h = math.clamp((my - ap.Y) / as.Y, 0, 1)
            updateCursors(); apply()
        end
    end)

    local openPicker = false
    swatch.MouseButton1Click:Connect(function()
        openPicker = not openPicker
        panel.Visible = true
        Util.tween(panel, 0.2, { Size = UDim2.new(0, 210, 0, openPicker and 120 or 0) })
        if not openPicker then task.wait(0.22); panel.Visible = false end
    end)

    apply()
    return { Instance = row }
end

-- ============================================================
-- Component: Keybind
-- ============================================================
local function CreateKeybind(parent, opts)
    opts = opts or {}
    local current = opts.Default or Enum.KeyCode.RightShift
    local row = makeRow(parent, 44)
    rowLabel(row, opts.Name or "Keybind")

    local btn = Util.new("TextButton", {
        BackgroundColor3 = Theme.Header,
        Position = UDim2.new(1, -108, 0.5, -14),
        Size = UDim2.new(0, 98, 0, 28),
        Font = Theme.FontBold,
        Text = current.Name,
        TextColor3 = Theme.Glow,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = row,
    })
    Util.corner(btn, 8)
    Util.stroke(btn, Theme.BorderSoft, 1, 0.3)

    local listening = false
    btn.MouseButton1Click:Connect(function()
        listening = true
        btn.Text = "..."
    end)
    UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if listening and i.UserInputType == Enum.UserInputType.Keyboard then
            current = i.KeyCode
            btn.Text = current.Name
            listening = false
        elseif not listening and i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == current then
            if opts.Callback then pcall(opts.Callback) end
        end
    end)

    return { Instance = row, Get = function() return current end }
end

-- ============================================================
-- Tab
-- ============================================================
local Tab = {}
Tab.__index = Tab

function Tab.new(window, opts)
    local self = setmetatable({}, Tab)
    self.Window = window
    self.Name = opts.Name or "Tab"

    self.Button = Util.new("TextButton", {
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, -6, 0, 36),
        Font = Theme.FontBold,
        Text = "",
        TextColor3 = Theme.SubText,
        AutoButtonColor = false,
        Parent = window.TabList,
    })
    Util.corner(self.Button, 10)

    -- Always render an icon slot so all tabs stay aligned. Only real image
    -- URLs (rbxassetid:// or http/https) are accepted; anything else (lucide
    -- names like "waves"/"tent") falls back to a neutral dot so the tab
    -- doesn't render blank.
    local rawIcon = opts.Icon and tostring(opts.Icon) or ""
    local isImage = rawIcon:match("^rbxassetid://") or rawIcon:match("^rbxthumb://") or rawIcon:match("^http")
    local iconAsset = isImage and rawIcon or "rbxassetid://6031075929"
    -- Custom user-uploaded artwork should render at the same size as the
    -- default lucide-style icons and keep its original colors (no tint).
    local CUSTOM_ICONS = {
        ["rbxassetid://90062701178064"] = true,   -- Information
        ["rbxassetid://125506289461098"] = true,  -- Sea Event
        ["rbxassetid://79414527368822"] = true,   -- Volcano Event
        ["rbxassetid://73117522660789"] = true,   -- Race V4
        ["rbxassetid://84351910860448"] = true,   -- Quest | Items
    }
    local iconImg = Util.new("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0.5, -9),
        Size = UDim2.new(0, 18, 0, 18),
        Image = iconAsset,
        ImageColor3 = CUSTOM_ICONS[iconAsset] and Color3.new(1, 1, 1) or Theme.SubText,
        Parent = self.Button,
    })
    self.TitleLabel = Util.new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 30, 0, 0),
        Size = UDim2.new(1, -34, 1, 0),
        Font = Theme.FontBold,
        Text = self.Name,
        TextColor3 = Theme.SubText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = self.Button,
    })
    self.IconImage = iconImg

    self.Container = Util.new("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Primary,
        Visible = false,
        Parent = window.Content,
    })
    Util.padding(self.Container, 12)
    Util.list(self.Container, 8)

    self.Button.MouseButton1Click:Connect(function() window:SelectTab(self) end)
    self.Button.MouseEnter:Connect(function()
        if window.CurrentTab ~= self then
            Util.tween(self.Button, 0.15, { BackgroundTransparency = 0.2 })
            Util.tween(self.TitleLabel, 0.15, { TextColor3 = Theme.Text })
        end
    end)
    self.Button.MouseLeave:Connect(function()
        if window.CurrentTab ~= self then
            Util.tween(self.Button, 0.15, { BackgroundTransparency = 0.5 })
            Util.tween(self.TitleLabel, 0.15, { TextColor3 = Theme.SubText })
        end
    end)

    return self
end

function Tab:CreateButton(o)      return CreateButton(self.Container, o) end
function Tab:CreateToggle(o)      return CreateToggle(self.Container, o) end
function Tab:CreateSlider(o)      return CreateSlider(self.Container, o) end
function Tab:CreateDropdown(o)    return CreateDropdown(self.Container, o) end
function Tab:CreateTextbox(o)     return CreateTextbox(self.Container, o) end
function Tab:CreateLabel(t)       return CreateLabel(self.Container, t) end
function Tab:CreateParagraph(o)   return CreateParagraph(self.Container, o) end
function Tab:CreateSection(t)     return CreateSection(self.Container, t) end
function Tab:CreateSeparator()    return CreateSeparator(self.Container) end
function Tab:CreateColorPicker(o) return CreateColorPicker(self.Container, o) end
function Tab:CreateKeybind(o)     return CreateKeybind(self.Container, o) end

-- ============================================================
-- Window
-- ============================================================
local Window = {}
Window.__index = Window

function Window.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Window)
    self.Tabs = {}
    self.CurrentTab = nil

    local gui = Util.new("ScreenGui", {
        Name = "AuroraUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    Util.protectGui(gui)
    self.Gui = gui

    local isMobile = Util.isMobile()
    local w = isMobile and 520 or 690
    local h = isMobile and 380 or 430

    local main = Util.new("Frame", {
        Name = "Main",
        BackgroundColor3 = Theme.Window,
        Size = UDim2.new(0, w, 0, h),
        Position = UDim2.new(0.5, -w/2, 0.5, -h/2),
        ClipsDescendants = true,
        Parent = gui,
    })
    Util.corner(main, 14)
    Util.stroke(main, Theme.Border, 1, 0.2)
    self.Main = main

    -- Ambient glow
    local glow = Util.new("ImageLabel", {
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageColor3 = Theme.Primary,
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24,24,276,276),
        Position = UDim2.new(0, -30, 0, -30),
        Size = UDim2.new(1, 60, 1, 60),
        Parent = main,
    })
    glow.ZIndex = 0

    -- Header
    local header = Util.new("Frame", {
        BackgroundColor3 = Theme.Header,
        Size = UDim2.new(1, 0, 0, 42),
        Parent = main,
    })
    Util.corner(header, 14)
    Util.new("Frame", {
        BackgroundColor3 = Theme.Header, Size = UDim2.new(1, 0, 0.5, 0),
        Position = UDim2.new(0, 0, 0.5, 0), BorderSizePixel = 0, Parent = header,
    })

    local title = Util.new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(1, -100, 1, 0),
        Font = Theme.FontBold,
        Text = opts.Title or "Aurora UI",
        TextColor3 = Theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
    if opts.SubTitle then
        local sub = Util.new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16 + title.TextBounds.X + 8, 0, 0),
            Size = UDim2.new(0, 200, 1, 0),
            Font = Theme.FontLight,
            Text = opts.SubTitle,
            TextColor3 = Theme.SubText,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = header,
        })
    end

    local closeBtn = Util.new("TextButton", {
        BackgroundColor3 = Theme.Error,
        BackgroundTransparency = 0.7,
        Position = UDim2.new(1, -30, 0.5, -11),
        Size = UDim2.new(0, 22, 0, 22),
        Font = Theme.FontBold,
        Text = "×",
        TextColor3 = Theme.Text,
        TextSize = 16,
        AutoButtonColor = false,
        Parent = header,
    })
    Util.corner(closeBtn, 11)
    closeBtn.MouseEnter:Connect(function() Util.tween(closeBtn, 0.15, { BackgroundTransparency = 0.2 }) end)
    closeBtn.MouseLeave:Connect(function() Util.tween(closeBtn, 0.15, { BackgroundTransparency = 0.7 }) end)
    closeBtn.MouseButton1Click:Connect(function() self:Destroy() end)

    local miniBtn = Util.new("TextButton", {
        BackgroundColor3 = Theme.Elevated,
        BackgroundTransparency = 0.4,
        Position = UDim2.new(1, -58, 0.5, -11),
        Size = UDim2.new(0, 22, 0, 22),
        Font = Theme.FontBold,
        Text = "—",
        TextColor3 = Theme.Text,
        TextSize = 14,
        AutoButtonColor = false,
        Parent = header,
    })
    Util.corner(miniBtn, 11)
    Util.stroke(miniBtn, Theme.BorderSoft, 1, 0.4)
    miniBtn.MouseEnter:Connect(function() Util.tween(miniBtn, 0.15, { BackgroundTransparency = 0.1 }) end)
    miniBtn.MouseLeave:Connect(function() Util.tween(miniBtn, 0.15, { BackgroundTransparency = 0.4 }) end)

    Util.makeDraggable(header, main)

    -- Body: sidebar + content
    local body = Util.new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 46),
        Size = UDim2.new(1, 0, 1, -50),
        Parent = main,
    })

    -- Floating restore bubble (visible only when minimized)
    local restoreBubble = Util.new("TextButton", {
        Name = "AuroraRestore",
        BackgroundColor3 = Theme.Primary,
        Position = UDim2.new(0, 20, 0.5, -22),
        Size = UDim2.new(0, 44, 0, 44),
        Font = Theme.FontBold,
        Text = "A",
        TextColor3 = Theme.Text,
        TextSize = 18,
        AutoButtonColor = false,
        Visible = false,
        Parent = gui,
    })
    Util.corner(restoreBubble, 22)
    Util.stroke(restoreBubble, Theme.Glow, 2, 0.3)
    Util.gradient(restoreBubble, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Primary),
        ColorSequenceKeypoint.new(1, Theme.Accent),
    }), 135)
    Util.makeDraggable(restoreBubble, restoreBubble)

    local minimized = false
    local function setMinimized(v)
        minimized = v
        if minimized then
            body.Visible = false
            Util.tween(main, 0.22, { Size = UDim2.new(0, w, 0, 0) })
            task.wait(0.23)
            main.Visible = false
            restoreBubble.Visible = true
        else
            restoreBubble.Visible = false
            main.Visible = true
            Util.tween(main, 0.25, { Size = UDim2.new(0, w, 0, h) })
            body.Visible = true
        end
    end
    miniBtn.MouseButton1Click:Connect(function() setMinimized(not minimized) end)
    restoreBubble.MouseButton1Click:Connect(function()
        if minimized then setMinimized(false) end
    end)

    local sidebar = Util.new("Frame", {
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.15,
        Size = UDim2.new(0, isMobile and 178 or 200, 1, -8),
        Position = UDim2.new(0, 6, 0, 0),
        Parent = body,
    })
    Util.corner(sidebar, 10)
    Util.stroke(sidebar, Theme.BorderSoft, 1, 0.5)
    Util.padding(sidebar, 6)

    self.TabList = Util.new("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        Parent = sidebar,
    })
    Util.list(self.TabList, 4)

    self.Content = Util.new("Frame", {
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.2,
        Position = UDim2.new(0, (isMobile and 178 or 200) + 12, 0, 0),
        Size = UDim2.new(1, -(isMobile and 178 or 200) - 18, 1, -8),
        Parent = body,
    })
    Util.corner(self.Content, 10)
    Util.stroke(self.Content, Theme.BorderSoft, 1, 0.5)

    -- Entry animation
    main.Size = UDim2.new(0, w, 0, 0)
    Util.tween(main, 0.35, { Size = UDim2.new(0, w, 0, h) }, Enum.EasingStyle.Back)

    -- Toggle key (default RightShift)
    local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
    UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == toggleKey then
            gui.Enabled = not gui.Enabled
        end
    end)

    table.insert(Aurora._WINDOWS, self)
    return self
end

function Window:CreateTab(opts)
    local tab = Tab.new(self, opts or {})
    table.insert(self.Tabs, tab)
    if not self.CurrentTab then self:SelectTab(tab) end
    return tab
end

function Window:SelectTab(tab)
    for _, t in ipairs(self.Tabs) do
        t.Container.Visible = false
        Util.tween(t.Button, 0.15, {
            BackgroundTransparency = 0.5, BackgroundColor3 = Theme.Panel
        })
        if t.TitleLabel then Util.tween(t.TitleLabel, 0.15, { TextColor3 = Theme.SubText }) end
        if t.IconImage  then Util.tween(t.IconImage,  0.15, { ImageColor3 = Theme.SubText }) end
    end
    tab.Container.Visible = true
    Util.tween(tab.Button, 0.2, {
        BackgroundTransparency = 0, BackgroundColor3 = Theme.Primary
    })
    if tab.TitleLabel then Util.tween(tab.TitleLabel, 0.2, { TextColor3 = Theme.Text }) end
    if tab.IconImage  then Util.tween(tab.IconImage,  0.2, { ImageColor3 = Theme.Text }) end
    self.CurrentTab = tab
end

function Window:Destroy()
    Util.tween(self.Main, 0.2, { Size = UDim2.new(0, self.Main.AbsoluteSize.X, 0, 0) })
    task.wait(0.22)
    self.Gui:Destroy()
end

-- ============================================================
-- Public API
-- ============================================================
function Aurora:CreateWindow(opts) return Window.new(opts) end
function Aurora:SetTheme(overrides)
    for k, v in pairs(overrides or {}) do Theme[k] = v end
end
function Aurora:Destroy()
    for _, w in ipairs(Aurora._WINDOWS) do pcall(function() w:Destroy() end) end
    Aurora._WINDOWS = {}
end

return Aurora
