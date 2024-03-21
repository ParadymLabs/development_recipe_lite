VehicleParser = {}

VehicleParser.generateVehicleData = function(processAll)
    local models = GetAllVehicleModels()
    local numModels = #models
    local numParsed = 0
    local coords = GetEntityCoords(cache.ped)
    local vehicleData = {}
    local hashMap = {}

    SetPlayerControl(cache.playerId, false, 1 << 8)

    lib.notify({
        title = 'Generating vehicle data',
        position = 'top',
        description = ('%d models loaded.'):format(numModels),
        type = 'info'
    })

    for i = 1, numModels do
        local model = models[i]:lower()

        if processAll then
            local hash = lib.requestModel(model)

            if hash then
                local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z + 10, 0.0, false, false)
                local make = GetMakeNameFromVehicleModel(hash)

                if make == '' then
                    local make2 = GetMakeNameFromVehicleModel(model:gsub('%A', ''))

                    if make2 ~= 'CARNOTFOUND' then
                        make = make2
                    end
                end

                SetPedIntoVehicle(cache.ped, vehicle, -1)

                local class = GetVehicleClass(vehicle)
                local vType

                if IsThisModelACar(hash) then
                    vType = 'automobile'
                elseif IsThisModelABicycle(hash) then
                    vType = 'bicycle'
                elseif IsThisModelABike(hash) then
                    vType = 'bike'
                elseif IsThisModelABoat(hash) then
                    vType = 'boat'
                elseif IsThisModelAHeli(hash) then
                    vType = 'heli'
                elseif IsThisModelAPlane(hash) then
                    vType = 'plane'
                elseif IsThisModelAQuadbike(hash) then
                    vType = 'quadbike'
                elseif IsThisModelATrain(hash) then
                    vType = 'train'
                else
                    vType = (class == 5 and 'submarinecar') or (class == 14 and 'submarine') or (class == 16 and 'blimp') or 'trailer'
                end

                local data = {
                    name = GetLabelText(GetDisplayNameFromVehicleModel(hash)),
                    make = make == '' and make or GetLabelText(make),
                    class = class,
                    seats = GetVehicleModelNumberOfSeats(hash),
                    weapons = DoesVehicleHaveWeapons(vehicle) or nil,
                    doors = GetNumberOfVehicleDoors(vehicle),
                    type = vType,
                }

                local hashData = {
                    model = model,
                    name = data.name,
                    hash = hash,
                }

                vehicleData[model] = data
                hashMap[hash] = hashData
                numParsed += 1

                SetVehicleAsNoLongerNeeded(vehicle)
                DeleteEntity(vehicle)
                SetModelAsNoLongerNeeded(hash)
                SetEntityCoordsNoOffset(cache.ped, coords.x, coords.y, coords.z, false, false, false)

                Utils.DebugPrint('INFO', ('Generated vehicle data for model: %s'):format(model))
            end
        end
    end

    lib.notify({
        title = 'Generated vehicle data',
        position = 'top',
        description = ('Generated new vehicle data for %d/%d models'):format(numParsed, numModels),
        type = 'success'
    })

    SetPlayerControl(cache.playerId, true, 0)

    return vehicleData, hashMap
end

VehicleParser.SaveVehicleData = function()
    local vehicleData, hashMap = VehicleParser.generateVehicleData(true)

    if vehicleData and next(vehicleData) then
        lib.callback.await('paradym_core:saveVehicleData', false, vehicleData, hashMap)
    end
end