local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shared = getgenv and getgenv() or _G
local ui

if shared.BanskoShutdown then
    pcall(shared.BanskoShutdown)
    shared.BanskoShutdown = nil
end

-- Destroy old UI
local existing = playerGui:FindFirstChild("BanskoUiOnly")
if existing then existing:Destroy() end

-- ==================== THEME ====================
local theme = {
    background = Color3.fromRGB(17, 17, 19),
    panel = Color3.fromRGB(24, 24, 28),
    card = Color3.fromRGB(31, 31, 36),
    cardAlt = Color3.fromRGB(26, 26, 31),
    stroke = Color3.fromRGB(58, 58, 66),
    text = Color3.fromRGB(240, 240, 240),
    softText = Color3.fromRGB(166, 166, 176),
    accent = Color3.fromRGB(98, 90, 215)
}

local themeDefaults = {
    background = theme.background,
    panel = theme.panel,
    card = theme.card,
    cardAlt = theme.cardAlt,
    stroke = theme.stroke,
    text = theme.text,
    softText = theme.softText,
    accent = theme.accent
}

-- ==================== FARMING FEATURES ====================
local vim = VirtualInputManager

local farmStates = {
    Coces = false,
    Miner = false,
    Milker = false,
    Cleaner = false
}

local farmData = {
    Coces = {
        positions = {
            Vector3.new(-1634, 15, -602), Vector3.new(-1686, 4, -596),
            Vector3.new(-1706, -2, -527), Vector3.new(-1671, 7, -490),
            Vector3.new(-1684, -4, -411), Vector3.new(-1692, -4, -391),
            Vector3.new(-1583, 4, -460), Vector3.new(-1629, 15, -481),
            Vector3.new(-1616, 26, -554), Vector3.new(-1626, 4, -654)
        },
        tpWait = 0.5,
        interactWait = 6.5
    },

    Miner = {
        positions = {
            {-820,12,-1001,0.5}, {-861,12,-1001,0.3}, {-905,12,-1053,0.3}
        },
        interactWait = 7.5,
        custom = true
    },

    Milker = {
        positions = {
            {671,84,-284,0.5},{659,84,-300,0.5},{648,84,-321,0.5},
            {637,84,-331,0.5},{657,84,-342,0.5},{672,84,-326,0.5},
            {682,84,-311,0.5},{690,84,-295,0.5}
        },
        interactWait = 6.5,
        custom = true
    },

    Cleaner = {
        positions = {
            Vector3.new(234, 3, 431), Vector3.new(213, 4, 396),
            Vector3.new(219, 4, 417), Vector3.new(207, 4, 436),
            Vector3.new(210, 4, 460)
        },
        tpWait = 0.3,
        firstTpWait = 0.5,
        interactWait = 8.5
    }
}

local function pressE()
    vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.1)
    vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function startFarm(name, enabled)
    farmStates[name] = enabled
    if not enabled then return end

    task.spawn(function()
        local config = farmData[name]
        local firstTP = true

        while farmStates[name] do
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then
                task.wait(0.5)
                continue
            end

            for _, pos in ipairs(config.positions) do
                if not farmStates[name] then break end

                if config.custom then
                    hrp.CFrame = CFrame.new(pos[1], pos[2], pos[3])
                    task.wait(pos[4])
                else
                    hrp.CFrame = CFrame.new(pos)
                    if config.firstTpWait and firstTP then
                        task.wait(config.firstTpWait)
                        firstTP = false
                    else
                        task.wait(config.tpWait or 0.5)
                    end
                end

                pressE()
                task.wait(config.interactWait or 6.5)
            end
        end
    end)
end


-- Seller / Start Process
local processing = false

local function startProcess(enabled)
    processing = enabled
    if processing then
        task.spawn(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(-610, 3, 315)  -- Seller position
                task.wait(0.5)
            end
            while processing do
                vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(3)
                vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                task.wait(0.4)
            end
        end)
    end
end

-- ==================== LOCAL TABS ====================

local keybindConnection
local keybindReleaseConnection
local isBindingKey = false

local AimEnabled = false
local ShowFOVCircle = false
local AimStrength = 0.18
local FOVRadius = 140
local AimHoldKey = "None"
local AimHolding = false
local aimConnection = nil
local FOVCircle = nil
local AIM_RENDERSTEP_NAME = "BanskoAimAssist"
local MenuToggleKey = "RightShift"


local tabs = {
    {
        name = "Combat",
        sections = {
            { name = "Aim Assist", controls = { 
                "toggle:Aim Assist", 
                "dropdown:Aim Key (Hold)",
                "dropdown:Aim Mode",
                "toggle:Show FOV", 
                "slider:FOV Size"
            } },
            { name = "Smoothing", controls = {
                "slider:Smoothness"
            } }
        }
    },
    {
        name = "Player",
        sections = {
            { name = "Speed", controls = { "toggle:Toggle", "slider:Walk Speed", "dropdown:Speed" } },
            { name = "Fly", controls = { "toggle:Toggle", "slider:Fly Speed", "dropdown:Fly" } },
            { name = "Super Jump", controls = { "toggle:Toggle", "slider:Jump Height", "dropdown:Jump" } },
            { name = "Others", controls = { "toggle:NoClip", "toggle:No Jump Cooldown", "toggle:High Gravity", "toggle:No Ragdoll" } }
        }
    },
    {
        name = "Visuals",
        sections = {
            { name = "Visuals", controls = {
				"toggle:Enabled",
				"toggle:Boxes",
				"toggle:Skeleton",
				"toggle:Tracers",
				"toggle:Nametags",
				"toggle:Distance"
			} },
            { name = "Filters", controls = {
                "toggle:Ignore Self",
                "toggle:Ignore Dead"
            } },
            { name = "Settings", controls = {
                "toggle:Filled Boxes",
                "slider:Max Distance",
                "dropdown:Text Style"
            } }
        }
    },
    {
        name = "Farm",
        sections = {
            { name = "Coces", controls = { "toggle:Start Collect", "toggle:Start Process", "button:Goto Seller" } },
            { name = "Miner", controls = { "toggle:Start Collect", "button:Goto Seller" } },
            { name = "Milker", controls = { "toggle:Start Collect", "button:Goto Seller" } },
            { name = "Cleaner", controls = { "toggle:Start Collect" } }
        }
    },
    {
        name = "Locations",
        sections = {
            { name = "Locations", controls = {
                "button:Goto Black Market", "button:Goto SuperMarket", "button:Goto Main Garage",
                "button:Goto Paleto Bank", "button:Goto Car Dealer", "button:Goto Farmakeio",
                "button:Goto Main Bank", "button:Goto Hospital", "button:Goto Gunshop",
                "button:Goto Oaed", "button:Goto Opap"
            }},
            { name = "Extra", controls = { "button:Goto Crate", "button:Goto Treasure"} }
        }
    },
    {
        name = "Online",
        sections = {
            { name = "Player List", controls = { "dropdown:Select Player", "button:Tp to Player", "button:Spectate Player", "button:Stop Spectating" } },
            { name = "Staff List", controls = { "dropdown:Select Staff", "button:Spectate Staff", "button:Stop Spectating" } }
        }
    },
    {
        name = "Miscellaneous",
        sectionTabs = {
            {
                name = "Misc",
                sections = {
                    { name = "Menu Bind", controls = { "dropdown:Menu Key" } },
                    { name = "Panic Button", controls = { "button:Destruct" } }
                }
            },
            {
                name = "Theme Editor",
                sections = {
                    { name = "Theme Editor", controls = {
                        "colorpicker:Accent Color",
                        "colorpicker:Text Color",
                        "colorpicker:Text Dim Color",
                        "colorpicker:Sidebar Background",
                        "colorpicker:Primary Background",
                        "colorpicker:Search Bar",
                        "colorpicker:Separator",
                        "colorpicker:Tab Bar",
                        "colorpicker:Tab Active",
                        "button:Reset Defaults"
                    } },
                    { name = "Display", controls = { "slider:UI Scale" } }
                }
            },
            {
                name = "Others",
                sections = {
                    { name = "Auto Clicker", controls = { "toggle:Toggle", "dropdown:Click Button", "slider:CPS", "dropdown:Auto Clicker Key", "dropdown:Auto Clicker Mode" } }
                }
            }
        },
        sections = {
            { name = "Menu Bind", controls = { "dropdown:Menu Key" } },
            { name = "Theme Editor", controls = { "colorpicker:Accent Color", "colorpicker:Text Color", "colorpicker:Text Dim Color", "colorpicker:Sidebar Background", "colorpicker:Primary Background", "colorpicker:Search Bar", "colorpicker:Separator", "colorpicker:Tab Bar", "colorpicker:Tab Active", "button:Reset Defaults", "slider:UI Scale" } },
            { name = "Auto Clicker", controls = { "toggle:Toggle", "dropdown:Click Button", "slider:CPS", "dropdown:Auto Clicker Key", "dropdown:Auto Clicker Mode" } },
            { name = "Panic Button", controls = { "button:Destruct" } }
        }
    }
}

shared.BanskoLockGuiButtonSize = function(button)
    task.defer(function()
        if not button.Parent then
            return
        end

        local baseSize = button.Size
        local basePosition = button.Position

        local restoring = false
        local function restore()
            if restoring or not button.Parent then
                return
            end

            restoring = true
            if button.Size ~= baseSize then
                button.Size = baseSize
            end
            if button.Position ~= basePosition then
                button.Position = basePosition
            end
            restoring = false
        end

        button.MouseEnter:Connect(function()
            task.defer(restore)
        end)
        button.MouseLeave:Connect(function()
            task.defer(restore)
        end)
        button:GetPropertyChangedSignal("Size"):Connect(restore)
        button:GetPropertyChangedSignal("Position"):Connect(restore)
    end)
end

local function create(className, props)
    local instance = Instance.new(className)
    if className == "TextButton" or className == "ImageButton" then
        instance.Selectable = false
    end
    for key, value in pairs(props) do
        instance[key] = value
    end
    if className == "TextButton" or className == "ImageButton" then
        shared.BanskoLockGuiButtonSize(instance)
    end
    return instance
end

local function tween(instance, info, props)
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end



local screenGui = create("ScreenGui", {
    Name = "BanskoUiOnly",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = playerGui
})

ui = {}

ui.notificationHolder = create("Frame", {
    Size = UDim2.fromOffset(290, 290),
    Position = UDim2.new(1, -18, 1, -18),
    AnchorPoint = Vector2.new(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 80,
    Parent = screenGui
})


ui.staffNotificationHolder = create("Frame", {
    Size = UDim2.fromOffset(340, 160),
    Position = UDim2.new(0.5, 0, 0, 22),
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 90,
    Parent = screenGui
})

create("UIListLayout", {
    Padding = UDim.new(0, 8),
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = ui.staffNotificationHolder
})


create("UIListLayout", {
    Padding = UDim.new(0, 8),
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = ui.notificationHolder
})

ui.background = create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Parent = screenGui
})

ui.shell = create("Frame", {
    Size = UDim2.new(0, 748, 0, 472),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = theme.background,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = false,
    Parent = ui.background
})

ui.menuScale = create("UIScale", {
    Name = "BanskoMenuScale",
    Scale = 1.05,
    Parent = ui.shell
})

ui.menuScale:GetPropertyChangedSignal("Scale"):Connect(function()
    local clamped = math.clamp(ui.menuScale.Scale, 0.85, 1.1)
    if math.abs(ui.menuScale.Scale - clamped) > 0.0001 then
        ui.menuScale.Scale = clamped
    end
end)

ui.shell.DescendantAdded:Connect(function(object)
    task.defer(function()
        if object.Parent and object:IsA("UIScale") and object ~= ui.menuScale and object:IsDescendantOf(ui.shell) then
            object:Destroy()
        end
    end)
end)

local existingBlur = Lighting:FindFirstChild("BanskoIntroBlur")
if existingBlur then
    existingBlur:Destroy()
end

local introBlur = create("BlurEffect", {
    Name = "BanskoIntroBlur",
    Size = 0,
    Parent = Lighting
})

local introOverlay = create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 50,
    Parent = screenGui
})

local introTitle = create("TextLabel", {
    Size = UDim2.new(0, 520, 0, 58),
    Position = UDim2.new(0.5, 0, 0.45, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Text = "bansko",
    Font = Enum.Font.GothamBlack,
    TextSize = 42,
    TextColor3 = theme.text,
    TextTransparency = 1,
    TextStrokeTransparency = 1,
    ZIndex = 51,
    TextXAlignment = Enum.TextXAlignment.Center,
    Parent = introOverlay
})

local introSubtitle = create("TextLabel", {
    Size = UDim2.new(0, 230, 0, 22),
    Position = UDim2.new(0.5, 18, 0.500, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Text = "Successfully Injected",
    Font = Enum.Font.GothamMedium,
    TextSize = 13,
    TextColor3 = theme.text,
    TextTransparency = 1,
    ZIndex = 51,
    TextXAlignment = Enum.TextXAlignment.Center,
    Parent = introOverlay
})

local introCheck = create("TextLabel", {
    Size = UDim2.fromOffset(16, 16),
    Position = UDim2.new(0.5, -62, 0.500, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Color3.fromRGB(172, 80, 255),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Text = "?",
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextTransparency = 1,
    ZIndex = 51,
    Parent = introOverlay
})
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = introCheck })


local introAccentLine = create("Frame", {
    Size = UDim2.new(0, 250, 0, 2),
    Position = UDim2.new(0.5, 0, 0.479, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Color3.fromRGB(168, 95, 255),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 51,
    Parent = introOverlay
})
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = introAccentLine })
create("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(168, 95, 255), Color3.fromRGB(168, 95, 255)),
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.18, 0.55),
        NumberSequenceKeypoint.new(0.5, 0.08),
        NumberSequenceKeypoint.new(0.82, 0.55),
        NumberSequenceKeypoint.new(1, 1)
    }),
    Parent = introAccentLine
})

local introStatus = create("Frame", {
    Size = UDim2.new(0, 285, 0, 30),
    Position = UDim2.new(0.5, 17, 0.545, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Color3.fromRGB(42, 42, 48),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 50,
    Parent = introOverlay
})

local introPressText = create("TextLabel", {
    Size = UDim2.fromOffset(46, 28),
    Position = UDim2.fromOffset(17, 1),
    BackgroundTransparency = 1,
    Text = "Press",
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextColor3 = theme.softText,
    TextTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 51,
    Parent = introStatus
})

local introKeyPill = create("TextLabel", {
    Size = UDim2.fromOffset(56, 20),
    Position = UDim2.fromOffset(60, 5),
    BackgroundColor3 = Color3.fromRGB(92, 65, 155),
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
    Text = "RSHIFT",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(230, 220, 255),
    TextTransparency = 1,
    ZIndex = 51,
    Parent = introStatus
})
create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = introKeyPill })
local introKeyPillStroke = create("UIStroke", { Color = Color3.fromRGB(168, 95, 255), Thickness = 1, Transparency = 1, Parent = introKeyPill })

local introStatusText = create("TextLabel", {
    Size = UDim2.new(0, 150, 1, 0),
    Position = UDim2.fromOffset(129, 0),
    BackgroundTransparency = 1,
    Text = "to open the menu",
    Font = Enum.Font.GothamMedium,
    TextSize = 13,
    TextColor3 = theme.softText,
    TextTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 51,
    Parent = introStatus
})


local shellStroke = create("UIStroke", { Color = theme.stroke, Thickness = 1, Transparency = 1, Parent = ui.shell })

ui.header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 38),
    Position = UDim2.fromOffset(0, 0), -- touches top
    BackgroundColor3 = Color3.fromRGB(30, 30, 35),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Parent = ui.shell
})

ui.main = create("Frame", {
    Size = UDim2.new(0, 160, 1, 0),
    Position = UDim2.fromOffset(0, 0),
    BackgroundColor3 = theme.panel,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Parent = ui.shell
})



local headerStroke = create("UIStroke", { Color = theme.stroke, Thickness = 1, Transparency = 1, Parent = ui.header })

local madeByLabel = create("TextLabel", {
    Size = UDim2.fromOffset(0, 0),
    Position = UDim2.fromOffset(0, 0),
    BackgroundTransparency = 1,
    Text = "",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = theme.accent,
    TextTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Left,
    Visible = false,
    Parent = ui.main
})

local titleLabel = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 22),
    Position = UDim2.fromOffset(0, 10),
    BackgroundTransparency = 1,
    Text = "",
    Font = Enum.Font.GothamBlack,
    TextSize = 23,
    TextColor3 = theme.text,
    TextTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Center,
    Visible = true,
    Parent = ui.main
})

local titleIcon = create("ImageLabel", {
    Size = UDim2.fromOffset(104, 83),
    Position = UDim2.new(0.5, -58, 0, -8),
    BackgroundTransparency = 1,
    Image = "rbxassetid://111375885206441",
    ScaleType = Enum.ScaleType.Fit,
    Parent = ui.main
})

local titleDefaultPosition = titleLabel.Position

ui.searchHolder = create("Frame", {
    Size = UDim2.new(1, -28, 0, 24),
    Position = UDim2.fromOffset(14, 68),
    BackgroundColor3 = theme.cardAlt,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    Parent = ui.main
})
create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = ui.searchHolder })
create("UIStroke", { Color = theme.stroke, Thickness = 1, Transparency = 0.35, Parent = ui.searchHolder })

ui.searchIcon = create("ImageLabel", {
    Size = UDim2.fromOffset(14, 14),
    Position = UDim2.fromOffset(10, 5),
    BackgroundTransparency = 1,
    Image = "rbxthumb://type=Asset&id=134175482524432&w=150&h=150",
    ScaleType = Enum.ScaleType.Fit,
    ImageColor3 = theme.softText,
    Parent = ui.searchHolder
})

