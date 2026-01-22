-- LonexDiscordAPI Client

local AllowedWeapons = {}
local AllowedVehicles = {}
local AllowedPeds = {}
local HasNoWeaponRestrictions = false
local HasNoVehicleRestrictions = false
local HasNoPedRestrictions = false
local PermissionsLoaded = false

local function ShowNotification(message)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, false)
end

local function IsWeaponRestricted(weaponHash)
    if not Config.WeaponPermissions or not Config.WeaponPermissions.Enabled then
        return false
    end
    
    if not Config.WeaponPermissions.RestrictedWeapons then
        return false
    end
    
    for _, weaponName in ipairs(Config.WeaponPermissions.RestrictedWeapons) do
        local restrictedHash = GetHashKey(weaponName)
        if restrictedHash == weaponHash then
            return true
        end
    end
    
    return false
end

local function IsVehicleRestricted(vehicleModel)
    if not Config.VehiclePermissions or not Config.VehiclePermissions.Enabled then
        return false
    end
    
    if not Config.VehiclePermissions.RestrictedVehicles then
        return false
    end
    
    for _, vehicleName in ipairs(Config.VehiclePermissions.RestrictedVehicles) do
        local restrictedHash = GetHashKey(vehicleName)
        if restrictedHash == vehicleModel then
            return true
        end
    end
    
    return false
end

local function CanUseWeapon(weaponHash)
    if HasNoWeaponRestrictions then
        return true
    end
    
    if not IsWeaponRestricted(weaponHash) then
        return true
    end
    
    for allowedHash, _ in pairs(AllowedWeapons) do
        if allowedHash == weaponHash then
            return true
        end
    end
    
    return false
end

local function CanUseVehicle(vehicleModel)
    if HasNoVehicleRestrictions then
        return true
    end
    
    if not IsVehicleRestricted(vehicleModel) then
        return true
    end
    
    for allowedHash, _ in pairs(AllowedVehicles) do
        if allowedHash == vehicleModel then
            return true
        end
    end
    
    return false
end

local function IsPedRestricted(pedModel)
    if not Config.PedPermissions or not Config.PedPermissions.Enabled then
        return false
    end
    
    if not Config.PedPermissions.RestrictedPeds then
        return false
    end
    
    for _, pedName in ipairs(Config.PedPermissions.RestrictedPeds) do
        local restrictedHash = GetHashKey(pedName)
        if restrictedHash == pedModel then
            return true
        end
    end
    
    return false
end

local function CanUsePed(pedModel)
    if HasNoPedRestrictions then
        return true
    end
    
    if not IsPedRestricted(pedModel) then
        return true
    end
    
    for allowedHash, _ in pairs(AllowedPeds) do
        if allowedHash == pedModel then
            return true
        end
    end
    
    return false
end

RegisterNetEvent('LonexDiscord:SyncWeaponPermissions')
AddEventHandler('LonexDiscord:SyncWeaponPermissions', function(weapons, noRestrictions)
    AllowedWeapons = {}
    HasNoWeaponRestrictions = noRestrictions or false
    
    if weapons then
        for _, weaponName in ipairs(weapons) do
            local hash = GetHashKey(weaponName)
            AllowedWeapons[hash] = true
        end
    end
    
    PermissionsLoaded = true
end)

RegisterNetEvent('LonexDiscord:SyncVehiclePermissions')
AddEventHandler('LonexDiscord:SyncVehiclePermissions', function(vehicles, noRestrictions)
    AllowedVehicles = {}
    HasNoVehicleRestrictions = noRestrictions or false
    
    if vehicles then
        for _, vehicleName in ipairs(vehicles) do
            local hash = GetHashKey(vehicleName)
            AllowedVehicles[hash] = true
        end
    end
    
    PermissionsLoaded = true
end)

RegisterNetEvent('LonexDiscord:SyncPedPermissions')
AddEventHandler('LonexDiscord:SyncPedPermissions', function(peds, noRestrictions)
    AllowedPeds = {}
    HasNoPedRestrictions = noRestrictions or false
    
    if peds then
        for _, pedName in ipairs(peds) do
            local hash = GetHashKey(pedName)
            AllowedPeds[hash] = true
        end
    end
    
    PermissionsLoaded = true
end)

RegisterNetEvent('LonexDiscord:SyncAllPermissions')
AddEventHandler('LonexDiscord:SyncAllPermissions', function(data)
    if data.weapons then
        AllowedWeapons = {}
        HasNoWeaponRestrictions = data.noWeaponRestrictions or false
        
        for _, weaponName in ipairs(data.weapons) do
            local hash = GetHashKey(weaponName)
            AllowedWeapons[hash] = true
        end
    end
    
    if data.vehicles then
        AllowedVehicles = {}
        HasNoVehicleRestrictions = data.noVehicleRestrictions or false
        
        for _, vehicleName in ipairs(data.vehicles) do
            local hash = GetHashKey(vehicleName)
            AllowedVehicles[hash] = true
        end
    end
    
    if data.peds then
        AllowedPeds = {}
        HasNoPedRestrictions = data.noPedRestrictions or false
        
        for _, pedName in ipairs(data.peds) do
            local hash = GetHashKey(pedName)
            AllowedPeds[hash] = true
        end
    end
    
    PermissionsLoaded = true
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('LonexDiscord:RequestPermissions')
end)

