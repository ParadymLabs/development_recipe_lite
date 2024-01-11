DEFAULT_SPAWN = vector4(211.5960, -799.0718, 30.8932, 153.3906)

CreateThread(function()
    local spawn = GetResourceKvpString("spawn")
    spawn = json.decode(spawn) or DEFAULT_SPAWN

    ShutdownLoadingScreen()
    FreezeEntityPosition(cache.ped, false)
    SetEntityCoords(cache.ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
    SetEntityHeading(cache.ped, spawn.w)

    while true do
        local position = GetEntityCoords(cache.ped, false)
        local heading = GetEntityHeading(cache.ped)
        if GetEntityHealth(cache.ped) <= 0 then
            NetworkResurrectLocalPlayer(position.x, position.y, position.z, heading, true, false)
        end
        SetResourceKvp("spawn", json.encode(position))
        Wait(1000)
    end
end)

RegisterCommand("revive", function()
    local position = GetEntityCoords(cache.ped, false)
    local heading = GetEntityHeading(cache.ped)
    NetworkResurrectLocalPlayer(position.x, position.y, position.z, heading, true, false)
    lib.notify({
        title = '',
        description = 'You have been revived',
        type = 'success',
        position = 'top'
    })
end)
