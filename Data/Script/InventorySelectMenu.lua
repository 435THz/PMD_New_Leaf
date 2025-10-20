---@meta
--[[
    InventorySelectMenu
    lua port by MistressNebula

    Opens a menu, potentially with multiple pages, that allows the player to select one or
    more items in their inventory.
    It contains a run method for quick instantiation and an ItemChosenMenu port for confirmation.
    This equivalent is NOT SAFE FOR REPLAYS. Do NOT use in dungeons until further notice.
]]


--- @class InventorySelectMenu : LuaClass Menu for selecting items from the player's inventory.
--- @field MAX_ELEMENTS integer
--- @field title string
--- @field confirm_button string
--- @field confirmAction fun(slots:InvSlot[])
--- @field refuseAction fun()
--- @field menuWidth integer
--- @field filter fun(slotList:InvSlot):boolean
--- @field includeEquips boolean
--- @field slotList InvSlot[]
--- @field optionsList Selectable[]
--- @field max_choices_param integer
--- @field max_choices integer
--- @field label string
--- @field multiConfirmAction fun(list:integer[])
--- @field choices InvItem[] the return list of the menu
--- @field menu ScriptableMultiPageMenu
--- @field summary ItemSummary
InventorySelectMenu = Class("InventorySelectMenu")

--- Creates a new ``InventorySelectMenu`` instance using the provided list and callbacks.
--- @param title string the title this window will have.
--- @param filter fun(slotList:InvSlot):boolean a function that takes a ``RogueEssence.Dungeon.InvSlot`` object and returns a boolean. Any slot that does not pass this check will have its option disabled in the menu. Defaults to ``return true``.
--- @param confirm_action fun(slots:InvSlot[]) the function called when the selection is confirmed. It will have a table array of ``RogueEssence.Dungeon.InvSlot`` objects passed to it as a parameter.
--- @param refuse_action fun() the function called when the player presses the cancel or menu button.
--- @param confirm_button? string the text used for the confirm button of ``ItemChosenMenu``. If nil, the sub-menu will be skipped entirely.
--- @param menu_width? integer the width of this window. Default is 176.
--- @param include_equips? boolean if true, the menu will include equipped items. Defaults to true.
--- @param max_choices? integer if set, it will never be possible to select more than the amount of items defined here. Defaults to the amount of selectable items.
--- @param label? string the label that will be applied to this menu. Defaults to "INVENTORY_MENU_LUA"
function InventorySelectMenu:initialize(title, filter, confirm_action, refuse_action, confirm_button, menu_width, include_equips, max_choices, label) end

--- Loads the item slots that will be part of the menu.
--- @return InvSlot[] a standardized version of the item list
function InventorySelectMenu:load_slots() end

--- Processes the menu's properties and generates the ``RogueEssence.Menu.MenuElementChoice`` list that will be displayed.
--- @return Selectable[] a list of ``RogueEssence.Menu.MenuElementChoice`` objects.
function InventorySelectMenu:generate_options() end

--- Counts the number of valid options generated.
--- @return integer the number of valid options.
function InventorySelectMenu:count_valid() end

--- Closes the menu and calls the menu's confirmation callback.
--- The result must be retrieved by accessing the choice variable of this object, which will hold
--- the chosen index as the single element of a table array.
--- @param index integer the index of the chosen character
function InventorySelectMenu:choose(index) end

--- Uses the current input to apply changes to the menu.
--- @param input any the ``RogueEssense.InputManager``.
function InventorySelectMenu:updateFunction(input) end

--- Sorts the inventory and genertes a new menu to replace this one with, reselecting any
--- selected slot in the process.
function InventorySelectMenu:SortCommand() end

--- Returns a newly created copy of this object
--- @return InventorySelectMenu an ``InventorySelectMenu``.
function InventorySelectMenu:cloneMenu() end

--- Updates the summary window.
function InventorySelectMenu:updateSummary()
    self.summary:SetItem(_DATA.Save.ActiveTeam:GetInv(self.slotList[self.menu.CurrentChoiceTotal+1].Slot))
end

--- Extract the list of selected slots.
--- @param list integer[] a table array containing the menu indices of the chosen items.
--- @return InvSlot[] a table array containing ``RogueEssence.Dungeon.InvSlot`` objects.
function InventorySelectMenu:multiConfirm(list) end





ItemChosenMenu = Class("ItemChosenMenu")

--- Creates a new ``ItemChosenMenu`` instance using the provided object as parent.
--- @param slots table the list of selected InvSlots
--- @param parent Menu the parent menu
--- @param confirm_text function the confirm button text
--- @param confirm_action function the function that is called when the confirm button is pressed
--- @param label string the label that will be applied to this menu. Defaults to "ITEM_CHOSEN_MENU_LUA"
function ItemChosenMenu:initialize(slots, parent, confirm_text, confirm_action, label) end

function ItemChosenMenu:choose(result) end






--- Creates a basic ``InventorySelectMenu`` instance using the provided parameters, then runs it and returns its output.
--- @param title string the title this window will have
--- @param filter function a function that takes a ``RogueEssence.Dungeon.InvSlot`` object and returns a boolean. Any ``InvSlot`` that does not pass this check will have its option disabled in the menu. Defaults to ``return true``.
--- @param confirm_text string the text used by the confirm sub-menu's confirm option. If nil, the sub-menu will be skipped entirely.
--- @param includeEquips boolean if true, the party's equipped items will be included in the menu. Defaults to true.
--- @param max_choices number if set, it will never be possible to select more than the amount of items defined here. Defaults to the amount of selectable items.
--- @return table a table array containing the chosen ``RogueEssence.Dungeon.InvSlot`` objects.
function InventorySelectMenu.run(title, filter, confirm_text, includeEquips, max_choices) end