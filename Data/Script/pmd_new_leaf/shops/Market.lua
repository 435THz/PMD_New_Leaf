--[[
    Market.lua

    Sells items.
    This file contains all market-specific callbacks and functionality data structures
]]

require 'pmd_new_leaf.menu.office.ShopUpgradeMenu'
require 'pmd_new_leaf.menu.office.ShopSubUpgradeMenu'

---@alias MarketPlot {unlocked:boolean,building:BuildingID,upgrades:UpgradeEntry,shopkeeper:ShopkeeperData,shopkeeper_shiny:boolean,data:MarketData,empty:integer}
---@alias MarketData {stock:MarketEntry,categories:table<string,MarketCategory>,specialization:MarketSpecialization,discount:boolean}
---@alias MarketCategory {slots:integer,tier:integer}
---@alias MarketSpecialization ""|"ammo"|"orbs"|"recruitment"|"survival"|"tm"|"utilities"|"wands"
---@alias MarketEntry {Index:string,Amount?:integer,Price:integer}

_SHOP.MarketTables = {
    MarketPools = {
        survival = {
            {
                { Index = "food_apple", Amount = 0, Price = 50},
                { Index = "berry_oran", Amount = 0, Price = 80},
                { Index = "berry_leppa", Amount = 0, Price = 80},
                { Index = "berry_lum", Amount = 0, Price = 120}
            },
            {
                { Index = "food_apple_big", Amount = 0, Price = 150},
                { Index = "food_banana", Amount = 0, Price = 500},
                { Index = "seed_reviver", Amount = 0, Price = 500}
            },
            {
                { Index = "orb_revival", Amount = 0, Price = 1000}
            }
        },
        recruitment = {
            {
                { Index = "apricorn_plain", Amount = 0, Price = 400},
                { Index = "apricorn_plain", Amount = 0, Price = 400},
                { Index = "apricorn_plain", Amount = 0, Price = 400},
                { Index = "apricorn_plain", Amount = 0, Price = 400},
                { Index = "apricorn_plain", Amount = 0, Price = 400},
                { Index = "apricorn_plain", Amount = 0, Price = 400},
                { Index = "apricorn_plain", Amount = 0, Price = 400},
                { Index = "apricorn_plain", Amount = 0, Price = 400}
            },
            {
                { Index = "apricorn_black", Amount = 0, Price = 500},
                { Index = "apricorn_blue", Amount = 0, Price = 500},
                { Index = "apricorn_green", Amount = 0, Price = 500},
                { Index = "apricorn_orange", Amount = 0, Price = 500},
                { Index = "apricorn_purple", Amount = 0, Price = 500},
                { Index = "apricorn_red", Amount = 0, Price = 500},
                { Index = "apricorn_white", Amount = 0, Price = 500},
                { Index = "apricorn_yellow", Amount = 0, Price = 500}
            },
            {
                { Index = "apricorn_big", Amount = 0, Price = 500},
                { Index = "apricorn_big", Amount = 0, Price = 500},
                { Index = "apricorn_big", Amount = 0, Price = 500},
                { Index = "apricorn_big", Amount = 0, Price = 500},
                { Index = "apricorn_glittery", Amount = 0, Price = 500},
                { Index = "apricorn_glittery", Amount = 0, Price = 500},
                { Index = "apricorn_glittery", Amount = 0, Price = 500},
                { Index = "medicine_amber_tear", Amount = 1, Price = 1000}
            }
        },
        utilities = {
            {
                { Index = "seed_warp", Amount = 0, Price = 80},
                { Index = "seed_sleep", Amount = 0, Price = 80},
                { Index = "seed_blinker", Amount = 0, Price = 80},
                { Index = "seed_vile", Amount = 0, Price = 80},
                { Index = "seed_ice", Amount = 0, Price = 80},
                { Index = "seed_decoy", Amount = 0, Price = 80},
            },
            {
                { Index = "berry_jaboca", Amount = 0, Price = 100},
                { Index = "berry_rowap", Amount = 0, Price = 100},
                { Index = "seed_blast", Amount = 0, Price = 200},
                { Index = "seed_last_chance", Amount = 0, Price = 150},
                { Index = "herb_mental", Amount = 0, Price = 120},
                { Index = "herb_power", Amount = 0, Price = 250},
                { Index = "herb_white", Amount = 0, Price = 80}
            },
            {
                { Index = "seed_ban", Amount = 0, Price = 500}
            }
        },
        ammo = {
            {
                { Index = "ammo_stick", Amount = 9, Price = 45},
                { Index = "ammo_geo_pebble", Amount = 9, Price = 45},
            },
            {
                { Index = "ammo_cacnea_spike", Amount = 9, Price = 90},
                { Index = "ammo_corsola_twig", Amount = 9, Price = 90},
                { Index = "ammo_gravelerock", Amount = 9, Price = 90},
                { Index = "ammo_rare_fossil", Amount = 9, Price = 90}

            },
            {
                { Index = "ammo_iron_thorn", Amount = 9, Price = 270},
                { Index = "ammo_silver_spike", Amount = 9, Price = 270}
            }
        },
        wands = {
            {
                { Index = "wand_lure", Amount = 9, Price = 180},
                { Index = "wand_pounce", Amount = 9, Price = 180},
                { Index = "wand_whirlwind", Amount = 9, Price = 180}
            },
            {
                { Index = "wand_lob", Amount = 9, Price = 180},
                { Index = "wand_path", Amount = 9, Price = 180},
                { Index = "wand_switcher", Amount = 9, Price = 180},
                { Index = "wand_warp", Amount = 9, Price = 180}
            },
            {
                { Index = "wand_fear", Amount = 9, Price = 180},
                { Index = "wand_purge", Amount = 9, Price = 180},
                { Index = "wand_slow", Amount = 9, Price = 180},
                { Index = "wand_topsy_turvy", Amount = 9, Price = 180}
            }
        },
        orbs = {
            {
                { Index = "orb_all_aim", Amount = 0, Price = 150},
                { Index = "orb_all_dodge", Amount = 0, Price = 150},
                { Index = "orb_cleanse", Amount = 0, Price = 150},
                { Index = "orb_fill_in", Amount = 0, Price = 250},
                { Index = "orb_mirror", Amount = 0, Price = 150},
                { Index = "orb_rollcall", Amount = 0, Price = 150},
                { Index = "orb_spurn", Amount = 0, Price = 250},
                { Index = "orb_trap_see", Amount = 0, Price = 200},
                { Index = "orb_weather", Amount = 0, Price = 150}
            },
            {
                { Index = "orb_endure", Amount = 0, Price = 150},
                { Index = "orb_foe_hold", Amount = 0, Price = 250},
                { Index = "orb_foe_seal", Amount = 0, Price = 250},
                { Index = "orb_halving", Amount = 0, Price = 250},
                { Index = "orb_mug", Amount = 0, Price = 250},
                { Index = "orb_nullify", Amount = 0, Price = 250},
                { Index = "orb_pierce", Amount = 0, Price = 150},
                { Index = "orb_rebound", Amount = 0, Price = 150},
                { Index = "orb_totter", Amount = 0, Price = 250},
                { Index = "orb_trapbust", Amount = 0, Price = 200}
            },
            {
                { Index = "orb_all_protect", Amount = 0, Price = 250},
                { Index = "orb_freeze", Amount = 0, Price = 250},
                { Index = "orb_mobile", Amount = 0, Price = 250},
                { Index = "orb_one_shot", Amount = 0, Price = 300},
                { Index = "orb_petrify", Amount = 0, Price = 250},
                { Index = "orb_scanner", Amount = 0, Price = 350},
                { Index = "orb_slow", Amount = 0, Price = 250},
                { Index = "orb_slumber", Amount = 0, Price = 250}
            }
        },
        tm = {{},{},{}}
    },
    upgrade_order = {"market_unlock", "market_expand", "market_tier", "market_specialize"},
    sub_order = {"sub_survival", "sub_recruitment", "sub_utilities", "sub_ammo", "sub_wands", "sub_orbs", "sub_tm"}
}

