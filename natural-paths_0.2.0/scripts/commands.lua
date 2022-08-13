require("scripts/libs/const")
require("scripts/libs/utils")
require("scripts/libs/table")
require("scripts/libs/debug")

local function commandPrintVehicleList(command)
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


local function commandPrintTileInfo(command)
    local player = game.get_player(command.player_index)

    local surfaceKey = GetSurfaceKey(player.surface)
    local entryKey = GetEntryKey(player.position)
    local chunkKey = GetChunkKey(player.position)
    local entryTile = GetEntryTile(surfaceKey, chunkKey, entryKey)

    debug.print("Surface '" .. surfaceKey .. "' - tile '" .. entryKey .. "' in chunk '" .. chunkKey .. "'.", player)

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


local function commandPrintTableInfo(command)
    local player = game.get_player(command.player_index)

    if global.tile_table then
        local info = GetTableInfo()

        if info.status then
            debug.print("Table Status: Healthy | " .. EntriesInChunksOnSurfacesToString(info.totalEntries, info.totalChunks, info.totalSurfaces) .. ".", player)
        else
            debug.printWarning("Table Status: Unused Surface Groups | " .. EntriesInChunksOnSurfacesToString(info.totalEntries, info.totalChunks, info.totalSurfaces) .. ".", player)
        end

        for _, surfaceInfo in pairs(info.surfaces) do
            if surfaceInfo.exists then
                debug.print("Surface '" .. surfaceInfo.name .. "' - " .. EntriesInChunksToString(surfaceInfo.entries, surfaceInfo.chunks), player)
            else
                debug.printWarning("Surface '" .. surfaceInfo.name .. "' - " .. EntriesInChunksToString(surfaceInfo.entries, surfaceInfo.chunks) .. " <- No game surface found.", player)
            end
        end
    else
        debug.printError("Table does not exist.")
    end
end


local function commandSetSurfaceTiles(command)
    local player = game.get_player(command.player_index)
    local tileName = command.parameter

    if not tileName then
        debug.print("No tile name given, try /np-tilesSet 'tilename'.", player)
        return
    end

    if not IsSurfaceTileValid(tileName) then
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
        if CanTileDeteriorate(surfaceTile) then
            local updateTexture = false

            local surfaceKey = GetSurfaceKey(surfaceTile.surface)
            local chunkKey = GetChunkKey(surfaceTile.position)
            local entryKey = GetEntryKey(surfaceTile.position)
            local entryTile = GetEntryTile(surfaceKey, chunkKey, entryKey) or CreateEntryTile(surfaceTile)

            if tileName ~= entryTile.startTile then
                entryTile.currentTile = tileName
                entryTile.requirePathUpdate = true
                updateTexture = true
            end

            entryTile.deterioration = TILE_INFO[tileName].threshold / 2

            InsertEntryTile(surfaceKey, chunkKey, entryKey, entryTile)
            if updateTexture then
                table.insert(tilesToUpdate, { name = entryTile.currentTile, position = entryTile.position })
            end
        end
    end

    UpdateTextureOfSurfaceTiles(player.surface, tilesToUpdate)
end


local function commandResetAllTiles(command)
    local player = game.get_player(command.player_index)
    local execute = command.parameter

    if not execute or not execute == "true" then
        debug.printWarning("/np-reset will reset all alterations made to the terrain by Natural Paths. If you want to continue write: /np-reset true", player)
        return
    end

    debug.print("Begin resetting terrain modifications.", player)

    for surfaceKey, surface in pairs(global.tile_table) do
        for _, gameSurface in pairs(game.surfaces) do
            if GetSurfaceKey(gameSurface) == surfaceKey then
                local chunksToDelete = {}
                local tilesToUpdate = {}

                for chunkKey, chunk in pairs(surface) do
                    for _, entryTile in pairs(chunk) do
                        table.insert(tilesToUpdate, { name = entryTile.startTile, position = entryTile.position })
                    end
                    chunksToDelete[chunkKey] = true
                end

                debug.print("Updating textures on surface: " .. gameSurface.name, player)

                RemoveChunksFromTableSurface(surfaceKey, chunksToDelete)
                UpdateTextureOfSurfaceTiles(gameSurface, tilesToUpdate)
                break
            end
        end
    end

    debug.printSuccess("Finished resetting terrain modifications.", player)
    debug.printSuccess("Use /np-tableInfo to check if undesired entries are present. Only surfaces that are currently in game were reset.", player)
