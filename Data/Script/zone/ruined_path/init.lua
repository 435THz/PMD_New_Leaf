--[[
    init.lua
    Created: 11/27/2023 01:56:02
    Description: Autogenerated script file for the map forgotten_path.
]]--
-- Commonly included lua functions and data
require 'common'

-- Package name
local forgotten_path = {}

-------------------------------
-- Zone Callbacks
-------------------------------
---forgotten_path.Init(zone)
--Engine callback function
function forgotten_path.Init(_)

end

---forgotten_path.EnterSegment(zone, rescuing, segmentID, mapID)
--Engine callback function
function forgotten_path.EnterSegment(_, _, segmentID, _)
    if segmentID == 0 then
        --remove pelipper from team
        _DATA.Save.ActiveTeam.Guests:Clear()
        -- add pelipper to team
        local guest_id = RogueEssence.Dungeon.MonsterID("pelipper", 0, "normal", RogueEssence.Data.Gender.Male)
        _DATA.Save.ActiveTeam.Guests:Add(_DATA.Save.ActiveTeam:CreatePlayer(_DATA.Save.Rand, guest_id, 5, "keen_eye", 0))
        local guest = GAME:GetPlayerGuestMember(0)
        GAME:SetCharacterSkill(guest, "wing_attack", 0)
        GAME:SetCharacterSkill(guest, "supersonic", 1)
        GAME:SetCharacterSkill(guest, "roost", 2)
        GAME:ForgetSkill(guest, 3)
        guest.IsPartner = true

        local talk_evt = RogueEssence.Dungeon.BattleScriptEvent("EscortInteract") --TODO edit event
        guest.ActionEvents:Add(talk_evt)
    end
end

---forgotten_path.ExitSegment(zone, result, rescue, segmentID, mapID)
--Engine callback function
function forgotten_path.ExitSegment(_, result, _, segmentID, _)
    DEBUG.EnableDbgCoro() --Enable debugging this coroutine
    PrintInfo("=>> ExitSegment_ruined_path result "..tostring(result).." segment "..tostring(segmentID))

    if result ~= RogueEssence.Data.GameProgress.ResultType.Cleared then
        SV.Intro.DungeonFailed = true
        COMMON.EndSessionWithResults(result, SV.checkpoint.Zone, SV.checkpoint.Segment, SV.checkpoint.Map, SV.checkpoint.Entry)
    else
        SV.Intro.HubReached = true
        COMMON.EndSessionWithResults(result, 'hub_zone', -1, _HUB.getHubRank()-1, 0)
    end
    _DATA.Save.ActiveTeam.Guests:Clear() --remove pelipper from team
end

--Engine callback function
function forgotten_path.Rescued(_, _, _)


end

return forgotten_path

