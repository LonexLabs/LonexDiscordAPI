-- LonexDiscordAPI Server

local REQUIRED_RESOURCE_NAME = 'LonexDiscordAPI'
local CURRENT_VERSION = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '0.0.0'
local GITHUB_REPO = 'LonexLabs/LonexDiscordAPI'

if GetCurrentResourceName() ~= REQUIRED_RESOURCE_NAME then
    print('^1[LonexDiscord] ERROR: Resource must be named "' .. REQUIRED_RESOURCE_NAME .. '"!^0')
    print('^1[LonexDiscord] Current name: "' .. GetCurrentResourceName() .. '"^0')
    print('^3[LonexDiscord] Please rename the resource folder to "' .. REQUIRED_RESOURCE_NAME .. '"^0')
    return
end

-- VERSION CHECKER

local function ParseVersion(versionStr)
    local major, minor, patch = versionStr:match('^v?(%d+)%.(%d+)%.(%d+)')
    if major then
        return {
            major = tonumber(major),
            minor = tonumber(minor),
            patch = tonumber(patch),
            str = versionStr
        }
    end
    return nil
end

local function IsNewerVersion(current, latest)
    if not current or not latest then return false end
    
    if latest.major > current.major then return true end
    if latest.major < current.major then return false end
    
    if latest.minor > current.minor then return true end
    if latest.minor < current.minor then return false end
    
    return latest.patch > current.patch
end

local function IsSameVersion(current, latest)
    if not current or not latest then return false end
    return current.major == latest.major and current.minor == latest.minor and current.patch == latest.patch
end

