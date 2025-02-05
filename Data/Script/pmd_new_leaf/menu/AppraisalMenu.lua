--[[
    AppraisalMenu

    Menu used to view an appraisal shop data and interact with it.
]]


--- Menu used to view an appraisal's stock and interact with it.
AppraisalMenu = Class("AppraisalMenu")

--- Creates a new ``AppraisalMenu`` instance using the provided plot data and callbacks.
--- @param data table the shop's data table
--- @param confirm_action function the function that is called when the confirm button is pressed
--- @param refuse_action function the function that is called when the refuse button is pressed
function AppraisalMenu:initialize(data, confirm_action, refuse_action)

    -- constants
    self.MAX_ELEMENTS = 8

    -- parsing data
    self.title = STRINGS:FormatKey("APPRAISAL_MENU_TITLE")
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

    self.summary = ExporterSummaryWindow:new(16, self.menu.Bounds.Bottom, GraphicsManager.ScreenWidth-16, GraphicsManager.ScreenHeight-8)
    self.progress_summary = AppraisalProgressWindow:new(self.menu.Bounds.Right, self.menu.Bounds.Bottom - 14*2 - GraphicsManager.MenuBG.TileHeight*2)
    self.menu.SummaryMenus:Add(self.summary.window)
    self.menu.SummaryMenus:Add(self.progress_summary.window)
    self:updateSummary()
end

--- Processes the menu's properties and generates the ``RogueEssence.Menu.MenuElementChoice`` list that will be displayed.
--- @return table a list of ``RogueEssence.Menu.MenuElementChoice`` objects.
function AppraisalMenu:generate_options()
    local options = {}
    for i=1, #self.slotList, 1 do
        local slot = self.slotList[i]
        local item = slot.item

        local enabled = slot.opened
        local name = item:GetDisplayName()
        local text_name = RogueEssence.Menu.MenuText(name, RogueElements.Loc(2, 1), Color.White)
        local option = RogueEssence.Menu.MenuElementChoice(function() self:choose(i) end, enabled, text_name)
        table.insert(options, option)
    end

    if #self.slotList < self.max_entries then
        local active = GAME:GetPlayerBagCount() + GAME:GetPlayerEquippedCount() > 0
        local color = Color.White
        if not active then color = Color.Red end
        local text_deposit = RogueEssence.Menu.MenuText(STRINGS:FormatKey("APPRAISAL_OPTION_DEPOSIT"), RogueElements.Loc(7, 1), color)
        local option = RogueEssence.Menu.MenuElementChoice(function() self:choose(-1) end, active, text_deposit)
        table.insert(options, option)
    end

    return options
end

--- Closes the menu and calls the menu's confirmation callback.
--- The result's index must be retrieved by accessing the choice variable of this object.
--- @param index number the index of the chosen character
function AppraisalMenu:choose(index)
    if index>=0 then
        local choose = function(answer)
            if answer then
                _MENU:RemoveMenu()
                self.confirmAction(index)
            end
        end
        local menu = AppraisalConfirmMenu:new(_DATA:GetItem(self.slotList[index].item.ID), self.menu, choose)
        _MENU:AddMenu(menu.menu, true)
    elseif index<0 or self.confirm_answer then
        _MENU:RemoveMenu()
        self.confirmAction(index)
    end
end


