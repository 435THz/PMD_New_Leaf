--[[
    A set of various scripting routines that can be useful pretty much anywhere
]]
COMMON_FUNC = {}
require 'pmd_new_leaf.CommonBattle'
------------------------------------------- TODO remove if empty at the end of the project
--region Logic
-------------------------------------------

-------------------------------------------
--region Math
-------------------------------------------


--- Forces a value to be in between two numbers.
--- @param min number the minimum value allowed
--- @param value number the value that needs to be clamped
--- @param max number the maximum value allowed
--- @return number min if value was lower than min, max if value was higher than max, value otherwise.
function math.clamp(min, value, max)
    return math.max(min, math.min(value, max))
end

--- Performs a modulo operation that does not start counting from zero.
--- Useful when cycling through page numbers that start from 1 instead of 0, for example.
--- @param value number the value to modulo
--- @param mod number the modulo
--- @param shift number how much the start of the modulo is shifted from 0. defaults to 1.
--- @return number the shifted modulo, which will always be a number between shift (included) and shift+mod (excluded)
function math.shifted_mod(value, mod, shift)
    if shift == nil then shift = 1 end
    return ((value-shift) % mod) + shift
end

-------------------------------------------
--region Table
-------------------------------------------

---Creates a deep copy of a table and returns it.
---this function checks for redundant paths to avoid infinite recursion.
---@param tbl table the table to deep copy
function table.deepcopy(tbl)
    local deepcopy = function(orig, copies)
        local orig_type = type(orig)
        local copy
        if orig_type == 'table' then
            if copies[orig] then
                copy = copies[orig]
            else
                copy = {}
                copies[orig] = copy
                for orig_key, orig_value in next, orig, nil do
                    copy[table.deepcopy(orig_key, copies)] = table.deepcopy(orig_value, copies)
                end
                setmetatable(copy, table.deepcopy(getmetatable(orig), copies))
            end
        else -- number, string, boolean, etc
            copy = orig
        end
        return copy
    end
    return deepcopy(tbl, {})
end

---Takes a list and returns a new, shuffled version of the integer pairs in the list.
---The returned list is new, meaning that tbl is left unmodified, but the items inside are not copies.
---Use table.deepcopy afterwards if you need to edit them.
---@param tbl table a table to shuffle
---@return table a shuffled version of the table
function table.shuffle(tbl)
    local indices = table.get_keys(tbl, true)
    local shuffled = {}
    for _=1, #tbl, 1 do
        local index, pos = COMMON_FUNC.WeightlessRoll(indices)
        table.remove(indices, pos)
        table.insert(shuffled, tbl[index])
    end
    return shuffled
end

---Returns all the keys inside a table
---@param tbl table a table
---@param int boolean if true, only integer keys that would be encountered starting from 1 will be returned. Defaults to false
---@return table a list of all the keys of the table
function table.get_keys(tbl, int)
    local keys = {}
    if int then
        for k in ipairs(tbl) do
            table.insert(keys, k)
        end
    else
        for k in pairs(tbl) do
            table.insert(keys, k)
        end
    end
    return keys
end

---Returns the key associated to a value inside a table
---@param tbl table a table
---@param object any the object to look for
---@param default any a return value to return in case of failure. Defaults to nil
---@return any the key of the object if it is found, default otherwise
function table.index_of(tbl, object, default)
    for index, element in pairs(tbl) do
        if element == object then return index end
    end
    return default
end

---Returns whether a table has a specific object as a value
---@param tbl table a table
---@param object any the object to look for
---@return boolean true if tbl contains object, false otherwise
function table.contains(tbl, object)
    return table.index_of(tbl, object) ~= nil
end

