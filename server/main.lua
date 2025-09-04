local activeBBQs = {}
local bbqStashes = {}


RegisterNetEvent('old_bbq:addBBQ', function(netId, coords)
    activeBBQs[netId] = coords
end)

RegisterNetEvent('old_bbq:openStash', function(netId)
    local src = source
    if not activeBBQs[netId] then return end

    local stashId = exports.ox_inventory:CreateTemporaryStash({
        label     = 'Barbecue',
        slots     = 2,
        maxWeight = 5000
    })

    bbqStashes[stashId] = stashId

    TriggerClientEvent('ox_inventory:openInventory', src, 'stash', stashId)
end)


exports.ox_inventory:registerHook('swapItems', function(payload)
    local src           = payload.source
    local toInventoryId = payload.toInventory
    local item          = payload.fromSlot
    local count         = tonumber(payload.count) or 0

    if toInventoryId == bbqStashes[toInventoryId] and item.name ~= 'rawmeat' then
        TriggerClientEvent("ox_lib:notify", src,
            { description = "Ceci est un Barbecue, vous pouvez mettre uniquement de la viande crue", position = 'top' })
        return false
    end
    if item.name == 'rawmeat' and payload.fromInventory == bbqStashes[payload.fromInventory] then
        TriggerClientEvent("ox_lib:notify", src,
            { description = "Votre viande est cuite", position = 'top' })
        return false
    end

    if item.name == 'rawmeat' and toInventoryId ~= src then
        exports.ox_inventory:AddItem(toInventoryId, "cookedmeat", count, nil, 2)
    elseif item.name == 'cookedmeat' and toInventoryId == src and payload.fromInventory == bbqStashes[payload.fromInventory] then
        exports.ox_inventory:RemoveItem(payload.fromInventory, "rawmeat", count)
    end
end, { 'rawmeat', 'cookedmeat' })



lib.callback.register('old_bbq:giveBbq', function(source)
    local canCarry = exports.ox_inventory:CanCarryItem(source, 'barbecue', 1)
    if canCarry then
        exports.ox_inventory:AddItem(source, 'barbecue', 1)
        return true
    else
        return false
    end
end)
