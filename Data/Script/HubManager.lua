--[[
    HubManager.lua
    Contains all constant global tables and variables necessary for the Hub to function, plus some functions that interface with them in a more intuitive way.
]]

function printall(table, level, root)
    if root == nil then print(" ") end

    if table == nil then print("<nil>") return end
    if level == nil then level = 0 end
    for key, value in pairs(table) do
        local spacing = ""
        for _=1, level*2, 1 do
            spacing = " "..spacing
        end
        if type(value) == 'table' then
            print(spacing..tostring(key).." = {")
            printall(value,level+1, false)
            print(spacing.."}")
        else
            print(spacing..tostring(key).." = "..tostring(value))
        end
    end

    if root == nil then print(" ") end
end

_HUB = _HUB or {}

require 'ShopManager'

_HUB.LevelRankTable = {1,1,2,2,2,3,3,3,4,4}
_HUB.RankSuffix = {"Camp", "Village", "Town", "City"}
_HUB.RankHubMap = {"hub_small", "hub_medium", "hub_large", "hub_final"}
_HUB.LevelBuildLimit = {2,3,4,5,6,7,8,10,12,15}
_HUB.LevelAssemblyLimit = {10,25,40,60,80,100,150,200,300,500}
_HUB.BoardUnlockLevel = 3
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

function _HUB.getHubRank()
    return _HUB.LevelRankTable[SV.HubData.Level]
end

function _HUB.getHubSuffix()
    return _HUB.RankSuffix[_HUB.getHubRank()]
end

function _HUB.getHubMap()
    return _HUB.RankHubMap[_HUB.getHubRank()]
end

function _HUB.getBuildLimit()
    return _HUB.LevelBuildLimit[_HUB.getHubRank()]
end

function _HUB.getAssemblyLimit()
    return _HUB.LevelAssemblyLimit[_HUB.getHubRank()]
end

function _HUB.boardUnlocked()
    return _HUB.getHubRank() >= _HUB.BoardUnlockLevel
end

function _HUB.getHubName(colorless)
    local ret = SV.HubData.Name
    if SV.HubData.UseSuffix then ret = ret.." ".._HUB.getHubSuffix() end
    if colorless then return ret end
    return "[color=#FFFFA5]"..ret.."[color]"
end

function _HUB.getPlotOriginList()
    return _HUB.PlotPositions[_HUB.getHubRank()]
end

function _HUB.getPlotOrigin(plot_id)
    if plot_id == "home" then return _HUB.getPlotOriginList()[1] end
    if plot_id == "office" then return _HUB.getPlotOriginList()[2] end
    return _HUB.getPlotOriginList()[plot_id]
end

-------------------------------------------
--region Graphics
-------------------------------------------

function _HUB.LoadMapEmpty()
    for i, pos in pairs(_HUB.getPlotOriginList()) do
        if     i == 1 then _HUB.DrawEmpty("home",   _HUB.getPlotData("home").empty,   pos)
        elseif i == 2 then _HUB.DrawEmpty("office", _HUB.getPlotData("office").empty, pos)
        else               _HUB.DrawEmpty(i-2,      _HUB.getPlotData(i-2).empty,      pos)
        end
    end
    GAME:GetCurrentGround().Name = RogueEssence.LocalText(_HUB.getHubName(true))
end

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

function _HUB.DrawBuilding(plot_id, building_data, pos)
    local rank = _HUB.getPlotRank(building_data)
    local graphics_data = _HUB.ShopBase[building_data.building].Graphics[rank]

    local deco_bottom = _HUB.GenerateDecoLayer(graphics_data.Base, pos)
    local objects = _HUB.GenerateObjectList(plot_id, graphics_data, pos)
    local sub_decos = _HUB.GenerateSubDecorationList(graphics_data, pos)
    local deco_top
    local npc
    if graphics_data.TopLayer then deco_top = _HUB.GenerateDecoLayer(graphics_data.TopLayer, pos) end
    if graphics_data.NPC_Loc then  npc =      _HUB.GenerateNPC(plot_id, building_data.shopkeeper, graphics_data.NPC_Loc, pos) end

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

function _HUB.GenerateDecoLayer(deco, pos)
    local object = RogueEssence.Content.ObjAnimData(deco, 1)
    local sheet = RogueEssence.Content.GraphicsManager.GetObject(deco)
    local size_x, size_y = sheet.Width, sheet.Height
    local offset_x, offset_y = (96-size_x)//2, (96-size_y)//2
    return RogueEssence.Ground.GroundAnim(object, RogueElements.Loc(pos.X+offset_x, pos.Y+offset_y))
end

function _HUB.GenerateNPC(plot_id, shopkeeper, NPC_Loc, pos)
    local nickname = _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Monster]:Get(shopkeeper).Name:ToLocal()
    local name = "NPC_"..plot_id
    local x, y = NPC_Loc.X + pos.X, NPC_Loc.Y + pos.Y
    local temp_monster = RogueEssence.Dungeon.MonsterID(shopkeeper, 0, "normal", Gender.Genderless)
    local npc = RogueEssence.Ground.GroundChar(temp_monster, RogueElements.Loc(x, y), Direction.Down, nickname, name)
    npc:ReloadEvents()
    return npc
end

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

function _HUB.ShowTitle(no_fade)
    GAME:FadeOut(false, 1)
    UI:WaitShowTitle(_HUB.getHubName(true), 30)
    GAME:WaitFrames(60)
    UI:WaitHideTitle(30)
    if not no_fade then GAME:FadeIn(20) end
end

function _HUB.SetMarker(x, y)
    SV.HubData.Marker = {X = x, Y = y}
end

function _HUB.TeleportToMarker()
    local marker = SV.HubData.Marker
    if marker then
        GROUND:TeleportTo(CH("PLAYER"), marker.X, marker.Y, Direction.Down)
        SV.HubData.Marker = nil
    end
end

function _HUB.WakeUpHome()
    SV.HubData.RunEnded = true
    local index = _HUB.getPlotRank(_HUB.getPlotData("home"))
    GAME:EnterGroundMap("hub_zone", "home_tier"..index, "Bed")
end

-------------------------------------------
--region SV Interface
-------------------------------------------

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

function _HUB.getPlotData(index)
    if index == "home"   then return SV.HubData.Home   end
    if index == "office" then return SV.HubData.Office end
    return SV.HubData.Plots[index]
end

function _HUB.getPlotLevel(plot)
    local lvl = 0
    for _, upgrade in pairs(plot.upgrades) do
        lvl = lvl + upgrade.count
    end
    return lvl
end

function _HUB.getPlotRank(plot)
    local lvl = _HUB.getPlotLevel(plot)
    return _HUB.LevelRankTable[lvl]
end