---Appends every element of the second table at the end of the first one.
---Any non-integer key will be copied without changing the key. Any integer
---key will be placed at the end of the first list as defined by the #
---operator, and all empty spaces in between them will be preserved.
---For example, if the tables have keys {1,2,3} and {-1,2,3}, the
---result will have the keys {1,2,3,4,7,8}. If any conflict occurs,
---`over` will describe how to solve it.
---
---This function edits tbl1 in-place. It does not create nor return a new table.
---@param tbl1 table a table
---@param tbl2 table another table
---@param over boolean if true, any conflicting keys will not check if preexisting values exist for that key inside tbl1 and will override said values. Defaults to false.
function table.merge(tbl1, tbl2, over)
    local startlen = #tbl1+1
    local numkeys = {}
    for key in pairs(tbl2) do
        if type(key) == 'number' then
            table.insert(numkeys, key)
        else
            if over or tbl1[key] == nil then
                tbl1[key] = tbl2[key]
            end
        end
    end
    table.sort(numkeys)
    local startkey = numkeys[1]
    for _, i2 in ipairs(numkeys) do
        local i1 = startlen+i2-startkey
        if over or tbl1[i1] == nil then
            tbl1[i1] = tbl2[i2]
        end
    end
end

---Appends every element of the other tables provided at the end of the first one, in the given order.
---This function edits tbl in-place. It does not create a new table.
---@param tbl table a table
---@param ... table a list of tables
function table.merge_all(tbl, ...)
    local tables = {...}
    for _, tbl2 in pairs(tables) do
        table.merge(tbl, tbl2)
    end
end

-------------------------------------------
--region COMMON+
-------------------------------------------

function COMMON_FUNC.StartNewRun()
    if not DungeonRestrictionMenu.run() then
        return
    end
    if not _SHOP.StorageCanStoreInventory() then
        UI:WaitShowDialogue(STRINGS:FormatKey("NEW_RUN_DEPOSIT_FAIL"))
        return
    end
    -- team remove
    for i= _DATA.Save.ActiveTeam.Players.Count-1, 0, -1 do
        if i >= SV.WishUpgrades.Player.TeamLimitUp+2 then
            _GROUND:SilentSendHome(i)
        else
            COMMON_FUNC.SaveStartData(_DATA.Save.ActiveTeam.Players[i])
        end
    end
    -- money deposit
    local moneyLimit = _HUB.StartingMoneyTable[SV.WishUpgrades.Player.StartingMoneyUp]
    local moneyToStore = math.max(0, GAME:GetPlayerMoney() - moneyLimit)
    GAME:RemoveFromPlayerMoney(moneyToStore)
    GAME:AddToPlayerMoneyBank(moneyToStore)
    -- item deposit
    local eq = GAME:GetPlayerEquippedCount()
    local items = GAME:GetPlayerBagCount()
    local invLimit = SV.WishUpgrades.Player.StartItems
    local maxItems = math.max(0, invLimit - eq)
    local maxEq = invLimit
    local j = items-1
    while j >= maxItems do
        local item = GAME:GetPlayerBagItem(j)
        if not _DATA:GetItem(item.ID).CannotDrop then
            GAME:TakePlayerBagItem(j, true)
            GAME:GivePlayerStorageItem(item)
        end
        j = j -1
    end
    j = _DATA.Save.ActiveTeam.Players.Count-1
    while eq >= maxEq do
        local item = GAME:GetPlayerEquippedItem(j)
        if item ~= nil and item.ID ~~ "" then
            if not _DATA:GetItem(item.ID).CannotDrop then
                GAME:TakePlayerEquippedItem(j, true)
                GAME:GivePlayerStorageItem(item)
            end
            eq = eq - 1
        end
        j = j -1
    end
    -- bonus limiting
    local maxBoost = SV.WishUpgrades.Player.StartBoosts * 32
    for i=0, _DATA.Save.ActiveTeam.Players.Count-1, 1 do
        local char = _DATA.Save.ActiveTeam.Players[i]
        COMMON_FUNC.SaveStartData(char)
        char.MaxHPBonus = math.min(char.MaxHPBonus, maxBoost)
        char.AtkBonus   = math.min(char.AtkBonus,   maxBoost)
        char.DefBonus   = math.min(char.DefBonus,   maxBoost)
        char.MAtkBonus  = math.min(char.MAtkBonus,  maxBoost)
        char.MDefBonus  = math.min(char.MDefBonus,  maxBoost)
        char.SpeedBonus = math.min(char.SpeedBonus, maxBoost)

    end
    GAME:EnterDungeon("ancient_trail", 0, 0, 0, RogueEssence.Data.GameProgress.DungeonStakes.Risk, true, true)
end

