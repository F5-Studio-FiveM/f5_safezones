Config = Config or {}

Config.Locales = "en"

Config.CheckInterval = 100 -- Zone check interval in ms

-- Default marker settings (can be overridden per zone)
Config.DefaultMarker = {
    type = 1, -- Cylinder
    color = {r = 245, g = 166, b = 35, a = 100},
    scale = {x = 1.0, y = 1.0, z = 1.0},
    height = 30.0,
    bobbing = false,
    pulsing = false,
    rotating = false,
    colorShift = false,
    autoLevel = true, -- Automatically adjust to ground level
    pulseSpeed = 2.0, -- Speed of pulse effect
    bobHeight = 0.5, -- Height of bobbing motion
    rotationSpeed = 1.0, -- Speed of rotation
    renderDistance = 150.0 -- Default render distance for zones
}

-- Available marker types
Config.MarkerTypes = {
    [1] = "Cylinder",
    [2] = "Circle Fat",
    [3] = "Circle Skinny",
    [4] = "Circle Arrow",
    [5] = "Split Arrow",
    [6] = "Dome"
}

-- Marker type ID mapping (internal type to GTA native marker ID)
-- Note: Type 6 (Dome) uses custom DrawPoly rendering, not native marker
Config.MarkerTypeMapping = {
    [1] = 1,   -- Cylinder
    [2] = 23,  -- Circle Fat
    [3] = 25,  -- Circle Skinny
    [4] = 26,  -- Circle Arrow
    [5] = 27,  -- Split Arrow
    [6] = 0    -- Dome (custom rendered using DrawPoly)
}

-- Polygon marker settings
Config.PolygonMarker = {
    wallColor = {r = 245, g = 166, b = 35, a = 50},
    groundColor = {r = 245, g = 166, b = 35, a = 30},
    wallHeight = 20.0,
    pulseEffect = false,
    gradientEffect = true,
    cornerBeams = true,
    insideOpacity = 0.8 -- Opacity multiplier for walls when viewed from inside (0.1-1.0)
}

-- Collision system settings
Config.CollisionSystem = {
    range = 100.0, -- Range to detect vehicles/entities for collision
    explosionRange = 100.0, -- Range to cancel explosions near safezone players
    vehicleAlpha = 200, -- Transparency level for vehicles (0-255)
    playerAlpha = 200, -- Transparency level for player in safezone (0-255)
}

-- Debug visualization settings
Config.DebugOptions = {
    enabled = false,
    markerColor = {r = 255, g = 0, b = 255, a = 150},
    showCoordinates = true,
    showZoneInfo = true,
}

-- Performance optimization
Config.Performance = {
    lodDistances = {
        medium = 150.0 -- Reduced quality threshold
    },
    updateIntervals = {
        playerCache = 600, -- Update player position cache
        markerList = 1000, -- Update which markers to render
        collisionCheck = 450, -- Update collision entities
        weaponCheck = 250, -- Check if player switched weapons
        invincibility = 1000, -- Refresh invincibility state
        vehicleProtection = 1000 -- Refresh vehicle protection state
    }
}

-- Safezone definitions (with enhanced marker configurations)
Config.Safezones = {
    {
        name = "Legion Square",
        type = "circle",
        coords = vector3(195.17, -933.77, 29.7),
        radius = 50.0,
        minZ = -50,
        maxZ = 150,
        showBlip = true,
        showMarker = true,
        blipName = "Safe Zone - Legion Square",
        -- Collision system options (all default to true if not specified)
        enableInvincibility = true, -- Make players invincible inside the zone
        enableGhosting = true, -- Enable player/vehicle ghosting
        preventVehicleDamage = true, -- Prevent vehicle damage to players
        disableVehicleWeapons = true, -- Disable vehicle-mounted weapons
        collisionDisabled = false, -- Set to true to completely disable collision system for this zone
        -- Render distance configuration
        renderDistance = 50.0 -- Distance from zone center to render the marker
    } 
}

