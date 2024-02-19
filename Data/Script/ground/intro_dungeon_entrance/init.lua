--[[
    init.lua
    Created: 12/10/2023 12:17:25
    Description: Autogenerated script file for the map intro_dungeon_entrance.
]]--
-- Commonly included lua functions and data
require 'common'
require 'HubManager'
require 'CommonFunctions'

-- Package name
local intro_dungeon_entrance = {}

-- Local, localized strings table
-- Use this to display the named strings you added in the strings files for the map!
-- Ex:
--      local localizedstring = MapStrings['SomeStringName']
local MapStrings = {}

-------------------------------
-- Map Callbacks
-------------------------------
---intro_dungeon_entrance.Init(map)
--Engine callback function
function intro_dungeon_entrance.Init(_)
    --This will fill the localized strings table automatically based on the locale the game is
    -- currently in. You can use the MapStrings table after this line!
    MapStrings = COMMON.AutoLoadLocalizedStrings()


end

---intro_dungeon_entrance.Enter(map)
--Engine callback function
function intro_dungeon_entrance.Enter(_)
    intro_dungeon_entrance.ManageCutscenes()
end

---intro_dungeon_entrance.Exit(map)
--Engine callback function
function intro_dungeon_entrance.Exit(_)

end

---intro_dungeon_entrance.Update(map)
--Engine callback function
function intro_dungeon_entrance.Update(_)

end

---intro_dungeon_entrance.GameSave(map)
--Engine callback function
function intro_dungeon_entrance.GameSave(_)

end

---intro_dungeon_entrance.GameLoad(map)
--Engine callback function
function intro_dungeon_entrance.GameLoad(_)

end

-------------------------------
-- Cutscenes
-------------------------------
function intro_dungeon_entrance.ManageCutscenes()
    if not SV.Intro.PelipperIntro then
        intro_dungeon_entrance.PelipperIntro()
    elseif SV.Intro.DungeonFailed then
        SV.Intro.DungeonFailed = false
        intro_dungeon_entrance.KnockoutDialogue()
    else
        local player = CH("PLAYER")
        local marker = MRKR("Spawn")
        GROUND:TeleportTo(player, marker.Position.X, marker.Position.Y, Direction.Up)
        GAME:FadeIn(20)
    end
end

function intro_dungeon_entrance.PelipperIntro()
    GAME:FadeOut(false, 1)
    GAME:CutsceneMode(true)
    GAME:WaitFrames(60)

    local player = CH("PLAYER")
    local pelipper = CH("NPC_Pelipper")

    --define coroutines
    local player_intro_walk = function()
        GROUND:MoveToPosition(player, 172, 42, false, 1)
        GROUND:CharTurnToCharAnimated(player, pelipper, 4)
        GROUND:CharAnimateTurnTo(player, Direction.Right, 4)
    end
    local pelipper_intro_walk = function()
        local marker = MRKR("Spawn")
        GROUND:MoveToMarker(pelipper, marker, false, 1)
        GROUND:MoveToPosition(pelipper, 212, 41, false, 1)
        GROUND:CharTurnToCharAnimated(pelipper, player, 4)
    end

    --prepare camera and characters
    GAME:MoveCamera(180, 120, 1, false)
    GROUND:TeleportTo(player, 172, 224, Direction.Up)
    GROUND:TeleportTo(pelipper, 172, 243, Direction.Up)

    -- run coroutines
    local coro1 = TASK:BranchCoroutine(function() player_intro_walk() end)
    local coro2 = TASK:BranchCoroutine(function() pelipper_intro_walk() end)
    GAME:FadeIn(40)

    -- wait for the characters to finish their movement
    TASK:JoinCoroutines({coro1,coro2})

    -- dialogue
    UI:SetSpeaker(pelipper)
    UI:WaitShowDialogue("Okay.[pause=0] We're almost at ".._HUB.getHubName()..".")
    UI:WaitShowDialogue("I know we're out of supplies, but we're almost there.[pause=0] I think we should just push forward.")
    UI:WaitShowDialogue("If you're ready,[pause=10] or if you have any questions for me[pause=10], just tell me,[pause=5] alright?")
    GROUND:CharAnimateTurnTo(pelipper, Direction.DownLeft, 4)

    GAME:CutsceneMode(false)
    SV.Intro.PelipperIntro = true