function COMMON_FUNC.EndSessionWithResults(result, zoneId, structureId, mapId, entryId)
    GAME:EndDungeonRun(result, zoneId, structureId, mapId, entryId, true, true)
    GAME:EnterZone(zoneId, structureId, mapId, entryId)
end

function COMMON_FUNC.InvItemFromInvSlot(invSlot)
    if not invSlot:IsValid() then return end
    if invSlot.IsEquipped then return _DATA.Save.ActiveTeam.Players[invSlot.Slot].EquippedItem end
    return _DATA.Save.ActiveTeam:GetInv(invSlot.Slot)
end

function COMMON_FUNC.MergeItemLists(list, ...)
    local lists = {...}
    for _, list2 in pairs(lists) do
        table.merge(list, list2)
    end
    COMMON_FUNC.CompactItems(list)
end

function COMMON_FUNC.CompactItems(list)
    for i=1, #list-1, 1 do
        for j=#list, i+1, -1 do
            local entry1, entry2 = list[i], list[j]
            if entry1.item == entry2.item then
                entry1.amount = entry1.amount + entry2.amount
                table.remove(list, j)
            end
        end
    end
end

function COMMON_FUNC.runTextInputMenu(title, notes, start)
    UI:NameMenu(title, notes, 116, start)
    UI:WaitForChoice()
    local res = UI:ChoiceResult()
    if res == "" then return false
    else return res end
end

--- Builds a string using a list of elements and applying the provided function to every element of the list.
--- The elements will be concatenated using the localized `ADD_SEPARATOR` and `ADD_END` strings as separators.
---@param list table the list of objects to build the string with
---@param func function a function that takes an item from the list and returns the string that will represent it. If omitted, the elements will be used directly
function COMMON_FUNC.BuildStringWithSeparators(list, func)
    func = func or function(a) return tostring(a) end
    local str = "" --TODO switch to STRINGS:CreateList(LuaTable)?
    for i, entry in pairs(list) do
        if i>1 then
            if i==#list then str = str..STRINGS:FormatKey("ADD_END")
            else str = str..STRINGS:FormatKey("ADD_SEPARATOR") end
        end
        str = str..func(entry)
    end
    return str
end

--- Builds a string that represents an item and its amount
---@param item_id string an item id, or `"(P)"` to print a money value instead
---@param amount number the amount of items to display. If nil, no amount indicator will be printed
---@param omit_single boolean if true, the amount will not be printed if the item is non-stackable AND the stack is 1. Defaults to false
function COMMON_FUNC.PrintItemAmount(item_id, amount, omit_single)
    amount = math.max(0, amount or 0)
    if item_id == "(P)" then
        return STRINGS:FormatKey("MONEY_AMOUNT", amount)
    end
    local data = _DATA:GetItem(item_id)
    local str = data:GetIconName()
    if amount>0 and not(omit_single and data.MaxStack <= 1 and amount <= 1) then
        str = STRINGS:Format("{0} [color=#FFCEFF]({1})[color]", str, string.format("%d", amount))
    end

    return str
end

--- Removes money from the player.
--- If bank is true, it will take from the money bank after depleting the money bank.
--- Returns the amount of money NOT removed if the player didn't have enough.
---@param amount number the amount of copies of the item to remove
---@param bank boolean if true, the function will start taking items from the money bank after the money on hand is depleted.
---@return number the difference between the the amount of items removed and the amount of requested copies, or 0 if all requested copies have been removed.
function COMMON_FUNC.RemoveMoney(amount, bank)
    return COMMON_FUNC.RemoveItem("(P)", amount, bank)
end

