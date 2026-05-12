--!nocheck
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local Core = {
    Version = "3.3.6",
    Debug = false
}

-- Single-source executor feature detection. Evaluated once at load time.
-- Use Core.Compat throughout instead of scattered typeof() checks.
Core.Compat = {
    hasFileIO     = typeof(readfile)   == "function" and typeof(writefile) == "function"
                    and typeof(isfile) == "function" and typeof(isfolder)  == "function"
                    and typeof(makefolder) == "function",
    hasGethui     = typeof(gethui)          == "function",
    hasProtectGui = typeof(protectgui)      == "function"
                    or (rawget(_G, "syn") ~= nil and typeof((rawget(_G, "syn") or {}).protect_gui) == "function")
                    or typeof(rawget(_G, "protect_gui")) == "function",
    hasClipboard  = typeof(setclipboard)    == "function" or typeof(toclipboard) == "function",
    hasRconsole   = typeof(rconsolecreate)  == "function",
    hasGetgenv    = typeof(getgenv)         == "function",
    hasNewtable   = typeof(newtable)        == "function",
    hasRequest    = typeof(request)         == "function" or typeof(http_request) == "function",
}

Core.Layout = {
    HeaderHeight = 32,
    TabPillHeight = 22,
    DockWidth = 150,
    DockHeaderHeight = 30,
    DockFooterHeight = 36,
    ComponentHeight = 32,
    SliderHeight = 40,
    Padding = 6,
    IconSize = 20,
    ButtonHeight = 32,
}

-- ZIndex values for dynamic layering (ZIndexBehavior.Sibling).
-- On open, the dropdown/picker boosts its ancestor section above siblings.
Core.ZIndex = {
    TabCover     = 50,   -- tab-switch animation cover (within Pages)
    Badge        = 10,   -- tab badge pill (within tab button)
    Dropdown     = 999,  -- raised on Root + ancestor section when dropdown/picker is open
    Tooltip      = 1000, -- tooltip layer (within its own ScreenGui)
}

Core.TweenCache = {
    Default = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Linear = TweenInfo.new(1, Enum.EasingStyle.Linear),
}

Core.Theme = {
    Background = Color3.fromRGB(25, 23, 36),
    Background2 = Color3.fromRGB(31, 29, 46),
    Background3 = Color3.fromRGB(27, 25, 40),
    TextColor = Color3.fromRGB(224, 222, 244),
    SubTextColor = Color3.fromRGB(144, 140, 170),
    DisabledText = Color3.fromRGB(128, 124, 155),
    Accent = Color3.fromRGB(196, 167, 231),
    AccentDim = Color3.fromRGB(127, 109, 150),
    Border = Color3.fromRGB(38, 35, 58),

    Scrollbar = {
        Color = Color3.fromRGB(96, 98, 104),
        Thickness = 2,
    },

    Overlays = {
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 0.3,
    },

    Rounding = 6,
    Padding = 6,
    LineThickness = 1,

    Font = Enum.Font.Gotham,
    FontMono = Enum.Font.Code,

    EnableScanlines = false,
    EnableTopSweep = false,
    EnableBrackets = true,
    EnableGridBG = false,

    Window = {
        Background = Color3.fromRGB(25, 23, 36),
        TitleText = Color3.fromRGB(224, 222, 244),
        SubtitleText = Color3.fromRGB(144, 140, 170),
        Border = Color3.fromRGB(38, 35, 58),
        CornerBrackets = Color3.fromRGB(84, 80, 112),
    },

    Tab = {
        IdleFill = Color3.fromRGB(31, 29, 46),
        ActiveFill = Color3.fromRGB(25, 23, 36),
        IdleText = Color3.fromRGB(144, 140, 170),
        ActiveText = Color3.fromRGB(224, 222, 244),
        Border = Color3.fromRGB(38, 35, 58),
        PillHeight = 22,
        Uppercase = false,
    },

    FX = {
        PulseBase = 0.45,
        PulseAmp = 0.35,
        PulseHz = 1.6,

        CornerBrackets = Color3.fromRGB(84, 80, 112),
        CornerBracketThickness = 1,

        ScanlineColor = Color3.fromRGB(224, 222, 244),
        ScanlineTransparency = 0.85,
        ScanlineSpeed = 60,

        TopSweepColor = Color3.fromRGB(120, 115, 150),
        TopSweepThickness = 3,
        TopSweepSpeed = 180,
        TopSweepGap = 24,
        TopSweepLength = 120,

        GridColor = Color3.fromRGB(38, 35, 58),
        GridAlpha = 0.15,
        GridGap = 16,
    },

    Button = {
        DangerIdle   = Color3.fromRGB(163, 48,  37),
        DangerHover  = Color3.fromRGB(192, 57,  43),
        DangerText   = Color3.fromRGB(255, 240, 240),
        SuccessIdle  = Color3.fromRGB(34,  139, 73),
        SuccessHover = Color3.fromRGB(39,  174, 96),
        SuccessText  = Color3.fromRGB(230, 255, 240),
        WarningIdle  = Color3.fromRGB(184, 100, 26),
        WarningHover = Color3.fromRGB(230, 126, 34),
        WarningText  = Color3.fromRGB(255, 245, 210),
    },
}

Core.Config = {
    new = function(options)
        local self = setmetatable({}, {__index = Core.Config})
        local opts = options or {}
        self._configFolder = opts.folder or "configs"
        self._configFile = opts.filename or "settings.json"
        self._configName = opts.name or "cfg"
        self._fullPath = self._configFolder .. "/" .. self._configFile
        self._data = Core.Safety.createSecureConfigTable()
        self._isExecutor = Core.Safety.isExecutor()
        self:Load()
        return self
    end,
    Set = function(self, key, value)
        self._data[key] = value
        self._needsSave = true
    end,
    Get = function(self, key, default)
        local val = self._data[key]
        if val == nil then return default end
        return val
    end,
    GetConfigs = function(self)
        if not self._isExecutor then return {} end
        
        local files = {}
        local success, result = pcall(function()
            if not isfolder(self._configFolder) then
                makefolder(self._configFolder)
            end
            return listfiles(self._configFolder)
        end)
        
        if success and result then
            for _, file in ipairs(result) do
                -- Extract filename from path
                local fileName = file:match("[^/\\]+$")
                if fileName and fileName:match("%.json$") then
                    table.insert(files, fileName)
                end
            end
        end
        return files
    end,
    SetFilename = function(self, name)
        self._configFile = name
        if not name:match("%.json$") then self._configFile = name .. ".json" end
        self._fullPath = self._configFolder .. "/" .. self._configFile
    end,
    Save = function(self)
        if self._isExecutor then
            return self:_saveToFile()
        end
        return false
    end,
    Load = function(self)
        if self._isExecutor then
            return self:_loadFromFile()
        end
        return false
    end,
    _saveToFile = function(self)
        if not self._needsSave then return true end
        
        local success, err = pcall(function()
            if not isfolder(self._configFolder) then
                makefolder(self._configFolder)
            end
            
            local jsonData = HttpService:JSONEncode(self._data)
            writefile(self._fullPath, jsonData)
            self._needsSave = false
        end)
        
        if not success then
            if Core.Debug then
                local executorInfo = Core.Safety.getExecutorInfo()
                Core.Console.Error("Config Save Error:", err)
                Core.Console.Debug("Executor:", executorInfo.name, "v" .. executorInfo.version)
            end
            return false, err
        end
        
        return true
    end,
    _loadFromFile = function(self)
        local success, result = pcall(function()
            if not isfile(self._fullPath) then
                return {} 
            end
            
            local fileContent = readfile(self._fullPath)
            if not fileContent or fileContent == "" then
                return {}
            end
            
            return HttpService:JSONDecode(fileContent)
        end)
        
        if success then
            local secureData = Core.Safety.createSecureConfigTable()
            if result then
                for key, value in pairs(result) do
                    secureData[key] = value
                end
            end
            self._data = secureData
            return true
        else
            if isfile(self._fullPath) then
                pcall(writefile, self._fullPath .. ".bak", readfile(self._fullPath))
            end

            if Core.Debug then
                local executorInfo = Core.Safety.getExecutorInfo()
                Core.Console.Error("Config Load Error:", result)
                Core.Console.Debug("Executor:", executorInfo.name, "v" .. executorInfo.version)
            end
            self._data = Core.Safety.createSecureConfigTable()
            return false, result
        end
    end,
}

Core.Safety = {
    isExecutor = function()
        return Core.Compat.hasFileIO
    end,
    hasSecureTable = function()
        return Core.Compat.hasNewtable
    end,
    createSecureTable = function(arraySize, hashSize)
        if not Core.Compat.hasNewtable then return {} end
        local ok, t = pcall(newtable, arraySize or 0, hashSize or 0)
        return ok and t or {}
    end,
    createSecureConfigTable = function()
        return Core.Safety.createSecureTable(50, 25)
    end,
    getExecutorInfo = function()
        if Core.Debug and typeof(identifyexecutor) == "function" then
            local success, name, version = pcall(identifyexecutor)
            if success and name then
                return {
                    name = name or "Unknown",
                    version = version or "Unknown",
                    identified = true,
                    reliable = true,
                    method = "identifyexecutor"
                }
            end
        end
        
        local executorName = "Unknown"
        local detectionMethod = "none"
        
        if typeof(request) == "function" and typeof(readfile) == "function" then
            executorName = "Generic Executor"
            detectionMethod = "functions"
        end
        
        return {
            name = executorName,
            version = "Unknown",
            identified = executorName ~= "Unknown",
            reliable = detectionMethod == "global",
            method = detectionMethod
        }
    end,
    GetRoot = function()
        if Core.Compat.hasGethui then
            local ok, res = pcall(gethui)
            if ok and res then return res end
        end
        local ok, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok and cg then return cg end
        error("[Library] No safe GUI parent available.")
    end,
    ProtectInstance = function(inst)
        if typeof(protectgui) == "function" then
            pcall(protectgui, inst)
            return
        end
        local syn = rawget(_G, "syn")
        if syn and typeof(syn.protect_gui) == "function" then
            pcall(syn.protect_gui, inst)
            return
        end
        local pg = rawget(_G, "protect_gui")
        if not pg and Core.Compat.hasGetgenv then
            local ok, env = pcall(getgenv)
            if ok and env then pg = env.protect_gui end
        end
        if typeof(pg) == "function" then
            pcall(pg, inst)
        end
    end,
    RandomString = function(length)
        local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        local str = ""
        for i = 1, length or 16 do
            local rand = math.random(1, #chars)
            str = str .. string.sub(chars, rand, rand)
        end
        return str
    end,
}

Core.Console = {
    _initialized = false,
    _available = false,
    
    Init = function()
        if Core.Compat.hasRconsole and not Core.Console._initialized then
            local ok = pcall(function()
                rconsolecreate()
                if typeof(rconsolename) == "function" then
                    pcall(rconsolename, "Console")
                end
            end)
            Core.Console._available = ok
            Core.Console._initialized = true
            return ok
        end
        return false
    end,
    
    IsAvailable = function()
        return Core.Compat.hasRconsole
    end,

    _format = function(...)
        local args = {...}
        local strArgs = {}
        for i, v in ipairs(args) do
            strArgs[i] = tostring(v)
        end
        return table.concat(strArgs, " ")
    end,
    
    Log = function(...)
        local message = Core.Console._format(...)
        
        if typeof(rconsoleprint) == "function" then
            pcall(rconsoleprint, message .. "\n")
        end
        -- No game-output fallback: avoids LogService detection by in-game ACs.
    end,
    
    Info = function(...)
        local message = Core.Console._format(...)
        
        if typeof(rconsoleinfo) == "function" then
            pcall(rconsoleinfo, message)
        elseif typeof(rconsoleprint) == "function" then
            pcall(rconsoleprint, "@@LIGHT_CYAN@@")
            pcall(rconsoleprint, "[INFO] " .. message .. "\n")
        end
    end,
    
    Warn = function(...)
        local message = Core.Console._format(...)
        
        if typeof(rconsolewarn) == "function" then
            pcall(rconsolewarn, message)
        elseif typeof(rconsoleprint) == "function" then
            pcall(rconsoleprint, "@@YELLOW@@")
            pcall(rconsoleprint, "[WARN] " .. message .. "\n")
        end
    end,
    
    Error = function(...)
        local message = Core.Console._format(...)
        
        if typeof(rconsolerr) == "function" then
            pcall(rconsolerr, message)
        elseif typeof(rconsoleprint) == "function" then
            pcall(rconsoleprint, "@@RED@@")
            pcall(rconsoleprint, "[ERROR] " .. message .. "\n")
        end
    end,
    
    Debug = function(...)
        if not Core.Debug then return end
        local message = Core.Console._format(...)
        
        if typeof(rconsoledebug) == "function" then
            pcall(rconsoledebug, message)
        elseif typeof(rconsoleprint) == "function" then
            pcall(rconsoleprint, "@@GRAY@@")
            pcall(rconsoleprint, "[DEBUG] " .. message .. "\n")
        end
    end,
    
    Clear = function()
        if typeof(rconsoleclear) == "function" then
            pcall(rconsoleclear)
        end
    end,
}

Core.Clipboard = {
    -- sUNC does not standardize a clipboard function; support both the modern
    -- `setclipboard` name and the legacy old-UNC `toclipboard` alias.
    IsAvailable = function()
        return Core.Compat.hasClipboard
    end,

    Set = function(text)
        local str = tostring(text)
        local ok = false
        if typeof(setclipboard) == "function" then
            ok = pcall(setclipboard, str)
        elseif typeof(toclipboard) == "function" then
            ok = pcall(toclipboard, str)
        end
        if ok and Core.Debug then
            Core.Console.Debug("Clipboard set:", string.sub(str, 1, 50))
        end
        return ok
    end,
    
    Get = function()
        if typeof(getclipboard) == "function" then
            local ok, result = pcall(getclipboard)
            if ok then return result end
        end
        return nil
    end,
}

Core.Connections = {
    _registry = {},
    
    Track = function(owner, connection)
        if not owner or not connection then return end
        
        if not Core.Connections._registry[owner] then
            Core.Connections._registry[owner] = {}
        end
        
        table.insert(Core.Connections._registry[owner], connection)
        return connection
    end,
    
    DisconnectAll = function(owner)
        -- Disconnect all connections for a specific owner
        local connections = Core.Connections._registry[owner]
        if not connections then return 0 end
        
        local count = 0
        for _, conn in ipairs(connections) do
            if conn and typeof(conn.Disconnect) == "function" then
                pcall(function() conn:Disconnect() end)
                count = count + 1
            end
        end
        
        Core.Connections._registry[owner] = nil
        
        if Core.Debug then
            Core.Console.Debug("Disconnected", count, "connections for", tostring(owner))
        end
        
        return count
    end,
    
    GetCount = function(owner)
        local connections = Core.Connections._registry[owner]
        return connections and #connections or 0
    end,
    
    CleanupAll = function()
        local totalCount = 0
        for owner, connections in pairs(Core.Connections._registry) do
            totalCount = totalCount + Core.Connections.DisconnectAll(owner)
        end
        
        if Core.Debug then
            Core.Console.Debug("Total connections cleaned:", totalCount)
        end
        
        return totalCount
    end,
}

Core.FX = {
    CreateScanlines = function(parent, theme)
        local holder = Instance.new("Frame")
        holder.Name = "Scanlines"
        holder.Size = UDim2.fromScale(1, 1)
        holder.BackgroundTransparency = 1
        holder.ClipsDescendants = true
        holder.Parent = parent

        local line = Instance.new("Frame")
        line.Name = "Line"
        line.Size = UDim2.new(1, 0, 0, 2)
        line.BackgroundColor3 = theme.FX.ScanlineColor
        line.BackgroundTransparency = theme.FX.ScanlineTransparency
        line.BorderSizePixel = 0
        line.Parent = holder

        local running = true
        task.spawn(function()
            while running and holder.Parent do
                local ok = pcall(function()
                    local speed = theme.FX.ScanlineSpeed
                    local height = holder.AbsoluteSize.Y
                    if height <= 0 or speed <= 0 then task.wait(0.05) return end
                    local duration = height / speed
                    line.Position = UDim2.fromOffset(0, -2)
                    local tween = TweenService:Create(line, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Position = UDim2.fromOffset(0, height)})
                    tween:Play()
                    task.wait(duration)
                end)
                if not ok then break end
            end
        end)

        return {
            Destroy = function()
                running = false
                holder:Destroy()
            end
        }
    end,

    CreateTopSweep = function(parent, theme)
        local holder = Instance.new("Frame")
        holder.Name = "TopSweep"
        holder.Size = UDim2.new(1, 0, 0, theme.FX.TopSweepThickness)
        holder.Position = UDim2.fromOffset(0, 0)
        holder.BackgroundTransparency = 1
        holder.ClipsDescendants = true
        holder.ZIndex = 100
        holder.Parent = parent

        local sweep = Instance.new("Frame")
        sweep.Name = "Sweep"
        sweep.Size = UDim2.new(0, theme.FX.TopSweepLength, 1, 0)
        sweep.BackgroundColor3 = theme.FX.TopSweepColor
        sweep.BackgroundTransparency = 0
        sweep.BorderSizePixel = 0
        sweep.Parent = holder

        local gradient = Instance.new("UIGradient")
        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.2, 0.5),
            NumberSequenceKeypoint.new(0.5, 0.25),
            NumberSequenceKeypoint.new(0.8, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        })
        gradient.Parent = sweep

        local running = true
        task.spawn(function()
            while running and holder.Parent do
                local ok = pcall(function()
                    local width = holder.AbsoluteSize.X
                    local speed = theme.FX.TopSweepSpeed
                    if width <= 0 or speed <= 0 then task.wait(0.05) return end
                    local duration = (width + theme.FX.TopSweepLength) / speed
                    sweep.Position = UDim2.new(0, -theme.FX.TopSweepLength, 0, 0)
                    local tween = TweenService:Create(sweep, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Position = UDim2.new(0, width, 0, 0)})
                    tween:Play()
                    task.wait(duration + theme.FX.TopSweepGap / speed)
                end)
                if not ok then break end
            end
        end)

        return {
            Destroy = function()
                running = false
                holder:Destroy()
            end
        }
    end,

    CreateGrid = function(parent, theme)
        local holder = Instance.new("Frame")
        holder.Name = "GridBackground"
        holder.Size = UDim2.fromScale(1, 1)
        holder.BackgroundTransparency = 1
        holder.Parent = parent

        local verticals = Instance.new("Frame")
        verticals.Name = "VerticalLines"
        verticals.Size = UDim2.fromScale(1, 1)
        verticals.BackgroundTransparency = 1
        verticals.Parent = holder

        local vPattern = Instance.new("Frame")
        vPattern.Name = "Pattern"
        vPattern.Size = UDim2.new(0, 1, 1, 0)
        vPattern.BackgroundColor3 = theme.FX.GridColor
        vPattern.BackgroundTransparency = 1 - theme.FX.GridAlpha
        vPattern.BorderSizePixel = 0

        local horizontals = Instance.new("Frame")
        horizontals.Name = "HorizontalLines"
        horizontals.Size = UDim2.fromScale(1, 1)
        horizontals.BackgroundTransparency = 1
        horizontals.Parent = holder

        local hPattern = Instance.new("Frame")
        hPattern.Name = "Pattern"
        hPattern.Size = UDim2.new(1, 0, 0, 1)
        hPattern.BackgroundColor3 = theme.FX.GridColor
        hPattern.BackgroundTransparency = 1 - theme.FX.GridAlpha
        hPattern.BorderSizePixel = 0

        local _pending = false
        local function performUpdate()
            -- Clear existing lines
            for _, child in ipairs(verticals:GetChildren()) do child:Destroy() end
            for _, child in ipairs(horizontals:GetChildren()) do child:Destroy() end
            local width = holder.AbsoluteSize.X
            local height = holder.AbsoluteSize.Y
            local gap = theme.FX.GridGap
            for x = gap, width, gap do
                local line = vPattern:Clone()
                line.Position = UDim2.fromOffset(x, 0)
                line.Parent = verticals
            end
            for y = gap, height, gap do
                local line = hPattern:Clone()
                line.Position = UDim2.fromOffset(0, y)
                line.Parent = horizontals
            end
        end

        local function scheduleUpdate()
            if _pending then return end
            _pending = true
            task.defer(function()
                _pending = false
                if holder.Parent then performUpdate() end
            end)
        end

        local connection = holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(scheduleUpdate)
        performUpdate()
        return {
            Destroy = function()
                connection:Disconnect()
                holder:Destroy()
            end,
            Update = performUpdate
        }
    end,

    CreateCornerBrackets = function(parent, theme)
        local holder = Instance.new("Frame")
        holder.Name = "CornerBrackets"
        holder.Size = UDim2.fromScale(1, 1)
        holder.BackgroundTransparency = 1
        holder.ZIndex = 100
        holder.Parent = parent

        local color = theme.FX.CornerBrackets or theme.Window.CornerBrackets
        local thickness = theme.FX.CornerBracketThickness or 1
        local length = 10

        local function createLine(name, size, pos)
            local f = Instance.new("Frame")
            f.Name = name
            f.Size = size
            f.Position = pos
            f.BackgroundColor3 = color
            f.BorderSizePixel = 0
            f.Parent = holder
        end

        createLine("TL_H", UDim2.new(0, length, 0, thickness), UDim2.new(0, 0, 0, 0))
        createLine("TL_V", UDim2.new(0, thickness, 0, length), UDim2.new(0, 0, 0, 0))
        createLine("TR_H", UDim2.new(0, length, 0, thickness), UDim2.new(1, -length, 0, 0))
        createLine("TR_V", UDim2.new(0, thickness, 0, length), UDim2.new(1, -thickness, 0, 0))
        createLine("BL_H", UDim2.new(0, length, 0, thickness), UDim2.new(0, 0, 1, -thickness))
        createLine("BL_V", UDim2.new(0, thickness, 0, length), UDim2.new(0, 0, 1, -length))
        createLine("BR_H", UDim2.new(0, length, 0, thickness), UDim2.new(1, -length, 1, -thickness))
        createLine("BR_V", UDim2.new(0, thickness, 0, length), UDim2.new(1, -thickness, 1, -length))

        return {
            Destroy = function()
                holder:Destroy()
            end
        }
    end,

    Apply = function(element, fxConfig, theme)
        if not fxConfig then return {} end
        
        local effects = {}
        
        if fxConfig.Scanlines then
            local config = type(fxConfig.Scanlines) == "table" and fxConfig.Scanlines or {}
            local fxTheme = {
                FX = {
                    ScanlineColor = config.Color or theme.FX.ScanlineColor,
                    ScanlineTransparency = config.Transparency or theme.FX.ScanlineTransparency,
                    ScanlineSpeed = config.Speed or theme.FX.ScanlineSpeed
                }
            }
            effects.scanlines = Core.FX.CreateScanlines(element, fxTheme)
        end
        
        if fxConfig.TopSweep then
            local config = type(fxConfig.TopSweep) == "table" and fxConfig.TopSweep or {}
            local fxTheme = {
                FX = {
                    TopSweepThickness = config.Thickness or theme.FX.TopSweepThickness,
                    TopSweepLength = config.Length or theme.FX.TopSweepLength,
                    TopSweepColor = config.Color or theme.FX.TopSweepColor,
                    TopSweepSpeed = config.Speed or theme.FX.TopSweepSpeed,
                    TopSweepGap = config.Gap or theme.FX.TopSweepGap
                }
            }
            effects.topsweep = Core.FX.CreateTopSweep(element, fxTheme)
        end
        
        if fxConfig.Grid then
            local config = type(fxConfig.Grid) == "table" and fxConfig.Grid or {}
            local fxTheme = {
                FX = {
                    GridColor = config.Color or theme.FX.GridColor,
                    GridAlpha = config.Alpha or theme.FX.GridAlpha,
                    GridGap = config.Gap or theme.FX.GridGap
                }
            }
            effects.grid = Core.FX.CreateGrid(element, fxTheme)
        end
        
        return effects
    end,
}

