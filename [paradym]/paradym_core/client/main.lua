Core = {}

if Settings.Debug then SetResourceKvp('player_data', '') end

local DatastoreService = require 'classes.datastore'
local PlayerData = DatastoreService:new('player_data')

Core.CurrentCharacter = nil
Core.DefaultSpawn = {x = 236.9, y = -869.5, z = 30.3, heading = 340.7}
Core.LoggedOut = false

Core.CreatePlayerData = function()
    PlayerData:save({
        identifier = lib.callback.await('paradym_core:getPlayerIdentifier'),
        characters = {},
        metadata = {},
        hasData = true
    })
end

Core.SetPedAttributes = function()
    SetCanAttackFriendly(cache.ped, true, true)
    NetworkSetFriendlyFireOption(true)
    SetMaxWantedLevel(0)
    SetCreateRandomCops(false)
    SetCreateRandomCopsNotOnScenarios(false)
    SetCreateRandomCopsOnScenarios(false)
end

Core.SetPosition = function(x, y, z, heading)
    RequestCollisionAtCoord(x, y, z)
    FreezeEntityPosition(cache.ped, true)
    SetEntityCoordsNoOffset(cache.ped, x, y, z, true, true, false)
    SetEntityHeading(cache.ped, heading)
    while not HasCollisionLoadedAroundEntity(cache.ped) do
        RequestCollisionAtCoord(x, y, z)
        Wait(0)
    end
    FreezeEntityPosition(cache.ped, false)
end

Core.SetPlayerMetadata = function(index, data)
    PlayerData.data.metadata[index] = data
    PlayerData:save(PlayerData.data)
end

Core.GetPlayerMetadata = function(index)
    return PlayerData.data.metadata[index]
end

Core.SetCharacterMetadata = function(characterId, index, data)
    if not characterId then Utils.DebugPrint('ERROR', '[SetCharacterMetadata] No characterId, aborting metadata save') return end
    PlayerData.data.characters[characterId].metadata[index] = data
    PlayerData:save(PlayerData.data)
end

Core.GetCharacterMetadata = function(characterId, index)
    if not PlayerData.data.characters[characterId] then
        Utils.DebugPrint('ERROR', 'Metadata retrieval error: no character found with id: '..characterId) return
    end
    return PlayerData.data.characters[characterId].metadata[index]
end

Core.SetDefaultCharacter = function(characterId)
    local character = PlayerData.data.characters[characterId]

    Core.SetPlayerMetadata('defaultCharacter', characterId)

    lib.notify({
        title = 'Default Character',
        description = characterId and ('Default character set to %s %s'):format(character.firstname, character.lastname) or 'Default character removed',
        type = 'success',
        position = 'top'
    })
end

Core.UpdateCharacterLocation = function()
    local coords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)

    Core.SetCharacterMetadata(Core.CurrentCharacter, 'lastlocation', {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = heading
    } )
end

Core.SetCharacterAppearance = function(characterId, appearance)
    if Core.GetCharacterMetadata(characterId, 'needAppearance') then
        Core.SetCharacterMetadata(characterId, 'needAppearance', false)
    end
    Core.SetCharacterMetadata(characterId, 'appearance', appearance)
end

Core.GerPlayerInfo = function()
    return PlayerData.data
end

Core.GetPlayerInfoOne = function(key)
    return PlayerData.data[key]
end

Core.GetCharacters = function()
    return PlayerData.data.characters
end

Core.GetCharacterInfo = function(characterId)
    return PlayerData.data.characters[characterId]
end

Core.GetCharacterInfoOne = function(characterId, key)
    return PlayerData.data.characters[characterId][key]
end

