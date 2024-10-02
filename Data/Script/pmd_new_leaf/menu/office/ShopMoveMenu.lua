--[[
    ShopMoveMenu.lua

    Menu used to choose a shop to manage.
]]

require 'pmd_new_leaf.menu.office.TownManagerSummary'
require 'pmd_new_leaf.menu.ScrollListMenu'
require 'origin.menu.DescriptionSummary'

ShopMoveMenu = Class("ShopMoveMenu", ScrollListMenu)

--- Creates a new ``ShopMoveMenu`` instance using the provided callback.
function ShopMoveMenu:initialize(start, callback)
    local x = 16
    local y = 16
    self.start_plot = start
    self.plots = SV.HubData.Plots
    self.descriptions = self:LoadShopDescriptions()
    local width = 64
    local no_expand = false

    ScrollListMenu.initialize(self, x, y, nil, callback, self.start_plot, width, no_expand)

    self.map_summary = TownManagerSummary:new()
    self.menu.SummaryMenus:Add(self.map_summary.window)
    self.map_summary:SelectPlot(self.selected, true)
    self.map_summary:SetSilverCursorToPlot(self.start_plot)

    local summary_x = 16
    local summary_w = Graphics.Manager.ScreenWidth - summary_x*2
    local summary_h = Graphics.Manager.MenuBG.TileHeight*3 + Graphics.LINE_HEIGHT*4 +2
    local summary_y = Graphics.Manager.ScreenHeight - 8 - summary_h
    self.text_summary = DescriptionSummary:new(summary_x, summary_y, summary_x+summary_w, summary_y+summary_h)
    self.menu.SummaryMenus:Add(self.text_summary.window)
    self:SetDescription()
end

function ShopMoveMenu:LoadOptions()
    local choices = {}
    local plotNumber = _HUB.getRankPlotNumber()
    local buildLimit = _HUB.getBuildLimit()
    for i = 1, plotNumber, 1 do
        local plot = self.plots[i]
        local text = STRINGS:FormatKey("SHOP_OPTION_EMPTY")
        local enabled = i <= buildLimit
        local color = Color.White
        if not enabled then
            text = STRINGS:FormatKey("SHOP_OPTION_OUT_OF_LIMIT")
            color = Color.Red
        elseif not plot.unlocked then
            text = STRINGS:FormatKey("SHOP_OPTION_LOCKED")
            color = Color.Gray
            enabled = false
        elseif plot.building ~= "" then
            text = STRINGS:FormatKey("SHOP_OPTION_"..string.upper(plot.building))
            if i == self.start_plot then color = Color.Yellow end
        end
        local choice = RogueEssence.Menu.MenuTextChoice(text, function() self.callback(i) end, enabled, color)
        table.insert(choices, choice)
    end
    return choices
end

function ShopMoveMenu:Update(input)
    self.map_summary:UpdateCursor()
    ScrollListMenu.Update(self, input)
end

function ShopMoveMenu:updateSelection(change)
    if ScrollListMenu.updateSelection(self, change) then
        self.map_summary:SelectPlot(self.selected)
        self:SetDescription()
        return true
    end
    return false
end

function ShopMoveMenu:CalcChoiceLength(start)
    local width = ScrollListMenu.CalcChoiceLength(self, start)
    local max_width = 124
    return math.min(width, max_width)
end

function ShopMoveMenu:LoadShopDescriptions()
    local source = self.plots[self.start_plot]
    local source_name = STRINGS:FormatKey("SHOP_NAME_"..string.upper(source.building), _DATA:GetMonster(source.shopkeeper.species):GetColoredName())

    local descriptions = {}
    for i, plot in pairs(self.plots) do
        if i == self.start_plot then
            table.insert(descriptions, STRINGS:FormatKey("PLOT_DESCRIPTION_MOVE_SOURCE", source_name))
        elseif plot.building ~= "" then
            local dest_name = STRINGS:FormatKey("SHOP_NAME_"..string.upper(plot.building), _DATA:GetMonster(plot.shopkeeper.species):GetColoredName())
            table.insert(descriptions, STRINGS:FormatKey("PLOT_DESCRIPTION_MOVE_SWAP", source_name, dest_name))
        elseif plot.unlocked then
            table.insert(descriptions, STRINGS:FormatKey("PLOT_DESCRIPTION_MOVE", source_name))
        else
            table.insert(descriptions, STRINGS:FormatKey("PLOT_DESCRIPTION_MOVE_CANNOT"))
        end
    end
    return descriptions
end

function ShopMoveMenu:SetDescription()
    local descr = self.descriptions[self.selected]
    if not descr then descr = "Missing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text" end
    self.text_summary:setDescription(descr)
end




function ShopMoveMenu.run(start)
    local ret
    local choose = function(index)
        ret = index
        if index<0 then ret = start end
    end
    local menu = ShopMoveMenu:new(start, choose)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end