ui.searchBox = create("TextBox", {
    Size = UDim2.new(1, -34, 1, 0),
    Position = UDim2.fromOffset(28, 0),
    BackgroundTransparency = 1,
    ClearTextOnFocus = false,
    Text = "",
    PlaceholderText = "Search",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = theme.text,
    PlaceholderColor3 = theme.softText,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = ui.searchHolder
})

local minimizeButton = create("TextButton", {
    Size = UDim2.fromOffset(24, 24),
    Position = UDim2.new(1, -34, 0, 7),
    BackgroundColor3 = Color3.fromRGB(38, 38, 43),
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    Text = "",
    Font = Enum.Font.GothamMedium,
    TextSize = 18,
    TextColor3 = theme.text,
    TextTransparency = 1,
    AutoButtonColor = false,
    Parent = ui.header
})
create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = minimizeButton })
local minimizeStroke = create("UIStroke", { Color = Color3.fromRGB(185, 185, 195), Thickness = 1.2, Transparency = 1, Parent = minimizeButton })
local minimizeIcon = create("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    Position = UDim2.fromOffset(0, -1),
    BackgroundTransparency = 1,
    Text = "-",
    Font = Enum.Font.GothamMedium,
    TextSize = 15,
    TextColor3 = theme.text,
    TextTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center,
    Parent = minimizeButton
})

ui.tabBar = create("ScrollingFrame", {
    Size = UDim2.new(1, 20, 1, -150),
    Position = UDim2.fromOffset(-20, 110),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    ScrollBarImageTransparency = 1,
    ScrollingEnabled = false,
    Active = false,
    CanvasSize = UDim2.new(),
    ZIndex = 2,
    Parent = ui.main
})

local tabLayout = create("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = ui.tabBar
})

ui.pageHolder = create("Frame", {
    Size = UDim2.new(1, -180, 1, -85),
    Position = UDim2.fromOffset(170, 58),
    BackgroundTransparency = 1,
    Parent = ui.shell
})




local function showNotification(title, message)
    local toast = create("Frame", {
        Size = UDim2.fromOffset(270, 58),
        BackgroundColor3 = theme.card,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 81,
        Parent = ui.notificationHolder
    })
    create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = toast })
    local toastScale = create("UIScale", {
        Scale = 0.96,
        Parent = toast
    })
    local toastStroke = create("UIStroke", {
        Color = theme.accent,
        Thickness = 1,
        Transparency = 1,
        Parent = toast
    })

    local accentBar = create("Frame", {
        Size = UDim2.new(0, 2, 1, -16),
        Position = UDim2.fromOffset(9, 8),
        BackgroundColor3 = theme.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 82,
        Parent = toast
    })
    create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = accentBar })

    local titleLabel = create("TextLabel", {
        Size = UDim2.new(1, -30, 0, 18),
        Position = UDim2.fromOffset(20, 8),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = theme.text,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 82,
        Parent = toast
    })

    local messageLabel = create("TextLabel", {
        Size = UDim2.new(1, -30, 0, 22),
        Position = UDim2.fromOffset(20, 28),
        BackgroundTransparency = 1,
        Text = message,
        Font = Enum.Font.Gotham,
        TextSize = 18,
        TextColor3 = theme.softText,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 82,
        Parent = toast
    })

    tween(toast, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    })
    tween(toastScale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Scale = 1
    })
    tween(toastStroke, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 0.25
    })
    tween(accentBar, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    })
    tween(titleLabel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    })
    tween(messageLabel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    })

    task.delay(2.4, function()
        if not toast.Parent then
            return
        end

        tween(toast, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        })
        tween(toastScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Scale = 0.96
        })
        tween(toastStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Transparency = 1
        })
        tween(accentBar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        })
        tween(titleLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1
        })
        local fadeOut = tween(messageLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1
        })
        fadeOut.Completed:Connect(function()
            if toast.Parent then
                toast:Destroy()
            end
        end)
    end)
end

local function showStaffNotification(title, message)
    local toast = create("Frame", {
        Size = UDim2.fromOffset(300, 62),
        BackgroundColor3 = theme.card,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 91,
        Parent = ui.staffNotificationHolder
    })

    create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = toast })

    local stroke = create("UIStroke", {
		Color = theme.accent,
		Thickness = 1.5,
		Transparency = 1,
		Parent = toast
	})

    local titleLabel = create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 22),
        Position = UDim2.fromOffset(10, 6),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = theme.accent,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = toast
    })

    local msgLabel = create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.fromOffset(10, 30),
        BackgroundTransparency = 1,
        Text = message,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = theme.text,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = toast
    })

    tween(toast, TweenInfo.new(0.25), {
        BackgroundTransparency = 0
    })

    tween(stroke, TweenInfo.new(0.25), {
        Transparency = 0
    })

    tween(titleLabel, TweenInfo.new(0.25), {
        TextTransparency = 0
    })

    tween(msgLabel, TweenInfo.new(0.25), {
        TextTransparency = 0
    })

    task.delay(3.2, function()
        tween(toast, TweenInfo.new(0.2), {
            BackgroundTransparency = 1
        })

        tween(stroke, TweenInfo.new(0.2), {
            Transparency = 1
        })

        tween(titleLabel, TweenInfo.new(0.2), {
            TextTransparency = 1
        })

        local fade = tween(msgLabel, TweenInfo.new(0.2), {
            TextTransparency = 1
        })

        fade.Completed:Connect(function()
            toast:Destroy()
        end)
    end)
end


local currentTabButton
local currentTabUnderline
local showTab



local tabButtons = {}
local tabButtonsByName = {}
local tabOriginalText = {}

local sectionLabelsByTab = {}
local sectionOriginalText = {}

local controlLabelsByTab = {}
local controlOriginalText = {}

local searchIndex = {}
local themeColorPreviews = {}
local activeThemeColorPicker

local themeColorControls = {
    ["Accent Color"] = "accent",
    ["Background Color"] = "background",
    ["Sidebar Color"] = "panel",
    ["Text Color"] = "text",
    ["Dim Text Color"] = "softText",
    ["Text Dim Color"] = "softText",
    ["Card Color"] = "card",
    ["Control Color"] = "cardAlt",
    ["Stroke Color"] = "stroke",
    ["Sidebar Background"] = "panel",
    ["Primary Background"] = "background",
    ["Search Bar"] = "cardAlt",
    ["Separator"] = "stroke",
    ["Tab Bar"] = "card",
    ["Tab Active"] = "accent"
}

local function getThemeColor(controlName)
    local key = themeColorControls[controlName] or "accent"
    return theme[key] or theme.accent
end

local function applyThemeColor(controlName, newColor, silent)
    local key = themeColorControls[controlName] or "accent"
    local oldColor = theme[key]
    if not oldColor then
        return
    end

    theme[key] = newColor

    for _, instance in ipairs(screenGui:GetDescendants()) do
        if instance:IsA("GuiObject") then
            if instance.BackgroundColor3 == oldColor then
                instance.BackgroundColor3 = newColor
            end

            if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
                if instance.TextColor3 == oldColor then
                    instance.TextColor3 = newColor
                end
            end

            if instance:IsA("TextBox") and instance.PlaceholderColor3 == oldColor then
                instance.PlaceholderColor3 = newColor
            end

            if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
                if instance.ImageColor3 == oldColor then
                    instance.ImageColor3 = newColor
                end
            end

            if instance:IsA("ScrollingFrame") and instance.ScrollBarImageColor3 == oldColor then
                instance.ScrollBarImageColor3 = newColor
            end
        elseif instance:IsA("UIStroke") then
            if instance.Color == oldColor then
                instance.Color = newColor
            end
        elseif instance:IsA("UIGradient")
            and instance.Name ~= "AccentPickerGradient"
            and instance.Name ~= "ThemePickerGradient"
            and instance.Name ~= "BoxPickerGradient"
            and instance.Name ~= "BoxBlendGradient" then
            instance.Color = ColorSequence.new(newColor, newColor)
        end
    end

    if key == "accent" and currentTabButton then
        currentTabButton.TextColor3 = newColor
    end

    if key == "accent" and currentTabUnderline then
        currentTabUnderline.BackgroundColor3 = newColor
    end

    if not silent then
        showNotification("Theme", controlName .. " changed")
    end
end

local function applyAccentColor(newColor, silent)
    applyThemeColor("Accent Color", newColor, silent)
end

local function resetThemeDefaults()
    for controlName, key in pairs(themeColorControls) do
        applyThemeColor(controlName, themeDefaults[key], true)

        local preview = themeColorPreviews[controlName]
        if preview then
            preview.BackgroundColor3 = themeDefaults[key]
        end
    end

    showNotification("Theme", "Defaults restored")
end

local function escapeRichText(str)
    str = tostring(str or "")
    str = str:gsub("&", "&amp;")
    str = str:gsub("<", "&lt;")
    str = str:gsub(">", "&gt;")
    return str
end

local function formatKeyName(keyName)
    if keyName == "RightShift" then
        return "RShift"
    elseif keyName == "LeftShift" then
        return "LShift"
    end

    return tostring(keyName or "None")
end

local function normalizeMouseBindName(name)
    return nil
end

local function getInputBindName(input)
    local inputTypeName = input.UserInputType and input.UserInputType.Name
    local mouseName = normalizeMouseBindName(inputTypeName)
    if mouseName then
        return mouseName
    end

    mouseName = normalizeMouseBindName(input.KeyCode and input.KeyCode.Name)
    if mouseName then
        return mouseName
    end

    if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
        return input.KeyCode.Name
    end

    return nil
end

local function isMouseBindInput(input)
    return normalizeMouseBindName(input.UserInputType and input.UserInputType.Name) ~= nil
        or normalizeMouseBindName(input.KeyCode and input.KeyCode.Name) ~= nil
end

