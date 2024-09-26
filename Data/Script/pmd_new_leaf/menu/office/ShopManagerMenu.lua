--[[
    ShopManagerMenu.lua

    Main town management menu.
]]

require 'pmd_new_leaf.menu.office.TownManagerSummary'
require 'pmd_new_leaf.menu.ScrollListMenu'
require 'origin.menu.DescriptionSummary'

ShopManagerMenu = Class("ShopManagerMenu", ScrollListMenu)

--- Creates a new ``ShopManagerMenu`` instance using the provided callback.
function ShopManagerMenu:initialize(index, callback)
    local x = 16
    local y = 16
    local options, return_values, descriptions = self:LoadOptionsData(index)
    self.cb = callback
    self.descriptions = descriptions
    self.return_values = return_values
    local width = 64
    local no_expand = false

    self.selectFunction = function(i)
        return self.cb(self.return_values[i] or "exit")
    end
    ScrollListMenu.initialize(self, x, y, options, self.selectFunction, width, no_expand)

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

function ShopManagerMenu:LoadOptionsData(index)
    local plot = _HUB.getPlotData(index)
    local level = _HUB.getPlotLevel(plot)
    local options = {}
    local return_values = {}
    local descriptions = {}
    if level < 10 then
        local base = _HUB.ShopBase[plot.building]
        local multi = false
        local upgrades = base.Upgrades[1]
        if #upgrades>1 or _HUB.UpgradeTable[upgrades[1]].sub_choices then
            multi = true
        end

        local descr = STRINGS:FormatKey("SHOP_MANAGER_DESCR_UPGRADE", level)
        if multi then
            descr = descr..STRINGS:FormatKey("SHOP_MANAGER_DESCR_UPGRADE_MULTI")
        else
            local lv = plot.upgrades[upgrades[1]] or 0
            local cost = _SHOP.GetUpgradeCost(upgrades[1], lv+1)
            local func = function(entry) return COMMON_FUNC.PrintItemAmount(entry.item, entry.amount) end
            descr = descr..STRINGS:FormatKey("SHOP_MANAGER_DESCR_UPGRADE_COST", COMMON_FUNC.BuildStringWithSeparators(cost, func))
        end

        local enabled = _HUB.getPlotRank(plot) <= _HUB.getHubRank()
        local color = Color.White
        if not enabled then
            color = Color.Red
            descr = descr..STRINGS:FormatKey("SHOP_MANAGER_DESCR_UPGRADE_LOCKED", _HUB.getHubSuffix())
        end

        table.insert(options, { STRINGS:FormatKey("SHOP_MANAGER_OPTION_UPGRADE"), enabled, color })
        table.insert(return_values, "upgrade")
        table.insert(descriptions, descr)
    end

    table.insert(options, STRINGS:FormatKey("SHOP_MANAGER_OPTION_MOVE"))
    table.insert(return_values, "move")
    table.insert(descriptions, STRINGS:FormatKey("SHOP_MANAGER_DESCR_MOVE"))

    table.insert(options, STRINGS:FormatKey("SHOP_MANAGER_OPTION_DEMOLISH"))
    table.insert(return_values, "demolish")
    table.insert(descriptions, STRINGS:FormatKey("SHOP_MANAGER_DESCR_DEMOLISH"))

    table.insert(options, STRINGS:FormatKey("TOWN_MANAGER_OPTION_EXIT"))
    table.insert(return_values, "exit")
    table.insert(descriptions, STRINGS:FormatKey("TOWN_MANAGER_DESCR_EXIT"))
    return options, return_values, descriptions
end

function ShopManagerMenu:Update(input)
    self.map_summary:UpdateCursor()
    ScrollListMenu.Update(self, input)
end

function ShopManagerMenu:updateSelection(change)
    if ScrollListMenu.updateSelection(self, change) then
        self.map_summary:RefreshCursor()
        self:SetDescription()
        return true
    end
    return false
end

function ShopManagerMenu:CalcChoiceLength(start)
    local width = ScrollListMenu.CalcChoiceLength(self, start)
    local max_width = 124
    return math.min(width, max_width)
end

function ShopManagerMenu:SetDescription()
    local descr = self.descriptions[self.selected]
    if not descr then descr = "Missing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text" end
    self.text_summary:setDescription(descr)
end

function ShopManagerMenu:makeHubUpgradeReqString()
    local next = _HUB.getHubLevel() +1
    local list = _HUB.getLevelUpItems(next)
    local func = function(entry)
        return COMMON_FUNC.PrintItemAmount(entry.item, entry.amount)
    end

    return COMMON_FUNC.BuildStringWithSeparators(list,func)
end






function ShopManagerMenu.run(plot_id)
    local ret
    local choose = function(index)
        ret = index
    end
    local menu = ShopManagerMenu:new(plot_id, choose)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end