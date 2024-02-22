--[[
    init.lua
    Created: 02/20/2024 19:58:22
    Description: Autogenerated script file for the map home_tier1.
]]--
-- Commonly included lua functions and data
require 'common'
require 'HubManager'

-- Package name
local home_tier1 = {}

-- Local, localized strings table
-- Use this to display the named strings you added in the strings files for the map!
-- Ex:
--      local localizedstring = MapStrings['SomeStringName']
local MapStrings = {}

-------------------------------
-- Map Callbacks
-------------------------------
---home_tier1.Init(map)
--Engine callback function
function home_tier1.Init(map)

  --This will fill the localized strings table automatically based on the locale the game is 
  -- currently in. You can use the MapStrings table after this line!
  MapStrings = COMMON.AutoLoadLocalizedStrings()

end

---home_tier1.Enter(map)
--Engine callback function
function home_tier1.Enter(map)
  local player = CH("PLAYER")
  if SV.HubData.RunEnded then
    GAME:CutsceneMode(true)
    local right = (math.random(0,1) > 0)
    local anim = "EventSleep"
    local wake = true
    if GROUND:CharGetAnimFallback(player, anim) ~= anim     then anim = "Sleep" end
    if GROUND:CharGetAnimFallback(player, "Wake") ~= "Wake" then wake = false   end

    if right then GROUND:EntTurn(player, Dir8.Right)
    else GROUND:EntTurn(player, Dir8.Left) end
    GROUND:CharSetAnim(player, anim, true)
    _HUB.ShowTitle()
    GAME:WaitFrames(75)
    if wake then GROUND:CharWaitAnim(player, "Wake")
    else GAME:WaitFrames(45) end
    GROUND:EntTurn(player, Dir8.Down)
    SV.HubData.RunEnded = false
    GAME:CutsceneMode(false)
  else
    GAME:FadeIn(20)
  end

end

---home_tier1.Exit(map)
--Engine callback function
function home_tier1.Exit(map)

end

---home_tier1.Update(map)
--Engine callback function
function home_tier1.Update(map)

end

---home_tier1.GameSave(map)
--Engine callback function
function home_tier1.GameSave(map)

end

---home_tier1.GameLoad(map)
--Engine callback function
function home_tier1.GameLoad(map)
  _HUB.ShowTitle()
end

-------------------------------
-- Entities Callbacks
-------------------------------
function home_tier1.Exit_Touch(obj, activator)
  GAME:FadeOut(false, 20)
  local pos = _HUB.getPlotOriginList()[1]
  local marker = _HUB.ShopBase["home"].Graphics[1].Marker_Loc
  GAME:EnterGroundMap(_HUB.getHubMap(), "Entrance")
  _HUB.SetMarker(pos.X + marker.X, pos.Y + marker.Y)
end

return home_tier1

