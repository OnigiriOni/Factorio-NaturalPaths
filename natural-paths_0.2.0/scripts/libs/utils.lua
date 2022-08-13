require("scripts/libs/const")
require("scripts/libs/debug")


-----------------------------------------------------------------------------------------
-- Math
-----------------------------------------------------------------------------------------


-- Returns the sign of the given number.
function Sign(number)
    return (number > 0 and 1) or (number == 0 and 0) or -1
end


-----------------------------------------------------------------------------------------
-- Validation
-----------------------------------------------------------------------------------------


-- Returns if the given surface is alowed to be modified by this mod.
function IsSurfaceValid(surfaceName)
    for _, invalidSurfaceName in pairs(INVALID_SURFACES) do
        if string.find(surfaceName, invalidSurfaceName) then return false end
    end

    return true
end


-- Returns if the given tile is alowed to receive deterioration.
function IsSurfaceTileValid(surfaceTileName)
    for name, _ in pairs(TILE_INFO) do
        if surfaceTileName == name then return true end
    end

    return false
end


-- Returns if the given vehicle is alowed to deteriorate tiles.
function IsVehicleValid(vehicleType)
    for _, invalidVehicleType in pairs(INVALID_VEHICLES) do
        if vehicleType == invalidVehicleType then return false end
    end

    return true
end


-- Returns if the tile can be modified.
function CanTileDeteriorate(surfaceTile)
    -- I do not fully understand the concept of the hidden tile in this check but the mod this is based on had it.
    if surfaceTile.hidden_tile then return false end

    if not IsSurfaceTileValid(surfaceTile.name) then return false end

    return true
end


-- Returns if the given player is the driver of the vehicle they are in.
function IsPlayerDriver(player)
    local driver = player.vehicle.get_driver()

    -- The driver can be an entity or player so we check for both.
    -- If the name is not equal then we might check an entity whith name == 'character'.
    -- In this case get the player of the entity and check again.
    if driver.name ~= player.name then
        driver = driver.player

        if driver.name ~= player.name then
            return false
        end
    end

    return true
end


-- Checks if a player can deteriorate tiles.
function CanPlayerDeteriorateTiles(player)
    -- Godmode , edit-mode and other instances where a player might not have a character to walk with.
    if not player.character then return false end
    if not IsSurfaceValid(player.surface.name) then return false end

    if player.walking_state.walking then
        -- Jetpack Mod - Check if the character is flying with the jetpack.
        if isPlayerUsingJetpack(player) then return false end
        return true
    end

    if player.vehicle then
        -- Let the driver player apply the deterioration. Multipayer clown taxis should not apply deterioration multiple times.
        if not IsPlayerDriver(player) then return false end
        if not IsVehicleValid(player.vehicle.type) then return false end
        return true
    end

    return false
end


-----------------------------------------------------------------------------------------
-- Weight
-----------------------------------------------------------------------------------------


-- Returns the weight of an item stack.
function GetMaxStackWeight(maxStackSize)
    local lastEntry = 0
    for key, value in pairs(INVENTORY_STACK_WEIGHTS) do
        lastEntry = value
        if maxStackSize <= key then
            return value
        end
    end

    return lastEntry
end


-- Returns the current weight of the given inventory.
function GetInventoryWeight(inventory)
    local inventoryWeight = 0

    for i = 1, #inventory, 1 do
        local itemStack = inventory[i]

        if itemStack.valid_for_read then
            local maxStackSize = itemStack.prototype.stack_size
            local itemWeight = GetMaxStackWeight(maxStackSize) / maxStackSize
            local currentStackWeight = itemWeight * itemStack.count
            inventoryWeight = inventoryWeight + currentStackWeight
        end
    end

    return inventoryWeight
end


-- Returns the weight of the characters inventory, including main, trash, armor, guns & ammo.
function GetCharacterInventoryWeight(player)
    local inventoryWeight = 0
    inventoryWeight = inventoryWeight + GetInventoryWeight(player.get_inventory(defines.inventory.character_main))
    inventoryWeight = inventoryWeight + GetInventoryWeight(player.get_inventory(defines.inventory.character_guns))
    inventoryWeight = inventoryWeight + GetInventoryWeight(player.get_inventory(defines.inventory.character_ammo))
    inventoryWeight = inventoryWeight + GetInventoryWeight(player.get_inventory(defines.inventory.character_armor))
    inventoryWeight = inventoryWeight + GetInventoryWeight(player.get_inventory(defines.inventory.character_trash))

    return inventoryWeight
