require("scripts/libs/const")
require("scripts/compat/jetpackmod")
require("scripts/playerstates/character")
require("scripts/playerstates/vehicle")

local debug = require("scripts/libs/debug")


-- Returns if the given player is the driver of the vehicle they are in.
function isPlayerDriver(player)
    local driver = player.vehicle.get_driver()

    -- The driver can be an entity or player so we check for both.
    -- If the name is not equal then we might check an entity whith name == 'character'.
    -- In this case get the player of the entity and check again.
    if driver.name ~= player.name then
        driver = driver.player

        if driver.name ~= player.name then
            return false
        end
    end

    return true
end


-- Checks if a player can deteriorate tiles.
function canPlayerDeteriorateTiles(player)

    -- Godmode , edit-mode and other instances where a player might not have a character to walk with.
    if not player.character then return false end

    if not isSurfaceValid(player.surface.name) then return false end

    if player.walking_state.walking then
        
        -- Jetpack Mod - Check if the character is flying with the jetpack.
        if isPlayerUsingJetpack(player) then return false end

        return true
    end
    
    if player.vehicle then

        -- Let the driver player apply the deterioration. Multipayer clown cars should not apply deterioration multiple times.
        if not isPlayerDriver(player) then return false end

        if not isVehicleValid(player.vehicle.type) then return false end

        return true
    end

    return false
end


function onPlayerChangedPosition(event)
    local player = game.players[event.player_index]
    
    if canPlayerDeteriorateTiles(player) then
        local surfaceTilesToEdit = {}
        local tilesToUpdate = {}

        if player.vehicle then
            local vehicleInfo = VEHICLES[player.vehicle.name] or VEHICLES["default"]

            surfaceTilesToEdit = getSurfaceTilesInPatternForVehicle(player, vehicleInfo)
            tilesToUpdate = deteriorateTilesVehicle(surfaceTilesToEdit, player, vehicleInfo)
        else
            local characterInfo = VEHICLES["character"]

            surfaceTilesToEdit = getSurfaceTilesInPatternForCharacter(player, characterInfo)
            tilesToUpdate = deteriorateTilesCharacter(surfaceTilesToEdit, player, characterInfo)
        end

        updateTextureOfSurfaceTiles(player.surface, tilesToUpdate)
    end
end


script.on_event(defines.events.on_player_changed_position, onPlayerChangedPosition)
