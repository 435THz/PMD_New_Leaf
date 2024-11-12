--[[
    Trader.lua

    Sells items.
    This file contains all trader-specific callbacks and functionality data structures
]]

require 'pmd_new_leaf.menu.office.ShopUpgradeMenu'
require 'pmd_new_leaf.menu.SwapTributeMenu'

_SHOP.TraderTables = {
    --level = 1  2  3  4  5  6  7  8  9 10
    offers = {1, 2, 3, 4, 4, 5, 6, 7, 7, 8},
    prices = {1000, 5000, 25000}
}

function _SHOP.TraderInitializer(plot)
    plot.data = {
        stock = {},
        max_random = 0,
        reroll = 0,
        guarantee_chance = false
    }
end

function _SHOP.TraderUpgradeFlow(plot, _, _)
    local level = _HUB.getPlotLevel(plot)
    local upgrade = "upgrade_trader_base"
    local curr = plot.upgrades[upgrade] or 0
    local cost = _SHOP.GetUpgradeCost(upgrade, curr+1)
    if COMMON_FUNC.CheckCost(cost, true) then
        local func = function(entry) return COMMON_FUNC.PrintItemAmount(entry.item, entry.amount) end
        local cost_string = COMMON_FUNC.BuildStringWithSeparators(cost, func)
        if level == 0 then UI:ChoiceMenuYesNo(STRINGS:FormatKey("OFFICE_BUILD_ASK", STRINGS:FormatKey("SHOP_OPTION_TRADER"), cost_string))
        else UI:ChoiceMenuYesNo(STRINGS:FormatKey("OFFICE_UPGRADE_ASK", STRINGS:FormatKey("SHOP_OPTION_TRADER"), cost_string)) end
        UI:WaitForChoice()
        local ch = UI:ChoiceResult()
        if ch then
            COMMON_FUNC.RemoveItems(cost, true)
            UI:ResetSpeaker(false)
            SOUND:PlaySE("Fanfare/Item")
            UI:SetCenter(true)
            UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_GIVE_ITEM", cost_string))
            UI:SetCenter(false)
            return upgrade
        end
    else
        if level == 0 then UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_CANNOT_BUILD"))
        else UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_CANNOT_UPGRADE")) end
    end
end

function _SHOP.TraderUpgrade(plot, upgrade)
    if upgrade ~= "upgrade_trader_base" then return end

    _SHOP.ConfirmShopUpgrade(plot, upgrade)

    local level = _HUB.getPlotLevel(plot)
    plot.data.max_random = _SHOP.TraderTables.offers[level]
    if level == 1 then
        _SHOP.TraderRestock(plot)
    elseif level == 5 or level == 8 then
        plot.data.reroll = plot.data.reroll+1
    elseif level == 10 then
        plot.data.guarantee_chance = true
    end
end