Core.CreateCharacter = function()
    local input = lib.inputDialog('Create Character', {
        {type = 'input', label = 'First Name', required = true, min = 2},
        {type = 'input', label = 'Last Name', required = true, min = 2},
        {type = 'number', label = 'Height (CM)', required = true, icon = 'up-down'},
        {type = 'date', label = 'Date of Birth', required = true, icon = {'far', 'calendar'}, returnString = true, format = "DD/MM/YYYY"}
    })

    if not input then Core.SelectCharacter() return end

    local character = {
        firstname = input[1] or 'John',
        lastname = input[2] or 'Doe',
        height = input[3] or 180,
        dob = input[4] or '01/01/1990',
        cash = 1000.0,
        bank = 2500.0,
        metadata = {
            needAppearance = true,
            lastlocation = Core.DefaultSpawn,
            health = 200,
            armor = 0,
        }
    }

    PlayerData.data.characters[#PlayerData.data.characters + 1] = character

    PlayerData:save(PlayerData.data)
    Core.SelectCharacter()
end

Core.SelectCharacter = function()
    local menu = {
        id = 'character_menu',
        title = 'Character Selection',
        canClose = false,
        options = {}
    }

    local characters = PlayerData.data.characters or {}

    Utility.PauseRessuraction()
    exports['fivem-appearance']:setPlayerModel('mp_m_freemode_01')

    menu.options[#menu.options + 1] = {
        title = 'Create Character',
        onSelect = function()
            TriggerEvent('paradym_core:openCharacterCreation')
        end,
        icon = 'plus',
    }

    for characterId, character in pairs(characters) do
        menu.options[#menu.options + 1] = {
            title = ('%s %s'):format(character.firstname, character.lastname),
            icon = 'user',
            iconColor = '#54e386',
            onSelect = function()
                TriggerEvent('paradym_core:selectCharacter', characterId)
            end,
            metadata = {
                {label = 'Cash', value = character.cash or 0},
                {label = 'Bank', value = character.bank or 0},
            },
        }
    end

    SetGameplayCamRelativeHeading(180.0)
    SetGameplayCamRelativePitch(0.0, 1.0)

    lib.registerContext(menu)
    lib.showContext(menu.id)
end

Core.SpawnCharacter = function(characterId)
    local character = PlayerData.data.characters[characterId]
    local menu = {
        id = 'character_options',
        title = ('Character: %s %s'):format(character.firstname, character.lastname),
        canClose = false,
        options = {}
    }

    local appearance = Core.GetCharacterMetadata(characterId, 'appearance')

    Utility.PauseRessuraction()
    exports['fivem-appearance']:setPlayerAppearance(appearance)

    menu.options[#menu.options + 1] = {
        title = 'Select Character',
        onSelect = function()
            Core.Spawn(characterId)
        end,
        icon = 'check',
    }

    menu.options[#menu.options + 1] = {
        title = 'Delete Character',
        onSelect = function()
            Core.PromptDeleteCharacter(characterId)
        end,
        icon = 'trash',
        iconColor = '#ff4f42',
    }

    menu.options[#menu.options + 1] = {
        title = 'Back',
        onSelect = function()
            Core.SelectCharacter()
        end,
        icon = 'arrow-left',
    }

    SetGameplayCamRelativeHeading(180.0)
    SetGameplayCamRelativePitch(0.0, 1.0)

    lib.registerContext(menu)
    lib.showContext(menu.id)
end

Core.PromptDefaultOptions = function(characterId)
    local menu = {
        id = 'default_character_options',
        title = 'Default Character',
        options = {}
    }

    menu.options[#menu.options + 1] = {
        title = 'Set Default',
        onSelect = function()
            Core.SetDefaultCharacter(characterId)
        end,
        icon = 'check',
    }

    menu.options[#menu.options + 1] = {
        title = 'Back',
        onSelect = function()
            Core.SelectDefaultCharacter()
        end,
        icon = 'arrow-left',
    }

    lib.registerContext(menu)
    lib.showContext(menu.id)
end

Core.SelectDefaultCharacter = function()
    local menu = {
        id = 'default_character_menu',
        title = 'Default Character',
        options = {}
    }

    local characters = PlayerData.data.characters or {}

    for characterId, character in pairs(characters) do
        menu.options[#menu.options + 1] = {
            title = ('%s %s'):format(character.firstname, character.lastname),
            icon = 'user',
            onSelect = function()
                Core.PromptDefaultOptions(characterId)
            end,
            metadata = {
                {label = 'Cash', value = character.cash or 0},
                {label = 'Bank', value = character.bank or 0},
            },
        }
    end

    menu.options[#menu.options + 1] = {
        title = 'Remove Default',
        onSelect = function()
            Core.SetDefaultCharacter(false)
        end,
        icon = 'xmark',
        iconColor = '#ff4f42'
    }

    lib.registerContext(menu)
    lib.showContext(menu.id)
end

Core.PromptDeleteCharacter = function(characterId)
    local character = PlayerData.data.characters[characterId]
    local alert = lib.alertDialog({
        header = 'Character Deletion',
        content = ('Are you sure you want to delete %s %s?'):format(character.firstname, character.lastname),
        labels = {
            confirm = 'Delete',
        },
        centered = true,
        cancel = true
    })

    local delete = alert == 'confirm' and true or false

    if delete then
        Core.DeleteCharacter(characterId)
        Core.SelectCharacter()
    else
        Core.SelectCharacter()
    end
end

Core.DeleteCharacter = function(characterId)
    PlayerData.data.characters[characterId] = nil
    PlayerData:save(PlayerData.data)

    Clothing.DeleteOutfits(characterId)
    Garage.DeleteVehicles(characterId)
end

Core.Spawn = function(characterId)
    local character = PlayerData.data.characters[characterId]
    if not character then Utils.DebugPrint('ERROR', '[CRITITCAL] Missing character data, aborting spawn') return end

    if Core.GetCharacterMetadata(characterId, 'needAppearance') then
        local appearance = Clothing.OpenMenu()

        if appearance then
            Core.SetCharacterAppearance(characterId, appearance)
        end
    end

    Utils.DebugPrint('INFO', 'Spawning character...')

    local lastLocation = Core.GetCharacterMetadata(characterId, 'lastlocation')
    lastLocation = lastLocation or Core.DefaultSpawn

    Core.SetPosition(lastLocation.x, lastLocation.y, lastLocation.z, lastLocation.heading)

    Core.CurrentCharacter = characterId
    Core.LoggedOut = false

    local characterData = {
        id = characterId,
        data = character,
        player = {
            identifier = PlayerData.data.identifier,
        }
    }

    SetGameplayCamRelativeHeading(0.0)
    SetGameplayCamRelativePitch(-10.0, 1.0)

    local appearance = Core.GetCharacterMetadata(characterId, 'appearance')

    if appearance then
        Utility.PauseRessuraction()
        exports['fivem-appearance']:setPlayerAppearance(appearance)
    end

    lib.notify({
        title = 'Character Selection',
        position = 'top',
        description = ('%s %s spawned. Welcome!'):format(character.firstname, character.lastname),
        type = 'success'
    })

    TriggerServerEvent('paradym_core:characterLogin', characterData)
end

Core.Logout = function()
    local coords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)

    Utils.DebugPrint('INFO', 'Logging out...')
    TriggerServerEvent('paradym_core:characterLogout')

    LocalPlayer.state:set('spawned', false, true)
    LocalPlayer.state:set('character', nil, true)

    Core.SetCharacterMetadata(Core.CurrentCharacter, 'lastlocation', {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = heading
    })

    lib.notify({
        title = 'Character Selection',
        position = 'top',
        description = 'You have logged out',
        type = 'success'
    })

    Core.CurrentCharacter = nil
    Core.LoggedOut = true
    Core.Init()
