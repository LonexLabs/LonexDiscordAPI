--[[
    LonexDiscordAPI - Discord API Methods
    https://github.com/LonexLabs/LonexDiscordAPI
]]

LonexDiscord = LonexDiscord or {}
LonexDiscord.API = {}

local API = LonexDiscord.API

local function Http() return LonexDiscord.Http end
local function Cache() return LonexDiscord.Cache end
local function Utils() return LonexDiscord.Utils end

---Fetch a Discord user by ID
---@param userId string Discord user ID
---@param useCache? boolean Whether to check cache first (default true)
---@return table|nil userData
---@return string|nil error
function API.GetUser(userId, useCache)
    if useCache == nil then useCache = true end
    
    userId = Utils().ToSnowflake(userId)
    
    -- Check cache first
    if useCache then
        local cached = Cache().GetUser(userId)
        if cached then
            return cached, nil
        end
    end
    
    -- Fetch from Discord
    local response = Http().Get(string.format('/users/%s', userId))
    
    if response.success and response.data then
        local user = {
            id = response.data.id,
            username = response.data.username,
            discriminator = response.data.discriminator or '0',
            globalName = response.data.global_name,
            avatar = response.data.avatar,
            bot = response.data.bot or false,
            system = response.data.system or false,
            banner = response.data.banner,
            accentColor = response.data.accent_color
        }
        
        -- Cache it
        Cache().SetUser(userId, user)
        
        return user, nil
    else
        return nil, response.error or 'Failed to fetch user'
    end
end

---Fetch a guild member by Discord ID
---@param userId string Discord user ID
---@param useCache? boolean Whether to check cache first (default true)
---@return table|nil memberData
---@return string|nil error
function API.GetMember(userId, useCache)
    if useCache == nil then useCache = true end
    
    userId = Utils().ToSnowflake(userId)
    
    -- Check cache first
    if useCache then
        local cached = Cache().GetMember(userId)
        if cached then
            return cached, nil
        end
    end
    
    -- Fetch from Discord
    local response = Http().Get(string.format('/guilds/%s/members/%s', Config.GuildId, userId))
    
    if response.success and response.data then
        local data = response.data
        
        local member = {
            -- User data (nested)
            user = {
                id = data.user.id,
                username = data.user.username,
                discriminator = data.user.discriminator or '0',
                globalName = data.user.global_name,
                avatar = data.user.avatar,
                bot = data.user.bot or false
            },
            -- Member-specific data
            nickname = data.nick,
            roles = data.roles or {},
            joinedAt = data.joined_at,
            premiumSince = data.premium_since,
            deaf = data.deaf or false,
            mute = data.mute or false,
            pending = data.pending or false,
            avatar = data.avatar, -- Guild-specific avatar
            communicationDisabledUntil = data.communication_disabled_until
        }
        
        -- Cache it
        Cache().SetMember(userId, member)
        
        -- Also cache the user data separately
        Cache().SetUser(userId, member.user)
        
        return member, nil
    else
        -- Handle specific error codes
        if response.status == 404 then
            return nil, 'Member not found in guild'
        end
        return nil, response.error or 'Failed to fetch member'
    end
end

---Fetch a guild member by player source
---@param source number FiveM player source
---@param useCache? boolean Whether to check cache first (default true)
---@return table|nil memberData
---@return string|nil error
function API.GetMemberBySource(source, useCache)
    local discordId = Utils().GetDiscordIdentifier(source)
    
    if not discordId then
        return nil, 'Player has no Discord identifier'
    end
    
    return API.GetMember(discordId, useCache)
end

---Check if a user is a member of the guild
---@param userId string Discord user ID
---@return boolean
function API.IsMemberOfGuild(userId)
    local member, err = API.GetMember(userId, true)
    return member ~= nil
end

