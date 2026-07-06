SafezoneServer = SafezoneServer or {}
local Server = SafezoneServer
Server.Logging = Server.Logging or {}
local Logging = Server.Logging

local function isServer()
    if type(IsDuplicityVersion) == 'function' then
        return IsDuplicityVersion()
    end

    return true
end

local function getConfig()
    Config = Config or {}
    Config.Logging = Config.Logging or {}
    return Config.Logging
end

local function joinPaths(base, relative)
    if not base or base == '' then
        return relative
    end

    if relative:sub(1, 1) ~= '/' then
        relative = '/' .. relative
    end

    return base .. relative
end

local function ensureDirectory(path)
    if not path or path:find('[;&|`$%%]') then
        return
    end

    local separator = '/'
    if type(package) == 'table' and type(package.config) == 'string' then
        separator = package.config:sub(1, 1)
    end

    if separator == '\\' then
        os.execute(string.format('if not exist "%s" mkdir "%s"', path, path))
    else
        os.execute(string.format('mkdir -p "%s"', path))
    end
end

local function parseDateString(dateString)
    local year, month, day = dateString:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
    if not year then
        return nil
    end

    return os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = 0,
        min = 0,
        sec = 0
    })
end

local function iso8601()
    return os.date('!%Y-%m-%dT%H:%M:%SZ')
end

local function epochNow()
    return os.time(os.date('!*t'))
end

local function isCategoryEnabled(config, category)
    if not config.enabled then
        return false
    end

    if not config.categories then
        return true
    end

    local normalized = category or 'GENERAL'
    return config.categories[normalized] ~= false
end

local function isActionEnabled(config, action)
    if not config.actions then
        return true
    end

    local normalized = action or 'general'
    if config.actions[normalized] == nil then
        return true
    end

    return config.actions[normalized] ~= false
end

local function getPlayerIdentifiers(sourceId)
    local config = getConfig()
    local types = config.identifierTypes or { 'steam', 'discord', 'license' }
    local result = {}
    for _, idType in ipairs(types) do
        result[idType] = GetPlayerIdentifierByType(sourceId, idType)
    end
    return result
end

local function getAdminContext(sourceId)
    local config = getConfig()
    local name = GetPlayerName(sourceId) or 'Unknown'

    local context = {
        id = sourceId,
        name = name
    }

    if config.includeIdentifiers ~= false then
        local identifiers = getPlayerIdentifiers(sourceId)
        for idType, value in pairs(identifiers) do
            context[idType] = value or ('NO_' .. idType:upper())
            context['has' .. idType:sub(1, 1):upper() .. idType:sub(2)] = value ~= nil
        end
    end

    return context
end

local function getZoneContext(zone)
    if not zone then
        return nil
    end

    return {
        name = zone.name,
        type = zone.type,
        isCustom = zone.isCustom == true,
        radius = zone.radius,
        minZ = zone.minZ,
        maxZ = zone.maxZ
    }
end

local function normalizeDirectory(basePath)
    local config = getConfig()
    local directory = config.directory or '/data/logs'
    return joinPaths(basePath, directory)
end

local function getFilePrefix()
    local config = getConfig()
    return config.filePrefix or 'admin-actions'
end

local function retentionSeconds()
    local config = getConfig()
    local days = tonumber(config.retentionDays) or 7
    return math.max(days, 1) * 86400
end

local function maxEntries()
    local config = getConfig()
    local limit = tonumber(config.maxEntries) or 500
    return math.max(limit, 50)
end

local function readManifest(path)
    local file = io.open(path, 'r')
    if not file then
        return { files = {} }
    end

    local content = file:read('*a')
    file:close()

    if not content or content == '' then
        return { files = {} }
    end

    local success, data = pcall(json.decode, content)
    if not success or type(data) ~= 'table' then
        return { files = {} }
    end

    data.files = data.files or {}
    return data
end

local function writeManifest(path, manifest)
    local file = io.open(path, 'w')
    if not file then
        return
    end

    file:write(json.encode(manifest, { indent = true }))
    file:close()
end

local function sortFiles(manifest)
    local files = {}
    for fileName, info in pairs(manifest.files or {}) do
        files[#files + 1] = {
            name = fileName,
            createdAt = info.createdAt or parseDateString(info.date or ''),
            date = info.date
        }
    end

    table.sort(files, function(a, b)
        local aTime = a.createdAt or 0
        local bTime = b.createdAt or 0
        if aTime == bTime then
            return a.name > b.name
        end
        return aTime > bTime
    end)

    return files
end

