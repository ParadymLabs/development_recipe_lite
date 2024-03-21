Garage = {}
Impound = {}

if Settings.Debug then SetResourceKvp('player_garage', '') end

local DatastoreService = require 'classes.datastore'
local GarageData = DatastoreService:new('player_garage')

Garage.VehicleModelData = LoadResourceFile('paradym_core', "data/vehicle_models.json")
Garage.VehicleModels = {}

Garage.CreateGarageData = function()
    GarageData:save({
        characters = {},
        hasData = true
    })
end

Garage.GetGarageData = function()
    return GarageData.data
end

Garage.GetVehicles = function()
    if not GarageData.data.characters[Core.CurrentCharacter] then
        GarageData.data.characters[Core.CurrentCharacter] = {
            vehicles = {}
        }
        GarageData:save(GarageData.data)
    end
    return GarageData.data.characters[Core.CurrentCharacter].vehicles
end

Garage.LoadVehicleModels = function()
    local vehicleData = json.decode(Garage.VehicleModelData) or {}
    local newData = {}

    for hash, data in pairs(vehicleData) do
        newData[math.floor(hash)] = data
    end

    Garage.VehicleModels = newData
end

Garage.GetGarageDataForCharacter = function(characterId)
    return GarageData.data.characters[characterId]
end

Garage.GetGarageDataForCurrentCharacter = function()
    return GarageData.data.characters[Core.CurrentCharacter]
end

Garage.SaveCurrentVehicle = function()
    if not Core.CurrentCharacter then Utils.DebugPrint('ERROR', 'GARAGE: No character loaded') return end
    local characterId = Core.CurrentCharacter

    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if not vehicle then return end

    local props = Garage.GetVehicleProperties()
    if not props then return end

    local input = lib.inputDialog('Save Vehicle', {
        {type = 'input', label = 'Vehicle Name', required = true, min = 2},
    })

    if not input then lib.notify({
        title = 'Garage',
        description = 'Invalid input, please try again.',
        type = 'error'
    }) return end

    local vehicleData = {
        name = input[1],
        model = GetEntityModel(vehicle),
        props = props,
        stored = true
    }

    local vehicles = Garage.GetVehicles()
    vehicles[#vehicles + 1] = vehicleData

    GarageData.data.characters[characterId].vehicles = vehicles
    GarageData:save(GarageData.data)
end

Garage.SelectVehicle = function(vehicleId)
    local menu = {
        id = 'garage_vehicle_options',
        title = 'Vehicle Options',
        options = {}
    }

    menu.options[#menu.options + 1] = {
        title = 'Spawn Vehicle',
        onSelect = function()
            Garage.SpawnVehicle(vehicleId)
        end,
        icon = 'car'
    }

    menu.options[#menu.options + 1] = {
        title = 'Delete Vehicle',
        onSelect = function()
            Garage.PromptDeleteVehicle(vehicleId)
        end,
        icon = 'edit'
    }

    lib.registerContext(menu)
    lib.showContext(menu.id)
end

Garage.PromptDeleteVehicle = function(vehicleId)
    local vehicle = Garage.GetVehicles()[vehicleId]
    if not vehicle then return end

    local alert = lib.alertDialog({
        header = 'Vehicle Deletion',
        content = ('Are you sure you want to delete %s?'):format(vehicle.name),
        labels = {
            confirm = 'Delete',
        },
        centered = true,
        cancel = true
    })
     
    local delete = alert == 'confirm' and true or false

    if delete then
        Garage.GetVehicles()[vehicleId] = nil
        GarageData:save(GarageData.data)
        Garage.OpenGarageMenu()
    else
        Garage.OpenGarageMenu()
    end
end

Garage.DeleteVehicles = function(vehicleId)
    -- Do this
end

Garage.SpawnVehicle = function(vehicleId)
    local vehicles = Garage.GetVehicles()
    local vehicleData = vehicles[vehicleId]
    if not vehicleData then return end

    if not vehicleData.stored then
        lib.notify({
            title = 'Garage',
            position = 'top',
            description = 'This vehicle is not stored in the garage.',
            type = 'error'
        })
        return
    end

    local currentVehicle = GetVehiclePedIsIn(cache.ped, false)
    if currentVehicle then
        DeleteEntity(currentVehicle)
    end

    local model = Garage.VehicleModels[vehicleData.model].model
    local coords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)
    local netId = lib.callback.await('paradym_core:spawnVehicle', false, model, coords, heading, true)
    local vehicle = NetToVeh(netId)

    TriggerServerEvent('paradym_core:unStoreVehicle', NetworkGetNetworkIdFromEntity(vehicle), vehicleId)

    vehicles[vehicleId].stored = false

    GarageData.data.characters[Core.CurrentCharacter].vehicles = vehicles
    GarageData:save(GarageData.data)

    Garage.SetVehicleProperies(vehicle, vehicleData.props, false)

    lib.notify {
        title = 'Garage',
        position = 'top',
        description = ('%s has been retrieved'):format(vehicleData.name),
        type = 'success'
    }