---Initializes a market shop's specific data
---@param plot MarketPlot the plot's data structure
function _SHOP.MarketInitializer(plot)
    plot.data = {
        stock = {},
        categories = {},
        specialization = "",
        discount = false
    }
end

---Runs the upgrade flow for the specified market, letting the player choose which upgrades to apply
---@param plot MarketPlot the plot's data structure
---@param index integer the plot index number
---@param shop_id? BuildingID a building id. It is only considered if no building exists in the given plot yet
---@return string|false #an upgrade to apply, or false if none was chosen
function _SHOP.MarketUpgradeFlow(plot, index, shop_id)
    local level = _HUB.getPlotLevel(plot)
    local upgrade = ""
    local sub_upgrade = ""

    local tree, keys = _SHOP.MakeUpgradeTree(index, level+1, shop_id)
    local comp = function(a,b, order)
        for _, elem in ipairs(order) do
            if elem == a then return true
            elseif elem == b then return false end
        end
        return false
    end
    table.sort(keys, function(a, b) return comp(a, b, _SHOP.MarketTables.upgrade_order) end)

    local up_start
    local loop = true
    while loop do
        if #keys == 1 then
            if upgrade == "" then
                upgrade = keys[1]
            else
                return false
            end
        else
            upgrade, up_start = ShopUpgradeMenu.run(tree, keys, index, up_start)
        end
        if upgrade == "exit" then return false end
        local sub_start
        local loop2 = true
        while loop2 do
            table.sort(tree[upgrade].sub, function(a, b) return comp(a, b, _SHOP.MarketTables.sub_order) end)
            sub_upgrade, sub_start = ShopSubUpgradeMenu.run(tree, upgrade, index, sub_start)
            if sub_upgrade == "exit" then
                loop2 = false
            else
                local final_upgrade = STRINGS:Format("{0}_{1}", upgrade, sub_upgrade)
                local curr = plot.upgrades[final_upgrade] or 0
                local cost = _SHOP.GetFullUpgradeCost(upgrade, sub_upgrade, curr+1)
                if COMMON_FUNC.CheckCost(cost, true) then
                    local func = function(entry) return COMMON_FUNC.PrintItemAmount(entry.item, entry.amount) end
                    local cost_string = COMMON_FUNC.BuildStringWithSeparators(cost, func)
                    if level == 0 then UI:ChoiceMenuYesNo(STRINGS:FormatKey("OFFICE_BUILD_ASK", STRINGS:FormatKey("SHOP_OPTION_MARKET"), cost_string))
                    else UI:ChoiceMenuYesNo(STRINGS:FormatKey("OFFICE_UPGRADE_ASK", STRINGS:FormatKey("SHOP_OPTION_MARKET"), cost_string)) end
                    UI:WaitForChoice()
                    local ch = UI:ChoiceResult()

                    if ch then
                        COMMON_FUNC.RemoveItems(cost, true)
                        UI:ResetSpeaker(false)
                        SOUND:PlaySE("Fanfare/Item")
                        UI:SetCenter(true)
                        UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_GIVE_ITEM", cost_string))
                        UI:SetCenter(false)
                        return final_upgrade
                    end
                else
                    if level == 0 then UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_CANNOT_BUILD"))
                    else UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_CANNOT_UPGRADE")) end
                end
            end
        end
    end
