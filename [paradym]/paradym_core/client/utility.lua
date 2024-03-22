Utility = {}

Utility.AiEnabled = true
Utility.Resurrecting = false
Utility.AllowResurrect = true

Utility.ResurrectPlayer = function()
    if not Utility.AllowResurrect then return end

    Wait(100)

    if GetEntityHealth(cache.ped) > 0 then
        return
    end

    Utility.Resurrecting = true

    lib.notify({
        title = 'Resurrect',
        position = 'top',
        description = 'You have died. You will be resurrected in 5 seconds.',
        type = 'info'
    })

    CreateThread(function()
        Wait(5000)
        local coords = GetEntityCoords(cache.ped)
        local heading = GetEntityHeading(cache.ped)

        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, false, false)
        Utility.Resurrecting = false
    end)
end

Utility.PauseRessuraction = function()
    Utility.AllowResurrect = false
    CreateThread(function()
        Wait(2000)
        Utility.AllowResurrect = true
    end)
end

Utility.TaskAiThread = function()
    CreateThread(function()
        while not Utility.AiEnabled do
            local pos = GetEntityCoords(cache.ped)

            RemoveVehiclesFromGeneratorsInArea(
                pos['x'] - 500.0,
                pos['y'] - 500.0,
                pos['z'] - 500.0,
                pos['x'] + 500.0,
                pos['y'] + 500.0,
                pos['z'] + 500.0
            )

            SetPedDensityMultiplierThisFrame(0)
            SetVehicleDensityMultiplierThisFrame(0)
            SetRandomVehicleDensityMultiplierThisFrame(0)
            SetParkedVehicleDensityMultiplierThisFrame(0)
            SetScenarioPedDensityMultiplierThisFrame(0, 0)
            Wait(0)
        end
    end)
end

Utility.SetAIEnabled = function(toggle)
    Utility.AiEnabled = toggle

    local budget = toggle and 3 or 0

    lib.notify({
        title = 'AI Toggle',
        position = 'top',
        description = ('AI has been %s'):format(toggle and 'Enabled' or 'Disabled'),
        type = 'info'
    })

    SetPedPopulationBudget(budget)
    SetVehiclePopulationBudget(budget)

    if not Utility.AiEnabled then
        Utility.TaskAiThread()
    end
end