local API = exports.LonexDiscordAPI

local RoleNameCache = nil
local RoleCacheTime = 0
local CACHE_TTL = 300

local function RefreshRoleCache()
    local now = os.time()
    if RoleNameCache and (now - RoleCacheTime) < CACHE_TTL then
        return RoleNameCache
    end

    local roles = API:GetGuildRoles()
    if roles then
        RoleNameCache = {}
        for _, role in ipairs(roles) do
            RoleNameCache[role.name] = role.id
        end
        RoleCacheTime = now
    end

    return RoleNameCache or {}
end

exports('GetDiscordRoles', function(user)
    return API:GetDiscordRoleIds(user)
end)

exports('GetDiscordName', function(user)
    return API:GetDiscordUsername(user)
end)

exports('GetDiscordNickname', function(user)
    return API:GetDiscordNickname(user)
end)

exports('GetDiscordAvatar', function(user)
    return API:GetDiscordAvatar(user)
end)

exports('GetDiscordEmail', function(user)
    local userData = API:GetDiscordUser(user)
    if userData then
        return userData.email
    end
    return nil
end)

exports('IsDiscordEmailVerified', function(user)
    local userData = API:GetDiscordUser(user)
    if userData then
        return userData.verified == true
    end
    return false
end)

exports('GetGuildName', function()
    return API:GetGuildName()
end)

exports('GetGuildDescription', function()
    return API:GetGuildDescription()
end)

exports('GetGuildIcon', function()
    return API:GetGuildIcon()
end)

exports('GetGuildSplash', function()
    return API:GetGuildSplash()
end)

exports('GetGuildMemberCount', function()
    return API:GetGuildMemberCount()
end)

exports('GetGuildOnlineMemberCount', function()
    return API:GetGuildOnlineCount()
end)

exports('GetGuildRoleList', function()
    return RefreshRoleCache()
end)

exports('GetRoleIdFromRoleName', function(name)
    return API:GetRoleIdFromName(name)
end)

exports('CheckEqual', function(role1, role2)
    local cache = RefreshRoleCache()

    local id1 = cache[tostring(role1)] or tostring(role1)
    local id2 = cache[tostring(role2)] or tostring(role2)

    return id1 == id2
end)

exports('SetNickname', function(user, nickname, reason)
    return API:SetNickname(user, nickname or '', reason)
end)

exports('AddRole', function(user, roleId, reason)
    return API:AddRole(user, tostring(roleId), reason)
end)

exports('RemoveRole', function(user, roleId, reason)
    return API:RemoveRole(user, tostring(roleId), reason)
end)

exports('SetRoles', function(user, roleList, reason)
    return API:SetRoles(user, roleList, reason)
end)

exports('ChangeDiscordVoice', function(user, voiceID, reason)
    print('[Badger_Discord_API Bridge] ChangeDiscordVoice is not yet implemented in LonexDiscordAPI')
    return false
end)

CreateThread(function()
    Wait(1000)
    print('^2[Badger_Discord_API Bridge] ^0Loaded - forwarding calls to LonexDiscordAPI')
end)
