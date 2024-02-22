--[[
    HubManager.lua
    Contains all constant global tables and variables necessary for the Hub to function, plus some functions that interface with them in a more intuitive way.
]]

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

function _HUB.LoadMapData()
    for i, pos in pairs(_HUB.getPlotOriginList()) do
        if i == 1 then _HUB.DrawBuilding("home", _HUB.getPlotData("home"), pos)
        elseif i == 2 then _HUB.DrawBuilding("office", _HUB.getPlotData("office"), pos)
        else
            local shop_data = _HUB.getPlotData(i-2)
            if shop_data.unlocked then
                _HUB.DrawEmpty(i, pos)
            elseif shop_data.building ~= "" then
                _HUB.DrawBuilding(i-2, shop_data, pos)
            end
        end
    end
    GAME:GetCurrentGround().Name = RogueEssence.LocalText(_HUB.getHubName(true))
end

function _HUB.DrawBuilding(plot_id, building_data, pos)
    local elements = _HUB.GenerateShopElements(plot_id, building_data, pos)

    local ground = GAME:GetCurrentGround()
    ground.Decorations[0].Anims:Add(elements.deco_bottom)
    if elements.deco_top then ground.Decorations[1].Anims:Add(elements.deco_top) end
    if elements.npc then ground:AddMapChar() end
    for _, obj in pairs(elements.objects) do
        ground:AddObject(obj)
    end
end

function _HUB.DrawEmpty(plot_id, pos)

end

function _HUB.GenerateShopElements(plot_id, building_data, pos)
    local rank = _HUB.getPlotRank(building_data)
    local graphics_data = _HUB.ShopBase[building_data.building].Graphics[rank]

    local elements = {
        deco_bottom = nil,
        deco_top = nil,
        npc = nil,
        objects = {}
    }
    local bottom = RogueEssence.Content.ObjAnimData(graphics_data.Base, 1)
    local sheet = RogueEssence.Content.GraphicsManager.GetObject(graphics_data.Base) --TODO this might be the solution
    local size_x, size_y = sheet.Width, sheet.Height
    local offset_x, offset_y = 96-size_x, 96-size_y

    elements.deco_bottom = RogueEssence.Ground.GroundAnim(bottom, RogueElements.Loc(pos.X+offset_x, pos.Y+offset_y))

    if graphics_data.TopLayer then
        local top = RogueEssence.Content.ObjAnimData(graphics_data.TopLayer, 1)
        sheet = RogueEssence.Content.GraphicsManager.GetObject(graphics_data.Base) --TODO this might be the solution
        size_x, size_y = sheet.Width, sheet.Height
        offset_x, offset_y = 96-size_x, 96-size_y

        elements.deco_top = RogueEssence.Ground.GroundAnim(top, RogueElements.Loc(pos.X+offset_x, pos.Y+offset_y))
    end

    if graphics_data.NPC_Loc then
        local name = "NPC_"..plot_id
        local x, y = graphics_data.NPC_Loc.X + pos.X, graphics_data.NPC_Loc.Y + pos.Y
        local temp_monster = RogueEssence.Dungeon.MonsterID(building_data.shopkeeper, 0, "normal", Gender.Genderless)
        elements.npc = RogueEssence.Ground.GroundChar(temp_monster, RogueElements.Loc(x, y), Direction.Down, name, building_data.shopkeeper)
        elements.npc:ReloadEvents()
    end

    for _, box in pairs(graphics_data.Bounds) do
        -- Display setup
        local display = box.Display
        local anim_index, frame_time, frame_start, frame_end = "", 1, -1, -1
        if display and display.Sprite then
            anim_index = display.Sprite
            if display.FrameLength then frame_time = display.FrameLength end
            if display.Start then frame_start = display.Start end
            if display.End then frame_end = display.End end
        end
        local anim = RogueEssence.Content.ObjAnimData(anim_index, frame_time, frame_start, frame_end)

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
        obj:ReloadEvents()
        table.insert(elements.objects, obj)
    end
    return elements
end
-------------------------------------------
---region Scripting
-------------------------------------------

function _HUB.ShowTitle()
    GAME:FadeOut(false, 1)
    UI:WaitShowTitle(_HUB.getHubName(true), 30)
    GAME:WaitFrames(60)
    UI:WaitHideTitle(30)
    GAME:FadeIn(20)
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
-------------------------------------------
--region SV Interface
-------------------------------------------

function _HUB.initializePlotData()
    SV.HubData.Plots = SV.HubData.Plots or {}
    for i = 1, 17, 1 do
        if i<16 then
            if not SV.HubData.Plots[i] then
                local plot_base = {
                    unlocked = i<_HUB.LevelBuildLimit[1],
                    building = "",
                    upgrades = {},
                    shopkeeper = "",
                    data = {}
                }
                table.insert(SV.HubData.Plots, plot_base)
            end
        elseif i<17 then
            -- generate home structure
            if not SV.HubData.Home then
                SV.HubData.Home = {
                    unlocked = true,
                    building = "home",
                    upgrades = {{type = "upgrade_generic", count = 1}},
                    shopkeeper = "",
                    data = {}
                }
            end
        elseif not SV.HubData.Office then
            SV.HubData.Office = {
                unlocked = true,
                building = "office",
                upgrades = {{type = "upgrade_generic", count = 1}},
                shopkeeper = "",
                data = {}
            }
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