end


function intro_dungeon_entrance.KnockoutDialogue()
    GAME:CutsceneMode(true)
    local player = CH("PLAYER")
    local pelipper = CH("NPC_Pelipper")

    local roll1 = math.random(0,6)
    local roll2 = math.random(0,3)
    if roll2 >= roll1-1 then roll2 = roll2+3 end
    local wait1 = 120 + (10*roll1)
    local wait2 = 120 + (10*roll2)

    --define coroutines
    local random_wake = function(chara, turnto, wait)

        GAME:WaitFrames(wait)
        GROUND:CharEndAnim(chara)
        GAME:WaitFrames(45)
        GROUND:CharTurnToCharAnimated(chara, turnto, 4)
    end

    GROUND:CharSetAnim(player, "Sleep", true)
    GROUND:CharSetAnim(pelipper, "Sleep", true)
    GROUND:EntTurn(player, Direction.Down)
    GROUND:EntTurn(pelipper, Direction.Down)
    GAME:FadeIn(30)

    -- run coroutines
    local coro1 = TASK:BranchCoroutine(function() random_wake(player, pelipper, wait1) end)
    local coro2 = TASK:BranchCoroutine(function() random_wake(pelipper, player, wait2) end)

    -- wait for both characters to wake up
    TASK:JoinCoroutines({coro1,coro2})

    GAME:WaitFrames(30)

    UI:SetSpeaker(pelipper)
    UI:WaitShowDialogue("Looks like we're ok...")
    UI:WaitShowDialogue("Let's not get discouraged.[pause=0] We've made it this far,[pause=10] we'll get through this one as well.")

    GAME:CutsceneMode(false)
end
-------------------------------
-- Entities Callbacks
-------------------------------
function intro_dungeon_entrance.NPC_Pelipper_Action(_, _)
    local player = CH("PLAYER")
    local pelipper = CH("NPC_Pelipper")
    UI:SetSpeaker(pelipper)
    local choices = {{"Mission", true}, {"Your role", true}, {"The dungeon", true}, {"Nothing", true}}

    -- characters face each other
    local coro = TASK:BranchCoroutine(function() GROUND:CharTurnToCharAnimated(player, pelipper, 4) end)
    GROUND:CharTurnToCharAnimated(pelipper, player, 4)
    TASK:JoinCoroutines({coro})

    UI:BeginChoiceMenu("Do you need something, "..player:GetDisplayName().."?", choices, 1, 4)
    while true do
        UI:WaitForChoice()
        local result = UI:ChoiceResult()

        if result == 1 then
            UI:WaitShowDialogue("Our mission here is to explore and colonize this region.")
            UI:WaitShowDialogue("Scouting teams have been here,[pause=10] but found no signs of civilization.")
            UI:WaitShowDialogue("On top of that,[pause=10] there are so many dungeons that it's almost impossible to find a safe spot.")
            UI:WaitShowDialogue("The only one that was found is ".._HUB.getHubName()..".[pause=0] That's where we're going now.")
            UI:WaitShowDialogue("We'll set up camp,[pause=10] then our goal will be to investigate what happened to this place.")
        elseif result == 2 then
            UI:WaitShowDialogue("My job here is to accompany you to ".._HUB.getHubName()..",[pause=5] set up shop and keep you in contact with the Federation.")
            UI:WaitShowDialogue("I'll stop accompanying you in dungeons from that point on.[pause=0] Recruiting new team members will be your job.")
        elseif result == 3 then
            UI:WaitShowDialogue("This dungeon is called "..GAME:GetCurrentDungeon():GetDisplayName()..".[pause=0] It looks like an abandoned trading route.")
            UI:WaitShowDialogue("It has now become a special Mystery Dungeon that gives no experience when explored.")
        else
            UI:WaitShowDialogue("Let's get to it,[pause=5] then.")
            break
        end
        UI:BeginChoiceMenu("Other questions?", choices, 1, 4)
    end
    GROUND:CharAnimateTurnTo(pelipper, Direction.DownLeft, 4)
end


