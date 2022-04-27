require("scripts/libs/const")
require("scripts/libs/table")
require("scripts/libs/utils")
require("scripts/playerstates/character")

local debug = require("scripts/libs/debug")


-----------------------------------------------------------------------------------------
-- Weight
-----------------------------------------------------------------------------------------


-- Returns the current weight of the vehicle.
function getVehicleWeight(player, vehicleInfo)
    local characterInfo = VEHICLES["character"]
    local vehicleWeight = vehicleInfo.weight

    -- Add the passenger weight to the total weight.
    local passenger = player.vehicle.get_passenger()
    local passengerWeight = 0
    
    if passenger then
        passengerWeight = getCharacterWeight(passenger, characterInfo)
    end

    vehicleWeight = vehicleWeight + getCharacterWeight(player, characterInfo) + passengerWeight

    -- Distribute the weight among each spidertron leg.
    if player.vehicle.type == "spider-vehicle" then
        vehicleWeight = vehicleWeight / #player.vehicle.get_spider_legs()
    end

    return vehicleWeight
end


-- Returns the deterioration that is applied to the tiles by the vehicle.
function getVehicleDeterioration(player, vehicleInfo, tileInfo)
    local weight = getVehicleWeight(player, vehicleInfo)

    local weightInfluence = vehicleInfo.destruction * tileInfo.hardness
    weight = weight / weightInfluence
    

    return weight * math.abs(player.vehicle.speed)
end


-----------------------------------------------------------------------------------------
-- Pattern Tiles
-----------------------------------------------------------------------------------------


function getSurfaceTilesInPatternForVehicle(player, vehicleInfo)
    local pattern = PATTERNS[vehicleInfo.pattern]
    local surfaceTilesToEdit = {}

    if player.vehicle.type == "spider-vehicle" then
        for _, leg in pairs(player.vehicle.get_spider_legs()) do
            for __, offset in pairs(pattern) do
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
-- Deterioration
-----------------------------------------------------------------------------------------


function deteriorateEntryTileVehicle(entryTile, player, vehicleInfo)
    local tileInfo = TILE_INFO[entryTile.currentTile]
    local updateTexture = false

    local deterioration = getVehicleDeterioration(player, vehicleInfo, tileInfo)
    entryTile.deterioration = entryTile.deterioration + deterioration

    debug.print(deterioration .. " -> " .. entryTile.currentTile .. " at " .. entryTile.deterioration .. "/" .. tileInfo.threshold, player)

    while entryTile.deterioration >= tileInfo.threshold do
        local nextTile = DETERIORATION_PATHS[entryTile.currentTile].nextVehicle

        if nextTile ~= nil then

            entryTile.currentTile = nextTile
            entryTile.deterioration = entryTile.deterioration - tileInfo.threshold
            entryTile.requirePathUpdate = true

            tileInfo = TILE_INFO[entryTile.currentTile]
            updateTexture = true
        else
            entryTile.deterioration = tileInfo.threshold
            break
        end
    end

    return {
        updateTexture = updateTexture,
        entryTile = entryTile,
    }
end


function deteriorateTilesVehicle(surfaceTiles, player, vehicleInfo)
    local tilesToUpdate = {}

    for _, surfaceTile in pairs(surfaceTiles) do

        if canTileDeteriorate(surfaceTile) then
            local surfaceKey = getSurfaceKey(surfaceTile.surface)
            local chunkKey = getChunkKey(surfaceTile.position)
            local entryKey = getEntryKey(surfaceTile.position)
            
            local entryTile = getEntryTile(surfaceKey, chunkKey, entryKey) or createEntryTile(surfaceTile)

            local result = deteriorateEntryTileVehicle(entryTile, player, vehicleInfo)

            insertEntryTile(surfaceKey, chunkKey, entryKey, result.entryTile)

            if result.updateTexture then
                table.insert(tilesToUpdate, {name = result.entryTile.currentTile, position = entryTile.position})
            end
        end
    end

    return tilesToUpdate
end
