Commands = {}

Commands.Vehicles = LoadResourceFile('paradym_core', "data/vehicles.json")
Commands.VehicleData = json.decode(Commands.Vehicles) or {}

Commands.SpawnVehicle = function(source, model, coords, heading, warp)
    local hash = joaat(model)
    local data = Commands.VehicleData[model]

    local vehicle = CreateVehicleServerSetter(hash, data.type, coords.x, coords.y, coords.z, heading)

    repeat Wait(0) until GetVehicleBodyHealth(vehicle) > 0

    local success = lib.callback.await('paradym_core:initVehicle', source, NetworkGetNetworkIdFromEntity(vehicle))

    if not success then
        Utils.DebugPrint('ERROR', 'Failed to initialize vehicle')
    end

    if warp then
        SetPedIntoVehicle(GetPlayerPed(source), vehicle, -1)
    end

    return NetworkGetNetworkIdFromEntity(vehicle)
end

Commands.TeleportToPlayer = function(source, targetId)
    local target = GetPlayerPed(targetId)
    local coords = GetEntityCoords(target)

    SetEntityCoords(GetPlayerPed(source), coords.x, coords.y, coords.z, true, false, false, false)
end

Commands.TeleportPlayer = function(source, targetId)
    local target = GetPlayerPed(targetId)
    local coords = GetEntityCoords(GetPlayerPed(source))

    SetEntityCoords(target, coords.x, coords.y, coords.z, true, false, false, false)
end

lib.addCommand('dv', {
    help = 'Delete current vehicle',
}, function(source, args, raw)
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(source), false)
    if vehicle then
        DeleteEntity(vehicle)
    end
end)

lib.addCommand('goto', {
    help = 'Teleport to player',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'Target player\'s server id',
        },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    Commands.TeleportToPlayer(source, args.target)
end)

lib.addCommand('bring', {
    help = 'Teleport player',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'Target player\'s server id',
        },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    Commands.TeleportPlayer(source, args.target)
end)

lib.addCommand('toggleai', {
    help = 'Toggle ped and vehicle AI',
    restricted = 'group.admin'
}, function(source, args, raw)
    Core.ToggleAI()
end)

lib.callback.register('paradym_core:spawnVehicle', function(source, model, coords, heading, warp)
    return Commands.SpawnVehicle(source, model, coords, heading, warp)
end)

RegisterNetEvent('paradym_core:teleportToPlayer', function(targetId)
    local src = source
    local target = GetPlayerPed(targetId)
    local coords = GetEntityCoords(target)

    SetEntityCoords(GetPlayerPed(src), coords.x, coords.y, coords.z, true, false, false, false)
end)

RegisterNetEvent('paradym_core:teleportPlayer', function(targetId)
    local src = source
    local target = GetPlayerPed(targetId)
    local coords = GetEntityCoords(GetPlayerPed(src))

    SetEntityCoords(target, coords.x, coords.y, coords.z, true, false, false, false)
end)