--- Removes a number of copies of a specific item from the player's inventory.
--- If storage is true, it will take from storage after depleting the stock in the inventory.
--- Returns the amount of items NOT removed if the player didn't have enough.
---@param item_id string the id of the item to remove. Use `"(P)"` to remove money
---@param amount number the amount of copies of the item to remove
---@param storage boolean if true, the function will start taking items from storage (or bank) after the inventory is emptied.
---@return number the difference between the the amount of items removed and the amount of requested copies, or 0 if all requested copies have been removed.
function COMMON_FUNC.RemoveItem(item_id, amount, storage)
    if item_id == "(P)" then
        local count = math.max(0, amount - GAME:GetPlayerMoney())
        local remove = amount-count
        GAME:RemoveFromPlayerMoney(remove)
        if count>0 then
            local count2 = math.max(0, count - GAME:GetPlayerMoneyBank())
            local remove2 = count-count2
            GAME:RemoveFromPlayerMoneyBank(remove2)
            count = count2
        end
        return count
    end

    for i = 1, amount, 1 do
        local item_slot = GAME:FindPlayerItem(item_id, true, true)
        if not item_slot:IsValid() then
            if storage and GAME:GetPlayerStorageItemCount(item_id) > 0 then
                GAME:TakePlayerStorageItem(item_id)
            else return amount-i+1 end
        elseif item_slot.IsEquipped then
            GAME:TakePlayerEquippedItem(item_slot.Slot)
        else
            GAME:TakePlayerBagItem(item_slot.Slot)
        end
    end
    return 0
end

--- Removes a number of copies of specific items from the player's inventory.
--- If storage is true, it will take from storage after depleting the stock in the inventory.
---@param cost_table table a list of `{item = string, amount = number}` entries
---@param storage boolean if true, the function will start taking items from storage after the inventory has been emptied.
---@return table a list of `{item = string, amount = number}` entries where `amount` is the amount of copies of `item` NOT removed if the player didn't have enough, or `{}` if all requested copies have been removed..
function COMMON_FUNC.RemoveItems(cost_table, storage)
    local fails = {}
    for _, entry in pairs(cost_table) do
        local missing = COMMON_FUNC.RemoveItem(entry.item, entry.amount, storage)
        if missing > 0 then
            table.insert(fails, {entry.item, missing})
        end
    end
    return fails
end

--- Checks if the player has the given amount of money.
---@param amount number the amount of money to check for
---@param check_bank boolean if true, the function will also account for the money bank
function COMMON_FUNC.CheckMoney(amount, check_bank)
    return COMMON_FUNC.CheckCost({ { item = "(P)", amount = amount } }, check_bank)
end

--- Checks if the player has the given amount of items.
--- If an item id is set to `"(P)"`, it will check the player's money instead.
---@param cost_table table a list of `{item = string, amount = number}` entries
---@param check_storage boolean if true, the function will also count the item in storage
function COMMON_FUNC.CheckCost(cost_table, check_storage)
    for _, entry in pairs(cost_table) do
        if entry.item == "(P)" then
            local count = GAME:GetPlayerMoney()
            if check_storage then count = count + GAME:GetPlayerMoneyBank() end
            if count < entry.amount then
                return false
            end
        else
            if COMMON.GetPlayerItemCount(entry.item, check_storage) < entry.amount then
                return false
            end
        end
    end
    return true
end

function COMMON_FUNC.GetMoney(check_bank)
    local ret = GAME:GetPlayerMoney()
    if check_bank then ret = ret + GAME:GetPlayerMoneyBank() end
    return ret
end

