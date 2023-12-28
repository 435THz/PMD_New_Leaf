--[[
    init.lua
    Created: 11/19/2023 20:25:11
    Description: Autogenerated script file for the map intro_scene.
]]--
-- Commonly included lua functions and data
require 'common'
require 'menu.character_menu'
require 'Global'

-- Package name
local intro_scene = {}

-- Local, localized strings table
-- Use this to display the named strings you added in the strings files for the map!
-- Ex:
--      local localizedstring = MapStrings['SomeStringName']
local MapStrings = {}

-------------------------------
-- Map Callbacks
-------------------------------
---intro_scene.Init(map)
--Engine callback function
function intro_scene.Init(map)

    --This will fill the localized strings table automatically based on the locale the game is
    -- currently in. You can use the MapStrings table after this line!
    MapStrings = COMMON.AutoLoadLocalizedStrings()

end

---intro_scene.Enter(map)
--Engine callback function
function intro_scene.Enter(map)
    intro_scene.PlotScripting()
end

---intro_scene.Exit(map)
--Engine callback function
function intro_scene.Exit(map)


end

---intro_scene.Update(map)
--Engine callback function
function intro_scene.Update(map)


end

---intro_scene.GameSave(map)
--Engine callback function
function intro_scene.GameSave(map)


end

---intro_scene.GameLoad(map)
--Engine callback function
function intro_scene.GameLoad(map)
    intro_scene.PlotScripting()
end

-------------------------------
-- Cutscene Script
-------------------------------

function intro_scene.PlotScripting()
    GAME:FadeOut(false, 1)
    if not SV.Intro.CharacterCreated then
        intro_scene.CharacterSelect()
    else
        intro_scene.IntroTeleport()
    end
end

function intro_scene.isStarterAllowed(id)
    local forced_blacklist = {"missingno", "cosmog", "kubfu"} -- excluded no matter what

    local mon = _DATA:GetMonster(id)
    --return true if mon is playable and unevolved and, if it is part of the undiscovered egg group, it has an evolution. Finally, it must not be part of the blacklist.
    --this filters out all unreleased mons, all evolved mons and all non-baby, undiscovered egg group mons, plus some cherry-picked outliars
    return mon.Released and mon.PromoteFrom == "" and (mon.SkillGroup1 ~= "undiscovered" or mon.Promotions.Count>0)
            and not table.index_of(forced_blacklist, id, false)
end

