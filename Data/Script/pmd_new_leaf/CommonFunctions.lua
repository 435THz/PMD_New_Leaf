--[[
    A set of various scripting routines that can be useful pretty much anywhere
]]
COMMON_FUNC = {}

------------------------------------------- TODO remove if empty at the end of the project
--region Logic
-------------------------------------------

-------------------------------------------
--region Math
-------------------------------------------


--- Forces a value to be in between two numbers.
--- @param min number the minimum value allowed
--- @param value number the value that needs to be clamped
--- @param max number the maximum value allowed
--- @return number min if value was lower than min, max if value was higher than max, value otherwise.
function math.clamp(min, value, max)
    return math.max(min, math.min(value, max))
end

--- Performs a modulo operation that does not start counting from zero.
--- Useful when cycling through page numbers that start from 1 instead of 0, for example.
--- @param value number the value to modulo
--- @param mod number the modulo
--- @param shift number how much the start of the modulo is shifted from 0. defaults to 1.
--- @return number the shifted modulo, which will always be a number between shift (included) and shift+mod (excluded)
function math.shifted_mod(value, mod, shift)
    if shift == nil then shift = 1 end
    return ((value-shift) % mod) + shift
end

-------------------------------------------
--region Table
-------------------------------------------

---Returns the key associated to a value inside a table
---@param tbl table a table
---@param object any the object to look for
---@param default any a return value to return in case of failure. Defaults to -1
---@return any the key of the object if it is found, default otherwise
function table.index_of(tbl, object, default)
    if default==nil then default = -1 end
    for index, element in pairs(tbl) do
        if element == object then return index end
    end
    return default
end

---Returns whether a table has a specific object as a value
---@param tbl table a table
---@param object any the object to look for
---@return boolean true if tbl contains object, false otherwise
function table.contains(tbl, object)
    return table.index_of(tbl, object, nil) ~= nil
end