Core.Behaviors = {
    MakeDraggable = function(handle, frame)
        
        local dragging = false
        local dragInput
        local dragStart
        local startPos
        local startRelativePos
        local connections = {}
        
        local function update(input)
            if not dragging or not frame.Parent then return end
            
            local currentPos = Core.Util.GetInputPosition(input)
            local delta = currentPos - dragStart
            
            local parentSize = frame.Parent.AbsoluteSize
            local frameSize = frame.AbsoluteSize
            local anchor = frame.AnchorPoint
            
            local targetX = startRelativePos.X + delta.X
            local targetY = startRelativePos.Y + delta.Y
            
            local clampedX = math.clamp(targetX, 0, parentSize.X - frameSize.X)
            local clampedY = math.clamp(targetY, 0, parentSize.Y - frameSize.Y)
            
            local finalX = clampedX + (anchor.X * frameSize.X)
            local finalY = clampedY + (anchor.Y * frameSize.Y)
            
            frame.Position = UDim2.fromOffset(finalX, finalY)
        end
        
        table.insert(connections, handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                
                dragging = true
                dragInput = input
                dragStart = Core.Util.GetInputPosition(input)
                startPos = frame.Position
                
                if frame.Parent then
                    local myAbsPos = frame.AbsolutePosition
                    local parentAbsPos = frame.Parent.AbsolutePosition
                    startRelativePos = myAbsPos - parentAbsPos
                end
                
                if input.UserInputType == Enum.UserInputType.Touch then
                    input:GetPropertyChangedSignal("UserInputState"):Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                        end
                    end)
                end
            end
        end))
        
        table.insert(connections, UserInputService.InputChanged:Connect(function(input)
            if input == dragInput or 
               (dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                             input.UserInputType == Enum.UserInputType.Touch)) then
                update(input)
            end
        end))
        
        table.insert(connections, UserInputService.InputEnded:Connect(function(input)
            if input == dragInput or 
               input.UserInputType == Enum.UserInputType.MouseButton1 or
               input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                dragInput = nil
            end
        end))
        
        table.insert(connections, handle.AncestryChanged:Connect(function()
            if not handle:IsDescendantOf(game) then
                dragging = false
                dragInput = nil
            end
        end))
        
        return {
            Destroy = function()
                dragging = false
                dragInput = nil
                for _, c in ipairs(connections) do
                    pcall(function() c:Disconnect() end)
                end
                connections = {}
            end
        }
    end,

    AddResizeGrip = function(frame, theme, minSize, maxSize)
        minSize = minSize or Vector2.new(200, 150)
        maxSize = maxSize or Vector2.new(math.huge, math.huge)
        
        local grip = Instance.new("TextButton")
        grip.Name = "ResizeGrip"
        grip.Size = UDim2.fromOffset(20, 20)
        grip.Position = UDim2.fromScale(1, 1)
        grip.AnchorPoint = Vector2.new(1, 1)
        grip.Text = ""
        grip.BackgroundTransparency = 1
        grip.Parent = frame
        grip.ZIndex = 100
        
        local indicators = Instance.new("Frame")
        indicators.Name = "Indicators"
        indicators.Size = UDim2.fromOffset(12, 12)
        indicators.Position = UDim2.fromScale(0.5, 0.5)
        indicators.AnchorPoint = Vector2.new(0.5, 0.5)
        indicators.BackgroundTransparency = 1
        indicators.ZIndex = 101
        indicators.Parent = grip
        
        for i = 1, 4 do
            for j = 1, 4-i do
                local dot = Instance.new("Frame")
                dot.Name = "Dot"
                dot.Size = UDim2.fromOffset(2, 2)
                dot.Position = UDim2.fromOffset(j * 3, i * 3)
                dot.BorderSizePixel = 0
                local initialColor
                if theme and theme.Accent then
                    initialColor = theme.Accent
                elseif theme and theme.TextColor then
                    initialColor = theme.TextColor
                else
                    initialColor = Color3.fromRGB(150, 150, 150)
                end
                dot.BackgroundColor3 = initialColor
                dot.BackgroundTransparency = 0.3
                dot.ZIndex = 102
                dot.Parent = indicators
            end
        end
        
        local resizing = false
        local activeInput = nil
        local startPos, startSize
        local connections = {}

        -- Support both mouse and touch; track the specific input object to block stray touches.
        table.insert(connections, grip.InputBegan:Connect(function(input)
            if Core.Util.IsActivate(input.UserInputType) and not activeInput then
                resizing = true
                activeInput = input
                startPos = Core.Util.GetInputPosition(input)
                startSize = frame.AbsoluteSize
            end
        end))

        table.insert(connections, UserInputService.InputChanged:Connect(function(input)
            if not resizing then return end
            -- For touch: match exact input object to ignore stray fingers.
            -- For mouse: accept MouseMovement while the initiating MouseButton1 is held.
            local relevant = (input == activeInput) or
                (activeInput and activeInput.UserInputType == Enum.UserInputType.MouseButton1
                    and input.UserInputType == Enum.UserInputType.MouseMovement)
            if relevant then
                local currentPos = Core.Util.GetInputPosition(input)
                local delta = currentPos - startPos
                local newSize = Vector2.new(
                    math.clamp(startSize.X + delta.X, minSize.X, maxSize.X), 
                    math.clamp(startSize.Y + delta.Y, minSize.Y, maxSize.Y)
                )
                frame.Size = UDim2.fromOffset(newSize.X, newSize.Y)
            end
        end))

        table.insert(connections, UserInputService.InputEnded:Connect(function(input)
            if input == activeInput then
                resizing = false
                activeInput = nil
            end
        end))
        
        table.insert(connections, grip.MouseEnter:Connect(function()
            for _, dot in ipairs(indicators:GetChildren()) do
                TweenService:Create(dot, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
            end
        end)
        )

        table.insert(connections, grip.MouseLeave:Connect(function()
            if not resizing then
                for _, dot in ipairs(indicators:GetChildren()) do
                    TweenService:Create(dot, TweenInfo.new(0.1), {BackgroundTransparency = 0.3}):Play()
                end
            end
        end))
        
        return {
            Grip = grip,
            SetMinSize = function(size) minSize = size end,
            SetMaxSize = function(size) maxSize = size end,
            Destroy = function()
                -- Disconnect input connections and destroy grip
                for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
                if grip and grip.Parent then grip:Destroy() end
            end,
            UpdateColors = function(newTheme)
                for _, dot in ipairs(indicators:GetChildren()) do
                    if dot.Name == "Dot" then
                        local accentColor
                        if newTheme and newTheme.Accent then
                            accentColor = newTheme.Accent
                        elseif newTheme and newTheme.TextColor then
                            accentColor = newTheme.TextColor
                        else
                            accentColor = Color3.fromRGB(150, 150, 150)
                        end
                        
                        if typeof(accentColor) == "Color3" then
                            dot.BackgroundColor3 = accentColor
                        else
                            dot.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
                        end
                    end
                end
            end
        }
    end,
}

Core.Util = {
    Create = function(className, properties)
        local inst = Instance.new(className)
        for k, v in pairs(properties or {}) do
            inst[k] = v
        end
        return inst
    end,
    Tween = function(object, properties, duration, style, direction)
        local info
        if not duration and not style and not direction then
            info = Core.TweenCache.Default
        elseif typeof(duration) == "TweenInfo" then
            info = duration
        else
            info = TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
        end
        local tween = TweenService:Create(object, info, properties)
        tween:Play()
        return tween
    end,
    ColorToHex = function(color)
        return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
    end,
    HexToColor = function(hex)
        hex = hex:gsub("#", "")
        return Color3.fromRGB(tonumber(hex:sub(1,2), 16), tonumber(hex:sub(3,4), 16), tonumber(hex:sub(5,6), 16))
    end,
    IsMobile = function()
        return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    end,
    -- IsActivate: fires for both finger-touch and mouse-click.
    -- Use on ALL InputBegan handlers that activate UI elements (buttons, sliders, dropdowns, etc.)
    IsActivate = function(inputType)
        return inputType == Enum.UserInputType.Touch or inputType == Enum.UserInputType.MouseButton1
    end,
    -- IsTouch: strictly finger-touch only. Use only when logic must differ between touch and mouse.
    IsTouch = function(inputType)
        return inputType == Enum.UserInputType.Touch
    end,
    -- IsMouse: mouse button 1 only.
    IsMouse = function(inputType)
        return inputType == Enum.UserInputType.MouseButton1
    end,
    IsTouchMovement = function(inputType)
        return inputType == Enum.UserInputType.Touch or inputType == Enum.UserInputType.MouseMovement
    end,
    GetInputPosition = function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            return Vector2.new(input.Position.X, input.Position.Y)
        else
            return UserInputService:GetMouseLocation()
        end
    end,
    ValidateProps = function(props, schema)
        if type(props) ~= "table" then
            return false, "Props must be a table"
        end
        for key, rules in pairs(schema) do
            if rules.Required and props[key] == nil then
                return false, "Missing required property: " .. key
            end
            if props[key] ~= nil and rules.Type then
                local valType = typeof(props[key])
                local allowedTypes = rules.Type
                
                if type(allowedTypes) == "string" then
                    if valType ~= allowedTypes then
                        return false, "Property " .. key .. " must be a " .. allowedTypes
                    end
                elseif type(allowedTypes) == "table" then
                    local match = false
                    for _, t in ipairs(allowedTypes) do
                        if valType == t then
                            match = true
                            break
                        end
                    end
                    if not match then
                        return false, "Property " .. key .. " must be one of: " .. table.concat(allowedTypes, ", ")
                    end
                end
            end
        end
        return true
    end,
    Throttle = function(func, wait)
        local lastRun = 0
        return function(...)
            local now = tick()
            if now - lastRun >= wait then
                lastRun = now
                return func(...)
            end
        end
    end,
}

Core.Tooltip = {
    _active = nil,
    _layer = nil,
    
    Init = function(screenGui)
        if Core.Tooltip._layer then return end
        Core.Tooltip._layer = Core.Util.Create("Frame", {
            Name = "TooltipLayer",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex = Core.ZIndex.Tooltip,
            Parent = screenGui
        })
    end,
    
    Show = function(text, parent, theme)
        if Core.Tooltip._active then Core.Tooltip.Hide() end
        if not Core.Tooltip._layer then return end
        
        local tooltip = Core.Util.Create("Frame", {
            Name = "Tooltip",
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundColor3 = theme.Background2,
            BorderSizePixel = 0,
            Active = false,
            Selectable = false,
            Parent = Core.Tooltip._layer
        })
        
        Core.Util.Create("UIStroke", {
            Color = theme.Border,
            Thickness = 1,
            Parent = tooltip
        })
        
        Core.Util.Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = tooltip
        })
        
        local label = Core.Util.Create("TextLabel", {
            Name = "Text",
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = theme.TextColor,
            Font = theme.Font,
            TextSize = 12,
            Parent = tooltip
        })
        
        Core.Util.Create("UIPadding", {
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent = tooltip
        })
        
        Core.Tooltip._active = tooltip
        
        local screenGui = Core.Tooltip._layer:FindFirstAncestorWhichIsA("ScreenGui")
        local yOffset = 0
        if screenGui and not screenGui.IgnoreGuiInset then
            yOffset = GuiService:GetGuiInset().Y
        end

        local mouse = UserInputService:GetMouseLocation()
        tooltip.Position = UDim2.fromOffset(mouse.X + 15, mouse.Y + 15 - yOffset)
        
        local connection = RunService.RenderStepped:Connect(function()
            if not tooltip.Parent then return end
            local m = UserInputService:GetMouseLocation()
            tooltip.Position = UDim2.fromOffset(m.X + 15, m.Y + 15 - yOffset)
        end)
        
        tooltip.Destroying:Connect(function()
            connection:Disconnect()
        end)
    end,
    
    Hide = function()
        if Core.Tooltip._active then
            Core.Tooltip._active:Destroy()
            Core.Tooltip._active = nil
        end
    end
}

-- Shared overlay ScreenGui used by dropdowns and colour-pickers so that their
-- pop-up panels escape ancestor ClipsDescendants / ScrollingFrame clipping.
-- IgnoreGuiInset = true means UDim2.fromOffset(x, y) directly maps to
-- AbsolutePosition coordinates — no inset subtraction required.
Core.Overlay = {
    _gui = nil,
    Get = function()
        if Core.Overlay._gui and Core.Overlay._gui.Parent then
            return Core.Overlay._gui
        end
        local gui = Core.Util.Create("ScreenGui", {
            Name = Core.Safety.RandomString(16),
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 999,
            Parent = Core.Safety.GetRoot(),
        })
        gui:SetAttribute("__g", true)
        Core.Safety.ProtectInstance(gui)
        Core.Overlay._gui = gui
        return gui
    end,
}

Core.Modal = {
    Create = function(name, theme)
        local screenGui = Core.Util.Create("ScreenGui", {
            Name = Core.Safety.RandomString(16),
            IgnoreGuiInset = true,
            DisplayOrder = 1000,
            ResetOnSpawn = false,
            Parent = Core.Safety.GetRoot()
        })
        screenGui:SetAttribute("__g", true)
        Core.Safety.ProtectInstance(screenGui)
        
        local background = Core.Util.Create("Frame", {
            Name = "Background",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = theme.Overlays.Color,
            BackgroundTransparency = 1,
            Parent = screenGui
        })
        
        local container = Core.Util.Create("Frame", {
            Name = "Container",
            Size = UDim2.fromOffset(300, 150),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            BackgroundColor3 = theme.Window.Background,
            BackgroundTransparency = 1,
            Parent = background
        })
        
        return {
            ScreenGui = screenGui,
            Background = background,
            Container = container
        }
    end,
    
    AnimateIn = function(modal, theme)
        TweenService:Create(modal.Background, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            BackgroundTransparency = theme.Overlays.Transparency
        }):Play()
        
        TweenService:Create(modal.Container, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 0
        }):Play()
        
        for _, child in ipairs(modal.Container:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
            elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {ImageTransparency = 0}):Play()
            elseif child:IsA("UIStroke") then
                TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Transparency = 0}):Play()
            end
        end
    end,
    
    Close = function(modal, callback)
        if not modal.ScreenGui then return end
        
        TweenService:Create(modal.Container, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
        TweenService:Create(modal.Background, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
        
        for _, child in ipairs(modal.Container:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
            elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {ImageTransparency = 1}):Play()
            elseif child:IsA("UIStroke") then
                TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Transparency = 1}):Play()
            elseif child:IsA("Frame") then
                TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
            end
        end
        
        task.delay(0.35, function()
            if modal.ScreenGui then modal.ScreenGui:Destroy() end
            if callback then callback() end
        end)
    end
}