-- Effect presets for quick configuration
Config.MarkerPresets = {
    safe = {
        type = 1,
        color = {r = 245, g = 166, b = 35, a = 100},
        pulsing = true,
        pulseSpeed = 1.0,
        renderDistance = 150.0
    },
    danger = {
        type = 1,
        color = {r = 255, g = 0, b = 0, a = 100},
        pulsing = true,
        bobbing = true,
        pulseSpeed = 3.0,
        bobHeight = 0.5,
        renderDistance = 200.0
    },
    special = {
        type = 4, -- Circle Arrow (was 43, outside valid MarkerTypes range)
        color = {r = 255, g = 215, b = 0, a = 150},
        rotating = true,
        pulsing = true,
        colorShift = true,
        rotationSpeed = 1.5,
        pulseSpeed = 2.0,
        renderDistance = 250.0
    },
    vip = {
        type = 5, -- Split Arrow (was 9, outside valid MarkerTypes range)
        color = {r = 255, g = 215, b = 0, a = 200},
        bobbing = true,
        rotating = true,
        colorShift = true,
        bobHeight = 1.0,
        rotationSpeed = 2.0,
        renderDistance = 300.0
    }
}

-- Admin ACE permissions (players with any of these will have safezone admin access)
Config.AdminPermissions = {
    'command', 'command.tx', 'txadmin', 'admin', 'moderator',
    'group.admin', 'group.moderator', 'safezones.admin', 'f5_safezones.admin'
}

-- ================================
-- COMMAND MANAGEMENT
-- ================================
Config.Commands = {
    szcoords = {
        name = 'szcoords',
        active = true,
        description = 'Get current coordinates'
    },
    szdebug = {
        name = 'szdebug',
        active = true,
        description = 'Toggle debug mode'
    },
    szadmin = {
        name = 'szadmin',
        active = true,
        description = 'Open admin panel'
    },
    sztoggle = {
        name = 'sztoggle',
        active = true,
        description = 'Toggle zone marker'
    },
    debugrender = {
        name = 'debugrender',
        active = true,
        description = 'Toggle render distance debug'
    },
    setrenderdist = {
        name = 'setrenderdist',
        active = true,
        description = 'Set zone render distance'
    },
    listsafezones = {
        name = 'listsafezones',
        active = true,
        description = 'List all safezones'
    }
}


-- ================================
-- AUDIT LOGGING SYSTEM
-- ================================
Config.Logging = {
    enabled = true,
    directory = '/data/logs',
    filePrefix = 'safezone-audit',
    retentionDays = 30,
    maxEntries = 500,

    -- Only these categories will be logged
    categories = {
        ZONE = true,
        SECURITY = true
    },

    -- Only these actions will be logged
    actions = {
        ['zone:create'] = true,
        ['zone:update'] = true,
        ['zone:delete'] = true,
        ['zone:toggle_marker'] = true,
        ['zone:toggle_activation'] = true,
        ['zone:toggle_activation_all'] = true,
        ['security:denied'] = true
    },

    -- Player identifier settings
    includeIdentifiers = true,
    identifierTypes = { 'steam', 'discord', 'license' },

    -- UI display settings
    ui = {
        showAdminName = true,
        showIdentifiers = true,
        dateFormat = 'DD/MM/YYYY HH:mm:ss'
    }
}

-- ================================
-- VERSION CHECK
-- ================================
Config.VersionCheck = true -- Check for updates on server start via GitHub Releases API
Config.GitHubRepo = 'F5-Studio-FiveM/f5_safezones' -- GitHub repository (owner/repo)

-- ================================
-- SYSTEM DEBUGGING
-- ================================
Config.BridgeLog = true -- Enable/disable bridge logs (framework detection, init). Errors always show.
Config.Debug = false -- Master debug toggle

Config.DebugCategories = {
    INIT = true,
    ZONE = true,
    COLLISION = true,
    NETWORK = true,
    ADMIN = true,
    UI = true,
    PLAYER = true,
    PERFORMANCE = true,
    COMMAND = true,
    ERROR = true,
    SUCCESS = true,
    DATA = true
}

Config.DebugColors = {
    INIT = "^3",       -- Yellow
    ZONE = "^2",       -- Green
    COLLISION = "^4",  -- Blue
    NETWORK = "^6",    -- Cyan
    ADMIN = "^9",      -- Bright red
    UI = "^5",         -- Purple
    PLAYER = "^4",     -- Blue
    PERFORMANCE = "^8",-- Orange
    COMMAND = "^3",    -- Yellow
    ERROR = "^1",      -- Red
    SUCCESS = "^2",    -- Green
    DATA = "^6"        -- Cyan
}

-- LOCALES !!DON'T TOUCH!!
function Translate(key)
    local languageCode = Config.Locales or "en"
    local localesTable = _G["Locales_" .. languageCode]
    if not localesTable then
        localesTable = _G["Locales_en"]
    end
    return localesTable and localesTable[key] or key
end