function intro_dungeon_entrance.Proceed_Touch(_, _)
    DEBUG.EnableDbgCoro() --Enable debugging this coroutine
    local player = CH("PLAYER")
    local pelipper = CH("NPC_Pelipper")

    UI:SetSpeaker(pelipper)
    SOUND:PlaySE("Menu/Skip")

    -- characters face each other
    local coro = TASK:BranchCoroutine(function() GROUND:CharTurnToCharAnimated(player, pelipper, 4) end)
    GROUND:CharTurnToCharAnimated(pelipper, player, 4)
    TASK:JoinCoroutines({coro})

    UI:ChoiceMenuYesNo("Ready to go?", false)
    UI:WaitForChoice()
    local ch = UI:ChoiceResult()
    if ch then
        GROUND:CharAnimateTurnTo(player, Direction.Up, 4)
        if not SV.Intro.HubReached then
            _DATA:PreLoadZone('ruined_path')
            GAME:FadeOut(false, 20)
            GAME:EnterDungeon('ruined_path', 0, 0, 0, RogueEssence.Data.GameProgress.DungeonStakes.Risk, true, true)
        else
            TASK:BranchCoroutine(function() SOUND:FadeOutBGM(60) end)
            GAME:WaitFrames(30)
            TASK:BranchCoroutine(function() GROUND:CharTurnToCharAnimated(player, pelipper, 4) end)

            UI:WaitShowDialogue("Hold on.[pause=0] I'm getting a weird feeling of déjà vu...")

            local coro_b = TASK:BranchCoroutine(function()
                GAME:WaitFrames(30)
                GROUND:CharAnimateTurnTo(pelipper, Direction.Left, 4)
            end)
            GROUND:MoveToPosition(player, 172, 42, false, 1)
            GROUND:CharTurnToCharAnimated(player, pelipper, 4)
            TASK:JoinCoroutines({coro_b})

            UI:WaitShowDialogue("Hey,[pause=5] "..player:GetDisplayName().."...[pause=10] Didn't we already finish this dungeon?")

            SOUND:PlaySE("Battle/EVT_Emote_Confused")
            GROUND:CharSetEmote(player, "question", 1)
            GAME:WaitFrames(60)

            UI:WaitShowDialogue("Ah,[pause=5] forget it.[pause=0] Let's just go...")

            local coro_fade = TASK:BranchCoroutine(function()
                GROUND:CharAnimateTurnTo(player, Direction.Up, 4)
                GROUND:MoveToPosition(player, 172, 2, false, 1)
            end)
            GAME:WaitFrames(20)
            GROUND:CharAnimateTurnTo(pelipper, Direction.UpLeft, 4)
            GAME:FadeOut(false, 20)
            TASK:JoinCoroutines({coro_fade})
            GAME:WaitFrames(60)

            UI:ResetSpeaker()
            UI:WaitShowDialogue("Since you have already completed the intro, this dungeon will be skipped.")
            UI:WaitShowDialogue("You are not supposed to be back here, so make sure to notify [color=#800080]MistressNebula[color] about this.")
            UI:WaitShowDialogue("You can either find her on the [color=#00FFFF]PMDO Discord Server[color] or leave a bug report on the mod's [color=#FFFF00]GitHub[color] page.")
            GAME:WaitFrames(60)
            GAME:EnterGroundMap('hub_zone', _HUB.getHubMap(), 'Entrance')
        end
    else
        GROUND:CharAnimateTurnTo(pelipper, Direction.DownLeft, 4)
        GROUND:MoveInDirection(player, Direction.Down, 1, false, 1)
    end
end

function intro_dungeon_entrance.Save_Action(_, _)
    UI:ResetSpeaker()
    UI:ChoiceMenuYesNo("Would you like to save your adventure?")
    UI:WaitForChoice()
    local ch = UI:ChoiceResult()

    if ch then
        GAME:WaitFrames(20)
        GAME:GroundSave()
        UI:WaitShowDialogue("Game Saved!")
    end
    if not SV.Intro.SaveReminder then
        UI:WaitShowDialogue("Remember that you can also save by selecting the [color=#FFFF00]Save[color] option in the main menu.")
        SV.Intro.SaveReminder = true
    else
        GAME:WaitFrames(20)
    end
end

return intro_dungeon_entrance

