--[[
    LonexDiscordAPI Configuration
    https://github.com/LonexLabs/LonexDiscordAPI
    
    server.cfg:
        set lonex_discord_token "YOUR_BOT_TOKEN"
        set lonex_discord_guild "YOUR_GUILD_ID"
        add_ace resource.LonexDiscordAPI command allow
        ensure LonexDiscordAPI
]]

Config = {}

Config.Debug = false
Config.LogLevel = 'info' -- 'error', 'warn', 'info', 'debug'

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

    --[[
        Role ID -> Permissions mapping
        Get Role IDs: Discord Developer Mode -> Right-click role -> Copy Role ID
        
        ['ROLE_ID'] = {
            permissions = { 'perm.node' },
            groups = { 'groupname' },
            inherits = { 'OTHER_ROLE_ID' },
            priority = 1,
        }
    ]]
    Roles = {
        -- ['123456789012345678'] = {
        --     permissions = { 'command.help' },
        --     groups = { 'user' },
        --     priority = 1,
        -- },
    },
}

Config.Webhooks = {
    Enabled = true,
    RateLimit = 1000,
    MaxQueueSize = 50,
    DefaultColor = 5793266,
    IncludeTimestamp = true,

    -- ['name'] = 'https://discord.com/api/webhooks/...'
    Urls = {},

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
        ['admin_action'] = {
            title = '⚠️ Admin Action',
            description = '**{admin}** performed an action',
            color = 16776960,
            fields = {
                { name = 'Action', value = '{action}', inline = true },
                { name = 'Target', value = '{target}', inline = true },
                { name = 'Reason', value = '{reason}', inline = false },
            },
        },
    },
}