local function highlightMatch(text, query, colorHex)
    text = tostring(text or "")
    query = tostring(query or "")

    if query == "" then
        return escapeRichText(text)
    end

    local parts = {}
    local found = false

    for word, spaces in text:gmatch("([^%s]+)(%s*)") do
        local lowerWord = string.lower(word)
        local lowerQuery = string.lower(query)

        if not found and lowerWord:sub(1, #lowerQuery) == lowerQuery then
            local matchPart = escapeRichText(word:sub(1, #query))
            local restPart = escapeRichText(word:sub(#query + 1))

            table.insert(parts, '<font color="' .. colorHex .. '">' .. matchPart .. "</font>" .. restPart .. spaces)
            found = true
        else
            table.insert(parts, escapeRichText(word) .. spaces)
        end
    end

    if #parts == 0 then
        return escapeRichText(text)
    end

    return table.concat(parts)
end



local function resetSearchVisuals()
    for tabName, button in pairs(tabButtonsByName) do
        button.RichText = true
        button.Text = escapeRichText(tabOriginalText[tabName] or tabName)
    end

    for tabName, labels in pairs(sectionLabelsByTab) do
        for i, label in ipairs(labels) do
            label.RichText = true
            label.Text = escapeRichText(sectionOriginalText[tabName][i])
        end
    end

    for tabName, labels in pairs(controlLabelsByTab) do
        for i, label in ipairs(labels) do
            label.RichText = true
            label.Text = escapeRichText(controlOriginalText[tabName][i])
        end
    end
end
local function rebuildSearchIndex()
    searchIndex = {}

    for _, tab in ipairs(tabs) do
        for _, section in ipairs(tab.sections) do
            table.insert(searchIndex, {
                kind = "section",
                tabName = tab.name,
                sectionName = section.name,
                text = section.name,
                priority = 1
            })

            for _, spec in ipairs(section.controls) do
                local _, controlName = spec:match("([^:]+):(.+)")
                if controlName then
                    table.insert(searchIndex, {
                        kind = "control",
                        tabName = tab.name,
                        sectionName = section.name,
                        text = controlName,
                        priority = 2
                    })
                end
            end
        end
    end
end



local function applySearch(query)
    query = tostring(query or "")
    query = query:gsub("^%s+", ""):gsub("%s+$", "")

    resetSearchVisuals()

    if query == "" then
        return
    end

    local lowerQuery = string.lower(query)
    local bestMatch = nil

    local function wordStartsWith(text, search)
        for word in string.gmatch(string.lower(text), "%S+") do
            if word:sub(1, #search) == search then
                return true
            end
        end
        return false
    end

    for _, entry in ipairs(searchIndex) do
        if wordStartsWith(entry.text, lowerQuery) then
            if not bestMatch then
                bestMatch = entry
            else
                if entry.priority < bestMatch.priority then
                    bestMatch = entry
                end
            end
        end
    end

    if not bestMatch then
        return
    end

    local accentHex = "#A85FFF"
    local entry = bestMatch
    

    showTab(entry.tabName)

    -- highlight matching section on the right
    if entry.sectionName and sectionLabelsByTab[entry.tabName] then
        for i, label in ipairs(sectionLabelsByTab[entry.tabName]) do
            local original = sectionOriginalText[entry.tabName][i]
            if original == entry.sectionName then
                label.RichText = true
                label.Text = highlightMatch(original, query, accentHex)

                
            end
        end
    end

    -- highlight matching controls on the right
    if controlLabelsByTab[entry.tabName] then
        for i, label in ipairs(controlLabelsByTab[entry.tabName]) do
            local original = controlOriginalText[entry.tabName][i]

            if wordStartsWith(original, lowerQuery) then
                label.RichText = true

                if label:IsA("TextButton") then
                    label.Text = highlightMatch(original, query, accentHex)
                else
                    local currentText = label.Text or ""
                    local suffix = currentText:match("(:.*)$") or ""
                    label.Text = highlightMatch(original, query, accentHex) .. escapeRichText(suffix)
                end

               
            end
        end
    end
end











local sellerPositions = {
    Coces = CFrame.new(292, 7, 1726),
    Miner = CFrame.new(-784, 3, -1035),
    Milker = CFrame.new(655, 84, -287)
}


-- ==================== ACTION / STATE LAYER ====================



local function tpNotify(name)
    showNotification("Teleport", "Teleported to " .. name)
end

local function safeTeleport(cf, name)
    local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = cf
        if name then
            tpNotify(name)
        end
    end
end

local state = {
    walkSpeedEnabled = false,
    walkSpeedMultiplier = 1.0,

    flyEnabled = false,
    flySpeed = 300,
    
    jumpEnabled = false,
    jumpHeight = 7.2,
	noJumpCooldown = false,
    stickToGround = false,
    noRagdoll = false,
    
    noclip = false,
    autoClicker = false,
    autoClickerHolding = false,
    autoClickerMode = "Hold",
    autoClickButton = "Left",
    autoClickCps = 10,
    visualMaxDistance = 500,
    

    selectedPlayer = nil,
    selectedStaff = nil,
}

state.aimMode = "Hold"
state.aimToggleActive = false


state.keybinds = {
    Speed = "None",
    Fly = "None",
    AutoClicker = "None",
    Jump = "None"
}

-- ==================== LOCATIONS ====================

local locations = {
    ["Goto Black Market"] = CFrame.new(-467, 3, 248),
    ["Goto SuperMarket"] = CFrame.new(-169, 3, -95),
    ["Goto Main Garage"] = CFrame.new(38, 17, 246),
    ["Goto Paleto Bank"] = CFrame.new(-430, 3, -1085),
    ["Goto Main Bank"] = CFrame.new(-114, 3, 254),
    ["Goto Car Dealer"] = CFrame.new(30, 3, 587),
    ["Goto Gunshop"] = CFrame.new(-171, 3, 593),
    ["Goto Hospital"] = CFrame.new(-921, 3, -57),
    ["Goto Farmakeio"] = CFrame.new(344, 3, 413),
    ["Goto Oaed"] = CFrame.new(260, 3, 424),
    ["Goto Opap"] = CFrame.new(-149, 3, 385),
}

local function gotoTreasure()

    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local chest = workspace:FindFirstChild("Chest", true)

    if not hrp or not chest then
        showNotification("Treasure", "Treasure not found")
        return
    end

    local part = chest:IsA("Model")
        and (chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart"))
        or chest

    if part then
        hrp.CFrame = part.CFrame + Vector3.new(0,3,0)
        showNotification("Treasure", "Teleported")
    end
end



local function gotoCrate1()

    local crate = workspace:FindFirstChild("CratePart", true)

    if not crate then
        showNotification("Crate", "Crate not found")
        return
    end

    local part

    if crate:IsA("BasePart") then
        part = crate

    elseif crate:IsA("Model") then
        part = crate.PrimaryPart or crate:FindFirstChildWhichIsA("BasePart")
    end

    if not part then
        showNotification("Crate", "Invalid crate")
        return
    end

    safeTeleport(part.CFrame + Vector3.new(0,3,0), "Crate")

    showNotification("Crate", "Teleported")
end

-- ==================== GENERAL ====================

local noclipConnection
local setNoClip
local walkSpeedConnection

local function getEffectiveWalkSpeedMultiplier()
    local visualMultiplier = state.walkSpeedMultiplier or 1
    if visualMultiplier <= 1 then
        return 1
    end

    return 1 + ((visualMultiplier - 1) * (9 / 49))
end

local function applyWalkSpeed()
    local char = player.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end

    humanoid.WalkSpeed = 16

    if walkSpeedConnection then
        walkSpeedConnection:Disconnect()
        walkSpeedConnection = nil
    end

    if flying or state.flyEnabled then
        return
    end

    if state.walkSpeedEnabled and state.walkSpeedMultiplier > 1 then
        walkSpeedConnection = RunService.Heartbeat:Connect(function()
            local currentChar = player.Character
            if not currentChar or flying or state.flyEnabled or not state.walkSpeedEnabled then
                return
            end

            local currentHumanoid = currentChar:FindFirstChildOfClass("Humanoid")
            local currentRoot = currentChar:FindFirstChild("HumanoidRootPart")
            if not currentHumanoid or not currentRoot then
                return
            end

            local moveDirection = currentHumanoid.MoveDirection

            if moveDirection.Magnitude > 0 then
                local effectiveMultiplier = getEffectiveWalkSpeedMultiplier()
                local extraSpeed = 16 * (effectiveMultiplier - 1) * 8
                local targetVelocity = moveDirection * (16 + extraSpeed)
                currentRoot.AssemblyLinearVelocity = Vector3.new(
                    targetVelocity.X,
                    currentRoot.AssemblyLinearVelocity.Y,
                    targetVelocity.Z
                )
            else
                local currentVelocity = currentRoot.AssemblyLinearVelocity
                currentRoot.AssemblyLinearVelocity = Vector3.new(
                    currentVelocity.X * 0.02,
                    currentVelocity.Y,
                    currentVelocity.Z * 0.02
                )
            end
        end)
    else
        local currentVelocity = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(0, currentVelocity.Y, 0)
    end
end

local function applyJump()
    local char = player.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    hum.UseJumpPower = false
    hum.JumpHeight = state.jumpEnabled and state.jumpHeight or 7.2
end

task.spawn(function()
    while true do
        task.wait(0.07)

        if state.jumpEnabled then
            applyJump()
        end
    end
end)

local lastNoCooldownJump = 0

task.spawn(function()
    while true do
        task.wait()

        if state.noJumpCooldown then
            local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")

            if hum
                and hum.Health > 0
                and hum.FloorMaterial ~= Enum.Material.Air
                and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                local now = tick()
                if now - lastNoCooldownJump > 0.6 then
                    lastNoCooldownJump = now
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait()

        if state.noRagdoll then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if hum and hum.Health > 0 then
                local currentState = hum:GetState()
                if currentState == Enum.HumanoidStateType.FallingDown
                    or currentState == Enum.HumanoidStateType.Ragdoll
                    or currentState == Enum.HumanoidStateType.Physics then
                    hum.PlatformStand = false
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait()

        if state.stickToGround and not flying then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if hum
                and root
                and hum.Health > 0
                and hum.FloorMaterial == Enum.Material.Air then
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {char}

                local hit = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), params)
                local currentVelocity = root.AssemblyLinearVelocity

                if hit then
                    local distanceToGround = (root.Position.Y - hit.Position.Y)
                    local altitudeBoost = math.clamp(distanceToGround - 3, 0, 25) * 8
                    local targetDownforce = (distanceToGround <= 3 and -220 or -140) - altitudeBoost

                    if currentVelocity.Y > targetDownforce then
                        root.AssemblyLinearVelocity = Vector3.new(
                            currentVelocity.X,
                            targetDownforce,
                            currentVelocity.Z
                        )
                    end
                else
                    local highAirDownforce = -80 - math.clamp(math.abs(currentVelocity.Y) * 0.35, 0, 80)
                    if currentVelocity.Y > highAirDownforce then
                    root.AssemblyLinearVelocity = Vector3.new(
                        currentVelocity.X,
                        highAirDownforce,
                        currentVelocity.Z
                    )
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(math.max(1 / math.max(state.autoClickCps or 10, 1), 0.005))

        if state.autoClicker and state.autoClickerHolding and state.keybinds.AutoClicker ~= "None" then
            local mousePosition = UserInputService:GetMouseLocation()
            local shell = ui and ui.shell
            local shellPosition = shell and shell.AbsolutePosition
            local shellSize = shell and shell.AbsoluteSize
            local insideMenu = shell
                and shell.Visible
                and mousePosition.X >= shellPosition.X
                and mousePosition.X <= shellPosition.X + shellSize.X
                and mousePosition.Y >= shellPosition.Y
                and mousePosition.Y <= shellPosition.Y + shellSize.Y

            if not insideMenu then
                local buttonIndex = state.autoClickButton == "Right" and 1 or 0
                vim:SendMouseButtonEvent(mousePosition.X, mousePosition.Y, buttonIndex, true, game, 0)
                vim:SendMouseButtonEvent(mousePosition.X, mousePosition.Y, buttonIndex, false, game, 0)
            end
        end
    end
end)

local originalCollision = {}

local function cacheCharacterCollision()
    local char = player.Character
    if not char then return end

    originalCollision = {}

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            originalCollision[part] = part.CanCollide
        end
    end
end

local function updateNoClip()
    local char = player.Character
    if not char then return end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if state.noclip then
                part.CanCollide = false
            else
                if originalCollision[part] ~= nil then
                    part.CanCollide = originalCollision[part]
                end
            end
        end
    end
end


setNoClip = function(enabled)
    state.noclip = enabled

    if enabled then
        if noclipConnection then
            noclipConnection:Disconnect()
        end

        noclipConnection = RunService.Stepped:Connect(updateNoClip)
        updateNoClip()
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end

        updateNoClip()
    end
end


local flyConnection
local flying = false
local controls = {
    forward = 0,
    backward = 0,
    left = 0,
    right = 0,
    up = 0,
    down = 0
}

local function resetControls()
    controls.forward = 0
    controls.backward = 0
    controls.left = 0
    controls.right = 0
    controls.up = 0
    controls.down = 0
end


local flyKeyMap = {
    [Enum.KeyCode.W] = "forward",
    [Enum.KeyCode.S] = "backward",
    [Enum.KeyCode.A] = "left",
    [Enum.KeyCode.D] = "right",
    [Enum.KeyCode.Space] = "up",
    [Enum.KeyCode.LeftControl] = "down"
}


UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or not flying then return end
    local key = flyKeyMap[input.KeyCode]
    if key then
        controls[key] = 1
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local key = flyKeyMap[input.KeyCode]
    if key then
        controls[key] = 0
    end
end)


local function setFly(enabled)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local root = char.HumanoidRootPart
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

	
    flying = enabled
    state.flyEnabled = enabled
    if enabled then
        applyWalkSpeed()
    end

	if not enabled then
		resetControls()

		if flyConnection then
			flyConnection:Disconnect()
			flyConnection = nil
		end

		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero

		humanoid.PlatformStand = false
		humanoid.Sit = false
		humanoid.AutoRotate = true

		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		task.wait()
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
		task.wait()
		humanoid:ChangeState(Enum.HumanoidStateType.Landed)

        updateNoClip()
        task.defer(updateNoClip)

	root.CFrame = CFrame.new(root.Position)
    applyWalkSpeed()

	return
end
     
    resetControls()
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    root.AssemblyLinearVelocity = Vector3.zero

    humanoid.PlatformStand = false
    humanoid.AutoRotate = false

    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
        end
    end
	

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    flyConnection = RunService.Heartbeat:Connect(function()
        if not flying or not player.Character then return end

        local rootNow = player.Character:FindFirstChild("HumanoidRootPart")
        local humanoidNow = player.Character:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera
        if not rootNow or not humanoidNow or not cam then return end
         

        local lookVector = cam.CFrame.LookVector
		local rightVector = cam.CFrame.RightVector

		local moveDir =
			lookVector * (controls.forward - controls.backward) +
			rightVector * (controls.right - controls.left) +
			Vector3.new(0, controls.up - controls.down, 0)

		local velocity = Vector3.zero
		if moveDir.Magnitude > 0 then
			velocity = moveDir.Unit * state.flySpeed
		else
			velocity = Vector3.zero
		end

				humanoidNow:ChangeState(Enum.HumanoidStateType.Physics)
				rootNow.AssemblyAngularVelocity = Vector3.zero
				rootNow.AssemblyLinearVelocity = velocity

				
				
			end)
		end


player.CharacterAdded:Connect(function()
    task.wait(0.5)

    cacheCharacterCollision()
    applyWalkSpeed()
    applyJump()

    flying = false
    resetControls()

    setNoClip(state.noclip)

    if state.flyEnabled then
        setFly(true)
    end
end)

if player.Character then
    cacheCharacterCollision()
    setNoClip(state.noclip)
end

-- ==================== PLAYERS ====================


local function getSelectablePlayers()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            table.insert(list, plr.Name)
        end
    end
    table.sort(list)
    return list
end

local function findPlayerByName(name)
    if not name then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name == name then
            return plr
        end
    end
end

local function tpToSelectedPlayer()
    local target = findPlayerByName(state.selectedPlayer)
    local targetHRP = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and targetHRP then
        hrp.CFrame = targetHRP.CFrame + Vector3.new(0, 0, 3)
        tpNotify(target.Name)
    end
end

local function spectatePlayerByName(name)
    local target = findPlayerByName(name)
    local hum = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        workspace.CurrentCamera.CameraSubject = hum
        showNotification("Players", "Spectating " .. target.Name)
    end
end


local function stopSpectating()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        workspace.CurrentCamera.CameraSubject = hum
        showNotification("Players", "Stopped spectating")
    end
end


-- ==================== VISUALS ====================

local OverlayEnabled = false
local IgnoreSelf = false
local IgnoreDead = false

local BoxesEnabled = false
local SkeletonEnabled = false
local TracersEnabled = false
local DistanceEnabled = false
local NameEnabled = false
local FillEnabled = false
local BoxColor = Color3.fromRGB(175, 175, 175)
local CornerBoxesEnabled = false
local BaseBoxWidth = 4
local BaseBoxHeight = 6.5

local SkeletonColor = Color3.fromRGB(255, 255, 255)
local TracerColor = Color3.fromRGB(255, 255, 255)
local TextFont = Enum.Font.GothamBold

local Boxes = {}
local Skeletons = {}
local Tracers = {}
local DistanceLabels = {}
local NameLabels = {}
local CharacterConnections = {}

local SkeletonThickness = 1
local JointOverlap = 1

local FontOptions = {
    "SourceSans",
    "SourceSansBold",
    "SourceSansSemibold",
    "Gotham",
    "GothamBold",
    "GothamSemibold",
    "Arial",
    "ArialBold",
    "Fantasy",
    "Code",
    "SciFi",
    "Arcade",
    "Cartoon"
}

local R15Connections = {
    {"Head","UpperTorso"},
    {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},
    {"LeftUpperArm","LeftLowerArm"},
    {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},
    {"RightUpperArm","RightLowerArm"},
    {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},
    {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},
    {"RightUpperLeg","RightLowerLeg"},
    {"RightLowerLeg","RightFoot"}
}

local R6Connections = {
    {"Head","Torso"},
    {"Torso","Left Arm"},
    {"Torso","Right Arm"},
    {"Torso","Left Leg"},
    {"Torso","Right Leg"}
}

local function getRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getVisualHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function isAlive(character)
    local humanoid = getVisualHumanoid(character)
    return humanoid and humanoid.Health > 0
end

local function getConnections(character)
    if character and character:FindFirstChild("UpperTorso") then
        return R15Connections
    end
    return R6Connections
end

local function shouldShowTarget(playerObj)
    if not OverlayEnabled then
        return false
    end

    if not playerObj or (IgnoreSelf and playerObj == player) then
        return false
    end

    local character = playerObj.Character
    if not character then
        return false
    end

    local root = getRoot(character)
    if not root then
        return false
    end

    if IgnoreDead and not isAlive(character) then
        return false
    end

    local distance = (Camera.CFrame.Position - root.Position).Magnitude
    local meters = distance * 0.28

    if meters > state.visualMaxDistance then
        return false
    end

    return true
end

local function removeBox(playerObj)
    if Boxes[playerObj] then
        Boxes[playerObj]:Destroy()
        Boxes[playerObj] = nil
    end
end

local function removeSkeleton(playerObj)
    if Skeletons[playerObj] then
        for _, line in pairs(Skeletons[playerObj].lines) do
            line:Remove()
        end
        Skeletons[playerObj] = nil
    end
end

local function removeTracer(playerObj)
    if Tracers[playerObj] then
        Tracers[playerObj]:Remove()
        Tracers[playerObj] = nil
    end
end

local function removeDistance(playerObj)
    if DistanceLabels[playerObj] then
        local gui = DistanceLabels[playerObj].Parent
        DistanceLabels[playerObj] = nil
        if gui then
            gui:Destroy()
        end
    end
end

local function removeName(playerObj)
    if NameLabels[playerObj] then
        local gui = NameLabels[playerObj].Parent
        NameLabels[playerObj] = nil
        if gui then
            gui:Destroy()
        end
    end
end

local function removeAllForPlayer(playerObj)
    removeBox(playerObj)
    removeSkeleton(playerObj)
    removeTracer(playerObj)
    removeDistance(playerObj)
    removeName(playerObj)
end

local function clearAllVisuals()
    for _, playerObj in ipairs(Players:GetPlayers()) do
        removeAllForPlayer(playerObj)
    end
end

local function createBox(playerObj)
    if not BoxesEnabled then return end
    if not shouldShowTarget(playerObj) then
        removeBox(playerObj)
        return
    end

    local character = playerObj.Character
    local root = getRoot(character)
    if not root then return end
    local boxDisplayColor = BoxColor

    removeBox(playerObj)

    local box = Instance.new("BillboardGui")
    box.Name = "DEBUG_BOX"
    box.Adornee = root
    box.AlwaysOnTop = true
    box.LightInfluence = 0
    box.Size = UDim2.new(BaseBoxWidth, 0, BaseBoxHeight, 0)
    box.StudsOffsetWorldSpace = Vector3.new(0, -0.3, 0)
    box.Parent = character

    local frame = Instance.new("Frame")
    frame.Name = "Frame"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = FillEnabled and 0.6 or 1
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.Parent = box

    local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = boxDisplayColor
    stroke.Transparency = CornerBoxesEnabled and 1 or 0
	stroke.Parent = frame

    local function makeCorner(name, size, position, anchor)
        local corner = Instance.new("Frame")
        corner.Name = name
        corner.Size = size
        corner.Position = position
        corner.AnchorPoint = anchor or Vector2.zero
        corner.BackgroundColor3 = boxDisplayColor
        corner.BorderSizePixel = 0
        corner.Visible = CornerBoxesEnabled
        corner.Parent = frame
    end

    makeCorner("CornerTopLeftH", UDim2.new(0.34, 0, 0, 2), UDim2.new(0, 0, 0, 0))
    makeCorner("CornerTopLeftV", UDim2.new(0, 2, 0.14, 0), UDim2.new(0, 0, 0, 0))
    makeCorner("CornerTopRightH", UDim2.new(0.34, 0, 0, 2), UDim2.new(1, 0, 0, 0), Vector2.new(1, 0))
    makeCorner("CornerTopRightV", UDim2.new(0, 2, 0.14, 0), UDim2.new(1, 0, 0, 0), Vector2.new(1, 0))
    makeCorner("CornerBottomLeftH", UDim2.new(0.34, 0, 0, 2), UDim2.new(0, 0, 1, 0), Vector2.new(0, 1))
    makeCorner("CornerBottomLeftV", UDim2.new(0, 2, 0.14, 0), UDim2.new(0, 0, 1, 0), Vector2.new(0, 1))
    makeCorner("CornerBottomRightH", UDim2.new(0.34, 0, 0, 2), UDim2.new(1, 0, 1, 0), Vector2.new(1, 1))
    makeCorner("CornerBottomRightV", UDim2.new(0, 2, 0.14, 0), UDim2.new(1, 0, 1, 0), Vector2.new(1, 1))

    Boxes[playerObj] = box
end

local function createSkeleton(playerObj)
    if not SkeletonEnabled then return end
    if not shouldShowTarget(playerObj) then
        removeSkeleton(playerObj)
        return
    end

    local character = playerObj.Character
    if not character then return end

    local connections = getConnections(character)
    removeSkeleton(playerObj)

    Skeletons[playerObj] = {
        lines = {},
        rigTypeCount = #connections
    }

    for _ = 1, #connections do
        local line = Drawing.new("Line")
        line.Thickness = SkeletonThickness
        line.Color = SkeletonColor
        line.Transparency = 1
        line.Visible = false
        table.insert(Skeletons[playerObj].lines, line)
    end
end

local function createTracer(playerObj)
    if not TracersEnabled then return end
    if not shouldShowTarget(playerObj) then
        removeTracer(playerObj)
        return
    end

    if Tracers[playerObj] then return end

    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Color = TracerColor
    line.Transparency = 1
    line.Visible = false

    Tracers[playerObj] = line
end

local function createVisualLabel(playerObj, store, config)
    local character = playerObj.Character
    local root = getRoot(character)
    if not root or store[playerObj] then
        return nil
    end

    local gui = Instance.new("BillboardGui")
    gui.Name = config.guiName
    gui.Adornee = root
    gui.Size = config.size
    gui.AlwaysOnTop = true
    gui.StudsOffsetWorldSpace = config.offset
    gui.Parent = character

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.TextSize = 14
    label.Font = TextFont
    label.Text = config.text or ""
    label.Parent = gui

    store[playerObj] = label
    return label
end

local function createDistance(playerObj)
    if not DistanceEnabled then return end
    if not shouldShowTarget(playerObj) then
        removeDistance(playerObj)
        return
    end

    createVisualLabel(playerObj, DistanceLabels, {
        guiName = "DebugDistance",
        size = UDim2.fromOffset(120, 20),
        offset = Vector3.new(0, -4.5, 0)
    })
end

local function createName(playerObj)
    if not NameEnabled then return end
    if not shouldShowTarget(playerObj) then
        removeName(playerObj)
        return
    end

    createVisualLabel(playerObj, NameLabels, {
        guiName = "DebugName",
        size = UDim2.fromOffset(140, 20),
        offset = Vector3.new(0, 4.3, 0),
        text = playerObj.Name
    })
end

local function refreshPlayerVisuals(playerObj)
    if not shouldShowTarget(playerObj) then
        removeAllForPlayer(playerObj)
        return
    end

    createBox(playerObj)
    createSkeleton(playerObj)
    createTracer(playerObj)
    createDistance(playerObj)
    createName(playerObj)
end

local function refreshAllVisuals()
    if not OverlayEnabled then
        clearAllVisuals()
        return
    end

    for _, playerObj in ipairs(Players:GetPlayers()) do
        refreshPlayerVisuals(playerObj)
    end
end


local function updateFill()
    for _, playerObj in ipairs(Players:GetPlayers()) do
        local box = Boxes[playerObj]
        if box then
            local frame = box:FindFirstChild("Frame")
            if frame then
                frame.BackgroundTransparency = FillEnabled and 0.6 or 1
                frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

                local stroke = frame:FindFirstChildOfClass("UIStroke")
                if stroke then
                    stroke.Color = BoxColor
                    stroke.Thickness = 2
                    stroke.Transparency = CornerBoxesEnabled and 1 or 0
                end

                for _, child in ipairs(frame:GetChildren()) do
                    if child:IsA("Frame") and child.Name:find("^Corner") then
                        child.BackgroundColor3 = BoxColor
                        child.Visible = CornerBoxesEnabled
                    end
                end
            end
        end
    end
end

local function setupVisualPlayer(playerObj)
    if CharacterConnections[playerObj] then
        CharacterConnections[playerObj]:Disconnect()
    end

    if playerObj.Character then
        refreshPlayerVisuals(playerObj)
    end

    CharacterConnections[playerObj] = playerObj.CharacterAdded:Connect(function()
        task.wait(0.5)
        refreshPlayerVisuals(playerObj)
    end)
end

Players.PlayerAdded:Connect(setupVisualPlayer)

Players.PlayerRemoving:Connect(function(playerObj)
    removeAllForPlayer(playerObj)

    if CharacterConnections[playerObj] then
        CharacterConnections[playerObj]:Disconnect()
        CharacterConnections[playerObj] = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if not OverlayEnabled then
        return
    end

    local cameraPosition = Camera.CFrame.Position
    local viewportSize = Camera.ViewportSize

    for _, playerObj in ipairs(Players:GetPlayers()) do
        local character = playerObj.Character

        if not shouldShowTarget(playerObj) then
            removeAllForPlayer(playerObj)
            continue
        end

        local root = character and getRoot(character)
        local studs = root and (cameraPosition - root.Position).Magnitude or 0
        local meters = studs * 0.28

        if SkeletonEnabled then
            local connections = getConnections(character)

                if not Skeletons[playerObj] or Skeletons[playerObj].rigTypeCount ~= #connections then
                    createSkeleton(playerObj)
                end

                local data = Skeletons[playerObj]
                if data then
                    local skeletonDisplayColor = SkeletonColor
                    for i, pair in ipairs(connections) do
                        local part1 = character:FindFirstChild(pair[1])
                        local part2 = character:FindFirstChild(pair[2])
                        local line = data.lines[i]

                        if part1 and part2 and line then
                            local pos1, vis1 = Camera:WorldToViewportPoint(part1.Position)
                            local pos2, vis2 = Camera:WorldToViewportPoint(part2.Position)

                            if vis1 and vis2 then
                                local p1 = Vector2.new(pos1.X, pos1.Y)
                                local p2 = Vector2.new(pos2.X, pos2.Y)
                                local dir = p2 - p1

                                if dir.Magnitude > 0 then
                                    dir = dir.Unit
                                    p1 = p1 - dir * JointOverlap
                                    p2 = p2 + dir * JointOverlap
                                end

                                line.Visible = true
                                line.Color = skeletonDisplayColor
                                line.Thickness = SkeletonThickness
                                line.From = p1
                                line.To = p2
                            else
                                line.Visible = false
                            end
                        elseif line then
                            line.Visible = false
                        end
                    end
                end
            else
                removeSkeleton(playerObj)
            end

            if TracersEnabled then
                if not Tracers[playerObj] then
                    createTracer(playerObj)
                end

                local line = Tracers[playerObj]

                if root and line then
                    local tracerDisplayColor = TracerColor
                    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        line.Visible = true
                        line.Color = tracerDisplayColor
                        line.Thickness = 1.5
                        line.From = Vector2.new(viewportSize.X / 2, viewportSize.Y)
                        line.To = Vector2.new(pos.X, pos.Y)
                    else
                        line.Visible = false
                    end
                elseif line then
                    line.Visible = false
                end
            else
                removeTracer(playerObj)
            end

            if DistanceEnabled then
                if not DistanceLabels[playerObj] then
                    createDistance(playerObj)
                end

                local label = DistanceLabels[playerObj]

                if label and root then
                    local dist = math.floor(meters)
                    local gui = label.Parent
                    if gui then
                        local offset = math.clamp(studs / 120, 0, 1.2)
                        gui.StudsOffsetWorldSpace = Vector3.new(0, -4.5 - offset, 0)
                    end
                    label.TextColor3 = Color3.new(1, 1, 1)
                    label.Text = dist .. "m"
                    label.TextSize = math.clamp(18 - (studs / 20), 10, 18)
                end
            else
                removeDistance(playerObj)
            end

            if NameEnabled then
                if not NameLabels[playerObj] then
                    createName(playerObj)
                end

                local label = NameLabels[playerObj]

                if label and root then
                    local gui = label.Parent
                    if gui then
                        local offset = math.clamp(studs / 120, 0, 1.2)
                        gui.StudsOffsetWorldSpace = Vector3.new(0, 4.3 + offset, 0)
                    end
                    label.TextColor3 = Color3.new(1, 1, 1)
                    label.TextSize = math.clamp(18 - (studs / 20), 10, 18)
                    label.Text = playerObj.Name
                end
            else
                removeName(playerObj)
            end

        if BoxesEnabled then
            if not Boxes[playerObj] then
                createBox(playerObj)
            end

            local box = Boxes[playerObj]
            if box and root then
                local boxDisplayColor = BoxColor
                local distanceBoost = meters > 20 and math.clamp((meters - 20) / 95, 0, 0.38) or 0
                local farBoxBoost = meters > 180 and math.clamp((meters - 180) / 45, 0, 1.2) or 0
                local farLineBoost = meters > 100 and math.clamp((meters - 100) / 90, 0, 0.08) or 0
                box.Size = UDim2.new(BaseBoxWidth + distanceBoost + farBoxBoost, 0, BaseBoxHeight + (distanceBoost * 0.75) + (farBoxBoost * 1.1), 0)

                local frame = box:FindFirstChild("Frame")
                if frame then
                    local stroke = frame:FindFirstChildOfClass("UIStroke")
                    if stroke then
                        stroke.Color = boxDisplayColor
                        stroke.Thickness = 2
                        stroke.Transparency = CornerBoxesEnabled and 1 or 0
                    end

                    local cornerScale = 0.34 + (distanceBoost * 0.018)
                    local verticalScale = 0.14 + (distanceBoost * 0.01) + farLineBoost
                    local cornerThickness = math.max(1, 2 - (distanceBoost * 0.45))
                    for _, child in ipairs(frame:GetChildren()) do
                        if child:IsA("Frame") and child.Name:find("H$") then
                            child.BackgroundColor3 = boxDisplayColor
                            child.Size = UDim2.new(cornerScale, 0, 0, cornerThickness)
                        elseif child:IsA("Frame") and child.Name:find("V$") then
                            child.BackgroundColor3 = boxDisplayColor
                            child.Size = UDim2.new(0, cornerThickness, verticalScale, 0)
                        end
                    end
                end
            end
        else
            removeBox(playerObj)
        end
    end
end)

for _, playerObj in ipairs(Players:GetPlayers()) do
    setupVisualPlayer(playerObj)
end


local function setVisualToggle(enabled, setFlag, removeFunc)
    setFlag(enabled)

    if not enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            removeFunc(p)
        end
    else
        refreshAllVisuals()
    end
end


-- ==================== CONTROL CALLBACK TABLES ====================

local toggleHandlers = {
    ["Start Collect"] = function(enabled, section) startFarm(section, enabled) end,

    ["Start Process"] = startProcess,

    ["Toggle"] = function(enabled, section)
        if section == "Speed" then
            state.walkSpeedEnabled = enabled
            applyWalkSpeed()
        elseif section == "Fly" then
            setFly(enabled)
        elseif section == "Super Jump" then
            state.jumpEnabled = enabled
            applyJump()
        elseif section == "Aim Assist" then
            AimEnabled = enabled
        elseif section == "Auto Clicker" then
            state.autoClicker = enabled
            if not enabled then
                state.autoClickerHolding = false
            end
        end
    end,

    ["No Jump Cooldown"] = function(enabled) state.noJumpCooldown = enabled end,
    ["High Gravity"] = function(enabled) state.stickToGround = enabled end,
    ["No Ragdoll"] = function(enabled) state.noRagdoll = enabled end,
    ["Auto Clicker"] = function(enabled)
        state.autoClicker = enabled
        if not enabled then
            state.autoClickerHolding = false
        end
    end,
    ["NoClip"] = setNoClip,

    ["Enabled"] = function(enabled)
        OverlayEnabled = enabled
        refreshAllVisuals()
    end,

    ["Boxes"] = function(enabled)
		setVisualToggle(enabled, function(v) BoxesEnabled = v end, removeBox)
	end,

	["Skeleton"] = function(enabled)
		setVisualToggle(enabled, function(v) SkeletonEnabled = v end, removeSkeleton)
	end,

	["Tracers"] = function(enabled)
		setVisualToggle(enabled, function(v) TracersEnabled = v end, removeTracer)
	end,

	["Distance"] = function(enabled)
		setVisualToggle(enabled, function(v) DistanceEnabled = v end, removeDistance)
	end,

	["Nametags"] = function(enabled)
		setVisualToggle(enabled, function(v) NameEnabled = v end, removeName)
	end,
    ["Ignore Dead"] = function(enabled)
        IgnoreDead = enabled
        refreshAllVisuals()
    end,

    ["Ignore Self"] = function(enabled)
        IgnoreSelf = enabled
        refreshAllVisuals()
    end,


    ["Filled Boxes"] = function(enabled)
        FillEnabled = enabled
        updateFill()
    end,
    ["Corner Boxes"] = function(enabled)
        CornerBoxesEnabled = enabled
        updateFill()
    end,



	


}


local function destructEverything()
    -- farm / process
	for farmName in pairs(farmStates) do
		farmStates[farmName] = false
	end
	processing = false

    -- movement states
    state.walkSpeedEnabled = false
    state.flyEnabled = false
    state.jumpEnabled = false
	state.noJumpCooldown = false
    state.stickToGround = false
    state.noRagdoll = false
    state.noclip = false
    state.autoClicker = false
    state.autoClickerHolding = false
    state.autoClickerMode = "Hold"
    -- visuals
    OverlayEnabled = false
    IgnoreSelf = false
    BoxesEnabled = false
    SkeletonEnabled = false
    TracersEnabled = false
    DistanceEnabled = false
    NameEnabled = false
    FillEnabled = false


	if keybindConnection then
		keybindConnection:Disconnect()
		keybindConnection = nil
	end
    if keybindReleaseConnection then
        keybindReleaseConnection:Disconnect()
        keybindReleaseConnection = nil
    end


    -- AIM CLEANUP
    AimEnabled = false
    AimHolding = false
    AimHoldKey = "None"
    state.aimToggleActive = false
    ShowFOVCircle = false
    if FOVCircle then
        pcall(function() FOVCircle:Remove() end)
        FOVCircle = nil
    end
    if aimConnection then
        RunService:UnbindFromRenderStep(AIM_RENDERSTEP_NAME)
        aimConnection = nil
    end


	

    -- stop spectate
    stopSpectating()

    -- stop fly
	setFly(false)
	flying = false
	resetControls()
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end

	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

	if hum then
		hum.PlatformStand = false
		hum.Sit = false
		hum.AutoRotate = true
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		task.wait()
		hum:ChangeState(Enum.HumanoidStateType.Running)
	end

	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end

    -- stop noclip
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    updateNoClip()

    -- restore jump
    applyJump()

    -- clear visuals
    clearAllVisuals()

    -- remove per-player visual listeners
    for plr, conn in pairs(CharacterConnections) do
        if conn then
            conn:Disconnect()
        end
        CharacterConnections[plr] = nil
    end

    -- remove blur if somehow still there
    local blur = Lighting:FindFirstChild("BanskoIntroBlur")
    if blur then
        blur:Destroy()
    end

    -- destroy ui last
	if screenGui then
		screenGui:Destroy()
	end

    if shared then
        shared.BanskoShutdown = nil
    end
end

shared.BanskoShutdown = destructEverything

local buttonHandlers = {
    ["Goto Seller"] = function(_, section)
        local target = sellerPositions[section]
        if target then
            safeTeleport(target, "Seller")
        end
    end,

    ["Tp to Player"] = tpToSelectedPlayer,

    ["Spectate Player"] = function() spectatePlayerByName(state.selectedPlayer) end,
    ["Spectate Staff"] = function() spectatePlayerByName(state.selectedStaff) end,

    ["Stop Spectating"] = stopSpectating,
    ["Goto Crate"] = gotoCrate1,
    ["Goto Treasure"] = gotoTreasure,
    ["Reset Defaults"] = resetThemeDefaults,
    ["Destruct"] = destructEverything,
}

for buttonName, cf in pairs(locations) do
    buttonHandlers[buttonName] = function()
        if cf.Position.Magnitude > 0 then
            safeTeleport(cf, buttonName:gsub("^Goto ", ""))
        end
    end
end

local sliderHandlers = {
    ["Walk Speed"] = function(value)
        state.walkSpeedMultiplier = tonumber(string.format("%.1f", value))
        applyWalkSpeed()
    end,
    ["Fly Speed"] = function(value) state.flySpeed = value end,
    ["Jump Height"] = function(value) state.jumpHeight = value applyJump() end,
    ["UI Scale"] = function(value) ui.menuScale.Scale = value / 100 end,
    ["CPS"] = function(value) state.autoClickCps = math.clamp(math.floor(value + 0.5), 1, 200) end,
    ["Max Distance"] = function(value) state.visualMaxDistance = value refreshAllVisuals() end,
}










-- ====================  AIM ASSIST ====================

local function getViewportCenter()
    Camera = workspace.CurrentCamera or Camera
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function getClosestPlayerToCrosshair()
    local closestTarget = nil
    local closestScreenDistance = math.huge
    local center = getViewportCenter()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local targetPart = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist2D <= FOVRadius and dist2D < closestScreenDistance then
                            closestScreenDistance = dist2D
                            closestTarget = targetPart
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

do
    local ok, circle = pcall(function()
        return Drawing.new("Circle")
    end)

    if ok and circle then
        FOVCircle = circle
        FOVCircle.Thickness = 2
        FOVCircle.NumSides = 100
        FOVCircle.Radius = FOVRadius
        FOVCircle.Filled = false
        FOVCircle.Transparency = 1
        FOVCircle.Color = Color3.fromRGB(255, 255, 255)
        FOVCircle.Visible = ShowFOVCircle
    else
        FOVCircle = nil
    end
end

RunService:UnbindFromRenderStep(AIM_RENDERSTEP_NAME)
aimConnection = true
RunService:BindToRenderStep(AIM_RENDERSTEP_NAME, Enum.RenderPriority.Last.Value, function()
    Camera = workspace.CurrentCamera or Camera

    if FOVCircle then
        FOVCircle.Visible = ShowFOVCircle
        FOVCircle.Position = getViewportCenter()
        FOVCircle.Radius = FOVRadius
    end

    if not AimEnabled then return end
    if AimHoldKey == "None" then return end
    if not AimHolding then return end

    local targetPart = getClosestPlayerToCrosshair()
    if not targetPart then return end

    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
    if not onScreen then return end

    local center = getViewportCenter()
    local deltaX = (screenPos.X - center.X) * AimStrength
    local deltaY = (screenPos.Y - center.Y) * AimStrength

    if type(mousemoverel) == "function" then
        pcall(mousemoverel, deltaX, deltaY)
    end
end)

-- Handlers
toggleHandlers["Aim Assist"] = function(enabled)
    AimEnabled = enabled
end

toggleHandlers["Show FOV"] = function(enabled)
    ShowFOVCircle = enabled
end

sliderHandlers["FOV Size"] = function(value)
    FOVRadius = math.clamp(value, 1, 500)
end

sliderHandlers["Smoothness"] = function(value)
    local smooth = math.clamp(value, 0, 100) / 100
    AimStrength = 0.02 + ((1 - smooth) ^ 2.05) * 1.08
end

















local knownStaff = {} -- [UserId] = playerName

local function isStaffPlayer(plr)
    if not plr or plr == player then
        return false
    end

    if knownStaff[plr.UserId] then
        return true
    end

    if plr.Team then
        local teamName = plr.Team.Name:lower()
        if teamName:find("staff") or teamName:find("admin") or teamName:find("mod") then
            return true
        end
    end

    local lowerName = plr.Name:lower()
    local lowerDisplay = (plr.DisplayName or ""):lower()

    return lowerName:find("admin")
        or lowerName:find("mod")
        or lowerName:find("staff")
        or lowerDisplay:find("admin")
        or lowerDisplay:find("mod")
        or lowerDisplay:find("staff")
end

local function notifyExistingStaff()
    local foundStaff = false

    for _, plr in ipairs(Players:GetPlayers()) do
        if isStaffPlayer(plr) then
            foundStaff = true
            knownStaff[plr.UserId] = plr.Name

            showStaffNotification("STAFF DETECTED", plr.Name)
        end
    end

    if not foundStaff then
		showStaffNotification("SERVER STATUS", "No staff Detected")
	end
end


local function getSelectableStaff()
    local list = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and knownStaff[plr.UserId] then
            table.insert(list, plr.Name)
        end
    end

    table.sort(list)
    return list
end


Players.PlayerAdded:Connect(function(plr)
    task.wait(1)

    if isStaffPlayer(plr) then
        knownStaff[plr.UserId] = plr.Name
        showStaffNotification("STAFF JOINED", plr.Name)
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    knownStaff[plr.UserId] = nil
end)


local keybindOptions = {"None", "Q", "E", "R", "T", "V"}

local dropdownSources = {
    ["Select Player"] = getSelectablePlayers,
    ["Select Staff"] = getSelectableStaff,
    ["Aim Key (Hold)"] = function() return keybindOptions end,
    ["Aim Mode"] = function() return {"Hold", "Toggle"} end,
    ["Auto Clicker Mode"] = function() return {"Hold", "Toggle"} end,
    ["Click Button"] = function() return {"Left", "Right"} end,
    ["Text Style"] = function() return FontOptions end,
    ["Speed"] = function() return keybindOptions end,
    ["Fly"] = function() return keybindOptions end,
    ["Auto Clicker Key"] = function() return keybindOptions end,
    ["Jump"] = function() return keybindOptions end,
}


local dropdownHandlers = {
    ["Select Player"] = function(value) state.selectedPlayer = value end,
    ["Select Staff"] = function(value) state.selectedStaff = value end,
    ["Aim Key (Hold)"] = function(value)
        AimHoldKey = value
        AimHolding = false
        state.aimToggleActive = false
    end,
    ["Aim Mode"] = function(value)
        state.aimMode = value
        AimHolding = false
        state.aimToggleActive = false
    end,
    ["Auto Clicker Mode"] = function(value)
        state.autoClickerMode = value
        state.autoClickerHolding = false
    end,
    ["Menu Key"] = function(value)
        MenuToggleKey = value
    end,
    ["Click Button"] = function(value) state.autoClickButton = value end,
    ["Speed"] = function(value) state.keybinds.Speed = value end,
    ["Fly"] = function(value) state.keybinds.Fly = value end,
    ["Auto Clicker Key"] = function(value) state.keybinds.AutoClicker = value end,
    ["Jump"] = function(value) state.keybinds.Jump = value end,
    ["Text Style"] = function(value)
        if Enum.Font[value] then
            TextFont = Enum.Font[value]
            for _, label in pairs(DistanceLabels) do label.Font = TextFont end
            for _, label in pairs(NameLabels) do label.Font = TextFont end
        end
    end,
}

local activeVisualColorPicker
local toggleVisualSetters = {}

local function getToggleVisualKey(section, control)
    return tostring(section or "") .. ":" .. tostring(control or "")
end

local function syncToggleVisual(section, control, value)
    local setter = toggleVisualSetters[getToggleVisualKey(section, control)]
    if setter then
        setter(value)
    end
end


local function notifyKeybind(name, enabled)
    showNotification("Keybind", name .. " " .. (enabled and "enabled" or "disabled"))
end

shared.BanskoAimKeyDown = function(keyName)
    if AimHoldKey ~= "None" and AimHoldKey == keyName then
        if state.aimMode == "Toggle" then
            state.aimToggleActive = not state.aimToggleActive
            AimHolding = state.aimToggleActive
        else
            AimHolding = true
        end
    end
end

shared.BanskoAimKeyUp = function(keyName)
    if state.aimMode ~= "Toggle" and AimHoldKey ~= "None" and AimHoldKey == keyName then
        AimHolding = false
    end
end

local function runKeybind(keyName)
    if not keyName then return end

    if state.keybinds.Speed == keyName then
        state.walkSpeedEnabled = not state.walkSpeedEnabled
        applyWalkSpeed()
        syncToggleVisual("Speed", "Toggle", state.walkSpeedEnabled)
        notifyKeybind("Speed", state.walkSpeedEnabled)
    end

    if state.keybinds.Fly == keyName then
        setFly(not state.flyEnabled)
        syncToggleVisual("Fly", "Toggle", state.flyEnabled)
        notifyKeybind("Fly", state.flyEnabled)
    end

    if state.keybinds.AutoClicker == keyName then
        if state.autoClickerMode == "Toggle" then
            state.autoClickerHolding = not state.autoClickerHolding
        else
            state.autoClickerHolding = true
        end
    end

    if state.keybinds.Jump == keyName then
        state.jumpEnabled = not state.jumpEnabled
        applyJump()
        syncToggleVisual("Super Jump", "Toggle", state.jumpEnabled)
        notifyKeybind("Jump", state.jumpEnabled)
    end

    shared.BanskoAimKeyDown(keyName)
end

keybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Escape and state.autoClicker then
        state.autoClicker = false
        state.autoClickerHolding = false
        syncToggleVisual("Auto Clicker", "Toggle", false)
        notifyKeybind("Auto Clicker", false)
        return
    end

    if isBindingKey or UserInputService:GetFocusedTextBox() then return end

    runKeybind(getInputBindName(input))
end)

keybindReleaseConnection = UserInputService.InputEnded:Connect(function(input)
    local keyName = getInputBindName(input)
    if not keyName then return end

    shared.BanskoAimKeyUp(keyName)

    if state.autoClickerMode ~= "Toggle" and state.keybinds.AutoClicker == keyName then
        state.autoClickerHolding = false
    end
end)

local function makeControl(parent, spec, currentSection, currentTabName)
    local controlType, controlName = spec:match("([^:]+):(.+)")

    if controlType == "button" then
        local isThemeResetButton = currentSection == "Theme Editor" and controlName == "Reset Defaults"
        local buttonParent = parent
        local buttonWidth = UDim2.new(1, 0, 0, 29)
        local buttonPosition = nil

        if isThemeResetButton then
            buttonParent = create("Frame", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                Parent = parent
            })
            buttonWidth = UDim2.new(0, 124, 0, 24)
            buttonPosition = UDim2.new(0.5, -62, 0, 2)
        end

        local buttonFrame = create("TextButton", {
            Size = buttonWidth,
            Position = buttonPosition,
            BackgroundColor3 = isThemeResetButton and Color3.fromRGB(58, 50, 112) or theme.cardAlt,
            BorderSizePixel = 0,
            Text = controlName,
            Font = Enum.Font.GothamBold,
            TextSize = isThemeResetButton and 10 or 11,
            TextColor3 = isThemeResetButton and theme.accent or theme.text,
			TextStrokeTransparency = 1,
            AutoButtonColor = false,
            Parent = buttonParent
        })
		
		buttonFrame.RichText = true

		controlLabelsByTab[currentTabName] = controlLabelsByTab[currentTabName] or {}
		controlOriginalText[currentTabName] = controlOriginalText[currentTabName] or {}

		table.insert(controlLabelsByTab[currentTabName], buttonFrame)
		table.insert(controlOriginalText[currentTabName], controlName)
		
        create("UICorner", { CornerRadius = UDim.new(0, isThemeResetButton and 6 or 8), Parent = buttonFrame })
        create("UIStroke", { Color = isThemeResetButton and theme.accent or theme.stroke, Thickness = 1, Transparency = isThemeResetButton and 0.3 or 0, Parent = buttonFrame })

        buttonFrame.MouseEnter:Connect(function()
            TweenService:Create(buttonFrame, TweenInfo.new(0.15), {
                BackgroundColor3 = isThemeResetButton and Color3.fromRGB(72, 63, 136) or theme.accent,
                TextColor3 = theme.text
            }):Play()
        end)

        buttonFrame.MouseLeave:Connect(function()
            TweenService:Create(buttonFrame, TweenInfo.new(0.15), {
                BackgroundColor3 = isThemeResetButton and Color3.fromRGB(58, 50, 112) or theme.cardAlt,
                TextColor3 = isThemeResetButton and theme.accent or theme.text
            }):Play()
        end)

        buttonFrame.MouseButton1Click:Connect(function()
			local handler = buttonHandlers[controlName]
			if handler then
				handler(controlName, currentSection)
			end
		end)

    elseif controlType == "toggle" then
        local isVisualBoxesToggle = controlName == "Boxes" and currentTabName == "Visuals"

        local row = create("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            ClipsDescendants = false,
            Parent = parent
        })

        local isVisualColorToggle = currentTabName == "Visuals" and (controlName == "Boxes" or controlName == "Skeleton" or controlName == "Tracers")

        local toggle = create("TextButton", {
            Size = UDim2.fromOffset(17, 17),
            Position = isVisualColorToggle and UDim2.fromOffset(0, 4) or UDim2.new(0, 0, 0.5, -8.5),
            BackgroundColor3 = theme.cardAlt,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = row
        })
        create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = toggle })
        create("UIStroke", { Color = theme.stroke, Thickness = 1, Transparency = 0.2, Parent = toggle })

        local toggleLabel = create("TextLabel", {
			Size = UDim2.new(1, -28, 0, 26),
            Position = UDim2.fromOffset(28, -1),
			BackgroundTransparency = 1,
			Text = controlName,
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = theme.softText,
			TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
			Parent = row
		})

		toggleLabel.RichText = true

		controlLabelsByTab[currentTabName] = controlLabelsByTab[currentTabName] or {}
		controlOriginalText[currentTabName] = controlOriginalText[currentTabName] or {}

		table.insert(controlLabelsByTab[currentTabName], toggleLabel)
		table.insert(controlOriginalText[currentTabName], controlName)

        local enabled = false
        local subRow
        local palette
        local preview
        local selector
        local draggingPicker = false
        local blendPalette
        local blendSelector
        local draggingBlend = false
        local cornerToggleRow
        local cornerToggle
        local currentHue = 0
        local currentBlend = 0
        local singleBarOnly = controlName == "Skeleton" or controlName == "Tracers"
        local currentBaseColor =
            controlName == "Boxes" and BoxColor
            or (controlName == "Skeleton" and SkeletonColor or TracerColor)

        local function setToggleVisual(value)
            enabled = value
            TweenService:Create(toggle, TweenInfo.new(0.18), {
                BackgroundColor3 = enabled and theme.accent or theme.cardAlt
            }):Play()

            if subRow then
                subRow.Visible = enabled
                palette.Visible = false
                selector.Visible = false
                if blendPalette then
                    blendPalette.Visible = false
                end
                if blendSelector then
                    blendSelector.Visible = false
                end
                if activeVisualColorPicker and activeVisualColorPicker.row == row then
                    activeVisualColorPicker = nil
                end
                row.Size = UDim2.new(1, 0, 0, enabled and (controlName == "Boxes" and 78 or 52) or 26)
            end
        end

        toggleVisualSetters[getToggleVisualKey(currentSection, controlName)] = setToggleVisual

        if isVisualColorToggle then
            subRow = create("Frame", {
                Size = UDim2.new(1, -28, 0, controlName == "Boxes" and 46 or 20),
                Position = UDim2.fromOffset(28, 30),
                BackgroundTransparency = 1,
                Visible = false,
                Parent = row
            })

            if controlName == "Boxes" then
                cornerToggleRow = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Parent = subRow
                })

                cornerToggle = create("TextButton", {
                    Size = UDim2.fromOffset(16, 16),
                    Position = UDim2.fromOffset(0, 2),
                    BackgroundColor3 = CornerBoxesEnabled and theme.accent or theme.cardAlt,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = cornerToggleRow
                })
                create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = cornerToggle })
                create("UIStroke", { Color = theme.stroke, Thickness = 1, Parent = cornerToggle })

                local cornerToggleLabel = create("TextLabel", {
                    Size = UDim2.new(1, -26, 1, 0),
                    Position = UDim2.fromOffset(26, 0),
                    BackgroundTransparency = 1,
                    Text = "Corner Boxes",
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextColor3 = theme.softText,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = cornerToggleRow
                })

                cornerToggleLabel.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and cornerToggle then
                        cornerToggle:Activate()
                    end
                end)
            end

            local subLabel = create("TextLabel", {
                Size = UDim2.new(1, -50, 0, 16),
                Position = UDim2.fromOffset(0, controlName == "Boxes" and 29 or 5),
                BackgroundTransparency = 1,
                Text = "Custom color",
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = theme.softText,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                Parent = subRow
            })

            preview = create("TextButton", {
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.new(0, 78, 0, controlName == "Boxes" and 29 or 5),
                BackgroundColor3 = currentBaseColor,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Parent = subRow
            })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = preview })
            create("UIStroke", { Color = theme.stroke, Thickness = 1, Parent = preview })

            palette = create("TextButton", {
                Size = UDim2.new(1, -4, 0, 16),
                Position = UDim2.fromOffset(0, controlName == "Boxes" and 50 or 26),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Visible = false,
                Parent = subRow
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = palette })

            create("UIGradient", {
                Name = "BoxPickerGradient",
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                }),
                Parent = palette
            })

            selector = create("Frame", {
                Size = UDim2.fromOffset(6, 20),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundColor3 = theme.text,
                BorderSizePixel = 0,
                Visible = false,
                Parent = palette
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = selector })
            create("UIStroke", { Color = theme.background, Thickness = 1, Parent = selector })

            if not singleBarOnly then
                blendPalette = create("TextButton", {
                    Size = UDim2.new(1, -4, 0, 16),
                    Position = UDim2.fromOffset(0, controlName == "Boxes" and 70 or 46),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    Visible = false,
                    Parent = subRow
                })
                create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = blendPalette })

                create("UIGradient", {
                    Name = "BoxBlendGradient",
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, currentBaseColor),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                    }),
                    Parent = blendPalette
                })

                blendSelector = create("Frame", {
                    Size = UDim2.fromOffset(6, 20),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(currentBlend, 0, 0.5, 0),
                    BackgroundColor3 = theme.text,
                    BorderSizePixel = 0,
                    Visible = false,
                    Parent = blendPalette
                })
                create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = blendSelector })
                create("UIStroke", { Color = theme.background, Thickness = 1, Parent = blendSelector })
            end

        end


        local function setToggle()
            setToggleVisual(not enabled)

            local handlerName = controlName
            if controlName == "Toggle" and (currentSection == "Aim Assist" or currentSection == "Auto Clicker") then
                handlerName = currentSection
            end

            local handler = toggleHandlers[handlerName]
            if handler then
                handler(enabled, currentSection)
            end

            local message = controlName .. (enabled and " enabled" or " disabled")
            showNotification("Toggle", message)
        end

        toggle.MouseButton1Click:Connect(setToggle)
        toggleLabel.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                setToggle()
            end
        end)

        if preview and palette and selector then
            local function applyControlColor(silent)
                local blendAmount = singleBarOnly and 0 or currentBlend
                local color = currentBaseColor:Lerp(Color3.fromRGB(255, 255, 255), blendAmount)
                if not singleBarOnly and currentBlend >= 0.995 then
                    color = Color3.fromRGB(175, 175, 175)
                end
                preview.BackgroundColor3 = color
                if controlName == "Boxes" then
                    BoxColor = color
                    updateFill()
                elseif controlName == "Skeleton" then
                    SkeletonColor = color
                elseif controlName == "Tracers" then
                    TracerColor = color
                end

                if not silent then
                    showNotification("Visuals", controlName .. " color changed")
                end
            end

            local function refreshBlendGradient()
                if not blendPalette then
                    return
                end

                local gradient = blendPalette:FindFirstChild("BoxBlendGradient")
                if gradient then
                    gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, currentBaseColor),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                    })
                end
            end

            local function setBoxColorFromX(mouseX, silent)
                local amount = math.clamp((mouseX - palette.AbsolutePosition.X) / math.max(palette.AbsoluteSize.X, 1), 0, 1)
                selector.Position = UDim2.new(amount, 0, 0.5, 0)
                selector.Visible = true
                currentHue = amount
                currentBaseColor = Color3.fromHSV(amount, 0.83, 0.98)
                refreshBlendGradient()
                applyControlColor(silent)
            end

            local function setBlendFromX(mouseX, silent)
                if not blendPalette or not blendSelector then
                    return
                end

                local amount = math.clamp((mouseX - blendPalette.AbsolutePosition.X) / math.max(blendPalette.AbsoluteSize.X, 1), 0, 1)
                currentBlend = amount
                blendSelector.Position = UDim2.new(amount, 0, 0.5, 0)
                blendSelector.Visible = true
                applyControlColor(silent)
            end

            preview.MouseButton1Click:Connect(function()
                if not subRow.Visible then
                    return
                end

                local nextVisible = not palette.Visible
                if nextVisible and activeVisualColorPicker and activeVisualColorPicker.row ~= row then
                    activeVisualColorPicker.palette.Visible = false
                    activeVisualColorPicker.selector.Visible = false
                    if activeVisualColorPicker.blendPalette then
                        activeVisualColorPicker.blendPalette.Visible = false
                    end
                    if activeVisualColorPicker.blendSelector then
                        activeVisualColorPicker.blendSelector.Visible = false
                    end
                    activeVisualColorPicker.row.Size = UDim2.new(1, 0, 0, activeVisualColorPicker.collapsedHeight)
                end

                palette.Visible = nextVisible
                selector.Visible = palette.Visible
                if blendPalette then
                    blendPalette.Visible = palette.Visible
                end
                if blendSelector then
                    blendSelector.Visible = palette.Visible
                end
                if palette.Visible then
                    activeVisualColorPicker = {
                        row = row,
                        palette = palette,
                        selector = selector,
                        blendPalette = blendPalette,
                        blendSelector = blendSelector,
                        collapsedHeight = controlName == "Boxes" and 78 or 52
                    }
                elseif activeVisualColorPicker and activeVisualColorPicker.row == row then
                    activeVisualColorPicker = nil
                end
                local expandedHeight
                if controlName == "Boxes" then
                    expandedHeight = 118
                elseif singleBarOnly then
                    expandedHeight = 72
                else
                    expandedHeight = 92
                end
                row.Size = UDim2.new(1, 0, 0, palette.Visible and expandedHeight or (controlName == "Boxes" and 78 or 52))
            end)

            if cornerToggle then
                local function setCornerToggleState(value)
                    TweenService:Create(cornerToggle, TweenInfo.new(0.18), {
                        BackgroundColor3 = value and theme.accent or theme.cardAlt
                    }):Play()
                end

                cornerToggle.MouseButton1Click:Connect(function()
                    CornerBoxesEnabled = not CornerBoxesEnabled
                    setCornerToggleState(CornerBoxesEnabled)
                    local handler = toggleHandlers["Corner Boxes"]
                    if handler then
                        handler(CornerBoxesEnabled, currentSection)
                    end
                    showNotification("Toggle", "Corner Boxes " .. (CornerBoxesEnabled and "enabled" or "disabled"))
                end)
            end

            palette.MouseButton1Down:Connect(function(x)
                if not subRow.Visible then
                    return
                end
                draggingPicker = true
                setBoxColorFromX(x, true)
            end)

            if blendPalette then
                blendPalette.MouseButton1Down:Connect(function(x)
                    if not subRow.Visible then
                        return
                    end
                    draggingBlend = true
                    setBlendFromX(x, true)
                end)
            end

            UserInputService.InputChanged:Connect(function(input)
                if draggingPicker and input.UserInputType == Enum.UserInputType.MouseMovement then
                    setBoxColorFromX(input.Position.X, true)
                elseif draggingBlend and input.UserInputType == Enum.UserInputType.MouseMovement then
                    setBlendFromX(input.Position.X, true)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if draggingPicker and input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingPicker = false
                    showNotification("Visuals", controlName .. " color changed")
                elseif draggingBlend and input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingBlend = false
                    showNotification("Visuals", controlName .. " color changed")
                end
            end)
        end


    elseif controlType == "slider" then
        local isThemeScaleSlider = currentSection == "Display" and controlName == "UI Scale"
        local holder = create("Frame", {
            Size = UDim2.new(1, 0, 0, isThemeScaleSlider and 52 or 46),
            BackgroundTransparency = 1,
            Parent = parent
        })

        local valueLabel = create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 12),
			BackgroundTransparency = 1,
			Text = isThemeScaleSlider and controlName or controlName .. ": 0",
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = theme.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = holder
		})

		valueLabel.RichText = true

		controlLabelsByTab[currentTabName] = controlLabelsByTab[currentTabName] or {}
		controlOriginalText[currentTabName] = controlOriginalText[currentTabName] or {}

		table.insert(controlLabelsByTab[currentTabName], valueLabel)
		table.insert(controlOriginalText[currentTabName], controlName)

        local currentSliderValue
        local minusButton
        local plusButton
        local barXOffset = 0
        local barWidthOffset = 0

        if controlName == "Walk Speed" or controlName == "Fly Speed" or controlName == "Jump Height" then
            minusButton = create("TextButton", {
                Size = UDim2.fromOffset(20, 20),
                Position = UDim2.fromOffset(0, 18),
                BackgroundColor3 = theme.cardAlt,
                BorderSizePixel = 0,
                Text = "-",
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextColor3 = theme.text,
                AutoButtonColor = false,
                Parent = holder
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = minusButton })
            create("UIStroke", { Color = theme.stroke, Thickness = 1, Parent = minusButton })

            plusButton = create("TextButton", {
                Size = UDim2.fromOffset(20, 20),
                Position = UDim2.new(1, -20, 0, 18),
                BackgroundColor3 = theme.cardAlt,
                BorderSizePixel = 0,
                Text = "+",
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextColor3 = theme.text,
                AutoButtonColor = false,
                Parent = holder
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = plusButton })
            create("UIStroke", { Color = theme.stroke, Thickness = 1, Parent = plusButton })

            barXOffset = 26
            barWidthOffset = -52
        end

        local bar = create("Frame", {
            Size = UDim2.new(1, barWidthOffset, 0, 6),
            Position = UDim2.new(0, barXOffset, 0, isThemeScaleSlider and 30 or 25),
            BackgroundColor3 = theme.cardAlt,
            BorderSizePixel = 0,
            Parent = holder
        })
        create("UICorner", { CornerRadius = UDim.new(1,0), Parent = bar })

        local fill = create("Frame", {
            Size = UDim2.new(0.5, 0, 1, 0),
            BackgroundColor3 = theme.accent,
            BorderSizePixel = 0,
            Parent = bar
        })
        create("UICorner", { CornerRadius = UDim.new(1,0), Parent = fill })

        local dragging = false
        local minValue, maxValue, startValue = 0, 100, 50

        if controlName == "Walk Speed" then
            minValue, maxValue, startValue = 1, 50, state.walkSpeedMultiplier
        elseif controlName == "Fly Speed" then
            minValue, maxValue, startValue = 50, 1000, state.flySpeed
        elseif controlName == "Jump Height" then
            minValue, maxValue, startValue = 7.2, 200, state.jumpHeight
        elseif controlName == "Max Distance" then
            minValue, maxValue, startValue = 25, 500, state.visualMaxDistance
        elseif controlName == "FOV Size" then
            minValue, maxValue, startValue = 1, 500, FOVRadius
        elseif controlName == "Smoothness" then
            minValue, maxValue, startValue = 0, 100, math.floor(((0.36 - AimStrength) / 0.32) * 100 + 0.5)
        elseif controlName == "UI Scale" then
            minValue, maxValue, startValue = 85, 110, math.floor((ui.menuScale.Scale * 100) + 0.5)
        elseif controlName == "CPS" then
            minValue, maxValue, startValue = 1, 200, state.autoClickCps
        end


        local function setSliderFromValue(val)
            currentSliderValue = val
            local alpha = math.clamp((val - minValue) / (maxValue - minValue), 0, 1)
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            local displayValue = math.floor(val)
            if controlName == "Walk Speed" then
                displayValue = string.format("%.1f", val):gsub("%.0$", "")
            end
            if controlName == "Jump Height" then
                displayValue = math.max(1, math.floor(val - minValue + 1))
            end
            if controlName == "UI Scale" then
                valueLabel.Text = escapeRichText(controlName)
            else
                valueLabel.Text = escapeRichText(controlName) .. ": " .. tostring(displayValue)
            end
        end

        local function applySliderValue(val)
            currentSliderValue = math.clamp(val, minValue, maxValue)
            setSliderFromValue(currentSliderValue)

            local handler = sliderHandlers[controlName]
            if handler then
                handler(currentSliderValue, currentSection)
            end
        end

        local function setFromX(x)
            local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = minValue + ((maxValue - minValue) * alpha)
            if controlName == "Walk Speed" then
                if val <= 1.5 then
                    val = math.floor((val * 10) + 0.5) / 10
                elseif val <= 5 then
                    val = math.floor((val * 2) + 0.5) / 2
                else
                    val = math.floor(val + 0.5)
                end
            else
                val = math.floor(val + 0.5)
            end
            applySliderValue(val)
        end

        if isThemeScaleSlider then
            local percentLabel = create("TextLabel", {
                Size = UDim2.new(0, 52, 0, 12),
                Position = UDim2.new(1, -52, 0, 0),
                BackgroundTransparency = 1,
                Text = "100%",
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = theme.softText,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = holder
            })

            local baseSetSliderFromValue = setSliderFromValue
            setSliderFromValue = function(val)
                baseSetSliderFromValue(val)
                percentLabel.Text = tostring(math.floor(val + 0.5)) .. "%"
            end
        end

        if minusButton and plusButton then
            local function getWalkSpeedStep(value, increase)
                if increase then
                    if value < 1.5 then
                        return 0.1
                    elseif value < 5 then
                        return 0.5
                    else
                        return 1
                    end
                end

                if value <= 1.5 then
                    return 0.1
                elseif value <= 5 then
                    return 0.5
                else
                    return 1
                end
            end

            minusButton.MouseButton1Click:Connect(function()
                local step = controlName == "Walk Speed" and getWalkSpeedStep(currentSliderValue, false) or 1
                applySliderValue(currentSliderValue - step)
            end)

            plusButton.MouseButton1Click:Connect(function()
                local step = controlName == "Walk Speed" and getWalkSpeedStep(currentSliderValue, true) or 1
                applySliderValue(currentSliderValue + step)
            end)
        end

        setSliderFromValue(startValue)

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                setFromX(input.Position.X)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                setFromX(input.Position.X)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

    elseif controlType == "colorpicker" then
        local isThemeEditorColor = currentSection == "Theme Editor"
        local row = create("Frame", {
            Size = UDim2.new(1, 0, 0, isThemeEditorColor and 30 or 54),
            BackgroundColor3 = isThemeEditorColor and theme.cardAlt or theme.card,
            BackgroundTransparency = isThemeEditorColor and 0 or 1,
            BorderSizePixel = 0,
            Parent = parent
        })

        if isThemeEditorColor then
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = row })
            create("UIStroke", { Color = theme.stroke, Thickness = 1, Transparency = 0.55, Parent = row })
        end

        local function colorToHex(color)
            return string.format("#%02X%02X%02X",
                math.floor(color.R * 255 + 0.5),
                math.floor(color.G * 255 + 0.5),
                math.floor(color.B * 255 + 0.5)
            )
        end

        local iconLabel = nil
        if isThemeEditorColor then
            iconLabel = create("Frame", {
                Size = UDim2.fromOffset(8, 8),
                Position = UDim2.fromOffset(11, 11),
                BackgroundColor3 = theme.softText,
                BorderSizePixel = 0,
                Parent = row
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = iconLabel })
        end

        local pickerLabel = create("TextLabel", {
			Size = UDim2.new(1, isThemeEditorColor and -120 or -46, 0, 18),
			Position = isThemeEditorColor and UDim2.fromOffset(26, 6) or UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			Text = controlName,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = theme.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row
		})

		pickerLabel.RichText = true

		controlLabelsByTab[currentTabName] = controlLabelsByTab[currentTabName] or {}
		controlOriginalText[currentTabName] = controlOriginalText[currentTabName] or {}

		table.insert(controlLabelsByTab[currentTabName], pickerLabel)
		table.insert(controlOriginalText[currentTabName], controlName)

        local hexLabel = nil
        if isThemeEditorColor then
            hexLabel = create("TextLabel", {
                Size = UDim2.fromOffset(74, 18),
                Position = UDim2.new(1, -108, 0, 6),
                BackgroundTransparency = 1,
                Text = colorToHex(getThemeColor(controlName)),
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = Color3.fromRGB(120, 120, 130),
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = row
            })
        end

        local previewProps = {
            Size = UDim2.fromOffset(24, 18),
            Position = UDim2.new(1, isThemeEditorColor and -26 or -24, 0, isThemeEditorColor and 6 or 0),
            BackgroundColor3 = getThemeColor(controlName),
            BorderSizePixel = 0,
            Parent = row
        }

        if isThemeEditorColor then
            previewProps.Text = ""
            previewProps.AutoButtonColor = false
        end

        local preview = create(isThemeEditorColor and "TextButton" or "Frame", previewProps)
        themeColorPreviews[controlName] = preview
        create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = preview })
        create("UIStroke", { Color = theme.stroke, Thickness = 1, Parent = preview })

        local palette = create("TextButton", {
            Size = UDim2.new(1, -8, 0, 18),
            Position = UDim2.fromOffset(8, isThemeEditorColor and 36 or 26),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Visible = not isThemeEditorColor,
            Parent = row
        })
        create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = palette })

        create("UIGradient", {
            Name = "ThemePickerGradient",
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            }),
            Parent = palette
        })

        local selector = create("Frame", {
            Size = UDim2.fromOffset(6, 24),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.75, 0, 0.5, 0),
            BackgroundColor3 = theme.text,
            BorderSizePixel = 0,
            Parent = palette
        })
        create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = selector })
        create("UIStroke", { Color = theme.background, Thickness = 1, Parent = selector })

        local draggingPicker = false
        

        local function setColorFromX(mouseX, silent)
            local hue = math.clamp((mouseX - palette.AbsolutePosition.X) / math.max(palette.AbsoluteSize.X, 1), 0, 1)
            selector.Position = UDim2.new(hue, 0, 0.5, 0)

            local color = Color3.fromHSV(hue, 0.83, 0.98)
            preview.BackgroundColor3 = color
            if hexLabel then
                hexLabel.Text = colorToHex(color)
            end
            applyThemeColor(controlName, color, silent)
        end

        if isThemeEditorColor then
            local function setExpanded(expanded)
                palette.Visible = expanded
                row.Size = UDim2.new(1, 0, 0, expanded and 56 or 30)
            end

            preview.MouseButton1Click:Connect(function()
                setExpanded(not palette.Visible)
            end)

            pickerLabel.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    setExpanded(not palette.Visible)
                end
            end)
        end

        palette.MouseButton1Down:Connect(function(x)
            draggingPicker = true
            setColorFromX(x, true)
        end)

        UserInputService.InputChanged:Connect(function(input)
            if draggingPicker and input.UserInputType == Enum.UserInputType.MouseMovement then
                setColorFromX(input.Position.X, true)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if draggingPicker and input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingPicker = false
                showNotification("Color Picker", controlName .. " changed")
            end
        end)


