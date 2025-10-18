--[[
    Home.lua

    Your hoe. You live and handle storage here.
    This file contains all storage-specific callbacks and functionality data structures
]]
--require 'pmd_new_leaf.menu.StorageMenu' TODO

---@alias HomePlot {unlocked:boolean,building:BuildingID,upgrades:table<string,integer>,shopkeeper:ShopkeeperData,shopkeeper_shiny:boolean,data:HomeData,empty:integer}
---@alias HomeData {storage_limit:integer,stackable_mult:integer,unstack_limit:integer}

_SHOP.HomeTables = {
    -- level          1   2    3    4    5    6    7    8    9    10
    storage_limit =  {64, 128, 200, 288, 384, 512, 640, 800, 960, 1000},
    -- slot pages     8   16   25   36   48   64   80   100  120  125
    stackable_mult = {1,  1,   2,   3,   4,   5,   6,   7,   8,   99}, --nothing is ever allowed to go past 99 per stack
    unstack_limit =  {1,  1,   2,   3,   4,   5,   6,   7,   8,   9}
}

---Initializes the home's specific data
---@param plot HomePlot the plot's data structure
function _SHOP.HomeInitializer(plot)
    plot.data = {
        storage_limit = 64,
        stackable_mult = 1,
        unstack_limit = 1,
        storage = {} -- id = {hidden = int}
    }
end

---Checks if the supplied upgrade is valid, and updates the plot's data structure accordingly if it is.
---@param plot HomePlot the plot's data structure
---@param upgrade string an upgrade id
function _SHOP.HomeUpgrade(plot, upgrade)
    if upgrade ~= "upgrade_generic" then return end

    local level = _HUB.getPlotLevel(plot)
    if level<10 then
        _SHOP.ConfirmShopUpgrade(plot, upgrade)
        level = _HUB.getPlotLevel(plot)
    else return end

    plot.data.storage_limit = _SHOP.HomeTables.storage_limit[level]
    plot.data.stackable_mult = _SHOP.HomeTables.stackable_mult[level]
    plot.data.unstack_limit = _SHOP.HomeTables.unstack_limit[level]
end

---Runs the interact flow for the player storage
function _SHOP.StorageInteract() --TODO

end

---Gets the home plot's internal data
---@return table #the home plot's internal data table
function _SHOP.HomeGetData()
    return _HUB.getPlotData("home").data
end

---Splits the storage slots in groups, following the rules dictated by the current home level.
---@return {[integer]:{id:string,hidden:string,count:integer},items:table<string,integer[]>}
function _SHOP.StorageGetSlots()
    local home = _SHOP.HomeGetData()
    local storage = home.storage
    local slots = {items = {}}
    for id, items in pairs(storage) do
        local origMaxStack = _DADA:GetItem(id).MaxStack
        local maxStack = home.unstack_limit
        if origMaxStack.MaxStack > 0 then
            maxStack = math.min(home.stackable_mult * origMaxStack, 99)
        end
        for hidden, count in pairs(items) do
            local n = count
            while n>0 do
                table.insert(slots, {id = id, hidden = hidden, count = math.min(maxStack, n)})
                n = n - math.min(maxStack, n)
                slots.items[id] = slots.items[id] or {}
                table.insert(slots.items[id], #slots)
            end
        end
    end
end

---Checks if the inventory can be fully added to the storage list. 
---@param store_treasures? boolean if true, treasure items will also be stored. Defaults to false
---@return boolean #true if all items can fit in storage, false otherwise
function _SHOP.StorageCanStoreInventory(store_treasures) --TODO
    local addAmount = function(slots, item)
        local home = _SHOP.HomeGetData()
        local depositLimit = home.storage_limit
        local id = item.ID
        local amt = item.Amount
        local origMaxStack = _DADA:GetItem(id).MaxStack
        local maxStack = home.unstack_limit
        if origMaxStack.MaxStack > 0 then
            maxStack = math.min(home.stackable_mult * origMaxStack, 99)
        else
            amt = math.max(1, amt)
        end
        if amt<1 then return end
        slots.items[id] = slots.items[id] or {}
        for _, index in ipairs(slots.items[id]) do
            local reduce = math.min(amt, maxStack - slots[index].count)
            amt = amt - reduce
            slots[index].count = slots[index].count + reduce
        end
        while amt>0 do
            table.insert(slots, {id = id, hidden = item.HiddenValue, count = math.min(maxStack, amt)})
            amt = amt - math.min(maxStack, amt)
            table.insert(slots.items[id], #slots)
            if #slots > depositLimit then
                return false
            end
        end
        return true
    end

    local items = GAME:GetPlayerBagCount()
    local storage = _SHOP.StorageGetSlots()
    for i = 0, _DATA.Save.ActiveTeam.Players.Count-1, 1 do
        local item = GAME:GetPlayerEquippedItem(i)
        if item ~= nil and item.ID ~~ "" then
            if not addAmount(storage, item) then return false end
        end
    end
    for j = 0, items-1, 1 do
        local item = GAME:GetPlayerBagItem(j)
        if not addAmount(storage, item) then return false end
    end
    return true
end

_SHOP.callbacks.initialize["home"] = _SHOP.HomeInitializer
_SHOP.callbacks.upgrade["home"] =    _SHOP.HomeUpgrade
