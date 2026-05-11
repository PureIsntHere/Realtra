-- ============================================================
--  Réaltra UI Library — Comprehensive Feature Showcase
--  Demonstrates every component, modal, HUD element, and FX
-- ============================================================

local Repo = "https://raw.githubusercontent.com/PureIsntHere/Realtra/main/"

local Library      = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "ThemeManager.lua"))()()
local SaveManager  = loadstring(game:HttpGet(Repo .. "SaveManager.lua"))()

-- ── Hot Reload Guard ────────────────────────────────────────
if typeof(getgenv) == "function" then
    if getgenv().__RealtraShowcase then
        getgenv().__RealtraShowcase:Unload()
    end
end

-- ============================================================
--  STEP 1: LOADING SPLASH (first modal shown)
-- ============================================================
local splash = Library:ShowLoadingSplash({
    Title   = "Réaltra Showcase",
    Version = "3.0.0",
    Status  = "Initializing...",
    Footer  = "Booting Réaltra UI Library",
})

task.spawn(function()
    task.wait(0.3)
    splash:SetProgress(0.15, "Loading core modules...")
    task.wait(0.4)
    splash:SetProgress(0.35, "Wiring ThemeManager...")
    task.wait(0.3)
    splash:SetProgress(0.55, "Connecting SaveManager...")
    task.wait(0.4)
    splash:SetProgress(0.75, "Building interface...")
    task.wait(0.35)
    splash:SetProgress(0.90, "Applying theme...")
    task.wait(0.3)
    splash:SetProgress(1.0, "Ready!")
    task.wait(0.4)
    splash:Close()
end)

-- ============================================================
--  STEP 2: SETUP — ThemeManager, SaveManager
-- ============================================================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("RealtraShowcase")
ThemeManager:SetTheme("Rose Pine")

-- Convenience auto-save wrapper
local function save()
    SaveManager:AttemptSave("autosave")
end

