--[[
    HubManager.lua
    Contains all constant global tables and variables necessary for the Hub to function, plus some functions that interface with them in a more intuitive way.
]]
require 'pmd_new_leaf.CommonFunctions'
require 'pmd_new_leaf.shops.ShopInterface'

--- Takes any kind of value and prints it in the easiest to read format it can.
--- If the supplied element is a table, this function will recursively print its entire contents,
--- increasing the indentation for every new layer discovered.
--- If the supplied element is not a table, it will just print its value.
--- @param element any the object to print
--- @param max_depth number the deepest layer this function will explore. if 1 or lower, it will only explore the first layer. Defaults to 20.
function printall(elem, max_depth)
    if max_depth == nil then max_depth = 20 end
    if max_depth < 1 then max_depth = 1 end

    local rec_printall = function(element, level, root, this)
        if root == nil then print(" ") end

        if element == nil then print("<nil>") return end
        if type(element) ~= 'table' then print(tostring(element)) return end

        if level == nil then level = 0 end
        for key, value in pairs(element) do
            local spacing = ""
            for _=1, level*2, 1 do
                spacing = " "..spacing
            end
            if type(value) == 'table' then
                if level<=max_depth then
                    print(spacing..tostring(key).." = {")
                    this(value, level+1, false, this)
                    print(spacing.."}")
                else
                    print(spacing..tostring(key).." = {...}")
                end
            else
                print(spacing..tostring(key).." = "..tostring(value))
            end
        end

        if root == nil then print(" ") end
    end

    rec_printall(elem, 0, nil, rec_printall)
end


_HUB = _HUB or {}

require 'pmd_new_leaf.ShopManager'

