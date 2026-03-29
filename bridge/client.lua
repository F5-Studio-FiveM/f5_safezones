local function initQBCore()
    Framework.Log('info', 'Initializing QBCore client bridge...')

    local ok, QBCore = pcall(exports['qb-core'].GetCoreObject, exports['qb-core'])
    if not ok or not QBCore then
        Framework.Log('error', 'Failed to get QBCore object: %s', tostring(QBCore))
        return false
    end

    Framework.OnPlayerLoaded = function(cb)
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', cb)
        Framework.Log('debug', 'Registered QBCore:Client:OnPlayerLoaded event handler')
    end

    Framework.IsPlayerLoaded = function()
        return LocalPlayer.state.isLoggedIn
    end

    Framework.GetPlayerData = function()
        return QBCore.Functions.GetPlayerData()
    end

    Framework.Notify = function(message, notifType)
        QBCore.Functions.Notify(message, notifType or 'primary', 5000)
    end

    Framework.GetPlayerJob = function()
        local pData = QBCore.Functions.GetPlayerData()
        if pData and pData.job then
            return { name = pData.job.name or 'unemployed', grade = pData.job.grade and pData.job.grade.level or 0 }
        end
        return { name = 'unemployed', grade = 0 }
    end

    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(jobInfo)
        Framework.Log('debug', 'Job updated: %s', jobInfo and jobInfo.name or 'unknown')
        TriggerEvent('f5_safezones:onJobUpdate')
    end)

    Framework.Log('success', 'QBCore client bridge initialized')
    return true
end

local function initQBox()
    Framework.Log('info', 'Initializing QBox client bridge...')

    local qbx = exports['qbx_core']

    Framework.OnPlayerLoaded = function(cb)
        AddEventHandler('QBCore:Client:OnPlayerLoaded', cb)
        Framework.Log('debug', 'Registered QBCore:Client:OnPlayerLoaded event handler (QBox local event)')
    end

    Framework.IsPlayerLoaded = function()
        return LocalPlayer.state.isLoggedIn
    end

    Framework.GetPlayerData = function()
        local ok, data = pcall(qbx.GetPlayerData, qbx)
        if ok and data then
            return data
        end
        Framework.Log('warn', 'qbx_core:GetPlayerData failed: %s', tostring(data))
        return {}
    end

    Framework.Notify = function(message, notifType)
        local qbxType = notifType
        if notifType == 'primary' or not notifType then qbxType = 'inform' end
        local ok, err = pcall(qbx.Notify, qbx, message, qbxType, 5000)
        if not ok then
            Framework.Log('warn', 'qbx_core:Notify failed: %s, trying ox_lib', tostring(err))
            local oxLib = exports['ox_lib']
            local oxType = qbxType == 'inform' and 'info' or qbxType
            local oxOk, oxErr = pcall(oxLib.notify, oxLib, {
                description = message,
                type = oxType
            })
            if not oxOk then
                Framework.Log('error', 'ox_lib notify also failed: %s', tostring(oxErr))
                SetNotificationTextEntry('STRING')
                AddTextComponentSubstringPlayerName(message)
                DrawNotification(false, true)
            end
        end
    end

    Framework.GetPlayerJob = function()
        local pData = Framework.GetPlayerData()
        if pData and pData.job then
            return { name = pData.job.name or 'unemployed', grade = pData.job.grade and pData.job.grade.level or 0 }
        end
        return { name = 'unemployed', grade = 0 }
    end

    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(jobInfo)
        Framework.Log('debug', 'Job updated: %s', jobInfo and jobInfo.name or 'unknown')
        TriggerEvent('f5_safezones:onJobUpdate')
    end)

    Framework.Log('success', 'QBox client bridge initialized')
    return true
end

local function initESX()
    Framework.Log('info', 'Initializing ESX client bridge...')

    local ok, ESX = pcall(exports['es_extended'].getSharedObject, exports['es_extended'])
    if not ok or not ESX then
        Framework.Log('error', 'Failed to get ESX shared object: %s', tostring(ESX))
        return false
    end

    Framework.OnPlayerLoaded = function(cb)
        RegisterNetEvent('esx:playerLoaded', function()
            cb()
        end)
        Framework.Log('debug', 'Registered esx:playerLoaded event handler')
    end

    Framework.IsPlayerLoaded = function()
        return ESX.PlayerLoaded
    end

    Framework.GetPlayerData = function()
        return ESX.GetPlayerData()
    end

    Framework.Notify = function(message, notifType)
        local esxType = notifType
        if notifType == 'primary' or not notifType then esxType = 'info' end
        ESX.ShowNotification(message, esxType, 5000)
    end

    Framework.GetPlayerJob = function()
        local pData = ESX.GetPlayerData()
        if pData and pData.job then
            return { name = pData.job.name or 'unemployed', grade = pData.job.grade or 0 }
        end
        return { name = 'unemployed', grade = 0 }
    end

    RegisterNetEvent('esx:setJob', function(job, lastJob)
        Framework.Log('debug', 'Job updated: %s (was: %s)', job and job.name or 'unknown', lastJob and lastJob.name or 'unknown')
        TriggerEvent('f5_safezones:onJobUpdate')
    end)

    Framework.Log('success', 'ESX client bridge initialized')
    return true
end

local function setNoopFunctions()
    Framework.OnPlayerLoaded = function() end
    Framework.IsPlayerLoaded = function() return false end
    Framework.GetPlayerData = function() return {} end
    Framework.GetPlayerJob = function() return { name = 'unemployed', grade = 0 } end
    Framework.Notify = function(message)
        SetNotificationTextEntry('STRING')
        AddTextComponentSubstringPlayerName(message)
        DrawNotification(false, true)
    end
end

CreateThread(function()
    Framework.WaitForReady()

    if not Framework.Name then
        Framework.Log('warn', 'No framework available, using fallback noop functions')
        setNoopFunctions()
        Framework.ClientReady = true
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
            Framework.Log('error', 'Client bridge initialization failed for %s, using fallback', Framework.Name)
            setNoopFunctions()
        end
    end

    Framework.ClientReady = true
    Framework.Log('info', 'Client bridge ready')
end)

function Framework.WaitForClientReady()
    while not Framework.ClientReady do
        Wait(10)
    end
end
