--[[
    PlotBuildMenu.lua

    Menu used to choose a shop to build.
]]

require 'pmd_new_leaf.menu.office.TownManagerSummary'
require 'pmd_new_leaf.menu.ScrollListMenu'
require 'origin.menu.DescriptionSummary'

PlotBuildMenu = Class("PlotBuildMenu", ScrollListMenu)

--- Creates a new ``PlotBuildMenu`` instance using the provided data and callback.
function PlotBuildMenu:initialize(index, callback, start)
    local x = 16
    local y = 16
    local options, return_values, descriptions = self:LoadOptionsData()
    self.cb = callback
    self.descriptions = descriptions
    self.return_values = return_values
    local width = 64
    local no_expand = false

    self.selectFunction = function(i)
        return self.cb(self.return_values[i] or "exit")
    end

    ScrollListMenu.initialize(self, x, y, options, self.selectFunction, start, width, no_expand)

    self.map_summary = TownManagerSummary:new()
    self.menu.SummaryMenus:Add(self.map_summary.window)
    self.map_summary:SelectPlot(index, true)

    local summary_x = 16
    local summary_w = Graphics.Manager.ScreenWidth - summary_x*2
    local summary_h = Graphics.Manager.MenuBG.TileHeight*3 + Graphics.LINE_HEIGHT*4 +2
    local summary_y = Graphics.Manager.ScreenHeight - 8 - summary_h
    self.text_summary = DescriptionSummary:new(summary_x, summary_y, summary_x+summary_w, summary_y+summary_h)
    self.menu.SummaryMenus:Add(self.text_summary.window)
    self:SetDescription()
end

function PlotBuildMenu:LoadOptionsData(_)
    local options = {}
    local return_values = {}
    local descriptions = {}
    for _, shop_id in ipairs(_SHOP.Order) do
        if shop_id ~= "home" and shop_id ~= "office" then
            local base = _HUB.ShopBase[shop_id]
            local multi = false
            local upgrades = base.Upgrades[1]
            if #upgrades>1 or _HUB.UpgradeTable[upgrades[1]].sub_choices then
                multi = true
            end
            local name = STRINGS:FormatKey("SHOP_OPTION_"..string.upper(shop_id))
            table.insert(options, name)
            table.insert(return_values, shop_id)

            local descr = STRINGS:FormatKey("PLOT_DESCRIPTION_BUILD_"..string.upper(shop_id))
            if multi then
                descr = descr..STRINGS:FormatKey("PLOT_DESCRIPTION_BUILD_MULTI_CHOICE")
            else
                local cost = _SHOP.GetUpgradeCost(upgrades[1], 1)
                local func = function(entry) return COMMON_FUNC.PrintItemAmount(entry.item, entry.amount) end
                descr = descr..STRINGS:FormatKey("PLOT_DESCRIPTION_BUILD_COST", COMMON_FUNC.BuildStringWithSeparators(cost, func))
            end
            table.insert(descriptions, descr)
        end
    end
    table.insert(options, STRINGS:FormatKey("TOWN_MANAGER_OPTION_EXIT"))
    table.insert(return_values, "exit")
    table.insert(descriptions, STRINGS:FormatKey("TOWN_MANAGER_DESCR_EXIT"))
    return options, return_values, descriptions
end

function PlotBuildMenu:Update(input)
    self.map_summary:UpdateCursor()
    ScrollListMenu.Update(self, input)
end

function PlotBuildMenu:updateSelection(change)
    if ScrollListMenu.updateSelection(self, change) then
        self.map_summary:RefreshCursor()
        self:SetDescription()
        return true
    end
    return false
end

function PlotBuildMenu:CalcChoiceLength(start)
    local width = ScrollListMenu.CalcChoiceLength(self, start)
    local max_width = 124
    return math.min(width, max_width)
end

function PlotBuildMenu:SetDescription()
    local descr = self.descriptions[self.selected]
    if not descr then descr = "Missing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text" end
    self.text_summary:setDescription(descr)
end




function PlotBuildMenu.run(index, start)
    local ret
    local choose = function(i)
        ret = i
    end
    local menu = PlotBuildMenu:new(index, choose, start)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret, menu.selected
end