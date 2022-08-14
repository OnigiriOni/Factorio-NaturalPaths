require("scripts/libs/debug")




local function onVehicleBuildEvent(event)
    local player = game.players[event.player_index]
    local entity = event.created_entity

    debug.print(entity.name .. " //" .. entity.type .. "was build by " .. player.name, player)
end



local filter = {{filter = "type", name = "car"}, {filter = "type", name = "spider-vehicle"}}

script.on_event(defines.events.on_built_entity, onVehicleBuildEvent)