--[[
    PlotManagerMenu.lua

    Menu used to choose a shop to manage.
]]

require 'pmd_new_leaf.menu.TownManagerSummary'
require 'pmd_new_leaf.menu.ScrollListMenu'
require 'origin.menu.DescriptionSummary'

PlotManagerMenu = Class("PlotManagerMenu", ScrollListMenu)

--- Creates a new ``PlotManagerMenu`` instance using the provided callback.
function PlotManagerMenu:initialize(callback)
    local x = 16
    local y = 16
    self.plots = SV.HubData.Plots
    self.descriptions = self:LoadShopDescriptions()
    local width = 64
    local no_expand = false

    ScrollListMenu.initialize(self, x, y, nil, callback, width, no_expand)

    self.map_summary = TownManagerSummary:new()
    self.menu.SummaryMenus:Add(self.map_summary.window)
    self.map_summary:SelectPlot(self.selected, true)

    local summary_x = 16
    local summary_w = Graphics.Manager.ScreenWidth - summary_x*2
    local summary_h = Graphics.Manager.MenuBG.TileHeight*3 + Graphics.LINE_HEIGHT*4
    local summary_y = Graphics.Manager.ScreenHeight - 8 - summary_h
    self.text_summary = DescriptionSummary:new(summary_x, summary_y, summary_x+summary_w, summary_y+summary_h)
    self.menu.SummaryMenus:Add(self.text_summary.window)
    self:SetDescription()
end

function PlotManagerMenu:LoadOptions(_)
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
            color = Color.LightGray
        elseif plot.building ~= "" then
            text = STRINGS:FormatKey("SHOP_OPTION_"..string.upper(plot.building))
        end
        local choice = RogueEssence.Menu.MenuTextChoice(text, function() self.callback(i) end, enabled, color)
        table.insert(choices, choice)
    end
    return choices
end

function PlotManagerMenu:Update(input)
    self.map_summary:UpdateCursor()
    ScrollListMenu.Update(self, input)
end

function PlotManagerMenu:updateSelection(change)
    if ScrollListMenu.updateSelection(self, change) then
        self.map_summary:SelectPlot(self.selected)
        self:SetDescription()
        return true
    end
    return false
end

function PlotManagerMenu:CalcChoiceLength(start)
    local width = ScrollListMenu.CalcChoiceLength(self, start)
    local max_width = 124
    return math.min(width, max_width)
end


function PlotManagerMenu:LoadShopDescriptions()
    local descriptions = {}
    for _, plot in pairs(self.plots) do
        table.insert(descriptions, _SHOP.GetPlotDescription(plot))
    end
    return descriptions
end

function PlotManagerMenu:SetDescription()
    local descr = self.descriptions[self.selected]
    if not descr then descr = "Missing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text" end
    self.text_summary:setDescription(descr)
end




function PlotManagerMenu.run()
    local ret
    local choose = function(index)
        ret = index
    end
    local menu = PlotManagerMenu:new(choose)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end