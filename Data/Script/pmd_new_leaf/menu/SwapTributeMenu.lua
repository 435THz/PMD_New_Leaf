--[[
    SwapTributeMenu

    Opens a menu, potentially with multiple pages, that allows the player to select one or
    more exclusive items in their inventory or storage.
    It contains a run method for quick instantiation and an ItemChosenMenu port for confirmation.
]]

require 'pmd_new_leaf.CommonFunctions'

--- Menu for selecting items from the player's inventory.
SwapTributeMenu = Class("SwapTributeMenu")

--- Creates a new ``SwapTributeMenu`` instance using the provided data and callbacks.
--- @param confirm_action function the function called when the selection is confirmed. It will have a table array of ``RogueEssence.Dungeon.InvSlot`` objects passed to it as a parameter.
--- @param refuse_action function the function called when the player presses the cancel or menu button.
--- @param choices boolean number of choices necessary.
function SwapTributeMenu:initialize(confirm_action, refuse_action, choices)

    -- constants
    self.MAX_ELEMENTS = 8

    -- parsing data
    self.title = STRINGS:FormatKey("TRADER_TRIBUTE_TITLE")
    self.confirmAction = confirm_action
    self.idList, self.itemList = self:load_items()
    self.optionsList, self.optionsData = self:generate_options()
    self.range_choices = RogueElements.IntRange(choices, choices)

    self.multiConfirmAction = function(list)
        self.choices = self:multiConfirm(list)
        _MENU:RemoveMenu()
        self.confirmAction(self.choices)
    end

    self.choices = {} -- result

    -- creating the menu
    local origin = RogueElements.Loc(16,16)
    local option_array = luanet.make_array(RogueEssence.Menu.MenuElementChoice, self.optionsList)
    self.menu = RogueEssence.Menu.ScriptableMultiPageMenu(origin, 176, self.title, option_array, 0, self.MAX_ELEMENTS, refuse_action, refuse_action, false, self.max_choices, self.multiConfirmAction)
    self.menu.ChoiceChangedFunction = function() self:updateSummary() end
    self.menu.MultiSelectChangedFunction = function() self:updateList() end

    -- create the summary window
    local GraphicsManager = RogueEssence.Content.GraphicsManager

    self.summary = RogueEssence.Menu.ItemSummary(RogueElements.Rect.FromPoints(
            RogueElements.Loc(16, GraphicsManager.ScreenHeight - 8 - GraphicsManager.MenuBG.TileHeight * 2 - 14 * 4), --LINE_HEIGHT = 12, VERT_SPACE = 14
            RogueElements.Loc(GraphicsManager.ScreenWidth - 16, GraphicsManager.ScreenHeight - 8)))
    self.menu.SummaryMenus:Add(self.summary)
    self:updateSummary()
end

--- Loads the item slots that will be part of the menu.
--- @return string[], table<string,integer> #a list of item ids and a table associating every id to its respective item amount
function SwapTributeMenu:load_slots()
    ---@type table<string,integer>
    local items = {}
    ---@type string[]
    local ids = {}

    -- add equipped items
    local chars = _DATA.Save.ActiveTeam.Players
    for i=0, chars.Count-1, 1 do
        local char = chars[i]
        if char.EquippedItem.ID and char.EquippedItem.ID ~= "" then
            local id = char.EquippedItem.ID
            if _DATA:GetItem(id).UsageType == RogueEssence.Data.ItemData.UseType.Treasure then
                local count = char.EquippedItem.Amount
                if count==0 then count = 1 end
                if not items[id] then
                    items[id] = 0
                    table.insert(ids, id)
                end
                items[id] = items[id] +count
            end
        end
    end
    -- add rest of inventory
    for i=0, _DATA.Save.ActiveTeam:GetInvCount()-1, 1 do
        local id = _DATA.Save.ActiveTeam:GetInv(i).ID
        if _DATA:GetItem(id).UsageType == RogueEssence.Data.ItemData.UseType.Treasure then
            local count = _DATA.Save.ActiveTeam:GetInv(i).Amount
            if count==0 then count = 1 end
            if not items[id] then
                items[id] = 0
                table.insert(ids, id)
            end
            items[id] = items[id] +count
        end
    end

    for pair in luanet.each(_DATA.Save.ActiveTeam.Storage) do
        local id = pair.Key
        if _DATA:GetItem(id).UsageType == RogueEssence.Data.ItemData.UseType.Treasure then
            if not items[id] then
                items[id] = 0
                table.insert(ids, id)
            end
            items[id] = items[id] +pair.Value
        end
    end

    local sort = function(a, b)
        return _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Item]:CompareWithSort(a, b) >= 0
    end
    table.sort(ids, sort)
    return ids, items
end

--- Processes the menu's properties and generates the ``RogueEssence.Menu.MenuElementChoice`` list that will be displayed.
--- @return table, {item:string,amount:integer}[] #a list of ``RogueEssence.Menu.MenuElementChoice`` objects and its corresponding list of option entries.
function SwapTributeMenu:generate_options()
    local options = {}
    local optionData = {}
    for _, item_id in ipairs(self.idList) do
        local amount = self.itemList[item_id]
        local item = _DATA:GetItem(item_id)

        local name = item:GetIconName()
        if amount>1 then name = STRINGS:Format("{0} ({1})", name, amount) end
        local text_name = RogueEssence.Menu.MenuText(name, RogueElements.Loc(2, 1), Color.White)
        local option = RogueEssence.Menu.MenuElementChoice(function() self:choose() end, true, text_name)
        table.insert(options, option)
        table.insert(optionData, {item = item_id, amount = amount})
    end
    return options, optionData
