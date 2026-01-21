--[[
    LonexDiscordAPI - Cache System
    https://github.com/LonexLabs/LonexDiscordAPI
]]

LonexDiscord = LonexDiscord or {}
LonexDiscord.Cache = {}

local Cache = LonexDiscord.Cache
local Utils = LonexDiscord.Utils

local Stores = {
    guild = { data = {}, ttl = Config.Cache.GuildTTL },
    roles = { data = {}, ttl = Config.Cache.RolesTTL },
    members = { data = {}, ttl = Config.Cache.MemberTTL, maxSize = Config.Cache.MaxMembers, accessOrder = {} },
    users = { data = {}, ttl = Config.Cache.UserTTL }
}

local function CreateEntry(value, ttl)
    return {
        value = value,
        createdAt = Utils.GetTime(),
        expiresAt = Utils.GetTime() + ttl,
        hits = 0
    }
end

local function IsExpired(entry)
    return Utils.GetTime() > entry.expiresAt
end

local function UpdateAccessOrder(store, key)
    if not store.accessOrder then return end
    
    for i, k in ipairs(store.accessOrder) do
        if k == key then
            table.remove(store.accessOrder, i)
            break
        end
    end
    
    table.insert(store.accessOrder, 1, key)
end

local function EvictLRU(store)
    if not store.maxSize or not store.accessOrder then return end
    
    while #store.accessOrder > store.maxSize do
        local keyToRemove = table.remove(store.accessOrder)
        if keyToRemove then
            store.data[keyToRemove] = nil
        end
    end
end

function Cache.Get(storeName, key)
    local store = Stores[storeName]
    if not store then return nil end

    local entry = store.data[key]
    if not entry then return nil end

    if IsExpired(entry) then
        store.data[key] = nil
        return nil
    end

    entry.hits = entry.hits + 1
    UpdateAccessOrder(store, key)
    
    return entry.value
end

function Cache.Set(storeName, key, value, customTTL)
    local store = Stores[storeName]
    if not store then return end

    local ttl = customTTL or store.ttl
    store.data[key] = CreateEntry(value, ttl)
    
    UpdateAccessOrder(store, key)
    EvictLRU(store)
end

function Cache.Has(storeName, key)
    local store = Stores[storeName]
    if not store then return false end
    
    local entry = store.data[key]
    if not entry then return false end
    
    if IsExpired(entry) then
        store.data[key] = nil
        return false
    end
    
    return true
end

function Cache.Delete(storeName, key)
    local store = Stores[storeName]
    if not store then return end
    
    store.data[key] = nil
    
    if store.accessOrder then
        for i, k in ipairs(store.accessOrder) do
            if k == key then
                table.remove(store.accessOrder, i)
                break
            end
        end
    end
end

function Cache.Clear(storeName)
    local store = Stores[storeName]
    if not store then return end
    
    store.data = {}
    if store.accessOrder then
        store.accessOrder = {}
    end
end

function Cache.ClearAll()
    for name in pairs(Stores) do
        Cache.Clear(name)
    end
end

function Cache.GetGuild()
    return Cache.Get('guild', 'info')
end

function Cache.SetGuild(data)
    Cache.Set('guild', 'info', data)
end

function Cache.GetRoles()
    return Cache.Get('roles', 'all')
end

function Cache.SetRoles(data)
    Cache.Set('roles', 'all', data)
end

function Cache.GetRoleByName(name)
    local roles = Cache.GetRoles()
    if not roles then return nil end
    
    for _, role in ipairs(roles) do
        if role.name == name then
            return role
        end
    end
    return nil
end

function Cache.GetRoleById(id)
    local roles = Cache.GetRoles()
    if not roles then return nil end
    
    id = Utils.ToSnowflake(id)
    for _, role in ipairs(roles) do
        if role.id == id then
            return role
        end
    end
    return nil
end

function Cache.GetMember(discordId)
    return Cache.Get('members', discordId)
end

function Cache.SetMember(discordId, data)
    Cache.Set('members', discordId, data)
end

function Cache.DeleteMember(discordId)
    Cache.Delete('members', discordId)
end

function Cache.GetUser(discordId)
    return Cache.Get('users', discordId)
end

function Cache.SetUser(discordId, data)
    Cache.Set('users', discordId, data)
end

function Cache.GetStats()
    local stats = {}
    
    for name, store in pairs(Stores) do
        local count = 0
        local expired = 0
        local totalHits = 0
        
        for _, entry in pairs(store.data) do
            count = count + 1
            totalHits = totalHits + (entry.hits or 0)
            if IsExpired(entry) then
                expired = expired + 1
            end
        end
        
        stats[name] = {
            entries = count,
            expired = expired,
            active = count - expired,
            totalHits = totalHits,
            maxSize = store.maxSize
        }
    end
    
    return stats
end

function Cache.Cleanup()
    local cleaned = 0
    
    for name, store in pairs(Stores) do
        for key, entry in pairs(store.data) do
            if IsExpired(entry) then
                Cache.Delete(name, key)
                cleaned = cleaned + 1
            end
        end
    end
    
    return cleaned
end

CreateThread(function()
    while true do
        Wait(300000)
        Cache.Cleanup()
    end
end)

return Cache
