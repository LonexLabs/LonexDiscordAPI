-- LonexDiscordAPI Server

local REQUIRED_RESOURCE_NAME = 'LonexDiscordAPI'

if GetCurrentResourceName() ~= REQUIRED_RESOURCE_NAME then
    print('^1[LonexDiscord] ERROR: Resource must be named "' .. REQUIRED_RESOURCE_NAME .. '"!^0')
    print('^1[LonexDiscord] Current name: "' .. GetCurrentResourceName() .. '"^0')
    print('^3[LonexDiscord] Please rename the resource folder to "' .. REQUIRED_RESOURCE_NAME .. '"^0')
    return
end

-- STARTUP VALIDATION

CreateThread(function()
    Wait(0)
    
    if Config.BotToken == '' then
        print('^1[LonexDiscord] ERROR: Bot token not configured!^0')
        print('^3[LonexDiscord] Set the convar: set lonex_discord_token "YOUR_BOT_TOKEN"^0')
    end

    if Config.GuildId == '' then
        print('^1[LonexDiscord] ERROR: Guild ID not configured!^0')
        print('^3[LonexDiscord] Set the convar: set lonex_discord_guild "YOUR_GUILD_ID"^0')
    end
end)


LonexDiscord = LonexDiscord or {}

-- PERMISSIONS MODULE (embedded)

LonexDiscord.Permissions = {}

local PermissionsModule = LonexDiscord.Permissions

-- Track assigned permissions per player (for cleanup)
local PlayerPermissions = {} -- [source] = { permissions = {}, groups = {} }

-- Resolved role configs (with inheritance flattened)
local ResolvedRoles = nil

---Resolve inheritance for a single role config
local function ResolveRoleInheritance(roleName, visited)
    visited = visited or {}
    
    if visited[roleName] then
        return { permissions = {}, groups = {} }
    end
    visited[roleName] = true
    
    local roleConfig = Config.Permissions and Config.Permissions.Roles and Config.Permissions.Roles[roleName]
    if not roleConfig then
        return { permissions = {}, groups = {} }
    end
    
    local resolved = {
        permissions = {},
        groups = {},
        priority = roleConfig.priority or 0
    }
    
    if roleConfig.inherits then
        for _, inheritedRole in ipairs(roleConfig.inherits) do
            local inherited = ResolveRoleInheritance(inheritedRole, visited)
            for _, perm in ipairs(inherited.permissions) do
                resolved.permissions[perm] = true
            end
            for _, group in ipairs(inherited.groups) do
                resolved.groups[group] = true
            end
        end
    end
    
    if roleConfig.permissions then
        for _, perm in ipairs(roleConfig.permissions) do
            resolved.permissions[perm] = true
        end
    end
    
    if roleConfig.groups then
        for _, group in ipairs(roleConfig.groups) do
            resolved.groups[group] = true
        end
    end
    
    local permArray = {}
    for perm in pairs(resolved.permissions) do
        table.insert(permArray, perm)
    end
    resolved.permissions = permArray
    
    local groupArray = {}
    for group in pairs(resolved.groups) do
        table.insert(groupArray, group)
    end
    resolved.groups = groupArray
    
    return resolved
end

function PermissionsModule.ResolveAllRoles()
    ResolvedRoles = {}
    
    if not Config.Permissions then
        return
    end
    
    if not Config.Permissions.Roles then
        return
    end
    
    for roleName, roleConfig in pairs(Config.Permissions.Roles) do
        ResolvedRoles[roleName] = ResolveRoleInheritance(roleName)
        ResolvedRoles[roleName].priority = roleConfig.priority or 0
    end
end

function PermissionsModule.BuildPermissionsForRoleIds(roleIds)
    if not ResolvedRoles then
        PermissionsModule.ResolveAllRoles()
    end
    
    roleIds = roleIds or {}
    
    local allPermissions = {}
    local allGroups = {}
    local matchedRoles = {}
    
    if Config.Permissions and Config.Permissions.DefaultPermissions then
        for _, perm in ipairs(Config.Permissions.DefaultPermissions) do
            allPermissions[perm] = true
        end
    end
    
    if Config.Permissions and Config.Permissions.DefaultGroups then
        for _, group in ipairs(Config.Permissions.DefaultGroups) do
            allGroups[group] = true
        end
    end
    
    -- Match role IDs against configured roles
    for _, roleId in ipairs(roleIds) do
        local resolved = ResolvedRoles and ResolvedRoles[roleId]
        if resolved then
            table.insert(matchedRoles, {
                id = roleId,
                config = resolved
            })
        end
    end
    
    table.sort(matchedRoles, function(a, b)
        return a.config.priority < b.config.priority
    end)
    
    for _, role in ipairs(matchedRoles) do
        for _, perm in ipairs(role.config.permissions) do
            allPermissions[perm] = true
        end
        for _, group in ipairs(role.config.groups) do
            allGroups[group] = true
        end
    end
    
    local permArray = {}
    for perm in pairs(allPermissions) do
        table.insert(permArray, perm)
    end
    
    local groupArray = {}
    for group in pairs(allGroups) do
        table.insert(groupArray, group)
    end
    
    return permArray, groupArray
end

local function SanitizeAceString(str)
    if type(str) ~= 'string' then return nil end
    return str:gsub('[^%w%.%_%-%*]', '')
end

function PermissionsModule.AssignToPlayer(source, permissions, groups)
    local identifier = 'player.' .. source
    
    PlayerPermissions[source] = {
        permissions = permissions,
        groups = groups
    }
    
    for _, group in ipairs(groups) do
        local safeGroup = SanitizeAceString(group)
        if safeGroup and safeGroup ~= '' then
            ExecuteCommand(string.format('add_principal identifier.%s group.%s', identifier, safeGroup))
        end
    end
    
    for _, perm in ipairs(permissions) do
        local safePerm = SanitizeAceString(perm)
        if safePerm and safePerm ~= '' then
            ExecuteCommand(string.format('add_ace identifier.%s %s allow', identifier, safePerm))
        end
    end
end

function PermissionsModule.RemoveFromPlayer(source)
    local stored = PlayerPermissions[source]
    if not stored then return end
    
    local identifier = 'player.' .. source
    
    for _, perm in ipairs(stored.permissions) do
        local safePerm = SanitizeAceString(perm)
        if safePerm and safePerm ~= '' then
            ExecuteCommand(string.format('remove_ace identifier.%s %s allow', identifier, safePerm))
        end
    end
    
    for _, group in ipairs(stored.groups) do
        local safeGroup = SanitizeAceString(group)
        if safeGroup and safeGroup ~= '' then
            ExecuteCommand(string.format('remove_principal identifier.%s group.%s', identifier, safeGroup))
        end
    end
    
    PlayerPermissions[source] = nil
end

