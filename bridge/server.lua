local function initQBCore()
    Framework.Log('info', 'Initializing QBCore server bridge...')

    local ok, QBCore = pcall(exports['qb-core'].GetCoreObject, exports['qb-core'])
    if not ok or not QBCore then
        Framework.Log('error', 'Failed to get QBCore object: %s', tostring(QBCore))
        return false
    end

    Framework.GetPlayer = function(source)
        return QBCore.Functions.GetPlayer(source)
    end

    Framework.IsAdmin = function(source)
        if QBCore.Functions.HasPermission(source, 'admin') then
            return true
        end
        if QBCore.Functions.HasPermission(source, 'god') then
            return true
        end
        return false
    end

    Framework.GetPlayerJob = function(source)
        local player = QBCore.Functions.GetPlayer(source)
        if player and player.PlayerData and player.PlayerData.job then
            return { name = player.PlayerData.job.name or 'unemployed', grade = player.PlayerData.job.grade and player.PlayerData.job.grade.level or 0 }
        end
        return { name = 'unemployed', grade = 0 }
    end

    Framework.Log('success', 'QBCore server bridge initialized')
    Framework.Log('debug', 'Admin detection: QBCore.Functions.HasPermission (admin, god)')
    return true
end

local function initQBox()
    Framework.Log('info', 'Initializing QBox server bridge...')

    local ok, err = pcall(exports['qbx_core'].GetCoreVersion, exports['qbx_core'])
    if not ok then
        Framework.Log('warn', 'Could not verify qbx_core version: %s', tostring(err))
    else
        Framework.Log('debug', 'qbx_core version: %s', tostring(err))
    end

    Framework.GetPlayer = function(source)
        return exports['qbx_core']:GetPlayer(source)
    end

    -- QBox relies on ACE permissions which are checked separately in Admin.IsPlayerAdmin
    Framework.IsAdmin = function()
        return false
    end

    Framework.GetPlayerJob = function(source)
        local player = exports['qbx_core']:GetPlayer(source)
        if player and player.PlayerData and player.PlayerData.job then
            return { name = player.PlayerData.job.name or 'unemployed', grade = player.PlayerData.job.grade and player.PlayerData.job.grade.level or 0 }
        end
        return { name = 'unemployed', grade = 0 }
    end

    Framework.Log('success', 'QBox server bridge initialized')
    Framework.Log('debug', 'Admin detection: ACE permissions only (framework fallback disabled)')
    return true
end

local function initESX()
    Framework.Log('info', 'Initializing ESX server bridge...')

    local ok, ESX = pcall(exports['es_extended'].getSharedObject, exports['es_extended'])
    if not ok or not ESX then
        Framework.Log('error', 'Failed to get ESX shared object: %s', tostring(ESX))
        return false
    end

    Framework.GetPlayer = function(source)
        return ESX.GetPlayerFromId(source)
    end

    Framework.IsAdmin = function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            local group = xPlayer.getGroup()
            if group == 'admin' or group == 'superadmin' then
                return true
            end
        end
        return false
    end

    Framework.GetPlayerJob = function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer and xPlayer.job then
            return { name = xPlayer.job.name or 'unemployed', grade = xPlayer.job.grade or 0 }
        end
        return { name = 'unemployed', grade = 0 }
    end

    Framework.Log('success', 'ESX server bridge initialized')
    Framework.Log('debug', 'Admin detection: xPlayer.getGroup() (admin, superadmin)')
    return true
end

local function setNoopFunctions()
    Framework.GetPlayer = function() return nil end
    Framework.IsAdmin = function() return false end
    Framework.GetPlayerJob = function() return { name = 'unemployed', grade = 0 } end
end

CreateThread(function()
    Framework.WaitForReady()

    if not Framework.Name then
        Framework.Log('warn', 'No framework available, using fallback noop functions')
        setNoopFunctions()
        Framework.ServerReady = true
        return
    end

    local inits = {
        qbcore = initQBCore,
        qbox = initQBox,
        esx = initESX
    }

    local init = inits[Framework.Name]
    if init then
        local success = init()
        if not success then
            Framework.Log('error', 'Server bridge initialization failed for %s, using fallback', Framework.Name)
            setNoopFunctions()
        end
    end

    Framework.ServerReady = true
    Framework.Log('info', 'Server bridge ready')
end)

function Framework.WaitForServerReady()
    while not Framework.ServerReady do
        Wait(10)
    end
end