-- ============================================================
--  STEP 3: ANNOUNCEMENT MODAL
-- ============================================================
-- Shown after the splash closes (small delay so it doesn't overlap)
task.delay(2.2, function()
    Library:ShowAnnouncement({
        Title   = "Welcome to Réaltra v3.0",
        Message = "This showcase demonstrates every feature in the Réaltra UI Library.\n\n"
               .. "Explore each tab to see Labels, Buttons, Toggles, Sliders, Textboxes, "
               .. "Dropdowns, MultiDropdowns, Hotkeys, ColorPickers, ProgressBars, Sections, "
               .. "DependencyBoxes, Tabboxes, Notifications, Watermark, Keybind Overlay, "
               .. "the full FX system, SaveManager, and ThemeManager.",
        Buttons = {
            {
                Text     = "Let's Go!",
                Primary  = true,
                Callback = function()
                    Library:Notify({
                        Title    = "Showcase Started",
                        Text     = "All tabs are ready. Enjoy exploring!",
                        Duration = 4,
                        Position = "TopRight",
                        FX       = { TopSweep = true },
                    })
                end,
            },
            {
                Text     = "Copy Repo URL",
                Primary  = false,
                Callback = function()
                    if typeof(setclipboard) == "function" then
                        setclipboard(Repo)
                        Library:Notify({
                            Title    = "Copied!",
                            Text     = "Repo URL is now in your clipboard.",
                            Duration = 3,
                        })
                    end
                end,
            },
        },
        FX = { TopSweep = true, Grid = true },
    })
end)

-- ============================================================
--  STEP 4: WINDOW
-- ============================================================
local Window = Library:CreateWindow({
    Title    = "Réaltra Showcase",
    SubTitle = "v3.0.0 · All Features",
    Size     = Vector2.new(820, 540),
})

if typeof(getgenv) == "function" then
    getgenv().__RealtraShowcase = Library
end

-- ============================================================
--  STEP 5: WATERMARK (live FPS + ping display)
-- ============================================================
local Watermark = Library:CreateWatermark({
    Text     = "Réaltra Showcase  |  Initializing...",
    Position = UDim2.new(1, -10, 0, 10),
})

local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

RunService.Heartbeat:Connect(function(dt)
    local fps  = math.floor(1 / math.max(dt, 0.001))
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local hp   = hum and math.floor(hum.Health) or 0
    local maxHp = hum and math.floor(hum.MaxHealth) or 0
    Watermark:SetText(string.format(
        "Réaltra  |  %s  |  HP: %d/%d  |  %d FPS",
        LocalPlayer.Name, hp, maxHp, fps
    ))
end)

-- ============================================================
--  STEP 6: KEYBIND OVERLAY
-- ============================================================
Library:ShowKeybindOverlay()

-- ============================================================
--  TAB 1: OVERVIEW
--  Shows Label, Button, ProgressBar, Notification demos
-- ============================================================
local OverviewTab = Window:AddTab("Overview")

-- ── Live Status Label ────────────────────────────────────────
local statusLabel = OverviewTab:AddLabel({ Text = "Status: Idle" })

-- ── Dynamic FPS Label ───────────────────────────────────────
local fpsLabel = OverviewTab:AddLabel({ Text = "FPS: --" })
RunService.RenderStepped:Connect(function(dt)
    fpsLabel:SetText(string.format("FPS: %d  |  Frame time: %.2f ms", math.floor(1/math.max(dt,0.001)), dt * 1000))
end)

-- ── Buttons ─────────────────────────────────────────────────
OverviewTab:AddButton({
    Text    = "Fire Notification (TopRight)",
    Tooltip = "Sends a standard notification to the top-right corner",
    Callback = function()
        Library:Notify({
            Title    = "Hello!",
            Text     = "This is a TopRight notification.",
            Duration = 4,
            Position = "TopRight",
        })
    end,
})

OverviewTab:AddButton({
    Text    = "Notification with FX (TopLeft)",
    Tooltip = "Sends a notification with TopSweep FX",
    Callback = function()
        Library:Notify({
            Title    = "FX Notification",
            Text     = "TopSweep effect is active on this notification.",
            Duration = 5,
            Position = "TopLeft",
            FX       = { TopSweep = true },
        })
    end,
})

OverviewTab:AddButton({
    Text    = "Notification with Scanlines (BottomLeft)",
    Tooltip = "Sends a notification with Scanline FX",
    Callback = function()
        Library:Notify({
            Title    = "Scanline FX",
            Text     = "Scanlines give that classic terminal look.",
            Duration = 5,
            Position = "BottomLeft",
            FX       = { Scanlines = true },
        })
    end,
})

OverviewTab:AddButton({
    Text    = "Persistent Notification → Auto Close in 5s",
    Tooltip = "Creates a notification without a Duration, then closes it via code",
    Callback = function()
        local notif = Library:Notify({
            Title    = "Persistent",
            Text     = "This will be closed by code in 5 seconds...",
            Position = "BottomRight",
        })
        task.delay(5, function()
            notif:Close()
            Library:Notify({
                Title    = "Closed",
                Text     = "The persistent notification was closed.",
                Duration = 2,
                Position = "BottomRight",
            })
        end)
    end,
})

-- ── ProgressBar Demo ─────────────────────────────────────────
local progressSection = OverviewTab:AddSection({ Text = "Progress Bar" })

local demoBar   = progressSection:AddProgressBar({ Text = "Demo Progress", Value = 0 })
local barLabel  = progressSection:AddLabel({ Text = "0%" })

progressSection:AddButton({
    Text    = "Run Animated Sequence",
    Tooltip = "Animates the progress bar through a sequence of steps",
    Callback = function()
        statusLabel:SetText("Status: Running Progress Demo")
        task.spawn(function()
            local steps = {
                { pct = 0.10, label = "10%  — Collecting data" },
                { pct = 0.30, label = "30%  — Processing" },
                { pct = 0.55, label = "55%  — Midway checkpoint" },
                { pct = 0.80, label = "80%  — Finalizing" },
                { pct = 1.00, label = "100% — Complete!" },
            }
            for _, step in ipairs(steps) do
                demoBar:SetProgress(step.pct)
                barLabel:SetText(step.label)
                task.wait(0.7)
            end
            statusLabel:SetText("Status: Idle")
        end)
    end,
})

progressSection:AddButton({
    Text    = "Reset Bar",
    Callback = function()
        demoBar:SetProgress(0)
        barLabel:SetText("0%")
    end,
})

-- ── Announcement Re-trigger ──────────────────────────────────
OverviewTab:AddButton({
    Text    = "Show Announcement Modal",
    Tooltip = "Manually triggers the announcement modal",
    FX      = { TopSweep = true },
    Callback = function()
        Library:ShowAnnouncement({
            Title   = "Announcement Modal",
            Message = "This is the Announcement component.\n\n"
                   .. "It supports multi-line text, multiple buttons, and the full FX system.",
            Buttons = {
                { Text = "Acknowledge", Primary = true,  Callback = function() end },
                { Text = "Later",       Primary = false, Callback = function() end },
            },
        })
    end,
})

-- ============================================================
--  TAB 2: COMPONENTS
--  Toggle, Slider, TextInput, Dropdown, MultiDropdown
-- ============================================================
local ComponentsTab = Window:AddTab("Components")

-- ── Toggle ───────────────────────────────────────────────────
local toggleSection = ComponentsTab:AddSection({ Text = "Toggle" })

local masterToggle = toggleSection:AddToggle({
    Text     = "Master Toggle",
    Flag     = "Demo_MasterToggle",
    Value    = false,
    Tooltip  = "Primary on/off switch. Other components react to this.",
    Callback = function(v)
        save()
        Library:Notify({
            Title    = "Master Toggle",
            Text     = "State changed to: " .. (v and "ON" or "OFF"),
            Duration = 2,
        })
    end,
})

toggleSection:AddToggle({
    Text     = "Silent Toggle (no callback log)",
    Flag     = "Demo_SilentToggle",
    Value    = true,
    Tooltip  = "Demonstrates SetValue with ignoreCallback",
    Callback = function(v) save() end,
})

-- ── Slider ───────────────────────────────────────────────────
local sliderSection = ComponentsTab:AddSection({ Text = "Slider" })

sliderSection:AddSlider({
    Text     = "Integer Slider (1–100, step 1)",
    Flag     = "Demo_IntSlider",
    Min      = 1,
    Max      = 100,
    Step     = 1,
    Value    = 50,
    Tooltip  = "A basic integer-step slider",
    Callback = function(v) save() end,
})

local fineSlider = sliderSection:AddSlider({
    Text     = "Float Slider (0.1–3.0, step 0.05)",
    Flag     = "Demo_FloatSlider",
    Min      = 0.1,
    Max      = 3.0,
    Step     = 0.05,
    Value    = 1.0,
    Tooltip  = "Fine-grained float slider, useful for animation speed",
    Callback = function(v) save() end,
})

local sliderReadout = sliderSection:AddLabel({ Text = "Current float value: 1.00" })
fineSlider:OnChanged(function(v)
    sliderReadout:SetText(string.format("Current float value: %.2f", v))
end)

-- ── TextInput ────────────────────────────────────────────────
local textSection = ComponentsTab:AddSection({ Text = "TextInput" })

local nameInput = textSection:AddTextbox({
    Text        = "Player Name",
    Placeholder = "Enter a player name...",
    Flag        = "Demo_PlayerName",
    Tooltip     = "Type and press Enter. Also supports Ctrl+V paste.",
    Callback    = function(text, enterPressed)
        if enterPressed and text ~= "" then
            Library:Notify({
                Title    = "TextInput",
                Text     = "You entered: " .. text,
                Duration = 3,
            })
        end
        save()
    end,
})

textSection:AddButton({
    Text    = "Read Input Value",
    Callback = function()
        Library:Notify({
            Title    = "Input Value",
            Text     = "Current value: \"" .. nameInput:GetText() .. "\"",
            Duration = 3,
        })
    end,
})

textSection:AddButton({
    Text    = "Set Input Programmatically",
    Callback = function()
        nameInput:SetText("RealtraUser")
        Library:Notify({ Title = "TextInput", Text = "Value set to: RealtraUser", Duration = 2 })
    end,
})

-- ── Dropdown ─────────────────────────────────────────────────
local dropSection = ComponentsTab:AddSection({ Text = "Dropdown" })

local difficultyDD = dropSection:AddDropdown({
    Text     = "Difficulty",
    Flag     = "Demo_Difficulty",
    Options  = { "Easy", "Normal", "Hard", "Extreme", "Impossible" },
    Value    = "Normal",
    Tooltip  = "Single-select dropdown",
    Callback = function(v)
        Library:Notify({ Title = "Dropdown", Text = "Selected: " .. v, Duration = 2 })
        save()
    end,
})

-- Dynamic options example
local playerDropdown = dropSection:AddDropdown({
    Text    = "Target Player (live)",
    Flag    = "Demo_TargetPlayer",
    Options = {},
    Tooltip = "Dynamically populated from Players service",
    Callback = function(v) save() end,
})

local function refreshPlayers()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(names, p.Name)
    end
    if #names == 0 then names = { "(No players)" } end
    playerDropdown:SetOptions(names)
    if names[1] then playerDropdown:SetValue(names[1], false, true) end
end

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

dropSection:AddButton({
    Text    = "Refresh Player List",
    Callback = function() refreshPlayers() end,
})

-- ── MultiDropdown ────────────────────────────────────────────
local multiSection = ComponentsTab:AddSection({ Text = "MultiDropdown" })

local abilityMDD = multiSection:AddMultiDropdown({
    Text          = "Active Abilities (max 3)",
    Flag          = "Demo_Abilities",
    Options       = { "Speed Boost", "Double Jump", "Wall Run", "Glide", "Dash", "Shield" },
    Values        = { "Speed Boost" },
    MaxSelections = 3,
    Tooltip       = "Multi-select dropdown capped at 3 simultaneous choices",
    Callback      = function(selected)
        local list = table.concat(selected, ", ")
        Library:Notify({
            Title    = "MultiDropdown",
            Text     = "Active: " .. (list ~= "" and list or "(none)"),
            Duration = 3,
        })
        save()
    end,
})

multiSection:AddButton({
    Text    = "Clear All Selections",
    Callback = function() abilityMDD:ClearSelection() end,
})

multiSection:AddButton({
    Text    = "Select All",
    Callback = function()
        abilityMDD:SetValues({ "Speed Boost", "Double Jump", "Wall Run" }, true)
    end,
})

-- ============================================================
--  TAB 3: ADVANCED COMPONENTS
--  ColorPicker, Hotkey, DependencyBox, Tabbox
-- ============================================================
local AdvancedTab = Window:AddTab("Advanced")

-- ── ColorPicker ──────────────────────────────────────────────
local colorSection = AdvancedTab:AddSection({ Text = "ColorPicker" })

local primaryColor = colorSection:AddColorPicker({
    Text         = "Primary Color",
    Flag         = "Demo_PrimaryColor",
    Default      = Color3.fromRGB(196, 167, 231),
    Transparency = 0,
    Tooltip      = "Full HSV color picker with alpha channel",
    Callback     = function(color, alpha)
        save()
    end,
})

local secondaryColor = colorSection:AddColorPicker({
    Text         = "Secondary Color (with alpha)",
    Flag         = "Demo_SecondaryColor",
    Default      = Color3.fromRGB(235, 111, 146),
    Transparency = 0.3,
    Tooltip      = "Alpha slider controls transparency (0 = opaque, 1 = invisible)",
    Callback     = function(color, alpha)
        save()
    end,
})

colorSection:AddButton({
    Text    = "Read Color Values",
    Callback = function()
        local c1, _ = primaryColor:GetValue and primaryColor:GetValue() or Color3.new(1,1,1)
        Library:Notify({
            Title = "Color Values",
            Text  = string.format("Primary picked! Check console for details."),
            Duration = 3,
        })
    end,
})

-- ── Hotkey / Keybind ─────────────────────────────────────────
local hotkeySection = AdvancedTab:AddSection({ Text = "Hotkey (Keybind)" })

local uiHotkey = hotkeySection:AddHotkey({
    Text     = "Toggle UI Visibility",
    Flag     = "Demo_UIToggle",
    Value    = "RightShift",
    Tooltip  = "Click to rebind. Press the bound key to toggle the window.",
    Callback = function(keyName)
        Library:Notify({
            Title    = "Hotkey Updated",
            Text     = "UI toggle key is now: " .. keyName,
            Duration = 3,
        })
        save()
    end,
})

-- Wire up the actual key action
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode.Name == uiHotkey:GetValue() then
        Window.Root.Visible = not Window.Root.Visible
    end
end)

