function SINGLE_CHAR_SCRIPT.GuestDeathCheck()
	local player_count = GAME:GetPlayerPartyCount()
	if SV.Intro.HubReached then return end--If we're not at game start then we don't need to do anything

	for i = 0, player_count - 1, 1 do
		local chara = GAME:GetPlayerPartyMember(i)
		if chara.Dead then
			--only beam up team because guests will never be a thing in game ever
			for j = 0, player_count - 1, 1 do -- beam everyone else out
				local chara_2 = GAME:GetPlayerPartyMember(j)
				if not chara_2.Dead then -- don't beam out whoever died
					GAME:WaitFrames(60)
					TASK:WaitTask(_DUNGEON:ProcessBattleFX(chara_2, chara_2, _DATA.SendHomeFX))
					chara_2.Dead = true
				end
			end
		end
	end
end

function SINGLE_CHAR_SCRIPT.TutorialScriptDungeon(owner, ownerChar, context, args)
	if context.User == nil then
		UI:ResetSpeaker()
		if args.Floor > SV.Intro.DungeonTutorialProgress then
			SOUND:PlayFanfare("Fanfare/Note")
			UI:WaitShowDialogue("Head for the stairs![pause=0] You can attack enemies in front of you with " .. STRINGS:LocalKeyString(2) .. ".")
			UI:WaitShowDialogue("Enemies don't take their turn until you do, so take your time and think carefully!")
			SV.Intro.DungeonTutorialProgress = 1
			GAME:WaitFrames(20)
		end
		if args.Floor > SV.Intro.DungeonTutorialProgress then
			SOUND:PlayFanfare("Fanfare/Note")
			UI:WaitShowDialogue("To use moves,[pause=10] hold " .. STRINGS:LocalKeyString(4) .. ",[pause=10] then press " .. STRINGS:LocalKeyString(21) .. ",[pause=10] " .. STRINGS:LocalKeyString(22) .. ",[pause=10] " .. STRINGS:LocalKeyString(23) .. ",[pause=10] or " .. STRINGS:LocalKeyString(24) .. " to use the corresponding move.")
			UI:WaitShowDialogue("Alternatively,[pause=10] press " .. STRINGS:LocalKeyString(9) .. " and choose the Moves option or press " .. STRINGS:LocalKeyString(11) .. " to open the Moves menu directly.")
			SV.Intro.DungeonTutorialProgress = 2
			GAME:WaitFrames(20)
		end
		if args.Floor > SV.Intro.DungeonTutorialProgress then
			SOUND:PlayFanfare("Fanfare/Note")
			UI:WaitShowDialogue("You can carry a certain number of items.[pause=0] Items have a number of various effects and uses.")
			UI:WaitShowDialogue("To see what items you are carrying,[pause=10] press " .. STRINGS:LocalKeyString(9) .. " and choose the Items option.")
			UI:WaitShowDialogue("Alternatively,[pause=10] press " .. STRINGS:LocalKeyString(12) .. " to access your items more quickly.")
			SV.Intro.DungeonTutorialProgress = 3
			GAME:WaitFrames(20)
		end
		if args.Floor > SV.Intro.DungeonTutorialProgress then
			local apple  = RogueEssence.Dungeon.InvItem("food_apple"):GetDisplayName()
			SOUND:PlayFanfare("Fanfare/Note")
			UI:WaitShowDialogue("If you get hungry,[pause=10] eat an " .. apple .. ".[pause=0] If your Belly runs empty,[pause=10] you will lose health until you faint or eat something!")
			SV.Intro.DungeonTutorialProgress = 4
			GAME:WaitFrames(20)
		end
		if args.Floor > SV.Intro.DungeonTutorialProgress then
			SOUND:PlayFanfare("Fanfare/Note")
			UI:WaitShowDialogue("In your travels you may see a black tile with a green arrow.[pause=0] This is known as a Wonder Tile.")
			UI:WaitShowDialogue("Step on one to reset the stat changes of yourself and anyone nearby.")
			SV.Intro.DungeonTutorialProgress = 5
			GAME:WaitFrames(20)
		end
		if args.Floor > SV.Intro.DungeonTutorialProgress then
			SOUND:PlayFanfare("Fanfare/Note")
			UI:WaitShowDialogue("Land at least one move on an enemy before defeating it.[pause=0] You will gain Exp only if you do.")
			UI:WaitShowDialogue("If a team member gains enough Exp,[pause=10] it will level up,[pause=10] increasing its stats and maybe even learning new moves!")
			SV.Intro.DungeonTutorialProgress = 6
			GAME:WaitFrames(20)
		end
		if args.Floor > SV.Intro.DungeonTutorialProgress then
			SOUND:PlayFanfare("Fanfare/Note")
			UI:WaitShowDialogue("You can hold " .. STRINGS:LocalKeyString(3) .. " to run![pause=0] This doesn't let you travel more distance in a single turn,[pause=10] but helps you navigate faster.")
			UI:WaitShowDialogue("Hold " .. STRINGS:LocalKeyString(5) .. " and press a direction to look that way without moving or using up your turn.")
			UI:WaitShowDialogue("You can also hold " .. STRINGS:LocalKeyString(6) .. " to only allow for diagonal movement or rotation.")
			SV.Intro.DungeonTutorialProgress = 7
			GAME:WaitFrames(20)
		end
	end
end

--TODO currently unused
function SINGLE_CHAR_SCRIPT.TutorialScriptItems(owner, ownerChar, context, args)
	if context.User == nil then
		UI:ResetSpeaker()
		if args.Item == nil and not SV.Intro.FuckedUpCheck then
			SOUND:PlayFanfare("Fanfare/Note")
			UI:WaitShowDialogue("Man, MistressNebula fucked up hard this time...")
			SV.Intro.FuckedUpCheck = nil
			GAME:WaitFrames(20)
		end
	end
end