-- Factorios standard chunk size 32x32 tiles.
-- 32 -> 32 * 32 = 1024 max tiles per chunk update.
-- Can be changed if a chunk update should update more or less tiles.
CHUNK_SIZE = 32


-- In Factorio 60 ticks are 1 second.
-- If we want to change a value over time we need to make sure the mods custom tickrate does not change the rate at which the value changes.
-- 3600 ticks = 1 minute -> tile regeneration 10 = tiles will recover over the span of 10 minutes.
DELTA_SCALE = 3600


-- Names of surfaces that should not be modified.
-- This is checked with string.find() and does not have to be identical to the whole surface name.
-- When adding more surface names be sure that they are not disabling additional surfaces.
INVALID_SURFACES = {
    "Factory",
}


-- Types of vehicles that should not modify tiles.
-- Vehicle types that should not modify tiles should be added here.
INVALID_VEHICLES = {
    "locomotive",
}


-- Items max stack size determines the weight of the item stack.
-- Items with a stack size not given as index always takes the closest previous index's weight or [1].
-- A whole stack of items with a max stack size of 5 weights 8. If the stack only has 1 item it weights 1.6.
INVENTORY_STACK_WEIGHTS = {
    [1] =   10,
    [5] =    8,
    [10] =   5,
    [50] =   2,
    [100] =  1,
}


-- Information about tile types.
-- Regeneration determines how much time it takes to heal and change to another tile.
-- When changing values see DELTA_SCALE for the time scale.
TILE_INFO = {
    ["grass-1"] =      { threshold = 5000, hardness = 1.24, regeneration = 15 },
    ["grass-2"] =      { threshold = 4800, hardness = 1.25, regeneration = 15 },
    ["grass-3"] =      { threshold = 4600, hardness = 1.24, regeneration = 15 },
    ["grass-4"] =      { threshold = 4500, hardness = 1.20, regeneration = 15 },

    ["red-desert-0"] = { threshold = 4200, hardness = 1.25, regeneration = 15 },
    ["red-desert-1"] = { threshold = 4000, hardness = 1.30, regeneration = 15 },
    ["red-desert-2"] = { threshold = 4000, hardness = 1.35, regeneration = 16 },
    ["red-desert-3"] = { threshold = 4000, hardness = 1.40, regeneration = 17 },

    ["dirt-1"] =       { threshold = 3900, hardness = 1.30, regeneration = 15 },
    ["dirt-2"] =       { threshold = 3900, hardness = 1.28, regeneration = 15 },
    ["dirt-3"] =       { threshold = 3800, hardness = 1.26, regeneration = 15 },
    ["dirt-4"] =       { threshold = 3700, hardness = 1.17, regeneration = 16 },
    ["dirt-5"] =       { threshold = 3800, hardness = 1.30, regeneration = 17 },
    ["dirt-6"] =       { threshold = 3700, hardness = 1.22, regeneration = 18 },
    ["dirt-7"] =       { threshold = 3600, hardness = 1.15, regeneration = 18 },
    ["dry-dirt"] =     { threshold = 3800, hardness = 1.40, regeneration = 20 },

    ["sand-1"] =       { threshold = 3000, hardness = 1.00, regeneration = 18 },
    ["sand-2"] =       { threshold = 3000, hardness = 0.90, regeneration = 20 },
    ["sand-3"] =       { threshold = 3500, hardness = 1.20, regeneration = 18 },

    ["landfill"] =     { threshold = 3800, hardness = 1.10, regeneration = 20 },
}