elseif controlType == "dropdown" then

    local holder = create("Frame", {
        Size = UDim2.new(1, 0, 0, 29),
        BackgroundTransparency = 1,
        Parent = parent
    })

    local bindRowLabels = {
        ["Aim Key (Hold)"] = "Aim Key",
        ["Aim Mode"] = "Activation Mode",
        ["Auto Clicker Mode"] = "Activation Mode",
        ["Menu Key"] = "Key",
        ["Speed"] = "Speed Key",
        ["Fly"] = "Fly Key",
        ["Auto Clicker Key"] = "Key",
        ["Jump"] = "Jump Key"
    }
    local bindRowOffsets = {
        ["Aim Key (Hold)"] = 50,
        ["Aim Mode"] = 92,
        ["Auto Clicker Mode"] = 92,
        ["Menu Key"] = 53,
        ["Speed"] = 58,
        ["Fly"] = 45,
        ["Auto Clicker Key"] = 62,
        ["Jump"] = 54
    }
    local bindRowLabel = bindRowLabels[controlName]
    local isBindStyleRow = bindRowLabel ~= nil
    local isModeDropdownRow = controlName == "Aim Mode" or controlName == "Auto Clicker Mode"
    local bindRowLeftOffset = bindRowOffsets[controlName] or 58
    local bindRowHeight = 23

    local row = create("TextButton", {
        Size = UDim2.new(1, isBindStyleRow and -bindRowLeftOffset or 0, 0, isBindStyleRow and bindRowHeight or 29),
        Position = isBindStyleRow and UDim2.fromOffset(bindRowLeftOffset, 3) or UDim2.new(),
        BackgroundColor3 = theme.cardAlt,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = holder
    })
    row.ClipsDescendants = false
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = row })
    create("UIStroke", { Color = theme.stroke, Thickness = 1, Parent = row })

    local outsideBindLabel = create("TextLabel", {
        Size = UDim2.new(0, 64, 0, 29),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        Text = bindRowLabel or "",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = theme.text,
        TextStrokeTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Visible = isBindStyleRow,
        Parent = holder
    })

    local label = create("TextLabel", {
        Size = UDim2.new(1, isBindStyleRow and -92 or -28, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = isBindStyleRow and "" or (controlName .. ": none"),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = theme.text,
        TextStrokeTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row
    })

	label.RichText = true

	controlLabelsByTab[currentTabName] = controlLabelsByTab[currentTabName] or {}
	controlOriginalText[currentTabName] = controlOriginalText[currentTabName] or {}

	table.insert(controlLabelsByTab[currentTabName], label)
	table.insert(controlOriginalText[currentTabName], controlName)

    local valueLabel = create("TextLabel", {
        Size = isBindStyleRow and UDim2.new(1, isModeDropdownRow and -24 or -28, 1, 0) or UDim2.fromOffset(56, 18),
        Position = isBindStyleRow and UDim2.fromOffset(6, 0) or UDim2.new(1, -72, 0.5, -9),
        BackgroundTransparency = 1,
        Text = "None",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = theme.softText,
        TextStrokeTransparency = 1,
        TextXAlignment = isBindStyleRow and Enum.TextXAlignment.Center or Enum.TextXAlignment.Right,
        TextYAlignment = Enum.TextYAlignment.Center,
        Visible = isBindStyleRow,
        Parent = row
    })

    local bindIcon = create("ImageLabel", {
        Size = UDim2.fromOffset(19, 19),
        Position = UDim2.new(1, -22, 0.5, -9.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://72486639480586",
        ScaleType = Enum.ScaleType.Fit,
        ImageColor3 = theme.softText,
        Visible = isBindStyleRow and not isModeDropdownRow,
        Parent = row
    })

    local arrow = create("TextLabel", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(1, -22, 0.5, -9),
        BackgroundTransparency = 1,
        Text = "v",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = theme.softText,
        TextStrokeTransparency = 1,
		Rotation = 0,
        Visible = (not isBindStyleRow) or isModeDropdownRow,
        Parent = row
    })

    local dropdownOpen = false
    local waitingForKey = false
    local listFrame

    local function getCurrentDropdownValue()
        if controlName == "Aim Key (Hold)" then
            return AimHoldKey
        elseif controlName == "Aim Mode" then
            return state.aimMode
        elseif controlName == "Auto Clicker Mode" then
            return state.autoClickerMode
        elseif controlName == "Menu Key" then
            return MenuToggleKey
        elseif controlName == "Click Button" then
            return state.autoClickButton
        elseif controlName == "Auto Clicker Key" then
            return state.keybinds.AutoClicker
        end

        return state.keybinds[controlName]
    end

    local function setDropdownLabelText(valueText)
        if isBindStyleRow then
            label.Text = ""
            outsideBindLabel.Text = bindRowLabel
            valueLabel.Text = isModeDropdownRow and tostring(valueText or "Hold") or formatKeyName(valueText or "None")
        else
            label.Text = escapeRichText((controlName == "Aim Mode" or controlName == "Auto Clicker Mode") and "Activation Mode" or controlName) .. ": " .. escapeRichText(tostring(valueText or "none"))
        end
    end

    setDropdownLabelText(getCurrentDropdownValue() or "none")
    

    local function getOptions()
		local source = dropdownSources[controlName]
		return source and (source() or {}) or {}
	end


    local function closeDropdown()
		dropdownOpen = false
		TweenService:Create(
			arrow,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Rotation = 0 }
		):Play()

        if listFrame then
			local oldList = listFrame
			local oldStroke = oldList:FindFirstChildOfClass("UIStroke")
			listFrame = nil
			

			TweenService:Create(holder, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.new(1, 0, 0, 29)
			}):Play()

			TweenService:Create(oldList, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1,
				ScrollBarImageTransparency = 1
			}):Play()

			if oldStroke then
				TweenService:Create(oldStroke, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Transparency = 1
				}):Play()
			end

			for _, child in ipairs(oldList:GetChildren()) do
				if child:IsA("TextButton") then
					TweenService:Create(child, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						BackgroundTransparency = 1,
						TextTransparency = 1
					}):Play()
				end
			end

			task.delay(0.16, function()
				if oldList then
					oldList:Destroy()
				end
			end)
		else
			holder.Size = UDim2.new(1, 0, 0, 29)
		end
	end


    local function openDropdown()
        closeDropdown()

        local options = getOptions()
        if #options == 0 then
            return
        end



        dropdownOpen = true
        TweenService:Create(
			arrow,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Rotation = 180 }
		):Play()

        local listHeight = isModeDropdownRow and (#options * 20 + 8) or math.min(#options * 26, 130)

        listFrame = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 0, listHeight),
            Position = UDim2.fromOffset(0, 33),
            BackgroundColor3 = theme.cardAlt,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            ScrollBarThickness = isModeDropdownRow and 0 or 3,
            ScrollBarImageColor3 = theme.accent,
            ScrollBarImageTransparency = 1,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ClipsDescendants = true,
            Parent = holder
        })


        create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = listFrame })
        local listStroke = create("UIStroke", { Color = theme.stroke, Thickness = 1, Transparency = 1, Parent = listFrame })

        TweenService:Create(listFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
            ScrollBarImageTransparency = isModeDropdownRow and 1 or 0
        }):Play()

        TweenService:Create(listStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = 0
        }):Play()

        create("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = listFrame
		})

        create("UIPadding", {
            PaddingTop = UDim.new(0, isModeDropdownRow and 3 or 4),
            PaddingBottom = UDim.new(0, isModeDropdownRow and 3 or 4),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
            Parent = listFrame
        })

        for _, value in ipairs(options) do
            local optionButton = create("TextButton", {
                Size = UDim2.new(1, 0, 0, isModeDropdownRow and 18 or 22),
                BackgroundColor3 = theme.panel,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = tostring(value),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = theme.text,
                TextTransparency = 1,
                TextStrokeTransparency = 1,
                AutoButtonColor = false,
                Parent = listFrame
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = optionButton })
            

            TweenService:Create(optionButton, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0,
                TextTransparency = 0
            }):Play()

			
            optionButton.MouseEnter:Connect(function()
                TweenService:Create(optionButton, TweenInfo.new(0.12), {
                    BackgroundColor3 = theme.accent,
                    TextColor3 = theme.text
                }):Play()
            end)

            optionButton.MouseLeave:Connect(function()
                TweenService:Create(optionButton, TweenInfo.new(0.12), {
                    BackgroundColor3 = theme.panel,
                    TextColor3 = theme.text
                }):Play()
            end)



            optionButton.MouseButton1Click:Connect(function()
                setDropdownLabelText(value)

                local handler = dropdownHandlers[controlName]
                if handler then
                    handler(value, currentSection)
                end

                if controlName ~= "Text Style" and controlName ~= "Select Player" and controlName ~= "Select Staff" then
                    closeDropdown()
                end

            end)
        end


        local targetHeight = 33 + listHeight
        holder.Size = UDim2.new(1, 0, 0, 29)

        if isModeDropdownRow then
            TweenService:Create(holder, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, 33 + listHeight)
            }):Play()
        else
            TweenService:Create(holder, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, targetHeight)
            }):Play()
        end
    end

    row.MouseButton1Click:Connect(function()
        if currentSection == "Keybinds" or (isBindStyleRow and not isModeDropdownRow) then
            if waitingForKey then
                return
            end

            waitingForKey = true
			isBindingKey = true
            if isBindStyleRow then
                valueLabel.Text = "..."
            else
			    label.Text = escapeRichText(controlName) .. ": ..."
            end

            local connection
            local function finishBinding(bindName)
                if bindName == "Backspace" then
                    local handler = dropdownHandlers[controlName]
                    if handler then
                        handler("None", currentSection)
                    end
                    setDropdownLabelText("None")
                else
                    local handler = dropdownHandlers[controlName]
                    if handler then
                        handler(bindName, currentSection)
                    end
                    setDropdownLabelText(bindName)
                end

                waitingForKey = false
				task.delay(0.1, function()
					isBindingKey = false
				end)
                if connection then
				    connection:Disconnect()
                end
            end

            connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed and not isMouseBindInput(input) then return end

                local bindName = getInputBindName(input)
                if not bindName then
                    return
                end

                finishBinding(bindName)
            end)

            return
        end

        if dropdownOpen then
            closeDropdown()
        else
            openDropdown()
        end
    end)