local function BuildUI(Theme)
    local UI = { Version = "2.6.15" }

    local Button, Toggle, Slider, TextInput, Dropdown, MultiDropdown, Hotkey, ColorPicker, Notification, Section, ProgressBar, Label, Tabbox, Separator, RadioGroup, DataTable, CodeBlock

    local ComponentMixin = {}
    
    function ComponentMixin:AddLabel(opts)
        local comp = Label.new({ Parent = self:GetParent(), Text = opts.Text, Theme = self:GetTheme(), Tooltip = opts.Tooltip })
        comp.Flag = opts.Flag
        table.insert(self:GetComponentList(), comp)
        return comp
    end
    
    function ComponentMixin:AddButton(opts)
        local comp = Button.new({ Parent = self:GetParent(), Text = opts.Text, Callback = opts.Callback, Theme = self:GetTheme(), FX = opts.FX, Tooltip = opts.Tooltip })
        comp.Flag = opts.Flag
        table.insert(self:GetComponentList(), comp)
        return comp
    end

    function ComponentMixin:AddToggle(opts)
        local comp = Toggle.new({ Parent = self:GetParent(), Text = opts.Text, Value = opts.Value, Callback = opts.Callback, Theme = self:GetTheme(), Tooltip = opts.Tooltip })
        comp.Flag = opts.Flag
        table.insert(self:GetComponentList(), comp)
        return comp
    end

    function ComponentMixin:AddSlider(opts)
        local comp = Slider.new({ Parent = self:GetParent(), Text = opts.Text, Min = opts.Min, Max = opts.Max, Step = opts.Step, Value = opts.Value, Callback = opts.Callback, Theme = self:GetTheme(), Tooltip = opts.Tooltip })
        comp.Flag = opts.Flag
        table.insert(self:GetComponentList(), comp)
        return comp
    end

    function ComponentMixin:AddTextbox(opts)
        local comp = TextInput.new({ Parent = self:GetParent(), Text = opts.Text, Placeholder = opts.Placeholder, Callback = opts.Callback, Theme = self:GetTheme(), Tooltip = opts.Tooltip })
        comp.Flag = opts.Flag
        table.insert(self:GetComponentList(), comp)
        return comp
    end

    function ComponentMixin:AddDropdown(opts)
        local dd = Dropdown.new({ Parent = self:GetParent(), Text = opts.Text, Options = opts.Options, Value = opts.Value, Callback = opts.Callback, Theme = self:GetTheme(), Tooltip = opts.Tooltip })
        dd:SetOptions(opts.Options or {})
        dd.Flag = opts.Flag
        table.insert(self:GetComponentList(), dd)
        return dd
    end

    function ComponentMixin:AddMultiDropdown(opts)
        local mdd = MultiDropdown.new({ 
            Parent = self:GetParent(), 
            Text = opts.Text, 
            Options = opts.Options, 
            Values = opts.Values, 
            Value = opts.Value, 
            Callback = opts.Callback, 
            MaxSelections = opts.MaxSelections,
            Theme = self:GetTheme(),
            Tooltip = opts.Tooltip
        })
        mdd:SetOptions(opts.Options or {})
        mdd.Flag = opts.Flag
        table.insert(self:GetComponentList(), mdd)
        return mdd
    end

    function ComponentMixin:AddHotkey(opts)
        local comp = Hotkey.new({ Parent = self:GetParent(), Text = opts.Text, Value = opts.Value, Callback = opts.Callback, Theme = self:GetTheme(), Tooltip = opts.Tooltip })
        comp.Flag = opts.Flag
        table.insert(self:GetComponentList(), comp)
        return comp
    end

    function ComponentMixin:AddColorPicker(opts)
        local comp = ColorPicker.new({ 
            Parent = self:GetParent(), 
            Text = opts.Text, 
            Default = opts.Default, 
            Callback = opts.Callback, 
            Theme = self:GetTheme(),
            Tooltip = opts.Tooltip
        })
        comp.Flag = opts.Flag
        table.insert(self:GetComponentList(), comp)
        return comp
    end

    function ComponentMixin:AddProgressBar(opts)
        local comp = ProgressBar.new({ Parent = self:GetParent(), Text = opts.Text, Value = opts.Value, Theme = self:GetTheme(), Tooltip = opts.Tooltip })
        comp.Flag = opts.Flag
        table.insert(self:GetComponentList(), comp)
        return comp
    end
    
    function ComponentMixin:AddSection(opts)
        local comp = Section.new({
            Parent = self:GetParent(),
            Text = opts.Text,
            Theme = self:GetTheme(),
            Tooltip = opts.Tooltip
        })
        table.insert(self:GetComponentList(), comp)
        return comp
    end

    function ComponentMixin:AddGroupbox(name)
        return self:AddSection({ Text = name })
    end

    -- DependencyBox: a Section whose visibility is driven by a Toggle.
    -- opts.Dependency  = toggle reference (required)
    -- opts.Invert      = bool (optional) — when true, show when toggle is OFF
    -- opts.Text        = header label (optional)
    function ComponentMixin:AddDependencyBox(opts)
        assert(opts and opts.Dependency, "AddDependencyBox: opts.Dependency (a Toggle) is required")
        local section = self:AddSection({ Text = opts.Text or "" })
        local dep = opts.Dependency
        local invert = opts.Invert or false

        local function updateVisibility(value)
            section.Root.Visible = invert ~= (value == true)
        end

        -- Apply initial state immediately
        if dep.GetValue then
            updateVisibility(dep:GetValue())
        end

        -- Subscribe to future changes
        if dep.OnChanged then
            dep:OnChanged(updateVisibility)
        end

        return section
    end

    -- Tabbox: mini-tab group nested inside any groupbox or section.
    -- Returns a tabbox object; call tabbox:AddTab(name) for each sub-tab.
    function ComponentMixin:AddTabbox(opts)
        opts = opts or {}
        local comp = Tabbox.new({ Parent = self:GetParent(), Theme = self:GetTheme() })
        table.insert(self:GetComponentList(), comp)
        return comp
    end

    function ComponentMixin:AddSeparator(opts)
        opts = opts or {}
        local comp = Separator.new({ Parent = self:GetParent(), Text = opts.Text, Theme = self:GetTheme() })
        table.insert(self:GetComponentList(), comp)
        return comp
    end

    function ComponentMixin:AddRadioGroup(opts)
        local comp = RadioGroup.new({
            Parent   = self:GetParent(),
            Text     = opts.Text,
            Options  = opts.Options or {},
            Value    = opts.Value,
            Callback = opts.Callback,
            Theme    = self:GetTheme(),
            Tooltip  = opts.Tooltip,
        })
        comp.Flag = opts.Flag
        table.insert(self:GetComponentList(), comp)
        return comp
    end

    function ComponentMixin:AddTable(opts)
        local comp = DataTable.new({
            Parent    = self:GetParent(),
            Headers   = opts.Headers or {},
            Rows      = opts.Rows    or {},
            RowHeight = opts.RowHeight,
            Theme     = self:GetTheme(),
        })
        table.insert(self:GetComponentList(), comp)
        return comp
    end

    function ComponentMixin:AddCodeBlock(opts)
        local comp = CodeBlock.new({
            Parent   = self:GetParent(),
            Text     = opts.Text or opts.Code or "",
            MaxLines = opts.MaxLines,
            Theme    = self:GetTheme(),
        })
        table.insert(self:GetComponentList(), comp)
        return comp
    end

    function ComponentMixin:AddLeftGroupbox(name)
        -- Create a two-column row in the current page. The right column is stored
        -- as _pendingRightCol so the next AddRightGroupbox call can populate it.
        local row = Core.Util.Create("Frame", {
            Name = "ColumnRow",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = self:GetParent()
        })
        Core.Util.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            Parent = row
        })
        local leftCol = Core.Util.Create("Frame", {
            Name = "LeftCol",
            Size = UDim2.new(0.5, -3, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            Parent = row
        })
        self._pendingRightCol = Core.Util.Create("Frame", {
            Name = "RightCol",
            Size = UDim2.new(0.5, -3, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = 2,
            Parent = row
        })
        local section = Section.new({ Text = name, Theme = self:GetTheme(), Parent = leftCol })
        table.insert(self:GetComponentList(), section)
        return section
    end

    function ComponentMixin:AddRightGroupbox(name)
        local col = self._pendingRightCol
        self._pendingRightCol = nil
        if not col then
            return self:AddSection({ Text = name })
        end
        local section = Section.new({ Text = name, Theme = self:GetTheme(), Parent = col })
        table.insert(self:GetComponentList(), section)
        return section
    end

    local BaseComponent = {}
    BaseComponent.__index = BaseComponent
    function BaseComponent.new(props)
        local self = setmetatable({}, BaseComponent)
        self.Name = props.Name or "Component"
        self._theme = props.Theme or Theme or Core.Theme
        self._visible = true
        self._destroyed = false
        self._connections = {}
        
        if props.Tooltip then
            self._tooltip = props.Tooltip
        end
        
        return self
    end
    function BaseComponent:_track(conn)
        if not conn then return end
        if not self._connections then self._connections = {} end
        table.insert(self._connections, conn)
        return conn
    end
    
    function BaseComponent:_setupTooltip(element)
        if not self._tooltip then return end
        
        self:_track(element.MouseEnter:Connect(function()
            Core.Tooltip.Show(self._tooltip, element, self._theme)
        end))
        
        self:_track(element.MouseLeave:Connect(function()
            Core.Tooltip.Hide()
        end))
    end

    function BaseComponent:Destroy()
        if self._destroyed then return end
        self._destroyed = true

        -- Core.Connections.Track is never called from _track (which uses self._connections
        -- directly), so _registry never has entries for components. Removed no-op call.

        if self._connections then
            for _, c in ipairs(self._connections) do
                pcall(function() if c and c.Disconnect then c:Disconnect() end end)
            end
            self._connections = nil
        end
        
        if self._fx then 
            for _, effect in pairs(self._fx) do 
                if effect and effect.Destroy then
                    pcall(function() effect:Destroy() end)
                end
            end
            self._fx = nil
        end
        
        if self.Root then 
            self.Root:Destroy()
            self.Root = nil
        end
    end
    function BaseComponent:_fire(...)
        if self._enabled == false then return end
        if not self._callback then return end
        local ok, err = pcall(self._callback, ...)
        if not ok and Core.Debug then
            Core.Console.Warn("[SafeCallback] " .. tostring(err))
        end
    end
    function BaseComponent:SetVisible(visible)
        self._visible = visible
        if self.Root then self.Root.Visible = visible end
    end
    function BaseComponent:SetEnabled(enabled)
        self._enabled = (enabled ~= false)
        if not self.Root then return end
        if not self._enabled then
            if not self._disabledOverlay then
                local ov = Instance.new("Frame")
                ov.Name = "_DisabledOverlay"
                ov.Size = UDim2.fromScale(1, 1)
                ov.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                ov.BackgroundTransparency = 0.6
                ov.ZIndex = 999
                ov.BorderSizePixel = 0
                ov.Parent = self.Root
                self._disabledOverlay = ov
            end
            self._disabledOverlay.Visible = true
        else
            if self._disabledOverlay then
                self._disabledOverlay.Visible = false
            end
        end
    end
    function BaseComponent:IsEnabled()
        return self._enabled ~= false
    end
    function BaseComponent:RefreshTheme() end

    local Docking = {}
    Docking.__index = Docking
    
    function Docking.new(window)
        local self = setmetatable({}, Docking)
        self._window = window
        self._theme = window._theme
        self._parent = window.ScreenGui
        self._visible = false
        self._snapped = false
        self._width = Core.Layout.DockWidth
        self._threshold = 0.8
        self._connections = {}
        self._showTabsWithDock = false
        
        self:_createDock()
        self:_setupWindowConnections()
        self:_loadState()
        
        return self
    end
    
    function Docking:_createDock()
        local width = self._width
        local mainPos = self._window.Root.AbsolutePosition
        local mainSize = self._window.Root.AbsoluteSize
        -- Container sits flush against the left edge of the main window
        local initX = mainPos.X - width
        local initY = mainPos.Y

        -- Container: full width, ClipsDescendants hides the Dock during slide
        self.Container = Core.Util.Create("Frame", { Name = "DockContainer", Size = UDim2.fromOffset(width, mainSize.Y), Position = UDim2.fromOffset(initX, initY), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 100, Parent = self._parent })
        -- Dock starts tucked to the right (hidden); Show() slides it left into view
        self.Dock = Core.Util.Create("Frame", { Name = "Dock", Size = UDim2.new(1, 0, 1, 0), Position = UDim2.fromOffset(width, 0), BackgroundColor3 = self._theme.Background2, BorderSizePixel = 0, ZIndex = 1, Visible = false, Parent = self.Container })
        -- Right border connects the dock to the main window
        Core.Util.Create("Frame", { Name = "RightBorder", Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = self._theme.Border, BorderSizePixel = 0, Parent = self.Dock })

        local dockHeader = Core.Util.Create("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, Core.Layout.DockHeaderHeight), BackgroundColor3 = self._theme.Background, BorderSizePixel = 0, Parent = self.Dock })
        Core.Util.Create("TextLabel", { Name = "Title", Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, Text = "TABS", TextColor3 = self._theme.TextColor, Font = self._theme.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = dockHeader })

        self.SnapBtn = Core.Util.Create("TextButton", { Name = "SnapButton", Size = UDim2.fromOffset(48, 22), Position = UDim2.new(1, -54, 0.5, -11), BackgroundColor3 = self._theme.Background2, Text = "Snap", TextColor3 = self._theme.TextColor, Font = self._theme.Font, TextSize = 12, AutoButtonColor = true, Parent = dockHeader })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = self.SnapBtn })
        self.SnapBtn.InputBegan:Connect(function(input) if Core.Util.IsActivate(input.UserInputType) then self:SetSnapped(not self._snapped) end end)

        -- "Tabs" button: toggles whether the main window tab bar stays visible while the dock is open
        self.TabsBtn = Core.Util.Create("TextButton", { Name = "TabsButton", Size = UDim2.fromOffset(40, 22), Position = UDim2.new(1, -100, 0.5, -11), BackgroundColor3 = self._theme.Background2, Text = "Tabs", TextColor3 = self._theme.SubTextColor, Font = self._theme.Font, TextSize = 12, AutoButtonColor = true, Parent = dockHeader })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = self.TabsBtn })
        self.TabsBtn.InputBegan:Connect(function(input)
            if Core.Util.IsActivate(input.UserInputType) then
                self._showTabsWithDock = not self._showTabsWithDock
                self:_updateTabBarVisibility()
                self:UpdateTabsButton()
                self:_saveState()
            end
        end)

        self.Content = Core.Util.Create("ScrollingFrame", { Name = "Content", Size = UDim2.new(1, -8, 1, -(Core.Layout.DockHeaderHeight + 8)), Position = UDim2.fromOffset(4, Core.Layout.DockHeaderHeight + 4), BackgroundTransparency = 1, ScrollBarThickness = (self._theme.Scrollbar and self._theme.Scrollbar.Thickness) or 2, ScrollBarImageColor3 = (self._theme.Scrollbar and self._theme.Scrollbar.Color) or self._theme.Border, BorderSizePixel = 0, Parent = self.Dock })
        Core.Util.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = self.Content })
        Core.Util.Create("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 4), Parent = self.Content })

        self:_setupDrag(dockHeader)
        self._resizeGrip = Core.Behaviors.AddResizeGrip(self.Container, self._theme, Vector2.new(120, 120), Vector2.new(800, 900))
        self:UpdateSnapButton()
        self:UpdateTabsButton()
    end
    
    function Docking:_setupDrag(header)
        local dragging, dragStart, startPos
        header.InputBegan:Connect(function(input)
            if self._snapped then return end
            if Core.Util.IsActivate(input.UserInputType) then dragging = true; dragStart = Core.Util.GetInputPosition(input); startPos = self.Container.Position end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if self._snapped then return end
            if dragging and Core.Util.IsTouchMovement(input.UserInputType) then
                local delta = Core.Util.GetInputPosition(input) - dragStart
                self.Container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if dragging and Core.Util.IsActivate(input.UserInputType) then 
                dragging = false
            end
        end)
    end
    
    function Docking:UpdateButtons()
        if not self.Content then return end
        for _, child in ipairs(self.Content:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        for i, tab in ipairs(self._window._tabs) do
            local dockBtn = Core.Util.Create("TextButton", { Name = "DockTab_" .. tab.Name, Size = UDim2.new(1, -4, 0, Core.Layout.ButtonHeight), BackgroundColor3 = self._theme.Background, Text = tab.Name, TextColor3 = self._theme.TextColor, Font = self._theme.Font, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, LayoutOrder = i, Parent = self.Content })
            Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = dockBtn })
            Core.Util.Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2), Parent = dockBtn })
            dockBtn.InputBegan:Connect(function(input) if Core.Util.IsActivate(input.UserInputType) then self._window:SelectTab(tab.Name) end end)
            if self._window._currentTab and self._window._currentTab.Name == tab.Name then dockBtn.BackgroundColor3 = self._theme.Accent; dockBtn.TextColor3 = self._theme.TextColor end
        end
        self.Content.CanvasSize = UDim2.fromOffset(0, #self._window._tabs * 36)
    end
    
    function Docking:Toggle()
        self._visible = not self._visible
        if self._visible then self:Show() else self:Hide() end
        self:_saveState()
    end
    
    function Docking:Show()
        if not self.Container then return end
        if self._snapped then self:_repositionToWindow() end
        local w = math.max(self.Container.AbsoluteSize.X, self._width)
        -- Slide Dock in from the right (right → left)
        self.Dock.Position = UDim2.fromOffset(w, 0)
        self.Dock.Visible = true
        if self._resizeGrip and self._resizeGrip.Grip then self._resizeGrip.Grip.Visible = true end
        Core.Util.Tween(self.Dock, {Position = UDim2.fromOffset(0, 0)}, 0.25)
        self._visible = true
        self:_updateTabBarVisibility()
    end
    
    function Docking:Hide()
        if not self.Container then return end
        local w = math.max(self.Container.AbsoluteSize.X, self._width)
        -- Slide Dock out to the right (left → right)
        Core.Util.Tween(self.Dock, {Position = UDim2.fromOffset(w, 0)}, 0.25)
        self._visible = false
        if self._resizeGrip and self._resizeGrip.Grip then self._resizeGrip.Grip.Visible = false end
        task.delay(0.26, function()
            if self.Dock and not self._visible then self.Dock.Visible = false end
        end)
        self:_updateTabBarVisibility()
    end
    
    function Docking:SetSnapped(snapped)
        self._snapped = snapped
        self:UpdateSnapButton()
        if self._visible and self._snapped then self:_repositionToWindow() end
        self:_saveState()
    end
    
    function Docking:UpdateSnapButton()
        self.SnapBtn.Text = self._snapped and "UnSnap" or "Snap"
        self.SnapBtn.BackgroundColor3 = self._snapped and self._theme.Accent or self._theme.Background2
    end

    function Docking:UpdateTabsButton()
        if not self.TabsBtn then return end
        self.TabsBtn.BackgroundColor3 = self._showTabsWithDock and self._theme.Accent or self._theme.Background2
        self.TabsBtn.TextColor3 = self._showTabsWithDock and self._theme.TextColor or self._theme.SubTextColor
    end

    function Docking:_updateTabBarVisibility()
        local win = self._window
        if not win or not win.TabContainer then return end
        local shouldShow = not self._visible or self._showTabsWithDock
        if win.TabContainer.Visible ~= shouldShow then
            win.TabContainer.Visible = shouldShow
            win:_updateContentPosition()
        end
    end

    function Docking:_repositionToWindow()
        local winPos  = self._window.Root.AbsolutePosition
        local winSize = self._window.Root.AbsoluteSize
        self.Container.Position = UDim2.fromOffset(winPos.X - self._width, winPos.Y)
        self.Container.Size = UDim2.fromOffset(self._width, winSize.Y)
    end
    
    function Docking:_setupWindowConnections()
        self._window.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() 
            if self._snapped and self._visible then
                self:_repositionToWindow()
            end
        end)

        self._window.Root:GetPropertyChangedSignal("Position"):Connect(function()
            if self._snapped and self._visible then
                self:_repositionToWindow()
            end
        end)
    end
    
    function Docking:RefreshTheme()
        self._theme = self._window._theme
        if self.Dock then
            self.Dock.BackgroundColor3 = self._theme.Background2
            local header = self.Dock:FindFirstChild('Header')
            if header then header.BackgroundColor3 = self._theme.Background end
            local footer = self.Dock:FindFirstChild('Footer')
            if footer then footer.BackgroundColor3 = self._theme.Background end
            local rightBorder = self.Dock:FindFirstChild('RightBorder')
            if rightBorder then rightBorder.BackgroundColor3 = self._theme.Border end
            
            if self.Content then
                self.Content.ScrollBarImageColor3 = (self._theme.Scrollbar and self._theme.Scrollbar.Color) or self._theme.Border
                self.Content.ScrollBarThickness = (self._theme.Scrollbar and self._theme.Scrollbar.Thickness) or 2
                for _, btn in ipairs(self.Content:GetChildren()) do
                    if btn:IsA('TextButton') then
                        local isActive = (self._window._currentTab and self._window._currentTab.Name == btn.Text)
                        btn.BackgroundColor3 = isActive and self._theme.Accent or self._theme.Background
                        btn.TextColor3 = self._theme.TextColor
                    end
                end
            end
            
            if self.SnapBtn then
                self.SnapBtn.BackgroundColor3 = self._snapped and self._theme.Accent or self._theme.Background2
                self.SnapBtn.TextColor3 = self._theme.TextColor
            end
            if self.TabsBtn then
                self:UpdateTabsButton()
            end
        end
        
        if self._resizeGrip and self._resizeGrip.UpdateColors then
            self._resizeGrip:UpdateColors(self._theme)
        end
    end
    
    function Docking:_saveState()
        if type(writefile) ~= "function" or type(isfolder) ~= "function" then return end
        pcall(function()
            if not isfolder("dock") then makefolder("dock") end
            writefile("dock/state.json", HttpService:JSONEncode({
                visible = self._visible, snapped = self._snapped, width = self._width,
                showTabsWithDock = self._showTabsWithDock
            }))
        end)
    end
    
    function Docking:_loadState()
        if type(readfile) ~= "function" or type(isfile) ~= "function" then return end
        if not isfile("dock/state.json") then return end
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile("dock/state.json"))
        end)
        if ok and data then
            self._snapped = data.snapped or false
            self._width = data.width or 150
            self._showTabsWithDock = data.showTabsWithDock or false
            if data.visible then self:Show() else self:Hide() end
            self:UpdateSnapButton()
            self:UpdateTabsButton()
        end
    end

    local Window = setmetatable({}, {__index = BaseComponent})
    Window.__index = Window
    function Window.new(props)
        local self = BaseComponent.new({ Name = props.Name or "Window", Theme = props.Theme or Core.Theme })
        setmetatable(self, Window)
        self._components = {}
        self.Docking = nil
        
        self.ScreenGui = Core.Util.Create("ScreenGui", { Name = Core.Safety.RandomString(16), ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = Core.Safety.GetRoot() })
        self.ScreenGui:SetAttribute("__g", true)
        Core.Safety.ProtectInstance(self.ScreenGui)
        
        Core.Tooltip.Init(self.ScreenGui)
        
        local _isMobile = Core.Util.IsMobile()
        local _defW = _isMobile and 340 or 800
        local _defH = _isMobile and 480 or 500
        local _insetY = 0
        if _isMobile then
            local ok, inset = pcall(function() return GuiService:GetGuiInset() end)
            if ok and inset then _insetY = inset.Y end
        end
        self.Root = Core.Util.Create("Frame", { Name = "Window", Size = UDim2.fromOffset(props.Width or (props.Size and props.Size.X) or _defW, props.Height or (props.Size and props.Size.Y) or _defH), Position = UDim2.new(0.5, 0, 0.5, _insetY), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = self._theme.Window.Background, BorderSizePixel = 0, Parent = self.ScreenGui })
        Core.Util.Create("UIStroke", { Color = self._theme.Window.Border or self._theme.Border, Thickness = 1, Parent = self.Root })

        self:_createTitleBar(props.Title, props.SubTitle)
        self:_createContentArea()
        self._fx = {}
        if self._theme.EnableScanlines then self._fx.scanlines = Core.FX.CreateScanlines(self.Root, self._theme) end
        if self._theme.EnableTopSweep then self._fx.topsweep = Core.FX.CreateTopSweep(self.Root, self._theme) end
        if self._theme.EnableGridBG then self._fx.grid = Core.FX.CreateGrid(self.Root, self._theme) end
        
        self._resizeGrip = Core.Behaviors.AddResizeGrip(self.Root, self._theme, Vector2.new(300, 200))
        self._titleDrag = Core.Behaviors.MakeDraggable(self.TitleBar, self.Root)
        
        if Core.Debug then Core.Console.Debug("Window created:", props.Title or "Untitled", "Parent:", self.ScreenGui.Parent:GetFullName()) end
        return self
    end
    
    function Window:_createTitleBar(title, subtitle)
        self.TitleBar = Core.Util.Create("Frame", { Name = "TitleBar", Size = UDim2.new(1, 0, 0, Core.Layout.HeaderHeight), BackgroundColor3 = self._theme.Window.Background, Parent = self.Root })
        self.Title = Core.Util.Create("TextLabel", { Name = "Title", Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, Text = title or "Window", TextColor3 = self._theme.Window.TitleText, TextXAlignment = Enum.TextXAlignment.Left, Font = self._theme.Font, TextSize = 14, Parent = self.TitleBar })
        if subtitle then self.Subtitle = Core.Util.Create("TextLabel", { Name = "Subtitle", Size = UDim2.new(1, -62, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, Text = subtitle, TextColor3 = self._theme.Window.SubtitleText, TextXAlignment = Enum.TextXAlignment.Right, Font = self._theme.Font, TextSize = 14, Parent = self.TitleBar }) end
        
        self.DockIcon = Core.Util.Create("TextButton", { Name = "DockIcon", Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -26, 0.5, -10), BackgroundColor3 = Color3.new(), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "≡", TextColor3 = self._theme.Window and self._theme.Window.TitleText or self._theme.TextColor, TextScaled = false, TextSize = 16, Font = Enum.Font.SourceSans, Parent = self.TitleBar })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = self.DockIcon })
        
        self.DockIcon.InputBegan:Connect(function(input) if Core.Util.IsActivate(input.UserInputType) then self:ToggleDock() end end)
        self.DockIcon.MouseEnter:Connect(function() self.DockIcon.BackgroundColor3 = self._theme.Accent; self.DockIcon.BackgroundTransparency = 0.8 end)
        self.DockIcon.MouseLeave:Connect(function() if self.Docking and self.Docking._visible then self.DockIcon.BackgroundColor3 = self._theme.Accent; self.DockIcon.BackgroundTransparency = 0.2 else self.DockIcon.BackgroundColor3 = Color3.new(); self.DockIcon.BackgroundTransparency = 1 end end)

        self.MinimizeBtn = Core.Util.Create("TextButton", { Name = "MinimizeBtn", Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -50, 0.5, -10), BackgroundColor3 = Color3.new(), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "−", TextColor3 = self._theme.Window and self._theme.Window.TitleText or self._theme.TextColor, TextScaled = false, TextSize = 18, Font = Enum.Font.SourceSans, Parent = self.TitleBar })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = self.MinimizeBtn })
        self.MinimizeBtn.InputBegan:Connect(function(input) if Core.Util.IsActivate(input.UserInputType) then self:ToggleMinimize() end end)
        self.MinimizeBtn.MouseEnter:Connect(function() self.MinimizeBtn.BackgroundColor3 = self._theme.Background2; self.MinimizeBtn.BackgroundTransparency = 0.5 end)
        self.MinimizeBtn.MouseLeave:Connect(function() self.MinimizeBtn.BackgroundColor3 = Color3.new(); self.MinimizeBtn.BackgroundTransparency = 1 end)
    end
    
    function Window:_createContentArea()
        self.Content = Core.Util.Create("Frame", { Name = "Content", Size = UDim2.new(1, 0, 1, -Core.Layout.HeaderHeight), Position = UDim2.fromOffset(0, Core.Layout.HeaderHeight), BackgroundColor3 = self._theme.Background, Parent = self.Root })
    end
    function Window:AddTab(name, icon)
        if self._destroyed then return end
        if not self.TabContainer then
            self.TabContainer = Core.Util.Create("ScrollingFrame", { Name = "TabContainer", Size = UDim2.new(1, 0, 0, self._theme.Tab.PillHeight), Position = UDim2.fromOffset(0, Core.Layout.HeaderHeight), BackgroundColor3 = self._theme.Background, BackgroundTransparency = 0, BorderSizePixel = 0, ClipsDescendants = true, ScrollBarThickness = (self._theme.Scrollbar and self._theme.Scrollbar.Thickness) or 2, ScrollBarImageColor3 = (self._theme.Scrollbar and self._theme.Scrollbar.Color) or self._theme.Border, ScrollingDirection = Enum.ScrollingDirection.X, CanvasSize = UDim2.fromOffset(0, self._theme.Tab.PillHeight), Parent = self.Root })
            Core.Util.Create("UIStroke", { Color = self._theme.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = self.TabContainer })
            self.Content.Size = UDim2.new(1, 0, 1, -(Core.Layout.HeaderHeight + self._theme.Tab.PillHeight))
            self.Content.Position = UDim2.fromOffset(0, Core.Layout.HeaderHeight + self._theme.Tab.PillHeight)
            self.TabList = Core.Util.Create("Frame", { Name = "TabList", Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true, Parent = self.TabContainer })
            self.Pages = Core.Util.Create("Frame", { Name = "Pages", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, Parent = self.Content })
            self._tabCover = Core.Util.Create("Frame", { Name = "TabCover", Size = UDim2.fromScale(1, 1), BackgroundColor3 = self._theme.Background, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = Core.ZIndex.TabCover, Parent = self.Pages })
            self._tabs = {}
            self._currentTab = nil
            
            if not self.Docking then self.Docking = Docking.new(self) end
        end
        
        local tabButton = Core.Util.Create("TextButton", { Name = name, Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = self._theme.Tab.IdleFill, Text = self._theme.Tab.Uppercase and string.upper(name) or name, TextColor3 = self._theme.Tab.IdleText, Font = self._theme.Font, TextSize = 14, AutoButtonColor = false, Parent = self.TabList })
        if icon then
            Core.Util.Create("ImageLabel", { Name = "Icon", Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 8, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1, Image = icon, ImageColor3 = self._theme.Tab.IdleText, Parent = tabButton })
            tabButton.TextPadding = UDim2.fromOffset(Core.Layout.HeaderHeight, 0)
        end
        
        local textSize = TextService:GetTextSize(tabButton.Text, 14, self._theme.Font, Vector2.new(1000, 20))
        tabButton.Size = UDim2.new(0, textSize.X + 24, 1, 0)
        
        local page = Core.Util.Create("ScrollingFrame", { Name = name .. "Page", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = (self._theme.Scrollbar and self._theme.Scrollbar.Thickness) or 2, ScrollBarImageColor3 = (self._theme.Scrollbar and self._theme.Scrollbar.Color) or self._theme.Border, Visible = false, Parent = self.Pages })
        Core.Util.Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), Parent = page })
        local layout = Core.Util.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = page })
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 16) end)
        task.defer(function() page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 16) end)
        
        tabButton.InputBegan:Connect(function(input) if Core.Util.IsActivate(input.UserInputType) then self:SelectTab(name) end end)
        
        local tab = { Name = name, Button = tabButton, Page = page, Icon = icon, Window = self }

        -- Badge counter: call tab:SetBadge(n) to show a pill; tab:ClearBadge() to hide it
        local _badge = Core.Util.Create("TextLabel", {
            Name = "Badge", Size = UDim2.fromOffset(16, 16),
            Position = UDim2.new(1, -4, 0, 3), AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = self._theme.Accent, Text = "",
            TextColor3 = Color3.fromRGB(255, 255, 255), Font = self._theme.Font,
            TextSize = 10, Visible = false, ZIndex = Core.ZIndex.Badge, Parent = tabButton,
        })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = _badge })
        tab._badge = _badge

        function tab:SetBadge(count)
            if count and count > 0 then
                local s = count > 99 and "99+" or tostring(count)
                self._badge.Text = s
                local w = count > 99 and 28 or count > 9 and 20 or 16
                self._badge.Size = UDim2.fromOffset(w, 16)
                self._badge.Visible = true
            else
                self._badge.Visible = false
            end
        end
        function tab:ClearBadge()
            if self._badge then self._badge.Visible = false end
        end

        function tab:GetParent() return self.Page end
        function tab:GetTheme() return self.Window._theme end
        function tab:GetComponentList() return self.Window._components end
        
        for k, v in pairs(ComponentMixin) do tab[k] = v end

        table.insert(self._tabs, tab)
        
        local xOffset = 0
        for _, t in ipairs(self._tabs) do t.Button.Position = UDim2.fromOffset(xOffset, 0); xOffset = xOffset + t.Button.AbsoluteSize.X + 6 end
        self.TabList.Size = UDim2.new(0, math.max(xOffset, self.TabContainer.AbsoluteSize.X), 1, 0)
        self.TabContainer.CanvasSize = UDim2.fromOffset(xOffset, self._theme.Tab.PillHeight)
        
        if #self._tabs == 1 then self:SelectTab(name) end
        if self.Docking then self.Docking:UpdateButtons() end
        
        return tab
    end
    
    function Window:SelectTab(name)
        if self._destroyed then return end
        if not self._tabs then return end
        local tab
        for _, t in ipairs(self._tabs) do if t.Name == name then tab = t; break end end
        if not tab then return end
        
        if self._currentTab then
            local current = self._currentTab
            -- Brief flash-fade to smooth the page switch
            if self._tabCover then
                self._tabCover.BackgroundTransparency = 0.15
                TweenService:Create(self._tabCover, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
            end
            current.Button.BackgroundColor3 = self._theme.Tab.IdleFill
            current.Button.TextColor3 = self._theme.Tab.IdleText
            if current.Icon then current.Button.Icon.ImageColor3 = self._theme.Tab.IdleText end
            current.Page.Visible = false
            
            if current.Brackets then
                for _, bracket in pairs(current.Brackets) do
                    Core.Util.Tween(bracket, { BackgroundTransparency = 1 }, 0.2)
                end
            end
        end
        
        self._currentTab = tab
        tab.Button.BackgroundColor3 = self._theme.Tab.ActiveFill
        tab.Button.TextColor3 = self._theme.Tab.ActiveText
        if tab.Icon then tab.Button.Icon.ImageColor3 = self._theme.Tab.ActiveText end
        tab.Page.Visible = true
        
        if self._theme.EnableBrackets then
            if not tab.Brackets then
                tab.Brackets = {
                    TopLeft = Core.Util.Create("Frame", { Name = "TopLeft", Size = UDim2.fromOffset(4, 4), Position = UDim2.fromOffset(-1, -1), BackgroundColor3 = self._theme.Window.CornerBrackets, BorderSizePixel = 0, Parent = tab.Button }),
                    TopRight = Core.Util.Create("Frame", { Name = "TopRight", Size = UDim2.fromOffset(4, 4), Position = UDim2.new(1, -3, 0, -1), BackgroundColor3 = self._theme.Window.CornerBrackets, BorderSizePixel = 0, Parent = tab.Button }),
                    BottomLeft = Core.Util.Create("Frame", { Name = "BottomLeft", Size = UDim2.fromOffset(4, 4), Position = UDim2.new(0, -1, 1, -3), BackgroundColor3 = self._theme.Window.CornerBrackets, BorderSizePixel = 0, Parent = tab.Button }),
                    BottomRight = Core.Util.Create("Frame", { Name = "BottomRight", Size = UDim2.fromOffset(4, 4), Position = UDim2.new(1, -3, 1, -3), BackgroundColor3 = self._theme.Window.CornerBrackets, BorderSizePixel = 0, Parent = tab.Button }),
                }
                for _, bracket in pairs(tab.Brackets) do Core.Util.Create("Frame", { Size = UDim2.fromOffset(2, 2), Position = UDim2.fromOffset(1, 1), BackgroundColor3 = self._theme.Tab.ActiveFill, BorderSizePixel = 0, Parent = bracket }) end
            end
            for _, bracket in pairs(tab.Brackets) do bracket.BackgroundTransparency = 1; Core.Util.Tween(bracket, { BackgroundTransparency = 0 }, 0.2) end
        end
        
        if self.Docking then self.Docking:UpdateButtons() end
    end
    
    function Window:ToggleDock()
        if self.Docking then self.Docking:Toggle() end
    end

    function Window:Minimize()
        if self._minimized then return end
        self._minimized  = true
        self._savedHeight = self.Root.AbsoluteSize.Y
        if self.Content      then self.Content.Visible = false end
        if self.TabContainer then self.TabContainer.Visible = false end
        Core.Util.Tween(self.Root, { Size = UDim2.fromOffset(self.Root.AbsoluteSize.X, Core.Layout.HeaderHeight) }, 0.2)
        if self.MinimizeBtn then self.MinimizeBtn.Text = "□" end
    end

    function Window:Restore()
        if not self._minimized then return end
        self._minimized = false
        local h = self._savedHeight or 500
        Core.Util.Tween(self.Root, { Size = UDim2.fromOffset(self.Root.AbsoluteSize.X, h) }, 0.2)
        task.delay(0.05, function()
            if self.Content then self.Content.Visible = true end
            if self.TabContainer and self._tabs and #self._tabs > 0 then self.TabContainer.Visible = true end
        end)
        if self.MinimizeBtn then self.MinimizeBtn.Text = "−" end
    end

    function Window:ToggleMinimize()
        if self._minimized then self:Restore() else self:Minimize() end
    end

    function Window:_updateContentPosition()
        if not self.Content then return end
        local topOffset = self.TabContainer and self.TabContainer.Visible and (Core.Layout.HeaderHeight + (self._theme.Tab.PillHeight or Core.Layout.TabPillHeight)) or Core.Layout.HeaderHeight
        self.Content.Position = UDim2.fromOffset(0, topOffset)
        self.Content.Size = UDim2.new(1, 0, 1, -topOffset)
    end
    
    function Window:RefreshTheme()
        if self._destroyed then return end

        local theme = self._theme or {}
        local thW = theme.Window or {}
        local thT = theme.Tab or {}
        local scrollbar = theme.Scrollbar or {}
        local bg = theme.Background
        local bg2 = theme.Background2
        local text = theme.TextColor
        local _subText = theme.SubTextColor
        local accent = theme.Accent
        local border = theme.Border

        local function safeColor(color, fallback)
            return (color and typeof(color) == 'Color3') and color or (fallback or Color3.fromRGB(100,100,255))
        end

        self.Root.BackgroundColor3 = safeColor(thW.Background, bg)
        self.TitleBar.BackgroundColor3 = safeColor(thW.Background, bg)
        self.Title.TextColor3 = safeColor(thW.TitleText, text)
        self.Content.BackgroundColor3 = safeColor(bg, Color3.fromRGB(25,25,25))

        local windowStroke = self.Root:FindFirstChildOfClass("UIStroke")
        if windowStroke then windowStroke.Color = border end

        if self.TabContainer then
            self.TabContainer.BackgroundColor3 = safeColor(bg, Color3.fromRGB(25,25,25))
            if self.TabContainer:IsA('ScrollingFrame') then
                self.TabContainer.ScrollBarImageColor3 = scrollbar.Color or border
                self.TabContainer.ScrollBarThickness = scrollbar.Thickness or self.TabContainer.ScrollBarThickness
            end
            
            local tabStroke = self.TabContainer:FindFirstChildOfClass("UIStroke")
            if tabStroke then tabStroke.Color = border end

            if self._tabs then
                local idleFill = thT.IdleFill
                local activeFill = thT.ActiveFill
                local idleText = thT.IdleText
                local activeText = thT.ActiveText
                for _, t in ipairs(self._tabs) do
                    local active = (self._currentTab and self._currentTab.Name == t.Name)
                    t.Button.BackgroundColor3 = safeColor(active and activeFill or idleFill, bg2)
                    t.Button.TextColor3 = safeColor(active and activeText or idleText, text)
                    if t.Icon then
                        t.Button.Icon.ImageColor3 = safeColor(active and activeText or idleText, text)
                    end
                    if t.Brackets then
                        for _, b in pairs(t.Brackets) do
                            b.BackgroundColor3 = safeColor(thW.CornerBrackets, border)
                            local inner = b:FindFirstChildOfClass('Frame')
                            if inner then inner.BackgroundColor3 = safeColor(thT.ActiveFill, bg) end
                        end
                    end
                    if t._badge then
                        t._badge.BackgroundColor3 = safeColor(accent, Color3.fromRGB(100, 100, 255))
                        t._badge.Font = self._theme.Font
                    end
                end
            end
        end

        if self.Pages then
            local sbCol = scrollbar.Color or border
            local sbTh = scrollbar.Thickness
            for _, child in ipairs(self.Pages:GetChildren()) do
                if child:IsA('ScrollingFrame') then
                    child.ScrollBarImageColor3 = sbCol
                    child.ScrollBarThickness = sbTh or child.ScrollBarThickness
                end
            end
        end

        if self.Docking then
            self.Docking:RefreshTheme()
        end

        if self.DockIcon then
            self.DockIcon.TextColor3 = safeColor(thW.TitleText, text)
            if self.Docking and self.Docking._visible then
                self.DockIcon.BackgroundColor3 = safeColor(accent, Color3.fromRGB(100,100,255))
                self.DockIcon.BackgroundTransparency = 0.2
            else
                self.DockIcon.BackgroundColor3 = Color3.new()
                self.DockIcon.BackgroundTransparency = 1
            end
        end

        if self.MinimizeBtn then
            self.MinimizeBtn.TextColor3 = safeColor(thW.TitleText, text)
        end

        if self._resizeGrip and self._resizeGrip.UpdateColors then
            if Core.Debug then
                Core.Console.Debug('Updating resize grip colors with theme:', accent)
            end
            self._resizeGrip:UpdateColors(self._theme)
        elseif Core.Debug then
            Core.Console.Debug('Resize grip not found or no UpdateColors function')
        end
        
        if self._fx then
            if self._fx.scanlines then
                self._fx.scanlines.Destroy()
                self._fx.scanlines = nil
            end
            if theme.EnableScanlines then
                self._fx.scanlines = Core.FX.CreateScanlines(self.Root, theme)
            end

            if self._fx.topsweep then
                self._fx.topsweep.Destroy()
                self._fx.topsweep = nil
            end
            if theme.EnableTopSweep then
                self._fx.topsweep = Core.FX.CreateTopSweep(self.Root, theme)
            end

            if self._fx.grid then
                self._fx.grid.Destroy()
                self._fx.grid = nil
            end
            if theme.EnableGridBG then
                self._fx.grid = Core.FX.CreateGrid(self.Root, theme)
            end

            if self._fx.brackets then
                self._fx.brackets.Destroy()
                self._fx.brackets = nil
            end
            if theme.EnableBrackets then
                self._fx.brackets = Core.FX.CreateCornerBrackets(self.Root, theme)
            end
        end

        if self._components then
            for _, component in ipairs(self._components) do
                if component.RefreshTheme then
                    component._theme = self._theme
                    component:RefreshTheme()
                end
            end
        end
        
        if KeybindListController then
            KeybindListController:RefreshTheme()
        end
    end
    function Window:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        
        Core.Connections.DisconnectAll(self)
        
        if self._scaleConnections then
            for _, connection in ipairs(self._scaleConnections) do
                pcall(function() connection:Disconnect() end)
            end
            self._scaleConnections = nil
        end

        if self._dockFollowConnections then
            for _, connection in ipairs(self._dockFollowConnections) do
                pcall(function() connection:Disconnect() end)
            end
            self._dockFollowConnections = nil
        end
        
        if self._resizeGrip then
            pcall(function() self._resizeGrip.Destroy() end)
            self._resizeGrip = nil
        end

        if self._dockResizeGrip then
            pcall(function() self._dockResizeGrip.Destroy() end)
            self._dockResizeGrip = nil
        end

        if self._titleDrag and self._titleDrag.Destroy then
            pcall(function() self._titleDrag:Destroy() end)
            self._titleDrag = nil
        end

        if self._dockDragConnections then
            for _, c in ipairs(self._dockDragConnections) do pcall(function() c:Disconnect() end) end
            self._dockDragConnections = nil
        end
        
        if self._fx then 
            for _, effect in pairs(self._fx) do 
                if effect and effect.Destroy then
                    pcall(function() effect.Destroy() end)
                end
            end 
            self._fx = nil
        end
        
        if self._components then
            for _, component in ipairs(self._components) do
                if component and component.Destroy and not component._destroyed then
                    pcall(function() component:Destroy() end)
                end
            end
            self._components = nil
        end
        
        if self.ScreenGui then 
            self.ScreenGui:Destroy()
            self.ScreenGui = nil
        end
        
        if Core.Debug then
            Core.Console.Debug("Window destroyed successfully")
        end
    end

    -- Label
    Label = setmetatable({}, {__index = BaseComponent})
    Label.__index = Label
    function Label.new(props)
        local self = BaseComponent.new(props)
        setmetatable(self, Label)
        
        self.Root = Core.Util.Create("Frame", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = props.Parent
        })
        
        self.TextLabel = Core.Util.Create("TextLabel", {
            Name = "Text",
            Size = UDim2.new(1, -10, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.fromOffset(10, 0),
            BackgroundTransparency = 1,
            Text = props.Text or "Label",
            TextColor3 = self._theme.TextColor,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = self._theme.Font,
            TextSize = 14,
            TextWrapped = true,
            Parent = self.Root
        })
        
        self:_setupTooltip(self.Root)
        return self
    end
    
    function Label:SetText(text)
        self.TextLabel.Text = text
    end
    
    function Label:GetText()
        return self.TextLabel.Text
    end
    
    function Label:RefreshTheme()
        if self._destroyed then return end
        self.TextLabel.TextColor3 = self._theme.TextColor
        self.TextLabel.Font = self._theme.Font
    end

    -- Button
    Button = setmetatable({}, {__index = BaseComponent})
    Button.__index = Button
    function Button.new(props)
        local valid, err = Core.Util.ValidateProps(props, {
            Text = { Type = "string", Required = false },
            Callback = { Type = "function", Required = false }
        })
        if not valid then warn("Button Validation Error: " .. err) end

        local self = BaseComponent.new({ Name = "Button", Theme = props.Theme or Theme, Tooltip = props.Tooltip })
        setmetatable(self, Button)
        self._idleColor  = self._theme.Background2
        self._hoverColor = self._theme.Accent
        self._variant    = "default"
        self.Root = Core.Util.Create("TextButton", { Name = "Button", Size = UDim2.new(1, 0, 0, Core.Layout.ButtonHeight), BackgroundColor3 = self._theme.Background2, Text = props.Text or "Button", TextColor3 = self._theme.TextColor, Font = self._theme.Font, TextSize = 14, BorderSizePixel = 0, Parent = props.Parent })
        
        -- Add UIStroke
        Core.Util.Create("UIStroke", {
            Color = self._theme.Border,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = self.Root
        })

        self:_setupInteractions()
        self._callback = props.Callback and Core.Util.Throttle(props.Callback, 0.2)
        
        -- Apply FX if provided
        if props.FX then
            self._fx = Core.FX.Apply(self.Root, props.FX, self._theme)
        end
        
        self:_setupTooltip(self.Root)
        return self
    end
    function Button:_setupInteractions()
        self.Root.MouseEnter:Connect(function()
            Core.Util.Tween(self.Root, { BackgroundColor3 = self._hoverColor }, 0.2)
        end)
        self.Root.MouseLeave:Connect(function()
            Core.Util.Tween(self.Root, { BackgroundColor3 = self._idleColor }, 0.2)
        end)
        self.Root.InputBegan:Connect(function(input)
            if Core.Util.IsActivate(input.UserInputType) then
                self:_fire()
            end
        end)
    end
    function Button:SetText(text) self.Root.Text = text end
    function Button:SetVariant(variant)
        self._variant = variant or "default"
        local bt = self._theme.Button or {}
        if self._variant == "danger" then
            self._idleColor   = bt.DangerIdle  or Color3.fromRGB(163, 48,  37)
            self._hoverColor  = bt.DangerHover or Color3.fromRGB(192, 57,  43)
            self._variantText = bt.DangerText  or Color3.fromRGB(255, 240, 240)
        elseif self._variant == "success" then
            self._idleColor   = bt.SuccessIdle  or Color3.fromRGB(34,  139, 73)
            self._hoverColor  = bt.SuccessHover or Color3.fromRGB(39,  174, 96)
            self._variantText = bt.SuccessText  or Color3.fromRGB(230, 255, 240)
        elseif self._variant == "warning" then
            self._idleColor   = bt.WarningIdle  or Color3.fromRGB(184, 100, 26)
            self._hoverColor  = bt.WarningHover or Color3.fromRGB(230, 126, 34)
            self._variantText = bt.WarningText  or Color3.fromRGB(255, 245, 210)
        else
            self._idleColor   = self._theme.Background2
            self._hoverColor  = self._theme.Accent
            self._variantText = nil
        end
        self.Root.BackgroundColor3 = self._idleColor
        self.Root.TextColor3 = self._variantText or self._theme.TextColor
    end
    function Button:RefreshTheme()
        if self._destroyed then return end
        self:SetVariant(self._variant)
        local stroke = self.Root:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = self._theme.Border end
    end

    -- Toggle
    Toggle = setmetatable({}, {__index = BaseComponent})
    Toggle.__index = Toggle
    function Toggle.new(props)
        local valid, err = Core.Util.ValidateProps(props, {
            Text = { Type = "string", Required = false },
            Value = { Type = "boolean", Required = false },
            Callback = { Type = "function", Required = false }
        })
        if not valid then warn("Toggle Validation Error: " .. err) end

        local self = BaseComponent.new({ Name = "Toggle", Theme = props.Theme or Theme, Tooltip = props.Tooltip })
        setmetatable(self, Toggle)
        self.Root = Core.Util.Create("Frame", { Name = "Toggle", Size = UDim2.new(1, 0, 0, Core.Layout.ComponentHeight), BackgroundTransparency = 1, Parent = props.Parent })
        self:_createLabel(props.Text)
        self:_createIndicator()
        self._value = props.Value or false
        self._callback = props.Callback and Core.Util.Throttle(props.Callback, 0.2)
        self:SetValue(self._value, false)
        self:_setupTooltip(self.Root)
        return self
    end
    function Toggle:_createLabel(text)
        self.Label = Core.Util.Create("TextLabel", { Name = "Label", Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1, Text = text or "Toggle", TextColor3 = self._theme.TextColor, TextXAlignment = Enum.TextXAlignment.Left, Font = self._theme.Font, TextSize = 14, Parent = self.Root })
    end
    function Toggle:_createIndicator()
        self.Indicator = Core.Util.Create("Frame", { Name = "Indicator", Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -40, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = self._theme.Background2, BorderSizePixel = 0, Parent = self.Root })
        
        -- Add UIStroke
        Core.Util.Create("UIStroke", {
            Color = self._theme.Border,
            Thickness = 1,
            Parent = self.Indicator
        })

        self.Knob = Core.Util.Create("Frame", { Name = "Knob", Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 2, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = self._theme.TextColor, Parent = self.Indicator })
        self.Indicator.InputBegan:Connect(function(input)
            if Core.Util.IsActivate(input.UserInputType) then self:SetValue(not self._value) end
        end)
    end
    function Toggle:SetValue(value, animate, ignoreCallback)
        self._value = value
        local knobPosition = value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        local indicatorColor = value and self._theme.Accent or self._theme.Background2
        if animate ~= false then
            Core.Util.Tween(self.Knob, { Position = knobPosition }, 0.2)
            Core.Util.Tween(self.Indicator, { BackgroundColor3 = indicatorColor }, 0.2)
        else
            self.Knob.Position = knobPosition
            self.Indicator.BackgroundColor3 = indicatorColor
        end
        if not ignoreCallback then self:_fire(value) end
        -- Notify any registered dependency listeners
        if self._listeners then
            for _, fn in ipairs(self._listeners) do
                pcall(fn, value)
            end
        end
    end
    function Toggle:GetValue() return self._value end
    -- Register a change listener (used by DependencyBox). Does not replace Callback.
    function Toggle:OnChanged(fn)
        if not self._listeners then self._listeners = {} end
        table.insert(self._listeners, fn)
    end
    function Toggle:RefreshTheme()
        if self._destroyed then return end
        self.Label.TextColor3 = self._theme.TextColor
        self.Knob.BackgroundColor3 = self._theme.TextColor
        
        -- Update border stroke
        local stroke = self.Indicator:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = self._theme.Border end

        self:SetValue(self._value, false, true)
    end

    -- Slider
    Slider = setmetatable({}, {__index = BaseComponent})
    Slider.__index = Slider
    function Slider.new(props)
        local valid, err = Core.Util.ValidateProps(props, {
            Text = { Type = "string", Required = false },
            Min = { Type = "number", Required = false },
            Max = { Type = "number", Required = false },
            Step = { Type = "number", Required = false },
            Value = { Type = "number", Required = false },
            Callback = { Type = "function", Required = false }
        })
        if not valid then warn("Slider Validation Error: " .. err) end

        local self = BaseComponent.new({ Name = "Slider", Theme = props.Theme or Theme, Tooltip = props.Tooltip })
        setmetatable(self, Slider)
        self.Root = Core.Util.Create("Frame", { Name = "Slider", Size = UDim2.new(1, 0, 0, Core.Layout.SliderHeight), BackgroundTransparency = 1, Parent = props.Parent })
        self:_createLabel(props.Text)
        self:_createTrack()
        self:_createValue()
        self._min = props.Min or 0
        self._max = props.Max or 100
        self._step = props.Step or 1
        self._callback = props.Callback and Core.Util.Throttle(props.Callback, 0.05)
        self._dragging = false
        self:SetValue(props.Value or self._min, false)
        self:_setupTooltip(self.Root)
        return self
    end
    function Slider:_createLabel(text)
        self.Label = Core.Util.Create("TextLabel", { Name = "Label", Size = UDim2.new(1, -50, 0, 20), BackgroundTransparency = 1, Text = text or "Slider", TextColor3 = self._theme.TextColor, TextXAlignment = Enum.TextXAlignment.Left, Font = self._theme.Font, TextSize = 14, Parent = self.Root })
    end
    function Slider:_createTrack()
        self.Track = Core.Util.Create("Frame", { Name = "Track", Size = UDim2.new(1, -50, 0, 4), Position = UDim2.new(0, 0, 0, 28), BackgroundColor3 = self._theme.Background2, BorderSizePixel = 0, Parent = self.Root })
        
        -- Add UIStroke
        Core.Util.Create("UIStroke", {
            Color = self._theme.Border,
            Thickness = 1,
            Parent = self.Track
        })

        self.Fill = Core.Util.Create("Frame", { Name = "Fill", Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = self._theme.Accent, Parent = self.Track })
        self.Knob = Core.Util.Create("Frame", { Name = "Knob", Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = self._theme.TextColor, Parent = self.Track })
        local function update(input)
            local trackPos = self.Track.AbsolutePosition.X
            local trackWidth = self.Track.AbsoluteSize.X
            local mousePos = Core.Util.GetInputPosition(input).X
            local pos = math.clamp(mousePos - trackPos, 0, trackWidth)
            local percentage = pos / trackWidth
            local value = self._min + (self._max - self._min) * percentage
            value = math.floor(value / self._step) * self._step
            self:SetValue(value)
        end
        self.Track.InputBegan:Connect(function(input)
            if Core.Util.IsActivate(input.UserInputType) then
                self._dragging = true
                update(input)
                
                local inputChanged, inputEnded
                
                inputChanged = UserInputService.InputChanged:Connect(function(input)
                    if Core.Util.IsTouchMovement(input.UserInputType) and self._dragging then 
                        update(input) 
                    end
                end)
                
                inputEnded = UserInputService.InputEnded:Connect(function(input)
                    if Core.Util.IsActivate(input.UserInputType) then 
                        self._dragging = false
                        inputChanged:Disconnect()
                        inputEnded:Disconnect()
                    end
                end)
            end
        end)
    end
    function Slider:_createValue()
        self.Value = Core.Util.Create("TextLabel", { Name = "Value", Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -40, 0, 0), BackgroundTransparency = 1, Text = tostring(self._min), TextColor3 = self._theme.TextColor, TextXAlignment = Enum.TextXAlignment.Right, Font = self._theme.Font, TextSize = 14, Parent = self.Root })
    end
    function Slider:SetValue(value, animate, ignoreCallback)
        value = math.clamp(value, self._min, self._max)
        self._value = value
        local percentage = (value - self._min) / (self._max - self._min)
        if animate ~= false then
            Core.Util.Tween(self.Fill, { Size = UDim2.new(percentage, 0, 1, 0) }, 0.2)
            Core.Util.Tween(self.Knob, { Position = UDim2.new(percentage, 0, 0.5, 0) }, 0.2)
        else
            self.Fill.Size = UDim2.new(percentage, 0, 1, 0)
            self.Knob.Position = UDim2.new(percentage, 0, 0.5, 0)
        end
        self.Value.Text = tostring(math.floor(value))
        if not ignoreCallback then self:_fire(value) end
    end
    function Slider:GetValue() return self._value end
    function Slider:RefreshTheme()
        if self._destroyed then return end
        self.Label.TextColor3 = self._theme.TextColor
        self.Value.TextColor3 = self._theme.TextColor
        self.Track.BackgroundColor3 = self._theme.Background2
        self.Fill.BackgroundColor3 = self._theme.Accent
        self.Knob.BackgroundColor3 = self._theme.TextColor
        
        -- Update border stroke
        local stroke = self.Track:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = self._theme.Border end
        
        self:SetValue(self._value, false, true)
    end

    function Slider:Destroy()
        if self._destroyed then return end
        BaseComponent.Destroy(self)
    end

    -- TextInput
    TextInput = setmetatable({}, {__index = BaseComponent})
    TextInput.__index = TextInput
    function TextInput.new(props)
        local valid, err = Core.Util.ValidateProps(props, {
            Text = { Type = "string", Required = false },
            Placeholder = { Type = "string", Required = false },
            Callback = { Type = "function", Required = false }
        })
        if not valid then warn("TextInput Validation Error: " .. err) end

        local self = BaseComponent.new({ Name = "TextInput", Theme = props.Theme or Theme, Tooltip = props.Tooltip })
        setmetatable(self, TextInput)
        self.Root = Core.Util.Create("Frame", { Name = "TextInput", Size = UDim2.new(1, 0, 0, Core.Layout.ComponentHeight), BackgroundColor3 = self._theme.Background2, BorderSizePixel = 0, Parent = props.Parent })
        
        -- Add UIStroke
        Core.Util.Create("UIStroke", {
            Color = self._theme.Border,
            Thickness = 1,
            Parent = self.Root
        })

        self:_createTextBox(props)
        self._callback = props.Callback
        self._placeholder = props.Placeholder
        self:_setupTooltip(self.Root)
        return self
    end
    function TextInput:_createTextBox(props)
        self.TextBox = Core.Util.Create("TextBox", { Name = "TextBox", Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, Text = props.Text or "", PlaceholderText = props.Placeholder or "Type here...", TextColor3 = self._theme.TextColor, PlaceholderColor3 = self._theme.DisabledText, Font = self._theme.Font, TextSize = 14, ClearTextOnFocus = false, Parent = self.Root })
        
        if Core.Clipboard.IsAvailable() then
            local rightClickConnection = self.TextBox.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                    local clipboardText = Core.Clipboard.Get()
                    if clipboardText then
                        self.TextBox.Text = clipboardText
                        if Core.Debug then
                            Core.Console.Debug("Pasted from clipboard to TextInput")
                        end
                    end
                end
            end)
            Core.Connections.Track(self, rightClickConnection)
            
            local keyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed or not self.TextBox:IsFocused() then return end
                
                if input.KeyCode == Enum.KeyCode.C and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    Core.Clipboard.Set(self.TextBox.Text)
                elseif input.KeyCode == Enum.KeyCode.V and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    local clipboardText = Core.Clipboard.Get()
                    if clipboardText then
                        self.TextBox.Text = clipboardText
                    end
                end
            end)
            Core.Connections.Track(self, keyConnection)
        end
        
        Core.Connections.Track(self, self.TextBox.Focused:Connect(function() 
            Core.Util.Tween(self.Root, { BackgroundColor3 = self._theme.Accent }, 0.2) 
        end))
        
        Core.Connections.Track(self, self.TextBox.FocusLost:Connect(function(enterPressed)
            Core.Util.Tween(self.Root, { BackgroundColor3 = self._theme.Background2 }, 0.2)
            self:_fire(self.TextBox.Text, enterPressed)
        end))
        -- On mobile the system keyboard covers the lower portion of the screen.
        -- Nudge the containing window frame up when this TextBox is focused, restore on release.
        if Core.Util.IsMobile() then
            local function findWindowRoot(inst)
                local cur = inst
                while cur and cur.Parent do
                    if cur.Parent:IsA("ScreenGui") then return cur end
                    cur = cur.Parent
                end
                return nil
            end
            local origOffsetY = nil
            Core.Connections.Track(self, UserInputService.TextBoxFocused:Connect(function(textBox)
                if textBox ~= self.TextBox then return end
                local root = findWindowRoot(self.Root)
                if not root then return end
                origOffsetY = root.Position.Y.Offset
                root.Position = UDim2.new(root.Position.X.Scale, root.Position.X.Offset, root.Position.Y.Scale, origOffsetY - 150)
            end))
            Core.Connections.Track(self, UserInputService.TextBoxFocusReleased:Connect(function(textBox)
                if textBox ~= self.TextBox then return end
                if origOffsetY == nil then return end
                local root = findWindowRoot(self.Root)
                if not root then return end
                root.Position = UDim2.new(root.Position.X.Scale, root.Position.X.Offset, root.Position.Y.Scale, origOffsetY)
                origOffsetY = nil
            end))
        end
    end
    function TextInput:SetText(text) self.TextBox.Text = text or "" end
    function TextInput:GetText() return self.TextBox.Text end
    function TextInput:RefreshTheme()
        if self._destroyed then return end
        self.Root.BackgroundColor3 = self._theme.Background2
        self.TextBox.TextColor3 = self._theme.TextColor
        self.TextBox.PlaceholderColor3 = self._theme.DisabledText
        
        -- Update border stroke
        local stroke = self.Root:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = self._theme.Border end
    end

    -- BaseDropdown
    local BaseDropdown = setmetatable({}, {__index = BaseComponent})
    BaseDropdown.__index = BaseDropdown
    function BaseDropdown.new(props)
        local self = BaseComponent.new({ Name = props.Name or "Dropdown", Theme = props.Theme, Tooltip = props.Tooltip })
        setmetatable(self, BaseDropdown)
        self.Root = Core.Util.Create("Frame", { Name = self.Name, Size = UDim2.new(1, 0, 0, Core.Layout.ComponentHeight), BackgroundColor3 = self._theme.Background2, BorderSizePixel = 0, Parent = props.Parent })
        Core.Util.Create("UIStroke", { Color = self._theme.Border, Thickness = 1, Parent = self.Root })
        
        self._parent = props.Parent
        self:_createHeader(props.Text)
        self:_createList()
        self._options = props.Options or {}
        self._callback = props.Callback
        self._open = false
        self:_setupTooltip(self.Root)
        return self
    end
    
    function BaseDropdown:_createHeader(text)
        self.Header = Core.Util.Create("TextLabel", { Name = "Header", Size = UDim2.new(1, -Core.Layout.ComponentHeight, 1, 0), BackgroundTransparency = 1, Text = text or "Dropdown", TextColor3 = self._theme.TextColor, TextXAlignment = Enum.TextXAlignment.Left, Font = self._theme.Font, TextSize = 14, ClipsDescendants = true, Parent = self.Root })
        self.Arrow = Core.Util.Create("TextLabel", { Name = "Arrow", Size = UDim2.fromOffset(Core.Layout.ComponentHeight, Core.Layout.ComponentHeight), Position = UDim2.new(1, -Core.Layout.ComponentHeight, 0, 0), BackgroundTransparency = 1, Text = "▼", TextColor3 = self._theme.TextColor, Font = self._theme.Font, TextSize = 14, Parent = self.Root })
        self.Root.InputBegan:Connect(function(input) if Core.Util.IsActivate(input.UserInputType) then self:Toggle() end end)
    end
    
    function BaseDropdown:_createList()
        self.List = Core.Util.Create("Frame", { Name = "List", Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 0), BackgroundColor3 = self._theme.Background2, ClipsDescendants = true, BorderSizePixel = 0, Parent = self.Root })
        Core.Util.Create("UIStroke", { Color = self._theme.Border, Thickness = 1, Parent = self.List })
        
        self.Options = Core.Util.Create("ScrollingFrame", { Name = "Options", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(1, 0, 0, 0), ScrollBarThickness = (self._theme.Scrollbar and self._theme.Scrollbar.Thickness) or 4, ScrollBarImageColor3 = (self._theme.Scrollbar and self._theme.Scrollbar.Color) or self._theme.Accent, Parent = self.List })
        Core.Util.Create("UIStroke", { Color = self._theme.Border, Thickness = 1, Parent = self.Options })
        Core.Util.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.Options })
    end
    
    function BaseDropdown:Toggle(state)
        local oldOpen = self._open
        if state ~= nil then self._open = state else self._open = not self._open end
        if self._open == oldOpen then return end

        local numOptions = #self._options
        local maxHeight  = math.min(numOptions * Core.Layout.ComponentHeight, Core.Layout.ComponentHeight * 5)
        Core.Util.Tween(self.Arrow, { Rotation = self._open and 180 or 0 }, 0.2)

        if self._open then
            self.Root.ZIndex = Core.ZIndex.Dropdown
            -- Boost every GuiObject ancestor up to (not including) the page ScrollingFrame.
            -- This fixes both cross-section overlap (ColumnRow vs Section below) and
            -- cross-column overlap (LeftCol vs RightCol, where RightCol wins by DOM order).
            self._boostedAncestors = {}
            local cur = self.Root.Parent
            while cur do
                if cur:IsA("ScrollingFrame") then break end
                if cur:IsA("GuiObject") then
                    table.insert(self._boostedAncestors, { inst = cur, prev = cur.ZIndex })
                    cur.ZIndex = Core.ZIndex.Dropdown
                end
                cur = cur.Parent
            end
            Core.Util.Tween(self.List, { Size = UDim2.new(1, 0, 0, maxHeight) }, 0.2)
        else
            Core.Util.Tween(self.List, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
            task.delay(0.21, function()
                if not self._open and not self._destroyed then
                    self.Root.ZIndex = 1
                    if self._boostedAncestors then
                        for _, entry in ipairs(self._boostedAncestors) do
                            entry.inst.ZIndex = entry.prev
                        end
                        self._boostedAncestors = nil
                    end
                end
            end)
        end
    end
    
    function BaseDropdown:RefreshTheme()
        if self._destroyed then return end
        self.Root.BackgroundColor3 = self._theme.Background2
        self.Header.TextColor3 = self._theme.TextColor
        self.Arrow.TextColor3 = self._theme.TextColor
        self.List.BackgroundColor3 = self._theme.Background2
        self.Options.ScrollBarImageColor3 = (self._theme.Scrollbar and self._theme.Scrollbar.Color) or self._theme.Accent
        
        local stroke = self.Root:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = self._theme.Border end
        local listStroke = self.List:FindFirstChildOfClass("UIStroke")
        if listStroke then listStroke.Color = self._theme.Border end
        local optionsStroke = self.Options:FindFirstChildOfClass("UIStroke")
        if optionsStroke then optionsStroke.Color = self._theme.Border end

        -- Update options
        for _, child in ipairs(self.Options:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = self._theme.Background2
                child.TextColor3 = self._theme.TextColor
                child.Font = self._theme.Font
            end
        end
    end

    function BaseDropdown:Destroy()
        if self._destroyed then return end
        BaseComponent.Destroy(self)
    end

    -- Dropdown
    Dropdown = setmetatable({}, {__index = BaseDropdown})
    Dropdown.__index = Dropdown
    function Dropdown.new(props)
        local valid, err = Core.Util.ValidateProps(props, {
            Text = { Type = "string", Required = false },
            Options = { Type = "table", Required = false },
            Value = { Type = "string", Required = false },
            Default = { Type = "string", Required = false },
            Callback = { Type = "function", Required = false }
        })
        if not valid then warn("Dropdown Validation Error: " .. err) end

        local self = BaseDropdown.new(props)
        setmetatable(self, Dropdown)
        
        local initialValue = props.Value or props.Default
        if initialValue and table.find(self._options, initialValue) then 
            self:SetValue(initialValue, false, true) 
        else 
            self:SetValue(self._options[1] or "None", false, true) 
        end
        return self
    end
    
    function Dropdown:SetOptions(options)
        self._options = options
        for _, child in ipairs(self.Options:GetChildren()) do 
            if not child:IsA("UIListLayout") then child:Destroy() end
        end
        local height = 0
        for i, option in ipairs(options) do
            local button = Core.Util.Create("TextButton", { Name = option, Size = UDim2.new(1, 0, 0, Core.Layout.ComponentHeight), BackgroundColor3 = self._theme.Background2, Text = option, TextColor3 = self._theme.TextColor, Font = self._theme.Font, TextSize = 14, BorderSizePixel = 0, LayoutOrder = i, Parent = self.Options })
            button.InputBegan:Connect(function(input)
                if Core.Util.IsActivate(input.UserInputType) then
                    self:SetValue(option)
                    self:Toggle(false)
                end
            end)
            height = height + Core.Layout.ComponentHeight
        end
        self.Options.CanvasSize = UDim2.new(1, 0, 0, height)
    end
    
    function Dropdown:SetValue(value, animate, ignoreCallback)
        if not table.find(self._options, value) then return end
        self._value = value
        self.Header.Text = value
        if not ignoreCallback then self:_fire(value) end
    end
    function Dropdown:GetValue() return self._value end
    
    function Dropdown:RefreshTheme()
        BaseDropdown.RefreshTheme(self)
        for _, button in ipairs(self.Options:GetChildren()) do
            if button:IsA("TextButton") then
                button.BackgroundColor3 = self._theme.Background2
                button.TextColor3 = self._theme.TextColor
            end
        end
        self:SetValue(self._value, false, true)
    end

    MultiDropdown = setmetatable({}, {__index = BaseDropdown})
    MultiDropdown.__index = MultiDropdown
    function MultiDropdown.new(props)
        local valid, err = Core.Util.ValidateProps(props, {
            Text = { Type = "string", Required = false },
            Options = { Type = "table", Required = false },
            Values = { Type = "table", Required = false },
            Callback = { Type = "function", Required = false }
        })
        if not valid then warn("MultiDropdown Validation Error: " .. err) end

        props.Name = "MultiDropdown"
        local self = BaseDropdown.new(props)
        setmetatable(self, MultiDropdown)
        self._selectedValues = {}
        self._maxSelections = props.MaxSelections or math.huge
        self._originalText = props.Text or "MultiDropdown"
        
        if props.Values and type(props.Values) == "table" then
            for _, value in ipairs(props.Values) do
                if table.find(self._options, value) then table.insert(self._selectedValues, value) end
            end
        elseif props.Value and table.find(self._options, props.Value) then
            table.insert(self._selectedValues, props.Value)
        end
        self:_updateHeaderText()
        return self
    end
    
    function MultiDropdown:_updateHeaderText()
        local numSelected = #self._selectedValues
        if numSelected == 0 then self.Header.Text = self._originalText
        elseif numSelected == 1 then self.Header.Text = self._selectedValues[1]
        elseif numSelected <= 3 then self.Header.Text = table.concat(self._selectedValues, ", ")
        else self.Header.Text = string.format("%d items selected", numSelected) end
    end
    
    function MultiDropdown:SetOptions(options)
        self._options = options
        for _, child in ipairs(self.Options:GetChildren()) do 
            if not child:IsA("UIListLayout") then child:Destroy() end
        end
        local height = 0
        for i, option in ipairs(options) do
            local isSelected = table.find(self._selectedValues, option) ~= nil
            local optionFrame = Core.Util.Create("Frame", { Name = "Option_" .. option, Size = UDim2.new(1, 0, 0, Core.Layout.ComponentHeight), BackgroundColor3 = self._theme.Background2, BorderSizePixel = 0, LayoutOrder = i, Parent = self.Options })
            local checkbox = Core.Util.Create("Frame", { Name = "Checkbox", Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 8, 0.5, -8), BackgroundColor3 = isSelected and self._theme.Accent or self._theme.Background, BorderSizePixel = 0, Parent = optionFrame })
            Core.Util.Create("UIStroke", { Color = self._theme.Accent, Thickness = 1, Parent = checkbox })
            Core.Util.Create("TextLabel", { Name = "Checkmark", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = isSelected and "✓" or "", TextColor3 = self._theme.TextColor, TextScaled = true, Font = self._theme.Font, Parent = checkbox })
            Core.Util.Create("TextLabel", { Name = "Text", Size = UDim2.new(1, -Core.Layout.ComponentHeight, 1, 0), Position = UDim2.new(0, Core.Layout.ComponentHeight, 0, 0), BackgroundTransparency = 1, Text = option, TextColor3 = self._theme.TextColor, TextXAlignment = Enum.TextXAlignment.Left, Font = self._theme.Font, TextSize = 14, Parent = optionFrame })
            local button = Core.Util.Create("TextButton", { Name = "Button", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = optionFrame })
            button.InputBegan:Connect(function(input) if Core.Util.IsActivate(input.UserInputType) then self:ToggleValue(option) end end)
            button.MouseEnter:Connect(function() optionFrame.BackgroundColor3 = self._theme.Accent; optionFrame.BackgroundTransparency = 0.8 end)
            button.MouseLeave:Connect(function() optionFrame.BackgroundColor3 = self._theme.Background2; optionFrame.BackgroundTransparency = 0 end)
            height = height + Core.Layout.ComponentHeight
        end
        self.Options.CanvasSize = UDim2.new(1, 0, 0, height)
    end
    
    function MultiDropdown:ToggleValue(value)
        local index = table.find(self._selectedValues, value)
        if index then table.remove(self._selectedValues, index)
        elseif #self._selectedValues < self._maxSelections then table.insert(self._selectedValues, value) end
        self:_updateHeaderText()
        self:SetOptions(self._options)
        self:_fire(self._selectedValues)
    end
    
    function MultiDropdown:SetValues(values, animate, ignoreCallback)
        self._selectedValues = {}
        if values and type(values) == "table" then
            for _, value in ipairs(values) do
                if table.find(self._options, value) and #self._selectedValues < self._maxSelections then table.insert(self._selectedValues, value) end
            end
        end
        self:_updateHeaderText()
        self:SetOptions(self._options)
        if not ignoreCallback then self:_fire(self._selectedValues) end
    end
    
    function MultiDropdown:GetValues() return self._selectedValues end
    function MultiDropdown:ClearSelection() self:SetValues({}, false, false) end
    function MultiDropdown:SetMaxSelections(max) self._maxSelections = max or math.huge; self:SetValues(self._selectedValues, false, false) end
    
    function MultiDropdown:RefreshTheme()
        BaseDropdown.RefreshTheme(self)
        for _, child in ipairs(self.Options:GetChildren()) do
            if child:IsA("Frame") and child.Name:match("Option_") then
                child.BackgroundColor3 = self._theme.Background2
                local checkbox = child:FindFirstChild("Checkbox")
                local text = child:FindFirstChild("Text")
                if checkbox then
                    local isSelected = checkbox:FindFirstChild("Checkmark") and checkbox.Checkmark.Text == "✓"
                    checkbox.BackgroundColor3 = isSelected and self._theme.Accent or self._theme.Background
                    local cbStroke = checkbox:FindFirstChildOfClass("UIStroke")
                    if cbStroke then cbStroke.Color = self._theme.Accent end
                    if checkbox:FindFirstChild("Checkmark") then checkbox.Checkmark.TextColor3 = self._theme.TextColor end
                end
                if text then text.TextColor3 = self._theme.TextColor end
            end
        end
    end

    -- KeybindList Controller
    local KeybindListController = {
        Visible = false,
        Keybinds = {},
        Frame = nil,
        Container = nil
    }
    
    function KeybindListController:Init(theme)
        self.Theme = theme
        self.ScreenGui = Core.Util.Create("ScreenGui", {
            Name = Core.Safety.RandomString(16),
            ResetOnSpawn = false,
            Parent = Core.Safety.GetRoot()
        })
        self.ScreenGui:SetAttribute("__g", true)
        Core.Safety.ProtectInstance(self.ScreenGui)
        
        self.Frame = Core.Util.Create("Frame", {
            Name = "Frame",
            Size = UDim2.fromOffset(200, 22),
            Position = UDim2.new(0, 10, 0.5, -100),
            BackgroundColor3 = theme.Window.Background,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = self.ScreenGui
        })
        
        Core.Util.Create("UIStroke", { Color = theme.Border, Thickness = 1, Parent = self.Frame })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = self.Frame })
        
        -- Header
        local header = Core.Util.Create("Frame", {
            Name = "Header",
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            Parent = self.Frame
        })
        
        Core.Util.Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.fromOffset(10, 0),
            BackgroundTransparency = 1,
            Text = "Keybinds",
            TextColor3 = theme.Window.TitleText,
            Font = theme.Font,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = header
        })
        
        self.Container = Core.Util.Create("Frame", {
            Name = "Container",
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.fromOffset(0, 22),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = self.Frame
        })
        
        Core.Util.Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2),
            Parent = self.Container
        })
        
        Core.Util.Create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 6),
            Parent = self.Container
        })
        
        Core.Behaviors.MakeDraggable(header, self.Frame)
    end
    
    function KeybindListController:SetVisible(visible)
        self.Visible = visible
        if not self.Frame then self:Init(Theme) end
        self.Frame.Visible = visible
    end
    
    function KeybindListController:Add(id, name, key)
        if not self.Frame then self:Init(Theme) end
        if self.Keybinds[id] then
            self:Update(id, name, key)
            return
        end
        
        local entry = Core.Util.Create("Frame", {
            Name = id,
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Parent = self.Container
        })
        
        local nameLabel = Core.Util.Create("TextLabel", {
            Name = "Name",
            Size = UDim2.new(1, -40, 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = self.Theme.TextColor,
            Font = self.Theme.Font,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = entry
        })
        
        local keyLabel = Core.Util.Create("TextLabel", {
            Name = "Key",
            Size = UDim2.new(0, 40, 1, 0),
            Position = UDim2.new(1, -40, 0, 0),
            BackgroundTransparency = 1,
            Text = "[" .. tostring(key) .. "]",
            TextColor3 = self.Theme.Accent,
            Font = self.Theme.Font,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = entry
        })
        
        self.Keybinds[id] = { Frame = entry, NameLabel = nameLabel, KeyLabel = keyLabel }
        entry.Visible = (key ~= "None")
    end
    
    function KeybindListController:Update(id, name, key)
        if not self.Keybinds[id] then return end
        self.Keybinds[id].NameLabel.Text = name
        self.Keybinds[id].KeyLabel.Text = "[" .. tostring(key) .. "]"
        self.Keybinds[id].Frame.Visible = (key ~= "None")
    end
    
    function KeybindListController:Remove(id)
        if self.Keybinds[id] then
            self.Keybinds[id].Frame:Destroy()
            self.Keybinds[id] = nil
        end
    end
    
    function KeybindListController:RefreshTheme()
        if not self.Frame then return end
        self.Theme = Core.Theme
        
        self.Frame.BackgroundColor3 = self.Theme.Window.Background
        local stroke = self.Frame:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = self.Theme.Border end
        
        local header = self.Frame:FindFirstChild("Header")
        if header then
            local title = header:FindFirstChild("Title")
            if title then title.TextColor3 = self.Theme.Window.TitleText end
        end
        
        for _, bind in pairs(self.Keybinds) do
            if bind.NameLabel then bind.NameLabel.TextColor3 = self.Theme.TextColor end
            if bind.KeyLabel then bind.KeyLabel.TextColor3 = self.Theme.Accent end
        end
    end

    -- Hotkey
    Hotkey = setmetatable({}, {__index = BaseComponent})
    Hotkey.__index = Hotkey
    function Hotkey.new(props)
        local valid, err = Core.Util.ValidateProps(props, {
            Text = { Type = "string", Required = false },
            Value = { Type = {"string", "EnumItem"}, Required = false },
            Callback = { Type = "function", Required = false }
        })
        if not valid then warn("Hotkey Validation Error: " .. err) end

        local self = BaseComponent.new({ Name = "Hotkey", Theme = props.Theme or Theme, Tooltip = props.Tooltip })
        setmetatable(self, Hotkey)
        self.Root = Core.Util.Create("Frame", { Name = "Hotkey", Size = UDim2.new(1, 0, 0, Core.Layout.ComponentHeight), BackgroundTransparency = 1, Parent = props.Parent })
        self._text = props.Text or "Hotkey"
        self:_createLabel(self._text)
        self:_createButton()
        self._callback = props.Callback
        self._listening = false
        self:SetValue(props.Value or "None", false)
        self:_setupTooltip(self.Root)
        
        self._id = Core.Safety.RandomString(8)
        KeybindListController:Add(self._id, self._text, self._value)
        
        return self
    end
    function Hotkey:_createLabel(text)
        self.Label = Core.Util.Create("TextLabel", { Name = "Label", Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1, Text = text or "Hotkey", TextColor3 = self._theme.TextColor, TextXAlignment = Enum.TextXAlignment.Left, Font = self._theme.Font, TextSize = 14, Parent = self.Root })
    end
    function Hotkey:_createButton()
        self.Button = Core.Util.Create("TextButton", { Name = "Button", Size = UDim2.fromOffset(90, 24), Position = UDim2.new(1, -90, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = self._theme.Background2, Text = "None", TextColor3 = self._theme.TextColor, Font = self._theme.Font, TextSize = 14, BorderSizePixel = 0, Parent = self.Root })
        
        -- Add UIStroke
        Core.Util.Create("UIStroke", {
            Color = self._theme.Border,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = self.Button
        })

        self.Button.InputBegan:Connect(function(input)
            if Core.Util.IsActivate(input.UserInputType) then
                self:StartListening()
            end
        end)
    end
    function Hotkey:StartListening()
        if self._listening then return end
        self._listening = true
        self.Button.Text = "..."
        Core.Util.Tween(self.Button, { BackgroundColor3 = self._theme.Accent }, 0.2)
        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local keyName = input.KeyCode.Name
                self:SetValue(keyName)
                self:StopListening()
                if connection then connection:Disconnect() end
            end
        end)
        self._hotkeyConnection = connection
    end
    function Hotkey:StopListening()
        if not self._listening then return end
        self._listening = false
        Core.Util.Tween(self.Button, { BackgroundColor3 = self._theme.Background2 }, 0.2)
        if self._hotkeyConnection then
            self._hotkeyConnection:Disconnect()
            self._hotkeyConnection = nil
        end
    end
    function Hotkey:SetValue(value, animate)
        if typeof(value) == "EnumItem" then
            value = value.Name
        end
        self._value = value or "None"
        self.Button.Text = self._value
        
        if self._id then
            KeybindListController:Update(self._id, self._text, self._value)
        end
        
        self:_fire(self._value)
    end
    function Hotkey:GetValue() return self._value end
    function Hotkey:RefreshTheme()
        if self._destroyed then return end
        self.Label.TextColor3 = self._theme.TextColor
        self.Button.BackgroundColor3 = self._listening and self._theme.Accent or self._theme.Background2
        self.Button.TextColor3 = self._theme.TextColor
        
        -- Update border stroke
        local stroke = self.Button:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = self._theme.Border end
    end
    function Hotkey:Destroy()
        if self._destroyed then return end
        if self._id then
            KeybindListController:Remove(self._id)
        end
        if self._hotkeyConnection then
            self._hotkeyConnection:Disconnect()
            self._hotkeyConnection = nil
        end
        BaseComponent.Destroy(self)
    end

    -- ColorPicker
    ColorPicker = setmetatable({}, {__index = BaseComponent})
    ColorPicker.__index = ColorPicker
    function ColorPicker.new(props)
        local self = BaseComponent.new({ Name = "ColorPicker", Theme = props.Theme or Theme, Tooltip = props.Tooltip })
        setmetatable(self, ColorPicker)
        
        self.Root = Core.Util.Create("Frame", { Name = "ColorPicker", Size = UDim2.new(1, 0, 0, Core.Layout.ComponentHeight), BackgroundTransparency = 1, Parent = props.Parent })
        self._color = props.Default or Color3.fromRGB(255, 255, 255)
        self._transparency = props.Transparency or 0
        self._callback = props.Callback
        self._open = false
        
        self:_createHeader(props.Text)
        self:_createPicker()
        
        self:SetValue(self._color, self._transparency, false)
        self:_setupTooltip(self.Root)
        
        return self
    end
    
    function ColorPicker:_createHeader(text)
        self.Label = Core.Util.Create("TextLabel", { Name = "Label", Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Text = text or "ColorPicker", TextColor3 = self._theme.TextColor, TextXAlignment = Enum.TextXAlignment.Left, Font = self._theme.Font, TextSize = 14, Parent = self.Root })
        
        self.Preview = Core.Util.Create("TextButton", { Name = "Preview", Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -40, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = self._color, BackgroundTransparency = self._transparency, Text = "", AutoButtonColor = false, Parent = self.Root })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = self.Preview })
        Core.Util.Create("UIStroke", { Color = self._theme.Border, Thickness = 1, Parent = self.Preview })
        
        local checker = Core.Util.Create("ImageLabel", { Name = "Checker", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "rbxassetid://14204231522", ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(10, 10), ZIndex = 0, Parent = self.Preview })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = checker })

        self.Preview.InputBegan:Connect(function(input)
            if Core.Util.IsActivate(input.UserInputType) then
                self:Toggle()
            end
        end)
    end
    
    function ColorPicker:_createPicker()
        self.Container = Core.Util.Create("Frame", { Name = "Container", Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 0), BackgroundColor3 = self._theme.Background2, ClipsDescendants = true, BorderSizePixel = 0, Parent = self.Root })
        Core.Util.Create("UIStroke", { Color = self._theme.Border, Thickness = 1, Parent = self.Container })
        
        self.PickerFrame = Core.Util.Create("Frame", { Name = "PickerFrame", Size = UDim2.new(1, -16, 1, -16), Position = UDim2.fromOffset(8, 8), BackgroundTransparency = 1, Parent = self.Container })
        
        self.SVImage = Core.Util.Create("ImageLabel", { Name = "SV", Size = UDim2.new(0, 150, 0, 150), BackgroundColor3 = Color3.new(1, 0, 0), Image = "rbxassetid://4155801252", BorderSizePixel = 0, Parent = self.PickerFrame })
        self.SVCursor = Core.Util.Create("Frame", { Name = "Cursor", Size = UDim2.fromOffset(4, 4), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = self.SVImage })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self.SVCursor })
        
        self.HueImage = Core.Util.Create("ImageLabel", { Name = "Hue", Size = UDim2.new(0, 20, 0, 150), Position = UDim2.fromOffset(160, 0), BackgroundColor3 = Color3.new(1, 1, 1), Image = "", BorderSizePixel = 0, Parent = self.PickerFrame })
        Core.Util.Create("UIGradient", { Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))
        }, Rotation = 90, Parent = self.HueImage })
        
        self.HueCursor = Core.Util.Create("Frame", { Name = "Cursor", Size = UDim2.new(1, 0, 0, 2), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = self.HueImage })
        
        self.AlphaImage = Core.Util.Create("ImageLabel", { Name = "Alpha", Size = UDim2.new(0, 20, 0, 150), Position = UDim2.fromOffset(190, 0), BackgroundColor3 = Color3.new(1, 1, 1), Image = "rbxassetid://14204231522", ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(10, 10), BorderSizePixel = 0, Parent = self.PickerFrame })
        self.AlphaGradientFrame = Core.Util.Create("Frame", { Name = "Gradient", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = self.AlphaImage })
        self.AlphaGradient = Core.Util.Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}, Parent = self.AlphaGradientFrame })
        
        self.AlphaCursor = Core.Util.Create("Frame", { Name = "Cursor", Size = UDim2.new(1, 0, 0, 2), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = self.AlphaImage })

        local h, s, v = self._color:ToHSV()
        self._h, self._s, self._v = h, s, v
        
        local draggingSV, draggingHue, draggingAlpha = false, false, false
        
        local function getCorrectedPos(input)
            local pos = Core.Util.GetInputPosition(input)
            local screenGui = self.Root:FindFirstAncestorWhichIsA("ScreenGui")
            if screenGui and not screenGui.IgnoreGuiInset then
                local inset = GuiService:GetGuiInset()
                pos = pos - Vector2.new(0, inset.Y)
            end
            return pos
        end

        local function updateSV(input)
            local pos = getCorrectedPos(input)
            local rPos = pos - self.SVImage.AbsolutePosition
            local size = self.SVImage.AbsoluteSize
            local s = math.clamp(rPos.X / size.X, 0, 1)
            local v = 1 - math.clamp(rPos.Y / size.Y, 0, 1)
            self._s, self._v = s, v
            self:UpdateColor()
        end
        
        local function updateHue(input)
            local pos = getCorrectedPos(input)
            local rPos = pos - self.HueImage.AbsolutePosition
            local size = self.HueImage.AbsoluteSize
            local h = 1 - math.clamp(rPos.Y / size.Y, 0, 1)
            self._h = h
            self:UpdateColor()
        end

        local function updateAlpha(input)
            local pos = getCorrectedPos(input)
            local rPos = pos - self.AlphaImage.AbsolutePosition
            local size = self.AlphaImage.AbsoluteSize
            local t = math.clamp(rPos.Y / size.Y, 0, 1)
            self._transparency = t
            self:UpdateColor()
        end
        
        self.SVImage.InputBegan:Connect(function(input)
            if Core.Util.IsActivate(input.UserInputType) then 
                draggingSV = true
                updateSV(input)
                
                local inputChanged, inputEnded
                inputChanged = UserInputService.InputChanged:Connect(function(input)
                    if draggingSV and Core.Util.IsTouchMovement(input.UserInputType) then updateSV(input) end
                end)
                inputEnded = UserInputService.InputEnded:Connect(function(input)
                    if Core.Util.IsActivate(input.UserInputType) then 
                        draggingSV = false
                        inputChanged:Disconnect()
                        inputEnded:Disconnect()
                    end
                end)
            end
        end)
        
        self.HueImage.InputBegan:Connect(function(input)
            if Core.Util.IsActivate(input.UserInputType) then 
                draggingHue = true
                updateHue(input)
                
                local inputChanged, inputEnded
                inputChanged = UserInputService.InputChanged:Connect(function(input)
                    if draggingHue and Core.Util.IsTouchMovement(input.UserInputType) then updateHue(input) end
                end)
                inputEnded = UserInputService.InputEnded:Connect(function(input)
                    if Core.Util.IsActivate(input.UserInputType) then 
                        draggingHue = false
                        inputChanged:Disconnect()
                        inputEnded:Disconnect()
                    end
                end)
            end
        end)
        
        self.AlphaImage.InputBegan:Connect(function(input)
            if Core.Util.IsActivate(input.UserInputType) then 
                draggingAlpha = true
                updateAlpha(input)
                
                local inputChanged, inputEnded
                inputChanged = UserInputService.InputChanged:Connect(function(input)
                    if draggingAlpha and Core.Util.IsTouchMovement(input.UserInputType) then updateAlpha(input) end
                end)
                inputEnded = UserInputService.InputEnded:Connect(function(input)
                    if Core.Util.IsActivate(input.UserInputType) then 
                        draggingAlpha = false
                        inputChanged:Disconnect()
                        inputEnded:Disconnect()
                    end
                end)
            end
        end)
    end
    
    function ColorPicker:UpdateColor()
        self._color = Color3.fromHSV(self._h, self._s, self._v)
        self.SVImage.BackgroundColor3 = Color3.fromHSV(self._h, 1, 1)
        self.SVCursor.Position = UDim2.fromScale(self._s, 1 - self._v)
        self.HueCursor.Position = UDim2.fromScale(0, 1 - self._h)
        self.AlphaCursor.Position = UDim2.fromScale(0, self._transparency)
        
        self.Preview.BackgroundColor3 = self._color
        self.Preview.BackgroundTransparency = self._transparency
        self.AlphaGradientFrame.BackgroundColor3 = self._color
        
        self:_fire(self._color, self._transparency)
    end
    
    function ColorPicker:SetValue(color, transparency, animate)
        self._color = color
        self._transparency = transparency or 0
        self._h, self._s, self._v = color:ToHSV()
        self:UpdateColor()
    end
    
    function ColorPicker:Toggle()
        self._open = not self._open
        local size = self._open and UDim2.new(1, 0, 0, 170) or UDim2.new(1, 0, 0, 0)
        Core.Util.Tween(self.Container, {Size = size}, 0.2)
        if self._open then
            self.Root.ZIndex = Core.ZIndex.Dropdown
            -- Boost every GuiObject ancestor up to (not including) the page ScrollingFrame.
            self._boostedAncestors = {}
            local cur = self.Root.Parent
            while cur do
                if cur:IsA("ScrollingFrame") then break end
                if cur:IsA("GuiObject") then
                    table.insert(self._boostedAncestors, { inst = cur, prev = cur.ZIndex })
                    cur.ZIndex = Core.ZIndex.Dropdown
                end
                cur = cur.Parent
            end
        else
            task.delay(0.21, function()
                if not self._open and not self._destroyed then
                    self.Root.ZIndex = 1
                    if self._boostedAncestors then
                        for _, entry in ipairs(self._boostedAncestors) do
                            entry.inst.ZIndex = entry.prev
                        end
                        self._boostedAncestors = nil
                    end
                end
            end)
        end
    end
    
    function ColorPicker:RefreshTheme()
        if self._destroyed then return end
        self.Root.BackgroundColor3 = self._theme.Background2
        self.Label.TextColor3 = self._theme.TextColor
        self.Container.BackgroundColor3 = self._theme.Background2
        
        local stroke = self.Root:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = self._theme.Border end
        local containerStroke = self.Container:FindFirstChildOfClass("UIStroke")
        if containerStroke then containerStroke.Color = self._theme.Border end
        local previewStroke = self.Preview:FindFirstChildOfClass("UIStroke")
        if previewStroke then previewStroke.Color = self._theme.Border end
    end

    function ColorPicker:Destroy()
        if self._destroyed then return end
        BaseComponent.Destroy(self)
    end

    -- Notification
    -- Notification Stack Manager
    -- Manages one shared ScreenGui per position string. All notifications at the
    -- same position parent their frames into a single UIListLayout container so
    -- they stack vertically instead of overlapping.
    local NotifStack = { _stacks = {} }

    function NotifStack._getOrCreate(position, theme)
        local existing = NotifStack._stacks[position]
        if existing and existing.gui and existing.gui.Parent then
            return existing.container
        end

        local gui = Core.Util.Create("ScreenGui", {
            Name = Core.Safety.RandomString(16),
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 10000,
            Parent = Core.Safety.GetRoot(),
        })
        gui:SetAttribute("__g", true)
        Core.Safety.ProtectInstance(gui)

        local anchorX = position:match("Right") and 1 or (position:match("Left") and 0 or 0.5)
        local anchorY = position:match("Bottom") and 1 or 0
        local ox = position:match("Right") and -10 or (position:match("Left") and 10 or 0)
        local oy = position:match("Bottom") and -10 or 10

        local container = Core.Util.Create("Frame", {
            Name = "NotifStack",
            Size = UDim2.fromOffset(290, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            AnchorPoint = Vector2.new(anchorX, anchorY),
            Position = UDim2.new(anchorX, ox, anchorY, oy),
            BackgroundTransparency = 1,
            Parent = gui,
        })
        Core.Util.Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Vertical,
            VerticalAlignment = position:match("Bottom")
                and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top,
            Parent = container,
        })

        NotifStack._stacks[position] = { gui = gui, container = container, order = 0 }
        return container
    end

    function NotifStack._nextOrder(position)
        local s = NotifStack._stacks[position]
        if not s then return 1 end
        s.order = s.order + 1
        return s.order
    end

    -- Notification
    Notification = setmetatable({}, {__index = BaseComponent})
    Notification.__index = Notification
    function Notification.new(props)
        local self = BaseComponent.new({ Name = "Notification", Theme = props.Theme or Core.Theme })
        setmetatable(self, Notification)

        self._position = props.Position or "TopRight"

        -- Get (or lazily create) the shared stacking container for this position.
        local container = NotifStack._getOrCreate(self._position, self._theme)
        local order = NotifStack._nextOrder(self._position)

        -- Outer slot: UIListLayout positions this. ClipsDescendants clips the slide animation.
        self._slot = Core.Util.Create("Frame", {
            Name = "NotifSlot",
            Size = UDim2.new(1, 0, 0, 88),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            LayoutOrder = order,
            Parent = container,
        })

        self.Root = Core.Util.Create("Frame", {
            Name = "Notification",
            Size = UDim2.new(1, 0, 0, 80),
            Position = UDim2.fromOffset(self._position:match("Left") and -300 or 300, 0),
            BackgroundColor3 = self._theme.Background2,
            BorderSizePixel = 0,
            Parent = self._slot,
        })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = self.Root })
        Core.Util.Create("UIStroke", { Color = self._theme.Border, Thickness = 1, Parent = self.Root })

        self.Title = Core.Util.Create("TextLabel", { Name = "Title", Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(8, 8), BackgroundTransparency = 1, Text = props.Title or "Notification", TextColor3 = self._theme.TextColor, TextXAlignment = Enum.TextXAlignment.Left, Font = self._theme.Font, TextSize = 14, Parent = self.Root })
        self.Message = Core.Util.Create("TextLabel", { Name = "Message", Size = UDim2.new(1, -16, 1, -40), Position = UDim2.fromOffset(8, 32), BackgroundTransparency = 1, Text = props.Text or "", TextColor3 = self._theme.SubTextColor, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Font = self._theme.Font, TextSize = 13, Parent = self.Root })
        if self._theme.EnableBrackets then self:_createCornerBrackets() end

        if props.FX then
            self._fx = Core.FX.Apply(self.Root, props.FX, self._theme)
        end

        if props.Duration then self:_startTimer(props.Duration) end
        self:_animate()
        return self
    end
    function Notification:_createCornerBrackets()
        local brackets = { TopLeft = {pos = UDim2.fromOffset(-1, -1), size = UDim2.fromOffset(4, 4)}, TopRight = {pos = UDim2.new(1, -3, 0, -1), size = UDim2.fromOffset(4, 4)}, BottomLeft = {pos = UDim2.new(0, -1, 1, -3), size = UDim2.fromOffset(4, 4)}, BottomRight = {pos = UDim2.new(1, -3, 1, -3), size = UDim2.fromOffset(4, 4)} }
        for name, data in pairs(brackets) do
            local bracket = Core.Util.Create("Frame", { Name = name, Size = data.size, Position = data.pos, BackgroundColor3 = self._theme.Window.CornerBrackets, BorderSizePixel = 0, Parent = self.Root })
            Core.Util.Create("Frame", { Size = UDim2.fromOffset(2, 2), Position = UDim2.fromOffset(1, 1), BackgroundColor3 = self._theme.Background2, BorderSizePixel = 0, Parent = bracket })
        end
    end
    function Notification:_startTimer(duration)
        local progress = Core.Util.Create("Frame", { Name = "Progress", Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = self._theme.Accent, BorderSizePixel = 0, Parent = self.Root })
        TweenService:Create(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
        task.delay(duration, function() if not self._destroyed then self:Close() end end)
    end
    function Notification:_animate()
        -- Slide in from the edge determined by position
        local targetX = 0
        local startX = self._position:match("Left") and -300 or 300
        self.Root.Position = UDim2.fromOffset(startX, 0)
        TweenService:Create(self.Root, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(targetX, 0) }):Play()
    end
    function Notification:Close()
        if self._destroyed or self._closing then return end
        self._closing = true
        local exitX = self._position:match("Left") and -300 or 300
        TweenService:Create(self.Root, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromOffset(exitX, 0) }):Play()
        -- Collapse the slot height so the remaining stack re-packs smoothly
        TweenService:Create(self._slot, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.new(1, 0, 0, 0) }):Play()
        task.delay(0.25, function() self:Destroy() end)
    end
    function Notification:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        if self._slot then self._slot:Destroy(); self._slot = nil end
    end

    -- Separator: a horizontal rule, optionally labelled
    Separator = setmetatable({}, {__index = BaseComponent})
    Separator.__index = Separator
    function Separator.new(props)
        local self = BaseComponent.new({ Name = "Separator", Theme = props.Theme })
        setmetatable(self, Separator)
        local hasText = props.Text and props.Text ~= ""
        self.Root = Core.Util.Create("Frame", {
            Name = "Separator",
            Size = UDim2.new(1, 0, 0, hasText and 20 or 1),
            BackgroundTransparency = hasText and 1 or 0,
            BackgroundColor3 = self._theme.Border,
            BorderSizePixel = 0,
            Parent = props.Parent
        })
        if hasText then
            self._line1 = Core.Util.Create("Frame", {
                Name = "Line1", Size = UDim2.new(0.5, -44, 0, 1),
                Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = self._theme.Border, BorderSizePixel = 0, Parent = self.Root
            })
            self._textLabel = Core.Util.Create("TextLabel", {
                Name = "Label", Size = UDim2.new(0, 80, 1, 0),
                Position = UDim2.new(0.5, -40, 0, 0), BackgroundTransparency = 1,
                Text = props.Text, TextColor3 = self._theme.SubTextColor,
                Font = self._theme.Font, TextSize = 12, Parent = self.Root
            })
            self._line2 = Core.Util.Create("Frame", {
                Name = "Line2", Size = UDim2.new(0.5, -44, 0, 1),
                Position = UDim2.new(0.5, 40, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = self._theme.Border, BorderSizePixel = 0, Parent = self.Root
            })
        end
        return self
    end
    function Separator:RefreshTheme()
        if self._destroyed then return end
        self.Root.BackgroundColor3 = self._theme.Border
        if self._line1 then self._line1.BackgroundColor3 = self._theme.Border end
        if self._textLabel then
            self._textLabel.TextColor3 = self._theme.SubTextColor
            self._textLabel.Font = self._theme.Font
        end
        if self._line2 then self._line2.BackgroundColor3 = self._theme.Border end
    end

    -- RadioGroup: mutually-exclusive option list
    RadioGroup = setmetatable({}, {__index = BaseComponent})
    RadioGroup.__index = RadioGroup
    function RadioGroup.new(props)
        local self = BaseComponent.new({ Name = "RadioGroup", Theme = props.Theme })
        setmetatable(self, RadioGroup)
        self._options  = props.Options or {}
        self._value    = props.Value
        self._callback = props.Callback
        self.Root = Core.Util.Create("Frame", {
            Name = "RadioGroup", Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = props.Parent
        })
        if props.Text then
            self._label = Core.Util.Create("TextLabel", {
                Name = "Label", Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1, Text = props.Text,
                TextColor3 = self._theme.SubTextColor, TextXAlignment = Enum.TextXAlignment.Left,
                Font = self._theme.Font, TextSize = 12, Parent = self.Root
            })
        end
        self._itemsFrame = Core.Util.Create("Frame", {
            Name = "Items", Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.fromOffset(0, props.Text and 22 or 0),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = self.Root
        })
        Core.Util.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = self._itemsFrame })
        self._buttons = {}
        self:_buildOptions()
        self:_setupTooltip(self.Root)
        return self
    end
    function RadioGroup:_buildOptions()
        for _, child in ipairs(self._itemsFrame:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        self._buttons = {}
        for i, opt in ipairs(self._options) do
            local row = Core.Util.Create("Frame", {
                Name = opt, Size = UDim2.new(1, 0, 0, Core.Layout.ComponentHeight),
                BackgroundTransparency = 1, LayoutOrder = i, Parent = self._itemsFrame
            })
            local dot = Core.Util.Create("Frame", {
                Name = "Dot", Size = UDim2.fromOffset(16, 16),
                Position = UDim2.new(0, 4, 0.5, -8),
                BackgroundColor3 = self._value == opt and self._theme.Accent or self._theme.Background2,
                BorderSizePixel = 0, Parent = row
            })
            Core.Util.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
            Core.Util.Create("UIStroke", { Color = self._theme.Border, Thickness = 1, Parent = dot })
            local inner = Core.Util.Create("Frame", {
                Name = "Inner", Size = UDim2.fromOffset(8, 8),
                Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = self._value == opt and 0 or 1, BorderSizePixel = 0, Parent = dot
            })
            Core.Util.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = inner })
            local lbl = Core.Util.Create("TextLabel", {
                Name = "Label", Size = UDim2.new(1, -28, 1, 0), Position = UDim2.fromOffset(28, 0),
                BackgroundTransparency = 1, Text = opt,
                TextColor3 = self._value == opt and self._theme.TextColor or self._theme.SubTextColor,
                TextXAlignment = Enum.TextXAlignment.Left, Font = self._theme.Font, TextSize = 14, Parent = row
            })
            row.InputBegan:Connect(function(input)
                if Core.Util.IsActivate(input.UserInputType) then self:SetValue(opt) end
            end)
            self._buttons[opt] = { Row = row, Dot = dot, Inner = inner, Label = lbl }
        end
    end
    function RadioGroup:SetValue(value, ignoreCallback)
        self._value = value
        for opt, parts in pairs(self._buttons) do
            local active = (opt == value)
            Core.Util.Tween(parts.Dot, { BackgroundColor3 = active and self._theme.Accent or self._theme.Background2 }, 0.15)
            parts.Inner.BackgroundTransparency = active and 0 or 1
            parts.Label.TextColor3 = active and self._theme.TextColor or self._theme.SubTextColor
        end
        if not ignoreCallback and self._callback then pcall(self._callback, value) end
    end
    function RadioGroup:GetValue() return self._value end
    function RadioGroup:SetOptions(options) self._options = options; self:_buildOptions() end
    function RadioGroup:RefreshTheme()
        if self._destroyed then return end
        if self._label then
            self._label.TextColor3 = self._theme.SubTextColor
            self._label.Font = self._theme.Font
        end
        for opt, parts in pairs(self._buttons) do
            local active = (opt == self._value)
            parts.Dot.BackgroundColor3 = active and self._theme.Accent or self._theme.Background2
            local stroke = parts.Dot:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = self._theme.Border end
            parts.Label.TextColor3 = active and self._theme.TextColor or self._theme.SubTextColor
            parts.Label.Font = self._theme.Font
        end
    end

    -- DataTable: themed header + alternating rows
    DataTable = setmetatable({}, {__index = BaseComponent})
    DataTable.__index = DataTable
    function DataTable.new(props)
        local self = BaseComponent.new({ Name = "DataTable", Theme = props.Theme })
        setmetatable(self, DataTable)
        self._headers   = props.Headers  or {}
        self._rows      = props.Rows     or {}
        self._rowHeight = props.RowHeight or Core.Layout.ComponentHeight
        self.Root = Core.Util.Create("Frame", {
            Name = "DataTable", Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = props.Parent
        })
        self._headerRow = Core.Util.Create("Frame", {
            Name = "HeaderRow", Size = UDim2.new(1, 0, 0, self._rowHeight),
            BackgroundColor3 = self._theme.Background2, BorderSizePixel = 0, Parent = self.Root
        })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = self._headerRow })
        Core.Util.Create("UIStroke", { Color = self._theme.Border, Thickness = 1, Parent = self._headerRow })
        Core.Util.Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Parent = self._headerRow })
        self._body = Core.Util.Create("Frame", {
            Name = "Body", Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.fromOffset(0, self._rowHeight + 2),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = self.Root
        })
        Core.Util.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1), Parent = self._body })
        self:_buildHeaders()
        self:SetRows(self._rows)
        return self
    end
    function DataTable:_buildHeaders()
        for _, child in ipairs(self._headerRow:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end
        local colW = #self._headers > 0 and (1 / #self._headers) or 1
        for i, h in ipairs(self._headers) do
            Core.Util.Create("TextLabel", {
                Name = h, Size = UDim2.new(colW, 0, 1, 0), BackgroundTransparency = 1,
                Text = h, TextColor3 = self._theme.TextColor, Font = self._theme.Font,
                TextSize = 13, LayoutOrder = i, Parent = self._headerRow
            })
        end
    end
    function DataTable:_buildRow(rowData, index)
        local colW   = #self._headers > 0 and (1 / #self._headers) or 1
        local isEven = (index % 2 == 0)
        local row = Core.Util.Create("Frame", {
            Name = "Row" .. tostring(index), Size = UDim2.new(1, 0, 0, self._rowHeight),
            BackgroundColor3 = isEven and self._theme.Background2 or self._theme.Background,
            BackgroundTransparency = isEven and 0 or 0.3, BorderSizePixel = 0,
            LayoutOrder = index, Parent = self._body
        })
        Core.Util.Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
        for i, cell in ipairs(rowData) do
            Core.Util.Create("TextLabel", {
                Name = "Cell" .. tostring(i), Size = UDim2.new(colW, 0, 1, 0), BackgroundTransparency = 1,
                Text = tostring(cell), TextColor3 = self._theme.SubTextColor,
                Font = self._theme.Font, TextSize = 13, LayoutOrder = i, Parent = row
            })
        end
        return row
    end
    function DataTable:SetRows(rows)
        self._rows = rows or {}
        for _, child in ipairs(self._body:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        for i, row in ipairs(self._rows) do self:_buildRow(row, i) end
    end
    function DataTable:AddRow(rowData)
        table.insert(self._rows, rowData)
        self:_buildRow(rowData, #self._rows)
    end
    function DataTable:ClearRows()
        self._rows = {}
        for _, child in ipairs(self._body:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
    end
    function DataTable:RefreshTheme()
        if self._destroyed then return end
        self._headerRow.BackgroundColor3 = self._theme.Background2
        local stroke = self._headerRow:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = self._theme.Border end
        for _, child in ipairs(self._headerRow:GetChildren()) do
            if child:IsA("TextLabel") then
                child.TextColor3 = self._theme.TextColor
                child.Font = self._theme.Font
            end
        end
        self:SetRows(self._rows)
    end

    -- CodeBlock: monospaced read-only text display with optional clipboard copy
    CodeBlock = setmetatable({}, {__index = BaseComponent})
    CodeBlock.__index = CodeBlock
    function CodeBlock.new(props)
        local self = BaseComponent.new({ Name = "CodeBlock", Theme = props.Theme })
        setmetatable(self, CodeBlock)
        self._text     = props.Text or ""
        self._maxLines = props.MaxLines or 10
        local lineCount = select(2, self._text:gsub("\n", "\n")) + 1
        local visLines  = math.min(lineCount, self._maxLines)
        local totalH    = visLines * 18 + 14
        self.Root = Core.Util.Create("Frame", {
            Name = "CodeBlock", Size = UDim2.new(1, 0, 0, totalH),
            BackgroundColor3 = self._theme.Background2, BorderSizePixel = 0,
            ClipsDescendants = true, Parent = props.Parent
        })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = self.Root })
        Core.Util.Create("UIStroke", { Color = self._theme.Border, Thickness = 1, Parent = self.Root })
        Core.Util.Create("UIPadding", {
            PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), Parent = self.Root
        })
        self._textLabel = Core.Util.Create("TextLabel", {
            Name = "Code", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            Text = self._text, TextColor3 = self._theme.TextColor,
            Font = self._theme.FontMono or Enum.Font.Code, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true, Parent = self.Root
        })
        if Core.Compat.hasClipboard then
            self._copyBtn = Core.Util.Create("TextButton", {
                Name = "CopyBtn", Size = UDim2.fromOffset(44, 16),
                Position = UDim2.new(1, -52, 0, 4), BackgroundColor3 = self._theme.Background2,
                Text = "copy", TextColor3 = self._theme.SubTextColor,
                Font = self._theme.Font, TextSize = 11, BorderSizePixel = 0, ZIndex = 2, Parent = self.Root
            })
            Core.Util.Create("UICorner",  { CornerRadius = UDim.new(0, 3), Parent = self._copyBtn })
            Core.Util.Create("UIStroke",  { Color = self._theme.Border, Thickness = 1, Parent = self._copyBtn })
            self._copyBtn.InputBegan:Connect(function(input)
                if Core.Util.IsActivate(input.UserInputType) then
                    local fn = typeof(setclipboard) == "function" and setclipboard
                            or typeof(toclipboard)   == "function" and toclipboard
                    if fn then pcall(fn, self._text) end
                    self._copyBtn.Text = "✓"
                    task.delay(1.5, function()
                        if not self._destroyed and self._copyBtn then self._copyBtn.Text = "copy" end
                    end)
                end
            end)
        end
        return self
    end
    function CodeBlock:SetText(text)
        self._text = text or ""
        if self._textLabel then self._textLabel.Text = self._text end
        local lineCount = select(2, self._text:gsub("\n", "\n")) + 1
        local visLines  = math.min(lineCount, self._maxLines)
        self.Root.Size  = UDim2.new(1, 0, 0, visLines * 18 + 14)
    end
    function CodeBlock:RefreshTheme()
        if self._destroyed then return end
        self.Root.BackgroundColor3 = self._theme.Background2
        local stroke = self.Root:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = self._theme.Border end
        if self._textLabel then
            self._textLabel.TextColor3 = self._theme.TextColor
            self._textLabel.Font = self._theme.FontMono or Enum.Font.Code
        end
        if self._copyBtn then
            self._copyBtn.BackgroundColor3 = self._theme.Background2
            self._copyBtn.TextColor3 = self._theme.SubTextColor
            self._copyBtn.Font = self._theme.Font
            local cs = self._copyBtn:FindFirstChildOfClass("UIStroke")
            if cs then cs.Color = self._theme.Border end
        end
    end

    -- Section
    Section = setmetatable({}, {__index = BaseComponent})
    Section.__index = Section
    function Section.new(props)
        local self = BaseComponent.new({ Name = "Section", Theme = props.Theme })
        setmetatable(self, Section)
        self._components = {}
        
        self.Root = Core.Util.Create("Frame", {
            Name = "Section",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = props.Parent
        })
        
        self.Header = Core.Util.Create("TextButton", {
            Name = "Header",
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundColor3 = self._theme.Background2,
            Text = props.Text or "Section",
            TextColor3 = self._theme.TextColor,
            Font = self._theme.Font,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            Parent = self.Root
        })
        
        Core.Util.Create("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = self.Header })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = self.Header })
        Core.Util.Create("UIStroke", { Color = self._theme.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = self.Header })
        
        self.Content = Core.Util.Create("Frame", {
            Name = "Content",
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, 28),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = self._theme.Background,
            BackgroundTransparency = 0.6,
            ClipsDescendants = false,
            Parent = self.Root
        })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = self.Content })
        Core.Util.Create("UIStroke", { Color = self._theme.Border, Thickness = 1, Transparency = 0.5, Parent = self.Content })
        
        Core.Util.Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            Parent = self.Content
        })
        Core.Util.Create("UIPadding", {
            PaddingLeft  = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop   = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
            Parent = self.Content
        })
        
        self.Arrow = Core.Util.Create("TextLabel", {
            Name = "Arrow",
            Size = UDim2.fromOffset(24, 24),
            Position = UDim2.new(1, -24, 0, 0),
            BackgroundTransparency = 1,
            Text = "▼",
            TextColor3 = self._theme.TextColor,
            Font = self._theme.Font,
            TextSize = 14,
            Parent = self.Header
        })
        
        self._open = true
        self.Header.MouseButton1Click:Connect(function() self:Toggle() end)
        
        self.Header.MouseEnter:Connect(function()
            Core.Util.Tween(self.Header, { BackgroundColor3 = self._theme.Accent }, 0.2)
        end)
        self.Header.MouseLeave:Connect(function()
            Core.Util.Tween(self.Header, { BackgroundColor3 = self._theme.Background2 }, 0.2)
        end)
        
        return self
    end
    
    function Section:Toggle()
        self._open = not self._open
        self.Content.Visible = self._open
        Core.Util.Tween(self.Arrow, { Rotation = self._open and 0 or -90 }, 0.2)
    end

    function Section:RefreshTheme()
        if self._destroyed then return end
        self.Header.BackgroundColor3 = self._theme.Background2
        self.Header.TextColor3 = self._theme.TextColor
        self.Arrow.TextColor3 = self._theme.TextColor
        self.Content.BackgroundColor3 = self._theme.Background
        
        local stroke = self.Header:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = self._theme.Border end
        local contentStroke = self.Content:FindFirstChildOfClass("UIStroke")
        if contentStroke then contentStroke.Color = self._theme.Border end
        
        for _, comp in ipairs(self._components) do
            if comp.RefreshTheme then
                comp._theme = self._theme
                comp:RefreshTheme()
            end
        end
    end
    
    function Section:GetParent() return self.Content end
    function Section:GetTheme() return self._theme end
    function Section:GetComponentList() return self._components end
    
    for k, v in pairs(ComponentMixin) do Section[k] = v end

    -- ProgressBar
    ProgressBar = setmetatable({}, {__index = BaseComponent})
    ProgressBar.__index = ProgressBar
    function ProgressBar.new(props)
        local self = BaseComponent.new({ Name = "ProgressBar", Theme = props.Theme, Tooltip = props.Tooltip })
        setmetatable(self, ProgressBar)
        
        self.Root = Core.Util.Create("Frame", {
            Name = "ProgressBar",
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
            Parent = props.Parent
        })
        
        self.Label = Core.Util.Create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = props.Text or "Progress",
            TextColor3 = self._theme.TextColor,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = self._theme.Font,
            TextSize = 14,
            Parent = self.Root
        })
        
        self.BarBg = Core.Util.Create("Frame", {
            Name = "BarBg",
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.new(0, 0, 0, 20),
            BackgroundColor3 = self._theme.Background2,
            BorderSizePixel = 0,
            Parent = self.Root
        })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = self.BarBg })
        Core.Util.Create("UIStroke", { Color = self._theme.Border, Thickness = 1, Parent = self.BarBg })
        
        self.Fill = Core.Util.Create("Frame", {
            Name = "Fill",
            Size = UDim2.fromScale(props.Value or 0, 1),
            BackgroundColor3 = self._theme.Accent,
            BorderSizePixel = 0,
            Parent = self.BarBg
        })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = self.Fill })
        
        self:_setupTooltip(self.Root)
        return self
    end
    
    function ProgressBar:SetProgress(val)
        val = math.clamp(val, 0, 1)
        Core.Util.Tween(self.Fill, { Size = UDim2.fromScale(val, 1) }, 0.2)
    end
    
    function ProgressBar:RefreshTheme()
        if self._destroyed then return end
        self.Label.TextColor3 = self._theme.TextColor
        self.BarBg.BackgroundColor3 = self._theme.Background2
        self.Fill.BackgroundColor3 = self._theme.Accent
        local stroke = self.BarBg:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = self._theme.Border end
    end

    -- Tabbox: nested mini-tab interface that lives inside any groupbox/section.
    -- Usage:
    --   local tabbox = group:AddTabbox()
    --   local tab1 = tabbox:AddTab("Tab 1")
    --   tab1:AddToggle(...)
    Tabbox = setmetatable({}, {__index = BaseComponent})
    Tabbox.__index = Tabbox
    function Tabbox.new(props)
        local self = BaseComponent.new({ Name = "Tabbox", Theme = props.Theme or Theme })
        setmetatable(self, Tabbox)
        self._components = {}
        self._tabs = {}
        self._currentTab = nil

        self.Root = Core.Util.Create("Frame", {
            Name = "Tabbox",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = props.Parent,
        })

        self.TabStrip = Core.Util.Create("Frame", {
            Name = "TabStrip",
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundColor3 = self._theme.Background2,
            BorderSizePixel = 0,
            Parent = self.Root,
        })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = self.TabStrip })
        Core.Util.Create("UIStroke", { Color = self._theme.Border, Thickness = 1, Parent = self.TabStrip })

        self.TabList = Core.Util.Create("Frame", {
            Name = "TabList",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Parent = self.TabStrip,
        })
        Core.Util.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2),
            Parent = self.TabList,
        })
        Core.Util.Create("UIPadding", {
            PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
            PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3),
            Parent = self.TabList,
        })

        self.Pages = Core.Util.Create("Frame", {
            Name = "Pages",
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.fromOffset(0, 28),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = self.Root,
        })

        return self
    end

    function Tabbox:AddTab(name)
        local tabbox = self
        local btn = Core.Util.Create("TextButton", {
            Name = name,
            Size = UDim2.fromOffset(0, 18),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = self._theme.Tab and self._theme.Tab.IdleFill or self._theme.Background,
            Text = name,
            TextColor3 = self._theme.Tab and self._theme.Tab.IdleText or self._theme.SubTextColor,
            Font = self._theme.Font,
            TextSize = 12,
            AutoButtonColor = false,
            Parent = self.TabList,
        })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = btn })
        Core.Util.Create("UIPadding", {
            PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
            Parent = btn,
        })

        local page = Core.Util.Create("Frame", {
            Name = name .. "Page",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Visible = false,
            Parent = self.Pages,
        })
        Core.Util.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = page })

        btn.InputBegan:Connect(function(input)
            if Core.Util.IsActivate(input.UserInputType) then tabbox:SelectTab(name) end
        end)

        local tab = { Name = name, Button = btn, Page = page, _tabbox = tabbox }
        function tab:GetParent() return self.Page end
        function tab:GetTheme() return self._tabbox._theme end
        function tab:GetComponentList() return self._tabbox._components end
        for k, v in pairs(ComponentMixin) do tab[k] = v end

        table.insert(self._tabs, tab)
        if #self._tabs == 1 then self:SelectTab(name) end
        return tab
    end

    function Tabbox:SelectTab(name)
        for _, tab in ipairs(self._tabs) do
            local active = (tab.Name == name)
            tab.Page.Visible = active
            local activeFill  = self._theme.Tab and self._theme.Tab.ActiveFill or self._theme.Accent
            local idleFill    = self._theme.Tab and self._theme.Tab.IdleFill  or self._theme.Background
            local activeText  = self._theme.Tab and self._theme.Tab.ActiveText or self._theme.TextColor
            local idleText    = self._theme.Tab and self._theme.Tab.IdleText   or self._theme.SubTextColor
            tab.Button.BackgroundColor3 = active and activeFill or idleFill
            tab.Button.TextColor3 = active and activeText or idleText
            if active then self._currentTab = tab end
        end
    end

    function Tabbox:RefreshTheme()
        if self._destroyed then return end
        self.TabStrip.BackgroundColor3 = self._theme.Background2
        local stroke = self.TabStrip:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = self._theme.Border end
        for _, tab in ipairs(self._tabs) do
            local active = (self._currentTab and self._currentTab.Name == tab.Name)
            local activeFill  = self._theme.Tab and self._theme.Tab.ActiveFill or self._theme.Accent
            local idleFill    = self._theme.Tab and self._theme.Tab.IdleFill  or self._theme.Background
            local activeText  = self._theme.Tab and self._theme.Tab.ActiveText or self._theme.TextColor
            local idleText    = self._theme.Tab and self._theme.Tab.IdleText   or self._theme.SubTextColor
            tab.Button.BackgroundColor3 = active and activeFill or idleFill
            tab.Button.TextColor3 = active and activeText or idleText
            tab.Button.Font = self._theme.Font
        end
        for _, comp in ipairs(self._components) do
            if comp.RefreshTheme then comp._theme = self._theme; comp:RefreshTheme() end
        end
    end

    function Tabbox:GetParent() return self.Pages end
    function Tabbox:GetTheme() return self._theme end
    function Tabbox:GetComponentList() return self._components end
    function Tabbox:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        if self._components then
            for _, comp in ipairs(self._components) do
                if comp and comp.Destroy and not comp._destroyed then
                    pcall(function() comp:Destroy() end)
                end
            end
            self._components = nil
        end
        if self.Root then self.Root:Destroy(); self.Root = nil end
    end
    for k, v in pairs(ComponentMixin) do Tabbox[k] = v end

    UI.Window = Window
    UI.Button = Button
    UI.Label = Label
    UI.Toggle = Toggle
    UI.Slider = Slider
    UI.TextInput = TextInput
    UI.Dropdown = Dropdown
    UI.MultiDropdown = MultiDropdown
    UI.Hotkey = Hotkey
    UI.ColorPicker = ColorPicker
    UI.Notification = Notification
    UI.Section = Section
    UI.ProgressBar = ProgressBar
    UI.KeybindList = KeybindListController
    UI.Tabbox = Tabbox
    UI.Separator = Separator
    UI.RadioGroup = RadioGroup
    UI.DataTable = DataTable
    UI.CodeBlock = CodeBlock

    function Window:GetParent() return (self._currentTab and self._currentTab.Page) or self.Content end
    function Window:GetTheme() return self._theme end
    function Window:GetComponentList() return self._components end
    
    for k, v in pairs(ComponentMixin) do Window[k] = v end

    return UI
