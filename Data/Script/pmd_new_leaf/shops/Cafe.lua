--[[
    Cafe.lua

    Allows gaining permanent stat bonuses and crafting.
    This file contains all cafe-specific callbacks and functionality data structures
]]

require 'pmd_new_leaf.menu.SmallShopMenu'
require 'pmd_new_leaf.menu.CraftingMenu'
require 'pmd_new_leaf.menu.JuiceMenu'

---@alias CafePlot {unlocked:boolean,building:BuildingID,upgrades:UpgradeEntry,shopkeeper:ShopkeeperData,shopkeeper_shiny:boolean,data:CafeData,empty:integer}
---@alias CafeData {price:integer,boost_pools:integer,daily_pools:integer,craft_pools:integer,daily_amount:integer,iotd:CafeEntry[]}
---@alias CafeEntry {Item:string,Weight:integer,Price:integer}
---@alias CafeTotalBoosts {boosts:CafeBoosts,random:CafeBoostRandomEntry[],reverse_random:boolean}
---@alias CafeBoosts {HP:integer,Atk:integer,Def:integer,SpAtk:integer,SpDef:integer,Speed:integer}
---@alias CafeBoostRandomEntry {HP:boolean,Atk:boolean,Def:boolean,SpAtk:boolean,SpDef:boolean,Speed:boolean,Rolls:integer,Amount:integer}