hotkeySection:AddHotkey({
    Text     = "Toggle Watermark",
    Flag     = "Demo_WMToggle",
    Value    = "RightAlt",
    Tooltip  = "Hides/shows the watermark HUD element",
    Callback = function(keyName) save() end,
})

local wmVisible = true
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightAlt then
        wmVisible = not wmVisible
        Watermark:SetVisible(wmVisible)
        Library:ToggleKeybindOverlay()
    end
end)

-- ── DependencyBox ────────────────────────────────────────────
local depSection = AdvancedTab:AddSection({ Text = "DependencyBox" })

local featureToggle = depSection:AddToggle({
    Text     = "Enable Advanced Feature",
    Flag     = "Demo_AdvFeature",
    Value    = false,
    Tooltip  = "Turn ON to reveal the settings below",
    Callback = function(v) save() end,
})

local depBox = depSection:AddDependencyBox({
    Dependency = featureToggle,
    Text       = "Advanced Feature Settings",
})

depBox:AddSlider({
    Text  = "Intensity",
    Flag  = "Demo_AdvIntensity",
    Min   = 0,
    Max   = 100,
    Value = 50,
    Callback = function() save() end,
})

depBox:AddDropdown({
    Text    = "Mode",
    Flag    = "Demo_AdvMode",
    Options = { "Passive", "Aggressive", "Balanced" },
    Value   = "Balanced",
    Callback = function() save() end,
})

