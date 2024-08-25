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

-------------------------------------------
--region COMMON+
-------------------------------------------

function COMMON_FUNC.EndSessionWithResults(result, zoneId, structureId, mapId, entryId)
    GAME:EndDungeonRun(result, zoneId, structureId, mapId, entryId, true, true)
    GAME:EnterZone(zoneId, structureId, mapId, entryId)
end

---Rolls for a random object inside a list and returns the result.
---Every object has the same chance of being chosen.
---@param list table a table of possible results
---@return number, any the index of a randomly chosen object inside the list and the object in question
function COMMON_FUNC.WeightlessRoll(list)
    local index = math.random(1, #list)
    return list[index], index
end

---Rolls for a random list inside a list and returns the result.
---Every table uses its length as its weight of probability.
---@param list table a table of tables
---@return number, table the index of a randomly chosen table inside the list and the table in question, or nil, nil if the list is empty
function COMMON_FUNC.LengthWeightedTableListRoll(list)
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
---@return number, table the index of a randomly chosen entry inside the list and the entry in question, or nil, nil if the list is empty
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