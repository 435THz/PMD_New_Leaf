--[[
    ShopSubUpgradeMenu.lua

    Menu used to choose an upgrade for a shop.
]]

require 'pmd_new_leaf.menu.office.TownManagerSummary'
require 'pmd_new_leaf.menu.ScrollListMenu'
require 'origin.menu.DescriptionSummary'

ShopSubUpgradeMenu = Class("ShopSubUpgradeMenu", ScrollListMenu)

--- Creates a new ``ShopSubUpgradeMenu`` instance using the provided data and callback.
function ShopSubUpgradeMenu:initialize(tree, upgrade, index, callback)
    local x = 16
    local y = 16
    local options, return_values, descriptions = self:LoadOptionsData(tree, upgrade, index)
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

function ShopSubUpgradeMenu:LoadOptionsData(tree, upgrade, index)
    local plot = _HUB.getPlotData(index)
    local branch = tree[upgrade]
    local upgrade_data = _HUB.UpgradeTable[upgrade]

    local options = {}
    local return_values = {}
    local descriptions = {}
    for _, sub in ipairs(branch.sub) do
        local sub_data = _HUB.UpgradeTable[sub]
        local formatted = STRINGS:Format("{0}_{1}", upgrade, sub)

        table.insert(options, STRINGS:FormatKey(sub_data.string))
        table.insert(return_values, sub)

        local descr = STRINGS:FormatKey(sub_data.description, STRINGS:FormatKey(upgrade_data.sub_description))
        local lv = plot.upgrades[formatted] or 0
        local cost = _SHOP.GetFullUpgradeCost(upgrade, sub, lv+1)
        local func = function(entry) return COMMON_FUNC.PrintItemAmount(entry.item, entry.amount) end
        descr = descr..STRINGS:FormatKey("PLOT_DESCRIPTION_UPGRADE_COST", COMMON_FUNC.BuildStringWithSeparators(cost, func))
        table.insert(descriptions, descr)
    end
    table.insert(options, STRINGS:FormatKey("TOWN_MANAGER_OPTION_EXIT"))
    table.insert(return_values, "exit")
    table.insert(descriptions, STRINGS:FormatKey("TOWN_MANAGER_DESCR_EXIT"))
    return options, return_values, descriptions
end

function ShopSubUpgradeMenu:Update(input)
    self.map_summary:UpdateCursor()
    ScrollListMenu.Update(self, input)
end

function ShopSubUpgradeMenu:updateSelection(change)
    if ScrollListMenu.updateSelection(self, change) then
        self.map_summary:RefreshCursor()
        self:SetDescription()
        return true
    end
    return false
end

function ShopSubUpgradeMenu:CalcChoiceLength(start)
    local width = ScrollListMenu.CalcChoiceLength(self, start)
    local max_width = 124
    return math.min(width, max_width)
end

function ShopSubUpgradeMenu:SetDescription()
    local descr = self.descriptions[self.selected]
    if not descr then descr = "Missing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text" end
    self.text_summary:setDescription(descr)
end




function ShopSubUpgradeMenu.run(tree, upgrade, index)
    local ret
    local choose = function(i)
        ret = i
    end
    local menu = ShopSubUpgradeMenu:new(tree, upgrade, index, choose)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end