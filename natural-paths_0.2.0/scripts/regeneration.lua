require("scripts/libs/vars")
require("scripts/libs/utils")
require("scripts/libs/table")
require("scripts/libs/graph")
require("scripts/libs/debug")


local function calculateRegenerationValue(tileInfo)
    return (tileInfo.threshold / tileInfo.regeneration) * RegenerationDelta
end


local function regenerateTile(entryTile)
    local updateTexture = false
    local deleteEntry = false

    local tileInfo = TILE_INFO[entryTile.currentTile]
    local regValue = calculateRegenerationValue(tileInfo)
    entryTile.deterioration = entryTile.deterioration - regValue

    while entryTile.deterioration <= 0 do
        if entryTile.currentTile ~= entryTile.startTile then
            if entryTile.requirePathUpdate then
                entryTile.regenerationPath = CalculateRegenerationPath(entryTile)
            end

            entryTile.currentTile = entryTile.regenerationPath[1]
            table.remove(entryTile.regenerationPath, 1)

            -- Use the same percent of the leftover regValue from the initial regeneration pass on the new tile regeneration pass.
            -- If one tile regenerates 1000 deterioration in one pass and the next tile only has a threshold of 500 it could just skipp the tile with the leftover regeneration.
            tileInfo = TILE_INFO[entryTile.currentTile]
            local value = (math.abs(entryTile.deterioration) / regValue) * calculateRegenerationValue(tileInfo)
            entryTile.deterioration = tileInfo.threshold - value

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


local function regenerateTilesInChunk(surface, surfaceKey, chunkKey)
    local tilesToUpdate = {}
    local tilesToDelete = {}

    for entryKey, entryTile in pairs(global.tile_table[surfaceKey][chunkKey]) do
        local result = regenerateTile(entryTile)
        if result.deleteEntry then tilesToDelete[entryKey] = true end
        if result.updateTexture then
            table.insert(tilesToUpdate, { name = entryTile.currentTile, position = entryTile.position })
        end
    end

    RemoveEntriesFromTableChunk(surfaceKey, chunkKey, tilesToDelete)
    UpdateTextureOfSurfaceTiles(surface, tilesToUpdate)
end


local function regenerateTilesOnSurface(surface)
    local surfaceKey = GetSurfaceKey(surface)

    for chunkKey, _ in pairs(global.tile_table[surfaceKey]) do
        regenerateTilesInChunk(surface, surfaceKey, chunkKey)
    end
end


local function updateRegeneration()
    debug.print("Natural Paths Regeneration Update")

    for _, surface in pairs(game.surfaces) do
        regenerateTilesOnSurface(surface)
    end
end


script.on_nth_tick(TicksBetweenUpdates, updateRegeneration)
