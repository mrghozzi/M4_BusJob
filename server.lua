local QBCore = exports['qb-core']:GetCoreObject()
local activeRoutes = {}

local function sendToDiscord(name, message, color)
    if not Config or not Config.Webhook or Config.Webhook == "" then return end

    local payload = {
        {
            ["color"] = color,
            ["title"] = "**" .. name .. "**",
            ["description"] = message,
            ["footer"] = {
                ["text"] = "M4 Bus Job Logs | " .. os.date("%Y-%m-%d %H:%M:%S"),
            },
        }
    }

    PerformHttpRequest(
        Config.Webhook,
        function() end,
        'POST',
        json.encode({
            username = "Bus Job Logger",
            embeds = payload,
            avatar_url = "https://i.imgur.com/HqC1v6x.png"
        }),
        { ['Content-Type'] = 'application/json' }
    )
end

local function getLineByNumber(lineNumber)
    if type(lineNumber) ~= 'number' then return nil end
    local rounded = math.floor(lineNumber)

    for _, line in ipairs(Config.BusLines or {}) do
        if line.number == rounded then
            return line
        end
    end

    return nil
end

local function isBusDriver(player)
    local allowedJob = (Config and Config.AllowedJob) or "busdriver"
    return player and player.PlayerData and player.PlayerData.job and player.PlayerData.job.name == allowedJob
end

local function isNearStation(src, stationCoords, maxDistance)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    local playerCoords = GetEntityCoords(ped)
    return #(playerCoords - stationCoords) <= maxDistance
end

RegisterNetEvent('bus_m4:server:startRoute', function(lineNumber)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local line = getLineByNumber(lineNumber)

    if not player or not line or not isBusDriver(player) then return end

    activeRoutes[src] = {
        lineNumber = line.number,
        lineName = line.name,
        stationCount = #line.stations,
        lastStation = 0,
        payoutReady = false,
        completedLap = false,
    }
end)

RegisterNetEvent('bus_m4:server:stationReached', function(lineNumber, stationIndex)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local state = activeRoutes[src]

    if not player or not state or not isBusDriver(player) then return end

    local line = getLineByNumber(lineNumber)
    if not line or line.number ~= state.lineNumber then return end
    if type(stationIndex) ~= 'number' then return end

    stationIndex = math.floor(stationIndex)
    if stationIndex < 1 or stationIndex > state.stationCount then return end

    local expectedStation = (state.lastStation % state.stationCount) + 1
    if stationIndex ~= expectedStation then return end
    if not isNearStation(src, line.stations[stationIndex], 80.0) then return end

    state.lastStation = stationIndex
    state.payoutReady = true

    if stationIndex == state.stationCount then
        state.completedLap = true
    end
end)

RegisterNetEvent('bus_m4:server:addMoney', function(passengerCount, stationIndex)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local state = activeRoutes[src]
    local rewardPerPassenger = tonumber(Config and Config.PassengerReward) or 0
    local maxPassengers = tonumber(Config and Config.MaxPassengers) or 15

    if not player or not state or not isBusDriver(player) then return end
    if type(passengerCount) ~= 'number' or type(stationIndex) ~= 'number' then return end

    passengerCount = math.floor(passengerCount)
    stationIndex = math.floor(stationIndex)

    if passengerCount < 1 or passengerCount > maxPassengers then return end
    if stationIndex ~= state.lastStation or not state.payoutReady then return end

    local line = getLineByNumber(state.lineNumber)
    if not line or not line.stations[stationIndex] then return end
    if not isNearStation(src, line.stations[stationIndex], 80.0) then return end

    local amount = passengerCount * rewardPerPassenger
    if amount <= 0 then return end

    state.payoutReady = false
    player.Functions.AddMoney('bank', amount, 'bus-driver-payment')
end)

RegisterNetEvent('bus_m4:server:finishRoute', function(lineNumber)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local state = activeRoutes[src]
    local bonus = tonumber(Config and Config.RouteCompletionBonus) or 0

    if not player or not state or not isBusDriver(player) then return end

    local line = getLineByNumber(lineNumber)
    if not line or line.number ~= state.lineNumber then return end
    if not state.completedLap or state.lastStation ~= state.stationCount then return end
    if bonus > 0 then
        player.Functions.AddMoney('bank', bonus, 'bus-route-completion')
        sendToDiscord(
            "Route Completed",
            "**Player:** " .. GetPlayerName(src) .. "\n**Route:** " .. state.lineName .. "\n**Bonus:** $" .. bonus,
            3066993
        )
    end

    state.completedLap = false
    state.payoutReady = false
end)

RegisterNetEvent('bus_m4:server:chargeRepair', function(amount)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player or not isBusDriver(player) then return end

    local penalty = tonumber(Config and Config.DamagePenalty) or tonumber(amount) or 0
    penalty = math.floor(penalty)
    if penalty <= 0 then return end

    player.Functions.RemoveMoney('bank', penalty, 'bus-repair-cost')
    sendToDiscord(
        "Bus Damaged",
        "**Player:** " .. GetPlayerName(src) .. "\n**Penalty:** $" .. penalty,
        15158332
    )
end)

RegisterNetEvent('bus_m4:server:endRoute', function()
    activeRoutes[source] = nil
end)

AddEventHandler('playerDropped', function()
    activeRoutes[source] = nil
end)
