--[[
    Home.lua

    Your hoe. You live and handle storage here.
    This file contains all storage-specific callbacks and functionality data structures
]]
--require 'pmd_new_leaf.menu.StorageMenu' TODO

---@alias HomePlot {unlocked:boolean,building:BuildingID,upgrades:UpgradeEntry,shopkeeper:ShopkeeperData,shopkeeper_shiny:boolean,data:HomeData,empty:integer}
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
    UI:ResetSpeaker()

    local exit = false
    while not exit do

        local has_items = GAME:GetPlayerBagCount() + GAME:GetPlayerEquippedCount() > 0
        local has_storage = GAME:GetPlayerStorageCount() > 0


        local storage_choices = { { STRINGS:FormatKey('MENU_STORAGE_STORE'), has_items},
                                  { STRINGS:FormatKey('MENU_STORAGE_TAKE_ITEM'), has_storage},
                                  { STRINGS:FormatKey('MENU_STORAGE_STORE_ALL'), has_items},
                                  { STRINGS:FormatKey("MENU_STORAGE_MONEY"), true},
                                  { STRINGS:FormatKey("MENU_CANCEL"), true}}
        UI:BeginChoiceMenu(STRINGS:FormatKey('DLG_WHAT_DO'), storage_choices, 1, 5)
        UI:WaitForChoice()
        local result = UI:ChoiceResult()

        if result == 1 then
            InventoryDepositMenu:run() --TODO
            UI:WaitForChoice()
        elseif result == 2 then
            SlotBasedStorageMenu:run() --TODO
            UI:WaitForChoice()
        elseif result == 3 then
            UI:ChoiceMenuYesNo(STRINGS:FormatKey('DLG_STORE_ALL_CONFIRM'), false)
            UI:WaitForChoice()
            if UI:ChoiceResult() then
                _HUB.StorageStoreInventory()
            end
        elseif result == 4 then
            UI:BankMenu()
            UI:WaitForChoice()
        elseif result == 5 then
            exit = true
        end
    end
end

---Gets the home plot's internal data
---@return table #the home plot's internal data table
function _SHOP.HomeGetData()
    return _HUB.getPlotData("home").data
end

---Returns the allowed max stack for the given item
---@param itemData ItemData
---@return unknown
function _SHOP.StorageGetItemMaxStack(itemData)
    if itemData.UsageType ~= RogueEssence.Data.ItemData.UseType.Box then return itemData.MaxStack end

    local home = _SHOP.HomeGetData()
    local origMaxStack = itemData.MaxStack
    local maxStack = home.unstack_limit
    if origMaxStack > 0 then
        maxStack = math.max(origMaxStack, math.min(home.stackable_mult * origMaxStack, 99))
    end
    return maxStack
end

