require("scripts/libs/table")


local function initializeTable()
    if not global.tile_table then
        global.tile_table = {}

        for _, surface in pairs(game.surfaces) do
            global.tile_table[GetSurfaceKey(surface)] = {}
        end
    end
end


script.on_init(initializeTable)
script.on_configuration_changed(initializeTable)
