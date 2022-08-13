require("scripts/libs/const")


-----------------------------------------------------------------------------------------
-- Settings
-----------------------------------------------------------------------------------------


-- Should debug messages be printed and commands be usable.
EnableDebug = settings.startup["natural-path--general--enableDebug"].value

-- How often should the regeneration script execute.
TicksBetweenUpdates = settings.startup["natural-path--general--ticksBetweenUpdates"].value


-----------------------------------------------------------------------------------------
-- General
-----------------------------------------------------------------------------------------


-- The change of regeneration relative to the update time.
RegenerationDelta = TicksBetweenUpdates / DELTA_SCALE
