--[[
    SmallShopMenu
    by MistressNebula

    Opens a shop menu that allows the player to select one item to buy.
    Contrary to the classic item menu this menu will shrink if there are less than 8 entries, and
    will skip directly to ItemChosenMenu if only 1 entry exists.
]]


---@class SmallShopMenu : LuaClass Menu for selecting items from a pretty small selection. If there is only one item, it opens the ChosenMenu directly
SmallShopMenu = Class("SmallShopMenu")

--- Creates a new ``SmallShopMenu`` instance using the provided list and callbacks.
--- @param title string the title this window will have.
--- @param items {Item:InvItem,Price:integer}[] the list of ``{Item = InvItem, Price = number}`` entries to display.
--- @param confirm_action fun(index:integer) the function called when the selection is confirmed. It will have an integer passed to it as a parameter.
--- @param refuse_action fun() the function called when the player presses the cancel or menu button.
--- @param menu_width? integer the width of this window. Default is 176.
function SmallShopMenu:initialize(title, items, confirm_action, refuse_action, menu_width)
    -- constants
    self.MAX_ELEMENTS = 8

    -- parsing data
    self.title = title
    self.confirm_button = STRINGS:FormatKey("MENU_SHOP_BUY")
    self.confirmAction = confirm_action
    self.refuseAction = refuse_action
    self.menuWidth = menu_width or 176
    self.items = items
    self.optionsList = self:generate_options()

    self.choices = {} -- result

    -- creating the menu
    local origin = RogueElements.Loc(16,16)
    local option_array = luanet.make_array(RogueEssence.Menu.MenuElementChoice, self.optionsList)
    self.menu = RogueEssence.Menu.ScriptableMultiPageMenu(origin, self.menuWidth, title, option_array, 0, math.min(#self.items, self.MAX_ELEMENTS), refuse_action, refuse_action, false)
    self.menu.ChoiceChangedFunction = function() self:updateSummary() end
    self.menu.UpdateFunction = function(input) self:updateFunction(input) end

    -- create the summary window
    local GraphicsManager = RogueEssence.Content.GraphicsManager

    self.summary = RogueEssence.Menu.ItemSummary(RogueElements.Rect.FromPoints(
            RogueElements.Loc(16, GraphicsManager.ScreenHeight - 8 - GraphicsManager.MenuBG.TileHeight * 2 - 14 * 4), --LINE_HEIGHT = 12, VERT_SPACE = 14
            RogueElements.Loc(GraphicsManager.ScreenWidth - 16, GraphicsManager.ScreenHeight - 8)))
    self.menu.SummaryMenus:Add(self.summary)
    self:updateSummary()
    self.firstFrame = true
end

--- Processes the menu's properties and generates the ``RogueEssence.Menu.MenuElementChoice`` list that will be displayed.
--- @return Selectable[] #a list of ``RogueEssence.Menu.MenuElementChoice`` objects.
function SmallShopMenu:generate_options()
    local options = {}
    for i=1, #self.items, 1 do
        local entry = self.items[i]
        local item = entry.Item
        local price = entry.Price
        local enabled = true

        local name = item:GetDisplayName()
        local text_name = RogueEssence.Menu.MenuText(name, RogueElements.Loc(2, 1))
        local text_price = RogueEssence.Menu.MenuText(tostring(price), RogueElements.Loc(self.menuWidth - 8 * 4, 1), RogueElements.DirV.Up, RogueElements.DirH.Right, Color.Lime)
        local option = RogueEssence.Menu.MenuElementChoice(function() self:choose(i) end, enabled, text_name, text_price)
        table.insert(options, option)
    end
    return options
end

--- Closes the menu and calls the menu's confirmation callback.
--- The result must be retrieved by accessing the choice variable of this object, which will hold
--- the chosen index as the single element of a table array.
--- @param index integer the index of the chosen item
function SmallShopMenu:choose(index)
    local choose = function(answer)
        if answer then
            _MENU:RemoveMenu()
            self.confirmAction(index)
        elseif #self.items==1 then
            self.refuseAction()
        end
    end
    local menu = SmallShopChosenMenu:new(self.items[index].Item, self.menu, self.confirm_button, choose)
    _MENU:AddMenu(menu.menu, true)
end

--- Uses the current input to apply changes to the menu.
function SmallShopMenu:updateFunction(_)
    if self.firstFrame then
        self.firstFrame = false
        if #self.items==1 then self:choose(1) end
    end
end
--- Updates the summary window.
function SmallShopMenu:updateSummary()
    self.summary:SetItem(self.items[self.menu.CurrentChoiceTotal+1].Item)
end




---@class SmallShopChosenMenu : LuaClass Menu that allows the player to choose what to do with the selected item
SmallShopChosenMenu = Class("SmallShopChosenMenu")

--- Creates a new ``SmallShopChosenMenu`` instance using the provided object as parent.
--- @param item ItemData the selected item
--- @param parent Menu the parent menu
--- @param confirm_text string the confirm button text
--- @param confirm_action fun(answer:boolean) the function that is called when the confirm button is pressed
function SmallShopChosenMenu:initialize(item, parent, confirm_text, confirm_action)
    local x, y = parent.Bounds.Right, parent.Bounds.Top
    local width = 72
    self.item = item

    self.confirmAction = confirm_action
    local options = {
        {confirm_text, true, function() self:choose(true) end},
        {STRINGS:FormatKey("MENU_INFO"),      true, function() _MENU:AddMenu(RogueEssence.Menu.TeachInfoMenu(self.item), false) end},
        {STRINGS:FormatKey("MENU_CANCEL"),    true, function() self:choose(false) end}
    }
    if self.item.UsageType ~= RogueEssence.Data.ItemData.UseType.Learn then
        table.remove(options, 2)
    end

    self.menu = RogueEssence.Menu.ScriptableSingleStripMenu(x, y, width, options, 0, function() self:choose(false) end)
end

---Wraps the confirmation callback and closes the menu as it calls it.
---@param result boolean the selected answer
function SmallShopChosenMenu:choose(result)
    _MENU:RemoveMenu()
    self.confirmAction(result)
end






--- Creates a basic ``SmallShopMenu`` instance using the provided parameters, then runs it and returns its output.
--- @param title string the title this window will have
--- @return integer #the the chosen ``RogueEssence.Dungeon.InvSlot`` object's index.
function SmallShopMenu.run(title, items)
    local ret = -1
    local choose = function(index) ret = index end
    local refuse = function() _MENU:RemoveMenu() end
    local menu = SmallShopMenu:new(title, items, choose, refuse, 176)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end