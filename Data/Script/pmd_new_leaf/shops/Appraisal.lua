--[[
    Appraisal.lua TODO barely even tested ALSO add 1*  item swap

    Allows the player to sell items, albeit over time.
    This file contains all appraisal-specific callbacks and functionality data structures
]]
require 'pmd_new_leaf.menu.AppraisalMenu'
require 'pmd_new_leaf.menu.office.ShopUpgradeMenu'
require 'origin.menu.InventorySelectMenu'

---@alias AppraisalPlot {unlocked:boolean,building:BuildingID,upgrades:UpgradeEntry,shopkeeper:ShopkeeperData,shopkeeper_shiny:boolean,data:AppraisalData,empty:integer}
---@alias AppraisalData {stock:AppraisalEntry[],specializations:table<string,boolean>,opened:integer,slots:integer,checks:integer,reduce_all:boolean,instant_open:boolean}
---@alias AppraisalEntry BoxEntry|TreasureEntry
---@alias BoxEntry {item:InvItemLua,state:integer,open_at:integer}
---@alias TreasureEntry {item:InvItemLua,opened:boolean}

_SHOP.AppraisalTables = {
    -- level  1  2  3  4  5   6   7   8   9  10
    slots  = {4, 6, 6, 8, 8, 10, 12, 12, 14, 16},
    checks = {3, 3, 4, 4, 5,  5,  6,  7,  7,  8},
    durability_table = {
        box_light = 1,
        box_cute =  2,
        box_nifty = 2,
        box_heavy = 5,
        box_pretty = 3,
        box_hard = 7,
        box_dainty = 3,
        box_glittery = 4,
        box_gorgeous = 8,
        box_deluxe = 6,
        box_shiny = 4,
        box_sinister = 4
    },
    stack_roll = {
        loot_building_tools = 4,
        loot_building_tools_uncommon = 3,
        loot_building_tools_rare = 2,
        loot_wish_fragment = 5
    },
    upgrade_order = {"upgrade_appraisal_cute",     "upgrade_appraisal_nifty",    "upgrade_appraisal_heavy",
                     "upgrade_appraisal_shiny",    "upgrade_appraisal_sinister", "upgrade_appraisal_pretty",
                     "upgrade_appraisal_hard",     "upgrade_appraisal_dainty",   "upgrade_appraisal_glittery",
                     "upgrade_appraisal_gorgeous", "upgrade_appraisal_deluxe"}
}

---Initializes an appraisal shop's specific data
---@param plot AppraisalPlot the plot's data structure
function _SHOP.AppraisalInitializer(plot)
    plot.data = {
        stock = {},
        specializations = {},
        opened = 0,
        slots = 0,
        checks = 0,
        reduce_all = false,
        instant_open = false
    }
end

---Runs the upgrade flow for the specified appraisal shop, letting the player choose which upgrades to apply
---@param plot AppraisalPlot the plot's data structure
---@param index integer the plot index number
---@param shop_id? BuildingID a building id. It is only considered if no building exists in the given plot yet
---@return string|false #an upgrade to apply, or false if none was chosen
function _SHOP.AppraisalUpgradeFlow(plot, index, shop_id)
    local level = _HUB.getPlotLevel(plot)
    local upgrade = ""

    local up_start
    local loop = true
    while loop do
        if level%2 == 0 then
            upgrade = "upgrade_appraisal_base"
        else
            local tree, keys = _SHOP.MakeUpgradeTree(index, level+1, shop_id)
            local comp = function(a,b)
                for _, elem in ipairs(_SHOP.AppraisalTables.upgrade_order) do
                    if elem == a then return true
                    elseif elem == b then return false end
                end
                return false
            end
            table.sort(keys, function(a, b) return comp(a, b) end)

            upgrade, up_start = ShopUpgradeMenu.run(tree, keys, index, up_start)
            if upgrade == "exit" then return false end
        end
        local curr = plot.upgrades[upgrade] or 0
        local cost = _SHOP.GetUpgradeCost(upgrade, curr+1)
        if COMMON_FUNC.CheckCost(cost, true) then
            local func = function(entry) return COMMON_FUNC.PrintItemAmount(entry.item, entry.amount) end
            local cost_string = COMMON_FUNC.BuildStringWithSeparators(cost, func)
            if level == 0 then UI:ChoiceMenuYesNo(STRINGS:FormatKey("OFFICE_BUILD_ASK", STRINGS:FormatKey("SHOP_OPTION_APPRAISAL"), cost_string))
            else UI:ChoiceMenuYesNo(STRINGS:FormatKey("OFFICE_UPGRADE_ASK", STRINGS:FormatKey("SHOP_OPTION_APPRAISAL"), cost_string)) end
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
        if level%2 == 0 then return false end
    end
