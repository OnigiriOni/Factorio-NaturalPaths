require("scripts/libs/vars")
require("scripts/libs/utils")
require("scripts/libs/table")
require("scripts/libs/graph")

local debug = require("scripts/libs/debug")


function regenerateTile(entryTile)

    local updateTexture = false
    local deleteEntry = false

    local tileInfo = TILE_INFO[entryTile.currentTile]

    entryTile.deterioration = entryTile.deterioration - (tileInfo.threshold / tileInfo.regeneration) * regenerationDelta

    while entryTile.deterioration <= 0 do

        if entryTile.currentTile ~= entryTile.startTile then

            if entryTile.requirePathUpdate then
                entryTile.regenerationPath = calculateRegenerationPath(entryTile)
            end

            entryTile.currentTile = entryTile.regenerationPath[1]
            table.remove(entryTile.regenerationPath, 1)
            entryTile.deterioration = TILE_INFO[entryTile.currentTile].threshold + entryTile.deterioration

            updateTexture = true
        else
            deleteEntry = true
            break
        end
    end

    return {
        updateTexture = updateTexture,
        deleteEntry = deleteEntry,
    }
end


function regenerateTilesInChunk(surface, surfaceKey, chunkKey)

    local tilesToUpdate = {}
    local tilesToDelete = {}

    for entryKey, entryTile in pairs(global.tile_table[surfaceKey][chunkKey]) do

        local result = regenerateTile(entryTile)

        if result.deleteEntry then tilesToDelete[entryKey] = true end

        if result.updateTexture then
            table.insert(tilesToUpdate, { name = entryTile.currentTile, position = entryTile.position })
        end
    end

    removeEntriesFromTableChunk(surfaceKey, chunkKey, tilesToDelete)
    updateTextureOfSurfaceTiles(surface, tilesToUpdate)
end


function regenerateTilesOnSurface(surface)
    local surfaceKey = getSurfaceKey(surface)

    for chunkKey, _ in pairs(global.tile_table[surfaceKey]) do

        regenerateTilesInChunk(surface, surfaceKey, chunkKey)
    end
end


function updateRegeneration()
    debug.print("Natural Paths Regeneration Update")

    for _, surface in pairs(game.surfaces) do
        regenerateTilesOnSurface(surface)
    end
end


script.on_nth_tick(ticksBetweenUpdates, updateRegeneration)
