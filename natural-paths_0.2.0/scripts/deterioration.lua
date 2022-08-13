require("scripts/libs/const")
require("scripts/libs/utils")
require("scripts/libs/debug")
require("scripts/compat/jetpackmod")


-- Returns the deterioration that is applied to the tile by the player.
local function getDeteriorationValue(deteriorationInfo, tileInfo)
    local weightInfluence = deteriorationInfo.destruction / tileInfo.hardness
    local weight = deteriorationInfo.weight * weightInfluence
    return weight * deteriorationInfo.speed
end


local function deteriorateEntryTile(entryTile, player, deteriorationInfo)
    local updateTexture = false

    local tileInfo = TILE_INFO[entryTile.currentTile]
    local deterioration = getDeteriorationValue(deteriorationInfo, tileInfo)
    entryTile.deterioration = entryTile.deterioration + deterioration

    debug.print("player weight: " .. deteriorationInfo.weight, player)
    debug.print(deterioration .. " -> " .. entryTile.currentTile .. " at " .. entryTile.deterioration .. "/" .. tileInfo.threshold, player)

    while entryTile.deterioration >= tileInfo.threshold do
        local nextTile = ""
        if player.vehicle then
            nextTile = DETERIORATION_PATHS[entryTile.currentTile].nextVehicle
        else
            nextTile = DETERIORATION_PATHS[entryTile.currentTile].nextWalking
        end

        if nextTile ~= nil then
            entryTile.currentTile = nextTile
            entryTile.deterioration = entryTile.deterioration - tileInfo.threshold

            -- If one tile deterioration 1000 health with a low hardness in one pass and the next tile only has a threshold of 500 with a high hardness it could just skipp the tile with the leftover deterioration.
            -- So we use the overflow percent of the new deterioration value to make the transition acurate.
            tileInfo = TILE_INFO[entryTile.currentTile]
            local value = (entryTile.deterioration / deterioration) * getDeteriorationValue(deteriorationInfo, tileInfo)
            entryTile.deterioration = value

            entryTile.requirePathUpdate = true
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


local function deteriorateTiles(surfaceTiles, player, deteriorationInfo)
    local tilesToUpdate = {}

    for _, surfaceTile in pairs(surfaceTiles) do
        if CanTileDeteriorate(surfaceTile) then
            local surfaceKey = GetSurfaceKey(surfaceTile.surface)
            local chunkKey = GetChunkKey(surfaceTile.position)
            local entryKey = GetEntryKey(surfaceTile.position)
            local entryTile = GetEntryTile(surfaceKey, chunkKey, entryKey) or CreateEntryTile(surfaceTile)

            local result = deteriorateEntryTile(entryTile, player, deteriorationInfo)

            InsertEntryTile(surfaceKey, chunkKey, entryKey, result.entryTile)
            if result.updateTexture then
                table.insert(tilesToUpdate, {name = result.entryTile.currentTile, position = entryTile.position})
            end
        end
    end

    return tilesToUpdate
end


local function onPlayerChangedPosition(event)
    local player = game.players[event.player_index]

    if CanPlayerDeteriorateTiles(player) then
        local deteriorationInfo = {}
        local surfaceTilesToEdit = {}
        local tilesToUpdate = {}

        if player.vehicle then
            -- Apparently 'a' is a reference to the table object and not a copy. It would persistently add weight to the vehicle.
            local a = VEHICLES[player.vehicle.name] or VEHICLES["default"]
            deteriorationInfo.weight = a.weight
            deteriorationInfo.destruction = a.destruction
            deteriorationInfo.pattern = a.pattern
            deteriorationInfo.unreachableTiles = a.unreachableTiles

            deteriorationInfo.speed = math.abs(player.vehicle.speed)
            deteriorationInfo.weight = GetVehicleWeight(player, deteriorationInfo)
        else
            -- Apparently 'a' is a reference to the table object and not a copy. It would persistently add weight to the vehicle.
            local a = VEHICLES["character"]
            deteriorationInfo.weight = a.weight
            deteriorationInfo.destruction = a.destruction
            deteriorationInfo.pattern = a.pattern
            deteriorationInfo.unreachableTiles = a.unreachableTiles

            deteriorationInfo.speed = math.abs(player.character_running_speed)
            deteriorationInfo.weight = GetCharacterWeight(player, deteriorationInfo)
        end

        surfaceTilesToEdit = GetSurfaceTilesInPattern(player, deteriorationInfo)
        tilesToUpdate = deteriorateTiles(surfaceTilesToEdit, player, deteriorationInfo)
        UpdateTextureOfSurfaceTiles(player.surface, tilesToUpdate)
    end
end


-- Is there a better event or update loop to do this ???
-- At least check if the player changed the tile position before blasting another deterioration pass !!!
script.on_event(defines.events.on_player_changed_position, onPlayerChangedPosition)
