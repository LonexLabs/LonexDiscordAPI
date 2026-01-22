--[[
    Badger_Discord_API Compatibility Bridge
    
    This resource forwards all Badger_Discord_API export calls to LonexDiscordAPI.
    Install this alongside LonexDiscordAPI to maintain compatibility with existing
    scripts that use Badger_Discord_API.
    
    Usage:
        1. Install LonexDiscordAPI and configure it
        2. Place this resource in your resources folder (named Badger_Discord_API)
        3. Add to server.cfg AFTER LonexDiscordAPI:
            ensure LonexDiscordAPI
            ensure Badger_Discord_API
        4. Remove the original Badger_Discord_API if you had it installed
    
    All existing scripts using exports.Badger_Discord_API will now work automatically.
]]

local API = exports.LonexDiscordAPI

-- Cache for role name -> ID lookups
local RoleNameCache = nil
local RoleCacheTime = 0
local CACHE_TTL = 300 -- 5 minutes

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

-- ============================================================================
-- PLAYER FUNCTIONS
-- ============================================================================

-- GetDiscordRoles(user) - Returns array of role IDs
exports('GetDiscordRoles', function(user)
    return API:GetDiscordRoleIds(user)
end)

-- GetDiscordName(user) - Returns Discord username
exports('GetDiscordName', function(user)
    return API:GetDiscordUsername(user)
end)

-- GetDiscordNickname(user) - Returns server nickname
exports('GetDiscordNickname', function(user)
    return API:GetDiscordNickname(user)
end)

-- GetDiscordAvatar(user) - Returns avatar URL
exports('GetDiscordAvatar', function(user)
    return API:GetDiscordAvatar(user)
end)

-- GetDiscordEmail(user) - Returns email (requires email OAuth scope)
exports('GetDiscordEmail', function(user)
    local userData = API:GetDiscordUser(user)
    if userData then
        return userData.email
    end
    return nil
end)

-- IsDiscordEmailVerified(user) - Returns boolean
exports('IsDiscordEmailVerified', function(user)
    local userData = API:GetDiscordUser(user)
    if userData then
        return userData.verified == true
    end
    return false
end)

-- ============================================================================
-- GUILD FUNCTIONS
-- ============================================================================

-- GetGuildName() - Returns guild name
exports('GetGuildName', function()
    return API:GetGuildName()
end)

-- GetGuildDescription() - Returns guild description
exports('GetGuildDescription', function()
    return API:GetGuildDescription()
end)

-- GetGuildIcon() - Returns guild icon URL
exports('GetGuildIcon', function()
    return API:GetGuildIcon()
end)

-- GetGuildSplash() - Returns guild splash URL
exports('GetGuildSplash', function()
    return API:GetGuildSplash()
end)

-- GetGuildMemberCount() - Returns approximate member count
exports('GetGuildMemberCount', function()
    return API:GetGuildMemberCount()
end)

-- GetGuildOnlineMemberCount() - Returns approximate online count
exports('GetGuildOnlineMemberCount', function()
    return API:GetGuildOnlineCount()
end)

-- GetGuildRoleList() - Returns {roleName = roleId} table
exports('GetGuildRoleList', function()
    return RefreshRoleCache()
end)

-- ============================================================================
-- ROLE FUNCTIONS
-- ============================================================================

-- GetRoleIdFromRoleName(name) - Returns role ID from name
exports('GetRoleIdFromRoleName', function(name)
    return API:GetRoleIdFromName(name)
end)

-- CheckEqual(role1, role2) - Compares two roles (can be names or IDs)
exports('CheckEqual', function(role1, role2)
    local cache = RefreshRoleCache()
    
    -- Convert names to IDs if needed
    local id1 = cache[tostring(role1)] or tostring(role1)
    local id2 = cache[tostring(role2)] or tostring(role2)
    
    return id1 == id2
end)

-- ============================================================================
-- MEMBER MODIFICATION FUNCTIONS
-- ============================================================================

-- SetNickname(user, nickname, reason) - Set member nickname
exports('SetNickname', function(user, nickname, reason)
    return API:SetNickname(user, nickname or '', reason)
end)

-- AddRole(user, roleId, reason) - Add role to member
exports('AddRole', function(user, roleId, reason)
    return API:AddRole(user, tostring(roleId), reason)
end)

-- RemoveRole(user, roleId, reason) - Remove role from member
exports('RemoveRole', function(user, roleId, reason)
    return API:RemoveRole(user, tostring(roleId), reason)
end)

-- SetRoles(user, roleList, reason) - Set member's roles
exports('SetRoles', function(user, roleList, reason)
    return API:SetRoles(user, roleList, reason)
end)

-- ChangeDiscordVoice(user, voiceID, reason) - Move user to voice channel
-- Note: This requires the bot to have MOVE_MEMBERS permission
exports('ChangeDiscordVoice', function(user, voiceID, reason)
    print('[Badger_Discord_API Bridge] ChangeDiscordVoice is not yet implemented in LonexDiscordAPI')
    return false
end)

-- ============================================================================
-- STARTUP
-- ============================================================================

CreateThread(function()
    Wait(1000)
    print('^2[Badger_Discord_API Bridge] ^0Loaded - forwarding calls to LonexDiscordAPI')
end)
