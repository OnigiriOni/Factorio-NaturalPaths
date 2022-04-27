require("scripts/libs/const")

local debug = require("scripts/libs/debug")


-----------------------------------------------------------------------------------------
-- Weight
-----------------------------------------------------------------------------------------


-- Returns the current weight of the player character.
function getCharacterWeight(player, characterInfo)
    local characterWeight = characterInfo.weight
    
    -- When adding something involving player:
    -- Fix the getVehicleWeight() passenger.
    -- Getting a driver or passenger returns either a player or character so we need to check this.

    return characterWeight
end


-- Returns the deterioration that is applied to the tiles by the character.
function getCharacterDeterioration(player, characterInfo, tileInfo)
    local weight = getCharacterWeight(player, characterInfo)

    local weightInfluence = characterInfo.destruction * tileInfo.hardness
    weight = weight / weightInfluence

    return weight * math.abs(player.character_running_speed)
end


-----------------------------------------------------------------------------------------
-- Pattern Tiles
-----------------------------------------------------------------------------------------


function getSurfaceTilesInPatternForCharacter(player, characterInfo)
    local pattern = PATTERNS[characterInfo.pattern]
    local surfaceTilesToEdit = {}

    for _, offset in pairs(pattern) do
        table.insert(surfaceTilesToEdit, player.surface.get_tile(player.position.x + offset.x, player.position.y + offset.y))
    end

    return surfaceTilesToEdit
end


-----------------------------------------------------------------------------------------
-- Deterioration
-----------------------------------------------------------------------------------------


function deteriorateEntryTileCharacter(entryTile, player, characterInfo)
    local tileInfo = TILE_INFO[entryTile.currentTile]
    local updateTexture = false

    local deterioration = getCharacterDeterioration(player, characterInfo, tileInfo)
    entryTile.deterioration = entryTile.deterioration + deterioration

    debug.print(deterioration .. " -> " .. entryTile.currentTile .. " at " .. entryTile.deterioration .. "/" .. tileInfo.threshold, player)

    while entryTile.deterioration >= tileInfo.threshold do
        local nextTile = DETERIORATION_PATHS[entryTile.currentTile].nextWalking

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


function deteriorateTilesCharacter(surfaceTiles, player, characterInfo)
    local tilesToUpdate = {}

    for _, surfaceTile in pairs(surfaceTiles) do

        if canTileDeteriorate(surfaceTile) then
            local surfaceKey = getSurfaceKey(surfaceTile.surface)
            local chunkKey = getChunkKey(surfaceTile.position)
            local entryKey = getEntryKey(surfaceTile.position)
            
            local entryTile = getEntryTile(surfaceKey, chunkKey, entryKey) or createEntryTile(surfaceTile)

            local result = deteriorateEntryTileCharacter(entryTile, player, characterInfo)

            insertEntryTile(surfaceKey, chunkKey, entryKey, result.entryTile)

            if result.updateTexture then
                table.insert(tilesToUpdate, {name = result.entryTile.currentTile, position = entryTile.position})
            end
        end
    end

    return tilesToUpdate
end
