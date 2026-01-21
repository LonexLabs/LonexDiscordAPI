--[[
    LonexDiscordAPI - HTTP Request Handler
    https://github.com/LonexLabs/LonexDiscordAPI
]]

Config = Config or {}
Config.BotToken = GetConvar('lonex_discord_token', '')
Config.GuildId = GetConvar('lonex_discord_guild', '')
Config.Http = {
    BaseUrl = 'https://discord.com/api/v10',
    Timeout = 10000,
    UserAgent = 'LonexDiscordAPI (https://github.com/LonexLabs/LonexDiscordAPI, 1.4.0)'
}
Config.Logging = Config.Logging or {}
Config.Logging.Prefix = '[LonexDiscord]'
Config.Logging.LogRateLimits = true
Config.Logging.LogSuccess = false
Config.Logging.LogCache = false

Config.Webhooks = Config.Webhooks or {}
if not Config.Webhooks.DefaultFooter then
    Config.Webhooks.DefaultFooter = { text = 'LonexDiscordAPI' }
end

LonexDiscord = LonexDiscord or {}
LonexDiscord.Http = {}

local Http = LonexDiscord.Http
local Utils = LonexDiscord.Utils

local Buckets = {}
local GlobalRateLimit = { limited = false, resetAt = 0 }
local RequestQueue = {}
local ProcessingQueue = false
local Stats = {
    totalRequests = 0,
    successfulRequests = 0,
    failedRequests = 0,
    rateLimitHits = 0,
    retries = 0
}

local function GetBucket(route)
    local bucketKey = route:gsub('/%d+', '/:id'):gsub('%?.*$', '')
    
    if not Buckets[bucketKey] then
        Buckets[bucketKey] = {
            remaining = 5,
            limit = 5,
            resetAt = 0,
            resetAfter = 0
        }
    end
    
    return Buckets[bucketKey]
end

local function UpdateBucket(route, headers)
    local bucket = GetBucket(route)
    
    if headers['x-ratelimit-remaining'] then
        bucket.remaining = tonumber(headers['x-ratelimit-remaining'])
    end
    if headers['x-ratelimit-limit'] then
        bucket.limit = tonumber(headers['x-ratelimit-limit'])
    end
    if headers['x-ratelimit-reset'] then
        bucket.resetAt = tonumber(headers['x-ratelimit-reset']) * 1000
    end
    if headers['x-ratelimit-reset-after'] then
        bucket.resetAfter = tonumber(headers['x-ratelimit-reset-after']) * 1000
    end
end

local function IsBucketLimited(route)
    local bucket = GetBucket(route)
    local now = Utils.GetTimeMs()
    
    if GlobalRateLimit.limited and now < GlobalRateLimit.resetAt then
        return true, GlobalRateLimit.resetAt - now
    end
    
    if bucket.remaining <= 0 and now < bucket.resetAt then
        return true, bucket.resetAt - now
    end
    
    return false, nil
end

local function ParseHeaders(headerString)
    local headers = {}
    if type(headerString) ~= 'table' then return headers end
    
    for key, value in pairs(headerString) do
        headers[key:lower()] = value
    end
    
    return headers
end

local function BuildUrl(endpoint)
    local base = Config.Http.BaseUrl
    if Utils.StartsWith(endpoint, '/') then
        return base .. endpoint
    end
    return base .. '/' .. endpoint
end

local function BuildHeaders()
    return {
        ['Authorization'] = 'Bot ' .. Config.BotToken,
        ['Content-Type'] = 'application/json',
        ['User-Agent'] = Config.Http.UserAgent
    }
end

local function ExecuteRequest(method, endpoint, body, customHeaders)
    local url = BuildUrl(endpoint)
    local headers = BuildHeaders()
    
    if customHeaders then
        for k, v in pairs(customHeaders) do
            headers[k] = v
        end
    end

    local requestBody = nil
    if body then
        requestBody = json.encode(body)
    end

    local p = promise.new()

    PerformHttpRequest(url, function(statusCode, responseText, responseHeaders)
        local response = {
            success = statusCode >= 200 and statusCode < 300,
            status = statusCode,
            data = nil,
            headers = ParseHeaders(responseHeaders),
            error = nil
        }

        if responseText and responseText ~= '' then
            local ok, parsed = pcall(json.decode, responseText)
            if ok then
                response.data = parsed
            else
                response.data = responseText
            end
        end

        if not response.success and response.data and type(response.data) == 'table' then
            response.error = response.data.message or 'Unknown error'
        end

        p:resolve(response)
    end, method, requestBody, headers)

    return Citizen.Await(p)