--- Maps ranks to level
_HUB.LevelRankTable = {1,1,2,2,2,3,3,3,4,4}
--- maps town name suffixes to rank
_HUB.RankSuffixKey = {"HUB_TIER_SMALL", "HUB_TIER_MEDIUM", "HUB_TIER_LARGE", "HUB_TIER_FINAL"}
--- maps town name patterns to rank
_HUB.RankNamePatterns = {"HUB_PATTERN_SMALL", "HUB_PATTERN_MEDIUM", "HUB_PATTERN_LARGE", "HUB_PATTERN_FINAL"}
--- maps town ground map id to rank
_HUB.RankHubMap = {"hub_small", "hub_medium", "hub_large", "hub_final"}
--- maps town map object id to rank
_HUB.RankPlotMap = {"map_small", "map_medium", "map_large", "map_final"}
--- maps town build limit to level
_HUB.LevelBuildLimit = {2,3,4,5,6,7,8,10,12,15}
--- maps town plots to rank
_HUB.RankPlotNumber = {3,6,10,15}
-- maps assembly limit to rank. TODO PROBABLY WILL BE SCRAPPED
_HUB.LevelAssemblyLimit = {10,25,40,60,80,100,150,200,300,500}
--- maps a list of map coordinates to every rank. Ground Map version.
_HUB.PlotPositions = {
    -- rank 1
    {
        {X=128, Y=64},  -- first plot is always "home"
        {X=304, Y=64},  -- second plot is always "office"
        {X=64,  Y=216}, -- plots 3+ have their plot index-2 as their id; this is the 3rd plot, but its id is "1"
        {X=368, Y=216}, -- this is the 4th plot, but its id is "2"
        {X=216, Y=216}  -- this is the 5th plot, but its id is "3"
    },
    -- rank 2, WIP
    {
        {X=128, Y=64},
        {X=304, Y=64},
        {X=64,  Y=216},
        {X=368, Y=216},
        {X=216, Y=216},
        ---------------
        {X=128, Y=64},
        {X=304, Y=64},
        {X=64,  Y=216}
    },
    -- rank 3, WIP
    {
        {X=128, Y=64},
        {X=304, Y=64},
        {X=64,  Y=216},
        {X=368, Y=216},
        {X=216, Y=216},
        ---------------
        {X=128, Y=64},
        {X=304, Y=64},
        {X=64,  Y=216},
        {X=368, Y=216},
        {X=216, Y=216},
        {X=128, Y=64},
        {X=304, Y=64}
    },
    -- rank 4, WIP
    {
        {X=128, Y=64},
        {X=304, Y=64},
        {X=64,  Y=216},
        {X=368, Y=216},
        {X=216, Y=216},
        ---------------
        {X=128, Y=64},
        {X=304, Y=64},
        {X=64,  Y=216},
        {X=368, Y=216},
        {X=216, Y=216},
        {X=128, Y=64},
        {X=304, Y=64},
        {X=64,  Y=216},
        {X=368, Y=216},
        {X=216, Y=216},
        {X=128, Y=64},
        {X=304, Y=64}
    }
}
--- maps a list of map coordinates to every rank. Office Plot Marker version. Entries do not include home and office
_HUB.PlotMarkerMapPositions = {
    -- rank 1
    {
        {X=6,  Y=27},
        {X=48, Y=27},
        {X=27, Y=27}
    },
    -- rank 2
    {
        {X=21, Y=27},
        {X=45, Y=27},
        {X=6,  Y=6},
        {X=60, Y=6},
        {X=6,  Y=27},
        {X=60, Y=27}
    },
    -- rank 3
    {
        {X=30, Y=30},
        {X=54, Y=30},
        {X=15, Y=9},
        {X=69, Y=9},
        {X=15, Y=36},
        {X=69, Y=36},
        {X=6,  Y=51},
        {X=27, Y=51},
        {X=57, Y=51},
        {X=78, Y=51}
    },
    -- rank 4
    {
        {X=36, Y=30},
        {X=60, Y=30},
        {X=21, Y=9},
        {X=75, Y=9},
        {X=21, Y=36},
        {X=75, Y=36},
        {X=21, Y=66},
        {X=36, Y=72},
        {X=60, Y=72},
        {X=75, Y=66},
        {X=6,  Y=39},
        {X=90, Y=39},
        {X=6,  Y=63},
        {X=90, Y=63},
        {X=48, Y=51}
    }
}
--- lists of items required to upgrade the town to each level. table 1 is empty because town starts at level 1 anyway
_HUB.LevelUpCosts = {
    {},
    {
        {item = "loot_wish_fragment", amount = 1 }
    },
    {
        {item = "loot_wish_fragment", amount = 2 }
    },
    {
        {item = "loot_wish_fragment", amount = 4 }
    },
    {
        {item = "loot_wish_fragment", amount = 6 }
    },
    {
        {item = "loot_wish_fragment", amount = 8 }
    },
    {
        {item = "loot_wish_fragment", amount = 12 }
    },
    {
        {item = "loot_wish_fragment", amount = 16 }
    },
    {
        {item = "loot_wish_fragment", amount = 21 }
    },
    {
        {item = "loot_wish_fragment", amount = 30 }
    }
}

-------------------------------------------
--region Getters
-------------------------------------------

---@return number the current level of the hub itself
function _HUB.getHubLevel()
    return SV.HubData.Level
end

---@return boolean true if there is at least 1 building that has a higher level than the town, false otherwise
function _HUB.canUpgrade()
    for i=1, _HUB.getRankPlotNumber(), 1 do
        local plot = _HUB.getPlotData(i)
        if plot.unlocked and _HUB.getPlotLevel(plot) > _HUB.getHubLevel() then
            return true
        end
    end
    return false
end

---@param level number a number between 1 and 10
---@return table the list of {item: string, amount: int} entries that describes the items required to reach the given level
function _HUB.getLevelUpItems(level)
    return _HUB.LevelUpCosts[level]
end

---@return number the current rank of the hub itself
function _HUB.getHubRank()
    return _HUB.LevelRankTable[_HUB.getHubLevel()]
end

---@return string the current town suffix for the hub
function _HUB.getHubSuffix()
    return STRINGS:FormatKey(_HUB.RankSuffixKey[_HUB.getHubRank()])
end

---@return string the id of the current ground map for the hub
function _HUB.getHubMap()
    return _HUB.RankHubMap[_HUB.getHubRank()]
end

---@return string the id of the current map object for the hub
function _HUB.getHubPlotMap()
    return _HUB.RankPlotMap[_HUB.getHubRank()]
end

---@param lvl number the level to get the build limit of. Defaults to the current hub level.
---@return number the current maximum building number for the hub
function _HUB.getBuildLimit(lvl)
    local level = lvl or _HUB.getHubLevel()
    return _HUB.LevelBuildLimit[level]