_SHOP.CafeTables = {
    --level =       1    2   3   4   5   6   7   8   9   10
    prices =       {100, 90, 80, 70, 60, 50, 40, 25, 10, 0},
    boost_tier =   {1,   1,  2,  2,  2,  3,  3,  4,  4,  4},
    daily_tier =   {0,   1,  1,  1,  2,  2,  2,  2,  3,  3},
    daily_amount = {0,   1,  1,  1,  1,  1,  2,  2,  2,  2},
    craft_tier =   {0,   0,  0,  1,  1,  2,  2,  2,  2,  3},
    boost_table = {
        {
            gummi_blue = { HP = 2, GummiEffect = 'water' },
            gummi_black = { HP = 2, GummiEffect = 'dark' },
            gummi_brown = { Atk = 2, GummiEffect = 'ground' },
            gummi_clear = { SpDef = 2, GummiEffect = 'ice' },
            gummi_grass = { SpDef = 2, GummiEffect = 'grass' },
            gummi_gray = { Def = 2, GummiEffect = 'rock' },
            gummi_green = { Speed = 2, GummiEffect = 'bug' },
            gummi_gold = { SpAtk = 2, GummiEffect = 'psychic' },
            gummi_magenta = { SpDef = 2, GummiEffect = 'fairy' },
            gummi_orange = { Atk = 2, GummiEffect = 'fighting' },
            gummi_pink = { Def = 2, GummiEffect = 'poison' },
            gummi_purple = { SpAtk = 2, GummiEffect = 'ghost' },
            gummi_red = { SpAtk = 2, GummiEffect = 'fire' },
            gummi_royal = { Atk = 2, GummiEffect = 'dragon' },
            gummi_sky = { Speed = 2, GummiEffect = 'flying' },
            gummi_silver = { Def = 2, GummiEffect = 'steel' },
            gummi_white = { HP = 2, GummiEffect = 'normal' },
            gummi_yellow = { Speed = 2, GummiEffect = 'electric' },
            gummi_wonder = { HP = 2, Atk = 2, Def = 2, SpAtk = 2, SpDef = 2, Speed = 2 }
        },
        {
            -- healing
            berry_oran = { HP = 1 },
            berry_leppa = { Rand = { Atk = true, SpAtk = true , Rolls = 1, Amount = 1 } },
            berry_sitrus = { HP = 1, Rand = { HP = true, Atk = true, Def = true, SpAtk = true, SpDef = true, Speed = true, Rolls = 1, Amount = 1 } },
            berry_lum = { Rand = { Def = true, SpDef = true, Rolls = 1, Amount = 1 } },
            -- type specific
            berry_passho = { HP = 1 },
            berry_colbur = { HP = 1 },
            berry_yache = { SpDef = 1 },
            berry_rindo = { SpDef = 1 },
            berry_tanga = { Speed = 1 },
            berry_shuca = { Atk = 1 },
            berry_chople = { Atk = 1 },
            berry_payapa = { SpAtk = 1 },
            berry_kebia = { Def = 1 },
            berry_kasib = { SpAtk = 1 },
            berry_occa = { SpAtk = 1 },
            berry_haban = { Atk = 1 },
            berry_babiri = { Def = 1 },
            berry_chilan = { HP = 1 },
            berry_wacan = { Speed = 1 },
            berry_coba = { Speed = 1 },
            berry_charti = { Def = 1 },
            berry_roseli = { SpDef = 1 },
            -- reflect category
            berry_jaboca = { Def = 1 },
            berry_rowap = { SpDef = 1 },
            -- stat stage ups
            berry_liechi = { Atk = 2 },
            berry_ganlon = { Def = 2 },
            berry_petaya = { SpAtk = 2 },
            berry_apicot = { SpDef = 2 },
            berry_salac = { Speed = 2 },
            berry_starf = { HP = 2 },
            berry_micle = { Atk = 1, SpAtk = 1 },
            -- absorb super-eff
            berry_enigma = { HP = 1, Rand = { HP = true, Atk = true, Def = true, SpAtk = true, SpDef = true, Speed = true, Rolls = 1 , Amount = 1 } },

            seed_plain = { Rand = { HP = true, Atk = true, Def = true, SpAtk = true, SpDef = true, Speed = true, Rolls = 1, Amount = 1 } },
            seed_reviver = { Rand = { HP = true, Atk = true, Def = true, SpAtk = true, SpDef = true, Speed = true,  Rolls = 3, Amount = 1 } },

            seed_joy = { Rand = { HP = true, Atk = true, Def = true, SpAtk = true, SpDef = true, Speed = true,  Rolls = 6, Amount = 1 } },
            seed_golden = { Rand = { HP = true, Atk = true, Def = true, SpAtk = true, SpDef = true, Speed = true,  Rolls = 6, Amount = 5 } },
            seed_doom = { Rand = { HP = -5, Atk = -5, Def = -5, SpAtk = -5, SpDef = -5, Speed = -5, Rolls = 6, Amount = 1 } },

            seed_hunger = { HP = -1, Rand = { HP = true, Atk = true, Def = true, SpAtk = true, SpDef = true, Speed = true,  Rolls = 1, Amount = 1 } },

            seed_warp = { Speed = 1 },
            seed_sleep = { HP = 1 },
            seed_vile = { Def = 1, SpDef = 1 },
            seed_blast = { Atk = 1 },
            seed_blinker = { Speed = 1 },

            seed_pure = { Rand = { HP = true, Atk = true, Def = true, SpAtk = true, SpDef = true, Speed = true,  Rolls = 1, Amount = 1 } },
            seed_ice = { Speed = 1 },
            seed_decoy = { SpDef = 1 },
            seed_last_chance = { Atk = 1, SpAtk = 1 },
            seed_ban = { Rand = { HP = true, Atk = true, Def = true, SpAtk = true, SpDef = true, Speed = true,  Rolls = 1, Amount = 1 } }
        },
        {
            medicine_amber_tear = { HP = 1, Atk = 1, Def = 1, SpAtk = 1, SpDef = 1, Speed = 1 },
            boost_nectar = { HP = 1, Atk = 1, Def = 1, SpAtk = 1, SpDef = 1, Speed = 1 },
            boost_hp_up = { HP = 8 },
            boost_protein = { Atk = 8 },
            boost_iron = { Def = 8 },
            boost_calcium = { SpAtk = 8 },
            boost_zinc = { SpDef = 8 },
            boost_carbos = { Speed = 8 }
        },
        {
            food_apple = { Rand = { HP = true, Atk = true, Def = true, SpAtk = true, SpDef = true, Speed = true,  Rolls = 1, Amount = 1 } },
            food_apple_big = { Rand = { HP = true, Atk = true, Def = true, SpAtk = true, SpDef = true, Speed = true,  Rolls = 1, Amount = 2 } },
            food_apple_huge = { Rand = { HP = true, Atk = true, Def = true, SpAtk = true, SpDef = true, Speed = true,  Rolls = 1, Amount = 4 } },
            food_apple_perfect = { Rand = { HP = true, Atk = true, Def = true, SpAtk = true, SpDef = true, Speed = true,  Rolls = 1, Amount = 32 } },
            food_apple_golden = { Rand = { HP = true, Atk = true, Def = true, SpAtk = true, SpDef = true, Speed = true,  Rolls = 1, Amount = 256 } },
            food_banana = { HP = 1, Atk = 1, Def = 1, SpAtk = 1, SpDef = 1, Speed = 1 },
            food_banana_big = { HP = 4, Atk = 4, Def = 4, SpAtk = 4, SpDef = 4, Speed = 4 },
            food_banana_golden = { HP = 256, Atk = 256, Def = 256, SpAtk = 256, SpDef = 256, Speed = 256 },
            herb_mental = { NegateStatA = true },
            herb_power = { NegateStatB = true },
            herb_white = { NegateStatC = true },
            food_grimy = { HP = -32, Atk = -32, Def = -32, SpAtk = -32, SpDef = -32, Speed = -32 }
        }
    },
    daily_pool = {
        {
            {Item = "food_apple_big", Weight = 30, Price = 100},
            {Item = "food_apple_huge", Weight = 20, Price = 200},

            {Item = "berry_lum", Weight = 15, Price = 90},
            {Item = "berry_sitrus", Weight = 5, Price = 100},

            {Item = "berry_jaboca", Weight = 3, Price = 75},
            {Item = "berry_rowap", Weight = 3, Price = 75},
            {Item = "berry_liechi", Weight = 3, Price = 100},
            {Item = "berry_ganlon", Weight = 3, Price = 100},
            {Item = "berry_petaya", Weight = 3, Price = 100},
            {Item = "berry_apicot", Weight = 3, Price = 100},
            {Item = "berry_salac", Weight = 3, Price = 100},
            {Item = "berry_starf", Weight = 3, Price = 100},
            {Item = "berry_micle", Weight = 3, Price = 100},
            {Item = "berry_enigma", Weight = 3, Price = 120},

            {Item = "seed_plain", Weight = 20, Price = 5},
            {Item = "seed_reviver", Weight = 10, Price = 350},

            {Item = "herb_mental", Weight = 5, Price = 80},
            {Item = "herb_power", Weight = 5, Price = 180},
            {Item = "herb_white", Weight = 5, Price = 50}
        },
        {
            {Item = "food_banana", Weight = 10, Price = 350},

            {Item = "berry_tanga", Weight = 3, Price = 100},
            {Item = "berry_colbur", Weight = 3, Price = 100},
            {Item = "berry_haban", Weight = 3, Price = 100},
            {Item = "berry_wacan", Weight = 3, Price = 100},
            {Item = "berry_chople", Weight = 3, Price = 100},
            {Item = "berry_occa", Weight = 3, Price = 100},
            {Item = "berry_coba", Weight = 3, Price = 100},
            {Item = "berry_kasib", Weight = 3, Price = 100},
            {Item = "berry_rindo", Weight = 3, Price = 100},
            {Item = "berry_shuca", Weight = 3, Price = 100},
            {Item = "berry_yache", Weight = 3, Price = 100},
            {Item = "berry_chilan", Weight = 3, Price = 100},
            {Item = "berry_kebia", Weight = 3, Price = 100},
            {Item = "berry_payapa", Weight = 3, Price = 100},
            {Item = "berry_charti", Weight = 3, Price = 100},
            {Item = "berry_babiri", Weight = 3, Price = 100},
            {Item = "berry_passho", Weight = 3, Price = 100},
            {Item = "berry_roseli", Weight = 3, Price = 100},

            {Item = "gummi_blue", Weight = 1, Price = 500},
            {Item = "gummi_black", Weight = 1, Price = 500},
            {Item = "gummi_clear", Weight = 1, Price = 500},
            {Item = "gummi_grass", Weight = 1, Price = 500},
            {Item = "gummi_green", Weight = 1, Price = 500},
            {Item = "gummi_brown", Weight = 1, Price = 500},
            {Item = "gummi_orange", Weight = 1, Price = 500},
            {Item = "gummi_gold", Weight = 1, Price = 500},
            {Item = "gummi_pink", Weight = 1, Price = 500},
            {Item = "gummi_purple", Weight = 1, Price = 500},
            {Item = "gummi_red", Weight = 1, Price = 500},
            {Item = "gummi_royal", Weight = 1, Price = 500},
            {Item = "gummi_silver", Weight = 1, Price = 500},
            {Item = "gummi_white", Weight = 1, Price = 500},
            {Item = "gummi_yellow", Weight = 1, Price = 500},
            {Item = "gummi_sky", Weight = 1, Price = 500},
            {Item = "gummi_gray", Weight = 1, Price = 500},
            {Item = "gummi_magenta", Weight = 1, Price = 500},
            {Item = "gummi_wonder", Weight = 1, Price = 800},

            {Item = "seed_joy", Weight = 1, Price = 800},
            {Item = "seed_doom", Weight = 3, Price = 400},
        },
        {
            {Item = "food_banana_big", Weight = 3, Price = 700},
            {Item = "food_apple_perfect", Weight = 2, Price = 1600},

            {Item = "boost_nectar", Weight = 1, Price = 800},
            {Item = "boost_protein", Weight = 1, Price = 800},
            {Item = "boost_iron", Weight = 1, Price = 800},
            {Item = "boost_calcium", Weight = 1, Price = 800},
            {Item = "boost_zinc", Weight = 1, Price = 800},
            {Item = "boost_carbos", Weight = 1, Price = 800},
            {Item = "boost_hp_up", Weight = 1, Price = 800},
        }
    },
    crafts = {
        {
            {Item = "gummi_blue",    ReqItems = {"apricorn_blue",   "berry_passho"}},
            {Item = "gummi_black",   ReqItems = {"apricorn_black",  "berry_colbur"}},
            {Item = "gummi_clear",   ReqItems = {"apricorn_blue",   "berry_yache"}},
            {Item = "gummi_grass",   ReqItems = {"apricorn_green",  "berry_rindo"}},
            {Item = "gummi_green",   ReqItems = {"apricorn_green",  "berry_tanga"}},
            {Item = "gummi_brown",   ReqItems = {"apricorn_brown",  "berry_shuca"}},
            {Item = "gummi_orange",  ReqItems = {"apricorn_brown",  "berry_chople"}},
            {Item = "gummi_gold",    ReqItems = {"apricorn_purple", "berry_payapa"}},
            {Item = "gummi_pink",    ReqItems = {"apricorn_purple", "berry_kebia"}},
            {Item = "gummi_purple",  ReqItems = {"apricorn_black",  "berry_kasib"}},
            {Item = "gummi_red",     ReqItems = {"apricorn_red",    "berry_occa"}},
            {Item = "gummi_royal",   ReqItems = {"apricorn_red",    "berry_haban"}},
            {Item = "gummi_silver",  ReqItems = {"apricorn_yellow", "berry_babiri"}},
            {Item = "gummi_white",   ReqItems = {"apricorn_white",  "berry_chilan"}},
            {Item = "gummi_yellow",  ReqItems = {"apricorn_yellow", "berry_wacan"}},
            {Item = "gummi_sky",     ReqItems = {"apricorn_white",  "berry_coba"}},
            {Item = "gummi_gray",    ReqItems = {"apricorn_brown",  "berry_charti"}},
            {Item = "gummi_magenta", ReqItems = {"apricorn_white",  "berry_roseli"}}
        } ,
        {
            {Item = "boost_protein", ReqItems = { { "berry_liechi", 4 }}},
            {Item = "boost_iron",    ReqItems = { { "berry_ganlon", 4 }}},
            {Item = "boost_calcium", ReqItems = { { "berry_petaya", 4 }}},
            {Item = "boost_zinc",    ReqItems = { { "berry_apicot", 4 }}},
            {Item = "boost_carbos",  ReqItems = { { "berry_salac",  4 }}},
            {Item = "boost_hp_up",   ReqItems = { { "berry_starf",  4 }}},
        },
        {
            --TODO special stuff. We should make at least 5 or 6 recipes
        }
    }
}

