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
---@return any a randomly chosen object inside the list
function COMMON_FUNC.WeightlessRoll(list)
    local index = math.random(1, #list)
    return list[index]
end