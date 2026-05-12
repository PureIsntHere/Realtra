# Réaltra UI Library

> A next-generation UI library.

<div align="center">

![Version](https://img.shields.io/badge/version-3.3.6-c4a7e7?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-31748f?style=flat-square)
![Lua](https://img.shields.io/badge/language-Lua-eb6f92?style=flat-square)

**[Documentation](https://github.com/PureIsntHere/Realtra/wiki)** &nbsp;•&nbsp; **[API Reference](https://github.com/PureIsntHere/Realtra/wiki/API-Reference)** &nbsp;•&nbsp; **[Examples](https://github.com/PureIsntHere/Realtra/wiki/Examples)**

</div>

---

## Features

- **Universal Executor Support** — Works across Delta, Solara, Krnl, Hydrogen, Fluxus, Celery, Xeno and more. Gracefully degrades on limited executors
- **Component-Rich** — Buttons, Toggles, Sliders, Textboxes, Dropdowns, MultiDropdowns, ColorPickers, Hotkeys, ProgressBars, Labels
- **25+ Built-in Themes** — Live runtime theme switching, custom theme support, and a full live color editor
- **Config System** — Save, load, and auto-load configs with per-flag control
- **Modals** — Loading Splash, Authorization key system, and Announcement dialogs
- **HUD Elements** — Draggable watermark and always-visible keybind overlay
- **FX System** — Scanlines, top sweep, grid background, and corner brackets — on windows and per-component
- **Layout System** — Multi-tab, section/groupbox, two-column layout, DependencyBox, and nested Tabbox
- **Docking Panel** — Collapsible sidebar dock that snaps and follows the window
- **Mobile Support** — Touch input, responsive layout, keyboard nudge on text focus
- **Cross-Executor Safety** — Clipboard, console, file I/O and GUI protection all degrade gracefully when unavailable

---

## Getting Started

```lua
local Repo = "https://raw.githubusercontent.com/PureIsntHere/Realtra/main/"

local Library      = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "ThemeManager.lua"))()()
local SaveManager  = loadstring(game:HttpGet(Repo .. "SaveManager.lua"))()

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("MyScript")
```

> **Note:** `ThemeManager.lua` returns a factory — call it twice `()()`.

---

## Basic Usage Example

```lua
local Window = Library:CreateWindow({
    Title    = "My Script",
    SubTitle = "v1.0",
    Size     = Vector2.new(780, 500),
})

local Tab = Window:AddTab("Main")

Tab:AddToggle({
    Text     = "Enable Feature",
    Flag     = "FeatureEnabled",
    Value    = false,
    Callback = function(v)
        print("Feature:", v)
    end,
})

Tab:AddSlider({
    Text  = "Walk Speed",
    Flag  = "WalkSpeed",
    Min   = 16, Max = 250, Step = 2, Value = 16,
    Callback = function(v)
        local hum = game.Players.LocalPlayer.Character
            and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end,
})

Tab:AddButton({
    Text     = "Notify Me",
    Callback = function()
        Library:Notify({ Title = "Hello", Text = "Réaltra is running.", Duration = 3 })
    end,
})

Tab:AddDropdown({
    Text    = "Mode",
    Flag    = "GameMode",
    Options = { "Normal", "Hard", "Extreme" },
    Value   = "Normal",
    Callback = function(v) print("Mode:", v) end,
})

Tab:AddColorPicker({
    Text    = "Accent Color",
    Flag    = "AccentColor",
    Default = Color3.fromRGB(196, 167, 231),
    Callback = function(color, alpha) end,
})

Tab:AddHotkey({
    Text  = "Toggle UI",
    Flag  = "UIToggle",
    Value = "RightShift",
    Callback = function(k) end,
})
```

---

## Theming

```lua
-- Apply a built-in preset
ThemeManager:SetTheme("Rose Pine")   -- default
ThemeManager:SetTheme("Dracula")
ThemeManager:SetTheme("Cyberpunk")

-- List all presets
for _, name in ipairs(ThemeManager:ListThemes()) do
    print(name)
end

-- Add the live theme editor to your UI
local SettingsTab = Window:AddTab("Settings")
ThemeManager:CreateThemeManager(SettingsTab:AddSection({ Text = "Appearance" }))
```

**Built-in presets:** Rose Pine · Dracula · Cyberpunk · Vaporwave · Azure · Void · Void-Red · Void-Cyan · Void-Pink · Forest · Crimson · Cream · Pastel · Retro · Cappuccino · Discord · Beautiful Blues · Shades of Teal · DownTown · Slytherin · Gryffindor · RavenClaw · Carlos&Cruella · Amethyst · Slate · Solarized Light

---

## Config Management

```lua
SaveManager:SetFolder("MyScript")

-- Wire auto-save into every component callback
local function save() SaveManager:AttemptSave("autosave") end

Tab:AddToggle({ Flag = "Feature1", Callback = function() save() end, ... })
Tab:AddSlider({ Flag = "Feature2", Callback = function() save() end, ... })

-- Add full config UI to settings tab
SaveManager:BuildConfigSection(SettingsTab)

-- Auto-load the last-used config on startup
SaveManager:LoadAutoloadConfig()
```

---

## Advanced

**Loading Splash:**
```lua
local splash = Library:ShowLoadingSplash({
    Title  = "My Script",
    Status = "Initializing...",
})
splash:SetProgress(0.5, "Loading modules...")
splash:SetProgress(1.0, "Done!")
task.wait(0.3)
splash:Close()
```

**Announcement Modal:**
```lua
Library:ShowAnnouncement({
    Title   = "Update Available",
    Message = "Version 2.0 is now live. Update for new features and fixes.",
    Buttons = {
        { Text = "Update", Primary = true,  Callback = function() end },
        { Text = "Later",  Primary = false, Callback = function() end },
    },
})
```

**Authorization / Key System:**
```lua
Library:RequestAuth({
    Title       = "KEY REQUIRED",
    MaxAttempts = 3,
    ValidateKey = function(key)
        return key == "MY-SECRET-KEY"
    end,
    OnSuccess = function(key)
        -- build your UI here
    end,
    OnFail = function(key)
        Library:Notify({ Title = "Denied", Text = "Invalid key.", Duration = 3 })
    end,
})
```

**Notifications with FX:**
```lua
Library:Notify({
    Title    = "Alert",
    Text     = "Player detected nearby!",
    Duration = 5,
    Position = "TopRight",
    FX       = { TopSweep = true },
})
```

**DependencyBox:**
```lua
local master = Tab:AddToggle({ Text = "Enable Aimbot", Flag = "AimOn" })
local depBox = Tab:AddDependencyBox({ Dependency = master, Text = "Aimbot Settings" })
depBox:AddSlider({ Text = "FOV", Flag = "AimFOV", Min = 10, Max = 300, Value = 90 })
```

**Nested Tabbox:**
```lua
local tabbox = Tab:AddTabbox()
local subA = tabbox:AddTab("Aimbot")
local subB = tabbox:AddTab("Triggerbot")
subA:AddToggle({ Text = "Enable", Flag = "AimEnabled" })
```

---

## Compatibility & Safety

- All executor-specific APIs (`readfile`, `setclipboard`, `gethui`, `protectgui`, etc.) are checked at load time via `Core.Compat` and degrade gracefully
- GUI is parented to `gethui()` or `CoreGui` with `protectgui` where available
- Duplicate flags emit a warning and are ignored rather than silently overwriting
- Hot-reload safe — call `Library:Unload()` before re-running to cleanly destroy all UI

```lua
-- Hot-reload guard pattern
if typeof(getgenv) == "function" and getgenv().__MyScript then
    getgenv().__MyScript:Unload()
end
local Library = loadstring(...)()
if typeof(getgenv) == "function" then
    getgenv().__MyScript = Library
end
```

---

## License

MIT — see [LICENSE](LICENSE)