end
end

local function createSectionCard(parent, section, widthScale, widthOffset, xScale, xOffset, tabName)
    local isThemeEditorSection = tabName == "Miscellaneous" and (section.name == "Theme Editor" or section.name == "Display")
    local card = create("Frame", {
        Size = UDim2.new(widthScale, widthOffset, 0, 80),
        Position = UDim2.new(xScale or 0, xOffset or 0, 0, 0),
        BackgroundColor3 = theme.card,
        BorderSizePixel = 0,
        Parent = parent
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = card })

    local sideAccent = create("Frame", {
        Size = UDim2.new(0, isThemeEditorSection and 0 or 10, 1, isThemeEditorSection and 0 or -4),
        Position = UDim2.fromOffset(0, isThemeEditorSection and 0 or 2),
        BackgroundColor3 = theme.accent,
        BackgroundTransparency = isThemeEditorSection and 1 or 0,
        BorderSizePixel = 0,
        Parent = card
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = sideAccent })

    local cardBody = create("Frame", {
        Size = UDim2.new(1, isThemeEditorSection and 0 or -2, 1, 0),
        Position = UDim2.fromOffset(isThemeEditorSection and 0 or 2, 0),
        BackgroundColor3 = theme.card,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = card
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = cardBody })

    create("UIStroke", {
        Color = theme.stroke,
        Thickness = 1,
        Transparency = isThemeEditorSection and 0.45 or 0.7,
        Parent = cardBody
    })

    local sectionTitle = create("TextLabel", {
        Size = UDim2.new(1, -18, 0, 19),
        Position = UDim2.fromOffset(isThemeEditorSection and 34 or 10, 8),
        BackgroundTransparency = 1,
        Text = section.name,
        Font = Enum.Font.Gotham,
        TextSize = isThemeEditorSection and 13 or 12,
        TextColor3 = isThemeEditorSection and theme.text or Color3.fromRGB(105, 105, 118),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
        Parent = cardBody
    })

    sectionTitle.RichText = true

    sectionLabelsByTab[tabName] = sectionLabelsByTab[tabName] or {}
    sectionOriginalText[tabName] = sectionOriginalText[tabName] or {}
    table.insert(sectionLabelsByTab[tabName], sectionTitle)
    table.insert(sectionOriginalText[tabName], section.name)

    local controlsY = 32

    if isThemeEditorSection then
        create("ImageLabel", {
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.fromOffset(13, 10),
            BackgroundTransparency = 1,
            Image = "rbxassetid://118208528515849",
            ScaleType = Enum.ScaleType.Fit,
            ImageColor3 = theme.accent,
            ZIndex = 3,
            Parent = cardBody
        })

        create("TextLabel", {
            Size = UDim2.new(1, -46, 0, 16),
            Position = UDim2.fromOffset(34, 24),
            BackgroundTransparency = 1,
            Text = section.name == "Theme Editor" and "Customize your interface colors" or "Adjust interface scale",
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = theme.softText,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 3,
            Parent = cardBody
        })

        controlsY = 50
    end

    local controlsHolder = create("Frame", {
        Size = UDim2.new(1, -22, 0, 0),
        Position = UDim2.fromOffset(14, controlsY),
        BackgroundTransparency = 1,
        ZIndex = 3,
        Parent = cardBody
    })

    local controlsLayout = create("UIListLayout", {
        Padding = UDim.new(0, 6),
        Parent = controlsHolder
    })

    for _, spec in ipairs(section.controls) do
        makeControl(controlsHolder, spec, section.name, tabName)
    end

    local function updateCardHeight()
        local cardHeight = controlsLayout.AbsoluteContentSize.Y + (isThemeEditorSection and 60 or 42)
        controlsHolder.Size = UDim2.new(1, -22, 0, controlsLayout.AbsoluteContentSize.Y)
        card.Size = UDim2.new(widthScale, widthOffset, 0, cardHeight)
        return cardHeight
    end

    controlsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCardHeight)
    return card