end

---Checks if the supplied upgrade is valid, and updates the plot's data structure accordingly if it is.
---@param plot AppraisalPlot the plot's data structure
---@param upgrade string an upgrade id
function _SHOP.AppraisalUpgrade(plot, upgrade)
    local level = _HUB.getPlotLevel(plot)
    local chest

    if string.match(upgrade, "^upgrade_appraisal") then
        if level%2 == 0 then
            if upgrade ~= "upgrade_appraisal_base" then return end
        else
            if string.match(upgrade, "cute") then
                chest = "box_cute"
            elseif string.match(upgrade, "nifty") then
                chest = "box_nifty"
            elseif string.match(upgrade, "heavy") then
                chest = "box_heavy"
            elseif string.match(upgrade, "pretty") then
                chest = "box_pretty"
            elseif string.match(upgrade, "hard") then
                chest = "box_hard"
            elseif string.match(upgrade, "dainty") then
                chest = "box_dainty"
            elseif string.match(upgrade, "glittery") then
                chest = "box_glittery"
            elseif string.match(upgrade, "gorgeous") then
                chest = "box_gorgeous"
            elseif string.match(upgrade, "deluxe") then
                chest = "box_deluxe"
            elseif string.match(upgrade, "shiny") then
                chest = "box_shiny"
            elseif string.match(upgrade, "sinister") then
                chest = "box_sinister"
            else
                return
            end
        end
    end

    if level<10 then
        _SHOP.ConfirmShopUpgrade(plot, upgrade)
        level = _HUB.getPlotLevel(plot)
    else return end

    if chest then plot.data.specializations[chest] = true end
    plot.data.slots =  _SHOP.AppraisalTables.slots[level]
    plot.data.checks = _SHOP.AppraisalTables.checks[level]

    if level == 5 then
        plot.data.reduce_all = true
    elseif level == 10 then
        plot.data.instant_open = true
    end
end

---Updates the appraisal counters for the stocked chests
---@param plot AppraisalPlot the plot's data structure
function _SHOP.AppraisalUpdate(plot)
    local stock = plot.data.stock

    if plot.data.instant_open and math.random(1,4) == 1 then
        local eligible = {}
        for i, item in stock do
            local checks_left = item.open_at - item.state
            if checks_left < 7 then
                table.insert(eligible, {Index = i, Weight =  7 - checks_left})
            end
        end
        if #eligible > 0 then
            local opened = COMMON_FUNC.WeightedRoll(eligible) --[[@as {Index:integer,Weight:integer}]]
            stock[opened.Index] = {_SHOP.AppraisalGetTreasure(stock[opened.Index]), opened = true}
            plot.data.opened = plot.data.opened + 1
        end
    end

    for _ = 1, plot.data.checks, 1 do
        if #stock == 0 then break end
        local entry, index = COMMON_FUNC.WeightlessRoll(stock)
        ---@cast index integer
        local ticks = 1
        if plot.data.specializations[entry.item.ID] and math.random(1, 2) == 1 then ticks = 2 end
        for _=1, ticks, 1 do
            if entry.state < entry.open_at-1 then
                entry.state = entry.state+1
            else
                stock[index] = {_SHOP.AppraisalGetTreasure(entry), opened = true}
                plot.data.opened = plot.data.opened + 1
                break
            end
        end
    end