depBox:AddToggle({
    Text  = "Sub-option A",
    Flag  = "Demo_AdvSubA",
    Callback = function() save() end,
})

-- Inverted DependencyBox (shows when toggle is OFF)
local safeToggle = depSection:AddToggle({
    Text     = "Safe Mode (OFF = danger zone visible)",
    Flag     = "Demo_SafeMode",
    Value    = true,
    Tooltip  = "Inverted DependencyBox: settings appear only when Safe Mode is OFF",
    Callback = function(v) save() end,
})

local dangerBox = depSection:AddDependencyBox({
    Dependency = safeToggle,
    Text       = "Danger Zone (requires Safe Mode OFF)",
    Invert     = true,
})

dangerBox:AddToggle({ Text = "Bypass Rate Limit",  Flag = "Demo_DangerA", Callback = save })
dangerBox:AddToggle({ Text = "Force Anti-Cheat Off", Flag = "Demo_DangerB", Callback = save })

-- ── Tabbox (Nested Tabs) ──────────────────────────────────────
local tabboxSection = AdvancedTab:AddSection({ Text = "Tabbox (Nested Tabs)" })

local innerTabbox = tabboxSection:AddTabbox()

local innerA = innerTabbox:AddTab("Module A")
innerA:AddToggle({ Text = "A — Feature 1", Flag = "TBox_A1", Callback = save })
innerA:AddToggle({ Text = "A — Feature 2", Flag = "TBox_A2", Callback = save })
innerA:AddSlider({ Text = "A — Intensity", Flag = "TBox_A3", Min = 1, Max = 50, Value = 10, Callback = save })

local innerB = innerTabbox:AddTab("Module B")
innerB:AddDropdown({ Text = "B — Strategy", Flag = "TBox_B1",
    Options = { "Alpha", "Beta", "Gamma" }, Value = "Alpha", Callback = save })
innerB:AddColorPicker({ Text = "B — Indicator", Flag = "TBox_B2",
    Default = Color3.fromRGB(62, 143, 176), Callback = save })

local innerC = innerTabbox:AddTab("Module C")
innerC:AddTextbox({ Text = "C — Custom Tag", Placeholder = "e.g. MyTag", Flag = "TBox_C1", Callback = save })
innerC:AddToggle({ Text = "C — Broadcast", Flag = "TBox_C2", Callback = save })
innerC:AddButton({
    Text = "C — Trigger Action",
    Callback = function()
        Library:Notify({ Title = "Tabbox", Text = "Module C action triggered!", Duration = 2 })
    end,
})

