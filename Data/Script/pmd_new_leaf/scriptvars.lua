--[[
    scriptvars.lua
      This file contains all the default values for the script variables. AKA on a new game this file is loaded!
      Script variables are stored in a table that gets saved when the game is saved.
      Its meant to be used to add data to be saved and loaded during a playthrough.
      
      You can simply refer to the "SV" global table like any other table in any scripts!
      You don't need to write a default value in this lua script to add a new value.
      However its good practice to set a default value when you can!
      
      It is important to stress that this file initializes the SV table ONCE when the player begins a new save file, and NEVER EVER again.
      This means that edits on this file will NOT be added on the script variables of an already existing file!
      To upgrade existing script variables, use the OnUpgrade in script services.  Example found in Data/Script/services/debug_tools/init.lua
      
    --Examples:
    SV.SomeVariable = "Smiles go for miles!"
    SV.AnotherVariable = 2526
    SV.AnotherVariable = { something={somethingelse={} } }
    SV.AnotherVariable = function() PrintInfo('lmao') end
]]--

-----------------------------------------------
-- General Defaults
-----------------------------------------------
SV.adventure =
{
    Thief    = false
}

SV.missions =
{
    Missions = { },
    FinishedMissions = { },
}

-----------------------------------------------
-- Level Specific Defaults
-----------------------------------------------
SV.HubData = {
    RunEnded = false, -- if true, teleporting the player to their home will play the wake up cutscene and set it back to false.
    Marker = nil,     -- if set, the character will be teleported here upon hub load, and then this will be cleared.
    Level = 1,        -- 1 to 10
    Name = "Base",    -- without rank suffix. can be changed from rank 2 onwards
    UseSuffix = true, -- can only be turned off at rank 4
    Plots = {}        -- contains plot struct. See HubManager.lua for details
}

SV.Intro = {
    CharacterCreated = false,   -- if the character creation sequence was finished
    PelipperIntro = false,      -- if the starting Ruined Path cutscene happened
    SaveReminder = false,       -- if the player was told about saving from the menu
    DungeonFailed = false,      -- if true, there will be a return-to-entrance cutscene when coming back to Ruined Path and this will be set to false again.
    HubReached = false,         -- if the hub has been reached
    -- 0 = nothing is done yet
    -- 1 = tents built
    -- 2 = first slept
    -- 3 = first run ended
    HubTutorialProgress = 0
}


-----------------------------------------------
-- General Defaults - BASEGAME
-----------------------------------------------

SV.General =
{
    Starter = MonsterID("missingno", 0, "normal", Gender.Genderless)
    --Anything that applies to more than a single level, and that is too small to make a sub-table for, should be put in here ideally, or a sub-table of this
}

SV.checkpoint =
{
    Zone    = 'ruined_path', Segment  = -1,
    Map  = 0, Entry  = 0
}


SV.base_shop = {
    { Index = "food_apple", Amount = 0, Price = 50},
    { Index = "food_apple_big", Amount = 0, Price = 150},
    { Index = "food_banana", Amount = 0, Price = 500},
    { Index = "food_chestnut", Amount = 0, Price = 80},
    { Index = "berry_leppa", Amount = 0, Price = 80}
}
SV.base_trades = {
    { Item="xcl_family_bulbasaur_02", ReqItem={"",""}},
    { Item="xcl_family_charmander_02", ReqItem={"",""}},
    { Item="xcl_family_squirtle_02", ReqItem={"",""}}
}

SV.unlocked_trades = {
}


SV.magnagate =
{
    Cards = 0
}

-----------------------------------------------
-- Level Specific Defaults - BASEGAME
-----------------------------------------------
SV.test_grounds =
{
    SpokeToPooch = false,
    AcceptedPooch = false,
    Starter = { Species="pikachu", Form=0, Skin="normal", Gender=2 },
    Partner = { Species="eevee", Form=0, Skin="normal", Gender=1 },
    DemoComplete = false,
    Tileset = 0,
}

SV.dex = {
    CurrentRewardIdx = 1
}

SV.roaming_legends =
{
    Raikou = false,
    Entei = false,
    Suicune = false,
    Celebi = false,
    Darkrai = false
}

SV.base_camp =
{
    IntroComplete    = false,
    ExpositionComplete  = false,
    FirstTalkComplete  = false,
    FoodIntro  = false,
    FerryUnlocked  = false,
    FerryIntroduced  = false,
    CenterStatueDate  = "",
    LeftStatueDate  = "",
    RightStatueDate  = ""
}

SV.base_town =
{
    Song    = "A02. Base Town.ogg",
    ValueTradeItem = "",
    ValueTraded = false
}

SV.luminous_spring =
{
    Returning    = false
}

SV.team_retreat =
{
    Intro = false
}

----------------------------------------------