end

---@return number the number of plots supported by the current hub map.
function _HUB.getRankPlotNumber()
    return _HUB.RankPlotNumber[_HUB.getHubRank()]
end

---@return number the number of unlocked plots in the hub
function _HUB.getUnlockedNumber()
    local num = 0
    for i=1, _HUB.getRankPlotNumber(), 1 do
        if _HUB.getPlotData(i).unlocked then num = num + 1 end
    end
    return num
end

---@return number the current assembly limit. TODO will probably be scrapped
function _HUB.getAssemblyLimit()
    return _HUB.LevelAssemblyLimit[_HUB.getHubRank()]
end

---@param colorless boolean set to true to not include color codes in the name. False by default
---@return string the current town name. Will not contain color codes if colorless is true
function _HUB.getHubName(colorless)
    local ret = SV.HubData.Name
    if SV.HubData.UseSuffix then
        local rank = _HUB.getHubRank()
        ret = STRINGS:FormatKey(_HUB.RankNamePatterns[rank], ret, STRINGS:FormatKey(_HUB.RankSuffixKey[rank]))
    end
    if colorless then return ret end
    return "[color=#FFFFA5]"..ret.."[color]"
end

---@return table the list of plot coordinates associated to the current hub rank
function _HUB.getPlotOriginList()
    return _HUB.PlotPositions[_HUB.getHubRank()]
end

---@return table the list of office map plot coordinates associated to the current hub rank
function _HUB.getPlotMarkerOriginList()
return _HUB.PlotMarkerMapPositions[_HUB.getHubRank()]
end

---@param plot_id any home, office or any number up to the current rank's plot limit
---@return table a table containing the X and Y coordinates associated to the specified plot id for the current hub rank
function _HUB.getPlotOrigin(plot_id)
    if plot_id == "home" then return _HUB.getPlotOriginList()[1] end
    if plot_id == "office" then return _HUB.getPlotOriginList()[2] end
    return _HUB.getPlotOriginList()[plot_id]
end
---@param plot_id number any number up to the current rank's plot limit
---@return table a table containing the X and Y coordinates of the map token associated to the specified plot id for the current hub rank
function _HUB.getPlotMarkerOrigin(plot_id)
    return _HUB.getPlotMarkerOriginList()[plot_id]
end

-------------------------------------------
--region Graphics
-------------------------------------------

--- This function loads all plot relevant data and injects the necessary decorations and
--- interactive objects inside the current map.
--- This code ignores any active plot and only loads the empty plot assets.
function _HUB.LoadMapEmpty()
    for i, pos in pairs(_HUB.getPlotOriginList()) do
        if     i == 1 then _HUB.DrawEmpty("home",   _HUB.getPlotData("home").empty,   pos)
        elseif i == 2 then _HUB.DrawEmpty("office", _HUB.getPlotData("office").empty, pos)
        else               _HUB.DrawEmpty(i-2,      _HUB.getPlotData(i-2).empty,      pos)
        end
    end
    GAME:GetCurrentGround().Name = RogueEssence.LocalText(_HUB.getHubName(true))
end

--- This function loads all plot relevant data and injects the necessary decorations and
--- interactive objects inside the current map.
--- Any inactive plot will have its empty plot assets loaded instead.
function _HUB.LoadMapData()
    for i, pos in pairs(_HUB.getPlotOriginList()) do
        if i == 1 then _HUB.DrawBuilding("home", _HUB.getPlotData("home"), pos)
        elseif i == 2 then _HUB.DrawBuilding("office", _HUB.getPlotData("office"), pos)
        else
            local shop_data = _HUB.getPlotData(i-2)
            if not shop_data.unlocked then
                _HUB.DrawEmpty(i-2, shop_data.empty ,pos)
            elseif shop_data.building ~= "" then
                _HUB.DrawBuilding(i-2, shop_data, pos)
            end
        end
    end
    GAME:GetCurrentGround().Name = RogueEssence.LocalText(_HUB.getHubName(true))
end

