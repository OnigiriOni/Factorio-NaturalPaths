-----------------------------------------------------------------------------------------
-- General Settings
-----------------------------------------------------------------------------------------


data:extend({
    {
        type = "bool-setting",
        name = "natural-path--general--enableDebug",
        description = "natural-path--general--enableDebug",
        setting_type = "startup",
        default_value = false,
        order = "-",
    },
    {
        type = "int-setting",
        name = "natural-path--general--ticksBetweenUpdates",
        description = "natural-path--general--ticksBetweenUpdates",
        setting_type = "startup",
        default_value = 3600,
        order = "-",
    },
})


-----------------------------------------------------------------------------------------
-- Customization Settings
-----------------------------------------------------------------------------------------


data:extend({
    {
        type = "bool-setting",
        name = "natural-path--general--enableUnreachableTiles",
        description = "natural-path--general--enableUnreachableTiles",
        setting_type = "startup",
        default_value = true,
        order = "a",
    },
})
