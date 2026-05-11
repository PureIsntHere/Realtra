--!nocheck

return function()
    local ThemeManager = {}
    ThemeManager.Library = nil
    ThemeManager.Presets = {}

    local HttpService = game:GetService('HttpService')

    function ThemeManager:SetLibrary(Library)
        self.Library = Library
        return self
    end

    local function clamp01(x)
        if x < 0 then return 0 elseif x > 1 then return 1 else return x end
    end
    local function rgb(hex)
        hex = hex:gsub('#','')
        local r = tonumber(hex:sub(1,2), 16)
        local g = tonumber(hex:sub(3,4), 16)
        local b = tonumber(hex:sub(5,6), 16)
        return Color3.fromRGB(r, g, b)
    end
    local function lighten(color, pct)
        local r, g, b = color.R, color.G, color.B
        return Color3.new(clamp01(r + (1 - r) * pct), clamp01(g + (1 - g) * pct), clamp01(b + (1 - b) * pct))
    end
    local function darken(color, pct)
        local r, g, b = color.R, color.G, color.B
        return Color3.new(clamp01(r * (1 - pct)), clamp01(g * (1 - pct)), clamp01(b * (1 - pct)))
    end

    local function deepCopy(tbl)
        if type(tbl) ~= "table" then return tbl end
        local seen = {}
        local function _copy(t)
            if type(t) ~= 'table' then return t end
            if seen[t] then return seen[t] end
            local out = {}
            seen[t] = out
            for k, v in pairs(t) do
                out[k] = (type(v) == 'table') and _copy(v) or v
            end
            return out
        end
        return _copy(tbl)
    end

    local function merge(into, from)
        if type(into) ~= 'table' or type(from) ~= 'table' then return into end
        for k, v in pairs(from) do
            if type(v) == 'table' then
                if type(into[k]) ~= 'table' then into[k] = {} end
                for kk, vv in pairs(v) do into[k][kk] = vv end
            else
                into[k] = v
            end
        end
        return into
    end

    local function buildTheme(p)
        local bg = p.bg; local bg2 = p.bg2 or darken(bg, 0.08)
        local bg3 = p.bg3 or darken(bg2, 0.08)
        local text = p.text
        local sub = p.sub or lighten(text, -0.25)
        local disabled = p.disabled or lighten(sub, -0.15)
        local accent = p.accent
        local accentDim = p.accentDim or darken(accent, 0.35)
        local border = p.border or darken(bg, 0.4)
        local bracket = p.bracket or lighten(border, 0.35)
        local fx = p.fx or {}
        return {
            Background = bg,
            Background2 = bg2,
            Background3 = bg3,
            TextColor = text,
            SubTextColor = sub,
            DisabledText = disabled,
            Accent = accent,
            AccentDim = accentDim,
            Border = border,
            Window = {
                Background = bg,
                TitleText = text,
                SubtitleText = sub,
                Border = border,
                CornerBrackets = bracket,
            },
            Tab = {
                IdleFill = bg2,
                ActiveFill = bg,
                IdleText = sub,
                ActiveText = text,
                Border = border,
            },
            FX = {
                CornerBrackets = bracket,
                ScanlineColor = fx.ScanlineColor or text,
                ScanlineTransparency = fx.ScanlineTransparency or 0.85,
                ScanlineSpeed = fx.ScanlineSpeed or 60,
                TopSweepColor = fx.TopSweepColor or bracket,
                TopSweepThickness = fx.TopSweepThickness or 2,
                TopSweepSpeed = fx.TopSweepSpeed or 180,
                TopSweepGap = fx.TopSweepGap or 26,
                TopSweepLength = fx.TopSweepLength or 120,
                GridColor = fx.GridColor or (p.grid or border),
                GridAlpha = fx.GridAlpha or 0.06,
                GridGap = fx.GridGap or 16,
            }
        }
    end

    ThemeManager.Presets = {
        ["Rose Pine"] = buildTheme({ 
            bg = rgb('#191724'), 
            bg2 = rgb('#1F1D2E'), 
            bg3 = rgb('#26233A'),
            text = rgb('#E0DEF4'), 
            sub = rgb('#908CAA'), 
            disabled = rgb('#6E6A86'),
            accent = rgb('#C4A7E7'), 
            accentDim = rgb('#9CCFD8'),
            border = rgb('#26233A'),
            bracket = rgb('#403D52'),
            fx = {
                ScanlineColor = rgb('#EBBCBA'),
                ScanlineTransparency = 0.85,
                ScanlineSpeed = 60,
                TopSweepColor = rgb('#C4A7E7'),
                TopSweepThickness = 2,
                TopSweepSpeed = 180,
                TopSweepGap = 24,
                TopSweepLength = 120,
                GridColor = rgb('#26233A'),
                GridAlpha = 0.06,
                GridGap = 16
            }
        }),

        ["Cyberpunk"] = buildTheme({
            bg = rgb('#050505'),
            bg2 = rgb('#0a0a0a'),
            bg3 = rgb('#141414'),
            text = rgb('#00f3ff'),
            sub = rgb('#ff0099'),
            disabled = rgb('#3d3d3d'),
            accent = rgb('#fcee0a'),
            accentDim = rgb('#b8ad06'),
            border = rgb('#00f3ff'),
            bracket = rgb('#ff0099'),
            fx = {
                ScanlineColor = rgb('#00f3ff'),
                ScanlineTransparency = 0.8,
                ScanlineSpeed = 100,
                TopSweepColor = rgb('#fcee0a'),
                TopSweepThickness = 3,
                TopSweepSpeed = 250,
                TopSweepGap = 40,
                TopSweepLength = 200,
                GridColor = rgb('#ff0099'),
                GridAlpha = 0.15,
                GridGap = 24
            }
        }),

        ["Vaporwave"] = buildTheme({
            bg = rgb('#241b2f'),
            bg2 = rgb('#2b213a'),
            bg3 = rgb('#1a1324'),
            text = rgb('#01cdfe'),
            sub = rgb('#b967ff'),
            disabled = rgb('#6d5a7a'),
            accent = rgb('#ff71ce'),
            accentDim = rgb('#b967ff'),
            border = rgb('#05ffa1'),
            bracket = rgb('#fffb96'),
            fx = {
                ScanlineColor = rgb('#ff71ce'),
                ScanlineTransparency = 0.85,
                ScanlineSpeed = 40,
                TopSweepColor = rgb('#01cdfe'),
                TopSweepThickness = 2,
                TopSweepSpeed = 120,
                TopSweepGap = 20,
                TopSweepLength = 150,
                GridColor = rgb('#05ffa1'),
                GridAlpha = 0.1,
                GridGap = 30
            }
        }),

        ["Forest"] = buildTheme({
            bg = rgb('#1e2622'),
            bg2 = rgb('#26302b'),
            bg3 = rgb('#2e3a34'),
            text = rgb('#d3c6aa'),
            sub = rgb('#9da9a0'),
            disabled = rgb('#5a665e'),
            accent = rgb('#a7c080'),
            accentDim = rgb('#839c62'),
            border = rgb('#3c4841'),
            bracket = rgb('#4f5b54'),
            fx = {
                ScanlineColor = rgb('#a7c080'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 30,
                TopSweepColor = rgb('#d3c6aa'),
                TopSweepThickness = 3,
                TopSweepSpeed = 80,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#3c4841'),
                GridAlpha = 0.05,
                GridGap = 20
            }
        }),

        ["Crimson"] = buildTheme({
            bg = rgb('#1a0b0c'),
            bg2 = rgb('#241011'),
            bg3 = rgb('#2e1517'),
            text = rgb('#ffb3b3'),
            sub = rgb('#cc8080'),
            disabled = rgb('#804d4d'),
            accent = rgb('#ff3333'),
            accentDim = rgb('#cc0000'),
            border = rgb('#4d1a1a'),
            bracket = rgb('#802b2b'),
            fx = {
                ScanlineColor = rgb('#ff0000'),
                ScanlineTransparency = 0.8,
                ScanlineSpeed = 90,
                TopSweepColor = rgb('#ff3333'),
                TopSweepThickness = 2,
                TopSweepSpeed = 200,
                TopSweepGap = 15,
                TopSweepLength = 180,
                GridColor = rgb('#4d1a1a'),
                GridAlpha = 0.1,
                GridGap = 12
            }
        }),

        ["Azure"] = buildTheme({
            bg = rgb('#0f172a'),
            bg2 = rgb('#1e293b'),
            bg3 = rgb('#334155'),
            text = rgb('#e2e8f0'),
            sub = rgb('#94a3b8'),
            disabled = rgb('#475569'),
            accent = rgb('#38bdf8'),
            accentDim = rgb('#0ea5e9'),
            border = rgb('#1e293b'),
            bracket = rgb('#0f172a'),
            fx = {
                ScanlineColor = rgb('#7dd3fc'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 45,
                TopSweepColor = rgb('#38bdf8'),
                TopSweepThickness = 2,
                TopSweepSpeed = 140,
                TopSweepGap = 30,
                TopSweepLength = 120,
                GridColor = rgb('#1e293b'),
                GridAlpha = 0.05,
                GridGap = 24
            }
        }),

        ["Cream"] = buildTheme({
            bg = rgb('#fffdf5'),
            bg2 = rgb('#f5f0e1'),
            bg3 = rgb('#ebe5ce'),
            text = rgb('#5c5346'),
            sub = rgb('#8f8576'),
            disabled = rgb('#c2b9ac'),
            accent = rgb('#ffb86c'),
            accentDim = rgb('#e09f55'),
            border = rgb('#e6dec8'),
            bracket = rgb('#d4cbb3'),
            fx = {
                ScanlineColor = rgb('#ffb86c'),
                ScanlineTransparency = 0.95,
                ScanlineSpeed = 20,
                TopSweepColor = rgb('#5c5346'),
                TopSweepThickness = 3,
                TopSweepSpeed = 60,
                TopSweepGap = 60,
                TopSweepLength = 80,
                GridColor = rgb('#e6dec8'),
                GridAlpha = 0.03,
                GridGap = 32
            }
        }),

        ["Void"] = buildTheme({
            bg = rgb('#000000'),
            bg2 = rgb('#0a0a0a'),
            bg3 = rgb('#141414'),
            text = rgb('#ffffff'),
            sub = rgb('#808080'),
            disabled = rgb('#404040'),
            accent = rgb('#ffffff'),
            accentDim = rgb('#cccccc'),
            border = rgb('#333333'),
            bracket = rgb('#ffffff'),
            fx = {
                ScanlineColor = rgb('#ffffff'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#ffffff'),
                TopSweepThickness = 3,
                TopSweepSpeed = 100,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#333333'),
                GridAlpha = 0.1,
                GridGap = 40
            }
        }),

        ["Void - Red"] = buildTheme({
            bg = rgb('#000000'),
            bg2 = rgb('#0a0a0a'),
            bg3 = rgb('#141414'),
            text = rgb('#ffffff'),
            sub = rgb('#808080'),
            disabled = rgb('#404040'),
            accent = rgb('#ff3333'),
            accentDim = rgb('#cc0000'),
            border = rgb('#333333'),
            bracket = rgb('#ff3333'),
            fx = {
                ScanlineColor = rgb('#ff3333'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#ff3333'),
                TopSweepThickness = 3,
                TopSweepSpeed = 100,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#333333'),
                GridAlpha = 0.1,
                GridGap = 40
            }
        }),

        ["Void - Cyan"] = buildTheme({
            bg = rgb('#000000'),
            bg2 = rgb('#0a0a0a'),
            bg3 = rgb('#141414'),
            text = rgb('#ffffff'),
            sub = rgb('#808080'),
            disabled = rgb('#404040'),
            accent = rgb('#00ffff'),
            accentDim = rgb('#00cccc'),
            border = rgb('#333333'),
            bracket = rgb('#00ffff'),
            fx = {
                ScanlineColor = rgb('#00ffff'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#00ffff'),
                TopSweepThickness = 3,
                TopSweepSpeed = 100,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#333333'),
                GridAlpha = 0.1,
                GridGap = 40
            }
        }),

        ["Void - Pink"] = buildTheme({
            bg = rgb('#000000'),
            bg2 = rgb('#0a0a0a'),
            bg3 = rgb('#141414'),
            text = rgb('#ffffff'),
            sub = rgb('#808080'),
            disabled = rgb('#404040'),
            accent = rgb('#ff66aa'),
            accentDim = rgb('#cc4488'),
            border = rgb('#333333'),
            bracket = rgb('#ff66aa'),
            fx = {
                ScanlineColor = rgb('#ff66aa'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#ff66aa'),
                TopSweepThickness = 3,
                TopSweepSpeed = 100,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#333333'),
                GridAlpha = 0.1,
                GridGap = 40
            }
        }),

        ["Void - Magenta"] = buildTheme({
            bg = rgb('#000000'),
            bg2 = rgb('#0a0a0a'),
            bg3 = rgb('#141414'),
            text = rgb('#ffffff'),
            sub = rgb('#808080'),
            disabled = rgb('#404040'),
            accent = rgb('#ff00ff'),
            accentDim = rgb('#cc00cc'),
            border = rgb('#333333'),
            bracket = rgb('#ff00ff'),
            fx = {
                ScanlineColor = rgb('#ff00ff'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#ff00ff'),
                TopSweepThickness = 3,
                TopSweepSpeed = 100,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#333333'),
                GridAlpha = 0.1,
                GridGap = 40
            }
        }),

        ["Pastel"] = buildTheme({
            bg = rgb('#202020'),
            bg2 = rgb('#2a2a2a'),
            bg3 = rgb('#303030'),
            text = rgb('#e1f7d5'),
            sub = rgb('#c9c9ff'),
            disabled = rgb('#aaaaaa'),
            accent = rgb('#ffbdbd'),
            accentDim = rgb('#f1cbff'),
            border = rgb('#c9c9ff'),
            bracket = rgb('#f1cbff'),
            fx = {
                ScanlineColor = rgb('#ffbdbd'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#c9c9ff'),
                TopSweepThickness = 3,
                TopSweepSpeed = 100,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#e1f7d5'),
                GridAlpha = 0.1,
                GridGap = 40
            }
        }),

        ["Retro"] = buildTheme({
            bg = rgb('#666547'),
            bg2 = rgb('#55543b'),
            bg3 = rgb('#44432f'),
            text = rgb('#fffeb3'),
            sub = rgb('#ffe28a'),
            disabled = rgb('#aaaaaa'),
            accent = rgb('#fb2e01'),
            accentDim = rgb('#d92500'),
            border = rgb('#6fcb9f'),
            bracket = rgb('#ffe28a'),
            fx = {
                ScanlineColor = rgb('#fb2e01'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#ffe28a'),
                TopSweepThickness = 3,
                TopSweepSpeed = 100,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#6fcb9f'),
                GridAlpha = 0.1,
                GridGap = 40
            }
        }),

        ["Cappuccino"] = buildTheme({
            bg = rgb('#3c2f2f'),
            bg2 = rgb('#4b3832'),
            bg3 = rgb('#5a433c'),
            text = rgb('#fff4e6'),
            sub = rgb('#be9b7b'),
            disabled = rgb('#854442'),
            accent = rgb('#be9b7b'),
            accentDim = rgb('#854442'),
            border = rgb('#4b3832'),
            bracket = rgb('#fff4e6'),
            fx = {
                ScanlineColor = rgb('#be9b7b'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#fff4e6'),
                TopSweepThickness = 3,
                TopSweepSpeed = 100,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#854442'),
                GridAlpha = 0.1,
                GridGap = 40
            }
        }),

        ["Beautiful Blues"] = buildTheme({
            bg = rgb('#011f4b'),
            bg2 = rgb('#03396c'),
            bg3 = rgb('#005b96'),
            text = rgb('#b3cde0'),
            sub = rgb('#6497b1'),
            disabled = rgb('#005b96'),
            accent = rgb('#005b96'),
            accentDim = rgb('#03396c'),
            border = rgb('#03396c'),
            bracket = rgb('#6497b1'),
            fx = {
                ScanlineColor = rgb('#6497b1'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#b3cde0'),
                TopSweepThickness = 3,
                TopSweepSpeed = 100,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#005b96'),
                GridAlpha = 0.1,
                GridGap = 40
            }
        }),

        ["Shades of Teal"] = buildTheme({
            bg = rgb('#004c4c'),
            bg2 = rgb('#006666'),
            bg3 = rgb('#008080'),
            text = rgb('#b2d8d8'),
            sub = rgb('#66b2b2'),
            disabled = rgb('#006666'),
            accent = rgb('#008080'),
            accentDim = rgb('#006666'),
            border = rgb('#006666'),
            bracket = rgb('#66b2b2'),
            fx = {
                ScanlineColor = rgb('#66b2b2'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#b2d8d8'),
                TopSweepThickness = 3,
                TopSweepSpeed = 100,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#008080'),
                GridAlpha = 0.1,
                GridGap = 40
            }
        }),

        ["DownTown"] = buildTheme({
            bg = rgb('#373854'),
            bg2 = rgb('#493267'),
            bg3 = rgb('#2e2f45'),
            text = rgb('#e86af0'),
            sub = rgb('#7bb3ff'),
            disabled = rgb('#9e379f'),
            accent = rgb('#9e379f'),
            accentDim = rgb('#7a2b7b'),
            border = rgb('#7bb3ff'),
            bracket = rgb('#e86af0'),
            fx = {
                ScanlineColor = rgb('#e86af0'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#7bb3ff'),
                TopSweepThickness = 3,
                TopSweepSpeed = 100,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#9e379f'),
                GridAlpha = 0.1,
                GridGap = 40
            }
        }),

        ["Slytherin"] = buildTheme({
            bg = rgb('#1a472a'),
            bg2 = rgb('#2a623d'),
            bg3 = rgb('#0f2b19'),
            text = rgb('#aaaaaa'),
            sub = rgb('#5d5d5d'),
            disabled = rgb('#404040'),
            accent = rgb('#aaaaaa'),
            accentDim = rgb('#888888'),
            border = rgb('#000000'),
            bracket = rgb('#aaaaaa'),
            fx = {
                ScanlineColor = rgb('#aaaaaa'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#2a623d'),
                TopSweepThickness = 3,
                TopSweepSpeed = 100,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#000000'),
                GridAlpha = 0.2,
                GridGap = 40
            }
        }),

        ["Discord"] = buildTheme({
            bg = rgb('#23272a'),
            bg2 = rgb('#2c2f33'),
            bg3 = rgb('#202225'),
            text = rgb('#ffffff'),
            sub = rgb('#99aab5'),
            disabled = rgb('#4f545c'),
            accent = rgb('#7289da'),
            accentDim = rgb('#5b6dce'),
            border = rgb('#202225'),
            bracket = rgb('#7289da'),
            fx = {
                ScanlineColor = rgb('#7289da'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#99aab5'),
                TopSweepThickness = 3,
                TopSweepSpeed = 100,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#202225'),
                GridAlpha = 0.1,
                GridGap = 40
            }
        }),

        ["Gryffindor"] = buildTheme({
            bg = rgb('#740001'),
            bg2 = rgb('#ae0001'),
            bg3 = rgb('#4d0001'),
            text = rgb('#eeba30'),
            sub = rgb('#d3a625'),
            disabled = rgb('#800000'),
            accent = rgb('#eeba30'),
            accentDim = rgb('#d3a625'),
            border = rgb('#000000'),
            bracket = rgb('#eeba30'),
            fx = {
                ScanlineColor = rgb('#eeba30'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#ae0001'),
                TopSweepThickness = 3,
                TopSweepSpeed = 100,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#000000'),
                GridAlpha = 0.2,
                GridGap = 40
            }
        }),

        ["RavenClaw"] = buildTheme({
            bg = rgb('#0e1a40'),
            bg2 = rgb('#222f5b'),
            bg3 = rgb('#070d20'),
            text = rgb('#946b2d'),
            sub = rgb('#5d5d5d'),
            disabled = rgb('#333333'),
            accent = rgb('#946b2d'),
            accentDim = rgb('#7a5825'),
            border = rgb('#000000'),
            bracket = rgb('#946b2d'),
            fx = {
                ScanlineColor = rgb('#946b2d'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#222f5b'),
                TopSweepThickness = 3,
                TopSweepSpeed = 100,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#000000'),
                GridAlpha = 0.2,
                GridGap = 40
            }
        }),

        ["Carlos&Cruella"] = buildTheme({
            bg = rgb('#201a1a'),
            bg2 = rgb('#2a2222'),
            bg3 = rgb('#352b2b'),
            text = rgb('#ffffff'),
            sub = rgb('#bbbbbb'),
            disabled = rgb('#aaaaaa'),
            accent = rgb('#b80202'),
            accentDim = rgb('#8a0202'),
            border = rgb('#403333'),
            bracket = rgb('#b80202'),
            fx = {
                ScanlineColor = rgb('#b80202'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 50,
                TopSweepColor = rgb('#b80202'),
                TopSweepThickness = 3,
                TopSweepSpeed = 100,
                TopSweepGap = 50,
                TopSweepLength = 100,
                GridColor = rgb('#403333'),
                GridAlpha = 0.1,
                GridGap = 40
            }
        }),

        ["Amethyst"] = buildTheme({
            bg = rgb('#190e24'),
            bg2 = rgb('#241633'),
            bg3 = rgb('#301e42'),
            text = rgb('#ede0ff'),
            sub = rgb('#bda3d9'),
            disabled = rgb('#7a668f'),
            accent = rgb('#a366ff'),
            accentDim = rgb('#7a33cc'),
            border = rgb('#3d2657'),
            bracket = rgb('#5c3a82'),
            fx = {
                ScanlineColor = rgb('#d9b3ff'),
                ScanlineTransparency = 0.88,
                ScanlineSpeed = 55,
                TopSweepColor = rgb('#a366ff'),
                TopSweepThickness = 2,
                TopSweepSpeed = 160,
                TopSweepGap = 28,
                TopSweepLength = 130,
                GridColor = rgb('#3d2657'),
                GridAlpha = 0.07,
                GridGap = 18
            }
        }),

        ["Slate"] = buildTheme({
            bg = rgb('#1a1c21'),
            bg2 = rgb('#23262e'),
            bg3 = rgb('#2c303b'),
            text = rgb('#dcdfe6'),
            sub = rgb('#909399'),
            disabled = rgb('#606266'),
            accent = rgb('#409eff'),
            accentDim = rgb('#3a8ee6'),
            border = rgb('#363b45'),
            bracket = rgb('#4c525e'),
            fx = {
                ScanlineColor = rgb('#909399'),
                ScanlineTransparency = 0.92,
                ScanlineSpeed = 35,
                TopSweepColor = rgb('#409eff'),
                TopSweepThickness = 3,
                TopSweepSpeed = 130,
                TopSweepGap = 35,
                TopSweepLength = 110,
                GridColor = rgb('#363b45'),
                GridAlpha = 0.04,
                GridGap = 22
            }
        }),

        ["Dracula"] = buildTheme({ 
            bg = rgb('#282A36'), 
            bg2 = rgb('#44475A'), 
            bg3 = rgb('#21222C'),
            text = rgb('#F8F8F2'), 
            sub = rgb('#6272A4'), 
            disabled = rgb('#6272A4'),
            accent = rgb('#BD93F9'), 
            accentDim = rgb('#FF79C6'), 
            border = rgb('#6272A4'),
            bracket = rgb('#FF79C6'),
            fx = {
                ScanlineColor = rgb('#BD93F9'),
                ScanlineTransparency = 0.9,
                ScanlineSpeed = 60,
                TopSweepColor = rgb('#FF79C6'),
                TopSweepThickness = 2,
                TopSweepSpeed = 180,
                TopSweepGap = 30,
                TopSweepLength = 140,
                GridColor = rgb('#6272A4'),
                GridAlpha = 0.1,
                GridGap = 20
            }
        }),

        ["Solarized Light"] = buildTheme({ 
            bg = rgb('#FDF6E3'), 
            bg2 = rgb('#EEE8D5'), 
            bg3 = rgb('#F7F0DD'),
            text = rgb('#073642'), 
            sub = rgb('#586E75'), 
            disabled = rgb('#657B83'),
            accent = rgb('#268BD2'), 
            accentDim = rgb('#D33682'),
            border = rgb('#93A1A1'),
            bracket = rgb('#839496'),
            fx = {
                ScanlineColor = rgb('#CB4B16'),
                ScanlineTransparency = 0.90,
                ScanlineSpeed = 40,
                TopSweepColor = rgb('#268BD2'),
                TopSweepThickness = 3,
                TopSweepSpeed = 120,
                TopSweepGap = 20,
                TopSweepLength = 100,
                GridColor = rgb('#93A1A1'),
                GridAlpha = 0.03,
                GridGap = 26
            }
        }),
    }

    function ThemeManager:SetTheme(theme)
        assert(self.Library, "ThemeManager: Library not set; call SetLibrary first")
        if type(theme) == "string" then
            local preset = self:GetTheme(theme)
            assert(preset, ("ThemeManager: theme '%s' not found"):format(theme))
            theme = preset
        end
        merge(self.Library.Theme, theme or {})
        if self.Library.RefreshAll then
            self.Library:RefreshAll()
        end
    end

    function ThemeManager:GetTheme(name)
        local preset = self.Presets[name]
        if not preset then return nil end
        return deepCopy(preset)
    end

    function ThemeManager:ListThemes()
        local names = {}
        for k in pairs(self.Presets) do table.insert(names, k) end
        table.sort(names)
        return names
    end

    function ThemeManager:ApplyToWindow(window)
        assert(self.Library, "ThemeManager: Library not set; call SetLibrary first")
        if not window then return end
        window._theme = self.Library.Theme
        if window.RefreshTheme then window:RefreshTheme() end
        if window._components then
            for _, comp in ipairs(window._components) do
                if comp and comp.RefreshTheme then
                    comp._theme = self.Library.Theme
                    comp:RefreshTheme()
                end
            end
        end
    end

    function ThemeManager:SaveToJSON()
        assert(self.Library, "ThemeManager: Library not set; call SetLibrary first")
        return HttpService:JSONEncode(self.Library.Theme)
    end

    function ThemeManager:LoadFromJSON(json)
        assert(self.Library, "ThemeManager: Library not set; call SetLibrary first")
        local ok, decoded = pcall(HttpService.JSONDecode, HttpService, json)
        if ok and type(decoded) == 'table' then
            self:SetTheme(decoded)
            return true
        end
        return false
    end

    function ThemeManager:CreateThemeManager(group)
        assert(self.Library, "ThemeManager: Library not set; call SetLibrary first")
        
        group:AddDropdown({
            Text = "Theme",
            Options = self:ListThemes(),
            Default = "Rose Pine",
            Callback = function(val)
                self:SetTheme(val)
            end
        })
        
        if group.AddSection then
            local colors = group:AddSection({ Text = "Colors" })
            
            local function add(name, key)
                colors:AddColorPicker({
                    Text = name,
                    Default = self.Library.Theme[key],
                    Callback = function(color)
                        self.Library.Theme[key] = color
                        if self.Library.RefreshAll then self.Library:RefreshAll() end
                    end
                })
            end
            
            add("Background", "Background")
            add("Background 2", "Background2")
            add("Text Color", "TextColor")
            add("Sub Text", "SubTextColor")
            add("Accent", "Accent")
            add("Border", "Border")
            
            local window = group:AddSection({ Text = "Window" })
            local function addW(name, key)
                window:AddColorPicker({
                    Text = name,
                    Default = self.Library.Theme.Window[key],
                    Callback = function(color)
                        self.Library.Theme.Window[key] = color
                        if self.Library.RefreshAll then self.Library:RefreshAll() end
                    end
                })
            end
            addW("Title Text", "TitleText")
            addW("Subtitle Text", "SubtitleText")
        end
    end

    return ThemeManager
end