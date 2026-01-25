LonexDiscord = LonexDiscord or {}
LonexDiscord.API = {}

local API = LonexDiscord.API

local function Http() return LonexDiscord.Http end
local function Cache() return LonexDiscord.Cache end
local function Utils() return LonexDiscord.Utils end

function API.GetUser(userId, useCache)
    if useCache == nil then useCache = true end

    userId = Utils().ToSnowflake(userId)

    if useCache then
        local cached = Cache().GetUser(userId)
        if cached then
            return cached, nil
        end
    end

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

        Cache().SetUser(userId, user)

        return user, nil
    else
        return nil, response.error or 'Failed to fetch user'
    end
end

function API.GetMember(userId, useCache)
    if useCache == nil then useCache = true end

    userId = Utils().ToSnowflake(userId)

    if useCache then
        local cached = Cache().GetMember(userId)
        if cached then
            return cached, nil
        end
    end

    local response = Http().Get(string.format('/guilds/%s/members/%s', Config.GuildId, userId))

    if response.success and response.data then
        local data = response.data

        local member = {

            user = {
                id = data.user.id,
                username = data.user.username,
                discriminator = data.user.discriminator or '0',
                globalName = data.user.global_name,
                avatar = data.user.avatar,
                bot = data.user.bot or false
            },

            nickname = data.nick,
            roles = data.roles or {},
            joinedAt = data.joined_at,
            premiumSince = data.premium_since,
            deaf = data.deaf or false,
            mute = data.mute or false,
            pending = data.pending or false,
            avatar = data.avatar,
            communicationDisabledUntil = data.communication_disabled_until
        }

        Cache().SetMember(userId, member)

        Cache().SetUser(userId, member.user)

        return member, nil
    else

        if response.status == 404 then
            return nil, 'Member not found in guild'
        end
        return nil, response.error or 'Failed to fetch member'
    end
end

function API.GetMemberBySource(source, useCache)
    local discordId = Utils().GetDiscordIdentifier(source)

    if not discordId then
        return nil, 'Player has no Discord identifier'
    end

    return API.GetMember(discordId, useCache)
end

function API.IsMemberOfGuild(userId)
    local member, err = API.GetMember(userId, true)
    return member ~= nil
end

function API.GetMemberRoles(userId)
    local member, err = API.GetMember(userId, true)

    if not member then
        return nil, err
    end

    local cachedRoles = Cache().GetRoles()
    if not cachedRoles then
        return nil, 'Roles not cached'
    end

    local roles = {}
    for _, roleId in ipairs(member.roles) do
        for _, cachedRole in ipairs(cachedRoles) do
            if cachedRole.id == roleId then
                table.insert(roles, cachedRole)
                break
            end
        end
    end

    table.sort(roles, function(a, b)
        return a.position > b.position
    end)

    return roles, nil
end

function API.GetMemberRoleIds(userId)
    local member, err = API.GetMember(userId, true)

    if not member then
        return nil, err
    end

    return member.roles, nil
end

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

function API.MemberHasRole(userId, roleId)
    local member, err = API.GetMember(userId, true)

    if not member then
        return false, err
    end

    roleId = Utils().ToSnowflake(roleId)
    if not Utils().IsValidSnowflake(roleId) then
        return false, 'Invalid role ID: ' .. tostring(roleId)
    end

    for _, memberRoleId in ipairs(member.roles) do
        if memberRoleId == roleId then
            return true, nil
        end
    end

    return false, nil
end

function API.MemberHasAnyRole(userId, roleIds)
    for _, roleId in ipairs(roleIds) do
        local hasRole, err = API.MemberHasRole(userId, roleId)
        if hasRole then
            return true, roleId
        end
    end
    return false, nil
end

function API.MemberHasAllRoles(userId, roleIds)
    for _, roleId in ipairs(roleIds) do
        local hasRole, err = API.MemberHasRole(userId, roleId)
        if not hasRole then
            return false, roleId
        end
    end
    return true, nil
end

function API.GetUserAvatar(userId, size)
    local user, err = API.GetUser(userId, true)

    if not user then
        return nil, err
    end

    return Utils().GetAvatarUrl(user.id, user.avatar, size), nil
end

function API.GetMemberAvatar(userId, size)
    size = size or 128
    local member, err = API.GetMember(userId, true)

    if not member then
        return nil, err
    end

    if member.avatar then
        local ext = Utils().StartsWith(member.avatar, 'a_') and 'gif' or 'png'
        return string.format('https://cdn.discordapp.com/guilds/%s/users/%s/avatars/%s.%s?size=%d',
            Config.GuildId, member.user.id, member.avatar, ext, size), nil
    end

    return Utils().GetAvatarUrl(member.user.id, member.user.avatar, size), nil