end

Garage.StoreVehicle = function()
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if not vehicle then return end

    local identifier = Core.GetPlayerInfoOne('identifier')
    local ownerData = Entity(vehicle).state.ownedvehicle

    if not ownerData or not ownerData.owner then
        lib.notify({
            title = 'Garage',
            position = 'top',
            description = 'You cannot store this vehicle',
            type = 'error'
        })
        return
    end

    if ownerData.owner ~= identifier then
        lib.notify({
            title = 'Garage',
            position = 'top',
            description = 'You cannot store a vehicle that is not yours.',
            type = 'error'
        })
        return
    end

    local props = Garage.GetVehicleProperties()
    if not props then return end

    local vehicleData = Garage.GetVehicles()[ownerData.vehicleId]
    if not vehicleData then return end

    vehicleData.props = props
    vehicleData.stored = true

    GarageData.data.characters[Core.CurrentCharacter].vehicles[ownerData.vehicleId] = vehicleData
    GarageData:save(GarageData.data)

    lib.notify {
        title = 'Garage',
        position = 'top',
        description = ('%s has been stored successfully'):format(vehicleData.name),
        type = 'success'
    }

    DeleteEntity(vehicle)
end

Garage.OpenGarageMenu = function()
    if not Core.CurrentCharacter then return end

    local vehicles = Garage.GetVehicles()
    
    local menu = {
        id = 'garage_menu',
        title = 'Garage',
        options = {}
    }

    menu.options[#menu.options + 1] = {
        title = 'Store Vehicle',
        onSelect = function()
            Garage.StoreVehicle()
        end,
        icon = 'plus'
    }

    for vehicleId, vehicle in pairs(vehicles) do
        menu.options[#menu.options + 1] = {
            title = vehicle.name,
            onSelect = function()
                Garage.SelectVehicle(vehicleId)
            end,
            icon = 'car'
        }
    end

    lib.registerContext(menu)
    lib.showContext(menu.id)
end

Garage.GetVehicleProperties = function()
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if not vehicle then return end

    local props = lib.getVehicleProperties(vehicle)

    return props
end

Garage.LoadVehicleModels()

Garage.SetVehicleProperies = function(vehicle, props, fixVehicle)
    if not vehicle or not props then return end
    lib.setVehicleProperties(vehicle, props, fixVehicle)
end

Impound.ClaimVehicle = function (vehicleId)
    local vehicles = Garage.GetVehicles()
    vehicles[vehicleId].stored = true

    GarageData.data.characters[Core.CurrentCharacter].vehicles = vehicles
    GarageData:save(GarageData.data)

    lib.notify {
        title = 'Garage',
        position = 'top',
        description = ('%s has been claimed successfully'):format(vehicles[vehicleId].name),
        type = 'success'
    }

    Impound.OpenImpoundMenu()
end

Impound.ImpoundOptions = function(vehicleId)
    local menu = {
        id = 'impound_options',
        title = 'Impound Options',
        options = {}
    }

    menu.options[#menu.options + 1] = {
        title = 'Claim Vehicle',
        onSelect = function()
            Impound.ClaimVehicle(vehicleId)
        end,
        icon = 'car'
    }

    menu.options[#menu.options + 1] = {
        title = 'Back',
        onSelect = function()
            Impound.OpenImpoundMenu()
        end,
        icon = 'arrow-left'
    }

    lib.registerContext(menu)
    lib.showContext(menu.id)
end

Impound.OpenImpoundMenu = function()
    if not Core.CurrentCharacter then return end

    local vehicles = Garage.GetVehicles()
    
    local menu = {
        id = 'impound_menu',
        title = 'Impound Lot',
        options = {}
    }

    for vehicleId, vehicle in pairs(vehicles) do
        if not vehicle.stored then
            menu.options[#menu.options + 1] = {
                title = vehicle.name,
                onSelect = function()
                    Impound.ImpoundOptions(vehicleId)
                end,
                icon = 'car'
            }
        end
    end

    lib.registerContext(menu)
    lib.showContext(menu.id)
end

if not GarageData.data or not GarageData.data.hasData then
    Utils.DebugPrint('INFO', 'Initializing player garage datastore.')
    Garage.CreateGarageData()
end