end

-- Build UI with default theme
local Theme = Core.Theme
local UI = BuildUI(Theme)

-- Loading splash component
local LoadingSplash = {}
LoadingSplash.__index = LoadingSplash

function LoadingSplash.new(opts)
    opts = opts or {}
    local self = setmetatable({}, LoadingSplash)
    
    local modal = Core.Modal.Create(nil, Theme)
    self.ScreenGui = modal.ScreenGui
    self.Background = modal.Background
    self.Container = modal.Container
    
    self.Container.Size = UDim2.fromOffset(400, 200)
    Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Container })
    Core.Util.Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = self.Container })
    
    self.Title = Core.Util.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -32, 0, 40),
        Position = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Text = opts.Title or "",
        TextColor3 = Theme.Window.TitleText,
        Font = Theme.Font,
        TextSize = 24,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self.Container
    })
    
    self.Version = Core.Util.Create("TextLabel", {
        Name = "Version",
        Size = UDim2.new(1, -32, 0, 20),
        Position = UDim2.fromOffset(16, 56),
        BackgroundTransparency = 1,
        Text = "v" .. (opts.Version or ""),
        TextColor3 = Theme.Window.SubtitleText,
        Font = Theme.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self.Container
    })
    
    self.Status = Core.Util.Create("TextLabel", {
        Name = "Status",
        Size = UDim2.new(1, -32, 0, 20),
        Position = UDim2.fromOffset(16, 100),
        BackgroundTransparency = 1,
        Text = opts.Status or "Loading...",
        TextColor3 = Theme.TextColor,
        Font = Theme.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self.Container
    })
    
    local progressBg = Core.Util.Create("Frame", {
        Name = "ProgressBg",
        Size = UDim2.new(1, -64, 0, 4),
        Position = UDim2.fromOffset(32, 140),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = self.Container
    })
    Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = progressBg })
    
    self.ProgressBar = Core.Util.Create("Frame", {
        Name = "ProgressBar",
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = progressBg
    })
    Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = self.ProgressBar })
    
    self.Footer = Core.Util.Create("TextLabel", {
        Name = "Footer",
        Size = UDim2.new(1, -32, 0, 20),
        Position = UDim2.new(0, 16, 1, -36),
        BackgroundTransparency = 1,
        Text = opts.Footer or "Initializing components...",
        TextColor3 = Theme.Window.SubtitleText,
        Font = Theme.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self.Container
    })
    
    -- Apply FX if provided
    if opts.FX then
        self._fx = Core.FX.Apply(self.Container, opts.FX, Theme)
    end
    
    Core.Modal.AnimateIn(self, Theme)
    
    return self
