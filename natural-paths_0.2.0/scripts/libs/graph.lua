require("scripts/libs/const")
require("scripts/libs/debug")


-- Performs a breath search by looking at each connection of the first queue entry.
local function breadthFirstSearch(queue, visited, previous)
    local queueEntry = queue[1]
    table.remove(queue, 1)

    for _, connection in pairs(REGENERATION_GRAPH[queueEntry]) do
        if not visited[connection] then
            table.insert(queue, connection)
            visited[connection] = true
            previous[connection] = queueEntry
        end
    end
end


-- Performs a bidirectional graph search to find a path from the start to the end tile.
local function bidirectionalGraphSearch(startTile, endTile)
    local queueStart = {}
    local queueEnd = {}
    local previousStart = {}
    local previousEnd = {}
    local visitedStart = {}
    local visitedEnd = {}

    table.insert(queueStart, startTile)
    table.insert(queueEnd, endTile)
    visitedStart[startTile] = true
    visitedEnd[endTile] = true
    local intersection = nil

    debug.print("Begin Graph search for " .. startTile .. " to " .. endTile .. ".")

    while #queueStart > 0 and #queueEnd > 0 and intersection == nil do
        breadthFirstSearch(queueStart, visitedStart, previousStart)
        breadthFirstSearch(queueEnd, visitedEnd, previousEnd)

        for tile, _ in pairs(REGENERATION_GRAPH) do
            if visitedStart[tile] and visitedEnd[tile] then
                intersection = tile
                break
            end
        end
    end

    if not intersection then
        debug.printWarning("Search ended without intersection")
        return nil
    end

    debug.print("Search ended with intersection at " .. intersection)

    local path = {}

    local startIntersection = intersection
    while startIntersection do
        table.insert(path, 1, startIntersection)
        startIntersection = previousStart[startIntersection]
    end

    local endIntersection = previousEnd[intersection]
    while endIntersection do
        table.insert(path, endIntersection)
        endIntersection = previousEnd[endIntersection]
    end

    debug.printGraphPath(path)

    -- Remove the first path entry because it is the start tile.
    table.remove(path, 1)

    return path
end


-- Searches for a path of tiles that the tile will change its textures to when regenerating.
function CalculateRegenerationPath(entryTile)
    return bidirectionalGraphSearch(entryTile.currentTile, entryTile.startTile)
end