---Initializes a cafe shop's specific data
---@param plot CafePlot the plot's data structure
function _SHOP.CafeInitializer(plot)
    plot.data = {
        price = 100,
        boost_pools = 1,
        daily_pools = 0,
        craft_pools = 0,
        daily_amount = 0,
        iotd = {}
    }
end

---Runs the upgrade flow for the specified cafe, letting the player choose which upgrades to apply
---@param plot CafePlot the plot's data structure
---@param index integer the plot index number
---@param shop_id? BuildingID a building id. It is only considered if no building exists in the given plot yet
---@return string|false #an upgrade to apply, or false if none was chosen
function _SHOP.CafeUpgradeFlow(plot, index, shop_id)
    local level = _HUB.getPlotLevel(plot)
    local upgrade = "upgrade_cafe_base"
    local curr = plot.upgrades[upgrade] or 0
    local cost = _SHOP.GetUpgradeCost(upgrade, curr+1)
    if COMMON_FUNC.CheckCost(cost, true) then
        local func = function(entry) return COMMON_FUNC.PrintItemAmount(entry.item, entry.amount) end
        local cost_string = COMMON_FUNC.BuildStringWithSeparators(cost, func)
        if level == 0 then UI:ChoiceMenuYesNo(STRINGS:FormatKey("OFFICE_BUILD_ASK", STRINGS:FormatKey("SHOP_OPTION_CAFE"), cost_string))
        else UI:ChoiceMenuYesNo(STRINGS:FormatKey("OFFICE_UPGRADE_ASK", STRINGS:FormatKey("SHOP_OPTION_CAFE"), cost_string)) end
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
    return false