end

---Checks if the supplied upgrade is valid, and updates the plot's data structure accordingly if it is.
---@param plot MarketPlot the plot's data structure
---@param upgrade string an upgrade id
function _SHOP.MarketUpgrade(plot, upgrade)
    local pool = ""
    if string.match(upgrade, "sub_survival") then
        pool = "survival"
    elseif string.match(upgrade, "sub_recruitment") then
        pool = "recruitment"
    elseif string.match(upgrade, "sub_utilities") then
        pool = "utilities"
    elseif string.match(upgrade, "sub_ammo") then
        pool = "ammo"
    elseif string.match(upgrade, "sub_wands") then
        pool = "wands"
    elseif string.match(upgrade, "sub_orbs") then
        pool = "orbs"
    elseif string.match(upgrade, "sub_tm") then
        pool = "tm"
    end

    local valid = false
    if pool ~= "" then
        valid = true
        if string.match(upgrade, "market_unlock") then
            plot.data.categories[pool] = {slots = 2, tier = 1}
            table.insert(plot.data.stock, _SHOP.MarketRoll(pool, plot.data.categories[pool].tier))
            table.insert(plot.data.stock, _SHOP.MarketRoll(pool, plot.data.categories[pool].tier))
        elseif string.match(upgrade, "market_expand") then
            plot.data.categories[pool].slots = plot.data.categories[pool].slots+1
            table.insert(plot.data.stock, _SHOP.MarketRoll(pool, plot.data.categories[pool].tier))
        elseif string.match(upgrade, "market_tier") then
            plot.data.categories[pool].tier = plot.data.categories[pool].tier+1
        elseif string.match(upgrade, "market_specialize") then
            plot.data.specialization = pool
        else
            valid = false
        end
    end

    if valid then _SHOP.ConfirmShopUpgrade(plot, upgrade) end

    local level = _HUB.getPlotLevel(plot)
    if level == 1 then
        _SHOP.MarketRestock(plot)
    elseif level == 10 then
        plot.data.discount = true
    end