CreateThread(function()
    Wait(2000)
    if not PermissionsLoaded then
        TriggerServerEvent('LonexDiscord:RequestPermissions')
    end
end)

AddEventHandler('playerSpawned', function()
    if Config.ForceDefaultPed and Config.ForceDefaultPed.Enabled then
        local defaultPed = Config.ForceDefaultPed.Ped or 'a_m_y_hipster_02'
        local defaultHash = GetHashKey(defaultPed)
        
        RequestModel(defaultHash)
        local timeout = 0
        while not HasModelLoaded(defaultHash) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        
        if HasModelLoaded(defaultHash) then
            SetPlayerModel(PlayerId(), defaultHash)
            SetModelAsNoLongerNeeded(defaultHash)
        end
    end
end)

CreateThread(function()
    while true do
        local interval = 1000
        
        if Config.WeaponPermissions and Config.WeaponPermissions.Enabled then
            interval = Config.WeaponPermissions.CheckInterval or 1000
            
            local ped = PlayerPedId()
            local currentWeapon = GetSelectedPedWeapon(ped)
            
            if currentWeapon and currentWeapon ~= GetHashKey('WEAPON_UNARMED') then
                if not CanUseWeapon(currentWeapon) then
                    if Config.WeaponPermissions.RemoveWeapon then
                        RemoveWeaponFromPed(ped, currentWeapon)
                    end
                    
                    if Config.WeaponPermissions.NotifyPlayer then
                        ShowNotification(Config.WeaponPermissions.NotifyMessage or 'You do not have permission to use this weapon.')
                    end
                end
            end
        end
        
        Wait(interval)
    end
end)

CreateThread(function()
    while true do
        local interval = 1000
        
        if Config.VehiclePermissions and Config.VehiclePermissions.Enabled then
            interval = Config.VehiclePermissions.CheckInterval or 1000
            
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if vehicle and vehicle ~= 0 then
                local vehicleModel = GetEntityModel(vehicle)
                
                if not CanUseVehicle(vehicleModel) then
                    local ejectDelay = Config.VehiclePermissions.EjectDelay or 0
                    
                    if ejectDelay > 0 then
                        Wait(ejectDelay)
                    end
                    
                    if Config.VehiclePermissions.EjectPlayer then
                        TaskLeaveVehicle(ped, vehicle, 16)
                        
                        if Config.VehiclePermissions.DeleteVehicle then
                            Wait(1500)
                            if DoesEntityExist(vehicle) then
                                SetEntityAsMissionEntity(vehicle, true, true)
                                DeleteVehicle(vehicle)
                            end
                        end
                    elseif Config.VehiclePermissions.DeleteVehicle then
                        SetEntityAsMissionEntity(vehicle, true, true)
                        DeleteVehicle(vehicle)
                    end
                    
                    if Config.VehiclePermissions.NotifyPlayer then
                        ShowNotification(Config.VehiclePermissions.NotifyMessage or 'You do not have permission to use this vehicle.')
                    end
                end
            end
        end
        
        Wait(interval)
    end
end)

CreateThread(function()
    while true do
        local interval = 1000
        
        if Config.PedPermissions and Config.PedPermissions.Enabled then
            interval = Config.PedPermissions.CheckInterval or 1000
            
            local ped = PlayerPedId()
            local pedModel = GetEntityModel(ped)
            
            if not CanUsePed(pedModel) then
                if Config.PedPermissions.ResetPed then
                    local defaultPed = Config.PedPermissions.DefaultPed or 'a_m_y_hipster_02'
                    local defaultHash = GetHashKey(defaultPed)
                    
                    RequestModel(defaultHash)
                    local timeout = 0
                    while not HasModelLoaded(defaultHash) and timeout < 50 do
                        Wait(100)
                        timeout = timeout + 1
                    end
                    
                    if HasModelLoaded(defaultHash) then
                        SetPlayerModel(PlayerId(), defaultHash)
                        SetModelAsNoLongerNeeded(defaultHash)
                    end
                end
                
                if Config.PedPermissions.NotifyPlayer then
                    ShowNotification(Config.PedPermissions.NotifyMessage or 'You do not have permission to use this ped model.')
                end
            end
        end
        
        Wait(interval)
    end
end)


