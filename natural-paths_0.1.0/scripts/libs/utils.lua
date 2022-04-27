require("scripts/libs/const")


-----------------------------------------------------------------------------------------
-- Math
-----------------------------------------------------------------------------------------


-- Returns the sign of the given number.
function sign(number)
    return (number > 0 and 1) or (number == 0 and 0) or -1
end


-----------------------------------------------------------------------------------------
-- Validation
-----------------------------------------------------------------------------------------


-- Returns if the given surface is alowed to be modified by this mod.
function isSurfaceValid(surfaceName)
    for _, invalidSurfaceName in pairs(INVALID_SURFACES) do
        if string.find(surfaceName, invalidSurfaceName) then return false end
    end

    return true
end


-- Returns if the given tile is alowed to receive deterioration.
function isSurfaceTileValid(surfaceTileName)
    for name, validTile in pairs(TILE_INFO) do        
        if surfaceTileName == name then return true end
    end

    return false
end


-- Returns if the given vehicle is alowed to deteriorate tiles.
function isVehicleValid(vehicleType)
    for _, invalidVehicleType in pairs(INVALID_VEHICLES) do
        if vehicleType == vehicle then return false end
    end

    return true
end


-- Returns if the tile can be modified.
function canTileDeteriorate(surfaceTile)

    -- I do not fully understand the concept of the hidden tile in this check but the mod this is based on had it.
    if surfaceTile.hidden_tile then return false end

    if not isSurfaceTileValid(surfaceTile.name) then return false end

    return true
end


-----------------------------------------------------------------------------------------
-- Factorio
-----------------------------------------------------------------------------------------


-- Changes textures of given tiles on the given surface.
function updateTextureOfSurfaceTiles(surface, tiles)
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
function surfacesToString(number)
    local desc = (number ~= 1 and " surfaces" or " surface")
    return number .. desc
end


-- Makes printing for plurals more enjoyable.
function chunksToString(number)
    local desc = (number ~= 1 and " chunks" or " chunk")
    return number .. desc
end


-- Makes printing for plurals more enjoyable.
function entriesToString(number)
    local desc = (number ~= 1 and " entries" or " entry")
    return number .. desc
end

-- Makes printing table information more enjoyable.
function entriesInChunksOnSurfacesToString(entries, chunks, surfaces)
    return entriesToString(entries) .. " in " .. chunksToString(chunks) .. " on " .. surfacesToString(surfaces)
end


-- Makes printing table information more enjoyable.
function entriesInChunksToString(entries, chunks)
    return entriesToString(entries) .. " in " .. chunksToString(chunks)
end
