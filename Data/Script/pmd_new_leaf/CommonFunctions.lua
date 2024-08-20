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

function math.clamp(min, value, max)
    return math.max(min, math.min(value, max))
end

--modulo operation with a base different from zero. 'shift' defaults to 1.
function math.shifted_mod(value, mod, shift)
    if shift == nil then shift = 1 end
    return ((value-shift) % mod) + shift
end

-------------------------------------------
--region Table
-------------------------------------------

function table.index_of(tbl, object, default)
    if default==nil then default = -1 end
    for index, element in pairs(tbl) do
        if element == object then return index end
    end
    return default
end

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

function COMMON_FUNC.WeightlessRoll(list)
    local index = math.random(1, #list)
    return list[index]
end