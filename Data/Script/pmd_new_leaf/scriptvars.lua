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
    RunEnded = false, -- if true, teleporting the player to their home will play the wake up cutscene and set this back to false.
    SkipNextMorning = false, -- if true, the next wake up cutscene will skip the next morning message and set this back to false
    Marker = nil,     -- if set, the character will be teleported here upon hub load, and then this will be cleared.
    Level = 1,        -- 1 to 10
    Name = "Base",    -- without rank suffix. can be changed from rank 2 onwards
    UseSuffix = true, -- can only be turned off at rank 4
    Plots = {},       -- contains plot struct. See HubManager.lua for details
    Quests = {
        Unlocked = {},
        Completed = {}
    }
}

SV.WishUpgrades = {
    --- Upgrades related to the passage areas
    Passages = {
        --- If 1, Wishing Wells will spawn in the passage areas. They work like in hades
        WishingWell = 0,
        --- If 1, Assembly Boxes will spawn in the passage areas. You can only switch, not take.
        --- The citizen will take the switched out mon's exact exp
        AssemblyBox = 0,
        --- Add this value to the base Item Box size. Meta currency items are always saved.
        ItemBoxSize = 0,
    },
    --- Upgrades related to the dungeons themselves
    Dungeons = {
      --- Evolution Altars will spawn in dungeons in areas up to this value
      EvoAltars = 0,
      --- Merchants will spawn in dungeons in areas up to this value
      Merchants = 0,
      --- Wishing Wells will spawn in dungeons in areas up to this value
      WishingWell = 0,
      --- Secret Stairs will spawn in dungeons in areas up to this value
      SecretStairs = 0,
      --- Minibosses will spawn in dungeons in areas up to this value
      Minibosses = 0,
      --- Vault Floors will spawn in dungeons in areas up to this value
      VaultFloors = 0,
      --- Wishing Wells will spawn in dungeons in areas up to this value
      WishingWell = 0,
      --- Purify a Corrupted Wish to get lots of fragments. But, the removed corruption will spread back into the dungeons...
      --- (acts like boss cells in Dead Cells after purifying)
      WishesPurified = 0,
      --- Currently selected difficulty level
      CorruptionLevel = 0,
    },
    --- Upgrades related to the player
    Player = {
        --- Increase the money you can start a run with: 0 = 500, 1 = 750, 2 = 1000, 3 = 1500, 4 = 2000, 5 = 3000
        StartingMoneyUp = 0,
        --- You can enter dungeons with 2 members + this value. The in-dungeon limit is still 4, even when you can't start with that.
        TeamLimitUp = 0,
        --- Add 8 inventory slots
        ExtraBags = 0,
        --- Number of items you can start a run with. First upgrade is free as part of the tutorial.
        StartItems = 0,
        --- Increase the amount of Boost points kept at the start of a run. The limit is applied to each stat separately.
        --- limit = this value * 32
        StartBoosts = 0
    }
}

SV.Intro = {
    --- true if the character creation sequence has been finished
    CharacterCreated = false,
    --- true if the starting Ruined Path cutscene happened
    PelipperIntro = false,
    --- true if the player was told about saving from the menu
    SaveReminder = false,
    --- if true, there will be a return-to-entrance cutscene when coming back to Ruined Path and this will be set to false again.
    DungeonFailed = false,
    --- if true, then Jirachi will appear
    ObtainedWishFragments = false,
    --- true if the hub has been reached
    HubReached = false,
    --- 0 = nothing is done yet;
    --- 1-5 = intro tutorials;
    --- 6+  = dungeon tutorial proper
    DungeonTutorialProgress = 0,
    --- 0 = nothing is done yet;
    --- 1 = tents built;
    --- 2 = first slept;
    --- 3 = pelipper left;
    --- 4 = first run ended;
    --- 5 = first shop built;
    --- 6 = first upgrade done;
    --- 7 = first town upgrade
    HubTutorialProgress = 0,
    --- false until players hover over something that has Random effects, true forever from then on
    CafeRandomDiscovered = false
}

SV.RunData = {
    CharCounter = 0
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