--[[
    TownManagerMenu.lua

    Main town management menu.
]]

require 'pmd_new_leaf.menu.office.TownManagerSummary'
require 'pmd_new_leaf.menu.ScrollListMenu'
require 'origin.menu.DescriptionSummary'

TownManagerMenu = Class("TownManagerMenu", ScrollListMenu)

--- Creates a new ``TownManagerMenu`` instance using the provided callback.
function TownManagerMenu:initialize(callback, start)
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
    self.map_summary:SelectTown()

    local summary_x = 16
    local summary_w = Graphics.Manager.ScreenWidth - summary_x*2
    local summary_h = Graphics.Manager.MenuBG.TileHeight*3 + Graphics.LINE_HEIGHT*4 +2
    local summary_y = Graphics.Manager.ScreenHeight - 8 - summary_h
    self.text_summary = DescriptionSummary:new(summary_x, summary_y, summary_x+summary_w, summary_y+summary_h)
    self.menu.SummaryMenus:Add(self.text_summary.window)
    self:SetDescription()
end

function TownManagerMenu:LoadOptionsData(_)
    local options = {}
    local return_values = {}
    local descriptions = {}
    table.insert(options, STRINGS:FormatKey("TOWN_MANAGER_OPTION_BUILDINGS"))
    table.insert(return_values, "buildings")
    table.insert(descriptions, STRINGS:FormatKey("TOWN_MANAGER_DESCR_BUILDINGS", _HUB.getHubSuffix()))
    if _HUB.getHubRank()>1 then
        table.insert(options, STRINGS:FormatKey("TOWN_MANAGER_OPTION_RENAME"))
        table.insert(return_values, "rename")
        if _HUB.getHubRank()>3 then
            table.insert(descriptions, STRINGS:FormatKey("TOWN_MANAGER_DESCR_RENAME_FINAL", _HUB.getHubSuffix()))
        else
            table.insert(descriptions, STRINGS:FormatKey("TOWN_MANAGER_DESCR_RENAME", _HUB.getHubSuffix()))
        end
    end
    if _HUB.getHubLevel()<10 and SV.Intro.ObtainedWishFragments then
        local enabled = _HUB.canUpgrade()
        local descr = STRINGS:FormatKey("TOWN_MANAGER_DESCR_UPGRADE", _HUB.getHubSuffix(), self:makeHubUpgradeReqString())
        local color = Color.White
        if not enabled then
            color = Color.Red
            descr = descr.."\n"..STRINGS:FormatKey("TOWN_MANAGER_DESCR_UPGRADE_LOCKED", _HUB.getHubLevel()+1)
        end
        table.insert(options, { STRINGS:FormatKey("TOWN_MANAGER_OPTION_UPGRADE"), enabled, color })
        table.insert(return_values, "upgrade")
        table.insert(descriptions, descr)
    end
    table.insert(options, STRINGS:FormatKey("TOWN_MANAGER_OPTION_EXIT"))
    table.insert(return_values, "exit")
    table.insert(descriptions, STRINGS:FormatKey("TOWN_MANAGER_DESCR_EXIT"))
    return options, return_values, descriptions
end

function TownManagerMenu:Update(input)
    self.map_summary:UpdateCursor()
    ScrollListMenu.Update(self, input)
end

function TownManagerMenu:updateSelection(change)
    if ScrollListMenu.updateSelection(self, change) then
        self:SetDescription()
        return true
    end
    return false
end

function TownManagerMenu:CalcChoiceLength(start)
    local width = ScrollListMenu.CalcChoiceLength(self, start)
    local max_width = 124
    return math.min(width, max_width)
end

function TownManagerMenu:SetDescription()
    local descr = self.descriptions[self.selected]
    if not descr then descr = "Missing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text\nMissing Description Text" end
    self.text_summary:setDescription(descr)
end

function TownManagerMenu:makeHubUpgradeReqString()
    local next = _HUB.getHubLevel() +1
    local list = _HUB.getLevelUpItems(next)
    local func = function(entry)
        return COMMON_FUNC.PrintItemAmount(entry.item, entry.amount)
    end

    return COMMON_FUNC.BuildStringWithSeparators(list,func)
end






function TownManagerMenu.run(start)
    local ret
    local choose = function(index)
        ret = index
    end
    local menu = TownManagerMenu:new(choose, start)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end