-- Information about vehicles and the character which determine how a tile deteriorates.
-- If a vehicle is not listed here it will use the default entry.
-- Can be modified as desired. Add new vehicles by name (not by type).
-- Make sure unreachableTiles does not block off paths too much.
VEHICLES = {
    ["default"]             = { weight =  1500, destruction = 1.10, pattern =   "plus", unreachableTiles = {} },
    ["character"]           = { weight =   100, destruction = 1.01, pattern = "center", unreachableTiles = {"landfill"} },
    ["car"]                 = { weight =  1000, destruction = 1.10, pattern =   "plus", unreachableTiles = {"landfill"} },
    ["vehicle-chaingunner"] = { weight =  2000, destruction = 1.32, pattern =   "plus", unreachableTiles = {"landfill"} },
    ["vehicle-warden"]      = { weight =  3000, destruction = 1.20, pattern =   "plus", unreachableTiles = {"landfill"} },
    ["vehicle-hauler"]      = { weight =  4000, destruction = 1.20, pattern =   "plus", unreachableTiles = {"landfill"} },
    ["immolator"]           = { weight =  6000, destruction = 1.07, pattern = "center", unreachableTiles = {} },
    ["spidertron"]          = { weight =  7000, destruction = 1.06, pattern = "center", unreachableTiles = {} },
    ["spidertron-builder"]  = { weight =  8000, destruction = 1.04, pattern = "center", unreachableTiles = {} },
    ["spidertronmk2"]       = { weight =  9000, destruction = 1.07, pattern = "center", unreachableTiles = {} },
    ["spidertronmk3"]       = { weight = 10000, destruction = 1.08, pattern = "center", unreachableTiles = {} },
    ["spidertronmk4"]       = { weight = 11000, destruction = 1.08, pattern = "center", unreachableTiles = {} },
    ["vehicle-flame-tank"]  = { weight = 18000, destruction = 1.32, pattern =   "plus", unreachableTiles = {} },
    ["vehicle-laser-tank"]  = { weight = 20000, destruction = 1.32, pattern =   "plus", unreachableTiles = {} },
    ["tank"]                = { weight = 25000, destruction = 1.35, pattern =   "plus", unreachableTiles = {} },
    ["kr-advanced-tank"]    = { weight = 30000, destruction = 1.38, pattern =    "box", unreachableTiles = {} },
}


-- Tiles deteriorate differently if a player walks or drives over them.
-- This is not stored in TILE_INFO[] for readability.
-- Can be modified as desired. Loops should be fine but are not tested.
DETERIORATION_PATHS = {
    ["grass-1"] =      { nextWalking = "grass-3",       nextVehicle = "grass-2" },
    ["grass-2"] =      { nextWalking = "grass-3",       nextVehicle = "grass-4" },
    ["grass-3"] =      { nextWalking = "red-desert-0",  nextVehicle = "grass-4" },
    ["grass-4"] =      { nextWalking = "dirt-6",        nextVehicle = "dirt-4"  },

    ["red-desert-0"] = { nextWalking = "dirt-3",        nextVehicle = "dirt-3" },
    ["red-desert-1"] = { nextWalking = "red-desert-2",  nextVehicle = "dirt-3" },
    ["red-desert-2"] = { nextWalking = "red-desert-3",  nextVehicle = "dirt-1" },
    ["red-desert-3"] = { nextWalking = "sand-3",        nextVehicle = "sand-3" },

    ["dirt-1"] =       { nextWalking = "red-desert-3",  nextVehicle = "dirt-2" },
    ["dirt-2"] =       { nextWalking = "dirt-1",        nextVehicle = "dirt-3" },
    ["dirt-3"] =       { nextWalking = "red-desert-1",  nextVehicle = "dirt-4" },
    ["dirt-4"] =       { nextWalking = "dirt-6",        nextVehicle = "dirt-7" },
    ["dirt-5"] =       { nextWalking = "dry-dirt",      nextVehicle = "dirt-6" },
    ["dirt-6"] =       { nextWalking = "dirt-5",        nextVehicle = "dirt-4" },
    ["dirt-7"] =       { nextWalking = "dirt-5",        nextVehicle = "landfill" },
    ["dry-dirt"] =     { nextWalking = nil,             nextVehicle = "dirt-5" },
    
    ["sand-1"] =       { nextWalking = "sand-2",        nextVehicle = "sand-2" },
    ["sand-2"] =       { nextWalking = nil,             nextVehicle = nil },
    ["sand-3"] =       { nextWalking = "sand-1",        nextVehicle = "sand-1" },

    ["landfill"] =     { nextWalking = nil,             nextVehicle = nil },
}


