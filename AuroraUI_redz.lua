-- Aurora UI · redzlib compatibility shim
-- Exposes the same API as `redz-V5-remake` (MakeWindow / MakeTab / AddToggle /
-- AddSlider / AddDropdown / AddButton / AddTextBox / AddSection / AddParagraph /
-- NewMinimizer / CreateMobileMinimizer) so existing scripts can swap only their
-- loader line and keep 100% of their logic intact.
--
-- Usage:
--   local redzlib = loadstring(game:HttpGet("https://api.aurorax.site/AuroraUI_redz.lua"))()
--   local Window  = redzlib:MakeWindow({ Title = "My Hub", SubTitle = "sub" })
--   local Tab     = Window:MakeTab({ Title = "Main", Icon = "" })
--   Tab:AddToggle({ Name = "AutoFarm", Default = false, Callback = function(v) end })

local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

-- Load the underlying Aurora UI library from the same host.
local Aurora = loadstring(game:HttpGet("https://api.aurorax.site/AuroraUI.lua"))()

local redzlib = {}
redzlib.__index = redzlib
redzlib._VERSION = "redz-compat-1.0"

local function pickCallback(o)
    return o and (o.Callback or o.Callbacks or o.Function) or function() end
end

-- ---------------------------------------------------------------- Tab wrapper
local function wrapTab(tab)
    local w = { _tab = tab }

    function w:AddToggle(o)
        o = o or {}
        local h = tab:CreateToggle({
            Name     = o.Name or o.Title or "Toggle",
            Default  = o.Default or o.CurrentValue or false,
            Callback = pickCallback(o),
        })
        -- Aliases used by some scripts
        h.SetValue = function(_, v) h:Set(v) end
        h.UpdateToggle = function(_, _, v) h:Set(v) end
        return h
    end

    function w:AddSlider(o)
        o = o or {}
        local incr = o.Increment or o.Rounding or 1
        local h = tab:CreateSlider({
            Name      = o.Name or "Slider",
            Min       = o.Min or 0,
            Max       = o.Max or 100,
            Default   = o.Default or o.Min or 0,
            Increment = incr,
            Callback  = pickCallback(o),
        })
        h.Set = function(_, _v) end
        h.SetValue = h.Set
        return h
    end

    function w:AddDropdown(o)
        o = o or {}
        local h = tab:CreateDropdown({
            Name     = o.Name or "Dropdown",
            Options  = o.Options or {},
            Default  = o.Default,
            Callback = pickCallback(o),
        })
        -- Keep the native :Refresh(newOptions, keep) from the library and just
        -- add SetOptions / SetValue aliases some redz scripts call.
        h.SetOptions = function(_, opts, keep) h:Refresh(opts, keep) end
        h.SetValue = function(_, _v) end
        h.Set = h.SetValue
        return h
    end

    function w:AddButton(o)
        o = o or {}
        return tab:CreateButton({
            Name     = o.Name or o.Title or o.Text or "Button",
            Callback = pickCallback(o),
        })
    end

    function w:AddTextBox(o)
        o = o or {}
        return tab:CreateTextbox({
            Name         = o.Name or "Textbox",
            Placeholder  = o.Placeholder or o.Default or "",
            Callback     = pickCallback(o),
            ClearOnFocus = o.ClearOnFocus,
        })
    end
    w.AddTextbox = w.AddTextBox

    function w:AddSection(o)
        local name = type(o) == "table" and (o.Name or o.Title or o.Text) or tostring(o)
        return tab:CreateSection(name)
    end

    function w:AddParagraph(o, content)
        -- redz supports both AddParagraph({Title=..,Content=..}) and the
        -- positional AddParagraph("Title", "Content") form used by many hubs.
        if type(o) == "table" then
            return tab:CreateParagraph({
                Title   = o.Title or o.Name or "",
                Content = o.Content or o.Text or content or "",
            })
        end
        return tab:CreateParagraph({
            Title   = tostring(o or ""),
            Content = tostring(content or ""),
        })
    end

    function w:AddLabel(o)
        local text = type(o) == "table" and (o.Name or o.Text or "") or tostring(o)
        return tab:CreateLabel(text)
    end

    function w:AddColorpicker(o)
        o = o or {}
        return tab:CreateColorPicker({
            Name     = o.Name or "Color",
            Default  = o.Default or Color3.fromRGB(255,255,255),
            Callback = pickCallback(o),
        })
    end
    w.AddColorPicker = w.AddColorpicker

    function w:AddBind(o)
        o = o or {}
        return tab:CreateKeybind({
            Name     = o.Name or "Keybind",
            Default  = o.Default or Enum.KeyCode.RightShift,
            Callback = pickCallback(o),
        })
    end
    w.AddKeybind = w.AddBind

    return w
