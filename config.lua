--[[
    LonexDiscordAPI Configuration
    https://github.com/LonexLabs/LonexDiscordAPI
    
    server.cfg:
        exec @LonexDiscordAPI/lonexperms.cfg
        set lonex_discord_token "YOUR_BOT_TOKEN"
        set lonex_discord_guild "YOUR_GUILD_ID"
        ensure LonexDiscordAPI
]]

-- ============================================================================
-- GENERAL SETTINGS (most users won't need to change these)
-- ============================================================================

Config = {}

Config.Debug = false
Config.LogLevel = 'info'
Config.LogCacheRefresh = false
Config.CheckUpdates = true

Config.ForceDefaultPed = {
    Enabled = false,
    Ped = 'a_m_y_hipster_02',
}

Config.Cache = {
    RolesTTL = 300,
    GuildTTL = 600,
    MemberTTL = 60,
    UserTTL = 300,
    MaxMembers = 500
}

Config.RateLimit = {
    Enabled = true,
    MaxRequestsPerSecond = 40,
    MaxQueueSize = 100,
    RetryOnLimit = true,
    MaxRetries = 3,
    RetryDelay = 1000
}

Config.Startup = {
    FetchGuildInfo = true,
    FetchRoles = true,
    InitDelay = 2000,
    ValidateToken = true
}

-- ============================================================================
-- PERMISSIONS
-- ============================================================================

Config.Permissions = {
    Enabled = true,         -- Enable/disable the permission system
    RefreshOnFetch = true,  -- Refresh permissions when Discord data updates
    LogAssignments = false, -- Log permission assignments to console
}

Roles = {
    -- ['1234567890123456789'] = 'admin',
    -- ['2345678901234567890'] = 'moderator', 
    -- ['3456789012345678901'] = 'vip',
    -- ['4567890123456789012'] = { 'staff', 'support' },
}

Config.Webhooks = {
    Enabled = true,
    RateLimit = 1000,
    MaxQueueSize = 50,
    DefaultColor = 5793266,
    IncludeTimestamp = true,
    Urls = {
        -- ['logs'] = 'https://discord.com/api/webhooks/...',
    },
    Templates = {
        ['player_join'] = {
            title = '👋 Player Connected',
            description = '**{player}** has joined the server',
            color = 5763719,
            fields = {
                { name = 'Discord', value = '{discord}', inline = true },
                { name = 'Player ID', value = '{id}', inline = true },
            },
        },
        ['player_leave'] = {
            title = '👋 Player Disconnected',
            description = '**{player}** has left the server',
            color = 15548997,
            fields = {
                { name = 'Reason', value = '{reason}', inline = false },
            },
        },
    },
}

Config.WeaponPermissions = {
    Enabled = false,
    CheckInterval = 1000,
    RemoveWeapon = true,
    NotifyPlayer = true,
    NotifyMessage = 'You do not have permission to use this weapon.',
    Roles = {
        -- ['ROLE_ID'] = { 'WEAPON_PISTOL', 'WEAPON_SMG' },
        -- ['ADMIN_ROLE_ID'] = {}, -- Empty = no restrictions
    },
    RestrictedWeapons = {
        'WEAPON_STUNGUN',
        'WEAPON_NIGHTSTICK',
        'WEAPON_RPG',
        'WEAPON_GRENADELAUNCHER',
        'WEAPON_MINIGUN',
        'WEAPON_FIREWORK',
        'WEAPON_RAILGUN',
        'WEAPON_HOMINGLAUNCHER',
        'WEAPON_MG',
        'WEAPON_COMBATMG',
        'WEAPON_COMBATMG_MK2',
        'WEAPON_STICKYBOMB',
        'WEAPON_PROXMINE',
        'WEAPON_PIPEBOMB',
    },
}

Config.VehiclePermissions = {
    Enabled = false,
    CheckInterval = 1000,
    EjectPlayer = true,
    DeleteVehicle = false,
    NotifyPlayer = true,
    NotifyMessage = 'You do not have permission to use this vehicle.',
    EjectDelay = 0,
    Roles = {
        -- ['POLICE_ROLE_ID'] = { 'police', 'police2', 'police3' },
        -- ['EMS_ROLE_ID'] = { 'ambulance', 'firetruk' },
        -- ['ADMIN_ROLE_ID'] = {}, -- Empty = no restrictions
    },
    RestrictedVehicles = {
        'police', 'police2', 'police3', 'police4', 'policeb', 'policet',
        'sheriff', 'sheriff2', 'pranger', 'riot', 'riot2', 'fbi', 'fbi2',
        'ambulance', 'firetruk',
        'rhino', 'barracks', 'crusader', 'insurgent', 'insurgent2', 'insurgent3', 'apc', 'khanjali',
    },
}

Config.PedPermissions = {
    Enabled = false,
    CheckInterval = 1000,
    ResetPed = true,
    NotifyPlayer = true,
    NotifyMessage = 'You do not have permission to use this ped model.',
    DefaultPed = 'a_m_y_hipster_02',
    Roles = {
        -- ['POLICE_ROLE_ID'] = { 's_m_y_cop_01', 's_f_y_cop_01' },
        -- ['EMS_ROLE_ID'] = { 's_m_m_paramedic_01', 's_m_y_fireman_01' },
        -- ['ADMIN_ROLE_ID'] = {}, -- Empty = no restrictions
    },
    RestrictedPeds = {
        's_m_y_cop_01', 's_f_y_cop_01', 's_m_y_hwaycop_01', 's_m_y_sheriff_01', 's_f_y_sheriff_01', 'csb_cop',
        's_m_m_fibsec_01', 's_m_y_fibmugger_01',
        's_m_m_paramedic_01', 's_m_y_fireman_01',
        's_m_m_marine_01', 's_m_m_marine_02', 's_m_y_marine_01', 's_m_y_marine_02', 's_m_y_marine_03',
        's_m_m_pilot_02', 's_m_y_pilot_01',
        's_m_m_security_01', 's_m_y_security_01', 's_m_m_prisguard_01',
    },
}

Config.Tags = {
    Enabled = false,
    MenuCommand = 'tags',
    MenuPosition = 'left', -- 'left' or 'right'
    
    HeadTags = {
        Enabled = true,
        MaxDistance = 20.0,
        HeightOffset = 1.0,
        Font = 4,
        Scale = 0.4,
    },
    
    ChatTags = {
        Enabled = true,
    },
    
    VoiceTags = {
        Enabled = true,
        ShowSelf = true,
    },
    
    DefaultShowOthers = true,
    DefaultShowOwn = true,
    
    DefaultTag = {
        text = 'Player',
        color = { r = 255, g = 255, b = 255 },
        chatColor = '^7',
    },
    
    Roles = {
        -- { roleId = 'ROLE_ID', text = 'VIP', color = { r = 0, g = 255, b = 0 }, chatColor = '^2' },
        -- { roleId = 'ROLE_ID', text = 'Moderator', color = { r = 0, g = 191, b = 255 }, chatColor = '^4' },
        -- { roleId = 'ROLE_ID', text = 'Admin', color = { r = 255, g = 165, b = 0 }, chatColor = '^8' },
        -- { roleId = 'ROLE_ID', text = 'Owner', color = { r = 255, g = 0, b = 0 }, chatColor = '^1' },
    },
}

-- ============================================================================
-- EMERGENCY CALLS (911/311 System)
-- ============================================================================

Config.EmergencyCalls = {
    Enabled = false,
    
    -- Cooldown between calls (seconds)
    Cooldown = 60,
    
    -- Duty system - only on-duty players receive calls
    Duty = {
        Enabled = false,          -- Set to true to require duty
        Command = 'duty',         -- /duty to toggle
        DefaultOnDuty = false,    -- Are players on duty by default when joining?
        Messages = {
            OnDuty = '^2You are now ^3ON DUTY^2 and will receive emergency calls.',
            OffDuty = '^1You are now ^3OFF DUTY^1 and will not receive emergency calls.',
            MustBeOnDuty = '^1You must be on duty to respond to calls. Use /duty to go on duty.',
        },
    },
    
    -- Call types configuration
    Types = {
        ['911'] = {
            Enabled = true,
            Command = '911',           -- /911 <message>
            Label = '911 Emergency',
            Color = 0xFF0000,          -- Red (Discord embed color in hex)
            ChannelId = '',            -- Discord channel ID to send calls
            
            -- Roles that can see calls in-game and respond
            ResponderRoles = {
                -- 'ROLE_ID_1',
                -- 'ROLE_ID_2',
            },
            
            -- Chat prefix for in-game notifications
            Prefix = '^1[911]^0',
            
            -- Messages
            Messages = {
                Sent = '^2Your 911 call has been sent to emergency services.',
                NoMessage = '^1Please provide details for your 911 call. Usage: /911 <message>',
                Cooldown = '^1Please wait before making another call.',
            },
        },
        
        ['311'] = {
            Enabled = false,
            Command = '311',           -- /311 <message>
            Label = '311 Non-Emergency',
            Color = 0x00FF00,          -- Green
            ChannelId = '',            -- Discord channel ID
            
            ResponderRoles = {
                -- 'ROLE_ID_1',
            },
            
            Prefix = '^2[311]^0',
            
            Messages = {
                Sent = '^2Your 311 report has been submitted.',
                NoMessage = '^1Please provide details. Usage: /311 <message>',
                Cooldown = '^1Please wait before making another report.',
            },
        },
    },
    
    -- Response command
    Response = {
        Command = 'resp',              -- /resp <call_id>
        Messages = {
            InvalidCall = '^1Invalid call ID or call no longer exists.',
            Responding = '^2Waypoint set. Responding to call #%s.',
            NoPermission = '^1You do not have permission to respond to calls.',
        },
    },
}

-- ============================================================================
-- AREA OF PLAY (AOP)
-- ============================================================================

Config.AOP = {
    Enabled = false,
    Command = 'aop',               -- /aop <zone>
    Default = 'All of San Andreas',
    
    -- Discord roles that can change AOP (empty = everyone)
    AllowedRoles = {
        -- 'ROLE_ID_1',
        -- 'ROLE_ID_2',
    },
    
    Messages = {
        Changed = '^2AOP has been changed to: ^3%s',
        NoPermission = '^1You do not have permission to change the AOP.',
        Usage = '^1Usage: /aop <zone name>',
    },
}

-- ============================================================================
-- PEACETIME
-- ============================================================================

Config.PeaceTime = {
    Enabled = false,
    Commands = { 'peacetime', 'pt' },  -- Both commands work
    Default = false,                    -- PeaceTime off by default
    
    -- Discord roles that can toggle PeaceTime (empty = everyone)
    AllowedRoles = {
        -- 'ROLE_ID_1',
    },
    
    -- Restrictions during PeaceTime
    Restrictions = {
        -- Prevent drawing/using weapons
        DisableWeapons = true,
        
        -- Speed limit warning
        SpeedLimit = {
            Enabled = true,
            Limit = 65,           -- Speed limit value
            Unit = 'mph',         -- 'mph' or 'kmh'
            WarningInterval = 5,  -- Seconds between warnings
        },
    },
    
    Messages = {
        Enabled = '^2PeaceTime is now ^3ENABLED^2. No criminal activity!',
        Disabled = '^1PeaceTime is now ^3DISABLED^1. Crime is allowed.',
        NoPermission = '^1You do not have permission to toggle PeaceTime.',
        WeaponBlocked = '~r~Weapons are disabled during PeaceTime!',
        SpeedWarning = '~y~Slow down! Speed limit during PeaceTime is %s %s',
    },
}

-- ============================================================================
-- ANNOUNCEMENTS
-- ============================================================================

Config.Announcements = {
    Enabled = false,
    Command = 'announce',          -- /announce <message>
    
    -- Discord roles that can make announcements (empty = everyone)
    AllowedRoles = {
        -- 'ROLE_ID_1',
    },
    
    -- Display settings
    Header = '~b~[~p~Server Announcement~b~]',
    Duration = 10,                 -- Seconds to display
    Position = 0.3,                -- 0 = top, 0.3 = middle, 0.5 = center
    
    Messages = {
        NoPermission = '^1You do not have permission to make announcements.',
        Usage = '^1Usage: /announce <message>',
        Sent = '^2Announcement sent!',
    },
}

-- ============================================================================
-- POSTALS
-- ============================================================================

Config.Postals = {
    Enabled = false,
    Command = 'postal',            -- /postal <code> or /postal to cancel
    
    Messages = {
        Set = '^2Waypoint set to postal ^3%s^2.',
        Cancelled = '^3Postal waypoint cancelled.',
        NotFound = '^1Postal code ^3%s^1 not found.',
        Usage = '^1Usage: /postal <code> or /postal to cancel waypoint',
    },
}

-- ============================================================================
-- SERVER HUD
-- ============================================================================

Config.ServerHUD = {
    Enabled = false,
    ToggleCommand = 'togglehud',   -- /togglehud to show/hide
    
    -- Watermark/Server name (shown at top of HUD)
    Watermark = {
        Enabled = false,
        Text = 'My RP Server | discord.gg/myserver',
        x = 0.165,
        y = 0.825,
        scale = 0.4,
    },
    
    -- Configurable display elements
    -- Use GTA color codes: ~r~ red, ~g~ green, ~b~ blue, ~y~ yellow, ~p~ purple, ~w~ white
    -- Placeholders: {COMPASS}, {STREET}, {ZONE}, {POSTAL}, {POSTAL_DIST}, {AOP}, {PEACETIME}, {ID}, {PLAYERS}, {TAG}
    Displays = {
        ['Compass'] = {
            x = 0.165,
            y = 0.85,
            display = "~w~| ~g~{COMPASS} ~w~|",
            scale = 1.0,
            enabled = true,
        },
        ['Street'] = {
            x = 0.22,
            y = 0.855,
            display = "~g~{STREET}",
            scale = 0.45,
            enabled = true,
        },
        ['Zone'] = {
            x = 0.22,
            y = 0.875,
            display = "~w~{ZONE}",
            scale = 0.45,
            enabled = true,
        },
        ['Postal'] = {
            x = 0.165,
            y = 0.91,
            display = "~w~Nearest ~g~Postal: ~w~{POSTAL} (~g~{POSTAL_DIST}m~w~)",
            scale = 0.4,
            enabled = true,
        },
        ['AOP'] = {
            x = 0.165,
            y = 0.93,
            display = "~w~Current ~g~AOP: ~w~{AOP} ~y~| ~w~PeaceTime: {PEACETIME}",
            scale = 0.4,
            enabled = true,
        },
        ['PlayerInfo'] = {
            x = 0.165,
            y = 0.953,
            display = "~w~Tag: ~g~{TAG} ~y~| ~w~ID: ~g~{ID}",
            scale = 0.4,
            enabled = true,
        },
    },
}

-- ============================================================================
-- VEHICLE MANAGEMENT
-- ============================================================================

Config.DeleteVehicle = {
    Enabled = true,
    Command = 'dv',                -- /dv to delete current/nearby vehicle
    
    -- Discord roles that can use /dv (empty = everyone)
    AllowedRoles = {
        -- 'ROLE_ID_1',
        -- 'ROLE_ID_2',
    },
    
    -- Search radius for nearby vehicle (if not in one)
    SearchRadius = 5.0,
    
    Messages = {
        Deleted = '^2Vehicle deleted.',
        NotFound = '^1No vehicle found nearby.',
        NoPermission = '^1You do not have permission to delete vehicles.',
    },
}

Config.DeleteAllVehicles = {
    Enabled = true,
    Command = 'dvall',             -- /dvall to delete all unoccupied vehicles
    
    -- Discord roles that can use /dvall (empty = everyone)
    AllowedRoles = {
        -- 'ROLE_ID_1',
    },
    
    -- Countdown before deletion (seconds)
    Countdown = 20,
    
    -- Only delete vehicles with no occupants
    OnlyUnoccupied = true,
    
    Messages = {
        Starting = '^3[SERVER] ^1All unoccupied vehicles will be deleted in %d seconds!',
        Countdown = '^3[SERVER] ^1Vehicles being deleted in %d seconds...',
        Deleted = '^3[SERVER] ^2%d unoccupied vehicles have been deleted.',
        NoPermission = '^1You do not have permission to delete all vehicles.',
        AlreadyRunning = '^1A vehicle deletion is already in progress.',
    },
}

-- ============================================================================
-- CLEAR CHAT
-- ============================================================================

Config.ClearChat = {
    Enabled = true,
    Command = 'clearchat',         -- /clearchat to clear server chat
    
    -- Discord roles that can clear chat (empty = everyone)
    AllowedRoles = {
        -- 'ROLE_ID_1',
    },
    
    -- Number of blank lines to send (effectively clears chat)
    BlankLines = 100,
    
    -- Show who cleared the chat
    ShowClearedBy = true,
    
    Messages = {
        Cleared = '^3[SERVER] ^2Chat has been cleared by ^3%s^2.',
        NoPermission = '^1You do not have permission to clear chat.',
    },
}
