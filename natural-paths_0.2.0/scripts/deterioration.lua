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


-- Returns the next tile in the deterioration path.
-- Skips tiles that are unreachable until tiles are reachable again.
-- If no tile is reachable then it will return nil as if the path had ended.
function GetNextPathTile(entryTile, deteriorationInfo, player)
    local nextTile = entryTile.currentTile
    local cashedNextTile = nextTile
    repeat
        if player.vehicle then
            nextTile = DETERIORATION_PATHS[cashedNextTile].nextVehicle
        else
            nextTile = DETERIORATION_PATHS[cashedNextTile].nextWalking
        end
        cashedNextTile = nextTile

        if nextTile == nil then break end
        if EnableUnreachableTiles and IsTileUnreachable(deteriorationInfo.unreachableTiles, nextTile) then
            nextTile = nil
        end
    until nextTile ~= nil

    return nextTile
end


local function deteriorateEntryTile(entryTile, player, deteriorationInfo)
    local updateTexture = false

    local tileInfo = TILE_INFO[entryTile.currentTile]
    local deterioration = getDeteriorationValue(deteriorationInfo, tileInfo)
    entryTile.deterioration = entryTile.deterioration + deterioration

    debug.print("player weight: " .. deteriorationInfo.weight, player)
    debug.print(deterioration .. " -> " .. entryTile.currentTile .. " at " .. entryTile.deterioration .. "/" .. tileInfo.threshold, player)

    while entryTile.deterioration >= tileInfo.threshold do
        local nextTile = GetNextPathTile(entryTile, deteriorationInfo, player)

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
            deteriorationInfo = GetVehicleInfo(player.vehicle.name)
            deteriorationInfo.speed = math.abs(player.vehicle.speed)
            deteriorationInfo.weight = GetVehicleWeight(player, deteriorationInfo)
        else
            deteriorationInfo = GetVehicleInfo("character")
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