-- A graph where tiles (index) are connected with other tiles (value table).
-- If a tile regenerates it chooses the tile connection which is closest in the connection path to the original tile.
-- This influences how it will look like when tiles regenerate.
-- When changing connections make sure there is a path from each tile to each other tile.
-- If a tile is reachable over two tiles at the same distance it will always choose the first (leftmost) tile.
REGENERATION_GRAPH = {
    ["grass-1"] =      { "grass-3", "grass-2" },
    ["grass-2"] =      { "grass-1", "grass-3", "grass-4", "red-desert-0" },
    ["grass-3"] =      { "grass-1", "grass-2", "grass-4", "red-desert-0" },
    ["grass-4"] =      { "grass-2", "grass-3", "red-desert-0", "dirt-7" },

    ["red-desert-0"] = { "grass-3", "grass-2", "grass-4", "red-desert-1" },
    ["red-desert-1"] = { "red-desert-0", "red-desert-2", "dirt-3" },
    ["red-desert-2"] = { "red-desert-1", "red-desert-3" },
    ["red-desert-3"] = { "red-desert-2", "dirt-2", "dirt-1", "sand-3" },

    ["dirt-1"] =       { "sand-3", "red-desert-3", "dirt-2" },
    ["dirt-2"] =       { "dirt-1", "dirt-3", "red-desert-3" },
    ["dirt-3"] =       { "dirt-2", "dirt-4", "red-desert-1" },
    ["dirt-4"] =       { "dirt-3", "dirt-6", "landfill" },
    ["dirt-5"] =       { "dirt-6", "dirt-7", "dry-dirt" },
    ["dirt-6"] =       { "dirt-4", "dirt-5" },
    ["dirt-7"] =       { "dirt-5", "landfill", "grass-4" },
    ["dry-dirt"] =     { "dirt-5" },

    ["sand-1"] =       { "sand-2", "sand-3" },
    ["sand-2"] =       { "sand-1" },
    ["sand-3"] =       { "sand-1", "dirt-1", "red-desert-3" },

    ["landfill"] =     { "dirt-7", "dirt-4" },
}


-- Offsets for the player position in which tiles are affected when moving.
-- Add a new pattern and reference it in VEHICLES[] to use it.
PATTERNS = {
    ["center"] = {
        {x = 0, y = 0},
    },
    ["plus"] = {
        {x = -1, y =  0},
        {x =  1, y =  0},
        {x =  0, y = -1},
        {x =  0, y =  1},
        {x =  0, y =  0},
    },
    ["crosshair"] = {
        {x = -1, y =  0},
        {x =  1, y =  0},
        {x =  0, y = -1},
        {x =  0, y =  1},
    },
    ["corners"] = {
        {x = -1, y = -1},
        {x =  1, y = -1},
        {x = -1, y =  1},
        {x =  1, y =  1},
    },
    ["cross"] = {
        {x = -1, y = -1},
        {x =  1, y = -1},
        {x = -1, y =  1},
        {x =  1, y =  1},
        {x =  0, y =  0},
    },
    ["box"] = {
        {x = -1, y = -1},
        {x =  0, y = -1},
        {x =  1, y = -1},
        {x = -1, y =  0},
        {x =  1, y =  0},
        {x = -1, y =  1},
        {x =  0, y =  1},
        {x =  1, y =  1},
    },
    ["full"] = {
        {x = -1, y = -1},
        {x =  0, y = -1},
        {x =  1, y = -1},
        {x = -1, y =  0},
        {x =  0, y =  0},
        {x =  1, y =  0},
        {x = -1, y =  1},
        {x =  0, y =  1},
        {x =  1, y =  1},
    },
    ["5x5"] = {
        {x = -2, y = -2},
        {x = -1, y = -2},
        {x =  0, y = -2},
        {x =  1, y = -2},
        {x =  2, y = -2},
        {x = -2, y = -1},
        {x = -1, y = -1},
        {x =  0, y = -1},
        {x =  1, y = -1},
        {x =  2, y = -1},
        {x = -2, y =  0},
        {x = -1, y =  0},
        {x =  0, y =  0},
        {x =  1, y =  0},
        {x =  2, y =  0},
        {x = -2, y =  1},
        {x = -1, y =  1},
        {x =  0, y =  1},
        {x =  1, y =  1},
        {x =  2, y =  1},
        {x = -2, y =  2},
        {x = -1, y =  2},
        {x =  0, y =  2},
        {x =  1, y =  2},
        {x =  2, y =  2},        
    },
}