---Rolls for a random object inside a list and returns the result.
---Every object has the same chance of being chosen.
---@param list table a table of possible results
---@return any, number a randomly chosen entry inside the list and its index, or nil, nil if the list is empty
function COMMON_FUNC.WeightlessRoll(list)
    if #list == 0 then return nil, nil end
    local index = math.random(1, #list)
    return list[index], index
end

---Rolls for a random list inside a list and returns the result.
---Every table uses its length as its weight of probability.
---@param list table a table of tables
---@return table, number a randomly chosen table inside the list and its index, or nil, nil if the list is empty
function COMMON_FUNC.LengthWeightedTableListRoll(list)
    if #list == 0 then return nil, nil end
    local entries = {}
    for i, tbl in pairs(list) do
        table.insert(entries, {Index = i, Weight = #tbl})
    end

    local _, index = COMMON_FUNC.WeightedRoll(entries).Index

    return list[index], index
end

---Rolls for a random table entry inside a list and returns the result.
---Every entry must have a positive Weight property that will determine its chance of being chosen.
---If this property is missing or non-positive, the entry will never be selected.
---@param list table a table of possible results containing a Weight property.
---@return table, number a randomly chosen entry inside the list and its index, or nil, nil if the list is empty
function COMMON_FUNC.WeightedRoll(list)
    local weight_total = 0
    for _, entry in pairs(list) do
        if entry.Weight and entry.Weight > 0 then
            weight_total = weight_total + entry.Weight
        end
    end

    local result = math.random(1, weight_total)

    local count = 0
    for i, entry in pairs(list) do
        if entry.Weight and entry.Weight > 0 then
            count = count + entry.Weight
            if count>=result then
                return entry, i
            end
        end
    end
    return nil, nil
end

--- Saves the current form data, ability and moveset of a Character inside its internal lua table and increments the restoration counter by 1
--- @param target userdata The Character to save the data of
function COMMON_FUNC.SaveStartData(target)
    local luaData = {
        form_data = {
            species = target.BaseForm.Species,
            form = target.BaseForm.Form,
            skin = target.BaseForm.Skin,
            gender = RogueEssence.Script.LuaEngine.Instance:EnumToNumeric(target.BaseForm.Gender)
        },
        ability = target.BaseIntrinsics[0],
        form_ability_slot = target.FormIntrinsicSlot,
        moves = {},
        boosts = {MHP = 0, ATK = 0, DEF = 0, SAT = 0, SDF = 0, SPE = 0}
    }
    local skillnum = math.min(4, target.BaseSkills.Count-1)
    for i=0, skillnum, 1 do
        if target.BaseSkills.Count>i then
            luaData.moves[i] = target.BaseSkills[i].SkillNum
        else
            luaData.moves[i] = ""
        end
    end
    luaData.boosts.MHP = target.MaxHPBonus
    luaData.boosts.ATK = target.AtkBonus
    luaData.boosts.DEF = target.DefBonus
    luaData.boosts.SAT = target.MAtkBonus
    luaData.boosts.SDF = target.MDefBonus
    luaData.boosts.SPE = target.SpeedBonus
    target.LuaData.StartData = luaData
    SV.RunData.CharCounter = SV.RunData.CharCounter+1
    printall(luaData)
end

--- Restores the stored form data, ability and moveset of a Character from inside its internal lua table and decrements the restoration counter by 1.
--- The Character will also be brought to level 5.
--- @param target userdata The Character to save the data of
function COMMON_FUNC.RestoreStartData(target)
    local luaData = target.LuaData.StartData
    local gender = luaData.form_data.gender
    if gender < 0
        then gender = _DATA:GetMonster(luaData.form_data.species).Forms[luaData.form_data.form]:RollGender(_DATA.Save.Rand)
        else gender = GLOBAL.GenderTable[gender]
    end
    target.BaseForm = RogueEssence.Dungeon.MonsterID(luaData.form_data.species, luaData.form_data.form, luaData.form_data.skin, gender)
    target:SetBaseIntrinsic(luaData.ability)
    target.FormIntrinsicSlot = luaData.form_ability_slot
    local skillnum = math.min(4, target.BaseSkills.Count-1)
    for i=0, skillnum, 1 do
        target.BaseSkills[i].SkillNum = luaData.moves[i]
    end
    target.MaxHPBonus = luaData.boosts.MHP
    target.AtkBonus   = luaData.boosts.ATK
    target.DefBonus   = luaData.boosts.DEF
    target.MAtkBonus  = luaData.boosts.SAT
    target.MDefBonus  = luaData.boosts.SDF
    target.SpeedBonus = luaData.boosts.SPE
    target.LuaData.StartData = nil
    SV.RunData.CharCounter = SV.RunData.CharCounter-1
end

---Converts an InvItem to a lua table
---@param invItem InvItem the InvItem to convert
---@return InvItemLua #a lua table that is equivalent to the supplied InvItem
function COMMON_FUNC.InvItemToTbl(invItem)
    return {
        ID = invItem.ID,
        Amount = invItem.Amount,
        Cursed = invItem.Cursed,
        HiddenValue = invItem.HiddenValue,
        Price = invItem.Price
    }
end

---Converts a lua-fied InvItem back into its original format
---@param invItemTbl InvItemLua the InvItem table to restore
---@return InvItem #the restored InvItem
function COMMON_FUNC.TblToInvItem(invItemTbl)
    local invItem = RogueEssence.Dungeon.InvItem(invItemTbl.ID, invItemTbl.Cursed, invItemTbl.Amount, invItemTbl.Price)
    invItem.HiddenValue = invItemTbl.HiddenValue
    return invItem
end