local function readEntriesFromFile(filePath)
    local entries = {}
    local file = io.open(filePath, 'r')
    if not file then
        return entries
    end

    for line in file:lines() do
        if line and line ~= '' then
            local ok, entry = pcall(json.decode, line)
            if ok and type(entry) == 'table' then
                entries[#entries + 1] = entry
            end
        end
    end

    file:close()
    return entries
end

function Logging.Init()
    if Logging.initialized or not isServer() then
        return
    end

    Logging.resourceName = GetCurrentResourceName()
    Logging.resourcePath = GetResourcePath(Logging.resourceName)
    Logging.directory = normalizeDirectory(Logging.resourcePath)
    Logging.manifestPath = Logging.directory .. '/manifest.json'
    Logging.cache = {}
    Logging.initialized = true

    ensureDirectory(Logging.directory)
    Logging.manifest = readManifest(Logging.manifestPath) or { files = {} }
    Logging:CleanupOldFiles()
end

function Logging:CleanupOldFiles()
    if not self.initialized then
        self.Init()
    end

    local cfg = getConfig()
    if not cfg.enabled then
        return
    end

    local manifest = self.manifest or { files = {} }
    local now = epochNow()
    local maxAge = retentionSeconds()

    for fileName, info in pairs(manifest.files or {}) do
        local filePath = self.directory .. '/' .. fileName
        local createdAt = info.createdAt or parseDateString(info.date or '') or now
        local fileHandle = io.open(filePath, 'r')

        if now - createdAt > maxAge then
            os.remove(filePath)
            manifest.files[fileName] = nil
        elseif not fileHandle then
            manifest.files[fileName] = nil
        else
            info.createdAt = createdAt
            info.date = info.date or os.date('%Y-%m-%d', createdAt)
        end

        if fileHandle then
            fileHandle:close()
        end
    end

    writeManifest(self.manifestPath, manifest)
    self.manifest = manifest
end

function Logging:GetOrCreateFile(dateString)
    if not self.initialized then
        self.Init()
    end

    local manifest = self.manifest or { files = {} }
    self.manifest = manifest
    manifest.files = manifest.files or {}

    local filePrefix = getFilePrefix()
    local fileName = string.format('%s-%s.log', filePrefix, dateString)
    local filePath = self.directory .. '/' .. fileName

    if not manifest.files[fileName] then
        manifest.files[fileName] = {
            createdAt = parseDateString(dateString) or epochNow(),
            date = dateString
        }
        writeManifest(self.manifestPath, manifest)
    end

    local existing = io.open(filePath, 'r')
    if existing then
        existing:close()
    else
        local file = io.open(filePath, 'w')
        if file then
            file:close()
        end
    end

    return filePath, fileName
end

local function normalizeMessage(message, ...)
    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, message, ...)
        if ok then
            return formatted
        end
    end
    return message
end

function Logging.Record(category, action, message, context, ...)
    Logging.Init()

    local cfg = getConfig()
    if not cfg.enabled then
        return
    end

    if not isCategoryEnabled(cfg, category) then
        return
    end

    if not isActionEnabled(cfg, action) then
        return
    end

    local entry = {
        timestamp = iso8601(),
        epoch = epochNow(),
        category = category or 'GENERAL',
        action = action or 'general',
        message = normalizeMessage(message or '', ...),
        context = context or {}
    }

    local dateString = os.date('!%Y-%m-%d', entry.epoch)
    local filePath = select(1, Logging:GetOrCreateFile(dateString))

    local file = io.open(filePath, 'a')
    if file then
        file:write(json.encode(entry), '\n')
        file:close()
    end

    Logging.cache[#Logging.cache + 1] = entry
    local maxCache = maxEntries()
    while #Logging.cache > maxCache do
        table.remove(Logging.cache, 1)
    end
end

function Logging:LogAdminAction(sourceId, action, message, extraContext, category)
    Logging.Init()

    category = category or 'ADMIN'
    local context = extraContext or {}
    context.admin = getAdminContext(sourceId)

    Logging.Record(category, action, message, context)
end

function Logging.GetEntries(limit)
    Logging.Init()

    local cfg = getConfig()
    if not cfg.enabled then
        return {}, {
            enabled = false
        }
    end

    limit = limit or maxEntries()
    local entries = {}

    local files = sortFiles(Logging.manifest or { files = {} })
    for _, fileInfo in ipairs(files) do
        local filePath = Logging.directory .. '/' .. fileInfo.name
        local fileEntries = readEntriesFromFile(filePath)
        for _, entry in ipairs(fileEntries) do
            entries[#entries + 1] = entry
        end
        if #entries >= limit then
            break
        end
    end

    table.sort(entries, function(a, b)
        local aEpoch = a.epoch or 0
        local bEpoch = b.epoch or 0
        if aEpoch == bEpoch then
            return (a.timestamp or '') > (b.timestamp or '')
        end
        return aEpoch > bEpoch
    end)

    if #entries > limit then
        local trimmed = {}
        for i = 1, limit do
            trimmed[#trimmed + 1] = entries[i]
        end
        entries = trimmed
    end

    local metadata = {
        enabled = true,
        categories = cfg.categories or {},
        actions = cfg.actions or {},
        retentionDays = cfg.retentionDays or 7,
        ui = cfg.ui or {}
    }

    return entries, metadata
end

function Logging.AppendZoneContext(context, zone)
    context.zone = getZoneContext(zone)
    return context
end

Logging.Init()
