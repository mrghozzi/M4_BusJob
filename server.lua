local QBCore = exports['qb-core']:GetCoreObject()

local function sendToDiscord(name, message, color)
    local connect = {
        {
            ["color"] = color,
            ["title"] = "**".. name .."**",
            ["description"] = message,
            ["footer"] = {
                ["text"] = "M4 Bus Job Logs • " .. os.date("%Y-%m-%d %H:%M:%S"),
            },
        }
    }
    PerformHttpRequest(Config.Webhook, function(err, text, headers) end, 'POST', json.encode({username = "Bus Job Logger", embeds = connect, avatar_url = "https://i.imgur.com/HqC1v6x.png"}), { ['Content-Type'] = 'application/json' })
end

-- Event to add money to player's account
RegisterNetEvent('bus_m4:server:addMoney', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        -- Add money to player's bank account
        Player.Functions.AddMoney('bank', amount, 'bus-driver-payment')
    end
end)

RegisterNetEvent('bus_m4:server:finishRoute', function(amount, routeName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        Player.Functions.AddMoney('bank', amount, 'bus-route-completion')
        if Config.Webhook ~= "" then
             sendToDiscord("Route Completed", "**Player:** " .. GetPlayerName(src) .. "\n**Route:** " .. routeName .. "\n**Bonus:** $" .. amount, 3066993)
        end
    end
end)

RegisterNetEvent('bus_m4:server:chargeRepair', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        Player.Functions.RemoveMoney('bank', amount, 'bus-repair-cost')
        if Config.Webhook ~= "" then
            sendToDiscord("Bus Damaged", "**Player:** " .. GetPlayerName(src) .. "\n**Penalty:** $" .. amount, 15158332)
       end
    end
end)