--[[
    ExporterMenu

    Menu used to view an exporter shop data and interact with it.
]]

require 'pmd_new_leaf.menu.summary.EditableSummary'

--- @class ExporterMenu : Class Menu used to view an exporter's stock and interact with it.
ExporterMenu = Class("ExporterMenu")

--- Creates a new ``ExporterMenu`` instance using the provided plot data and callbacks.
--- @param data ExporterData the shop's data table
--- @param confirm_action fun(index:integer) the function that is called when the confirm button is pressed
function ExporterMenu:initialize(data, confirm_action, refuse_action)

    -- constants
    self.MAX_ELEMENTS = 8

    -- parsing data
    self.title = STRINGS:FormatKey("EXPORTER_MENU_TITLE")
    self.confirmAction = confirm_action
    self.refuseAction = refuse_action
    self.menuWidth = 176
    self.slotList = data.stock
    self.max_entries = data.slots
    self.optionsList = self:generate_options()

    self.choice = nil -- result
    self.confirm_answer = false

    -- creating the menu
    local origin = RogueElements.Loc(16,16)
    local option_array = luanet.make_array(RogueEssence.Menu.MenuElementChoice, self.optionsList)
    self.menu = RogueEssence.Menu.ScriptableMultiPageMenu(origin, self.menuWidth, self.title, option_array, 0, self.MAX_ELEMENTS, refuse_action, refuse_action)
    self.menu.ChoiceChangedFunction = function() self:updateSummary() end

    -- create the summary windows
    local GraphicsManager = RogueEssence.Content.GraphicsManager

    self.summary = EditableSummaryWindow:new(16, self.menu.Bounds.Bottom, GraphicsManager.ScreenWidth-16, GraphicsManager.ScreenHeight-8)
    self.progress_summary = ExporterProgressWindow:new(self.menu.Bounds.Right, self.menu.Bounds.Bottom - 14*2 - GraphicsManager.MenuBG.TileHeight*2)
    self.menu.SummaryMenus:Add(self.summary.window)
    self.menu.SummaryMenus:Add(self.progress_summary.window)
    self:updateSummary()
end

--- Processes the menu's properties and generates the ``RogueEssence.Menu.MenuElementChoice`` list that will be displayed.
--- @return userdata[] #a list of ``RogueEssence.Menu.MenuElementChoice`` objects.
function ExporterMenu:generate_options()
    local options = {}
    for i=1, #self.slotList, 1 do
        local slot = self.slotList[i]
        local item = COMMON_FUNC.TblToInvItem(slot.item)

        local name = item:GetDisplayName()
        local price = tostring(item:GetSellValue())
        local text_name = RogueEssence.Menu.MenuText(name, RogueElements.Loc(2, 1), Color.White)
        local text_price = RogueEssence.Menu.MenuText(price, RogueElements.Loc(self.menuWidth - 32, 1), RogueElements.DirV.Up, RogueElements.DirH.Right, Color.Lime)
        local option = RogueEssence.Menu.MenuElementChoice(function() self:choose(i) end, true, text_name, text_price)
        table.insert(options, option)
    end

    if #self.slotList < self.max_entries then
        local active = GAME:GetPlayerBagCount() + GAME:GetPlayerEquippedCount() > 0
        local color = Color.White
        if not active then color = Color.Red end
        local text_deposit = RogueEssence.Menu.MenuText(STRINGS:FormatKey("EXPORTER_OPTION_DEPOSIT"), RogueElements.Loc(7, 1), color)
        local option = RogueEssence.Menu.MenuElementChoice(function() self:choose(-1) end, active, text_deposit)
        table.insert(options, option)
    end

    return options
end

--- Closes the menu and calls the menu's confirmation callback.
--- @param index integer the index of the chosen item
function ExporterMenu:choose(index)
    if index>=0 then
        local choose = function(answer)
            if answer then
                _MENU:RemoveMenu()
                self.confirmAction(index)
            end
        end
        local menu = ExporterConfirmMenu:new(_DATA:GetItem(self.slotList[index].item.ID), self.menu, choose)
        _MENU:AddMenu(menu.menu, true)
    elseif index<0 or self.confirm_answer then
        _MENU:RemoveMenu()
        self.confirmAction(index)
    end
end


