--[[
    DungeonRestrictionMenu

    Menu used to view the dungeon restrictions before entering it. It asks for a yes/no.
]]

DungeonRestrictionMenu = Class("DungeonRestrictionMenu")

--- Creates a new ``DungeonRestrictionMenu`` using the provided callback.
--- @param confirm_action function the function that is called when the confirm button is pressed
function DungeonRestrictionMenu:initialize(confirm_action)

    self.confirmAction = confirm_action
    local options = {
        {STRINGS:FormatKey("DLG_CHOICE_YES"), true, function() self:choose(true)  end},
        {STRINGS:FormatKey("DLG_CHOICE_NO"),  true, function() self:choose(false) end}
    }

    self.menu = RogueEssence.Menu.ScriptableSingleStripMenu(0, 0, 0, options, 0, function() self:choose(false) end)

    self.summaryList = DungeonRestrictionList:new()
    self.summaryDialog = DungeonRestrictionDialog:new()
    self.menu.SummaryMenus:Add(self.summaryList.window)
    self.menu.SummaryMenus:Add(self.summaryDialog.window)

    local left, top = self.summaryDialog.window.Right - self.menu.Bounds.Width, self.summaryDialog.window.Top - self.menu.Bounds.Height
    self.menu.Bounds = RogueElements.Rect(left, top, self.menu.Bounds.Width, self.menu.Bounds.Height)
end


function DungeonRestrictionMenu:choose(result)
    _MENU:RemoveMenu()
    self.confirmAction(result)
end







DungeonRestrictionDialog = Class("DungeonRestrictionDialog")

function DungeonRestrictionDialog:initialize()
    local classBox = RogueEssence.Menu.DialogueBox
    local tl = RogueElements.Loc(classBox.SIDE_BUFFER, Graphics.Manager.ScreenHeight - (16 + classBox.TEXT_HEIGHT * classBox.MAX_LINES + classBox.VERT_PAD * 2))
    local br = RogueElements.Loc(Graphics.Manager.ScreenWidth - classBox.SIDE_BUFFER, Graphics.Manager.ScreenHeight - 8)
    self.window = RogueEssence.Menu.SummaryMenu(RogueElements.Rect.FromPoints(tl, br))

    local tl2 = RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth + classBox.HORIZ_PAD, Graphics.Manager.MenuBG.TileHeight + classBox.VERT_PAD + classBox.VERT_OFFSET)
    local br2 = RogueElements.Loc(self.window.Bounds.Width - Graphics.Manager.MenuBG.TileWidth * 2 - classBox.HORIZ_PAD * 2, self.window.Bounds.Height - Graphics.Manager.MenuBG.TileHeight * 2 - classBox.VERT_PAD * 2 - classBox.VERT_OFFSET * 2)
    self.window.Elements:Add(RogueEssence.Menu.DialogueText(STRINGS:FormatKey("NEW_RUN_PROMPT"), RogueElements.Rect.FromPoints(tl2, br2)), classBox.TEXT_HEIGHT)
end

DungeonRestrictionList = Class("DungeonRestrictionList")

function DungeonRestrictionDialog:initialize()
    local reqs = {}
    if SV.WishUpgrades.Player.TeamLimitUp<2 then
        table.insert(reqs, STRINGS:FormatKey("ZONE_RESTRICT_TEAM", SV.WishUpgrades.Player.TeamLimitUp+2))
    end
    table.insert(reqs, STRINGS:FormatKey("NEW_RUN_MONEY", _HUB.StartingMoneyTable[SV.WishUpgrades.Player.StartingMoneyUp]))
    if SV.WishUpgrades.Player.StartItems>0 then
        table.insert(reqs, STRINGS:FormatKey("ZONE_RESTRICT_ITEM", SV.WishUpgrades.Player.StartItems))
    else
        table.insert(reqs, STRINGS:FormatKey("ZONE_RESTRICT_ITEM_ALL"))
    end
    if SV.WishUpgrades.Player.StartBoosts < 8 then
        table.insert(reqs, STRINGS:FormatKey("NEW_RUN_BOOSTS", SV.WishUpgrades.Player.StartBoosts*32))
    end

    local tl = RogueElements.Loc(8, 8)
    local br = RogueElements.Loc(144, GraphicsManager.MenuBG.TileHeight * 2 + Graphics.VERT_SPACE * (reqs+1))
    self.window = RogueEssence.Menu.SummaryMenu(RogueElements.Rect.FromPoints(tl, br))

    self.window.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("NEW_RUN_TITLE"), RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth * 2, Graphics.Manager.MenuBG.TileHeight), Color.Orange))
    self.window.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth, Graphics.Manager.MenuBG.TileHeight + Graphics.LINE_HEIGHT), self.window.Bounds.Width - Graphics.Manager.MenuBG.TileWidth * 2))
    for i, string in ipairs(reqs) do
        self.window.Elements:Add(RogueEssence.Menu.MenuText(string, RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth * 2, Graphics.Manager.MenuBG.TileHeight + 16 + Graphics.VERT_SPACE * i)))
    end
end



--- Creates a basic ``SmallShopMenu`` instance using the provided parameters, then runs it and returns its output.
function DungeonRestrictionMenu.run()
    UI:WaitShowTimedDialogue(STRINGS:FormatKey("NEW_RUN_PROMPT"), 0)
    local ret = -1
    local choose = function(result) ret = result end
    local menu = DungeonRestrictionMenu:new(choose)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end