--- Updates the summary window.
function AppraisalMenu:updateSummary()
    local slot = self.menu.CurrentChoiceTotal+1
    if slot > #self.slotList then
        self.summary:SetData(STRINGS:FormatKey("APPRAISAL_DEPOSIT_DESC"),"", STRINGS:FormatKey("APPRAISAL_SLOTS", #self.slotList, self.max_entries))
        self.menu.SummaryMenus:Clear()
        self.menu.SummaryMenus:Add(self.summary.window)
    elseif self.slotList[slot].opened then
        self.summary:SetItem(_DATA:GetItem(self.slotList[slot].item.ID))
        self.menu.SummaryMenus:Clear()
        self.menu.SummaryMenus:Add(self.summary.window)
    else
        if self.menu.SummaryMenus.Count<2 then
            self.menu.SummaryMenus:Add(self.progress_summary.window)
        end
        self.summary:SetItem(_DATA:GetItem(self.slotList[slot].item.ID))
        self.progress_summary:SetProgress(self.slotList[slot].open_at - self.slotList[slot].state, self.slotList[slot].open_at)
    end
end






AppraisalConfirmMenu = Class("AppraisalConfirmMenu")

--- Creates a new ``AppraisalConfirmMenu`` instance using the provided object as parent.
--- @param item userdata the selected Item
--- @param parent userdata the parent menu
function AppraisalConfirmMenu:initialize(item, parent, confirm)
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

function AppraisalConfirmMenu:choose(result)
    _MENU:RemoveMenu()
    self.confirmAction(result)
end




ExporterSummaryWindow = Class("ExporterSummaryWindow")

function ExporterSummaryWindow:initialize(left, top, right, bottom)
    self.window = RogueEssence.Menu.SummaryMenu(RogueElements.Rect.FromPoints(
            RogueElements.Loc(left, top), RogueElements.Loc(right, bottom)))

    local GraphicsManager = RogueEssence.Content.GraphicsManager
    self.description_box = RogueEssence.Menu.DialogueText("", RogueElements.Rect.FromPoints(
            RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight),
            RogueElements.Loc(self.window.Bounds.Width - GraphicsManager.MenuBG.TileWidth * 4, self.window.Bounds.Height - GraphicsManager.MenuBG.TileHeight * 4)),
            12)
    self.price_box = RogueEssence.Menu.MenuText("", RogueElements.Loc(self.window.Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + 4 * 12), RogueElements.DirH.Right);
    self.rarity = RogueEssence.Menu.MenuText("", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + 4 * 12), RogueElements.DirH.Left);

    self.window.Elements:Add(self.description_box);
    self.window.Elements:Add(self.price_box);
    self.window.Elements:Add(self.rarity);
end

function ExporterSummaryWindow:SetItem(item)
    local descr  = item.Desc:ToLocal()
    local price  = ""
    local rarity = ""
    if item.Price > 0 then
        price = STRINGS:FormatKey("MENU_ITEM_VALUE", STRINGS:FormatKey("MONEY_AMOUNT", item.Price))
    end

    if item.Rarity > 0 then
        for _ = 0, item.Rarity, 1 do
            rarity = rarity.."\u{E10C}"
        end
        rarity = Text.FormatKey("MENU_ITEM_RARITY", rarity)
    else
        rarity = ""
    end

    self:SetData(descr, rarity, price)
end

function ExporterSummaryWindow:SetData(description, rarity, price)
    self.description_box:SetAndFormatText(description)
    self.price_box:SetText(price)
    self.rarity:SetText(rarity)
end







AppraisalProgressWindow = Class("AppraisalProgressWindow")

function AppraisalProgressWindow:initialize(left, top)
    local GraphicsManager = RogueEssence.Content.GraphicsManager
    self.window = RogueEssence.Menu.SummaryMenu(RogueElements.Rect.FromPoints(
            RogueElements.Loc(left, top),
            RogueElements.Loc(GraphicsManager.ScreenWidth-16, top + 14*2 + GraphicsManager.MenuBG.TileHeight*2)))

    self.progress = RogueEssence.Menu.MenuText("", RogueElements.Loc(self.window.Bounds.Width/2, GraphicsManager.MenuBG.TileHeight + 14), RogueElements.DirH.None)
    self.window.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("APPRAISAL_PROGRESS"), RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight), RogueElements.DirH.Left))
    self.window.Elements:Add(self.progress)
end

function AppraisalProgressWindow:SetProgress(current, max)
    self.progress:SetText(STRINGS:FormatKey("APPRAISAL_PROGRESS_NUMBER", current, max))
end









--- Creates an ``AppraisalMenu`` instance using the provided plot data, then runs it and returns its output.
--- @param data table the shop's data table
--- @return number the index of the selected object if one was selected, -1 if a deposit was requested, nil if the menu has been closed.
function AppraisalMenu.run(data)
    local ret
    local choose = function(index)
        ret = index
    end
    local refuse = function() _MENU:RemoveMenu() end
    local menu = AppraisalMenu:new(data, choose, refuse)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end