end

local function createSectionColumns(parent, sections, tabName)
    if #sections > 1 then
        local holder = create("Frame", {
            Size = UDim2.new(1, -6, 0, 80),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = parent
        })
        local leftColumn = create("Frame", {
            Size = UDim2.new(0.5, -6, 0, 80),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = holder
        })
        local rightColumn = create("Frame", {
            Size = UDim2.new(0.5, -6, 0, 80),
            Position = UDim2.new(0.5, 6, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = holder
        })
        local leftLayout = create("UIListLayout", {
            Padding = UDim.new(0, 12),
            Parent = leftColumn
        })
        local rightLayout = create("UIListLayout", {
            Padding = UDim.new(0, 12),
            Parent = rightColumn
        })

        for i, section in ipairs(sections) do
            createSectionCard(i % 2 == 1 and leftColumn or rightColumn, section, 1, 0, 0, 0, tabName)
        end

        local function updateHeight()
            local leftHeight = leftLayout.AbsoluteContentSize.Y
            local rightHeight = rightLayout.AbsoluteContentSize.Y
            leftColumn.Size = UDim2.new(0.5, -6, 0, leftHeight)
            rightColumn.Size = UDim2.new(0.5, -6, 0, rightHeight)
            holder.Size = UDim2.new(1, -6, 0, math.max(leftHeight, rightHeight))
        end

        leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateHeight)
        rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateHeight)
        task.defer(updateHeight)
    elseif sections[1] then
        createSectionCard(parent, sections[1], 1, -6, 0, 0, tabName)
    end
