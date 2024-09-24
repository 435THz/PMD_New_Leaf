--[[
    Exporter.lua

    Allows the player to sell items, albeit over time.
    This file contains all exporter-specific callbacks and functionality data structures
]]
require 'pmd_new_leaf.menu.ExporterMenu'
require 'pmd_new_leaf.menu.InventorySelectMenu'

_SHOP.ExporterTables = {
    -- level  1  2  3  4  5   6   7   8   9  10
    slots  = {4, 6, 6, 8, 8, 10, 12, 12, 14, 16},
    checks = {3, 3, 4, 4, 5,  5,  6,  7,  7,  8}
}

function _SHOP.ExporterInitializer(plot)
    plot.data = {
        stock = {
            --{item = InvItem, state = int, sell_at = int}
        },
        earnings = 0,
        sold = 0,
        slots = 0,
        checks = 0,
        reduce_all = false,
        store_earnings = false,
        instant_sell = false
    }
end

function _SHOP.ExporterUpgradeFlow(plot, _, _)
    local level = _HUB.getPlotLevel(plot)
    local upgrade = "upgrade_exporter_base"
    local curr = plot.upgrades[upgrade] or 0
    local cost = _SHOP.GetUpgradeCost(upgrade, curr+1)
    if COMMON_FUNC.CheckCost(cost, true) then
        local func = function(entry) return COMMON_FUNC.PrintItemAmount(entry.item, entry.amount) end
        local cost_string = COMMON_FUNC.BuildStringWithSeparators(cost, func)
        if level == 0 then UI:ChoiceMenuYesNo(STRINGS:FormatKey("OFFICE_BUILD_ASK", STRINGS:FormatKey("SHOP_OPTION_EXPORTER"), cost_string))
        else UI:ChoiceMenuYesNo(STRINGS:FormatKey("OFFICE_UPGRADE_ASK", STRINGS:FormatKey("SHOP_OPTION_EXPORTER"), cost_string)) end
        UI:WaitForChoice()
        local ch = UI:ChoiceResult()
        if ch then
            COMMON_FUNC.RemoveItems(cost, true)
            UI:ResetSpeaker(false)
            SOUND:PlaySE("Fanfare/Item")
            UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_GIVE_ITEM", cost_string))
            return upgrade
        end
    else
        if level == 0 then UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_CANNOT_BUILD"))
        else UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_CANNOT_UPGRADE")) end
    end
end

function _SHOP.ExporterUpgrade(plot, upgrade)
    if upgrade ~= "upgrade_exporter_base" then return end

    local level = _HUB.getPlotLevel(plot)
    if level<10 then
        _SHOP.ConfirmShopUpgrade(plot, upgrade)
        level = _HUB.getPlotLevel(plot)
    else return end

    plot.data.slots =  _SHOP.ExporterTables.slots[level]
    plot.data.checks = _SHOP.ExporterTables.checks[level]

    if level == 5 then
        plot.data.reduce_all = true
    elseif level == o then
        plot.data.store_earnings = true
    elseif level == 10 then
        plot.data.instant_sell = true
    end
end

function _SHOP.ExporterUpdate(plot)
    local stock = plot.data.stock
    local new_earnings = 0

    if plot.data.instant_sell and math.random(1,4) == 1 then
        local eligible = {}
        for i, item in stock do
            local checks_left = item.sell_at - item.state
            if checks_left < 7 then
                table.insert(eligible, {Index = i, Weight =  7 - checks_left})
            end
        end
        if #eligible > 0 then
            local sold = COMMON_FUNC.WeightedRoll(eligible)
            new_earnings = new_earnings + stock[sold.Index].item:GetSellValue()
            plot.data.sold = plot.data.sold + 1
            table.remove(stock, sold.Index)
        end
    end

    for _ = 1, plot.data.checks, 1 do
        if #stock == 0 then break end
        local entry, index = COMMON_FUNC.WeightlessRoll(stock)
        if entry.state < entry.sell_at-1 then
            entry.state = entry.state+1
        else
            new_earnings = new_earnings + entry.item:GetSellValue()
            plot.data.sold = plot.data.sold + 1
            table.remove(stock, index)
        end
    end

    if plot.data.store_earnings then
        GAME:AddToPlayerMoneyBank(new_earnings)
    else
        plot.data.earnings = plot.data.earnings + new_earnings
    end
end