---Draws an empty plot by loading the specified empty plot image and the plot's objects in the specified position.
---@param plot_id any home, office or any number
---@param empty_image_id number the id of the asset that defines this plot's appearance when it's empty.
---@param pos table a table containing the X and Y coordinates of the plot's origin
function _HUB.DrawEmpty(plot_id, empty_image_id, pos)
    local graphics_data
    if empty_image_id > #_HUB.NotUnlockedVisuals.NonBlocking then
        graphics_data = _HUB.NotUnlockedVisuals.Blocking[empty_image_id-#_HUB.NotUnlockedVisuals.NonBlocking]
    else
        graphics_data = _HUB.NotUnlockedVisuals.NonBlocking[empty_image_id]
    end

    local deco_bottom = _HUB.GenerateDecoLayer(graphics_data.Base, pos)
    local objects = _HUB.GenerateObjectList(plot_id, graphics_data, pos)
    local sub_decos = _HUB.GenerateSubDecorationList(graphics_data, pos)
    local deco_top
    if graphics_data.TopLayer then deco_top = _HUB.GenerateDecoLayer(graphics_data.TopLayer, pos) end

    local ground = GAME:GetCurrentGround()
    ground.Decorations[0].Anims:Add(deco_bottom)
    if deco_top then ground.Decorations[1].Anims:Add(deco_top) end
    for _, obj in pairs(objects) do
        ground:AddObject(obj)
    end
    for _, deco in pairs(sub_decos) do
        ground.Decorations[0].Anims:Add(deco)
    end
end

---Draws a building by loading the specified building data in the specified position.
---@param plot_id any home, office or any number
---@param building_data table the plot's data structure
---@param pos table a table containing the X and Y coordinates of the plot's origin
function _HUB.DrawBuilding(plot_id, building_data, pos)
    local rank = _HUB.getPlotRank(building_data)
    if not rank then
        local level = _HUB.getPlotLevel(building_data)
        if level < 1 then
            PrintError("Plot ID "..plot_id.." has non-positive level so it has been removed.")
            --_HUB.RemoveShop(plot_id) TODO de-comment before release
        else
            PrintError("Plot ID "..plot_id.." has invalid level "..level)
            PrintError("Attempting to restore valid state...")
            --TODO _HUB.LevelOutOfRangeFailsafe(plot_id)
        end
        return
    end
    local graphics_data = _HUB.ShopBase[building_data.building].Graphics[rank]

    local deco_bottom = _HUB.GenerateDecoLayer(graphics_data.Base, pos)
    local objects = _HUB.GenerateObjectList(plot_id, graphics_data, pos)
    local sub_decos = _HUB.GenerateSubDecorationList(graphics_data, pos)
    local deco_top
    local npc
    if graphics_data.TopLayer then deco_top = _HUB.GenerateDecoLayer(graphics_data.TopLayer, pos) end
    if graphics_data.NPC_Loc then  npc =      _HUB.GenerateNPC(plot_id, building_data.shopkeeper, building_data.shopkeeper_shiny, graphics_data.NPC_Loc, pos) end

    local ground = GAME:GetCurrentGround()
    ground.Decorations[0].Anims:Add(deco_bottom)
    if deco_top then ground.Decorations[1].Anims:Add(deco_top) end
    if npc then ground:AddMapChar(npc) end
    for _, obj in pairs(objects) do
        ground:AddObject(obj)
    end
    for _, deco in pairs(sub_decos) do
        ground.Decorations[0].Anims:Add(deco)
    end
end

--- Loads the specified decoration layer.
--- @param deco string the name of the asset
--- @param pos table a table containing the X and Y coordinates of the plot's origin
--- @return userdata a GroundAnim object corresponding to the requested decoration
function _HUB.GenerateDecoLayer(deco, pos)
    local object = RogueEssence.Content.ObjAnimData(deco, 1)
    local sheet = RogueEssence.Content.GraphicsManager.GetObject(deco)
    local size_x, size_y = sheet.Width, sheet.Height
    local offset_x, offset_y = (96-size_x)//2, (96-size_y)//2
    return RogueEssence.Ground.GroundAnim(object, RogueElements.Loc(pos.X+offset_x, pos.Y+offset_y))
end

--- Creates a new interactable NPC using the supplied data.
--- @param plot_id any home, office or any number
--- @param shopkeeper string the id of the shopkeeper's species
--- @param NPC_Loc table a table containing the X and Y offsets of the shopkeeper, starting from the plot's origin
--- @param pos table a table containing the X and Y coordinates of the plot's origin
--- @return userdata a GroundChar object corresponding to the requested NPC
function _HUB.GenerateNPC(plot_id, shopkeeper, shiny, NPC_Loc, pos)
    local nickname = _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Monster]:Get(shopkeeper.species).Name:ToLocal()
    local name = "NPC_"..plot_id
    local x, y = NPC_Loc.X + pos.X, NPC_Loc.Y + pos.Y
    local form = shopkeeper.form or 0
    local skin = "normal"
    if shiny then skin = "shiny" end
    local temp_monster = RogueEssence.Dungeon.MonsterID(shopkeeper.species, form, skin, Gender.Genderless)
    local npc = RogueEssence.Ground.GroundChar(temp_monster, RogueElements.Loc(x, y), Direction.Down, nickname, name)
    npc:ReloadEvents()
    return npc