end

function API.GetMemberDisplayName(userId)
    local member, err = API.GetMember(userId, true)

    if not member then
        return nil, err
    end

    return member.nickname or member.user.globalName or member.user.username, nil
end

function API.GetUsername(userId)
    local user, err = API.GetUser(userId, true)

    if not user then
        return nil, err
    end

    return user.username, nil
end

function API.PrefetchMembers(sources)
    Utils().Info('Prefetching member data for %d players...', #sources)

    local fetched = 0
    local failed = 0

    for _, source in ipairs(sources) do
        local discordId = Utils().GetDiscordIdentifier(source)
        if discordId then
            local member, err = API.GetMember(discordId, false)
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

function API.InvalidateMember(userId)
    userId = Utils().ToSnowflake(userId)
    Cache().DeleteMember(userId)
    Utils().Debug('Invalidated cache for member: %s', userId)
end

function API.AddRole(userId, roleId, reason)
    userId = Utils().ToSnowflake(userId)
    roleId = Utils().ToSnowflake(roleId)

    if not Utils().IsValidSnowflake(roleId) then
        return false, 'Invalid role ID: ' .. tostring(roleId)
    end

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

        API.InvalidateMember(userId)
        Utils().Debug('Added role %s to user %s', roleId, userId)
        return true, nil
    else
        Utils().Warn('Failed to add role %s to user %s: %s', roleId, userId, response.error or 'Unknown error')
        return false, response.error or 'Failed to add role'
    end
end

function API.RemoveRole(userId, roleId, reason)
    userId = Utils().ToSnowflake(userId)
    roleId = Utils().ToSnowflake(roleId)

    if not Utils().IsValidSnowflake(roleId) then
        return false, 'Invalid role ID: ' .. tostring(roleId)
    end

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

        API.InvalidateMember(userId)
        Utils().Debug('Removed role %s from user %s', roleId, userId)
        return true, nil
    else
        Utils().Warn('Failed to remove role %s from user %s: %s', roleId, userId, response.error or 'Unknown error')
        return false, response.error or 'Failed to remove role'
    end
end

function API.SetRoles(userId, roleIds, reason)
    userId = Utils().ToSnowflake(userId)

    local validRoleIds = {}
    for _, roleId in ipairs(roleIds) do
        local resolved = Utils().ToSnowflake(roleId)
        if not Utils().IsValidSnowflake(resolved) then
            return false, 'Invalid role ID: ' .. tostring(roleId)
        end
        table.insert(validRoleIds, resolved)
    end

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

        API.InvalidateMember(userId)
        Utils().Debug('Set %d roles for user %s', #validRoleIds, userId)
        return true, nil
    else
        Utils().Warn('Failed to set roles for user %s: %s', userId, response.error or 'Unknown error')
        return false, response.error or 'Failed to set roles'
    end
end

function API.SetNickname(userId, nickname, reason)
    userId = Utils().ToSnowflake(userId)

    if nickname == '' then
        nickname = nil
    end

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

        API.InvalidateMember(userId)
        Utils().Debug('Set nickname for user %s to: %s', userId, tostring(nickname))
        return true, nil
    else

        if response.status == 403 then
            return false, 'Missing permissions (user may have higher role or be server owner)'
        end
        Utils().Warn('Failed to set nickname for user %s: %s', userId, response.error or 'Unknown error')
        return false, response.error or 'Failed to set nickname'
    end
end

function API.MoveToVoiceChannel(userId, channelId, reason)
    userId = Utils().ToSnowflake(userId)

    if channelId then
        channelId = Utils().ToSnowflake(channelId)
    end

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

function API.SendChannelMessage(channelId, content, embeds)
    if not channelId or channelId == '' then
        return false, 'No channel ID provided'
    end

    local body = {}

    if content and content ~= '' then
        body.content = content
    end

    if embeds and #embeds > 0 then
        body.embeds = embeds
    end

    if not body.content and not body.embeds then
        return false, 'No content or embeds provided'
    end

    local endpoint = string.format('/channels/%s/messages', channelId)
    local response = Http().Post(endpoint, body)

    if response.success then
        Utils().Debug('Sent message to channel %s', channelId)
        return true, nil
    else
        Utils().Warn('Failed to send message to channel %s: %s', channelId, response.error or 'Unknown error')
        return false, response.error or 'Failed to send message'
    end
end

return API