-- ============================================================================
-- UNIFIED TAGS SYSTEM
-- ============================================================================

local TagsData = {}
local TagsSettings = { showOthers = true, showOwn = true }
local AvailableTags = {}
local SelectedTagIndex = 1
local MenuOpen = false
local MenuIndex = 1

-- Load menu textures
CreateThread(function()
    RequestStreamedTextureDict('commonmenu', true)
    while not HasStreamedTextureDictLoaded('commonmenu') do
        Wait(10)
    end
end)

local function DrawText3D(x, y, z, text, r, g, b, scale, font)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(font or 4)
        SetTextProportional(true)
        SetTextColour(r, g, b, 255)
        SetTextOutline()
        SetTextCentre(true)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(sx, sy)
    end
end

local function GetTagDisplayText(playerId, tagData)
    local tag = tagData.tag and tagData.tag.text or 'Player'
    local name = tagData.name or 'Unknown'
    return string.format('%s | [%d] %s', tag, playerId, name)
end

RegisterNetEvent('LonexDiscord:Tags:SyncAll')
AddEventHandler('LonexDiscord:Tags:SyncAll', function(allTags, settings, available, selectedIndex)
    TagsData = allTags or {}
    if settings then
        TagsSettings.showOthers = settings.showOthers ~= false
        TagsSettings.showOwn = settings.showOwn ~= false
    end
    if available then AvailableTags = available end
    if selectedIndex then SelectedTagIndex = selectedIndex end
end)

RegisterNetEvent('LonexDiscord:Tags:UpdatePlayer')
AddEventHandler('LonexDiscord:Tags:UpdatePlayer', function(playerId, tagData)
    TagsData[playerId] = tagData
end)

RegisterNetEvent('LonexDiscord:Tags:PlayerLeft')
AddEventHandler('LonexDiscord:Tags:PlayerLeft', function(playerId)
    TagsData[playerId] = nil
end)

RegisterNetEvent('LonexDiscord:Tags:OpenMenu')
AddEventHandler('LonexDiscord:Tags:OpenMenu', function(available, selectedIndex, settings)
    if available then AvailableTags = available end
    if selectedIndex then SelectedTagIndex = selectedIndex end
    if settings then
        TagsSettings.showOthers = settings.showOthers ~= false
        TagsSettings.showOwn = settings.showOwn ~= false
    end
    MenuOpen = true
    MenuIndex = 1
    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end)

AddEventHandler('playerSpawned', function()
    if Config.Tags and Config.Tags.Enabled then
        TriggerServerEvent('LonexDiscord:Tags:RequestSync')
    end
end)

-- ============================================================================
-- HEAD TAGS RENDERER
-- ============================================================================

