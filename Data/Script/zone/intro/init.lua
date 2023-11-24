--[[
    init.lua
    Created: 11/01/2023 17:36:19
    Description: Autogenerated script file for the map intro.
]]--
-- Commonly included lua functions and data
require 'common'

-- Package name
local intro = {}

-- Local, localized strings table
-- Use this to display the named strings you added in the strings files for the map!
local MapStrings = {}

-------------------------------
-- Zone Callbacks
-------------------------------
---intro.Init(zone)
--Engine callback function
function intro.Init(zone)
    --This will fill the localized strings table automatically based on the locale the game is
    -- currently in. You can use the MapStrings table after this line!
    MapStrings = COMMON.AutoLoadLocalizedStrings()
end

---intro.EnterSegment(zone, rescuing, segmentID, mapID)
--Engine callback function
function intro.EnterSegment(zone, rescuing, segmentID, mapID)


end

---intro.ExitSegment(zone, result, rescue, segmentID, mapID)
--Engine callback function
function intro.ExitSegment(zone, result, rescue, segmentID, mapID)


end

---intro.Rescued(zone, name, mail)
--Engine callback function
function intro.Rescued(zone, name, mail)


end
------------------------------------------
-- Intro script
------------------------------------------

return intro