---Get a member's roles as full role objects
---@param userId string Discord user ID
---@return table|nil roles Array of role objects
---@return string|nil error
function API.GetMemberRoles(userId)
    local member, err = API.GetMember(userId, true)
    
    if not member then
        return nil, err
    end
    
    local cachedRoles = Cache().GetRoles()
    if not cachedRoles then
        return nil, 'Roles not cached'
    end
    
    -- Map role IDs to full role objects
    local roles = {}
    for _, roleId in ipairs(member.roles) do
        for _, cachedRole in ipairs(cachedRoles) do
            if cachedRole.id == roleId then
                table.insert(roles, cachedRole)
                break
            end
        end
    end
    
    -- Sort by position (highest first)
    table.sort(roles, function(a, b)
        return a.position > b.position
    end)
    
    return roles, nil
end

---Get a member's role IDs
---@param userId string Discord user ID
---@return table|nil roleIds Array of role ID strings
---@return string|nil error
function API.GetMemberRoleIds(userId)
    local member, err = API.GetMember(userId, true)
    
    if not member then
        return nil, err
    end
    
    return member.roles, nil
end

---Get a member's role names
---@param userId string Discord user ID
---@return table|nil roleNames Array of role name strings
---@return string|nil error
function API.GetMemberRoleNames(userId)
    local roles, err = API.GetMemberRoles(userId)
    
    if not roles then
        return nil, err
    end
    
    local names = {}
    for _, role in ipairs(roles) do
        table.insert(names, role.name)
    end
    
    return names, nil
end

---Check if a member has a specific role
---@param userId string Discord user ID
---@param roleId string Role ID
---@return boolean hasRole
---@return string|nil error
function API.MemberHasRole(userId, roleId)
    local member, err = API.GetMember(userId, true)
    
    if not member then
        return false, err
    end
    
    roleId = Utils().ToSnowflake(roleId)
    if not Utils().IsValidSnowflake(roleId) then
        return false, 'Invalid role ID: ' .. tostring(roleId)
    end
    
    -- Check if member has the role
    for _, memberRoleId in ipairs(member.roles) do
        if memberRoleId == roleId then
            return true, nil
        end
    end
    
    return false, nil
end

---Check if a member has any of the specified roles
---@param userId string Discord user ID
---@param roleIds table Array of role IDs
---@return boolean hasAny
---@return string|nil matchedRoleId The first matched role ID
function API.MemberHasAnyRole(userId, roleIds)
    for _, roleId in ipairs(roleIds) do
        local hasRole, err = API.MemberHasRole(userId, roleId)
        if hasRole then
            return true, roleId
        end
    end
    return false, nil
end

---Check if a member has all of the specified roles
---@param userId string Discord user ID
---@param roleIds table Array of role IDs
---@return boolean hasAll
---@return string|nil missingRoleId The first missing role ID
function API.MemberHasAllRoles(userId, roleIds)
    for _, roleId in ipairs(roleIds) do
        local hasRole, err = API.MemberHasRole(userId, roleId)
        if not hasRole then
            return false, roleId
        end
    end
    return true, nil
end

---Get a user's avatar URL
---@param userId string Discord user ID
---@param size? number Image size (default 128)
---@return string|nil avatarUrl
---@return string|nil error
function API.GetUserAvatar(userId, size)
    local user, err = API.GetUser(userId, true)
    
    if not user then
        return nil, err
    end
    
    return Utils().GetAvatarUrl(user.id, user.avatar, size), nil
end

---Get a member's guild avatar URL (falls back to user avatar)
---@param userId string Discord user ID
---@param size? number Image size (default 128)
---@return string|nil avatarUrl
---@return string|nil error
function API.GetMemberAvatar(userId, size)
    size = size or 128
    local member, err = API.GetMember(userId, true)
    
    if not member then
        return nil, err
    end
    
    -- Guild-specific avatar takes priority
    if member.avatar then
        local ext = Utils().StartsWith(member.avatar, 'a_') and 'gif' or 'png'
        return string.format('https://cdn.discordapp.com/guilds/%s/users/%s/avatars/%s.%s?size=%d',
            Config.GuildId, member.user.id, member.avatar, ext, size), nil
    end
    
    -- Fall back to user avatar
    return Utils().GetAvatarUrl(member.user.id, member.user.avatar, size), nil