end

-- --------------------------------------------------------------- Window / Mini
local function wrapWindow(win)
    local W = { _win = win, _tabs = {} }

    function W:MakeTab(o)
        o = o or {}
        local tab = win:CreateTab({
            Name = o.Title or o.Name or "Tab",
            Icon = o.Icon,
        })
        local wt = wrapTab(tab)
        table.insert(self._tabs, wt)
        return wt
    end

    function W:MakeNotification(o)
        o = o or {}
        if Aurora.Notify then
            Aurora:Notify({
                Title   = o.Name or o.Title or "Aurora",
                Content = o.Content or o.Text or "",
                Duration = o.Time or o.Duration or 4,
            })
        end
    end

    function W:NewMinimizer(mopts)
        mopts = mopts or {}
        local Mini = {}

        -- Keybind toggles the entire GUI
        if mopts.KeyCode then
            UserInputService.InputBegan:Connect(function(i, gp)
                if gp then return end
                if i.KeyCode == mopts.KeyCode then
                    win.Gui.Enabled = not win.Gui.Enabled
                end
            end)
        end

        function Mini:CreateMobileMinimizer(mmo)
            mmo = mmo or {}
            -- Prevent double-minimize buttons: hide the library's built-in
            -- restore bubble and header minimize button so only the
            -- script-provided mobile minimizer is visible.
            local restore = win.Gui:FindFirstChild("AuroraRestore")
            if restore then restore.Visible = false end
            for _, d in ipairs(win.Main:GetDescendants()) do
                if d:IsA("TextButton") and d.Text == "—" then
                    d.Visible = false
                end
            end
            local btn = Instance.new("ImageButton")
            btn.Name = "AuroraMobileMinimizer"
            btn.Size = UDim2.new(0, 52, 0, 52)
            btn.Position = UDim2.new(0, 20, 0, 120)
            btn.BackgroundColor3 = mmo.BackgroundColor3 or Color3.fromRGB(255, 255, 255)
            btn.BackgroundTransparency = mmo.BackgroundTransparency or 0.15
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Image = mmo.Image or ""
            btn.ScaleType = Enum.ScaleType.Fit
            btn.ClipsDescendants = true
            btn.Active = true
            btn.Draggable = false
            btn.ZIndex = 50
            btn.Parent = win.Gui

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = btn

            -- Draggable behaviour
            if Aurora.Util and Aurora.Util.makeDraggable then
                Aurora.Util.makeDraggable(btn, btn)
            end

            -- Click toggles window main frame visibility (open/close)
            local dragStart, moved
            btn.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch
                   or i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragStart = i.Position
                    moved = false
                end
            end)
            btn.InputChanged:Connect(function(i)
                if dragStart and (i.UserInputType == Enum.UserInputType.Touch
                                  or i.UserInputType == Enum.UserInputType.MouseMovement) then
                    if (i.Position - dragStart).Magnitude > 6 then moved = true end
                end
            end)
            btn.InputEnded:Connect(function(i)
                if (i.UserInputType == Enum.UserInputType.Touch
                    or i.UserInputType == Enum.UserInputType.MouseButton1) and not moved then
                    win.Main.Visible = not win.Main.Visible
                end
                dragStart = nil
            end)

            return btn
        end

        function Mini:Toggle()
            win.Gui.Enabled = not win.Gui.Enabled
        end

        return Mini
    end

    function W:Destroy() win:Destroy() end

    return W
end

-- ----------------------------------------------------------------------- API
function redzlib:MakeWindow(opts)
    opts = opts or {}
    local win = Aurora:CreateWindow({
        Title    = opts.Title or "Aurora UI",
        SubTitle = opts.SubTitle or "",
    })
    return wrapWindow(win)
end

function redzlib:MakeNotification(o)
    if Aurora.Notify then
        Aurora:Notify({
            Title   = (o and (o.Name or o.Title)) or "Aurora",
            Content = (o and (o.Content or o.Text)) or "",
            Duration = (o and (o.Time or o.Duration)) or 4,
        })
    end
end

return redzlib