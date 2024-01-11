CLOTHING_CURRENT = GetResourceKvpString("clothing_current")
SAVES = json.decode(GetResourceKvpString("clothing")) or {}

PEDS = {}

RegisterCommand("clothing", function()
	local config = {
		ped = true,
		headBlend = true,
		faceFeatures = true,
		headOverlays = true,
		components = true,
		props = true,
		allowExit = true,
		tattoos = true,
	}

	exports["fivem-appearance"]:startPlayerCustomization(function(appearance)
		if appearance then
			SetResourceKvp("clothing_current", json.encode(appearance))
		end
	end, config)
end, false)

TriggerEvent('chat:addSuggestion', '/clothing', 'Open the clothing menu', {})

local function loadAppearance(outfit)
	local coords = GetEntityCoords(cache.ped)
	exports["fivem-appearance"]:setPlayerAppearance(outfit)
	SetEntityCoords(cache.ped, coords.x, coords.y, coords.z + 1.0, false, false, false, false)
end

local function ShowOutfits()
	local items = {}
	local name, outfit = nil, nil

	for _name, _outfit in pairs(SAVES) do
		table.insert(items, {
			title = 'Outfit: '.._name,
			icon = 'shirt',
			onSelect = function()
				name, outfit = _name, _outfit
			end,
		})
	end

	lib.registerContext({
		id = 'outfit_menu',
		title = 'OUTFITS',
		options = items,
	})

	lib.showContext('outfit_menu')

	repeat Wait(0)
	until name ~= nil

	return name, outfit
end

local function SaveOutfit()
	local outfitName = nil

	lib.registerContext({
		id = 'outfit_save',
		title = 'OUTFITS',
		options = {
			{
				title = 'Save New Outfit',
				icon = 'plus',
				onSelect = function()
					local input = lib.inputDialog('SAVE OUTFIT', {'Outfit Name'})

					if not input then
						lib.notify({
							title = 'Save Outfit',
							description = 'Invalid name',
							type = 'error',
							position = 'top'
						})
						return
					end

					outfitName = input[1]
				end,
			},
			{
				title = 'Save Existing Outfit',
				icon = 'save',
				onSelect = function()
					local name, _ = ShowOutfits()
					
					if not name then
						lib.notify({
							title = 'Save Outfit',
							description = 'Error selecting outfit',
							type = 'error',
							position = 'top'
						})
						return
					end

					outfitName = name
				end,
			},
		},
	})

	lib.showContext('outfit_save')

	local tries = 0

	if not outfitName then
		repeat Wait(100) tries = tries + 1
		until outfitName ~= nil or tries > 60000

		if not outfitName then
			lib.notify({
				title = 'Save Outfit',
				description = 'No outfit selected',
				type = 'error',
				position = 'top'
			})
			return
		end
	end

	local appearance = exports["fivem-appearance"]:getPedAppearance(cache.ped)
	SAVES[outfitName] = appearance

	SetResourceKvp("clothing", json.encode(SAVES))

	lib.notify({
		title = 'Save Outfit',
		description = 'Successfully saved outfit: '..outfitName,
		type = 'success',
		position = 'top'
	})
end

local function LoadOutfit()
	local name, outfit = ShowOutfits()
	
	loadAppearance(outfit)

	lib.notify({
		title = 'Load Outfit',
		description = 'Successfully loaded outfit: '..name,
		type = 'success',
		position = 'top'
	})
end

local function DeleteOutfit()
	local name, _ = ShowOutfits()

	if not name then
		lib.notify({
			title = 'Delete Outfit',
			description = 'Error selecting outfit',
			type = 'error',
			position = 'top'
		})
		return
	end

	SAVES[name] = nil

	SetResourceKvp("clothing", json.encode(SAVES))

	lib.notify({
		title = 'Delete Outfit',
		description = 'Successfully deleted outfit: '..name,
		type = 'success',
		position = 'top'
	})
end

RegisterCommand("outfit", function(source, args, rawCommand)
	lib.registerContext({
		id = 'outfit_managememt',
		title = 'OUTFITS',
		options = {
			{
				title = 'Save Outfit',
				icon = 'plus',
				onSelect = function()
					SaveOutfit()
				end,
			},
			{
				title = 'Load Outfit',
				icon = 'shirt',
				onSelect = function()
					LoadOutfit()
				end,
			},
			{
				title = 'Delete Outfit',
				icon = 'trash',
				onSelect = function()
					DeleteOutfit()
				end,
			},
		},
	})

	lib.showContext('outfit_managememt')
end)

TriggerEvent('chat:addSuggestion', '/outfit', 'Manage outfits', {})

RegisterCommand("copyped", function(source, args, rawCommand)
	local appearance = exports["fivem-appearance"]:getPedAppearance(cache.ped)
	local model = appearance.model

	RequestModel(model)
	while not HasModelLoaded(model) do
		Wait(0)
	end

	local coords = GetEntityCoords(cache.ped) + GetEntityForwardVector(cache.ped) * 1.5
	local heading = GetEntityHeading(cache.ped) + 180.0

	local ped = CreatePed(4, model, coords.x, coords.y, coords.z, heading, false, false)
	exports["fivem-appearance"]:setPedAppearance(ped, appearance)

	PEDS[#PEDS+1] = ped
end)

RegisterCommand("clearpeds", function(source, args, rawCommand)
	for _, ped in ipairs(PEDS) do
		DeleteEntity(ped)
	end

	PEDS = {}
end)

if CLOTHING_CURRENT then
	CLOTHING_CURRENT = json.decode(CLOTHING_CURRENT)
	loadAppearance(CLOTHING_CURRENT)
end
