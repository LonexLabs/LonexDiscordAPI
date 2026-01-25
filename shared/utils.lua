LonexDiscord = LonexDiscord or {}
LonexDiscord.Utils = {}

local Utils = LonexDiscord.Utils

local LogLevels = { error = 1, warn = 2, info = 3, debug = 4 }
local LogColors = { error = '^1', warn = '^3', info = '^5', debug = '^7' }

local function GetLogLevelNum()
    local level = (Config and Config.LogLevel) or 'info'
    return LogLevels[level] or 3
end

function Utils.Log(level, message, ...)
    local levelNum = LogLevels[level] or 3
    if levelNum > GetLogLevelNum() then return end

    local color = LogColors[level] or '^7'
    local formatted = string.format(message, ...)
    print(string.format('%s[LonexDiscord] [%s] %s^0', color, level:upper(), formatted))
end

function Utils.Error(message, ...) Utils.Log('error', message, ...) end
function Utils.Warn(message, ...) Utils.Log('warn', message, ...) end
function Utils.Info(message, ...) Utils.Log('info', message, ...) end

function Utils.Debug(message, ...)
    if Config and Config.Debug then
        Utils.Log('debug', message, ...)
    end
end

function Utils.DeepCopy(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = type(v) == 'table' and Utils.DeepCopy(v) or v
    end
    return copy
end

function Utils.Contains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then return true end
    end
    return false
end

function Utils.Keys(tbl)
    local keys = {}
    for k in pairs(tbl) do keys[#keys + 1] = k end
    return keys
end

function Utils.Values(tbl)
    local values = {}
    for _, v in pairs(tbl) do values[#values + 1] = v end
    return values
end

function Utils.Merge(t1, t2)
    local result = {}
    for k, v in pairs(t1) do result[k] = v end
    for k, v in pairs(t2) do result[k] = v end
    return result
end

function Utils.StartsWith(str, prefix)
    return str:sub(1, #prefix) == prefix
end

function Utils.EndsWith(str, suffix)
    return str:sub(-#suffix) == suffix
end

function Utils.Trim(str)
    return str:match('^%s*(.-)%s*$')
end

function Utils.GetTimeMs()
    return GetGameTimer()
end

function Utils.GetTime()
    return os.time()
end

function Utils.FormatDuration(seconds)
    if seconds < 60 then
        return string.format('%ds', seconds)
    elseif seconds < 3600 then
        return string.format('%dm %ds', math.floor(seconds / 60), seconds % 60)
    else
        return string.format('%dh %dm', math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

function Utils.GetDiscordIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        if Utils.StartsWith(id, 'discord:') then
            return id:sub(9)
        end
    end
    return nil
end

function Utils.GetAvatarUrl(userId, avatarHash, size)
    size = size or 128
    if not avatarHash then
        return string.format('https://cdn.discordapp.com/embed/avatars/%d.png', tonumber(userId) % 5)
    end
    local ext = Utils.StartsWith(avatarHash, 'a_') and 'gif' or 'png'
    return string.format('https://cdn.discordapp.com/avatars/%s/%s.%s?size=%d', userId, avatarHash, ext, size)
end

function Utils.GetGuildIconUrl(guildId, iconHash, size)
    if not iconHash then return nil end
    size = size or 128
    local ext = Utils.StartsWith(iconHash, 'a_') and 'gif' or 'png'
    return string.format('https://cdn.discordapp.com/icons/%s/%s.%s?size=%d', guildId, iconHash, ext, size)
end

function Utils.IsValidSnowflake(id)
    if type(id) ~= 'string' then return false end
    return id:match('^%d+$') ~= nil and #id >= 17 and #id <= 19
end

function Utils.ToSnowflake(id)
    return tostring(id)
end

return Utils