end

---Checks if the supplied upgrade is valid, and updates the plot's data structure accordingly if it is.
---@param plot CafePlot the plot's data structure
---@param upgrade string an upgrade id
function _SHOP.CafeUpgrade(plot, upgrade)
    if upgrade ~= "upgrade_cafe_base" then return end

    local level = _HUB.getPlotLevel(plot)
    if level<10 then
        _SHOP.ConfirmShopUpgrade(plot, upgrade)
        level = _HUB.getPlotLevel(plot)
    else return end

    plot.data.price  = _SHOP.CafeTables.prices[level]
    plot.data.boost_pools  = _SHOP.CafeTables.boost_tier[level]
    plot.data.daily_pools  = _SHOP.CafeTables.daily_tier[level]
    plot.data.craft_pools  = _SHOP.CafeTables.craft_tier[level]
    plot.data.daily_amount = _SHOP.CafeTables.daily_amount[level]

    if level>1 and _SHOP.CafeTables.daily_amount[level-1] < _SHOP.CafeTables.daily_amount[level] then
        table.insert(plot.data.iotd, _SHOP.CafeRollItemOfTheDay(plot.data.daily_pools))
    end
end

---Restocks the dailies for the given cafe
---@param plot CafePlot the plot's data structure
function _SHOP.CafeUpdate(plot)
    local new_iotd = {}
    for _=1, _SHOP.CafeTables.daily_amount[_HUB.getPlotLevel(plot)], 1 do
        table.insert(new_iotd, _SHOP.CafeRollItemOfTheDay(plot.data.daily_pools))
    end
    plot.data.iotd = new_iotd
end

---Rolls a daily special
---@param tier integer the current daily item tier
---@return CafeEntry
function _SHOP.CafeRollItemOfTheDay(tier)
    local pool = {}
    for i=1, tier, 1 do table.merge(pool, _SHOP.CafeTables.daily_pool[i]) end
    local item = COMMON_FUNC.WeightedRoll(pool) --[[@as CafeEntry]]
    return item
end