end

---Get a member's display name (nickname > global name > username)
---@param userId string Discord user ID
---@return string|nil displayName
---@return string|nil error
function API.GetMemberDisplayName(userId)
    local member, err = API.GetMember(userId, true)
    
    if not member then
        return nil, err
    end
    
    -- Priority: nickname > global name > username
    return member.nickname or member.user.globalName or member.user.username, nil
end

---Get a user's username (without nickname)
---@param userId string Discord user ID
---@return string|nil username
---@return string|nil error
function API.GetUsername(userId)
    local user, err = API.GetUser(userId, true)
    
    if not user then
        return nil, err
    end
    
    return user.username, nil
end

---Prefetch member data for multiple players (useful on resource start)
---@param sources table Array of player sources
function API.PrefetchMembers(sources)
    Utils().Info('Prefetching member data for %d players...', #sources)
    
    local fetched = 0
    local failed = 0
    
    for _, source in ipairs(sources) do
        local discordId = Utils().GetDiscordIdentifier(source)
        if discordId then
            local member, err = API.GetMember(discordId, false) -- Skip cache, force fetch
            if member then
                fetched = fetched + 1
            else
                failed = failed + 1
                Utils().Debug('Failed to prefetch member %s: %s', discordId, err)
            end
        end
    end
    
    Utils().Info('Prefetch complete: %d fetched, %d failed', fetched, failed)
end

---Invalidate a member's cached data
---@param userId string Discord user ID
function API.InvalidateMember(userId)
    userId = Utils().ToSnowflake(userId)
    Cache().DeleteMember(userId)
    Utils().Debug('Invalidated cache for member: %s', userId)
end

---Add a role to a guild member
---@param userId string Discord user ID
---@param roleId string Role ID
---@param reason? string Audit log reason
---@return boolean success
---@return string|nil error
function API.AddRole(userId, roleId, reason)
    userId = Utils().ToSnowflake(userId)
    roleId = Utils().ToSnowflake(roleId)
    
    if not Utils().IsValidSnowflake(roleId) then
        return false, 'Invalid role ID: ' .. tostring(roleId)
    end
    
    -- Build headers with audit log reason
    local headers = nil
    if reason then
        headers = {
            ['X-Audit-Log-Reason'] = reason
        }
    end
    
    local endpoint = string.format('/guilds/%s/members/%s/roles/%s', 
        Config.GuildId, userId, roleId)
    
    local response = Http().Put(endpoint, nil, headers)
    
    if response.success then
        -- Invalidate cache so next fetch gets updated roles
        API.InvalidateMember(userId)
        Utils().Debug('Added role %s to user %s', roleId, userId)
        return true, nil
    else
        Utils().Warn('Failed to add role %s to user %s: %s', roleId, userId, response.error or 'Unknown error')
        return false, response.error or 'Failed to add role'
    end
end

---Remove a role from a guild member
---@param userId string Discord user ID
---@param roleId string Role ID
---@param reason? string Audit log reason
---@return boolean success
---@return string|nil error
function API.RemoveRole(userId, roleId, reason)
    userId = Utils().ToSnowflake(userId)
    roleId = Utils().ToSnowflake(roleId)
    
    if not Utils().IsValidSnowflake(roleId) then
        return false, 'Invalid role ID: ' .. tostring(roleId)
    end
    
    -- Build headers with audit log reason
    local headers = nil
    if reason then
        headers = {
            ['X-Audit-Log-Reason'] = reason
        }
    end
    
    local endpoint = string.format('/guilds/%s/members/%s/roles/%s', 
        Config.GuildId, userId, roleId)
    
    local response = Http().Delete(endpoint, headers)
    
    if response.success then
        -- Invalidate cache so next fetch gets updated roles
        API.InvalidateMember(userId)
        Utils().Debug('Removed role %s from user %s', roleId, userId)
        return true, nil
    else
        Utils().Warn('Failed to remove role %s from user %s: %s', roleId, userId, response.error or 'Unknown error')
        return false, response.error or 'Failed to remove role'
    end
end

---Set all roles for a guild member (replaces existing roles)
---@param userId string Discord user ID
---@param roleIds table Array of role IDs
---@param reason? string Audit log reason
---@return boolean success
---@return string|nil error
function API.SetRoles(userId, roleIds, reason)
    userId = Utils().ToSnowflake(userId)
    
    -- Validate all role IDs
    local validRoleIds = {}
    for _, roleId in ipairs(roleIds) do
        local resolved = Utils().ToSnowflake(roleId)
        if not Utils().IsValidSnowflake(resolved) then
            return false, 'Invalid role ID: ' .. tostring(roleId)
        end
        table.insert(validRoleIds, resolved)
    end
    
    -- Build headers with audit log reason
    local headers = nil
    if reason then
        headers = {
            ['X-Audit-Log-Reason'] = reason
        }
    end
    
    local endpoint = string.format('/guilds/%s/members/%s', Config.GuildId, userId)
    local body = {
        roles = validRoleIds
    }
    
    local response = Http().Patch(endpoint, body, headers)
    
    if response.success then
        -- Invalidate cache so next fetch gets updated roles
        API.InvalidateMember(userId)
        Utils().Debug('Set %d roles for user %s', #validRoleIds, userId)
        return true, nil
    else
        Utils().Warn('Failed to set roles for user %s: %s', userId, response.error or 'Unknown error')
        return false, response.error or 'Failed to set roles'
    end
end

---Set a guild member's nickname
---@param userId string Discord user ID
---@param nickname string|nil New nickname (nil or empty to reset)
---@param reason? string Audit log reason
---@return boolean success
---@return string|nil error
function API.SetNickname(userId, nickname, reason)
    userId = Utils().ToSnowflake(userId)
    
    -- Treat empty string as nil (reset nickname)
    if nickname == '' then
        nickname = nil
    end
    
    -- Build headers with audit log reason
    local headers = nil
    if reason then
        headers = {
            ['X-Audit-Log-Reason'] = reason
        }
    end
    
    local endpoint = string.format('/guilds/%s/members/%s', Config.GuildId, userId)
    local body = {
        nick = nickname
    }
    
    local response = Http().Patch(endpoint, body, headers)
    
    if response.success then
        -- Invalidate cache so next fetch gets updated nickname
        API.InvalidateMember(userId)
        Utils().Debug('Set nickname for user %s to: %s', userId, tostring(nickname))
        return true, nil
    else
        -- Common error: trying to change nickname of server owner or higher role
        if response.status == 403 then
            return false, 'Missing permissions (user may have higher role or be server owner)'
        end
        Utils().Warn('Failed to set nickname for user %s: %s', userId, response.error or 'Unknown error')
        return false, response.error or 'Failed to set nickname'
    end
end

---Move a guild member to a voice channel
---@param userId string Discord user ID
---@param channelId string|nil Voice channel ID (nil to disconnect)
---@param reason? string Audit log reason
---@return boolean success
---@return string|nil error
function API.MoveToVoiceChannel(userId, channelId, reason)
    userId = Utils().ToSnowflake(userId)
    
    if channelId then
        channelId = Utils().ToSnowflake(channelId)
    end
    
    -- Build headers with audit log reason
    local headers = nil
    if reason then
        headers = {
            ['X-Audit-Log-Reason'] = reason
        }
    end
    
    local endpoint = string.format('/guilds/%s/members/%s', Config.GuildId, userId)
    local body = {
        channel_id = channelId
    }
    
    local response = Http().Patch(endpoint, body, headers)
    
    if response.success then
        Utils().Debug('Moved user %s to voice channel: %s', userId, tostring(channelId))
        return true, nil
    else
        if response.status == 400 then
            return false, 'User is not in a voice channel or invalid channel ID'
        end
        Utils().Warn('Failed to move user %s to voice channel: %s', userId, response.error or 'Unknown error')
        return false, response.error or 'Failed to move to voice channel'
    end
end

return API