---Appends every element of the second table at the end of the first one.
---This function edits tbl1 in-place. It does not create a new table.
---@param tbl1 table a table
---@param tbl2 table another table
function table.merge(tbl1, tbl2)
    table.move(tbl2, 1, #tbl2, #tbl1+1, tbl1)
end

---Appends every element of the other tables provided at the end of the first one, in the given order.
---This function edits tbl in-place. It does not create a new table.
---@param tbl table a table
---@param ... table a list of tables
function table.merge_all(tbl, ...)
    local tables = {...}
    for _, tbl2 in pairs(tables) do
        table.merge(tbl, tbl2)
    end
end

-------------------------------------------
--region COMMON+
-------------------------------------------

function COMMON_FUNC.EndSessionWithResults(result, zoneId, structureId, mapId, entryId)
    GAME:EndDungeonRun(result, zoneId, structureId, mapId, entryId, true, true)
    GAME:EnterZone(zoneId, structureId, mapId, entryId)
end

--- Builds a string using a list of elements and applying the provided function to every element of the list.
--- The elements will be concatenated using the localized `ADD_SEPARATOR` and `ADD_END` strings as separators.
---@param list table the list of items to build the string with
---@param func function a function that takes an item from the list and returns the string that will represent it
function COMMON_FUNC.BuildStringWithSeparators(list, func)
    local str = ""
    for i, entry in pairs(list) do
        if i>1 then
            if i==#list then str = str..STRINGS:FormatKey("ADD_END")
            else str = str..STRINGS:FormatKey("ADD_SEPARATOR") end
        end
        str = str..func(entry)
    end
    return str
end

--- Builds a string that represents an item and its amount
---@param item_id string an item id, or `"(P)"` to print a money value instead
---@param amount number the amount of items to display. If nil, no amount indicator will be printed
function COMMON_FUNC.PrintItemAmount(item_id, amount)
    amount = math.max(0, amount or 0)
    if item_id == "(P)" then
        return STRINGS:FormatKey("MONEY_AMOUNT", amount)
    end
    local str = _DATA:GetItem(item_id):GetIconName()
    if amount>0 then
        str = STRINGS:Format("{0} ({1})", str, tostring(amount))
    end

    return "[color=#FFCEFF]"..str.."[color]"
end

--- Removes a number of copies of a specific item from the player's inventory.
--- If storage is true, it will take from storage after depleting the stock in the inventory.
--- Returns the amount of items NOT removed if the player didn't have enough.
---@param item_id string the id of the item to remove
---@param amount number the amount of copies of the item to remove
---@param storage boolean if true, the function will start taking items from storage after the inventory has been emptied.
---@return number the difference between the the amount of items removed and the amount of requested copies, or 0 if all requested copies have been removed.
function COMMON_FUNC.RemoveItem(item_id, amount, storage)
    for i = 1, amount, 1 do
        local item_slot = GAME:FindPlayerItem(item_id, true, true)
        if not item_slot:IsValid() then
            if storage and GAME.GetPlayerStorageItemCount > 0 then
                GAME:TakePlayerStorageItem(item_id)
            else return amount-i+1 end
        elseif item_slot.IsEquipped then
            GAME:TakePlayerEquippedItem(item_slot.Slot)
        else
            GAME:TakePlayerBagItem(item_slot.Slot)
        end
    end
    return 0
end

--- Removes a number of copies of specific items from the player's inventory.
--- If storage is true, it will take from storage after depleting the stock in the inventory.
---@param cost_table table a list of `{item = string, amount = number}` entries
---@param storage boolean if true, the function will start taking items from storage after the inventory has been emptied.
---@return table a list of `{item = string, amount = number}` entries where `amount` is the amount of copies of `item` NOT removed if the player didn't have enough, or `{}` if all requested copies have been removed..
function COMMON_FUNC.RemoveItems(cost_table, storage)
    local fails = {}
    for _, entry in pairs(cost_table) do
        local missing = COMMON_FUNC.RemoveItem(entry.item, entry.amount, storage)
        if missing > 0 then
            table.insert(fails, {entry.item, missing})
        end
    end
    return fails
end

--- Checks if the player has the given amount of items.
---@param cost_table table a list of `{item = string, amount = number}` entries
---@param check_storage boolean if true, the function will also count the item in storage
function COMMON_FUNC.CheckCost(cost_table, check_storage)
    for _, entry in pairs(cost_table) do
        if COMMON.GetPlayerItemCount(entry.item, check_storage) < entry.amount then
            return false
        end
    end
    return true
end

---Rolls for a random object inside a list and returns the result.
---Every object has the same chance of being chosen.
---@param list table a table of possible results
---@return any, number a randomly chosen entry inside the list and its index, or nil, nil if the list is empty
function COMMON_FUNC.WeightlessRoll(list)
    if #list == 0 then return nil, nil end
    local index = math.random(1, #list)
    return list[index], index
end

---Rolls for a random list inside a list and returns the result.
---Every table uses its length as its weight of probability.
---@param list table a table of tables
---@return table, number a randomly chosen table inside the list and its index, or nil, nil if the list is empty
function COMMON_FUNC.LengthWeightedTableListRoll(list)
    if #list == 0 then return nil, nil end
    local entries = {}
    for i, tbl in pairs(list) do
        table.insert(entries, {Index = i, Weight = #tbl})
    end

    local _, index = COMMON_FUNC.WeightedRoll(entries).Index

    return list[index], index
end

---Rolls for a random table entry inside a list and returns the result.
---Every entry must have a positive Weight property that will determine its chance of being chosen.
---If this property is missing or non-positive, the entry will never be selected.
---@param list table a table of possible results containing a Weight property.
---@return table, number a randomly chosen entry inside the list and its index, or nil, nil if the list is empty
function COMMON_FUNC.WeightedRoll(list)
    local weight_total = 0
    for _, entry in pairs(list) do
        if entry.Weight and entry.Weight > 0 then
            weight_total = weight_total + entry.Weight
        end
    end

    local result = math.random(1, weight_total)

    local count = 0
    for i, entry in pairs(list) do
        if entry.Weight and entry.Weight > 0 then
            count = count + entry.Weight
            if count>=result then
                return entry, i
            end
        end
    end
    return nil, nil
end