function intro_scene.CharacterSelect()
    GAME:CutsceneMode(true)
    UI:ResetSpeaker()
    SOUND:FadeOutBGM()

    --move camera to arbitrary position. Partner and hero will spawn in at 0,0 when they're created, so this is done to hide that without extra hassle.
	GAME:MoveCamera(300, 300, 1, false)

	--initialize some save data
	_DATA.Save.ActiveTeam:SetRank("unranked")
	_DATA.Save.ActiveTeam.Money = 0
	_DATA.Save.ActiveTeam.Bank = 0
	_DATA.Save.NoSwitching = true--switching is not allowed

    local species_list = {}
    local mons = _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Monster]:GetOrderedKeys(true)

    for id in luanet.each(mons) do
        if intro_scene.isStarterAllowed(id) then
            --only if the check is passed, add the mon as a playable species
            table.insert(species_list, id)
        end
    end


    SOUND:PlayFanfare("Fanfare/Item")
    UI:WaitShowVoiceOver("The Exploration Team Federation\nhas sent a message...", -1)
    SOUND:PlayFanfare("Fanfare/LevelUp")
    UI:WaitShowVoiceOver("You have been chosen for their\nnext exploration initiative!", -1)
    UI:WaitShowVoiceOver("You will be tasked with colonizing\na newly discovered region!", -1)
    UI:WaitShowVoiceOver("All you need to do now is fill in\nsome identification papers.", -1)
    UI:WaitShowVoiceOver("Shall we begin?", -1)
    GAME:WaitFrames(40)

    SOUND:PlayBGM("Welcome to the World of Pokémon!.ogg", true)
    GAME:FadeIn(40)
    GAME:WaitFrames(20)

    local CharacterMenu = CharacterSelectionMenu()
    local menu = CharacterMenu:new(species_list)
    while not menu.confirmed do
        UI:SetCustomMenu(menu:getFocusedWindow())
        UI:WaitForChoice()
    end

    --remove any team members that may exist by default for some reason
    local party_count = _DATA.Save.ActiveTeam.Players.Count
    for ii = 1, party_count, 1 do
        _DATA.Save.ActiveTeam.Players:RemoveAt(0)
    end

    local assembly_count = GAME:GetPlayerAssemblyCount()
    for i = 1, assembly_count, 1 do
        _DATA.Save.ActiveTeam.Assembly.RemoveAt(i-1)--not sure if this permanently deletes or not...
    end

    --generate new player character
    local mon_id = menu:toMonsterID()
    _DATA.Save.ActiveTeam.Players:Add(_DATA.Save.ActiveTeam:CreatePlayer(_DATA.Save.Rand, mon_id, 5, menu.data.intrinsic, 0))
    if menu.data.egg_move ~= '' then
        GAME:SetCharacterSkill(GAME:GetPlayerPartyMember(0), menu.data.egg_move, menu.data.egg_move_index)
    end
    GAME:SetTeamLeaderIndex(0)
    _DATA.Save:UpdateTeamProfile(true)
    _DATA.Save.ActiveTeam.Players[0].IsFounder = true -- cannot be removed from assembly
    _DATA.Save.ActiveTeam.Players[0].IsPartner = true -- cannot be removed from active team. This will be an unlock later on.
    _DATA.Save.ActiveTeam.Players[0]:FullRestore()
    GAME:SetCharacterNickname(_DATA.Save.ActiveTeam.Players[0], menu.data.nickname)
    GAME:SetTeamName("Envoy") --Team Envoy. This will be editable in the future
    COMMON.RespawnAllies()
    SV.Intro.CharacterCreated = true

    UI:WaitShowDialogue("Your data has been registered.")
    UI:WaitShowDialogue("The expedition will start very soon.[pause=0] You will be paired with another agent that will fill you in on the details.")
    UI:WaitShowDialogue("Thank you for your participation![pause=0] We expect great things from you!")
    UI:WaitShowDialogue("Signed: E.T.F.")

    SOUND:FadeOutBGM(120)
    GAME:FadeOut(false, 120)
    GAME:WaitFrames(120)

    UI:WaitShowVoiceOver("Some weeks later...", -1)

    GAME:CutsceneMode(false)
    GAME:EnterGroundMap('ruined_path','intro_dungeon_entrance', 'Spawn_Cutscene')
end

function intro_scene.IntroTeleport()
    GAME:WaitFrames(120)
    UI:WaitShowVoiceOver("...", -1)
    UI:WaitShowVoiceOver("You're here...", -1)
    UI:WaitShowVoiceOver("Why are you here?", -1)
    UI:WaitShowVoiceOver("Shouldn't you be somewhere else?", -1)
    if SV.Intro.HubReached then
        local hub_name = GLOBAL.getHubName()
        UI:WaitShowVoiceOver("Yes, that's right.\nYou should be at "..hub_name..", shouldn't you?", -1)
    else
        UI:WaitShowVoiceOver("Yes, that's right.\nYou should be starting your journey.", -1)
    end
    UI:WaitShowVoiceOver("Don't worry.\nYou'll be back there shortly.", -1)
    UI:WaitShowVoiceOver("Just make sure to notify [color=#800080]MistressNebula[color] about this.\nYou can find her on the [color=#00FFFF]PMDO Discord Server[color] or\nleave a bug report on the mod's [color=#FFFF00]GitHub[color] page.", -1)
    UI:WaitShowVoiceOver("Time to get back to your adventure, now...", -1)

    if not SV.Intro.HubReached then
        GAME:EnterGroundMap('ruined_path','intro_dungeon_entrance', 'Spawn')
    else
        GAME:EnterGroundMap('hub_zone', GLOBAL.getHubMap(), "DefaultSpawn") --TODO fail safe. If player somehow gets to the intro_scene after beating the intro dungeon, warp them to current village map.
    end
end

return intro_scene