end

local function ProcessRequest(request)
    local route = request.method .. ':' .. request.endpoint
    local attempt = 0
    local maxRetries = Config.RateLimit.RetryOnLimit and Config.RateLimit.MaxRetries or 0

    while attempt <= maxRetries do
        local limited, waitTime = IsBucketLimited(route)
        
        if limited then
            if Config.Logging.LogRateLimits then
                Utils.Debug('Rate limited on %s, waiting %dms', route, waitTime)
            end
            Stats.rateLimitHits = Stats.rateLimitHits + 1
            Wait(waitTime + 100)
        end

        local response = ExecuteRequest(request.method, request.endpoint, request.body, request.headers)
        UpdateBucket(route, response.headers)

        if response.status == 429 then
            Stats.rateLimitHits = Stats.rateLimitHits + 1
            
            local retryAfter = 1000
            if response.data and response.data.retry_after then
                retryAfter = response.data.retry_after * 1000
            end

            if response.data and response.data.global then
                GlobalRateLimit.limited = true
                GlobalRateLimit.resetAt = Utils.GetTimeMs() + retryAfter
                Utils.Warn('Global rate limit hit! Waiting %dms', retryAfter)
            end

            if attempt < maxRetries then
                attempt = attempt + 1
                Stats.retries = Stats.retries + 1
                Utils.Debug('Rate limited, retry %d/%d in %dms', attempt, maxRetries, retryAfter)
                Wait(retryAfter)
            else
                Utils.Error('Rate limited on %s, max retries exceeded', route)
                return response
            end
        else
            Stats.totalRequests = Stats.totalRequests + 1
            
            if response.success then
                Stats.successfulRequests = Stats.successfulRequests + 1
                if Config.Logging.LogSuccess then
                    Utils.Debug('%s %s -> %d', request.method, request.endpoint, response.status)
                end
            else
                Stats.failedRequests = Stats.failedRequests + 1
                Utils.Warn('%s %s -> %d: %s', request.method, request.endpoint, response.status, response.error or 'Unknown error')
            end
            
            return response
        end
    end
end

local function QueueRequest(request)
    if #RequestQueue >= Config.RateLimit.MaxQueueSize then
        Utils.Error('Request queue full, rejecting request to %s', request.endpoint)
        return { success = false, status = 0, error = 'Request queue full', data = nil, headers = {} }
    end

    request.promise = promise.new()
    table.insert(RequestQueue, request)
    
    if not ProcessingQueue then
        ProcessingQueue = true
        CreateThread(function()
            while #RequestQueue > 0 do
                local req = table.remove(RequestQueue, 1)
                local response = ProcessRequest(req)
                req.promise:resolve(response)
                Wait(math.ceil(1000 / Config.RateLimit.MaxRequestsPerSecond))
            end
            ProcessingQueue = false
        end)
    end

    return Citizen.Await(request.promise)
end

function Http.Get(endpoint, headers)
    return QueueRequest({ method = 'GET', endpoint = endpoint, body = nil, headers = headers })
end

function Http.Post(endpoint, body, headers)
    return QueueRequest({ method = 'POST', endpoint = endpoint, body = body, headers = headers })
end

function Http.Put(endpoint, body, headers)
    return QueueRequest({ method = 'PUT', endpoint = endpoint, body = body, headers = headers })
end

function Http.Patch(endpoint, body, headers)
    return QueueRequest({ method = 'PATCH', endpoint = endpoint, body = body, headers = headers })
end

function Http.Delete(endpoint, headers)
    return QueueRequest({ method = 'DELETE', endpoint = endpoint, body = nil, headers = headers })
end

function Http.GetStats()
    return Utils.DeepCopy(Stats)
end

function Http.ResetStats()
    Stats.totalRequests = 0
    Stats.successfulRequests = 0
    Stats.failedRequests = 0
    Stats.rateLimitHits = 0
    Stats.retries = 0
end

function Http.GetQueueLength()
    return #RequestQueue
end

return Http