---Splits the storage slots in groups, following the rules dictated by the current home level.
---@return {[integer]:{id:string,hidden:string,count:integer},items:table<string,integer[]>}
function _SHOP.StorageGetSlots()
    local storage = LUA_ENGINE:MakeList(_DATA.Save.ActiveTeam.Storage)
    local boxes = LUA_ENGINE:MakeList(_DATA.Save.ActiveTeam.BoxStorage)
    ---@type {[integer]:{id:string,hidden:string,count:integer},items:table<string,integer[]>}
    local slots = {items = {}}
    for pair in luanet.each(storage) do
        local id, count = pair.Key, pair.Value
        local itemData = _DATA:GetItem(id)
        local maxStack = _SHOP.StorageGetItemMaxStack(itemData)
        if itemData.MaxStack == 0 then count = 1 end
        local n = count
        while n>0 do
            table.insert(slots, {id = id, hidden = "", count = math.min(maxStack, n)})
            n = n - math.min(maxStack, n)
            slots.items[id] = slots.items[id] or {}
            table.insert(slots.items[id], #slots)
        end
    end
    for box in luanet.each(boxes) do --TODO decide how to handle boxes. Probably just 1 per box instead
        local id, count, hidden = box.ID, box.Amount, box.HiddenValue
        local itemData = _DATA:GetItem(id)
        local maxStack = _SHOP.StorageGetItemMaxStack(itemData)
        if itemData.MaxStack == 0 then count = 1 end
        local n = count
        while n>0 do
            table.insert(slots, {id = id, hidden = hidden, count = math.min(maxStack, n)})
            n = n - math.min(maxStack, n)
            slots.items[id] = slots.items[id] or {}
            table.insert(slots.items[id], #slots)
        end
    end
    return slots
end

---Checks if the inventory can be fully added to the storage list. 
---@param store_treasures? boolean if true, treasure items will also be stored. Defaults to false
---@return boolean #true if all items can fit in storage, false otherwise
function _SHOP.StorageCanStoreInventory(store_treasures)
    local addAmount = function(slots, item)
        local home = _SHOP.HomeGetData()
        local depositLimit = home.storage_limit
        local id, count, hidden = item.ID, item.Amount, item.HiddenValue
        local itemData = _DATA:GetItem(id)
        local maxStack = _SHOP.StorageGetItemMaxStack(itemData)
        if itemData.MaxStack == 0 then count = 1 end
        if not store_treasures and itemData.CannotDrop then
            return true -- keep treasures
        end
        if itemData.UsageType ~= RogueEssence.Data.ItemData.UseType.Box then
            hidden = ""
        end
        if count<1 then return end
        slots.items[id] = slots.items[id] or {}
        for _, index in ipairs(slots.items[id]) do
            local reduce = math.min(count, maxStack - slots[index].count)
            count = count - reduce
            slots[index].count = slots[index].count + reduce
        end
        while count>0 do
            table.insert(slots, {id = id, hidden = hidden, count = math.min(maxStack, count)})
            count = count - math.min(maxStack, count)
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

---Stores the whole inventory if possible. Aborts and has no effects if it can't.
---@param store_treasures boolean if true, also store items that cannot be dropped
function _SHOP.StorageStoreInventory(store_treasures)
    if _SHOP.StorageCanStoreInventory(store_treasures) then
        _SHOP.StorageStoreInventoryWithoutChecking(store_treasures, false)
    else
        UI:WaitShowDialogue(STRINGS:FormatKey("HUB_DEPOSIT_FAIL"))
    end
end

---Stores the whole inventory if possible. Stores as much as possible if it can't store everything.
---It starts storing from below, taking equipment for last.
---@param store_treasures boolean if true, also store items that cannot be dropped
---@param skip_individual_checks boolean if true, it doesn't check for validity at all and will overflow the deposit
function _SHOP.StorageStoreInventoryWithoutChecking(store_treasures, skip_individual_checks)
    local items = GAME:GetPlayerBagCount()
    local slots = _SHOP.StorageGetSlots()
    local j = items-1
    while j >= 0 do
        local item = GAME:GetPlayerBagItem(j)
        if (store_treasures or not _DATA:GetItem(item.ID).CannotDrop) then
            local deposit = true
            if skip_individual_checks then _SHOP.StorageStoreItemWithoutChecking(item, slots)
            else deposit = _SHOP.StorageStoreItem(item, slots) end
            if deposit then GAME:TakePlayerBagItem(j, true) end
        end
        j = j-1
    end
    j = _DATA.Save.ActiveTeam.Players.Count-1
    while j >= 0 do
        local item = GAME:GetPlayerEquippedItem(j)
        if item ~= nil and item.ID ~~ "" and (store_treasures or not _DATA:GetItem(item.ID).CannotDrop) then
            local deposit = true
            if skip_individual_checks then _SHOP.StorageStoreItemWithoutChecking(item, slots)
            else deposit = _SHOP.StorageStoreItem(item, slots) end
            if deposit then GAME:TakePlayerEquippedItem(j, true) end
        end
        j = j-1
    end
end

---@param item InvItem the InvItem to store
---@param slots table the result of a ``_SHOP.StorageGetSlots()`` operation. Used to update the slots list for efficiency reasons. It will be ignored if nil.
---@param alert? boolean if true, the failure message will be displayed. Defaults to false
function _SHOP.StorageStoreItem(item, slots, alert)
    if _SHOP.StorageCanStoreItem(item, slots) then
        _SHOP.StorageStoreItemWithoutChecking(item, slots)
        return true
    else
        if alert then
            UI:WaitShowDialogue(STRINGS:FormatKey("HUB_DEPOSIT_FAIL"))
        end
        return false
    end
end

---@param item InvItem the InvItem to store
---@param slots table the result of a ``_SHOP.StorageGetSlots()`` operation. If nil, it will be called automatically.
---@return boolean #whether there's space for the item or not
function _SHOP.StorageCanStoreItem(item, slots)
    slots = slots or _SHOP.StorageGetSlots()
    local home = _SHOP.HomeGetData()
    local depositLimit = home.storage_limit
    if #slots<depositLimit then return true end
    local id, count, hidden = item.ID, item.Amount, item.HiddenValue
    local itemData = _DATA:GetItem(id)
    local maxStack = _SHOP.StorageGetItemMaxStack(itemData)
    if itemData.MaxStack == 0 then count = 1 end
    for _, index in ipairs(slots.items[item.ID]) do
        if slots[index].hidden == hidden and slots[index].count<maxStack then
            count = count - (maxStack - slots[index].count)
        end
        if count <=0 then return true end
    end
    return false
end

---@param item InvItem the InvItem to store
---@param slots? table the result of a ``_SHOP.StorageGetSlots()`` operation. Used to update the slots list for efficiency reasons. It will be ignored if nil.
function _SHOP.StorageStoreItemWithoutChecking(item, slots)
    GAME:GivePlayerStorageItem(item)
    if slots then
        local id, count, hidden = item.ID, item.Amount, item.HiddenValue
        local itemData = _DATA:GetItem(id)
        local maxStack = _SHOP.StorageGetItemMaxStack(itemData)
        if itemData.UsageType ~= RogueEssence.Data.ItemData.UseType.Box then
            hidden = ""
        end

        if itemData.MaxStack == 0 then count = 1 end
        for _, index in ipairs(slots.items[item.ID]) do
            local diff = math.min(count, maxStack - slots[index].count)
            if slots[index].hidden ~= hidden then diff = 0 end
            count = count - diff
            slots[index].count = slots[index].count + diff
            if count <=0 then
                slots[index].count = slots[index].count + count
                break
            end
        end
        while count>0 do
            table.insert(slots, {id = id, hidden = hidden, count = math.min(maxStack, count)})
            count = count - math.min(maxStack, count)
            slots.items[id] = slots.items[id] or {}
            table.insert(slots.items[id], #slots)
        end
    end
end

_SHOP.callbacks.initialize["home"] = _SHOP.HomeInitializer
_SHOP.callbacks.upgrade["home"] =    _SHOP.HomeUpgrade
