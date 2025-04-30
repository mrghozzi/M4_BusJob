local QBCore = exports['qb-core']:GetCoreObject()

local allowedJob = "busdriver" -- غيّره حسب الوظيفة المطلوبة

local function isPlayerBusDriver()
    local PlayerData = QBCore.Functions.GetPlayerData()
    return PlayerData and PlayerData.job and PlayerData.job.name == allowedJob
end

local busSpawnLocation = vector3(452.31, -583.75, 28.5) -- Bus Depot
local busModel = 'bus'

local busLines = {
    {
        name = 'South Loop', number = 1, color = {r = 255, g = 0, b = 0}, 
        stations = {
            vector3(465.98, -632.11, 28.5), -- Bus Depot
            vector3(309.64, -765.13, 29.31), -- Station 1
            vector3(269.74, -1220.24, 29.51), -- Station 2
            vector3(-106.16, -1689.55, 29.32), -- Station 3
            vector3(-142.1, -1975.86, 22.82), -- Station 4
            vector3(200.29, -1972.3, 19.33), -- Station 5
            vector3(442.45, -1683.33, 28.75), -- Station 6
            vector3(468.06, -1413.67, 28.74),   -- Station 7
            vector3(269.72, -1220.39, 29.0),    -- Station 8
            vector3(358.17, -1061.67, 28.82),    -- Station 9
            vector3(471.82, -826.59, 25.81) -- Station 10
        }
    },    
    {
        name = 'Vespucci Line', number = 2, color = {r = 0, g = 0, b = 255},
        stations = {
            vector3(465.98, -632.11, 28.5), -- Bus Depot
            vector3(309.64, -765.13, 29.31), -- Station 1
            vector3(114.78, -787.79, 31.42), -- Station 2
            vector3(-170.96, -820.02, 30.7), -- Station 3
            vector3(-273.25, -823.37, 31.37), -- Station 4
            vector3(-598.03, -649.42, 31.5), -- Station 5
            vector3(-933.62, -461.04, 36.73), -- Station 6
            vector3(-1158.26, -401.45, 35.37), -- Station 7
            vector3(-1408.38, -571.79, 29.91), -- Station 8
            vector3(-1210.48, -1218.54, 7.23), -- Station 9
            vector3(-1167.78, -1468.44, 3.92), -- Station 10
            vector3(-1143.69, -1367.62, 4.63), -- Station 11
            vector3(-1255.36, -1030.5, 8.4), -- Station 12
            vector3(-1477.36, -629.93, 30.19), -- Station 13
            vector3(-1046.96, -387.6, 37.16), -- Station 14
            vector3(-692.09, -666.17, 30.45), -- Station 15
            vector3(-506.18, -665.73, 32.66), -- Station 16
            vector3(-241.58, -716.72, 33.03), -- Station 17
            vector3(-248.92, -880.45, 30.23), -- Station 18
            vector3(214.55, -847.17, 29.86), -- Station 19
            vector3(309.64, -765.13, 29.31),  -- Station 20
            vector3(471.82, -826.59, 25.81) -- Station 21
        }
    },
    {
        name = 'University Route', number = 3, color = {r = 0, g = 255, b = 0},
        stations = {
            vector3(1843.2, 3682.3, 34.3),
            vector3(1461.7, 3570.6, 34.4),
            vector3(989.2, 1567.3, 34.8),
            vector3(462.3, 1315.6, 30.9),
            vector3(260.1, 1193.3, 224.2),
            vector3(-161.6, 937.5, 234.0)
        }
    },
    {
        name = 'Industrial Circle', number = 4, color = {r = 255, g = 255, b = 0},
        stations = {
            vector3(1122.1, -3197.1, -40.4),
            vector3(880.2, -2351.9, 29.3),
            vector3(814.7, -1237.3, 26.0),
            vector3(763.2, -885.2, 25.1),
            vector3(960.3, -539.6, 58.9),
            vector3(2744.6, 1501.8, 24.5)
        }
    },
    {
        name = 'Rural Shuttle', number = 5, color = {r = 128, g = 0, b = 128},
        stations = {
            vector3(1702.4, 4916.5, 42.1),
            vector3(1965.6, 5184.3, 47.9),
            vector3(1842.3, 3655.5, 34.2),
            vector3(1152.4, 2653.9, 37.7),
            vector3(-180.2, 6271.4, 31.5),
            vector3(-2122.4, 3245.2, 32.8)
        }
    },
    {
        name = 'Tourist Loop', number = 6, color = {r = 255, g = 165, b = 0},
        stations = {
            vector3(-1612.9, -1024.5, 13.0),
            vector3(-1305.5, 252.3, 62.1),
            vector3(711.1, 1197.6, 325.4),
            vector3(364.9, 282.5, 103.6),
            vector3(1069.4, -686.6, 58.3),
            vector3(-1028.3, -1003.8, 1.0)
        }
    }
}

local activeBlips = {}

local function showBusLinesMenu()
    if not isPlayerBusDriver() then
        QBCore.Functions.Notify('You are not a bus driver!', 'error')
        return
    end

    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle ~= 0 and GetEntityModel(vehicle) == GetHashKey(busModel) then
        QBCore.Functions.Notify('You are already in the bus!', 'error')
        return
    end

    local menu = {}
    for _, line in ipairs(busLines) do
        table.insert(menu, {
            header = line.name,
            txt = 'Number: ' .. line.number,
            params = {
                event = 'spawnBusWithLine',
                args = line
            }
        })
    end
    TriggerEvent('qb-menu:client:openMenu', menu)
