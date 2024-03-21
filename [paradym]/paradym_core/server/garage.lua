
RegisterNetEvent('paradym_core:unStoreVehicle', function(netId, vehicleId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle then Utils.DebugPrint('ERROR', ('Error retrieving vehicle. vehicle: %s'):format(vehicle)) return end

    local ownerData = {
        owner = Core.Characters[src].player.identifier,
        characterId = Core.Characters[src].id,
        vehicleId = vehicleId
    }

    Entity(vehicle).state:set('ownedvehicle', ownerData, true)
end)