function _SHOP.ExporterInteract(plot, index)
    local npc = CH("NPC_"..index)
    UI:SetSpeaker(npc)
    local msg = STRINGS:FormatKey('EXPORTER_INTRO', npc:GetDisplayName())
    local exit = false
    while not exit do
        local choices = {STRINGS:FormatKey('EXPORTER_OPTION_MANAGE'),
                         STRINGS:FormatKey('EXPORTER_OPTION_EARNINGS'),
                         STRINGS:FormatKey("MENU_INFO"),
                         STRINGS:FormatKey("MENU_EXIT")}
        UI:BeginChoiceMenu(msg, choices, 1, 4)
        UI:WaitForChoice()

        msg = STRINGS:FormatKey('EXPORTER_REPEAT')

        local result = UI:ChoiceResult()
        if result == 1 then
            local loop = true
            while loop do
                local choice = ExporterMenu.run(plot.data)
                if not choice then
                    loop = false
                elseif choice > 0 then
                    local entry = plot.data.stock[choice]
                    UI:ChoiceMenuYesNo(STRINGS:FormatKey('EXPORTER_CONFIRM_TAKE', entry.item:GetDisplayName()), false)
                    UI:WaitForChoice()
                    if UI:ChoiceResult() then
                        UI:ResetSpeaker(false)
                        UI:SetCenter(true)
                        SOUND:PlaySE("Fanfare/Item")
                        UI:WaitShowDialogue(STRINGS:FormatKey('RECEIVE_ITEM_MESSAGE', entry.item:GetDisplayName()))
                        GAME:GivePlayerItem(entry.item)
                        table.remove(plot.data.stock, choice)
                        UI:SetCenter(false)
                        UI:SetSpeaker(npc)
                    end
                else
                    UI:WaitShowDialogue(STRINGS:FormatKey('EXPORTER_DEPOSIT'))
                    while loop do
                        local filter = function(slot)
                            local item
                            if slot.IsEquipped then item = _DATA.Save.ActiveTeam.Players[slot.Slot].EquippedItem
                            else item = _DATA.Save.ActiveTeam:GetInv(slot.Slot) end
                            return item:GetSellValue() > 0
                        end
                        local items = InventorySelectMenu.run(STRINGS:FormatKey('MENU_ITEM_TITLE'), filter, STRINGS:FormatKey('MENU_ITEM_GIVE'), true, plot.data.slots - #plot.data.stock)
                        if #items > 0 then
                            if #items > 1 then
                                UI:WaitShowDialogue(STRINGS:FormatKey('EXPORTER_CONFIRM_GIVE_MANY'))
                                _SHOP.ExporterAddToStock(plot, items)
                                loop = false
                            else
                                local item_slot = items[1]
                                local item
                                if item_slot.IsEquipped then
                                    item = _DATA.Save.ActiveTeam.Players[item_slot.Slot].EquippedItem
                                else
                                    item = _DATA.Save.ActiveTeam:GetInv(item_slot.Slot)
                                end
                                UI:WaitShowDialogue(STRINGS:FormatKey('EXPORTER_CONFIRM_GIVE_ONE', item:GetDisplayName()))
                                _SHOP.ExporterAddToStock(plot, items)
                                if GAME:GetPlayerBagCount() + GAME:GetPlayerEquippedCount() > 0 then
                                    UI:WaitShowDialogue(STRINGS:FormatKey('EXPORTER_CONTINUE'))
                                else
                                    loop = false
                                end
                            end
                        else
                            GAME:WaitFrames(5)
                            loop = false
                        end
                    end
                end
            end
        elseif result == 2 then
            if plot.data.earnings > 0 then
                local s = "s"
                if plot.data.sold == 1 then s = "" end
                UI:WaitShowDialogue(STRINGS:FormatKey('EXPORTER_GET_EARNINGS', plot.data.sold, s))
                UI:ResetSpeaker(false)
                UI:SetCenter(true)
                SOUND:PlaySE("Battle/DUN_Money")
                UI:WaitShowDialogue(STRINGS:FormatKey('RECEIVE_ITEM_MESSAGE', STRINGS:FormatKey("MONEY_AMOUNT", plot.data.earnings)))
                GAME:AddToPlayerMoney(plot.data.earnings)
                plot.data.earnings = 0
                plot.data.sold = 0
                UI:SetCenter(false)
                UI:SetSpeaker(npc)
            else
                UI:WaitShowDialogue(STRINGS:FormatKey('EXPORTER_NO_EARNINGS'))
            end
        elseif result == 3 then
            UI:WaitShowDialogue(STRINGS:FormatKey('EXPORTER_INFO_1'))
            UI:WaitShowDialogue(STRINGS:FormatKey('EXPORTER_INFO_2'))
            UI:WaitShowDialogue(STRINGS:FormatKey('EXPORTER_INFO_3'))
            if _HUB.getPlotLevel(plot) < 10 then
                UI:WaitShowDialogue(STRINGS:FormatKey('EXPORTER_INFO_4'))
            end
        else
            UI:WaitShowDialogue(STRINGS:FormatKey('EXPORTER_BYE'))
            exit = true
        end
    end
end

function _SHOP.ExporterAddToStock(plot, items)
    for i, slot in pairs(items) do
        local shift = i-1
        local index = slot.Slot-shift
        local item
        if slot.IsEquipped then
            item = _DATA.Save.ActiveTeam.Players[index].EquippedItem
            GAME:TakePlayerEquippedItem(index, true)
        else
            item = _DATA.Save.ActiveTeam:GetInv(index)
            GAME:TakePlayerBagItem(index, true)
        end
        local checks_required = math.ceil(math.max(1, math.log(item:GetSellValue()/10)))
        local entry = {item = item, state = 0, sell_at = checks_required}
        table.insert(plot.data.stock, entry)
    end
end

function _SHOP.ExporterGetDescription(plot)
    local description = STRINGS:FormatKey("PLOT_DESCRIPTION_EXPORTER_BASE",plot.data.slots, plot.data.checks)
    if plot.data.reduce_all then description = description..STRINGS:FormatKey("PLOT_DESCRIPTION_EXPORTER_BOOST") end
    if plot.data.instant_sell then description = description..STRINGS:FormatKey("PLOT_DESCRIPTION_EXPORTER_INSTANT") end
    if plot.data.earnings > 0 then description = description..STRINGS:FormatKey("PLOT_DESCRIPTION_EXPORTER_SOLD") end
    if plot.data.store_earnings then description = description..STRINGS:FormatKey("PLOT_DESCRIPTION_EXPORTER_DEPOSIT") end
    return description
end

_SHOP.callbacks.initialize["exporter"] =   _SHOP.ExporterInitializer
_SHOP.callbacks.upgrade_flow["exporter"] = _SHOP.ExporterUpgradeFlow
_SHOP.callbacks.upgrade["exporter"] =      _SHOP.ExporterUpgrade
_SHOP.callbacks.endOfDay["exporter"] =     _SHOP.ExporterUpdate
_SHOP.callbacks.interact["exporter"] =     _SHOP.ExporterInteract
_SHOP.callbacks.description["exporter"] =  _SHOP.ExporterGetDescription