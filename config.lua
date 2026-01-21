--[[
    LonexDiscordAPI Configuration
    https://github.com/LonexLabs/LonexDiscordAPI
    
    server.cfg:
        set lonex_discord_token "YOUR_BOT_TOKEN"
        set lonex_discord_guild "YOUR_GUILD_ID"
        ensure LonexDiscordAPI
]]

Config = {}

Config.Debug = false
Config.LogLevel = 'info'
Config.LogCacheRefresh = false

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

Config.Permissions = {
    Enabled = true,
    RefreshOnFetch = true,
    LogAssignments = true,
    DefaultPermissions = {},
    DefaultGroups = {},
    Roles = {
        -- ['ROLE_ID'] = { permissions = { 'perm.node' }, groups = { 'groupname' }, priority = 1 },
    },
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

Config.ChatRoles = {
    Enabled = false,
    DefaultRole = {
        prefix = '^7',
        name = 'Civilian',
    },
    -- Color codes: ^0=White ^1=Red ^2=Green ^3=Yellow ^4=Blue ^5=Cyan ^6=Pink ^7=White ^8=Orange ^9=Grey
    Roles = {
        -- { roleId = 'ROLE_ID', prefix = '^2[VIP] ', name = 'VIP' },
        -- { roleId = 'ROLE_ID', prefix = '^1[Admin] ', name = 'Admin' },
    },
}

Config.HeadTags = {
    Enabled = false,
    MenuCommand = 'headtags',
    MaxDistance = 20.0,
    HeightOffset = 1.0,
    Font = 4,
    Scale = 0.4,
    DefaultShowOthers = true,
    DefaultShowOwn = true,
    DefaultTag = {
        text = 'Player',
        color = { r = 255, g = 255, b = 255 },
    },
    Roles = {
        -- { roleId = 'ROLE_ID', text = 'VIP', color = { r = 0, g = 255, b = 0 } },
        -- { roleId = 'ROLE_ID', text = 'Admin', color = { r = 255, g = 165, b = 0 } },
        -- { roleId = 'ROLE_ID', text = 'Owner', color = { r = 255, g = 0, b = 0 } },
    },
}