end

local function createBlipsForLine(line)
    for _, blip in ipairs(activeBlips) do RemoveBlip(blip) end
    activeBlips = {}
    for _, station in ipairs(line.stations) do
        local blip = AddBlipForCoord(station.x, station.y, station.z)
        SetBlipSprite(blip, 1)
        SetBlipColour(blip, 3)
        SetBlipScale(blip, 0.8)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(line.name .. " Station")
        EndTextCommandSetBlipName(blip)
        table.insert(activeBlips, blip)
    end
end

-- Event to spawn bus with line
RegisterNetEvent('spawnBusWithLine', function(line)
    if not isPlayerBusDriver() then
        QBCore.Functions.Notify('You are not a bus driver!', 'error')
        return
    end

    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle ~= 0 and GetEntityModel(vehicle) == GetHashKey(busModel) then
        QBCore.Functions.Notify('You are already in the bus!', 'error')
        return
    end

    RequestModel(busModel)
    while not HasModelLoaded(busModel) do Wait(0) end

    local bus = CreateVehicle(GetHashKey(busModel), busSpawnLocation.x, busSpawnLocation.y, busSpawnLocation.z, 263.27, true, false)
    SetVehicleCustomPrimaryColour(bus, line.color.r, line.color.g, line.color.b)
    TaskWarpPedIntoVehicle(playerPed, bus, -1)
    TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(bus)) -- Set the vehicle keys
    SetModelAsNoLongerNeeded(busModel)

    QBCore.Functions.Notify('Bus for ' .. line.name .. ' has been spawned!', 'warning')
    createBlipsForLine(line)

    CreateThread(function()
        while true do
            for i, station in ipairs(line.stations) do
                SetNewWaypoint(station.x, station.y)
                QBCore.Functions.Notify('GPS route set to station ' .. i .. ' of ' .. line.name, 'success')
                local reached = false
                while not reached do
                    Wait(1000)
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    if #(playerCoords - station) < 10.0 then
                        reached = true
                    end
                end
                QBCore.Functions.Notify('You have reached station ' .. i .. ' of ' .. line.name, 'success')
                QBCore.Functions.Notify('Press K to open the bus doors.', 'primary')
                local doorsOpened = false
                while not doorsOpened do
                    Wait(0)
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    if vehicle ~= 0 and GetEntityModel(vehicle) == GetHashKey(busModel) then
                        if GetVehicleDoorLockStatus(vehicle) == 1 then
                            doorsOpened = true
                        end
                    end
                end
                QBCore.Functions.Notify('Wait 5 seconds before moving.', 'primary')
                Wait(5000)
            end
            QBCore.Functions.Notify('All stations for ' .. line.name .. ' completed! Restarting.', 'warning')
        end
    end)
end)

local function deleteBus()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle ~= 0 and GetEntityModel(vehicle) == GetHashKey(busModel) then
        DeleteVehicle(vehicle)
        QBCore.Functions.Notify('Bus deleted!', 'success')
        for _, blip in ipairs(activeBlips) do RemoveBlip(blip) end
        activeBlips = {}
        SetWaypointOff()
    else
        QBCore.Functions.Notify('You are not in the bus!', 'error')
    end
end

local function toggleBusDoors()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle ~= 0 and GetEntityModel(vehicle) == GetHashKey(busModel) then
        local doorState = GetVehicleDoorLockStatus(vehicle)
        if doorState == 1 then
            SetVehicleDoorsLocked(vehicle, 2)
            for i = 0, GetNumberOfVehicleDoors(vehicle) - 1 do SetVehicleDoorShut(vehicle, i, false) end
            QBCore.Functions.Notify('Doors locked.', 'success')
        else
            SetVehicleDoorsLocked(vehicle, 1)
            for i = 0, GetNumberOfVehicleDoors(vehicle) - 1 do SetVehicleDoorOpen(vehicle, i, false, false) end
            QBCore.Functions.Notify('Doors opened.', 'success')
        end
    else
        QBCore.Functions.Notify('You are not in the bus!', 'error')
    end
end

CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustReleased(0, 311) then
            toggleBusDoors()
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - busSpawnLocation)

        if distance < 10.0 then
            DrawMarker(
                1,              -- marker type
                busSpawnLocation.x, busSpawnLocation.y, busSpawnLocation.z - 1.0,  -- marker position
                0, 0, 0,        -- marker direction
                0, 0, 0,        -- marker rotation
                2.0, 2.0, 3.0,  -- size
                255, 255, 0,    -- color
                100,            -- alpha
                false, true, 2, nil, nil, false -- bob up and down, face camera, draw on ground
            )      
            if distance < 1.5 then
                QBCore.Functions.DrawText3D(busSpawnLocation.x, busSpawnLocation.y, busSpawnLocation.z, '[E] Select Bus Line | [G] Delete Bus')

                if IsControlJustReleased(0, 38) then
                    showBusLinesMenu()
                elseif IsControlJustReleased(0, 47) then
                    deleteBus()
                end
            end
        end
    end
end)

-- Create a blip for the bus spawn location
CreateThread(function()
    local blip = AddBlipForCoord(busSpawnLocation.x, busSpawnLocation.y, busSpawnLocation.z)
    SetBlipSprite(blip, 513)            -- Bus icon
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.6)             -- Blip size
    SetBlipColour(blip, 5)              --  Yellow color
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Bus Depot")
    EndTextCommandSetBlipName(blip)
end)