-- ============================================================
--  TAB 4: LAYOUT
--  Two-column groupbox, Section collapsing, full-width
-- ============================================================
local LayoutTab = Window:AddTab("Layout")

-- ── Two-Column Layout ────────────────────────────────────────
local LeftBox  = LayoutTab:AddLeftGroupbox("Left Groupbox")
local RightBox = LayoutTab:AddRightGroupbox("Right Groupbox")

LeftBox:AddLabel({ Text = "Left column — column A" })
LeftBox:AddToggle({ Text = "Left Toggle 1", Flag = "Layout_LT1", Callback = save })
LeftBox:AddToggle({ Text = "Left Toggle 2", Flag = "Layout_LT2", Callback = save })
LeftBox:AddSlider({ Text = "Left Slider",   Flag = "Layout_LS1", Min = 0, Max = 100, Value = 30, Callback = save })
LeftBox:AddButton({
    Text = "Left Button",
    Callback = function()
        Library:Notify({ Title = "Layout", Text = "Left column button pressed!", Duration = 2 })
    end,
})

RightBox:AddLabel({ Text = "Right column — column B" })
RightBox:AddToggle({ Text = "Right Toggle 1", Flag = "Layout_RT1", Callback = save })
RightBox:AddToggle({ Text = "Right Toggle 2", Flag = "Layout_RT2", Callback = save })
RightBox:AddSlider({ Text = "Right Slider",   Flag = "Layout_RS1", Min = 0, Max = 100, Value = 70, Callback = save })
RightBox:AddButton({
    Text = "Right Button",
    Callback = function()
        Library:Notify({ Title = "Layout", Text = "Right column button pressed!", Duration = 2 })
    end,
})

-- ── Full-width Section ───────────────────────────────────────
local fullSection = LayoutTab:AddSection({ Text = "Full-Width Section (collapsible)" })

fullSection:AddLabel({ Text = "This section spans the full width of the tab." })
fullSection:AddLabel({ Text = "Click the section header to collapse it." })
fullSection:AddToggle({ Text = "Full-Width Toggle", Flag = "Layout_FWT", Callback = save })
fullSection:AddButton({
    Text = "Full-Width Button with FX",
    FX   = { TopSweep = true },
    Callback = function()
        Library:Notify({ Title = "FX Button", Text = "TopSweep FX fired from button!", Duration = 3 })
    end,
})

-- ── Groupbox alias ──────────────────────────────────────────
local gbSection = LayoutTab:AddGroupbox("Groupbox (alias for AddSection)")
gbSection:AddLabel({ Text = "AddGroupbox and AddSection are identical." })
gbSection:AddToggle({ Text = "Groupbox Toggle", Flag = "Layout_GBT", Callback = save })

-- ============================================================
--  TAB 5: FX SHOWCASE
--  Demonstrates FX system and theme effects
-- ============================================================
local FXTab = Window:AddTab("FX")

local fxSection = FXTab:AddSection({ Text = "Window FX Toggles" })

fxSection:AddToggle({
    Text     = "Enable Scanlines",
    Flag     = "FX_Scanlines",
    Value    = Library.Theme.EnableScanlines,
    Tooltip  = "Animated horizontal scanline sweeping across the window",
    Callback = function(v)
        Library.Theme.EnableScanlines = v
        Library:RefreshAll()
    end,
})

fxSection:AddToggle({
    Text     = "Enable Top Sweep",
    Flag     = "FX_TopSweep",
    Value    = Library.Theme.EnableTopSweep,
    Tooltip  = "Animated line sweeping across the top edge of the window",
    Callback = function(v)
        Library.Theme.EnableTopSweep = v
        Library:RefreshAll()
    end,
})

fxSection:AddToggle({
    Text     = "Enable Corner Brackets",
    Flag     = "FX_Brackets",
    Value    = Library.Theme.EnableBrackets,
    Tooltip  = "Decorative corner brackets on the window frame",
    Callback = function(v)
        Library.Theme.EnableBrackets = v
        Library:RefreshAll()
    end,
})

fxSection:AddToggle({
    Text     = "Enable Grid Background",
    Flag     = "FX_Grid",
    Value    = Library.Theme.EnableGridBG,
    Tooltip  = "Subtle grid pattern in the window background",
    Callback = function(v)
        Library.Theme.EnableGridBG = v
        Library:RefreshAll()
    end,
})

-- ── FX Notification Demos ────────────────────────────────────
local fxNotifSection = FXTab:AddSection({ Text = "Notification FX" })

fxNotifSection:AddButton({
    Text    = "Notify: TopSweep",
    Callback = function()
        Library:Notify({ Title = "FX Demo", Text = "TopSweep FX", Duration = 5,
            FX = { TopSweep = true } })
    end,
})

fxNotifSection:AddButton({
    Text    = "Notify: Scanlines",
    Callback = function()
        Library:Notify({ Title = "FX Demo", Text = "Scanlines FX", Duration = 5, Position = "TopLeft",
            FX = { Scanlines = true } })
    end,
})

fxNotifSection:AddButton({
    Text    = "Notify: Grid",
    Callback = function()
        Library:Notify({ Title = "FX Demo", Text = "Grid FX", Duration = 5, Position = "BottomLeft",
            FX = { Grid = true } })
    end,
})