end

--- no.
function SwapTributeMenu:choose(_) _GAME:SE("Menu/Cancel") end


function SwapTributeMenu:updateList()
    local hover_option = self.menu.CurrentChoiceTotal
    local hover_data = self.menu.CurrentChoiceTotal+1
    local options = self.menu.ExportChoices()
    local data = self.optionsData
    local curr_option = options[hover_option]
    local curr_data = data[hover_data]
    if curr_option.Selected then --has JUST been selected
        if curr_data.amount > 1 then
            local curr_name = _DATA:GetItem(curr_data.item):GetIconName()
            local new_name = curr_name
            local new_data = {item = curr_data.item, amount = curr_data.amount-1}
            if new_data.amount>1 then new_name = STRINGS:Format("{0} ({1})", new_name, new_data.amount) end
            curr_option:TetText(curr_name)
            local new_text = RogueEssence.Menu.MenuText(new_name, RogueElements.Loc(2, 1), Color.White)
            local new_option = RogueEssence.Menu.MenuElementChoice(function() self:choose() end, true, new_text)
            options:Insert(hover_option+1, new_option)
            table.insert(data, hover_data+1, new_data)
            curr_data.amount = 1
        end
    else --has JUST been deselected
        local start = hover_data
        local finish = hover_data
        local max
        while finish<options.Count and curr_data.item == data[finish].item do
            finish=finish+1
            if not options[finish].Selected and (not max or data[finish].amount > data[max].amount) then
                max = finish
            end
        end
        while start>=0 and curr_data.item == data[start].item do
            start=start-1
            if not options[start].Selected and (not max or data[start].amount > data[max].amount) then
                max = start
            end
        end
        start, finish = start+1, finish-1

        if max then
            data[max].amount = data[max].amount + curr_data.amount
            options:Remove(hover_option)
            table.remove(data, hover_data)
--[[            if max>hover_data then max=max-1 end
            self.menu.CurrentChoiceTotal = max
            TODO this is impossible without a setter in CurrentChoiceTotal. Maybe it won't be needed though
]]
        end
    end
    self.menu.ImportChoices(options)
    self:updateSummary()
end

--- Updates the summary window.
function SwapTributeMenu:updateSummary()
    self.summary:SetItem(_DATA.Save.ActiveTeam:GetInv(self.itemList[self.menu.CurrentChoiceTotal+1].Slot))
end

--- Extract the list of selected slots.
--- @param list table a table array containing the menu indices of the chosen items.
--- @return table #a table array containing item ids.
function SwapTributeMenu:multiConfirm(list)
    local result = {}
    for _, index in pairs(list) do
        local item_id = self.itemList[index+1]
        table.insert(result, item_id)
    end
    return result
end






--- Creates a basic ``SwapTributeMenu`` instance using the provided parameters, then runs it and returns its output.
--- @param max_choices integer The amount of items to select.
--- @return table #a table array containing the chosen ``RogueEssence.Dungeon.InvSlot`` objects.
function SwapTributeMenu.run(max_choices)
    local ret = {}
    local choose = function(list) ret = list end
    local refuse = function() _MENU:RemoveMenu() end
    local menu = SwapTributeMenu:new(choose, refuse, 176, max_choices)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end

--- Checks if it would make sense to open a ``SwapTributeMenu``
--- @param required_num number the minimum amount of exclusive items required to open the menu
function SwapTributeMenu.canOpen(required_num)
    if required_num<=0 then return true end
    local found = 0

    -- add equipped items
    local chars = _DATA.Save.ActiveTeam.Players
    for i=0, chars.Count-1, 1 do
        local char = chars[i]
        if char.EquippedItem.ID and char.EquippedItem.ID ~= "" then
            local id = char.EquippedItem.ID
            if _DATA:GetItem(id).UsageType == RogueEssence.Data.ItemData.UseType.Treasure then
                local count = char.EquippedItem.Amount
                if count==0 then count = 1 end
                found = found + count
                if found >= required_num then return true end
            end
        end
    end
    -- add rest of inventory
    for i=0, _DATA.Save.ActiveTeam:GetInvCount()-1, 1 do
        local id = _DATA.Save.ActiveTeam:GetInv(i).ID
        if _DATA:GetItem(id).UsageType == RogueEssence.Data.ItemData.UseType.Treasure then
            local count = _DATA.Save.ActiveTeam:GetInv(i).Amount
            if count==0 then count = 1 end
            found = found + count
            if found >= required_num then return true end
        end
    end

    for pair in luanet.each(_DATA.Save.ActiveTeam.Storage) do
        local id = pair.Key
        if _DATA:GetItem(id).UsageType == RogueEssence.Data.ItemData.UseType.Treasure then
            found = found + pair.Value
            if found >= required_num then return true end
        end
    end
    return false
end