CreateThread(function()
    while true do
        local sleep = 500
        
        if Config.Tags and Config.Tags.Enabled and Config.Tags.HeadTags and Config.Tags.HeadTags.Enabled then
            if TagsSettings.showOthers or TagsSettings.showOwn then
                sleep = 0
                
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                local maxDist = Config.Tags.HeadTags.MaxDistance or 20.0
                local height = Config.Tags.HeadTags.HeightOffset or 1.0
                local scale = Config.Tags.HeadTags.Scale or 0.35
                local font = Config.Tags.HeadTags.Font or 4
                local myId = PlayerId()
                
                for playerId, data in pairs(TagsData) do
                    local target = GetPlayerFromServerId(playerId)
                    if target ~= -1 then
                        local isMe = target == myId
                        local show = (isMe and TagsSettings.showOwn) or (not isMe and TagsSettings.showOthers)
                        
                        if show then
                            local targetPed = GetPlayerPed(target)
                            if DoesEntityExist(targetPed) and not IsEntityDead(targetPed) then
                                local targetPos = GetEntityCoords(targetPed)
                                local dist = #(pos - targetPos)
                                if dist <= maxDist then
                                    local tag = data.tag or Config.Tags.DefaultTag
                                    local color = tag.color or { r = 255, g = 255, b = 255 }
                                    DrawText3D(targetPos.x, targetPos.y, targetPos.z + height,
                                        GetTagDisplayText(playerId, data),
                                        color.r, color.g, color.b, scale, font)
                                end
                            end
                        end
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- ============================================================================
-- VOICE TAGS (Currently Talking)
-- ============================================================================

CreateThread(function()
    while true do
        local sleep = 100
        
        if Config.Tags and Config.Tags.Enabled and Config.Tags.VoiceTags and Config.Tags.VoiceTags.Enabled then
            local talking = {}
            local myId = PlayerId()
            
            for playerId, data in pairs(TagsData) do
                local target = GetPlayerFromServerId(playerId)
                if target ~= -1 then
                    local isMe = target == myId
                    if NetworkIsPlayerTalking(target) then
                        if not isMe or Config.Tags.VoiceTags.ShowSelf then
                            table.insert(talking, {
                                id = playerId,
                                name = data.name or 'Unknown',
                                tag = data.tag or Config.Tags.DefaultTag,
                            })
                        end
                    end
                end
            end
            
            if #talking > 0 then
                sleep = 0
                
                -- Header
                SetTextFont(4)
                SetTextScale(0.50, 0.50)
                SetTextColour(255, 255, 255, 255)
                SetTextCentre(true)
                SetTextDropShadow()
                SetTextOutline()
                BeginTextCommandDisplayText('STRING')
                AddTextComponentSubstringPlayerName('CURRENTLY TALKING')
                EndTextCommandDisplayText(0.5, 0.012)
                
                -- Players
                for i, player in ipairs(talking) do
                    local y = 0.018 + (i * 0.025)
                    local color = player.tag.color or { r = 255, g = 255, b = 255 }
                    local text = player.tag.text .. ' | ' .. player.name
                    
                    SetTextFont(4)
                    SetTextScale(0.42, 0.42)
                    SetTextColour(color.r, color.g, color.b, 255)
                    SetTextCentre(true)
                    SetTextDropShadow()
                    SetTextOutline()
                    BeginTextCommandDisplayText('STRING')
                    AddTextComponentSubstringPlayerName(text)
                    EndTextCommandDisplayText(0.5, y)
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- ============================================================================
-- NATIVEUI MENU
-- ============================================================================

local Menu = {
    width = 0.225,
    headerH = 0.07,
    subH = 0.032,
    itemH = 0.038,
}

local function GetMenuX()
    if Config.Tags and Config.Tags.MenuPosition == 'right' then
        return 1.0 - 0.16
    end
    return 0.16
end

CreateThread(function()
    while true do
        if MenuOpen then
            local menuX = GetMenuX()
            
            local items = {
                { type = 'toggle', label = "Show Others' Tags", value = TagsSettings.showOthers },
                { type = 'toggle', label = 'Show Own Tag', value = TagsSettings.showOwn },
                { type = 'separator', label = 'SELECT TAG' },
            }
            
            for i, tag in ipairs(AvailableTags) do
                table.insert(items, {
                    type = 'tag',
                    label = tag.text or 'Unknown',
                    color = tag.color or { r = 255, g = 255, b = 255 },
                    index = i,
                    active = (i == SelectedTagIndex)
                })
            end
            
            local selectableItems = {}
            for i, item in ipairs(items) do
                if item.type ~= 'separator' then
                    table.insert(selectableItems, i)
                end
            end
            local selectableCount = #selectableItems
            
            local startY = 0.15
            
            -- Header
            DrawSprite('commonmenu', 'gradient_bgd', menuX, startY + Menu.headerH/2, Menu.width, Menu.headerH, 0.0, 145, 30, 30, 255)
            
            SetTextFont(1)
            SetTextScale(0.85, 0.85)
            SetTextColour(255, 255, 255, 255)
            SetTextCentre(true)
            SetTextDropShadow()
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName('TAGS')
            EndTextCommandDisplayText(menuX, startY + Menu.headerH/2 - 0.018)
            
            -- Subtitle bar
            local subY = startY + Menu.headerH
            DrawRect(menuX, subY + Menu.subH/2, Menu.width, Menu.subH, 0, 0, 0, 255)
            
            SetTextFont(0)
            SetTextScale(0.30, 0.30)
            SetTextColour(255, 255, 255, 255)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName('LonexDiscordAPI')
            EndTextCommandDisplayText(menuX - Menu.width/2 + 0.005, subY + 0.006)
            
            SetTextFont(0)
            SetTextScale(0.30, 0.30)
            SetTextColour(255, 255, 255, 255)
            SetTextRightJustify(true)
            SetTextWrap(0.0, menuX + Menu.width/2 - 0.005)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(MenuIndex .. ' / ' .. selectableCount)
            EndTextCommandDisplayText(menuX + Menu.width/2 - 0.005, subY + 0.006)
            
            -- Items
            local itemY = subY + Menu.subH
            local currentSelectable = 0
            
            for i, item in ipairs(items) do
                local y = itemY + (i - 1) * Menu.itemH + Menu.itemH/2
                
                if item.type == 'separator' then
                    DrawRect(menuX, y, Menu.width, Menu.itemH, 15, 15, 15, 255)
                    
                    SetTextFont(0)
                    SetTextScale(0.28, 0.28)
                    SetTextColour(100, 150, 255, 255)
                    SetTextCentre(true)
                    BeginTextCommandDisplayText('STRING')
                    AddTextComponentSubstringPlayerName(item.label)
                    EndTextCommandDisplayText(menuX, y - 0.01)
                else
                    currentSelectable = currentSelectable + 1
                    local isSelected = currentSelectable == MenuIndex
                    
                    if isSelected then
                        DrawRect(menuX, y, Menu.width, Menu.itemH, 255, 255, 255, 255)
                    else
                        DrawRect(menuX, y, Menu.width, Menu.itemH, 0, 0, 0, 160)
                    end
                    
                    local tr, tg, tb = 255, 255, 255
                    if isSelected then tr, tg, tb = 0, 0, 0 end
                    
                    SetTextFont(0)
                    SetTextScale(0.30, 0.30)
                    SetTextColour(tr, tg, tb, 255)
                    BeginTextCommandDisplayText('STRING')
                    AddTextComponentSubstringPlayerName(item.label)
                    EndTextCommandDisplayText(menuX - Menu.width/2 + 0.006, y - 0.01)
                    
                    if item.type == 'toggle' then
                        -- Checkbox using sprites
                        local checkX = menuX + Menu.width/2 - 0.018
                        local checkY = y
                        
                        if item.value then
                            if isSelected then
                                DrawSprite('commonmenu', 'shop_box_tickb', checkX, checkY, 0.022, 0.04, 0.0, 255, 255, 255, 255)
                            else
                                DrawSprite('commonmenu', 'shop_box_tick', checkX, checkY, 0.022, 0.04, 0.0, 255, 255, 255, 255)
                            end
                        else
                            if isSelected then
                                DrawSprite('commonmenu', 'shop_box_blankb', checkX, checkY, 0.022, 0.04, 0.0, 255, 255, 255, 255)
                            else
                                DrawSprite('commonmenu', 'shop_box_blank', checkX, checkY, 0.022, 0.04, 0.0, 255, 255, 255, 255)
                            end
                        end
                        
                    elseif item.type == 'tag' then
                        local swatchX = menuX + Menu.width/2 - 0.016
                        DrawRect(swatchX, y, 0.020, 0.024, item.color.r, item.color.g, item.color.b, 255)
                        
                        if item.active then
                            SetTextFont(0)
                            SetTextScale(0.35, 0.35)
                            SetTextColour(tr, tg, tb, 255)
                            SetTextRightJustify(true)
                            SetTextWrap(0.0, menuX + Menu.width/2 - 0.032)
                            BeginTextCommandDisplayText('STRING')
                            AddTextComponentSubstringPlayerName('~g~>>')
                            EndTextCommandDisplayText(menuX + Menu.width/2 - 0.032, y - 0.012)
                        end
                    end
                end
            end
            
            -- Footer gradient
            local footerY = itemY + #items * Menu.itemH
            DrawSprite('commonmenu', 'gradient_bgd', menuX, footerY + 0.012, Menu.width, 0.024, 180.0, 30, 30, 30, 255)
            
            -- Input
            DisableControlAction(0, 172, true)
            DisableControlAction(0, 173, true)
            DisableControlAction(0, 176, true)
            DisableControlAction(0, 177, true)
            DisableControlAction(0, 200, true)
            
            if IsDisabledControlJustPressed(0, 172) then
                MenuIndex = MenuIndex - 1
                if MenuIndex < 1 then MenuIndex = selectableCount end
                PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end
            
            if IsDisabledControlJustPressed(0, 173) then
                MenuIndex = MenuIndex + 1
                if MenuIndex > selectableCount then MenuIndex = 1 end
                PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end
            
            if IsDisabledControlJustPressed(0, 176) then
                local actualIndex = selectableItems[MenuIndex]
                local item = items[actualIndex]
                
                if item.type == 'toggle' then
                    if item.label:find('Others') then
                        TagsSettings.showOthers = not TagsSettings.showOthers
                        TriggerServerEvent('LonexDiscord:Tags:UpdateSettings', { showOthers = TagsSettings.showOthers })
                    else
                        TagsSettings.showOwn = not TagsSettings.showOwn
                        TriggerServerEvent('LonexDiscord:Tags:UpdateSettings', { showOwn = TagsSettings.showOwn })
                    end
                    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                    
                elseif item.type == 'tag' then
                    SelectedTagIndex = item.index
                    TriggerServerEvent('LonexDiscord:Tags:SelectTag', item.index)
                    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                end
            end
            
            if IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 200) then
                MenuOpen = false
                PlaySoundFrontend(-1, 'BACK', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end
        end
        
        Wait(MenuOpen and 0 or 500)
    end
end)

-- ============================================================================
-- EMERGENCY CALLS (Client)
-- ============================================================================

---Get the street name at current position
local function GetStreetName(coords)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    
    if crossingHash ~= 0 then
        local crossingName = GetStreetNameFromHashKey(crossingHash)
        if crossingName and crossingName ~= '' then
            return streetName .. ' / ' .. crossingName
        end
    end
    
    return streetName or 'Unknown Location'
end

---Get zone name
local function GetZoneName(coords)
    local zone = GetNameOfZone(coords.x, coords.y, coords.z)
    return GetLabelText(zone) or zone
end

-- Event: Server requests location for emergency call
RegisterNetEvent('LonexDiscord:EmergencyCall:GetLocation')
AddEventHandler('LonexDiscord:EmergencyCall:GetLocation', function(callType, message)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local street = GetStreetName(coords)
    local zone = GetZoneName(coords)
    
    local fullLocation = street
    if zone and zone ~= '' and zone ~= 'Unknown' then
        fullLocation = street .. ', ' .. zone
    end
    
    -- Send back to server
    TriggerServerEvent('LonexDiscord:EmergencyCall:Submit', callType, message, {
        x = coords.x,
        y = coords.y,
        z = coords.z,
    }, fullLocation)
end)

-- Event: Set waypoint to call location
RegisterNetEvent('LonexDiscord:EmergencyCall:SetWaypoint')
AddEventHandler('LonexDiscord:EmergencyCall:SetWaypoint', function(coords)
    if coords and coords.x and coords.y then
        SetNewWaypoint(coords.x, coords.y)
        PlaySoundFrontend(-1, 'WAYPOINT_SET', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end
end)

-- Event: Notification sound for new call
RegisterNetEvent('LonexDiscord:EmergencyCall:Notify')
AddEventHandler('LonexDiscord:EmergencyCall:Notify', function(callType, callId)
    PlaySoundFrontend(-1, 'FLIGHT_SCHOOL_LESSON_PASSED', 'HUD_AWARDS', true)
end)

-- ============================================================================
-- SERVER UTILITIES (AOP, PeaceTime, Announcements, Postals, HUD)
-- ============================================================================

local ServerUtils = {
    AOP = nil,
    PeaceTime = false,
    HUDEnabled = true,
    NearestPostal = nil,
    NearestPostalDist = 0,
}

-- Announcement display state
local CurrentAnnouncement = nil
local AnnouncementEndTime = 0

-- Cached location data (updated periodically, not every frame)
local CachedStreet = ''
local CachedZone = ''
local CachedPostal = '---'
local CachedCompass = 'N'

---Get compass direction from heading
local function GetCompassDirection(heading)
    local directions = { [0] = 'N', [45] = 'NE', [90] = 'E', [135] = 'SE', [180] = 'S', [225] = 'SW', [270] = 'W', [315] = 'NW', [360] = 'N' }
    local h = math.floor((heading + 22.5) % 360 / 45) * 45
    return directions[h] or 'N'
end

---Get current street and zone
local function GetLocationInfo()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash) or ''
    
    local zone = GetNameOfZone(coords.x, coords.y, coords.z)
    local zoneName = GetLabelText(zone)
    if zoneName == 'NULL' then zoneName = zone end
    
    -- If there's a crossing, show it in the zone line
    local zoneDisplay = zoneName
    if crossingHash ~= 0 then
        local crossing = GetStreetNameFromHashKey(crossingHash)
        if crossing and crossing ~= '' then
            zoneDisplay = crossing .. ', ' .. zoneName
        end
    end
    
    return street, zoneDisplay
end

---Find nearest postal
local function UpdateNearestPostal()
    if not Postals then return end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    local nearest = nil
    local nearestDist = 999999
    
    for _, postal in ipairs(Postals) do
        local dist = #(coords - vector3(postal.x, postal.y, coords.z))
        if dist < nearestDist then
            nearestDist = dist
            nearest = postal
        end
    end
    
    ServerUtils.NearestPostal = nearest and nearest.code or nil
    ServerUtils.NearestPostalDist = math.floor(nearestDist)
end

---Draw text helper
local function Draw2DText(x, y, text, scale)
    SetTextFont(4)
    SetTextProportional(7)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

---Get player's current tag (if using Tags system)
local function GetPlayerTag()
    if not Config.Tags or not Config.Tags.Enabled then return 'Player' end
    
    local playerId = GetPlayerServerId(PlayerId())
    local playerData = TagsData[playerId]
    
    if playerData and playerData.tag and playerData.tag.text then
        return playerData.tag.text
    end
    
    return 'Player'
end

---Replace placeholders in display text
local function ReplaceDisplayPlaceholders(text)
    local replacements = {
        ['{AOP}'] = ServerUtils.AOP or 'All of San Andreas',
        ['{CURRENT_AOP}'] = ServerUtils.AOP or 'All of San Andreas',
        ['{PEACETIME}'] = ServerUtils.PeaceTime and '~g~ON' or '~r~OFF',
        ['{STREET}'] = CachedStreet or 'Unknown',
        ['{STREET_NAME}'] = CachedStreet or 'Unknown',
        ['{ZONE}'] = CachedZone or 'Unknown',
        ['{CITY}'] = CachedZone or 'Unknown',
        ['{COMPASS}'] = CachedCompass or 'N',
        ['{POSTAL}'] = CachedPostal or '---',
        ['{NEAREST_POSTAL}'] = CachedPostal or '---',
        ['{POSTAL_DIST}'] = tostring(ServerUtils.NearestPostalDist or 0),
        ['{NEAREST_POSTAL_DISTANCE}'] = tostring(ServerUtils.NearestPostalDist or 0),
        ['{ID}'] = tostring(GetPlayerServerId(PlayerId())),
        ['{PLAYERS}'] = tostring(#GetActivePlayers()),
        ['{TAG}'] = GetPlayerTag(),
    }
    
    for placeholder, value in pairs(replacements) do
        text = text:gsub(placeholder, value)
    end
    
    return text
end

---Draw the configurable HUD displays
local function DrawConfigurableHUD()
    if not Config.ServerHUD or not Config.ServerHUD.Enabled then return end
    if not ServerUtils.HUDEnabled then return end
    
    -- Draw watermark if enabled
    if Config.ServerHUD.Watermark and Config.ServerHUD.Watermark.Enabled then
        local wm = Config.ServerHUD.Watermark
        Draw2DText(wm.x or 0.165, wm.y or 0.80, wm.Text or '', wm.scale or 0.35)
    end
    
    -- Draw configurable displays
    if Config.ServerHUD.Displays then
        for name, display in pairs(Config.ServerHUD.Displays) do
            if display.enabled then
                local text = ReplaceDisplayPlaceholders(display.display)
                Draw2DText(display.x, display.y, text, display.scale or 0.4)
            end
        end
    end
end

-- Check if any utility feature is enabled
local function AnyUtilityEnabled()
    return (Config.AOP and Config.AOP.Enabled) or
           (Config.PeaceTime and Config.PeaceTime.Enabled) or
           (Config.Announcements and Config.Announcements.Enabled) or
           (Config.Postals and Config.Postals.Enabled) or
           (Config.ServerHUD and Config.ServerHUD.Enabled)
end

-- Request state on spawn
CreateThread(function()
    Wait(2000)
    if AnyUtilityEnabled() then
        TriggerServerEvent('LonexDiscord:Utils:RequestState')
    end
end)

-- Sync state from server
RegisterNetEvent('LonexDiscord:Utils:SyncState')
AddEventHandler('LonexDiscord:Utils:SyncState', function(state)
    if state.aop then ServerUtils.AOP = state.aop end
    if state.peacetime ~= nil then ServerUtils.PeaceTime = state.peacetime end
end)

-- AOP changed
RegisterNetEvent('LonexDiscord:AOP:Changed')
AddEventHandler('LonexDiscord:AOP:Changed', function(newAOP)
    ServerUtils.AOP = newAOP
end)

-- PeaceTime changed
RegisterNetEvent('LonexDiscord:PeaceTime:Changed')
AddEventHandler('LonexDiscord:PeaceTime:Changed', function(enabled)
    ServerUtils.PeaceTime = enabled
end)

-- PeaceTime Restrictions Enforcement
local LastSpeedWarning = 0

-- Display notification helper
local function ShowPeaceTimeNotification(message)
    SetTextComponentFormat('STRING')
    AddTextComponentString(message)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

-- PeaceTime weapon restriction thread
CreateThread(function()
    while true do
        local sleep = 500
        
        -- Only enforce if PeaceTime is enabled and restrictions are configured
        if ServerUtils.PeaceTime and Config.PeaceTime and Config.PeaceTime.Restrictions then
            local restrictions = Config.PeaceTime.Restrictions
            
            -- Disable weapons
            if restrictions.DisableWeapons then
                sleep = 0
                local playerPed = PlayerPedId()
                local currentWeapon = GetSelectedPedWeapon(playerPed)
                
                -- Check if player has a weapon out (not unarmed)
                if currentWeapon ~= GetHashKey('WEAPON_UNARMED') then
                    -- Remove the weapon and show notification
                    SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true)
                    local msg = Config.PeaceTime.Messages and Config.PeaceTime.Messages.WeaponBlocked or '~r~Weapons are disabled during PeaceTime!'
                    ShowPeaceTimeNotification(msg)
                    PlaySoundFrontend(-1, 'ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                end
                
                -- Disable firing (extra protection)
                DisablePlayerFiring(playerPed, true)
            end
        end
        
        Wait(sleep)
    end
end)

-- PeaceTime speed restriction thread
CreateThread(function()
    while true do
        local sleep = 1000
        
        -- Only enforce if PeaceTime is enabled and speed limit is configured
        if ServerUtils.PeaceTime and Config.PeaceTime and Config.PeaceTime.Restrictions then
            local speedConfig = Config.PeaceTime.Restrictions.SpeedLimit
            
            if speedConfig and speedConfig.Enabled then
                local playerPed = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                
                if vehicle ~= 0 then
                    -- Get speed in m/s and convert
                    local speedMs = GetEntitySpeed(vehicle)
                    local speed, limit, unit
                    
                    if speedConfig.Unit == 'kmh' then
                        speed = speedMs * 3.6  -- Convert to km/h
                        limit = speedConfig.Limit or 105
                        unit = 'km/h'
                    else
                        speed = speedMs * 2.236936  -- Convert to mph
                        limit = speedConfig.Limit or 65
                        unit = 'mph'
                    end
                    
                    -- Check if over the limit
                    if speed > limit then
                        local now = GetGameTimer()
                        local interval = (speedConfig.WarningInterval or 5) * 1000
                        
                        if now - LastSpeedWarning > interval then
                            LastSpeedWarning = now
                            local msg = Config.PeaceTime.Messages and Config.PeaceTime.Messages.SpeedWarning or '~y~Slow down! Speed limit during PeaceTime is %s %s'
                            ShowPeaceTimeNotification(string.format(msg, limit, unit))
                            PlaySoundFrontend(-1, 'RACE_PLACED', 'HUD_AWARDS', true)
                        end
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Announcement received
RegisterNetEvent('LonexDiscord:Announcement:Show')
AddEventHandler('LonexDiscord:Announcement:Show', function(data)
    CurrentAnnouncement = data
    AnnouncementEndTime = GetGameTimer() + (data.duration * 1000)
    PlaySoundFrontend(-1, 'FLIGHT_SCHOOL_LESSON_PASSED', 'HUD_AWARDS', true)
end)

-- Set postal waypoint
RegisterNetEvent('LonexDiscord:Postal:Set')
AddEventHandler('LonexDiscord:Postal:Set', function(postal)
    if postal and postal.x and postal.y then
        SetNewWaypoint(postal.x, postal.y)
        PlaySoundFrontend(-1, 'WAYPOINT_SET', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end
end)

-- Cancel postal waypoint
RegisterNetEvent('LonexDiscord:Postal:Cancel')
AddEventHandler('LonexDiscord:Postal:Cancel', function()
    if IsWaypointActive() then
        SetWaypointOff()
    end
end)

-- HUD toggle command
CreateThread(function()
    Wait(1000)
    
    if not Config.ServerHUD or not Config.ServerHUD.Enabled then return end
    
    if Config.ServerHUD.ToggleCommand then
        RegisterCommand(Config.ServerHUD.ToggleCommand, function()
            ServerUtils.HUDEnabled = not ServerUtils.HUDEnabled
            if ServerUtils.HUDEnabled then
                TriggerEvent('chat:addMessage', { args = { '^2HUD enabled.' } })
            else
                TriggerEvent('chat:addMessage', { args = { '^1HUD disabled.' } })
            end
        end, false)
    end
end)

-- Update nearest postal and location periodically
CreateThread(function()
    while true do
        Wait(200) -- Update more frequently for smoother compass
        
        if (Config.Postals and Config.Postals.Enabled) or (Config.ServerHUD and Config.ServerHUD.Enabled) then
            UpdateNearestPostal()
            CachedPostal = ServerUtils.NearestPostal or '---'
        end
        
        if Config.ServerHUD and Config.ServerHUD.Enabled then
            -- Update location info
            local street, zone = GetLocationInfo()
            CachedStreet = street or 'Unknown'
            CachedZone = zone or 'Unknown'
            
            -- Update compass
            local playerPed = PlayerPedId()
            local heading = GetEntityHeading(playerPed)
            CachedCompass = GetCompassDirection(heading)
        end
    end
end)

-- HUD and Announcement render loop
CreateThread(function()
    while true do
        local sleep = 500
        
        -- Draw HUD
        if Config.ServerHUD and Config.ServerHUD.Enabled and ServerUtils.HUDEnabled then
            sleep = 0
            DrawConfigurableHUD()
        end
        
        -- Draw announcement
        if CurrentAnnouncement and GetGameTimer() < AnnouncementEndTime then
            sleep = 0
            
            local y = CurrentAnnouncement.position or 0.3
            
            -- Draw header
            SetTextFont(4)
            SetTextScale(0.6, 0.6)
            SetTextColour(255, 255, 255, 255)
            SetTextCentre(true)
            SetTextOutline()
            SetTextEntry('STRING')
            AddTextComponentString(CurrentAnnouncement.header or '~b~[~p~Announcement~b~]')
            DrawText(0.5, y)
            
            -- Draw message
            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextCentre(true)
            SetTextOutline()
            SetTextEntry('STRING')
            AddTextComponentString(CurrentAnnouncement.message)
            DrawText(0.5, y + 0.04)
        else
            CurrentAnnouncement = nil
        end
        
        Wait(sleep)
    end
end)
