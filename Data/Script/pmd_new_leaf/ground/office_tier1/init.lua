--[[
    init.lua
    Created: 02/21/2024 02:13:24
    Description: Autogenerated script file for the map office_tier1.
]]--
-- Commonly included lua functions and data
require 'origin.common'
require 'pmd_new_leaf.HubManager'

-- Package name
local office_tier1 = {}

-- Local, localized strings table
-- Use this to display the named strings you added in the strings files for the map!
-- Ex:
--      local localizedstring = STRINGS.MapStrings['SomeStringName']


-------------------------------
-- Map Callbacks
-------------------------------
---office_tier1.Init(map)
--Engine callback function
function office_tier1.Init(map)
    if SV.Intro.HubTutorialProgress<2 then
        GROUND:CharSetAnim(CH("Pelipper"), "Sleep", true)
        GROUND:Hide("Pelipper")
    elseif SV.Intro.HubTutorialProgress<4 then
    end
end

---office_tier1.Enter(map)
--Engine callback function
function office_tier1.Enter(map)
    GAME:FadeIn(20)
end

---office_tier1.Exit(map)
--Engine callback function
function office_tier1.Exit(map)

end

---office_tier1.Update(map)
--Engine callback function
function office_tier1.Update(map)

end

---office_tier1.GameSave(map)
--Engine callback function
function office_tier1.GameSave(map)

end

---office_tier1.GameLoad(map)
--Engine callback function
function office_tier1.GameLoad(map)
    _HUB.ShowTitle()
end

-------------------------------
-- Entities Callbacks
-------------------------------
function office_tier1.Pelipper_Talk_Action(obj, activator)
    if SV.Intro.HubTutorialProgress<2 then
        UI:ResetSpeaker(false)
        UI:WaitShowDialogue("He seems to be sleeping.[pause=0] You probably shouldn't disturb him.")
        UI:ResetSpeaker()
    elseif SV.Intro.HubTutorialProgress>1 then --TODO set back to >3
        _SHOP.ShopInteract("office")
    end
end

function office_tier1.Exit_Touch(obj, activator)
    GAME:FadeOut(false, 20)
    local pos = _HUB.getPlotOriginList()[2]
    local marker = _HUB.ShopBase["office"].Graphics[1].Marker_Loc
    GAME:EnterGroundMap(_HUB.getHubMap(), "Entrance")
    _HUB.SetMarker(pos.X + marker.X, pos.Y + marker.Y)
end

return office_tier1

