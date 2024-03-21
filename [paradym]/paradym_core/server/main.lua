Core = {}

Core.Characters = {}
Core.AIEnabled = true

Core.CharacterLogin = function(source, characterData)
    Utils.DebugPrint('INFO', ('Character login with data: source: %s name: %s %s'):format(source, characterData.data.firstname, characterData.data.lastname))
    Utils.DebugPrint('INFO', ('Player data: identifier: %s'):format(characterData.player.identifier))
    Player(source).state:set('character', characterData, true)
    Player(source).state:set('spawned', true, true)
    Core.Characters[source] = characterData
end

Core.CharacterLogout = function(source)
    local characterData = Core.Characters[source]
    Utils.DebugPrint('INFO', ('Character logout with data: source: %s name: %s %s'):format(source, characterData.data.firstname, characterData.data.lastname))
    Utils.DebugPrint('INFO', ('Player data: identifier: %s'):format(characterData.player.identifier))
    Player(source).state:set('character', nil, true)
    Player(source).state:set('spawned', false, true)
    Core.Characters[source] = nil
end

Core.ToggleAI = function()
    Core.AIEnabled = not Core.AIEnabled
    GlobalState:set('AIEnabled', Core.AIEnabled, true)
end

RegisterNetEvent('paradym_core:characterLogin', function(...)
    local src = source
    Core.CharacterLogin(src, ...)
end)

RegisterNetEvent('paradym_core:characterLogout', function()
    local src = source
    Core.CharacterLogout(src)
end)

lib.callback.register('paradym_core:getPlayerIdentifier', function(source)
    return GetPlayerIdentifierByType(source, 'fivem')
end)

lib.callback.register('paradym_core:saveVehicleData', function(source, vehicleData, hashMap)
    SaveResourceFile('paradym_core', 'data/vehicles.json', json.encode(vehicleData, {
        indent = true, sort_keys = true, indent_count = 2
    }), -1)
    SaveResourceFile('paradym_core', 'data/vehicle_models.json', json.encode(hashMap, {
        indent = true, sort_keys = true, indent_count = 2
    }), -1)
end)

GlobalState:set('AIEnabled', Core.AIEnabled, true)

