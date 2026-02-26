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
local routeSessionId = 0
local routeInProgress = false
local clothingNPC = nil
local isWearingUniform = false

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

local function setUniform()
    if not Config.Uniforms then return end
    local playerData = QBCore.Functions.GetPlayerData()
    if not playerData or not playerData.charinfo then return end

    local gender = playerData.charinfo.gender
    local uniform = (gender == 1) and Config.Uniforms.female or Config.Uniforms.male
    
    if uniform then
        TriggerEvent('qb-clothing:client:loadOutfit', uniform)
        isWearingUniform = true
    end
end

local function resetUniform()
    TriggerServerEvent("qb-clothes:loadPlayerSkin")
    isWearingUniform = false
end

local function stopActiveRoute()
    if routeInProgress then
        routeInProgress = false
        routeSessionId = routeSessionId + 1
        TriggerServerEvent('bus_m4:server:endRoute')
    end
end

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

local function getBusLineByNumber(lineNumber)
    if type(lineNumber) ~= 'number' then return nil end
    for _, line in ipairs(busLines) do
        if line.number == math.floor(lineNumber) then
            return line
        end
    end
    return nil
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

local function showFloatingText(ped, text)
    CreateThread(function()
        local displayTime = 3000
        local startTime = GetGameTimer()
        
        while GetGameTimer() - startTime < displayTime do
            Wait(0)
            if DoesEntityExist(ped) then
                local coords = GetPedBoneCoords(ped, 12844, 0.0, 0.0, 0.0) -- Head bone
                QBCore.Functions.DrawText3D(coords.x, coords.y, coords.z + 0.5, text)
            else
                break
            end
        end
    end)
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
        TriggerServerEvent('bus_m4:server:addMoney', passengersRemoved, stationIndex)
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

    local selectedLine = getBusLineByNumber(line and line.number)
    if not selectedLine or not selectedLine.stations or #selectedLine.stations == 0 then
        QBCore.Functions.Notify('Invalid bus line selected.', 'error')
        return
    end
    line = selectedLine

    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle ~= 0 and GetEntityModel(vehicle) == GetHashKey(busModel) then
        QBCore.Functions.Notify('You are already in the bus!', 'error')
        return
    end

    RequestModel(busModel)
    while not HasModelLoaded(busModel) do Wait(0) end

    stopActiveRoute()

    local bus = CreateVehicle(GetHashKey(busModel), busSpawnLocation.x, busSpawnLocation.y, busSpawnLocation.z, 263.27, true, false)
    currentBusEntity = bus
    SetVehicleCustomPrimaryColour(bus, line.color.r, line.color.g, line.color.b)
    TaskWarpPedIntoVehicle(playerPed, bus, -1)
    TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(bus)) -- Set the vehicle keys
    if GetResourceState('LegacyFuel') == 'started' then
        exports['LegacyFuel']:SetFuel(bus, 100.0)
    end
    SetModelAsNoLongerNeeded(busModel)

    QBCore.Functions.Notify('Bus for ' .. line.name .. ' has been spawned!', 'warning')
    createBlipsForLine(line)
    
    setUniform()

    -- Initialize dashboard variables
    activeBusLine = line
    currentStationIndex = 0
    nextStationIndex = 1
    showDashboard = true
    routeInProgress = true
    routeSessionId = routeSessionId + 1
    local thisRouteSession = routeSessionId
    TriggerServerEvent('bus_m4:server:startRoute', line.number)

    CreateThread(function()
        while routeInProgress and thisRouteSession == routeSessionId do
            if not currentBusEntity or not DoesEntityExist(currentBusEntity) then
                stopActiveRoute()
                break
            end

            for i, station in ipairs(line.stations) do
                if not routeInProgress or thisRouteSession ~= routeSessionId then break end

                -- Update dashboard variables
                nextStationIndex = i
                
                SetNewWaypoint(station.x, station.y)
                QBCore.Functions.Notify('GPS route set to station ' .. i .. ' of ' .. line.name, 'success')
                local reached = false
                while routeInProgress and thisRouteSession == routeSessionId and not reached do
                    Wait(1000)
                    if not currentBusEntity or not DoesEntityExist(currentBusEntity) then
                        stopActiveRoute()
                        break
                    end
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    if vehicle ~= 0 and vehicle == currentBusEntity and #(playerCoords - station) < 10.0 then
                        reached = true
                    end
                end
                if not routeInProgress or thisRouteSession ~= routeSessionId then break end
                
                -- Update dashboard variables after reaching station
                currentStationIndex = i
                nextStationIndex = i < #line.stations and i + 1 or 1
                TriggerServerEvent('bus_m4:server:stationReached', line.number, i)
                
                QBCore.Functions.Notify('You have reached station ' .. i .. ' of ' .. line.name, 'success')
                QBCore.Functions.Notify('Press K to open the bus doors.', 'primary')
                local doorsOpened = false
                local waitStart = GetGameTimer()
                while routeInProgress and thisRouteSession == routeSessionId and not doorsOpened do
                    Wait(100)
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    if vehicle ~= 0 and vehicle == currentBusEntity and GetEntityModel(vehicle) == GetHashKey(busModel) then
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
                    if not doorsOpened and GetGameTimer() - waitStart > 60000 then
                        doorsOpened = true
                        QBCore.Functions.Notify('Stop timeout reached, continuing route.', 'error')
                    end
                end
                if not routeInProgress or thisRouteSession ~= routeSessionId then break end

                QBCore.Functions.Notify('Wait 5 seconds before moving.', 'primary')
                local pauseStart = GetGameTimer()
                while routeInProgress and thisRouteSession == routeSessionId and GetGameTimer() - pauseStart < 5000 do
                    Wait(100)
                end
            end
            if not routeInProgress or thisRouteSession ~= routeSessionId then break end

            QBCore.Functions.Notify('All stations for ' .. line.name .. ' completed! Restarting.', 'warning')
            
            -- Route Completion Bonus
            if Config.RouteCompletionBonus then
                 TriggerServerEvent('bus_m4:server:finishRoute', line.number)
                 QBCore.Functions.Notify('You received a $' .. Config.RouteCompletionBonus .. ' bonus for completing the route!', 'success')
            end
            
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
        stopActiveRoute()

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
        
        -- resetUniform() -- Removed auto reset uniform

        -- Reset dashboard variables
        activeBusLine = nil
        currentStationIndex = 0
        nextStationIndex = 0
        showDashboard = false
        -- Ensure NUI dashboard is hidden when bus is deleted
        SendNUIMessage({ type = 'bus_dashboard_visible', visible = false })
        
        -- Reset earnings
        totalEarnings = 0
        isWearingUniform = false
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

RegisterNetEvent('bus_m4:client:openMenu', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 and GetEntityModel(vehicle) == GetHashKey(busModel) then
        deleteBus()
    else
        showBusLinesMenu()
    end
end)

CreateThread(function()
    if Config.UseTarget then
        exports['qb-target']:AddBoxZone("BusDepot", busSpawnLocation, 5.0, 5.0, {
            name = "BusDepot",
            heading = 0,
            debugPoly = false,
            minZ = busSpawnLocation.z - 2,
            maxZ = busSpawnLocation.z + 2,
        }, {
            options = {
                {
                    type = "client",
                    event = "bus_m4:client:openMenu",
                    icon = "fas fa-bus",
                    label = "Bus Job Menu",
                    job = allowedJob,
                },
            },
            distance = 5.0
        })
    end

    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - busSpawnLocation)
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local isBus = (vehicle ~= 0 and GetEntityModel(vehicle) == GetHashKey(busModel))

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
                if isBus then
                     QBCore.Functions.DrawText3D(busSpawnLocation.x, busSpawnLocation.y, busSpawnLocation.z, '[G] Delete Bus')
                     if IsControlJustReleased(0, 47) then
                        deleteBus()
                     end
                elseif not Config.UseTarget then
                    QBCore.Functions.DrawText3D(busSpawnLocation.x, busSpawnLocation.y, busSpawnLocation.z, '[E] Select Bus Line')

                    if IsControlJustReleased(0, 38) then
                        showBusLinesMenu()
                    end
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
        stopActiveRoute()
        cleanupAllPassengers()
        showDashboard = false
        activeBusLine = nil
        currentBusEntity = nil
        SendNUIMessage({ type = 'bus_dashboard_visible', visible = false })
    end
end)

