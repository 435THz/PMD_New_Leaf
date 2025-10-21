--[[
    ScrollListMenu.lua

    Represents a menu that can be scrolled up or down
--]]

require 'pmd_new_leaf.menu.GraphicsEssential'

---@class ScrollListMenu : LuaClass
ScrollListMenu = Class("ScrollListMenu")

--- Creates a new ``ScrollListMenu`` instance using the provided list and callbacks.
--- @param x integer the x coordinate of this menu's origin
--- @param y integer the y coordinate of this menu's origin
--- @param options (string|{[1]:string,[2]:boolean,[3]:userdata})[] the list of options. Every entry can be either a string or a {string, boolean, Color} table. string is the displayed text, boolean is the enabled state and Color is the text color.
--- @param callback fun(index:integer) the function called when the menu is closed. It will have the chosen option's number passed to it as a parameter, or -1 if none was selected.
--- @param start integer the 1-based index of the option that will be selected at the start. Defaults to 1
--- @param min_width integer the minimum width tis menu can have. The actual width will be calculated depending on the options' text.
--- @param no_expand boolean if true, the menu will not be expanded horizontally even if the text of some options can't fit
--- @param max_elem? integer the maximum number of elements allowed on screen at the same time. It must be at least 3. Defaults to 8.
function ScrollListMenu:initialize(x, y, options, callback, start, min_width, no_expand, max_elem)
    assert(self, "RecruitMainChoice:initialize(): self is nil!")
    self.selected = 1   --cursor position inside full list
    self.pos = 1        --cursor position inside visible span
    self.start_from = 1 --displayed options starting point

    self.choices = self:LoadOptions(options) --list of all choices
    self.visible = {}                        --list of visible choices

    self.MAX_ELEM = math.max(max_elem or 8)                 -- max menu size
    self.ELEMENTS = math.min(#self.choices, self.MAX_ELEM)  -- actual menu size
    self.callback = callback

    self.arrow_visible_up = false
    self.arrow_visible_dn = false
    self.arrows = #self.choices > self.MAX_ELEM

    if start then self:Select(start) end

    -- calculate window position using options text
    local w = min_width
    if not no_expand then w = self:CalcChoiceLength(w) end
    local h = Graphics.VERT_SPACE*self.ELEMENTS + Graphics.Manager.MenuBG.TileHeight*2 -2
    if self.arrows then h = h + Graphics.VERT_SPACE end

    self.menu  = RogueEssence.Menu.ScriptableMenu(x, y, w, h, function(input) self:Update(input) end)
    self.cursor = RogueEssence.Menu.MenuCursor(self.menu)
    self.arrow_up = RogueEssence.Menu.MenuCursor(self.menu, RogueElements.Dir4.Up)
    self.arrow_dn = RogueEssence.Menu.MenuCursor(self.menu, RogueElements.Dir4.Down)
    local arrow_x = math.floor((self.menu.Bounds.Width - Graphics.Manager.Cursor.TileWidth)/2)
    local arrow_y_up = Graphics.Manager.MenuBG.TileHeight + math.floor(Graphics.VERT_SPACE/2) - 2 - Graphics.Manager.Cursor.TileHeight
    local arrow_y_dn = self.menu.Bounds.Height - Graphics.Manager.MenuBG.TileHeight - math.floor(Graphics.VERT_SPACE/2)

    self.arrow_up.Loc = RogueElements.Loc(arrow_x, arrow_y_up)
    self.arrow_dn.Loc = RogueElements.Loc(arrow_x, arrow_y_dn)

    local offset = 1
    if self.arrows then offset = 0.5 end
    for i = 1, self.ELEMENTS, 1 do
        local slot = RogueEssence.Menu.MenuTextChoice("", function() end)
        slot.Bounds = RogueElements.Rect(RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth + 16 - 5, Graphics.Manager.MenuBG.TileHeight + math.floor(Graphics.VERT_SPACE * (i - offset)) - 1),
                RogueElements.Loc(self.menu.Bounds.Width - Graphics.Manager.MenuBG.TileWidth * 2 - 16 + 5 - 4, Graphics.VERT_SPACE - 2));
        table.insert(self.visible, slot)
        self.menu.Elements:Add(slot)
    end

    self.menu.Elements:Add(self.cursor)
    self:DrawMenu()
end

---Generates the menu's selectable options
---@param options (string|{[1]:string,[2]:boolean,[3]:userdata})[]
---@return MenuTextChoice[]
function ScrollListMenu:LoadOptions(options)
    local choices = {}
    for i, option in pairs(options) do
        local text = option
        local enabled = true
        local color = Color.White
        if type(option) == "table" then
            text = option[1] or text
            if option[2] ~= nil then enabled = option[2] end
            color = option[3] or color
        end
        local choice = RogueEssence.Menu.MenuTextChoice(text, function() self.callback(i) end, enabled, color)
        table.insert(choices, choice)
    end
    return choices