fxNotifSection:AddButton({
    Text    = "Notify: All FX Combined",
    FX      = { TopSweep = true },
    Callback = function()
        Library:Notify({ Title = "All FX", Text = "Scanlines + TopSweep + Grid together!", Duration = 6,
            Position = "BottomRight",
            FX = { Scanlines = true, TopSweep = true, Grid = true } })
    end,
})

-- ── Custom FX Parameters ─────────────────────────────────────
local fxCustomSection = FXTab:AddSection({ Text = "Custom FX Parameters" })

fxCustomSection:AddButton({
    Text    = "Custom Colored TopSweep",
    Callback = function()
        Library:Notify({
            Title = "Custom FX",
            Text  = "Neon cyan sweep, thick and fast",
            Duration = 6,
            FX = {
                TopSweep = {
                    Color     = Color3.fromRGB(0, 255, 220),
                    Thickness = 5,
                    Speed     = 400,
                    Length    = 200,
                    Gap       = 10,
                },
            },
        })
    end,
})

fxCustomSection:AddButton({
    Text    = "Custom Scanline Speed",
    Callback = function()
        Library:Notify({
            Title = "Custom Scanline",
            Text  = "Very fast magenta scanline",
            Duration = 6,
            Position = "TopLeft",
            FX = {
                Scanlines = {
                    Color        = Color3.fromRGB(255, 80, 200),
                    Transparency = 0.6,
                    Speed        = 200,
                },
            },
        })
    end,
})

-- ============================================================
--  TAB 6: KEY SYSTEM TEST
--  Full auth key modal demonstration
-- ============================================================
local KeyTab = Window:AddTab("Key Test")

local keySection = KeyTab:AddSection({ Text = "Authorization Key Demo" })

keySection:AddLabel({ Text = "The correct key for this demo is: REALTRA-2025" })

keySection:AddButton({
    Text    = "Launch Key System (3 attempts)",
    Tooltip = "Opens the authorization modal. Correct key: REALTRA-2025",
    FX      = { TopSweep = true },
    Callback = function()
        Library:RequestAuth({
            Title       = "AUTHORIZATION REQUIRED",
            Subtitle    = "Enter your Réaltra license key",
            MaxAttempts = 3,
            ValidateKey = function(key)
                -- Synchronous validator
                return key == "REALTRA-2025"
            end,
            OnSuccess = function(key)
                Library:Notify({
                    Title    = "Access Granted",
                    Text     = "Key accepted: " .. key,
                    Duration = 5,
                    FX       = { TopSweep = true },
                })
            end,
            OnFail = function(key)
                Library:Notify({
                    Title    = "Access Denied",
                    Text     = "Wrong key: \"" .. key .. "\". Try: REALTRA-2025",
                    Duration = 4,
                    Position = "TopLeft",
                })
            end,
        })
    end,
})

keySection:AddButton({
    Text    = "Launch Key System (async / simulated HTTP)",
    Tooltip = "Simulates async key validation as would be done with an HTTP endpoint",
    Callback = function()
        Library:RequestAuth({
            Title       = "ASYNC AUTHORIZATION",
            Subtitle    = "Simulates an HTTP key check (correct key: ASYNC-KEY)",
            MaxAttempts = 5,
            ValidateKey = function(key, callback)
                -- Async path: simulate a 0.8s network round-trip
                task.spawn(function()
                    task.wait(0.8)
                    callback(key == "ASYNC-KEY")
                end)
            end,
            OnSuccess = function(key)
                Library:Notify({
                    Title    = "Async Auth Passed",
                    Text     = "HTTP simulation accepted your key.",
                    Duration = 4,
                })
            end,
            OnFail = function(key)
                Library:Notify({
                    Title    = "Async Auth Failed",
                    Text     = "Simulated server rejected: \"" .. key .. "\"",
                    Duration = 3,
                })
            end,
        })
    end,
})

-- ============================================================
--  TAB 7: FEATURE TEST
--  Real-game-like feature toggles wired to actual game services
-- ============================================================
local FeatureTab = Window:AddTab("Feature Test")

local featureLeftBox  = FeatureTab:AddLeftGroupbox("Movement")
local featureRightBox = FeatureTab:AddRightGroupbox("Character")

-- ── Walk Speed ───────────────────────────────────────────────
featureLeftBox:AddSlider({
    Text     = "Walk Speed",
    Flag     = "Feat_WalkSpeed",
    Min      = 16,
    Max      = 250,
    Step     = 2,
    Value    = 16,
    Tooltip  = "Sets Humanoid.WalkSpeed",
    Callback = function(v)
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
        save()
    end,
})

-- ── Jump Power ──────────────────────────────────────────────
featureLeftBox:AddSlider({
    Text     = "Jump Power",
    Flag     = "Feat_JumpPower",
    Min      = 7,
    Max      = 200,
    Step     = 1,
    Value    = 50,
    Tooltip  = "Sets Humanoid.JumpPower",
    Callback = function(v)
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
        save()
    end,
})

