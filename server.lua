local QBCore = exports['qb-core']:GetCoreObject()

-- Event to add money to player's account
RegisterNetEvent('bus_m4:server:addMoney', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        -- Add money to player's bank account
        Player.Functions.AddMoney('bank', amount, 'bus-driver-payment')
    end
end)