---Runs the interact flow for the given cafe, letting the player interact with the shop
---@param plot CafePlot the plot's data structure
---@param index integer the plot index number
function _SHOP.CafeInteract(plot, index)
    local npc = CH("NPC_"..index)
    UI:SetSpeaker(npc)
    local msg = STRINGS:FormatKey('CAFE_INTRO', npc:GetDisplayName())
    local exit = false
    while not exit do
        local choices = {STRINGS:FormatKey('CAFE_OPTION_DRINK'),
                         STRINGS:FormatKey('CAFE_OPTION_BUY'),
                         STRINGS:FormatKey('CAFE_OPTION_CRAFT'),
                         STRINGS:FormatKey("MENU_INFO"),
                         STRINGS:FormatKey("MENU_EXIT")}
        if plot.data.craft_pools  < 1 then table.remove(choices, 3) end
        if plot.data.daily_amount < 1 then table.remove(choices, 2) end
        UI:BeginChoiceMenu(msg, choices, 1, #choices)
        UI:WaitForChoice()
        msg = STRINGS:FormatKey('CAFE_REPEAT')

        local result = UI:ChoiceResult()
        if plot.data.daily_amount < 1 and result >= 2 then result = result + 1 end
        if plot.data.craft_pools  < 1 and result >= 3 then result = result + 1 end

        if result == 1 then
            if COMMON_FUNC.CheckMoney(plot.data.price, true) then
                local loop = true
                while loop do
                    UI:WaitShowDialogue(STRINGS:FormatKey("CAFE_DRINK_WHO"))
                    local member = TeamSelectMenu.runPartyMenu()
                    if member then
                        local loop2 = true --the long-awaited sequel
                        while loop2 do
                            local max_choices = GAME:GetPlayerBagLimit()
                            if plot.data.price>0 then
                                max_choices = COMMON_FUNC.GetMoney(true)//plot.data.price
                                UI:WaitShowDialogue(STRINGS:FormatKey("CAFE_DRINK_WHAT", STRINGS:FormatKey("MONEY_AMOUNT", plot.data.price), STRINGS:LocalKeyString(26)))
                            else
                                UI:WaitShowDialogue(STRINGS:FormatKey("CAFE_DRINK_WHAT_FREE", STRINGS:LocalKeyString(26)))
                            end

                            local boost_tbl = {}
                            for i=1, plot.data.boost_pools, 1 do
                                table.merge(boost_tbl, _SHOP.CafeTables.boost_table[i])
                            end
                            local cart = JuiceMenu.run(member, boost_tbl, true, function(cart, char, tbl) return _SHOP.CafeGetTotalBoost(plot, cart, char, tbl) end, max_choices)
                            if #cart > 0 then
                                local items = {}
                                for _, slot in pairs(cart) do table.insert(items, COMMON_FUNC.InvItemFromInvSlot(slot)) end
                                local price = plot.data.price*#cart
                                local ch
                                if price > 0 then
                                    if #cart == 1 then
                                        local name = items[1]:GetDisplayName()
                                        UI:ChoiceMenuYesNo(STRINGS:FormatKey('CAFE_DRINK_ONE', STRINGS:FormatKey("MONEY_AMOUNT", price), name), false)
                                    else
                                        UI:ChoiceMenuYesNo(STRINGS:FormatKey('CAFE_DRINK_MULTI', STRINGS:FormatKey("MONEY_AMOUNT", price)), false)
                                    end
                                    UI:WaitForChoice()
                                    ch = UI:ChoiceResult()
                                else
                                    ch = true
                                end

                                if ch then
                                    local total_boost = _SHOP.CafeGetTotalBoost(plot, cart, member, boost_tbl)

                                    for ii = #cart, 1, -1 do
                                        if cart[ii].IsEquipped then GAME:TakePlayerEquippedItem(cart[ii].Slot, true)
                                        else GAME:TakePlayerBagItem(cart[ii].Slot, true) end
                                    end

                                    UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_DRINK_BEGIN'))
                                    SOUND:PlayBattleSE("DUN_Drink")
                                    UI:ResetSpeaker(false)
                                    UI:SetCenter(true)
                                    COMMON_FUNC.RemoveMoney(price, true)
                                    UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_DRINK_DRINK', member:GetDisplayName(true)))
                                    _SHOP.CafeApplyBoosts(total_boost, member)
                                    UI:SetCenter(false)
                                    UI:SetSpeaker(npc)
                                    loop, loop2 = false, false
                                end
                            else
                                loop2 = false
                            end
                        end
                    else
                        loop = false
                    end
                end
            else
                UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_NO_MONEY_MIN', STRINGS:FormatKey("MONEY_AMOUNT", plot.data.price)))
            end
        elseif result == 2 then
            if #plot.data.iotd > 0 then
                ---@type {Item:InvItem,Price:integer}
                local catalog = { }
                for i = 1, #plot.data.iotd, 1 do
                    local entry = plot.data.iotd[i]
                    local item_data = { Item = RogueEssence.Dungeon.InvItem(entry.Item, false, 0), Price = entry.Price }
                    table.insert(catalog, item_data)
                end
                local loop = true
                while loop do
                    local chosen = SmallShopMenu.run(STRINGS:FormatKey("MENU_SHOP_TITLE"), catalog)
                    if chosen > 0 then
                        if not COMMON_FUNC.CheckMoney(catalog[chosen].Price) then
                            UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_NO_MONEY'))
                        else
                            local name = catalog[chosen].Item:GetDisplayName()
                            UI:ChoiceMenuYesNo(STRINGS:FormatKey('CAFE_DAILY_BUY', name, STRINGS:FormatKey("MONEY_AMOUNT", catalog[chosen].Price)), false)

                            UI:WaitForChoice()
                            local ch = UI:ChoiceResult()
                            if ch then
                                COMMON_FUNC.RemoveMoney(catalog[chosen].Price, true)
                                GAME:GivePlayerItem(catalog[chosen].Item.ID, catalog[chosen].Item.Amount, false)
                                table.remove(catalog, chosen)
                                table.remove(plot.data.iotd, chosen)

                                SOUND:PlaySE("Battle/DUN_Money")
                                UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_DAILY_BUY_END'))
                                if #plot.data.iotd > 0 then
                                    UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_DAILY_BUY_CONTINUE'))
                                else
                                    loop = false
                                end
                            end
                        end
                    else
                        loop = false
                    end
                end
            else
                UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_OUT_OF_STOCK'))
            end
        elseif result == 3 then
            local recipes = { }
            for i=1, plot.data.craft_pools, 1 do table.merge(recipes, _SHOP.CafeTables.crafts[i]) end

            UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_CRAFT_BEGIN'))
            local loop = true
            while loop do
                local chosen, crafts = CraftingMenu.run(recipes)
                if chosen and crafts>0 then
                    local result_amount = chosen.Amount or 1
                    local result_str = COMMON_FUNC.PrintItemAmount(chosen.Item, result_amount*crafts, true)
                    UI:ChoiceMenuYesNo(STRINGS:FormatKey('CAFE_CRAFT_ASK', result_str), false)
                    UI:WaitForChoice()
                    if UI:ChoiceResult() then
                        GAME:WaitFrames(15)
                        SOUND:PlayBattleSE('DUN_Drink')
                        for _, item in ipairs(chosen.ReqItems) do
                            local id = ""
                            local amount = 1
                            if type(item) == "table" then id, amount = item[1], item[2]
                            else id = item end
                            COMMON_FUNC.RemoveItem(id, amount*crafts, true)
                        end
                        GAME:GivePlayerItem(chosen.Item, result_amount*crafts)
                        GAME:WaitFrames(60)

                        UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_CRAFT_END'))
                        UI:ResetSpeaker(false)
                        UI:SetCenter(true)
                        SOUND:PlaySE("Fanfare/Item")
                        UI:WaitShowDialogue(STRINGS:FormatKey('RECEIVE_ITEM_MESSAGE', result_str))
                        UI:SetCenter(false)
                        UI:SetSpeaker(npc)
                        UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_CRAFT_CONTINUE'))
                    end
                else
                    loop = false
                end
            end
        elseif result == 4 then
            local can_sell = _HUB.getPlotLevel(plot) >= 2
            local can_craft = _HUB.getPlotLevel(plot) >= 4
            UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_INFO_1'))
            UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_INFO_2'))
            if can_craft then UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_INFO_3')) end
            if can_craft then
                if _SHOP.CafeTables.daily_amount[_HUB.getPlotLevel(plot)] == 1 then UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_INFO_4'))
                else UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_INFO_4b')) end
            end
            if can_sell then UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_INFO_5'))
            elseif can_craft then UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_INFO_5b'))
            elseif _HUB.getPlotLevel(plot) < 10 then UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_INFO_5c')) end
        else
            UI:WaitShowDialogue(STRINGS:FormatKey('CAFE_BYE'))
            exit = true
        end
    end
end

---Calculates the boost to be added to a character
---@param plot CafePlot the plot's data structure
---@param cart InvSlot the items to be used
---@param member Character the character to apply the boosts to
---@param boost_table table the boost table at the top of this file
---@return CafeTotalBoosts, integer #a table containing all the boosts that should be applied to the character, and the number of boost points that will be randomly assigned.
function _SHOP.CafeGetTotalBoost(plot, cart, member, boost_table)
    local boost_tbl = boost_table or {}
    if #boost_tbl == 0 then
        for i=1, plot.data.boost_pools, 1 do table.merge(boost_tbl, _SHOP.CafeTables.boost_table[i]) end
    end

    local playerMonId = member.BaseForm
    local mon = _DATA:GetMonster(playerMonId.Species)
    local form = mon.Forms[playerMonId.Form]

    local total_boost = { HP = 0, Atk = 0, Def = 0, SpAtk = 0, SpDef = 0, Speed = 0 }
    local random_data = {}
    local random_amount = 0

    local negate_a = false
    local negate_b = false
    local negate_c = false

    for ii = 1, #cart, 1 do
        local item
        if cart[ii].IsEquipped then item = GAME:GetPlayerEquippedItem(cart[ii].Slot)
        else item = GAME:GetPlayerBagItem(cart[ii].Slot) end
        local boost = boost_tbl[item.ID]

        if boost ~= nil then
            if boost.GummiEffect ~= nil then

                local matchup = PMDC.Dungeon.PreTypeEvent.CalculateTypeMatchup(boost.GummiEffect, form.Element1)
                matchup = matchup + PMDC.Dungeon.PreTypeEvent.CalculateTypeMatchup(boost.GummiEffect, form.Element2)

                local main_stat = ""
                if boost.HP ~= nil then    main_stat = "HP" end
                if boost.Atk ~= nil then   main_stat = "Atk" end
                if boost.Def ~= nil then   main_stat = "Def" end
                if boost.SpAtk ~= nil then main_stat = "SpAtk" end
                if boost.SpDef ~= nil then main_stat = "SpDef" end
                if boost.Speed ~= nil then main_stat = "Speed" end

                local stats = {}

                local main_boost = 0
                local all_boost = 0


                if boost.GummiEffect == form.Element1 or boost.GummiEffect == form.Element2 then
                    main_boost = 2
                    all_boost = 1

                    table.insert(stats, "HP")
                    table.insert(stats, "Atk")
                    table.insert(stats, "Def")
                    table.insert(stats, "SpAtk")
                    table.insert(stats, "SpDef")
                    table.insert(stats, "Speed")
                elseif matchup >= PMDC.Dungeon.PreTypeEvent.S_E_2 then
                    main_boost = 2
                    all_boost = 1

                    local top_stats = {}
                    if main_stat ~= "HP" then table.insert(top_stats, { RogueEssence.Data.Stat.HP, "HP"}) end
                    if main_stat ~= "Atk" then table.insert(top_stats, { RogueEssence.Data.Stat.Attack, "Atk"}) end
                    if main_stat ~= "Def" then table.insert(top_stats, { RogueEssence.Data.Stat.Defense, "Def"}) end
                    if main_stat ~= "SpAtk" then table.insert(top_stats, { RogueEssence.Data.Stat.MAtk, "SpAtk"}) end
                    if main_stat ~= "SpDef" then table.insert(top_stats, { RogueEssence.Data.Stat.MDef, "SpDef"}) end
                    if main_stat ~= "Speed" then table.insert(top_stats, { RogueEssence.Data.Stat.Speed, "Speed"}) end

                    table.sort(top_stats, function(a, b) return form:GetBaseStat(a[1]) > form:GetBaseStat(b[1]) end)

                    table.insert(stats, top_stats[1][2])
                    table.insert(stats, top_stats[2][2])
                    table.insert(stats, main_stat)
                elseif matchup == PMDC.Dungeon.PreTypeEvent.NRM_2 then
                    main_boost = 2
                    all_boost = 0
                    table.insert(stats, main_stat)
                elseif matchup > PMDC.Dungeon.PreTypeEvent.N_E_2 then
                    main_boost = 1
                    all_boost = 0
                    table.insert(stats, main_stat)
                end

                for _, stat in ipairs(stats) do
                    if stat == main_stat then total_boost[stat] = total_boost[stat] + main_boost
                    else total_boost[stat] = total_boost[stat] + all_boost end
                end
            else
                if boost.HP ~= nil then total_boost.HP = total_boost.HP + boost.HP end
                if boost.Atk ~= nil then total_boost.Atk = total_boost.Atk + boost.Atk end
                if boost.Def ~= nil then total_boost.Def = total_boost.Def + boost.Def end
                if boost.SpAtk ~= nil then total_boost.SpAtk = total_boost.SpAtk + boost.SpAtk end
                if boost.SpDef ~= nil then total_boost.SpDef = total_boost.SpDef + boost.SpDef end
                if boost.Speed ~= nil then total_boost.Speed = total_boost.Speed + boost.Speed end
            end

            if boost.NegateStatA then negate_a = true end
            if boost.NegateStatB then negate_b = true end
            if boost.NegateStatC then negate_c = true end
            if boost.Rand ~= nil then
                table.insert(random_data, boost.Rand)
                random_amount = random_amount + ((boost.Rand.Amount * boost.Rand.Rolls) or 0)
            end
        end
    end

    if negate_a and negate_b and negate_c then
        total_boost.HP = -256
        total_boost.Atk = -256
        total_boost.Def = -256
        total_boost.SpAtk = -256
        total_boost.SpDef = -256
        total_boost.Speed = -256
        random_data = {}
    elseif negate_a or negate_b or negate_c then
        total_boost.HP = total_boost.HP * -1
        total_boost.Atk = total_boost.Atk * -1
        total_boost.Def = total_boost.Def * -1
        total_boost.SpAtk = total_boost.SpAtk * -1
        total_boost.SpDef = total_boost.SpDef * -1
        total_boost.Speed = total_boost.Speed * -1
        random_amount = random_amount * -1
    end

    local ret = {
        boosts = total_boost,
        random = random_data,
        reverse_random = negate_a or negate_b or negate_c
    }

    return ret, random_amount
end

---Applies a list of boosts to the given character 
---@param boost_data CafeTotalBoosts a table containing the boosts to apply
---@param member Character the character to apply the boost to
function _SHOP.CafeApplyBoosts(boost_data, member)
    local boost = boost_data.boosts

    local random_mult = 1
    if boost_data.reverse_random then random_mult = -1 end
    local all_stats = {"HP",         "Atk",      "Def",      "SpAtk",     "SpDef",     "Speed"}
    local mem_stats = {"MaxHPBonus", "AtkBonus", "DefBonus", "MAtkBonus", "MDefBonus", "SpeedBonus"}
    local max_boost = PMDC.Data.MonsterFormData.MAX_STAT_BOOST
    if member.SpeedBonus + boost.Speed > max_boost then table.remove(all_stats, 6) end --discard maxed stats
    if member.MDefBonus  + boost.SpDef > max_boost then table.remove(all_stats, 5) end
    if member.MAtkBonus  + boost.SpAtk > max_boost then table.remove(all_stats, 4) end
    if member.DefBonus   + boost.Def   > max_boost then table.remove(all_stats, 3) end
    if member.AtkBonus   + boost.Atk   > max_boost then table.remove(all_stats, 2) end
    if member.MaxHPBonus + boost.HP    > max_boost then table.remove(all_stats, 1) end
    for _, rand in ipairs(boost_data.random) do
        local stats = {}
        local amount = 0
        local rolls = 0
        for key, value in pairs(rand) do
            local index = table.index_of(all_stats, key)
            if index and member[mem_stats[index]] + boost[all_stats[index]] < max_boost then
                table.insert(stats, key)
            elseif key == "Amount" then amount = value --[[@as integer]]
            elseif key == "Rolls" then rolls = value --[[@as integer]] end
        end
        for _=1, rolls, 1 do
            local stat = COMMON_FUNC.WeightlessRoll(stats)
            boost[stat] = boost[stat] + (amount * random_mult)
        end
    end

    local any_boost = false
    local changed_stats = {}
    local changed_amounts = {}
    local any_stat_boosted = false
    local any_stat_dropped = false

    local old_level = member.Level
    local old_hp = member.MaxHP
    local old_atk = member.BaseAtk
    local old_def = member.BaseDef
    local old_sp_atk = member.BaseMAtk
    local old_sp_def = member.BaseMDef
    local old_speed = member.BaseSpeed

    if boost.HP ~= 0 then
        member.MaxHPBonus = math.max(0, math.min(member.MaxHPBonus + boost.HP, max_boost))
        local diff = member.MaxHP - old_hp
        if diff > 0 then
            table.insert(changed_stats, RogueEssence.Data.Stat.HP)
            table.insert(changed_amounts, diff)
            any_stat_boosted = true
        elseif diff < 0 then
            table.insert(changed_stats, RogueEssence.Data.Stat.HP)
            table.insert(changed_amounts, diff)
            any_stat_dropped = true
        end
    end
    if boost.Atk ~= 0 then
        member.AtkBonus = math.max(0, math.min(member.AtkBonus + boost.Atk, max_boost))
        local diff = member.BaseAtk - old_atk
        if diff > 0 then
            table.insert(changed_stats, RogueEssence.Data.Stat.Attack)
            table.insert(changed_amounts, diff)
            any_stat_boosted = true
        elseif diff < 0 then
            table.insert(changed_stats, RogueEssence.Data.Stat.Attack)
            table.insert(changed_amounts, diff)
            any_stat_dropped = true
        end
    end
    if boost.Def ~= 0 then
        member.DefBonus = math.max(0, math.min(member.DefBonus + boost.Def, max_boost))
        local diff = member.BaseDef - old_def
        if diff > 0 then
            table.insert(changed_stats, RogueEssence.Data.Stat.Defense)
            table.insert(changed_amounts, diff)
            any_stat_boosted = true
        elseif diff < 0 then
            table.insert(changed_stats, RogueEssence.Data.Stat.Defense)
            table.insert(changed_amounts, diff)
            any_stat_dropped = true
        end
    end
    if boost.SpAtk ~= 0 then
        member.MAtkBonus = math.max(0, math.min(member.MAtkBonus + boost.SpAtk, max_boost))
        local diff = member.BaseMAtk - old_sp_atk
        if diff > 0 then
            table.insert(changed_stats, RogueEssence.Data.Stat.MAtk)
            table.insert(changed_amounts, diff)
            any_stat_boosted = true
        elseif diff < 0 then
            table.insert(changed_stats, RogueEssence.Data.Stat.MAtk)
            table.insert(changed_amounts, diff)
            any_stat_dropped = true
        end
    end
    if boost.SpDef ~= 0 then
        member.MDefBonus = math.max(0, math.min(member.MDefBonus + boost.SpDef, max_boost))
        local diff = member.BaseMDef - old_sp_def
        if diff > 0 then
            table.insert(changed_stats, RogueEssence.Data.Stat.MDef)
            table.insert(changed_amounts, diff)
            any_stat_boosted = true
        elseif diff < 0 then
            table.insert(changed_stats, RogueEssence.Data.Stat.MDef)
            table.insert(changed_amounts, diff)
            any_stat_dropped = true
        end
    end
    if boost.Speed ~= 0 then
        member.SpeedBonus = math.max(0, math.min(member.SpeedBonus + boost.Speed, max_boost))
        local diff = member.BaseSpeed - old_speed
        if diff > 0 then
            table.insert(changed_stats, RogueEssence.Data.Stat.Speed)
            table.insert(changed_amounts, diff)
            any_stat_boosted = true
        elseif diff < 0 then
            table.insert(changed_stats, RogueEssence.Data.Stat.Speed)
            table.insert(changed_amounts, diff)
            any_stat_dropped = true
        end
    end

    if any_stat_boosted then
        if #changed_stats > 1 then
            --increase sound?
            UI:WaitShowDialogue(STRINGS:Format(RogueEssence.StringKey("MSG_STAT_BOOST_MULTI"):ToLocal(), member:GetDisplayName(true)))
            UI:SetCustomMenu(RogueEssence.Menu.LevelUpMenu(member, old_level, old_hp, old_speed, old_atk, old_def, old_sp_atk, old_sp_def))
            UI:WaitForChoice()
        else
            --increase sound?
            UI:WaitShowDialogue(STRINGS:Format(RogueEssence.StringKey("MSG_STAT_BOOST"):ToLocal(), member:GetDisplayName(true), RogueEssence.Text.ToLocal(changed_stats[1], nil), changed_amounts[1]))
        end
        any_boost = true
    elseif any_stat_dropped then
        if #changed_stats > 1 then
            --drop sound?
            UI:WaitShowDialogue(STRINGS:Format(RogueEssence.StringKey("MSG_STAT_DROP_MULTI"):ToLocal(), member:GetDisplayName(true)))
            UI:SetCustomMenu(RogueEssence.Menu.LevelUpMenu(member, old_level, old_hp, old_speed, old_atk, old_def, old_sp_atk, old_sp_def))
            UI:WaitForChoice()
        else
            --drop sound?
            UI:WaitShowDialogue(STRINGS:Format(RogueEssence.StringKey("MSG_STAT_DROP"):ToLocal(), member:GetDisplayName(true), RogueEssence.Text.ToLocal(changed_stats[1], nil), changed_amounts[1] * -1))
        end
        any_boost = true
    end

    if not any_boost then
        UI:WaitShowDialogue(STRINGS:FormatKey("CAFE_DRINK_NO_BOOST", member:GetDisplayName(true)))
    end
end

---Returns the description that will be used for this shop in the office menu.
---@param plot CafePlot the plot's data structure
---@return string #the plot's description
function _SHOP.CafeGetDescription(plot)
    local boost_string_maker_index = {1, 3, 4}
    local boost_string_elements = {STRINGS:FormatKey("CAFE_POOL_NAME_GUMMIES"), STRINGS:FormatKey("CAFE_POOL_NAME_BERRIES"), STRINGS:FormatKey("CAFE_POOL_NAME_SEEDS"), STRINGS:FormatKey("CAFE_POOL_NAME_MEDICINES")}
    local boost_string_list = {}
    if plot.data.boost_pools > #boost_string_maker_index then boost_string_list = {STRINGS:FormatKey("CAFE_POOL_NAME_ANY_FOOD")} else
    for i = 1, boost_string_maker_index[plot.data.boost_pools], 1 do table.insert(boost_string_list, boost_string_elements[i]) end end
    local description = STRINGS:FormatKey("PLOT_DESCRIPTION_CAFE_BASE", COMMON_FUNC.BuildStringWithSeparators(boost_string_list))

    if plot.data.daily_amount > 1 then
        description = description..STRINGS:FormatKey("PLOT_DESCRIPTION_CAFE_DAILY_MORE", plot.data.daily_amount)
    elseif plot.data.daily_amount == 1 then
        description = description..STRINGS:FormatKey("PLOT_DESCRIPTION_CAFE_DAILY_ONE")
    end

    if plot.data.craft_pools > 0 then
        local craft_elements = {STRINGS:FormatKey("CAFE_POOL_NAME_GUMMIES"), STRINGS:FormatKey("CAFE_POOL_NAME_MEDICINES"), STRINGS:FormatKey("CAFE_POOL_NAME_OTHERS")}
        local craft_string_list = {}
        for i = 1, plot.data.craft_pools, 1 do table.insert(craft_string_list, craft_elements[i]) end
        description = description..STRINGS:FormatKey("PLOT_DESCRIPTION_CAFE_CRAFT", craft_string_list)
    end
    return description
end

_SHOP.callbacks.initialize["cafe"] =   _SHOP.CafeInitializer
_SHOP.callbacks.upgrade_flow["cafe"] = _SHOP.CafeUpgradeFlow
_SHOP.callbacks.upgrade["cafe"] =      _SHOP.CafeUpgrade
_SHOP.callbacks.endOfDay["cafe"] =     _SHOP.CafeUpdate
_SHOP.callbacks.interact["cafe"] =     _SHOP.CafeInteract
_SHOP.callbacks.description["cafe"] =  _SHOP.CafeGetDescription