--- Updates the summary window.
function ExporterMenu:updateSummary()
    local slot = self.menu.CurrentChoiceTotal+1
    if slot > #self.slotList then
        self.summary:SetData(STRINGS:FormatKey("EXPORTER_DEPOSIT_DESC"),"", STRINGS:FormatKey("EXPORTER_SLOTS", #self.slotList, self.max_entries))
        self.menu.SummaryMenus:Clear()
        self.menu.SummaryMenus:Add(self.summary.window)
    else
        if self.menu.SummaryMenus.Count<2 then
            self.menu.SummaryMenus:Add(self.progress_summary.window)
        end
        self.summary:SetItem(_DATA:GetItem(self.slotList[slot].item.ID))
        self.progress_summary:SetProgress(self.slotList[slot].state, self.slotList[slot].sell_at)
    end
end





---@class ExporterConfirmMenu : Class A menu that asks the player what to do with the chosen exporter item
ExporterConfirmMenu = Class("ExporterConfirmMenu")

--- Creates a new ``ExporterConfirmMenu`` instance using the provided object as parent.
--- @param item ItemData the selected Item
--- @param parent Menu the C# parent menu
--- @param confirm fun(answer:boolean) the function that will be called when giving an answer to the menu. The parameter is true if the player wants to take the item, false otherwise.
function ExporterConfirmMenu:initialize(item, parent, confirm)
    local x, y = parent.Bounds.Right, parent.Bounds.Top
    local width = 72
    self.item = item
    self.confirmAction = confirm
    local options = {
        {STRINGS:FormatKey("MENU_ITEM_TAKE"), GAME:GetPlayerBagCount() + GAME:GetPlayerEquippedCount() < GAME:GetPlayerBagLimit(), function() self:choose(true) end},
        {STRINGS:FormatKey("MENU_INFO"),      true, function() _MENU:AddMenu(RogueEssence.Menu.TeachInfoMenu(self.item), false) end},
        {STRINGS:FormatKey("MENU_CANCEL"),    true, function() self:choose(false) end}
    }
    if self.item.UsageType ~= RogueEssence.Data.ItemData.UseType.Learn then
        table.remove(options, 2)
    end

    self.menu = RogueEssence.Menu.ScriptableSingleStripMenu(x, y, width, options, 0, function() self:choose(false) end)
end

---Wrapper function for the callback that also closes the menu.
---@param result boolean the answer chosen by the player
function ExporterConfirmMenu:choose(result)
    _MENU:RemoveMenu()
    self.confirmAction(result)
end






---@class ExporterProgressWindow : Class Window that displays the selling progress of the hoveder item
ExporterProgressWindow = Class("ExporterProgressWindow")

---Initializes the window that displays the selling progress for the currently hovered item
---@param left integer the x coordinate of the left side of the window relative to the screen's origin
---@param top integer the y coordinate of the top of the window relative to the screen's origin
function ExporterProgressWindow:initialize(left, top)
    local GraphicsManager = RogueEssence.Content.GraphicsManager
    self.window = RogueEssence.Menu.SummaryMenu(RogueElements.Rect.FromPoints(
            RogueElements.Loc(left, top),
            RogueElements.Loc(GraphicsManager.ScreenWidth-16, top + 14*2 + GraphicsManager.MenuBG.TileHeight*2)))

    self.progress = RogueEssence.Menu.MenuText("", RogueElements.Loc(self.window.Bounds.Width/2, GraphicsManager.MenuBG.TileHeight + 14), RogueElements.DirH.None)
    self.window.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("EXPORTER_PROGRESS"), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight), RogueElements.DirH.Left))
    self.window.Elements:Add(self.progress)
end

---Sets the progress number to display
---@param current integer the current progress
---@param max integer the maximum value for the progress
function ExporterProgressWindow:SetProgress(current, max)
    self.progress:SetText(STRINGS:FormatKey("EXPORTER_PROGRESS_NUMBER", current, max))
end









--- Creates an ``ExporterMenu`` instance using the provided plot data, then runs it and returns its output.
--- @param data ExporterData the shop's data table
--- @return integer #the index of the selected object if one was selected, -1 if a deposit was requested, nil if the menu has been closed.
function ExporterMenu.run(data)
    local ret
    local choose = function(index)
        ret = index
    end
    local refuse = function() _MENU:RemoveMenu() end
    local menu = ExporterMenu:new(data, choose, refuse)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end
