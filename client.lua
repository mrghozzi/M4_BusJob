local QBCore = exports['qb-core']:GetCoreObject()

-- Config variables loaded from global Config (set in config.lua)
local allowedJob = Config.AllowedJob
local busSpawnLocation = Config.BusSpawnLocation
local busModel = Config.BusModel
local maxPassengers = Config.MaxPassengers
local passengerReward = Config.PassengerReward
local passengerModels = Config.PassengerModels
local passengerSeats = Config.PassengerSeats
local busLines = Config.BusLines

-- Runtime state variables
local activeBusLine = nil
local currentStationIndex = 0
local nextStationIndex = 0
local showDashboard = false
local currentBusEntity = nil

-- Passenger state
local passengers = {}
local currentPassengers = 0

-- Earnings state
local totalEarnings = 0
local showEarnings = true

-- Check if the player has the allowed job
local function isPlayerBusDriver()
    local PlayerData = QBCore.Functions.GetPlayerData()
    return PlayerData and PlayerData.job and PlayerData.job.name == allowedJob
end

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
    if not showDashboard or not activeBusLine then
        SendNUIMessage({ type = 'bus_dashboard_visible', visible = false })
        return
    end

    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle == 0 or (currentBusEntity and vehicle ~= currentBusEntity) or GetEntityModel(vehicle) ~= GetHashKey(busModel) then
        -- لا تقم بإطفاء الحالة العامة للوحة لتجنب حالات السباق عند الإدخال للحافلة
        SendNUIMessage({ type = 'bus_dashboard_visible', visible = false })
        return
    end

    local distance = 0
    if nextStationIndex <= #activeBusLine.stations then
        local nextStation = activeBusLine.stations[nextStationIndex]
        local playerCoords = GetEntityCoords(playerPed)
        distance = math.floor(#(playerCoords - nextStation))
    end

    local accent = activeBusLine.color or { r = 30, g = 144, b = 255 }
    local maxP = maxPassengers or (Config and Config.MaxPassengers) or 0

    SendNUIMessage({
        type = 'bus_dashboard_update',
        lineName = activeBusLine.name,
        lineNumber = activeBusLine.number,
        currentStationIndex = currentStationIndex,
        nextStationIndex = nextStationIndex,
        totalStations = #activeBusLine.stations,
        distanceToNext = distance,
        currentPassengers = currentPassengers or 0,
        maxPassengers = maxP,
        totalEarnings = totalEarnings or 0,
        showEarnings = showEarnings or false,
        color = accent
    })

    SendNUIMessage({ type = 'bus_dashboard_visible', visible = true })
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
    currentBusEntity = bus
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
        currentBusEntity = nil
        QBCore.Functions.Notify('Bus deleted!', 'success')
        for _, blip in ipairs(activeBlips) do RemoveBlip(blip) end
        activeBlips = {}
        SetWaypointOff()
        
        -- Reset dashboard variables
        activeBusLine = nil
        currentStationIndex = 0
        nextStationIndex = 0
        showDashboard = false
        -- Ensure NUI dashboard is hidden when bus is deleted
        SendNUIMessage({ type = 'bus_dashboard_visible', visible = false })
        
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

-- Hide dashboard when player job changes away from allowed job
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    if job and job.name ~= allowedJob then
        showDashboard = false
        activeBusLine = nil
        SendNUIMessage({ type = 'bus_dashboard_visible', visible = false })
    end
end)

-- Hide dashboard cleanly when resource stops to avoid stuck UI
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        SendNUIMessage({ type = 'bus_dashboard_visible', visible = false })
    end
end)