end

local function createTopSectionTabs(page, tab)
    local buttonMap = {}
    local contentMap = {}

    local bar = create("Frame", {
        Size = UDim2.new(1, -6, 0, 34),
        BackgroundColor3 = theme.card,
        BorderSizePixel = 0,
        Parent = page
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = bar })
    create("UIStroke", { Color = theme.stroke, Thickness = 1, Transparency = 0.25, Parent = bar })
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 22),
        Parent = bar
    })

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = bar
    })

    for index, group in ipairs(tab.sectionTabs) do
        local tabWidth = group.name == "Misc" and 82
            or group.name == "Theme Editor" and 132
            or 110
        local button = create("TextButton", {
            Size = UDim2.new(0, tabWidth, 1, 0),
            LayoutOrder = index,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = index == 1 and theme.text or theme.softText,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            Parent = bar
        })
        local iconId = group.name == "Theme Editor" and "rbxassetid://118208528515849"
            or group.name == "Others" and "rbxassetid://80430998430551"
            or "rbxassetid://120859309326267"

        create("ImageLabel", {
            Size = UDim2.fromOffset(15, 15),
            Position = UDim2.fromOffset(10, 9),
            BackgroundTransparency = 1,
            Image = iconId,
            ScaleType = Enum.ScaleType.Fit,
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ImageTransparency = index == 1 and 0 or 0.25,
            Parent = button
        })

        local textLabel = create("TextLabel", {
            Size = UDim2.new(1, -32, 1, 0),
            Position = UDim2.fromOffset(32, 0),
            BackgroundTransparency = 1,
            Text = group.name,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = index == 1 and theme.text or theme.softText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = button
        })
        local underline = create("Frame", {
            Size = UDim2.new(1, group.name == "Misc" and -10 or -24, 0, 2),
            Position = UDim2.new(0, group.name == "Theme Editor" and 2 or -4, 1, -2),
            BackgroundColor3 = theme.accent,
            BackgroundTransparency = index == 1 and 0 or 1,
            BorderSizePixel = 0,
            Parent = button
        })
        create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = underline })

        local content = create("Frame", {
            Size = UDim2.new(1, 0, 0, index == 1 and 80 or 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = index == 1,
            Parent = page
        })
        local contentLayout = create("UIListLayout", {
            Padding = UDim.new(0, 12),
            Parent = content
        })
        if tab.name == "Miscellaneous" and group.name == "Theme Editor" then
            for _, section in ipairs(group.sections) do
                createSectionCard(content, section, 1, -6, 0, 0, tab.name)
            end
        else
            createSectionColumns(content, group.sections, tab.name)
        end
        local function updateContentHeight()
            content.Size = UDim2.new(1, 0, 0, content.Visible and contentLayout.AbsoluteContentSize.Y or 0)
        end
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentHeight)
        task.defer(updateContentHeight)

        content:GetPropertyChangedSignal("Visible"):Connect(function()
            task.defer(updateContentHeight)
        end)

        buttonMap[index] = { button = button, underline = underline }
        buttonMap[index].textLabel = textLabel
        contentMap[index] = content

        button.MouseButton1Click:Connect(function()
            for i, item in ipairs(buttonMap) do
                item.button.TextColor3 = i == index and theme.text or theme.softText
                if item.textLabel then
                    item.textLabel.TextColor3 = i == index and theme.text or theme.softText
                end
                item.underline.BackgroundTransparency = i == index and 0 or 1
                local icon = item.button:FindFirstChildOfClass("ImageLabel")
                if icon then
                    icon.ImageTransparency = i == index and 0 or 0.25
                end
                contentMap[i].Visible = i == index
                contentMap[i].Size = UDim2.new(1, 0, 0, i == index and contentMap[i]:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y or 0)
            end
        end)
    end
end

local pages = {}
local menuState = {
    minimized = false,
    savedShellSize = ui.shell.Size,
    savedShellPosition = ui.shell.Position,
    savedMainVisible = true,
    isClosing = false,
    menuAnimating = false,
    introFinished = false,
    menuHidden = true,
    expandedShellSize = ui.shell.Size,
    expandedShellPosition = ui.shell.Position,
    defaultExpandedShellSize = ui.shell.Size,
    fadeTargets = {
        { ui.shell, "BackgroundTransparency", 0 },
        { shellStroke, "Transparency", 0 },
        { ui.header, "BackgroundTransparency", 0 },
        { headerStroke, "Transparency", 0 },
        { madeByLabel, "TextTransparency", 0 },
        { titleLabel, "TextTransparency", 0 },
        { minimizeButton, "BackgroundTransparency", 0 },
        { minimizeIcon, "TextTransparency", 0 },
        { minimizeStroke, "Transparency", 0 },
        { ui.main, "BackgroundTransparency", 0 },
    }
}

local showMenu


local function playIntro()
    ui.shell.Visible = false
    ui.shell.Size = UDim2.new(0, 515, 0, 430)
    tween(introBlur, TweenInfo.new(0.64, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = 18
    })
    tween(introOverlay, TweenInfo.new(0.64, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.68
    })
    tween(introTitle, TweenInfo.new(0.98, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    })
    tween(introSubtitle, TweenInfo.new(1.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    })
    tween(introCheck, TweenInfo.new(1.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0,
        BackgroundTransparency = 0
    })
    tween(introAccentLine, TweenInfo.new(1.03, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.08
    })
    tween(introPressText, TweenInfo.new(1.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    })
    tween(introKeyPill, TweenInfo.new(1.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0,
        BackgroundTransparency = 0.08
    })
    tween(introKeyPillStroke, TweenInfo.new(1.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 0.35
    })
    tween(introStatusText, TweenInfo.new(1.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    })

    task.delay(3.40, function()
        if introOverlay.Parent then
            tween(introBlur, TweenInfo.new(0.21, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = 0
            })
            tween(introOverlay, TweenInfo.new(0.21, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1
            })
            tween(introTitle, TweenInfo.new(0.21, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                TextTransparency = 1
            })
            tween(introSubtitle, TweenInfo.new(0.21, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                TextTransparency = 1
            })
            tween(introCheck, TweenInfo.new(0.21, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                TextTransparency = 1,
                BackgroundTransparency = 1
            })
            tween(introAccentLine, TweenInfo.new(0.21, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1
            })
            tween(introPressText, TweenInfo.new(0.21, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                TextTransparency = 1
            })
            tween(introKeyPill, TweenInfo.new(0.21, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                TextTransparency = 1,
                BackgroundTransparency = 1
            })
            tween(introKeyPillStroke, TweenInfo.new(0.21, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Transparency = 1
            })
            tween(introStatusText, TweenInfo.new(0.21, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                TextTransparency = 1
            })
        end
    end)

    task.delay(3.59, function()
        if introOverlay.Parent then
            introOverlay:Destroy()
        end

        if introBlur.Parent then
            introBlur:Destroy()
        end

        ui.shell.Size = menuState.savedShellSize
        for _, target in ipairs(menuState.fadeTargets) do
            target[1][target[2]] = target[3]
        end

        ui.shell.Visible = false
        menuState.introFinished = true
        menuState.menuHidden = true
    end)