end


-- Returns the weight of the vehicles inventory, including main, fuel & ammo.
function GetVehicleInventoryWeight(vehicle)
    local inventoryWeight = 0
    inventoryWeight = inventoryWeight + GetInventoryWeight(vehicle.get_inventory(defines.inventory.fuel))

    if vehicle.type == "spider-vehicle" then
        inventoryWeight = inventoryWeight + GetInventoryWeight(vehicle.get_inventory(defines.inventory.spider_trunk))
        inventoryWeight = inventoryWeight + GetInventoryWeight(vehicle.get_inventory(defines.inventory.spider_ammo))
    else
        inventoryWeight = inventoryWeight + GetInventoryWeight(vehicle.get_inventory(defines.inventory.car_trunk))
        inventoryWeight = inventoryWeight + GetInventoryWeight(vehicle.get_inventory(defines.inventory.car_ammo))
    end

    return inventoryWeight
end


-- Returns the current weight of the player character.
function GetCharacterWeight(player, characterInfo)
    local characterWeight = characterInfo.weight
    characterWeight = characterWeight + GetCharacterInventoryWeight(player)

    return characterWeight
end


-- Returns the current weight of the vehicle.
function GetVehicleWeight(player, vehicleInfo)
    local vehicleWeight = vehicleInfo.weight
    local characterInfo = VEHICLES["character"]

    -- Add the passenger weight to the total weight.
    -- Fix the getVehicleWeight() passenger.
    -- Getting a driver or passenger returns either a player or character.
    local passenger = player.vehicle.get_passenger()
    local passengerWeight = 0
    if passenger then
        passengerWeight = GetCharacterWeight(passenger, characterInfo)
    end

    vehicleWeight = vehicleWeight + GetVehicleInventoryWeight(player.vehicle)
    vehicleWeight = vehicleWeight + GetCharacterWeight(player, characterInfo) + passengerWeight

    -- Distribute the weight among each spidertron leg.
    if player.vehicle.type == "spider-vehicle" then
        vehicleWeight = vehicleWeight / #player.vehicle.get_spider_legs()
    end

    return vehicleWeight
end


-----------------------------------------------------------------------------------------
-- Pattern Tiles
-----------------------------------------------------------------------------------------


function GetSurfaceTilesInPattern(player, vehicleInfo)
    local pattern = PATTERNS[vehicleInfo.pattern]
    local surfaceTilesToEdit = {}

    if player.vehicle and player.vehicle.type == "spider-vehicle" then
        for _, leg in pairs(player.vehicle.get_spider_legs()) do
            for _, offset in pairs(pattern) do
                table.insert(surfaceTilesToEdit, player.surface.get_tile(leg.position.x + offset.x, leg.position.y + offset.y))
            end
        end
    else
        for _, offset in pairs(pattern) do
            table.insert(surfaceTilesToEdit, player.surface.get_tile(player.position.x + offset.x, player.position.y + offset.y))
        end
    end

    return surfaceTilesToEdit
end


-----------------------------------------------------------------------------------------
-- Factorio
-----------------------------------------------------------------------------------------


-- Changes textures of given tiles on the given surface.
function UpdateTextureOfSurfaceTiles(surface, tiles)
    if #tiles > 0 then
        -- Don't enforce collision checks on new tiles. So desert doesn't delete entities.
        -- set_tiles(tiles, correct tiles, remove colliding entities, remove colliding decoratives, raise event)
        surface.set_tiles(tiles, true, false, true)
    end
end


-----------------------------------------------------------------------------------------
-- Print
-----------------------------------------------------------------------------------------


-- Makes printing for plurals more enjoyable.
function SurfacesToString(number)
    local desc = (number ~= 1 and " surfaces" or " surface")
    return number .. desc
end


-- Makes printing for plurals more enjoyable.
function ChunksToString(number)
    local desc = (number ~= 1 and " chunks" or " chunk")
    return number .. desc
end


-- Makes printing for plurals more enjoyable.
function EntriesToString(number)
    local desc = (number ~= 1 and " entries" or " entry")
    return number .. desc
end

-- Makes printing table information more enjoyable.
function EntriesInChunksOnSurfacesToString(entries, chunks, surfaces)
    return EntriesToString(entries) .. " in " .. ChunksToString(chunks) .. " on " .. SurfacesToString(surfaces)
end


-- Makes printing table information more enjoyable.
function EntriesInChunksToString(entries, chunks)
    return EntriesToString(entries) .. " in " .. ChunksToString(chunks)
end
