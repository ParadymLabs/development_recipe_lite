local spawn = GetResourceKvpString("spawn")
spawn = spawn and json.decode(spawn) or vector3(0, 0, 70)

ShutdownLoadingScreen()

local ped = cache.ped

print(ped)