end

function LoadingSplash:SetProgress(progress, status)
    if self.ProgressBar then
        TweenService:Create(self.ProgressBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(progress, 1)}):Play()
    end
    if status and self.Status then
        self.Status.Text = status
    end
end

function LoadingSplash:SetFooter(text)
    if self.Footer then
        self.Footer.Text = text
    end
end

function LoadingSplash:Close()
    Core.Modal.Close(self, function()
        if self._fx then
            for _, fx in pairs(self._fx) do
                if type(fx) == "table" and fx.Destroy then
                    pcall(function() fx.Destroy() end)
                end
            end
            self._fx = nil
        end
        self.ScreenGui = nil
    end)
end

-- Authorization modal
local Authorization = {}
Authorization.__index = Authorization

function Authorization.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Authorization)
    
    -- Callbacks stored as local upvalues, NOT on self.
    -- This prevents the common crack: `auth.ValidateCallback = function() return true end`
    local _validate    = opts.ValidateKey or function() return false end
    local _onSuccess   = opts.OnSuccess   or function() end
    local _onFail      = opts.OnFail      or function() end
    local _maxAttempts = math.max(1, tonumber(opts.MaxAttempts) or 5)
    local _attempts    = 0
    local _locked      = false

    local modal = Core.Modal.Create(nil, Theme)
    self.ScreenGui = modal.ScreenGui
    self.Background = modal.Background
    self.Container = modal.Container
    
    self.Container.Size = UDim2.fromOffset(400, 250)
    Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Container })
    Core.Util.Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = self.Container })
    
    -- Title
    Core.Util.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -32, 0, 40),
        Position = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Text = opts.Title or "AUTHORIZATION REQUIRED",
        TextColor3 = Theme.Window.TitleText,
        Font = Theme.Font,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self.Container
    })
    
    Core.Util.Create("TextLabel", {
        Name = "Subtitle",
        Size = UDim2.new(1, -32, 0, 40),
        Position = UDim2.fromOffset(16, 56),
        BackgroundTransparency = 1,
        Text = opts.Subtitle or "Enter your access key to continue",
        TextColor3 = Theme.Window.SubtitleText,
        Font = Theme.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self.Container
    })
    
    local inputBg = Core.Util.Create("Frame", {
        Name = "InputBg",
        Size = UDim2.new(1, -64, 0, 36),
        Position = UDim2.fromOffset(32, 110),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = self.Container
    })
    Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = inputBg })
    Core.Util.Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = inputBg })
    
    self.KeyInput = Core.Util.Create("TextBox", {
        Name = "KeyInput",
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Enter key...",
        PlaceholderColor3 = Theme.DisabledText,
        TextColor3 = Theme.TextColor,
        Font = Theme.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = inputBg
    })
    
    self.SubmitButton = Core.Util.Create("TextButton", {
        Name = "SubmitButton",
        Size = UDim2.new(1, -64, 0, 36),
        Position = UDim2.fromOffset(32, 160),
        BackgroundColor3 = Theme.Accent,
        Text = "SUBMIT",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Theme.Font,
        TextSize = 14,
        AutoButtonColor = false,
        Parent = self.Container
    })
    Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = self.SubmitButton })
    
    self.StatusLabel = Core.Util.Create("TextLabel", {
        Name = "StatusLabel",
        Size = UDim2.new(1, -32, 0, 20),
        Position = UDim2.new(0, 16, 1, -36),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Theme.Window.SubtitleText,
        Font = Theme.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self.Container
    })
    
    self.SubmitButton.MouseEnter:Connect(function()
        TweenService:Create(self.SubmitButton, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(
            math.min(255, Theme.Accent.R * 255 * 1.2),
            math.min(255, Theme.Accent.G * 255 * 1.2),
            math.min(255, Theme.Accent.B * 255 * 1.2)
        )}):Play()
    end)
    
    self.SubmitButton.MouseLeave:Connect(function()
        TweenService:Create(self.SubmitButton, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Accent}):Play()
    end)
    
    -- _doValidate is a local closure — not reachable via the returned object,
    -- so hookfunction on `Authorization:ValidateKey` or table-patching attacks fail.
    local _doValidate
    _doValidate = function()
        if _locked then return end

        local key = self.KeyInput and self.KeyInput.Text or ""
        key = key:match("^%s*(.-)%s*$") or key  -- trim whitespace

        if key == "" then
            self:SetStatus("Please enter a key", Color3.fromRGB(255, 100, 100))
            return
        end
        if #key > 256 then
            self:SetStatus("Invalid key", Color3.fromRGB(255, 100, 100))
            return
        end

        _attempts = _attempts + 1

        if _attempts > _maxAttempts then
            _locked = true
            self:SetStatus("Too many attempts. Access denied.", Color3.fromRGB(255, 60, 60))
            if self.SubmitButton then
                self.SubmitButton.Active = false
                self.SubmitButton.Text   = "LOCKED"
            end
            if self.KeyInput then self.KeyInput.TextEditable = false end
            task.delay(1.5, function() self:Close() end)
            return
        end

        if self.SubmitButton then self.SubmitButton.Text = "VALIDATING..." end
        if self.KeyInput then self.KeyInput.TextEditable = false end

        -- Exponential backoff: 0.4s → 0.8s → 1.6s → ... capped at 8s per failure.
        local _backoff = math.min(2 ^ (_attempts - 1) * 0.4, 8)

        -- _onResult handles both sync (bool return) and async (callback) validators.
        -- _called guard prevents double-firing if a buggy async validator calls twice.
        local _called = false
        local function _onResult(success)
            if _called then return end
            _called = true
            if not self.SubmitButton then return end

            if success then
                self:SetStatus("Access granted!", Color3.fromRGB(80, 255, 130))
                self.SubmitButton.Text = "✓"
                task.delay(0.6, function()
                    self:Close()
                    _onSuccess(key)
                end)
            else
                local remaining = _maxAttempts - _attempts
                if remaining <= 0 then
                    _locked = true
                    self:SetStatus("Too many attempts. Access denied.", Color3.fromRGB(255, 60, 60))
                    if self.SubmitButton then
                        self.SubmitButton.Active = false
                        self.SubmitButton.Text   = "LOCKED"
                    end
                    task.delay(1.5, function() self:Close() end)
                else
                    self:SetStatus("Invalid key — " .. remaining .. " attempt(s) remaining", Color3.fromRGB(255, 100, 100))
                    task.delay(_backoff, function()
                        if self.SubmitButton then self.SubmitButton.Text = "SUBMIT" end
                        if self.KeyInput then
                            self.KeyInput.TextEditable = true
                            self.KeyInput.Text = ""
                        end
                    end)
                    _onFail(key)
                end
            end
        end

        -- Call validator. Supports:
        --   sync:  ValidateKey = function(key) return bool end
        --   async: ValidateKey = function(key, callback) ... callback(bool) ... end
        local ok, result = pcall(_validate, key, _onResult)
        if not ok then
            _onResult(false)
        elseif result ~= nil then
            _onResult(result)  -- synchronous bool return
        end
        -- result == nil + no error → async, _onResult will be called by the validator
    end

    self.SubmitButton.MouseButton1Click:Connect(_doValidate)
    self.SubmitButton.InputBegan:Connect(function(input)
        if Core.Util.IsActivate(input.UserInputType) then _doValidate() end
    end)
    self.KeyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then _doValidate() end
    end)

    Core.Modal.AnimateIn(self, Theme)

    task.delay(0.6, function()
        if self.KeyInput then self.KeyInput:CaptureFocus() end
    end)

    return self