end

--- Creates a list of objects using the supplied graphics data.
--- @param plot_id any home, office or any number
--- @param graphics_data table the Graphics table of the requested building. See ShopManager.lua for details
--- @param pos table a table containing the X and Y coordinates of the plot's origin
--- @return table a list of GroundObjects corresponding to all of the objects described in the Bounds data of this building.
function _HUB.GenerateObjectList(plot_id, graphics_data, pos)
    local objects = {}

    if not graphics_data.Bounds then return objects end
    for _, box in pairs(graphics_data.Bounds) do
        -- Display setup
        local anim = _HUB.GenerateAnimData(box.Display)

        -- Bounds setup
        local x, y = pos.X+box.X, pos.Y+box.Y
        local w, h = box.W, box.H
        local rect = RogueElements.Rect.FromPoints(RogueElements.Loc(x,y), RogueElements.Loc(x+w, y+h))

        -- Functionality setup
        local trigger = box.Trigger
        if not trigger then trigger = RogueEssence.Ground.GroundEntity.EEntityTriggerTypes.None end
        local passable = not box.Solid
        if box.Solid == nil then passable = false end
        local name = box.Name.."_"..plot_id
        local obj = RogueEssence.Ground.GroundObject(anim, RogueElements.Dir8.Down, rect, RogueElements.Loc(), trigger, passable, name)
        obj.Passable = passable
        obj:ReloadEvents()
        table.insert(objects, obj)
    end
    return objects
end

--- Plots can require other decoration objects. This function creates a list of decorations using
--- the supplied graphics data.
--- @param graphics_data table the Graphics table of the requested building. See ShopManager.lua for details
--- @param pos table a table containing the X and Y coordinates of the plot's origin
--- @return table a list of GroundAnim objects corresponding to all of the decorations described in the Decorations data of this building
function _HUB.GenerateSubDecorationList(graphics_data, pos)
    local decos = {}

    if not graphics_data.Decorations then return decos end
    for _, deco_data in pairs(graphics_data.Decorations) do
        local anim = _HUB.GenerateAnimData(deco_data.Display)
        local offset_x, offset_y =  deco_data.X, deco_data.Y
        local anim_obj = RogueEssence.Ground.GroundAnim(anim, RogueElements.Loc(pos.X+offset_x, pos.Y+offset_y))
        table.insert(decos, anim_obj)
    end
    return decos
end

--- Loads a single decoration object.
--- @param display table a table containing the animation data for the specified decoration
--- @return userdata an ObjAnimData created using the supplied animation data
function _HUB.GenerateAnimData(display)
    local anim_index, frame_time, frame_start, frame_end = "", 1, -1, -1
    if display and display.Sprite then
        anim_index = display.Sprite
        if display.FrameLength then frame_time = display.FrameLength end
        if display.Start then frame_start = display.Start end
        if display.End then frame_end = display.End end
    end
    return RogueEssence.Content.ObjAnimData(anim_index, frame_time, frame_start, frame_end)
end
-------------------------------------------
--region Scripting
-------------------------------------------

