Commands = {}

Commands.SpawnServerVehicle = function(model)
    local coords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)
    local existingVehicle = GetVehiclePedIsIn(cache.ped, false)
    if existingVehicle then
        DeleteEntity(existingVehicle)
    end

    lib.callback.await('paradym_core:spawnVehicle', false, model, coords, heading, true)
end

Commands.ShowId = function()
    lib.notify({
        title = 'Your ID',
        description = ('Your ID is %s'):format(GetPlayerServerId(PlayerId())),
        type = 'info',
        position = 'top'
    })
end

lib.callback.register('paradym_core:initVehicle', function(netId)
    lib.waitFor(function()
        local vehicle = NetToVeh(netId)
        if DoesEntityExist(vehicle) then return true end
        return false
    end, 'Failed loading vehicle', 1000)

    local vehicle = NetToVeh(netId)

    lib.waitFor(function()
        if NetworkGetEntityOwner(vehicle) == PlayerId() then return true end
        return false
    end, 'Failed loading vehicle', 1000)

    if NetworkGetEntityOwner(vehicle) == PlayerId() then 
        for i = -1, 9 do
            local ped = GetPedInVehicleSeat(vehicle, i)
            if ped ~= 0 then
                DeleteEntity(ped)
            end
        end
        return true
    end
    return false
end)

RegisterCommand('clothing', function(source, args, rawCommand)
    TriggerEvent('paradym_core:clothingMenu')
end)

TriggerEvent('chat:addSuggestion', '/clothing', 'Open the clothing menu')

RegisterCommand('outfits', function(source, args, rawCommand)
    TriggerEvent('paradym_core:outfits')
end)

TriggerEvent('chat:addSuggestion', '/outfits', 'Open the outfits menu')

RegisterCommand('logout', function(source, args, rawCommand)
    Core.Logout()
end)

TriggerEvent('chat:addSuggestion', '/logout', 'Logout of the current character')

RegisterCommand('revive', function(source, args, rawCommand)
    local coords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, false, false)
end)

RegisterCommand('car', function(source, args, raw)
    Commands.SpawnServerVehicle(args[1])
end)

RegisterCommand('garage', function(source, args, raw)
    Garage.OpenGarageMenu()
end)

RegisterCommand('impound', function(source, args, raw)
    Impound.OpenImpoundMenu()
end)

RegisterCommand('savevehicle', function(source, args, raw)
    Garage.SaveCurrentVehicle()
end)

TriggerEvent('chat:addSuggestion', '/car', 'Spawn a car', {
    { name="model", help="The model of the car to spawn" }
})

RegisterCommand('myid', function(source, args, raw)
    Commands.ShowId()
end)

RegisterCommand('defaultchar', function(source, args, rawCommand)
    Core.SelectDefaultCharacter()
end)

RegisterCommand('parsevehicles', function(source, args, raw)
    VehicleParser.SaveVehicleData()
end)