end

---Restocks the market
---@param plot MarketPlot the plot's data structure
function _SHOP.MarketRestock(plot)
    local stock = {}
    local specialization_items = {}
    for pool, data in pairs(plot.data.categories) do
        local specialization_effect = false
        if plot.data.specialization == pool then specialization_effect = true end
        for _ = 1, data.slots, 1 do
            local result = _SHOP.MarketRoll(pool, data.tier)
            if result then
                if specialization_effect and not table.contains(specialization_items, data) then
                    table.insert(specialization_items, result.Index)
                end
                if plot.data.discount then
                    result.Price = math.ceil(result.Price*4/5)
                end
                table.insert(stock, result)
            end
        end
    end
    if #specialization_items>0 and math.random(1,4) == 1 then
        local item_id = COMMON_FUNC.WeightlessRoll(specialization_items)
        for _, item in pairs(stock) do
            if item.Index == item_id then
                item.Price = math.ceil(item.Price/2)
            end
        end
    end
    plot.data.stock = stock
end

---Rolls a single shop entry from a pool and returns it
---@param pool_id string a pool id to roll for
---@param tier integer the tier that pool is currently at
---@return MarketEntry|nil #a market entry if one was selected, otherwise nil
function _SHOP.MarketRoll(pool_id, tier)
    local pool = _SHOP.MarketTables.MarketPools[pool_id]

    local roll_table = pool[1]
    if tier == 2 then roll_table = COMMON_FUNC.LengthWeightedTableListRoll({pool[1], pool[2]}) --[[@as table]]
    elseif tier == 3 then roll_table = COMMON_FUNC.LengthWeightedTableListRoll(pool)  --[[@as table]] end
    local result = COMMON_FUNC.WeightlessRoll(roll_table)
    if result then return { Index = result.Index, Amount = result.Amount, Price = result.Price} end
    return nil
end

---Runs the interact flow for the given market, letting the player interact with the shop
---@param plot MarketPlot the plot's data structure
---@param index integer the plot index number
function _SHOP.MarketInteract(plot, index)
    local catalog = { }
    for i = 1, #plot.data.stock, 1 do
        local entry = plot.data.stock[i]
        local item_data = { Item = RogueEssence.Dungeon.InvItem(entry.Index, false, entry.Amount), Price = entry.Price }
        table.insert(catalog, item_data)
    end

    local npc = CH("NPC_"..index)
    UI:SetSpeaker(npc)
    local msg = STRINGS:FormatKey('MARKET_INTRO', npc:GetDisplayName())
    local exit = false
    while not exit do
        local choices = {STRINGS:FormatKey('MARKET_OPTION_BUY'),
                         STRINGS:FormatKey("MENU_INFO"),
                         STRINGS:FormatKey("MENU_EXIT")}
        UI:BeginChoiceMenu(msg, choices, 1, 3)
        UI:WaitForChoice()

        msg = STRINGS:FormatKey('MARKET_REPEAT')

        local result = UI:ChoiceResult()
        if result == 1 then
            local leave_shop = false
            while not leave_shop do
                if #catalog == 0 then
                    UI:SetSpeakerEmotion("Worried")
                    UI:WaitShowDialogue(STRINGS:FormatKey('MARKET_OUT_OF_STOCK'))
                    UI:SetSpeakerEmotion("Normal")
                    leave_shop = true
                else
                    UI:ShopMenu(catalog)
                    UI:WaitForChoice()
                    local cart = UI:ChoiceResult()
                    if #cart > 0 then
                        local total = 0
                        for i = 1, #cart, 1 do
                            total = total + catalog[cart[i]].Price
                        end
                        if COMMON_FUNC.CheckMoney(total) then
                            UI:SetSpeakerEmotion("Angry")
                            UI:WaitShowDialogue(STRINGS:FormatKey('MARKET_NO_MONEY'))
                            UI:SetSpeakerEmotion("Normal")
                        else
                            if #cart == 1 then
                                local name = catalog[cart[1]].Item:GetDisplayName()
                                UI:ChoiceMenuYesNo(STRINGS:FormatKey('MARKET_BUY_ONE', STRINGS:FormatKey("MONEY_AMOUNT", total), name), false)
                            else
                                UI:ChoiceMenuYesNo(STRINGS:FormatKey('MARKET_BUY_MULTI', STRINGS:FormatKey("MONEY_AMOUNT", total)), false)
                            end
                            UI:WaitForChoice()
                            result = UI:ChoiceResult()

                            if result then
                                COMMON_FUNC.RemoveMoney(total, true)
                                for i = 1, #cart, 1 do
                                    local item = catalog[cart[i]].Item
                                    GAME:GivePlayerItem(item.ID, item.Amount, false)
                                end
                                for i = #cart, 1, -1 do
                                    table.remove(catalog, cart[i])
                                    table.remove(plot.data.stock, cart[i])
                                end

                                cart = {}
                                SOUND:PlaySE("Battle/DUN_Money")
                                UI:WaitShowDialogue(STRINGS:FormatKey('MARKET_BUY_END'))
                                leave_shop = true
                            end
                        end
                    else
                        leave_shop = true
                    end
                end
            end
        elseif result == 2 then
            UI:WaitShowDialogue(STRINGS:FormatKey('MARKET_INFO_1'))
            UI:WaitShowDialogue(STRINGS:FormatKey('MARKET_INFO_2'))
            UI:WaitShowDialogue(STRINGS:FormatKey('MARKET_INFO_3'))
            if _HUB.getPlotLevel(plot) < 10 then
                UI:WaitShowDialogue(STRINGS:FormatKey('MARKET_INFO_4'))
            end
        else
            UI:WaitShowDialogue(STRINGS:FormatKey('MARKET_BYE'))
            exit = true
        end
    end