function PermissionsModule.SyncPlayer(source)
    if not Config.Permissions then
        return false, 'Permission config missing'
    end
    
    if not Config.Permissions.Enabled then
        return false, 'Permission system disabled'
    end
    
    local discordId = LonexDiscord.Utils.GetDiscordIdentifier(source)
    
    if not discordId then
        local perms, groups = PermissionsModule.BuildPermissionsForRoleIds({})
        PermissionsModule.AssignToPlayer(source, perms, groups)
        return true, nil
    end
    
    local roleIds, err = LonexDiscord.API.GetMemberRoleIds(discordId)
    
    if not roleIds then
        local perms, groups = PermissionsModule.BuildPermissionsForRoleIds({})
        PermissionsModule.AssignToPlayer(source, perms, groups)
        return false, err
    end
    
    local perms, groups = PermissionsModule.BuildPermissionsForRoleIds(roleIds)
    
    PermissionsModule.RemoveFromPlayer(source)
    PermissionsModule.AssignToPlayer(source, perms, groups)
    
    if Config.Permissions.LogAssignments then
        LonexDiscord.Utils.Info('Synced permissions for player %d: %d perms, %d groups', 
            source, #perms, #groups)
    end
    
    return true, nil
end

function PermissionsModule.ResyncAllPlayers()
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        PermissionsModule.SyncPlayer(tonumber(playerId))
    end
end

function PermissionsModule.HasPermission(source, permission)
    if IsPlayerAceAllowed(source, permission) then
        return true
    end
    
    local stored = PlayerPermissions[source]
    if not stored then return false end
    
    for _, perm in ipairs(stored.permissions) do
        if perm == permission then
            return true
        end
        
        if perm:sub(-2) == '.*' then
            local prefix = perm:sub(1, -3)
            if permission:sub(1, #prefix) == prefix then
                return true
            end
        end
    end
    
    return false
end

function PermissionsModule.HasAnyPermission(source, permissions)
    for _, perm in ipairs(permissions) do
        if PermissionsModule.HasPermission(source, perm) then
            return true, perm
        end
    end
    return false, nil
end

function PermissionsModule.HasAllPermissions(source, permissions)
    for _, perm in ipairs(permissions) do
        if not PermissionsModule.HasPermission(source, perm) then
            return false, perm
        end
    end
    return true, nil
end

function PermissionsModule.IsInGroup(source, group)
    local stored = PlayerPermissions[source]
    if not stored then return false end
    
    for _, g in ipairs(stored.groups) do
        if g == group then
            return true
        end
    end
    
    return false
end

function PermissionsModule.GetPlayerPermissions(source)
    local stored = PlayerPermissions[source]
    if not stored then return nil end
    return stored.permissions
end

function PermissionsModule.GetPlayerGroups(source)
    local stored = PlayerPermissions[source]
    if not stored then return nil end
    return stored.groups
end

-- Resolve roles on startup
CreateThread(function()
    Wait(100)
    PermissionsModule.ResolveAllRoles()
end)

-- WEBHOOK MODULE (embedded)

LonexDiscord.Webhooks = {}

local WebhooksModule = LonexDiscord.Webhooks

-- Per-webhook state
local WebhookQueues = {}    -- [name] = { queue = {}, processing = false }
local WebhookLastSent = {}  -- [name] = timestamp

---Build an embed object
---@param options table Embed options
---@return table embed
function WebhooksModule.BuildEmbed(options)
    local embed = {}
    
    if options.title then
        embed.title = options.title
    end
    
    if options.description then
        embed.description = options.description
    end
    
    if options.url then
        embed.url = options.url
    end
    
    -- Color (use default if not specified)
    embed.color = options.color or (Config.Webhooks and Config.Webhooks.DefaultColor) or 5793266
    
    -- Timestamp
    if options.timestamp ~= false then
        if Config.Webhooks and Config.Webhooks.IncludeTimestamp then
            embed.timestamp = options.timestamp or os.date('!%Y-%m-%dT%H:%M:%SZ')
        end
    end
    
    -- Author
    if options.author then
        embed.author = {
            name = options.author.name,
            url = options.author.url,
            icon_url = options.author.icon_url,
        }
    end
    
    -- Thumbnail
    if options.thumbnail then
        embed.thumbnail = {
            url = type(options.thumbnail) == 'string' and options.thumbnail or options.thumbnail.url,
        }
    end
    
    -- Image
    if options.image then
        embed.image = {
            url = type(options.image) == 'string' and options.image or options.image.url,
        }
    end
    
    -- Footer
    if options.footer then
        embed.footer = {
            text = type(options.footer) == 'string' and options.footer or options.footer.text,
            icon_url = type(options.footer) == 'table' and options.footer.icon_url or nil,
        }
    elseif Config.Webhooks and Config.Webhooks.DefaultFooter then
        embed.footer = Config.Webhooks.DefaultFooter
    end
    
    -- Fields
    if options.fields and #options.fields > 0 then
        embed.fields = {}
        for _, field in ipairs(options.fields) do
            table.insert(embed.fields, {
                name = field.name or 'Field',
                value = field.value or '',
                inline = field.inline or false,
            })
        end
    end
    
    return embed
end

---Replace placeholders in a string
---@param str string String with {placeholders}
---@param data table Key-value pairs for replacement
---@return string
local function ReplacePlaceholders(str, data)
    if not str then return str end
    
    for key, value in pairs(data) do
        str = str:gsub('{' .. key .. '}', tostring(value or 'N/A'))
    end
    
    return str
end

---Build embed from template
---@param templateName string Template name from Config.Webhooks.Templates
---@param data table Placeholder data
---@return table|nil embed
function WebhooksModule.BuildFromTemplate(templateName, data)
    if not Config.Webhooks or not Config.Webhooks.Templates then
        return nil
    end
    
    local template = Config.Webhooks.Templates[templateName]
    if not template then
        return nil
    end
    
    data = data or {}
    
    local embed = {
        title = ReplacePlaceholders(template.title, data),
        description = ReplacePlaceholders(template.description, data),
        color = template.color or Config.Webhooks.DefaultColor,
        url = ReplacePlaceholders(template.url, data),
    }
    
    -- Timestamp
    if Config.Webhooks.IncludeTimestamp then
        embed.timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    end
    
    -- Footer
    if template.footer then
        embed.footer = {
            text = ReplacePlaceholders(template.footer.text or template.footer, data),
            icon_url = template.footer.icon_url,
        }
    elseif Config.Webhooks.DefaultFooter then
        embed.footer = Config.Webhooks.DefaultFooter
    end
    
    -- Author
    if template.author then
        embed.author = {
            name = ReplacePlaceholders(template.author.name, data),
            url = ReplacePlaceholders(template.author.url, data),
            icon_url = ReplacePlaceholders(template.author.icon_url, data),
        }
    end
    
    -- Thumbnail
    if template.thumbnail then
        embed.thumbnail = {
            url = ReplacePlaceholders(
                type(template.thumbnail) == 'string' and template.thumbnail or template.thumbnail.url, 
                data
            ),
        }
    end
    
    -- Image
    if template.image then
        embed.image = {
            url = ReplacePlaceholders(
                type(template.image) == 'string' and template.image or template.image.url,
                data
            ),
        }
    end
    
    -- Fields
    if template.fields and #template.fields > 0 then
        embed.fields = {}
        for _, field in ipairs(template.fields) do
            table.insert(embed.fields, {
                name = ReplacePlaceholders(field.name, data),
                value = ReplacePlaceholders(field.value, data),
                inline = field.inline or false,
            })
        end
    end
    
    return embed
end

---Validate webhook URL
---@param url string
---@return boolean
local function IsValidWebhookUrl(url)
    return type(url) == 'string' and url:match('^https://discord%.com/api/webhooks/') ~= nil
end

---Get webhook URL by name
---@param name string Webhook name
---@return string|nil url
---@return table|nil options
local function GetWebhookUrl(name)
    if not Config.Webhooks or not Config.Webhooks.Urls then
        return nil, nil
    end
    
    local webhook = Config.Webhooks.Urls[name]
    if not webhook then
        return nil, nil
    end
    
    local url, options
    if type(webhook) == 'string' then
        url, options = webhook, {}
    elseif type(webhook) == 'table' then
        url, options = webhook.url, webhook
    end
    
    if not IsValidWebhookUrl(url) then
        LonexDiscord.Utils.Error('Invalid webhook URL for "%s" - must be a Discord webhook URL', name)
        return nil, nil
    end
    
    return url, options
end

---Send a webhook message (internal)
---@param url string Webhook URL
---@param payload table Webhook payload
---@param options table|nil Webhook options
---@return boolean success
---@return string|nil error
local function SendWebhookInternal(url, payload, options)
    options = options or {}
    
    -- Apply webhook-level overrides
    if options.username then
        payload.username = payload.username or options.username
    end
    if options.avatar_url then
        payload.avatar_url = payload.avatar_url or options.avatar_url
    end
    
    local body = json.encode(payload)
    
    PerformHttpRequest(url, function(statusCode, responseText, headers)
        if statusCode >= 200 and statusCode < 300 then
            -- Success
        elseif statusCode == 429 then
            -- Rate limited
            LonexDiscord.Utils.Warn('Webhook rate limited')
        else
            LonexDiscord.Utils.Error('Webhook failed: %d - %s', statusCode, responseText or 'No response')
        end
    end, 'POST', body, {
        ['Content-Type'] = 'application/json',
    })
    
    return true, nil
end

---Process webhook queue for a named webhook
---@param name string Webhook name
local function ProcessWebhookQueue(name)
    local state = WebhookQueues[name]
    if not state or state.processing or #state.queue == 0 then
        return
    end
    
    state.processing = true
    
    CreateThread(function()
        while #state.queue > 0 do
            local item = table.remove(state.queue, 1)
            
            -- Rate limiting
            local rateLimit = Config.Webhooks and Config.Webhooks.RateLimit or 1000
            local lastSent = WebhookLastSent[name] or 0
            local elapsed = GetGameTimer() - lastSent
            
            if elapsed < rateLimit then
                Wait(rateLimit - elapsed)
            end
            
            -- Send
            SendWebhookInternal(item.url, item.payload, item.options)
            WebhookLastSent[name] = GetGameTimer()
            
            -- Small delay between messages
            Wait(100)
        end
        
        state.processing = false
    end)
end

---Send a webhook message
---@param name string Webhook name from Config.Webhooks.Urls
---@param data table Message data (content, embeds, username, avatar_url)
---@return boolean success
---@return string|nil error
function WebhooksModule.Send(name, data)
    if not Config.Webhooks or not Config.Webhooks.Enabled then
        return false, 'Webhooks disabled'
    end
    
    local url, options = GetWebhookUrl(name)
    if not url then
        return false, 'Webhook not found: ' .. tostring(name)
    end
    
    -- Build payload
    local payload = {
        content = data.content,
        username = data.username,
        avatar_url = data.avatar_url,
        tts = data.tts,
    }
    
    -- Handle embeds
    if data.embeds then
        payload.embeds = data.embeds
    elseif data.embed then
        payload.embeds = { data.embed }
    end
    
    -- Initialize queue if needed
    if not WebhookQueues[name] then
        WebhookQueues[name] = { queue = {}, processing = false }
    end
    
    local state = WebhookQueues[name]
    
    -- Check queue size
    local maxQueue = Config.Webhooks.MaxQueueSize or 50
    if #state.queue >= maxQueue then
        return false, 'Webhook queue full'
    end
    
    -- Add to queue
    table.insert(state.queue, {
        url = url,
        payload = payload,
        options = options,
    })
    
    -- Start processing
    ProcessWebhookQueue(name)
    
    return true, nil
end

---Send a simple text message
---@param name string Webhook name
---@param message string Message content
---@return boolean success
---@return string|nil error
function WebhooksModule.SendMessage(name, message)
    return WebhooksModule.Send(name, {
        content = message,
    })
end

---Send an embed
---@param name string Webhook name
---@param embed table Embed data (or options for BuildEmbed)
---@return boolean success
---@return string|nil error
function WebhooksModule.SendEmbed(name, embed)
    -- If it looks like options, build the embed
    if embed.title or embed.description or embed.fields then
        embed = WebhooksModule.BuildEmbed(embed)
    end
    
    return WebhooksModule.Send(name, {
        embeds = { embed },
    })
end

---Send using a template
---@param name string Webhook name
---@param templateName string Template name
---@param data table Placeholder data
---@return boolean success
---@return string|nil error
function WebhooksModule.SendTemplate(name, templateName, data)
    local embed = WebhooksModule.BuildFromTemplate(templateName, data)
    if not embed then
        return false, 'Template not found: ' .. tostring(templateName)
    end
    
    return WebhooksModule.Send(name, {
        embeds = { embed },
    })
end

---Send directly to a URL (bypasses named webhooks)
---@param url string Full webhook URL
---@param data table Message data
---@return boolean success
---@return string|nil error
function WebhooksModule.SendDirect(url, data)
    if not Config.Webhooks or not Config.Webhooks.Enabled then
        return false, 'Webhooks disabled'
    end
    
    if type(url) ~= 'string' or not url:match('^https://discord%.com/api/webhooks/') then
        return false, 'Invalid webhook URL - must be a Discord webhook'
    end
    
    local payload = {
        content = data.content,
        username = data.username,
        avatar_url = data.avatar_url,
        tts = data.tts,
    }
    
    if data.embeds then
        payload.embeds = data.embeds
    elseif data.embed then
        payload.embeds = { data.embed }
    end
    
    return SendWebhookInternal(url, payload, {})
end


local Utils = LonexDiscord.Utils
local Http = LonexDiscord.Http
local Cache = LonexDiscord.Cache

-- STATE

local Initialized = false
local InitializationError = nil

-- DISCORD API METHODS

---Validate the bot token by fetching current user
---@return boolean success
---@return table|nil userData
local function ValidateToken()
    Utils.Info('Validating bot token...')
    
    local response = Http.Get('/users/@me')
    
    if response.success and response.data then
        Utils.Info('Bot authenticated as: %s#%s (%s)', 
            response.data.username, 
            response.data.discriminator or '0',
            response.data.id
        )
        return true, response.data
    else
        Utils.Error('Token validation failed: %s', response.error or 'Unknown error')
        return false, nil
    end
end

---Fetch guild information
---@param isInitial? boolean If true, always log (for startup)
---@return boolean success
---@return table|nil guildData
local function FetchGuildInfo(isInitial)
    if isInitial or Config.LogCacheRefresh then
        Utils.Info('Fetching guild information...')
    end
    
    local response = Http.Get(string.format('/guilds/%s?with_counts=true', Config.GuildId))
    
    if response.success and response.data then
        local guild = response.data
        
        if isInitial or Config.LogCacheRefresh then
            Utils.Info('Connected to guild: %s (%d members)', 
                guild.name, 
                guild.approximate_member_count or 0
            )
        end
        
        -- Cache guild info
        Cache.SetGuild({
            id = guild.id,
            name = guild.name,
            icon = guild.icon,
            splash = guild.splash,
            description = guild.description,
            memberCount = guild.approximate_member_count,
            onlineCount = guild.approximate_presence_count,
            features = guild.features
        })
        
        return true, guild
    else
        Utils.Error('Failed to fetch guild: %s', response.error or 'Unknown error')
        return false, nil
    end
end

---Fetch all guild roles
---@param isInitial? boolean If true, always log (for startup)
---@return boolean success
---@return table|nil roles
local function FetchGuildRoles(isInitial)
    if isInitial or Config.LogCacheRefresh then
        Utils.Info('Fetching guild roles...')
    end
    
    local response = Http.Get(string.format('/guilds/%s/roles', Config.GuildId))
    
    if response.success and response.data then
        local roles = response.data
        
        -- Sort by position (highest first)
        table.sort(roles, function(a, b)
            return a.position > b.position
        end)
        
        if isInitial or Config.LogCacheRefresh then
            Utils.Info('Loaded %d roles', #roles)
        end
        
        -- Cache roles
        Cache.SetRoles(roles)
        
        return true, roles
    else
        Utils.Error('Failed to fetch roles: %s', response.error or 'Unknown error')
        return false, nil
    end
end

-- INITIALIZATION

local function Initialize()
    Utils.Info('Initializing LonexDiscordAPI v1.1.0...')
    
    -- Check configuration
    if Config.BotToken == '' then
        InitializationError = 'Bot token not configured'
        Utils.Error(InitializationError)
        return false
    end
    
    if Config.GuildId == '' then
        InitializationError = 'Guild ID not configured'
        Utils.Error(InitializationError)
        return false
    end
    
    -- Validate token
    if Config.Startup.ValidateToken then
        local success = ValidateToken()
        if not success then
            InitializationError = 'Invalid bot token'
            return false
        end
    end
    
    -- Fetch guild info
    if Config.Startup.FetchGuildInfo then
        local success = FetchGuildInfo(true)
        if not success then
            InitializationError = 'Failed to fetch guild info'
            return false
        end
    end
    
    -- Fetch roles
    if Config.Startup.FetchRoles then
        local success = FetchGuildRoles(true)
        if not success then
            InitializationError = 'Failed to fetch roles'
            return false
        end
    end
    
    Initialized = true
    Utils.Info('Initialization complete!')
    
    -- Trigger event for other resources
    TriggerEvent('lonex_discord:ready')
    
    return true
end

-- Delayed initialization
CreateThread(function()
    Wait(Config.Startup.InitDelay)
    Initialize()
end)

-- EXPORTS - CORE

---Check if the API is ready
---@return boolean
---@return string|nil error
exports('IsReady', function()
    return Initialized, InitializationError
end)

---Get the initialization error if any
---@return string|nil
exports('GetError', function()
    return InitializationError
end)

-- EXPORTS - GUILD

---Get cached guild information
---@return table|nil
exports('GetGuildInfo', function()
    return Cache.GetGuild()
end)

---Get guild name
---@return string|nil
exports('GetGuildName', function()
    local guild = Cache.GetGuild()
    return guild and guild.name or nil
end)

---Get guild icon URL
---@param size? number
---@return string|nil
exports('GetGuildIcon', function(size)
    local guild = Cache.GetGuild()
    if not guild or not guild.icon then return nil end
    return Utils.GetGuildIconUrl(guild.id, guild.icon, size)
end)

---Get guild splash URL
---@param size? number
---@return string|nil
exports('GetGuildSplash', function(size)
    local guild = Cache.GetGuild()
    if not guild or not guild.splash then return nil end
    size = size or 480
    return string.format('https://cdn.discordapp.com/splashes/%s/%s.png?size=%d',
        guild.id, guild.splash, size)
end)

---Get guild description
---@return string|nil
exports('GetGuildDescription', function()
    local guild = Cache.GetGuild()
    return guild and guild.description or nil
end)

---Get guild member count
---@return number|nil
exports('GetGuildMemberCount', function()
    local guild = Cache.GetGuild()
    return guild and guild.memberCount or nil
end)

---Get guild online member count
---@return number|nil
exports('GetGuildOnlineCount', function()
    local guild = Cache.GetGuild()
    return guild and guild.onlineCount or nil
end)

---Get guild features (e.g., COMMUNITY, VERIFIED, etc.)
---@return table|nil
exports('GetGuildFeatures', function()
    local guild = Cache.GetGuild()
    return guild and guild.features or nil
end)

---Check if guild has a specific feature
---@param feature string Feature name (e.g., "COMMUNITY")
---@return boolean
exports('HasGuildFeature', function(feature)
    local guild = Cache.GetGuild()
    if not guild or not guild.features then return false end
    
    for _, f in ipairs(guild.features) do
        if f == feature then
            return true
        end
    end
    return false
end)

---Refresh guild info from Discord
---@return boolean success
exports('RefreshGuildInfo', function()
    return FetchGuildInfo()
end)

-- EXPORTS - ROLES

---Get all cached roles
---@return table|nil
exports('GetGuildRoles', function()
    return Cache.GetRoles()
end)

---Get role by name (utility to find Role ID - use ID for all operations)
---@param name string
---@return table|nil
exports('GetRoleByName', function(name)
    return Cache.GetRoleByName(name)
end)

---Get role by ID
---@param id string|number
---@return table|nil
exports('GetRoleById', function(id)
    return Cache.GetRoleById(id)
end)

---Get role ID from name (utility to convert name to ID)
---@param name string
---@return string|nil
exports('GetRoleIdFromName', function(name)
    local role = Cache.GetRoleByName(name)
    return role and role.id or nil
end)

---Get role name from ID (for display purposes)
---@param id string|number
---@return string|nil
exports('GetRoleNameFromId', function(id)
    local role = Cache.GetRoleById(id)
    return role and role.name or nil
end)

---Refresh roles from Discord
---@return boolean success
exports('RefreshRoles', function()
    return FetchGuildRoles()
end)

---Get total number of roles
---@return number
exports('GetRoleCount', function()
    local roles = Cache.GetRoles()
    return roles and #roles or 0
end)

---Get roles above a certain position
---@param position number Role position threshold
---@return table|nil roles
exports('GetRolesAbovePosition', function(position)
    local roles = Cache.GetRoles()
    if not roles then return nil end
    
    local result = {}
    for _, role in ipairs(roles) do
        if role.position > position then
            table.insert(result, role)
        end
    end
    return result
end)

---Get roles with a specific permission
---@param permission string Permission name (e.g., "administrator", "manage_roles")
---@return table|nil roles
exports('GetRolesWithPermission', function(permission)
    local roles = Cache.GetRoles()
    if not roles then return nil end
    
    -- Discord permission bit flags
    local permissionBits = {
        administrator = 0x8,
        manage_roles = 0x10000000,
        manage_channels = 0x10,
        manage_guild = 0x20,
        kick_members = 0x2,
        ban_members = 0x4,
        manage_nicknames = 0x8000000,
        manage_messages = 0x2000,
        moderate_members = 0x10000000000
    }
    
    local bit = permissionBits[permission:lower()]
    if not bit then return nil end
    
    local result = {}
    for _, role in ipairs(roles) do
        local perms = tonumber(role.permissions) or 0
        -- Check if permission bit is set or if administrator
        if (perms & bit) ~= 0 or (perms & 0x8) ~= 0 then
            table.insert(result, role)
        end
    end
    return result
end)

-- PERIODIC REFRESH

-- Refresh guild data periodically
CreateThread(function()
    while true do
        -- Wait for configured interval (default: role TTL)
        Wait(Config.Cache.RolesTTL * 1000)
        
        if Initialized then
            Utils.Debug('Periodic refresh: updating guild data...')
            FetchGuildInfo()
            FetchGuildRoles()
        end
    end
end)

-- EXPORTS - PLAYER DATA

local API = LonexDiscord.API

---Get Discord ID from player source
---@param source number
---@return string|nil
exports('GetDiscordId', function(source)
    return Utils.GetDiscordIdentifier(source)
end)

---Get Discord user data by player source
---@param source number Player source
---@return table|nil userData
exports('GetDiscordUser', function(source)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then return nil end
    
    local user, err = API.GetUser(discordId, true)
    return user
end)

---Get Discord user data by Discord ID
---@param discordId string
---@return table|nil userData
exports('GetDiscordUserById', function(discordId)
    local user, err = API.GetUser(discordId, true)
    return user
end)

---Get Discord guild member data by player source
---@param source number Player source
---@return table|nil memberData
exports('GetDiscordMember', function(source)
    local member, err = API.GetMemberBySource(source, true)
    return member
end)

---Get Discord guild member data by Discord ID
---@param discordId string
---@return table|nil memberData
exports('GetDiscordMemberById', function(discordId)
    local member, err = API.GetMember(discordId, true)
    return member
end)

---Get player's Discord avatar URL
---@param source number Player source
---@param size? number Image size (default 128)
---@return string|nil avatarUrl
exports('GetDiscordAvatar', function(source, size)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then return nil end
    
    local avatar, err = API.GetMemberAvatar(discordId, size)
    return avatar
end)

---Get Discord avatar URL by Discord ID
---@param discordId string
---@param size? number Image size (default 128)
---@return string|nil avatarUrl
exports('GetDiscordAvatarById', function(discordId, size)
    local avatar, err = API.GetMemberAvatar(discordId, size)
    return avatar
end)

---Get player's Discord roles (as role objects)
---@param source number Player source
---@return table|nil roles Array of role objects
exports('GetDiscordRoles', function(source)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then return nil end
    
    local roles, err = API.GetMemberRoles(discordId)
    return roles
end)

---Get player's Discord role IDs
---@param source number Player source
---@return table|nil roleIds Array of role ID strings
exports('GetDiscordRoleIds', function(source)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then return nil end
    
    local roleIds, err = API.GetMemberRoleIds(discordId)
    return roleIds
end)

---Get player's Discord role names (for display purposes only - use Role IDs for all other operations)
---@param source number Player source
---@return table|nil roleNames Array of role name strings
exports('GetDiscordRoleNames', function(source)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then return nil end
    
    local roleNames, err = API.GetMemberRoleNames(discordId)
    return roleNames
end)

---Check if player has a specific Discord role
---@param source number Player source
---@param roleId string Role ID
---@return boolean
exports('HasDiscordRole', function(source, roleId)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then return false end
    
    local hasRole, err = API.MemberHasRole(discordId, roleId)
    return hasRole
end)

---Check if player has any of the specified Discord roles
---@param source number Player source
---@param roleIds table Array of role IDs
---@return boolean
exports('HasAnyDiscordRole', function(source, roleIds)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then return false end
    
    local hasAny, matched = API.MemberHasAnyRole(discordId, roleIds)
    return hasAny
end)

---Check if player has all of the specified Discord roles
---@param source number Player source
---@param roleIds table Array of role IDs
---@return boolean
exports('HasAllDiscordRoles', function(source, roleIds)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then return false end
    
    local hasAll, missing = API.MemberHasAllRoles(discordId, roleIds)
    return hasAll
end)

---Get player's Discord display name (nickname > global name > username)
---@param source number Player source
---@return string|nil displayName
exports('GetDiscordName', function(source)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then return nil end
    
    local name, err = API.GetMemberDisplayName(discordId)
    return name
end)

---Get player's Discord nickname (server-specific)
---@param source number Player source
---@return string|nil nickname
exports('GetDiscordNickname', function(source)
    local member, err = API.GetMemberBySource(source, true)
    if not member then return nil end
    
    return member.nickname
end)

---Get player's Discord username (not nickname)
---@param source number Player source
---@return string|nil username
exports('GetDiscordUsername', function(source)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then return nil end
    
    local username, err = API.GetUsername(discordId)
    return username
end)

---Check if player is a member of the Discord guild
---@param source number Player source
---@return boolean
exports('IsInDiscordGuild', function(source)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then return false end
    
    return API.IsMemberOfGuild(discordId)
end)

---Invalidate cached data for a player
---@param source number Player source
exports('InvalidatePlayer', function(source)
    local discordId = Utils.GetDiscordIdentifier(source)
    if discordId then
        API.InvalidateMember(discordId)
    end
end)

---Prefetch member data for all connected players
exports('PrefetchAllPlayers', function()
    local players = GetPlayers()
    local sources = {}
    for _, playerId in ipairs(players) do
        table.insert(sources, tonumber(playerId))
    end
    API.PrefetchMembers(sources)
end)

-- EXPORTS - ROLE MANAGEMENT

---Add a Discord role to a player
---@param source number Player source
---@param roleId string Role ID
---@param reason? string Audit log reason
---@return boolean success
---@return string|nil error
exports('AddRole', function(source, roleId, reason)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then
        return false, 'Player has no Discord identifier'
    end
    
    return API.AddRole(discordId, roleId, reason)
end)

---Add a Discord role by Discord ID
---@param discordId string Discord user ID
---@param roleId string Role ID
---@param reason? string Audit log reason
---@return boolean success
---@return string|nil error
exports('AddRoleById', function(discordId, roleId, reason)
    return API.AddRole(discordId, roleId, reason)
end)

---Remove a Discord role from a player
---@param source number Player source
---@param roleId string Role ID
---@param reason? string Audit log reason
---@return boolean success
---@return string|nil error
exports('RemoveRole', function(source, roleId, reason)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then
        return false, 'Player has no Discord identifier'
    end
    
    return API.RemoveRole(discordId, roleId, reason)
end)

---Remove a Discord role by Discord ID
---@param discordId string Discord user ID
---@param roleId string Role ID
---@param reason? string Audit log reason
---@return boolean success
---@return string|nil error
exports('RemoveRoleById', function(discordId, roleId, reason)
    return API.RemoveRole(discordId, roleId, reason)
end)

---Set all Discord roles for a player (replaces existing)
---@param source number Player source
---@param roleIds table Array of role IDs
---@param reason? string Audit log reason
---@return boolean success
---@return string|nil error
exports('SetRoles', function(source, roleIds, reason)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then
        return false, 'Player has no Discord identifier'
    end
    
    return API.SetRoles(discordId, roleIds, reason)
end)

---Set all Discord roles by Discord ID (replaces existing)
---@param discordId string Discord user ID
---@param roleIds table Array of role IDs
---@param reason? string Audit log reason
---@return boolean success
---@return string|nil error
exports('SetRolesById', function(discordId, roleIds, reason)
    return API.SetRoles(discordId, roleIds, reason)
end)

---Set a player's Discord nickname
---@param source number Player source
---@param nickname string|nil New nickname (nil or "" to reset)
---@param reason? string Audit log reason
---@return boolean success
---@return string|nil error
exports('SetNickname', function(source, nickname, reason)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then
        return false, 'Player has no Discord identifier'
    end
    
    return API.SetNickname(discordId, nickname, reason)
end)

---Set Discord nickname by Discord ID
---@param discordId string Discord user ID
---@param nickname string|nil New nickname (nil or "" to reset)
---@param reason? string Audit log reason
---@return boolean success
---@return string|nil error
exports('SetNicknameById', function(discordId, nickname, reason)
    return API.SetNickname(discordId, nickname, reason)
end)

---Move a player to a Discord voice channel
---@param source number Player source
---@param channelId string|nil Voice channel ID (nil to disconnect)
---@param reason? string Audit log reason
---@return boolean success
---@return string|nil error
exports('MoveToVoiceChannel', function(source, channelId, reason)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then
        return false, 'Player has no Discord identifier'
    end
    
    return API.MoveToVoiceChannel(discordId, channelId, reason)
end)

---Move to voice channel by Discord ID
---@param discordId string Discord user ID
---@param channelId string|nil Voice channel ID (nil to disconnect)
---@param reason? string Audit log reason
---@return boolean success
---@return string|nil error
exports('MoveToVoiceChannelById', function(discordId, channelId, reason)
    return API.MoveToVoiceChannel(discordId, channelId, reason)
end)

-- EXPORTS - PERMISSIONS

local Perms = LonexDiscord.Permissions

---Check if a player has a specific permission
---@param source number Player source
---@param permission string Permission node
---@return boolean
exports('HasPermission', function(source, permission)
    return Perms.HasPermission(source, permission)
end)

---Check if a player has any of the specified permissions
---@param source number Player source
---@param permissions table Array of permission nodes
---@return boolean
exports('HasAnyPermission', function(source, permissions)
    local hasAny, _ = Perms.HasAnyPermission(source, permissions)
    return hasAny
end)

---Check if a player has all of the specified permissions
---@param source number Player source
---@param permissions table Array of permission nodes
---@return boolean
exports('HasAllPermissions', function(source, permissions)
    local hasAll, _ = Perms.HasAllPermissions(source, permissions)
    return hasAll
end)

---Check if a player is in a specific ACE group
---@param source number Player source
---@param group string Group name
---@return boolean
exports('IsInGroup', function(source, group)
    return Perms.IsInGroup(source, group)
end)

---Get all permissions assigned to a player
---@param source number Player source
---@return table|nil permissions
exports('GetPermissions', function(source)
    return Perms.GetPlayerPermissions(source)
end)

---Get all groups assigned to a player
---@param source number Player source
---@return table|nil groups
exports('GetGroups', function(source)
    return Perms.GetPlayerGroups(source)
end)

---Sync permissions for a player (re-fetch Discord roles and reassign)
---@param source number Player source
---@return boolean success
---@return string|nil error
exports('SyncPermissions', function(source)
    return Perms.SyncPlayer(source)
end)

---Resync permissions for all connected players
exports('ResyncAllPermissions', function()
    Perms.ResyncAllPlayers()
end)

-- EXPORTS - WEBHOOKS

local Webhooks = LonexDiscord.Webhooks

---Send a webhook message
---@param name string Webhook name from Config.Webhooks.Urls
---@param data table Message data (content, embeds, username, avatar_url)
---@return boolean success
---@return string|nil error
exports('SendWebhook', function(name, data)
    return Webhooks.Send(name, data)
end)

---Send a simple text message to a webhook
---@param name string Webhook name
---@param message string Message content
---@return boolean success
---@return string|nil error
exports('SendWebhookMessage', function(name, message)
    return Webhooks.SendMessage(name, message)
end)

---Send an embed to a webhook
---@param name string Webhook name
---@param embed table Embed data
---@return boolean success
---@return string|nil error
exports('SendWebhookEmbed', function(name, embed)
    return Webhooks.SendEmbed(name, embed)
end)

---Send a template-based message to a webhook
---@param name string Webhook name
---@param templateName string Template name from Config.Webhooks.Templates
---@param data table Placeholder data
---@return boolean success
---@return string|nil error
exports('SendWebhookTemplate', function(name, templateName, data)
    return Webhooks.SendTemplate(name, templateName, data)
end)

---Send directly to a webhook URL (bypasses named webhooks)
---@param url string Full webhook URL
---@param data table Message data
---@return boolean success
---@return string|nil error
exports('SendWebhookDirect', function(url, data)
    return Webhooks.SendDirect(url, data)
end)

---Build an embed object
---@param options table Embed options (title, description, color, fields, etc.)
---@return table embed
exports('BuildEmbed', function(options)
    return Webhooks.BuildEmbed(options)
end)

---Build an embed from a template
---@param templateName string Template name
---@param data table Placeholder data
---@return table|nil embed
exports('BuildEmbedFromTemplate', function(templateName, data)
    return Webhooks.BuildFromTemplate(templateName, data)
end)

-- EXPORTS - UTILITIES

---Get HTTP statistics
---@return table
exports('GetHttpStats', function()
    return Http.GetStats()
end)

---Get cache statistics
---@return table
exports('GetCacheStats', function()
    return Cache.GetStats()
end)

---Clear all caches
exports('ClearCache', function()
    Cache.ClearAll()
end)

-- COMMANDS (Debug/Admin)

if Config.Debug then
    RegisterCommand('lonex_discord_status', function(source)
        if source ~= 0 then return end -- Console only
        
        print('--- LonexDiscordAPI Status ---')
        print(string.format('Initialized: %s', Initialized and 'Yes' or 'No'))
        if InitializationError then
            print(string.format('Error: %s', InitializationError))
        end
        
        local guild = Cache.GetGuild()
        if guild then
            print(string.format('Guild: %s (%s)', guild.name, guild.id))
            print(string.format('Members: %d', guild.memberCount or 0))
        end
        
        local roles = Cache.GetRoles()
        if roles then
            print(string.format('Roles cached: %d', #roles))
        end
        
        local httpStats = Http.GetStats()
        print(string.format('HTTP Requests: %d total, %d success, %d failed', 
            httpStats.totalRequests, 
            httpStats.successfulRequests, 
            httpStats.failedRequests
        ))
        print(string.format('Rate limits: %d hits, %d retries', 
            httpStats.rateLimitHits, 
            httpStats.retries
        ))
        
        print('------------------------------')
    end, true)
    
    RegisterCommand('lonex_discord_roles', function(source)
        if source ~= 0 then return end -- Console only
        
        local roles = Cache.GetRoles()
        if not roles then
            print('No roles cached')
            return
        end
        
        print('--- Guild Roles ---')
        for _, role in ipairs(roles) do
            print(string.format('  [%d] %s (%s)', role.position, role.name, role.id))
        end
        print('-------------------')
    end, true)
    
    RegisterCommand('lonex_discord_guild', function(source)
        if source ~= 0 then return end -- Console only
        
        local guild = Cache.GetGuild()
        if not guild then
            print('No guild data cached')
            return
        end
        
        print('--- Guild Information ---')
        print('Name: ' .. tostring(guild.name))
        print('ID: ' .. tostring(guild.id))
        print('Description: ' .. tostring(guild.description or 'None'))
        print('Member Count: ' .. tostring(guild.memberCount or 'Unknown'))
        print('Online Count: ' .. tostring(guild.onlineCount or 'Unknown'))
        
        if guild.icon then
            print('Icon: ' .. Utils.GetGuildIconUrl(guild.id, guild.icon, 128))
        else
            print('Icon: None')
        end
        
        if guild.features and #guild.features > 0 then
            print('Features: ' .. table.concat(guild.features, ', '))
        else
            print('Features: None')
        end
        
        local roles = Cache.GetRoles()
        print('Roles Cached: ' .. (roles and #roles or 0))
        
        print('-------------------------')
    end, true)
    
    RegisterCommand('lonex_discord_test', function(source)
        if source == 0 then
            print('Run this command in-game, not from console')
            return
        end
        
        local src = source
        
        print('--- Testing LonexDiscordAPI for player ' .. src .. ' ---')
        
        -- Discord ID
        local discordId = Utils.GetDiscordIdentifier(src)
        print('Discord ID: ' .. tostring(discordId))
        
        if not discordId then
            print('No Discord linked - cannot test further')
            return
        end
        
        -- In guild?
        local inGuild = API.IsMemberOfGuild(discordId)
        print('In Guild: ' .. tostring(inGuild))
        
        -- Display name
        local name, err = API.GetMemberDisplayName(discordId)
        print('Display Name: ' .. tostring(name))
        
        -- Member data
        local member, err = API.GetMember(discordId)
        if member then
            print('Nickname: ' .. tostring(member.nickname))
            print('Username: ' .. tostring(member.user.username))
            
            -- Avatar
            local avatar = API.GetMemberAvatar(discordId, 128)
            print('Avatar URL: ' .. tostring(avatar))
            
            -- Roles
            local roleNames, err = API.GetMemberRoleNames(discordId)
            if roleNames and #roleNames > 0 then
                print('Roles: ' .. table.concat(roleNames, ', '))
            else
                print('Roles: none')
            end
        else
            print('Could not fetch member data: ' .. tostring(err))
        end
        
        print('--- Test Complete ---')
    end, false)
    
    RegisterCommand('lonex_discord_testid', function(source, args)
        if source ~= 0 then return end -- Console only
        
        local discordId = args[1]
        if not discordId then
            print('Usage: lonex_discord_testid <discord_id>')
            return
        end
        
        print('--- Testing Discord ID: ' .. discordId .. ' ---')
        
        local member, err = API.GetMember(discordId)
        if member then
            print('Username: ' .. member.user.username)
            print('Global Name: ' .. tostring(member.user.globalName))
            print('Nickname: ' .. tostring(member.nickname))
            print('Roles: ' .. #member.roles .. ' roles')
            for _, roleId in ipairs(member.roles) do
                local role = Cache.GetRoleById(roleId)
                if role then
                    print('  - ' .. role.name)
                end
            end
            print('Joined: ' .. tostring(member.joinedAt))
            
            local avatar = API.GetMemberAvatar(discordId, 128)
            print('Avatar: ' .. tostring(avatar))
        else
            print('Member not found in guild: ' .. tostring(err))
        end
        
        print('--- Test Complete ---')
    end, true)
    
    RegisterCommand('lonex_discord_addrole', function(source, args)
        print('lonex_discord_addrole called, source: ' .. tostring(source))
        
        if source ~= 0 then 
            print('Command must be run from server console')
            return 
        end
        
        local discordId = args[1]
        local roleId = args[2]
        
        if not discordId or not roleId then
            print('Usage: lonex_discord_addrole <discord_id> <role_id>')
            return
        end
        
        print('Adding role "' .. roleId .. '" to user ' .. discordId .. '...')
        
        local success, err = API.AddRole(discordId, roleId, 'Added via console command')
        if success then
            print('SUCCESS: Role added!')
        else
            print('FAILED: ' .. tostring(err))
        end
    end, false)
    
    RegisterCommand('lonex_discord_removerole', function(source, args)
        print('lonex_discord_removerole called, source: ' .. tostring(source))
        
        if source ~= 0 then 
            print('Command must be run from server console')
            return 
        end
        
        local discordId = args[1]
        local roleId = args[2]
        
        if not discordId or not roleId then
            print('Usage: lonex_discord_removerole <discord_id> <role_id>')
            return
        end
        
        print('Removing role "' .. roleId .. '" from user ' .. discordId .. '...')
        
        local success, err = API.RemoveRole(discordId, roleId, 'Removed via console command')
        if success then
            print('SUCCESS: Role removed!')
        else
            print('FAILED: ' .. tostring(err))
        end
    end, false)
    
    RegisterCommand('lonex_discord_setnick', function(source, args)
        if source ~= 0 then return end -- Console only
        
        local discordId = args[1]
        if not discordId then
            print('Usage: lonex_discord_setnick <discord_id> [nickname]')
            print('Leave nickname empty to reset')
            return
        end
        
        -- Join remaining args as nickname (allows spaces)
        local nickname = nil
        if args[2] then
            local nickParts = {}
            for i = 2, #args do
                table.insert(nickParts, args[i])
            end
            nickname = table.concat(nickParts, ' ')
        end
        
        if nickname then
            print('Setting nickname for ' .. discordId .. ' to: ' .. nickname)
        else
            print('Resetting nickname for ' .. discordId)
        end
        
        local success, err = API.SetNickname(discordId, nickname, 'Set via console command')
        if success then
            print('SUCCESS: Nickname updated!')
        else
            print('FAILED: ' .. tostring(err))
        end
    end, true)
    
    RegisterCommand('lonex_discord_perms', function(source, args)
        local targetSource = tonumber(args[1])
        
        if source ~= 0 and not targetSource then
            -- In-game, no target specified - check self
            targetSource = source
        elseif not targetSource then
            print('Usage: lonex_discord_perms <player_id>')
            return
        end
        
        local PermsModule = LonexDiscord.Permissions
        
        print('--- Permissions for player ' .. targetSource .. ' ---')
        
        local permissions = PermsModule.GetPlayerPermissions(targetSource)
        local groups = PermsModule.GetPlayerGroups(targetSource)
        
        if groups and #groups > 0 then
            print('Groups: ' .. table.concat(groups, ', '))
        else
            print('Groups: none')
        end
        
        if permissions and #permissions > 0 then
            print('Permissions (' .. #permissions .. '):')
            for _, perm in ipairs(permissions) do
                print('  - ' .. perm)
            end
        else
            print('Permissions: none')
        end
        
        print('-------------------------------')
    end, false)
    
    RegisterCommand('lonex_discord_hasperm', function(source, args)
        local targetSource = tonumber(args[1])
        local permission = args[2]
        
        if source ~= 0 and not permission then
            -- In-game: first arg is permission, check self
            permission = args[1]
            targetSource = source
        end
        
        if not targetSource or not permission then
            print('Usage: lonex_discord_hasperm <player_id> <permission>')
            return
        end
        
        local PermsModule = LonexDiscord.Permissions
        local hasPerm = PermsModule.HasPermission(targetSource, permission)
        
        print(string.format('Player %d has "%s": %s', targetSource, permission, hasPerm and 'YES' or 'NO'))
    end, false)
    
    RegisterCommand('lonex_discord_syncperms', function(source, args)
        local targetSource = tonumber(args[1])
        
        if source ~= 0 and not targetSource then
            -- In-game, no target - sync self
            targetSource = source
        end
        
        local PermsModule = LonexDiscord.Permissions
        
        if not PermsModule then
            print('ERROR: Permissions module not loaded!')
            print('LonexDiscord table keys:')
            for k, v in pairs(LonexDiscord or {}) do
                print('  - ' .. tostring(k) .. ' = ' .. type(v))
            end
            return
        end
        
        if targetSource then
            print('Syncing permissions for player ' .. targetSource .. '...')
            local success, err = PermsModule.SyncPlayer(targetSource)
            if success then
                print('SUCCESS: Permissions synced!')
            else
                print('FAILED: ' .. tostring(err))
            end
        elseif args[1] == 'all' then
            print('Resyncing permissions for all players...')
            PermsModule.ResyncAllPlayers()
        else
            print('Usage: lonex_discord_syncperms <player_id>')
            print('Or: lonex_discord_syncperms all')
        end
    end, false)
    
    -- Sync by Discord ID (for testing from console)
    RegisterCommand('lonex_discord_syncid', function(source, args)
        if source ~= 0 then return end -- Console only
        
        local discordId = args[1]
        local targetSource = tonumber(args[2])
        
        if not discordId or not targetSource then
            print('Usage: lonex_discord_syncid <discord_id> <player_id>')
            return
        end
        
        print('Syncing permissions for player ' .. targetSource .. ' using Discord ID ' .. discordId .. '...')
        
        local PermsModule = LonexDiscord.Permissions
        
        -- Get role IDs directly using Discord ID
        local roleIds, err = LonexDiscord.API.GetMemberRoleIds(discordId)
        print('[DEBUG] Role IDs: ' .. (roleIds and table.concat(roleIds, ', ') or 'nil'))
        
        if not roleIds then
            print('FAILED to get roles: ' .. tostring(err))
            return
        end
        
        local perms, groups = PermsModule.BuildPermissionsForRoleIds(roleIds)
        print('[DEBUG] Built perms: ' .. #perms .. ', groups: ' .. #groups)
        
        PermsModule.RemoveFromPlayer(targetSource)
        PermsModule.AssignToPlayer(targetSource, perms, groups)
        
        print('SUCCESS: Assigned ' .. #perms .. ' permissions and ' .. #groups .. ' groups')
    end, false)
    
    -- Test webhook (send test message)
    RegisterCommand('lonex_discord_testwebhook', function(source, args)
        if source ~= 0 then return end -- Console only
        
        local webhookName = args[1]
        
        if not webhookName then
            print('Usage: lonex_discord_testwebhook <webhook_name>')
            print('Configured webhooks:')
            if Config.Webhooks and Config.Webhooks.Urls then
                for name, _ in pairs(Config.Webhooks.Urls) do
                    print('  - ' .. name)
                end
            else
                print('  (none configured)')
            end
            return
        end
        
        print('Sending test message to webhook: ' .. webhookName)
        
        local WebhooksModule = LonexDiscord.Webhooks
        local success, err = WebhooksModule.SendEmbed(webhookName, {
            title = '🧪 Test Message',
            description = 'This is a test message from LonexDiscordAPI.',
            color = 5793266, -- Blue
            fields = {
                { name = 'Server', value = GetConvar('sv_hostname', 'Unknown'), inline = true },
                { name = 'Resource', value = GetCurrentResourceName(), inline = true },
            },
        })
        
        if success then
            print('SUCCESS: Test message sent!')
        else
            print('FAILED: ' .. tostring(err))
        end
    end, false)
    
    -- Send direct webhook message
    RegisterCommand('lonex_discord_webhook', function(source, args)
        if source ~= 0 then return end -- Console only
        
        local webhookName = args[1]
        if not webhookName or not args[2] then
            print('Usage: lonex_discord_webhook <webhook_name> <message>')
            return
        end
        
        -- Join remaining args as message
        local msgParts = {}
        for i = 2, #args do
            table.insert(msgParts, args[i])
        end
        local message = table.concat(msgParts, ' ')
        
        print('Sending message to webhook: ' .. webhookName)
        
        local WebhooksModule = LonexDiscord.Webhooks
        local success, err = WebhooksModule.SendMessage(webhookName, message)
        
        if success then
            print('SUCCESS: Message sent!')
        else
            print('FAILED: ' .. tostring(err))
        end
    end, false)
end

-- EVENTS

local Perms = LonexDiscord.Permissions

-- Resource stop cleanup
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        Utils.Info('Resource stopping, clearing caches...')
        Cache.ClearAll()
    end
end)

-- Player connect - extract Discord ID early
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    local discordId = Utils.GetDiscordIdentifier(source)
    
    if discordId then
        Utils.Debug('Player connecting: %s (Discord: %s)', name, discordId)
    else
        Utils.Debug('Player connecting: %s (No Discord linked)', name)
    end
end)

-- Player fully joined - sync permissions
AddEventHandler('playerJoining', function()
    local source = source
    
    if Config.Permissions and Config.Permissions.Enabled then
        -- Small delay to ensure player is fully connected
        SetTimeout(1000, function()
            -- Check if player still exists (might have disconnected)
            if GetPlayerName(source) then
                Utils.Debug('Syncing permissions for player %d...', source)
                Perms.SyncPlayer(source)
            end
        end)
    end
end)

-- Player disconnect - cleanup permissions
AddEventHandler('playerDropped', function(reason)
    local source = source
    
    -- Clean up stored permissions
    Perms.RemoveFromPlayer(source)
    
    -- Clean up cached member data
    local discordId = Utils.GetDiscordIdentifier(source)
    if discordId then
        API.InvalidateMember(discordId)
    end
end)

local WeaponVehicleModule = {}

function WeaponVehicleModule.GetAllowedWeapons(roleIds)
    if not Config.WeaponPermissions or not Config.WeaponPermissions.Enabled then
        return {}, true
    end
    
    if not Config.WeaponPermissions.Roles or not roleIds then
        return {}, false
    end
    
    local allowed = {}
    local noRestrictions = false
    
    for _, roleId in ipairs(roleIds) do
        local roleConfig = Config.WeaponPermissions.Roles[roleId]
        if roleConfig then
            if #roleConfig == 0 then
                noRestrictions = true
                return {}, true
            end
            for _, weapon in ipairs(roleConfig) do
                allowed[weapon] = true
            end
        end
    end
    
    local result = {}
    for weapon in pairs(allowed) do
        table.insert(result, weapon)
    end
    
    return result, noRestrictions
end

function WeaponVehicleModule.GetAllowedVehicles(roleIds)
    if not Config.VehiclePermissions or not Config.VehiclePermissions.Enabled then
        return {}, true
    end
    
    if not Config.VehiclePermissions.Roles or not roleIds then
        return {}, false
    end
    
    local allowed = {}
    local noRestrictions = false
    
    for _, roleId in ipairs(roleIds) do
        local roleConfig = Config.VehiclePermissions.Roles[roleId]
        if roleConfig then
            if #roleConfig == 0 then
                noRestrictions = true
                return {}, true
            end
            for _, vehicle in ipairs(roleConfig) do
                allowed[vehicle] = true
            end
        end
    end
    
    local result = {}
    for vehicle in pairs(allowed) do
        table.insert(result, vehicle)
    end
    
    return result, noRestrictions
end

function WeaponVehicleModule.GetAllowedPeds(roleIds)
    if not Config.PedPermissions or not Config.PedPermissions.Enabled then
        return {}, true
    end
    
    if not Config.PedPermissions.Roles or not roleIds then
        return {}, false
    end
    
    local allowed = {}
    local noRestrictions = false
    
    for _, roleId in ipairs(roleIds) do
        local roleConfig = Config.PedPermissions.Roles[roleId]
        if roleConfig then
            if #roleConfig == 0 then
                noRestrictions = true
                return {}, true
            end
            for _, ped in ipairs(roleConfig) do
                allowed[ped] = true
            end
        end
    end
    
    local result = {}
    for ped in pairs(allowed) do
        table.insert(result, ped)
    end
    
    return result, noRestrictions
end

function WeaponVehicleModule.SyncPermissions(source)
    local discordId = Utils.GetDiscordIdentifier(source)
    
    if not discordId then
        TriggerClientEvent('LonexDiscord:SyncAllPermissions', source, {
            weapons = {},
            vehicles = {},
            peds = {},
            noWeaponRestrictions = false,
            noVehicleRestrictions = false,
            noPedRestrictions = false,
        })
        return
    end
    
    local roleIds, err = API.GetMemberRoleIds(discordId)
    
    if not roleIds then
        roleIds = {}
    end
    
    local weapons, noWeaponRestrictions = WeaponVehicleModule.GetAllowedWeapons(roleIds)
    local vehicles, noVehicleRestrictions = WeaponVehicleModule.GetAllowedVehicles(roleIds)
    local peds, noPedRestrictions = WeaponVehicleModule.GetAllowedPeds(roleIds)
    
    TriggerClientEvent('LonexDiscord:SyncAllPermissions', source, {
        weapons = weapons,
        vehicles = vehicles,
        peds = peds,
        noWeaponRestrictions = noWeaponRestrictions,
        noVehicleRestrictions = noVehicleRestrictions,
        noPedRestrictions = noPedRestrictions,
    })
    
    if Config.Debug then
        Utils.Debug('Synced weapon/vehicle/ped permissions for player %d: %d weapons, %d vehicles, %d peds', 
            source, #weapons, #vehicles, #peds)
    end
end

RegisterNetEvent('LonexDiscord:RequestPermissions')
AddEventHandler('LonexDiscord:RequestPermissions', function()
    local source = source
    WeaponVehicleModule.SyncPermissions(source)
end)

exports('GetAllowedWeapons', function(source)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then return {}, false end
    
    local roleIds = API.GetMemberRoleIds(discordId)
    return WeaponVehicleModule.GetAllowedWeapons(roleIds or {})
end)

exports('GetAllowedVehicles', function(source)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then return {}, false end
    
    local roleIds = API.GetMemberRoleIds(discordId)
    return WeaponVehicleModule.GetAllowedVehicles(roleIds or {})
end)

exports('CanUseWeapon', function(source, weaponName)
    if not Config.WeaponPermissions or not Config.WeaponPermissions.Enabled then
        return true
    end
    
    local restricted = false
    if Config.WeaponPermissions.RestrictedWeapons then
        for _, w in ipairs(Config.WeaponPermissions.RestrictedWeapons) do
            if w:upper() == weaponName:upper() then
                restricted = true
                break
            end
        end
    end
    
    if not restricted then
        return true
    end
    
    local weapons, noRestrictions = exports.LonexDiscordAPI:GetAllowedWeapons(source)
    
    if noRestrictions then
        return true
    end
    
    for _, w in ipairs(weapons) do
        if w:upper() == weaponName:upper() then
            return true
        end
    end
    
    return false
end)

exports('CanUseVehicle', function(source, vehicleName)
    if not Config.VehiclePermissions or not Config.VehiclePermissions.Enabled then
        return true
    end
    
    local restricted = false
    if Config.VehiclePermissions.RestrictedVehicles then
        for _, v in ipairs(Config.VehiclePermissions.RestrictedVehicles) do
            if v:lower() == vehicleName:lower() then
                restricted = true
                break
            end
        end
    end
    
    if not restricted then
        return true
    end
    
    local vehicles, noRestrictions = exports.LonexDiscordAPI:GetAllowedVehicles(source)
    
    if noRestrictions then
        return true
    end
    
    for _, v in ipairs(vehicles) do
        if v:lower() == vehicleName:lower() then
            return true
        end
    end
    
    return false
end)

exports('GetAllowedPeds', function(source)
    local discordId = Utils.GetDiscordIdentifier(source)
    if not discordId then return {}, false end
    
    local roleIds = API.GetMemberRoleIds(discordId)
    return WeaponVehicleModule.GetAllowedPeds(roleIds or {})
end)

exports('CanUsePed', function(source, pedName)
    if not Config.PedPermissions or not Config.PedPermissions.Enabled then
        return true
    end
    
    local restricted = false
    if Config.PedPermissions.RestrictedPeds then
        for _, p in ipairs(Config.PedPermissions.RestrictedPeds) do
            if p:lower() == pedName:lower() then
                restricted = true
                break
            end
        end
    end
    
    if not restricted then
        return true
    end
    
    local peds, noRestrictions = exports.LonexDiscordAPI:GetAllowedPeds(source)
    
    if noRestrictions then
        return true
    end
    
    for _, p in ipairs(peds) do
        if p:lower() == pedName:lower() then
            return true
        end
    end
    
    return false
end)

exports('SyncWeaponVehiclePermissions', function(source)
    WeaponVehicleModule.SyncPermissions(source)
end)

exports('SyncAllRestrictionPermissions', function(source)
    WeaponVehicleModule.SyncPermissions(source)
end)

LonexDiscord.WeaponVehicle = WeaponVehicleModule

-- CHAT ROLES MODULE

local ChatRolesModule = {}
local PlayerChatRoles = {}

function ChatRolesModule.GetPlayerChatRole(source)
    if not Config.ChatRoles or not Config.ChatRoles.Enabled then
        return nil
    end
    
    -- Check cache first
    if PlayerChatRoles[source] then
        return PlayerChatRoles[source]
    end
    
    local discordId = Utils.GetDiscordIdentifier(source)
    
    if not discordId then
        return Config.ChatRoles.DefaultRole
    end
    
    local roleIds, err = API.GetMemberRoleIds(discordId)
    
    if not roleIds then
        return Config.ChatRoles.DefaultRole
    end
    
    -- Convert roleIds to a set for faster lookup
    local playerRoleSet = {}
    for _, roleId in ipairs(roleIds) do
        playerRoleSet[roleId] = true
    end
    
    -- Find highest priority role (last in list that player has)
    local highestRole = Config.ChatRoles.DefaultRole
    
    if Config.ChatRoles.Roles then
        for _, roleConfig in ipairs(Config.ChatRoles.Roles) do
            if playerRoleSet[roleConfig.roleId] then
                highestRole = roleConfig
            end
        end
    end
    
    -- Cache it
    PlayerChatRoles[source] = highestRole
    
    return highestRole
end

function ChatRolesModule.GetChatPrefix(source)
    local role = ChatRolesModule.GetPlayerChatRole(source)
    
    if role and role.prefix then
        return role.prefix
    end
    
    return ''
end

function ChatRolesModule.RefreshPlayerRole(source)
    PlayerChatRoles[source] = nil
    return ChatRolesModule.GetPlayerChatRole(source)
end

function ChatRolesModule.ClearPlayerRole(source)
    PlayerChatRoles[source] = nil
end

-- Clear chat role cache on disconnect
AddEventHandler('playerDropped', function()
    local source = source
    ChatRolesModule.ClearPlayerRole(source)
end)

-- Chat message handler
AddEventHandler('chatMessage', function(source, name, message)
    if not Config.ChatRoles or not Config.ChatRoles.Enabled then
        return
    end
    
    local prefix = ChatRolesModule.GetChatPrefix(source)
    
    if prefix and prefix ~= '' then
        -- Cancel original message
        CancelEvent()
        
        -- Send modified message with prefix
        TriggerClientEvent('chat:addMessage', -1, {
            args = { prefix .. name, message },
            color = { 255, 255, 255 }
        })
    end
end)

exports('GetPlayerChatRole', function(source)
    return ChatRolesModule.GetPlayerChatRole(source)
end)

exports('GetChatPrefix', function(source)
    return ChatRolesModule.GetChatPrefix(source)
end)

exports('RefreshPlayerChatRole', function(source)
    return ChatRolesModule.RefreshPlayerRole(source)
end)

LonexDiscord.ChatRoles = ChatRolesModule

-- HEADTAGS MODULE

local HeadTagsModule = {}
local PlayerAvailableTags = {}
local PlayerSelectedTag = {}
local PlayerHeadTagSettings = {}

function HeadTagsModule.GetPlayerAvailableTags(source)
    if not Config.HeadTags or not Config.HeadTags.Enabled then
        return {}
    end
    
    if PlayerAvailableTags[source] then
        return PlayerAvailableTags[source]
    end
    
    local discordId = Utils.GetDiscordIdentifier(source)
    local available = {}
    
    -- Always add default tag first
    if Config.HeadTags.DefaultTag then
        table.insert(available, Config.HeadTags.DefaultTag)
    end
    
    if discordId then
        local roleIds, err = API.GetMemberRoleIds(discordId)
        
        if roleIds then
            local playerRoleSet = {}
            for _, roleId in ipairs(roleIds) do
                playerRoleSet[roleId] = true
            end
            
            if Config.HeadTags.Roles then
                for _, roleConfig in ipairs(Config.HeadTags.Roles) do
                    if playerRoleSet[roleConfig.roleId] then
                        table.insert(available, roleConfig)
                    end
                end
            end
        end
    end
    
    PlayerAvailableTags[source] = available
    return available
end

function HeadTagsModule.GetPlayerHeadTag(source)
    if not Config.HeadTags or not Config.HeadTags.Enabled then
        return nil
    end
    
    local available = HeadTagsModule.GetPlayerAvailableTags(source)
    local selectedIndex = PlayerSelectedTag[source] or #available
    
    if selectedIndex > #available then
        selectedIndex = #available
    end
    if selectedIndex < 1 then
        selectedIndex = 1
    end
    
    return available[selectedIndex] or Config.HeadTags.DefaultTag
end

function HeadTagsModule.SetPlayerSelectedTag(source, index)
    local available = HeadTagsModule.GetPlayerAvailableTags(source)
    
    if index >= 1 and index <= #available then
        PlayerSelectedTag[source] = index
        HeadTagsModule.BroadcastPlayerTag(source)
        return true
    end
    
    return false
end

function HeadTagsModule.GetPlayerSettings(source)
    if not PlayerHeadTagSettings[source] then
        PlayerHeadTagSettings[source] = {
            showOthers = Config.HeadTags.DefaultShowOthers ~= false,
            showOwn = Config.HeadTags.DefaultShowOwn ~= false,
            selectedIndex = nil,
        }
    end
    return PlayerHeadTagSettings[source]
end

function HeadTagsModule.SetPlayerSettings(source, settings)
    PlayerHeadTagSettings[source] = settings
end

function HeadTagsModule.RefreshPlayerHeadTag(source)
    PlayerAvailableTags[source] = nil
    PlayerSelectedTag[source] = nil
    local tag = HeadTagsModule.GetPlayerHeadTag(source)
    HeadTagsModule.BroadcastPlayerTag(source)
    return tag
end

function HeadTagsModule.ClearPlayerHeadTag(source)
    PlayerAvailableTags[source] = nil
    PlayerSelectedTag[source] = nil
    PlayerHeadTagSettings[source] = nil
end

function HeadTagsModule.GetAllPlayerTags()
    local tags = {}
    local players = GetPlayers()
    
    for _, playerId in ipairs(players) do
        local source = tonumber(playerId)
        local tag = HeadTagsModule.GetPlayerHeadTag(source)
        if tag then
            tags[source] = {
                tag = tag,
                name = GetPlayerName(source) or 'Unknown',
            }
        end
    end
    
    return tags
end

function HeadTagsModule.BroadcastPlayerTag(source)
    local tag = HeadTagsModule.GetPlayerHeadTag(source)
    local name = GetPlayerName(source) or 'Unknown'
    
    TriggerClientEvent('LonexDiscord:HeadTags:UpdatePlayerTag', -1, source, {
        tag = tag,
        name = name,
    })
end

function HeadTagsModule.SyncAllTagsToPlayer(targetSource)
    local allTags = HeadTagsModule.GetAllPlayerTags()
    local settings = HeadTagsModule.GetPlayerSettings(targetSource)
    local available = HeadTagsModule.GetPlayerAvailableTags(targetSource)
    local selectedIndex = PlayerSelectedTag[targetSource] or #available
    
    TriggerClientEvent('LonexDiscord:HeadTags:SyncAll', targetSource, allTags, settings, available, selectedIndex)
end

-- Clear headtag cache on disconnect
AddEventHandler('playerDropped', function()
    local source = source
    HeadTagsModule.ClearPlayerHeadTag(source)
    TriggerClientEvent('LonexDiscord:HeadTags:PlayerLeft', -1, source)
end)

-- Sync tags when player joins
AddEventHandler('playerJoining', function()
    local source = source
    
    if not Config.HeadTags or not Config.HeadTags.Enabled then
        return
    end
    
    SetTimeout(3000, function()
        HeadTagsModule.BroadcastPlayerTag(source)
        HeadTagsModule.SyncAllTagsToPlayer(source)
    end)
end)

-- Register headtags command
RegisterCommand(Config.HeadTags and Config.HeadTags.MenuCommand or 'headtags', function(source, args)
    if source == 0 then return end
    
    if not Config.HeadTags or not Config.HeadTags.Enabled then
        return
    end
    
    local available = HeadTagsModule.GetPlayerAvailableTags(source)
    local selectedIndex = PlayerSelectedTag[source] or #available
    local settings = HeadTagsModule.GetPlayerSettings(source)
    
    TriggerClientEvent('LonexDiscord:HeadTags:OpenMenu', source, available, selectedIndex, settings)
end, false)

-- Client requests
RegisterNetEvent('LonexDiscord:HeadTags:RequestSync')
AddEventHandler('LonexDiscord:HeadTags:RequestSync', function()
    local source = source
    HeadTagsModule.SyncAllTagsToPlayer(source)
end)

RegisterNetEvent('LonexDiscord:HeadTags:SelectTag')
AddEventHandler('LonexDiscord:HeadTags:SelectTag', function(index)
    local source = source
    
    if type(index) ~= 'number' then return end
    
    HeadTagsModule.SetPlayerSelectedTag(source, index)
end)

RegisterNetEvent('LonexDiscord:HeadTags:UpdateMySettings')
AddEventHandler('LonexDiscord:HeadTags:UpdateMySettings', function(settings)
    local source = source
    
    if type(settings) ~= 'table' then return end
    
    local currentSettings = HeadTagsModule.GetPlayerSettings(source)
    
    if settings.showOthers ~= nil then
        currentSettings.showOthers = settings.showOthers == true
    end
    if settings.showOwn ~= nil then
        currentSettings.showOwn = settings.showOwn == true
    end
    
    HeadTagsModule.SetPlayerSettings(source, currentSettings)
end)

exports('GetPlayerHeadTag', function(source)
    return HeadTagsModule.GetPlayerHeadTag(source)
end)

exports('GetPlayerAvailableTags', function(source)
    return HeadTagsModule.GetPlayerAvailableTags(source)
end)

exports('GetPlayerHeadTagSettings', function(source)
    return HeadTagsModule.GetPlayerSettings(source)
end)

exports('SetPlayerHeadTagSettings', function(source, settings)
    HeadTagsModule.SetPlayerSettings(source, settings)
end)

exports('SetPlayerSelectedTag', function(source, index)
    return HeadTagsModule.SetPlayerSelectedTag(source, index)
end)

exports('RefreshPlayerHeadTag', function(source)
    return HeadTagsModule.RefreshPlayerHeadTag(source)
end)

exports('GetAllHeadTags', function()
    return HeadTagsModule.GetAllPlayerTags()
end)

LonexDiscord.HeadTags = HeadTagsModule