-- ── Infinite Jump ────────────────────────────────────────────
local infJumpToggle = featureLeftBox:AddToggle({
    Text     = "Infinite Jump",
    Flag     = "Feat_InfJump",
    Value    = false,
    Tooltip  = "Allows jumping in mid-air",
    Callback = function(v) save() end,
})

game:GetService("UserInputService").JumpRequest:Connect(function()
    if infJumpToggle:GetValue() then
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ── Noclip ───────────────────────────────────────────────────
local noclipToggle = featureLeftBox:AddToggle({
    Text     = "NoClip",
    Flag     = "Feat_NoClip",
    Value    = false,
    Tooltip  = "Disables collision on character parts",
    Callback = function(v) save() end,
})

RunService.Stepped:Connect(function()
    if noclipToggle:GetValue() then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- ── Character right column ────────────────────────────────────
featureRightBox:AddSlider({
    Text     = "FOV",
    Flag     = "Feat_FOV",
    Min      = 50,
    Max      = 120,
    Step     = 1,
    Value    = 70,
    Tooltip  = "Sets workspace.CurrentCamera.FieldOfView",
    Callback = function(v)
        if workspace.CurrentCamera then
            workspace.CurrentCamera.FieldOfView = v
        end
        save()
    end,
})

featureRightBox:AddToggle({
    Text     = "Show Health in Watermark",
    Flag     = "Feat_WMHealth",
    Value    = true,
    Tooltip  = "Already wired in the watermark setup above",
    Callback = function(v) save() end,
})

featureRightBox:AddButton({
    Text    = "Reset Character",
    Tooltip = "Kills the character to trigger a respawn",
    Callback = function()
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = 0
            Library:Notify({ Title = "Character", Text = "Character reset.", Duration = 2 })
        end
    end,
})

featureRightBox:AddButton({
    Text    = "Teleport to Spawn",
    Tooltip = "Moves character to world origin",
    Callback = function()
        local char = LocalPlayer.Character
        if char and char.PrimaryPart then
            char:SetPrimaryPartCFrame(CFrame.new(0, 5, 0))
            Library:Notify({ Title = "Teleport", Text = "Teleported to spawn.", Duration = 2 })
        end
    end,
})

-- ── Full Feature Test Section ────────────────────────────────
local fullFeatureSection = FeatureTab:AddSection({ Text = "Full Feature (DependencyBox + Tabbox)" })

local combatMasterToggle = fullFeatureSection:AddToggle({
    Text     = "Enable Combat Module",
    Flag     = "Feat_CombatMaster",
    Value    = false,
    Tooltip  = "Master switch. Reveals nested combat settings via DependencyBox.",
    Callback = function(v) save() end,
})

local combatDepBox = fullFeatureSection:AddDependencyBox({
    Dependency = combatMasterToggle,
    Text       = "Combat Module Settings",
})

local combatTabbox = combatDepBox:AddTabbox()

local aimSubTab  = combatTabbox:AddTab("Aimbot")
local trigSubTab = combatTabbox:AddTab("Triggerbot")
local miscSubTab = combatTabbox:AddTab("Misc")

-- Aimbot sub-tab
local aimEnabled = aimSubTab:AddToggle({ Text = "Enable Aimbot", Flag = "Combat_AimOn", Callback = save })
local aimDepBox  = aimSubTab:AddDependencyBox({ Dependency = aimEnabled, Text = "Aimbot Settings" })
aimDepBox:AddSlider({ Text = "FOV Radius",    Flag = "Combat_AimFOV",    Min = 10,  Max = 300, Value = 90,  Callback = save })
aimDepBox:AddSlider({ Text = "Smoothness",    Flag = "Combat_AimSmooth", Min = 1,   Max = 30,  Value = 8,   Callback = save })
aimDepBox:AddDropdown({ Text = "Target Bone", Flag = "Combat_AimBone",   Options = { "Head", "Upper Torso", "Nearest" }, Value = "Head", Callback = save })
aimDepBox:AddHotkey({ Text = "Aimbot Key", Flag = "Combat_AimKey", Value = "Q", Callback = save })

-- Triggerbot sub-tab
local trigEnabled = trigSubTab:AddToggle({ Text = "Enable Triggerbot", Flag = "Combat_TrigOn", Callback = save })
local trigDepBox  = trigSubTab:AddDependencyBox({ Dependency = trigEnabled, Text = "Triggerbot Settings" })
trigDepBox:AddSlider({ Text = "Delay (ms)", Flag = "Combat_TrigDelay", Min = 0, Max = 500, Step = 10, Value = 80, Callback = save })
trigDepBox:AddToggle({ Text = "Head Only",  Flag = "Combat_TrigHead",  Callback = save })
trigDepBox:AddHotkey({ Text = "Trigger Key", Flag = "Combat_TrigKey", Value = "E", Callback = save })

-- Misc sub-tab
miscSubTab:AddToggle({ Text = "Anti-Aim",      Flag = "Combat_AntiAim", Callback = save })
miscSubTab:AddToggle({ Text = "Silent Aim",    Flag = "Combat_Silent",  Callback = save })
miscSubTab:AddSlider({ Text = "Hit Chance %",  Flag = "Combat_HitChance", Min = 1, Max = 100, Value = 85, Callback = save })
miscSubTab:AddDropdown({ Text = "Hit Effect",  Flag = "Combat_Effect", Options = { "None", "Shake", "Flash", "Blur" }, Value = "None", Callback = save })

-- ============================================================
--  TAB 8: SETTINGS
--  ThemeManager, SaveManager, Library utilities
-- ============================================================
local SettingsTab = Window:AddTab("Settings")

-- ── Theme ────────────────────────────────────────────────────
local themeSection = SettingsTab:AddSection({ Text = "Appearance" })
ThemeManager:CreateThemeManager(themeSection)

-- ── Quick Theme Switcher ─────────────────────────────────────
local quickThemeSection = SettingsTab:AddSection({ Text = "Quick Theme Presets" })

quickThemeSection:AddDropdown({
    Text    = "Apply Preset",
    Options = ThemeManager:ListThemes(),
    Value   = "Rose Pine",
    Tooltip = "Instantly applies any of the 25+ built-in theme presets",
    Callback = function(v)
        ThemeManager:SetTheme(v)
        Library:Notify({ Title = "Theme", Text = "Applied: " .. v, Duration = 2 })
    end,
})

quickThemeSection:AddButton({
    Text    = "Custom Theme (Réaltra Blue)",
    Tooltip = "Applies a hand-crafted deep-blue custom theme",
    Callback = function()
        ThemeManager:SetTheme({
            Background   = Color3.fromRGB(8,  12, 24),
            Background2  = Color3.fromRGB(12, 18, 36),
            Background3  = Color3.fromRGB(10, 15, 30),
            TextColor    = Color3.fromRGB(210, 230, 255),
            SubTextColor = Color3.fromRGB(130, 160, 210),
            DisabledText = Color3.fromRGB(80,  100, 150),
            Accent       = Color3.fromRGB(80,  160, 255),
            AccentDim    = Color3.fromRGB(40,  90,  160),
            Border       = Color3.fromRGB(25,  40,  80),
            Rounding     = 6,
            Font         = Enum.Font.Gotham,
            EnableBrackets  = true,
            EnableTopSweep  = true,
            EnableScanlines = false,
            EnableGridBG    = false,
            Window = {
                Background     = Color3.fromRGB(8,  12, 24),
                TitleText      = Color3.fromRGB(210, 230, 255),
                SubtitleText   = Color3.fromRGB(130, 160, 210),
                Border         = Color3.fromRGB(25,  40,  80),
                CornerBrackets = Color3.fromRGB(60, 110, 200),
            },
            Tab = {
                IdleFill   = Color3.fromRGB(12, 18, 36),
                ActiveFill = Color3.fromRGB(8,  12, 24),
                IdleText   = Color3.fromRGB(130, 160, 210),
                ActiveText = Color3.fromRGB(210, 230, 255),
                Border     = Color3.fromRGB(25,  40,  80),
            },
        })
        Library:Notify({ Title = "Theme", Text = "Réaltra Blue applied!", Duration = 3 })
    end,
})

-- ── Configs ──────────────────────────────────────────────────
SaveManager:BuildConfigSection(SettingsTab)

-- ── Window Controls ──────────────────────────────────────────
local windowSection = SettingsTab:AddSection({ Text = "Window Controls" })

windowSection:AddButton({
    Text    = "Toggle Dock Panel",
    Tooltip = "Shows or hides the side docking panel",
    Callback = function()
        Window:ToggleDock()
    end,
})

windowSection:AddButton({
    Text    = "Toggle Keybind Overlay",
    Callback = function()
        Library:ToggleKeybindOverlay()
    end,
})

windowSection:AddButton({
    Text    = "Toggle Watermark",
    Callback = function()
        wmVisible = not wmVisible
        Watermark:SetVisible(wmVisible)
    end,
})

windowSection:AddButton({
    Text    = "Refresh All Themes",
    Tooltip = "Propagates current Library.Theme to all windows and components",
    Callback = function()
        Library:RefreshAll()
        Library:Notify({ Title = "Refreshed", Text = "Theme propagated to all components.", Duration = 2 })
    end,
})

-- ── Unload ───────────────────────────────────────────────────
local unloadSection = SettingsTab:AddSection({ Text = "Library" })

unloadSection:AddLabel({ Text = "Version: " .. (Library.Version or "3.0.0") })
unloadSection:AddLabel({ Text = "Hot-reload safe. Re-running the script will unload this instance." })

unloadSection:AddButton({
    Text    = "Unload Library",
    Tooltip = "Destroys all windows and ScreenGuis created by the library",
    FX      = { TopSweep = true },
    Callback = function()
        Library:Notify({
            Title    = "Unloading",
            Text     = "Réaltra UI will destroy in 1.5 seconds...",
            Duration = 1.5,
        })
        task.delay(1.5, function()
            Library:Unload()
        end)
    end,
})

-- ============================================================
--  FINAL INIT: Auto-load config + welcome notification
-- ============================================================
SaveManager:LoadAutoloadConfig()

task.delay(3.5, function()
    Library:Notify({
        Title    = "Réaltra Showcase Ready",
        Text     = "All 8 tabs loaded. Explore each one to see every feature!",
        Duration = 6,
        Position = "BottomRight",
        FX       = { TopSweep = true },
    })
end)
