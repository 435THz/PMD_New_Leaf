--[[
    A set of various scripting routines that can be useful pretty much anywhere
]]
COMMON_FUNC = {}

-------------------------------------------
--region Logic
-------------------------------------------
-- Ternary operator
function COMMON_FUNC.tri(check, t, f)
    if check then return t else return f end
end

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

function table.index_of(table, object, default)
    if default==nil then default = -1 end
    for index, element in pairs(table) do
        if element == object then return index end
    end
    return default
end

-------------------------------------------
--region COMMON+
-------------------------------------------

function COMMON_FUNC.EndSessionWithResults(result, zoneId, structureId, mapId, entryId)
    GAME:EndDungeonRun(result, zoneId, structureId, mapId, entryId, true, true)
    GAME:EnterZone(zoneId, structureId, mapId, entryId)
end