--[[
    Exporter.lua

    Allows the player to sell items, albeit over time.
    This file contains all exporter-specific callbacks and functionality data structures
]]

function _SHOP.ExporterInitializer(plot)
    plot.data = {
        stock = {},
        earnings = 0,
        sold = 0,
        slots = 0,
        checks = 0,
        reduce_all = false,
        store_earnings = false,
        instant_sell = false
    }
end

function _SHOP.ExporterUpgrade(plot, upgrade)
    if upgrade ~= "upgrade_generic" then return end

    local level = _HUB.getPlotLevel(plot)
    if level<10 then
        _SHOP.ConfirmShopUpgrade(plot, upgrade)
        level = _HUB.getPlotLevel(plot)
    else return end

    plot.data.slots =  _SHOP.ExporterLevelTables.slots[level]
    plot.data.checks = _SHOP.ExporterLevelTables.checks[level]

    if level == 5 then
        plot.data.reduce_all = true
    elseif level == o then
        plot.data.store_earnings = true
    elseif level == 10 then
        plot.data.instant_sell = true
    end
end


_SHOP.ExporterLevelTables = {
    -- level  1  2  3  4  5   6   7   8   9  10
    slots  = {4, 6, 6, 8, 8, 10, 12, 12, 14, 16},
    checks = {3, 3, 4, 4, 4,  4,  4,  5,  5,  5}
}

function _SHOP.ExporterUpdate(plot)
    local stock = plot.data.stock
    local new_earnings = 0

    if plot.data.instant_sell and math.random(1,4) == 1 then
        local eligible = {}
        for i, item in stock do
            if item.state < 8 then
                table.insert(eligible, {Index = i, Weight = 8 - item.state})
            end
        end
        if #eligible > 0 then
            local sold = COMMON_FUNC.WeightedRoll(eligible)
            new_earnings = new_earnings + stock[sold.Index].item.Price
            plot.data.sold = plot.data.sold + 1
            table.remove(stock, sold.Index)
        end
    end

    for _ = 0, plot.data.checks, 1 do
        if #stock == 0 then break end
        local entry, index = COMMON_FUNC.WeightlessRoll(stock)
        if entry.state > 1 then
            entry.state = entry.state-1
        else
            new_earnings = new_earnings + entry.item.Price
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
    local catalog = { }
    for i = 1, #plot.data.stock, 1 do
        local entry = plot.data.stock[i]
        local item_data = { Item = RogueEssence.Dungeon.InvItem(entry.Index, false, entry.Amount), Price = entry.Price }
        table.insert(catalog, item_data)
    end

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
            --TODO write exporter menu flow


        elseif result == 2 then
            if plot.data.earnings > 0 then
                UI:WaitShowDialogue(STRINGS:FormatKey('EXPORTER_GET_EARNINGS', plot.data.sold))
                UI:ResetSpeaker(false)
                UI:SetCenter(true)
                UI:WaitShowDialogue(STRINGS:FormatKey('MONEY_GAIN', STRINGS:FormatKey("MONEY_AMOUNT", plot.data.earnings)))
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

_SHOP.callbacks.initialize["exporter"] = _SHOP.ExporterInitializer
_SHOP.callbacks.upgrade["exporter"] =    _SHOP.ExporterUpgrade
_SHOP.callbacks.endOfDay["exporter"] =   _SHOP.ExporterUpdate
_SHOP.callbacks.interact["exporter"] =   _SHOP.ExporterInteract