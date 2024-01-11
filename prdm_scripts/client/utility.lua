HUD_ELEMENTS = {
    HUD = { id = 0, hidden = false },
    HUD_WANTED_STARS = { id = 1, hidden = true },
    HUD_WEAPON_ICON = { id = 2, hidden = true },
    HUD_CASH = { id = 3, hidden = true },
    HUD_MP_CASH = { id = 4, hidden = true },
    HUD_MP_MESSAGE = { id = 5, hidden = true },
    HUD_VEHICLE_NAME = { id = 6, hidden = true },
    HUD_AREA_NAME = { id = 7, hidden = true },
    HUD_VEHICLE_CLASS = { id = 8, hidden = true },
    HUD_STREET_NAME = { id = 9, hidden = true },
    HUD_HELP_TEXT = { id = 10, hidden = false },
    HUD_FLOATING_HELP_TEXT_1 = { id = 11, hidden = false },
    HUD_FLOATING_HELP_TEXT_2 = { id = 12, hidden = false },
    HUD_CASH_CHANGE = { id = 13, hidden = true },
    HUD_RETICLE = { id = 14, hidden = true },
    HUD_SUBTITLE_TEXT = { id = 15, hidden = false },
    HUD_RADIO_STATIONS = { id = 16, hidden = false },
    HUD_SAVING_GAME = { id = 17, hidden = false },
    HUD_GAME_STREAM = { id = 18, hidden = false },
    HUD_WEAPON_WHEEL = { id = 19, hidden = false },
    HUD_WEAPON_WHEEL_STATS = { id = 20, hidden = false },
    MAX_HUD_COMPONENTS = { id = 21, hidden = false },
    MAX_HUD_WEAPONS = { id = 22, hidden = false },
    MAX_SCRIPTED_HUD_COMPONENTS = { id = 141, hidden = false }
}

HUD_HIDE_RADAR_ON_FOOT = true

AI_ENABLED = true

local function CreateCar(model, x, y, z, heading)
    local vehicle = CreateVehicle(model, x, y, z, heading, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    
    return vehicle
end

RegisterCommand("car", function(source, args, rawCommand)
    local model = joaat(args[1])
    
    if not IsModelInCdimage(model) then lib.notify({
        title = 'Vehicle',
        description = 'Invalid model: '..string.lower(args[1]),
        type = 'error',
        position = 'top'
    }) return end

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    local coords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)

    local vehicle = CreateCar(model, coords.x, coords.y, coords.z, heading)

    SetPedIntoVehicle(cache.ped, vehicle, -1)

    lib.notify({
        title = 'Vehicle',
        description = 'Spawning vehicle: '..string.lower(args[1]),
        type = 'success',
        position = 'top'
    })

    SetModelAsNoLongerNeeded(model)
end)

TriggerEvent('chat:addSuggestion', '/car', 'Spawn a car', {
    { name="vehicle", help="the vehicle model" },
})


RegisterCommand('dv', function()
    if not IsPedInAnyVehicle(cache.ped, false) then lib.notify({
        title = 'Vehicle',
        description = 'You are not in a vehicle',
        type = 'error',
        position = 'top'
    }) return end

    local vehicle = GetVehiclePedIsIn(cache.ped, false)

    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)

    lib.notify({
        title = 'Vehicle',
        description = 'Vehicle deleted',
        type = 'success',
        position = 'top'
    })
end)

CreateThread(function()
    SetMaxWantedLevel(0)
    SetPoliceIgnorePlayer(cache.ped, true)
    SetDispatchCopsForPlayer(cache.ped, false)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_LOST`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_SALVA`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_HILLBILLY`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_BALLAS`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_MEXICAN`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_FAMILY`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_MARABUNTE`, `PLAYER`)

    SetRelationshipBetweenGroups(1, `GANG_1`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `GANG_2`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `GANG_9`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `GANG_10`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `FIREMAN`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `MEDIC`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `COP`, `PLAYER`)
end)


RegisterCommand("time" , function(source, args, rawCommand)
    local hour = tonumber(args[1])
    local minute = tonumber(args[2])
    if hour and minute then
        NetworkOverrideClockTime(hour, minute, 0)
    else
        lib.notify({
            title = 'Time',
            description = 'Invalid time',
            type = 'error',
            position = 'top'
        })
    end
end)

TriggerEvent('chat:addSuggestion', '/time', 'Set time of day', {
    { name="hours", help="the hour to sat the current time to" },
    { name="minutes", help="the minutes to set the current time to" }
})

RegisterCommand("weather" , function(source, args, rawCommand)
    local weather = args[1]
    if weather then
        SetWeatherTypeOvertimePersist(weather, 30.0)
    else
        lib.notify({
            title = 'Weather',
            description = 'Invalid weather',
            type = 'error',
            position = 'top'
        })
    end
end)

TriggerEvent('chat:addSuggestion', '/weather', 'Set the current weather', {
    { name="weather", help="the weather type" },
})

RegisterCommand("toggleai" , function(source, args, rawCommand)
    AI_ENABLED = not AI_ENABLED
    
    if AI_ENABLED then
        lib.notify({
            title = 'AI',
            description = 'Enabled AI',
            type = 'success',
            position = 'top'
        })
        SetPedPopulationBudget(3)
        return
    end

    lib.notify({
        title = 'AI',
        description = 'Disabled AI',
        type = 'success',
        position = 'top'
    })

    while not AI_ENABLED do
        local playerId = PlayerId()

        --[[ DISABLE VEHICLE GENERATORS IN PLAYER AREA ]]
        local pos = GetEntityCoords(cache.ped)
        RemoveVehiclesFromGeneratorsInArea(
            pos['x'] - 500.0,
            pos['y'] - 500.0,
            pos['z'] - 500.0,
            pos['x'] + 500.0,
            pos['y'] + 500.0,
            pos['z'] + 500.0
        )

        --[[ POLICE DISPATCH SPAWNS OFF ]]
        for i = 1, 12 do
            EnableDispatchService(i, false)
        end

        --[[ PED POPULATION OFF ]]
        SetPedPopulationBudget(0)
        SetPedDensityMultiplierThisFrame(0)
        SetScenarioPedDensityMultiplierThisFrame(0, 0)

        --[[ VEHICLE POPULATION OFF ]]
        SetPedPopulationBudget(0)
        SetVehicleDensityMultiplierThisFrame(0)
        SetRandomVehicleDensityMultiplierThisFrame(0)
        SetParkedVehicleDensityMultiplierThisFrame(0)

        Wait(0)
	end
end)

CreateThread(function()
    while true do
        Wait(0)

        if HUD_HIDE_RADAR_ON_FOOT then
            DisplayRadar(IsPedInAnyVehicle(cache.ped, false))
            SetRadarZoomLevelThisFrame(200.0)
        end

        for _, data in pairs(HUD_ELEMENTS) do
            if data.hidden then
                HideHudComponentThisFrame(data.id)
            else
                ShowHudComponentThisFrame(data.id)
            end
        end
    end
end)