function _SHOP.TraderRestock(plot)
    local stock = {}
    local indices = {}

    for i = 1, #COMMON_GEN.TRADES_RANDOM, 1 do
        -- check if the item is a 1* item and dex has been seen
        if #COMMON_GEN.TRADES_RANDOM[i].ReqItem == 2 and _DATA.Save:GetMonsterUnlock(COMMON_GEN.TRADES_RANDOM[i].Dex) == RogueEssence.Data.GameProgress.UnlockState.Discovered then
            table.insert(indices, i)
        end
    end

    local rerolled = false
    for _ = 1, math.min(#indices, plot.data.max_random), 1 do
        local index, i = COMMON_FUNC.WeightlessRoll(indices)
        local trade = COMMON_GEN.TRADES_RANDOM[index]
        if not _SHOP.TraderIsPartyItem(trade.Item) and math.random(1, 5) <= plot.data.reroll then
            if plot.data.guarantee_chance and not rerolled and math.random(1, 4) == 1 then
                local new_index, j = _SHOP.TraderGetPartyTrade(indices)
                if new_index then index, i = new_index, j end
                rerolled = true
            else
                index, i = COMMON_FUNC.WeightlessRoll(indices)
            end
            trade = COMMON_GEN.TRADES_RANDOM[index]
        end
        local base_data = { Item=trade.Item, ReqItem=trade.ReqItem }
        table.insert(stock, base_data)
        table.remove(indices, i)
    end

    plot.data.stock = stock
end

function _SHOP.TraderIsPartyItem(item_id)
    local RarityDataType = luanet.import_type('PMDC.Data.RarityData')
    local rarity = _DATA.UniversalData:Get(luanet.ctype(RarityDataType))
    for char in luanet.each(_DATA.Save.ActiveTeam.Players) do
        local species = char.BaseForm.Species
        if rarity.RarityMap:ContainsKey(species) then
            local table = rarity.RarityMap[species]
            if table:ContainsKey(1) then
                for item in luanet.each(table[1]) do
                    if item == item_id then return true end
                end
            end
        end
    end
    return false
end

function _SHOP.TraderGetPartyTrade(indices)
    local RarityDataType = luanet.import_type('PMDC.Data.RarityData')
    local rarity = _DATA.UniversalData:Get(luanet.ctype(RarityDataType))
    local possibleItems = {}
    for char in luanet.each(_DATA.Save.ActiveTeam.Players) do
        local species = char.BaseForm.Species
        if rarity.RarityMap:ContainsKey(species) then
            local table = rarity.RarityMap[species]
            if table:ContainsKey(1) then
                for item in luanet.each(table[1]) do
                    table.insert(possibleItems, item)
                end
            end
        end
    end
    if #possibleItems > 0 then
        local id = COMMON_FUNC.WeightlessRoll(possibleItems)
        for i, index in ipairs(indices) do
            if COMMON_GEN.TRADES_RANDOM[index].Item == id then
                return index, i
            end
        end
    end
    return nil, nil
end

function _SHOP.TraderComputeCatalog(plot)
    --silk/dust/gem/globes
    local catalog = {
        { Item="xcl_element_bug_gem", ReqItem={"xcl_element_bug_silk","xcl_element_bug_dust"}},
        { Item="xcl_element_bug_globe", ReqItem={"xcl_element_bug_silk", "xcl_element_bug_dust", "xcl_element_bug_gem"}},
        { Item="xcl_element_dark_gem", ReqItem={"xcl_element_dark_silk","xcl_element_dark_dust"}},
        { Item="xcl_element_dark_globe", ReqItem={"xcl_element_dark_silk", "xcl_element_dark_dust", "xcl_element_dark_gem"}},
        { Item="xcl_element_dragon_gem", ReqItem={"xcl_element_dragon_silk","xcl_element_dragon_dust"}},
        { Item="xcl_element_dragon_globe", ReqItem={"xcl_element_dragon_silk", "xcl_element_dragon_dust", "xcl_element_dragon_gem"}},
        { Item="xcl_element_electric_gem", ReqItem={"xcl_element_electric_silk","xcl_element_electric_dust"}},
        { Item="xcl_element_electric_globe", ReqItem={"xcl_element_electric_silk", "xcl_element_electric_dust", "xcl_element_electric_gem"}},
        { Item="xcl_element_fairy_gem", ReqItem={"xcl_element_fairy_silk","xcl_element_fairy_dust"}},
        { Item="xcl_element_fairy_globe", ReqItem={"xcl_element_fairy_silk", "xcl_element_fairy_dust", "xcl_element_fairy_gem"}},
        { Item="xcl_element_fighting_gem", ReqItem={"xcl_element_fighting_silk","xcl_element_fighting_dust"}},
        { Item="xcl_element_fighting_globe", ReqItem={"xcl_element_fighting_silk", "xcl_element_fighting_dust", "xcl_element_fighting_gem"}},
        { Item="xcl_element_fire_gem", ReqItem={"xcl_element_fire_silk","xcl_element_fire_dust"}},
        { Item="xcl_element_fire_globe", ReqItem={"xcl_element_fire_silk", "xcl_element_fire_dust", "xcl_element_fire_gem"}},
        { Item="xcl_element_flying_gem", ReqItem={"xcl_element_flying_silk","xcl_element_flying_dust"}},
        { Item="xcl_element_flying_globe", ReqItem={"xcl_element_flying_silk", "xcl_element_flying_dust", "xcl_element_flying_gem"}},
        { Item="xcl_element_ghost_gem", ReqItem={"xcl_element_ghost_silk","xcl_element_ghost_dust"}},
        { Item="xcl_element_ghost_globe", ReqItem={"xcl_element_ghost_silk", "xcl_element_ghost_dust", "xcl_element_ghost_gem"}},
        { Item="xcl_element_grass_gem", ReqItem={"xcl_element_grass_silk","xcl_element_grass_dust"}},
        { Item="xcl_element_grass_globe", ReqItem={"xcl_element_grass_silk", "xcl_element_grass_dust", "xcl_element_grass_gem"}},
        { Item="xcl_element_ground_gem", ReqItem={"xcl_element_ground_silk","xcl_element_ground_dust"}},
        { Item="xcl_element_ground_globe", ReqItem={"xcl_element_ground_silk", "xcl_element_ground_dust", "xcl_element_ground_gem"}},
        { Item="xcl_element_ice_gem", ReqItem={"xcl_element_ice_silk","xcl_element_ice_dust"}},
        { Item="xcl_element_ice_globe", ReqItem={"xcl_element_ice_silk", "xcl_element_ice_dust", "xcl_element_ice_gem"}},
        { Item="xcl_element_normal_gem", ReqItem={"xcl_element_normal_silk","xcl_element_normal_dust"}},
        { Item="xcl_element_normal_globe", ReqItem={"xcl_element_normal_silk", "xcl_element_normal_dust", "xcl_element_normal_gem"}},
        { Item="xcl_element_poison_gem", ReqItem={"xcl_element_poison_silk","xcl_element_poison_dust"}},
        { Item="xcl_element_poison_globe", ReqItem={"xcl_element_poison_silk", "xcl_element_poison_dust", "xcl_element_poison_gem"}},
        { Item="xcl_element_psychic_gem", ReqItem={"xcl_element_psychic_silk","xcl_element_psychic_dust"}},
        { Item="xcl_element_psychic_globe", ReqItem={"xcl_element_psychic_silk", "xcl_element_psychic_dust", "xcl_element_psychic_gem"}},
        { Item="xcl_element_rock_gem", ReqItem={"xcl_element_rock_silk","xcl_element_rock_dust"}},
        { Item="xcl_element_rock_globe", ReqItem={"xcl_element_rock_silk", "xcl_element_rock_dust", "xcl_element_rock_gem"}},
        { Item="xcl_element_steel_gem", ReqItem={"xcl_element_steel_silk","xcl_element_steel_dust"}},
        { Item="xcl_element_steel_globe", ReqItem={"xcl_element_steel_silk", "xcl_element_steel_dust", "xcl_element_steel_gem"}},
        { Item="xcl_element_water_gem", ReqItem={"xcl_element_water_silk","xcl_element_water_dust"}},
        { Item="xcl_element_water_globe", ReqItem={"xcl_element_water_silk", "xcl_element_water_dust", "xcl_element_water_gem"}}
    }

    --normal trades
    for ii = 1, #COMMON_GEN.TRADES, 1 do
        local base_data = COMMON_GEN.TRADES[ii]
        table.insert(catalog, base_data)
    end

    --random trades
    for ii = 1, #plot.data.stock, 1 do
        local base_data = plot.data.stock[ii]
        table.insert(catalog, base_data)
    end
    return catalog
end

function _SHOP.TraderInteract(plot, index)
    local catalog = _SHOP.TraderComputeCatalog(plot)

    local npc = CH("NPC_"..index)
    UI:SetSpeaker(npc)
    local msg = STRINGS:FormatKey('TRADER_INTRO', npc:GetDisplayName())
    local exit = false
    while not exit do
        local choices = {STRINGS:FormatKey('TRADER_OPTION_TRADE'),
                         STRINGS:FormatKey("MENU_INFO"),
                         STRINGS:FormatKey("MENU_EXIT")}
        UI:BeginChoiceMenu(msg, choices, 1, 3)
        UI:WaitForChoice()

        msg = STRINGS:FormatKey('TRADER_REPEAT')

        local result = UI:ChoiceResult()
        if result == 1 then
            if not SwapTributeMenu.canOpen(2) then
                UI:WaitShowDialogue(STRINGS:FormatKey('TRADER_CANNOT_TRADE'))
            else
                local leave_shop = false
                while not leave_shop do

                    UI:SwapMenu(catalog, _SHOP.TraderTables.prices)
                    UI:WaitForChoice()
                    local cart = UI:ChoiceResult()
                    if cart > -1 then

                        local trade = catalog[cart]
                        local receive_item = RogueEssence.Dungeon.InvItem(trade.Item)
                        local free_slots = 0
                        local tribute = {}
                        for ii = 1, #trade.ReqItem, 1 do
                            if trade.ReqItem[ii] == "" then
                                free_slots = free_slots + 1
                            else
                                table.insert(tribute, trade.ReqItem[ii])
                            end
                        end

                        if free_slots > 0 then
                            UI:WaitShowDialogue(STRINGS:FormatKey('TRADER_ASK_TRIBUTE', free_slots, receive_item:GetDisplayName()))
                            --tribute simply aggregates all items period
                            --this means that choosing multiple of one item will be impossible
                            --must choose all DIFFERENT specific items
                            local chosen_items = SwapTributeMenu.run(free_slots)
                            if #chosen_items > 0 then
                                for ii = 1, #chosen_items, 1 do
                                    table.insert(tribute, chosen_items[ii])
                                end
                            end
                        end
                        if #tribute == #trade.ReqItem then

                            local itemEntry = _DATA:GetItem(trade.Item)
                            local total = _SHOP.TraderTables.prices[itemEntry.Rarity]

                            local func = function(entry) RogueEssence.Dungeon.InvItem(entry):GetDisplayName() end
                            UI:WaitShowDialogue(STRINGS:FormatKey('TRADER_CONFIRM_SWAP_1', COMMON_FUNC.BuildStringWithSeparators(tribute, func), receive_item:GetDisplayName()))
                            UI:ChoiceMenuYesNo(STRINGS:FormatKey('TRADER_CONFIRM_SWAP_2', STRINGS:FormatKey("MONEY_AMOUNT", total)), false)
                            UI:WaitForChoice()
                            local ch = UI:ChoiceResult()

                            if ch then
                                for ii = #tribute, 1, -1 do

                                    local item_slot = GAME:FindPlayerItem(tribute[ii], true, true)
                                    if not item_slot:IsValid() then
                                        --it is a certainty that there is an item in storage, due to previous checks
                                        GAME:TakePlayerStorageItem(tribute[ii])
                                    elseif item_slot.IsEquipped then
                                        GAME:TakePlayerEquippedItem(item_slot.Slot)
                                    else
                                        GAME:TakePlayerBagItem(item_slot.Slot)
                                    end
                                end
                                SOUND:PlayBattleSE("DUN_Money")
                                COMMON_FUNC.RemoveMoney(total, true)
                                UI:WaitShowDialogue(STRINGS:FormatKey("TRADER_END"))


                                --remove the trade if it was a base trade
                                local base_trade_idx = cart - (#catalog - #plot.data.stock)
                                if base_trade_idx > 0 then
                                    table.remove(plot.data.stock, base_trade_idx)
                                end

                                UI:ResetSpeaker()
                                SOUND:PlayFanfare("Fanfare/Treasure")
                                UI:SetCenter(true)
                                UI:WaitShowDialogue(STRINGS:FormatKey("RECEIVE_ITEM_MESSAGE", receive_item:GetDisplayName()))

                                if GAME:GetPlayerBagCount() + GAME:GetPlayerEquippedCount() < GAME:GetPlayerBagLimit() then
                                    GAME:GivePlayerItem(trade.Item, 1, false, "")
                                else
                                    GAME:GivePlayerStorageItem(trade.Item, 1, false, "")
                                    UI:WaitShowDialogue(STRINGS:FormatKey("DLG_ITEM_TO_STORAGE"))
                                end
                                UI:SetCenter(false)

                                UI:SetSpeaker(npc)

                                -- recompute the available trades
                                catalog = _SHOP.TraderComputeCatalog()

                                leave_shop = true
                            end
                        else
                            leave_shop = true
                        end
                    else
                        leave_shop = true
                    end
                end
            end
        elseif result == 2 then
            UI:WaitShowDialogue(STRINGS:FormatKey('TRADER_INFO_1'))
            UI:WaitShowDialogue(STRINGS:FormatKey('TRADER_INFO_2'))
            UI:WaitShowDialogue(STRINGS:FormatKey('TRADER_INFO_3'))
            if _HUB.getPlotLevel(plot) < 10 then
                UI:WaitShowDialogue(STRINGS:FormatKey('TRADER_INFO_4'))
            end
        else
            UI:WaitShowDialogue(STRINGS:FormatKey('TRADER_BYE'))
            exit = true
        end
    end
end

function _SHOP.TraderGetDescription(plot)
    local description = STRINGS:FormatKey("PLOT_DESCRIPTION_TRADER_BASE", plot.data.max_random)
    if plot.data.reroll>0 then description = description..STRINGS:FormatKey("PLOT_DESCRIPTION_TRADER_ADVANTAGE") end
    if plot.data.guarantee_chance then description = description..STRINGS:FormatKey("PLOT_DESCRIPTION_TRADER_GUARANTEE") end
    return description
end

_SHOP.callbacks.initialize["trader"] =   _SHOP.TraderInitializer
_SHOP.callbacks.upgrade_flow["trader"] = _SHOP.TraderUpgradeFlow
_SHOP.callbacks.upgrade["trader"] =      _SHOP.TraderUpgrade
_SHOP.callbacks.endOfDay["trader"] =     _SHOP.TraderRestock
_SHOP.callbacks.interact["trader"] =     _SHOP.TraderInteract
_SHOP.callbacks.description["trader"] =  _SHOP.TraderGetDescription