--- Makes sure the screen is black, then displays the hub name in the middle of the screen.
--- if no_fade is false, the game will then fade in. It will stay black otherwise.
--- @param no_fade boolean if true, this function will not automatically fade back in after the title disappears. Defaults to false
function _HUB.ShowTitle(no_fade)
    GAME:FadeOut(false, 1)
    UI:WaitShowTitle(_HUB.getHubName(true), 30)
    GAME:WaitFrames(60)
    UI:WaitHideTitle(30)
    if not no_fade then GAME:FadeIn(20) end
end

--- Loads a set of coordinates in the hub data. Useful to teleport the player in front of buildings when leaving them.
--- @param x number the X coordinate of the marker
--- @param y number the Y coordinate of the marker
function _HUB.SetMarker(x, y)
    SV.HubData.Marker = {X = x, Y = y}
end

--- Teleports the player to the marked position and then clears the marker data.
function _HUB.TeleportToMarker()
    local marker = SV.HubData.Marker
    if marker then
        GROUND:TeleportTo(CH("PLAYER"), marker.X, marker.Y, Direction.Down)
        SV.HubData.Marker = nil
    end
end

--- Teleports the player to their bed at the end of a run.
function _HUB.WakeUpHome()
    SV.HubData.RunEnded = true
    local index = _HUB.getPlotRank(_HUB.getPlotData("home"))
    GAME:EnterGroundMap("hub_zone", "home_tier"..index, "Bed")
end

-------------------------------------------
--region SV Interface
-------------------------------------------

---@param level number the level to set the hub to
function _HUB.setHubLevel(level)
    SV.HubData.Level = level
    _HUB.getPlotData("home").upgrades["upgrade_generic"] = level
    _HUB.getPlotData("office").upgrades["upgrade_generic"] = level
end

---Increases the hub's level by 1
function _HUB.levelUpHub()
    _HUB.setHubLevel(_HUB.getHubLevel()+1)
end

