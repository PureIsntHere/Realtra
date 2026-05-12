--!nocheck
-- Réaltra SaveManager - Configuration persistence system

local HttpService = game:GetService('HttpService')

local SaveManager = {} do
    SaveManager.Folder = 'configs'
    SaveManager.Ignore = {}
    SaveManager.Library = nil
    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object)
                return { type = 'Toggle', idx = idx, value = object:GetValue() }
            end,
            Load = function(idx, data, object)
                if object then
                    -- animate=false, ignoreCallback=true — no notification spam on load
                    object:SetValue(data.value, false, true)
                end
            end,
        },
        Slider = {
            Save = function(idx, object)
                return { type = 'Slider', idx = idx, value = tostring(object:GetValue()) }
            end,
            Load = function(idx, data, object)
                if object then
                    object:SetValue(tonumber(data.value), false, true)
                end
            end,
        },
        Dropdown = {
            Save = function(idx, object)
                return { type = 'Dropdown', idx = idx, value = object:GetValue() }
            end,
            Load = function(idx, data, object)
                if object then
                    object:SetValue(data.value, false, true)
                end
            end,
        },
        TextInput = {
            Save = function(idx, object)
                return { type = 'TextInput', idx = idx, text = object:GetText() }
            end,
            Load = function(idx, data, object)
                if object and type(data.text) == 'string' then
                    object:SetText(data.text)
                end
            end,
        },
        Hotkey = {
            Save = function(idx, object)
                return { type = 'Hotkey', idx = idx, value = object:GetValue() }
            end,
            Load = function(idx, data, object)
                if object then
                    object:SetValue(data.value)
                end
            end,
        },
        MultiDropdown = {
            Save = function(idx, object)
                return { type = 'MultiDropdown', idx = idx, values = object:GetValues() }
            end,
            Load = function(idx, data, object)
                if object and type(data.values) == 'table' then
                    -- animate=false, ignoreCallback=true — state is synced via OnLoaded
                    object:SetValues(data.values, false, true)
                end
            end,
        },
        RadioGroup = {
            Save = function(idx, object)
                return { type = 'RadioGroup', idx = idx, value = object:GetValue() }
            end,
            Load = function(idx, data, object)
                if object then
                    object:SetValue(data.value, true)
                end
            end,
        },
    }

    function SaveManager:SetIgnoreIndexes(list)
        for _, key in ipairs(list) do
            self.Ignore[key] = true
        end
    end

    function SaveManager:SetLibrary(library)
        self.Library = library
    end

    function SaveManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    function SaveManager:BuildFolderTree()
        if not (typeof(isfolder) == "function" and typeof(makefolder) == "function") then
            return
        end
        local paths = {
            self.Folder,
            self.Folder .. '/settings'
        }

        for i = 1, #paths do
            local str = paths[i]
            if not isfolder(str) then
                makefolder(str)
            end
        end
    end

    function SaveManager:Save(name)
        if (not name) then
            return false, 'no config file is selected'
        end

        local fullPath = self.Folder .. '/settings/' .. name .. '.json'

        local data = {
            objects = {}
        }

        -- Recursive collector: traverses sections and nested containers.
        -- Components added to Sections live in section._components, not window._components.
        local function collectForSave(components)
            for _, comp in ipairs(components or {}) do
                if comp._components then
                    collectForSave(comp._components)
                end
                local idx = comp.Flag
                if idx and not self.Ignore[idx] then
                    local compType = comp.Name
                    if self.Parser[compType] then
                        table.insert(data.objects, self.Parser[compType].Save(idx, comp))
                    end
                end
            end
        end

        -- Collect all flagged components from all windows (including section children)
        for _, window in ipairs(self.Library.Windows or {}) do
            collectForSave(window._components)
        end

        local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
        if not ok or type(encoded) ~= 'string' then
            return false, 'failed to encode data'
        end

        local wrote, werr = pcall(function() writefile(fullPath, encoded) end)
        if not wrote then
            return false, werr or 'writefile failed'
        end
        return true
    end

    function SaveManager:Load(name)
        if (not name) then
            return false, 'no config file is selected'
        end

        local file = self.Folder .. '/settings/' .. name .. '.json'
        if not isfile(file) then return false, 'invalid file' end

        local contents
        local ok, err = pcall(function() contents = readfile(file) end)
        if not ok then return false, err or 'readfile failed' end

        local success, decoded = pcall(function() return HttpService:JSONDecode(contents) end)
        if not success or type(decoded) ~= 'table' then return false, 'decode error' end

        -- Build lookup table for flagged components (recursive: descends into sections)
        local flaggedComponents = {}
        local function collectForLoad(components)
            for _, comp in ipairs(components or {}) do
                if comp._components then
                    collectForLoad(comp._components)
                end
                if comp.Flag then
                    flaggedComponents[comp.Flag] = comp
                end
            end
        end
        for _, window in ipairs(self.Library.Windows or {}) do
            collectForLoad(window._components)
        end

        -- Load saved values
        for _, option in ipairs(decoded.objects or {}) do
            if self.Parser[option.type] and not self.Ignore[option.idx] then
                local comp = flaggedComponents[option.idx]
                -- Run load synchronously
                local ok, perr = pcall(function()
                    self.Parser[option.type].Load(option.idx, option, comp)
                end)
                if not ok then
                    warn('SaveManager: Failed to apply config option:', perr)
                end
            end
        end

        -- Fire the post-load hook (e.g. to refresh derived UI like status labels)
        if self.OnLoaded then
            pcall(self.OnLoaded)
        end

        return true
    end

    function SaveManager:RefreshConfigList()
        local list
        local ok, err = pcall(function() list = listfiles(self.Folder .. '/settings') end)
        if not ok or type(list) ~= 'table' then return {} end

        local out = {}
        for i = 1, #list do
            local fname = list[i]
            if type(fname) == 'string' and fname:sub(-5) == '.json' then
                -- Extract filename without path and extension
                local name = fname:match('[\\/]*([^\\/]+)%.json$')
                if name then table.insert(out, name) end
            end
        end

        return out
    end

    -- AttemptSave: debounced save — waits 1 second after the last call before writing.
    -- Ideal for wiring into component callbacks so the config is auto-saved on change.
    -- Usage: SaveManager:AttemptSave("default")  (call from inside any component Callback)
    function SaveManager:AttemptSave(name)
        if not name then return end
        if self._saveDebounce then
            task.cancel(self._saveDebounce)
            self._saveDebounce = nil
        end
        self._saveDebounce = task.delay(1, function()
            self._saveDebounce = nil
            self:Save(name)
        end)
    end

    function SaveManager:LoadAutoloadConfig()
        local autopath = self.Folder .. '/settings/autoload.txt'
        if isfile(autopath) then
            local name
            local ok, err = pcall(function() name = readfile(autopath) end)
            if not ok then
                if self.Library and self.Library.Notify then
                    self.Library:Notify({ Title = 'Config Error', Text = 'Failed to read autoload file', Duration = 3 })
                end
                return
            end

            local success, lerr = self:Load(name)
            if not success then
                return self.Library:Notify({
                    Title = 'Config Error',
                    Text = 'Failed to load autoload config: ' .. tostring(lerr),
                    Duration = 3
                })
            end

            if self.Library and self.Library.Notify then
                self.Library:Notify({ Title = 'Config Loaded', Text = string.format('Auto loaded config: %s', name), Duration = 2 })
            end
        end
    end

    function SaveManager:BuildConfigSection(container)
        assert(self.Library, 'Must set SaveManager.Library')

        local isTab = container.AddLeftGroupbox ~= nil
        local section

        if isTab then
            section = container:AddRightGroupbox('Configuration')
        else
            section = container
        end

        local configNameInput = section:AddTextbox({
            Text = 'Config Name',
            Placeholder = 'Enter config name...',
            Flag = 'SaveManager_ConfigName'
        })

        local configList = section:AddDropdown({
            Text = 'Config List',
            Options = self:RefreshConfigList(),
            Flag = 'SaveManager_ConfigList'
        })

        section:AddButton({
            Text = 'Create Config',
            Callback = function()
                local name = configNameInput:GetText()

                if name:gsub(' ', '') == '' then
                    return self.Library:Notify({
                        Title = 'Config Error',
                        Text = 'Invalid config name (empty)',
                        Duration = 2
                    })
                end

                local success, err = self:Save(name)
                if not success then
                    return self.Library:Notify({
                        Title = 'Config Error',
                        Text = 'Failed to save: ' .. err,
                        Duration = 3
                    })
                end

                self.Library:Notify({
                    Title = 'Config Saved',
                    Text = string.format('Created config: %s', name),
                    Duration = 2
                })

                configList:SetOptions(self:RefreshConfigList())
            end
        })

        section:AddButton({
            Text = 'Load Config',
            Callback = function()
                local name = configList:GetValue()

                local success, err = self:Load(name)
                if not success then
                    return self.Library:Notify({
                        Title = 'Config Error',
                        Text = 'Failed to load: ' .. err,
                        Duration = 3
                    })
                end

                self.Library:Notify({
                    Title = 'Config Loaded',
                    Text = string.format('Loaded config: %s', name),
                    Duration = 2
                })
            end
        })

        section:AddButton({
            Text = 'Overwrite Config',
            Callback = function()
                local name = configList:GetValue()

                local success, err = self:Save(name)
                if not success then
                    return self.Library:Notify({
                        Title = 'Config Error',
                        Text = 'Failed to overwrite: ' .. err,
                        Duration = 3
                    })
                end

                self.Library:Notify({
                    Title = 'Config Saved',
                    Text = string.format('Overwrote config: %s', name),
                    Duration = 2
                })
            end
        })

        section:AddButton({
            Text = 'Refresh List',
            Callback = function()
                configList:SetOptions(self:RefreshConfigList())
            end
        })

        section:AddButton({
            Text = 'Set as Autoload',
            Callback = function()
                local name = configList:GetValue()
                local ok, werr = pcall(writefile, self.Folder .. '/settings/autoload.txt', name)
                if not ok then
                    return self.Library:Notify({ Title = 'Config Error', Text = 'Failed to set autoload: ' .. tostring(werr), Duration = 3 })
                end

                if SaveManager.AutoloadLabel then
                    SaveManager.AutoloadLabel:SetText('Current autoload: ' .. name)
                end

                self.Library:Notify({
                    Title = 'Autoload Set',
                    Text = string.format('Set %s to auto load', name),
                    Duration = 2
                })
            end
        })

        local autoloadText = 'Current autoload: none'
        if isfile(self.Folder .. '/settings/autoload.txt') then
            local ok, name = pcall(function() return readfile(self.Folder .. '/settings/autoload.txt') end)
            if ok and type(name) == 'string' then
                autoloadText = 'Current autoload: ' .. name
            end
        end

        SaveManager.AutoloadLabel = section:AddLabel({ Text = autoloadText })

        SaveManager:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName' })
    end

    SaveManager:BuildFolderTree()
end

return SaveManager