end

function Authorization:SetStatus(text, color)
    if self.StatusLabel then
        self.StatusLabel.Text = text
        if color then
            self.StatusLabel.TextColor3 = color
        end
    end
end

function Authorization:Close()
    Core.Modal.Close(self, function()
        self.ScreenGui = nil
    end)
end

-- Announcement modal
local Announcement = {}
Announcement.__index = Announcement

function Announcement.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Announcement)
    
    self.Callbacks = {}
    
    local theme = opts.Theme or Theme
    
    self.ScreenGui = Core.Util.Create("ScreenGui", {
        Name = Core.Safety.RandomString(16),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 20000,
        Parent = Core.Safety.GetRoot()
    })
    self.ScreenGui:SetAttribute("__g", true)
    Core.Safety.ProtectInstance(self.ScreenGui)
    
    self.Background = Core.Util.Create("Frame", {
        Name = "Background",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = theme.Overlays and theme.Overlays.Color or Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = theme.Overlays and theme.Overlays.Transparency or 0.3,
        BorderSizePixel = 0,
        Parent = self.ScreenGui
    })
    
    self.Container = Core.Util.Create("Frame", {
        Name = "Container",
        Size = UDim2.fromOffset(500, 300),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.Window.Background,
        BorderSizePixel = 0,
        Parent = self.Background
    })
    Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Container })
    Core.Util.Create("UIStroke", { Color = theme.Border, Thickness = 2, Parent = self.Container })
    
    local titleBar = Core.Util.Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Parent = self.Container
    })
    self.Title = Core.Util.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -32, 1, 0),
        Position = UDim2.fromOffset(16, 0),
        BackgroundTransparency = 1,
        Text = opts.Title or "ANNOUNCEMENT",
        TextColor3 = theme.Window.Background,  -- Contrasting color on accent
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = titleBar
    })

    -- Draggable title bar — delegate to the library's proven MakeDraggable helper.
    -- It captures the frame's relative position on mouse-down and applies deltas,
    -- so the container never snaps to the cursor regardless of AnchorPoint.
    self._modalDrag = Core.Behaviors.MakeDraggable(titleBar, self.Container)

    local messageContainer = Core.Util.Create("Frame", {
        Name = "MessageContainer",
        Size = UDim2.new(1, -32, 1, -130),
        Position = UDim2.fromOffset(16, 60),
        BackgroundTransparency = 1,
        Parent = self.Container
    })
    
    self.Message = Core.Util.Create("TextLabel", {
        Name = "Message",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = opts.Message or "This is an important announcement.",
        TextColor3 = Color3.fromRGB(255, 255, 255),  -- Bright white for visibility
        Font = theme.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = messageContainer
    })
    
    local buttonContainer = Core.Util.Create("Frame", {
        Name = "ButtonContainer",
        Size = UDim2.new(1, -32, 0, 50),
        Position = UDim2.new(0, 16, 1, -66),
        BackgroundTransparency = 1,
        Parent = self.Container
    })
    
    Core.Util.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = buttonContainer
    })
    
    local buttons = opts.Buttons or {{Text = "OK", Primary = true}}
    for i, buttonData in ipairs(buttons) do
        local button = Core.Util.Create("TextButton", {
            Name = "Button_" .. i,
            Size = UDim2.fromOffset(100, 40),
            BackgroundColor3 = buttonData.Primary and theme.Accent or theme.Background2,
            Text = buttonData.Text or "Button",
            TextColor3 = buttonData.Primary and theme.Window.Background or theme.TextColor,
            Font = buttonData.Primary and Enum.Font.GothamBold or theme.Font,
            TextSize = 14,
            LayoutOrder = i,
            BorderSizePixel = 0,
            Parent = buttonContainer
        })
        Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = button })
        
        if not buttonData.Primary then
            Core.Util.Create("UIStroke", { Color = theme.Border, Thickness = 1, Parent = button })
        end
        
        button.MouseEnter:Connect(function()
            if buttonData.Primary then
                TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(
                    math.min(255, theme.Accent.R * 255 * 1.2),
                    math.min(255, theme.Accent.G * 255 * 1.2),
                    math.min(255, theme.Accent.B * 255 * 1.2)
                )}):Play()
            else
                TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = theme.Background}):Play()
            end
        end)
        
        button.MouseLeave:Connect(function()
            if buttonData.Primary then
                TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = theme.Accent}):Play()
            else
                TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = theme.Background2}):Play()
            end
        end)
        
        button.InputBegan:Connect(function(input)
            if Core.Util.IsActivate(input.UserInputType) then
                if self._closing then return end
                self._closing = true
                button.Active = false
                button.AutoButtonColor = false
                self:Close()
                if buttonData.Callback then
                    task.spawn(function()
                        local ok, err = pcall(buttonData.Callback)
                        if not ok then warn("[Announcement] Button callback error:", err) end
                    end)
                end
            end
        end)
    end
    
    -- Apply FX if provided
    if opts.FX then
        self._fx = Core.FX.Apply(self.Container, opts.FX, theme)
    end
    
    self.Container.Size = UDim2.fromOffset(400, 250)
    self.Background.BackgroundTransparency = 1
    self.Container.BackgroundTransparency = 1
    
    for _, child in ipairs(self.Container:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            child.TextTransparency = 1
        elseif child:IsA("Frame") then
            -- Start transparent for fade-in; we'll restore selective targets below
            child.BackgroundTransparency = 1
        elseif child:IsA("UIStroke") then
            child.Transparency = 1
        end
    end
    
    TweenService:Create(self.Background, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        BackgroundTransparency = Theme.Overlays and Theme.Overlays.Transparency or 0.3
    }):Play()
    
    TweenService:Create(self.Container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(500, 300),
        BackgroundTransparency = 0
    }):Play()
    
    task.delay(0.2, function()
        for _, child in ipairs(self.Container:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
            elseif child:IsA("Frame") and child ~= self.Container then
                local targetTrans
                if child.Name == "TitleBar" then
                    targetTrans = 0
                elseif child.Name == "MessageContainer" or child.Name == "ButtonContainer" then
                    targetTrans = 1
                elseif child.Name == "GridBackground" or child.Name == "Scanlines" or child.Name == "TopSweep" or child.Name == "CornerBrackets" then
                    targetTrans = 1
                elseif child.Name == "VerticalLines" or child.Name == "HorizontalLines" then
                    targetTrans = 1
                else
                    targetTrans = 0
                end
                TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = targetTrans}):Play()
            elseif child:IsA("UIStroke") then
                TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Transparency = 0}):Play()
            end
        end
    end)
    
    return self
