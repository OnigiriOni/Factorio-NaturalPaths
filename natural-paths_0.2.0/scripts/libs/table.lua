-- struct entryTile
-- {
--     {x,y}    position            -- The world position of the tile. [Static]
--     string   startTile           -- The original tile type. The tile will regenerate to this eventually. [Static]
--     string   currentTile         -- The current type of the tile. This determines the deterioration threshold & regeneration path. [Dynamic]
--     float    deterioration       -- How destroyed this tile is. If this is over the threshold it will change to a new tile. [Dynamic]
--     string[] regenerationPath    -- This stores the tile types this tile has to change to while regenerationg. Each tile type may have a different path. [Dynamic (currentTile)]
--     bool     requirePathUpdate   -- If true, regenerationPath above needs to be recalculated because the tile type has probably changed. [Dynamic (currentTile)]
-- }


-----------------------------------------------------------------------------------------
-- Index Generation
-----------------------------------------------------------------------------------------


-- Returns a string used as key for the surface group in the table.
function GetSurfaceKey(surface)
    return surface.name
end


-- Returns a string used as key for the chunk group in the table.
function GetChunkKey(position)
    position.x = math.floor(position.x / CHUNK_SIZE)
    position.y = math.floor(position.y / CHUNK_SIZE)
    return position.x .. "," .. position.y
end


-- Returns a string used as key for the entry tile in the table.
function GetEntryKey(position)
    position.x = math.floor(position.x)
    position.y = math.floor(position.y)
    return position.x .. "," .. position.y
end


-----------------------------------------------------------------------------------------
-- Entry Manipulation
-----------------------------------------------------------------------------------------


-- Returns a new entry tile object based on the given surface tile.
function CreateEntryTile(surfaceTile)
    return {
        position = surfaceTile.position,
        startTile = surfaceTile.name,
        currentTile = surfaceTile.name,
        deterioration = 0,
        regenerationPath = {},
        requirePathUpdate = false,
    }
end


-- Returns an entry tile or nil.
function GetEntryTile(surfaceKey, chunkKey, entryKey)
    return global.tile_table[surfaceKey]
    and global.tile_table[surfaceKey][chunkKey]
    and global.tile_table[surfaceKey][chunkKey][entryKey] 
end


-- Stores an entry tile in the table at the specified surface and chunk group.
function InsertEntryTile(surfaceKey, chunkKey, entryKey, entryTile)
    local chunks = global.tile_table[surfaceKey]
    if not chunks then
        chunks = {}
        global.tile_table[surfaceKey] = chunks
    end

    local entries = chunks[chunkKey]
    if not entries then
        entries = {}
        chunks[chunkKey] = entries
    end

    entries[entryKey] = entryTile
end


-- Set entries in the specified surface and chunk group to nil.
function RemoveEntriesFromTableChunk(surfaceKey, chunkKey, entryKeys)
    for entryKey, _ in pairs(entryKeys) do
        global.tile_table[surfaceKey][chunkKey][entryKey] = nil
    end
end


-- Set chunks in the specified surface group to nil.
function RemoveChunksFromTableSurface(surfaceKey, chunkKeys)
    for chunkKey, _ in pairs(chunkKeys) do
        global.tile_table[surfaceKey][chunkKey] = nil
    end
end


-- Set surfaces in the table to nil.
function RemoveSurfacesFromTable(surfaceKeys)
    for surfaceKey, _ in pairs(surfaceKeys) do
        global.tile_table[surfaceKey] = nil
    end
end


-----------------------------------------------------------------------------------------
-- Debug
-----------------------------------------------------------------------------------------


-- Returns an object with some information about the table.
function GetTableInfo()
    local info = {}
    info.status = true
    info.totalSurfaces = 0
    info.totalChunks = 0
    info.totalEntries = 0
    info.surfaces = {}

    for surfaceKey, surface in pairs(global.tile_table) do
        info.totalSurfaces = info.totalSurfaces + 1

        local surfaceInfo = {}
        surfaceInfo.name = surfaceKey
        surfaceInfo.exists = false
        surfaceInfo.chunks = 0
        surfaceInfo.entries = 0

        for _, gameSurface in pairs(game.surfaces) do
            if surfaceKey == gameSurface.name then surfaceInfo.exists = true break end
        end

        for _, chunk in pairs(surface) do
            surfaceInfo.chunks = surfaceInfo.chunks + 1

            for _, _ in pairs(chunk) do
                surfaceInfo.entries = surfaceInfo.entries + 1
            end
        end

        info.totalEntries = info.totalEntries + surfaceInfo.entries
        info.totalChunks = info.totalChunks + surfaceInfo.chunks

        table.insert(info.surfaces, surfaceInfo)
    end

    return info
end