local function CheckForUpdates()
    local url = 'https://api.github.com/repos/' .. GITHUB_REPO .. '/releases/latest'
    
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode ~= 200 then
            if Config.Debug then
                print('^3[LonexDiscord] Could not check for updates (HTTP ' .. tostring(statusCode) .. ')^0')
            end
            return
        end
        
        local data = json.decode(response)
        if not data or not data.tag_name then
            return
        end
        
        local latestVersion = ParseVersion(data.tag_name)
        local currentVersion = ParseVersion(CURRENT_VERSION)
        
        if IsNewerVersion(currentVersion, latestVersion) then
            -- Update available
            print('')
            print('^3╔══════════════════════════════════════════════════════════════╗^0')
            print('^3║^0              ^1LonexDiscordAPI Update Available^0               ^3║^0')
            print('^3╠══════════════════════════════════════════════════════════════╣^0')
            print('^3║^0  Current Version: ^1' .. CURRENT_VERSION .. string.rep(' ', 44 - #CURRENT_VERSION) .. '^3║^0')
            print('^3║^0  Latest Version:  ^2' .. data.tag_name .. string.rep(' ', 44 - #data.tag_name) .. '^3║^0')
            print('^3╠══════════════════════════════════════════════════════════════╣^0')
            print('^3║^0  Download: ^4https://github.com/' .. GITHUB_REPO .. '/releases^0  ^3║^0')
            print('^3╚══════════════════════════════════════════════════════════════╝^0')
            print('')
        elseif IsSameVersion(currentVersion, latestVersion) then
            -- Same version - up to date
            print('^2[LonexDiscord] ^0v' .. CURRENT_VERSION .. ' - Up to date!')
        else
            -- Current is newer than latest (development/unreleased version)
            print('^3[LonexDiscord] ^0v' .. CURRENT_VERSION .. ' - Development version (latest release: ' .. data.tag_name .. ')')
        end
    end, 'GET', '', {
        ['User-Agent'] = 'LonexDiscordAPI/' .. CURRENT_VERSION,
        ['Accept'] = 'application/vnd.github.v3+json'
    })
end

-- STARTUP VALIDATION

local ACE_PERMISSION_GRANTED = false
local ACE_WARNING_SHOWN = false
local RESOURCE_NAME = GetCurrentResourceName()

-- Test if we have permission to assign ACE permissions
local function TestAcePermissions()
    -- Create a test principal that we'll immediately remove
    local testIdentifier = 'lonex.test.' .. math.random(100000, 999999)
    local testGroup = 'lonex_permission_test'
    
    -- Try to add a test principal
    local success = true
    
    -- Register a one-time handler to catch the error
    local errorOccurred = false
    
    -- Use pcall to catch any errors
    local ok, err = pcall(function()
        ExecuteCommand(string.format('add_principal identifier.%s group.%s', testIdentifier, testGroup))
    end)
    
    if not ok then
        success = false
    end
    
    -- Clean up test
    pcall(function()
        ExecuteCommand(string.format('remove_principal identifier.%s group.%s', testIdentifier, testGroup))
    end)
    
    return success
end

-- Print ACE setup instructions
local function PrintAceSetupInstructions()
    print('')
    print('^1╔══════════════════════════════════════════════════════════════════════════════╗^0')
    print('^1║                    LONEXDISCORDAPI - PERMISSION ERROR                        ║^0')
    print('^1╠══════════════════════════════════════════════════════════════════════════════╣^0')
    print('^1║^0 The resource cannot assign ACE permissions to players.                       ^1║^0')
    print('^1║^0 This means Discord role permissions will NOT work.                           ^1║^0')
    print('^1╠══════════════════════════════════════════════════════════════════════════════╣^0')
    print('^1║^0 ^3Add this line to your server.cfg BEFORE ensure ' .. RESOURCE_NAME .. ':^0' .. string.rep(' ', 21 - #RESOURCE_NAME) .. '^1║^0')
    print('^1╠══════════════════════════════════════════════════════════════════════════════╣^0')
    print('^1║^0                                                                              ^1║^0')
    print('^1║^0  ^2exec @' .. RESOURCE_NAME .. '/lonexperms.cfg^0' .. string.rep(' ', 42 - #RESOURCE_NAME) .. '^1║^0')
    print('^1║^0                                                                              ^1║^0')
    print('^1╠══════════════════════════════════════════════════════════════════════════════╣^0')
    print('^1║^0 ^3Example server.cfg:^0                                                         ^1║^0')
    print('^1║^0                                                                              ^1║^0')
    print('^1║^0  ^2exec @' .. RESOURCE_NAME .. '/lonexperms.cfg^0' .. string.rep(' ', 42 - #RESOURCE_NAME) .. '^1║^0')
    print('^1║^0  ^2set lonex_discord_token "YOUR_BOT_TOKEN"^0                                   ^1║^0')
    print('^1║^0  ^2set lonex_discord_guild "YOUR_GUILD_ID"^0                                    ^1║^0')
    print('^1║^0  ^2ensure ' .. RESOURCE_NAME .. '^0' .. string.rep(' ', 51 - #RESOURCE_NAME) .. '^1║^0')
    print('^1║^0                                                                              ^1║^0')
    print('^1╠══════════════════════════════════════════════════════════════════════════════╣^0')
    print('^1║^0 ^3After adding, do a FULL server restart (stop + start, not just restart)^0    ^1║^0')
    print('^1╚══════════════════════════════════════════════════════════════════════════════╝^0')
    print('')
end

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
    
    -- Test ACE permissions if permission system is enabled
    Wait(2000) -- Wait for server to fully initialize
    
    if Config.Permissions and Config.Permissions.Enabled then
        -- Actually test if we can assign permissions by doing a test assignment
        local testId = 'lonex.test.' .. math.random(100000, 999999)
        local testGroup = 'lonex_ace_test_' .. math.random(1000, 9999)
        
        -- Try to add a test principal
        ExecuteCommand(string.format('add_principal identifier.%s group.%s', testId, testGroup))
        
        -- Clean up
        ExecuteCommand(string.format('remove_principal identifier.%s group.%s', testId, testGroup))
        
        -- Assume permissions work - we'll catch actual failures when assigning to real players
        ACE_PERMISSION_GRANTED = true
        
        if Config.Debug then
            print('^2[LonexDiscord] Permission system initialized^0')
        end
        
        -- Pre-resolve all roles from config on startup
        LonexDiscord.Permissions.ResolveAllRoles()
        
        -- Count and log
        local roleCount = 0
        for _ in pairs(Roles or {}) do roleCount = roleCount + 1 end
        if roleCount > 0 then
            print('^2[LonexDiscord] Loaded ' .. roleCount .. ' role mappings^0')
        end
        
        -- Sync permissions for any players already connected (e.g., after resource restart)
        SetTimeout(3000, function()
            local players = GetPlayers()
            if #players > 0 then
                for _, playerId in ipairs(players) do
                    LonexDiscord.Permissions.SyncPlayer(tonumber(playerId))
                end
            end
        end)
    end
    
    -- Check for updates after a short delay
    Wait(3000)
    if Config.CheckUpdates ~= false then
        CheckForUpdates()
    end
end)

-- Console command to check for updates
RegisterCommand('lonex_update', function(source)
    if source ~= 0 then return end -- Server console only
    print('[LonexDiscord] Checking for updates...')
    CheckForUpdates()
end, true)

-- Console command to check ACE permission status
RegisterCommand('lonex_ace_check', function(source)
    if source ~= 0 then return end -- Server console only
    
    print('')
    print('^3[LonexDiscord] ACE Permission Test^0')
    print('^3================================^0')
    print('Resource name: ^2' .. RESOURCE_NAME .. '^0')
    
    -- Do an actual test assignment
    local testId = 'lonex.acetest.' .. math.random(100000, 999999)
    local testGroup = 'lonex_test_' .. math.random(1000, 9999)
    
    print('Testing add_principal...')
    ExecuteCommand(string.format('add_principal identifier.%s group.%s', testId, testGroup))
    
    print('Testing remove_principal...')
    ExecuteCommand(string.format('remove_principal identifier.%s group.%s', testId, testGroup))
    
    print('')
    print('^2If you see "Access denied" errors above, permissions are NOT working.^0')
    print('^2If no errors appeared, permissions should work correctly.^0')
    print('')
    print('^3To fix permission issues:^0')
    print('  1. Add ^2exec @' .. RESOURCE_NAME .. '/lonexperms.cfg^0 to server.cfg')
    print('  2. Make sure it comes BEFORE ^2ensure ' .. RESOURCE_NAME .. '^0')
    print('  3. Do a full server restart (stop + start)')
    print('')
end, true)

-- Console command to show setup instructions
RegisterCommand('lonex_ace_help', function(source)
    if source ~= 0 then return end -- Server console only
    PrintAceSetupInstructions()
end, true)

-- Console command to list configured roles
RegisterCommand('lonex_roles', function(source)
    if source ~= 0 then return end -- Server console only
    
    print('')
    print('^3[LonexDiscord] Configured Roles^0')
    print('^3================================^0')
    
    local configRoles = Roles
    if configRoles == nil then
        print('^1Roles table is NIL - config not loaded correctly!^0')
        return
    end
    
    local count = 0
    for roleId, config in pairs(configRoles) do
        count = count + 1
        local groupStr = type(config) == 'string' and config or (type(config) == 'table' and table.concat(config, ', ') or tostring(config))
        print('  ' .. roleId .. ' -> group.' .. groupStr)
    end
    
    if count == 0 then
        print('^3No roles configured. Add them to config.lua:^0')
        print('')
        print("Roles = {")
        print("    ['DISCORD_ROLE_ID'] = 'groupname',")
        print("}")
    else
        print('')
        print('Total: ' .. count .. ' role mappings')
    end
    print('')
end, true)

-- Console command to sync all players
RegisterCommand('lonex_syncall', function(source)
    if source ~= 0 then return end -- Server console only
    
    local players = GetPlayers()
    if #players == 0 then
        print('^3[LonexDiscord] No players connected^0')
        return
    end
    
    print('^3[LonexDiscord] Syncing ' .. #players .. ' player(s)...^0')
    
    for _, playerId in ipairs(players) do
        local src = tonumber(playerId)
        local playerName = GetPlayerName(src) or 'Unknown'
        local success, err = LonexDiscord.Permissions.SyncPlayer(src)
        
        if success then
            local groups = LonexDiscord.Permissions.GetPlayerGroups(src)
            print('^2  ✓ ' .. playerName .. ': ' .. (groups and #groups > 0 and table.concat(groups, ', ') or 'no groups') .. '^0')
        else
            print('^1  ✗ ' .. playerName .. ': ' .. tostring(err) .. '^0')
        end
    end
    
    print('^2[LonexDiscord] Sync complete^0')
end, true)

-- Debug command to diagnose player permission issues
RegisterCommand('lonex_debug_player', function(source, args)
    if source ~= 0 then return end -- Server console only
    
    local playerId = tonumber(args[1])
    if not playerId then
        print('Usage: lonex_debug_player <player_id>')
        return
    end
    
    local playerName = GetPlayerName(playerId)
    if not playerName then
        print('^1Player ' .. playerId .. ' not found^0')
        return
    end
    
    print('')
    print('^3═══════════════════════════════════════════════════^0')
    print('^3  LonexDiscordAPI Debug - Player ' .. playerId .. '^0')
    print('^3═══════════════════════════════════════════════════^0')
    print('')
    print('^2[1] Player Info^0')
    print('    Name: ' .. playerName)
    
    -- Get Discord ID
    local discordId = LonexDiscord.Utils.GetDiscordIdentifier(playerId)
    print('    Discord ID: ' .. (discordId or '^1NOT LINKED^0'))
    
    if not discordId then
        print('')
        print('^1Player does not have Discord linked to FiveM!^0')
        print('^3They need to link Discord in FiveM settings.^0')
        return
    end
    
    -- Try to fetch from Discord
    print('')
    print('^2[2] Discord API Fetch^0')
    local roleIds, err = LonexDiscord.API.GetMemberRoleIds(discordId)
    
    if not roleIds then
        print('    ^1Error fetching roles: ' .. tostring(err) .. '^0')
        print('')
        print('^1Check:^0')
        print('  - Is the bot token correct?')
        print('  - Is the guild ID correct?')
        print('  - Does the bot have Server Members Intent enabled?')
        print('  - Is the player in the Discord server?')
        return
    end
    
    print('    Found ' .. #roleIds .. ' Discord roles:')
    for _, roleId in ipairs(roleIds) do
        local role = LonexDiscord.Cache.GetRoleById(roleId)
        local roleName = role and role.name or 'Unknown'
        print('    - ' .. roleId .. ' (' .. roleName .. ')')
    end
    
    -- Check config - show the actual global Roles table
    print('')
    print('^2[3] Config Roles Table (global Roles)^0')
    local configRoles = Roles
    if configRoles == nil then
        print('    ^1Roles table is NIL - not loaded!^0')
        configRoles = {}
    else
        local configCount = 0
        for k, v in pairs(configRoles) do 
            configCount = configCount + 1
            local groupStr = type(v) == 'string' and v or (type(v) == 'table' and table.concat(v, ', ') or tostring(v))
            print('    ' .. k .. ' -> ' .. groupStr)
        end
        print('    Total configured: ' .. configCount)
    end
    
    -- Check ResolvedRoles
    print('')
    print('^2[4] ResolvedRoles (processed)^0')
    if not ResolvedRoles then
        print('    ^1ResolvedRoles is NIL - calling ResolveAllRoles()^0')
        LonexDiscord.Permissions.ResolveAllRoles()
    end
    local resolvedCount = 0
    for k, v in pairs(ResolvedRoles or {}) do
        resolvedCount = resolvedCount + 1
        local groupStr = v.groups and table.concat(v.groups, ', ') or 'none'
        print('    ' .. k .. ' -> ' .. groupStr)
    end
    print('    Total resolved: ' .. resolvedCount)
    
    -- Check matches
    print('')
    print('^2[5] Matching Roles^0')
    local matchCount = 0
    for _, roleId in ipairs(roleIds) do
        local config = configRoles[roleId]
        if config then
            matchCount = matchCount + 1
            local groupStr = type(config) == 'string' and config or table.concat(config, ', ')
            print('    ^2✓^0 ' .. roleId .. ' -> ' .. groupStr)
        end
    end
    
    if matchCount == 0 then
        print('    ^1No matches found!^0')
        print('')
        print('^3Add the Discord role IDs to config.lua:^0')
        print('Roles = {')
        for _, roleId in ipairs(roleIds) do
            local role = LonexDiscord.Cache.GetRoleById(roleId)
            local roleName = role and role.name or 'Unknown'
            print("    ['" .. roleId .. "'] = 'groupname',  -- " .. roleName)
        end
        print('}')
    else
        print('')
        print('    Matched ' .. matchCount .. ' of ' .. #roleIds .. ' roles')
    end
    
    -- Build permissions
    print('')
    print('^2[6] Building Permissions^0')
    local perms, groups = LonexDiscord.Permissions.BuildPermissionsForRoleIds(roleIds)
    print('    Groups: ' .. (#groups > 0 and table.concat(groups, ', ') or 'none'))
    print('    Permissions: ' .. #perms)
    
    -- Check stored
    print('')
    print('^2[7] Currently Stored^0')
    local storedGroups = LonexDiscord.Permissions.GetPlayerGroups(playerId)
    local storedPerms = LonexDiscord.Permissions.GetPlayerPermissions(playerId)
    print('    Stored Groups: ' .. (storedGroups and #storedGroups > 0 and table.concat(storedGroups, ', ') or 'none'))
    print('    Stored Perms: ' .. (storedPerms and #storedPerms or 0))
    
    print('')
    print('^3═══════════════════════════════════════════════════^0')
    print('')
end, true)


LonexDiscord = LonexDiscord or {}

-- PERMISSIONS MODULE (embedded)

LonexDiscord.Permissions = {}

local PermissionsModule = LonexDiscord.Permissions

-- Track assigned permissions per player (for cleanup)
local PlayerPermissions = {} -- [source] = { permissions = {}, groups = {} }

-- Resolved role configs (with inheritance flattened)
local ResolvedRoles = nil

---Normalize a role config to the standard format
---Handles: string, array of strings, or full config table
local function NormalizeRoleConfig(roleConfig)
    if type(roleConfig) == 'string' then
        -- Simple format: 'groupname'
        return {
            groups = { roleConfig },
            permissions = {},
            priority = 0
        }
    elseif type(roleConfig) == 'table' then
        -- Check if it's an array of strings (multiple groups)
        if #roleConfig > 0 and type(roleConfig[1]) == 'string' then
            -- Array format: { 'group1', 'group2' }
            return {
                groups = roleConfig,
                permissions = {},
                priority = 0
            }
        else
            -- Advanced format: { groups = {...}, permissions = {...}, priority = X }
            return {
                groups = roleConfig.groups or {},
                permissions = roleConfig.permissions or {},
                priority = roleConfig.priority or 0,
                inherits = roleConfig.inherits
            }
        end
    end
    
    return { groups = {}, permissions = {}, priority = 0 }
end

---Resolve inheritance for a single role config
local function ResolveRoleInheritance(roleName, visited, roleMappings)
    visited = visited or {}
    roleMappings = roleMappings or Roles or {}
    
    if visited[roleName] then
        return { permissions = {}, groups = {}, priority = 0 }
    end
    visited[roleName] = true
    
    local rawConfig = roleMappings[roleName]
    if not rawConfig then
        return { permissions = {}, groups = {}, priority = 0 }
    end
    
    local roleConfig = NormalizeRoleConfig(rawConfig)
    
    local resolved = {
        permissions = {},
        groups = {},
        priority = roleConfig.priority or 0
    }
    
    -- Handle inheritance (advanced format only)
    if roleConfig.inherits then
        for _, inheritedRole in ipairs(roleConfig.inherits) do
            local inherited = ResolveRoleInheritance(inheritedRole, visited, roleMappings)
            for _, perm in ipairs(inherited.permissions) do
                resolved.permissions[perm] = true
            end
            for _, group in ipairs(inherited.groups) do
                resolved.groups[group] = true
            end
        end
    end
    
    -- Add this role's permissions
    if roleConfig.permissions then
        for _, perm in ipairs(roleConfig.permissions) do
            resolved.permissions[perm] = true
        end
    end
    
    -- Add this role's groups
    if roleConfig.groups then
        for _, group in ipairs(roleConfig.groups) do
            resolved.groups[group] = true
        end
    end
    
    -- Convert sets to arrays
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

-- Load role mappings from convars (lonexperms.cfg)
local function LoadRolesFromConvars()
    local convarRoles = {}
    local loadedCount = 0
    
    -- We need to check for convars, but FiveM doesn't let us enumerate them
    -- So we'll check the Config.Permissions.Roles keys and also look for 
    -- any convars that were set via lonexperms.cfg
    
    -- The trick: We can't enumerate convars, but we CAN check if specific ones exist
    -- Users will set: set lonex_perm_ROLEID "groupname"
    -- We need to scan for these when a player joins and we know their role IDs
    
    -- For now, we'll store a flag that convar loading is enabled
    -- and check convars dynamically when building permissions
    
    -- Check for default groups convar
    local defaultGroupsConvar = GetConvar('lonex_default_groups', '')
    if defaultGroupsConvar ~= '' then
        local groups = {}
        for group in string.gmatch(defaultGroupsConvar, '([^,]+)') do
            group = group:match('^%s*(.-)%s*$') -- trim whitespace
            if group ~= '' then
                table.insert(groups, group)
            end
        end
        if #groups > 0 then
            Config.Permissions = Config.Permissions or {}
            Config.Permissions.DefaultGroups = Config.Permissions.DefaultGroups or {}
            for _, group in ipairs(groups) do
                local found = false
                for _, existing in ipairs(Config.Permissions.DefaultGroups) do
                    if existing == group then found = true break end
                end
                if not found then
                    table.insert(Config.Permissions.DefaultGroups, group)
                end
            end
            if Config.Debug then
                print('^2[LonexDiscord] Loaded default groups from convar: ' .. table.concat(groups, ', ') .. '^0')
            end
        end
    end
    
    return convarRoles
end

-- Check convar for a specific role ID (called when building permissions)
local function GetRoleConfigFromConvar(roleId)
    local convar = GetConvar('lonex_perm_' .. roleId, '')
    if convar == '' then
        return nil
    end
    
    -- Parse the convar value (can be "group" or "group1,group2")
    local groups = {}
    for group in string.gmatch(convar, '([^,]+)') do
        group = group:match('^%s*(.-)%s*$') -- trim whitespace
        if group ~= '' then
            table.insert(groups, group)
        end
    end
    
    if #groups == 0 then
        return nil
    end
    
    return {
        groups = groups,
        permissions = {},
        priority = 0
    }
end

function PermissionsModule.ResolveAllRoles()
    ResolvedRoles = {}
    
    -- Load any settings from convars first
    LoadRolesFromConvars()
    
    -- Get roles from the global Roles table (roles.lua)
    local roleMappings = Roles or {}
    
    -- Also support legacy Config.Permissions.Roles if it exists
    if Config.Permissions and Config.Permissions.Roles then
        for roleId, config in pairs(Config.Permissions.Roles) do
            if not roleMappings[roleId] then
                roleMappings[roleId] = config
            end
        end
    end
    
    for roleName, rawConfig in pairs(roleMappings) do
        ResolvedRoles[roleName] = ResolveRoleInheritance(roleName, nil, roleMappings)
        local normalized = NormalizeRoleConfig(rawConfig)
        ResolvedRoles[roleName].priority = normalized.priority or 0
    end
    
    -- Log loaded roles count
    local count = 0
    for _ in pairs(ResolvedRoles) do count = count + 1 end
    if count > 0 and Config.Debug then
        print('^2[LonexDiscord] Loaded ' .. count .. ' role mappings^0')
    end
end

-- Get resolved config for a role (checks both config.lua and convars)
local function GetResolvedRoleConfig(roleId)
    -- First check if we have it in ResolvedRoles (from config.lua)
    if ResolvedRoles and ResolvedRoles[roleId] then
        return ResolvedRoles[roleId]
    end
    
    -- Then check convars
    local convarConfig = GetRoleConfigFromConvar(roleId)
    if convarConfig then
        -- Cache it for future use
        ResolvedRoles = ResolvedRoles or {}
        ResolvedRoles[roleId] = convarConfig
        
        if Config.Debug then
            print('^2[LonexDiscord] Loaded role ' .. roleId .. ' from convar -> ' .. table.concat(convarConfig.groups, ', ') .. '^0')
        end
        
        return convarConfig
    end
    
    return nil
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
    
    -- Match role IDs against configured roles (checks both config.lua and convars)
    for _, roleId in ipairs(roleIds) do
        local resolved = GetResolvedRoleConfig(roleId)
        if resolved then
            table.insert(matchedRoles, {
                id = roleId,
                config = resolved
            })
        end
    end
    
    table.sort(matchedRoles, function(a, b)
        return (a.config.priority or 0) < (b.config.priority or 0)
    end)
    
    for _, role in ipairs(matchedRoles) do
        for _, perm in ipairs(role.config.permissions or {}) do
            allPermissions[perm] = true
        end
        for _, group in ipairs(role.config.groups or {}) do
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
    -- Check if we have permission to assign ACE
    if not ACE_PERMISSION_GRANTED and not ACE_WARNING_SHOWN then
        ACE_WARNING_SHOWN = true
        PrintAceSetupInstructions()
    end
    
    -- Use Discord identifier for ACE (like Badger does)
    local discordId = LonexDiscord.Utils.GetDiscordIdentifier(source)
    if not discordId then
        print('^1[LonexDiscord] Cannot assign permissions - no Discord identifier for player ' .. source .. '^0')
        return
    end
    
    local identifier = 'discord:' .. discordId
    
    PlayerPermissions[source] = {
        permissions = permissions,
        groups = groups,
        discordId = discordId
    }
    
    -- Log what we're trying to assign
    if Config.Debug or not ACE_PERMISSION_GRANTED then
        local playerName = GetPlayerName(source) or 'Unknown'
        if not ACE_PERMISSION_GRANTED then
            print('^3[LonexDiscord] WARNING: Attempting to assign permissions without ACE access^0')
            print('^3[LonexDiscord] Player: ' .. playerName .. ' (ID: ' .. source .. ')^0')
            print('^3[LonexDiscord] Groups: ' .. table.concat(groups, ', ') .. '^0')
            print('^3[LonexDiscord] Permissions: ' .. #permissions .. ' total^0')
        end
    end
    
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
    
    -- Use stored Discord ID, or fetch it
    local discordId = stored.discordId or LonexDiscord.Utils.GetDiscordIdentifier(source)
    if not discordId then
        PlayerPermissions[source] = nil
        return
    end
    
    local identifier = 'discord:' .. discordId
    
    for _, perm in ipairs(stored.permissions or {}) do
        local safePerm = SanitizeAceString(perm)
        if safePerm and safePerm ~= '' then
            ExecuteCommand(string.format('remove_ace identifier.%s %s allow', identifier, safePerm))
        end
    end
    
    for _, group in ipairs(stored.groups or {}) do
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
                local roleName = role and role.name or 'Unknown'
                print('  - ' .. roleId .. ' (' .. roleName .. ')')
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
        
        print('Syncing permissions for player ' .. targetSource .. '...')
        
        local PermsModule = LonexDiscord.Permissions
        
        local roleIds, err = LonexDiscord.API.GetMemberRoleIds(discordId)
        
        if not roleIds then
            print('FAILED to get roles: ' .. tostring(err))
            return
        end
        
        local perms, groups = PermsModule.BuildPermissionsForRoleIds(roleIds)
        
        PermsModule.RemoveFromPlayer(targetSource)
        PermsModule.AssignToPlayer(targetSource, perms, groups)
        
        print('SUCCESS: Assigned ' .. #groups .. ' groups')
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

-- ESSENTIAL COMMANDS (Always available)

RegisterCommand('lonex_discord_perms', function(source, args)
    local targetSource = tonumber(args[1])
    
    if source ~= 0 and not targetSource then
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

RegisterCommand('lonex_discord_syncperms', function(source, args)
    local targetSource = tonumber(args[1])
    
    if source ~= 0 and not targetSource then
        targetSource = source
    end
    
    local PermsModule = LonexDiscord.Permissions
    
    if not PermsModule then
        print('ERROR: Permissions module not loaded!')
        return
    end
    
    if targetSource then
        print('Syncing permissions for player ' .. targetSource .. '...')
        local success, err = PermsModule.SyncPlayer(targetSource)
        if success then
            local groups = PermsModule.GetPlayerGroups(targetSource)
            print('SUCCESS: Groups: ' .. (groups and #groups > 0 and table.concat(groups, ', ') or 'none'))
        else
            print('FAILED: ' .. tostring(err))
        end
    elseif args[1] == 'all' then
        print('Resyncing permissions for all players...')
        PermsModule.ResyncAllPlayers()
        print('Done!')
    else
        print('Usage: lonex_discord_syncperms <player_id>')
        print('Or: lonex_discord_syncperms all')
    end
end, false)

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
    
    -- Sync permissions during connection (before vMenu loads)
    if Config.Permissions and Config.Permissions.Enabled and discordId then
        deferrals.defer()
        deferrals.update('Syncing permissions...')
        
        Wait(0) -- Yield to allow deferrals to work
        
        local success, err = Perms.SyncPlayer(source)
        if success then
            local groups = Perms.GetPlayerGroups(source)
            local playerName = name or 'Unknown'
            if groups and #groups > 0 then
                print('^2[LonexDiscord] ^0' .. playerName .. ' assigned groups: ' .. table.concat(groups, ', '))
            end
        end
        
        deferrals.done()
    end
end)

-- Player fully joined - backup sync (in case connecting sync failed)
AddEventHandler('playerJoining', function()
    local source = source
    
    if Config.Permissions and Config.Permissions.Enabled then
        -- Only sync if not already synced
        local existing = Perms.GetPlayerGroups(source)
        if not existing or #existing == 0 then
            SetTimeout(500, function()
                if GetPlayerName(source) then
                    Perms.SyncPlayer(source)
                end
            end)
        end
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

-- UNIFIED TAGS MODULE (Head Tags, Chat Tags, Voice Tags)

local TagsModule = {}
local PlayerAvailableTags = {}
local PlayerSelectedTag = {}
local PlayerTagSettings = {}

function TagsModule.GetPlayerAvailableTags(source)
    if not Config.Tags or not Config.Tags.Enabled then
        return {}
    end
    
    if PlayerAvailableTags[source] then
        return PlayerAvailableTags[source]
    end
    
    local discordId = Utils.GetDiscordIdentifier(source)
    local available = {}
    
    if Config.Tags.DefaultTag then
        table.insert(available, Config.Tags.DefaultTag)
    end
    
    if discordId then
        local roleIds, err = API.GetMemberRoleIds(discordId)
        
        if roleIds then
            local playerRoleSet = {}
            for _, roleId in ipairs(roleIds) do
                playerRoleSet[roleId] = true
            end
            
            if Config.Tags.Roles then
                for _, roleConfig in ipairs(Config.Tags.Roles) do
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

function TagsModule.GetPlayerTag(source)
    if not Config.Tags or not Config.Tags.Enabled then
        return nil
    end
    
    local available = TagsModule.GetPlayerAvailableTags(source)
    local selectedIndex = PlayerSelectedTag[source] or #available
    
    if selectedIndex > #available then selectedIndex = #available end
    if selectedIndex < 1 then selectedIndex = 1 end
    
    return available[selectedIndex] or Config.Tags.DefaultTag
end

function TagsModule.SetPlayerSelectedTag(source, index)
    local available = TagsModule.GetPlayerAvailableTags(source)
    
    if index >= 1 and index <= #available then
        PlayerSelectedTag[source] = index
        TagsModule.BroadcastPlayerTag(source)
        return true
    end
    
    return false
end

function TagsModule.GetPlayerSettings(source)
    if not PlayerTagSettings[source] then
        PlayerTagSettings[source] = {
            showOthers = Config.Tags.DefaultShowOthers ~= false,
            showOwn = Config.Tags.DefaultShowOwn ~= false,
        }
    end
    return PlayerTagSettings[source]
end

function TagsModule.SetPlayerSettings(source, settings)
    PlayerTagSettings[source] = settings
end

function TagsModule.RefreshPlayerTag(source)
    PlayerAvailableTags[source] = nil
    PlayerSelectedTag[source] = nil
    local tag = TagsModule.GetPlayerTag(source)
    TagsModule.BroadcastPlayerTag(source)
    return tag
end

function TagsModule.ClearPlayerTag(source)
    PlayerAvailableTags[source] = nil
    PlayerSelectedTag[source] = nil
    PlayerTagSettings[source] = nil
end

function TagsModule.GetAllPlayerTags()
    local tags = {}
    local players = GetPlayers()
    
    for _, playerId in ipairs(players) do
        local src = tonumber(playerId)
        local tag = TagsModule.GetPlayerTag(src)
        if tag then
            tags[src] = {
                tag = tag,
                name = GetPlayerName(src) or 'Unknown',
            }
        end
    end
    
    return tags
end

function TagsModule.BroadcastPlayerTag(source)
    local tag = TagsModule.GetPlayerTag(source)
    local name = GetPlayerName(source) or 'Unknown'
    
    TriggerClientEvent('LonexDiscord:Tags:UpdatePlayer', -1, source, {
        tag = tag,
        name = name,
    })
end

function TagsModule.SyncAllTagsToPlayer(targetSource)
    local allTags = TagsModule.GetAllPlayerTags()
    local settings = TagsModule.GetPlayerSettings(targetSource)
    local available = TagsModule.GetPlayerAvailableTags(targetSource)
    local selectedIndex = PlayerSelectedTag[targetSource] or #available
    
    TriggerClientEvent('LonexDiscord:Tags:SyncAll', targetSource, allTags, settings, available, selectedIndex)
end

function TagsModule.GetChatPrefix(source)
    local tag = TagsModule.GetPlayerTag(source)
    if tag and tag.chatColor then
        return tag.chatColor .. '[' .. tag.text .. '] '
    end
    return ''
end

AddEventHandler('playerDropped', function()
    local source = source
    TagsModule.ClearPlayerTag(source)
    TriggerClientEvent('LonexDiscord:Tags:PlayerLeft', -1, source)
end)

AddEventHandler('playerJoining', function()
    local source = source
    
    if not Config.Tags or not Config.Tags.Enabled then
        return
    end
    
    SetTimeout(3000, function()
        TagsModule.BroadcastPlayerTag(source)
        TagsModule.SyncAllTagsToPlayer(source)
    end)
end)

AddEventHandler('chatMessage', function(source, name, message)
    if not Config.Tags or not Config.Tags.Enabled then return end
    if not Config.Tags.ChatTags or not Config.Tags.ChatTags.Enabled then return end
    
    local prefix = TagsModule.GetChatPrefix(source)
    
    if prefix and prefix ~= '' then
        CancelEvent()
        TriggerClientEvent('chat:addMessage', -1, {
            args = { prefix .. name, message },
            color = { 255, 255, 255 }
        })
    end
end)

RegisterCommand(Config.Tags and Config.Tags.MenuCommand or 'tags', function(source, args)
    if source == 0 then return end
    if not Config.Tags or not Config.Tags.Enabled then return end
    
    local available = TagsModule.GetPlayerAvailableTags(source)
    local selectedIndex = PlayerSelectedTag[source] or #available
    local settings = TagsModule.GetPlayerSettings(source)
    
    TriggerClientEvent('LonexDiscord:Tags:OpenMenu', source, available, selectedIndex, settings)
end, false)

RegisterNetEvent('LonexDiscord:Tags:RequestSync')
AddEventHandler('LonexDiscord:Tags:RequestSync', function()
    local source = source
    TagsModule.SyncAllTagsToPlayer(source)
end)

RegisterNetEvent('LonexDiscord:Tags:SelectTag')
AddEventHandler('LonexDiscord:Tags:SelectTag', function(index)
    local source = source
    if type(index) ~= 'number' then return end
    TagsModule.SetPlayerSelectedTag(source, index)
end)

RegisterNetEvent('LonexDiscord:Tags:UpdateSettings')
AddEventHandler('LonexDiscord:Tags:UpdateSettings', function(settings)
    local source = source
    if type(settings) ~= 'table' then return end
    
    local currentSettings = TagsModule.GetPlayerSettings(source)
    
    if settings.showOthers ~= nil then
        currentSettings.showOthers = settings.showOthers == true
    end
    if settings.showOwn ~= nil then
        currentSettings.showOwn = settings.showOwn == true
    end
    
    TagsModule.SetPlayerSettings(source, currentSettings)
end)

exports('GetPlayerTag', function(source)
    return TagsModule.GetPlayerTag(source)
end)

exports('GetPlayerAvailableTags', function(source)
    return TagsModule.GetPlayerAvailableTags(source)
end)

exports('GetPlayerTagSettings', function(source)
    return TagsModule.GetPlayerSettings(source)
end)

exports('SetPlayerTagSettings', function(source, settings)
    TagsModule.SetPlayerSettings(source, settings)
end)

exports('SetPlayerSelectedTag', function(source, index)
    return TagsModule.SetPlayerSelectedTag(source, index)
end)

exports('RefreshPlayerTag', function(source)
    return TagsModule.RefreshPlayerTag(source)
end)

exports('GetAllTags', function()
    return TagsModule.GetAllPlayerTags()
end)

exports('GetChatPrefix', function(source)
    return TagsModule.GetChatPrefix(source)
end)

LonexDiscord.Tags = TagsModule

-- ============================================================================
-- EMERGENCY CALLS MODULE (911/311 System)
-- ============================================================================

local EmergencyModule = {}

-- Active calls storage: [callId] = { type, source, coords, street, message, time }
local ActiveCalls = {}
local CallIdCounter = 0
local PlayerCooldowns = {} -- [source] = { [type] = timestamp }
local PlayerDutyStatus = {} -- [source] = boolean

-- Call expiry time (seconds) - calls older than this can't be responded to
local CALL_EXPIRY = 600 -- 10 minutes

---Generate a new call ID
local function GenerateCallId()
    CallIdCounter = CallIdCounter + 1
    return CallIdCounter
end

---Check if player is on duty
local function IsOnDuty(source)
    local dutyConfig = Config.EmergencyCalls.Duty
    
    -- If duty system is disabled, everyone is considered on duty
    if not dutyConfig or not dutyConfig.Enabled then
        return true
    end
    
    -- Check player's duty status
    if PlayerDutyStatus[source] == nil then
        -- Default status
        return dutyConfig.DefaultOnDuty == true
    end
    
    return PlayerDutyStatus[source] == true
end

---Set player duty status
local function SetDutyStatus(source, onDuty)
    PlayerDutyStatus[source] = onDuty
end

---Toggle player duty status
local function ToggleDuty(source)
    local currentStatus = IsOnDuty(source)
    
    -- If duty system disabled, they're always on duty
    if not Config.EmergencyCalls.Duty or not Config.EmergencyCalls.Duty.Enabled then
        return true, 'Duty system is not enabled.'
    end
    
    local newStatus = not currentStatus
    SetDutyStatus(source, newStatus)
    
    local messages = Config.EmergencyCalls.Duty.Messages
    if newStatus then
        return true, messages.OnDuty
    else
        return false, messages.OffDuty
    end
end

---Check if player has any of the responder roles for a call type
local function HasResponderRole(source, callType)
    local typeConfig = Config.EmergencyCalls.Types[callType]
    if not typeConfig or not typeConfig.ResponderRoles then
        return false
    end
    
    -- If no roles configured, everyone can respond
    if #typeConfig.ResponderRoles == 0 then
        return true
    end
    
    local playerRoles = exports.LonexDiscordAPI:GetDiscordRoleIds(source)
    if not playerRoles then return false end
    
    -- Check if player has any responder role
    for _, responderRoleId in ipairs(typeConfig.ResponderRoles) do
        for _, playerRoleId in ipairs(playerRoles) do
            if tostring(playerRoleId) == tostring(responderRoleId) then
                return true
            end
        end
    end
    
    return false
end

---Check if player can receive/respond to calls (has role AND on duty)
local function IsResponder(source, callType)
    -- Must have responder role
    if not HasResponderRole(source, callType) then
        return false
    end
    
    -- Must be on duty (if duty system enabled)
    if not IsOnDuty(source) then
        return false
    end
    
    return true
end

---Check if player is on cooldown for a call type
local function IsOnCooldown(source, callType)
    if not PlayerCooldowns[source] then return false end
    if not PlayerCooldowns[source][callType] then return false end
    
    local cooldownTime = Config.EmergencyCalls.Cooldown or 60
    local elapsed = os.time() - PlayerCooldowns[source][callType]
    
    return elapsed < cooldownTime
end

---Set cooldown for player
local function SetCooldown(source, callType)
    if not PlayerCooldowns[source] then
        PlayerCooldowns[source] = {}
    end
    PlayerCooldowns[source][callType] = os.time()
end

---Clean up expired calls
local function CleanupExpiredCalls()
    local now = os.time()
    for callId, call in pairs(ActiveCalls) do
        if now - call.time > CALL_EXPIRY then
            ActiveCalls[callId] = nil
        end
    end
end

---Send call to Discord channel
local function SendToDiscord(callType, callId, playerName, message, street, coords)
    local typeConfig = Config.EmergencyCalls.Types[callType]
    if not typeConfig or not typeConfig.ChannelId or typeConfig.ChannelId == '' then
        if Config.Debug then
            print('^3[LonexDiscord] Emergency call channel not configured for: ' .. callType .. '^0')
        end
        return
    end
    
    local embed = {
        title = typeConfig.Label .. ' - Call #' .. callId,
        color = typeConfig.Color or 0xFF0000,
        fields = {
            { name = 'Caller', value = playerName, inline = true },
            { name = 'Call ID', value = '#' .. callId, inline = true },
            { name = 'Location', value = street or 'Unknown', inline = false },
            { name = 'Details', value = message or 'No details provided', inline = false },
        },
        footer = {
            text = 'Use /resp ' .. callId .. ' in-game to respond',
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    }
    
    if coords then
        table.insert(embed.fields, 3, {
            name = 'Coordinates',
            value = string.format('X: %.2f, Y: %.2f, Z: %.2f', coords.x, coords.y, coords.z),
            inline = false,
        })
    end
    
    -- Send via Discord API
    local channelId = typeConfig.ChannelId
    local response = LonexDiscord.Http.Post('/channels/' .. channelId .. '/messages', {
        embeds = { embed }
    })
    
    if not response.success and Config.Debug then
        print('^1[LonexDiscord] Failed to send emergency call to Discord: ' .. (response.error or 'Unknown error') .. '^0')
    end
end

---Notify all responders in-game
local function NotifyResponders(callType, callId, callerName, message, street)
    local typeConfig = Config.EmergencyCalls.Types[callType]
    if not typeConfig then return end
    
    local prefix = typeConfig.Prefix or ('^1[' .. callType .. ']^0')
    local notification = string.format(
        '%s ^3Call #%d^0 from ^5%s^0 at ^3%s^0: ^7%s',
        prefix, callId, callerName, street or 'Unknown', message
    )
    
    -- Send to all players who are responders
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if IsResponder(src, callType) then
            TriggerClientEvent('chat:addMessage', src, {
                args = { notification },
                color = { 255, 255, 255 },
            })
            TriggerClientEvent('LonexDiscord:EmergencyCall:Notify', src, callType, callId)
        end
    end
end

---Create an emergency call
function EmergencyModule.CreateCall(source, callType, message, coords, street)
    local typeConfig = Config.EmergencyCalls.Types[callType]
    if not typeConfig or not typeConfig.Enabled then
        return nil, 'Call type not enabled'
    end
    
    -- Check cooldown
    if IsOnCooldown(source, callType) then
        return nil, typeConfig.Messages.Cooldown
    end
    
    -- Generate call ID
    local callId = GenerateCallId()
    local playerName = GetPlayerName(source) or 'Unknown'
    
    -- Store the call
    ActiveCalls[callId] = {
        id = callId,
        type = callType,
        source = source,
        playerName = playerName,
        message = message,
        coords = coords,
        street = street,
        time = os.time(),
    }
    
    -- Set cooldown
    SetCooldown(source, callType)
    
    -- Send to Discord
    SendToDiscord(callType, callId, playerName, message, street, coords)
    
    -- Notify responders in-game
    NotifyResponders(callType, callId, playerName, message, street)
    
    -- Cleanup old calls periodically
    CleanupExpiredCalls()
    
    return callId, typeConfig.Messages.Sent
end

---Respond to a call (get location)
function EmergencyModule.RespondToCall(source, callId)
    local call = ActiveCalls[tonumber(callId)]
    if not call then
        return nil, Config.EmergencyCalls.Response.Messages.InvalidCall
    end
    
    -- Check if responder has the role
    if not HasResponderRole(source, call.type) then
        return nil, Config.EmergencyCalls.Response.Messages.NoPermission
    end
    
    -- Check if responder is on duty
    if not IsOnDuty(source) then
        local dutyConfig = Config.EmergencyCalls.Duty
        if dutyConfig and dutyConfig.Messages and dutyConfig.Messages.MustBeOnDuty then
            return nil, dutyConfig.Messages.MustBeOnDuty
        end
        return nil, Config.EmergencyCalls.Response.Messages.NoPermission
    end
    
    -- Return call data for waypoint
    return call, string.format(Config.EmergencyCalls.Response.Messages.Responding, callId)
end

---Get active calls for a responder
function EmergencyModule.GetActiveCalls(source)
    local calls = {}
    CleanupExpiredCalls()
    
    for callId, call in pairs(ActiveCalls) do
        -- Check if player can see this call type
        if IsResponder(source, call.type) then
            table.insert(calls, {
                id = call.id,
                type = call.type,
                playerName = call.playerName,
                street = call.street,
                message = call.message,
                time = call.time,
            })
        end
    end
    
    -- Sort by time (newest first)
    table.sort(calls, function(a, b) return a.time > b.time end)
    
    return calls
end

-- Register commands for each call type
CreateThread(function()
    Wait(1000)
    
    if not Config.EmergencyCalls or not Config.EmergencyCalls.Enabled then
        return
    end
    
    -- Register call commands (911, 311, etc.)
    for callType, typeConfig in pairs(Config.EmergencyCalls.Types) do
        if typeConfig.Enabled and typeConfig.Command then
            RegisterCommand(typeConfig.Command, function(source, args)
                if source == 0 then return end
                
                local message = table.concat(args, ' ')
                if message == '' then
                    TriggerClientEvent('chat:addMessage', source, {
                        args = { typeConfig.Messages.NoMessage },
                    })
                    return
                end
                
                -- Request location from client
                TriggerClientEvent('LonexDiscord:EmergencyCall:GetLocation', source, callType, message)
            end, false)
            
            if Config.Debug then
                print('[LonexDiscord] Registered emergency command: /' .. typeConfig.Command)
            end
        end
    end
    
    -- Register response command
    local respConfig = Config.EmergencyCalls.Response
    if respConfig and respConfig.Command then
        RegisterCommand(respConfig.Command, function(source, args)
            if source == 0 then return end
            
            local callId = args[1]
            if not callId then
                TriggerClientEvent('chat:addMessage', source, {
                    args = { '^1Usage: /' .. respConfig.Command .. ' <call_id>' },
                })
                return
            end
            
            local call, msg = EmergencyModule.RespondToCall(source, callId)
            
            TriggerClientEvent('chat:addMessage', source, {
                args = { msg },
            })
            
            if call and call.coords then
                TriggerClientEvent('LonexDiscord:EmergencyCall:SetWaypoint', source, call.coords)
            end
        end, false)
        
        if Config.Debug then
            print('[LonexDiscord] Registered response command: /' .. respConfig.Command)
        end
    end
    
    -- Register duty command
    local dutyConfig = Config.EmergencyCalls.Duty
    if dutyConfig and dutyConfig.Enabled and dutyConfig.Command then
        RegisterCommand(dutyConfig.Command, function(source, args)
            if source == 0 then return end
            
            -- Check if player has any responder role for any call type
            local hasAnyRole = false
            for callType, _ in pairs(Config.EmergencyCalls.Types) do
                if HasResponderRole(source, callType) then
                    hasAnyRole = true
                    break
                end
            end
            
            if not hasAnyRole then
                TriggerClientEvent('chat:addMessage', source, {
                    args = { '^1You do not have permission to use the duty system.' },
                })
                return
            end
            
            local newStatus, msg = ToggleDuty(source)
            
            TriggerClientEvent('chat:addMessage', source, {
                args = { msg },
            })
            
            -- Notify client of duty status change
            TriggerClientEvent('LonexDiscord:EmergencyCall:DutyChanged', source, newStatus)
        end, false)
        
        if Config.Debug then
            print('[LonexDiscord] Registered duty command: /' .. dutyConfig.Command)
        end
    end
    
    print('^2[LonexDiscord] ^0Emergency Calls system loaded')
end)

-- Event: Receive location from client and create call
RegisterNetEvent('LonexDiscord:EmergencyCall:Submit')
AddEventHandler('LonexDiscord:EmergencyCall:Submit', function(callType, message, coords, street)
    local source = source
    
    local callId, msg = EmergencyModule.CreateCall(source, callType, message, coords, street)
    
    TriggerClientEvent('chat:addMessage', source, {
        args = { msg },
    })
end)

-- Cleanup on player disconnect
AddEventHandler('playerDropped', function()
    local source = source
    PlayerCooldowns[source] = nil
    PlayerDutyStatus[source] = nil
end)

-- Exports
exports('CreateEmergencyCall', function(source, callType, message, coords, street)
    return EmergencyModule.CreateCall(source, callType, message, coords, street)
end)

exports('GetActiveCalls', function(source)
    return EmergencyModule.GetActiveCalls(source)
end)

exports('RespondToCall', function(source, callId)
    return EmergencyModule.RespondToCall(source, callId)
end)

exports('IsEmergencyResponder', function(source, callType)
    return IsResponder(source, callType)
end)

exports('HasEmergencyResponderRole', function(source, callType)
    return HasResponderRole(source, callType)
end)

exports('IsOnDuty', function(source)
    return IsOnDuty(source)
end)

exports('SetDutyStatus', function(source, onDuty)
    SetDutyStatus(source, onDuty)
end)

exports('ToggleDuty', function(source)
    return ToggleDuty(source)
end)

LonexDiscord.EmergencyCalls = EmergencyModule

-- ============================================================================
-- SERVER UTILITIES MODULE (AOP, PeaceTime, Announcements, Postals)
-- ============================================================================

local ServerUtilsModule = {}

-- State
local CurrentAOP = nil
local PeaceTimeEnabled = nil

---Check if player has any of the allowed roles
local function HasUtilityPermission(source, allowedRoles)
    -- If no roles configured, everyone has permission
    if not allowedRoles or #allowedRoles == 0 then
        return true
    end
    
    local playerRoles = exports.LonexDiscordAPI:GetDiscordRoleIds(source)
    if not playerRoles then return false end
    
    for _, allowedRoleId in ipairs(allowedRoles) do
        for _, playerRoleId in ipairs(playerRoles) do
            if tostring(playerRoleId) == tostring(allowedRoleId) then
                return true
            end
        end
    end
    
    return false
end

---Get current AOP
function ServerUtilsModule.GetAOP()
    return CurrentAOP
end

---Set AOP
function ServerUtilsModule.SetAOP(newAOP, sourceId)
    local oldAOP = CurrentAOP
    CurrentAOP = newAOP
    
    -- Notify all clients
    TriggerClientEvent('LonexDiscord:AOP:Changed', -1, newAOP)
    
    -- Trigger event for integrations
    TriggerEvent('LonexDiscord:AOPChange', oldAOP, newAOP, sourceId)
    
    return true
end

---Get PeaceTime status
function ServerUtilsModule.GetPeaceTime()
    return PeaceTimeEnabled
end

---Set PeaceTime status
function ServerUtilsModule.SetPeaceTime(enabled, sourceId)
    PeaceTimeEnabled = enabled
    
    -- Notify all clients
    TriggerClientEvent('LonexDiscord:PeaceTime:Changed', -1, enabled)
    
    -- Trigger event for integrations
    TriggerEvent('LonexDiscord:PeaceTimeChange', enabled, sourceId)
    
    return true
end

---Send announcement to all players
function ServerUtilsModule.Announce(message, sourceId)
    local config = Config.Announcements
    
    TriggerClientEvent('LonexDiscord:Announcement:Show', -1, {
        message = message,
        header = config and config.Header or '~b~[~p~Announcement~b~]',
        duration = config and config.Duration or 10,
        position = config and config.Position or 0.3,
    })
    
    -- Trigger event for integrations
    TriggerEvent('LonexDiscord:Announcement', message, sourceId)
    
    return true
end

-- Initialize and register commands
CreateThread(function()
    Wait(1000)
    
    local anyEnabled = false
    
    -- Initialize AOP
    if Config.AOP and Config.AOP.Enabled then
        anyEnabled = true
        CurrentAOP = Config.AOP.Default or 'All of San Andreas'
        
        RegisterCommand(Config.AOP.Command or 'aop', function(source, args)
            if source == 0 then
                local newAOP = table.concat(args, ' ')
                if newAOP == '' then
                    print('[LonexDiscord] Current AOP: ' .. (CurrentAOP or 'Not set'))
                    return
                end
                ServerUtilsModule.SetAOP(newAOP, 0)
                print('[LonexDiscord] AOP changed to: ' .. newAOP)
                return
            end
            
            if not HasUtilityPermission(source, Config.AOP.AllowedRoles) then
                TriggerClientEvent('chat:addMessage', source, {
                    args = { Config.AOP.Messages.NoPermission },
                })
                return
            end
            
            local newAOP = table.concat(args, ' ')
            if newAOP == '' then
                TriggerClientEvent('chat:addMessage', source, {
                    args = { Config.AOP.Messages.Usage },
                })
                return
            end
            
            ServerUtilsModule.SetAOP(newAOP, source)
            
            local msg = string.format(Config.AOP.Messages.Changed, newAOP)
            TriggerClientEvent('chat:addMessage', -1, {
                args = { msg },
            })
        end, false)
        
        if Config.Debug then
            print('[LonexDiscord] Registered AOP command: /' .. (Config.AOP.Command or 'aop'))
        end
    end
    
    -- Initialize PeaceTime
    if Config.PeaceTime and Config.PeaceTime.Enabled then
        anyEnabled = true
        PeaceTimeEnabled = Config.PeaceTime.Default or false
        
        for _, cmd in ipairs(Config.PeaceTime.Commands or { 'peacetime', 'pt' }) do
            RegisterCommand(cmd, function(source)
                if source == 0 then
                    PeaceTimeEnabled = not PeaceTimeEnabled
                    ServerUtilsModule.SetPeaceTime(PeaceTimeEnabled, 0)
                    print('[LonexDiscord] PeaceTime: ' .. (PeaceTimeEnabled and 'ENABLED' or 'DISABLED'))
                    return
                end
                
                if not HasUtilityPermission(source, Config.PeaceTime.AllowedRoles) then
                    TriggerClientEvent('chat:addMessage', source, {
                        args = { Config.PeaceTime.Messages.NoPermission },
                    })
                    return
                end
                
                PeaceTimeEnabled = not PeaceTimeEnabled
                ServerUtilsModule.SetPeaceTime(PeaceTimeEnabled, source)
                
                local msg = PeaceTimeEnabled and Config.PeaceTime.Messages.Enabled or Config.PeaceTime.Messages.Disabled
                TriggerClientEvent('chat:addMessage', -1, {
                    args = { msg },
                })
            end, false)
        end
        
        if Config.Debug then
            print('[LonexDiscord] Registered PeaceTime commands: /' .. table.concat(Config.PeaceTime.Commands or { 'peacetime', 'pt' }, ', /'))
        end
    end
    
    -- Initialize Announcements
    if Config.Announcements and Config.Announcements.Enabled then
        anyEnabled = true
        
        RegisterCommand(Config.Announcements.Command or 'announce', function(source, args)
            if source == 0 then
                local message = table.concat(args, ' ')
                if message == '' then
                    print('[LonexDiscord] Usage: announce <message>')
                    return
                end
                ServerUtilsModule.Announce(message, 0)
                print('[LonexDiscord] Announcement sent: ' .. message)
                return
            end
            
            if not HasUtilityPermission(source, Config.Announcements.AllowedRoles) then
                TriggerClientEvent('chat:addMessage', source, {
                    args = { Config.Announcements.Messages.NoPermission },
                })
                return
            end
            
            local message = table.concat(args, ' ')
            if message == '' then
                TriggerClientEvent('chat:addMessage', source, {
                    args = { Config.Announcements.Messages.Usage },
                })
                return
            end
            
            ServerUtilsModule.Announce(message, source)
            
            TriggerClientEvent('chat:addMessage', source, {
                args = { Config.Announcements.Messages.Sent },
            })
        end, false)
        
        if Config.Debug then
            print('[LonexDiscord] Registered announcement command: /' .. (Config.Announcements.Command or 'announce'))
        end
    end
    
    -- Initialize Postals
    if Config.Postals and Config.Postals.Enabled then
        anyEnabled = true
        
        RegisterCommand(Config.Postals.Command or 'postal', function(source, args)
            if source == 0 then return end
            
            local code = args[1]
            
            if not code or code == '' then
                TriggerClientEvent('LonexDiscord:Postal:Cancel', source)
                TriggerClientEvent('chat:addMessage', source, {
                    args = { Config.Postals.Messages.Cancelled },
                })
                return
            end
            
            local found = nil
            if Postals then
                for _, postal in ipairs(Postals) do
                    if tostring(postal.code) == tostring(code) then
                        found = postal
                        break
                    end
                end
            end
            
            if found then
                TriggerClientEvent('LonexDiscord:Postal:Set', source, found)
                TriggerClientEvent('chat:addMessage', source, {
                    args = { string.format(Config.Postals.Messages.Set, code) },
                })
            else
                TriggerClientEvent('chat:addMessage', source, {
                    args = { string.format(Config.Postals.Messages.NotFound, code) },
                })
            end
        end, false)
        
        if Config.Debug then
            print('[LonexDiscord] Registered postal command: /' .. (Config.Postals.Command or 'postal'))
        end
    end
    
    if anyEnabled then
        print('^2[LonexDiscord] ^0Server utilities loaded (AOP/PeaceTime/Announcements/Postals)')
    end
end)

-- Sync state to joining players
RegisterNetEvent('LonexDiscord:Utils:RequestState')
AddEventHandler('LonexDiscord:Utils:RequestState', function()
    local source = source
    
    TriggerClientEvent('LonexDiscord:Utils:SyncState', source, {
        aop = CurrentAOP,
        peacetime = PeaceTimeEnabled,
    })
end)

-- Exports
exports('GetAOP', function()
    return ServerUtilsModule.GetAOP()
end)

exports('SetAOP', function(newAOP, sourceId)
    return ServerUtilsModule.SetAOP(newAOP, sourceId or 0)
end)

exports('GetPeaceTime', function()
    return ServerUtilsModule.GetPeaceTime()
end)

exports('SetPeaceTime', function(enabled, sourceId)
    return ServerUtilsModule.SetPeaceTime(enabled, sourceId or 0)
end)

exports('Announce', function(message, sourceId)
    return ServerUtilsModule.Announce(message, sourceId or 0)
end)

LonexDiscord.ServerUtils = ServerUtilsModule

-- ============================================================================
-- VEHICLE MANAGEMENT & MODERATION COMMANDS
-- ============================================================================

local ModerationModule = {}
local DVAllInProgress = false

-- Helper to check if player has allowed role
local function HasAllowedRole(source, allowedRoles)
    if not allowedRoles or #allowedRoles == 0 then
        return true -- Empty = everyone allowed
    end
    
    local discordId = LonexDiscord.Utils.GetDiscordIdentifier(source)
    if not discordId then
        return false
    end
    
    local roleIds, err = LonexDiscord.API.GetMemberRoleIds(discordId)
    if not roleIds then
        return false
    end
    
    for _, allowedRole in ipairs(allowedRoles) do
        for _, playerRole in ipairs(roleIds) do
            if allowedRole == playerRole then
                return true
            end
        end
    end
    
    return false
end

-- Delete Vehicle command
CreateThread(function()
    Wait(1000)
    
    if Config.DeleteVehicle and Config.DeleteVehicle.Enabled then
        RegisterCommand(Config.DeleteVehicle.Command or 'dv', function(source, args)
            if source == 0 then return end
            
            -- Check permission
            if not HasAllowedRole(source, Config.DeleteVehicle.AllowedRoles) then
                TriggerClientEvent('chat:addMessage', source, {
                    args = { Config.DeleteVehicle.Messages.NoPermission },
                })
                return
            end
            
            -- Tell client to delete nearby vehicle
            TriggerClientEvent('LonexDiscord:DeleteVehicle', source, Config.DeleteVehicle.SearchRadius or 5.0)
        end, false)
        
        print('^2[LonexDiscord] ^0Registered command: /' .. (Config.DeleteVehicle.Command or 'dv'))
    end
    
    -- Delete All Vehicles command
    if Config.DeleteAllVehicles and Config.DeleteAllVehicles.Enabled then
        RegisterCommand(Config.DeleteAllVehicles.Command or 'dvall', function(source, args)
            if source == 0 then return end
            
            -- Check permission
            if not HasAllowedRole(source, Config.DeleteAllVehicles.AllowedRoles) then
                TriggerClientEvent('chat:addMessage', source, {
                    args = { Config.DeleteAllVehicles.Messages.NoPermission },
                })
                return
            end
            
            -- Check if already running
            if DVAllInProgress then
                TriggerClientEvent('chat:addMessage', source, {
                    args = { Config.DeleteAllVehicles.Messages.AlreadyRunning },
                })
                return
            end
            
            DVAllInProgress = true
            local countdown = Config.DeleteAllVehicles.Countdown or 20
            
            -- Announce starting
            TriggerClientEvent('chat:addMessage', -1, {
                args = { string.format(Config.DeleteAllVehicles.Messages.Starting, countdown) },
            })
            
            -- Countdown warnings at 10, 5, 3, 2, 1
            local warnings = { 10, 5, 3, 2, 1 }
            
            CreateThread(function()
                local remaining = countdown
                
                while remaining > 0 do
                    Wait(1000)
                    remaining = remaining - 1
                    
                    for _, warn in ipairs(warnings) do
                        if remaining == warn then
                            TriggerClientEvent('chat:addMessage', -1, {
                                args = { string.format(Config.DeleteAllVehicles.Messages.Countdown, remaining) },
                            })
                            break
                        end
                    end
                end
                
                -- Set up response tracking
                local players = GetPlayers()
                dvallExpectedResponses = #players
                dvallDeletedCount = 0
                dvallResponseCount = 0
                
                -- Tell all clients to delete unoccupied vehicles and report count
                TriggerClientEvent('LonexDiscord:DeleteAllVehicles', -1, Config.DeleteAllVehicles.OnlyUnoccupied ~= false)
                DVAllInProgress = false
            end)
        end, false)
        
        print('^2[LonexDiscord] ^0Registered command: /' .. (Config.DeleteAllVehicles.Command or 'dvall'))
    end
    
    -- Clear Chat command
    if Config.ClearChat and Config.ClearChat.Enabled then
        RegisterCommand(Config.ClearChat.Command or 'clearchat', function(source, args)
            if source == 0 then return end
            
            -- Check permission
            if not HasAllowedRole(source, Config.ClearChat.AllowedRoles) then
                TriggerClientEvent('chat:addMessage', source, {
                    args = { Config.ClearChat.Messages.NoPermission },
                })
                return
            end
            
            -- Clear chat using the built-in chat:clear event
            TriggerClientEvent('chat:clear', -1)
            
            -- Show cleared by message
            if Config.ClearChat.ShowClearedBy then
                local playerName = GetPlayerName(source) or 'Unknown'
                TriggerClientEvent('chat:addMessage', -1, {
                    args = { string.format(Config.ClearChat.Messages.Cleared, playerName) },
                })
            end
        end, false)
        
        print('^2[LonexDiscord] ^0Registered command: /' .. (Config.ClearChat.Command or 'clearchat'))
    end
end)

-- Event handler for vehicle deletion results
RegisterNetEvent('LonexDiscord:DeleteVehicle:Result')
AddEventHandler('LonexDiscord:DeleteVehicle:Result', function(success)
    local source = source
    
    if success then
        TriggerClientEvent('chat:addMessage', source, {
            args = { Config.DeleteVehicle.Messages.Deleted },
        })
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = { Config.DeleteVehicle.Messages.NotFound },
        })
    end
end)

-- Event handler for dvall results (aggregate count from all clients)
local dvallDeletedCount = 0
local dvallResponseCount = 0
local dvallExpectedResponses = 0

RegisterNetEvent('LonexDiscord:DeleteAllVehicles:Result')
AddEventHandler('LonexDiscord:DeleteAllVehicles:Result', function(count)
    dvallDeletedCount = dvallDeletedCount + (count or 0)
    dvallResponseCount = dvallResponseCount + 1
    
    -- When all clients have responded (or after timeout), announce the total
    if dvallResponseCount >= dvallExpectedResponses and dvallExpectedResponses > 0 then
        TriggerClientEvent('chat:addMessage', -1, {
            args = { string.format(Config.DeleteAllVehicles.Messages.Deleted, dvallDeletedCount) },
        })
        
        -- Reset counters
        dvallDeletedCount = 0
        dvallResponseCount = 0
        dvallExpectedResponses = 0
    end
end)

-- Fallback: if not all clients respond within 5 seconds, announce anyway
CreateThread(function()
    while true do
        Wait(5000)
        if dvallExpectedResponses > 0 and dvallResponseCount > 0 then
            -- Force announce if we've been waiting
            TriggerClientEvent('chat:addMessage', -1, {
                args = { string.format(Config.DeleteAllVehicles.Messages.Deleted, dvallDeletedCount) },
            })
            dvallDeletedCount = 0
            dvallResponseCount = 0
            dvallExpectedResponses = 0
        end
    end
end)

LonexDiscord.Moderation = ModerationModule
