--[[
    ShopUpgradeMenu.lua

    Menu used to choose an upgrade for a shop.
]]

require 'pmd_new_leaf.menu.office.TownManagerSummary'
require 'pmd_new_leaf.menu.ScrollListMenu'
require 'origin.menu.DescriptionSummary'

ShopUpgradeMenu = Class("ShopUpgradeMenu", ScrollListMenu)

--- Creates a new ``ShopUpgradeMenu`` instance using the provided data and callback.
function ShopUpgradeMenu:initialize(tree, keys, index, callback, start)
    local x = 16
    local y = 16
    local options, return_values, descriptions = self:LoadOptionsData(tree, keys, index)
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

function ShopUpgradeMenu:LoadOptionsData(tree, keys, index)
    local plot = _HUB.getPlotData(index)

    local options = {}
    local return_values = {}
    local descriptions = {}
    for _, upgrade in ipairs(keys) do
        local data = tree[upgrade]
        local upgrade_data = _HUB.UpgradeTable[upgrade]
        table.insert(options, STRINGS:FormatKey(upgrade_data.string))
        table.insert(return_values, upgrade)

        local descr = STRINGS:FormatKey(upgrade_data.description)
        if data.has_sub then
            descr = descr..STRINGS:FormatKey("PLOT_DESCRIPTION_UPGRADE_MULTI_CHOICE")
        else
            local lv = plot.upgrades[upgrade] or 0
            local cost = _SHOP.GetUpgradeCost(upgrade, lv+1)
            local func = function(entry) return COMMON_FUNC.PrintItemAmount(entry.item, entry.amount) end
            descr = descr..STRINGS:FormatKey("PLOT_DESCRIPTION_UPGRADE_COST", COMMON_FUNC.BuildStringWithSeparators(cost, func))
        end
        table.insert(descriptions, descr)
    end
    table.insert(options, STRINGS:FormatKey("TOWN_MANAGER_OPTION_EXIT"))
    table.insert(return_values, "exit")
    table.insert(descriptions, STRINGS:FormatKey("TOWN_MANAGER_DESCR_EXIT"))
    return options, return_values, descriptions
end

function ShopUpgradeMenu:Update(input)
    self.map_summary:UpdateCursor()
    ScrollListMenu.Update(self, input)
end

function ShopUpgradeMenu:updateSelection(change)
    if ScrollListMenu.updateSelection(self, change) then
        self.map_summary:RefreshCursor()
        self:SetDescription()
        return true
    end
    return false
end

function ShopUpgradeMenu:CalcChoiceLength(start)
    local width = ScrollListMenu.CalcChoiceLength(self, start)
    local max_width = 124
    return math.min(width, max_width)
end

function ShopUpgradeMenu:SetDescription()
    local descr = self.descriptions[self.selected]
    if not descr then descr = "Missing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text" end
    self.text_summary:setDescription(descr)
end




function ShopUpgradeMenu.run(tree, keys, index, start)
    local ret
    local choose = function(i)
        ret = i
    end
    local menu = ShopUpgradeMenu:new(tree, keys, index, choose, start)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret, menu.selected
end