RegisterNetEvent('bus_m4:client:toggleDuty', function()
    if not isPlayerBusDriver() then
        QBCore.Functions.Notify('You are not a bus driver!', 'error')
        return
    end

    if isWearingUniform then
        resetUniform()
        QBCore.Functions.Notify('Bus uniform removed.', 'success')
    else
        setUniform()
        QBCore.Functions.Notify('Bus uniform equipped.', 'success')
    end
end)

CreateThread(function()
    if Config.ClothingNPC then
        local model = GetHashKey(Config.ClothingNPC.model)
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end
        
        local coords = Config.ClothingNPC.coords
        -- Removed -1.0 from Z coordinate to fix spawning underground
        clothingNPC = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w, false, true)
        SetEntityHeading(clothingNPC, coords.w)
        FreezeEntityPosition(clothingNPC, true)
        SetEntityInvincible(clothingNPC, true)
        SetBlockingOfNonTemporaryEvents(clothingNPC, true)
        SetModelAsNoLongerNeeded(model)
        
        exports['qb-target']:AddTargetEntity(clothingNPC, {
            options = {
                {
                    type = "client",
                    event = "bus_m4:client:toggleDuty",
                    icon = "fas fa-tshirt",
                    label = "Toggle Bus Uniform",
                    job = Config.AllowedJob,
                },
            },
            distance = 2.5,
        })
    end
end)

-- Hide dashboard cleanly when resource stops to avoid stuck UI
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        stopActiveRoute()
        cleanupAllPassengers()
        SendNUIMessage({ type = 'bus_dashboard_visible', visible = false })
    end
end)
