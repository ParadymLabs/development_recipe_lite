Clothing = {}

if Settings.Debug then SetResourceKvp('player_clothing', '') end

local DatastoreService = require 'classes.datastore'
local ClothingData = DatastoreService:new('player_clothing')

Clothing.DefaultAppearance = {}
Clothing.DefaultConfig = {
    ped = true,
    headBlend = true,
    faceFeatures = true,
    headOverlays = true,
    components = true,
    props = true,
    allowExit = true,
    tattoos = true
}

Clothing.CreateClothingData = function()
    ClothingData:save({
        characters = {},
        hasData = true
    })
end

Clothing.OpenMenu = function()
    local appearance = Clothing.StartCustomization()
    if appearance then return appearance end
    return false
end

Clothing.StartCustomization = function()
    local finished = false
    local finalAppearance = nil

    exports['fivem-appearance']:startPlayerCustomization(function(appearance)
        if appearance then
            finalAppearance = appearance
            finished = true
        end
    end, Clothing.DefaultConfig)

    repeat Wait(0) until finished

    return finalAppearance
end

Clothing.UpdateCharacterAppearance = function()
    if not Core.CurrentCharacter then return end

    local appearance = Clothing.StartCustomization()
    if not appearance then return end

    Core.SetCharacterAppearance(Core.CurrentCharacter, appearance)
end

Clothing.GetOutfits = function()
    if not ClothingData.data.characters[Core.CurrentCharacter] then
        ClothingData.data.characters[Core.CurrentCharacter] = {
            outfits = {}
        }
        ClothingData:save(ClothingData.data)
    end
    return ClothingData.data.characters[Core.CurrentCharacter].outfits
end

Clothing.OpenOutfitMenu = function()
    if not Core.CurrentCharacter then return end

    local outfits = Clothing.GetOutfits()

    local menu = {
        id = 'outfit_menu',
        title = 'Character Outfits',
        options = {}
    }

    menu.options[#menu.options + 1] = {
        title = 'Create Outfit',
        onSelect = function()
            Clothing.CreateOutfit()
        end,
        icon = 'plus'
    }

    for outfitId, outfit in pairs(outfits) do
        menu.options[#menu.options + 1] = {
            title = outfit.name,
            onSelect = function()
                Clothing.SelectOutfit(outfitId)
            end,
            icon = 'shirt',
            iconColor = '#6593c7'
        }
    end

    lib.registerContext(menu)
    lib.showContext(menu.id)
end

Clothing.CreateOutfit = function()
    local input = lib.inputDialog('Create Character', {
        {type = 'input', label = 'outfit Name', required = true, min = 2},
    })

    if not input then Clothing.OpenOutfitMenu() return end

    local outfit = {
        name = input[1],
        appearance = exports['fivem-appearance']:getPedAppearance(cache.ped)
    }

    local outfits = Clothing.GetOutfits()
    outfits[#outfits + 1] = outfit

    ClothingData.data.characters[Core.CurrentCharacter].outfits = outfits
    ClothingData:save(ClothingData.data)

    lib.notify {
        title = 'Outfits',
        position = 'top',
        description = ('%s has been saved.'):format(outfit.name),
        type = 'success'
    }

    Clothing.OpenOutfitMenu()
end

Clothing.SelectOutfit = function(outfitId)
    local menu = {
        id = 'outfit_menu',
        title = 'Character Outfits',
        options = {}
    }

    menu.options[#menu.options + 1] = {
        title = 'Wear Outfit',
        onSelect = function()
            Clothing.UseOutfit(outfitId)
        end,
        icon = 'check'
    }

    menu.options[#menu.options + 1] = {
        title = 'Delete Outfit',
        onSelect = function()
            Clothing.PromptDeleteOutfit(outfitId)
        end,
        icon = 'xmark',
        iconColor = '#ff4f42'
    }

    menu.options[#menu.options + 1] = {
        title = 'Back',
        onSelect = function()
            Clothing.OpenOutfitMenu()
        end,
        icon = 'arrow-left',
    }

    lib.registerContext(menu)
    lib.showContext(menu.id)
end

Clothing.UseOutfit = function(outfitId)
    local outfit = Clothing.GetOutfits()[outfitId]
    if not outfit or not outfit.appearance then return end

    Utility.PauseRessuraction()
    Core.SetCharacterAppearance(Core.CurrentCharacter, outfit.appearance)
    exports['fivem-appearance']:setPlayerAppearance(outfit.appearance)

    lib.notify {
        title = 'Outfits',
        position = 'top',
        description = ('Outfit: %s has been applied.'):format(outfit.name),
        type = 'success'
    }
end

Clothing.PromptDeleteOutfit = function(outfitId)
    local outfit = Clothing.GetOutfits()[outfitId]
    if not outfit then return end

    local alert = lib.alertDialog({
        header = 'Outfit Deletion',
        content = ('Are you sure you want to delete %s?'):format(outfit.name),
        labels = {
            confirm = 'Delete',
        },
        centered = true,
        cancel = true
    })

    local delete = alert == 'confirm' and true or false

    if delete then
        Clothing.GetOutfits()[outfitId] = nil
        ClothingData:save(ClothingData.data)
        Clothing.OpenOutfitMenu()

        lib.notify {
            title = 'Outfits',
            position = 'top',
            description = ('%s has been deleted.'):format(outfit.name),
            type = 'success'
        }
    else
        Clothing.OpenOutfitMenu()
    end
end

Clothing.DeleteOutfits = function(characterId)
    if not ClothingData.data.characters[characterId] then return end
    ClothingData.data.characters[characterId].outfits = {}
    ClothingData:save(ClothingData.data)
end

if not ClothingData.data or not ClothingData.data.hasData then
    Utils.DebugPrint('INFO', 'Initializing player clothing datastore.')
    Clothing.CreateClothingData()
end

RegisterNetEvent('paradym_core:clothingMenu', Clothing.UpdateCharacterAppearance)
RegisterNetEvent('paradym_core:outfits', Clothing.OpenOutfitMenu)