end

---Calculates the width necessary for all entries to be displayed fully
---@param start integer the starting window width
---@return integer #the final window width
function ScrollListMenu:CalcChoiceLength(start)
    local MenuTextChoiceType = luanet.import_type('RogueEssence.Menu.MenuTextChoice')
    local width = start
    for _, choice in pairs(self.choices) do
        if LUA_ENGINE:TypeOf(choice) == luanet.ctype(MenuTextChoiceType) then
            width = math.max(width, choice.Text:GetTextLength())
        end
    end
    width = math.ceil(width/4) * 4
    return width + 16 + Graphics.Manager.MenuBG.TileWidth * 2
end

---Updates the display elements of the menu
function ScrollListMenu:DrawMenu()
    --fill choices in
    local end_at = self.start_from+self.ELEMENTS - 1
    for i=self.start_from, end_at, 1 do
        local choice = self.choices[i]
        local slot = i - self.start_from+1
        self.visible[slot].Text = choice.Text
        self.visible[slot].ChoiceAction = choice.ChoiceAction
    end

    --position cursor
    local offset = 1
    if self.arrows then offset = 0.5 end
    self.cursor.Loc = RogueElements.Loc(10, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*(self.pos-offset))

    if self.start_from == 1 and self.arrow_visible_up then
        self.menu.Elements:Remove(self.arrow_up)
        self.arrow_visible_up = false
    elseif self.start_from > 1 and not self.arrow_visible_up then
        self.menu.Elements:Add(self.arrow_up)
        self.arrow_visible_up = true
    end

    if end_at == #self.choices and self.arrow_visible_dn then
        self.menu.Elements:Remove(self.arrow_dn)
        self.arrow_visible_dn = false
    elseif end_at < #self.choices and not self.arrow_visible_dn then
        self.menu.Elements:Add(self.arrow_dn)
        self.arrow_visible_dn = true
    end
end

---Processes inputs
---@param input InputManager
function ScrollListMenu:Update(input)
    if input:JustPressed(RogueEssence.FrameInput.InputType.Confirm) then
        self.choices[self.selected]:OnConfirm()
        if self.choices[self.selected].Enabled then
            _MENU:RemoveMenu()
        end
    elseif input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) or
            input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
        _GAME:SE("Menu/Cancel")
        self:Refuse()
        _MENU:RemoveMenu()
    elseif self:directionHold(input, RogueElements.Dir8.Up) then
        _GAME:SE("Menu/Skip")
        self:updateSelection(-1)
        self:DrawMenu()
    elseif self:directionHold(input, RogueElements.Dir8.Down) then
        _GAME:SE("Menu/Skip")
        self:updateSelection(1)
        self:DrawMenu()
    end
end

---Wraps the confirmation callback
---@param index integer the selected index
function ScrollListMenu:Choose(index)
    self.callback(index)
end

---Wraps the confirmation callback and passes -1 to it
function ScrollListMenu:Refuse()
    self.callback(-1)
end

--- Checks if a direction is being held and handles how often the options should shift
---@param input InputManager the input object
---@param direction userdata the direction being held
function ScrollListMenu:directionHold(input, direction)
    return RogueEssence.Menu.InteractableMenu.IsInputting(input, direction)
end

--- Changes the selected option
--- @param change integer the amount to change the selection by. Usually just +1 or -1
function ScrollListMenu:updateSelection(change)
    local start = self.selected
    self.selected = math.shifted_mod(self.selected+change, #self.choices)
    if self.selected == 1 then self.pos = 1
    elseif self.selected == #self.choices then self.pos = self.ELEMENTS
    else self.pos = math.clamp(2,self.pos + change, self.ELEMENTS-1) end
    self.start_from = self.selected+1 - self.pos
    self.cursor:ResetTimeOffset()
    self.arrow_up:ResetTimeOffset()
    self.arrow_dn:ResetTimeOffset()
    return start ~= self.selected
end

---Selects a specific index
---@param pos integer the index to select
function ScrollListMenu:Select(pos)
    pos = math.clamp(1, pos or self.selected, #self.choices)
    self.selected = pos
    self.start_from = math.clamp(1, pos - self.MAX_ELEM//2, #self.choices - self.ELEMENTS+1)
    self.pos = pos-self.start_from+1
end





--- Creates a ``ScrollListMenu`` instance using the provided parameters, then runs it and returns its output.
---@param options (string|{[1]:string,[2]:boolean,[3]:userdata})[] the list of options
---@param start integer the starting selection
---@return integer #the selected option
function ScrollListMenu.run(options, start)
    local ret
    local callback = function(index)
        ret = index
    end
    local menu = ScrollListMenu:new(16, 16, options, callback, start, 64, false, 8)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end