end

function Announcement:Close()
    if not self.ScreenGui or self._closed then return end
    self._closed = true
    if self._modalDrag then self._modalDrag.Destroy(); self._modalDrag = nil end

    local curSize = self.Container.AbsoluteSize
    local targetSize = UDim2.fromOffset(math.max(1, curSize.X * 0.92), math.max(1, curSize.Y * 0.92))

    local containerTween = TweenService:Create(self.Container, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = targetSize,
        BackgroundTransparency = 1
    })
    containerTween:Play()

    local bgTween = TweenService:Create(self.Background, TweenInfo.new(0.32, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 1
    })
    bgTween:Play()

    for _, child in ipairs(self.Container:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            TweenService:Create(child, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
        elseif child:IsA("UIStroke") then
            TweenService:Create(child, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {Transparency = 1}):Play()
        elseif child:IsA("Frame") and child ~= self.Container then
            TweenService:Create(child, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
        end
    end

    for _, child in ipairs(self.Container:GetDescendants()) do
        if child:IsA("TextButton") then
            child.Active = false
            child.AutoButtonColor = false
            child.Selectable = false
        end
    end

    task.delay(0.35, function()
        if self.Container then self.Container.Visible = false end
        if self.Background then self.Background.Visible = false end
    end)

    task.spawn(function()
        pcall(function() containerTween.Completed:Wait() end)
        pcall(function() bgTween.Completed:Wait() end)
        task.wait(0.02)
        if self.ScreenGui then
            self.ScreenGui:Destroy()
            self.ScreenGui = nil
        end
    end)

    task.delay(1.0, function()
        if self.ScreenGui then
            self.ScreenGui:Destroy()
            self.ScreenGui = nil
        end
    end)
end

-- Library API

-- Hot reload: Destroy existing instance if re-executing.
-- Use a random key so in-game ACs cannot detect by scanning getgenv() for known names.
local _getgenv = rawget(_G, 'getgenv')
local env = (type(_getgenv) == 'function' and _getgenv() ) or _G
local _envKey = Core.Safety.RandomString(16)
-- Check for a previously loaded instance using the hidden marker key.
local _markerKey = "__lib_loaded"
if env[_markerKey] then
    local prev = env[env[_markerKey]]
    if prev and prev.Unload then
        pcall(function() prev:Unload() end)
    end
    env[env[_markerKey]] = nil
    env[_markerKey] = nil
end

local Library = {
    Version = Core.Version,
    Core = Core,
    Theme = Theme,
    UI = UI,
    Windows = {},
}

-- Store under random key; leave only the marker (also a random key per-load) pointing to it.
env[_envKey] = Library
env[_markerKey] = _envKey

function Library:GetExecutorInfo()
    return Core.Safety.getExecutorInfo()
end

function Library:HasSecureTable()
    return Core.Safety.hasSecureTable()
end

function Library:CreateSecureTable(arraySize, hashSize)
    return Core.Safety.createSecureTable(arraySize, hashSize)
end

function Library:CreateWindow(opts)
    opts = opts or {}
    -- [FIX] Use self.Theme (Library.Theme) to ensure we use the current theme state
    -- This handles cases where ThemeManager updates Library.Theme
    local theme = opts.Theme or self.Theme
    local window = UI.Window.new({
        Name = opts.Name,
        Theme = theme,
        Title = opts.Title or "",
        SubTitle = opts.SubTitle,
        Size = opts.Size,
        Width = opts.Width,
        Height = opts.Height,
        DockThreshold = opts.DockThreshold,  -- Optional: width threshold for auto-dock (default 450)
        DockWidth = opts.DockWidth,          -- Optional: dock panel width (default 150)
    })
    table.insert(self.Windows, window)
    return window
end

function Library:Notify(opts)
    return UI.Notification.new({
        Theme = Core.Theme,
        Title = opts.Title,
        Text = opts.Text,
        Duration = opts.Duration,
        Position = opts.Position,
        FX = opts.FX,
    })
end

-- Keybind overlay — shows the compact always-visible keybind list HUD.
function Library:ShowKeybindOverlay()
    UI.KeybindList:SetVisible(true)
end
function Library:HideKeybindOverlay()
    UI.KeybindList:SetVisible(false)
end
function Library:ToggleKeybindOverlay()
    UI.KeybindList:SetVisible(not UI.KeybindList.Visible)
end

-- Watermark HUD — a small draggable label showing script name + version.
-- opts.Text     = string  (e.g. "MyScript v1.0")
-- opts.Position = UDim2   (optional, defaults to top-right)
-- opts.Theme    = theme table (optional)
-- Returns { SetText(str), SetVisible(bool), Destroy() }
function Library:CreateWatermark(opts)
    opts = opts or {}
    local theme = opts.Theme or self.Theme

    local gui = Core.Util.Create("ScreenGui", {
        Name = Core.Safety.RandomString(16),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 5000,
        Parent = Core.Safety.GetRoot(),
    })
    gui:SetAttribute("__g", true)
    Core.Safety.ProtectInstance(gui)

    local frame = Core.Util.Create("Frame", {
        Name = "Watermark",
        Size = UDim2.fromOffset(0, 26),
        AutomaticSize = Enum.AutomaticSize.X,
        Position = opts.Position or UDim2.new(1, -10, 0, 10),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = theme.Background2,
        BorderSizePixel = 0,
        Parent = gui,
    })
    Core.Util.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = frame })
    Core.Util.Create("UIStroke", { Color = theme.Border, Thickness = 1, Parent = frame })
    Core.Util.Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
        Parent = frame,
    })

    local label = Core.Util.Create("TextLabel", {
        Name = "Text",
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = opts.Text or "",
        TextColor3 = theme.TextColor,
        Font = theme.Font,
        TextSize = 13,
        Parent = frame,
    })

    Core.Behaviors.MakeDraggable(frame, frame)

    local wm = { _gui = gui, _frame = frame, _label = label }
    function wm:SetText(text) self._label.Text = text end
    function wm:SetVisible(v) self._frame.Visible = v end
    function wm:Destroy()
        if self._gui then self._gui:Destroy(); self._gui = nil end
    end
    return wm
