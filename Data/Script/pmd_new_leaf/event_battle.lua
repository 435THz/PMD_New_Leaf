require'pmd_new_leaf.Global'
require'pmd_new_leaf.HubManager'

function BATTLE_SCRIPT.SaveCatchData(owner, ownerChar, context, args)
    if context.Target.MemberTeam == _DATA.Save.ActiveTeam then
        local target = context.Target
        local recData = {
            nickname = target.Nickname or "",
            form_data = {
                species = target.BaseForm.Species,
                form = target.BaseForm.Form,
                skin = target.BaseForm.Skin,
                gender = RogueEssence.Script.LuaEngine.Instance:EnumToNumeric(target.BaseForm.Gender) --TODO deal with -1
            },
            ability = target.BaseIntrinsics[0],
            form_ability_slot = target.FormIntrinsicSlot,
            moves = {},
            boosts = {MHP = 0, ATK = 0, DEF = 0, SAT = 0, SDF = 0, SPE = 0}
        }
        local skillnum = math.min(4, target.BaseSkills.Count-1)
        for i=0, skillnum, 1 do
            table.insert(recData.moves, target.BaseSkills[i].SkillNum)
        end
        recData.boosts.MHP = target.MaxHPBonus;
        recData.boosts.ATK = target.AtkBonus;
        recData.boosts.DEF = target.DefBonus;
        recData.boosts.SAT = target.MAtkBonus;
        recData.boosts.SDF = target.MDefBonus;
        recData.boosts.SPE = target.SpeedBonus;
        table.insert(SV.RunData.Recruited, recData)
        printall(recData)
    end
end
