--[[
    ScrollListMenu.lua

    Represents a menu that can be scrolled up or down
--]]

require 'pmd_new_leaf.menu.GraphicsEssential'

ScrollListMenu = Class("ScrollListMenu")

--- Creates a new ``ScrollListMenu`` instance using the provided list and callbacks.
--- @param x number the x coordinate of this menu's origin
--- @param y number the y coordinate of this menu's origin
--- @param options table the list of options. Every entry can be either a string or a {string, boolean, Color} table. string is the displayed text, boolean is the enabled state and Color is the text color.
--- @param callback function the function called when the menu is closed. It will have the chosen option's number passed to it as a parameter, or -1 if none was selected.
--- @param min_width number the minimum width tis menu can have. The actual width will be calculated depending on the options' text.
--- @param no_expand boolean if true, the menu will not be expanded horizontally even if the text of some options can't fit
--- @param max_elem number the maximum number of elements allowed on screen at the same time. It must be at least 3. Defaults to 8.
function ScrollListMenu:initialize(x, y, options, callback, min_width, no_expand, max_elem)
    assert(self, "RecruitMainChoice:initialize(): self is nil!")
    self.selected = 1 --cursor position inside full list
    self.pos = 1 --cursor position inside visible span

    self.choices = self:LoadOptions(options) --list of all choices
    self.visible = {}                        --list of visible choices

    self.MAX_ELEM = math.max(max_elem or 8)                 -- max menu size
    self.ELEMENTS = math.min(#self.choices, self.MAX_ELEM)  -- actual menu size
    self.start_from = 1                                    -- displayed option starting point
    self.callback = callback

    self.arrow_visible_up = false
    self.arrow_visible_dn = false
    self.arrows = #self.choices > self.MAX_ELEM

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
        if self.selected > 1 then
            _GAME:SE("Menu/Skip")
            self:updateSelection(-1)
        else
            _GAME:SE("Menu/Cancel")
            self.selected = 1
            self.pos = 1
            self.start_from = 1
        end
        self:DrawMenu()
    elseif self:directionHold(input, RogueElements.Dir8.Down) then
        if self.selected<#self.choices then
            _GAME:SE("Menu/Skip")
            self:updateSelection(1)
        else
            _GAME:SE("Menu/Cancel")
            self.selected = #self.choices
            self.pos = self.ELEMENTS
            self.start_from = #self.choices+1 - self.ELEMENTS
        end
        self:DrawMenu()
    end
end

function ScrollListMenu:Choose(index)
    self.callback(index)
end

function ScrollListMenu:Refuse()
    self.callback(-1)
end

function ScrollListMenu:directionHold(input, direction)
    return RogueEssence.Menu.InteractableMenu.IsInputting(input, direction)
end

function ScrollListMenu:updateSelection(change)
    local start = self.selected
    self.selected = math.clamp(1,self.selected + change, #self.choices)
    if self.selected == 1 then self.pos = 1
    elseif self.selected == #self.choices then self.pos = self.ELEMENTS
    else self.pos = math.clamp(2,self.pos + change, self.ELEMENTS-1) end
    self.start_from = self.selected+1 - self.pos
    self.cursor:ResetTimeOffset()
    self.arrow_up:ResetTimeOffset()
    self.arrow_dn:ResetTimeOffset()
    return start ~= self.selected
end





function ScrollListMenu.run(options)
    local ret
    local callback = function(index)
        ret = index
    end
    local menu = ScrollListMenu:new(16, 16, options, callback, 64, false, 8)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end