end


-- Copy of utils.GetInventoryWeight(inventory) but with debug.
local function GetInventoryWeight(inventory, player)
    local inventoryWeight = 0

    for i = 1, #inventory, 1 do
        local itemStack = inventory[i]

        if itemStack.valid_for_read then
            local maxStackSize = itemStack.prototype.stack_size
            local itemWeight = GetMaxStackWeight(maxStackSize) / maxStackSize
            local currentStackWeight = itemWeight * itemStack.count
            inventoryWeight = inventoryWeight + currentStackWeight

            debug.print(itemStack.name .. ", Weight: " .. currentStackWeight .. ", Count: " .. itemStack.count .. "/" .. maxStackSize, player)
        end
    end

    return inventoryWeight
end


-- Prints the current weight of the inventory and every item stack.
local function commandPrintInventory(command)
    local player = game.get_player(command.player_index)
    local entity = command.parameter

    if not entity then
        debug.print("Please define what inventory you want to print. Try /np-inventory 'entity'", player)
    end

    if entity == "p" then
        local inventoryWeight = 0
        inventoryWeight = inventoryWeight + GetInventoryWeight(player.get_inventory(defines.inventory.character_main), player)
        inventoryWeight = inventoryWeight + GetInventoryWeight(player.get_inventory(defines.inventory.character_guns), player)
        inventoryWeight = inventoryWeight + GetInventoryWeight(player.get_inventory(defines.inventory.character_ammo), player)
        inventoryWeight = inventoryWeight + GetInventoryWeight(player.get_inventory(defines.inventory.character_armor), player)
        inventoryWeight = inventoryWeight + GetInventoryWeight(player.get_inventory(defines.inventory.character_trash), player)

        debug.print("Combined Inventory Weight: " .. inventoryWeight, player)

    elseif entity == "v" then
        if player.vehicle then
            local inventoryWeight = 0
            inventoryWeight = inventoryWeight + GetInventoryWeight(player.vehicle.get_inventory(defines.inventory.fuel), player)

            if player.vehicle.type == "spider-vehicle" then
                inventoryWeight = inventoryWeight + GetInventoryWeight(player.vehicle.get_inventory(defines.inventory.spider_trunk), player)
                inventoryWeight = inventoryWeight + GetInventoryWeight(player.vehicle.get_inventory(defines.inventory.spider_ammo), player)
            else
                inventoryWeight = inventoryWeight + GetInventoryWeight(player.vehicle.get_inventory(defines.inventory.car_trunk), player)
                inventoryWeight = inventoryWeight + GetInventoryWeight(player.vehicle.get_inventory(defines.inventory.car_ammo), player)
            end

            debug.print("Combined Inventory Weight: " .. inventoryWeight, player)        
        else
            debug.print("Make sure to sit in a vehicle before using this command", player)
        end
    else
        debug.print(entity .. " is not a valid entity descriptor. Try 'p' for your character inventory or 'v' for the vehicle you are currently seated in.", player)
    end
end


if EnableDebug then
    commands.add_command("np-gameVehicles", nil, commandPrintVehicleList)
    commands.add_command("np-tileInfo", nil, commandPrintTileInfo)
    commands.add_command("np-tableInfo", nil, commandPrintTableInfo)
    commands.add_command("np-tilesSet", nil, commandSetSurfaceTiles)
    commands.add_command("np-reset", nil, commandResetAllTiles)
    commands.add_command("np-inventory", nil, commandPrintInventory)
end
