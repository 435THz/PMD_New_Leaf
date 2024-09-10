--[[
    TownManagerMenu.lua

    Main town management menu.
]]

require 'pmd_new_leaf.menu.TownManagerSummary'
require 'pmd_new_leaf.menu.ScrollListMenu'
require 'origin.menu.DescriptionSummary'

TownManagerMenu = Class("PlotManagerMenu", ScrollListMenu)

--- Creates a new ``PlotManagerMenu`` instance using the provided callback.
function TownManagerMenu:initialize(callback)
    local x = 16
    local y = 16
    local options, return_values = self.LoadOptionsData()
    local selectFunction = function(i) callback(return_values[i]) end
    local width = 64
    local no_expand = false

    ScrollListMenu.initialize(self, x, y, options, selectFunction, width, no_expand)

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

function TownManagerMenu:LoadOptionsData(_)
    local options = {}
    local return_values = {}
    table.insert(options, "TOWN_MANAGER_OPTION_BUILDINGS")
    table.insert(return_values, "buildings")
    if _HUB.getHubRank() >1 then
        table.insert(options, "TOWN_MANAGER_OPTION_RENAME")
        table.insert(return_values, "rename")
    end
    table.insert(options, { "TOWN_MANAGER_OPTION_UPGRADE" })
    table.insert(return_values, "upgrade")
    table.insert(options, "TOWN_MANAGER_OPTION_EXIT")
    table.insert(return_values, "exit")
    return options, return_values
end

function TownManagerMenu:Update(input)
    self.map_summary:UpdateCursor()
    ScrollListMenu.Update(self, input)
end

function TownManagerMenu:updateSelection(change)
    if ScrollListMenu.updateSelection(self, change) then
        self.map_summary:SelectPlot(self.selected)
        return true
    end
    return false
end

function TownManagerMenu:CalcChoiceLength(start)
    local width = ScrollListMenu.CalcChoiceLength(self, start)
    local max_width = 124
    return math.min(width, max_width)
end


function TownManagerMenu:LoadShopDescriptions()
    local descriptions = {}
    for _, plot in self.plots do
        table.insert(descriptions, _SHOP.GetPlotDescription(plot))
    end
    return descriptions
end

function TownManagerMenu:SetDescription()
    local descr = self.descriptions[self.selected]
    if not descr then descr = "Missing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text" end
    self.text_summary:setDescription(descr)
end




function TownManagerMenu.run()
    local ret
    local choose = function(index)
        ret = index
    end
    local menu = PlotManagerMenu:new(choose)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end