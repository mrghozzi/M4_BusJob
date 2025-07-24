local QBCore = exports['qb-core']:GetCoreObject()

local allowedJob = "busdriver" -- Change this to the job name you want to allowedJob 

local function isPlayerBusDriver()
    local PlayerData = QBCore.Functions.GetPlayerData()
    return PlayerData and PlayerData.job and PlayerData.job.name == allowedJob
end

local busSpawnLocation = vector3(452.31, -583.75, 28.5) -- Bus Depot
local busModel = 'bus'

-- Dashboard variables
local activeBusLine = nil
local currentStationIndex = 0
local nextStationIndex = 0
local showDashboard = false

-- Passenger variables
local passengers = {}
local maxPassengers = 15
local currentPassengers = 0
local passengerModels = {'a_f_m_beach_01', 'a_f_m_bevhills_01', 'a_f_m_bevhills_02', 'a_f_m_bodybuild_01', 'a_f_m_business_02', 'a_f_m_downtown_01', 'a_f_m_eastsa_01', 'a_f_m_eastsa_02', 'a_f_m_fatbla_01', 'a_f_m_fatwhite_01', 'a_f_m_ktown_01', 'a_f_m_ktown_02', 'a_f_m_prolhost_01', 'a_f_m_salton_01', 'a_f_m_skidrow_01', 'a_f_m_soucent_01', 'a_f_m_soucent_02', 'a_f_m_soucentmc_01', 'a_f_m_tourist_01', 'a_f_m_tramp_01', 'a_f_m_trampbeac_01', 'a_f_o_genstreet_01', 'a_f_o_indian_01', 'a_f_o_ktown_01', 'a_f_o_salton_01', 'a_f_o_soucent_01', 'a_f_o_soucent_02', 'a_f_y_beach_01', 'a_f_y_bevhills_01', 'a_f_y_bevhills_02', 'a_f_y_bevhills_03', 'a_f_y_bevhills_04', 'a_f_y_business_01', 'a_f_y_business_02', 'a_f_y_business_03', 'a_f_y_business_04', 'a_f_y_eastsa_01', 'a_f_y_eastsa_02', 'a_f_y_eastsa_03', 'a_f_y_epsilon_01', 'a_f_y_fitness_01', 'a_f_y_fitness_02', 'a_f_y_genhot_01', 'a_f_y_golfer_01', 'a_f_y_hiker_01', 'a_f_y_hippie_01', 'a_f_y_hipster_01', 'a_f_y_hipster_02', 'a_f_y_hipster_03', 'a_f_y_hipster_04', 'a_f_y_indian_01', 'a_f_y_juggalo_01', 'a_f_y_runner_01', 'a_f_y_rurmeth_01', 'a_f_y_scdressy_01', 'a_f_y_skater_01', 'a_f_y_soucent_01', 'a_f_y_soucent_02', 'a_f_y_soucent_03', 'a_f_y_tennis_01', 'a_f_y_topless_01', 'a_f_y_tourist_01', 'a_f_y_tourist_02', 'a_f_y_vinewood_01', 'a_f_y_vinewood_02', 'a_f_y_vinewood_03', 'a_f_y_vinewood_04', 'a_f_y_yoga_01', 'a_m_m_acult_01', 'a_m_m_afriamer_01', 'a_m_m_beach_01', 'a_m_m_beach_02', 'a_m_m_bevhills_01', 'a_m_m_bevhills_02', 'a_m_m_business_01', 'a_m_m_eastsa_01', 'a_m_m_eastsa_02', 'a_m_m_farmer_01', 'a_m_m_fatlatin_01', 'a_m_m_genfat_01', 'a_m_m_genfat_02', 'a_m_m_golfer_01', 'a_m_m_hasjew_01', 'a_m_m_hillbilly_01', 'a_m_m_hillbilly_02', 'a_m_m_indian_01', 'a_m_m_ktown_01', 'a_m_m_malibu_01', 'a_m_m_mexcntry_01', 'a_m_m_mexlabor_01', 'a_m_m_og_boss_01', 'a_m_m_paparazzi_01', 'a_m_m_polynesian_01', 'a_m_m_prolhost_01', 'a_m_m_rurmeth_01', 'a_m_m_salton_01', 'a_m_m_salton_02', 'a_m_m_salton_03', 'a_m_m_salton_04', 'a_m_m_skater_01', 'a_m_m_skidrow_01', 'a_m_m_socenlat_01', 'a_m_m_soucent_01', 'a_m_m_soucent_02', 'a_m_m_soucent_03', 'a_m_m_soucent_04', 'a_m_m_stlat_02', 'a_m_m_tennis_01', 'a_m_m_tourist_01', 'a_m_m_tramp_01', 'a_m_m_trampbeac_01', 'a_m_m_tranvest_01', 'a_m_m_tranvest_02', 'a_m_o_acult_01', 'a_m_o_acult_02', 'a_m_o_beach_01', 'a_m_o_genstreet_01', 'a_m_o_ktown_01', 'a_m_o_salton_01', 'a_m_o_soucent_01', 'a_m_o_soucent_02', 'a_m_o_soucent_03', 'a_m_o_tramp_01', 'a_m_y_acult_01', 'a_m_y_acult_02', 'a_m_y_beach_01', 'a_m_y_beach_02', 'a_m_y_beach_03', 'a_m_y_beachvesp_01', 'a_m_y_beachvesp_02', 'a_m_y_bevhills_01', 'a_m_y_bevhills_02', 'a_m_y_breakdance_01', 'a_m_y_busicas_01', 'a_m_y_business_01', 'a_m_y_business_02', 'a_m_y_business_03', 'a_m_y_cyclist_01', 'a_m_y_dhill_01', 'a_m_y_downtown_01', 'a_m_y_eastsa_01', 'a_m_y_eastsa_02', 'a_m_y_epsilon_01', 'a_m_y_epsilon_02', 'a_m_y_gay_01', 'a_m_y_gay_02', 'a_m_y_genstreet_01', 'a_m_y_genstreet_02', 'a_m_y_golfer_01', 'a_m_y_hasjew_01', 'a_m_y_hiker_01', 'a_m_y_hippy_01', 'a_m_y_hipster_01', 'a_m_y_hipster_02', 'a_m_y_hipster_03', 'a_m_y_indian_01', 'a_m_y_jetski_01', 'a_m_y_juggalo_01', 'a_m_y_ktown_01', 'a_m_y_ktown_02', 'a_m_y_latino_01', 'a_m_y_methhead_01', 'a_m_y_mexthug_01', 'a_m_y_motox_01', 'a_m_y_motox_02', 'a_m_y_musclbeac_01', 'a_m_y_musclbeac_02', 'a_m_y_polynesian_01', 'a_m_y_roadcyc_01', 'a_m_y_runner_01', 'a_m_y_runner_02', 'a_m_y_salton_01', 'a_m_y_skater_01', 'a_m_y_skater_02', 'a_m_y_soucent_01', 'a_m_y_soucent_02', 'a_m_y_soucent_03', 'a_m_y_soucent_04', 'a_m_y_stbla_01', 'a_m_y_stbla_02', 'a_m_y_stlat_01', 'a_m_y_stwhi_01', 'a_m_y_stwhi_02', 'a_m_y_sunbathe_01', 'a_m_y_surfer_01', 'a_m_y_vindouche_01', 'a_m_y_vinewood_01', 'a_m_y_vinewood_02', 'a_m_y_vinewood_03', 'a_m_y_vinewood_04', 'a_m_y_yoga_01'}
local passengerSeats = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14} -- Seat indices for bus

