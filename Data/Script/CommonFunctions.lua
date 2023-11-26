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

-------------------------------------------
--region Table
-------------------------------------------

function table.index_of(table, object, default)
    for index, element in pairs(table) do
        if element == object then return index end
    end
    return default
end