end

---Loads all TMs in the tm market pool. Cost and tier are based on the number of PP the moves have.
function _SHOP.MarketLoadTMs()
    _SHOP.MarketTables.MarketPools.tm = {{},{},{}}
                          --1   2   3   4   5   6   7   8   9   10  11  12  13  14  15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31+
    local charge_to_cost = {24, 20, 17, 15, 14, 14, 13, 13, 12, 12, 11, 11, 10, 10, 10, 9, 9, 9, 8, 8, 8, 7, 7, 7, 7, 6, 6, 6, 6, 6, 5}
    local multiplier = 500
    local proxy = luanet.import_type('RogueEssence.Dungeon.ItemIDState')
    local id_state_type = luanet.ctype(proxy)
    local items = _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Item]:GetOrderedKeys(true)
    for id in luanet.each(items) do
        if(string.sub(id, 1,3) == "tm_") then
            local item = _DATA:GetItem(id)
            local move_id = item.ItemStates:GetWithDefault(id_state_type).ID
            local move = _DATA:GetSkill(move_id)
            local price = charge_to_cost[#charge_to_cost]
            local tier = 1
            if move.BaseCharges <= #charge_to_cost then
                price = charge_to_cost[move.BaseCharges]
                if move.BaseCharges<13 then tier = 3
                elseif move.BaseCharges<17 then tier = 2 end
            end
            local entry = { Index = id, Amount = 0, Price = price*multiplier}
            table.insert(_SHOP.MarketTables.MarketPools.tm[tier], entry)
        end
    end
end

---Returns the description that will be used for this shop in the office menu.
---@param plot MarketPlot the plot's data structure
---@return string #the plot's description
function _SHOP.MarketGetDescription(plot)
    local l = {}
    for pool in pairs(plot.data.categories) do
        table.insert(l, pool)
    end
    local func = function(entry)
        return STRINGS:FormatKey("MARKET_POOL_"..string.upper(entry))
    end

    local pools = COMMON_FUNC.BuildStringWithSeparators(l, func)
    local description = STRINGS:FormatKey("PLOT_DESCRIPTION_MARKET_BASE", pools)

    if plot.data.specialization ~= "" then
        description = description..STRINGS:FormatKey("PLOT_DESCRIPTION_MARKET_SPECIALIZATION", STRINGS:FormatKey("MARKET_POOL_", string.upper(plot.data.specialization)))
    end
    if plot.data.discount then description = description..STRINGS:FormatKey("PLOT_DESCRIPTION_MARKET_DISCOUNT") end
    return description
end

_SHOP.callbacks.initialize["market"] =   _SHOP.MarketInitializer
_SHOP.callbacks.upgrade_flow["market"] = _SHOP.MarketUpgradeFlow
_SHOP.callbacks.upgrade["market"] =      _SHOP.MarketUpgrade
_SHOP.callbacks.endOfDay["market"] =     _SHOP.MarketRestock
_SHOP.callbacks.interact["market"] =     _SHOP.MarketInteract
_SHOP.callbacks.description["market"] =  _SHOP.MarketGetDescription
_SHOP.MarketLoadTMs()