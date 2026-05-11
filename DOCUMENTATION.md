# Réaltra UI Library — Complete Documentation

> **Version 3.0.0** · Production-ready executor UI library for Roblox scripts  
> Supports: Delta, Solara, Krnl, Hydrogen, Fluxus, Celery, Xeno (PC + Mobile)

---

## Table of Contents

1. [Getting Started](#1-getting-started)
2. [Library API](#2-library-api)
3. [Window](#3-window)
4. [Tabs](#4-tabs)
5. [Components](#5-components)
   - [Label](#label)
   - [Button](#button)
   - [Toggle](#toggle)
   - [Slider](#slider)
   - [TextInput](#textinput)
   - [Dropdown](#dropdown)
   - [MultiDropdown](#multidropdown)
   - [Hotkey](#hotkey)
   - [ColorPicker](#colorpicker)
   - [ProgressBar](#progressbar)
   - [Section / Groupbox](#section--groupbox)
   - [DependencyBox](#dependencybox)
   - [Tabbox (Nested Tabs)](#tabbox-nested-tabs)
6. [SaveManager](#6-savemanager)
7. [ThemeManager](#7-thememanager)
8. [Modals](#8-modals)
   - [Loading Splash](#loading-splash)
   - [Authorization](#authorization)
   - [Announcement](#announcement)
9. [HUD Elements](#9-hud-elements)
   - [Watermark](#watermark)
   - [Keybind Overlay](#keybind-overlay)
10. [Notifications](#10-notifications)
11. [FX System](#11-fx-system)
12. [Docking Panel](#12-docking-panel)
13. [Tips & Best Practices](#13-tips--best-practices)
14. [Common Use Cases](#14-common-use-cases)
15. [Unique Use Cases](#15-unique-use-cases)
16. [Full Example Script](#16-full-example-script)

---

## 1. Getting Started

### Loading the Library

```lua
local Repo = "https://raw.githubusercontent.com/PureIsntHere/Realtra/main/"

local Library     = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "ThemeManager.lua"))()()
local SaveManager  = loadstring(game:HttpGet(Repo .. "SaveManager.lua"))()
```

> **Note:** `ThemeManager.lua` returns a factory function — call it twice `()()`.

### Minimal Setup

```lua
local Window = Library:CreateWindow({
    Title    = "My Script",
    SubTitle = "v1.0",
})

local Tab = Window:AddTab("Main")

Tab:AddToggle({
    Text     = "God Mode",
    Flag     = "GodMode",
    Value    = false,
    Callback = function(value)
        -- your code
    end
})
```

### Wiring Up SaveManager and ThemeManager

```lua
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("MyScript")

-- Add the built-in config UI to any tab
local SettingsTab = Window:AddTab("Settings")
ThemeManager:CreateThemeManager(SettingsTab:AddSection({ Text = "Appearance" }))
SaveManager:BuildConfigSection(SettingsTab)

-- Auto-load the last-used config
SaveManager:LoadAutoloadConfig()
```

---

## 2. Library API

`Library` is the top-level object returned by `Library.lua`.

### `Library:CreateWindow(opts)`

Creates and returns a `Window`. The window is immediately visible.

| Option | Type | Default | Description |
|:---|:---|:---|:---|
| `Title` | string | `""` | Large header text |
| `SubTitle` | string | `nil` | Smaller right-aligned subtitle |
| `Size` | Vector2 | `800×500` | Initial size (desktop) |
| `Width` | number | — | Overrides `Size.X` |
| `Height` | number | — | Overrides `Size.Y` |
| `Theme` | table | `Library.Theme` | Override the theme for this window |

```lua
local Window = Library:CreateWindow({
    Title    = "Réaltra",
    SubTitle = "Combat Script",
    Size     = Vector2.new(700, 520),
})
```

---

### `Library:Notify(opts)`

Shows a floating notification. Multiple notifications at the same position stack and animate without overlapping.

| Option | Type | Default | Description |
|:---|:---|:---|:---|
| `Title` | string | `"Notification"` | Bold top line |
| `Text` | string | `""` | Body text |
| `Duration` | number | `nil` | Auto-close after N seconds. Omit to persist |
| `Position` | string | `"TopRight"` | `"TopRight"`, `"TopLeft"`, `"BottomRight"`, `"BottomLeft"` |
| `FX` | table | `nil` | Visual effects (see [FX System](#11-fx-system)) |

```lua
Library:Notify({
    Title    = "Script Loaded",
    Text     = "Réaltra v3.0 is running.",
    Duration = 4,
    Position = "TopRight",
})
```

---

### `Library:CreateWatermark(opts)`

Creates a small draggable HUD label fixed to a corner of the screen. See [Watermark](#watermark).

### `Library:ShowKeybindOverlay()` / `HideKeybindOverlay()` / `ToggleKeybindOverlay()`

Shows/hides the compact keybind list HUD. See [Keybind Overlay](#keybind-overlay).

### `Library:ShowLoadingSplash(opts)`

Shows a loading splash modal. See [Loading Splash](#loading-splash).

### `Library:RequestAuth(opts)`

Shows an auth key modal. See [Authorization](#authorization).

### `Library:ShowAnnouncement(opts)`

Shows an announcement modal. See [Announcement](#announcement).

### `Library:RefreshAll()`

Propagates the current `Library.Theme` to every open window and all their components. Call this after manually mutating `Library.Theme`.

```lua
Library.Theme.Accent = Color3.fromRGB(255, 100, 100)
Library:RefreshAll()
```

### `Library:Unload()`

Destroys every window and removes all ScreenGuis created by the library. Safe to call on hot-reload.

```lua
-- Hot reload pattern
if getgenv().MyScriptLoaded then
    getgenv().MyScriptLoaded:Unload()
end
local Library = loadstring(...)()
getgenv().MyScriptLoaded = Library
```

---

## 3. Window

```lua
local Window = Library:CreateWindow({ Title = "Demo" })
```

### `Window:AddTab(name, icon?)`

Creates and returns a `Tab` object. The first tab added is auto-selected.

| Param | Type | Description |
|:---|:---|:---|
| `name` | string | Tab label text |
| `icon` | string? | Optional Roblox asset ID for a tab icon |

```lua
local CombatTab  = Window:AddTab("Combat")
local VisualTab  = Window:AddTab("Visuals")
local SettingsTab = Window:AddTab("Settings", "rbxassetid://7733960981")
```

### `Window:SelectTab(name)`

Programmatically switches to the named tab.

```lua
Window:SelectTab("Visuals")
```

### `Window:ToggleDock()`

Opens or closes the side docking panel.

### `Window:RefreshTheme()`

Refreshes all visual elements of the window and its components to match the current `_theme`. Normally called automatically by `Library:RefreshAll()`.

### `Window:Destroy()`

Destroys the window, all its components, all connections, and its `ScreenGui`.

---

## 4. Tabs

A `Tab` is returned by `Window:AddTab()`. It is the primary container for components.  
All component-creation methods (`AddToggle`, `AddSlider`, etc.) are available on tabs, sections, and groupboxes — they all share the same `ComponentMixin` interface.

### Two-Column Layout

```lua
local Left  = Tab:AddLeftGroupbox("Left Column")
local Right = Tab:AddRightGroupbox("Right Column")

-- Left and Right are Section objects, side by side at 50% width each
Left:AddToggle({ Text = "Option A", Flag = "OptionA" })
Right:AddToggle({ Text = "Option B", Flag = "OptionB" })
```

> **Tip:** Always call `AddLeftGroupbox` before `AddRightGroupbox`. They are paired — Left creates the row, Right fills it.

---

## 5. Components

Every component accepts a `Flag` property. Flagged components are tracked by `SaveManager` for config persistence. Use unique string flags across your entire script.

Every component also accepts a `Tooltip` string that shows a hover tooltip.

```lua
Tab:AddToggle({
    Text    = "Auto Farm",
    Flag    = "AutoFarm",         -- for SaveManager
    Tooltip = "Automatically farms mobs in the current area",
    Value   = false,
    Callback = function(v) end,
})
```

---

### Label

A read-only text element. Useful for status displays, section headers, or dynamic info.

```lua
local lbl = Tab:AddLabel({ Text = "Status: Idle" })

-- Update it later
lbl:SetText("Status: Running")

-- Read it
print(lbl:GetText())
```

**Methods:**

| Method | Description |
|:---|:---|
| `SetText(str)` | Updates the displayed text |
| `GetText()` | Returns current text |

**Use case — live FPS counter:**
```lua
local fpsLabel = Tab:AddLabel({ Text = "FPS: --" })

game:GetService("RunService").RenderStepped:Connect(function(dt)
    fpsLabel:SetText(string.format("FPS: %d", math.floor(1 / dt)))
end)
```

---

### Button

A clickable button. Callbacks are throttled to 0.2s to prevent spam.

```lua
Tab:AddButton({
    Text     = "Teleport to Spawn",
    Tooltip  = "Teleports your character to the spawn point",
    Flag     = "TpSpawn",
    Callback = function()
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(
            CFrame.new(0, 5, 0)
        )
    end,
})
```

**Options:**

| Option | Type | Description |
|:---|:---|:---|
| `Text` | string | Button label |
| `Callback` | function | Called on click/tap |
| `FX` | table | Visual effects on the button surface |
| `Tooltip` | string | Hover tooltip |

**Methods:**

| Method | Description |
|:---|:---|
| `SetText(str)` | Changes button label |

---

### Toggle

An on/off switch. The most common component.

```lua
local toggle = Tab:AddToggle({
    Text     = "Speed Hack",
    Flag     = "SpeedHack",
    Value    = false,          -- initial state
    Tooltip  = "Multiplies WalkSpeed",
    Callback = function(enabled)
        local char = game.Players.LocalPlayer.Character
        if char then
            char.Humanoid.WalkSpeed = enabled and 100 or 16
        end
    end,
})
```

**Options:**

| Option | Type | Default | Description |
|:---|:---|:---|:---|
| `Text` | string | `"Toggle"` | Label |
| `Value` | boolean | `false` | Initial state |
| `Flag` | string | — | SaveManager key |
| `Callback` | function | — | `function(bool)` |

**Methods:**

| Method | Signature | Description |
|:---|:---|:---|
| `SetValue` | `(bool, animate?, ignoreCallback?)` | Sets state, optionally skipping animation or callback |
| `GetValue` | `() → bool` | Returns current state |
| `OnChanged` | `(fn: function(bool))` | Registers an additional listener without replacing `Callback` |

**`OnChanged` — non-destructive observer:**
```lua
-- Used internally by DependencyBox but useful for your own logic too
toggle:OnChanged(function(value)
    print("Toggle changed to:", value)
end)
```

> **Tip:** Use `SetValue(true, false, true)` to set a value silently (no animation, no callback). Useful when loading configs.

---

### Slider

A numeric range picker with a draggable knob. Works with mouse and touch.

```lua
local slider = Tab:AddSlider({
    Text     = "Field of View",
    Flag     = "FOV",
    Min      = 50,
    Max      = 120,
    Step     = 1,
    Value    = 70,
    Tooltip  = "Adjusts camera FOV",
    Callback = function(value)
        workspace.CurrentCamera.FieldOfView = value
    end,
})
```

**Options:**

| Option | Type | Default | Description |
|:---|:---|:---|:---|
| `Text` | string | `"Slider"` | Label |
| `Min` | number | `0` | Minimum value |
| `Max` | number | `100` | Maximum value |
| `Step` | number | `1` | Snap increment |
| `Value` | number | `Min` | Initial value |
| `Flag` | string | — | SaveManager key |
| `Callback` | function | — | `function(number)` |

**Methods:**

| Method | Signature | Description |
|:---|:---|:---|
| `SetValue` | `(number, animate?, ignoreCallback?)` | Programmatic set |
| `GetValue` | `() → number` | Returns current value |

**Use case — animation speed:**
```lua
Tab:AddSlider({
    Text     = "Animation Speed",
    Min      = 0.1,
    Max      = 3.0,
    Step     = 0.05,
    Value    = 1.0,
    Flag     = "AnimSpeed",
    Callback = function(v)
        game.Players.LocalPlayer.Character.Humanoid.PlaybackSpeed = v
    end,
})
```

---

### TextInput

A text field. Supports clipboard paste (Ctrl+V or right-click). On mobile, nudges the window upward when the keyboard appears.

```lua
local input = Tab:AddTextbox({
    Text        = "Target Name",
    Placeholder = "Enter player name...",
    Flag        = "TargetName",
    Tooltip     = "Name of the player to target",
    Callback    = function(text, enterPressed)
        if enterPressed then
            print("Targeting:", text)
        end
    end,
})
```

**Options:**

| Option | Type | Description |
|:---|:---|:---|
| `Text` | string | Label shown above the box |
| `Placeholder` | string | Greyed-out hint text |
| `Flag` | string | SaveManager key |
| `Callback` | function | `function(text: string, enterPressed: bool)` |

**Methods:**

| Method | Description |
|:---|:---|
| `SetText(str)` | Programmatically set input value |
| `GetText() → string` | Get current input value |

---

### Dropdown

A single-select option picker.

```lua
local dd = Tab:AddDropdown({
    Text     = "Game Mode",
    Flag     = "GameMode",
    Options  = { "Normal", "Hard", "Extreme" },
    Value    = "Normal",           -- initial selection
    Tooltip  = "Select difficulty",
    Callback = function(selected)
        print("Mode:", selected)
    end,
})
```

**Options:**

| Option | Type | Description |
|:---|:---|:---|
| `Text` | string | Label |
| `Options` | `{string}` | List of choices |
| `Value` | string | Initial selection |
| `Flag` | string | SaveManager key |
| `Callback` | function | `function(string)` |

**Methods:**

| Method | Description |
|:---|:---|
| `SetValue(str, animate?, ignoreCallback?)` | Change selection |
| `GetValue() → string` | Current selection |
| `SetOptions({string})` | Replace the option list entirely |

**Use case — dynamic options from game data:**
```lua
local playerDropdown = Tab:AddDropdown({
    Text    = "Target Player",
    Options = {},
    Flag    = "TargetPlayer",
})

-- Populate with current players
local function refreshPlayers()
    local names = {}
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    playerDropdown:SetOptions(names)
end

game.Players.PlayerAdded:Connect(refreshPlayers)
game.Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()
```

---

### MultiDropdown

A multi-select dropdown. Supports a maximum selections cap.

```lua
local mdd = Tab:AddMultiDropdown({
    Text          = "Active Abilities",
    Flag          = "ActiveAbilities",
    Options       = { "Speed", "Jump", "Fly", "NoClip", "Infinite Stamina" },
    Values        = { "Speed" },       -- pre-selected
    MaxSelections = 3,
    Callback      = function(selected)
        -- selected is a table of currently selected strings
        for _, ability in ipairs(selected) do
            print("Active:", ability)
        end
    end,
})
```

**Options:**

| Option | Type | Description |
|:---|:---|:---|
| `Options` | `{string}` | All available choices |
| `Values` | `{string}` | Initially selected values |
| `MaxSelections` | number | Cap on simultaneous selections (`math.huge` = unlimited) |
| `Flag` | string | SaveManager key |
| `Callback` | function | `function({string})` — full selected list |

**Methods:**

| Method | Description |
|:---|:---|
| `SetValues({string}, animate?, ignoreCallback?)` | Replace entire selection |
| `GetValues() → {string}` | Current selections |
| `ToggleValue(str)` | Toggle a single item |
| `ClearSelection()` | Deselect all |
| `SetMaxSelections(n)` | Change the cap |
| `SetOptions({string})` | Replace the option list |

---

### Hotkey

A rebindable keyboard shortcut. Clicking the button and pressing any key binds it. Automatically registers with the [Keybind Overlay](#keybind-overlay).

```lua
local hotkey = Tab:AddHotkey({
    Text     = "Toggle UI",
    Flag     = "UIToggle",
    Value    = "RightShift",          -- initial key name
    Tooltip  = "Press to show/hide the window",
    Callback = function(keyName)
        -- keyName is the Enum.KeyCode name string
        print("New keybind:", keyName)
    end,
})
```

**Options:**

| Option | Type | Description |
|:---|:---|:---|
| `Text` | string | Label shown next to the button |
| `Value` | string or EnumItem | Initial key (`"None"` = unbound) |
| `Flag` | string | SaveManager key |
| `Callback` | function | `function(keyName: string)` — fires when key is changed |

**Methods:**

| Method | Description |
|:---|:---|
| `SetValue(keyName)` | Programmatically bind a key |
| `GetValue() → string` | Current key name |
| `StartListening()` | Enter listen mode (next keypress binds) |
| `StopListening()` | Exit listen mode without changing the key |

**Listening for the keybind press (acting on it, not binding it):**
```lua
-- The Callback fires when the KEY IS CHANGED, not when it is pressed.
-- To act on a hotkey press, use UserInputService directly:
local hotkeyComp = Tab:AddHotkey({ Text = "Open Menu", Flag = "MenuKey", Value = "RightShift" })

game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode.Name == hotkeyComp:GetValue() then
        Window.Root.Visible = not Window.Root.Visible
    end
end)
```

---

### ColorPicker

An HSV + alpha color picker. Fully functional on mouse and touch.

```lua
local picker = Tab:AddColorPicker({
    Text         = "ESP Color",
    Flag         = "ESPColor",
    Default      = Color3.fromRGB(255, 100, 100),
    Transparency = 0,
    Tooltip      = "Color used for ESP boxes",
    Callback     = function(color, transparency)
        -- color: Color3
        -- transparency: 0 (opaque) → 1 (invisible)
        ESPModule:SetColor(color, transparency)
    end,
})
```

**Options:**

| Option | Type | Default | Description |
|:---|:---|:---|:---|
| `Default` | Color3 | `White` | Initial color |
| `Transparency` | number | `0` | Initial alpha (0–1) |
| `Flag` | string | — | SaveManager key |
| `Callback` | function | — | `function(Color3, number)` |

**Methods:**

| Method | Description |
|:---|:---|
| `SetValue(color, transparency, animate?)` | Set both color and alpha |
| `Toggle()` | Open/close the picker panel |

> **Tip:** The alpha bar is always shown. If you don't need transparency, just ignore the second argument in the callback.

---

### ProgressBar

A read-only visual progress bar. Useful for loading sequences or displaying a bounded value.

```lua
local bar = Tab:AddProgressBar({
    Text    = "Loading Assets",
    Value   = 0,       -- 0.0 to 1.0
    Tooltip = "Asset download progress",
})

-- Animate to 75%
bar:SetProgress(0.75)
```

**Methods:**

| Method | Description |
|:---|:---|
| `SetProgress(0..1)` | Animates fill to the given fraction |

**Use case — real loading sequence:**
```lua
local loadBar = Tab:AddProgressBar({ Text = "Initializing", Value = 0 })
local loadLabel = Tab:AddLabel({ Text = "Starting..." })

local steps = {
    { text = "Loading modules...",   pct = 0.2 },
    { text = "Fetching player data", pct = 0.5 },
    { text = "Building UI...",       pct = 0.8 },
    { text = "Done!",                pct = 1.0 },
}

task.spawn(function()
    for _, step in ipairs(steps) do
        loadLabel:SetText(step.text)
        loadBar:SetProgress(step.pct)
        task.wait(0.6)
    end
end)
```

---

### Section / Groupbox

A collapsible container with a header. All component methods work inside sections.  
`AddGroupbox` is an alias for `AddSection`.

```lua
-- These are identical:
local section = Tab:AddSection({ Text = "Combat Settings" })
local section = Tab:AddGroupbox("Combat Settings")
```

**Adding components inside:**
```lua
local section = Tab:AddSection({ Text = "Aimbot" })

section:AddToggle({ Text = "Enabled",     Flag = "AimbotOn"  })
section:AddSlider({ Text = "Smoothness",  Flag = "AimbotSmooth", Min = 1, Max = 20, Value = 5 })
section:AddSlider({ Text = "FOV Radius",  Flag = "AimbotFOV",   Min = 10, Max = 300, Value = 90 })
```

Sections are collapsible by clicking their header. They start open.

---

### DependencyBox

A `Section` whose visibility is driven by a `Toggle`. When the toggle is off, the entire section (and all its components) is hidden. This keeps your UI uncluttered.

```lua
local aimbotToggle = Tab:AddToggle({
    Text  = "Enable Aimbot",
    Flag  = "AimbotOn",
    Value = false,
})

-- This section only shows when aimbotToggle is ON
local aimbotSettings = Tab:AddDependencyBox({
    Dependency = aimbotToggle,
    Text       = "Aimbot Settings",
    Invert     = false,   -- true = show when toggle is OFF
})

aimbotSettings:AddSlider({ Text = "FOV",       Flag = "AimbotFOV",    Min = 10,  Max = 300, Value = 90 })
aimbotSettings:AddSlider({ Text = "Smoothness", Flag = "AimbotSmooth", Min = 1,   Max = 20,  Value = 5  })
aimbotSettings:AddDropdown({ Text = "Target Part", Flag = "AimbotPart", Options = { "Head", "Torso", "Nearest" } })
```

**Options:**

| Option | Type | Required | Description |
|:---|:---|:---|:---|
| `Dependency` | Toggle | ✅ | The toggle that controls visibility |
| `Text` | string | ❌ | Header label for the section |
| `Invert` | bool | ❌ | If `true`, shows when toggle is OFF |

**Inverted use case — "disable" section:**
```lua
local safeMode = Tab:AddToggle({ Text = "Safe Mode", Flag = "SafeMode", Value = true })

-- Shows dangerous options only when Safe Mode is OFF
local dangerZone = Tab:AddDependencyBox({
    Dependency = safeMode,
    Text       = "Advanced (Unsafe)",
    Invert     = true,
})
dangerZone:AddToggle({ Text = "Speed Bypass", Flag = "SpeedBypass" })
```

---

### Tabbox (Nested Tabs)

A mini tab interface that lives inside any groupbox, section, or tab. Useful for splitting a large feature into sub-categories.

```lua
local tabbox = Tab:AddTabbox()

local aimTab  = tabbox:AddTab("Aimbot")
local trigTab = tabbox:AddTab("Triggerbot")
local miscTab = tabbox:AddTab("Misc")

-- Components go directly on the tab objects
aimTab:AddToggle({ Text = "Enabled",    Flag = "AimbotOn"     })
aimTab:AddSlider({ Text = "FOV",        Flag = "AimbotFOV",    Min = 10, Max = 300 })
aimTab:AddSlider({ Text = "Smoothness", Flag = "AimbotSmooth", Min = 1,  Max = 20  })

trigTab:AddToggle({ Text = "Enabled",   Flag = "TrigOn"  })
trigTab:AddSlider({ Text = "Delay",     Flag = "TrigDelay", Min = 0, Max = 500, Step = 10 })

miscTab:AddToggle({ Text = "Auto Reload", Flag = "AutoReload" })
```

**Methods on the tabbox object:**

| Method | Description |
|:---|:---|
| `AddTab(name) → tab` | Creates a new sub-tab and returns it |
| `SelectTab(name)` | Switches to a named sub-tab |
| `RefreshTheme()` | Updates all button and component colors |
| `Destroy()` | Destroys all components and the UI |

---

## 6. SaveManager

`SaveManager` handles config persistence — saving and loading component values to JSON files.

### Setup

```lua
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("MyScriptName")   -- creates "MyScriptName/settings/" folder
```

### Flagging Components

Only components with a `Flag` property are saved/loaded.

```lua
Tab:AddToggle({ Text = "Speed", Flag = "SpeedEnabled", ... })
--                                     ^ this is the save key
```

Flags must be **unique across your entire script**. Duplicate flags will cause the last-set value to overwrite earlier ones.

### `SaveManager:Save(name)`

Saves all flagged component values to `<Folder>/settings/<name>.json`.

```lua
local success, err = SaveManager:Save("default")
if not success then
    Library:Notify({ Title = "Save Error", Text = err, Duration = 3 })
end
```

### `SaveManager:Load(name)`

Loads and applies a saved config.

```lua
local success, err = SaveManager:Load("default")
if not success then
    Library:Notify({ Title = "Load Error", Text = err, Duration = 3 })
end
```

### `SaveManager:AttemptSave(name)`

Debounced save — waits 1 second after the last call before writing. Ideal to wire into every component's `Callback` so changes are auto-saved.

```lua
local function autosave()
    SaveManager:AttemptSave("default")
end

Tab:AddToggle({ Text = "Feature", Flag = "Feat1", Callback = function() autosave() end })
Tab:AddSlider({ Text = "Speed",   Flag = "Feat2", Callback = function() autosave() end })
```

> **How it works:** If you move a slider quickly, `AttemptSave` cancels the pending save and resets the 1-second timer each time. Only one file write happens after you stop interacting.

### `SaveManager:LoadAutoloadConfig()`

Reads `<Folder>/settings/autoload.txt` and loads whichever config name is written there. Call this once at script start after `BuildConfigSection`.

### `SaveManager:BuildConfigSection(container)`

Builds a full config UI (load, save, overwrite, autoload) inside the given tab or section.

```lua
SaveManager:BuildConfigSection(SettingsTab)
-- or inside a specific groupbox:
SaveManager:BuildConfigSection(SettingsTab:AddSection({ Text = "Configs" }))
```

### `SaveManager:SetIgnoreIndexes({...})`

Prevents specific flags from being saved/loaded. The built-in config UI flags are auto-ignored.

```lua
SaveManager:SetIgnoreIndexes({ "UIToggle", "DebugMode" })
```

### `SaveManager:RefreshConfigList() → {string}`

Returns a list of all config names in the settings folder.

```lua
local configs = SaveManager:RefreshConfigList()
for _, name in ipairs(configs) do
    print(name)
end
```

---

## 7. ThemeManager

`ThemeManager` provides 25+ built-in theme presets and a live color editor.

### Setup

```lua
local ThemeManager = loadstring(game:HttpGet(Repo .. "ThemeManager.lua"))()()
ThemeManager:SetLibrary(Library)
```

### `ThemeManager:SetTheme(name or table)`

Apply a preset by name or pass a raw theme table.

```lua
ThemeManager:SetTheme("Cyberpunk")
ThemeManager:SetTheme("Dracula")
ThemeManager:SetTheme("Rose Pine")   -- default
```

### `ThemeManager:ListThemes() → {string}`

Returns all preset names, sorted alphabetically.

```lua
for _, name in ipairs(ThemeManager:ListThemes()) do
    print(name)
end
```

### `ThemeManager:GetTheme(name) → table`

Returns a deep copy of a preset. Modify it without affecting the original.

```lua
local myTheme = ThemeManager:GetTheme("Dracula")
myTheme.Accent = Color3.fromRGB(255, 50, 50)   -- custom accent
ThemeManager:SetTheme(myTheme)
```

### `ThemeManager:CreateThemeManager(group)`

Adds a full theme picker UI (dropdown + color pickers) into the given section or tab.

```lua
local uiSection = SettingsTab:AddSection({ Text = "Interface" })
ThemeManager:CreateThemeManager(uiSection)
```

### Built-in Theme Presets

| Name | Style |
|:---|:---|
| Rose Pine | Muted purple, soft — the default |
| Dracula | Purple/pink on dark charcoal |
| Cyberpunk | Neon cyan/yellow/pink on near-black |
| Vaporwave | Retro 80s — pink, cyan, magenta |
| Azure | Cool blue-slate, clean |
| Void | Pure black & white |
| Void - Red / Cyan / Pink / Magenta | Void variants with colored accents |
| Forest | Earthy greens and tans |
| Crimson | Deep red on near-black |
| Cream | Light parchment, warm |
| Pastel | Soft pastels on dark |
| Retro | Olive/yellow, vintage feel |
| Cappuccino | Warm browns |
| Discord | Familiar Discord dark |
| Beautiful Blues | Deep navy gradient |
| Shades of Teal | Teal on dark teal |
| DownTown | Purple/magenta neon |
| Slytherin | Dark green + silver |
| Gryffindor | Deep red + gold |
| RavenClaw | Navy + bronze |
| Carlos&Cruella | Black/white + red |
| Pastel | Soft mixed pastels |
| Amethyst | Deep purple with violet glow |
| Slate | Dark steel blue, minimal |
| Solarized Light | Warm light background |

### Custom Themes

```lua
ThemeManager:SetTheme({
    Background  = Color3.fromRGB(10,  10,  20),
    Background2 = Color3.fromRGB(20,  20,  35),
    TextColor   = Color3.fromRGB(220, 220, 255),
    SubTextColor = Color3.fromRGB(140, 140, 180),
    Accent      = Color3.fromRGB(80,  160, 255),
    Border      = Color3.fromRGB(40,  40,  70),
    Window = {
        Background   = Color3.fromRGB(10, 10, 20),
        TitleText    = Color3.fromRGB(220, 220, 255),
        SubtitleText = Color3.fromRGB(140, 140, 180),
        Border       = Color3.fromRGB(40,  40,  70),
        CornerBrackets = Color3.fromRGB(80, 80, 120),
    },
    Tab = {
        IdleFill   = Color3.fromRGB(20, 20, 35),
        ActiveFill = Color3.fromRGB(10, 10, 20),
        IdleText   = Color3.fromRGB(140, 140, 180),
        ActiveText = Color3.fromRGB(220, 220, 255),
        Border     = Color3.fromRGB(40, 40, 70),
    },
    EnableBrackets = true,
    EnableScanlines = false,
    EnableTopSweep  = false,
    EnableGridBG    = false,
})
```

---

## 8. Modals

### Loading Splash

A fullscreen loading modal with a progress bar and status text. Ideal for showing script initialization progress.

```lua
local splash = Library:ShowLoadingSplash({
    Title   = "My Script",
    Version = "2.4.1",
    Status  = "Initializing...",
    Footer  = "Loading modules",
})

-- Update progress as you load
splash:SetProgress(0.3, "Fetching remote data...")
task.wait(0.5)
splash:SetProgress(0.7, "Building interface...")
task.wait(0.5)
splash:SetProgress(1.0, "Done!")
task.wait(0.3)
splash:Close()
```

**Methods:**

| Method | Description |
|:---|:---|
| `SetProgress(0..1, statusText?)` | Animate bar + optional status update |
| `SetFooter(text)` | Update the small footer line |
| `Close()` | Fade out and destroy |

---

### Authorization

A key-validation modal with exponential backoff and lockout after too many attempts. Supports both synchronous and asynchronous validators.

**Synchronous validator:**
```lua
local auth = Library:RequestAuth({
    Title       = "Access Required",
    Subtitle    = "Enter your license key",
    MaxAttempts = 3,
    ValidateKey = function(key)
        return key == "SECRET-KEY-123"
    end,
    OnSuccess = function(key)
        Library:Notify({ Title = "Authorized", Text = "Welcome back!", Duration = 3 })
        -- build your UI here
    end,
    OnFail = function(key)
        Library:Notify({ Title = "Denied", Text = "Wrong key", Duration = 2 })
    end,
})
```

**Asynchronous validator (HTTP request):**
```lua
Library:RequestAuth({
    ValidateKey = function(key, callback)
        -- call callback(true/false) when done
        task.spawn(function()
            local ok, res = pcall(function()
                return game:HttpGet("https://yourapi.com/validate?key=" .. key)
            end)
            callback(ok and res == "valid")
        end)
    end,
    OnSuccess = function(key)
        -- proceed
    end,
})
```

**Options:**

| Option | Type | Default | Description |
|:---|:---|:---|:---|
| `Title` | string | `"AUTHORIZATION REQUIRED"` | Header text |
| `Subtitle` | string | — | Sub-header text |
| `ValidateKey` | `function(key, cb?)` | `→ false` | Validator. Return bool for sync, call `cb(bool)` for async |
| `OnSuccess` | `function(key)` | — | Fires on correct key |
| `OnFail` | `function(key)` | — | Fires on each wrong attempt |
| `MaxAttempts` | number | `5` | Lockout after this many failures |

> **Security note:** The validation closure is not stored on the returned object. Hookfunction attacks on the auth object's methods cannot bypass validation.

---

### Announcement

A stylized fullscreen announcement with configurable buttons.

```lua
Library:ShowAnnouncement({
    Title   = "⚠️  Update Required",
    Message = "Version 2.4 is required to use this script. Please update at github.com/example.",
    Buttons = {
        {
            Text     = "Update Now",
            Primary  = true,
            Callback = function()
                setclipboard("https://github.com/example")
                Library:Notify({ Title = "Link Copied", Text = "GitHub URL copied", Duration = 3 })
            end,
        },
        {
            Text     = "Dismiss",
            Primary  = false,
            Callback = function() end,
        },
    },
})
```

**Options:**

| Option | Type | Description |
|:---|:---|:---|
| `Title` | string | Bold header on the accent bar |
| `Message` | string | Body text (wraps) |
| `Buttons` | `{table}` | Array of `{ Text, Primary, Callback }` |
| `FX` | table | Visual effects on the container |

---

## 9. HUD Elements

### Watermark

A small draggable label anchored to a corner. Good for showing script name + version + player info.

```lua
local wm = Library:CreateWatermark({
    Text     = "MyScript v1.0",
    Position = UDim2.new(1, -10, 0, 10),   -- top-right (default)
})

-- Update it dynamically
game:GetService("RunService").RenderStepped:Connect(function(dt)
    local fps = math.floor(1 / dt)
    wm:SetText(string.format("MyScript v1.0  |  %d FPS", fps))
end)
```

**Options:**

| Option | Type | Default | Description |
|:---|:---|:---|:---|
| `Text` | string | `""` | Initial text |
| `Position` | UDim2 | Top-right corner | Anchor position |
| `Theme` | table | `Library.Theme` | Override theme |

**Methods:**

| Method | Description |
|:---|:---|
| `SetText(str)` | Update watermark text |
| `SetVisible(bool)` | Show or hide |
| `Destroy()` | Remove entirely |

**Rich watermark example:**
```lua
local wm = Library:CreateWatermark({ Text = "" })
local player = game.Players.LocalPlayer

game:GetService("RunService").Heartbeat:Connect(function(dt)
    local char = player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local fps = math.floor(1 / dt)

    wm:SetText(string.format(
        "Script  |  %s  |  HP: %d  |  %d FPS",
        player.Name,
        hum and hum.Health or 0,
        fps
    ))
end)
```

---

### Keybind Overlay

A compact always-visible list of all registered `Hotkey` components. All hotkeys auto-register — you only need to control visibility.

```lua
-- Show on startup
Library:ShowKeybindOverlay()

-- Toggle with a keybind
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightAlt then
        Library:ToggleKeybindOverlay()
    end
end)
```

**Methods:**

| Method | Description |
|:---|:---|
| `Library:ShowKeybindOverlay()` | Make visible |
| `Library:HideKeybindOverlay()` | Hide |
| `Library:ToggleKeybindOverlay()` | Toggle |

> **Tip:** Hotkeys with the value `"None"` are automatically hidden from the overlay. They appear as soon as a key is bound.

---

## 10. Notifications

Notifications stack cleanly at any corner. Each position has its own independent stack.

```lua
-- Basic
Library:Notify({
    Title    = "Feature Enabled",
    Text     = "Speed hack is now active.",
    Duration = 3,
})

-- Persistent (no Duration = stays until Close() is called)
local persistent = Library:Notify({
    Title    = "Searching...",
    Text     = "Looking for targets",
    Position = "BottomRight",
})
-- later:
persistent:Close()

-- With FX
Library:Notify({
    Title    = "Alert",
    Text     = "Player detected nearby!",
    Duration = 5,
    Position = "TopLeft",
    FX       = { TopSweep = true },
})
```

**Position values:** `"TopRight"` · `"TopLeft"` · `"BottomRight"` · `"BottomLeft"`

**Methods on a notification object:**

| Method | Description |
|:---|:---|
| `Close()` | Slide out + collapse + destroy |

---

## 11. FX System

Visual effects that can be applied to windows or notifications.

### Window FX

Enable effects globally in the theme:

```lua
Library.Theme.EnableScanlines = true
Library.Theme.EnableTopSweep  = true
Library.Theme.EnableBrackets  = true
Library.Theme.EnableGridBG    = true
Library:RefreshAll()
```

Or configure a theme with them enabled:

```lua
ThemeManager:SetTheme({
    -- ... colors ...
    EnableBrackets  = true,
    EnableScanlines = false,
    EnableTopSweep  = true,
    EnableGridBG    = false,
})
```

### Component / Notification FX

Pass an `FX` table to `AddButton`, `Notify`, `ShowLoadingSplash`, or `ShowAnnouncement`:

```lua
Tab:AddButton({
    Text = "Execute",
    FX   = { TopSweep = true },
})

Library:Notify({
    Title = "Done",
    Text  = "Process complete",
    FX    = { Scanlines = true, TopSweep = true },
})
```

### FX Options

| Key | Type | Description |
|:---|:---|:---|
| `Scanlines` | bool or table | Animated horizontal scan line |
| `TopSweep` | bool or table | Animated line sweeping across the top |
| `Grid` | bool or table | Static grid of dots/lines in background |

**Fine-grained FX config:**
```lua
FX = {
    Scanlines = {
        Color        = Color3.fromRGB(0, 255, 200),
        Transparency = 0.8,
        Speed        = 80,
    },
    TopSweep = {
        Color     = Color3.fromRGB(255, 200, 0),
        Thickness = 3,
        Speed     = 250,
        Length    = 180,
        Gap       = 30,
    },
    Grid = {
        Color = Color3.fromRGB(40, 40, 80),
        Alpha = 0.1,
        Gap   = 20,
    },
}
```

### Theme FX Config Keys

| Key | Default | Description |
|:---|:---|:---|
| `FX.ScanlineColor` | TextColor | Scanline color |
| `FX.ScanlineTransparency` | `0.85` | 0 = solid, 1 = invisible |
| `FX.ScanlineSpeed` | `60` | Pixels/second |
| `FX.TopSweepColor` | bracket | Sweep color |
| `FX.TopSweepThickness` | `3` | Sweep bar height in px |
| `FX.TopSweepSpeed` | `180` | Pixels/second |
| `FX.TopSweepLength` | `120` | Width of the sweep bar |
| `FX.TopSweepGap` | `24` | Pause between sweeps |
| `FX.CornerBrackets` | accent | Corner bracket color |
| `FX.CornerBracketThickness` | `1` | Bracket line thickness |
| `FX.GridColor` | border | Grid line color |
| `FX.GridAlpha` | `0.15` | Grid opacity |
| `FX.GridGap` | `16` | Pixels between grid lines |

---

## 12. Docking Panel

The docking panel is a collapsible sidebar that lists all tabs in the window. It is created automatically on the first `AddTab` call.

- **Toggle:** Click the `≡` icon in the title bar.
- **Snap:** Click "Snap" inside the panel to attach it to the left edge of the window. It will follow the window when dragged.
- **Resize:** Drag the grip at the bottom-right corner of the dock panel.

The dock's state (visible/snapped/width) is persisted to `dock/state.json` automatically.

---

## 13. Tips & Best Practices

### Use Flags on Everything You Want Saved
```lua
-- Good
Tab:AddToggle({ Text = "Speed", Flag = "SpeedEnabled", ... })

-- Bad — this component will be invisible to SaveManager
Tab:AddToggle({ Text = "Speed", ... })
```

### Use Unique Flags — Namespace Them
```lua
-- Bad — "Enabled" will collide across features
Tab:AddToggle({ Flag = "Enabled", ... })

-- Good — prefix by feature
Tab:AddToggle({ Flag = "Aimbot_Enabled", ... })
Tab:AddToggle({ Flag = "ESP_Enabled", ... })
```

### Use DependencyBox to Reduce Clutter
Every feature that has sub-settings should use a `DependencyBox`. Only show the settings when the master toggle is on.

### Debounce Auto-Save with AttemptSave
Avoid `SaveManager:Save()` directly inside slider callbacks — it writes to disk on every mouse move. Use `AttemptSave` instead.

### Use the Notification Stack for Feedback
Instead of print/warn, surface results to the user:
```lua
local ok, err = SaveManager:Load("default")
if ok then
    Library:Notify({ Title = "Loaded", Text = "Config applied successfully", Duration = 2 })
else
    Library:Notify({ Title = "Load Failed", Text = err, Duration = 5 })
end
```

### `SetValue(..., false, true)` for Silent Init
When building your own init logic outside of SaveManager, use the `ignoreCallback, noAnimate` flags to set initial values without triggering side effects:
```lua
speedToggle:SetValue(true, false, true)   -- set ON, no animation, no callback
```

### Check Mobile Before Sizing
On mobile, the default 480×340 is used automatically. If you specify a custom size, consider branching:
```lua
local isMobile = game:GetService("UserInputService").TouchEnabled
    and not game:GetService("UserInputService").KeyboardEnabled

local Window = Library:CreateWindow({
    Size = isMobile and Vector2.new(360, 480) or Vector2.new(800, 500),
})
```

### Watermark + Keybind Overlay Visibility Tie-In
```lua
local visible = true
local wm = Library:CreateWatermark({ Text = "Script" })

game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        visible = not visible
        Window.Root.Visible = visible
        wm:SetVisible(visible)
        if visible then Library:ShowKeybindOverlay()
        else Library:HideKeybindOverlay() end
    end
end)
```

---

## 14. Common Use Cases

### Toggle a Game Feature On/Off
```lua
Tab:AddToggle({
    Text  = "Infinite Jump",
    Flag  = "InfJump",
    Value = false,
    Callback = function(enabled)
        _G.InfJump = enabled
    end,
})

game:GetService("UserInputService").JumpRequest:Connect(function()
    if _G.InfJump then
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)
```

### Player Target Selector
```lua
local targetDD = Tab:AddDropdown({
    Text    = "Target",
    Options = {},
    Flag    = "TargetPlayer",
    Callback = function(name)
        _G.Target = game.Players:FindFirstChild(name)
    end,
})

local function refresh()
    local names = {}
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    targetDD:SetOptions(names)
    if names[1] then targetDD:SetValue(names[1], false, true) end
end

game.Players.PlayerAdded:Connect(refresh)
game.Players.PlayerRemoving:Connect(refresh)
refresh()
```

### Color-Coded ESP
```lua
Tab:AddColorPicker({
    Text     = "ESP Box Color",
    Flag     = "ESPColor",
    Default  = Color3.fromRGB(255, 50, 50),
    Callback = function(color, alpha)
        for _, highlight in ipairs(ESPModule.Highlights) do
            highlight.FillColor = color
            highlight.FillTransparency = alpha
        end
    end,
})
```

### Throttled Walk Speed
```lua
Tab:AddSlider({
    Text     = "Walk Speed",
    Flag     = "WalkSpeed",
    Min      = 16,
    Max      = 250,
    Step     = 2,
    Value    = 16,
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = v
        end
    end,
})
```

### Config With Auto-Save on Every Change
```lua
local function save() SaveManager:AttemptSave("autosave") end

Tab:AddToggle({ Flag = "Feat_A", Callback = function() save() end, ... })
Tab:AddSlider({ Flag = "Feat_B", Callback = function() save() end, ... })
Tab:AddDropdown({ Flag = "Feat_C", Callback = function() save() end, ... })

-- On load, restore everything
SaveManager:Load("autosave")
```

---

## 15. Unique Use Cases

### Dynamic Section Based on Game State
```lua
local section = Tab:AddSection({ Text = "In-Game Tools" })
section.Root.Visible = false   -- hidden by default

game.Players.LocalPlayer.CharacterAdded:Connect(function()
    section.Root.Visible = true
end)
game.Players.LocalPlayer.CharacterRemoving:Connect(function()
    section.Root.Visible = false
end)
```

### Per-Place Script Config
```lua
-- Automatically loads a different config per game
local placeId = game.PlaceId
local configName = "place_" .. tostring(placeId)

if not table.find(SaveManager:RefreshConfigList(), configName) then
    SaveManager:Save(configName)   -- create default config for this place
end
SaveManager:Load(configName)
```

### Live Aimbot FOV Circle on Watermark
```lua
local fovSlider = Tab:AddSlider({
    Text  = "Aimbot FOV",
    Flag  = "AimFOV",
    Min   = 10,
    Max   = 300,
    Value = 90,
})
local wm = Library:CreateWatermark({ Text = "" })

game:GetService("RunService").RenderStepped:Connect(function(dt)
    wm:SetText(string.format("Script  |  FOV: %d  |  %d FPS",
        fovSlider:GetValue(), math.floor(1/dt)))
end)
```

### Nested Tabbox for a Full Combat Module
```lua
local combatTab = Window:AddTab("Combat")
local tabbox    = combatTab:AddTabbox()

-- Aimbot sub-tab
local aim = tabbox:AddTab("Aimbot")
local aimEnabled = aim:AddToggle({ Text = "Enable", Flag = "Aim_On", Value = false })
local aimSettings = aim:AddDependencyBox({ Dependency = aimEnabled, Text = "Settings" })
aimSettings:AddSlider({ Text = "FOV",        Flag = "Aim_FOV",    Min = 10,  Max = 300, Value = 90 })
aimSettings:AddSlider({ Text = "Smoothness", Flag = "Aim_Smooth", Min = 1,   Max = 30,  Value = 8  })
aimSettings:AddDropdown({ Text = "Bone",     Flag = "Aim_Bone",   Options = {"Head","Torso","Nearest"} })

-- Triggerbot sub-tab
local trig = tabbox:AddTab("Trigger")
local trigEnabled = trig:AddToggle({ Text = "Enable", Flag = "Trig_On", Value = false })
local trigSettings = trig:AddDependencyBox({ Dependency = trigEnabled, Text = "Settings" })
trigSettings:AddSlider({ Text = "Delay (ms)", Flag = "Trig_Delay", Min = 0, Max = 500, Step = 10, Value = 50 })
trigSettings:AddToggle({ Text = "Head Only",  Flag = "Trig_Head" })
```

### Key System With HTTP Validation + Loading Splash
```lua
local splash = Library:ShowLoadingSplash({
    Title  = "My Script",
    Status = "Authenticating...",
})

Library:RequestAuth({
    Title       = "Key System",
    MaxAttempts = 3,
    ValidateKey = function(key, callback)
        task.spawn(function()
            local ok, result = pcall(function()
                return game:HttpGet("https://yourapi.com/validate?k=" .. key)
            end)
            callback(ok and result == "VALID")
        end)
    end,
    OnSuccess = function(key)
        splash:SetProgress(1.0, "Authorized!")
        task.wait(0.5)
        splash:Close()
        -- build your actual UI here
    end,
    OnFail = function(key)
        Library:Notify({ Title = "Auth Failed", Text = "Invalid key", Duration = 3 })
    end,
})
```

### Announcement on Version Mismatch
```lua
local CURRENT_VERSION = "2.4.0"

-- Fetch latest version string from GitHub
local ok, latest = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/.../version.txt"):match("^%s*(.-)%s*$")
end)

if ok and latest ~= CURRENT_VERSION then
    Library:ShowAnnouncement({
        Title   = "Update Available",
        Message = string.format(
            "You are on v%s. Version %s is now available.\n\nUpdate for new features and bug fixes.",
            CURRENT_VERSION, latest
        ),
        Buttons = {
            { Text = "Copy Link", Primary = true,  Callback = function() setclipboard("https://github.com/...") end },
            { Text = "Ignore",    Primary = false, Callback = function() end },
        },
    })
end
```

---

## 16. Full Example Script

A complete, production-ready script demonstrating the entire library.

```lua
-- ============================================================
--  MyScript — Full Réaltra UI Example
-- ============================================================

local Repo = "https://raw.githubusercontent.com/PureIsntHere/Realtra/main/"

local Library      = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "ThemeManager.lua"))()()
local SaveManager  = loadstring(game:HttpGet(Repo .. "SaveManager.lua"))()

-- ── Hot Reload Guard ────────────────────────────────────────
if getgenv and getgenv().__MyScript then
    getgenv().__MyScript:Unload()
end

-- ── Loading Splash ──────────────────────────────────────────
local splash = Library:ShowLoadingSplash({
    Title   = "MyScript",
    Version = "1.0.0",
    Status  = "Loading...",
})

task.spawn(function()
    splash:SetProgress(0.3, "Connecting modules...")
    task.wait(0.4)
    splash:SetProgress(0.7, "Building interface...")
    task.wait(0.4)
    splash:SetProgress(1.0, "Ready!")
    task.wait(0.3)
    splash:Close()
end)

-- ── Setup ───────────────────────────────────────────────────
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("MyScript")
ThemeManager:SetTheme("Rose Pine")

-- ── Window ──────────────────────────────────────────────────
local Window = Library:CreateWindow({
    Title    = "MyScript",
    SubTitle = "v1.0.0",
    Size     = Vector2.new(780, 520),
})

local function save() SaveManager:AttemptSave("autosave") end

-- ── Watermark ───────────────────────────────────────────────
local wm = Library:CreateWatermark({ Text = "MyScript v1.0" })
game:GetService("RunService").Heartbeat:Connect(function(dt)
    wm:SetText(string.format("MyScript  |  %d FPS", math.floor(1 / dt)))
end)

-- ── Tab: Combat ─────────────────────────────────────────────
local CombatTab = Window:AddTab("Combat")

-- Aimbot section
local aimbotOn = CombatTab:AddToggle({
    Text  = "Aimbot",
    Flag  = "Aim_Enabled",
    Value = false,
    Callback = function(v) _G.AimbotEnabled = v; save() end,
})

local aimbotBox = CombatTab:AddDependencyBox({
    Dependency = aimbotOn,
    Text       = "Aimbot Settings",
})

aimbotBox:AddSlider({
    Text = "FOV Radius", Flag = "Aim_FOV",
    Min = 10, Max = 300, Value = 90,
    Callback = function(v) _G.AimbotFOV = v; save() end,
})
aimbotBox:AddSlider({
    Text = "Smoothness", Flag = "Aim_Smooth",
    Min = 1, Max = 30, Value = 8,
    Callback = function(v) _G.AimbotSmooth = v; save() end,
})
aimbotBox:AddDropdown({
    Text = "Target Bone", Flag = "Aim_Bone",
    Options = { "Head", "Upper Torso", "Lower Torso", "Nearest" },
    Value = "Head",
    Callback = function(v) _G.AimbotBone = v; save() end,
})
aimbotBox:AddHotkey({
    Text = "Aimbot Key", Flag = "Aim_Key",
    Value = "Q",
    Callback = function(v) _G.AimbotKey = v; save() end,
})

-- ── Tab: Visuals ─────────────────────────────────────────────
local VisualTab = Window:AddTab("Visuals")

local Left, Right = VisualTab:AddLeftGroupbox("ESP"), VisualTab:AddRightGroupbox("Chams")

local espOn = Left:AddToggle({
    Text = "ESP Enabled", Flag = "ESP_On", Value = false,
    Callback = function(v) _G.ESPEnabled = v; save() end,
})
Left:AddColorPicker({
    Text = "ESP Color", Flag = "ESP_Color",
    Default = Color3.fromRGB(255, 60, 60),
    Callback = function(c, t) _G.ESPColor = c; _G.ESPAlpha = t; save() end,
})
Left:AddToggle({ Text = "Show Names",    Flag = "ESP_Names",    Callback = save })
Left:AddToggle({ Text = "Show Distance", Flag = "ESP_Distance", Callback = save })
Left:AddSlider({ Text = "Max Distance",  Flag = "ESP_MaxDist",
    Min = 50, Max = 2000, Value = 500, Callback = function() save() end })

Right:AddToggle({ Text = "Chams",        Flag = "Chams_On",     Callback = save })
Right:AddColorPicker({ Text = "Chams Color", Flag = "Chams_Color",
    Default = Color3.fromRGB(100, 100, 255),
    Callback = function() save() end })
Right:AddDropdown({ Text = "Chams Style", Flag = "Chams_Style",
    Options = { "Solid", "Wireframe", "Neon" }, Value = "Solid",
    Callback = function() save() end })

-- ── Tab: Player ──────────────────────────────────────────────
local PlayerTab = Window:AddTab("Player")
local tabbox    = PlayerTab:AddTabbox()

local movTab = tabbox:AddTab("Movement")
movTab:AddToggle({ Text = "Speed Hack",      Flag = "Move_Speed",    Callback = save })
movTab:AddSlider({ Text = "Walk Speed",      Flag = "Move_SpeedVal", Min = 16, Max = 250, Value = 16, Callback = save })
movTab:AddToggle({ Text = "Infinite Jump",   Flag = "Move_InfJump",  Callback = save })
movTab:AddToggle({ Text = "No Clip",         Flag = "Move_NoClip",   Callback = save })
movTab:AddToggle({ Text = "Fly",             Flag = "Move_Fly",      Callback = save })
movTab:AddSlider({ Text = "Fly Speed",       Flag = "Move_FlySpeed", Min = 10, Max = 200, Value = 60, Callback = save })

local charTab = tabbox:AddTab("Character")
charTab:AddToggle({ Text = "God Mode",       Flag = "Char_God",      Callback = save })
charTab:AddToggle({ Text = "Infinite Ammo",  Flag = "Char_InfAmmo",  Callback = save })
charTab:AddSlider({ Text = "Jump Power",     Flag = "Char_Jump",     Min = 7, Max = 200, Value = 7, Callback = save })
charTab:AddColorPicker({ Text = "Shirt Color",  Flag = "Char_Shirt",  Default = Color3.fromRGB(255,255,255), Callback = save })
charTab:AddColorPicker({ Text = "Pants Color",  Flag = "Char_Pants",  Default = Color3.fromRGB(255,255,255), Callback = save })

-- ── Tab: Settings ────────────────────────────────────────────
local SettingsTab = Window:AddTab("Settings")

local uiSection = SettingsTab:AddSection({ Text = "Interface" })
ThemeManager:CreateThemeManager(uiSection)

SaveManager:BuildConfigSection(SettingsTab)
SaveManager:LoadAutoloadConfig()

-- Fallback: try loading autosave if no autoload is set
task.defer(function()
    if table.find(SaveManager:RefreshConfigList(), "autosave") then
        SaveManager:Load("autosave")
    end
end)

-- ── Keybind Overlay ──────────────────────────────────────────
Library:ShowKeybindOverlay()

-- ── Hide/Show Toggle ─────────────────────────────────────────
local UIS = game:GetService("UserInputService")
local guiVisible = true
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        guiVisible = not guiVisible
        Window.Root.Visible = guiVisible
        wm:SetVisible(guiVisible)
        if guiVisible then Library:ShowKeybindOverlay()
        else Library:HideKeybindOverlay() end
    end
end)

-- ── Store for hot reload ─────────────────────────────────────
if getgenv then
    getgenv().__MyScript = Library
end

Library:Notify({
    Title    = "MyScript",
    Text     = "Loaded successfully. Press RShift to hide.",
    Duration = 4,
    Position = "TopRight",
})
```

---

*Réaltra UI Library · v3.0.0 · github.com/PureIsntHere/Realtra*

---

## Getting Started

To use Réaltra UI, you must load the library and its auxiliary managers. It is recommended to load them from a hosted source (like GitHub) to ensure you have the latest version.

```lua
local Repo = "https://raw.githubusercontent.com/PureIsntHere/Realtra/main/"

local Library = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repo .. "SaveManager.lua"))()
```

---

## Core Library

### Window Creation

The Window is the root container for your UI.

**Usage:**
```lua
local Window = Library:CreateWindow({
    Title = "Réaltra UI",
    Subtitle = "Main Window",
    Size = Vector2.new(600, 500),
    Name = "MyWindow" -- Used for config saving
})
```

**Properties:**
| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `Title` | string | "Window" | The main header text. |
| `Subtitle` | string | "" | Smaller text below the title. |
| `Size` | Vector2 | (550, 400) | The initial size of the window. |
| `Name` | string | "Window" | Internal name used for saving window positions/configs. |

### Tabs & Containers

Content is organized into **Tabs**, which contain **Sections** (also known as Groupboxes).

**Creating a Tab:**
```lua
local MainTab = Window:AddTab("Dashboard")
```

**Creating a Section:**
Sections can be added to the left or right side of a tab.
```lua
-- Auto-aligns based on column usage, or use specific methods
local Section = MainTab:AddSection({ Text = "Main Controls" })

-- Specific alignment aliases
local LeftGroup = MainTab:AddLeftGroupbox("Left Group")
local RightGroup = MainTab:AddRightGroupbox("Right Group")
```

---

## Components

All components are added to a **Section** (or Groupbox).

### 1. Label
Displays static text.

```lua
Section:AddLabel({
    Text = "Status: Active",
    Tooltip = "Current script status" -- Optional hover text
})
```

### 2. Button
A clickable button that executes a callback.

```lua
Section:AddButton({
    Text = "Click Me",
    Tooltip = "Executes a function",
    Callback = function()
        print("Button pressed!")
    end
})
```

### 3. Toggle
A boolean switch.

```lua
Section:AddToggle({
    Text = "Enable Aimbot",
    Flag = "AimbotEnabled", -- Unique identifier for SaveManager
    Value = true, -- Default state
    Callback = function(bool)
        print("Aimbot is now:", bool)
    end
})
```

### 4. Slider
A numeric slider for selecting values within a range.

```lua
Section:AddSlider({
    Text = "WalkSpeed",
    Flag = "WalkSpeedSlider",
    Min = 16,
    Max = 100,
    Value = 16, -- Default value
    Rounding = 1, -- Decimal places (0 for integers)
    Callback = function(val)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
    end
})
```

### 5. Textbox
Input field for strings.

```lua
Section:AddTextbox({
    Text = "Target Player",
    Flag = "TargetName",
    Placeholder = "Enter name...",
    Callback = function(text)
        print("Target set to:", text)
    end
})
```

### 6. Dropdown
Select one option from a list.

```lua
Section:AddDropdown({
    Text = "Target Part",
    Flag = "TargetPart",
    Options = {"Head", "Torso", "HumanoidRootPart"},
    Value = "Head", -- Default option
    Callback = function(option)
        print("Selected:", option)
    end
})
```

### 7. MultiDropdown
Select multiple options from a list.

```lua
Section:AddMultiDropdown({
    Text = "Esp Filters",
    Flag = "EspFilters",
    Options = {"Players", "NPCs", "Items"},
    Values = { -- Default selected states
        Players = true,
        NPCs = false
    },
    Callback = function(selectedTable)
        -- Returns table like {Players = true, NPCs = false}
        for option, state in pairs(selectedTable) do
            print(option, state)
        end
    end
})
```

### 8. ColorPicker
Allows selecting a Color3 value. Usually attached to another component (like a Toggle) but can be standalone.

```lua
-- Adding to a Toggle
local MyToggle = Section:AddToggle({ ... })

MyToggle:AddColorPicker({
    Flag = "EspColor",
    Value = Color3.fromRGB(255, 0, 0), -- Default color
    Callback = function(color)
        -- Update color logic
    end
})

-- Standalone
Section:AddColorPicker({
    Text = "Accent Color",
    Flag = "AccentColor",
    Value = Color3.new(1, 1, 1),
    Callback = function(color) end
})
```

### 9. Hotkey (Keybind)
Allows the user to bind a key to an action.

```lua
Section:AddHotkey({
    Text = "Toggle Menu",
    Flag = "MenuKey",
    Value = Enum.KeyCode.RightControl, -- Default key
    Callback = function()
        Window:Toggle() -- Toggles UI visibility
    end
})
```

### 10. ProgressBar
Displays a progress value (0 to 1).

```lua
local Bar = Section:AddProgressBar({
    Text = "Loading...",
    Value = 0.5
})

-- Updating
Bar:SetValue(0.75)
```

---

## Theme Manager

The `ThemeManager` handles applying, saving, and loading visual themes.

**Setup:**
```lua
ThemeManager:SetLibrary(Library)
```

**Implementation:**
Create a dedicated tab for settings to allow users to change themes.

```lua
local ThemeTab = Window:AddTab("Settings")
local ThemeGroup = ThemeTab:AddLeftGroupbox("Theme")

-- Adds the dropdown and controls to the groupbox
ThemeManager:CreateThemeManager(ThemeGroup)
```

**Applying a Default Theme:**
```lua
ThemeManager:SetTheme("Void - Red")
```

---

## Save Manager

The `SaveManager` handles saving the state of Toggles, Sliders, Dropdowns, etc., to files.

**Setup:**
```lua
SaveManager:SetLibrary(Library)
SaveManager:SetIgnoreIndexes({ "IgnoreMe_Flag" }) -- Flags to skip saving
SaveManager:SetFolder("MyScript/Configs") -- Folder path in workspace
```

**Implementation:**
Add the config controls to your settings tab.

```lua
local ConfigGroup = ThemeTab:AddRightGroupbox("Configuration")
SaveManager:BuildConfigSection(ConfigGroup)
```

**Auto-Loading:**
To automatically load the user's last config on script start:
```lua
SaveManager:LoadAutoloadConfig()
```

---

## Utilities

### Notifications
Send a temporary notification to the user.

```lua
Library:Notify({
    Title = "Success",
    Text = "Config loaded successfully!",
    Duration = 5 -- Seconds
})
```

### Loading Splash
Show a loading screen before the UI appears.

```lua
local Splash = Library:ShowLoadingSplash({
    Title = "My Script",
    Footer = "Initializing..."
})

Splash:SetProgress(0.5, "Loading assets...")
task.wait(1)
Splash:Close()
```

### Authorization Window
Require a key before showing the main UI.

```lua
Library:RequestAuth({
    Title = "Authentication",
    Subtitle = "Enter Key",
    ValidateKey = function(key)
        return key == "secret_password"
    end,
    OnSuccess = function()
        print("Logged in!")
        -- Create Window here
    end
})
```

### Announcements
Show a popup with news or updates.

```lua
Library:ShowAnnouncement({
    Title = "Update Log",
    Text = "Added new features...",
    Time = "12/11/2025"
})
```
