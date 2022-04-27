require("scripts/libs/const")


-----------------------------------------------------------------------------------------
-- Settings
-----------------------------------------------------------------------------------------

-- Should debug messages be printed and commands be usable.
enableDebug = settings.startup["natural-path--general--enableDebug"].value

-- How often should the regeneration script execute.
ticksBetweenUpdates = settings.startup["natural-path--general--ticksBetweenUpdates"].value


-----------------------------------------------------------------------------------------
-- General
-----------------------------------------------------------------------------------------

-- The change of regeneration relative to the update time.
regenerationDelta = ticksBetweenUpdates / DELTA_SCALE
