require("scripts/libs/vars")


-- Colors used for printing messages.
debug.white     = { r = 1, g = 1, b = 1, a = 1 }
debug.green     = { r = 0, g = 1, b = 0, a = 1 }
debug.yellow    = { r = 1, g = 1, b = 0, a = 1 }
debug.red       = { r = 1, g = 0, b = 0, a = 1 }


-- Prints a message in the chat console only if debug is enabled.
function debug.print(msg, player, color)
    if EnableDebug then
        player = player or game
        color = color or debug.white

        player.print(msg, color)
    end
end


-- Prints a debug message with a specific color.
function debug.printSuccess(msg, player)
    debug.print(msg, player, debug.green)
end


-- Prints a debug message with a specific color.
function debug.printWarning(msg, player)
    debug.print(msg, player, debug.yellow)
end


-- Prints a debug message with a specific color.
function debug.printError(msg, player)
    debug.print(msg, player, debug.red)
end


-- Special method to print the path found by the grap search.
function debug.printGraphPath(path, player)
    local msg = "Found Path for " .. path[1] .. ": "

    for i, entry in pairs(path) do
        if i ~= 1 then
            if i == 2 then
                msg = msg .. entry
            else
                msg = msg .. " -> " .. entry
            end
        end
    end

    debug.print(msg, player, debug.green)
end