end

function Library:ShowLoadingSplash(opts)
    opts = opts or {}
    return LoadingSplash.new({
        Title = opts.Title or "",
        Version = opts.Version or "",
        Status = opts.Status or "Loading...",
        Footer = opts.Footer or "Initializing components...",
        FX = opts.FX,
    })
end

function Library:RequestAuth(opts)
    opts = opts or {}
    return Authorization.new({
        Title = opts.Title,
        Subtitle = opts.Subtitle,
        ValidateKey = opts.ValidateKey,
        OnSuccess = opts.OnSuccess,
        OnFail = opts.OnFail,
        MaxAttempts = opts.MaxAttempts,
    })
end

function Library:ShowAnnouncement(opts)
    opts = opts or {}
    return Announcement.new({
        Title = opts.Title,
        Message = opts.Message,
        Buttons = opts.Buttons,
        FX = opts.FX,
        Theme = self.Theme,
    })
end

function Library:RefreshAll()
    for _, window in ipairs(self.Windows) do
        window._theme = self.Theme
        if window.RefreshTheme then window:RefreshTheme() end
        if window._components then
            for _, comp in ipairs(window._components) do
                if comp and comp.RefreshTheme then
                    comp._theme = self.Theme
                    comp:RefreshTheme()
                end
            end
        end
    end
end

function Library:Unload()
    for _, window in ipairs(self.Windows) do
        if window and window.Destroy then
            window:Destroy()
        end
    end
    
    self.Windows = {}
    
    local root = Core.Safety.GetRoot()
    pcall(function()
        for _, child in ipairs(root:GetChildren()) do
            if child:IsA("ScreenGui") and child:GetAttribute("__g") == true then
                child:Destroy()
            end
        end
    end)
end

return Library
