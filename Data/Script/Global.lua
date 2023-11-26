require 'CommonFunctions'
--[[
    Global.lua
    Contains all constant global tables and variables, plus functions that interface with them
]]
GLOBAL = {
    GenderTable = {RogueEssence.Data.Gender.Male, RogueEssence.Data.Gender.Female, RogueEssence.Data.Gender.Genderless},
    HubData = {
        LevelRankTable = {1,1,2,2,2,3,3,3,4,4},
        RankName = {"Camp", "Village", "Town", "City"},
        LevelBuildLimit = {2,3,4,5,6,7,8,10,12,15},
        LevelAssemblyLimit = {10,25,40,60,80,100,150,200,300,500},
        BBLevel = 3
    }
}


-------------------------------------------
--region Save Data Reading
-------------------------------------------

function GLOBAL.getHubRank()
    return GLOBAL.HubData.LevelRankTable[SV.HubData.Level]
end

function GLOBAL.getHubSuffix()
    return GLOBAL.HubData.RankName[GLOBAL.getHubRank()]
end

function GLOBAL.getHubName()
    return "[color=#FFFFA5]"..SV.HubData.Name..COMMON_FUNC.tri(SV.HubData.UseSuffix, " "..GLOBAL.getHubSuffix(), "").."[color]"
end