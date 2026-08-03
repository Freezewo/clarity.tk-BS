    local env = getgenv and getgenv() or _G
    local Players = game:GetService("Players")
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    local _spoofed_registry = {}
    local _original_tostring = tostring
    local _original_type = type
    local _original_typeof = typeof
    local _hooks_installed = false
    local function install_global_spoofs()
        if _hooks_installed then return end
        _hooks_installed = true
        local old_tostring = _original_tostring
        local new_tostring = newcclosure(function(v)
            if _original_type(v) == "table" and _spoofed_registry[v] then
                return _spoofed_registry[v]
            end
            return old_tostring(v)
        end)
        local old_type = _original_type
        local new_type = newcclosure(function(v)
            if old_type(v) == "table" and _spoofed_registry[v] then
                return "function"
            end
            return old_type(v)
        end)
        local old_typeof = _original_typeof
        local new_typeof = newcclosure(function(v)
            if old_type(v) == "table" and _spoofed_registry[v] then
                return "function"
            end
            return old_typeof(v)
        end)
        getgenv().tostring = new_tostring
        getgenv().type = new_type
        getgenv().typeof = new_typeof
    end
    local function hookToStringSpoof(target_table, func_name, hook_fn)
        local original_func = target_table[func_name]
        if type(original_func) ~= "function" then
            return nil
        end
        local original_str = _original_tostring(original_func)
        install_global_spoofs()
        local proxy = setmetatable({}, {
            __call = function(_, ...)
                local success, result = pcall(hook_fn, original_func, ...)
                if success then
                    return result
                else
                    return original_func(...)
                end
            end,
            __tostring = function()
                return original_str
            end,
            __metatable = getmetatable(original_func),
        })
        _spoofed_registry[proxy] = original_str
        target_table[func_name] = proxy
        return original_func
    end
    getgenv().hookToStringSpoof = hookToStringSpoof
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local CoreGui = game:GetService("CoreGui")
    local Library = {}
    Library.Flags = {}
    Library.KeybindRegistry = {}
    local Utility = {}
    local AccentUpdates = {}
    local GuiTheme = 1 
    local Theme = {
        MainBg = GuiTheme == 1 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(11, 11, 11),
        TabFrameBg = GuiTheme == 1 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(16, 16, 16),
        SectionBg = GuiTheme == 1 and Color3.fromRGB(4, 4, 4) or Color3.fromRGB(14, 14, 14),
        SectionOutline = GuiTheme == 1 and Color3.fromRGB(12, 12, 12) or Color3.fromRGB(24, 24, 24),
        TabButton = GuiTheme == 1 and Color3.fromRGB(12, 12, 12) or Color3.fromRGB(30, 30, 30),
        TabButtonActive = GuiTheme == 1 and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(44, 44, 44),
        TextMain = Color3.fromRGB(255, 255, 255),
        TextCategory = Color3.fromRGB(77, 77, 77),
        ToggleActive = GuiTheme == 1 and Color3.fromRGB(153, 255, 51) or Color3.fromRGB(255, 127, 211), 
        ToggleInactive = GuiTheme == 1 and Color3.fromRGB(12, 12, 12) or Color3.fromRGB(44, 44, 44),
        ElementBg = GuiTheme == 1 and Color3.fromRGB(12, 12, 12) or Color3.fromRGB(30, 30, 30),
        Font = Enum.Font.GothamBold,
        LabelFont = Enum.Font.Gotham
    }
    local function ApplyAccent()
        for _, func in AccentUpdates do
            pcall(func, Theme.ToggleActive)
        end
    end
    local ESP_Objects = {}
    local WeaponDecals = {
        M4 = "rbxthumb://type=Asset&id=16010744953&w=420&h=420",
        Pistol = "rbxthumb://type=Asset&id=15571374080&w=420&h=420",
        Sniper = "rbxthumb://type=Asset&id=15571370793&w=420&h=420",
        Shotgun = "rbxthumb://type=Asset&id=113518705567829&w=420&h=420",
        AK = "rbxthumb://type=Asset&id=121279676616739&w=420&h=420",
        SMG = "rbxthumb://type=Asset&id=16057575272&w=420&h=420"
    }
    function Utility:GetWeaponIcon(weaponName)
        weaponName = string.lower(tostring(weaponName or ""))
        if string.find(weaponName, "ak") or string.find(weaponName, "kalash") then return WeaponDecals.AK
        elseif string.find(weaponName, "m4") or string.find(weaponName, "ar") or string.find(weaponName, "rifle") or string.find(weaponName, "aug") or string.find(weaponName, "famas") then return WeaponDecals.M4
        elseif string.find(weaponName, "snip") or string.find(weaponName, "awp") or string.find(weaponName, "scout") or string.find(weaponName, "ssg") then return WeaponDecals.Sniper
        elseif string.find(weaponName, "shot") or string.find(weaponName, "pump") or string.find(weaponName, "spas") or string.find(weaponName, "nova") then return WeaponDecals.Shotgun
        elseif string.find(weaponName, "smg") or string.find(weaponName, "p90") or string.find(weaponName, "mac") or string.find(weaponName, "mp") or string.find(weaponName, "uzi") then return WeaponDecals.SMG
        else return WeaponDecals.Pistol end
    end
    function Utility:CreateESP()
        local esp = {
            Box = Drawing.new("Square"),
            BoxFills = {},
            BoxGlows = {},
            BoxOutline = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            HealthBar = Drawing.new("Square"),
            HealthBarGlows = {},
            HealthBarOutline = Drawing.new("Square"),
            HealthNumber = Drawing.new("Text"),
            Corners = {},
            Skeletons = {},
            HealthBarSegments = {},
            Flags = {
                Ping = Drawing.new("Text"),
                AFK = Drawing.new("Text"),
                Lethal = Drawing.new("Text")
            },
            OffscreenArrow = Drawing.new("Triangle"),
            OffscreenArrowOutline = Drawing.new("Triangle"),
            LastPos = Vector3.new(),
            LastMoveTime = os.clock()
        }
        for i = 1, 15 do
            local seg = Drawing.new("Square")
            seg.Thickness = 1
            seg.Filled = true
            seg.ZIndex = 2
            esp.HealthBarSegments[i] = seg
        end
        for i = 1, 6 do
            local glow = Drawing.new("Square")
            glow.Thickness = 1
            glow.Filled = false
            glow.ZIndex = 0
            esp.HealthBarGlows[i] = glow
        end
        for i = 1, 8 do
            local bglow = Drawing.new("Square")
            bglow.Thickness = 1
            bglow.Filled = false
            bglow.ZIndex = 0
            esp.BoxGlows[i] = bglow
        end
        esp.Box.Thickness = 1
        esp.Box.Filled = false
        esp.Box.ZIndex = 2
        for i = 1, 40 do
            local bfill = Drawing.new("Square")
            bfill.Thickness = 0
            bfill.Filled = true
            bfill.ZIndex = 1
            esp.BoxFills[i] = bfill
        end
        esp.BoxOutline.Thickness = 3
        esp.BoxOutline.Filled = false
        esp.BoxOutline.ZIndex = 1
        esp.Name.Center = true
        esp.Name.Outline = true
        esp.Name.ZIndex = 3
        esp.HealthBar.Thickness = 1
        esp.HealthBar.Filled = true
        esp.HealthBar.ZIndex = 2
        esp.HealthBarOutline.Thickness = 1
        esp.HealthBarOutline.Filled = true
        esp.HealthBarOutline.ZIndex = 1
        esp.HealthNumber.Center = true
        esp.HealthNumber.Outline = true
        esp.HealthNumber.ZIndex = 3
        for i = 1, 8 do
            local line = Drawing.new("Line")
            line.Thickness = 1
            line.ZIndex = 2
            local shadow = Drawing.new("Line")
            shadow.Thickness = 3
            shadow.ZIndex = 1
            esp.Corners[i] = {Main = line, Shadow = shadow}
        end
        for i = 1, 14 do
            local line = Drawing.new("Line")
            line.Thickness = 1
            line.ZIndex = 2
            local shadow = Drawing.new("Line")
            shadow.Thickness = 3
            shadow.ZIndex = 1
            esp.Skeletons[i] = {Main = line, Shadow = shadow}
        end
        esp.Flags.Ping.Center = false
        esp.Flags.Ping.Outline = true
        esp.Flags.Ping.ZIndex = 3
        esp.Flags.AFK.Center = false
        esp.Flags.AFK.Outline = true
        esp.Flags.AFK.ZIndex = 3
        esp.Flags.Lethal.Center = false
        esp.Flags.Lethal.Outline = true
        esp.Flags.Lethal.ZIndex = 3
        esp.OffscreenArrow.Filled = true
        esp.OffscreenArrow.Thickness = 1
        esp.OffscreenArrow.ZIndex = 2
        esp.OffscreenArrowOutline.Filled = false
        esp.OffscreenArrowOutline.Thickness = 2
        esp.OffscreenArrowOutline.ZIndex = 1
        local mainGui = game:GetService("CoreGui"):FindFirstChild("LocalMazeGUI") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("LocalMazeGUI")
        local wm_CoreGui = game:GetService("CoreGui")
        local weaponGui = wm_CoreGui:FindFirstChild("WeaponESPGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("WeaponESPGui")
        if not weaponGui then
            weaponGui = Instance.new("ScreenGui")
            weaponGui.Name = "WeaponESPGui"
            weaponGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            weaponGui.IgnoreGuiInset = true
            weaponGui.DisplayOrder = 100
            local s = pcall(function() weaponGui.Parent = game:GetService("CoreGui") end)
            if not s then weaponGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end
        end
        local weaponIcon = Instance.new("ImageLabel")
        weaponIcon.BackgroundTransparency = 1
        weaponIcon.Size = UDim2.new(0, 40, 0, 20)
        weaponIcon.ScaleType = Enum.ScaleType.Stretch
        weaponIcon.Visible = false
        weaponIcon.ZIndex = 10
        weaponIcon.Parent = weaponGui
        esp.WeaponIcon = weaponIcon
        return esp
    end
    function Utility:Create(class, properties)
        local instance = Instance.new(class)
        for k, v in properties do
            instance[k] = v
        end
        return instance
    end
    do
        local notifyGui = Instance.new("ScreenGui")
        notifyGui.Name = "ClarityNotifications"
        notifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        pcall(function() notifyGui.Parent = CoreGui end)
        if notifyGui.Parent == nil then
            notifyGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        end
        local notifyListTL = Instance.new("Frame", notifyGui)
        notifyListTL.BackgroundTransparency = 1
        notifyListTL.Size = UDim2.new(0, 300, 1, -32)
        notifyListTL.Position = UDim2.new(0, 10, 0, 16)
        local listLayoutTL = Instance.new("UIListLayout", notifyListTL)
        listLayoutTL.Padding = UDim.new(0, 10)
        listLayoutTL.SortOrder = Enum.SortOrder.LayoutOrder
        listLayoutTL.VerticalAlignment = Enum.VerticalAlignment.Top
        listLayoutTL.HorizontalAlignment = Enum.HorizontalAlignment.Left
        local notifyListBC = Instance.new("Frame", notifyGui)
        notifyListBC.BackgroundTransparency = 1
        notifyListBC.Size = UDim2.new(0, 300, 1, -100)
        notifyListBC.Position = UDim2.new(0.5, -150, 0, 0)
        local listLayoutBC = Instance.new("UIListLayout", notifyListBC)
        listLayoutBC.Padding = UDim.new(0, 10)
        listLayoutBC.SortOrder = Enum.SortOrder.LayoutOrder
        listLayoutBC.VerticalAlignment = Enum.VerticalAlignment.Bottom
        listLayoutBC.HorizontalAlignment = Enum.HorizontalAlignment.Center
        local notificationQueue = {}
        function Library:Notify(text, duration, pos)
            duration = duration or 3
            pos = pos or "Top Left"
            table.insert(notificationQueue, {text = text, duration = duration, pos = pos})
        end
        game:GetService("RunService").Heartbeat:Connect(function()
            while #notificationQueue > 0 do
                local notif = table.remove(notificationQueue, 1)
                local text, duration, pos = notif.text, notif.duration, notif.pos
                task.spawn(function()
                    local targetList = pos == "Bottom Center" and notifyListBC or notifyListTL
                    local plainText = string.gsub(text, "<[^>]+>", "")
                    local textService = game:GetService("TextService")
                    local textBounds = textService:GetTextSize(plainText, 20, Enum.Font.TitilliumWeb, Vector2.new(1000, 32))
                    local frameWidth = textBounds.X + 24
                    local notifyFrame = Instance.new("Frame")
                    notifyFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
                    notifyFrame.BorderSizePixel = 0
                    notifyFrame.Size = UDim2.new(0, 0, 0, 32)
                    notifyFrame.ClipsDescendants = true
                    notifyFrame.Parent = targetList
                    local uiCorner = Instance.new("UICorner", notifyFrame)
                    uiCorner.CornerRadius = UDim.new(0, 3)
                    local textLabel = Instance.new("TextLabel", notifyFrame)
                    textLabel.BackgroundTransparency = 1
                    textLabel.Size = UDim2.new(1, 0, 1, 0)
                    textLabel.Font = Enum.Font.TitilliumWeb
                    textLabel.TextSize = 20
                    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    textLabel.RichText = true
                    textLabel.Text = text
                    textLabel.TextXAlignment = Enum.TextXAlignment.Center
                    textLabel.TextYAlignment = Enum.TextYAlignment.Center
                    local timebar = Instance.new("Frame", notifyFrame)
                    timebar.BorderSizePixel = 0
                    timebar.BackgroundColor3 = Theme.ToggleActive
                    timebar.Size = UDim2.new(1, -4, 0, 2)
                    timebar.Position = UDim2.new(0, 2, 0, 0)
                    local tbCorner = Instance.new("UICorner", timebar)
                    tbCorner.CornerRadius = UDim.new(0, 3)
                    table.insert(AccentUpdates, function()
                        if timebar and timebar.Parent then
                            timebar.BackgroundColor3 = Theme.ToggleActive
                        end
                    end)
                    local inTween = TweenService:Create(notifyFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, frameWidth, 0, 32)})
                    inTween:Play()
                    inTween.Completed:Wait()
                    TweenService:Create(timebar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
                    task.delay(duration, function()
                        local tw = TweenService:Create(notifyFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 32)})
                        tw:Play()
                        tw.Completed:Wait()
                        notifyFrame:Destroy()
                    end)
                end)
            end
        end)
    end
    function Utility:MakeDraggable(topbar, window)
        local dragging
        local dragInput
        local dragStart
        local startPos
        topbar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = window.Position
                local moveConn, endConn
                moveConn = UserInputService.InputChanged:Connect(function(moveInput)
                    if moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch then
                        local delta = moveInput.Position - dragStart
                        window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                    end
                end)
                endConn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if moveConn then moveConn:Disconnect() end
                        if endConn then endConn:Disconnect() end
                    end
                end)
            end
        end)
    end
    function Library:CreateWindow(options)
        options = options or {}
        local windowTitle = options.Title or "Script is Loaded!"
        local windowSize = options.Size or UDim2.new(0, 836, 0, 538)
        local ScreenGui = Utility:Create("ScreenGui", {
            Name = "LocalMazeGUI",
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            ResetOnSpawn = false
        })
        local toggleKey = options.ToggleKey or Enum.KeyCode.Insert
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.KeyCode == toggleKey then
                ScreenGui.Enabled = not ScreenGui.Enabled
            end
        end)
        local success = pcall(function() ScreenGui.Parent = CoreGui end)
        if not success then ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end
        function Library:IsGuiOpen()
            return ScreenGui.Enabled
        end
        local PopupBg = Utility:Create("TextButton", {
            Name = "PopupBg",
            Parent = ScreenGui,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 100,
            Visible = false,
            Text = "",
            AutoButtonColor = false
        })
        local PopupConnections = {}
        PopupBg.MouseButton1Click:Connect(function() 
            PopupBg.Visible = false
            for _, conn in PopupConnections do
                if conn.Disconnect then conn:Disconnect() end
            end
            table.clear(PopupConnections)
        end)
        local PopupOutline = Utility:Create("Frame", {
            Name = "PopupOutline",
            Parent = PopupBg,
            BackgroundColor3 = Theme.SectionOutline,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 291, 0, 282),
            ZIndex = 101
        })
        Utility:Create("UICorner", { Parent = PopupOutline, CornerRadius = UDim.new(0, 8) })
        local PopupFrame = Utility:Create("Frame", {
            Name = "PopupFrame",
            Parent = PopupOutline,
            BackgroundColor3 = Theme.MainBg,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 101
        })
        Utility:Create("UICorner", { Parent = PopupFrame, CornerRadius = UDim.new(0, 8) })
        local PopupTitle = Utility:Create("TextLabel", {
            Parent = PopupFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(1, -20, 0, 16),
            Font = Theme.Font, Text = "Settings", TextColor3 = Theme.TextMain, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102
        })
        local PopupContent = Utility:Create("Frame", {
            Parent = PopupFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 32), Size = UDim2.new(1, -20, 1, -42),
            ZIndex = 102
        })
        local PopupLayout = Utility:Create("UIListLayout", { Parent = PopupContent, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
        PopupLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
            PopupOutline.Size = UDim2.new(0, 291, 0, PopupLayout.AbsoluteContentSize.Y + 44)
        end)
        local CPPopupBg = Utility:Create("TextButton", {
            Name = "CPPopupBg",
            Parent = ScreenGui,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 200,
            Visible = false,
            Text = "",
            AutoButtonColor = false
        })
        local CPPopupConnections = {}
        CPPopupBg.MouseButton1Click:Connect(function() 
            CPPopupBg.Visible = false
            for _, conn in CPPopupConnections do
                if conn.Disconnect then conn:Disconnect() end
            end
            table.clear(CPPopupConnections)
        end)
        local CPPopupOutline = Utility:Create("Frame", {
            Name = "CPPopupOutline",
            Parent = CPPopupBg,
            BackgroundColor3 = Theme.SectionOutline,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 291, 0, 282),
            ZIndex = 201
        })
        Utility:Create("UICorner", { Parent = CPPopupOutline, CornerRadius = UDim.new(0, 8) })
        local CPPopupFrame = Utility:Create("Frame", {
            Name = "CPPopupFrame",
            Parent = CPPopupOutline,
            BackgroundColor3 = Theme.MainBg,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 201
        })
        Utility:Create("UICorner", { Parent = CPPopupFrame, CornerRadius = UDim.new(0, 8) })
        local CPPopupTitle = Utility:Create("TextLabel", {
            Parent = CPPopupFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(1, -20, 0, 16),
            Font = Theme.Font, Text = "Settings", TextColor3 = Theme.TextMain, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 202
        })
        local CPPopupContent = Utility:Create("Frame", {
            Parent = CPPopupFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 32), Size = UDim2.new(1, -20, 1, -42),
            ZIndex = 202
        })
        local CPPopupLayout = Utility:Create("UIListLayout", { Parent = CPPopupContent, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
        CPPopupLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
            CPPopupOutline.Size = UDim2.new(0, 291, 0, CPPopupLayout.AbsoluteContentSize.Y + 44)
        end)
        local function OpenCPModal(title, setupFunc, sourceElement)
            CPPopupTitle.Text = title
            for _, conn in CPPopupConnections do
                if conn.Disconnect then conn:Disconnect() end
            end
            table.clear(CPPopupConnections)
            for _, child in CPPopupContent:GetChildren() do
                if not child:IsA("UIListLayout") then 
                    if child:GetAttribute("Cached") then
                        child.Parent = nil
                    else
                        child:Destroy() 
                    end
                end
            end
            setupFunc(CPPopupContent)
            if sourceElement then
                local absPos = sourceElement.AbsolutePosition
                local absSize = sourceElement.AbsoluteSize
                local screenX = ScreenGui.AbsoluteSize.X
                local screenY = ScreenGui.AbsoluteSize.Y
                local targetX = absPos.X + absSize.X + 10
                local targetY = absPos.Y
                if targetX + 291 > screenX then
                    targetX = absPos.X - 291 - 10
                end
                if targetY + CPPopupOutline.AbsoluteSize.Y > screenY then
                    targetY = screenY - CPPopupOutline.AbsoluteSize.Y - 10
                end
                CPPopupOutline.Position = UDim2.new(0, targetX, 0, targetY)
            else
                CPPopupOutline.Position = UDim2.new(0.5, -145, 0.5, -141)
            end
            CPPopupBg.Visible = true
        end
        local function OpenModal(title, setupFunc, sourceElement)
            PopupTitle.Text = title
            for _, conn in PopupConnections do
                if conn.Disconnect then conn:Disconnect() end
            end
            table.clear(PopupConnections)
            for _, child in PopupContent:GetChildren() do
                if not child:IsA("UIListLayout") then 
                    if child:GetAttribute("Cached") then
                        child.Parent = nil
                    else
                        child:Destroy() 
                    end
                end
            end
            setupFunc(PopupContent)
            if sourceElement then
                local absPos = sourceElement.AbsolutePosition
                local absSize = sourceElement.AbsoluteSize
                local screenX = ScreenGui.AbsoluteSize.X
                local screenY = ScreenGui.AbsoluteSize.Y
                local targetX = absPos.X + absSize.X + 10
                local targetY = absPos.Y
                if targetX + 291 > screenX then
                    targetX = absPos.X - 291 - 10
                end
                if targetY + PopupOutline.AbsoluteSize.Y > screenY then
                    targetY = screenY - PopupOutline.AbsoluteSize.Y - 10
                end
                PopupOutline.Position = UDim2.new(0, targetX, 0, targetY)
            else
                PopupOutline.Position = UDim2.new(0.5, -145, 0.5, -141)
            end
            PopupBg.Visible = true
        end
        local function OpenColorPicker(title, defaultColor, defaultAlpha, callback, sourceElement)
            OpenCPModal(title, function(container)
                local currentColor = defaultColor or Color3.new(1, 1, 1)
                local currentAlpha = defaultAlpha or 1
                local colorCb = callback or function() end
                local h, s, v = currentColor:ToHSV()
                local ColorContainer = Utility:Create("Frame", { Parent = container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 120), ZIndex = 102 })
                local SVMap = Utility:Create("TextButton", { Parent = ColorContainer, BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 0, 0, 0), Text = "", AutoButtonColor = false, ClipsDescendants = true, ZIndex = 102 })
                Utility:Create("UICorner", { Parent = SVMap, CornerRadius = UDim.new(0, 4) })
                local SatOverlay = Utility:Create("Frame", { Parent = SVMap, BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1, 0, 1, 0), ZIndex = 103 })
                Utility:Create("UIGradient", { Parent = SatOverlay, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}), Rotation = 0 })
                local ValOverlay = Utility:Create("Frame", { Parent = SVMap, BackgroundColor3 = Color3.new(0,0,0), Size = UDim2.new(1, 0, 1, 0), ZIndex = 104 })
                Utility:Create("UIGradient", { Parent = ValOverlay, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}), Rotation = 90 })
                local PickerRing = Utility:Create("Frame", { Parent = SVMap, BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(0, 6, 0, 6), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(s, 0, 1-v, 0), ZIndex = 105 })
                Utility:Create("UICorner", { Parent = PickerRing, CornerRadius = UDim.new(1, 0) })
                Utility:Create("UIStroke", { Parent = PickerRing, Color = Color3.new(0,0,0), Thickness = 1 })
                local HueBar = Utility:Create("TextButton", { Parent = ColorContainer, Position = UDim2.new(1, -34, 0, 0), Size = UDim2.new(0, 16, 1, 0), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 102 })
                Utility:Create("UICorner", { Parent = HueBar, CornerRadius = UDim.new(0, 4) })
                local HueGradient = Utility:Create("UIGradient", { Parent = HueBar, Rotation = 90 })
                HueGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                })
                local HueRing = Utility:Create("Frame", { Parent = HueBar, BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1, 2, 0, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, h, 0), ZIndex = 106 })
                Utility:Create("UIStroke", { Parent = HueRing, Color = Color3.new(0,0,0), Thickness = 1 })
                local AlphaBar = Utility:Create("TextButton", { Parent = ColorContainer, Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0, 12, 1, 0), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 102 })
                Utility:Create("UICorner", { Parent = AlphaBar, CornerRadius = UDim.new(0, 4) })
                local AlphaGradient = Utility:Create("UIGradient", { Parent = AlphaBar, Rotation = 90 })
                AlphaGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, currentColor), ColorSequenceKeypoint.new(1, Theme.ElementBg) })
                local AlphaRing = Utility:Create("Frame", { Parent = AlphaBar, BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1, 2, 0, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1-currentAlpha, 0), ZIndex = 106 })
                Utility:Create("UIStroke", { Parent = AlphaRing, Color = Color3.new(0,0,0), Thickness = 1 })
                local BottomContainer = Utility:Create("Frame", { Parent = container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), ZIndex = 102 })
                local PreviewBox = Utility:Create("Frame", { Parent = BottomContainer, BackgroundColor3 = currentColor, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), ZIndex = 102 })
                Utility:Create("UICorner", { Parent = PreviewBox, CornerRadius = UDim.new(0, 4) })
                local draggingSV, draggingHue, draggingAlpha = false, false, false
                local function updateColor()
                    currentColor = Color3.fromHSV(h, s, v)
                    PreviewBox.BackgroundColor3 = currentColor
                    PreviewBox.BackgroundTransparency = 1 - currentAlpha
                    AlphaGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, currentColor), ColorSequenceKeypoint.new(1, Theme.ElementBg) })
                    colorCb(currentColor, currentAlpha)
                end
                local function updateSV(input)
                    local x = math.clamp(input.Position.X - SVMap.AbsolutePosition.X, 0, SVMap.AbsoluteSize.X)
                    local y = math.clamp(input.Position.Y - SVMap.AbsolutePosition.Y, 0, SVMap.AbsoluteSize.Y)
                    s = x / SVMap.AbsoluteSize.X; v = 1 - (y / SVMap.AbsoluteSize.Y)
                    PickerRing.Position = UDim2.new(s, 0, 1-v, 0); updateColor()
                end
                local function updateHue(input)
                    local y = math.clamp(input.Position.Y - HueBar.AbsolutePosition.Y, 0, HueBar.AbsoluteSize.Y)
                    h = y / HueBar.AbsoluteSize.Y
                    HueRing.Position = UDim2.new(0.5, 0, h, 0); SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1); updateColor()
                end
                local function updateAlpha(input)
                    local y = math.clamp(input.Position.Y - AlphaBar.AbsolutePosition.Y, 0, AlphaBar.AbsoluteSize.Y)
                    currentAlpha = 1 - (y / AlphaBar.AbsoluteSize.Y)
                    AlphaRing.Position = UDim2.new(0.5, 0, y / AlphaBar.AbsoluteSize.Y, 0); updateColor()
                end
                SVMap.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = true; updateSV(input) end end)
                HueBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = true; updateHue(input) end end)
                AlphaBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingAlpha = true; updateAlpha(input) end end)
                local c1 = UserInputService.InputEnded:Connect(function(input) 
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV, draggingHue, draggingAlpha = false, false, false end 
                end)
                local c2 = UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement then
                        if draggingSV then updateSV(input) end
                        if draggingHue then updateHue(input) end
                        if draggingAlpha then updateAlpha(input) end
                    end
                end)
                table.insert(CPPopupConnections, c1); table.insert(CPPopupConnections, c2)
            end, sourceElement)
        end
        local MainOutlineFrame = Utility:Create("Frame", {
            Name = "MainOutlineFrame",
            Parent = ScreenGui,
            BackgroundColor3 = Theme.SectionOutline,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, -windowSize.X.Offset/2 - 1, 0.5, -windowSize.Y.Offset/2 - 1),
            Size = UDim2.new(windowSize.X.Scale, windowSize.X.Offset + 2, windowSize.Y.Scale, windowSize.Y.Offset + 2),
            Active = true
        })
        Utility:Create("UICorner", { Parent = MainOutlineFrame, CornerRadius = UDim.new(0, 8) })
        local MainFrame = Utility:Create("Frame", {
            Name = "MainFrame",
            Parent = MainOutlineFrame,
            BackgroundColor3 = Theme.MainBg,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            Active = false
        })
        Utility:Create("UICorner", { Parent = MainFrame, CornerRadius = UDim.new(0, 8) })
        local TabFrame = Utility:Create("Frame", {
            Name = "tabframe",
            Parent = MainFrame,
            BackgroundColor3 = Theme.TabFrameBg,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 175, 1, 0)
        })
        Utility:Create("UICorner", { Parent = TabFrame, CornerRadius = UDim.new(0, 8) })
        if GuiTheme == 1 then
            local TopIcon = Utility:Create("ImageLabel", {
                Name = "TopIcon",
                Parent = TabFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 10),
                Size = UDim2.new(1, -20, 0, 50),
                Image = "rbxthumb://type=Asset&id=71503198986463&w=150&h=150",
                ImageColor3 = Theme.ToggleActive,
                ScaleType = Enum.ScaleType.Fit,
                Active = true
            })
            Utility:MakeDraggable(TopIcon, MainOutlineFrame)
            table.insert(AccentUpdates, function(col)
                TopIcon.ImageColor3 = col
            end)
        end
        local TabButtonContainer = Utility:Create("Frame", {
            Name = "TabButtonContainer",
            Parent = TabFrame,
            BackgroundTransparency = 1,
            Position = GuiTheme == 1 and UDim2.new(0, 10, 0, 70) or UDim2.new(0, 10, 0, 10),
            Size = GuiTheme == 1 and UDim2.new(1, -20, 1, -80) or UDim2.new(1, -20, 1, -20)
        })
        local TabListLayout = Utility:Create("UIListLayout", {
            Parent = TabButtonContainer,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 0)
        })
        local PageContainer = Utility:Create("Frame", {
            Name = "PageContainer",
            Parent = MainFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 185, 0, 10),
            Size = UDim2.new(1, -195, 1, -20)
        })
        local Window = {}
        local Tabs = {}
        local tabCount = 2
        local KeybindRegistry = Library.KeybindRegistry
        UserInputService.InputBegan:Connect(function(input, gp)
            for _, bind in KeybindRegistry do
                if bind.isBindingFunc() then
                    bind.onBegan(input)
                    return
                end
            end
            if UserInputService:GetFocusedTextBox() == nil then
                for _, bind in KeybindRegistry do
                    local key = bind.getKey()
                    if key and (input.KeyCode == key or input.UserInputType == key) then
                        bind.onKeyDown()
                    end
                end
            end
        end)
        UserInputService.InputEnded:Connect(function(input, gp)
            if UserInputService:GetFocusedTextBox() == nil then
                for _, bind in KeybindRegistry do
                    local key = bind.getKey()
                    if key and (input.KeyCode == key or input.UserInputType == key) then
                        bind.onKeyUp()
                    end
                end
            end
        end)
        function Window:CreateCategory(name)
            if GuiTheme == 1 then return end
            Utility:Create("TextLabel", {
                Parent = TabButtonContainer,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
                Font = Theme.Font,
                Text = "   " .. name,
                TextColor3 = Theme.TextCategory,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = tabCount
            })
            tabCount = tabCount + 1
        end
        function Window:CreateTab(name, iconId)
            local tabName = GuiTheme == 1 and name:lower() or name
            local inactiveColor = GuiTheme == 1 and Theme.TextMain or Color3.fromRGB(130, 130, 130)
            local currentTabOrder = tabCount
            tabCount = tabCount + 2
            local TabBtn = Utility:Create("TextButton", {
                Name = "TabButton_" .. name,
                Parent = TabButtonContainer,
                BackgroundColor3 = Theme.TabFrameBg,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 32),
                Font = Theme.LabelFont,
                Text = (iconId and "          " or "   ") .. tabName,
                TextColor3 = inactiveColor,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                LayoutOrder = currentTabOrder
            })
            Utility:Create("UICorner", { Parent = TabBtn, CornerRadius = UDim.new(0, 6) })
            local SubTabContainer = Utility:Create("Frame", {
                Name = "SubTabContainer_" .. name,
                Parent = TabButtonContainer,
                BackgroundColor3 = GuiTheme == 1 and Color3.fromRGB(4, 4, 4) or Color3.fromRGB(20, 20, 20),
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                ClipsDescendants = true,
                Visible = false,
                LayoutOrder = currentTabOrder + 1
            })
            Utility:Create("UICorner", { Parent = SubTabContainer, CornerRadius = UDim.new(0, 4) })
            local SubTabLayout = Utility:Create("UIListLayout", {
                Parent = SubTabContainer,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 0)
            })
            SubTabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SubTabContainer.Size = UDim2.new(1, 0, 0, SubTabLayout.AbsoluteContentSize.Y)
            end)
            local TabIcon
            if iconId then
                TabIcon = Utility:Create("ImageLabel", {
                    Parent = TabBtn, BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0.5, -8), Size = UDim2.new(0, 16, 0, 16),
                    Image = "rbxthumb://type=Asset&id=" .. iconId .. "&w=150&h=150", ImageColor3 = GuiTheme == 1 and Theme.ToggleActive or Color3.fromRGB(130, 130, 130)
                })
                if GuiTheme == 1 then
                    table.insert(AccentUpdates, function(col)
                        TabIcon.ImageColor3 = col
                    end)
                end
            end
            local Page = Utility:Create("Frame", {
                Name = "Page_" .. name,
                Parent = PageContainer,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Visible = false
            })
            local LeftCol = Utility:Create("ScrollingFrame", {
                Name = "LeftColumn", Parent = Page, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0.5, -5, 1, 0), ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.TextCategory, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0)
            })
            local LeftLayout = Utility:Create("UIListLayout", { Parent = LeftCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center })
            local RightCol = Utility:Create("ScrollingFrame", {
                Name = "RightColumn", Parent = Page, BackgroundTransparency = 1, Position = UDim2.new(0.5, 5, 0, 0), Size = UDim2.new(0.5, -5, 1, 0), ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.TextCategory, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0)
            })
            local RightLayout = Utility:Create("UIListLayout", { Parent = RightCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center })
            LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() LeftCol.CanvasSize = UDim2.new(0, 0, 0, LeftLayout.AbsoluteContentSize.Y + 10) end)
            RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() RightCol.CanvasSize = UDim2.new(0, 0, 0, RightLayout.AbsoluteContentSize.Y + 10) end)
            local TabObj = { SubTabs = {}, Expanded = false }
            local tabData = {Btn = TabBtn, Page = Page, Icon = TabIcon, IsSubTab = false, ParentTab = nil}
            table.insert(Tabs, tabData)
            tabData.Collapse = function()
                TabObj.Expanded = false
                SubTabContainer.Visible = false
            end
            local function ActivateTab()
                for _, t in Tabs do
                    t.Page.Visible = false
                    if t.IsSubTab then
                        t.Btn.TextColor3 = t.InactiveColor
                        t.Btn.Font = Theme.LabelFont
                    else
                        t.Btn.BackgroundColor3 = Theme.TabFrameBg
                        t.Btn.TextColor3 = t.InactiveColor
                        t.Btn.Font = Theme.LabelFont
                        if t.Icon then t.Icon.ImageColor3 = GuiTheme == 1 and Theme.ToggleActive or Color3.fromRGB(130, 130, 130) end
                        if t.Collapse and t.Btn ~= TabBtn then t.Collapse() end
                    end
                end
                TabBtn.BackgroundColor3 = Theme.TabButton
                TabBtn.TextColor3 = Theme.TextMain
                TabBtn.Font = Theme.Font
                if TabIcon then TabIcon.ImageColor3 = GuiTheme == 1 and Theme.ToggleActive or Theme.TextMain end
                if #TabObj.SubTabs > 0 then
                    TabObj.Expanded = true
                    SubTabContainer.Visible = true
                    local anyVisible = false
                    for _, sub in TabObj.SubTabs do
                        if sub.Page.Visible then anyVisible = true break end
                    end
                    if not anyVisible and TabObj.SubTabs[1] then
                        TabObj.SubTabs[1].Activate()
                    end
                else
                    Page.Visible = true
                end
            end
            tabData.Activate = ActivateTab
            tabData.InactiveColor = inactiveColor
            TabBtn.MouseButton1Click:Connect(ActivateTab)
            if #Tabs == 1 then
                ActivateTab()
            end
            local subTabCount = 0
            function TabObj:CreateSubTab(subName)
                local subTabName = GuiTheme == 1 and subName:lower() or subName
                local subInactiveColor = GuiTheme == 1 and Theme.TextMain or Color3.fromRGB(130, 130, 130)
                local SubBtn = Utility:Create("TextButton", {
                    Name = "SubTabButton_" .. subName,
                    Parent = SubTabContainer,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 26),
                    Font = Theme.LabelFont,
                    Text = (iconId and "          " or "   ") .. subTabName,
                    TextColor3 = subInactiveColor,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                    LayoutOrder = subTabCount,
                    Visible = true
                })
                subTabCount = subTabCount + 1
                local SubPage = Utility:Create("Frame", {
                    Name = "Page_" .. name .. "_" .. subName,
                    Parent = PageContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Visible = false
                })
                local SLeftCol = Utility:Create("ScrollingFrame", {
                    Name = "LeftColumn", Parent = SubPage, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0.5, -5, 1, 0), ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.TextCategory, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0)
                })
                local SLeftLayout = Utility:Create("UIListLayout", { Parent = SLeftCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center })
                local SRightCol = Utility:Create("ScrollingFrame", {
                    Name = "RightColumn", Parent = SubPage, BackgroundTransparency = 1, Position = UDim2.new(0.5, 5, 0, 0), Size = UDim2.new(0.5, -5, 1, 0), ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.TextCategory, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0)
                })
                local SRightLayout = Utility:Create("UIListLayout", { Parent = SRightCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center })
                SLeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() SLeftCol.CanvasSize = UDim2.new(0, 0, 0, SLeftLayout.AbsoluteContentSize.Y + 10) end)
                SRightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() SRightCol.CanvasSize = UDim2.new(0, 0, 0, SRightLayout.AbsoluteContentSize.Y + 10) end)
                local subData = {Btn = SubBtn, Page = SubPage, IsSubTab = true, ParentTab = TabBtn, InactiveColor = subInactiveColor}
                table.insert(Tabs, subData)
                table.insert(TabObj.SubTabs, subData)
                local function ActivateSubTab()
                    for _, t in Tabs do
                        t.Page.Visible = false
                        if t.IsSubTab then
                            t.Btn.TextColor3 = t.InactiveColor
                            t.Btn.Font = Theme.LabelFont
                        else
                            t.Btn.BackgroundColor3 = Theme.TabFrameBg
                            t.Btn.TextColor3 = t.InactiveColor
                            t.Btn.Font = Theme.LabelFont
                            if t.Icon then t.Icon.ImageColor3 = GuiTheme == 1 and Theme.ToggleActive or Color3.fromRGB(130, 130, 130) end
                            if t.Collapse and t.Btn ~= TabBtn then t.Collapse() end
                        end
                    end
                    SubPage.Visible = true
                    SubBtn.TextColor3 = Theme.ToggleActive
                    SubBtn.Font = Theme.Font
                    TabBtn.BackgroundColor3 = Theme.TabButton
                    TabBtn.TextColor3 = Theme.TextMain
                    if TabIcon then TabIcon.ImageColor3 = GuiTheme == 1 and Theme.ToggleActive or Theme.TextMain end
                    TabObj.Expanded = true
                    SubTabContainer.Visible = true
                end
                subData.Activate = ActivateSubTab
                SubBtn.MouseButton1Click:Connect(ActivateSubTab)
                local SubObj = {}
                function SubObj:CreateSection(options)
                    return TabObj.BuildSection(options, SLeftCol, SRightCol)
                end
                return SubObj
            end
            function TabObj:CreateSection(options)
                return TabObj.BuildSection(options, LeftCol, RightCol)
            end
            function TabObj.BuildSection(options, lCol, rCol)
                options = options or {}
                local secName = options.Name or "Section"
                local side = options.Side or "Left"
                local targetCol = (side:lower() == "left") and lCol or rCol
                local SectionOutlineFrame = Utility:Create("Frame", {
                    Name = "ChildOutline_" .. secName,
                    Parent = targetCol,
                    BackgroundColor3 = Theme.SectionOutline,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -4, 0, 42)
                })
                Utility:Create("UICorner", { Parent = SectionOutlineFrame, CornerRadius = UDim.new(0, 6) })
                local SectionFrame = Utility:Create("Frame", {
                    Name = "Child_" .. secName,
                    Parent = SectionOutlineFrame,
                    BackgroundColor3 = Theme.SectionBg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -2, 1, -2),
                    Position = UDim2.new(0, 1, 0, 1)
                })
                Utility:Create("UICorner", { Parent = SectionFrame, CornerRadius = UDim.new(0, 6) })
                local SectionTitle = Utility:Create("TextLabel", {
                    Parent = SectionFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 5),
                    Size = UDim2.new(1, -24, 0, 20),
                    Font = GuiTheme == 1 and Theme.Font or Theme.LabelFont,
                    Text = GuiTheme == 1 and secName:lower() or secName,
                    TextColor3 = GuiTheme == 1 and Theme.TextMain or Theme.TextCategory,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local SectionSeparator = Utility:Create("Frame", {
                    Parent = SectionFrame,
                    BackgroundColor3 = Theme.SectionOutline,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0, 27),
                    Size = UDim2.new(1, 0, 0, 1)
                })
                local ContentContainer = Utility:Create("Frame", {
                    Parent = SectionFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 1, -30)
                })
                local SectionLayout = Utility:Create("UIListLayout", {
                    Parent = ContentContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center
                })
                SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    SectionOutlineFrame.Size = UDim2.new(1, -4, 0, SectionLayout.AbsoluteContentSize.Y + 42)
                end)
                local Elements = {}
                function Elements:CreateToggle(opts)
                    opts = opts or {}
                    local togText = opts.Name or "Toggle"
                    local state = opts.Default or false
                    local callback = opts.Callback or function() end
                    local targetContainer = opts.Container or ContentContainer
                    local ToggleFrame = Utility:Create("Frame", {
                        Parent = targetContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 24)
                    })
                    local ToggleLabel = Utility:Create("TextLabel", {
                        Parent = ToggleFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 24, 0, 0), Size = UDim2.new(1, -60, 1, 0),
                        Font = Theme.LabelFont, Text = togText, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
                    })
                    local ToggleBox = Utility:Create("TextButton", {
                        Parent = ToggleFrame, BackgroundColor3 = state and Theme.ToggleActive or Theme.ToggleInactive, BorderSizePixel = 0,
                        Size = UDim2.new(0, 16, 0, 16), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Text = "", AutoButtonColor = false
                    })
                    Utility:Create("UICorner", { Parent = ToggleBox, CornerRadius = UDim.new(0, 4) })
                    local Checkmark = Utility:Create("ImageLabel", {
                        Parent = ToggleBox, BackgroundTransparency = 1, Size = UDim2.new(1, -6, 1, -6), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
                        Image = "rbxthumb://type=Asset&id=122260051760942&w=150&h=150", ImageColor3 = Theme.SectionBg, ImageTransparency = state and 0 or 1
                    })
                    table.insert(AccentUpdates, function(col)
                        if state then ToggleBox.BackgroundColor3 = col end
                    end)
                    local currentBind = nil
                    local bindMode = "Toggle"
                    local isBinding = false
                    local activeBindBtnInModal = nil
                    local GearBtn = Utility:Create("ImageButton", {
                        Parent = ToggleFrame, BackgroundTransparency = 1, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
                        Image = "rbxthumb://type=Asset&id=124522320095654&w=150&h=150", ImageColor3 = Color3.fromRGB(150, 150, 150), AutoButtonColor = false
                    })
                    local cpAPIs = {}
                    local function getDarkenedColor(color)
                        local h, s, v = color:ToHSV()
                        return Color3.fromHSV(h, s, v * 0.588)
                    end
                    if type(opts.Colorpickers) == "table" then
                        for i, cpOpts in opts.Colorpickers do
                            if i > 5 then break end
                            local currentColor = cpOpts.ColorDefault or Color3.fromRGB(255, 255, 255)
                            local currentAlpha = cpOpts.AlphaDefault or 1
                            local cpBtn = Utility:Create("ImageButton", {
                                Parent = ToggleFrame, BackgroundTransparency = 1, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -(i * 20), 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
                                Image = "rbxthumb://type=Asset&id=96979905103763&w=150&h=150", ImageColor3 = getDarkenedColor(currentColor), AutoButtonColor = false
                            })
                            local function updateColor(color, alpha)
                                currentColor = color
                                currentAlpha = alpha
                                cpBtn.ImageColor3 = getDarkenedColor(color)
                                if cpOpts.Callback then cpOpts.Callback(color, alpha) end
                            end
                            cpAPIs[i] = {
                                Set = updateColor,
                                Get = function() return { Color = currentColor, Alpha = currentAlpha } end
                            }
                            cpBtn.MouseButton1Click:Connect(function()
                                OpenColorPicker(cpOpts.Name or (togText .. " Color"), currentColor, currentAlpha, updateColor, cpBtn)
                            end)
                        end
                    elseif opts.Colorpicker then
                        local currentColor = opts.ColorDefault or Color3.fromRGB(255, 255, 255)
                        local currentAlpha = opts.AlphaDefault or 1
                        local cpBtn = Utility:Create("ImageButton", {
                            Parent = ToggleFrame, BackgroundTransparency = 1, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -20, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
                            Image = "rbxthumb://type=Asset&id=96979905103763&w=150&h=150", ImageColor3 = getDarkenedColor(currentColor), AutoButtonColor = false
                        })
                        local function updateColor(color, alpha)
                            currentColor = color
                            currentAlpha = alpha
                            cpBtn.ImageColor3 = getDarkenedColor(color)
                            if opts.ColorCallback then opts.ColorCallback(color, alpha) end
                        end
                        cpAPIs[1] = {
                            Set = updateColor,
                            Get = function() return { Color = currentColor, Alpha = currentAlpha } end
                        }
                        cpBtn.MouseButton1Click:Connect(function()
                            OpenColorPicker(togText .. " Color", currentColor, currentAlpha, updateColor, cpBtn)
                        end)
                    end
                    local SubElementsContainer = Utility:Create("Frame", {
                        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)
                    })
                    SubElementsContainer:SetAttribute("Cached", true)
                    local SubLayout = Utility:Create("UIListLayout", {
                        Parent = SubElementsContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)
                    })
                    SubLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                        SubElementsContainer.Size = UDim2.new(1, 0, 0, SubLayout.AbsoluteContentSize.Y)
                    end)
                    local BindFrame = Utility:Create("Frame", {
                        Parent = SubElementsContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 24)
                    })
                    local BindLabel = Utility:Create("TextLabel", {
                        Parent = BindFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -70, 1, 0),
                        Font = Theme.LabelFont, Text = "Keybind", TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
                    })
                    local BindBtnInModal = Utility:Create("TextButton", {
                        Parent = BindFrame, BackgroundColor3 = Color3.fromRGB(35, 35, 35), BorderSizePixel = 0,
                        Position = UDim2.new(1, -60, 0, 2), Size = UDim2.new(0, 60, 1, -4),
                        Font = Theme.Font, Text = currentBind and currentBind.Name or "None", TextColor3 = Color3.fromRGB(180, 180, 180), TextSize = 12
                    })
                    Utility:Create("UICorner", { Parent = BindBtnInModal, CornerRadius = UDim.new(0, 4) })
                    activeBindBtnInModal = BindBtnInModal
                    local BindModeList = Utility:Create("Frame", {
                        Parent = BindFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0,
                        Position = UDim2.new(1, -60, 1, 2), Size = UDim2.new(0, 60, 0, 40),
                        Visible = false, ZIndex = 105
                    })
                    Utility:Create("UICorner", { Parent = BindModeList, CornerRadius = UDim.new(0, 4) })
                    Utility:Create("UIListLayout", { Parent = BindModeList, SortOrder = Enum.SortOrder.LayoutOrder })
                    local function makeModeBtn(modeName)
                        local btn = Utility:Create("TextButton", {
                            Parent = BindModeList, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20),
                            Font = Theme.Font, Text = modeName, TextColor3 = bindMode == modeName and Theme.ToggleActive or Theme.TextMain, TextSize = 12, ZIndex = 106
                        })
                        btn.MouseButton1Click:Connect(function()
                            bindMode = modeName
                            for _, v in BindModeList:GetChildren() do
                                if v:IsA("TextButton") then
                                    v.TextColor3 = v.Text == bindMode and Theme.ToggleActive or Theme.TextMain
                                end
                            end
                            BindModeList.Visible = false
                        end)
                    end
                    makeModeBtn("Toggle")
                    makeModeBtn("Hold")
                    BindBtnInModal.MouseButton1Click:Connect(function()
                        isBinding = true
                        BindBtnInModal.Text = "..."
                        BindModeList.Visible = false
                    end)
                    BindBtnInModal.MouseButton2Click:Connect(function()
                        BindModeList.Visible = not BindModeList.Visible
                    end)
                    if type(opts.Dropdowns) == "table" then
                        for _, dropOpts in opts.Dropdowns do
                            dropOpts.Container = SubElementsContainer
                            self:CreateDropdown(dropOpts)
                        end
                    end
                    if type(opts.Toggles) == "table" then
                        for _, toggleOpts in opts.Toggles do
                            toggleOpts.Container = SubElementsContainer
                            self:CreateToggle(toggleOpts)
                        end
                    end
                    local function openSettingsModal()
                        OpenModal(togText .. " Settings", function(container)
                            SubElementsContainer.Parent = container
                        end, GearBtn)
                    end
                    GearBtn.MouseButton1Click:Connect(openSettingsModal)
                    GearBtn.MouseButton2Click:Connect(openSettingsModal)
                    local toggleBindInfo = {
                        getName = function() return togText end,
                        getState = function() return state end,
                        getKey = function() return currentBind end,
                        getMode = function() return bindMode end,
                        isBindingFunc = function() return isBinding end,
                        setBinding = function(val) isBinding = val end,
                        onBegan = function(input)
                            if isBinding then
                                if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                                    currentBind = nil
                                    if activeBindBtnInModal then activeBindBtnInModal.Text = "[Click to Bind]" end
                                elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                                    currentBind = input.KeyCode
                                    if activeBindBtnInModal then activeBindBtnInModal.Text = "[" .. input.KeyCode.Name .. "]" end
                                elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                                    currentBind = input.UserInputType
                                    local name = input.UserInputType.Name
                                    if name == "MouseButton1" then name = "LMB" end
                                    if name == "MouseButton2" then name = "RMB" end
                                    if name == "MouseButton3" then name = "MMB" end
                                    if activeBindBtnInModal then activeBindBtnInModal.Text = "[" .. name .. "]" end
                                end
                                isBinding = false
                                return true
                            end
                            return false
                        end,
                        onKeyDown = function()
                            if bindMode == "Toggle" then
                                state = not state
                            else
                                state = true
                            end
                            TweenService:Create(ToggleBox, TweenInfo.new(0.2), {BackgroundColor3 = state and Theme.ToggleActive or Theme.ToggleInactive}):Play()
                            TweenService:Create(Checkmark, TweenInfo.new(0.2), {ImageTransparency = state and 0 or 1}):Play()
                            callback(state)
                        end,
                        onKeyUp = function()
                            if bindMode == "Hold" then
                                state = false
                                TweenService:Create(ToggleBox, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ToggleInactive}):Play()
                                TweenService:Create(Checkmark, TweenInfo.new(0.2), {ImageTransparency = 1}):Play()
                                callback(state)
                            end
                        end
                    }
                    table.insert(KeybindRegistry, toggleBindInfo)
                    ToggleBox.MouseButton1Click:Connect(function()
                        state = not state
                        TweenService:Create(ToggleBox, TweenInfo.new(0.2), {BackgroundColor3 = state and Theme.ToggleActive or Theme.ToggleInactive}):Play()
                        TweenService:Create(Checkmark, TweenInfo.new(0.2), {ImageTransparency = state and 0 or 1}):Play()
                        callback(state)
                    end)
                    task.spawn(function() callback(state) end)
                    local API = {
                        Set = function(val, bind, mode, colors)
                            if val ~= nil then
                                state = val
                                TweenService:Create(ToggleBox, TweenInfo.new(0.2), {BackgroundColor3 = state and Theme.ToggleActive or Theme.ToggleInactive}):Play()
                                TweenService:Create(Checkmark, TweenInfo.new(0.2), {ImageTransparency = state and 0 or 1}):Play()
                                task.spawn(function() callback(state) end)
                            end
                            if bind ~= nil then
                                currentBind = bind
                                if activeBindBtnInModal then activeBindBtnInModal.Text = "[" .. (typeof(bind) == "EnumItem" and bind.Name or tostring(bind)) .. "]" end
                            end
                            if mode ~= nil then
                                bindMode = mode
                            end
                            if type(colors) == "table" then
                                for i, cstate in colors do
                                    if cpAPIs[i] then
                                        cpAPIs[i].Set(Color3.new(cstate.R, cstate.G, cstate.B), cstate.Alpha)
                                    end
                                end
                            end
                        end,
                        Get = function()
                            local cols = {}
                            for i, capi in cpAPIs do
                                local cstate = capi.Get()
                                table.insert(cols, { R = cstate.Color.R, G = cstate.Color.G, B = cstate.Color.B, Alpha = cstate.Alpha })
                            end
                            return { Type = "Toggle", Value = state, Bind = currentBind and currentBind.Value or nil, Mode = bindMode, Colors = cols }
                        end
                    }
                    API.Elements = {}
                    setmetatable(API.Elements, {
                        __index = function(_, key)
                            return function(self, subOpts)
                                subOpts = subOpts or {}
                                subOpts.Container = SubElementsContainer
                                return Elements[key](Elements, subOpts)
                            end
                        end
                    })
                    local flagId = opts.Flag or opts.Name
                    if flagId then Library.Flags[flagId] = API end
                    return API
                end
                function Elements:CreateSlider(opts)
                    opts = opts or {}
                    local slName = opts.Name or "Slider"
                    local min = opts.Min or 0
                    local max = opts.Max or 100
                    local default = opts.Default or min
                    local callback = opts.Callback or function() end
                    local targetContainer = opts.Container or ContentContainer
                    local SliderFrame = Utility:Create("Frame", {
                        Parent = targetContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 36)
                    })
                    local SliderLabel = Utility:Create("TextLabel", {
                        Parent = SliderFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 0, 16), Font = Theme.LabelFont, Text = slName, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
                    })
                    local WarningIcon
                    if slName == "Silent FOV" then
                        WarningIcon = Utility:Create("ImageLabel", {
                            Parent = SliderFrame,
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 70, 0, 0),
                            Size = UDim2.new(0, 16, 0, 16),
                            Image = "rbxthumb://type=Asset&id=87824282931713&w=150&h=150",
                            ImageColor3 = Color3.fromRGB(204, 163, 0),
                            Visible = default > 90
                        })
                    end
                    local ValueLabel = Utility:Create("TextLabel", {
                        Parent = SliderFrame, BackgroundTransparency = 1, Position = UDim2.new(1, -40, 0, 0), Size = UDim2.new(0, 40, 0, 16), Font = Theme.Font, Text = tostring(default), TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right
                    })
                    local SliderBack = Utility:Create("Frame", {
                        Parent = SliderFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 23), Size = UDim2.new(1, 0, 0, 3)
                    })
                    Utility:Create("UICorner", { Parent = SliderBack, CornerRadius = UDim.new(0, 3) })
                    local fillPct = math.clamp((default - min) / (max - min), 0, 1)
                    local SliderFill = Utility:Create("Frame", {
                        Parent = SliderBack, BackgroundColor3 = Theme.ToggleActive, BorderSizePixel = 0, Size = UDim2.new(fillPct, 0, 1, 0)
                    })
                    Utility:Create("UICorner", { Parent = SliderFill, CornerRadius = UDim.new(0, 3) })
                    local SliderKnob = Utility:Create("Frame", {
                        Parent = SliderFill,
                        BackgroundColor3 = Theme.ToggleActive,
                        BorderSizePixel = 0,
                        Size = UDim2.new(0, 14, 0, 8),
                        Position = UDim2.new(1, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5)
                    })
                    Utility:Create("UICorner", { Parent = SliderKnob, CornerRadius = UDim.new(0, 3) })
                    table.insert(AccentUpdates, function(col)
                        SliderFill.BackgroundColor3 = col
                        SliderKnob.BackgroundColor3 = col
                    end)
                    local SliderBtn = Utility:Create("TextButton", {
                        Parent = SliderBack, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false
                    })
                    local dragging = false
                    local function update(input)
                        local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                        SliderFill.Size = UDim2.new(pos, 0, 1, 0)
                        local value = math.floor(min + ((max - min) * pos))
                        ValueLabel.Text = tostring(value)
                        if WarningIcon then
                            WarningIcon.Visible = value > 90
                        end
                        callback(value)
                    end
                    SliderBtn.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = true
                            update(input)
                            local moveConn, endConn
                            moveConn = UserInputService.InputChanged:Connect(function(moveInput)
                                if moveInput.UserInputType == Enum.UserInputType.MouseMovement then
                                    update(moveInput)
                                end
                            end)
                            endConn = input.Changed:Connect(function()
                                if input.UserInputState == Enum.UserInputState.End then
                                    dragging = false
                                    if moveConn then moveConn:Disconnect() end
                                    if endConn then endConn:Disconnect() end
                                end
                            end)
                        end
                    end)
                    task.spawn(function() callback(default) end)
                    local API = {
                        Set = function(val)
                            local clamped = math.clamp(tonumber(val) or min, min, max)
                            local percent = (clamped - min) / (max - min)
                            ValueLabel.Text = tostring(math.floor(clamped * 10) / 10)
                            TweenService:Create(SliderFill, TweenInfo.new(0.1), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
                            task.spawn(function() callback(clamped) end)
                        end,
                        Get = function()
                            return { Type = "Slider", Value = tonumber(ValueLabel.Text) }
                        end
                    }
                    local flagId = opts.Flag or opts.Name
                    if flagId then Library.Flags[flagId] = API end
                    return API
                end
                function Elements:CreateButton(opts)
                    opts = opts or {}
                    local btnText = opts.Name or "Button"
                    local callback = opts.Callback or function() end
                    local targetContainer = opts.Container or ContentContainer
                    local ButtonFrame = Utility:Create("Frame", {
                        Parent = targetContainer, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Size = UDim2.new(1, -24, 0, 24)
                    })
                    Utility:Create("UICorner", { Parent = ButtonFrame, CornerRadius = UDim.new(0, 6) })
                    local Button = Utility:Create("TextButton", {
                        Parent = ButtonFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Theme.Font, Text = btnText, TextColor3 = Theme.TextMain, TextSize = 13
                    })
                    Button.MouseButton1Click:Connect(function()
                        callback()
                    end)
                end
                function Elements:CreateTextbox(opts)
                    opts = opts or {}
                    local tbText = opts.Name or "Textbox"
                    local placeholder = opts.Placeholder or ""
                    local callback = opts.Callback or function() end
                    local targetContainer = opts.Container or ContentContainer
                    local TextboxFrame = Utility:Create("Frame", {
                        Parent = targetContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 40)
                    })
                    Utility:Create("TextLabel", {
                        Parent = TextboxFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Font = Theme.LabelFont, Text = tbText, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
                    })
                    local BoxBg = Utility:Create("Frame", {
                        Parent = TextboxFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 16), Size = UDim2.new(1, 0, 0, 24)
                    })
                    Utility:Create("UICorner", { Parent = BoxBg, CornerRadius = UDim.new(0, 6) })
                    local TextBox = Utility:Create("TextBox", {
                        Parent = BoxBg, BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 1, 0), Font = Theme.Font, Text = "", PlaceholderText = placeholder, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false
                    })
                    TextBox.FocusLost:Connect(function()
                        callback(TextBox.Text)
                    end)
                end
                function Elements:CreateDropdown(opts)
                    opts = opts or {}
                    local dropText = opts.Name or "Dropdown"
                    local list = opts.Options or {}
                    local callback = opts.Callback or function() end
                    local targetContainer = opts.Container or ContentContainer
                    local isOpen = false
                    local selected = opts.Default or (list[1] or "")
                    local DropdownFrame = Utility:Create("Frame", {
                        Parent = targetContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 40)
                    })
                    Utility:Create("TextLabel", {
                        Parent = DropdownFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Font = Theme.LabelFont, Text = dropText, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
                    })
                    local MainBox = Utility:Create("TextButton", {
                        Parent = DropdownFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 16), Size = UDim2.new(1, 0, 0, 24), Text = ""
                    })
                    Utility:Create("UICorner", { Parent = MainBox, CornerRadius = UDim.new(0, 6) })
                    local SelectedLabel = Utility:Create("TextLabel", {
                        Parent = MainBox, BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -25, 1, 0), Font = Theme.Font, Text = selected, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
                    })
                    local Arrow = Utility:Create("TextLabel", {
                        Parent = MainBox, BackgroundTransparency = 1, Position = UDim2.new(1, -20, 0, 0), Size = UDim2.new(0, 20, 1, 0), Font = Theme.Font, Text = "v", TextColor3 = Theme.TextMain, TextSize = 13
                    })
                    local DropContainer = Utility:Create("Frame", {
                        Parent = DropdownFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(1, 0, 0, 0), Visible = false, ClipsDescendants = true
                    })
                    Utility:Create("UICorner", { Parent = DropContainer, CornerRadius = UDim.new(0, 6) })
                    local DropLayout = Utility:Create("UIListLayout", { Parent = DropContainer, SortOrder = Enum.SortOrder.LayoutOrder })
                    local function createList()
                        for _, v in DropContainer:GetChildren() do if v:IsA("TextButton") then v:Destroy() end end
                        local h = 0
                        for _, option in list do
                            local OptBtn = Utility:Create("TextButton", {
                                Parent = DropContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 25), Font = Enum.Font.Gotham, Text = "  " .. option, TextColor3 = Theme.TextMain, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
                            })
                            h = h + 25
                            OptBtn.MouseButton1Click:Connect(function()
                                selected = option
                                SelectedLabel.Text = selected
                                isOpen = false
                                DropContainer.Visible = false
                                Arrow.Text = "v"
                                DropdownFrame.Size = UDim2.new(1, -24, 0, 50)
                                for _, btn in DropContainer:GetChildren() do
                                    if btn:IsA("TextButton") then
                                        local optName = btn.Text:sub(3)
                                        btn.TextColor3 = (optName == selected) and Theme.ToggleActive or Theme.TextMain
                                        btn.Font = (optName == selected) and Theme.Font or Enum.Font.Gotham
                                    end
                                end
                                callback(selected)
                            end)
                        end
                        DropContainer.Size = UDim2.new(1, 0, 0, h)
                        for _, btn in DropContainer:GetChildren() do
                            if btn:IsA("TextButton") then
                                local optName = btn.Text:sub(3)
                                btn.TextColor3 = (optName == selected) and Theme.ToggleActive or Theme.TextMain
                                btn.Font = (optName == selected) and Theme.Font or Enum.Font.Gotham
                            end
                        end
                    end
                    createList()
                    table.insert(AccentUpdates, function(col)
                        for _, btn in DropContainer:GetChildren() do
                            if btn:IsA("TextButton") then
                                local optName = btn.Text:sub(3)
                                if optName == selected then
                                    btn.TextColor3 = col
                                end
                            end
                        end
                    end)
                    MainBox.MouseButton1Click:Connect(function()
                        isOpen = not isOpen
                        DropContainer.Visible = isOpen
                        Arrow.Text = isOpen and "^" or "v"
                        if isOpen then
                            DropdownFrame.Size = UDim2.new(1, -24, 0, 55 + DropContainer.Size.Y.Offset)
                        else
                            DropdownFrame.Size = UDim2.new(1, -24, 0, 50)
                        end
                    end)
                    task.spawn(function() callback(selected) end)
                    local API = {
                        Set = function(val)
                            selected = val
                            SelectedLabel.Text = tostring(selected)
                            for _, btn in DropContainer:GetChildren() do
                                if btn:IsA("TextButton") then
                                    local optName = btn.Text:sub(3)
                                    btn.TextColor3 = (optName == selected) and Theme.ToggleActive or Theme.TextMain
                                    btn.Font = (optName == selected) and Theme.Font or Enum.Font.Gotham
                                end
                            end
                            task.spawn(function() callback(selected) end)
                        end,
                        Get = function()
                            return { Type = "Dropdown", Value = selected }
                        end,
                        Refresh = function(newList)
                            list = newList
                            local found = false
                            for _, v in list do
                                if v == selected then found = true; break end
                            end
                            if not found then
                                selected = list[1] or ""
                                SelectedLabel.Text = tostring(selected)
                                task.spawn(function() callback(selected) end)
                            end
                            createList()
                        end
                    }
                    local flagId = opts.Flag or opts.Name
                    if flagId then Library.Flags[flagId] = API end
                    return API
                end
                function Elements:CreateMultiDropdown(opts)
                    opts = opts or {}
                    local dropText = opts.Name or "Multi Dropdown"
                    local list = opts.Options or {}
                    local callback = opts.Callback or function() end
                    local targetContainer = opts.Container or ContentContainer
                    local isOpen = false
                    local selected = {}
                    if opts.Default then
                        for _, v in opts.Default do
                            table.insert(selected, v)
                        end
                    end
                    local DropdownFrame = Utility:Create("Frame", {
                        Parent = targetContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 40)
                    })
                    Utility:Create("TextLabel", {
                        Parent = DropdownFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Font = Theme.LabelFont, Text = dropText, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
                    })
                    local MainBox = Utility:Create("TextButton", {
                        Parent = DropdownFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 16), Size = UDim2.new(1, 0, 0, 24), Text = ""
                    })
                    Utility:Create("UICorner", { Parent = MainBox, CornerRadius = UDim.new(0, 6) })
                    local function getSelectedText()
                        if #selected == 0 then return "None" end
                        return table.concat(selected, ", ")
                    end
                    local SelectedLabel = Utility:Create("TextLabel", {
                        Parent = MainBox, BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -25, 1, 0), Font = Theme.Font, Text = getSelectedText(), TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd
                    })
                    local Arrow = Utility:Create("TextLabel", {
                        Parent = MainBox, BackgroundTransparency = 1, Position = UDim2.new(1, -20, 0, 0), Size = UDim2.new(0, 20, 1, 0), Font = Theme.Font, Text = "v", TextColor3 = Theme.TextMain, TextSize = 13
                    })
                    local DropContainer = Utility:Create("Frame", {
                        Parent = DropdownFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(1, 0, 0, 0), Visible = false, ClipsDescendants = true
                    })
                    Utility:Create("UICorner", { Parent = DropContainer, CornerRadius = UDim.new(0, 6) })
                    local DropLayout = Utility:Create("UIListLayout", { Parent = DropContainer, SortOrder = Enum.SortOrder.LayoutOrder })
                    local function createList()
                        for _, v in DropContainer:GetChildren() do if v:IsA("TextButton") then v:Destroy() end end
                        local h = 0
                        for _, option in list do
                            local OptBtn = Utility:Create("TextButton", {
                                Parent = DropContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 25), Font = Enum.Font.Gotham, Text = "  " .. option, TextColor3 = Theme.TextMain, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
                            })
                            h = h + 25
                            OptBtn.MouseButton1Click:Connect(function()
                                local isSel = false
                                for _, v in selected do if v == option then isSel = true break end end
                                if isSel then
                                    for i, v in selected do
                                        if v == option then table.remove(selected, i) break end
                                    end
                                else
                                    table.insert(selected, option)
                                end
                                SelectedLabel.Text = getSelectedText()
                                callback(selected)
                                for _, btn in DropContainer:GetChildren() do
                                    if btn:IsA("TextButton") then
                                        local optName = btn.Text:sub(3) 
                                        local sel = false
                                        for _, v in selected do if v == optName then sel = true break end end
                                        btn.TextColor3 = sel and Theme.ToggleActive or Theme.TextMain
                                        btn.Font = sel and Theme.Font or Enum.Font.Gotham
                                    end
                                end
                            end)
                        end
                        DropContainer.Size = UDim2.new(1, 0, 0, h)
                        for _, btn in DropContainer:GetChildren() do
                            if btn:IsA("TextButton") then
                                local optName = btn.Text:sub(3)
                                local sel = false
                                for _, v in selected do if v == optName then sel = true break end end
                                btn.TextColor3 = sel and Theme.ToggleActive or Theme.TextMain
                                btn.Font = sel and Theme.Font or Enum.Font.Gotham
                            end
                        end
                    end
                    createList()
                    table.insert(AccentUpdates, function(col)
                        for _, btn in DropContainer:GetChildren() do
                            if btn:IsA("TextButton") then
                                local optName = btn.Text:sub(3)
                                local sel = false
                                for _, v in selected do if v == optName then sel = true break end end
                                if sel then
                                    btn.TextColor3 = col
                                end
                            end
                        end
                    end)
                    MainBox.MouseButton1Click:Connect(function()
                        isOpen = not isOpen
                        DropContainer.Visible = isOpen
                        Arrow.Text = isOpen and "^" or "v"
                        if isOpen then
                            DropdownFrame.Size = UDim2.new(1, -24, 0, 55 + DropContainer.Size.Y.Offset)
                        else
                            DropdownFrame.Size = UDim2.new(1, -24, 0, 50)
                        end
                    end)
                    task.spawn(function() callback(selected) end)
                    local API = {
                        Set = function(val)
                            if type(val) == "table" then
                                selected = {}
                                for _, v in val do table.insert(selected, v) end
                            end
                            SelectedLabel.Text = getSelectedText()
                            for _, btn in DropContainer:GetChildren() do
                                if btn:IsA("TextButton") then
                                    local optName = btn.Text:sub(3)
                                    local sel = false
                                    for _, v in selected do if v == optName then sel = true break end end
                                    btn.TextColor3 = sel and Theme.ToggleActive or Theme.TextMain
                                    btn.Font = sel and Theme.Font or Enum.Font.Gotham
                                end
                            end
                            task.spawn(function() callback(selected) end)
                        end,
                        Get = function()
                            return { Type = "MultiDropdown", Value = selected }
                        end
                    }
                    local flagId = opts.Flag or opts.Name
                    if flagId then Library.Flags[flagId] = API end
                    return API
                end
                function Elements:CreateButton(opts)
                    opts = opts or {}
                    local btnText = opts.Name or "Button"
                    local callback = opts.Callback or function() end
                    local targetContainer = opts.Container or ContentContainer
                    local BtnFrame = Utility:Create("Frame", {
                        Parent = targetContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 28)
                    })
                    local Btn = Utility:Create("TextButton", {
                        Parent = BtnFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
                        Font = Theme.Font, Text = btnText, TextColor3 = Theme.TextMain, TextSize = 13
                    })
                    Utility:Create("UICorner", { Parent = Btn, CornerRadius = UDim.new(0, 4) })
                    Btn.MouseButton1Click:Connect(callback)
                end
                function Elements:CreateTextbox(opts)
                    opts = opts or {}
                    local tbName = opts.Name or "Textbox"
                    local placeholder = opts.Placeholder or ""
                    local callback = opts.Callback or function() end
                    local targetContainer = opts.Container or ContentContainer
                    local TbFrame = Utility:Create("Frame", {
                        Parent = targetContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 44)
                    })
                    local TbLabel = Utility:Create("TextLabel", {
                        Parent = TbFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
                        Font = Theme.LabelFont, Text = tbName, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
                    })
                    local TbInput = Utility:Create("TextBox", {
                        Parent = TbFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 20), Size = UDim2.new(1, 0, 0, 24),
                        Font = Theme.Font, Text = "", PlaceholderText = placeholder, TextColor3 = Theme.TextMain, TextSize = 13, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left
                    })
                    Utility:Create("UICorner", { Parent = TbInput, CornerRadius = UDim.new(0, 4) })
                    TbInput.FocusLost:Connect(function()
                        callback(TbInput.Text)
                    end)
                end
                function Elements:CreateESPPreview(opts)
                    opts = opts or {}
                    local targetContainer = opts.Container or ContentContainer
                    local PreviewFrame = Utility:Create("Frame", {
                        Parent = targetContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 240)
                    })
                    local Viewport = Utility:Create("ViewportFrame", {
                        Parent = PreviewFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
                        Ambient = Color3.fromRGB(200, 200, 200), LightColor = Color3.fromRGB(255, 255, 255), LightDirection = Vector3.new(-1, -1, -1),
                        Active = true
                    })
                    Utility:Create("UICorner", { Parent = Viewport, CornerRadius = UDim.new(0, 6) })
                    local dummy = Instance.new("Model")
                    dummy.Name = "PreviewDummy"
                    local function makePart(name, size, pos)
                        local part = Instance.new("Part")
                        part.Name = name
                        part.Size = size
                        part.CFrame = CFrame.new(pos)
                        part.Anchored = true
                        part.CanCollide = false
                        part.TopSurface = Enum.SurfaceType.Smooth
                        part.BottomSurface = Enum.SurfaceType.Smooth
                        part.Color = Color3.fromRGB(163, 162, 165)
                        part.Parent = dummy
                        return part
                    end
                    local torso = makePart("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0))
                    local head = makePart("Head", Vector3.new(2, 1, 1), Vector3.new(0, 4.5, 0))
                    local leftArm = makePart("Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0))
                    local rightArm = makePart("Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0))
                    local leftLeg = makePart("Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0))
                    local rightLeg = makePart("Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0))
                    local headMesh = Instance.new("SpecialMesh", head)
                    headMesh.MeshType = Enum.MeshType.Head
                    headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
                    dummy.PrimaryPart = torso
                    dummy.Parent = Viewport
                    local cam = Instance.new("Camera")
                    cam.CFrame = CFrame.new(Vector3.new(0, 3, -7), dummy.PrimaryPart.Position)
                    cam.FieldOfView = 70
                    Viewport.CurrentCamera = cam
                    local dragging = false
                    local lastPos
                    local angleX, angleY = 0, math.pi
                    Viewport.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = true
                            lastPos = input.Position
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                            local delta = input.Position - lastPos
                            lastPos = input.Position
                            angleY = angleY + math.rad(delta.X * 0.5)
                            angleX = math.clamp(angleX + math.rad(delta.Y * 0.5), -math.pi/4, math.pi/4)
                            dummy:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0, 3, 0)) * CFrame.Angles(angleX, angleY, 0))
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                            dragging = false 
                        end
                    end)
                    local espDrawings = Utility:CreateESP()
                    local API = {
                        Model = dummy,
                        Viewport = Viewport,
                        Camera = cam,
                        ESP = espDrawings
                    }
                    return API
                end
                return Elements
            end
            return TabObj
        end
        return Window
    end
    local Window = Library:CreateWindow({
        Title = "LocalMaze Evade",
        Size = UDim2.new(0, 790, 0, 520)
    })
    Window:CreateCategory("Combat")
    CombatTab = Window:CreateTab("Combat", "107058246184363")
    LegitbotTab = CombatTab:CreateSubTab("Legitbot")
                        Window:CreateCategory("Visuals")
    EspTab = Window:CreateTab("ESP", "2795572803")
    VisualsTab = Window:CreateTab("Visuals", "137182874573549")
    Window:CreateCategory("Movement")
    MovementTab = Window:CreateTab("Movement", "8673852020")
    Window:CreateCategory("Misc")
    MiscTab = Window:CreateTab("Misc", "14219516560")
        Window:CreateCategory("Config")
    ConfigTab = Window:CreateTab("Config", "18397244089")
    CustomHitsoundIDs = {
        ["among us"] = "5700183626",
        ["ar2 body"] = "2062015952",
        ["ar2 head"] = "2062016772",
        ["ar2 limb"] = "6659353525",
        ["bag"] = "364942410",
        ["baimware"] = "3124331820",
        ["bamboo"] = "3769434519",
        ["bambi"] = "8437203821",
        ["bameware"] = "7898991882",
        ["bat"] = "3333907347",
        ["bb hitm"] = "4645745735",
        ["bb kill"] = "2636743632",
        ["bell"] = "6534947240",
        ["bitchbot"] = "5709456554",
        ["bitchbot body"] = "3744371342",
        ["bitchbot head"] = "5043539486",
        ["body"] = "3213738472",
        ["bonk"] = "3765689841",
        ["bop"] = "8829676038",
        ["bruh"] = "4275842574",
        ["bubble"] = "6534947588",
        ["button"] = "12221967",
        ["carrier kill"] = "7139067012",
        ["click"] = "8053704437",
        ["clink"] = "711751971",
        ["clutch kill"] = "7379106527",
        ["cod"] = "160432334",
        ["crickets"] = "2101148",
        ["crit"] = "296102734",
        ["csgo"] = "7269900245",
        ["ding"] = "7149516994",
        ["double kill"] = "6818527307",
        ["doublekill 1"] = "1950547222",
        ["doublekill 2"] = "130819307",
        ["elevator"] = "8322227967",
        ["emptygun"] = "203691822",
        ["fart"] = "131314452",
        ["fart2"] = "6367774932",
        ["fatality"] = "7347423703",
        ["fatality mkx"] = "6721975770",
        ["fatality original"] = "158012252",
        ["fortniteguns"] = "3008769599",
        ["gamesense"] = "4817809188",
        ["grenade hit"] = "5684745272",
        ["headshot"] = "8418469749",
        ["hitmarker"] = "8543972310",
        ["hl crowbar"] = "546410481",
        ["hl door"] = "4996094887",
        ["hl elevator"] = "237877850",
        ["hl med kit"] = "4720445506",
        ["hl revolver"] = "1678424590",
        ["kill imanjaro"] = "6818527258",
        ["kill ionaire"] = "6818527200",
        ["kill pocalypse"] = "6818526916",
        ["kill tacular"] = "6818527070",
        ["kill tastrophe"] = "6818526916",
        ["killing frenzy"] = "6822465319",
        ["killing spree"] = "6822465178",
        ["killing spree 1"] = "723054723",
        ["killing spree 2"] = "937898383",
        ["killtrocity"] = "6818544945",
        ["kombat"] = "8527433497",
        ["laserslash"] = "199145497",
        ["lazer beam"] = "130791043",
        ["mario"] = "2815207981",
        ["mario 2"] = "5709456554",
        ["minecraft"] = "6361963422",
        ["minecraft experience "] = "1053296915",
        ["neverlose"] = "8726881116",
        ["oof"] = "4792539171",
        ["osu"] = "7149919358",
        ["osu combobreak"] = "3547118594",
        ["over kill"] = "6818526995",
        ["pd body"] = "4585364605",
        ["pd head"] = "4585351098",
        ["pick"] = "1347140027",
        ["pop"] = "198598793",
        ["quake hitsound"] = "4868633804",
        ["railgunf"] = "199145534",
        ["rust"] = "1255040462",
        ["saber"] = "8415678813",
        ["screamingkid"] = "5980352978",
        ["sit dog"] = "7349055654",
        ["skeet"] = "4753603610",
        ["slime"] = "6916371803",
        ["snow"] = "6455527632",
        ["splat"] = "12222152",
        ["steve"] = "4965083997",
        ["stomp"] = "200632875",
        ["stone"] = "3581383408",
        ["taco bell"] = "5689199277",
        ["tf2 bat"] = "3333907347",
        ["tf2 beepo"] = "3466987025",
        ["tf2 hitsound"] = "3455144981",
        ["tf2 pow"] = "679798995",
        ["tf2 retro"] = "3466984142",
        ["tf2 space"] = "3466982899",
        ["tf2 squasher"] = "3466981613",
        ["tf2 vortex"] = "3466980212",
        ["tf2 you suck"] = "1058417264",
        ["triple kill"] = "6818526855",
        ["windows xp ding"] = "489390072",
        ["windows xp error"] = "160715357"
    }
    HitSoundDropdownList = {"Off"}
    for k, _ in CustomHitsoundIDs do
        table.insert(HitSoundDropdownList, k)
    end
    table.sort(HitSoundDropdownList, function(a, b)
        if a == "Off" then return true end
        if b == "Off" then return false end
        return a < b
    end)
    local AimbotSettings = {
        Enabled = false,
        SilentAim = false,
        SilentAimWallbang = true,
        NoSpread = false,
        Smoothing = 3,
        FOV_Visible = false,
        FOV_Radius = 100,
        FOV_Color = Color3.fromRGB(255, 255, 255),
        FOV_Alpha = 1,
        TargetPart = "Head",
        AimKey = Enum.UserInputType.MouseButton2,
        SilentAimFOV_Visible = false,
        SilentAimFOV_Radius = 100,
        SilentAimFOV_Color = Color3.fromRGB(255, 0, 0),
        SilentAimFOV_Alpha = 1,
        SilentAimTargetPart = "Head",
                Backtrack = false,
        BacktrackTime = 200,
        NameSpoofer = false,
        SpoofedName = "Spoofed"
    }
    local LeftSection = LegitbotTab:CreateSection({
        Name = "Aimbot",
        Side = "Left" 
    })
    AimbotToggle = LeftSection:CreateToggle({
        Name = "Enable Aimbot",
        Default = false,
        Callback = function(state) AimbotSettings.Enabled = state end
    })
    AimbotToggle.Elements:CreateToggle({
        Name = "Nested Setting Test",
        Default = true,
        Callback = function(state) print("Nested Toggle:", state) end
    })
    AimbotToggle.Elements:CreateSlider({
        Name = "Nested Slider",
        Min = 1,
        Max = 10,
        Default = 5,
        Callback = function(val) print("Nested Slider:", val) end
    })
    LeftSection:CreateSlider({
        Name = "FOV Radius",
        Min = 0,
        Max = 360,
        Default = 100,
        Callback = function(val) AimbotSettings.FOV_Radius = val end
    })
    LeftSection:CreateSlider({
        Name = "Smooth",
        Min = 1,
        Max = 10,
        Default = 3,
        Callback = function(val) AimbotSettings.Smoothing = val end
    })
    LeftSection:CreateToggle({
        Name = "Show FOV",
        Default = false,
        Colorpickers = {
            {Name = "Color", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 1, Callback = function(c, a) AimbotSettings.FOV_Color = c; AimbotSettings.FOV_Alpha = a end}
        },
        Callback = function(state) AimbotSettings.FOV_Visible = state end
    })
    local RightSection = LegitbotTab:CreateSection({
        Name = "Silent Aim",
        Side = "Right"
    })
    RightSection:CreateToggle({
        Name = "Silent Aim",
        Default = false,
        Callback = function(state) AimbotSettings.SilentAim = state end
    })
    RightSection:CreateSlider({
        Name = "Silent FOV",
        Min = 0,
        Max = 360,
        Default = 100,
        Callback = function(val) AimbotSettings.SilentAimFOV_Radius = val end
    })
    RightSection:CreateToggle({
        Name = "Show Silent FOV",
        Default = false,
        Colorpickers = {
            {Name = "Color", ColorDefault = Color3.fromRGB(255, 0, 0), AlphaDefault = 1, Callback = function(c, a) AimbotSettings.SilentAimFOV_Color = c; AimbotSettings.SilentAimFOV_Alpha = a end}
        },
        Callback = function(state) AimbotSettings.SilentAimFOV_Visible = state end
    })
    RightSection:CreateToggle({
        Name = "Auto Shoot",
        Default = false,
        Callback = function(state) AimbotSettings.AutoShoot = state end
    })
    RightSection:CreateToggle({
        Name = "Gaysystem",
        Default = false,
        Callback = function(state) AimbotSettings.SilentAimWallbang = state end
    })
    RightSection:CreateToggle({
        Name = "No Spread",
        Default = false,
        Callback = function(state) AimbotSettings.NoSpread = state end
    })
    RightSection:CreateMultiDropdown({
        Name = "Silent Hitboxes",
        Options = {"Head", "Body", "Hands", "Legs"},
        Default = {"Head"},
        Callback = function(sel) AimbotSettings.SilentAimTargetPart = sel end
    })
    RightSection:CreateToggle({
        Name = "Backtrack",
        Default = false,
        Callback = function(state) AimbotSettings.Backtrack = state end
    })
    RightSection:CreateSlider({
        Name = "Backtrack Time (ms)",
        Min = 10,
        Max = 1000,
        Default = 200,
        Callback = function(val) AimbotSettings.BacktrackTime = val end
    })
    EspGeneralSubTab = EspTab:CreateSubTab("General")
    local EspSection = EspGeneralSubTab:CreateSection({
        Name = "Player ESP",
        Side = "Left"
    })
    PreviewSection = EspGeneralSubTab:CreateSection({
        Name = "Preview",
        Side = "Right"
    })
    PreviewAPI = PreviewSection:CreateESPPreview({})
    local ESP_Settings = {
        Enabled = false,
        Highlight = false,
        HighlightFill = Color3.fromRGB(255, 255, 255),
        HighlightFillAlpha = 0.5,
        HighlightOutline = Color3.fromRGB(255, 255, 255),
        HighlightOutlineAlpha = 0,
        Boxes = false,
        BoxType = "Corner", 
        BoxColor = Color3.fromRGB(255, 255, 255),
        BoxAlpha = 1,
        BoxOutlineColor = Color3.fromRGB(0, 0, 0),
        BoxOutlineAlpha = 1,
        BoxFill = false,
        BoxFillColor1 = Color3.fromRGB(150, 150, 150),
        BoxFillColor2 = Color3.fromRGB(255, 255, 255),
        BoxFillAlpha1 = 0.5,
        BoxFillAlpha2 = 0.5,
        BoxGlow = false,
        BoxGlowColor = Color3.fromRGB(255, 255, 255),
        BoxGlowAlpha = 0.5,
        HealthBar = false,
        HealthBarType = "Adaptive", 
        HealthBarColor1 = Color3.fromRGB(0, 255, 0),
        HealthBarAlpha = 1,
        HealthBarColor2 = Color3.fromRGB(255, 0, 0),
        HealthBarOutlineColor = Color3.fromRGB(0, 0, 0),
        HealthBarOutlineAlpha = 1,
        ShowHealthNumber = false,
        HealthNumberColor = Color3.fromRGB(255, 255, 255),
        HealthNumberAlpha = 1,
        HealthBarGlow = false,
        HealthBarGlowColor = Color3.fromRGB(0, 255, 0),
        HealthBarGlowAlpha = 0.5,
        Names = false,
        NameColor = Color3.fromRGB(255, 255, 255),
        NameAlpha = 1,
        NameOutlineColor = Color3.fromRGB(0, 0, 0),
        NameOutlineAlpha = 1,
        ShowWeapon = false,
        WeaponIconColor = Color3.fromRGB(255, 255, 255),
        WeaponIconAlpha = 1,
        Skeleton = false,
        SkeletonColor = Color3.fromRGB(255, 255, 255),
        SkeletonAlpha = 1,
        SkeletonOutlineColor = Color3.fromRGB(0, 0, 0),
        SkeletonOutlineAlpha = 1,
        OffscreenArrows = false,
        OffscreenArrowColor = Color3.fromRGB(255, 255, 255),
        OffscreenArrowAlpha = 1,
        OffscreenArrowOutlineColor = Color3.fromRGB(0, 0, 0),
        OffscreenArrowOutlineAlpha = 1,
        OffscreenArrowRadius = 150,
        OffscreenArrowSize = 15,
        Flags = false,
        FlagPing = true,
        FlagPingColor = Color3.fromRGB(255, 255, 255),
        FlagPingAlpha = 1,
        FlagAFK = true,
        FlagAFKColor = Color3.fromRGB(255, 255, 100),
        FlagAFKAlpha = 1,
        FlagLethal = true,
        FlagLethalColor = Color3.fromRGB(255, 50, 50),
        FlagLethalAlpha = 1,
        ChamsEnemyVisible = false,
        ChamsEnemyVisibleMaterial = "ForceField",
        ChamsEnemyVisibleColor = Color3.fromRGB(0, 255, 0),
        ChamsEnemyVisibleAlpha = 0.5,
        ChamsEnemyInvisible = false,
        ChamsEnemyInvisibleMaterial = "ForceField",
        ChamsEnemyInvisibleColor = Color3.fromRGB(255, 0, 0),
        ChamsEnemyInvisibleAlpha = 0.5,
        ChamsTeamVisible = false,
        ChamsTeamVisibleMaterial = "ForceField",
        ChamsTeamVisibleColor = Color3.fromRGB(0, 255, 255),
        ChamsTeamVisibleAlpha = 0.5,
        ChamsTeamInvisible = false,
        ChamsTeamInvisibleMaterial = "ForceField",
        ChamsTeamInvisibleColor = Color3.fromRGB(0, 0, 255),
        ChamsTeamInvisibleAlpha = 0.5,
        ChamsWeapon = false,
        ChamsWeaponMaterial = "ForceField",
        ChamsWeaponFill = Color3.fromRGB(255, 0, 255),
        ChamsWeaponFillAlpha = 0.5,
        ChamsWeaponOutline = Color3.fromRGB(255, 255, 255),
        ChamsWeaponOutlineAlpha = 1,
        ChamsArms = false,
        ChamsArmsMaterial = "ForceField",
        ChamsArmsFill = Color3.fromRGB(0, 255, 255),
        ChamsArmsFillAlpha = 0.5,
        ChamsArmsOutline = Color3.fromRGB(255, 255, 255),
        ChamsArmsOutlineAlpha = 1,
        ChamsSleeves = false,
        ChamsSleevesMaterial = "ForceField",
        ChamsSleevesFill = Color3.fromRGB(255, 150, 0),
        ChamsSleevesFillAlpha = 0.5,
        ChamsSleevesOutline = Color3.fromRGB(255, 255, 255),
        ChamsSleevesOutlineAlpha = 1,
        ChamsGloves = false,
        ChamsGlovesMaterial = "ForceField",
        ChamsGlovesFill = Color3.fromRGB(0, 150, 255),
        ChamsGlovesFillAlpha = 0.5,
        ChamsGlovesOutline = Color3.fromRGB(255, 255, 255),
        ChamsGlovesOutlineAlpha = 1,
        BacktrackChams = false,
        BacktrackChamsMaterial = "ForceField",
        BacktrackChamsColor = Color3.fromRGB(255, 255, 255),
        BacktrackChamsAlpha = 0.5
    }
    EspSection:CreateToggle({
        Name = "Enable ESP",
        Default = false,
        Callback = function(state) ESP_Settings.Enabled = state end
    })
    EspSection:CreateToggle({
        Name = "Show Boxes",
        Default = false,
        Colorpickers = {
            {Name = "Box Color", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.BoxColor = c; ESP_Settings.BoxAlpha = a end},
            {Name = "Outline", ColorDefault = Color3.fromRGB(0, 0, 0), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.BoxOutlineColor = c; ESP_Settings.BoxOutlineAlpha = a end}
        },
        Dropdowns = {
            {
                Name = "Box Type",
                Options = {"Default", "Corner"},
                Default = "Corner",
                Callback = function(val) ESP_Settings.BoxType = val end
            }
        },
        Toggles = {
            {
                Name = "Box Fill", Default = false,
                Colorpickers = { 
                    {Name = "Top Color", ColorDefault = Color3.fromRGB(150, 150, 150), AlphaDefault = 0.5, Callback = function(c, a) ESP_Settings.BoxFillColor1 = c; ESP_Settings.BoxFillAlpha1 = a end},
                    {Name = "Bottom Color", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 0.5, Callback = function(c, a) ESP_Settings.BoxFillColor2 = c; ESP_Settings.BoxFillAlpha2 = a end}
                },
                Callback = function(state) ESP_Settings.BoxFill = state end
            },
            {
                Name = "Box Glow", Default = false,
                Colorpickers = { {Name = "Color", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 0.5, Callback = function(c, a) ESP_Settings.BoxGlowColor = c; ESP_Settings.BoxGlowAlpha = a end} },
                Callback = function(state) ESP_Settings.BoxGlow = state end
            }
        },
        Callback = function(state) ESP_Settings.Boxes = state end
    })
    EspSection:CreateToggle({
        Name = "Show Highlight",
        Default = false,
        Colorpickers = { 
            {Name = "Fill (Color)", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 0.5, Callback = function(c, a) ESP_Settings.HighlightFill = c; ESP_Settings.HighlightFillAlpha = a end},
            {Name = "Outline (Scatter)", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 0, Callback = function(c, a) ESP_Settings.HighlightOutline = c; ESP_Settings.HighlightOutlineAlpha = a end}
        },
        Callback = function(state) ESP_Settings.Highlight = state end
    })
    EspSection:CreateToggle({
        Name = "Show Health Bar",
        Default = false,
        Colorpickers = {
            {Name = "High HP", ColorDefault = Color3.fromRGB(0, 255, 0), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.HealthBarColor1 = c; ESP_Settings.HealthBarAlpha = a end},
            {Name = "Low HP", ColorDefault = Color3.fromRGB(255, 0, 0), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.HealthBarColor2 = c end},
            {Name = "Outline", ColorDefault = Color3.fromRGB(0, 0, 0), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.HealthBarOutlineColor = c; ESP_Settings.HealthBarOutlineAlpha = a end}
        },
        Dropdowns = {
            {
                Name = "Health Bar Mode",
                Options = {"Default", "Adaptive", "Fade"},
                Default = "Adaptive",
                Callback = function(val) ESP_Settings.HealthBarType = val end
            }
        },
        Callback = function(state) ESP_Settings.HealthBar = state end
    })
    EspSection:CreateToggle({
        Name = "Show Health Number",
        Default = false,
        Colorpickers = {
            {Name = "Text Color", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.HealthNumberColor = c; ESP_Settings.HealthNumberAlpha = a end}
        },
        Callback = function(state) ESP_Settings.ShowHealthNumber = state end
    })
    EspSection:CreateToggle({
        Name = "Healthbar Glow",
        Default = false,
        Colorpickers = {
            {Name = "Glow Color", ColorDefault = Color3.fromRGB(0, 255, 0), AlphaDefault = 0.5, Callback = function(c, a) ESP_Settings.HealthBarGlowColor = c; ESP_Settings.HealthBarGlowAlpha = a end}
        },
        Callback = function(state) ESP_Settings.HealthBarGlow = state end
    })
    EspSection:CreateToggle({
        Name = "Show Names",
        Default = false,
        Colorpickers = {
            {Name = "Name Color", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.NameColor = c; ESP_Settings.NameAlpha = a end},
            {Name = "Outline", ColorDefault = Color3.fromRGB(0, 0, 0), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.NameOutlineColor = c; ESP_Settings.NameOutlineAlpha = a end}
        },
        Callback = function(state) ESP_Settings.Names = state end
    })
    EspSection:CreateToggle({
        Name = "Show Weapon",
        Default = false,
        Colorpickers = {
            {Name = "Color", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.WeaponIconColor = c; ESP_Settings.WeaponIconAlpha = a end}
        },
        Callback = function(state) ESP_Settings.ShowWeapon = state end
    })
    EspSection:CreateToggle({
        Name = "Show Skeletons",
        Default = false,
        Colorpickers = {
            {Name = "Skeleton Color", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.SkeletonColor = c; ESP_Settings.SkeletonAlpha = a end},
            {Name = "Outline", ColorDefault = Color3.fromRGB(0, 0, 0), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.SkeletonOutlineColor = c; ESP_Settings.SkeletonOutlineAlpha = a end}
        },
        Callback = function(state) ESP_Settings.Skeleton = state end
    })
    EspSection:CreateToggle({
        Name = "Show Flags",
        Default = false,
        Toggles = {
            {
                Name = "Ping Flag", Default = true,
                Colorpickers = { {Name = "Color", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.FlagPingColor = c; ESP_Settings.FlagPingAlpha = a end} },
                Callback = function(state) ESP_Settings.FlagPing = state end
            },
            {
                Name = "AFK Flag", Default = true,
                Colorpickers = { {Name = "Color", ColorDefault = Color3.fromRGB(255, 255, 100), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.FlagAFKColor = c; ESP_Settings.FlagAFKAlpha = a end} },
                Callback = function(state) ESP_Settings.FlagAFK = state end
            },
            {
                Name = "Lethal Flag", Default = true,
                Colorpickers = { {Name = "Color", ColorDefault = Color3.fromRGB(255, 50, 50), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.FlagLethalColor = c; ESP_Settings.FlagLethalAlpha = a end} },
                Callback = function(state) ESP_Settings.FlagLethal = state end
            }
        },
        Callback = function(state) ESP_Settings.Flags = state end
    })
    local OffscreenToggleAPI = EspSection:CreateToggle({
        Name = "Offscreen Arrows",
        Default = false,
        Colorpickers = {
            {Name = "Arrow Color", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.OffscreenArrowColor = c; ESP_Settings.OffscreenArrowAlpha = a end},
            {Name = "Outline", ColorDefault = Color3.fromRGB(0, 0, 0), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.OffscreenArrowOutlineColor = c; ESP_Settings.OffscreenArrowOutlineAlpha = a end}
        },
        Callback = function(state) ESP_Settings.OffscreenArrows = state end
    })
    OffscreenToggleAPI.Elements:CreateSlider({
        Name = "Radius",
        Min = 50,
        Max = 500,
        Default = 150,
        Callback = function(val) ESP_Settings.OffscreenArrowRadius = val end
    })
    OffscreenToggleAPI.Elements:CreateSlider({
        Name = "Size",
        Min = 5,
        Max = 50,
        Default = 15,
        Callback = function(val) ESP_Settings.OffscreenArrowSize = val end
    })
    local ChamsSection = EspGeneralSubTab:CreateSection({
        Name = "Chams",
        Side = "Right"
    })
    ChamsSection:CreateToggle({
        Name = "Enemy Visible",
        Default = false,
        Colorpickers = {
            {Name = "Color", ColorDefault = Color3.fromRGB(0, 255, 0), AlphaDefault = 0.5, Callback = function(c, a) ESP_Settings.ChamsEnemyVisibleColor = c; ESP_Settings.ChamsEnemyVisibleAlpha = a end}
        },
        Callback = function(state) ESP_Settings.ChamsEnemyVisible = state end
    })
    ChamsSection:CreateDropdown({
        Name = "Enemy Visible Material",
        Options = {"ForceField", "Neon", "Plastic", "Glass", "Ice"},
        Default = "ForceField",
        Callback = function(val) ESP_Settings.ChamsEnemyVisibleMaterial = val end
    })
    ChamsSection:CreateToggle({
        Name = "Enemy Invisible",
        Default = false,
        Colorpickers = {
            {Name = "Color", ColorDefault = Color3.fromRGB(255, 0, 0), AlphaDefault = 0.5, Callback = function(c, a) ESP_Settings.ChamsEnemyInvisibleColor = c; ESP_Settings.ChamsEnemyInvisibleAlpha = a end}
        },
        Callback = function(state) ESP_Settings.ChamsEnemyInvisible = state end
    })
    ChamsSection:CreateDropdown({
        Name = "Enemy Invisible Material",
        Options = {"ForceField", "Neon", "Plastic", "Glass", "Ice"},
        Default = "ForceField",
        Callback = function(val) ESP_Settings.ChamsEnemyInvisibleMaterial = val end
    })
    ChamsSection:CreateToggle({
        Name = "Team Visible",
        Default = false,
        Colorpickers = {
            {Name = "Color", ColorDefault = Color3.fromRGB(0, 255, 255), AlphaDefault = 0.5, Callback = function(c, a) ESP_Settings.ChamsTeamVisibleColor = c; ESP_Settings.ChamsTeamVisibleAlpha = a end}
        },
        Callback = function(state) ESP_Settings.ChamsTeamVisible = state end
    })
    ChamsSection:CreateDropdown({
        Name = "Team Visible Material",
        Options = {"ForceField", "Neon", "Plastic", "Glass", "Ice"},
        Default = "ForceField",
        Callback = function(val) ESP_Settings.ChamsTeamVisibleMaterial = val end
    })
    ChamsSection:CreateToggle({
        Name = "Team Invisible",
        Default = false,
        Colorpickers = {
            {Name = "Color", ColorDefault = Color3.fromRGB(0, 0, 255), AlphaDefault = 0.5, Callback = function(c, a) ESP_Settings.ChamsTeamInvisibleColor = c; ESP_Settings.ChamsTeamInvisibleAlpha = a end}
        },
        Callback = function(state) ESP_Settings.ChamsTeamInvisible = state end
    })
    ChamsSection:CreateDropdown({
        Name = "Team Invisible Material",
        Options = {"ForceField", "Neon", "Plastic", "Glass", "Ice"},
        Default = "ForceField",
        Callback = function(val) ESP_Settings.ChamsTeamInvisibleMaterial = val end
    })
    ChamsSection:CreateToggle({
        Name = "Weapon Chams",
        Default = false,
        Colorpickers = {
            {Name = "Fill", ColorDefault = Color3.fromRGB(255, 0, 255), AlphaDefault = 0.5, Callback = function(c, a) ESP_Settings.ChamsWeaponFill = c; ESP_Settings.ChamsWeaponFillAlpha = a end},
            {Name = "Outline", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.ChamsWeaponOutline = c; ESP_Settings.ChamsWeaponOutlineAlpha = a end}
        },
        Callback = function(state) ESP_Settings.ChamsWeapon = state end
    })
    ChamsSection:CreateDropdown({
        Name = "Weapon Material",
        Options = {"ForceField", "Neon", "Plastic", "Glass", "Ice"},
        Default = "ForceField",
        Callback = function(val) ESP_Settings.ChamsWeaponMaterial = val end
    })
    ChamsSection:CreateToggle({
        Name = "Arms Chams",
        Default = false,
        Colorpickers = {
            {Name = "Fill", ColorDefault = Color3.fromRGB(0, 255, 255), AlphaDefault = 0.5, Callback = function(c, a) ESP_Settings.ChamsArmsFill = c; ESP_Settings.ChamsArmsFillAlpha = a end},
            {Name = "Outline", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.ChamsArmsOutline = c; ESP_Settings.ChamsArmsOutlineAlpha = a end}
        },
        Callback = function(state) ESP_Settings.ChamsArms = state end
    })
    ChamsSection:CreateDropdown({
        Name = "Arms Material",
        Options = {"ForceField", "Neon", "Plastic", "Glass", "Ice"},
        Default = "ForceField",
        Callback = function(val) ESP_Settings.ChamsArmsMaterial = val end
    })
    ChamsSection:CreateToggle({
        Name = "Sleeves Chams",
        Default = false,
        Colorpickers = {
            {Name = "Fill", ColorDefault = Color3.fromRGB(255, 150, 0), AlphaDefault = 0.5, Callback = function(c, a) ESP_Settings.ChamsSleevesFill = c; ESP_Settings.ChamsSleevesFillAlpha = a end},
            {Name = "Outline", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.ChamsSleevesOutline = c; ESP_Settings.ChamsSleevesOutlineAlpha = a end}
        },
        Callback = function(state) ESP_Settings.ChamsSleeves = state end
    })
    ChamsSection:CreateDropdown({
        Name = "Sleeves Material",
        Options = {"ForceField", "Neon", "Plastic", "Glass", "Ice"},
        Default = "ForceField",
        Callback = function(val) ESP_Settings.ChamsSleevesMaterial = val end
    })
    ChamsSection:CreateToggle({
        Name = "Gloves Chams",
        Default = false,
        Colorpickers = {
            {Name = "Fill", ColorDefault = Color3.fromRGB(0, 150, 255), AlphaDefault = 0.5, Callback = function(c, a) ESP_Settings.ChamsGlovesFill = c; ESP_Settings.ChamsGlovesFillAlpha = a end},
            {Name = "Outline", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 1, Callback = function(c, a) ESP_Settings.ChamsGlovesOutline = c; ESP_Settings.ChamsGlovesOutlineAlpha = a end}
        },
        Callback = function(state) ESP_Settings.ChamsGloves = state end
    })
    ChamsSection:CreateDropdown({
        Name = "Gloves Material",
        Options = {"ForceField", "Neon", "Plastic", "Glass", "Ice"},
        Default = "ForceField",
        Callback = function(val) ESP_Settings.ChamsGlovesMaterial = val end
    })
    ChamsSection:CreateToggle({
        Name = "Backtrack Chams",
        Default = false,
        Colorpickers = {
            {Name = "Color (Last Tick)", ColorDefault = Color3.fromRGB(255, 0, 0), AlphaDefault = 0.5, Callback = function(c, a) ESP_Settings.BacktrackChamsColor = c; ESP_Settings.BacktrackChamsAlpha = a end},
            {Name = "Color (First Tick)", ColorDefault = Color3.fromRGB(0, 255, 0), AlphaDefault = 0.5, Callback = function(c, a) ESP_Settings.BacktrackChamsColor2 = c; ESP_Settings.BacktrackChamsAlpha2 = a end}
        },
        Callback = function(state) ESP_Settings.BacktrackChams = state end
    })
    ChamsSection:CreateDropdown({
        Name = "Backtrack Material",
        Options = {"ForceField", "Neon", "Plastic", "Glass", "Ice"},
        Default = "ForceField",
        Callback = function(val) ESP_Settings.BacktrackChamsMaterial = val end
    })
    local function isGuiVisible(gui)
        local curr = gui
        while curr and curr:IsA("GuiObject") do
            if not curr.Visible then return false end
            curr = curr.Parent
        end
        return true
    end
    local RunService = game:GetService("RunService")
    RunService.RenderStepped:Connect(function()
        if not PreviewAPI.Viewport.Parent then return end
        local previewParts = {}
        for _, v in PreviewAPI.Model:GetDescendants() do
            if v:IsA("BasePart") then table.insert(previewParts, v) end
        end
        if ESP_Settings.ChamsEnemyVisible then
            local matStr = ESP_Settings.ChamsEnemyVisibleMaterial
            if matStr == "ForceField" then matStr = "Neon" end
            local mat = Enum.Material[matStr] or Enum.Material.ForceField
            for _, p in previewParts do
                p.Material = mat
                p.Color = ESP_Settings.ChamsEnemyVisibleColor
                p.Transparency = 1 - ESP_Settings.ChamsEnemyVisibleAlpha
            end
        else
            for _, p in previewParts do
                p.Material = Enum.Material.SmoothPlastic
                p.Color = Color3.fromRGB(163, 162, 165)
                p.Transparency = 0
            end
        end
        local cframe, size = PreviewAPI.Model:GetBoundingBox()
        local cam = PreviewAPI.Camera
        local vSize = PreviewAPI.Viewport.AbsoluteSize
        local fov = math.rad(cam.FieldOfView)
        local tanFov2 = math.tan(fov / 2)
        local aspectRatio = vSize.X / vSize.Y
        if aspectRatio ~= aspectRatio or aspectRatio == math.huge then aspectRatio = 1 end
        local absPos = PreviewAPI.Viewport.AbsolutePosition
        local guiInset = game:GetService("GuiService"):GetGuiInset()
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        local validBox = false
        for _, offset in {
            Vector3.new(size.X/2, size.Y/2, size.Z/2), Vector3.new(-size.X/2, size.Y/2, size.Z/2),
            Vector3.new(size.X/2, -size.Y/2, size.Z/2), Vector3.new(-size.X/2, -size.Y/2, size.Z/2),
            Vector3.new(size.X/2, size.Y/2, -size.Z/2), Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
            Vector3.new(size.X/2, -size.Y/2, -size.Z/2), Vector3.new(-size.X/2, -size.Y/2, -size.Z/2)
        } do
            local worldP = (cframe * CFrame.new(offset)).Position
            local localP = cam.CFrame:PointToObjectSpace(worldP)
            local z = -localP.Z
            if z > 0.1 then
                local normY = localP.Y / (z * tanFov2)
                local normX = localP.X / (z * tanFov2 * aspectRatio)
                local screenX = (normX + 1) / 2 * vSize.X + absPos.X
                local screenY = (1 - normY) / 2 * vSize.Y + absPos.Y + guiInset.Y
                if screenX < minX then minX = screenX end
                if screenX > maxX then maxX = screenX end
                if screenY < minY then minY = screenY end
                if screenY > maxY then maxY = screenY end
                validBox = true
            end
        end
        local esp = PreviewAPI.ESP
        local mainGui = game:GetService("CoreGui"):FindFirstChild("LocalMazeGUI")
        if not validBox or not isGuiVisible(PreviewAPI.Viewport) or absPos.Y < -50 or (mainGui and not mainGui.Enabled) then
            esp.Box.Visible = false
            for j = 1, 40 do esp.BoxFills[j].Visible = false end
            for j = 1, 8 do esp.BoxGlows[j].Visible = false end
            esp.BoxOutline.Visible = false
            esp.Name.Visible = false
            esp.WeaponIcon.Visible = false
            esp.HealthBar.Visible = false
            for j = 1, 6 do esp.HealthBarGlows[j].Visible = false end
            esp.HealthBarOutline.Visible = false
            esp.HealthNumber.Visible = false
            for i = 1, 8 do esp.Corners[i].Main.Visible = false; esp.Corners[i].Shadow.Visible = false end
            for i = 1, 14 do esp.Skeletons[i].Main.Visible = false; esp.Skeletons[i].Shadow.Visible = false end
            for i = 1, 15 do esp.HealthBarSegments[i].Visible = false end
            esp.Flags.Ping.Visible = false
            esp.Flags.AFK.Visible = false
            esp.Flags.Lethal.Visible = false
            return
        end
        local boxData = {
            Min = Vector2.new(minX, minY),
            Max = Vector2.new(maxX, maxY),
            Height = maxY - minY,
            Width = maxX - minX,
            Depth = 25
        }
        local isCorner = (ESP_Settings.BoxType == "Corner")
        local boxVisible = ESP_Settings.Boxes
        if boxVisible and not isCorner then
            esp.Box.Visible = true
            esp.BoxOutline.Visible = true
            esp.Box.Position = boxData.Min
            esp.Box.Size = boxData.Max - boxData.Min
            esp.Box.Color = ESP_Settings.BoxColor
            esp.Box.Transparency = 1 
            esp.BoxOutline.Position = boxData.Min
            esp.BoxOutline.Size = boxData.Max - boxData.Min
            esp.BoxOutline.Color = ESP_Settings.BoxOutlineColor
            esp.BoxOutline.Transparency = ESP_Settings.BoxOutlineAlpha
        else
            esp.Box.Visible = false
            esp.BoxOutline.Visible = false
        end
        if boxVisible then
            if ESP_Settings.BoxFill then
                local segments = 40
                for j = 1, segments do
                    local y1 = math.floor(boxData.Min.Y + (boxData.Height * ((j - 1) / segments)))
                    local y2 = math.floor(boxData.Min.Y + (boxData.Height * (j / segments)))
                    esp.BoxFills[j].Visible = true
                    esp.BoxFills[j].Position = Vector2.new(boxData.Min.X, y1)
                    esp.BoxFills[j].Size = Vector2.new(boxData.Width, y2 - y1)
                    esp.BoxFills[j].Color = ESP_Settings.BoxFillColor1:Lerp(ESP_Settings.BoxFillColor2, j / segments)
                    esp.BoxFills[j].Transparency = ESP_Settings.BoxFillAlpha1 + (ESP_Settings.BoxFillAlpha2 - ESP_Settings.BoxFillAlpha1) * (j / segments)
                end
            else
                for j = 1, 40 do esp.BoxFills[j].Visible = false end
            end
            if ESP_Settings.BoxGlow then
                for j = 1, 8 do
                    esp.BoxGlows[j].Visible = true
                    esp.BoxGlows[j].Position = boxData.Min - Vector2.new(j, j)
                    esp.BoxGlows[j].Size = (boxData.Max - boxData.Min) + Vector2.new(j * 2, j * 2)
                    esp.BoxGlows[j].Color = ESP_Settings.BoxGlowColor
                    local fade = 1 - (j / 8)
                    esp.BoxGlows[j].Transparency = ESP_Settings.BoxGlowAlpha * (fade * fade)
                end
            else
                for j = 1, 8 do esp.BoxGlows[j].Visible = false end
            end
        else
            for j = 1, 40 do esp.BoxFills[j].Visible = false end
            for j = 1, 8 do esp.BoxGlows[j].Visible = false end
        end
        if boxVisible and isCorner then
            local px, py = boxData.Min.X, boxData.Min.Y
            local sx, sy = boxData.Width, boxData.Height
            local lengthX = math.max(math.floor(sx / 4), 2)
            local lengthY = math.max(math.floor(sy / 4), 2)
            local function updateCorner(idx, x, y, sizeX, sizeY)
                esp.Corners[idx].Main.From = Vector2.new(x, y)
                esp.Corners[idx].Main.To = Vector2.new(x + sizeX, y + sizeY)
                esp.Corners[idx].Main.Color = ESP_Settings.BoxColor
                esp.Corners[idx].Main.Transparency = 1
                esp.Corners[idx].Main.Visible = true
                esp.Corners[idx].Shadow.From = Vector2.new(x, y)
                esp.Corners[idx].Shadow.To = Vector2.new(x + sizeX, y + sizeY)
                esp.Corners[idx].Shadow.Color = ESP_Settings.BoxOutlineColor
                esp.Corners[idx].Shadow.Transparency = ESP_Settings.BoxOutlineAlpha
                esp.Corners[idx].Shadow.Visible = true
            end
            updateCorner(1, px, py, lengthX, 0)
            updateCorner(2, px, py, 0, lengthY)
            updateCorner(3, px + sx - lengthX, py, lengthX, 0)
            updateCorner(4, px + sx, py, 0, lengthY)
            updateCorner(5, px, py + sy, lengthX, 0)
            updateCorner(6, px, py + sy - lengthY, 0, lengthY)
            updateCorner(7, px + sx - lengthX, py + sy, lengthX, 0)
            updateCorner(8, px + sx, py + sy - lengthY, 0, lengthY)
        else
            for i = 1, 8 do
                esp.Corners[i].Main.Visible = false
                esp.Corners[i].Shadow.Visible = false
            end
        end
        local hum = {Health = 100, MaxHealth = 100}
        local healthPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        local barHeight = boxData.Height * healthPct
        local textSize = math.max(math.min(math.floor(boxData.Height / 14), 16), 10)
        if ESP_Settings.HealthBar then
            if ESP_Settings.HealthBarGlow then
                for j = 1, 6 do
                    esp.HealthBarGlows[j].Visible = true
                    esp.HealthBarGlows[j].Position = boxData.Min + Vector2.new(-6 - j, -1 - j)
                    esp.HealthBarGlows[j].Size = Vector2.new(4 + (j * 2), boxData.Height + 2 + (j * 2))
                    esp.HealthBarGlows[j].Color = ESP_Settings.HealthBarGlowColor
                    local fade = 1 - (j / 6)
                    esp.HealthBarGlows[j].Transparency = ESP_Settings.HealthBarGlowAlpha * (fade * fade)
                end
            else
                for j = 1, 6 do esp.HealthBarGlows[j].Visible = false end
            end
            esp.HealthBarOutline.Visible = true
            esp.HealthBarOutline.Position = boxData.Min + Vector2.new(-6, -1)
            esp.HealthBarOutline.Size = Vector2.new(4, boxData.Height + 2)
            esp.HealthBarOutline.Color = ESP_Settings.HealthBarOutlineColor
            esp.HealthBarOutline.Transparency = ESP_Settings.HealthBarOutlineAlpha
            local isFade = (ESP_Settings.HealthBarType == "Fade")
            esp.HealthBar.Visible = not isFade
            if not isFade then
                esp.HealthBar.Position = boxData.Min + Vector2.new(-5, boxData.Height - barHeight)
                esp.HealthBar.Size = Vector2.new(2, barHeight)
                if ESP_Settings.HealthBarType == "Default" then
                    esp.HealthBar.Color = ESP_Settings.HealthBarColor1
                else
                    esp.HealthBar.Color = ESP_Settings.HealthBarColor2:Lerp(ESP_Settings.HealthBarColor1, healthPct)
                end
                esp.HealthBar.Transparency = ESP_Settings.HealthBarAlpha or 1
                for i = 1, 15 do esp.HealthBarSegments[i].Visible = false end
            else
                local segments = 15
                local sizePerSegment = boxData.Height / segments
                local currentSegment = math.ceil(healthPct * segments)
                local bottomY = boxData.Min.Y + boxData.Height
                for i = 1, segments do
                    local seg = esp.HealthBarSegments[i]
                    if i <= currentSegment and healthPct > 0 then
                        seg.Visible = true
                        local segBottom = bottomY - ((i - 1) * sizePerSegment)
                        local segTop
                        if i == currentSegment then
                            local remainder = (healthPct * segments) - (currentSegment - 1)
                            segTop = segBottom - (sizePerSegment * remainder)
                        else
                            segTop = segBottom - sizePerSegment
                        end
                        seg.Position = Vector2.new(boxData.Min.X - 5, math.floor(segTop))
                        seg.Size = Vector2.new(2, math.max(1, math.ceil(segBottom - segTop)))
                        seg.Color = ESP_Settings.HealthBarColor2:Lerp(ESP_Settings.HealthBarColor1, i / segments)
                        seg.Transparency = ESP_Settings.HealthBarAlpha or 1
                    else
                        seg.Visible = false
                    end
                end
            end
        else
            esp.HealthBar.Visible = false
            for j = 1, 6 do esp.HealthBarGlows[j].Visible = false end
            esp.HealthBarOutline.Visible = false
            for i = 1, 15 do esp.HealthBarSegments[i].Visible = false end
        end
        if ESP_Settings.ShowHealthNumber then
            esp.HealthNumber.Visible = true
            esp.HealthNumber.Text = tostring(math.floor(hum.Health))
            esp.HealthNumber.Position = Vector2.new(boxData.Min.X - 5 - esp.HealthNumber.TextBounds.X / 2 - 4, boxData.Min.Y + boxData.Height - barHeight - textSize / 2)
            esp.HealthNumber.Color = ESP_Settings.HealthNumberColor or Color3.new(1, 1, 1)
            esp.HealthNumber.Transparency = ESP_Settings.HealthNumberAlpha or 1
            esp.HealthNumber.Size = textSize
            esp.HealthNumber.Font = 2
        else
            esp.HealthNumber.Visible = false
        end
        if ESP_Settings.Names then
            esp.Name.Visible = true
            esp.Name.Text = "Preview"
            esp.Name.Position = Vector2.new(boxData.Min.X + (boxData.Width / 2), boxData.Min.Y - textSize - 2)
            esp.Name.Size = textSize
            esp.Name.Font = 2
            esp.Name.Color = ESP_Settings.NameColor
            esp.Name.Transparency = ESP_Settings.NameAlpha
            esp.Name.OutlineColor = ESP_Settings.NameOutlineColor
        else
            esp.Name.Visible = false
        end
        local currentFlagY = boxData.Min.Y
        local function drawFlag(drawObj, text, color, alpha)
            drawObj.Visible = true
            drawObj.Text = text
            drawObj.Color = color
            drawObj.Transparency = alpha
            drawObj.Size = textSize
            drawObj.Font = 2
            drawObj.OutlineColor = Color3.new(0, 0, 0)
            drawObj.Position = Vector2.new(boxData.Min.X + boxData.Width + 4, currentFlagY)
            currentFlagY = currentFlagY + textSize
        end
        if ESP_Settings.Flags then
            if ESP_Settings.FlagPing then drawFlag(esp.Flags.Ping, "PING", ESP_Settings.FlagPingColor, ESP_Settings.FlagPingAlpha) else esp.Flags.Ping.Visible = false end
            if ESP_Settings.FlagAFK then drawFlag(esp.Flags.AFK, "AFK", ESP_Settings.FlagAFKColor, ESP_Settings.FlagAFKAlpha) else esp.Flags.AFK.Visible = false end
            if ESP_Settings.FlagLethal then drawFlag(esp.Flags.Lethal, "LETHAL", ESP_Settings.FlagLethalColor, ESP_Settings.FlagLethalAlpha) else esp.Flags.Lethal.Visible = false end
        else
            esp.Flags.Ping.Visible = false
            esp.Flags.AFK.Visible = false
            esp.Flags.Lethal.Visible = false
        end
        if ESP_Settings.ShowWeapon then
            esp.WeaponIcon.Visible = true
            esp.WeaponIcon.Image = Utility:GetWeaponIcon("AK47")
            esp.WeaponIcon.ImageColor3 = ESP_Settings.WeaponIconColor
            esp.WeaponIcon.ImageTransparency = 1 - ESP_Settings.WeaponIconAlpha
            local wWidth = textSize * 7.5
            local wHeight = textSize * 4.5
            esp.WeaponIcon.Size = UDim2.new(0, wWidth, 0, wHeight)
            esp.WeaponIcon.Position = UDim2.new(0, boxData.Min.X + (boxData.Width / 2) - (wWidth / 2), 0, boxData.Max.Y + 2)
        else
            esp.WeaponIcon.Visible = false
        end
        if ESP_Settings.Skeleton then
            local R6JointsDummy = {
                {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
                {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
            }
            local function getPoint(partName)
                local part = PreviewAPI.Model:FindFirstChild(partName)
                if not part then return nil end
                local localP = cam.CFrame:PointToObjectSpace(part.Position)
                local z = -localP.Z
                if z <= 0.1 then return nil end
                local normY = localP.Y / (z * tanFov2)
                local normX = localP.X / (z * tanFov2 * aspectRatio)
                local screenX = (normX + 1) / 2 * vSize.X + absPos.X
                local screenY = (1 - normY) / 2 * vSize.Y + absPos.Y + guiInset.Y
                return Vector2.new(screenX, screenY)
            end
            for i = 1, #R6JointsDummy do
                local p0 = getPoint(R6JointsDummy[i][1])
                local p1 = getPoint(R6JointsDummy[i][2])
                if p0 and p1 then
                    esp.Skeletons[i].Main.Visible = true
                    esp.Skeletons[i].Main.From = p0
                    esp.Skeletons[i].Main.To = p1
                    esp.Skeletons[i].Main.Color = ESP_Settings.SkeletonColor
                    esp.Skeletons[i].Main.Transparency = ESP_Settings.SkeletonAlpha
                    esp.Skeletons[i].Shadow.Visible = true
                    esp.Skeletons[i].Shadow.From = p0
                    esp.Skeletons[i].Shadow.To = p1
                    esp.Skeletons[i].Shadow.Color = ESP_Settings.SkeletonOutlineColor
                    esp.Skeletons[i].Shadow.Transparency = ESP_Settings.SkeletonOutlineAlpha
                else
                    esp.Skeletons[i].Main.Visible = false
                    esp.Skeletons[i].Shadow.Visible = false
                end
            end
            for i = #R6JointsDummy + 1, 14 do
                esp.Skeletons[i].Main.Visible = false
                esp.Skeletons[i].Shadow.Visible = false
            end
        else
            for i = 1, 14 do
                esp.Skeletons[i].Main.Visible = false
                esp.Skeletons[i].Shadow.Visible = false
            end
        end
        local previewHl = PreviewAPI.Model:FindFirstChild("ESPHighlight")
        if ESP_Settings.Highlight then
            if not previewHl then
                previewHl = Instance.new("Highlight")
                previewHl.Name = "ESPHighlight"
                previewHl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                previewHl.Parent = PreviewAPI.Model
            end
            previewHl.FillColor = ESP_Settings.HighlightFill
            previewHl.FillTransparency = 1 - ESP_Settings.HighlightFillAlpha
            previewHl.OutlineColor = ESP_Settings.HighlightOutline
            previewHl.OutlineTransparency = 1 - ESP_Settings.HighlightOutlineAlpha
            previewHl.Enabled = true
        elseif previewHl then
            previewHl.Enabled = false
        end
    end)
    local WorldSection = VisualsTab:CreateSection({
        Name = "World",
        Side = "Left"
    })
    local EffectsSection = VisualsTab:CreateSection({
        Name = "Atmosphere Changer",
        Side = "Left"
    })
    local ColorCorrectionSection = VisualsTab:CreateSection({
        Name = "Color Correction",
        Side = "Left"
    })
    local CameraSection = VisualsTab:CreateSection({
        Name = "Camera",
        Side = "Right"
    })
    env.HitmarkerSettings = {
        Hitmarker2D = false,
        Hitmarker2D_Color = Color3.fromRGB(255, 255, 255),
        Hitmarker2D_OutlineColor = Color3.fromRGB(0, 0, 0),
        Hitmarker2D_Gap = 5,
        Hitmarker2D_Length = 10,
        Hitmarker2D_Thickness = 2,
        Hitmarker2D_FadeTime = 0.5,
        Hitmarker3D = false,
        Hitmarker3D_Color = Color3.fromRGB(255, 255, 255),
        Hitmarker3D_OutlineColor = Color3.fromRGB(0, 0, 0),
        Hitmarker3D_Gap = 5,
        Hitmarker3D_Length = 10,
        Hitmarker3D_Thickness = 2,
        Hitmarker3D_FadeTime = 0.5,
        Tracers = false,
        TracerColor = Color3.fromRGB(255, 255, 255),
        TracerFadeTime = 0.5,
        HitLog = false,
        HitLogPosition = "Top Left",
        Hitsound = "Default"
    }
    local WorldSettings = {
        CustomFOVEnabled = false,
        CustomFOV = 70,
        ThirdPersonEnabled = false,
        ThirdPersonDistance = 10,
        WorldColorEnabled = false,
        WorldColor = Color3.fromRGB(255, 255, 255),
        SkyColorEnabled = false,
        SkyColor = Color3.fromRGB(255, 255, 255),
        EffectsChangerEnabled = false,
        ClockTime = 12,
        AtmosphereDensity = 0.3,
        AtmosphereHaze = 0,
        AtmosphereGlare = 0,
        ColorCorrectionEnabled = false,
        Saturation = 0,
        Brightness = 0,
        Contrast = 0,
        TintColor = Color3.fromRGB(255, 255, 255)
    }
    local OriginalMapData = {}
    local MapParts = {}
    local function UpdateWorldColor(forceRebuild)
        task.spawn(function()
            if not WorldSettings.WorldColorEnabled then
                for part, data in OriginalMapData do
                    if part and part.Parent then
                        part.Color = data.Color
                        for child, val in data.Textures do
                            if child and child.Parent then
                                if child:IsA("Texture") or child:IsA("Decal") then
                                    child.Color3 = val
                                end
                            end
                        end
                    end
                end
                OriginalMapData = {}
                MapParts = {}
                return
            end
            if forceRebuild or #MapParts == 0 then
                MapParts = {}
                for _, part in workspace:GetDescendants() do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and not part:FindFirstAncestorOfClass("Camera") then
                        local model = part:FindFirstAncestorOfClass("Model")
                        if not (model and model:FindFirstChild("Humanoid")) and not part:FindFirstAncestor("ClarityChamsGui") then
                            if not OriginalMapData[part] then
                                OriginalMapData[part] = {
                                    Color = part.Color,
                                    Textures = {}
                                }
                            end
                            table.insert(MapParts, part)
                        end
                    end
                end
            end
            local c = WorldSettings.WorldColor
            for _, part in MapParts do
                if part and part.Parent then
                    part.Color = c
                    for _, child in part:GetChildren() do
                        if child:IsA("Texture") or child:IsA("Decal") then
                            if OriginalMapData[part].Textures[child] == nil then
                                OriginalMapData[part].Textures[child] = child.Color3
                            end
                            child.Color3 = c
                        end
                    end
                end
            end
        end)
    end
    WorldSection:CreateToggle({
        Name = "World Color",
        Default = false,
        Colorpickers = { {Name = "Color", ColorDefault = Color3.fromRGB(255, 255, 255), Callback = function(c) 
            WorldSettings.WorldColor = c 
            if WorldSettings.WorldColorEnabled then UpdateWorldColor(false) end
        end} },
        Callback = function(state) 
            WorldSettings.WorldColorEnabled = state 
            UpdateWorldColor(true)
        end
    })
    WorldSection:CreateToggle({
        Name = "Second Color",
        Default = false,
        Colorpickers = { {Name = "Color", ColorDefault = Color3.fromRGB(255, 255, 255), Callback = function(c) WorldSettings.SkyColor = c end} },
        Callback = function(state) WorldSettings.SkyColorEnabled = state end
    })
    EffectsSection:CreateToggle({
        Name = "Enable Effects Changer",
        Default = false,
        Callback = function(state) WorldSettings.EffectsChangerEnabled = state end
    })
    EffectsSection:CreateSlider({
        Name = "Clock Time",
        Min = 0,
        Max = 24,
        Default = 12,
        Callback = function(val) WorldSettings.ClockTime = val end
    })
    EffectsSection:CreateSlider({
        Name = "Atmosphere Density",
        Min = 0,
        Max = 100,
        Default = 30,
        Callback = function(val) WorldSettings.AtmosphereDensity = val / 100 end
    })
    EffectsSection:CreateSlider({
        Name = "Atmosphere Haze",
        Min = 0,
        Max = 100,
        Default = 0,
        Callback = function(val) WorldSettings.AtmosphereHaze = val / 10 end
    })
    EffectsSection:CreateSlider({
        Name = "Atmosphere Glare",
        Min = 0,
        Max = 100,
        Default = 0,
        Callback = function(val) WorldSettings.AtmosphereGlare = val / 10 end
    })
    ColorCorrectionSection:CreateToggle({
        Name = "Enable Color Correction",
        Default = false,
        Colorpickers = { {Name = "Tint Color", ColorDefault = Color3.fromRGB(255, 255, 255), Callback = function(c) WorldSettings.TintColor = c end} },
        Callback = function(state) WorldSettings.ColorCorrectionEnabled = state end
    })
    ColorCorrectionSection:CreateSlider({
        Name = "Saturation",
        Min = -100,
        Max = 100,
        Default = 0,
        Callback = function(val) WorldSettings.Saturation = val / 100 end
    })
    ColorCorrectionSection:CreateSlider({
        Name = "Brightness",
        Min = -100,
        Max = 100,
        Default = 0,
        Callback = function(val) WorldSettings.Brightness = val / 100 end
    })
    ColorCorrectionSection:CreateSlider({
        Name = "Contrast",
        Min = -100,
        Max = 100,
        Default = 0,
        Callback = function(val) WorldSettings.Contrast = val / 100 end
    })
    CameraSection:CreateToggle({
        Name = "Enable Custom FOV",
        Default = false,
        Callback = function(state) WorldSettings.CustomFOVEnabled = state end
    })
    CameraSection:CreateSlider({
        Name = "Field of View",
        Min = 60,
        Max = 120,
        Default = 70,
        Callback = function(val) WorldSettings.CustomFOV = val end
    })
    CameraSection:CreateToggle({
        Name = "Third Person",
        Default = false,
        Callback = function(state) WorldSettings.ThirdPersonEnabled = state end
    })
    CameraSection:CreateSlider({
        Name = "Third Person Distance",
        Min = 5,
        Max = 30,
        Default = 10,
        Callback = function(val) WorldSettings.ThirdPersonDistance = val end
    })
    local HitLogSection = VisualsTab:CreateSection({
        Name = "Hit Logs",
        Side = "Right"
    })
    HitLogSection:CreateToggle({
        Name = "Enable Hit Logs",
        Default = false,
        Callback = function(state) env.HitmarkerSettings.HitLog = state end
    })
    HitLogSection:CreateDropdown({
        Name = "Hit Log Position",
        Options = {"Top Left", "Bottom Center"},
        Default = "Top Left",
        Callback = function(val) env.HitmarkerSettings.HitLogPosition = val end
    })
    local HitEffects2DSection = VisualsTab:CreateSection({
        Name = "2D Hit Effects",
        Side = "Right"
    })
    HitEffects2DSection:CreateToggle({
        Name = "2D Hitmarker",
        Default = false,
        Colorpickers = {
            {Name = "Color", ColorDefault = Color3.fromRGB(255, 255, 255), Callback = function(c) env.HitmarkerSettings.Hitmarker2D_Color = c end},
            {Name = "Outline", ColorDefault = Color3.fromRGB(0, 0, 0), Callback = function(c) env.HitmarkerSettings.Hitmarker2D_OutlineColor = c end}
        },
        Callback = function(state) env.HitmarkerSettings.Hitmarker2D = state end
    })
    HitEffects2DSection:CreateDropdown({
        Name = "Hitsound",
        Options = HitSoundDropdownList,
        Default = "Off",
        Callback = function(val) env.HitmarkerSettings.Hitsound = val end
    })
    HitEffects2DSection:CreateSlider({
        Name = "2D Gap",
        Min = 0,
        Max = 20,
        Default = 5,
        Callback = function(val) env.HitmarkerSettings.Hitmarker2D_Gap = val end
    })
    HitEffects2DSection:CreateSlider({
        Name = "2D Length",
        Min = 2,
        Max = 30,
        Default = 10,
        Callback = function(val) env.HitmarkerSettings.Hitmarker2D_Length = val end
    })
    HitEffects2DSection:CreateSlider({
        Name = "2D Thickness",
        Min = 1,
        Max = 10,
        Default = 2,
        Callback = function(val) env.HitmarkerSettings.Hitmarker2D_Thickness = val end
    })
    HitEffects2DSection:CreateSlider({
        Name = "2D Fade Time",
        Min = 1,
        Max = 20,
        Default = 5,
        Callback = function(val) env.HitmarkerSettings.Hitmarker2D_FadeTime = val / 10 end
    })
    local HitEffects3DSection = VisualsTab:CreateSection({
        Name = "3D Hit Effects",
        Side = "Right"
    })
    HitEffects3DSection:CreateToggle({
        Name = "3D Hitmarker",
        Default = false,
        Colorpickers = {
            {Name = "Color", ColorDefault = Color3.fromRGB(255, 255, 255), Callback = function(c) env.HitmarkerSettings.Hitmarker3D_Color = c end},
            {Name = "Outline", ColorDefault = Color3.fromRGB(0, 0, 0), Callback = function(c) env.HitmarkerSettings.Hitmarker3D_OutlineColor = c end}
        },
        Callback = function(state) env.HitmarkerSettings.Hitmarker3D = state end
    })
    HitEffects3DSection:CreateSlider({
        Name = "3D Gap",
        Min = 0,
        Max = 20,
        Default = 5,
        Callback = function(val) env.HitmarkerSettings.Hitmarker3D_Gap = val end
    })
    HitEffects3DSection:CreateSlider({
        Name = "3D Length",
        Min = 2,
        Max = 30,
        Default = 10,
        Callback = function(val) env.HitmarkerSettings.Hitmarker3D_Length = val end
    })
    HitEffects3DSection:CreateSlider({
        Name = "3D Thickness",
        Min = 1,
        Max = 10,
        Default = 2,
        Callback = function(val) env.HitmarkerSettings.Hitmarker3D_Thickness = val end
    })
    HitEffects3DSection:CreateSlider({
        Name = "3D Fade Time",
        Min = 1,
        Max = 20,
        Default = 5,
        Callback = function(val) env.HitmarkerSettings.Hitmarker3D_FadeTime = val / 10 end
    })
    HitEffects3DSection:CreateToggle({
        Name = "Bullet Tracers",
        Default = false,
        Colorpickers = { {Name = "Color", ColorDefault = Color3.fromRGB(255, 255, 255), Callback = function(c) env.HitmarkerSettings.TracerColor = c end} },
        Callback = function(state) env.HitmarkerSettings.Tracers = state end
    })
    HitEffects3DSection:CreateSlider({
        Name = "Tracer Fade Time",
        Min = 1,
        Max = 20,
        Default = 5,
        Callback = function(val) env.HitmarkerSettings.TracerFadeTime = val / 10 end
    })
    env.GetFakeDamage = function(targetInstance, currentHealth)
        local isHead = targetInstance and (targetInstance.Name:lower():find("head") ~= nil)
        local dmg = 0
        if isHead then
            if currentHealth <= 92 then
                dmg = math.random(100, 115)
            else
                dmg = math.random(80, 92)
            end
        else
            if currentHealth <= 60 then
                dmg = math.random(70, 101)
            else
                dmg = math.random(15, 60)
            end
        end
        return dmg
    end
    env.LogHit = function(targetName, bodyPart, damage)
        if not env.HitmarkerSettings.HitLog then return end
        local accent = Theme.ToggleActive
        local r, g, b = math.floor(accent.R * 255), math.floor(accent.G * 255), math.floor(accent.B * 255)
        local hex = string.format("#%02X%02X%02X", r, g, b)
        local text = string.format('Hit <font color="%s">%s</font> in <font color="%s">%s</font> for <font color="%s">%s</font> damage', hex, tostring(targetName), hex, tostring(bodyPart), hex, tostring(damage))
        Library:Notify(text, 3, env.HitmarkerSettings.HitLogPosition)
    end
    env.Draw2DHitmarker = function()
        task.spawn(function()
            local soundOption = env.HitmarkerSettings.Hitsound
            if soundOption ~= "Off" then
                local sound = Instance.new("Sound", workspace)
                local sid = CustomHitsoundIDs[soundOption]
                if sid then
                    sound.SoundId = "rbxassetid://" .. sid
                else
                    sound.SoundId = "rbxassetid://160432334"
                end
                sound.Volume = 1
                sound:Play()
                game:GetService("Debris"):AddItem(sound, 2)
            end
            if not Drawing then return end
            local center = workspace.CurrentCamera.ViewportSize / 2
            local gap = env.HitmarkerSettings.Hitmarker2D_Gap
            local length = env.HitmarkerSettings.Hitmarker2D_Length
            local thickness = env.HitmarkerSettings.Hitmarker2D_Thickness
            local color = env.HitmarkerSettings.Hitmarker2D_Color
            local outlineColor = env.HitmarkerSettings.Hitmarker2D_OutlineColor
            local fadeTime = env.HitmarkerSettings.Hitmarker2D_FadeTime
            local lines = {}
            local function createLine(dx, dy)
                local outL = Drawing.new("Line")
                outL.Visible = true
                outL.Color = outlineColor
                outL.Thickness = thickness + 2
                outL.ZIndex = 1
                local inL = Drawing.new("Line")
                inL.Visible = true
                inL.Color = color
                inL.Thickness = thickness
                inL.ZIndex = 2
                table.insert(lines, {outL, inL, dx, dy})
            end
            createLine(1, 1)
            createLine(-1, -1)
            createLine(1, -1)
            createLine(-1, 1)
            local steps = 30
            local sleepTime = fadeTime / steps
            for i = 1, steps do
                local transparency = 1 - (i/steps)
                for _, line in lines do
                    local dx, dy = line[3], line[4]
                    line[1].From = center + Vector2.new(dx * (gap - 1), dy * (gap - 1))
                    line[1].To = center + Vector2.new(dx * (gap + length + 1), dy * (gap + length + 1))
                    line[1].Transparency = transparency
                    line[2].From = center + Vector2.new(dx * gap, dy * gap)
                    line[2].To = center + Vector2.new(dx * (gap + length), dy * (gap + length))
                    line[2].Transparency = transparency
                end
                task.wait(sleepTime)
            end
            for _, line in lines do
                line[1]:Remove()
                line[2]:Remove()
            end
        end)
    end
    env.Draw3DHitmarker = function(position)
        task.spawn(function()
            local part = Instance.new("Part")
            part.Anchored = true
            part.CanCollide = false
            part.Transparency = 1
            part.Size = Vector3.new(0.1, 0.1, 0.1)
            part.Position = position
            part.Parent = workspace
            local bg = Instance.new("BillboardGui", part)
            bg.AlwaysOnTop = true
            bg.Size = UDim2.new(0, 100, 0, 100)
            local gap = env.HitmarkerSettings.Hitmarker3D_Gap
            local length = env.HitmarkerSettings.Hitmarker3D_Length
            local thickness = env.HitmarkerSettings.Hitmarker3D_Thickness
            local color = env.HitmarkerSettings.Hitmarker3D_Color
            local outlineColor = env.HitmarkerSettings.Hitmarker3D_OutlineColor
            local fadeTime = env.HitmarkerSettings.Hitmarker3D_FadeTime
            local dist = gap + (length / 2)
            local offset = dist * 0.7071
            local lines = {}
            local configs = {
                { -1, -1, 45 },  
                { 1, 1, 45 },    
                { 1, -1, -45 },  
                { -1, 1, -45 }   
            }
            for _, cfg in configs do
                local dx, dy, rot = cfg[1], cfg[2], cfg[3]
                local out = Instance.new("Frame", bg)
                out.Size = UDim2.new(0, length + 2, 0, thickness + 2)
                out.Position = UDim2.new(0.5, dx * offset, 0.5, dy * offset)
                out.AnchorPoint = Vector2.new(0.5, 0.5)
                out.Rotation = rot
                out.BackgroundColor3 = outlineColor
                out.BorderSizePixel = 0
                out.ZIndex = 1
                local inn = Instance.new("Frame", out)
                inn.Size = UDim2.new(0, length, 0, thickness)
                inn.Position = UDim2.new(0.5, 0, 0.5, 0)
                inn.AnchorPoint = Vector2.new(0.5, 0.5)
                inn.BackgroundColor3 = color
                inn.BorderSizePixel = 0
                inn.ZIndex = 2
                table.insert(lines, {out, inn})
            end
            local ts = game:GetService("TweenService")
            local ti = TweenInfo.new(fadeTime, Enum.EasingStyle.Linear)
            for _, linePair in lines do
                ts:Create(linePair[1], ti, {BackgroundTransparency = 1}):Play()
                ts:Create(linePair[2], ti, {BackgroundTransparency = 1}):Play()
            end
            task.wait(fadeTime)
            part:Destroy()
        end)
    end
    env.DrawTracer = function(startPos, endPos)
        task.spawn(function()
            local distance = (endPos - startPos).Magnitude
            local part = Instance.new("Part")
            part.Anchored = true
            part.CanCollide = false
            part.Material = Enum.Material.Neon
            part.Color = env.HitmarkerSettings.TracerColor
            part.Size = Vector3.new(0.1, 0.1, distance)
            part.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -distance / 2)
            part.Parent = workspace
            local fadeTime = env.HitmarkerSettings.TracerFadeTime
            local ts = game:GetService("TweenService")
            local ti = TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = ts:Create(part, ti, {Transparency = 1, Size = Vector3.new(0, 0, distance)})
            tween:Play()
            task.wait(fadeTime)
            part:Destroy()
        end)
    end
    local OrigEffects = {}
    local effectsSaved = false
    local function SaveEffects()
        local Lighting = game:GetService("Lighting")
        OrigEffects.ClockTime = Lighting.ClockTime
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then
            OrigEffects.Density = atm.Density
            OrigEffects.Haze = atm.Haze
            OrigEffects.Glare = atm.Glare
        end
        effectsSaved = true
    end
    local function RestoreEffects()
        if not effectsSaved then return end
        local Lighting = game:GetService("Lighting")
        Lighting.ClockTime = OrigEffects.ClockTime
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm and OrigEffects.Density then
            atm.Density = OrigEffects.Density
            atm.Haze = OrigEffects.Haze
            atm.Glare = OrigEffects.Glare
        end
        effectsSaved = false
    end
    game:GetService("RunService"):BindToRenderStep("ClarityVMOffset", 3000, function()
        if WorldSettings.CustomFOVEnabled then
            if workspace.CurrentCamera.FieldOfView > 55 then
                workspace.CurrentCamera.FieldOfView = WorldSettings.CustomFOV
            end
        end
        if WorldSettings.ThirdPersonEnabled then
            local cam = workspace.CurrentCamera
            local lp = game:GetService("Players").LocalPlayer
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local targetDist = WorldSettings.ThirdPersonDistance
                local direction = -cam.CFrame.LookVector * targetDist
                local hit = workspace:Raycast(cam.CFrame.Position, direction, rayParams)
                if hit then
                    targetDist = (hit.Position - cam.CFrame.Position).Magnitude - 0.5
                    if targetDist < 0 then targetDist = 0 end
                end
                cam.CFrame = cam.CFrame * CFrame.new(0, 0, targetDist)
                for _, v in char:GetDescendants() do
                    if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                        v.LocalTransparencyModifier = 0
                    end
                end
            end
        end
        local lp = game:GetService("Players").LocalPlayer
        local isAlive = false
        if lp and lp.Character and lp.Character:FindFirstChild("Humanoid") and lp.Character.Humanoid.Health > 0 then
            isAlive = true
        end
        if isAlive then
            if WorldSettings.ColorCorrectionEnabled then
                local Lighting = game:GetService("Lighting")
                local cc = Lighting:FindFirstChild("ClarityColorCorrection")
                if not cc then
                    cc = Instance.new("ColorCorrectionEffect")
                    cc.Name = "ClarityColorCorrection"
                    cc.Parent = Lighting
                end
                cc.Enabled = true
                cc.Saturation = WorldSettings.Saturation
                cc.Brightness = WorldSettings.Brightness
                cc.Contrast = WorldSettings.Contrast
                cc.TintColor = WorldSettings.TintColor
            else
                local Lighting = game:GetService("Lighting")
                local cc = Lighting:FindFirstChild("ClarityColorCorrection")
                if cc then cc.Enabled = false end
            end
            if WorldSettings.EffectsChangerEnabled then
                if not effectsSaved then SaveEffects() end
                local Lighting = game:GetService("Lighting")
                Lighting.ClockTime = WorldSettings.ClockTime
                local atm = Lighting:FindFirstChildOfClass("Atmosphere")
                if atm then
                    atm.Density = WorldSettings.AtmosphereDensity
                    atm.Haze = WorldSettings.AtmosphereHaze
                    atm.Glare = WorldSettings.AtmosphereGlare
                end
            elseif effectsSaved then
                RestoreEffects()
            end
            local Lighting = game:GetService("Lighting")
            if WorldSettings.SkyColorEnabled then
                local skyColor = WorldSettings.SkyColor
                Lighting.OutdoorAmbient = skyColor
                Lighting.Ambient = skyColor
                Lighting.ColorShift_Bottom = skyColor
                Lighting.ColorShift_Top = skyColor
                Lighting.FogColor = skyColor
                local atm = Lighting:FindFirstChildOfClass("Atmosphere")
                if not atm then
                    atm = Instance.new("Atmosphere")
                    atm.Name = "ClaritySky"
                    atm.Parent = Lighting
                end
                atm.Color = skyColor
                atm.Decay = skyColor
                if not WorldSettings.EffectsChangerEnabled and atm.Name == "ClaritySky" then
                    atm.Density = 0.5
                    atm.Haze = 2
                end
            else
                local customAtm = Lighting:FindFirstChild("ClaritySky")
                if customAtm then customAtm:Destroy() end
            end
        else
            local Lighting = game:GetService("Lighting")
            local cc = Lighting:FindFirstChild("ClarityColorCorrection")
            if cc then cc.Enabled = false end
            if effectsSaved then
                RestoreEffects()
            end
        end
    end)
    local function GetCurrentFOV()
        local fov = workspace.CurrentCamera.FieldOfView
        if WorldSettings and WorldSettings.CustomFOVEnabled and fov > 55 then
            return WorldSettings.CustomFOV
        end
        return fov
    end
    local ESP_Objects = {}
    local Camera = workspace.CurrentCamera
    local CharactersFolder = workspace:WaitForChild("Characters", 10)
    local ChamsGui = Instance.new("ScreenGui")
    ChamsGui.Name = "ClarityChamsGui"
    ChamsGui.IgnoreGuiInset = true
    pcall(function() ChamsGui.Parent = game:GetService("CoreGui") end)
    local ChamsViewport = Instance.new("ViewportFrame")
    ChamsViewport.Name = "Viewport"
    ChamsViewport.Size = UDim2.new(1, 0, 1, 0)
    ChamsViewport.BackgroundTransparency = 1
    ChamsViewport.Ambient = Color3.new(1, 1, 1)
    ChamsViewport.LightColor = Color3.new(1, 1, 1)
    ChamsViewport.Parent = ChamsGui
    local ChamsCamera = Instance.new("Camera")
    ChamsCamera.Name = "ChamsCamera"
    ChamsViewport.CurrentCamera = ChamsCamera
    local ActiveChams = {} 
    local function UpdateCham(instance, enabled, fill, outline, fillAlpha, outlineAlpha, depthMode, materialName)
        if not instance then return end
        if enabled then
            if not ActiveChams[instance] then
                local cloneModel = Instance.new("Model")
                cloneModel.Name = instance.Name
                cloneModel.Parent = ChamsViewport
                local partsMap = {}
                for _, part in instance:GetChildren() do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 1 then
                        pcall(function()
                            local clonePart = part:Clone()
                            if clonePart then
                                clonePart:ClearAllChildren()
                                clonePart.Anchored = true
                                clonePart.CanCollide = false
                                clonePart.CanTouch = false
                                clonePart.CanQuery = false
                                clonePart.CastShadow = false
                                clonePart.Parent = cloneModel
                                partsMap[part] = clonePart
                            end
                        end)
                    end
                end
                ActiveChams[instance] = { Model = cloneModel, PartsMap = partsMap }
            end
            local chamData = ActiveChams[instance]
            local newMat = Enum.Material.ForceField
            if materialName == "Neon" then newMat = Enum.Material.Neon
            elseif materialName == "Plastic" then newMat = Enum.Material.SmoothPlastic
            elseif materialName == "Glass" then newMat = Enum.Material.Glass
            elseif materialName == "Ice" then newMat = Enum.Material.Ice
            end
            local needsPropUpdate = false
            if chamData.LastMat ~= newMat or chamData.LastColor ~= fill or chamData.LastAlpha ~= fillAlpha then
                chamData.LastMat = newMat
                chamData.LastColor = fill
                chamData.LastAlpha = fillAlpha
                needsPropUpdate = true
            end
            for realPart, clonePart in chamData.PartsMap do
                if realPart and realPart.Parent and realPart.Transparency < 1 then
                    clonePart.CFrame = realPart.CFrame
                    if needsPropUpdate then
                        clonePart.Color = fill
                        clonePart.Transparency = 1 - fillAlpha
                        clonePart.Material = newMat
                    end
                else
                    clonePart:Destroy()
                    chamData.PartsMap[realPart] = nil
                end
            end
        else
            if ActiveChams[instance] then
                ActiveChams[instance].Model:Destroy()
                ActiveChams[instance] = nil
            end
        end
    end
    local function UpdateHighlight(char, enabled, fColor, fAlpha, oColor, oAlpha)
        if not char then return end
        local highlight = char:FindFirstChild("ESPHighlight")
        if enabled then
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "ESPHighlight"
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = char
            end
            highlight.FillColor = fColor
            highlight.FillTransparency = 1 - fAlpha
            highlight.OutlineColor = oColor
            highlight.OutlineTransparency = 1 - oAlpha
            highlight.Enabled = true
        else
            if highlight then
                highlight.Enabled = false
            end
        end
    end
    local OriginalMaterials = {}
    local function UpdateMaterialOverride(instance, enabled, materialName, color, alpha, affectDescendants)
        if not instance then return end
        local parts = {}
        if affectDescendants == false then
            if instance:IsA("BasePart") then
                table.insert(parts, instance)
            end
        else
            parts = instance:GetDescendants()
            if instance:IsA("BasePart") then
                table.insert(parts, instance)
            end
            if instance:IsA("Model") then
                if not OriginalMaterials[instance] then
                    OriginalMaterials[instance] = {Clothing = {}}
                    for _, child in instance:GetChildren() do
                        if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") or child:IsA("CharacterMesh") then
                            OriginalMaterials[instance].Clothing[child] = child.Parent
                        end
                    end
                end
                if enabled then
                    for child, _ in OriginalMaterials[instance].Clothing do
                        child.Parent = nil
                    end
                else
                    for child, parent in OriginalMaterials[instance].Clothing do
                        child.Parent = parent
                    end
                end
            end
        end
        for _, part in parts do
            if part:IsA("BasePart") then
                if not OriginalMaterials[part] then
                    if part.Transparency < 1 then
                        local orig = {
                            Material = part.Material,
                            Color = part.Color,
                            Transparency = part.Transparency,
                            Children = {}
                        }
                        if part:IsA("MeshPart") then
                            orig.TextureID = part.TextureID
                        end
                        for _, child in part:GetChildren() do
                            if child:IsA("Decal") or child:IsA("Texture") then
                                orig.Children[child] = child.Transparency
                            elseif child:IsA("SpecialMesh") then
                                orig.Children[child] = child.TextureId
                            elseif child:IsA("SurfaceAppearance") then
                                orig.Children[child] = child.Parent
                            end
                        end
                        OriginalMaterials[part] = orig
                    end
                end
            end
        end
        if enabled then
            for _, part in parts do
                if part:IsA("BasePart") then
                    local orig = OriginalMaterials[part]
                    if orig then
                        local newMat = Enum.Material.ForceField
                        if materialName == "Neon" then newMat = Enum.Material.Neon
                        elseif materialName == "Plastic" then newMat = Enum.Material.SmoothPlastic
                        elseif materialName == "Glass" then newMat = Enum.Material.Glass
                        elseif materialName == "Ice" then newMat = Enum.Material.Ice
                        end
                        part.Material = newMat
                        part.Color = color
                        part.Transparency = 1 - alpha
                        if part:IsA("MeshPart") then
                            part.TextureID = ""
                        end
                        for child, _ in orig.Children do
                            if child:IsA("Decal") or child:IsA("Texture") then
                                child.Transparency = 1
                            elseif child:IsA("SpecialMesh") then
                                child.TextureId = ""
                            elseif child:IsA("SurfaceAppearance") then
                                child.Parent = nil
                            end
                        end
                    end
                end
            end
        else
            if affectDescendants ~= false and instance:IsA("Model") and OriginalMaterials[instance] then
                for child, parent in OriginalMaterials[instance].Clothing do
                    child.Parent = parent
                end
                OriginalMaterials[instance] = nil
            end
            for _, part in parts do
                if part:IsA("BasePart") and OriginalMaterials[part] then
                    local orig = OriginalMaterials[part]
                    local isVM = part:IsDescendantOf(workspace.CurrentCamera)
                    if isVM and WorldSettings.ThirdPersonEnabled then
                        part.Material = orig.Material
                        part.Color = orig.Color
                        part.Transparency = 1
                        if part:IsA("MeshPart") and orig.TextureID ~= nil then
                            part.TextureID = orig.TextureID
                        end
                        for child, val in orig.Children do
                            if child:IsA("Decal") or child:IsA("Texture") then
                                child.Transparency = 1
                            end
                        end
                    else
                        part.Material = orig.Material
                        part.Color = orig.Color
                        part.Transparency = orig.Transparency
                        if part:IsA("MeshPart") and orig.TextureID ~= nil then
                            part.TextureID = orig.TextureID
                        end
                        for child, val in orig.Children do
                            if child:IsA("Decal") or child:IsA("Texture") then
                                child.Transparency = val
                            elseif child:IsA("SpecialMesh") then
                                child.TextureId = val
                            elseif child:IsA("SurfaceAppearance") then
                                child.Parent = val
                            end
                        end
                        OriginalMaterials[part] = nil
                    end
                end
            end
        end
    end
    local function getTFolder() return CharactersFolder and CharactersFolder:FindFirstChild("Terrorists") end
    local function getCTFolder() return CharactersFolder and CharactersFolder:FindFirstChild("Counter-Terrorists") end
    local function isAlive()
        local lp = game:GetService("Players").LocalPlayer
        if not lp then return false end
        local t, ct = getTFolder(), getCTFolder()
        return (t and t:FindFirstChild(lp.Name)) or (ct and ct:FindFirstChild(lp.Name))
    end
    local function getEnemyFolder()
        if not isAlive() then return nil end
        local lp = game:GetService("Players").LocalPlayer
        if not lp then return nil end
        local t, ct = getTFolder(), getCTFolder()
        if t and t:FindFirstChild(lp.Name) then return ct end
        if ct and ct:FindFirstChild(lp.Name) then return t end
        return nil
    end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    local function CheckVisibility(char)
        if not char or not char.PrimaryPart then return false end
        local cam = workspace.CurrentCamera
        if not cam then return false end
        local origin = cam.CFrame.Position
        local target = char.PrimaryPart.Position
        local dir = target - origin
        local ignoreList = {cam, char}
        local lp = game:GetService("Players").LocalPlayer
        if lp and lp.Character then
            table.insert(ignoreList, lp.Character)
        end
        raycastParams.FilterDescendantsInstances = ignoreList
        local result = workspace:Raycast(origin, dir, raycastParams)
        return result == nil
    end
    local lastESPUpdate = 0
    game:GetService("RunService").RenderStepped:Connect(function()
        local now = os.clock()
        if now - lastESPUpdate < 1/60 then return end
        lastESPUpdate = now
        if ChamsCamera and workspace.CurrentCamera then
            ChamsCamera.CFrame = workspace.CurrentCamera.CFrame
            ChamsCamera.FieldOfView = workspace.CurrentCamera.FieldOfView
        end
        local lp = game:GetService("Players").LocalPlayer
        local t, ct = getTFolder(), getCTFolder()
        if t then
            for _, char in t:GetChildren() do
                if char:IsA("Model") then
                    local isEnemy = (lp and getEnemyFolder() == t)
                    if isEnemy then
                        UpdateMaterialOverride(char, ESP_Settings.ChamsEnemyVisible, ESP_Settings.ChamsEnemyVisibleMaterial, ESP_Settings.ChamsEnemyVisibleColor, ESP_Settings.ChamsEnemyVisibleAlpha, true)
                        UpdateCham(char, ESP_Settings.ChamsEnemyInvisible, ESP_Settings.ChamsEnemyInvisibleColor, nil, ESP_Settings.ChamsEnemyInvisibleAlpha, nil, nil, ESP_Settings.ChamsEnemyInvisibleMaterial)
                        UpdateHighlight(char, ESP_Settings.Highlight, ESP_Settings.HighlightFill, ESP_Settings.HighlightFillAlpha, ESP_Settings.HighlightOutline, ESP_Settings.HighlightOutlineAlpha)
                    else
                        UpdateMaterialOverride(char, ESP_Settings.ChamsTeamVisible, ESP_Settings.ChamsTeamVisibleMaterial, ESP_Settings.ChamsTeamVisibleColor, ESP_Settings.ChamsTeamVisibleAlpha, true)
                        UpdateCham(char, ESP_Settings.ChamsTeamInvisible, ESP_Settings.ChamsTeamInvisibleColor, nil, ESP_Settings.ChamsTeamInvisibleAlpha, nil, nil, ESP_Settings.ChamsTeamInvisibleMaterial)
                        UpdateHighlight(char, false, ESP_Settings.HighlightFill, ESP_Settings.HighlightFillAlpha, ESP_Settings.HighlightOutline, ESP_Settings.HighlightOutlineAlpha)
                    end
                end
            end
        end
        if ct then
            for _, char in ct:GetChildren() do
                if char:IsA("Model") then
                    local isEnemy = (lp and getEnemyFolder() == ct)
                    if isEnemy then
                        UpdateMaterialOverride(char, ESP_Settings.ChamsEnemyVisible, ESP_Settings.ChamsEnemyVisibleMaterial, ESP_Settings.ChamsEnemyVisibleColor, ESP_Settings.ChamsEnemyVisibleAlpha, true)
                        UpdateCham(char, ESP_Settings.ChamsEnemyInvisible, ESP_Settings.ChamsEnemyInvisibleColor, nil, ESP_Settings.ChamsEnemyInvisibleAlpha, nil, nil, ESP_Settings.ChamsEnemyInvisibleMaterial)
                        UpdateHighlight(char, ESP_Settings.Highlight, ESP_Settings.HighlightFill, ESP_Settings.HighlightFillAlpha, ESP_Settings.HighlightOutline, ESP_Settings.HighlightOutlineAlpha)
                    else
                        UpdateMaterialOverride(char, ESP_Settings.ChamsTeamVisible, ESP_Settings.ChamsTeamVisibleMaterial, ESP_Settings.ChamsTeamVisibleColor, ESP_Settings.ChamsTeamVisibleAlpha, true)
                        UpdateCham(char, ESP_Settings.ChamsTeamInvisible, ESP_Settings.ChamsTeamInvisibleColor, nil, ESP_Settings.ChamsTeamInvisibleAlpha, nil, nil, ESP_Settings.ChamsTeamInvisibleMaterial)
                        UpdateHighlight(char, false, ESP_Settings.HighlightFill, ESP_Settings.HighlightFillAlpha, ESP_Settings.HighlightOutline, ESP_Settings.HighlightOutlineAlpha)
                    end
                end
            end
        end
        local cam = workspace.CurrentCamera
        for _, child in cam:GetChildren() do
            if child:IsA("Model") then
                local weapon = child:FindFirstChild("Weapon")
                local leftArm = child:FindFirstChild("Left Arm")
                local rightArm = child:FindFirstChild("Right Arm")
                if weapon then
                    UpdateMaterialOverride(weapon, ESP_Settings.ChamsWeapon, ESP_Settings.ChamsWeaponMaterial, ESP_Settings.ChamsWeaponFill, ESP_Settings.ChamsWeaponFillAlpha)
                end
                for _, arm in {leftArm, rightArm} do
                    if arm then
                        local sleeve = arm:FindFirstChild("Sleeve")
                        local glove = arm:FindFirstChild("Glove")
                        UpdateMaterialOverride(arm, ESP_Settings.ChamsArms, ESP_Settings.ChamsArmsMaterial, ESP_Settings.ChamsArmsFill, ESP_Settings.ChamsArmsFillAlpha, false)
                        if sleeve then
                            UpdateMaterialOverride(sleeve, ESP_Settings.ChamsSleeves, ESP_Settings.ChamsSleevesMaterial, ESP_Settings.ChamsSleevesFill, ESP_Settings.ChamsSleevesFillAlpha)
                        end
                        if glove then
                            UpdateMaterialOverride(glove, ESP_Settings.ChamsGloves, ESP_Settings.ChamsGlovesMaterial, ESP_Settings.ChamsGlovesFill, ESP_Settings.ChamsGlovesFillAlpha)
                        end
                    end
                end
            end
        end
            for inst, hl in ActiveChams do
            if not inst or not inst.Parent then
                hl.Model:Destroy()
                ActiveChams[inst] = nil
            end
        end
    end)
    local function getBoundingBox(rootCf, headCf, rootSize, headSize)
        local th = headCf * Vector3.new(0, headSize.y * 0.5 + 0.5, 0)
        local bf = rootCf * Vector3.new(0, -(rootSize.y * 0.5 + 2.5 + 0.5), 0)
        local td = (th - rootCf.p).Magnitude
        local bd = (rootCf.p - bf).Magnitude
        local up = rootCf.UpVector
        local tp = rootCf.p + up * td
        local bp = rootCf.p - up * bd
        local top, topVisible = workspace.CurrentCamera:WorldToViewportPoint(tp)
        local bottom, bottomVisible = workspace.CurrentCamera:WorldToViewportPoint(bp)
        local width = math.abs(top.x - bottom.x)
        local height = math.max(math.abs(top.y - bottom.y), width / 1.75)
        local size = Vector2.new(math.floor(math.max(height / 1.7, width * 2.5)), math.floor(height))
        local pos = Vector2.new(math.floor((bottom.x - size.x + top.x) / 2), math.floor(math.min(top.y, bottom.y)))
        return {Min = pos, Max = pos + size, Height = height, Width = size.x, OnScreen = (topVisible or bottomVisible), Depth = bottom.Z}
    end
    local R15Joints = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
    }
    local R6Joints = {
        {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
        {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
    }
    game:GetService("RunService").RenderStepped:Connect(function()
        if not ESP_Settings.Enabled or not isAlive() then
            for _, esp in ESP_Objects do
                esp.Box.Visible = false
                for j = 1, 40 do esp.BoxFills[j].Visible = false end
                for j = 1, 8 do esp.BoxGlows[j].Visible = false end
                esp.BoxOutline.Visible = false
                esp.Name.Visible = false
                esp.WeaponIcon.Visible = false
                esp.HealthBar.Visible = false
                for j = 1, 6 do esp.HealthBarGlows[j].Visible = false end
                esp.HealthBarOutline.Visible = false
                esp.HealthNumber.Visible = false
                for i = 1, 8 do esp.Corners[i].Main.Visible = false; esp.Corners[i].Shadow.Visible = false end
                for i = 1, 14 do esp.Skeletons[i].Main.Visible = false; esp.Skeletons[i].Shadow.Visible = false end
                for i = 1, 15 do esp.HealthBarSegments[i].Visible = false end
                esp.OffscreenArrow.Visible = false
                esp.OffscreenArrowOutline.Visible = false
            end
            return
        end
        local enemyFolder = getEnemyFolder()
        if not enemyFolder then return end
        local currentAlive = {}
        for _, enemy in enemyFolder:GetChildren() do
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart")
            local head = enemy:FindFirstChild("Head")
            if hum and hum.Health > 0 and root and head then
                currentAlive[enemy] = true
                if not ESP_Objects[enemy] then ESP_Objects[enemy] = Utility:CreateESP() end
                local esp = ESP_Objects[enemy]
                local boxData = getBoundingBox(root.CFrame, head.CFrame, root.Size, head.Size)
                if boxData.OnScreen and boxData.Depth > 0 then
                    esp.OffscreenArrow.Visible = false
                    esp.OffscreenArrowOutline.Visible = false
                    local isCorner = (ESP_Settings.BoxType == "Corner")
                    local boxVisible = ESP_Settings.Boxes
                    if boxVisible and not isCorner then
                        esp.Box.Visible = true
                        esp.BoxOutline.Visible = true
                        esp.Box.Position = boxData.Min
                        esp.Box.Size = boxData.Max - boxData.Min
                        esp.Box.Color = ESP_Settings.BoxColor
                        esp.Box.Transparency = 1 
                        esp.BoxOutline.Position = boxData.Min
                        esp.BoxOutline.Size = boxData.Max - boxData.Min
                        esp.BoxOutline.Color = ESP_Settings.BoxOutlineColor
                        esp.BoxOutline.Transparency = ESP_Settings.BoxOutlineAlpha
                    else
                        esp.Box.Visible = false
                        esp.BoxOutline.Visible = false
                    end
                    if boxVisible then
                        if ESP_Settings.BoxFill then
                            local segments = 40
                            for j = 1, segments do
                                local y1 = math.floor(boxData.Min.Y + (boxData.Height * ((j - 1) / segments)))
                                local y2 = math.floor(boxData.Min.Y + (boxData.Height * (j / segments)))
                                esp.BoxFills[j].Visible = true
                                esp.BoxFills[j].Position = Vector2.new(boxData.Min.X, y1)
                                esp.BoxFills[j].Size = Vector2.new(boxData.Width, y2 - y1)
                                esp.BoxFills[j].Color = ESP_Settings.BoxFillColor1:Lerp(ESP_Settings.BoxFillColor2, j / segments)
                                esp.BoxFills[j].Transparency = ESP_Settings.BoxFillAlpha1 + (ESP_Settings.BoxFillAlpha2 - ESP_Settings.BoxFillAlpha1) * (j / segments)
                            end
                        else
                            for j = 1, 40 do esp.BoxFills[j].Visible = false end
                        end
                        if ESP_Settings.BoxGlow then
                            for j = 1, 8 do
                                esp.BoxGlows[j].Visible = true
                                esp.BoxGlows[j].Position = boxData.Min - Vector2.new(j, j)
                                esp.BoxGlows[j].Size = (boxData.Max - boxData.Min) + Vector2.new(j * 2, j * 2)
                                esp.BoxGlows[j].Color = ESP_Settings.BoxGlowColor
                                local fade = 1 - (j / 8)
                                esp.BoxGlows[j].Transparency = ESP_Settings.BoxGlowAlpha * (fade * fade)
                            end
                        else
                            for j = 1, 8 do esp.BoxGlows[j].Visible = false end
                        end
                    else
                        for j = 1, 40 do esp.BoxFills[j].Visible = false end
                        for j = 1, 8 do esp.BoxGlows[j].Visible = false end
                    end
                    if boxVisible and isCorner then
                        local px, py = boxData.Min.X, boxData.Min.Y
                        local sx, sy = boxData.Width, boxData.Height
                        local lengthX = math.max(math.floor(sx / 4), 2)
                        local lengthY = math.max(math.floor(sy / 4), 2)
                        local function updateCorner(idx, x, y, sizeX, sizeY)
                            esp.Corners[idx].Main.From = Vector2.new(x, y)
                            esp.Corners[idx].Main.To = Vector2.new(x + sizeX, y + sizeY)
                            esp.Corners[idx].Main.Color = ESP_Settings.BoxColor
                            esp.Corners[idx].Main.Transparency = 1
                            esp.Corners[idx].Main.Visible = true
                            esp.Corners[idx].Shadow.From = Vector2.new(x, y)
                            esp.Corners[idx].Shadow.To = Vector2.new(x + sizeX, y + sizeY)
                            esp.Corners[idx].Shadow.Color = ESP_Settings.BoxOutlineColor
                            esp.Corners[idx].Shadow.Transparency = ESP_Settings.BoxOutlineAlpha
                            esp.Corners[idx].Shadow.Visible = true
                        end
                        updateCorner(1, px, py, lengthX, 0)
                        updateCorner(2, px, py, 0, lengthY)
                        updateCorner(3, px + sx - lengthX, py, lengthX, 0)
                        updateCorner(4, px + sx, py, 0, lengthY)
                        updateCorner(5, px, py + sy, lengthX, 0)
                        updateCorner(6, px, py + sy - lengthY, 0, lengthY)
                        updateCorner(7, px + sx - lengthX, py + sy, lengthX, 0)
                        updateCorner(8, px + sx, py + sy - lengthY, 0, lengthY)
                    else
                        for i = 1, 8 do
                            esp.Corners[i].Main.Visible = false
                            esp.Corners[i].Shadow.Visible = false
                        end
                    end
                    local healthPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local barHeight = boxData.Height * healthPct
                    local textSize = math.max(math.min(math.floor(boxData.Height / 14), 16), 10)
                    if ESP_Settings.HealthBar then
                        if ESP_Settings.HealthBarGlow then
                            for j = 1, 6 do
                                esp.HealthBarGlows[j].Visible = true
                                esp.HealthBarGlows[j].Position = boxData.Min + Vector2.new(-6 - j, -1 - j)
                                esp.HealthBarGlows[j].Size = Vector2.new(4 + (j * 2), boxData.Height + 2 + (j * 2))
                                esp.HealthBarGlows[j].Color = ESP_Settings.HealthBarGlowColor
                                local fade = 1 - (j / 6)
                                esp.HealthBarGlows[j].Transparency = ESP_Settings.HealthBarGlowAlpha * (fade * fade)
                            end
                        else
                            for j = 1, 6 do esp.HealthBarGlows[j].Visible = false end
                        end
                        esp.HealthBarOutline.Visible = true
                        esp.HealthBarOutline.Position = boxData.Min + Vector2.new(-6, -1)
                        esp.HealthBarOutline.Size = Vector2.new(4, boxData.Height + 2)
                        esp.HealthBarOutline.Color = ESP_Settings.HealthBarOutlineColor
                        esp.HealthBarOutline.Transparency = ESP_Settings.HealthBarOutlineAlpha
                        local isFade = (ESP_Settings.HealthBarType == "Fade")
                        esp.HealthBar.Visible = not isFade
                        if not isFade then
                            esp.HealthBar.Position = boxData.Min + Vector2.new(-5, boxData.Height - barHeight)
                            esp.HealthBar.Size = Vector2.new(2, barHeight)
                            if ESP_Settings.HealthBarType == "Default" then
                                esp.HealthBar.Color = ESP_Settings.HealthBarColor1
                            else
                                esp.HealthBar.Color = ESP_Settings.HealthBarColor2:Lerp(ESP_Settings.HealthBarColor1, healthPct)
                            end
                            esp.HealthBar.Transparency = ESP_Settings.HealthBarAlpha or 1
                            for i = 1, 15 do esp.HealthBarSegments[i].Visible = false end
                        else
                            local segments = 15
                            local sizePerSegment = boxData.Height / segments
                            local currentSegment = math.ceil(healthPct * segments)
                            local bottomY = boxData.Min.Y + boxData.Height
                            for i = 1, segments do
                                local seg = esp.HealthBarSegments[i]
                                if i <= currentSegment and healthPct > 0 then
                                    seg.Visible = true
                                    local segBottom = bottomY - ((i - 1) * sizePerSegment)
                                    local segTop
                                    if i == currentSegment then
                                        local remainder = (healthPct * segments) - (currentSegment - 1)
                                        segTop = segBottom - (sizePerSegment * remainder)
                                    else
                                        segTop = segBottom - sizePerSegment
                                    end
                                    seg.Position = Vector2.new(boxData.Min.X - 5, math.floor(segTop))
                                    seg.Size = Vector2.new(2, math.max(1, math.ceil(segBottom - segTop)))
                                    seg.Color = ESP_Settings.HealthBarColor2:Lerp(ESP_Settings.HealthBarColor1, i / segments)
                                    seg.Transparency = ESP_Settings.HealthBarAlpha or 1
                                else
                                    seg.Visible = false
                                end
                            end
                        end
                    else
                        esp.HealthBar.Visible = false
                        for j = 1, 6 do esp.HealthBarGlows[j].Visible = false end
                        esp.HealthBarOutline.Visible = false
                        for i = 1, 15 do esp.HealthBarSegments[i].Visible = false end
                    end
                    if ESP_Settings.ShowHealthNumber then
                        esp.HealthNumber.Visible = true
                        esp.HealthNumber.Text = tostring(math.floor(hum.Health))
                        esp.HealthNumber.Position = Vector2.new(boxData.Min.X - 5 - esp.HealthNumber.TextBounds.X / 2 - 4, boxData.Min.Y + boxData.Height - barHeight - textSize / 2)
                        esp.HealthNumber.Color = ESP_Settings.HealthNumberColor or Color3.new(1, 1, 1)
                        esp.HealthNumber.Transparency = ESP_Settings.HealthNumberAlpha or 1
                        esp.HealthNumber.Size = textSize
                        esp.HealthNumber.Font = 2
                    else
                        esp.HealthNumber.Visible = false
                    end
                    local textSize = math.max(math.min(math.floor(boxData.Height / 14), 16), 10)
                    if ESP_Settings.Names then
                        esp.Name.Visible = true
                        esp.Name.Text = enemy.Name
                        esp.Name.Position = Vector2.new(boxData.Min.X + (boxData.Width / 2), boxData.Min.Y - textSize - 2)
                        esp.Name.Size = textSize
                        esp.Name.Font = 2
                        esp.Name.Color = ESP_Settings.NameColor
                        esp.Name.Transparency = ESP_Settings.NameAlpha
                        esp.Name.OutlineColor = ESP_Settings.NameOutlineColor
                    else
                        esp.Name.Visible = false
                    end
                    if ESP_Settings.ShowWeapon then
                        esp.WeaponIcon.Visible = true
                        local wName = ""
                        local tool = enemy:FindFirstChildOfClass("Tool")
                        if tool then wName = tool.Name else wName = "Pistol" end
                        esp.WeaponIcon.Image = Utility:GetWeaponIcon(wName)
                        esp.WeaponIcon.ImageColor3 = ESP_Settings.WeaponIconColor
                        esp.WeaponIcon.ImageTransparency = 1 - ESP_Settings.WeaponIconAlpha
                        local wWidth = textSize * 5
                        local wHeight = textSize * 3
                        esp.WeaponIcon.Size = UDim2.new(0, wWidth, 0, wHeight)
                        esp.WeaponIcon.Position = UDim2.new(0, boxData.Min.X + (boxData.Width / 2) - (wWidth / 2), 0, boxData.Max.Y + 2)
                    else
                        esp.WeaponIcon.Visible = false
                    end
                    if ESP_Settings.Skeleton then
                        local isR15 = enemy:FindFirstChild("UpperTorso") ~= nil
                        local joints = isR15 and R15Joints or R6Joints
                        for i = 1, 14 do
                            local jointPair = joints[i]
                            if jointPair then
                                local p0 = enemy:FindFirstChild(jointPair[1])
                                local p1 = enemy:FindFirstChild(jointPair[2])
                                if p0 and p1 then
                                    local pos0, vis0 = workspace.CurrentCamera:WorldToViewportPoint(p0.Position)
                                    local pos1, vis1 = workspace.CurrentCamera:WorldToViewportPoint(p1.Position)
                                    if vis0 or vis1 then
                                        esp.Skeletons[i].Main.Visible = true
                                        esp.Skeletons[i].Main.From = Vector2.new(pos0.X, pos0.Y)
                                        esp.Skeletons[i].Main.To = Vector2.new(pos1.X, pos1.Y)
                                        esp.Skeletons[i].Main.Color = ESP_Settings.SkeletonColor
                                        esp.Skeletons[i].Main.Transparency = ESP_Settings.SkeletonAlpha
                                        esp.Skeletons[i].Shadow.Visible = true
                                        esp.Skeletons[i].Shadow.From = esp.Skeletons[i].Main.From
                                        esp.Skeletons[i].Shadow.To = esp.Skeletons[i].Main.To
                                        esp.Skeletons[i].Shadow.Color = ESP_Settings.SkeletonOutlineColor
                                        esp.Skeletons[i].Shadow.Transparency = ESP_Settings.SkeletonOutlineAlpha
                                    else
                                        esp.Skeletons[i].Main.Visible = false
                                        esp.Skeletons[i].Shadow.Visible = false
                                    end
                                else
                                    esp.Skeletons[i].Main.Visible = false
                                    esp.Skeletons[i].Shadow.Visible = false
                                end
                            else
                                esp.Skeletons[i].Main.Visible = false
                                esp.Skeletons[i].Shadow.Visible = false
                            end
                        end
                    else
                        for i = 1, 14 do
                            esp.Skeletons[i].Main.Visible = false
                            esp.Skeletons[i].Shadow.Visible = false
                        end
                    end
                    local currentFlagY = boxData.Min.Y
                    local function drawFlag(drawObj, text, color, alpha)
                        drawObj.Visible = true
                        drawObj.Text = text
                        drawObj.Color = color
                        drawObj.Transparency = alpha
                        drawObj.Size = textSize
                        drawObj.Font = 2
                        drawObj.OutlineColor = Color3.new(0, 0, 0)
                        drawObj.Position = Vector2.new(boxData.Min.X + boxData.Width + 4, currentFlagY)
                        currentFlagY = currentFlagY + textSize
                    end
                    if ESP_Settings.Flags then
                        local isLagging = false
                        if enemy:IsA("Model") and enemy.PrimaryPart then
                            local dPos = (enemy.PrimaryPart.Position - esp.LastPos).Magnitude
                            if dPos > 15 then
                                isLagging = true
                            end
                            esp.LastPos = enemy.PrimaryPart.Position
                            if dPos > 0.5 then
                                esp.LastMoveTime = os.clock()
                            end
                        end
                        local isAFK = (os.clock() - esp.LastMoveTime > 3)
                        local isLethal = false
                        if CheckVisibility and CheckVisibility(enemy) then
                            isLethal = true
                        end
                        if ESP_Settings.FlagPing and isLagging then drawFlag(esp.Flags.Ping, "PING", ESP_Settings.FlagPingColor, ESP_Settings.FlagPingAlpha) else esp.Flags.Ping.Visible = false end
                        if ESP_Settings.FlagAFK and isAFK then drawFlag(esp.Flags.AFK, "AFK", ESP_Settings.FlagAFKColor, ESP_Settings.FlagAFKAlpha) else esp.Flags.AFK.Visible = false end
                        if ESP_Settings.FlagLethal and isLethal then drawFlag(esp.Flags.Lethal, "LETHAL", ESP_Settings.FlagLethalColor, ESP_Settings.FlagLethalAlpha) else esp.Flags.Lethal.Visible = false end
                    else
                        esp.Flags.Ping.Visible = false
                        esp.Flags.AFK.Visible = false
                        esp.Flags.Lethal.Visible = false
                    end
                else
                    if ESP_Settings.OffscreenArrows then
                        local cam = workspace.CurrentCamera
                        local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
                        local objPos = cam:WorldToViewportPoint(root.Position)
                        local objDir = (Vector2.new(objPos.X, objPos.Y) - screenCenter).Unit
                        if objPos.Z < 0 then
                            objDir = -objDir
                        end
                        local radius = ESP_Settings.OffscreenArrowRadius
                        local size = ESP_Settings.OffscreenArrowSize
                        local pA = screenCenter + objDir * radius
                        local back = screenCenter + objDir * (radius - size)
                        local right = Vector2.new(-objDir.Y, objDir.X)
                        local width = size / 1.5
                        local pB = back + right * width
                        local pC = back - right * width
                        esp.OffscreenArrow.Visible = true
                        esp.OffscreenArrow.PointA = pA
                        esp.OffscreenArrow.PointB = pB
                        esp.OffscreenArrow.PointC = pC
                        esp.OffscreenArrow.Color = ESP_Settings.OffscreenArrowColor
                        esp.OffscreenArrow.Transparency = ESP_Settings.OffscreenArrowAlpha
                        esp.OffscreenArrowOutline.Visible = true
                        esp.OffscreenArrowOutline.PointA = pA
                        esp.OffscreenArrowOutline.PointB = pB
                        esp.OffscreenArrowOutline.PointC = pC
                        esp.OffscreenArrowOutline.Color = ESP_Settings.OffscreenArrowOutlineColor
                        esp.OffscreenArrowOutline.Transparency = ESP_Settings.OffscreenArrowOutlineAlpha
                    else
                        esp.OffscreenArrow.Visible = false
                        esp.OffscreenArrowOutline.Visible = false
                    end
                    esp.Box.Visible = false
                    for j = 1, 40 do esp.BoxFills[j].Visible = false end
                    for j = 1, 8 do esp.BoxGlows[j].Visible = false end
                    esp.BoxOutline.Visible = false
                    esp.Name.Visible = false
                    esp.WeaponIcon.Visible = false
                    esp.HealthBar.Visible = false
                    for j = 1, 6 do esp.HealthBarGlows[j].Visible = false end
                    esp.HealthBarOutline.Visible = false
                    esp.HealthNumber.Visible = false
                    for i = 1, 8 do esp.Corners[i].Main.Visible = false; esp.Corners[i].Shadow.Visible = false end
                    for i = 1, 14 do esp.Skeletons[i].Main.Visible = false; esp.Skeletons[i].Shadow.Visible = false end
                    for i = 1, 15 do esp.HealthBarSegments[i].Visible = false end
                    esp.Flags.Ping.Visible = false
                    esp.Flags.AFK.Visible = false
                    esp.Flags.Lethal.Visible = false
                end
            else
                if ESP_Objects[enemy] then
                    local esp = ESP_Objects[enemy]
                    esp.Box.Visible = false
                    for j = 1, 40 do esp.BoxFills[j].Visible = false end
                    for j = 1, 8 do esp.BoxGlows[j].Visible = false end
                    esp.BoxOutline.Visible = false
                    esp.Name.Visible = false
                    esp.WeaponIcon.Visible = false
                    esp.HealthBar.Visible = false
                    for j = 1, 6 do esp.HealthBarGlows[j].Visible = false end
                    esp.HealthBarOutline.Visible = false
                    esp.HealthNumber.Visible = false
                    for i = 1, 8 do esp.Corners[i].Main.Visible = false; esp.Corners[i].Shadow.Visible = false end
                    for i = 1, 14 do esp.Skeletons[i].Main.Visible = false; esp.Skeletons[i].Shadow.Visible = false end
                    for i = 1, 15 do esp.HealthBarSegments[i].Visible = false end
                    esp.Flags.Ping.Visible = false
                    esp.Flags.AFK.Visible = false
                    esp.Flags.Lethal.Visible = false
                    esp.OffscreenArrow.Visible = false
                    esp.OffscreenArrowOutline.Visible = false
                end
            end
        end
        for cEnemy, esp in ESP_Objects do
            if not currentAlive[cEnemy] then
                esp.Box:Remove()
                esp.BoxOutline:Remove()
                esp.Name:Remove()
                esp.WeaponIcon:Destroy()
                esp.HealthBar:Remove()
                esp.HealthBarOutline:Remove()
                esp.HealthNumber:Remove()
                for i = 1, 8 do esp.Corners[i].Main:Remove(); esp.Corners[i].Shadow:Remove() end
                for i = 1, 14 do esp.Skeletons[i].Main:Remove(); esp.Skeletons[i].Shadow:Remove() end
                for i = 1, 15 do esp.HealthBarSegments[i]:Remove() end
                esp.Flags.Ping:Remove()
                esp.Flags.AFK:Remove()
                esp.Flags.Lethal:Remove()
                for j = 1, 40 do esp.BoxFills[j]:Remove() end
                for j = 1, 8 do esp.BoxGlows[j]:Remove() end
                for j = 1, 6 do esp.HealthBarGlows[j]:Remove() end
                esp.OffscreenArrow:Remove()
                esp.OffscreenArrowOutline:Remove()
                ESP_Objects[cEnemy] = nil
            end
        end
    end)
    LeftSection:CreateMultiDropdown({
        Name = "Hitboxes",
        Options = {"Head", "Body", "Hands", "Legs"},
        Default = {"Head"},
        Callback = function(sel) AimbotSettings.TargetPart = sel end
    })
    local FOVCircle = Drawing.new("Circle")
    FOVCircle.Filled = false
    FOVCircle.Thickness = 1
    FOVCircle.NumSides = 60
    local SilentAimFOVCircle = Drawing.new("Circle")
    SilentAimFOVCircle.Filled = false
    SilentAimFOVCircle.Thickness = 1
    SilentAimFOVCircle.NumSides = 60
    local function getValidHitboxes(settingVal)
        local rawHitboxes = {}
        if type(settingVal) == "string" then
            table.insert(rawHitboxes, settingVal)
        elseif type(settingVal) == "table" then
            for k, v in settingVal do
                if type(k) == "number" and type(v) == "string" then
                    table.insert(rawHitboxes, v)
                elseif type(k) == "string" and v == true then
                    table.insert(rawHitboxes, k)
                end
            end
        end
        if #rawHitboxes == 0 then table.insert(rawHitboxes, "Head") end
        local mappedHitboxes = {}
        for _, hb in rawHitboxes do
            if hb == "Head" then
                table.insert(mappedHitboxes, "Head")
            elseif hb == "Body" then
                table.insert(mappedHitboxes, "Torso")
                table.insert(mappedHitboxes, "HumanoidRootPart")
                table.insert(mappedHitboxes, "UpperTorso")
                table.insert(mappedHitboxes, "LowerTorso")
            elseif hb == "Hands" then
                table.insert(mappedHitboxes, "Right Arm")
                table.insert(mappedHitboxes, "Left Arm")
                table.insert(mappedHitboxes, "RightUpperArm")
                table.insert(mappedHitboxes, "LeftUpperArm")
                table.insert(mappedHitboxes, "RightLowerArm")
                table.insert(mappedHitboxes, "LeftLowerArm")
                table.insert(mappedHitboxes, "RightHand")
                table.insert(mappedHitboxes, "LeftHand")
            elseif hb == "Legs" then
                table.insert(mappedHitboxes, "Right Leg")
                table.insert(mappedHitboxes, "Left Leg")
                table.insert(mappedHitboxes, "RightUpperLeg")
                table.insert(mappedHitboxes, "LeftUpperLeg")
                table.insert(mappedHitboxes, "RightLowerLeg")
                table.insert(mappedHitboxes, "LeftLowerLeg")
                table.insert(mappedHitboxes, "RightFoot")
                table.insert(mappedHitboxes, "LeftFoot")
            else
                table.insert(mappedHitboxes, hb)
            end
        end
        return mappedHitboxes
    end
    local function getClosestEnemyToMouse()
        local closestEnemy = nil
        local shortestDistance = AimbotSettings.FOV_Radius == 360 and math.huge or AimbotSettings.FOV_Radius
        local enemyFolder = getEnemyFolder()
        if not enemyFolder or not AimbotSettings.Enabled then return nil end
        local mousePos = UserInputService:GetMouseLocation()
        local hitboxesToCheck = getValidHitboxes(AimbotSettings.TargetPart)
        for _, enemy in enemyFolder:GetChildren() do
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                for _, hbName in hitboxesToCheck do
                    local targetPart = enemy:FindFirstChild(hbName)
                    if targetPart then
                        local partPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(targetPart.Position)
                        if onScreen or AimbotSettings.FOV_Radius == 360 then
                            local fovScale = (70 / GetCurrentFOV())
                            local distance = 0
                            if AimbotSettings.FOV_Radius == 360 then
                                local lpChar = Players.LocalPlayer.Character
                                if lpChar and lpChar:FindFirstChild("HumanoidRootPart") then
                                    distance = (targetPart.Position - lpChar.HumanoidRootPart.Position).Magnitude
                                end
                            else
                                distance = (Vector2.new(partPos.X, partPos.Y) - mousePos).Magnitude
                            end
                            if distance < shortestDistance * fovScale then
                                shortestDistance = AimbotSettings.FOV_Radius == 360 and distance or (distance / fovScale)
                                closestEnemy = targetPart
                            end
                        end
                    end
                end
            end
        end
        return closestEnemy
    end
    local function isVisible(targetPart)
        local origin = workspace.CurrentCamera.CFrame.Position
        local direction = (targetPart.Position - origin).Unit * 1000
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {Players.LocalPlayer.Character, workspace.CurrentCamera}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.IgnoreWater = true
        local result = workspace:Raycast(origin, direction, raycastParams)
        if result then
            if result.Instance:IsDescendantOf(targetPart.Parent) then
                return true
            end
            return false
        end
        return true
    end
    local BacktrackRecords = {}
    local function isVisiblePosition(targetPos, targetInstance)
        local origin = workspace.CurrentCamera.CFrame.Position
        local direction = (targetPos - origin).Unit * 1000
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {Players.LocalPlayer.Character, workspace.CurrentCamera}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.IgnoreWater = true
        local result = workspace:Raycast(origin, direction, raycastParams)
        if result then
            if targetInstance and result.Instance:IsDescendantOf(targetInstance.Parent) then
                return true
            end
            local distToTarget = (targetPos - origin).Magnitude
            if result.Distance >= distToTarget - 0.5 then
                return true
            end
            return false
        end
        return true
    end
    local function getClosestEnemyToMouseSilentAim()
        local closestPosition = nil
        local closestInstance = nil
        local shortestDistance = AimbotSettings.SilentAimFOV_Radius == 360 and math.huge or AimbotSettings.SilentAimFOV_Radius
        local enemyFolder = getEnemyFolder()
        if not enemyFolder or not AimbotSettings.SilentAim then return nil, nil end
        local mousePos = UserInputService:GetMouseLocation()
        local hitboxesToCheck = getValidHitboxes(AimbotSettings.SilentAimTargetPart)
        local function processHitboxPosition(worldPos, instance)
            local partPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(worldPos)
            if onScreen or AimbotSettings.SilentAimFOV_Radius == 360 then
                local fovScale = (70 / GetCurrentFOV())
                local distance = 0
                if AimbotSettings.SilentAimFOV_Radius == 360 then
                    local lpChar = Players.LocalPlayer.Character
                    if lpChar and lpChar:FindFirstChild("HumanoidRootPart") then
                        distance = (worldPos - lpChar.HumanoidRootPart.Position).Magnitude
                    end
                else
                    distance = (Vector2.new(partPos.X, partPos.Y) - mousePos).Magnitude
                end
                if distance < shortestDistance * fovScale then
                    local canShoot = true
                    local isWallbangEnabled = AimbotSettings.SilentAimWallbang
                    if AimbotSettings.AutoShoot then
                        isWallbangEnabled = true 
                    end
                    if not isWallbangEnabled then
                        canShoot = isVisiblePosition(worldPos, instance)
                    end
                    if canShoot then
                        shortestDistance = AimbotSettings.SilentAimFOV_Radius == 360 and distance or (distance / fovScale)
                        closestPosition = worldPos
                        closestInstance = instance
                    end
                end
            end
        end
        for _, enemy in enemyFolder:GetChildren() do
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                for _, hbName in hitboxesToCheck do
                    local targetPart = enemy:FindFirstChild(hbName)
                    if targetPart then
                        processHitboxPosition(targetPart.Position, targetPart)
                    end
                end
                if AimbotSettings.Backtrack and BacktrackRecords[enemy] then
                    for _, record in BacktrackRecords[enemy] do
                        for _, hbName in hitboxesToCheck do
                            local historicalCFrame = record.Hitboxes[hbName]
                            if historicalCFrame then
                                local targetPart = enemy:FindFirstChild(hbName)
                                processHitboxPosition(historicalCFrame.Position, targetPart)
                            end
                        end
                    end
                end
            end
        end
        return closestPosition, closestInstance
    end
    task.spawn(function()
        while task.wait(0.03) do
            if AimbotSettings.AutoShoot and AimbotSettings.SilentAim and isAlive() then
                if not (Library.IsGuiOpen and Library:IsGuiOpen()) then
                    local targetPos, targetInstance = getClosestEnemyToMouseSilentAim()
                    if targetPos and targetInstance then
                        if isVisiblePosition(targetPos, targetInstance) then
                            if mouse1click then
                                mouse1click()
                            elseif mouse1press and mouse1release then
                                mouse1press()
                                task.wait(0.01)
                                mouse1release()
                            end
                        end
                    end
                end
            end
        end
    end)
    local CharacterKinematics
    pcall(function()
        local getloadedmodules = getloadedmodules or get_loaded_modules
        for _, v in (getloadedmodules and getloadedmodules() or {}) do
            if v.Name == "CharacterKinematics" then
                CharacterKinematics = require(v)
                break
            end
        end
    end)
    if not CharacterKinematics then
        pcall(function()
            for _, v in (game:GetService("ReplicatedStorage"):GetDescendants()) do
                if v:IsA("ModuleScript") and v.Name == "CharacterKinematics" then
                    CharacterKinematics = require(v)
                    break
                end
            end
        end)
    end
        local lastBTUpdate = 0
    game:GetService("RunService").RenderStepped:Connect(function()
        local now = os.clock()
        if now - lastBTUpdate < 1/60 then return end
        lastBTUpdate = now
        local enemyFolder = getEnemyFolder()
        local currentTime = os.clock()
        local maxAge = AimbotSettings.BacktrackTime / 1000
        if enemyFolder then
            for char, _ in BacktrackRecords do
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not char:IsDescendantOf(enemyFolder) or not hum or hum.Health <= 0 then
                    BacktrackRecords[char] = nil
                end
            end
            for _, enemy in enemyFolder:GetChildren() do
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    if not BacktrackRecords[enemy] then BacktrackRecords[enemy] = {} end
                    local hitboxes = {}
                    for _, partName in {
                        "Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso",
                        "Right Arm", "Left Arm", "RightHand", "LeftHand", "RightLowerArm", "LeftLowerArm", "RightUpperArm", "LeftUpperArm",
                        "Right Leg", "Left Leg", "RightFoot", "LeftFoot", "RightLowerLeg", "LeftLowerLeg", "RightUpperLeg", "LeftUpperLeg"
                    } do
                        local part = enemy:FindFirstChild(partName)
                        if part then
                            hitboxes[partName] = part.CFrame
                        end
                    end
                    table.insert(BacktrackRecords[enemy], {Time = currentTime, Hitboxes = hitboxes})
                    for i = #BacktrackRecords[enemy], 1, -1 do
                        if currentTime - BacktrackRecords[enemy][i].Time > maxAge then
                            table.remove(BacktrackRecords[enemy], i)
                        end
                    end
                end
            end
            if not env.BacktrackChamsParts then env.BacktrackChamsParts = {} end
            local btParts = env.BacktrackChamsParts
            if ESP_Settings.BacktrackChams then
                local pIndex = 1
                local lp = game:GetService("Players").LocalPlayer
                local ignoreList = {workspace.CurrentCamera}
                if lp and lp.Character then table.insert(ignoreList, lp.Character) end
                if enemyFolder then table.insert(ignoreList, enemyFolder) end
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = ignoreList
                for _, enemy in enemyFolder:GetChildren() do
                    if BacktrackRecords[enemy] then
                        local isVisible = false
                        local totalRecs = #BacktrackRecords[enemy]
                        for recIdx, record in BacktrackRecords[enemy] do
                            if recIdx == 1 or recIdx == totalRecs or (recIdx % 3 ~= 0) then
                                local targetPart = record.Hitboxes["Torso"] or record.Hitboxes["HumanoidRootPart"] or record.Hitboxes["Head"]
                                if targetPart then
                                    local origin = workspace.CurrentCamera.CFrame.Position
                                    local dir = targetPart.Position - origin
                                    local result = workspace:Raycast(origin, dir, rayParams)
                                    if not result then
                                        isVisible = true
                                        break
                                    end
                                end
                            end
                        end
                        if isVisible then
                            for recIdx, record in BacktrackRecords[enemy] do
                                if recIdx == 1 or recIdx == totalRecs or (recIdx % 3 ~= 0) then
                                local lerpAlpha = 1
                                if totalRecs > 1 then
                                    lerpAlpha = (recIdx - 1) / (totalRecs - 1)
                                end
                                local c1 = ESP_Settings.BacktrackChamsColor or Color3.new(1,1,1)
                                local c2 = ESP_Settings.BacktrackChamsColor2 or Color3.new(1,1,1)
                                local col = c1:Lerp(c2, lerpAlpha)
                                local a1 = ESP_Settings.BacktrackChamsAlpha or 0.5
                                local a2 = ESP_Settings.BacktrackChamsAlpha2 or 0.5
                                local trans = 1 - (a1 + (a2 - a1) * lerpAlpha)
                                for partName, cframe in record.Hitboxes do
                                    local part = btParts[pIndex]
                                    if not part then
                                        part = Instance.new("Part")
                                        part.Anchored = true
                                        part.CanCollide = false
                                        part.CanQuery = false
                                        part.CanTouch = false
                                        part.CastShadow = false
                                        part.Parent = workspace.Terrain
                                        btParts[pIndex] = part
                                    end
                                    local realPart = enemy:FindFirstChild(partName)
                                    part.Size = realPart and realPart.Size or Vector3.new(1,1,1)
                                    part.CFrame = cframe
                                    part.Color = col
                                    part.Transparency = trans
                                    local mat = Enum.Material.ForceField
                                    local mName = ESP_Settings.BacktrackChamsMaterial
                                    if mName == "Neon" then mat = Enum.Material.Neon
                                    elseif mName == "Plastic" then mat = Enum.Material.SmoothPlastic
                                    elseif mName == "Glass" then mat = Enum.Material.Glass
                                    elseif mName == "Ice" then mat = Enum.Material.Ice end
                                    part.Material = mat
                                    part.Position = cframe.Position 
                                    pIndex = pIndex + 1
                                end
                                end 
                            end
                        end
                    end
                end
                for i = pIndex, #btParts do
                    btParts[i].CFrame = CFrame.new(0, 99999, 0)
                end
            else
                for i = 1, #btParts do
                    btParts[i].CFrame = CFrame.new(0, 99999, 0)
                end
            end
        end
        local fovScale = (70 / GetCurrentFOV())
        if AimbotSettings.FOV_Visible then
            FOVCircle.Position = UserInputService:GetMouseLocation()
            local displayRadius = AimbotSettings.FOV_Radius == 360 and 2000 or AimbotSettings.FOV_Radius * 3
            FOVCircle.Radius = displayRadius * fovScale
            FOVCircle.Color = AimbotSettings.FOV_Color
            FOVCircle.Transparency = AimbotSettings.FOV_Alpha
            FOVCircle.Visible = AimbotSettings.FOV_Alpha > 0
        else
            FOVCircle.Visible = false
        end
        if AimbotSettings.SilentAimFOV_Visible then
            SilentAimFOVCircle.Position = UserInputService:GetMouseLocation()
            local displayRadiusSilent = AimbotSettings.SilentAimFOV_Radius == 360 and 2000 or AimbotSettings.SilentAimFOV_Radius * 3
            SilentAimFOVCircle.Radius = displayRadiusSilent * fovScale
            SilentAimFOVCircle.Color = AimbotSettings.SilentAimFOV_Color
            SilentAimFOVCircle.Transparency = AimbotSettings.SilentAimFOV_Alpha
            SilentAimFOVCircle.Visible = AimbotSettings.SilentAimFOV_Alpha > 0
        else
            SilentAimFOVCircle.Visible = false
        end
        if not isAlive() or not AimbotSettings.Enabled then return end
        if Library.IsGuiOpen and Library:IsGuiOpen() then return end
        local target = getClosestEnemyToMouse()
        if target then
            local headPos = workspace.CurrentCamera:WorldToViewportPoint(target.Position)
            local mousePos = UserInputService:GetMouseLocation()
            local distanceToMouse = (Vector2.new(headPos.X, headPos.Y) - mousePos).Magnitude
            if distanceToMouse <= (AimbotSettings.FOV_Radius * fovScale) then
                local moveX = (headPos.X - mousePos.X) / AimbotSettings.Smoothing
                local moveY = (headPos.Y - mousePos.Y) / AimbotSettings.Smoothing
                if mousemoverel then 
                    mousemoverel(moveX, moveY) 
                end
            end
        end
    end)
    local MovementSection = MovementTab:CreateSection({
        Name = "Movement",
        Side = "Left"
    })
    local AutoBhop = false
    local AntiTrimp = true
    local AutoStrafe = false
    MovementSection:CreateToggle({
        Name = "Auto Bhop",
        Default = false,
        Callback = function(state) AutoBhop = state end
    })
    local AutoStrafeSpeed = 5
    MovementSection:CreateToggle({
        Name = "Auto Strafe",
        Default = false,
        Callback = function(state) AutoStrafe = state end
    })
    MovementSection:CreateSlider({
        Name = "Strafe Speed",
        Min = 0,
        Max = 50,
        Default = 21,
        Callback = function(val) AutoStrafeSpeed = val end
    })
    local AutoJumpbug = false
    MovementSection:CreateToggle({
        Name = "Auto Jumpbug",
        Default = false,
        Callback = function(state) AutoJumpbug = state end
    })
    local AutoLongjump = false
    MovementSection:CreateToggle({
        Name = "Auto Longjump",
        Default = false,
        Callback = function(state) AutoLongjump = state end
    })
    local AutoMinijump = false
    MovementSection:CreateToggle({
        Name = "Auto Minijump",
        Default = false,
        Callback = function(state) AutoMinijump = state end
    })
    local AutoFastladder = false
    MovementSection:CreateToggle({
        Name = "Auto Fastladder",
        Default = false,
        Callback = function(state) AutoFastladder = state end
    })
    local AutoFireman = false
    MovementSection:CreateToggle({
        Name = "Auto Fireman",
        Default = false,
        Callback = function(state) AutoFireman = state end
    })
    local AutoEdgebug = false
    MovementSection:CreateToggle({
        Name = "Auto Edgebug",
        Default = false,
        Callback = function(state) AutoEdgebug = state end
    })
    local AutoEdgebugHitsound = "Off"
    MovementSection:CreateDropdown({
        Name = "Edgebug Hitsound",
        Options = HitSoundDropdownList,
        Default = "Off",
        Callback = function(state) AutoEdgebugHitsound = state end
    })
    AutoEdgebugEffect = "Off"
    MovementSection:CreateDropdown({
        Name = "Edgebug Effect",
        Options = {"Off", "Circle", "Hit Skeleton"},
        Default = "Off",
        Callback = function(state) AutoEdgebugEffect = state end
    })
    CustomEffectColorToggle = false
    CustomEffectColor = Color3.fromRGB(255, 255, 255)
    MovementSection:CreateToggle({
        Name = "Custom Effect Color",
        Default = false,
        Colorpickers = {
            {Name = "Color", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 1, Callback = function(c, a) CustomEffectColor = c end}
        },
        Callback = function(state) CustomEffectColorToggle = state end
    })
    EdgebugNotify = false
    MovementSection:CreateToggle({
        Name = "Edgebug Notify",
        Default = false,
        Callback = function(state) EdgebugNotify = state end
    })
    AutoEdgebugForce = 10
    MovementSection:CreateSlider({
        Name = "Edgebug Pull Force",
        Min = 1,
        Max = 10,
        Default = 4,
        Callback = function(val) AutoEdgebugForce = val end
    })
    AutoPixelsurf = false
    MovementSection:CreateToggle({
        Name = "Auto Pixelsurf",
        Default = false,
        Callback = function(state) AutoPixelsurf = state end
    })
    AutoPixelsurfHitsound = "Off"
    MovementSection:CreateDropdown({
        Name = "Pixelsurf Hitsound",
        Options = HitSoundDropdownList,
        Default = "Off",
        Callback = function(state) AutoPixelsurfHitsound = state end
    })
    AutoPixelsurfEffect = "Off"
    MovementSection:CreateDropdown({
        Name = "Pixelsurf Effect",
        Options = {"Off", "Circle", "Hit Skeleton"},
        Default = "Off",
        Callback = function(state) AutoPixelsurfEffect = state end
    })
    CustomPixelsurfEffectColorToggle = false
    CustomPixelsurfEffectColor = Color3.fromRGB(255, 255, 255)
    MovementSection:CreateToggle({
        Name = "Custom Effect Color",
        Default = false,
        Colorpickers = {
            {Name = "Color", ColorDefault = Color3.fromRGB(255, 255, 255), AlphaDefault = 1, Callback = function(c, a) CustomPixelsurfEffectColor = c end}
        },
        Callback = function(state) CustomPixelsurfEffectColorToggle = state end
    })
    PixelsurfNotify = false
    MovementSection:CreateToggle({
        Name = "Pixelsurf Notify",
        Default = false,
        Callback = function(state) PixelsurfNotify = state end
    })
    AutoTexturebug = false
    MovementSection:CreateToggle({
        Name = "Auto Texturebug",
        Default = false,
        Callback = function(state) AutoTexturebug = state end
    })
    AutoWallstuck = false
    MovementSection:CreateToggle({
        Name = "Auto Wallstuck",
        Default = false,
        Callback = function(state) AutoWallstuck = state end
    })
    AutoWallclimb = false
    MovementSection:CreateToggle({
        Name = "WallClimb",
        Default = false,
        Callback = function(state) AutoWallclimb = state end
    })
    local AssistantsSection = MovementTab:CreateSection({
        Name = "Assistants",
        Side = "Right"
    })
    env.PSLineSettings = env.PSLineSettings or {
        Color = Color3.fromRGB(0, 255, 255),
        Transparency = 0,
        Lines = {}
    }
    env.PSLineParts = env.PSLineParts or {}
    env.RefreshPSLines = function()
        for _, part in env.PSLineParts do
            if part then part:Destroy() end
        end
        env.PSLineParts = {}
        if not env.PSLineSettings or type(env.PSLineSettings.Lines) ~= "table" then return end
        for _, data in env.PSLineSettings.Lines do
            if data.P1 and data.P2 and data.Normal then
                local p = Instance.new("Part", workspace)
                p.Anchored = true
                p.CanCollide = false
                p.CanTouch = false
                p.CanQuery = false
                p.CastShadow = false
                p.Massless = true
                local length = (data.P2 - data.P1).Magnitude
                if length < 0.01 then length = 0.01 end
                local center = data.P1:Lerp(data.P2, 0.5)
                p.Size = Vector3.new(length, 0.05, 0.001)
                p.Color = env.PSLineSettings.Color
                p.Transparency = env.PSLineSettings.Transparency
                p.Material = Enum.Material.Neon
                local right = (data.P2 - data.P1).Unit
                if right.Magnitude < 0.01 then right = data.Normal:Cross(Vector3.new(0,1,0)) end
                local up = data.Normal:Cross(right).Unit
                p.CFrame = CFrame.fromMatrix(center + data.Normal * 0.01, right, up, -data.Normal)
                table.insert(env.PSLineParts, p)
            end
        end
    end
    env.RemovePSLine = function()
        local lp = game:GetService("Players").LocalPlayer
        if not (lp and lp.Character and lp.Character:FindFirstChild("Humanoid") and lp.Character.Humanoid.Health > 0) then return end
        if env.PSLineSettings and env.PSLineSettings.Lines then
            local cam = workspace.CurrentCamera
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = {lp.Character}
            local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 1000, rayParams)
            if hit then
                local closestIdx = -1
                local minSqDist = 16 
                for i, data in env.PSLineSettings.Lines do
                    if data.P1 and data.P2 then
                        local p1 = data.P1
                        local p2 = data.P2
                        local v = p2 - p1
                        local w = hit.Position - p1
                        local c1 = w:Dot(v)
                        local c2 = v:Dot(v)
                        local distSq
                        if c1 <= 0 then
                            distSq = (hit.Position - p1).Magnitude ^ 2
                        elseif c2 <= c1 then
                            distSq = (hit.Position - p2).Magnitude ^ 2
                        else
                            local b = c1 / c2
                            local pb = p1 + v * b
                            distSq = (hit.Position - pb).Magnitude ^ 2
                        end
                        if distSq < minSqDist then
                            minSqDist = distSq
                            closestIdx = i
                        end
                    end
                end
                if closestIdx ~= -1 then
                    table.remove(env.PSLineSettings.Lines, closestIdx)
                end
            end
        end
        env.RefreshPSLines()
    end
    env.SetPSLine = (function()
        local isDrawingLine = false
        local drawStartHit = nil
        local currentDrawPart = nil
        local drawConnection = nil
        local function cleanupDraw()
            isDrawingLine = false
            if drawConnection then drawConnection:Disconnect(); drawConnection = nil end
            if currentDrawPart then currentDrawPart:Destroy(); currentDrawPart = nil end
            drawStartHit = nil
        end
        return function(state)
            local lp = game:GetService("Players").LocalPlayer
            if not (lp and lp.Character and lp.Character:FindFirstChild("Humanoid") and lp.Character.Humanoid.Health > 0) then return end
            if state then
                cleanupDraw()
                isDrawingLine = true
                local cam = workspace.CurrentCamera
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = {lp.Character}
                local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 1000, rayParams)
                if hit and hit.Instance then
                    drawStartHit = { Position = hit.Position, Normal = hit.Normal }
                    currentDrawPart = Instance.new("Part", workspace)
                    currentDrawPart.Anchored = true
                    currentDrawPart.CanCollide = false
                    currentDrawPart.CanTouch = false
                    currentDrawPart.CanQuery = false
                    currentDrawPart.CastShadow = false
                    currentDrawPart.Massless = true
                    currentDrawPart.Color = env.PSLineSettings.Color
                    currentDrawPart.Transparency = env.PSLineSettings.Transparency
                    currentDrawPart.Material = Enum.Material.Neon
                    drawConnection = game:GetService("RunService").RenderStepped:Connect(function()
                        if not isDrawingLine then return end
                        local rayDir = cam.CFrame.LookVector
                        local rayOrigin = cam.CFrame.Position
                        local d = drawStartHit.Normal:Dot(rayDir)
                        if math.abs(d) > 1e-5 then
                            local t = drawStartHit.Normal:Dot(drawStartHit.Position - rayOrigin) / d
                            if t > 0 then
                                local intersect = rayOrigin + rayDir * t
                                local endPos = Vector3.new(intersect.X, drawStartHit.Position.Y, intersect.Z)
                                local length = (endPos - drawStartHit.Position).Magnitude
                                if length > 100 then
                                    local dir = (endPos - drawStartHit.Position).Unit
                                    endPos = drawStartHit.Position + dir * 100
                                    length = 100
                                end
                                if length < 0.1 then length = 0.1 end
                                local center = drawStartHit.Position:Lerp(endPos, 0.5)
                                currentDrawPart.Size = Vector3.new(length, 0.05, 0.001)
                                local right = (endPos - drawStartHit.Position).Unit
                                if right.Magnitude < 0.01 then right = drawStartHit.Normal:Cross(Vector3.new(0,1,0)) end
                                local up = drawStartHit.Normal:Cross(right).Unit
                                currentDrawPart.CFrame = CFrame.fromMatrix(center + drawStartHit.Normal * 0.01, right, up, -drawStartHit.Normal)
                            end
                        end
                    end)
                end
            else
                if isDrawingLine and drawStartHit and currentDrawPart then
                    local halfSize = currentDrawPart.Size.X / 2
                    local right = currentDrawPart.CFrame.RightVector
                    local center = currentDrawPart.Position - drawStartHit.Normal * 0.01
                    local p1 = center - right * halfSize
                    local p2 = center + right * halfSize
                    table.insert(env.PSLineSettings.Lines, {
                        P1 = p1,
                        P2 = p2,
                        Normal = drawStartHit.Normal
                    })
                    cleanupDraw()
                    env.RefreshPSLines()
                else
                    cleanupDraw()
                end
            end
        end
    end)()
    env.PSAssistant = false
    AssistantsSection:CreateToggle({
        Name = "PS Assistant",
        Default = false,
        Colorpickers = {
            {Name = "Line Color", ColorDefault = Color3.fromRGB(0, 255, 255), AlphaDefault = 1, Callback = function(c, alpha) 
                env.PSLineSettings.Color = c
                env.PSLineSettings.Transparency = 1 - (alpha or 1)
                env.RefreshPSLines() 
            end}
        },
        Callback = function(state) env.PSAssistant = state end
    })
    AssistantsSection:CreateToggle({
        Name = "Set PS Line",
        Default = false,
        Callback = function(state) 
            env.SetPSLine(state)
        end
    })
    AssistantsSection:CreateToggle({
        Name = "Remove PS Line",
        Default = false,
        Callback = function(state) 
            if state then env.RemovePSLine() end 
        end
    })
    ;(function()
        local psConfigName = "ps_default"
        AssistantsSection:CreateTextbox({
            Name = "PS Assist Config Name",
            Placeholder = "ps_default",
            Callback = function(text)
                if text == "" then psConfigName = "ps_default" else psConfigName = text end
            end
        })
        AssistantsSection:CreateButton({
            Name = "Save PS Assist Config",
            Callback = function()
                local fullConfig = {
                    PSLines = env.PSLineSettings.Lines
                }
                local encodedConfig = encodeValue(fullConfig)
                local s, str = pcall(function() return game:GetService("HttpService"):JSONEncode(encodedConfig) end)
                if s then
                    if not isfolder("mayday.tk") then pcall(makefolder, "mayday.tk") end
                    if not isfolder("mayday.tk/PSLines") then pcall(makefolder, "mayday.tk/PSLines") end
                    pcall(writefile, "mayday.tk/PSLines/" .. psConfigName .. ".json", str)
                    Library:Notify("PS Assist config saved: " .. psConfigName, 3)
                end
            end
        })
        AssistantsSection:CreateButton({
            Name = "Load PS Assist Config",
            Callback = function()
                local path = "mayday.tk/PSLines/" .. psConfigName .. ".json"
                if isfile(path) then
                    local success, str = pcall(readfile, path)
                    if success and str then
                        local s, decodedJSON = pcall(function() return game:GetService("HttpService"):JSONDecode(str) end)
                        if s and type(decodedJSON) == "table" then
                            local decodedConfig = decodeValue(decodedJSON)
                            if decodedConfig.PSLines then
                                env.PSLineSettings.Lines = decodedConfig.PSLines
                                env.RefreshPSLines()
                                Library:Notify("PS Assist config loaded: " .. psConfigName, 3)
                            else
                                Library:Notify("Invalid PS Assist config format.", 3)
                            end
                        end
                    end
                else
                    Library:Notify("PS Assist config '" .. psConfigName .. "' not found!", 3)
                end
            end
        })
    env.BounceAssist = false
    AssistantsSection:CreateToggle({
        Name = "Bounce Assist",
        Default = false,
        Callback = function(state) env.BounceAssist = state end
    })
    env.TBAssistant = false
    AssistantsSection:CreateToggle({
        Name = "TB Assistant",
        Default = false,
        Callback = function(state) env.TBAssistant = state end
    })
    end)()
    local IndicatorSection = MovementTab:CreateSection({
        Name = "Indicators",
        Side = "Right"
    })
    local SpeedIndicatorEnabled = false
    local SpeedInd_Y = 590
    local SpeedInd_Size = 32
    local SpeedInd_Color = Color3.fromRGB(255, 255, 255)
    local SpeedInd_Outline = Color3.fromRGB(0, 0, 0)
    local SpeedInd_Font = "RobotoMono"
    local SpeedInd_ShowLastSpeed = false
    local SpeedInd_LastSpeedColor = Color3.fromRGB(150, 150, 150)
    local BindIndicatorEnabled = false
    local BindInd_Y = 630
    local BindInd_Size = 28
    local BindInd_Color = Color3.fromRGB(255, 255, 255)
    local BindInd_Outline = Color3.fromRGB(0, 0, 0)
    local BindInd_Font = "RobotoMono"
    local FontsList = {"RobotoMono", "Gotham", "GothamBold", "TitilliumWeb", "SourceSans", "Arcade", "Highway", "Jura", "SciFi"}
    IndicatorSection:CreateToggle({
        Name = "Speed Indicator",
        Default = false,
        Colorpickers = {
            {Name = "Text", ColorDefault = Color3.fromRGB(255, 255, 255), Callback = function(c) SpeedInd_Color = c end},
            {Name = "Outline", ColorDefault = Color3.fromRGB(0, 0, 0), Callback = function(c) SpeedInd_Outline = c end}
        },
        Callback = function(state) SpeedIndicatorEnabled = state end
    })
    IndicatorSection:CreateToggle({
        Name = "Show Last Speed",
        Default = false,
        Colorpickers = {
            {Name = "Color", ColorDefault = Color3.fromRGB(150, 150, 150), Callback = function(c) SpeedInd_LastSpeedColor = c end}
        },
        Callback = function(state) SpeedInd_ShowLastSpeed = state end
    })
    IndicatorSection:CreateSlider({
        Name = "Speed Y Pos", Min = 0, Max = 1000, Default = 590,
        Callback = function(val) SpeedInd_Y = val end
    })
    IndicatorSection:CreateSlider({
        Name = "Speed Size", Min = 10, Max = 100, Default = 32,
        Callback = function(val) SpeedInd_Size = val end
    })
    if type(FontsList) == "table" and not table.find(FontsList, "VerdanaBold") then table.insert(FontsList, "VerdanaBold") end
    IndicatorSection:CreateDropdown({
        Name = "Speed Font", Options = FontsList, Default = "VerdanaBold",
        Callback = function(val) SpeedInd_Font = val end
    })
    IndicatorSection:CreateToggle({
        Name = "Bind Indicator",
        Default = false,
        Colorpickers = {
            {Name = "Text", ColorDefault = Color3.fromRGB(255, 255, 255), Callback = function(c) BindInd_Color = c end},
            {Name = "Outline", ColorDefault = Color3.fromRGB(0, 0, 0), Callback = function(c) BindInd_Outline = c end}
        },
        Callback = function(state) BindIndicatorEnabled = state end
    })
    IndicatorSection:CreateSlider({
        Name = "Bind Y Pos", Min = 0, Max = 1000, Default = 630,
        Callback = function(val) BindInd_Y = val end
    })
    IndicatorSection:CreateSlider({
        Name = "Bind Size", Min = 10, Max = 100, Default = 28,
        Callback = function(val) BindInd_Size = val end
    })
    IndicatorSection:CreateDropdown({
        Name = "Bind Font", Options = FontsList, Default = "VerdanaBold",
        Callback = function(val) BindInd_Font = val end
    })
    local BindIndicatorSelection = {eb = true, jb = true, lj = true, ps = true, tb = true, mj = true, ws = true, wc = true}
    IndicatorSection:CreateMultiDropdown({
        Name = "Shown Binds",
        Options = {"eb", "jb", "lj", "mj", "ps", "tb", "ws", "wc"},
        Default = {"eb", "jb", "lj", "mj", "ps", "tb", "ws", "wc"},
        Callback = function(sel)
            BindIndicatorSelection = {}
            for k, v in sel do
                if type(k) == "number" and type(v) == "string" then
                    BindIndicatorSelection[v] = true
                elseif type(k) == "string" and v == true then
                    BindIndicatorSelection[k] = true
                end
            end
        end
    })
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local edgebugSlideEndTime = 0
    local firemanJumpTick = 0
    local edgebugSlideVel = Vector3.new(0, 0, 0)
    local wasEdgebugging = false
    local lockedPixelSurfY = nil
    local pixelSurfEndTime = 0
    local lastPixelsurfEffectTime = 0
    local pixelSurfVel = Vector3.new(0, 0, 0)
    local lastSurfNormal = Vector3.new(0, 0, 0)
    local activeZiplineData = nil
    local lastTBugStart = 0
    local wasTBugging = false
    local isTBugValid = false
    local lastWallclimbTime = 0
    RunService.RenderStepped:Connect(function(deltaTime)
        local lp = Players.LocalPlayer
        if not lp then return end
        local char = lp.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end
        local needsNewController = false
        if not env.MovementController then
            needsNewController = true
        elseif env.MovementController.HumanoidRootPart ~= hrp then
            needsNewController = true
        end
        if needsNewController and getgc then
            for _, obj in (getgc(true)) do
                if type(obj) == "table" and rawget(obj, "GlobalVelocity") and rawget(obj, "Stamina") and rawget(obj, "HumanoidRootPart") == hrp then
                    env.MovementController = obj
                    if obj.Landed and type(obj.Landed) == "table" then
                        pcall(function()
                            local origFire = obj.Landed.Fire
                            if type(origFire) == "function" and not rawget(obj, "EdgebugHooked") then
                                obj.Landed.Fire = function(self, ...)
                                    local lastClimb = rawget(self, "LastClimbingTick") or 0
                                    if wasEdgebugging or tick() < edgebugSlideEndTime or (tick() - lastClimb) <= 1.0 then
                                        obj.PeakFallVelocity = 0
                                        obj.LandingVelocityY = 0
                                        obj.LastAirTime = 0
                                    end
                                    return origFire(self, ...)
                                end
                                rawset(obj, "EdgebugHooked", true)
                            end
                        end)
                    end
                    if obj.Jumping and type(obj.Jumping) == "table" then
                        pcall(function()
                            local origJump = obj.Jumping.Fire
                            if type(origJump) == "function" and not rawget(obj, "JumpHooked") then
                                obj.Jumping.Fire = function(self, ...)
                                    if AutoMinijump then
                                        if obj.Humanoid then obj.Humanoid.JumpPower = 19.5 * 0.67 end
                                    elseif AutoJumpbug then
                                        if obj.Humanoid then obj.Humanoid.JumpPower = 19.5 * 1.140 end
                                    else
                                        if obj.Humanoid then obj.Humanoid.JumpPower = 19.5 end
                                    end
                                    return origJump(self, ...)
                                end
                                rawset(obj, "JumpHooked", true)
                            end
                        end)
                    end
                    if type(obj.MoveFunction) == "function" then
                        pcall(function()
                            local origMove = obj.MoveFunction
                            if not rawget(obj, "MoveHookedFastLadder") then
                                local firemanJumpCooldown = 0
                                local firemanJumpVel = Vector3.zero
                                obj.MoveFunction = function(self, ...)
                                    origMove(self, ...)
                                    if AutoFastladder and self.IsClimbing and self.HumanoidRootPart then
                                        local hrp = self.HumanoidRootPart
                                        local vel = hrp.AssemblyLinearVelocity
                                        if vel.Y > 0.1 then
                                            hrp.AssemblyLinearVelocity = Vector3.new(vel.X, 18.9, vel.Z)
                                        elseif vel.Y < -0.1 then
                                            hrp.AssemblyLinearVelocity = Vector3.new(vel.X, -18.9, vel.Z)
                                        end
                                    end
                                end
                                rawset(obj, "MoveHookedFastLadder", true)
                            end
                        end)
                    end
                    break
                end
            end
        end
        if AutoEdgebug then
            if hum:GetState() == Enum.HumanoidStateType.Freefall and hrp.AssemblyLinearVelocity.Y < -10 then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local vel = hrp.AssemblyLinearVelocity
                local hDir = Vector3.new(vel.X, 0, vel.Z)
                if hDir.Magnitude > 0.5 then
                    hDir = hDir.Unit
                    local rDir = hDir:Cross(Vector3.new(0, 1, 0))
                    local edgeFound = false
                    local edgeFound = false
                    for offset = -1.5, 1.0, 0.5 do
                        local pos1 = hrp.Position + (hDir * offset)
                        local pos2 = hrp.Position + (hDir * (offset + 0.5))
                        local hit1 = workspace:Raycast(pos1, Vector3.new(0, -8, 0), rayParams)
                        local hit2 = workspace:Raycast(pos2, Vector3.new(0, -8, 0), rayParams)
                        if hit1 and not hit2 then
                            edgeFound = true
                            break
                        elseif hit1 and hit2 then
                            if hit1.Position.Y - hit2.Position.Y > 0.35 then
                                if hit1.Normal.Y > 0.8 and hit2.Normal.Y > 0.8 then
                                    edgeFound = true
                                    break
                                end
                            end
                        end
                    end
                    if edgeFound then
                        hrp.AssemblyLinearVelocity = Vector3.new(vel.X, vel.Y - (AutoEdgebugForce * deltaTime * 50), vel.Z)
                        wasEdgebugging = true
                        edgebugSlideVel = Vector3.new(vel.X, 0, vel.Z)
                    end
                end
            elseif wasEdgebugging then
                local state = hum:GetState()
                local velY = hrp.AssemblyLinearVelocity.Y
                if state == Enum.HumanoidStateType.Freefall and velY >= -10 and velY < 15 then
                    wasEdgebugging = false
                    edgebugSlideEndTime = tick() + 0.065
                    if AutoEdgebugEffect == "Circle" then
                        task.spawn(function()
                            local ts = game:GetService("TweenService")
                            local part = Instance.new("Part")
                            part.Anchored = true
                            part.CanCollide = false
                            part.CastShadow = false
                            part.Transparency = 1
                            part.Size = Vector3.new(3.75, 0.1, 3.75)
                            part.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2.95, 0))
                            part.Parent = workspace
                            local sg = Instance.new("SurfaceGui")
                            sg.Face = Enum.NormalId.Top
                            sg.CanvasSize = Vector2.new(400, 400)
                            sg.LightInfluence = 0
                            sg.Parent = part
                            local frame = Instance.new("Frame")
                            frame.Size = UDim2.new(0.9, 0, 0.9, 0)
                            frame.Position = UDim2.new(0.05, 0, 0.05, 0)
                            frame.BackgroundTransparency = 1
                            frame.Parent = sg
                            local corner = Instance.new("UICorner")
                            corner.CornerRadius = UDim.new(0.5, 0)
                            corner.Parent = frame
                            local stroke = Instance.new("UIStroke")
                            stroke.Color = CustomEffectColorToggle and CustomEffectColor or Color3.fromRGB(255, 255, 255)
                            stroke.Thickness = 12
                            stroke.Parent = frame
                            local ti = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0.4)
                            local tween = ts:Create(stroke, ti, {
                                Transparency = 1
                            })
                            tween:Play()
                            game:GetService("Debris"):AddItem(part, 1.5)
                        end)
                    end
                    if AutoEdgebugEffect == "Hit Skeleton" then
                        task.spawn(function()
                            local ts = game:GetService("TweenService")
                            local char = game:GetService("Players").LocalPlayer.Character
                            if not char then return end
                            local folder = Instance.new("Folder")
                            folder.Name = "HitSkeleton"
                            folder.Parent = workspace
                            local partsToFade = {}
                            local color = CustomEffectColorToggle and CustomEffectColor or Color3.fromRGB(255, 255, 255)
                            local function drawLine(part1Name, part2Name)
                                local p1 = char:FindFirstChild(part1Name)
                                local p2 = char:FindFirstChild(part2Name)
                                if p1 and p2 and p1:IsA("BasePart") and p2:IsA("BasePart") then
                                    local pos1 = p1.Position
                                    local pos2 = p2.Position
                                    local distance = (pos1 - pos2).Magnitude
                                    if distance > 0.01 then
                                        local line = Instance.new("Part")
                                        line.Anchored = true
                                        line.CanCollide = false
                                        line.CastShadow = false
                                        line.Material = Enum.Material.Neon
                                        line.Color = color
                                        line.Size = Vector3.new(0.08, 0.08, distance)
                                        line.CFrame = CFrame.lookAt(pos1, pos2) * CFrame.new(0, 0, -distance/2)
                                        line.Parent = folder
                                        table.insert(partsToFade, line)
                                    end
                                end
                            end
                            if char:FindFirstChild("UpperTorso") then
                                drawLine("Head", "UpperTorso")
                                drawLine("UpperTorso", "LowerTorso")
                                drawLine("UpperTorso", "LeftUpperArm")
                                drawLine("LeftUpperArm", "LeftLowerArm")
                                drawLine("LeftLowerArm", "LeftHand")
                                drawLine("UpperTorso", "RightUpperArm")
                                drawLine("RightUpperArm", "RightLowerArm")
                                drawLine("RightLowerArm", "RightHand")
                                drawLine("LowerTorso", "LeftUpperLeg")
                                drawLine("LeftUpperLeg", "LeftLowerLeg")
                                drawLine("LeftLowerLeg", "LeftFoot")
                                drawLine("LowerTorso", "RightUpperLeg")
                                drawLine("RightUpperLeg", "RightLowerLeg")
                                drawLine("RightLowerLeg", "RightFoot")
                            elseif char:FindFirstChild("Torso") then
                                drawLine("Head", "Torso")
                                drawLine("Torso", "Left Arm")
                                drawLine("Torso", "Right Arm")
                                drawLine("Torso", "Left Leg")
                                drawLine("Torso", "Right Leg")
                            end
                            local ti = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0.4)
                            for _, p in partsToFade do
                                local tween = ts:Create(p, ti, {Transparency = 1})
                                tween:Play()
                            end
                            game:GetService("Debris"):AddItem(folder, 2.5)
                        end)
                    end
                    if AutoEdgebugHitsound ~= "Off" and CustomHitsoundIDs[AutoEdgebugHitsound] then
                        local sound = Instance.new("Sound")
                        sound.SoundId = "rbxassetid://" .. CustomHitsoundIDs[AutoEdgebugHitsound]
                        sound.Volume = 1
                        sound.Parent = workspace
                        sound:Play()
                        game:GetService("Debris"):AddItem(sound, 5)
                    end
                    if EdgebugNotify then
                        Library:Notify("Edgebugged!", 3)
                    end
                elseif state ~= Enum.HumanoidStateType.Freefall or velY >= 15 then
                    wasEdgebugging = false
                end
            end
            if tick() < edgebugSlideEndTime then
                hrp.AssemblyLinearVelocity = Vector3.new(edgebugSlideVel.X, 0, edgebugSlideVel.Z)
            end
            if wasEdgebugging or tick() < edgebugSlideEndTime then
                if env.MovementController then
                    pcall(function()
                        env.MovementController.PeakFallVelocity = 0
                        env.MovementController.LandingVelocityY = 0
                        env.MovementController.LastAirTime = 0
                    end)
                end
            end
        end
        if tick() < firemanJumpTick + 0.5 then
            if hum and hum:GetStateEnabled(Enum.HumanoidStateType.Climbing) then
                hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
            end
        elseif hum and not hum:GetStateEnabled(Enum.HumanoidStateType.Climbing) then
            hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
        end
        if AutoFireman then
            local isClimbing = (hum:GetState() == Enum.HumanoidStateType.Climbing)
            if env.MovementController and env.MovementController.IsClimbing then
                isClimbing = true
            end
            if isClimbing and hrp then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -4.5, 0), rayParams)
                local isAtBottom = hit and hit.Normal.Y > 0.5
                if not isAtBottom then
                    local vel = hrp.AssemblyLinearVelocity
                    if vel.Y <= 0.5 then
                        hrp.AssemblyLinearVelocity = Vector3.new(vel.X, -22, vel.Z)
                    end
                else
                    if tick() > firemanJumpTick + 0.5 then
                        firemanJumpTick = tick()
                        local jumpDir = -hrp.CFrame.LookVector
                        local closestDist = 10
                        local dirs = { hrp.CFrame.LookVector, -hrp.CFrame.LookVector, hrp.CFrame.RightVector, -hrp.CFrame.RightVector }
                        for _, d in dirs do
                            local r = workspace:Raycast(hrp.Position, d * 3, rayParams)
                            if r and r.Distance < closestDist then
                                closestDist = r.Distance
                                jumpDir = r.Normal
                            end
                        end
                        local jumpVec = Vector3.new(jumpDir.X * 43.75, 20, jumpDir.Z * 43.75)
                        hrp.AssemblyLinearVelocity = jumpVec
                        if env.MovementController then
                            pcall(function() 
                                env.MovementController.IsClimbing = false
                                env.MovementController.GlobalVelocity = Vector3.new(jumpVec.X, 0, jumpVec.Z)
                                env.MovementController.IsJumping = true
                            end)
                            pcall(function() 
                                if env.MovementController.VectorForce then
                                    env.MovementController.VectorForce.Enabled = false
                                end
                            end)
                            pcall(function() env.MovementController.Jumping:Fire() end)
                        end
                        if hum then hum:ChangeState(Enum.HumanoidStateType.Freefall) end
                    end
                end
            end
        end
        if (AutoPixelsurf or env.PSAssistant) and hum:GetState() == Enum.HumanoidStateType.Freefall and hrp.AssemblyLinearVelocity.Y < 0 then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {char}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            local center = hrp.Position - Vector3.new(0, 2.8, 0) 
            local lv = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z).Unit
            local rv = Vector3.new(hrp.CFrame.RightVector.X, 0, hrp.CFrame.RightVector.Z).Unit
            local baseDirs = { lv, -lv, rv, -rv }
            local dirs = {}
            for _, bDir in baseDirs do
                table.insert(dirs, bDir)
                table.insert(dirs, (CFrame.new(Vector3.zero, bDir) * CFrame.Angles(0, math.rad(15), 0)).LookVector)
                table.insert(dirs, (CFrame.new(Vector3.zero, bDir) * CFrame.Angles(0, math.rad(-15), 0)).LookVector)
            end
            local pixelSurfFound = false
            local currentHitNormal = nil
            for _, dir in dirs do
                local pos1 = center + Vector3.new(0, 0.4, 0)
                local pos2 = center - Vector3.new(0, 0.4, 0)
                local hit1 = workspace:Raycast(pos1, dir * 1.65, rayParams)
                local hit2 = workspace:Raycast(pos2, dir * 1.65, rayParams)
                if hit1 and hit2 then
                    local function isValidPSPart(inst)
                        if not inst or not inst.Anchored then return false end
                        local p = inst.Parent
                        if p and p:FindFirstChildOfClass("Humanoid") then return false end
                        if inst:IsA("MeshPart") and inst.Size.Magnitude < 15 then return false end
                        if p and p.Name:lower():match("corpse") then return false end
                        if p and p.Parent and p.Parent.Name:lower():match("corpse") then return false end
                        return true
                    end
                    if isValidPSPart(hit1.Instance) and isValidPSPart(hit2.Instance) then
                        local distDiff = math.abs(hit1.Distance - hit2.Distance)
                        local normalDot = hit1.Normal:Dot(hit2.Normal)
                        if distDiff < 0.3 and normalDot > 0.9 then
                            if hit1.Instance ~= hit2.Instance or hit1.Material ~= hit2.Material or hit1.Instance.Color ~= hit2.Instance.Color then
                                pixelSurfFound = true
                                currentHitNormal = hit1.Normal
                                break
                            end
                        end
                    end
                end
            end
            if not pixelSurfFound and env.PSAssistant then
                local feetY = center.Y
                local matchedLineData = nil
                if env.PSLineSettings and env.PSLineSettings.Lines then
                    for _, data in env.PSLineSettings.Lines do
                        if data.P1 and data.P2 then
                            if math.abs(feetY - data.P1.Y) <= 0.35 then
                                local p1_xz = Vector2.new(data.P1.X, data.P1.Z)
                                local p2_xz = Vector2.new(data.P2.X, data.P2.Z)
                                local char_xz = Vector2.new(center.X, center.Z)
                                local segDir = (p2_xz - p1_xz).Unit
                                local segLen = (p2_xz - p1_xz).Magnitude
                                local charVec = char_xz - p1_xz
                                local proj = charVec:Dot(segDir)
                                if proj >= -0.1 and proj <= segLen + 0.1 then
                                    local closest_xz = p1_xz + segDir * math.clamp(proj, 0, segLen)
                                    if (char_xz - closest_xz).Magnitude <= 2 then
                                        matchedLineData = data
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
                if matchedLineData then
                    pixelSurfFound = true
                    currentHitNormal = matchedLineData.Normal
                    activeZiplineData = matchedLineData
                end
            end
            local uis = game:GetService("UserInputService")
            local cam = workspace.CurrentCamera
            local moveVector = Vector3.zero
            if uis:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + cam.CFrame.RightVector end
            moveVector = Vector3.new(moveVector.X, 0, moveVector.Z)
            if moveVector.Magnitude > 0 then
                moveVector = moveVector.Unit
            end
            if pixelSurfFound then
                if moveVector:Dot(currentHitNormal) > 0.2 then
                    pixelSurfFound = false
                end
            end
            if pixelSurfFound then
                lastSurfNormal = currentHitNormal
                if tick() > pixelSurfEndTime then
                    lockedPixelSurfY = hrp.Position.Y
                    pixelSurfVel = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
                    lastPixelsurfEffectTime = 0
                end
                if tick() > lastPixelsurfEffectTime + 0.4 then
                    lastPixelsurfEffectTime = tick()
                    if AutoPixelsurfEffect == "Circle" then
                        task.spawn(function()
                            local ts = game:GetService("TweenService")
                            local part = Instance.new("Part")
                            part.Anchored = true
                            part.CanCollide = false
                            part.CastShadow = false
                            part.Transparency = 1
                            part.Size = Vector3.new(3.75, 0.1, 3.75)
                            part.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2.95, 0))
                            part.Parent = workspace
                            local sg = Instance.new("SurfaceGui")
                            sg.Face = Enum.NormalId.Top
                            sg.CanvasSize = Vector2.new(400, 400)
                            sg.LightInfluence = 0
                            sg.Parent = part
                            local frame = Instance.new("Frame")
                            frame.Size = UDim2.new(0.9, 0, 0.9, 0)
                            frame.Position = UDim2.new(0.05, 0, 0.05, 0)
                            frame.BackgroundTransparency = 1
                            frame.Parent = sg
                            local corner = Instance.new("UICorner")
                            corner.CornerRadius = UDim.new(0.5, 0)
                            corner.Parent = frame
                            local stroke = Instance.new("UIStroke")
                            stroke.Color = CustomPixelsurfEffectColorToggle and CustomPixelsurfEffectColor or Color3.fromRGB(255, 255, 255)
                            stroke.Thickness = 12
                            stroke.Parent = frame
                            local ti = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0.4)
                            local tween = ts:Create(stroke, ti, { Transparency = 1 })
                            tween:Play()
                            game:GetService("Debris"):AddItem(part, 1.5)
                        end)
                    end
                    if AutoPixelsurfEffect == "Hit Skeleton" then
                        task.spawn(function()
                            local ts = game:GetService("TweenService")
                            local char = game:GetService("Players").LocalPlayer.Character
                            if not char then return end
                            local folder = Instance.new("Folder")
                            folder.Name = "HitSkeleton"
                            folder.Parent = workspace
                            local partsToFade = {}
                            local color = CustomPixelsurfEffectColorToggle and CustomPixelsurfEffectColor or Color3.fromRGB(255, 255, 255)
                            local function drawLine(part1Name, part2Name)
                                local p1 = char:FindFirstChild(part1Name)
                                local p2 = char:FindFirstChild(part2Name)
                                if p1 and p2 and p1:IsA("BasePart") and p2:IsA("BasePart") then
                                    local pos1 = p1.Position
                                    local pos2 = p2.Position
                                    local distance = (pos1 - pos2).Magnitude
                                    if distance > 0.01 then
                                        local line = Instance.new("Part")
                                        line.Anchored = true
                                        line.CanCollide = false
                                        line.CastShadow = false
                                        line.Material = Enum.Material.Neon
                                        line.Color = color
                                        line.Size = Vector3.new(0.08, 0.08, distance)
                                        line.CFrame = CFrame.lookAt(pos1, pos2) * CFrame.new(0, 0, -distance/2)
                                        line.Parent = folder
                                        table.insert(partsToFade, line)
                                    end
                                end
                            end
                            if char:FindFirstChild("UpperTorso") then
                                drawLine("Head", "UpperTorso") drawLine("UpperTorso", "LowerTorso") drawLine("UpperTorso", "LeftUpperArm") drawLine("LeftUpperArm", "LeftLowerArm") drawLine("LeftLowerArm", "LeftHand") drawLine("UpperTorso", "RightUpperArm") drawLine("RightUpperArm", "RightLowerArm") drawLine("RightLowerArm", "RightHand") drawLine("LowerTorso", "LeftUpperLeg") drawLine("LeftUpperLeg", "LeftLowerLeg") drawLine("LeftLowerLeg", "LeftFoot") drawLine("LowerTorso", "RightUpperLeg") drawLine("RightUpperLeg", "RightLowerLeg") drawLine("RightLowerLeg", "RightFoot")
                            elseif char:FindFirstChild("Torso") then
                                drawLine("Head", "Torso") drawLine("Torso", "Left Arm") drawLine("Torso", "Right Arm") drawLine("Torso", "Left Leg") drawLine("Torso", "Right Leg")
                            end
                            local ti = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0.4)
                            for _, p in partsToFade do
                                local tween = ts:Create(p, ti, {Transparency = 1})
                                tween:Play()
                            end
                            game:GetService("Debris"):AddItem(folder, 2.5)
                        end)
                    end
                    if AutoPixelsurfHitsound ~= "Off" and CustomHitsoundIDs[AutoPixelsurfHitsound] then
                        local sound = Instance.new("Sound")
                        sound.SoundId = "rbxassetid://" .. CustomHitsoundIDs[AutoPixelsurfHitsound]
                        sound.Volume = 1
                        sound.Parent = workspace
                        sound:Play()
                        game:GetService("Debris"):AddItem(sound, 5)
                    end
                    if PixelsurfNotify then
                        Library:Notify("Pixelsurfed!", 3)
                    end
                end
                pixelSurfEndTime = tick() + 0.3
            end
            if tick() < pixelSurfEndTime then
                if moveVector:Dot(lastSurfNormal) > 0.2 then
                    pixelSurfEndTime = 0 
                end
            end
            if tick() < pixelSurfEndTime then
                if activeZiplineData then
                    local targetY = activeZiplineData.P1.Y + (hrp.Position.Y - center.Y)
                    local p1_xz = Vector2.new(activeZiplineData.P1.X, activeZiplineData.P1.Z)
                    local p2_xz = Vector2.new(activeZiplineData.P2.X, activeZiplineData.P2.Z)
                    local hrp_xz = Vector2.new(hrp.Position.X, hrp.Position.Z)
                    local segDir = (p2_xz - p1_xz).Unit
                    local segLen = (p2_xz - p1_xz).Magnitude
                    local charVec = hrp_xz - p1_xz
                    local rawProj = charVec:Dot(segDir)
                    if rawProj < -0.2 or rawProj > segLen + 0.2 then
                        pixelSurfEndTime = 0
                        lockedPixelSurfY = nil
                        activeZiplineData = nil
                    else
                        local proj = math.clamp(rawProj, 0, segLen)
                        local closest_xz = p1_xz + segDir * proj
                        local targetXZ = closest_xz + Vector2.new(activeZiplineData.Normal.X, activeZiplineData.Normal.Z) * 1.5
                        local speed = pixelSurfVel.Magnitude
                        local velDir = Vector2.new(pixelSurfVel.X, pixelSurfVel.Z)
                        if velDir.Magnitude > 0.1 then
                             local dot = velDir.Unit:Dot(segDir)
                             local newVelDir = segDir * dot * speed
                             hrp.AssemblyLinearVelocity = Vector3.new(newVelDir.X, 0, newVelDir.Y)
                        else
                             hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        end
                        hrp.CFrame = CFrame.new(targetXZ.X, targetY, targetXZ.Y) * hrp.CFrame.Rotation
                    end
                else
                    hrp.AssemblyLinearVelocity = pixelSurfVel
                    hrp.CFrame = (hrp.CFrame - hrp.CFrame.Position) + Vector3.new(hrp.Position.X, lockedPixelSurfY, hrp.Position.Z)
                end
            else
                lockedPixelSurfY = nil
                activeZiplineData = nil
                if env.OriginalGravity then
                    workspace.Gravity = env.OriginalGravity
                    env.OriginalGravity = nil
                end
            end
        end
        if AutoLongjump and hum:GetState() == Enum.HumanoidStateType.Running and hrp.AssemblyLinearVelocity.Magnitude > 10 then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {char}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            local hitDown = workspace:Raycast(hrp.Position, Vector3.new(0, -4, 0), rayParams)
            local moveDir = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Unit
            local checkPos = hrp.Position + (moveDir * 1.5)
            local hitForward = workspace:Raycast(checkPos, Vector3.new(0, -4, 0), rayParams)
            if hitDown and not hitForward then
                if env.MovementController then
                    env.MovementController.IsJumping = true
                    env.MovementController.LastJumpTick = tick()
                    env.MovementController.ReadyToJump = false
                    pcall(function() env.MovementController.Jumping:Fire() end)
                    pcall(function() env.MovementController.CharacterAnimator:play("Jump", 0.2) end)
                end
                hum.Jump = true
                task.defer(function()
                    if hrp then
                        local currentVel = hrp.AssemblyLinearVelocity
                        hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X * 1.4, math.max(currentVel.Y, 19.5) * 1.1, currentVel.Z * 1.4)
                    end
                end)
            end
        end
        if AutoTexturebug and hrp then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {char}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.RespectCanCollide = true
            local lv = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z).Unit
            local rv = Vector3.new(hrp.CFrame.RightVector.X, 0, hrp.CFrame.RightVector.Z).Unit
            local baseDirs = { lv, -lv, rv, -rv }
            local directions = {}
            for _, bDir in baseDirs do
                table.insert(directions, bDir)
                table.insert(directions, (CFrame.new(Vector3.zero, bDir) * CFrame.Angles(0, math.rad(15), 0)).LookVector)
                table.insert(directions, (CFrame.new(Vector3.zero, bDir) * CFrame.Angles(0, math.rad(-15), 0)).LookVector)
            end
            local rayLength = 1.95
            local isBugging = false
            local isHeadBugging = false
            local wallNormal = Vector3.new()
            local numRays = 20
            local minY = -3.0
            local maxY = 2.5
            for _, dir in directions do
                local hits = {}
                for i = 0, numRays - 1 do
                    local t = i / (numRays - 1)
                    local yOffset = minY + (maxY - minY) * t
                    local origin = hrp.Position + Vector3.new(0, yOffset, 0)
                    local currentPos = origin
                    local remDist = rayLength
                    local finalHit = nil
                    while remDist > 0 do
                        local hitResult = workspace:Raycast(currentPos, dir * remDist, rayParams)
                        if hitResult then
                            if hitResult.Instance.Transparency == 1 or not hitResult.Instance.CanCollide then
                                local trav = (hitResult.Position - currentPos).Magnitude
                                remDist = remDist - trav - 0.001
                                currentPos = hitResult.Position + (dir * 0.001)
                            else
                                finalHit = hitResult
                                break
                            end
                        else
                            break
                        end
                    end
                    if finalHit then
                        hits[i] = finalHit.Normal
                    else
                        hits[i] = nil
                    end
                end
                local foundBodyEdge = false
                local foundHeadEdge = false
                local detectedNormal = nil
                for i = 1, numRays - 1 do
                    local hitTop = hits[i]
                    local hitBottom = hits[i-1]
                    local isOverhangBottom = hitTop and not hitBottom
                    local isLedgeTop = not hitTop and hitBottom
                    if isOverhangBottom or isLedgeTop then
                        if i >= 17 then 
                            if isOverhangBottom then
                                foundHeadEdge = true
                                detectedNormal = hitTop or hitBottom
                            end
                        else 
                            local normal = hitTop or hitBottom
                            if normal and math.abs(normal.Y) < 0.5 then
                                foundBodyEdge = true
                                detectedNormal = normal
                            end
                        end
                    end
                end
                if foundHeadEdge then
                    isBugging = true
                    isHeadBugging = true
                    wallNormal = detectedNormal
                    break
                elseif foundBodyEdge then
                    isBugging = true
                    isHeadBugging = false
                    wallNormal = detectedNormal
                    break
                end
            end
            if isBugging then
                local canTriggerNewBug = true
                if not isHeadBugging and tick() - lastTBugStart < 0.3 then
                    canTriggerNewBug = false
                end
                if (not wasTBugging or hrp.AssemblyLinearVelocity.Y > 5) and canTriggerNewBug then
                    lastTBugStart = tick()
                    if hrp.AssemblyLinearVelocity.Y > 0 then
                        isTBugValid = true
                    else
                        isTBugValid = false
                    end
                end
                wasTBugging = true
                local shouldFreeze = isTBugValid
                if isHeadBugging then
                    shouldFreeze = true
                elseif tick() - lastTBugStart > 0.1 then
                    shouldFreeze = false
                end
                local moveDir = hum and hum.MoveDirection or Vector3.new()
                if moveDir.Magnitude > 0 and moveDir:Dot(wallNormal) > 0.3 then
                elseif shouldFreeze then
                    local currentVel = hrp.AssemblyLinearVelocity
                    local horizVel = Vector3.new(currentVel.X, 0, currentVel.Z)
                    local wallNormalHoriz = Vector3.new(wallNormal.X, 0, wallNormal.Z)
                    if wallNormalHoriz.Magnitude > 0.001 then
                        wallNormalHoriz = wallNormalHoriz.Unit
                        local dotProduct = horizVel:Dot(wallNormalHoriz)
                        if dotProduct < 0 then
                            horizVel = horizVel - wallNormalHoriz * dotProduct
                        end
                    end
                    hrp.AssemblyLinearVelocity = Vector3.new(horizVel.X, 0, horizVel.Z)
                end
            else
                wasTBugging = false
                isTBugValid = false
            end
        end
        if AutoWallstuck then
            local state = hum:GetState()
            if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {char, workspace.CurrentCamera}
                params.FilterType = Enum.RaycastFilterType.Exclude
                local hitWall = false
                local dirs = {
                    hrp.CFrame.LookVector,
                    -hrp.CFrame.LookVector,
                    hrp.CFrame.RightVector,
                    -hrp.CFrame.RightVector
                }
                for _, dir in dirs do
                    local res = workspace:Raycast(hrp.Position, dir * 2.5, params)
                    if res and res.Instance and res.Instance.CanCollide then
                        hitWall = true
                        break
                    end
                end
                if hitWall then
                    if not env.IsWallstuck then
                        env.IsWallstuck = true
                        hrp.Anchored = true
                    end
                else
                    if env.IsWallstuck then
                        env.IsWallstuck = false
                        hrp.Anchored = false
                    end
                end
                if env.IsWallstuck then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            else
                if env.IsWallstuck then
                    env.IsWallstuck = false
                    hrp.Anchored = false
                end
            end
        else
            if env.IsWallstuck then
                env.IsWallstuck = false
                if hrp then hrp.Anchored = false end
            end
        end
        local head = char:FindFirstChild("Head")
        if AutoBhop then
            if head then
                local isCtrlPressed = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
                if isCtrlPressed then
                    if head.CanCollide then head.CanCollide = false end
                else
                    if not head.CanCollide then head.CanCollide = true end
                end
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            local state = hum:GetState()
            if AntiTrimp then
                local hrpVel = hrp.AssemblyLinearVelocity
                if hrpVel.Y > 55 then
                    hrp.AssemblyLinearVelocity = Vector3.new(hrpVel.X, 50, hrpVel.Z)
                end
            end
            if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
                if env.MovementController then
                    env.MovementController.IsJumping = true
                    env.MovementController.LastJumpTick = tick()
                    env.MovementController.ReadyToJump = false
                    pcall(function() env.MovementController.Jumping:Fire() end)
                    pcall(function() env.MovementController.CharacterAnimator:play("Jump", 0.2) end)
                end
                hum.Jump = true
                if AutoJumpbug or AutoMinijump then
                end
            end
            end
        else
            if head and not head.CanCollide then
                head.CanCollide = true
            end
        end
        local isClimbingLadder = false
        if char then
            local vf = char:FindFirstChildWhichIsA("VectorForce", true)
            if vf and vf.Enabled then
                isClimbingLadder = true
            end
        end
        if AutoWallclimb and not isClimbingLadder then
            local now = tick()
            if (now - lastWallclimbTime) >= 0.4 then
                if hum:GetState() == Enum.HumanoidStateType.Freefall or hum.FloorMaterial == Enum.Material.Air then
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = {char}
                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                        local center = hrp.Position
                        local lv = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z).Unit
                        local rv = Vector3.new(hrp.CFrame.RightVector.X, 0, hrp.CFrame.RightVector.Z).Unit
                        local baseDirs = { lv, -lv, rv, -rv }
                        local dirs = {}
                        for _, bDir in baseDirs do
                            table.insert(dirs, bDir)
                            table.insert(dirs, (CFrame.new(Vector3.zero, bDir) * CFrame.Angles(0, math.rad(15), 0)).LookVector)
                            table.insert(dirs, (CFrame.new(Vector3.zero, bDir) * CFrame.Angles(0, math.rad(-15), 0)).LookVector)
                        end
                        local hitFound = false
                        for _, dir in dirs do
                            local pos1 = center + Vector3.new(0, 0.4, 0)
                            local pos2 = center - Vector3.new(0, 0.4, 0)
                            local hit1 = workspace:Raycast(pos1, dir * 2.5, rayParams)
                            local hit2 = workspace:Raycast(pos2, dir * 2.5, rayParams)
                            if hit1 or hit2 then
                                hitFound = true
                                break
                            end
                        end
                        if hitFound then
                            local currentVel = hrp.AssemblyLinearVelocity
                            hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X, 22, currentVel.Z)
                            pcall(function()
                                if env.MovementController and env.MovementController.CharacterAnimator then
                                    env.MovementController.CharacterAnimator:play("Jump", 0.1)
                                end
                            end)
                            lastWallclimbTime = now
                        end
                    end
                end
            end
        end
        if AutoStrafe and hum:GetState() == Enum.HumanoidStateType.Freefall and not isClimbingLadder then
            local moveVector = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + Vector3.new(0, 0, -1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector + Vector3.new(0, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector + Vector3.new(-1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + Vector3.new(1, 0, 0) end
            if moveVector.Magnitude > 0 then
                moveVector = moveVector.Unit
                local Camera = workspace.CurrentCamera
                local lookVector = Camera.CFrame.LookVector
                local rightVector = Camera.CFrame.RightVector
                local forward = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
                local right = Vector3.new(rightVector.X, 0, rightVector.Z).Unit
                local targetDir = (forward * -moveVector.Z) + (right * moveVector.X)
                if targetDir.Magnitude > 0 then
                    targetDir = targetDir.Unit
                end
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local hit = workspace:Spherecast(hrp.Position, 0.64, targetDir * 1, rayParams)
                if hit then
                    local dot = targetDir:Dot(hit.Normal)
                    if dot < 0 then
                        targetDir = targetDir - hit.Normal * dot
                        if targetDir.Magnitude > 0.01 then
                            targetDir = targetDir.Unit
                        else
                            targetDir = Vector3.new(0, 0, 0)
                        end
                    end
                end
                local currentVel = hrp.AssemblyLinearVelocity
                local newVel = targetDir * AutoStrafeSpeed
                hrp.AssemblyLinearVelocity = Vector3.new(newVel.X, currentVel.Y, newVel.Z)
            end
        end
    end)
    task.spawn(function()
        print("[clarity] Waiting for player to spawn before hooking Silent Aim...")
        local lp = game:GetService("Players").LocalPlayer
        while not (lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")) do task.wait(1) end
        print("[clarity] Player spawned. Waiting 1 second before searching for Bullet module...")
        task.wait(1)
        local bullet_module = nil
        while not bullet_module do
            if type(getloadedmodules) == "function" then
                for _, v in getloadedmodules() do
                    if v:IsA("ModuleScript") and not string.find(v:GetFullName(), "Audio") then
                        local success, mod = pcall(require, v)
                        if success and type(mod) == "table" and (rawget(mod, "_performRaycast") or mod._performRaycast or mod.performRaycast) then
                            bullet_module = mod
                            print("[clarity] Successfully found Bullet module via getloadedmodules! Path: " .. v:GetFullName())
                            break
                        end
                    end
                end
            end
            if not bullet_module then
                local rs = game:GetService("ReplicatedStorage")
                local comp = rs:FindFirstChild("Components")
                if comp then
                    for _, weaponFolder in comp:GetChildren() do
                        if weaponFolder:IsA("Folder") then
                            local classesFolder = weaponFolder:FindFirstChild("Classes")
                            if classesFolder then
                                for _, blt in classesFolder:GetChildren() do
                                    if blt:IsA("ModuleScript") then
                                        local success, mod = pcall(require, blt)
                                        if success and type(mod) == "table" and (rawget(mod, "_performRaycast") or mod._performRaycast or mod.performRaycast) then
                                            bullet_module = mod
                                            print("[clarity] Successfully found Bullet module via Structural Search! Path: " .. blt:GetFullName())
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        if bullet_module then break end
                    end
                end
            end
            if not bullet_module then
task.wait(2)
            end
        end
        if bullet_module then
        local originalPerformRaycast = bullet_module._performRaycast
        if not originalPerformRaycast and bullet_module.performRaycast then
            originalPerformRaycast = bullet_module.performRaycast
        end
        if originalPerformRaycast then
            if hookToStringSpoof then
                hookToStringSpoof(bullet_module, "_performRaycast", function(orig, self, spreadAmount)
                    local lp = game:GetService("Players").LocalPlayer
                    local isFalling = false
                    if lp and lp.Character then
                        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
                        if hum and hum:GetState() == Enum.HumanoidStateType.Freefall then
                            isFalling = true
                        end
                    end
                    local targetPos, targetInstance = getClosestEnemyToMouseSilentAim()
                    local startPos = workspace.CurrentCamera.CFrame.Position
                    if AimbotSettings.SilentAim and targetPos and targetInstance and startPos then
                        local targetMaterial = Enum.Material.Plastic
                        local targetMaterialName = "Plastic"
                        if targetInstance:IsA("BasePart") then
                            targetMaterial = targetInstance.Material
                            targetMaterialName = targetInstance.Material.Name
                        end
                        if isFalling then
                            if AimbotSettings.NoSpread then
                                local direction = (targetPos - startPos).Unit
                                local fakeResult = {
                                    Distance = (targetPos - startPos).Magnitude,
                                    Origin = startPos,
                                    Direction = direction,
                                    Hits = {
                                        {
                                            Instance = targetInstance,
                                            Position = targetPos,
                                            Material = targetMaterialName,
                                            Normal = Vector3.new(0, 1, 0),
                                            Exit = false
                                        }
                                    }
                                }
                                if env.HitmarkerSettings.Tracers then env.DrawTracer(startPos, targetPos) end
                                if env.HitmarkerSettings.Hitmarker2D then env.Draw2DHitmarker() end
                                if env.HitmarkerSettings.Hitmarker3D then env.Draw3DHitmarker(targetPos) end
                                if env.HitmarkerSettings.HitLog then 
                                    local tHum = targetInstance.Parent:FindFirstChildOfClass("Humanoid")
                                    local tHealth = tHum and tHum.Health or 100
                                    env.LogHit(targetInstance.Parent.Name, targetInstance.Name, env.GetFakeDamage(targetInstance, tHealth))
                                end
                                return fakeResult
                            else
                                local legitRoll = math.random(1, 100)
                                if legitRoll <= 20 then
                                    local direction = (targetPos - startPos).Unit
                                    local fakeResult = {
                                        Distance = (targetPos - startPos).Magnitude,
                                        Origin = startPos,
                                        Direction = direction,
                                        Hits = {
                                            {
                                                Instance = targetInstance,
                                                Position = targetPos,
                                                Material = targetMaterialName,
                                                Normal = Vector3.new(0, 1, 0),
                                                Exit = false
                                            }
                                        }
                                    }
                                    if env.HitmarkerSettings.Tracers then env.DrawTracer(startPos, targetPos) end
                                    if env.HitmarkerSettings.Hitmarker2D then env.Draw2DHitmarker() end
                                    if env.HitmarkerSettings.Hitmarker3D then env.Draw3DHitmarker(targetPos) end
                                    if env.HitmarkerSettings.HitLog then 
                                        local tHum = targetInstance.Parent:FindFirstChildOfClass("Humanoid")
                                        local tHealth = tHum and tHum.Health or 100
                                        env.LogHit(targetInstance.Parent.Name, targetInstance.Name, env.GetFakeDamage(targetInstance, tHealth))
                                    end
                                    return fakeResult
                                else
                                    local baseSpread = spreadAmount > 0 and spreadAmount or 0.1
                                    return orig(self, baseSpread * math.random(2, 5))
                                end
                            end
                        else
                            local direction = (targetPos - startPos).Unit
                            local fakeResult = {
                                Distance = (targetPos - startPos).Magnitude,
                                Origin = startPos,
                                Direction = direction,
                                Hits = {
                                    {
                                        Instance = targetInstance,
                                        Position = targetPos,
                                        Material = targetMaterialName,
                                        Normal = Vector3.new(0, 1, 0),
                                        Exit = false
                                    }
                                }
                            }
                            if env.HitmarkerSettings.Tracers then env.DrawTracer(startPos, targetPos) end
                            if env.HitmarkerSettings.Hitmarker2D then env.Draw2DHitmarker() end
                            if env.HitmarkerSettings.Hitmarker3D then env.Draw3DHitmarker(targetPos) end
                            if env.HitmarkerSettings.HitLog then 
                                local tHum = targetInstance.Parent:FindFirstChildOfClass("Humanoid")
                                local tHealth = tHum and tHum.Health or 100
                                env.LogHit(targetInstance.Parent.Name, targetInstance.Name, env.GetFakeDamage(targetInstance, tHealth))
                            end
                            return fakeResult
                        end
                    elseif AimbotSettings.SilentAim then
                    end
                    if AimbotSettings.NoSpread then
                        spreadAmount = 0
                    end
                    local finalResult = orig(self, spreadAmount)
                    if finalResult and finalResult.Hits and #finalResult.Hits > 0 then
                        local hit = finalResult.Hits[1]
                        if env.HitmarkerSettings.Tracers then
                            env.DrawTracer(finalResult.Origin or workspace.CurrentCamera.CFrame.Position, hit.Position)
                        end
                        if hit.Instance and hit.Instance.Parent and hit.Instance.Parent:FindFirstChild("Humanoid") then
                            local hum = hit.Instance.Parent:FindFirstChild("Humanoid")
                            if hum.Health > 0 then
                                if env.HitmarkerSettings.Hitmarker2D then env.Draw2DHitmarker() end
                                if env.HitmarkerSettings.Hitmarker3D then env.Draw3DHitmarker(hit.Position) end
                                if env.HitmarkerSettings.HitLog then 
                                    local tHealth = hum and hum.Health or 100
                                    env.LogHit(hit.Instance.Parent.Name, hit.Instance.Name, env.GetFakeDamage(hit.Instance, tHealth))
                                end
                            end
                        end
                    end
                    return finalResult
                end)
                print("[clarity] Successfully hooked _performRaycast safely with hookToStringSpoof!")
            else
bullet_module._performRaycast = function(self, spreadAmount)
                    if AimbotSettings.SilentAim then spreadAmount = 0 end
                    local targetPart = getClosestEnemyToMouse()
                    local startPos = workspace.CurrentCamera.CFrame.Position
                    if AimbotSettings.SilentAim and targetPart and startPos then
                        local targetPos = targetPart.Position
                        local direction = (targetPos - startPos).Unit
                        return {
                            Hits = {{ Instance = targetPart, Position = targetPos, Normal = Vector3.new(0, 1, 0), Material = targetPart.Material.Name, Distance = (targetPos - startPos).Magnitude, Exit = false }},
                            Ray = Ray.new(startPos, direction), Instance = targetPart, Position = targetPos, Material = targetPart.Material, Normal = Vector3.new(0, 1, 0), Distance = (targetPos - startPos).Magnitude, Direction = direction, Origin = startPos 
                        }
                    end
                    return originalPerformRaycast(self, spreadAmount)
                end
            end
            end
        end
    end)
    local WidgetsSection = MiscTab:CreateSection({
        Name = "Widgets",
        Side = "Left"
    })
    local WidgetsEnabled = false
    WidgetsSection:CreateToggle({
        Name = "Enable Widgets",
        Default = false,
        Callback = function(state) WidgetsEnabled = state end
    })
    local ActiveWidgets = {["Spectator List"] = true, ["Keybinds"] = true}
    WidgetsSection:CreateMultiDropdown({
        Name = "Active Widgets",
        Options = {"Spectator List", "Keybinds"},
        Default = {"Spectator List", "Keybinds"},
        Callback = function(sel)
            ActiveWidgets = {}
            for k, v in sel do
                if type(k) == "number" and type(v) == "string" then
                    ActiveWidgets[v] = true
                elseif type(k) == "string" and v == true then
                    ActiveWidgets[k] = true
                end
            end
        end
    })
    local Spec_TitleColor = Color3.fromRGB(255, 255, 255)
    local Spec_PlayersColor = Color3.fromRGB(98, 98, 98)
    local Spec_Scale = 80
    local Spec_Font = "TitilliumWeb"
    local KB_TitleColor = Color3.fromRGB(255, 255, 255)
    local KB_TextColor = Color3.fromRGB(98, 98, 98)
    local KB_Scale = 80
    local KB_Font = "TitilliumWeb"
    local SpecFontsList = {"RobotoMono", "Gotham", "GothamBold", "TitilliumWeb", "SourceSans", "Arcade", "Highway", "Jura", "SciFi"}
    WidgetsSection:CreateToggle({
        Name = "Spectator Settings",
        Default = false,
        Colorpickers = {
            {Name = "Title", ColorDefault = Color3.fromRGB(255, 255, 255), Callback = function(c) Spec_TitleColor = c end},
            {Name = "Players", ColorDefault = Color3.fromRGB(98, 98, 98), Callback = function(c) Spec_PlayersColor = c end}
        },
        Callback = function(state) end
    })
    WidgetsSection:CreateSlider({
        Name = "Spectator Size", Min = 50, Max = 150, Default = 80,
        Callback = function(val) Spec_Scale = val end
    })
    WidgetsSection:CreateDropdown({
        Name = "Spectator Font", Options = SpecFontsList, Default = "TitilliumWeb",
        Callback = function(val) Spec_Font = val end
    })
    WidgetsSection:CreateToggle({
        Name = "Keybinds Settings",
        Default = false,
        Colorpickers = {
            {Name = "Title", ColorDefault = Color3.fromRGB(255, 255, 255), Callback = function(c) KB_TitleColor = c end},
            {Name = "Text", ColorDefault = Color3.fromRGB(98, 98, 98), Callback = function(c) KB_TextColor = c end}
        },
        Callback = function(state) end
    })
    WidgetsSection:CreateSlider({
        Name = "Keybinds Size", Min = 50, Max = 150, Default = 80,
        Callback = function(val) KB_Scale = val end
    })
    WidgetsSection:CreateDropdown({
        Name = "Keybinds Font", Options = SpecFontsList, Default = "TitilliumWeb",
        Callback = function(val) KB_Font = val end
    })
    local _UnlockState = {}
    local state = _UnlockState
    local function unlock_inventory()
        pcall(function()
            local Players = game:GetService("Players")
            local localPlayer = Players.LocalPlayer
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local DataController = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("DataController"))
            if state.OriginalDataControllerGet then DataController.Get = state.OriginalDataControllerGet end
            if state.OriginalApplyInventoryDelta then DataController.ApplyInventoryDelta = state.OriginalApplyInventoryDelta end
            local Remotes = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Security"):WaitForChild("Remotes"))
            local EquipLoadoutSkin = Remotes.Inventory.EquipLoadoutSkin
            local EquipSpecialItem = Remotes.Inventory.EquipSpecialItem
            local SwapLoadoutSkins = Remotes.Inventory.SwapLoadoutSkins
            if state.OriginalEquipLoadoutSkinSend then EquipLoadoutSkin.Send = state.OriginalEquipLoadoutSkinSend end
            if state.OriginalEquipSpecialItemSend then EquipSpecialItem.Send = state.OriginalEquipSpecialItemSend end
            if state.OriginalSwapLoadoutSkinsSend then SwapLoadoutSkins.Send = state.OriginalSwapLoadoutSkinsSend end
            local WeaponComponentModule = ReplicatedStorage:WaitForChild("Classes"):WaitForChild("WeaponComponent")
            local WeaponComponent = require(WeaponComponentModule)
            if state.OriginalWeaponComponentNew then WeaponComponent.new = state.OriginalWeaponComponentNew end
            local ViewmodelModule = WeaponComponentModule:WaitForChild("Classes"):WaitForChild("Viewmodel")
            local Viewmodel = require(ViewmodelModule)
            if state.OriginalAddAttachments then Viewmodel.addAttachments = state.OriginalAddAttachments end
            local weaponTypes = {
                ["CZ75-Auto"] = {Class = "Weapon", Type = "Pistol", Team = "Both"},
                ["USP-S"] = {Class = "Weapon", Type = "Pistol", Team = "Counter-Terrorists"},
                ["Glock-18"] = {Class = "Weapon", Type = "Pistol", Team = "Terrorists"},
                ["P250"] = {Class = "Weapon", Type = "Pistol", Team = "Both"},
                ["Five-SeveN"] = {Class = "Weapon", Type = "Pistol", Team = "Counter-Terrorists"},
                ["Tec-9"] = {Class = "Weapon", Type = "Pistol", Team = "Terrorists"},
                ["Desert Eagle"] = {Class = "Weapon", Type = "Pistol", Team = "Both"},
                ["Dual Berettas"] = {Class = "Weapon", Type = "Pistol", Team = "Both"},
                ["Zeus x27"] = {Class = "Weapon", Type = "Pistol", Team = "Both"},
                ["R8 Revolver"] = {Class = "Weapon", Type = "Pistol", Team = "Both"},
                ["AK-47"] = {Class = "Weapon", Type = "Rifle", Team = "Terrorists"},
                ["M4A4"] = {Class = "Weapon", Type = "Rifle", Team = "Counter-Terrorists"},
                ["M4A1-S"] = {Class = "Weapon", Type = "Rifle", Team = "Counter-Terrorists"},
                ["AWP"] = {Class = "Weapon", Type = "Rifle", Team = "Both"},
                ["FAMAS"] = {Class = "Weapon", Type = "Rifle", Team = "Counter-Terrorists"},
                ["Galil AR"] = {Class = "Weapon", Type = "Rifle", Team = "Terrorists"},
                ["SG 553"] = {Class = "Weapon", Type = "Rifle", Team = "Terrorists"},
                ["SSG 08"] = {Class = "Weapon", Type = "Rifle", Team = "Both"},
                ["AUG"] = {Class = "Weapon", Type = "Rifle", Team = "Counter-Terrorists"},
                ["MP9"] = {Class = "Weapon", Type = "SMG", Team = "Counter-Terrorists"},
                ["MAC-10"] = {Class = "Weapon", Type = "SMG", Team = "Terrorists"},
                ["P90"] = {Class = "Weapon", Type = "SMG", Team = "Both"},
                ["Negev"] = {Class = "Weapon", Type = "Heavy", Team = "Both"},
                ["Nova"] = {Class = "Weapon", Type = "Heavy", Team = "Both"},
                ["XM1014"] = {Class = "Weapon", Type = "Heavy", Team = "Both"},
                ["Sawed-Off"] = {Class = "Weapon", Type = "Heavy", Team = "Terrorists"},
                ["MAG-7"] = {Class = "Weapon", Type = "Heavy", Team = "Counter-Terrorists"},
                ["T Knife"] = {Class = "Melee", Type = "Equipment", Team = "Terrorists"},
                ["CT Knife"] = {Class = "Melee", Type = "Equipment", Team = "Counter-Terrorists"},
                ["Knife"] = {Class = "Melee", Type = "Equipment", Team = "Both"},
                ["Karambit"] = {Class = "Melee", Type = "Equipment", Team = "Both"},
                ["Butterfly Knife"] = {Class = "Melee", Type = "Equipment", Team = "Both"},
                ["M9 Bayonet"] = {Class = "Melee", Type = "Equipment", Team = "Both"},
                ["Stiletto Knife"] = {Class = "Melee", Type = "Equipment", Team = "Both"},
                ["Flip Knife"] = {Class = "Melee", Type = "Equipment", Team = "Both"},
                ["Skeleton Knife"] = {Class = "Melee", Type = "Equipment", Team = "Both"},
                ["Gut Knife"] = {Class = "Melee", Type = "Equipment", Team = "Both"},
                ["T Glove"] = {Class = "Glove", Type = "Equipment", Team = "Terrorists"},
                ["CT Glove"] = {Class = "Glove", Type = "Equipment", Team = "Counter-Terrorists"},
                ["Operator Gloves"] = {Class = "Glove", Type = "Equipment", Team = "Both"},
                ["Hand Wraps"] = {Class = "Glove", Type = "Equipment", Team = "Both"},
                ["Sports Gloves"] = {Class = "Glove", Type = "Equipment", Team = "Both"},
                ["Driver Gloves"] = {Class = "Glove", Type = "Equipment", Team = "Both"},
            }
            local customSkinsLookup = {}
            local function local_getWeaponProperties(weaponName)
                if typeof(weaponName) ~= "string" then return {Class = "Weapon", Type = "Pistol", Team = "Both"} end
                if state.OriginalGetWeaponProperties then
                    local ok, res = pcall(state.OriginalGetWeaponProperties, weaponName)
                    if ok and res then return res end
                end
                if customSkinsLookup and customSkinsLookup[weaponName] then
                    local item = customSkinsLookup[weaponName]
                    if item and item.Name then
                        weaponName = item.Name
                        if state.OriginalGetWeaponProperties then
                            local ok, res = pcall(state.OriginalGetWeaponProperties, weaponName)
                            if ok and res then return res end
                        end
                    end
                end
                if weaponTypes[weaponName] then return weaponTypes[weaponName] end
                local defaultProp = {Class = "Weapon", Type = "Pistol", Team = "Both"}
                if weaponName:find("Glove") or weaponName:find("Wraps") then
                    defaultProp = {Class = "Glove", Type = "Equipment", Team = "Both"}
                elseif weaponName:find("Knife") or weaponName == "Karambit" or weaponName:find("Bayonet") then
                    defaultProp = {Class = "Melee", Type = "Equipment", Team = "Both"}
                end
                return defaultProp
            end
            local skinsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Skins")
            if not skinsFolder then return end
            local customInventory = {}
            local cachedInventory = nil
            local defaultItems = {
                { Name = "T Knife", Type = "Melee", _id = "T Knife_Stock" },
                { Name = "CT Knife", Type = "Melee", _id = "CT Knife_Stock" },
                { Name = "Knife", Type = "Melee", _id = "Knife_Stock" },
                { Name = "T Glove", Type = "Glove", _id = "T Glove_Stock" },
                { Name = "CT Glove", Type = "Glove", _id = "CT Glove_Stock" },
                { Name = "Zeus x27", Type = "Weapon", _id = "Zeus x27_Stock" },
            }
            for _, item in defaultItems do
                local stockItem = {
                    Type = item.Type, Charm = false, IsTradeable = false,
                    MetaData = { LastTradeAt = 0, Origin = "Stock", TradeHistory = {}, Owner = localPlayer.UserId, OriginalOwner = localPlayer.UserId, CreatedAt = 0 },
                    Serial = 777, StatTrak = 0, Name = item.Name, Skin = "Stock", Float = 0.001, _id = item._id, NameTag = "", Stickers = {}
                }
                table.insert(customInventory, stockItem)
                customSkinsLookup[item._id] = stockItem
            end
            local function addSkinItem(weaponName, skinName)
                local itemType = "Weapon"
                if weaponName:find("Glove") or weaponName == "Operator Gloves" or weaponName:find("Wraps") then itemType = "Glove"
                elseif weaponName:find("Knife") or weaponName == "Karambit" or weaponName:find("Bayonet") then itemType = "Melee" end
                local customId = "custom_" .. weaponName:lower():gsub(" ", "_") .. "_" .. skinName:lower():gsub(" ", "_")
                if skinName == "Stock" then customId = weaponName .. "_Stock" end
                local newItem = {
                    Type = itemType, Charm = false, IsTradeable = false,
                    MetaData = { LastTradeAt = 0, Origin = "Stock", TradeHistory = {}, Owner = localPlayer.UserId, OriginalOwner = localPlayer.UserId, CreatedAt = 0 },
                    Serial = 777, StatTrak = 0, Name = weaponName, Skin = skinName, Float = 0.001, _id = customId, NameTag = "LO & ENI <3", Stickers = {}
                }
                table.insert(customInventory, newItem)
                customSkinsLookup[customId] = newItem
            end
            for _, weaponFolder in skinsFolder:GetChildren() do
                local weaponName = weaponFolder.Name
                for _, skinFolder in weaponFolder:GetChildren() do
                    local skinName = skinFolder.Name
                    addSkinItem(weaponName, skinName)
                end
            end
            state.CustomSkinsInventory = customInventory
            state.ClientEquippedOverrides = state.ClientEquippedOverrides or {
                ["Counter-Terrorists"] = { Loadout = {}, Equipped = {} },
                ["Terrorists"] = { Loadout = {}, Equipped = {} }
            }
            local function getLocalStockId(identifier, team)
                if identifier:sub(1, 7) ~= "custom_" then return identifier end
                local item = customSkinsLookup[identifier]
                if not item then return identifier end
                if item.Type == "Glove" then return team == "Counter-Terrorists" and "CT Glove_Stock" or "T Glove_Stock"
                elseif item.Type == "Melee" then return team == "Counter-Terrorists" and "CT Knife_Stock" or "T Knife_Stock"
                else return item.Name .. "_Stock" end
            end
            local originalApplyDelta = state.OriginalApplyInventoryDelta or DataController.ApplyInventoryDelta
            local local_ApplyInventoryDelta = debug.getupvalue(originalApplyDelta, 1)
            if not state.OriginalApplyInventoryDelta then state.OriginalApplyInventoryDelta = DataController.ApplyInventoryDelta end
            DataController.ApplyInventoryDelta = function(p1, p2, p3)
                cachedInventory = nil
                return state.OriginalApplyInventoryDelta(p1, p2, p3)
            end
            if not state.OriginalEquipLoadoutSkinSend then state.OriginalEquipLoadoutSkinSend = EquipLoadoutSkin.Send end
            EquipLoadoutSkin.Send = function(data)
                cachedInventory = nil
                local team = data.Team
                local category = data.Type
                local slot = data.Slot + 1
                local identifier = data.Identifier
                state.ClientEquippedOverrides[team] = state.ClientEquippedOverrides[team] or {}
                state.ClientEquippedOverrides[team].Loadout = state.ClientEquippedOverrides[team].Loadout or {}
                state.ClientEquippedOverrides[team].Loadout[category] = state.ClientEquippedOverrides[team].Loadout[category] or {}
                state.ClientEquippedOverrides[team].Loadout[category][slot] = identifier
                data.Identifier = getLocalStockId(identifier, team)
                local ExecuteListeners = debug.getupvalue(local_ApplyInventoryDelta, 4)
                setthreadidentity(2)
                ExecuteListeners(localPlayer, {"Loadout"})
                setthreadidentity(8)
                return state.OriginalEquipLoadoutSkinSend(data)
            end
            if not state.OriginalEquipSpecialItemSend then state.OriginalEquipSpecialItemSend = EquipSpecialItem.Send end
            EquipSpecialItem.Send = function(data)
                cachedInventory = nil
                local team = data.Team
                local path = data.Path
                local identifier = data.Identifier
                state.ClientEquippedOverrides[team] = state.ClientEquippedOverrides[team] or {}
                state.ClientEquippedOverrides[team].Equipped = state.ClientEquippedOverrides[team].Equipped or {}
                state.ClientEquippedOverrides[team].Equipped[path] = identifier
                data.Identifier = getLocalStockId(identifier, team)
                local ExecuteListeners = debug.getupvalue(local_ApplyInventoryDelta, 4)
                setthreadidentity(2)
                ExecuteListeners(localPlayer, {"Loadout"})
                setthreadidentity(8)
                return state.OriginalEquipSpecialItemSend(data)
            end
            if not state.OriginalSwapLoadoutSkinsSend then state.OriginalSwapLoadoutSkinsSend = SwapLoadoutSkins.Send end
            SwapLoadoutSkins.Send = function(data)
                cachedInventory = nil
                local team = data.Team
                local category = data.Type
                local slotOne = data.SlotOne + 1
                local slotTwo = data.SlotTwo + 1
                state.ClientEquippedOverrides[team] = state.ClientEquippedOverrides[team] or {}
                state.ClientEquippedOverrides[team].Loadout = state.ClientEquippedOverrides[team].Loadout or {}
                state.ClientEquippedOverrides[team].Loadout[category] = state.ClientEquippedOverrides[team].Loadout[category] or {}
                local currentLoadout = state.OriginalDataControllerGet(localPlayer, "Loadout")
                local val1 = currentLoadout[team].Loadout[category].Options[slotOne]
                local val2 = currentLoadout[team].Loadout[category].Options[slotTwo]
                if state.ClientEquippedOverrides[team].Loadout[category][slotOne] then val1 = state.ClientEquippedOverrides[team].Loadout[category][slotOne] end
                if state.ClientEquippedOverrides[team].Loadout[category][slotTwo] then val2 = state.ClientEquippedOverrides[team].Loadout[category][slotTwo] end
                state.ClientEquippedOverrides[team].Loadout[category][slotOne] = val2
                state.ClientEquippedOverrides[team].Loadout[category][slotTwo] = val1
                local ExecuteListeners = debug.getupvalue(local_ApplyInventoryDelta, 4)
                setthreadidentity(2)
                ExecuteListeners(localPlayer, {"Loadout"})
                setthreadidentity(8)
                return state.OriginalSwapLoadoutSkinsSend(data)
            end
            local t2 = debug.getupvalue(local_ApplyInventoryDelta, 1)
            if not state.OriginalDataControllerGet then state.OriginalDataControllerGet = DataController.Get end
            DataController.Get = function(player, ...)
                local keys = table.pack(...)
                if player == localPlayer then
                    local profile = t2[localPlayer]
                    if profile and typeof(profile.Loadout) == "table" then
                        for team, teamOverrides in state.ClientEquippedOverrides or {} do
                            local teamData = profile.Loadout[team]
                            if teamData then
                                if teamOverrides.Loadout and typeof(teamData.Loadout) == "table" then
                                    for category, categoryOverrides in teamOverrides.Loadout do
                                        local catData = teamData.Loadout[category]
                                        if catData and typeof(catData.Options) == "table" then
                                            for optIdx, identifier in categoryOverrides do catData.Options[optIdx] = identifier end
                                        end
                                    end
                                end
                                if teamOverrides.Equipped and typeof(teamData.Equipped) == "table" then
                                    for path, identifier in teamOverrides.Equipped do teamData.Equipped[path] = identifier end
                                end
                            end
                        end
                    end
                end
                local results = table.pack(state.OriginalDataControllerGet(player, table.unpack(keys, 1, keys.n)))
                if player == localPlayer then
                    for idx, key in keys do
                        if key == "Inventory" then
                            if cachedInventory then results[idx] = cachedInventory
                            else
                                local val = results[idx]
                                local merged = {}
                                if typeof(val) == "table" then for _, item in val do table.insert(merged, item) end end
                                for _, item in state.CustomSkinsInventory do table.insert(merged, item) end
                                cachedInventory = merged
                                results[idx] = merged
                            end
                        end
                    end
                end
                return table.unpack(results, 1, results.n)
            end
            local function getEquippedSkinForWeapon(weaponName)
            local ok, result = pcall(function()
                local profile = t2[localPlayer]
                if not profile then return nil end
                local team = localPlayer:GetAttribute("Team") or "Terrorists"
                if team == "Spectators" or team == "" then team = "Terrorists" end
                local teamData = DataController.Get(localPlayer, "Loadout")
                if not teamData or not teamData[team] then return nil end
                local activeTeamData = teamData[team]
                if weaponName == "T Knife" or weaponName == "CT Knife" or weaponName == "Knife" or weaponName == "Karambit" then
                    local meleeId = activeTeamData.Equipped and activeTeamData.Equipped["Equipped Melee"]
                    if meleeId and customSkinsLookup[meleeId] then
                        return customSkinsLookup[meleeId]
                    end
                end
                if weaponName == "Operator Gloves" or weaponName:find("Glove") then
                    local gloveId = activeTeamData.Equipped and activeTeamData.Equipped["Equipped Gloves"]
                    if gloveId and customSkinsLookup[gloveId] then
                        return customSkinsLookup[gloveId]
                    end
                end
                if activeTeamData.Loadout then
                    for category, catData in activeTeamData.Loadout do
                        if typeof(catData) == "table" and catData.Options then
                            for _, optionId in catData.Options do
                                if optionId and customSkinsLookup[optionId] then
                                    local item = customSkinsLookup[optionId]
                                    local cleanItemName = item.Name:lower():gsub(" ", ""):gsub("-", "")
                                    local cleanWeaponName = weaponName:lower():gsub(" ", ""):gsub("-", "")
                                    if cleanItemName == cleanWeaponName then
                                        return item
                                    end
                                end
                            end
                        end
                    end
                end
                return nil
            end)
            if ok then return result end
            return nil
        end
            if not state.OriginalWeaponComponentNew then state.OriginalWeaponComponentNew = WeaponComponent.new end
            WeaponComponent.new = function(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12)
                if p1 == localPlayer then
                    local custom = getEquippedSkinForWeapon(p5)
                    if custom then
                        p5 = custom.Name or p5
                        p6 = custom.Skin or p6
                        p7 = custom.Float or 0.001
                        p8 = custom.StatTrack or 0
                        p9 = custom.NameTag or p9
                    end
                end
                return state.OriginalWeaponComponentNew(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12)
            end
            if not state.OriginalAddAttachments then state.OriginalAddAttachments = Viewmodel.addAttachments end
            Viewmodel.addAttachments = function(self, p2)
                if self.Player == localPlayer then
                    local custom = getEquippedSkinForWeapon("Operator Gloves")
                    if custom then
                        p2 = { SkinIdentifier = custom._id, Name = custom.Name, Skin = custom.Skin, Float = custom.Float or 0.001 }
                    end
                end
                return state.OriginalAddAttachments(self, p2)
            end
            local CreateWeaponModel = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("Observers"):WaitForChild("Players"):WaitForChild("Components"):WaitForChild("CreateWeaponModel"))
            local mt = getmetatable(CreateWeaponModel)
            if mt and mt.__call then
                local f3 = debug.getupvalue(mt.__call, 1)
                if f3 then
                    local original_CreateEquippedWeapon = debug.getupvalue(f3, 1)
                    local original_CreateCharacterWeapons = debug.getupvalue(f3, 2)
                    local hook_CreateEquippedWeapon = function(p1, p2, p3)
                        if p1 == localPlayer and typeof(p3) == "table" then
                            local ok, res = pcall(function()
                                local cloneP3 = table.clone(p3)
                                local custom = getEquippedSkinForWeapon(cloneP3.Name)
                                if custom then
                                    cloneP3.Name = custom.Name or cloneP3.Name
                                    cloneP3.Skin = custom.Skin or cloneP3.Skin
                                    cloneP3.Float = custom.Float or 0.001
                                    cloneP3.StatTrack = custom.StatTrack or 0
                                    cloneP3.NameTag = custom.NameTag or cloneP3.NameTag
                                end
                                return original_CreateEquippedWeapon(p1, p2, cloneP3)
                            end)
                            if ok and res then return res end
                        end
                        return original_CreateEquippedWeapon(p1, p2, p3)
                    end
                    local hook_CreateCharacterWeapons = function(p1, p2, p3, p4)
                        if p1 == localPlayer and typeof(p4) == "table" then
                            local ok, res = pcall(function()
                                local cloneP4 = table.clone(p4)
                                for idx, item in cloneP4 do
                                    if typeof(item) == "table" and item.Weapon then
                                        local custom = getEquippedSkinForWeapon(item.Weapon)
                                        if custom then
                                            local newItem = table.clone(item)
                                            newItem.Weapon = custom.Name or item.Weapon
                                            newItem.Skin = custom.Skin or item.Skin
                                            newItem.Float = custom.Float or 0.001
                                            newItem.StatTrack = custom.StatTrack or 0
                                            newItem.NameTag = custom.NameTag or item.NameTag
                                            cloneP4[idx] = newItem
                                        end
                                    end
                                end
                                return original_CreateCharacterWeapons(p1, p2, p3, cloneP4)
                            end)
                            if ok and res then return res end
                        end
                        return original_CreateCharacterWeapons(p1, p2, p3, p4)
                    end
                    debug.setupvalue(f3, 1, hook_CreateEquippedWeapon)
                    debug.setupvalue(f3, 2, hook_CreateCharacterWeapons)
                end
            end
            local function hookModuleFunctions(moduleTable)
                local scanned = {}
                local function scan(func)
                    if typeof(func) ~= "function" then return end
                    if scanned[func] then return end
                    scanned[func] = true
                    local i = 1
                    while true do
                        local s, val = pcall(debug.getupvalue, func, i)
                        if not s then break end
                        if typeof(val) == "function" then
                            local okInfo, info = pcall(debug.getinfo, val)
                            if okInfo and info and info.source:find("Components.Common.GetWeaponProperties$") then
                                state.OriginalGetWeaponProperties = state.OriginalGetWeaponProperties or val
                                debug.setupvalue(func, i, local_getWeaponProperties)
                            else scan(val) end
                        elseif typeof(val) == "table" then
                            pcall(function()
                                for _, subVal in val do
                                    if typeof(subVal) == "function" then scan(subVal) end
                                end
                            end)
                        end
                        i = i + 1
                    end
                end
                for _, v in moduleTable do
                    if typeof(v) == "function" then scan(v) end
                end
            end
            local LoadoutUI = require(ReplicatedStorage:WaitForChild("Interface"):WaitForChild("Screens"):WaitForChild("Menu"):WaitForChild("Loadout"))
            local InventoryUI = require(ReplicatedStorage:WaitForChild("Interface"):WaitForChild("Screens"):WaitForChild("Menu"):WaitForChild("Inventory"))
            local LoadoutClass = require(ReplicatedStorage:WaitForChild("Classes"):WaitForChild("Loadout"))
            hookModuleFunctions(LoadoutUI)
            hookModuleFunctions(InventoryUI)
            hookModuleFunctions(LoadoutClass)
            local ExecuteListeners = debug.getupvalue(local_ApplyInventoryDelta, 4)
            setthreadidentity(2)
            ExecuteListeners(localPlayer, {"Loadout"})
            setthreadidentity(8)
        end)
    end
    state.unlock_inventory = unlock_inventory

    local ServerSection = MiscTab:CreateSection({
        Name = "Misc",
        Side = "Right"
    })
    ServerSection:CreateButton({
        Name = "Unlock All Skins",
        Callback = function()
            local s, err = pcall(unlock_inventory)
            if s then
                Library:Notify("Unlocked All Skins!", 3)
            else
                Library:Notify("Unlock Error: " .. tostring(err), 3)
            end
        end
    })
    local AntiBarriersEnabled = false
    local barrierCache = {}
    local barrierAddedConn = nil
    local function disableBarrier(part)
        if part:IsA("BasePart") then
            local nameLower = part.Name:lower()
            local isBarrier = nameLower:find("barrier") or nameLower:find("clip") or (part.Transparency == 1 and part.CanCollide and part.Anchored)
            if isBarrier and not part:FindFirstChild("BarrierCachedVal") then
                local tag = Instance.new("BoolValue")
                tag.Name = "BarrierCachedVal"
                tag.Parent = part
                table.insert(barrierCache, {part = part, trans = part.Transparency, collide = part.CanCollide, color = part.Color, mat = part.Material})
                part.CanCollide = false
                part.Transparency = 1
                part.Color = Color3.fromRGB(255, 0, 0)
                part.Material = Enum.Material.Neon
            end
        end
    end
    ServerSection:CreateToggle({
        Name = "Anti Barriers(dont stay too long there)",
        Default = false,
        Callback = function(state)
            AntiBarriersEnabled = state
            if state then
                for _, part in workspace:GetDescendants() do
                    disableBarrier(part)
                end
                barrierAddedConn = workspace.DescendantAdded:Connect(function(descendant)
                    task.wait(0.1)
                    if AntiBarriersEnabled then
                        disableBarrier(descendant)
                    end
                end)
            else
                if barrierAddedConn then
                    barrierAddedConn:Disconnect()
                    barrierAddedConn = nil
                end
                for _, data in barrierCache do
                    if data.part and data.part.Parent then
                        data.part.CanCollide = data.collide
                        data.part.Transparency = data.trans
                        data.part.Color = data.color
                        data.part.Material = data.mat
                        local tag = data.part:FindFirstChild("BarrierCachedVal")
                        if tag then tag:Destroy() end
                    end
                end
                table.clear(barrierCache)
            end
        end
    })
    ServerSection:CreateToggle({
        Name = "Name Spoofer",
        Default = false,
        Callback = function(state) AimbotSettings.NameSpoofer = state end
    })
    ServerSection:CreateTextbox({
        Name = "Spoofed Name",
        Default = "Spoofed",
        PlaceholderText = "Enter spoofed name...",
        RemoveTextAfterFocusLost = false,
        Callback = function(val) AimbotSettings.SpoofedName = val end
    })
    local HiddenGuis = {}
    ServerSection:CreateToggle({
        Name = "Hide HUD",
        Default = false,
        Callback = function(state)
            local StarterGui = game:GetService("StarterGui")
            local lp = game:GetService("Players").LocalPlayer
            if lp and lp:FindFirstChild("PlayerGui") then
                if state then
                    local safeGuis = {}
                    for _, gui in lp.PlayerGui:GetDescendants() do
                        local gName = string.lower(gui.Name)
                        if string.find(gName, "crosshair") or string.find(gName, "killfeed") or string.find(gName, "scope") or string.find(gName, "menu") or string.find(gName, "gui") or string.find(gName, "viewport") or string.find(gName, "clarity") then
                            safeGuis[gui] = true
                            for _, desc in gui:GetDescendants() do
                                safeGuis[desc] = true
                            end
                            local curr = gui.Parent
                            while curr and curr ~= lp.PlayerGui do
                                safeGuis[curr] = true
                                curr = curr.Parent
                            end
                        end
                    end
                    for _, gui in lp.PlayerGui:GetChildren() do
                        if gui:IsA("ScreenGui") then
                            if not safeGuis[gui] and gui.Enabled then
                                table.insert(HiddenGuis, gui)
                                gui.Enabled = false
                            elseif safeGuis[gui] then
                                for _, desc in gui:GetDescendants() do
                                    if desc:IsA("GuiObject") and desc.Visible and not safeGuis[desc] then
                                        table.insert(HiddenGuis, desc)
                                        desc.Visible = false
                                    end
                                end
                            end
                        end
                    end
                else
                    for _, gui in HiddenGuis do
                        if gui and gui.Parent then
                            if gui:IsA("ScreenGui") then
                                gui.Enabled = true
                            elseif gui:IsA("GuiObject") then
                                gui.Visible = true
                            end
                        end
                    end
                    table.clear(HiddenGuis)
                end
            end
        end
    })
    local function encodeValue(v)
        local t = typeof(v)
        if t == "Color3" then
            return { _type = "Color3", R = v.R, G = v.G, B = v.B }
        elseif t == "Vector3" then
            return { _type = "Vector3", X = v.X, Y = v.Y, Z = v.Z }
        elseif t == "EnumItem" then
            return { _type = "EnumItem", EnumType = tostring(v.EnumType), Value = v.Value }
        elseif t == "table" then
            local res = {}
            for k, val in v do
                res[k] = encodeValue(val)
            end
            return res
        end
        return v
    end
    local function decodeValue(v)
        if type(v) == "table" then
            if v._type == "Color3" then
                return Color3.new(v.R, v.G, v.B)
            elseif v._type == "Vector3" then
                return Vector3.new(v.X, v.Y, v.Z)
            elseif v._type == "EnumItem" then
                local enumSplit = string.split(v.EnumType, ".")
                local enumTypeStr = enumSplit[#enumSplit]
                if Enum[enumTypeStr] then
                    for _, enumItem in (Enum[enumTypeStr]:GetEnumItems()) do
                        if enumItem.Value == v.Value then return enumItem end
                    end
                end
                return nil
            else
                local res = {}
                for k, val in v do
                    res[k] = decodeValue(val)
                end
                return res
            end
        end
        return v
    end
    local MenuSection = ConfigTab:CreateSection({
        Name = "Menu",
        Side = "Right"
    })
    local wm_CoreGui = game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")
    local LMG2L_ScreenGui_1 = Instance.new("ScreenGui")
    LMG2L_ScreenGui_1.Name = "claritywm_Screen"
    LMG2L_ScreenGui_1.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() LMG2L_ScreenGui_1.Parent = wm_CoreGui end)
    local LMG2L_claritywm_2
    local FPS_Label = nil
    if GuiTheme == 1 then
        LMG2L_claritywm_2 = Instance.new("Frame", LMG2L_ScreenGui_1)
        LMG2L_claritywm_2.Name = "clarity_wm"
        LMG2L_claritywm_2.ZIndex = 2
        LMG2L_claritywm_2.BorderSizePixel = 0
        LMG2L_claritywm_2.BackgroundColor3 = Theme.SectionBg
        LMG2L_claritywm_2.ClipsDescendants = true
        LMG2L_claritywm_2.Size = UDim2.new(0, 153, 0, 29)
        LMG2L_claritywm_2.Position = UDim2.new(1, -163, 0, -49)
        LMG2L_claritywm_2.BackgroundTransparency = 0.35
        LMG2L_claritywm_2.Active = true
        local Frame_3 = Instance.new("Frame", LMG2L_claritywm_2)
        Frame_3.BorderSizePixel = 0
        Frame_3.BackgroundColor3 = Theme.SectionBg
        Frame_3.ClipsDescendants = true
        Frame_3.Size = UDim2.new(0, 148, 0, 24)
        Frame_3.Position = UDim2.new(0, 3, 0, 3)
        Instance.new("UICorner", Frame_3).CornerRadius = UDim.new(0, 4)
        local uis = Instance.new("UIStroke", Frame_3)
        uis.Thickness = 1.2
        local ImageLabel_6 = Instance.new("ImageLabel", Frame_3)
        ImageLabel_6.Active = true
        ImageLabel_6.ZIndex = -1
        ImageLabel_6.ImageTransparency = 0.7
        ImageLabel_6.ImageColor3 = Theme.ToggleActive
        ImageLabel_6.Image = "rbxassetid://13875972589"
        ImageLabel_6.Size = UDim2.new(0, 64, 0, 60)
        ImageLabel_6.ClipsDescendants = true
        ImageLabel_6.BackgroundTransparency = 1
        ImageLabel_6.Position = UDim2.new(0, -12, 0, -12)
        local accentlabel_7 = Instance.new("TextLabel", Frame_3)
        accentlabel_7.BorderSizePixel = 0
        accentlabel_7.TextSize = 18
        accentlabel_7.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        accentlabel_7.TextColor3 = Theme.ToggleActive
        accentlabel_7.BackgroundTransparency = 1
        accentlabel_7.Size = UDim2.new(0, 60, 0, 28)
        accentlabel_7.Text = "clarity"
        accentlabel_7.Position = UDim2.new(0, -4, 0, -2)
        local nicknamelable_8 = Instance.new("TextLabel", Frame_3)
        nicknamelable_8.BorderSizePixel = 0
        nicknamelable_8.TextSize = 17
        nicknamelable_8.TextXAlignment = Enum.TextXAlignment.Left
        nicknamelable_8.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        nicknamelable_8.TextColor3 = Color3.fromRGB(125, 125, 125)
        nicknamelable_8.BackgroundTransparency = 1
        nicknamelable_8.Size = UDim2.new(0, 34, 0, 28)
        nicknamelable_8.Text = "user"
        nicknamelable_8.Position = UDim2.new(0, 57, 0, -2)
        local numberfpslabel_9 = Instance.new("TextLabel", Frame_3)
        numberfpslabel_9.BorderSizePixel = 0
        numberfpslabel_9.TextSize = 18
        numberfpslabel_9.TextXAlignment = Enum.TextXAlignment.Left
        numberfpslabel_9.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        numberfpslabel_9.TextColor3 = Color3.fromRGB(125, 125, 125)
        numberfpslabel_9.BackgroundTransparency = 1
        numberfpslabel_9.Size = UDim2.new(0, 60, 0, 28)
        numberfpslabel_9.Text = "fps"
        numberfpslabel_9.Position = UDim2.new(0, 120, 0, -2)
        local Frame_a = Instance.new("Frame", Frame_3)
        Frame_a.BorderSizePixel = 0
        Frame_a.BackgroundColor3 = Color3.fromRGB(69, 69, 69)
        Frame_a.Size = UDim2.new(0, 1, 0, 17)
        Frame_a.Position = UDim2.new(0, 52, 0, 4)
        local Frame_b = Instance.new("Frame", Frame_3)
        Frame_b.BorderSizePixel = 0
        Frame_b.BackgroundColor3 = Color3.fromRGB(69, 69, 69)
        Frame_b.Size = UDim2.new(0, 1, 0, 17)
        Frame_b.Position = UDim2.new(0, 88, 0, 4)
        FPS_Label = Instance.new("TextLabel", Frame_3)
        FPS_Label.BorderSizePixel = 0
        FPS_Label.TextSize = 18
        FPS_Label.TextXAlignment = Enum.TextXAlignment.Left
        FPS_Label.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        FPS_Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        FPS_Label.BackgroundTransparency = 1
        FPS_Label.Size = UDim2.new(0, 60, 0, 28)
        FPS_Label.Text = "111"
        FPS_Label.Position = UDim2.new(0, 92, 0, -2)
        Instance.new("UICorner", LMG2L_claritywm_2).CornerRadius = UDim.new(0, 5)
        local uis2 = Instance.new("UIStroke", LMG2L_claritywm_2)
        uis2.Thickness = 0.7
        table.insert(AccentUpdates, function(col)
            ImageLabel_6.ImageColor3 = col
            accentlabel_7.TextColor3 = col
        end)
    else
        LMG2L_claritywm_2 = Instance.new("TextBox", LMG2L_ScreenGui_1)
        LMG2L_claritywm_2.Name = "claritywm"
        LMG2L_claritywm_2.BorderSizePixel = 0
        LMG2L_claritywm_2.TextSize = 24
        LMG2L_claritywm_2.TextColor3 = Color3.fromRGB(255, 255, 255)
        LMG2L_claritywm_2.BackgroundColor3 = Color3.fromRGB(21, 21, 21)
        LMG2L_claritywm_2.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        LMG2L_claritywm_2.Size = UDim2.new(0, 100, 0, 28)
        LMG2L_claritywm_2.Position = UDim2.new(1, -110, 0, -49)
        LMG2L_claritywm_2.BorderColor3 = Color3.fromRGB(255, 255, 255)
        LMG2L_claritywm_2.Text = "kamibebra"
        LMG2L_claritywm_2.ClearTextOnFocus = false
        local LMG2L_UICorner_3 = Instance.new("UICorner", LMG2L_claritywm_2)
        LMG2L_UICorner_3.CornerRadius = UDim.new(0, 4)
    end
    local customFont
    do
        local folderName = "fonts"
        local fontFileName = folderName .. "/verdanabold.ttf"
        local jsonFileName = folderName .. "/verdanabold.json"
        local fontUrl = "https://raw.githubusercontent.com/artersurf-glitch/verdanafontroblox/main/Verdana%20Bold.ttf"
        if not isfolder(folderName) then makefolder(folderName) end
        local req = (request or http and http.request or http_request or syn and syn.request)
        if not isfile(fontFileName) then
            local response = req({Url = fontUrl, Method = "GET"})
            if response and response.Body then writefile(fontFileName, response.Body) end
        end
        local ttfAsset = getcustomasset(fontFileName)
        local fontJson = [[{
            "name": "VerdanaBold",
            "faces": [{
                "name": "Bold",
                "weight": 400,
                "style": "normal",
                "assetId": "]] .. ttfAsset .. [["
            }]
        }]]
        writefile(jsonFileName, fontJson)
        local jsonAsset = getcustomasset(jsonFileName)
        customFont = Font.new(jsonAsset, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    end
    local Ind_Speed = Instance.new("TextLabel", LMG2L_ScreenGui_1)
    Ind_Speed.Name = "speed"
    Ind_Speed.TextStrokeTransparency = 0
    Ind_Speed.BorderSizePixel = 0
    Ind_Speed.TextSize = 32
    Ind_Speed.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Ind_Speed.FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Ind_Speed.TextColor3 = Color3.fromRGB(255, 255, 255)
    Ind_Speed.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    Ind_Speed.BackgroundTransparency = 1
    Ind_Speed.Size = UDim2.new(0, 182, 0, 26)
    Ind_Speed.Position = UDim2.new(0.5, -91, 0, 590)
    Ind_Speed.Text = "250"
    Ind_Speed.Visible = false
    Ind_Speed.RichText = true
    local Ind_Binds = Instance.new("TextLabel", LMG2L_ScreenGui_1)
    Ind_Binds.Name = "indicators"
    Ind_Binds.TextStrokeTransparency = 0
    Ind_Binds.BorderSizePixel = 0
    Ind_Binds.TextSize = 28
    Ind_Binds.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Ind_Binds.FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Ind_Binds.TextColor3 = Color3.fromRGB(255, 255, 255)
    Ind_Binds.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    Ind_Binds.BackgroundTransparency = 1
    Ind_Binds.Size = UDim2.new(0, 140, 0, 32)
    Ind_Binds.Position = UDim2.new(0.5, -70, 0, 630)
    Ind_Binds.Text = ""
    Ind_Binds.Visible = false
    local wasInAir = false
    local lastJumpSpeed = 0
    local lastJumpTime = 0
    local lastFpsTick = tick()
    RunService.RenderStepped:Connect(function(deltaTime)
        if FPS_Label then
            FPS_Label.Text = tostring(math.floor(1 / deltaTime))
        end
        if SpeedIndicatorEnabled then
            Ind_Speed.Visible = true
            Ind_Speed.Position = UDim2.new(0.5, -91, 0, SpeedInd_Y)
            Ind_Speed.TextSize = SpeedInd_Size
            Ind_Speed.TextColor3 = SpeedInd_Color
            Ind_Speed.TextStrokeColor3 = SpeedInd_Outline
            if SpeedInd_Font == "VerdanaBold" then
                Ind_Speed.FontFace = customFont
            else
                Ind_Speed.FontFace = Font.new("rbxasset://fonts/families/" .. SpeedInd_Font .. ".json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            end
            local lp = Players.LocalPlayer
            if lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                local vel = lp.Character.HumanoidRootPart.AssemblyLinearVelocity
                local speed = math.floor((Vector3.new(vel.X, 0, vel.Z).Magnitude) * 15.625)
                local hum = lp.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    local inAir = (hum:GetState() == Enum.HumanoidStateType.Freefall or hum:GetState() == Enum.HumanoidStateType.Jumping)
                    if inAir and not wasInAir then
                        lastJumpSpeed = speed
                        lastJumpTime = tick()
                    end
                    wasInAir = inAir
                end
                local displayText = tostring(speed)
                if SpeedInd_ShowLastSpeed and tick() - lastJumpTime <= 3 and lastJumpSpeed > 0 then
                    local r = math.floor(SpeedInd_LastSpeedColor.R * 255)
                    local g = math.floor(SpeedInd_LastSpeedColor.G * 255)
                    local b = math.floor(SpeedInd_LastSpeedColor.B * 255)
                    displayText = tostring(speed) .. string.format(' <font color="rgb(%d,%d,%d)">(%d)</font>', r, g, b, lastJumpSpeed)
                end
                Ind_Speed.Text = displayText
            else
                Ind_Speed.Text = "0"
                wasInAir = false
            end
        else
            Ind_Speed.Visible = false
        end
        if BindIndicatorEnabled then
            Ind_Binds.Visible = true
            Ind_Binds.Position = UDim2.new(0.5, -70, 0, BindInd_Y)
            Ind_Binds.TextSize = BindInd_Size
            Ind_Binds.TextColor3 = BindInd_Color
            Ind_Binds.TextStrokeColor3 = BindInd_Outline
            if BindInd_Font == "VerdanaBold" then
                Ind_Binds.FontFace = customFont
            else
                Ind_Binds.FontFace = Font.new("rbxasset://fonts/families/" .. BindInd_Font .. ".json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            end
            local activeBinds = {}
            if AutoEdgebug and BindIndicatorSelection["eb"] then table.insert(activeBinds, "eb") end
            if AutoJumpbug and BindIndicatorSelection["jb"] then table.insert(activeBinds, "jb") end
            if AutoLongjump and BindIndicatorSelection["lj"] then table.insert(activeBinds, "lj") end
            if AutoMinijump and BindIndicatorSelection["mj"] then table.insert(activeBinds, "mj") end
            if AutoPixelsurf and BindIndicatorSelection["ps"] then table.insert(activeBinds, "ps") end
            if AutoTexturebug and BindIndicatorSelection["tb"] then table.insert(activeBinds, "tb") end
            if AutoWallstuck and BindIndicatorSelection["ws"] then table.insert(activeBinds, "ws") end
            if AutoWallclimb and BindIndicatorSelection["wc"] then table.insert(activeBinds, "wc") end
            Ind_Binds.Text = table.concat(activeBinds, " ")
        else
            Ind_Binds.Visible = false
        end
    end)
    MenuSection:CreateToggle({
        Name = "Enable Watermark",
        Default = true,
        Callback = function(state)
            LMG2L_claritywm_2.Visible = state
        end
    })
    local wm_dragging, wm_dragInput, wm_dragStart, wm_startPos
    LMG2L_claritywm_2.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mainGui = wm_CoreGui:FindFirstChild("LocalMazeGUI")
            if mainGui and mainGui.Enabled then
                wm_dragging = true
                wm_dragStart = input.Position
                wm_startPos = LMG2L_claritywm_2.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        wm_dragging = false
                    end
                end)
            end
        end
    end)
    LMG2L_claritywm_2.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            wm_dragInput = input
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == wm_dragInput and wm_dragging then
            local delta = input.Position - wm_dragStart
            LMG2L_claritywm_2.Position = UDim2.new(wm_startPos.X.Scale, wm_startPos.X.Offset + delta.X, wm_startPos.Y.Scale, wm_startPos.Y.Offset + delta.Y)
        end
    end)
    local Spec_Frame = Instance.new("Frame", LMG2L_ScreenGui_1)
    Spec_Frame.Name = "SpectatorList"
    Spec_Frame.BorderSizePixel = 0
    Spec_Frame.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    Spec_Frame.Size = UDim2.new(0, 240, 0, 66)
    Spec_Frame.Position = UDim2.new(0, 12, 0, 316)
    Spec_Frame.Visible = false
    local Spec_UICorner = Instance.new("UICorner", Spec_Frame)
    local Spec_Title = Instance.new("TextLabel", Spec_Frame)
    Spec_Title.BorderSizePixel = 0
    Spec_Title.TextSize = 28
    Spec_Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Spec_Title.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Spec_Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Spec_Title.BackgroundTransparency = 1
    Spec_Title.Size = UDim2.new(0, 154, 0, 26)
    Spec_Title.Text = "Spectators"
    Spec_Title.Position = UDim2.new(0, 42, 0, 6)
    local Spec_Template = Instance.new("TextLabel")
    Spec_Template.BorderSizePixel = 0
    Spec_Template.TextSize = 24
    Spec_Template.TextXAlignment = Enum.TextXAlignment.Left
    Spec_Template.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Spec_Template.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Spec_Template.TextColor3 = Color3.fromRGB(98, 98, 98)
    Spec_Template.BackgroundTransparency = 1
    Spec_Template.Size = UDim2.new(0, 228, 0, 28)
    Spec_Template.Text = "player1 -> you"
    Spec_Template.Position = UDim2.new(0, 6, 0, 34)
    local spec_dragging, spec_dragInput, spec_dragStart, spec_startPos
    Spec_Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mainGui = wm_CoreGui:FindFirstChild("LocalMazeGUI")
            if mainGui and mainGui.Enabled then
                spec_dragging = true
                spec_dragStart = input.Position
                spec_startPos = Spec_Frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        spec_dragging = false
                    end
                end)
            end
        end
    end)
    Spec_Frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            spec_dragInput = input
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == spec_dragInput and spec_dragging then
            local delta = input.Position - spec_dragStart
            Spec_Frame.Position = UDim2.new(spec_startPos.X.Scale, spec_startPos.X.Offset + delta.X, spec_startPos.Y.Scale, spec_startPos.Y.Offset + delta.Y)
        end
    end)
    local Keybind_Frame = Instance.new("Frame", LMG2L_ScreenGui_1)
    Keybind_Frame.Name = "KeybindList"
    Keybind_Frame.BorderSizePixel = 0
    Keybind_Frame.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    Keybind_Frame.Size = UDim2.new(0, 240, 0, 66)
    Keybind_Frame.Position = UDim2.new(0, 12, 0, 400)
    Keybind_Frame.Visible = false
    local Keybind_UICorner = Instance.new("UICorner", Keybind_Frame)
    local Keybind_Title = Instance.new("TextLabel", Keybind_Frame)
    Keybind_Title.BorderSizePixel = 0
    Keybind_Title.TextSize = 28
    Keybind_Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Keybind_Title.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Keybind_Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Keybind_Title.BackgroundTransparency = 1
    Keybind_Title.Size = UDim2.new(0, 154, 0, 26)
    Keybind_Title.Text = "Keybinds"
    Keybind_Title.Position = UDim2.new(0, 42, 0, 6)
    local kb_dragging, kb_dragInput, kb_dragStart, kb_startPos
    Keybind_Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mainGui = wm_CoreGui:FindFirstChild("LocalMazeGUI")
            if mainGui and mainGui.Enabled then
                kb_dragging = true
                kb_dragStart = input.Position
                kb_startPos = Keybind_Frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        kb_dragging = false
                    end
                end)
            end
        end
    end)
    Keybind_Frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            kb_dragInput = input
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == kb_dragInput and kb_dragging then
            local delta = input.Position - kb_dragStart
            Keybind_Frame.Position = UDim2.new(kb_startPos.X.Scale, kb_startPos.X.Offset + delta.X, kb_startPos.Y.Scale, kb_startPos.Y.Offset + delta.Y)
        end
    end)
    task.spawn(function()
        while task.wait(0.5) do
            if WidgetsEnabled and ActiveWidgets["Spectator List"] then
                local scale = Spec_Scale / 100
                Spec_Frame.Visible = true
                Spec_Title.TextColor3 = Spec_TitleColor
                Spec_Title.FontFace = Font.new("rbxasset://fonts/families/" .. Spec_Font .. ".json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Spec_Title.TextSize = 28 * scale
                Spec_Title.Size = UDim2.new(0, 154 * scale, 0, 26 * scale)
                Spec_Title.Position = UDim2.new(0, 42 * scale, 0, 6 * scale)
                local spectators = {}
                for _, p in (game:GetService("Players"):GetPlayers()) do
                    if p ~= game:GetService("Players").LocalPlayer then
                        if p.Character == nil or not p.Character:FindFirstChild("HumanoidRootPart") then
                            table.insert(spectators, p.Name)
                        end
                    end
                end
                for _, child in Spec_Frame:GetChildren() do
                    if child:IsA("TextLabel") and child.Name == "PlayerEntry" then
                        child:Destroy()
                    end
                end
                local yOffset = 34 * scale
                for _, spec in spectators do
                    local label = Spec_Template:Clone()
                    label.Name = "PlayerEntry"
                    label.Text = spec .. " -> you"
                    label.TextColor3 = Spec_PlayersColor
                    label.TextSize = 24 * scale
                    label.Size = UDim2.new(0, 228 * scale, 0, 28 * scale)
                    label.FontFace = Font.new("rbxasset://fonts/families/" .. Spec_Font .. ".json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                    label.Position = UDim2.new(0, 6 * scale, 0, yOffset)
                    label.Parent = Spec_Frame
                    yOffset = yOffset + 28 * scale
                end
                Spec_Frame.Size = UDim2.new(0, 240 * scale, 0, math.max(66 * scale, yOffset + 6 * scale))
            else
                Spec_Frame.Visible = false
            end
            if WidgetsEnabled and ActiveWidgets["Keybinds"] then
                local scale = KB_Scale / 100
                Keybind_Frame.Visible = true
                Keybind_Title.TextColor3 = KB_TitleColor
                Keybind_Title.FontFace = Font.new("rbxasset://fonts/families/" .. KB_Font .. ".json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Keybind_Title.TextSize = 28 * scale
                Keybind_Title.Size = UDim2.new(0, 154 * scale, 0, 26 * scale)
                Keybind_Title.Position = UDim2.new(0, 42 * scale, 0, 6 * scale)
                local activeBinds = {}
                for _, bind in Library.KeybindRegistry do
                    local state = bind.getState()
                    local key = bind.getKey()
                    if state and key then
                        local keyName = typeof(key) == "EnumItem" and key.Name or tostring(key)
                        if keyName == "MouseButton1" then keyName = "LMB" end
                        if keyName == "MouseButton2" then keyName = "RMB" end
                        if keyName == "MouseButton3" then keyName = "MMB" end
                        table.insert(activeBinds, bind.getName() .. " [ " .. keyName .. " ]")
                    end
                end
                for _, child in Keybind_Frame:GetChildren() do
                    if child:IsA("TextLabel") and child.Name == "BindEntry" then
                        child:Destroy()
                    end
                end
                local yOffset = 34 * scale
                for _, text in activeBinds do
                    local label = Spec_Template:Clone()
                    label.Name = "BindEntry"
                    label.Text = text
                    label.TextColor3 = KB_TextColor
                    label.TextSize = 24 * scale
                    label.Size = UDim2.new(0, 228 * scale, 0, 28 * scale)
                    label.FontFace = Font.new("rbxasset://fonts/families/" .. KB_Font .. ".json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                    label.Position = UDim2.new(0, 6 * scale, 0, yOffset)
                    label.Parent = Keybind_Frame
                    yOffset = yOffset + 28 * scale
                end
                Keybind_Frame.Size = UDim2.new(0, 240 * scale, 0, math.max(66 * scale, yOffset + 6 * scale))
            else
                Keybind_Frame.Visible = false
            end
        end
    end)
    if GuiTheme ~= 1 then
        MenuSection:CreateTextbox({
            Name = "Watermark Text",
            Placeholder = "clarity",
            Callback = function(text)
                if text ~= "" then
                    LMG2L_claritywm_2.Text = text
                end
            end
        })
        MenuSection:CreateToggle({
            Name = "Customize Colors",
            Default = false,
            Colorpickers = {
                {Name = "Text Color", ColorDefault = Color3.fromRGB(255, 255, 255), Callback = function(c) LMG2L_claritywm_2.TextColor3 = c end},
                {Name = "Background", ColorDefault = Color3.fromRGB(22, 22, 22), Callback = function(c) LMG2L_claritywm_2.BackgroundColor3 = c end}
            },
            Callback = function(state) end
        })
    end
    ;(function()
        local ConfigSection = ConfigTab:CreateSection({
            Name = "File Config Manager",
            Side = "Left"
        })
        ConfigSection:CreateToggle({
            Name = "Accent Color",
            Default = true,
            Colorpickers = {
                {
                    Name = "Accent Color",
                    ColorDefault = Theme.ToggleActive,
                    Callback = function(c)
                        Theme.ToggleActive = c
                        ApplyAccent()
                    end
                }
            },
            Callback = function() end
        })
        local currentConfigName = "default"
        ConfigSection:CreateTextbox({
        Name = "Config Name",
        Placeholder = "default",
        Callback = function(text) 
            if text == "" then currentConfigName = "default" else currentConfigName = text end
        end
    })
    ConfigSection:CreateButton({
        Name = "Save Config",
        Callback = function()
            local uiFlags = {}
            for k, v in Library.Flags do
                uiFlags[k] = v:Get()
            end
            local fullConfig = {
                Aimbot = AimbotSettings,
                ESP = ESP_Settings,
                World = WorldSettings,
                Skins = CustomSkins,
                UnlockedEquipped = state.ClientEquippedOverrides,
                PSLines = env.PSLineSettings.Lines,
                UI = uiFlags
            }
            local encodedConfig = encodeValue(fullConfig)
            local s, str = pcall(function() return game:GetService("HttpService"):JSONEncode(encodedConfig) end)
            if s then
                if not isfolder("mayday.tk") then pcall(makefolder, "mayday.tk") end
                pcall(writefile, "mayday.tk/" .. currentConfigName .. ".json", str)
                Library:Notify("Config saved: " .. currentConfigName, 3)
            end
        end
    })
    ConfigSection:CreateButton({
        Name = "Load Config",
        Callback = function()
            local path = "mayday.tk/" .. currentConfigName .. ".json"
            if isfile(path) then
                local success, str = pcall(readfile, path)
                if success and str then
                    local s, decodedJSON = pcall(function() return game:GetService("HttpService"):JSONDecode(str) end)
                    if s and type(decodedJSON) == "table" then
                        local decodedConfig = decodeValue(decodedJSON)
                        if decodedConfig.Aimbot then for k, v in decodedConfig.Aimbot do AimbotSettings[k] = v end end
                        if decodedConfig.ESP then for k, v in decodedConfig.ESP do ESP_Settings[k] = v end end
                        if decodedConfig.World then for k, v in decodedConfig.World do WorldSettings[k] = v end end
                        if decodedConfig.PSLines then
                            env.PSLineSettings.Lines = decodedConfig.PSLines
                            env.RefreshPSLines()
                        end
                        if decodedConfig.Skins then
                            CustomSkins = {}
                            for k, v in decodedConfig.Skins do CustomSkins[k] = v end
                            if type(refreshConfiguredWeaponsList) == "function" then
                                refreshConfiguredWeaponsList()
                            end
                        end
                        if decodedConfig.UnlockedEquipped then
                            state.ClientEquippedOverrides = decodedConfig.UnlockedEquipped
                            if type(unlock_inventory) == "function" then
                                pcall(unlock_inventory)
                            end
                        end
                        if decodedConfig.UI then
                            for k, v in decodedConfig.UI do
                                if Library.Flags[k] then
                                    if v.Type == "Toggle" then
                                        local enumBind = nil
                                        if v.Bind then
                                            pcall(function()
                                                for _, e in Enum.UserInputType:GetEnumItems() do
                                                    if e.Value == v.Bind then enumBind = e break end
                                                end
                                                if not enumBind then
                                                    for _, e in Enum.KeyCode:GetEnumItems() do
                                                        if e.Value == v.Bind then enumBind = e break end
                                                    end
                                                end
                                            end)
                                        end
                                        Library.Flags[k].Set(v.Value, enumBind, v.Mode, v.Colors)
                                    elseif v.Type == "Slider" or v.Type == "Dropdown" or v.Type == "MultiDropdown" then
                                        Library.Flags[k].Set(v.Value)
                                    end
                                end
                            end
                        end
                        Library:Notify("Config loaded: " .. currentConfigName, 3)
else
                        Library:Notify("Config format is outdated or incorrect.", 3)
end
                end
            else
                Library:Notify("Config file '" .. currentConfigName .. "' not found!", 3)
end
        end
    })
    end)()
    ;(function()
        local Players = game:GetService("Players")
        local lp = Players.LocalPlayer
        if not lp then return end
        local realName = lp.Name
        local realDisplayName = lp.DisplayName
        local function spoofText(obj)
            if not AimbotSettings.NameSpoofer or not AimbotSettings.SpoofedName or AimbotSettings.SpoofedName == "" then return end
            pcall(function()
                local txt = obj.Text
                if txt and (string.find(txt, realName) or string.find(txt, realDisplayName)) then
                    if string.find(txt, AimbotSettings.SpoofedName) then return end
                    local newText = string.gsub(txt, realName, AimbotSettings.SpoofedName)
                    newText = string.gsub(newText, realDisplayName, AimbotSettings.SpoofedName)
                    if newText ~= txt then
                        obj.Text = newText
                    end
                end
            end)
        end
        local boundObjects = {}
        local function bindObj(obj)
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                if boundObjects[obj] then return end
                boundObjects[obj] = true
                spoofText(obj)
                obj:GetPropertyChangedSignal("Text"):Connect(function()
                    spoofText(obj)
                end)
            end
        end
        local pGui = lp:FindFirstChild("PlayerGui")
        if pGui then
            for _, obj in pGui:GetDescendants() do
                bindObj(obj)
            end
            pGui.DescendantAdded:Connect(bindObj)
        end
        for _, obj in workspace:GetDescendants() do
            if obj:FindFirstAncestorOfClass("BillboardGui") then
                bindObj(obj)
            end
        end
        workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                task.wait(0.1)
                if obj:FindFirstAncestorOfClass("BillboardGui") then
                    bindObj(obj)
                end
            end
        end)
    end)()
    task.spawn(function()
        task.wait(1)
        Library:Notify("Script fully loaded!", 3)
    end)
    return Library