end

showMenu = function()
    if not menuState.introFinished or menuState.isClosing or menuState.menuAnimating or not menuState.menuHidden then
        return
    end

    menuState.menuAnimating = true
    menuState.menuHidden = false
    task.delay(0.45, function()
        menuState.menuAnimating = false
    end)

    ui.shell.Visible = true
    ui.shell.Position = menuState.savedShellPosition

    for _, target in ipairs(menuState.fadeTargets) do
        if target[2] == "Transparency" or target[2] == "TextTransparency" or target[2] == "BackgroundTransparency" then
            target[1][target[2]] = 1
            tween(target[1], TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                [target[2]] = target[3]
            })
        else
            target[1][target[2]] = target[3]
        end
    end

    if menuState.minimized then
        ui.main.Visible = false
        madeByLabel.Visible = false
        titleLabel.Visible = false
        ui.searchHolder.Visible = false
        ui.tabBar.Visible = false
        ui.pageHolder.Visible = false
        minimizeIcon.Text = "+"

        local targetSize = UDim2.new(0, 320, 0, 38)
        local targetPosition = menuState.savedShellPosition

        ui.shell.Size = UDim2.new(0, targetSize.X.Offset, 0, 0)
        ui.shell.Position = UDim2.new(
            targetPosition.X.Scale,
            targetPosition.X.Offset,
            targetPosition.Y.Scale,
            targetPosition.Y.Offset - (targetSize.Y.Offset / 2)
        )

        local shellTween = tween(ui.shell, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = targetSize,
            Position = targetPosition
        })
        shellTween.Completed:Connect(function()
            menuState.menuAnimating = false
        end)
    else
        ui.main.Visible = true
        madeByLabel.Visible = false
        titleLabel.Visible = true
        titleLabel.Position = titleDefaultPosition
        ui.searchHolder.Visible = true
        ui.tabBar.Visible = true
        ui.pageHolder.Visible = true
        minimizeIcon.Text = "-"

        menuState.savedShellSize = menuState.expandedShellSize
        ui.shell.Size = UDim2.new(0, 260, 0, 54)
        local shellTween = tween(ui.shell, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = menuState.expandedShellSize,
            Position = menuState.savedShellPosition
        })
        shellTween.Completed:Connect(function()
            ui.shell.Size = menuState.expandedShellSize
            menuState.savedShellSize = menuState.expandedShellSize
            menuState.menuAnimating = false
        end)
    end

end

local function hideMenu()
    if menuState.isClosing or menuState.menuAnimating then
        return
    end

    menuState.isClosing = true
    menuState.menuHidden = true
    task.delay(0.45, function()
        menuState.isClosing = false
    end)
    if menuState.minimized then
		menuState.savedShellPosition = ui.shell.Position
		menuState.savedShellSize = ui.shell.Size
	else
		menuState.expandedShellPosition = ui.shell.Position
		menuState.expandedShellSize = menuState.defaultExpandedShellSize
		menuState.savedShellPosition = ui.shell.Position
		menuState.savedShellSize = menuState.defaultExpandedShellSize
	end

    for _, target in ipairs(menuState.fadeTargets) do
        local finalValue = (target[2] == "Transparency" or target[2] == "TextTransparency" or target[2] == "BackgroundTransparency") and 1 or target[3]
        tween(target[1], TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            [target[2]] = finalValue
        })
        task.delay(0.22, function()
            if target[1].Parent then
                target[1][target[2]] = target[3]
            end
        end)
    end

    local shellTween

    if menuState.minimized then
	ui.main.Visible = false
	madeByLabel.Visible = false
	titleLabel.Visible = false
        ui.searchHolder.Visible = false
        ui.tabBar.Visible = false
        ui.pageHolder.Visible = false
        minimizeIcon.Text = "+"

        shellTween = tween(ui.shell, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 320, 0, 0),
            Position = UDim2.new(
                menuState.savedShellPosition.X.Scale,
                menuState.savedShellPosition.X.Offset,
                menuState.savedShellPosition.Y.Scale,
                menuState.savedShellPosition.Y.Offset - 36
            )
        })
    else
        shellTween = tween(ui.shell, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, math.max(260, ui.shell.AbsoluteSize.X - 40), 0, 54)
        })
    end

        shellTween.Completed:Connect(function()
        ui.shell.Visible = false
        if menuState.minimized then
        ui.shell.Size = UDim2.new(0, 320, 0, 38)
        else
            ui.shell.Size = menuState.expandedShellSize
            menuState.savedShellSize = menuState.expandedShellSize
        end
        menuState.isClosing = false
    end)

    showNotification("Menu is Hidden", "Press " .. formatKeyName(MenuToggleKey) .. " to unhide it.")
end




showTab = function(name)
    for tabName, page in pairs(pages) do
        page.Visible = tabName == name
    end
end

local function buildTabEntry(index, tab)
    local hasTabIcon = tab.name == "Farm" or tab.name == "Visuals" or tab.name == "Player" or tab.name == "Online" or tab.name == "Combat" or tab.name == "Locations" or tab.name == "Miscellaneous"
    local tabButton = create("TextButton", {
        Size = UDim2.new(1, -14, 0, 32),
        Position = UDim2.fromOffset(7, 0),
        LayoutOrder = (index * 2) - 1,
        BackgroundColor3 = theme.card,
        BorderSizePixel = 0,
        Text = tab.name,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = index == 1 and theme.text or theme.softText,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = index == 1 and 0 or 1,
        AutoButtonColor = false,
        Parent = ui.tabBar
    })
	table.insert(tabButtons, tabButton)
	tabButtonsByName[tab.name] = tabButton
    tabOriginalText[tab.name] = tab.name
    tabButton.RichText = true

    create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = tabButton })
    local tabUnderline = create("Frame", {
        Size = UDim2.new(0, 2, 1, -14),
        Position = UDim2.new(0, -44, 0, 7),
        BackgroundColor3 = theme.accent,
        BackgroundTransparency = index == 1 and 0 or 1,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = tabButton
    })
    create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = tabUnderline })
    if hasTabIcon then
        local iconSize = tab.name == "Farm" and 20
            or tab.name == "Locations" and 18
            or tab.name == "Combat" and 21
            or tab.name == "Miscellaneous" and 17
            or 18
        local iconY = tab.name == "Miscellaneous" and 8
            or tab.name == "Combat" and 5
            or (tab.name == "Farm" or tab.name == "Locations") and 6
            or 8
        local iconX = tab.name == "Locations" and -31
            or tab.name == "Miscellaneous" and -29
            or tab.name == "Player" and -29
            or tab.name == "Combat" and -31
            or -30

        create("ImageLabel", {
            Size = UDim2.fromOffset(iconSize, iconSize),
            Position = UDim2.fromOffset(iconX, iconY),
            BackgroundTransparency = 1,
            Image = tab.name == "Farm"
                and "rbxassetid://91354776362373"
                or tab.name == "Visuals"
                and "rbxassetid://117608216273399"
                or tab.name == "Player"
                and "rbxassetid://85260584791331"
                or tab.name == "Combat"
                and "rbxassetid://100172071465513"
                or tab.name == "Locations"
                and "rbxassetid://76257441468500"
                or tab.name == "Miscellaneous"
                and "rbxassetid://83694447317045"
                or "rbxassetid://102086664095781",
            ScaleType = Enum.ScaleType.Fit,
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            Parent = tabButton
        })
    end
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 66),
        Parent = tabButton
    })
    if index == 2 or index == 5 then
        local separatorHolder = create("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            LayoutOrder = index * 2,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = ui.tabBar
        })
        create("Frame", {
            Size = UDim2.new(1, -56, 0, 1),
            Position = UDim2.fromOffset(34, 0),
            BackgroundColor3 = theme.stroke,
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            Parent = separatorHolder
        })
    end

    local page = create("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = tab.name == "Visuals" and 5 or 3,
        ScrollBarImageColor3 = theme.accent,
        ScrollBarImageTransparency = tab.name == "Visuals" and 0.05 or 0.15,
		VerticalScrollBarInset = Enum.ScrollBarInset.Always,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.Never,
        ScrollingEnabled = true,
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Visible = index == 1,
        Parent = ui.pageHolder
    })
    pages[tab.name] = page

    create("UIPadding", {
        PaddingTop = UDim.new(0, 3),
        Parent = page
    })

    local pageLayout = create("UIListLayout", {
        Padding = UDim.new(0, 12),
        Parent = page
    })

    local customVisualsLayout = false

    if tab.sectionTabs then
        createTopSectionTabs(page, tab)
        customVisualsLayout = true
    elseif tab.name == "Visuals" and #tab.sections == 3 then
        local visualRow = create("Frame", {
            Size = UDim2.new(1, -6, 0, 80),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = page
        })

        local leftCard = createSectionCard(visualRow, tab.sections[1], 0.5, -6, 0, 0, tab.name)

        local rightColumn = create("Frame", {
            Size = UDim2.new(0.5, -6, 0, 80),
            Position = UDim2.new(0.5, 6, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = visualRow
        })

        local rightLayout = create("UIListLayout", {
            Padding = UDim.new(0, 12),
            Parent = rightColumn
        })

        createSectionCard(rightColumn, tab.sections[2], 1, 0, 0, 0, tab.name)
        createSectionCard(rightColumn, tab.sections[3], 1, 0, 0, 0, tab.name)

        local function updateVisualRow()
            local rightHeight = rightLayout.AbsoluteContentSize.Y
            local leftCardHeight = math.max(leftCard.AbsoluteSize.Y, leftCard.Size.Y.Offset)
            rightColumn.Size = UDim2.new(0.5, -6, 0, rightHeight)
            visualRow.Size = UDim2.new(1, -6, 0, math.max(leftCardHeight, rightHeight))
        end

        leftCard:GetPropertyChangedSignal("Size"):Connect(updateVisualRow)
        leftCard:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateVisualRow)
        rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateVisualRow)
        task.defer(updateVisualRow)
        customVisualsLayout = true
    end

if not customVisualsLayout then
    if #tab.sections > 1 then
        local columnsHolder = create("Frame", {
            Size = UDim2.new(1, -6, 0, 80),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = page
        })

        local leftColumn = create("Frame", {
            Size = UDim2.new(0.5, -6, 0, 80),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = columnsHolder
        })

        local rightColumn = create("Frame", {
            Size = UDim2.new(0.5, -6, 0, 80),
            Position = UDim2.new(0.5, 6, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = columnsHolder
        })

        local leftLayout = create("UIListLayout", {
            Padding = UDim.new(0, 12),
            Parent = leftColumn
        })

        local rightLayout = create("UIListLayout", {
            Padding = UDim.new(0, 12),
            Parent = rightColumn
        })

        for i, section in ipairs(tab.sections) do
            if i % 2 == 1 then
                createSectionCard(leftColumn, section, 1, 0, 0, 0, tab.name)
            else
                createSectionCard(rightColumn, section, 1, 0, 0, 0, tab.name)
            end
        end

        local function updateColumnsHeight()
            local leftHeight = leftLayout.AbsoluteContentSize.Y
            local rightHeight = rightLayout.AbsoluteContentSize.Y

            leftColumn.Size = UDim2.new(0.5, -6, 0, leftHeight)
            rightColumn.Size = UDim2.new(0.5, -6, 0, rightHeight)
            columnsHolder.Size = UDim2.new(1, -6, 0, math.max(leftHeight, rightHeight))
        end

        leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateColumnsHeight)
        rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateColumnsHeight)
        task.defer(updateColumnsHeight)
    else
        createSectionCard(page, tab.sections[1], 1, -6, 0, 0, tab.name)
    end
end

    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.fromOffset(0, pageLayout.AbsoluteContentSize.Y + 6)
    end)



    tabButton.MouseButton1Click:Connect(function()
        if currentTabButton and currentTabButton ~= tabButton then
            TweenService:Create(currentTabButton, TweenInfo.new(0.15), {
                TextColor3 = theme.softText,
                BackgroundTransparency = 1
            }):Play()
        end
        if currentTabUnderline and currentTabUnderline ~= tabUnderline then
            TweenService:Create(currentTabUnderline, TweenInfo.new(0.18), {
                BackgroundTransparency = 1
            }):Play()
        end
        currentTabButton = tabButton
        currentTabUnderline = tabUnderline
        TweenService:Create(tabButton, TweenInfo.new(0.15), {
            TextColor3 = theme.text,
            BackgroundTransparency = 0
        }):Play()
        TweenService:Create(tabUnderline, TweenInfo.new(0.18), {
            BackgroundTransparency = 0
        }):Play()
        showTab(tab.name)
    end)

    if index == 1 then
        currentTabButton = tabButton
        currentTabUnderline = tabUnderline
    end
end

(function()
    for index, tab in ipairs(tabs) do
        buildTabEntry(index, tab)
    end

    rebuildSearchIndex()

    ui.searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        applySearch(ui.searchBox.Text)
    end)

    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ui.tabBar.CanvasSize = UDim2.fromOffset(0, tabLayout.AbsoluteContentSize.Y + 8)
    end)

    minimizeButton.MouseButton1Click:Connect(function()
        if menuState.isClosing or menuState.menuAnimating then
            return
        end

        menuState.minimized = not menuState.minimized
        menuState.menuAnimating = true
        task.delay(0.45, function()
            menuState.menuAnimating = false
        end)

        if menuState.minimized then
            menuState.savedMainVisible = ui.main.Visible

            -- save current FULL menu position before minimizing
            menuState.expandedShellPosition = ui.shell.Position
            menuState.expandedShellSize = menuState.defaultExpandedShellSize

            local topOffset = menuState.expandedShellPosition.Y.Offset - (menuState.expandedShellSize.Y.Offset / 2)
            local targetSize = UDim2.new(0, 320, 0, 38)
            local targetPosition = UDim2.new(
                menuState.expandedShellPosition.X.Scale,
                menuState.expandedShellPosition.X.Offset,
                menuState.expandedShellPosition.Y.Scale,
                topOffset + (targetSize.Y.Offset / 2)
            )

            -- save minimized state too
            menuState.savedShellPosition = targetPosition
            menuState.savedShellSize = targetSize

            ui.main.Visible = false
            madeByLabel.Visible = false
            titleLabel.Visible = false
            ui.searchHolder.Visible = false
            ui.tabBar.Visible = false
            ui.pageHolder.Visible = false

            local shellTween = tween(ui.shell, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = targetSize,
                Position = targetPosition
            })
            shellTween.Completed:Connect(function()
                menuState.menuAnimating = false
            end)

            minimizeIcon.Text = "+"
        else
            ui.main.Visible = menuState.savedMainVisible
            madeByLabel.Visible = false
            titleLabel.Visible = true
            titleLabel.Position = titleDefaultPosition
            ui.searchHolder.Visible = true
            ui.tabBar.Visible = true
            ui.pageHolder.Visible = true

            -- IMPORTANT: use current minimized position as base if it was moved/reopened there
            local currentMinimizedPos = ui.shell.Position

            menuState.expandedShellPosition = UDim2.new(
                currentMinimizedPos.X.Scale,
                currentMinimizedPos.X.Offset,
                currentMinimizedPos.Y.Scale,
                currentMinimizedPos.Y.Offset + ((menuState.expandedShellSize.Y.Offset - ui.shell.AbsoluteSize.Y) / 2)
            )

            local shellTween = tween(ui.shell, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = menuState.expandedShellSize,
                Position = menuState.expandedShellPosition
            })
            shellTween.Completed:Connect(function()
                ui.shell.Size = menuState.expandedShellSize
                menuState.savedShellSize = menuState.expandedShellSize
                menuState.menuAnimating = false
            end)

            menuState.savedShellPosition = menuState.expandedShellPosition
            menuState.savedShellSize = menuState.expandedShellSize

            minimizeIcon.Text = "-"
        end
    end)

    ui.dragging = false
    ui.dragStart = nil
    ui.dragStartPos = nil

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed and not isMouseBindInput(input) then
            return
        end

        local bindName = getInputBindName(input)
        if MenuToggleKey ~= "None" and bindName == MenuToggleKey then
            if menuState.menuHidden then
                showMenu()
            else
                hideMenu()
            end
        end
    end)

    ui.header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            ui.dragging = true
            ui.dragStart = input.Position
            ui.dragStartPos = ui.shell.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    ui.dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if ui.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - ui.dragStart
            local newPosition = UDim2.new(
                ui.dragStartPos.X.Scale,
                ui.dragStartPos.X.Offset + delta.X,
                ui.dragStartPos.Y.Scale,
                ui.dragStartPos.Y.Offset + delta.Y
            )

            ui.shell.Position = newPosition

            if menuState.minimized then
                local minimizedHeight = ui.shell.Size.Y.Offset
                menuState.savedShellPosition = UDim2.new(
                    newPosition.X.Scale,
                    newPosition.X.Offset,
                    newPosition.Y.Scale,
                    newPosition.Y.Offset + ((menuState.savedShellSize.Y.Offset - minimizedHeight) / 2)
                )
            else
                menuState.savedShellPosition = newPosition
            end
        end
    end)

    playIntro()
    task.delay(3.8, function()
        notifyExistingStaff()
    end)
end)()
