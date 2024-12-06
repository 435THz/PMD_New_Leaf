require 'pmd_new_leaf.Global'
require 'pmd_new_leaf.HubManager'
require 'pmd_new_leaf.CommonFunctions'

function BATTLE_SCRIPT.SaveCatchData(_, _, context, _)
    if context.Target.MemberTeam == _DATA.Save.ActiveTeam then
        COMMON_FUNC.SaveStartData(context.Target)
    end
end