end

---Runs the interact flow for the given appraisal shop, letting the player interact with it
---@param plot AppraisalPlot the plot's data structure
---@param index integer the plot index number
function _SHOP.AppraisalInteract(plot, index)
    local price = 150
    local npc = CH("NPC_"..index)
    UI:SetSpeaker(npc)
    local msg = STRINGS:FormatKey('APPRAISAL_INTRO', npc:GetDisplayName())
    local exit = false
    while not exit do
        local choices = {STRINGS:FormatKey('APPRAISAL_OPTION_MANAGE'),
                         STRINGS:FormatKey("MENU_INFO"),
                         STRINGS:FormatKey("MENU_EXIT")}
        UI:BeginChoiceMenu(msg, choices, 1, 3)
        UI:WaitForChoice()

        msg = STRINGS:FormatKey('APPRAISAL_REPEAT')

        local result = UI:ChoiceResult()
        if result == 1 then
            local loop = true
            while loop do
                local choice = AppraisalMenu.run(plot.data)
                if not choice then
                    loop = false
                elseif choice > 0 then
                    local entry = plot.data.stock[choice]
                    UI:ResetSpeaker(false)
                    UI:SetCenter(true)
                    SOUND:PlaySE("Fanfare/Item")
                    UI:WaitShowDialogue(STRINGS:FormatKey('RECEIVE_ITEM_MESSAGE', COMMON_FUNC.TblToInvItem(entry.item):GetDisplayName()))
                    GAME:GivePlayerItem(entry.item)
                    table.remove(plot.data.stock, choice)
                    UI:SetCenter(false)
                    UI:SetSpeaker(npc)
                else
                    UI:WaitShowDialogue(STRINGS:FormatKey('APPRAISAL_DEPOSIT', STRINGS:FormatKey("MONEY_AMOUNT", price), STRINGS:LocalKeyString(26)))
                    while loop do
                        local filter = function(slot)
                            local item
                            if slot.IsEquipped then item = _DATA.Save.ActiveTeam.Players[slot.Slot].EquippedItem
                            else item = _DATA.Save.ActiveTeam:GetInv(slot.Slot) end
                            return item.UsageType == RogueEssence.Data.ItemData.UseType.Box
                        end
                        local choosable = math.min(plot.data.slots - #plot.data.stock, COMMON_FUNC.GetMoney(true)//price)
                        local items = InventorySelectMenu.run(STRINGS:FormatKey('MENU_ITEM_TITLE'), filter, STRINGS:FormatKey('MENU_ITEM_GIVE'), true, choosable)
                        if #items > 0 then
                            local full_cost = price*#items
                            UI:WaitShowDialogue(STRINGS:FormatKey('APPRAISAL_PAYMENT'), full_cost)
                            if #items > 1 then
                                UI:ChoiceMenuYesNo(STRINGS:FormatKey('APPRAISAL_CONFIRM_GIVE_MANY'), price)
                            else
                                local item_slot = items[1]
                                local item
                                if item_slot.IsEquipped then
                                    item = _DATA.Save.ActiveTeam.Players[item_slot.Slot].EquippedItem
                                else
                                    item = _DATA.Save.ActiveTeam:GetInv(item_slot.Slot)
                                end
                                UI:ChoiceMenuYesNo(STRINGS:FormatKey('APPRAISAL_CONFIRM_GIVE_ONE', price, item:GetDisplayName()))
                            end

                            UI:WaitForChoice()
                            local ch = UI:ChoiceResult()
                            if ch then
                                COMMON_FUNC.RemoveMoney(full_cost, true)
                                _SHOP.AppraisalAddToStock(plot, items)
                                UI:WaitShowDialogue(STRINGS:FormatKey('APPRAISAL_CONFIRM'))
                                if #items == 1 and GAME:GetPlayerBagCount() + GAME:GetPlayerEquippedCount() > 0 and plot.data.slots - #plot.data.stock > 0 then --TODO add checks to Exporter too
                                    UI:WaitShowDialogue(STRINGS:FormatKey('APPRAISAL_CONTINUE'))
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
            UI:WaitShowDialogue(STRINGS:FormatKey('APPRAISAL_INFO_1'))
            UI:WaitShowDialogue(STRINGS:FormatKey('APPRAISAL_INFO_2'))
            UI:WaitShowDialogue(STRINGS:FormatKey('APPRAISAL_INFO_3'))
            if _HUB.getPlotLevel(plot) < 10 then
                UI:WaitShowDialogue(STRINGS:FormatKey('APPRAISAL_INFO_4'))
            end
        else
            UI:WaitShowDialogue(STRINGS:FormatKey('APPRAISAL_BYE'))
            exit = true
        end
    end
end

---Adds a list of items to the given shop's stock.
---@param plot AppraisalPlot the plot's data structure
---@param items InvSlot[] InvSlots pointing to the items to store
function _SHOP.AppraisalAddToStock(plot, items)
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
        local checks_required = _SHOP.AppraisalTables.durability_table[item.ID] or 10
        local entry = {item = COMMON_FUNC.InvItemToTbl(item), state = 0, open_at = checks_required}
        table.insert(plot.data.stock, entry)
    end
end

---Returns the description that will be used for this shop in the office menu.
---@param plot AppraisalPlot the plot's data structure
---@return string #the plot's description
function _SHOP.AppraisalGetDescription(plot)
    local description = STRINGS:FormatKey("PLOT_DESCRIPTION_APPRAISAL_BASE", plot.data.slots, plot.data.checks)
    local specs = table.get_keys(plot.data.specializations)
    if #specs>0 then
        local func = function(spec) return _DATA:GetItem(spec):GetDisplayName() end
        local str = COMMON_FUNC.BuildStringWithSeparators(specs, func)
        description = description..STRINGS:FormatKey("PLOT_DESCRIPTION_APPRAISAL_SPECS", str)
    end
    if plot.data.reduce_all then description = description..STRINGS:FormatKey("PLOT_DESCRIPTION_APPRAISAL_BOOST") end
    if plot.data.instant_open then description = description..STRINGS:FormatKey("PLOT_DESCRIPTION_APPRAISAL_INSTANT") end
    return description
end

---Given an appraisal entry, it converts it into an opened treasure entry. If the supplied entry was already opened, it returns it directly
---@param entry AppraisalEntry an appraisal entry
---@return TreasureEntry #the opened treasure entry
function _SHOP.AppraisalGetTreasure(entry)
    if entry.opened then return entry --[[@as TreasureEntry]] end
    local box = entry.item
    local treasure_item = box.HiddenValue
    if not treasure_item or treasure_item == "" then treasure_item = "seed_plain" end
    local itemEntry = _DATA:GetItem(treasure_item)
    local stack = itemEntry.MaxStack
    local roll = _SHOP.AppraisalTables.stack_roll[treasure_item]
    if roll then stack = math.min(math.random(roll), stack) end
    ---@type InvItemLua
    local newItem = {ID=treasure_item, Cursed = false, HiddenValue = "", Amount = stack, Price = 0}
    return {item = newItem, opened = true}
end

_SHOP.callbacks.initialize["appraisal"] =   _SHOP.AppraisalInitializer
_SHOP.callbacks.upgrade_flow["appraisal"] = _SHOP.AppraisalUpgradeFlow
_SHOP.callbacks.upgrade["appraisal"] =      _SHOP.AppraisalUpgrade
_SHOP.callbacks.endOfDay["appraisal"] =     _SHOP.AppraisalUpdate
_SHOP.callbacks.interact["appraisal"] =     _SHOP.AppraisalInteract
_SHOP.callbacks.description["appraisal"] =  _SHOP.AppraisalGetDescription