-- Reward variables
local passengerReward = 15 -- Amount of money earned per passenger
local totalEarnings = 0 -- Total earnings in current session
local showEarnings = true -- Whether to show earnings on dashboard

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

-- Function to create a random passenger ped
local function createPassenger(busVehicle, seatIndex)
    if currentPassengers >= maxPassengers then return nil end
    
    -- Select a random passenger model
    local modelName = passengerModels[math.random(1, #passengerModels)]
    local modelHash = GetHashKey(modelName)
    
    -- Request the model
    RequestModel(modelHash)
    local timeoutCounter = 0
    while not HasModelLoaded(modelHash) do
        timeoutCounter = timeoutCounter + 1
        if timeoutCounter > 50 then -- Timeout after ~5 seconds
            return nil
        end
        Wait(100)
    end
    
    -- Get bus position for spawning passenger nearby
    local busCoords = GetEntityCoords(busVehicle)
    local spawnPos = vector3(busCoords.x + math.random(-5, 5), busCoords.y + math.random(-5, 5), busCoords.z)
    
    -- Create the passenger ped
    local ped = CreatePed(4, modelHash, spawnPos.x, spawnPos.y, spawnPos.z, 0.0, true, false)
    
    -- Set ped properties
    SetPedDefaultComponentVariation(ped)
    SetPedRandomComponentVariation(ped, true)
    SetPedRandomProps(ped)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedCanRagdoll(ped, false)
    SetPedConfigFlag(ped, 185, true) -- Disable damage events
    SetPedConfigFlag(ped, 108, true) -- Disable melee
    SetPedConfigFlag(ped, 208, true) -- Don't get out of vehicle when driver leaves
    
    -- Task ped to enter vehicle
    TaskEnterVehicle(ped, busVehicle, 10000, seatIndex, 1.0, 1, 0)
    
    -- Add to passengers table
    local passenger = {
        ped = ped,
        seat = seatIndex,
        destinationStation = currentStationIndex + math.random(1, 3) -- Will exit 1-3 stations later
    }
    table.insert(passengers, passenger)
    currentPassengers = currentPassengers + 1
    
    -- Release the model
    SetModelAsNoLongerNeeded(modelHash)
    
    return passenger
end

-- Function to remove passengers who reached their destination
local function removePassengersAtStation(stationIndex, busVehicle)
    local passengersToRemove = {}
    local passengersRemoved = 0
    local stationEarnings = 0
    
    -- Find passengers who need to exit at this station
    for i, passenger in ipairs(passengers) do
        if passenger.destinationStation == stationIndex then
            table.insert(passengersToRemove, i)
            
            -- Task ped to leave vehicle
            TaskLeaveVehicle(passenger.ped, busVehicle, 0)
            
            -- Make ped walk away
            local busCoords = GetEntityCoords(busVehicle)
            local randomPos = vector3(
                busCoords.x + math.random(-15, 15), 
                busCoords.y + math.random(-15, 15), 
                busCoords.z
            )
            TaskGoStraightToCoord(passenger.ped, randomPos.x, randomPos.y, randomPos.z, 1.0, -1, 0.0, 0.0)
            
            -- Schedule deletion after walking away
            SetTimeout(10000, function()
                if DoesEntityExist(passenger.ped) then
                    DeletePed(passenger.ped)
                end
            end)
            
            passengersRemoved = passengersRemoved + 1
            
            -- Add reward for each passenger that reaches their destination
            stationEarnings = stationEarnings + passengerReward
            totalEarnings = totalEarnings + passengerReward
        end
    end
    
    -- Remove passengers from table (in reverse order to avoid index issues)
    for i = #passengersToRemove, 1, -1 do
        table.remove(passengers, passengersToRemove[i])
    end
    
    currentPassengers = currentPassengers - passengersRemoved
    
    -- If passengers were removed and earned money, show notification
    if passengersRemoved > 0 then
        TriggerServerEvent('bus_m4:server:addMoney', stationEarnings)
        QBCore.Functions.Notify('You earned $' .. stationEarnings .. ' from ' .. passengersRemoved .. ' passengers!', 'success')
    end
    
    return passengersRemoved
end

-- Function to add new passengers at a station
local function addPassengersAtStation(busVehicle, stationIndex)
    -- Determine how many passengers to add (1-4 random passengers)
    local passengersToAdd = math.random(1, 4)
    local passengersAdded = 0
    
    -- Find available seats
    local availableSeats = {}
    for _, seatIndex in ipairs(passengerSeats) do
        local isOccupied = false
        for _, passenger in ipairs(passengers) do
            if passenger.seat == seatIndex then
                isOccupied = true
                break
            end
        end
        if not isOccupied then
            table.insert(availableSeats, seatIndex)
        end
    end
    
    -- Add passengers until we reach the limit or run out of seats
    for i = 1, math.min(passengersToAdd, #availableSeats) do
        if currentPassengers < maxPassengers then
            local seatIndex = table.remove(availableSeats, math.random(1, #availableSeats))
            local passenger = createPassenger(busVehicle, seatIndex)
            if passenger then
                passengersAdded = passengersAdded + 1
            end
        else
            break
        end
    end
    
    return passengersAdded
end

-- Function to clean up all passengers
local function cleanupAllPassengers()
    for _, passenger in ipairs(passengers) do
        if DoesEntityExist(passenger.ped) then
            DeletePed(passenger.ped)
        end
    end
    passengers = {}
    currentPassengers = 0
end

-- Function to display the dashboard inside the bus
local function displayDashboard()
    if not showDashboard or not activeBusLine then return end
    
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 or GetEntityModel(vehicle) ~= GetHashKey(busModel) then 
        showDashboard = false
        return 
    end
    
    -- Dashboard background
    DrawRect(0.85, 0.2, 0.2, 0.3, 0, 0, 0, 150)
    
    -- Dashboard title
    SetTextScale(0.4, 0.4)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(activeBusLine.name .. " - Line " .. activeBusLine.number)
    DrawText(0.85, 0.1)
    
    -- Current station info
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString("Current Station: " .. currentStationIndex .. "/" .. #activeBusLine.stations)
    DrawText(0.85, 0.15)
    
    -- Next station info
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextColour(255, 255, 0, 255) -- Yellow color for next station
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString("Next Station: " .. nextStationIndex .. "/" .. #activeBusLine.stations)
    DrawText(0.85, 0.2)
    
    -- Distance to next station
    if nextStationIndex <= #activeBusLine.stations then
        local nextStation = activeBusLine.stations[nextStationIndex]
        local playerCoords = GetEntityCoords(playerPed)
        local distance = math.floor(#(playerCoords - nextStation))
        
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString("Distance: " .. distance .. " m")
        DrawText(0.85, 0.25)
    end
    
    -- Passenger information
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextColour(50, 200, 50, 255) -- Green color for passengers
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString("Passengers: " .. currentPassengers .. "/" .. maxPassengers)
    DrawText(0.85, 0.3)
    
    -- Earnings information
    if showEarnings then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextColour(255, 215, 0, 255) -- Gold color for money
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString("Earnings: $" .. totalEarnings)
        DrawText(0.85, 0.35)
    end
    
    -- Instructions
    SetTextScale(0.3, 0.3)
    SetTextFont(4)
    SetTextColour(200, 200, 200, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString("Press K to open/close doors")
    DrawText(0.85, 0.4)
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
    
    -- Initialize dashboard variables
    activeBusLine = line
    currentStationIndex = 0
    nextStationIndex = 1
    showDashboard = true

    CreateThread(function()
        while true do
            for i, station in ipairs(line.stations) do
                -- Update dashboard variables
                nextStationIndex = i
                
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
                
                -- Update dashboard variables after reaching station
                currentStationIndex = i
                nextStationIndex = i < #line.stations and i + 1 or 1
                
                QBCore.Functions.Notify('You have reached station ' .. i .. ' of ' .. line.name, 'success')
                QBCore.Functions.Notify('Press K to open the bus doors.', 'primary')
                local doorsOpened = false
                while not doorsOpened do
                    Wait(0)
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    if vehicle ~= 0 and GetEntityModel(vehicle) == GetHashKey(busModel) then
                        if GetVehicleDoorLockStatus(vehicle) == 1 then
                            doorsOpened = true
                            
                            -- Handle passengers at this station
                            local passengersLeft = removePassengersAtStation(i, vehicle)
                            if passengersLeft > 0 then
                                QBCore.Functions.Notify(passengersLeft .. ' passengers got off the bus.', 'primary')
                            end
                            
                            -- Add new passengers after a short delay
                            Wait(2000)
                            local passengersBoarded = addPassengersAtStation(vehicle, i)
                            if passengersBoarded > 0 then
                                QBCore.Functions.Notify(passengersBoarded .. ' passengers boarded the bus.', 'primary')
                            end
                        end
                    end
                end
                QBCore.Functions.Notify('Wait 5 seconds before moving.', 'primary')
                Wait(5000)
            end
            QBCore.Functions.Notify('All stations for ' .. line.name .. ' completed! Restarting.', 'warning')
            -- Reset dashboard variables for restart
            currentStationIndex = 0
            nextStationIndex = 1
        end
    end)
end)

local function deleteBus()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle ~= 0 and GetEntityModel(vehicle) == GetHashKey(busModel) then
        -- Clean up all passengers before deleting the bus
        cleanupAllPassengers()
        
        -- Show final earnings notification if earned money
        if totalEarnings > 0 then
            QBCore.Functions.Notify('Total earnings from this route: $' .. totalEarnings, 'success')
        end
        
        DeleteVehicle(vehicle)
        QBCore.Functions.Notify('Bus deleted!', 'success')
        for _, blip in ipairs(activeBlips) do RemoveBlip(blip) end
        activeBlips = {}
        SetWaypointOff()
        
        -- Reset dashboard variables
        activeBusLine = nil
        currentStationIndex = 0
        nextStationIndex = 0
        showDashboard = false
        
        -- Reset earnings
        totalEarnings = 0
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

-- Thread to display the dashboard while driving
CreateThread(function()
    while true do
        Wait(0)
        if showDashboard and activeBusLine then
            displayDashboard()
        else
            Wait(1000) -- Wait longer if dashboard is not active
        end
    end
end)