--- Initializes the plot database inside the SV structure.
function _HUB.initializePlotData()
    SV.HubData.Plots = SV.HubData.Plots or {}
    for i = 1, 17, 1 do
        local rand = #_HUB.NotUnlockedVisuals.NonBlocking+#_HUB.NotUnlockedVisuals.Blocking
        if i>5 or (i>2 and i<5) then rand = rand end

        local plot_base = {
            unlocked = false,
            building = "",
            upgrades = {
                -- {type = string, count = number}
            },
            shopkeeper = "",
            shopkeeper_shiny = false,
            data = {
                -- see shops folder
            },
            empty = math.random(rand)
        }

        if i<16 then
            -- for cutscene reasons it must be nonblocking
            if i==3 then  plot_base.empty = math.random(#_HUB.NotUnlockedVisuals.NonBlocking) end
            --just a tree in the middle of the plot
            if i==15 then plot_base.empty = 5 end
            table.insert(SV.HubData.Plots, plot_base)
        else
            plot_base.unlocked = true
            plot_base.upgrades["upgrade_generic"] = 1
            plot_base.empty = math.random(#_HUB.NotUnlockedVisuals.NonBlocking)
            if i==16 then
                plot_base.building = "home"
                SV.HubData.Home = plot_base
            else
                plot_base.building = "office"
                SV.HubData.Office = plot_base
            end
        end
    end
end

--- Returns the data of a specified plot
--- @param index any home, office or any positive integer up to 15
--- @return table the plot's entire data table
function _HUB.getPlotData(index)
    if index == "home"   then return SV.HubData.Home   end
    if index == "office" then return SV.HubData.Office end
    return SV.HubData.Plots[index]
end

--- Returns the level of a specified plot
--- @param plot table the plot's data structure, obtained by calling _HUB.getPlotData(index)
--- @return table the plot's level
function _HUB.getPlotLevel(plot)
    local lvl = 0
    for _, count in pairs(plot.upgrades) do
        lvl = lvl + count
    end
    return lvl
end

--- Returns the rank of a specified plot
--- @param plot table the plot's data structure, obtained by calling _HUB.getPlotData(index)
--- @return table the plot's rank
function _HUB.getPlotRank(plot)
    local lvl = _HUB.getPlotLevel(plot)
    return _HUB.LevelRankTable[lvl]
end

--- Takes a list of shopkeepers and filters out any already used species, refilling the list again
--- if and only if it ends up being fully empty.
--- @param shopkeepers table a shopkeepers list as defined in ShopManager.lua
--- @return table, boolean the filtered list of shopkeepers and a boolean that says whether or not the result should be shiny
function _HUB.DiscardUsed(shopkeepers)
    local current = {}
    local list = {}
    local shiny = true
    for _, plot in pairs(SV.HubData.Plots) do
        table.insert(current, plot.shopkeeper)
    end
    local refill_list = function()
        for i in pairs(shopkeepers) do
            if _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Monster]:Get(shopkeepers[i].species).Released then
                table.insert(list, i)
            end
        end
        shiny = not shiny
    end
    refill_list()
    local removed_one = false
    repeat
        local curr_list = {}
        for _, index in pairs(list) do
            table.insert(curr_list, index)
        end
        for _, index in pairs(curr_list) do
            removed_one = false
            if #list == 0 then refill_list() end
            local i = table.index_of(list,    index, nil)
            local j = table.index_of(current, shopkeepers[index].species, nil)
            if j>0 and i>0 then
                table.remove(current, j)
                table.remove(list,    i)
                removed_one = true
            end
        end
    until(#current == 0 or removed_one == false)

    for i=1, #list, 1 do
        list[i] = shopkeepers[list[i]]
    end

    if #list == 0 then return shopkeepers, shiny else return list, shiny end
end

--- Unlocks the plot, allowing the player to build there.
--- @param index number a positive integer up to 15
function _HUB.UnlockPlot(index)
    if index <= _HUB.getRankPlotNumber() and _HUB.getUnlockedNumber() < _HUB.getBuildLimit() then
        _HUB.getPlotData(index).unlocked = true
    end
end

--- Builds a new shop in the specified plot, but only if the plot itself is already unlocked.
--- @param index number a positive integer up to 15
--- @param shop_type string the id of the shop to build
--- @param start_upgrade string the id of the first upgrade this shop will have. Defaults to upgrade_generic
--- @return boolean true if it went well, false if it failed
function _HUB.CreateShop(index, shop_type, start_upgrade)
    local success = false
    if not start_upgrade then start_upgrade = "upgrade_generic" end
    local data = _HUB.getPlotData(index)
    if data.unlocked and data.building=="" then
        local db = _HUB.ShopBase[shop_type]
        if db then
            data.building = shop_type
            _SHOP.InitializeShop(index)
            success = _HUB.UpgradeShop(index, start_upgrade)
            if success then
                _SHOP.FinalizeShop(index)
            else
                data.building = ""
                data.upgrades = {}
                data.data = {}
            end
        end
    end
    return success
end

--- Applies the specified upgrade to the shop in the specified plot
--- @param index any home, office or any positive integer up to 15
--- @param upgrade string the id of the upgrade that will be applied to this shop
--- @return boolean true if it went well, false if it failed
function _HUB.UpgradeShop(index, upgrade)
    local data = _HUB.getPlotData(index)
    if data.unlocked and data.building~="" then
        local level = _HUB.getPlotLevel(data)
        _SHOP.UpgradeShop(index, upgrade)
        return level+1 == _HUB.getPlotLevel(data)
    end
    return false
end

--- Completely removes all shop data in the specified plot
--- @param index number any positive integer up to 15
function _HUB.RemoveShop(index)
    SV.HubData.Plots[index].building = ""
    SV.HubData.Plots[index].upgrades = {}
    SV.HubData.Plots[index].shopkeeper = ""
    SV.HubData.Plots[index].data = {}
end

--- Switches the shop data of two plots. Does nothing if the plot ids are the same.
--- @param index1 number any positive integer up to 15
--- @param index2 number any positive integer up to 15
function _HUB.SwapPlots(index1, index2)
    if index1 == index2 then return end

    local copy = {
        building =   SV.HubData.Plots[index1].building,
        upgrades =   SV.HubData.Plots[index1].upgrades,
        shopkeeper = SV.HubData.Plots[index1].shopkeeper,
        data =       SV.HubData.Plots[index1].data
    }

    index1.building =   index2.building
    index1.upgrades =   index2.upgrades
    index1.shopkeeper = index2.shopkeeper
    index1.data =       index2.data

    index2.building =   copy.building
    index2.upgrades =   copy.upgrades
    index2.shopkeeper = copy.shopkeeper
    index2.data =       copy.data
end