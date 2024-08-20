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