end

Core.SetAIEnabled = function(toggle)
    Core.AIEnabled = toggle
    Utility.SetAIEnabled(Core.AIEnabled)
end

Core.MainThread = function()
    CreateThread(function()
        while true do

            SetPlayerWantedLevel(PlayerId(), 0, false)

            if IsPedUsingActionMode(cache.ped) then
                SetPedUsingActionMode(cache.ped, false, -1, 0)
            end

            if GetEntityHealth(cache.ped) <= 0 and not Utility.Resurrecting then
                Utility.ResurrectPlayer()
            end

            Wait(0)
        end
    end)

    CreateThread(function()
        while true do
            if not Core.CurrentCharacter then goto continue end

            Core.UpdateCharacterLocation()

            ::continue::
            Wait(5000)
        end
    end)

    Wait(2000)

    ShutdownLoadingScreen()
end

Core.Init = function()
    if not LocalPlayer.state.spawned then
        ShutdownLoadingScreen()

        FreezeEntityPosition(cache.ped, true)

        if Core.GetPlayerMetadata('defaultCharacter') == nil then
            Utils.DebugPrint('INFO', 'No default character set, setting default...')
            Core.SetPlayerMetadata('defaultCharacter', false)
        end

        Wait(100)

        if Core.GetPlayerMetadata('defaultCharacter') and not Core.LoggedOut then
            Utils.DebugPrint('INFO', 'Default character found, spawning...')
            Core.Spawn(Core.GetPlayerMetadata('defaultCharacter'))
            return
        end

        Core.SetPosition(Core.DefaultSpawn.x, Core.DefaultSpawn.y, Core.DefaultSpawn.z, Core.DefaultSpawn.heading)
        Utils.DebugPrint('INFO', 'Spawning player model...')
        Core.SelectCharacter()
    else
        Utils.DebugPrint('INFO', 'Player already spawned, assuming resource restart...')
        local characterData = LocalPlayer.state.character

        Core.CurrentCharacter = characterData.id
        TriggerServerEvent('paradym_core:characterLogin', characterData)
    end

    Core.PlayerData = PlayerData
end

if not PlayerData.data or not PlayerData.data.hasData then
    Utils.DebugPrint('WARN', 'No player data found, creating new data using defaults.')
    LocalPlayer.state:set('spawned', false, true)
    Core.CreatePlayerData()
end

local scenarios = lib.load("data.scenarios")
local models = lib.load("data.models")
local relationships = lib.load("data.relationships")

CreateThread(function()
    for i = 1, #relationships do
        SetRelationshipBetweenGroups(1, relationships[i], `PLAYER`)
    end
    for i = 1, #scenarios do
        SetScenarioTypeEnabled(scenarios[i], false)
    end
    for i = 1, 32 do
        EnableDispatchService(i, false)
    end
    for i = 1, #models do
        local model = models[i]
        if IsModelAVehicle(model) then
            SetVehicleModelIsSuppressed(model, true)
        elseif IsModelAPed(model) then
            SetPedModelIsSuppressed(model, true)
        end
    end
end)

Core.SetAIEnabled(GlobalState.AIEnabled or true)

AddStateBagChangeHandler('AIEnabled', 'global', function(bagName, key, value, _, _)
    Core.SetAIEnabled(value)
end)

Core.Init()
Core.MainThread()

RegisterNetEvent('paradym_core:resoleNilCharacter', Core.SelectCharacter)
RegisterNetEvent('paradym_core:openCharacterCreation', Core.CreateCharacter)
RegisterNetEvent('paradym_core:selectCharacter', Core.SpawnCharacter)
RegisterNetEvent('paradym_core:toggleAI', Core.SetAIEnabled)