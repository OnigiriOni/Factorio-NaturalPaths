require("scripts/libs/const")
require("scripts/libs/utils")
require("scripts/libs/table")

local debug = require("scripts/libs/debug")


function commandPrintVehicleList(command)
    local player = game.get_player(command.player_index)

    local playerVehicle = 0

    debug.print("Found Vehicles:", player)

    for i, prototype in pairs(game.entity_prototypes) do
        if prototype.weight then

            if player.vehicle then
                if prototype.name == player.vehicle.name then
                    playerVehicle = playerVehicle + 1
                    debug.print("Name: " .. prototype.name .. ", Type: " .. prototype.type .. ", Weight: " .. prototype.weight .. " <- You are seated in this one.", player)
                end
            else
                playerVehicle = -1
                debug.print("Name: " .. prototype.name .. ", Type: " .. prototype.type .. ", Weight: " .. prototype.weight, player)
            end
        end
    end

    if playerVehicle ~= -1 then
        if playerVehicle == 0 then

            debug.printWarning("You are seated in a vehicle but its prototype was not found. Maybe its weight is nil?", player)

        elseif playerVehicle > 1 then

            debug.printWarning("The vehicle you are seated in shares the same name with multiple prototypes.", player)
        end
    end
end


function commandPrintTileInfo(command)
    local player = game.get_player(command.player_index)

    local surfaceKey = getSurfaceKey(player.surface)
    local entryKey = getEntryKey(player.position)
    local chunkKey = getChunkKey(player.position)

    debug.print("Surface '" .. surfaceKey .. "' - tile '" .. entryKey .. "' in chunk '" .. chunkKey .. "'.", player)

    local entryTile = getEntryTile(surfaceKey, chunkKey, entryKey)

    if entryTile then
        
        local tileInfo = TILE_INFO[entryTile.currentTile]
        
        local time = (entryTile.deterioration / tileInfo.threshold) * tileInfo.regeneration
        time = time * (DELTA_SCALE / 3600)

        debug.print("Original tile: " .. entryTile.startTile, player)
        debug.print("Current tile: " .. entryTile.currentTile .. " at " .. entryTile.deterioration .. " deterioration", player)
        debug.print("Expected change in " .. time .. " minutes", player)
        
        if entryTile.regenerationPath and not entryTile.requirePathUpdate then
            debug.print("Reg-Path length: " .. #entryTile.regenerationPath, player)
        else
            debug.print("Path update pending.", player)
        end
    else
        debug.printWarning("Tile has no table entry.", player)
    end
end


function commandPrintTableInfo(command)
    local player = game.get_player(command.player_index)

    if global.tile_table then
        local info = getTableInfo()

        if info.status then
            debug.print("Table Status: Healthy | " .. entriesInChunksOnSurfacesToString(info.totalEntries, info.totalChunks, info.totalSurfaces) .. ".", player)
        else
            debug.printWarning("Table Status: Unused Surface Groups | " .. entriesInChunksOnSurfacesToString(info.totalEntries, info.totalChunks, info.totalSurfaces) .. ".", player)
        end

        for _, surfaceInfo in pairs(info.surfaces) do

            if surfaceInfo.exists then
                debug.print("Surface '" .. surfaceInfo.name .. "' - " .. entriesInChunksToString(surfaceInfo.entries, surfaceInfo.chunks), player)
            else
                debug.printWarning("Surface '" .. surfaceInfo.name .. "' - " .. entriesInChunksToString(surfaceInfo.entries, surfaceInfo.chunks) .. " <- No game surface found.", player)
            end
        end
    else
        debug.printError("Table does not exist.")
    end
end


function commandSetSurfaceTiles(command)
    local player = game.get_player(command.player_index)
    local tileName = command.parameter

    if not tileName then
        debug.print("No tile name given, try /np-tilesSet 'tilename'.", player)
        return
    end

    if not isSurfaceTileValid(tileName) then
        debug.print(tileName .. " is not a valid tile name, try: 'grass-1' (1-4), 'red-desert-0' (0-3), 'dirt-1' (1-7), 'sand-1' (1-3), 'dry-dirt' or 'landfill'.", player)
        return
    end

    -- Set tiles to new type.
    local tilesToModify = {}
    local tilesToUpdate = {}

    for _, pos in pairs(PATTERNS["5x5"]) do
        table.insert(tilesToModify, player.surface.get_tile(player.position.x + pos.x, player.position.y + pos.y))
    end

    for _, surfaceTile in pairs(tilesToModify) do

        if canTileDeteriorate(surfaceTile) then
            local surfaceKey = getSurfaceKey(surfaceTile.surface)
            local chunkKey = getChunkKey(surfaceTile.position)
            local entryKey = getEntryKey(surfaceTile.position)

            local entryTile = getEntryTile(surfaceKey, chunkKey, entryKey) or createEntryTile(surfaceTile)

            local updateTexture = false
                
            if tileName ~= entryTile.startTile then
                entryTile.currentTile = tileName
                entryTile.requirePathUpdate = true
                updateTexture = true
            end
                
            entryTile.deterioration = TILE_INFO[tileName].threshold / 2
                
            insertEntryTile(surfaceKey, chunkKey, entryKey, entryTile)
                
            if updateTexture then
                table.insert(tilesToUpdate, { name = entryTile.currentTile, position = entryTile.position })
            end
        end
    end

    updateTextureOfSurfaceTiles(player.surface, tilesToUpdate)
end


function commandResetAllTiles(command)
    local player = game.get_player(command.player_index)
    local execute = command.parameter

    if not execute or not execute == "true" then
        debug.printWarning("/np-reset will reset all alterations made to the terrain by Natural Paths. If you want to continue write: /np-reset true")
        return
    end

    debug.print("Begin resetting terrain modifications.")

    for surfaceKey, surface in pairs(global.tile_table) do

        for _, gameSurface in pairs(game.surfaces) do
            if getSurfaceKey(gameSurface) == surfaceKey then

                local chunksToDelete = {}
                local tilesToUpdate = {}

                for chunkKey, chunk in pairs(surface) do
                    for entryKey, entryTile in pairs(chunk) do
                        table.insert(tilesToUpdate, { name = entryTile.startTile, position = entryTile.position })
                    end

                    chunksToDelete[chunkKey] = true
                end
        
                debug.print("Updating textures on surface: " .. gameSurface.name)
                
                removeChunksFromTableSurface(surfaceKey, chunksToDelete)
                updateTextureOfSurfaceTiles(gameSurface, tilesToUpdate)
                break
            end
        end
    end

    debug.printSuccess("Finished resetting terrain modifications.")
    debug.printSuccess("Use /np-tableInfo to check if undesired entries are present. Only surfaces that are currently in game were reset.")
end


if enableDebug then

    commands.add_command("np-gameVehicles", nil, commandPrintVehicleList)
    commands.add_command("np-tileInfo", nil, commandPrintTileInfo)
    commands.add_command("np-tableInfo", nil, commandPrintTableInfo)
    commands.add_command("np-tilesSet", nil, commandSetSurfaceTiles)
    commands.add_command("np-reset", nil, commandResetAllTiles)

end
