--[[
    HubManager.lua
    Contains all constant global tables and variables necessary for the Hub to function, plus some functions that interface with them in a more intuitive way.
]]
require 'pmd_new_leaf.CommonFunctions'

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
_HUB.RankSuffix = {"Camp", "Village", "Town", "City"}
--- maps town map id to rank
_HUB.RankHubMap = {"hub_small", "hub_medium", "hub_large", "hub_final"}
--- maps town build limit to level
_HUB.LevelBuildLimit = {2,3,4,5,6,7,8,10,12,15}
--- maps assembly limit to rank. TODO PROBABLY WILL BE SCRAPPED
_HUB.LevelAssemblyLimit = {10,25,40,60,80,100,150,200,300,500}
--- maps a list of map coordinates to every rank
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

-------------------------------------------
--region Getters
-------------------------------------------

---@return number the current rank of the hub itself
function _HUB.getHubRank()
    return _HUB.LevelRankTable[SV.HubData.Level]
end

---@return string the current town suffix for the hub
function _HUB.getHubSuffix()
    return _HUB.RankSuffix[_HUB.getHubRank()]
end

---@return string the id of the current town map for the hub
function _HUB.getHubMap()
    return _HUB.RankHubMap[_HUB.getHubRank()]
end

---@return number the current maximum building number for the hub
function _HUB.getBuildLimit()
    return _HUB.LevelBuildLimit[_HUB.getHubRank()]
end

---@return number the current assembly limit. TODO will probably be scrapped
function _HUB.getAssemblyLimit()
    return _HUB.LevelAssemblyLimit[_HUB.getHubRank()]
end

---@param colorless boolean set to true to not include color codes in the name. False by default
---@return string the current town name. Will not contain color codes if colorless is true
function _HUB.getHubName(colorless)
    local ret = SV.HubData.Name
    if SV.HubData.UseSuffix then ret = ret.." ".._HUB.getHubSuffix() end
    if colorless then return ret end
    return "[color=#FFFFA5]"..ret.."[color]"
end

---@return table the list of plot coordinates associated to the current hub rank
function _HUB.getPlotOriginList()
    return _HUB.PlotPositions[_HUB.getHubRank()]
end

---@param plot_id any home, office or any number up to the current rank's plot limit
---@return table a table containing the X and Y coordinates associated to the specified plot id for the current hub rank
function _HUB.getPlotOrigin(plot_id)
    if plot_id == "home" then return _HUB.getPlotOriginList()[1] end
    if plot_id == "office" then return _HUB.getPlotOriginList()[2] end
    return _HUB.getPlotOriginList()[plot_id]
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
---@param building_data number the id of the asset that defines this plot's appearance when it's empty.
---@param pos table a table containing the X and Y coordinates of the plot's origin
function _HUB.DrawBuilding(plot_id, building_data, pos)
    local rank = _HUB.getPlotRank(building_data)
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

--- Initializes the plot database inside the SV structure.
function _HUB.initializePlotData()
    SV.HubData.Plots = SV.HubData.Plots or {}
    for i = 1, 17, 1 do
        local rand = #_HUB.NotUnlockedVisuals.NonBlocking+#_HUB.NotUnlockedVisuals.Blocking
        if i>5 or (i>2 and i<5) then rand = rand end

        local plot_base = {
            unlocked = false,
            building = "",
            upgrades = {},
            shopkeeper = "",
            shopkeeper_shiny = false,
            data = {},
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
            plot_base.upgrades = {{type = "upgrade_generic", count = 1}}
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
    for _, upgrade in pairs(plot.upgrades) do
        lvl = lvl + upgrade.count
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
    --TODO AAAAAAAAAAAAAAAAAAA
    local current = {}
    local list = {}
    local shiny = false
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
            if j~=nil and i~=nil then
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
    if index <= _HUB.getBuildLimit() then
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
            success = _HUB.UpgradeShop(index, start_upgrade)
            if success then
                local npc, shiny = _HUB.DiscardUsed(db.Shopkeepers)
                local _, result = COMMON_FUNC.WeightlessRoll(npc)
                data.shopkeeper = result
                data.shopkeeper_shiny = shiny
            else
                data.building = ""
                data.upgrades = {}
                data.data = {}
            end
        end
    end
    return success
end

--- Builds a new shop in the specified plot
--- @param plot any home, office or any positive integer up to 15
--- @param upgrade string the id of the upgrade that will be applied to this shop
--- @return boolean true if it went well, false if it failed
function _HUB.UpgradeShop(plot, upgrade)
    local data = _HUB.getPlotData(plot)
    if data.unlocked and data.building~="" then
        local rank = _HUB.getPlotRank(data) or 0
        if table.contains(_HUB.ShopBase[data.building].Upgrades[rank+1], upgrade) then
            local found = false
            for _, upgr in pairs(plot.upgrades) do
                if upgr.type == upgrade then
                    upgr.count = upgr.count+1
                    found = true
                end
            end
            if not found then table.insert(plot.upgrades, {type = upgrade, count = 1}) end
            return true
        end
    end
    return false
end

--- Completely removes all shop data in the specified plot
--- @param plot number any positive integer up to 15
function _HUB.RemoveShop(plot)
    SV.HubData.Plots[plot].building = ""
    SV.HubData.Plots[plot].upgrades = {}
    SV.HubData.Plots[plot].shopkeeper = ""
    SV.HubData.Plots[plot].data = {}
end

--- Switches the shop data of two plots. Does nothing if the plot ids are the same.
--- @param plot1 number any positive integer up to 15
--- @param plot2 number any positive integer up to 15
function _HUB.SwapPlots(plot1, plot2)
    if plot1 == plot2 then return end

    local copy = {
        building =   SV.HubData.Plots[plot1].building,
        upgrades =   SV.HubData.Plots[plot1].upgrades,
        shopkeeper = SV.HubData.Plots[plot1].shopkeeper,
        data =       SV.HubData.Plots[plot1].data
    }

    plot1.building =   plot2.building
    plot1.upgrades =   plot2.upgrades
    plot1.shopkeeper = plot2.shopkeeper
    plot1.data =       plot2.data

    plot2.building =   copy.building
    plot2.upgrades =   copy.upgrades
    plot2.shopkeeper = copy.shopkeeper
    plot2.data =       copy.data
end