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

-- HEADTAGS CLIENT

local HeadTagsData = {}
local HeadTagsSettings = {
    showOthers = true,
    showOwn = true,
}
local HeadTagsAvailable = {}
local HeadTagsSelectedIndex = 1
local HeadTagsMenuOpen = false
local HeadTagsMenuIndex = 1

local function DrawText3D(x, y, z, text, r, g, b, a, scale, font)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(scale or 0.4, scale or 0.4)
        SetTextFont(font or 4)
        SetTextProportional(true)
        SetTextColour(r or 255, g or 255, b or 255, a or 255)
        SetTextOutline()
        SetTextEntry('STRING')
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

local function GetHeadTagDisplayText(playerId, tagData)
    local tag = tagData.tag and tagData.tag.text or 'Player'
    local name = tagData.name or 'Unknown'
    return string.format('%s | [%d] %s', tag, playerId, name)
end

-- Simple menu drawing functions
local function DrawMenuRect(x, y, width, height, r, g, b, a)
    DrawRect(x + width/2, y + height/2, width, height, r, g, b, a)
end

local function DrawMenuText(text, x, y, scale, r, g, b, a, font, alignment)
    SetTextFont(font or 0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    if alignment == 1 then
        SetTextCentre(true)
    elseif alignment == 2 then
        SetTextRightJustify(true)
        SetTextWrap(0, x)
    end
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

RegisterNetEvent('LonexDiscord:HeadTags:SyncAll')
AddEventHandler('LonexDiscord:HeadTags:SyncAll', function(allTags, settings, available, selectedIndex)
    HeadTagsData = allTags or {}
    if settings then
        HeadTagsSettings.showOthers = settings.showOthers ~= false
        HeadTagsSettings.showOwn = settings.showOwn ~= false
    end
    if available then HeadTagsAvailable = available end
    if selectedIndex then HeadTagsSelectedIndex = selectedIndex end
end)

RegisterNetEvent('LonexDiscord:HeadTags:UpdatePlayerTag')
AddEventHandler('LonexDiscord:HeadTags:UpdatePlayerTag', function(playerId, tagData)
    HeadTagsData[playerId] = tagData
end)

RegisterNetEvent('LonexDiscord:HeadTags:PlayerLeft')
AddEventHandler('LonexDiscord:HeadTags:PlayerLeft', function(playerId)
    HeadTagsData[playerId] = nil
end)

RegisterNetEvent('LonexDiscord:HeadTags:OpenMenu')
AddEventHandler('LonexDiscord:HeadTags:OpenMenu', function(available, selectedIndex, settings)
    if available then HeadTagsAvailable = available end
    if selectedIndex then HeadTagsSelectedIndex = selectedIndex end
    if settings then
        HeadTagsSettings.showOthers = settings.showOthers ~= false
        HeadTagsSettings.showOwn = settings.showOwn ~= false
    end
    HeadTagsMenuOpen = true
    HeadTagsMenuIndex = 1
    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end)

AddEventHandler('playerSpawned', function()
    if Config.HeadTags and Config.HeadTags.Enabled then
        TriggerServerEvent('LonexDiscord:HeadTags:RequestSync')
    end
end)

-- HeadTags 3D rendering
CreateThread(function()
    while true do
        local sleep = 500
        if Config.HeadTags and Config.HeadTags.Enabled and (HeadTagsSettings.showOthers or HeadTagsSettings.showOwn) then
            sleep = 0
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local maxDist = Config.HeadTags.MaxDistance or 20.0
            local heightOffset = Config.HeadTags.HeightOffset or 1.0
            local scale = Config.HeadTags.Scale or 0.4
            local font = Config.HeadTags.Font or 4
            local myId = PlayerId()
            
            for playerId, tagData in pairs(HeadTagsData) do
                local targetPlayer = GetPlayerFromServerId(playerId)
                if targetPlayer ~= -1 then
                    local isMe = targetPlayer == myId
                    local shouldShow = (isMe and HeadTagsSettings.showOwn) or (not isMe and HeadTagsSettings.showOthers)
                    
                    if shouldShow then
                        local targetPed = GetPlayerPed(targetPlayer)
                        if DoesEntityExist(targetPed) and not IsEntityDead(targetPed) then
                            local targetCoords = GetEntityCoords(targetPed)
                            local dist = #(playerCoords - targetCoords)
                            if dist <= maxDist then
                                local tag = tagData.tag or Config.HeadTags.DefaultTag
                                local color = tag.color or { r = 255, g = 255, b = 255 }
                                DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + heightOffset,
                                    GetHeadTagDisplayText(playerId, tagData),
                                    color.r, color.g, color.b, 255, scale, font)
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- HeadTags Menu
CreateThread(function()
    while true do
        if HeadTagsMenuOpen then
            -- Menu configuration
            local menuX = 0.75
            local menuY = 0.15
            local menuW = 0.25
            local headerH = 0.035
            local itemH = 0.035
            local padding = 0.005
            
            -- Build items list
            local menuItems = {
                { type = 'checkbox', label = "Show Other's Headtags", checked = HeadTagsSettings.showOthers },
                { type = 'checkbox', label = "Show Your Headtag", checked = HeadTagsSettings.showOwn },
                { type = 'separator', label = "SELECT HEADTAG" },
            }
            
            for i, tag in ipairs(HeadTagsAvailable) do
                table.insert(menuItems, {
                    type = 'tag',
                    label = tag.text or 'Unknown',
                    color = tag.color or {r=255,g=255,b=255},
                    tagIndex = i,
                    selected = (i == HeadTagsSelectedIndex)
                })
            end
            
            local itemCount = #menuItems
            local totalH = headerH + (itemCount * itemH) + headerH + padding * 2
            
            -- Background
            DrawMenuRect(menuX, menuY, menuW, totalH, 0, 0, 0, 230)
            
            -- Header
            DrawMenuRect(menuX, menuY, menuW, headerH, 140, 0, 0, 255)
            DrawMenuText("HEADTAGS", menuX + menuW/2, menuY + 0.006, 0.45, 255, 255, 255, 255, 1, 1)
            
            -- Subtitle
            local subY = menuY + headerH
            DrawMenuRect(menuX, subY, menuW, headerH * 0.7, 0, 0, 0, 255)
            DrawMenuText("LonexDiscordAPI", menuX + padding, subY + 0.005, 0.3, 255, 255, 255, 200, 0, 0)
            
            -- Items
            local currentY = subY + headerH * 0.7 + padding
            
            for i, item in ipairs(menuItems) do
                local itemY = currentY + (i - 1) * itemH
                local isHovered = (i == HeadTagsMenuIndex)
                
                if item.type == 'separator' then
                    -- Separator
                    DrawMenuRect(menuX, itemY, menuW, itemH, 30, 30, 30, 255)
                    DrawMenuText(item.label, menuX + menuW/2, itemY + 0.008, 0.28, 150, 150, 150, 255, 0, 1)
                else
                    -- Regular item
                    if isHovered then
                        DrawMenuRect(menuX, itemY, menuW, itemH, 255, 255, 255, 255)
                    end
                    
                    local tr, tg, tb = 255, 255, 255
                    if isHovered then tr, tg, tb = 0, 0, 0 end
                    
                    DrawMenuText(item.label, menuX + padding, itemY + 0.008, 0.32, tr, tg, tb, 255, 0, 0)
                    
                    if item.type == 'checkbox' then
                        local status = item.checked and "ON" or "OFF"
                        local sr, sg, sb = 100, 255, 100
                        if not item.checked then sr, sg, sb = 255, 100, 100 end
                        if isHovered then
                            sr, sg, sb = 0, 100, 0
                            if not item.checked then sr, sg, sb = 100, 0, 0 end
                        end
                        DrawMenuText(status, menuX + menuW - padding, itemY + 0.008, 0.32, sr, sg, sb, 255, 0, 2)
                        
                    elseif item.type == 'tag' then
                        -- Color swatch
                        local swatchX = menuX + menuW - padding - 0.015
                        local swatchY = itemY + itemH/2
                        DrawRect(swatchX, swatchY, 0.015, 0.018, item.color.r, item.color.g, item.color.b, 255)
                        
                        -- Selected indicator
                        if item.selected then
                            DrawMenuText(">", menuX + menuW - padding - 0.035, itemY + 0.008, 0.32, tr, tg, tb, 255, 0, 0)
                        end
                    end
                end
            end
            
            -- Footer
            local footerY = currentY + itemCount * itemH
            DrawMenuRect(menuX, footerY, menuW, headerH, 0, 0, 0, 255)
            DrawMenuText("UP/DOWN  ENTER  ESC", menuX + menuW/2, footerY + 0.008, 0.25, 200, 200, 200, 200, 0, 1)
            
            -- Input handling
            DisableControlAction(0, 200, true)
            
            -- Navigate up
            if IsDisabledControlJustPressed(0, 172) then
                repeat
                    HeadTagsMenuIndex = HeadTagsMenuIndex - 1
                    if HeadTagsMenuIndex < 1 then HeadTagsMenuIndex = itemCount end
                until menuItems[HeadTagsMenuIndex].type ~= 'separator'
                PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end
            
            -- Navigate down
            if IsDisabledControlJustPressed(0, 173) then
                repeat
                    HeadTagsMenuIndex = HeadTagsMenuIndex + 1
                    if HeadTagsMenuIndex > itemCount then HeadTagsMenuIndex = 1 end
                until menuItems[HeadTagsMenuIndex].type ~= 'separator'
                PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end
            
            -- Select
            if IsDisabledControlJustPressed(0, 176) then
                local item = menuItems[HeadTagsMenuIndex]
                if item.type == 'checkbox' then
                    if HeadTagsMenuIndex == 1 then
                        HeadTagsSettings.showOthers = not HeadTagsSettings.showOthers
                        TriggerServerEvent('LonexDiscord:HeadTags:UpdateMySettings', { showOthers = HeadTagsSettings.showOthers })
                    elseif HeadTagsMenuIndex == 2 then
                        HeadTagsSettings.showOwn = not HeadTagsSettings.showOwn
                        TriggerServerEvent('LonexDiscord:HeadTags:UpdateMySettings', { showOwn = HeadTagsSettings.showOwn })
                    end
                    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                elseif item.type == 'tag' then
                    HeadTagsSelectedIndex = item.tagIndex
                    TriggerServerEvent('LonexDiscord:HeadTags:SelectTag', item.tagIndex)
                    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                end
            end
            
            -- Close
            if IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 200) then
                HeadTagsMenuOpen = false
                PlaySoundFrontend(-1, 'BACK', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end
        end
        
        Wait(HeadTagsMenuOpen and 0 or 500)
    end
end)
