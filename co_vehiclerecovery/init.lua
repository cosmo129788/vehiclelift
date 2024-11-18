ESX = nil
ESX = exports["es_extended"]:getSharedObject()

RegisterServerEvent('esx:removeliftbag')
AddEventHandler('esx:removeliftbag', function(itemType, itemName, count)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        xPlayer.removeInventoryItem(itemName, count)
    end
end)

-- Server-side: Callback for getting player inventory item
ESX.RegisterServerCallback('esx:getplayerspockets', function(source, cb, itemName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local item = xPlayer.getInventoryItem(itemName)
        cb(item)
    else
        cb(nil)
    end
end)
