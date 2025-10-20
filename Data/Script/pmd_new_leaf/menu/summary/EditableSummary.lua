---@class EditableSummaryWindow : Class A window that can either display an item summary or a custom set of strings.
EditableSummaryWindow = Class("EditableSummaryWindow")

---Initializes the exporter menu's summary window.
---@param left integer the x coordinate of the left side of the window relative to the screen's origin
---@param top integer the y coordinate of the top of the window relative to the screen's origin
---@param right integer the x coordinate of the right side of the window relative to the screen's origin
---@param bottom integer the y coordinate of the bottom of the window relative to the screen's origin
function EditableSummaryWindow:initialize(left, top, right, bottom)
    self.window = RogueEssence.Menu.SummaryMenu(RogueElements.Rect.FromPoints(
            RogueElements.Loc(left, top), RogueElements.Loc(right, bottom)))

    local GraphicsManager = RogueEssence.Content.GraphicsManager
    self.description_box = RogueEssence.Menu.DialogueText("", RogueElements.Rect.FromPoints(
            RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight),
            RogueElements.Loc(self.window.Bounds.Width - GraphicsManager.MenuBG.TileWidth * 4, self.window.Bounds.Height - GraphicsManager.MenuBG.TileHeight * 4)),
            12)
    self.price_box = RogueEssence.Menu.MenuText("", RogueElements.Loc(self.window.Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + 4 * 12), RogueElements.DirH.Right)
    self.rarity = RogueEssence.Menu.MenuText("", RogueElements.Loc(GraphicsManager.MenuBG.TileWidth * 2, GraphicsManager.MenuBG.TileHeight + 4 * 12), RogueElements.DirH.Left)

    self.window.Elements:Add(self.description_box)
    self.window.Elements:Add(self.price_box)
    self.window.Elements:Add(self.rarity)
end

---Updates the window with a new item.
---@param item ItemData the item to display the summary of
function EditableSummaryWindow:SetItem(item)
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
        rarity = STRINGS:FormatKey("MENU_ITEM_RARITY", rarity)
    else
        rarity = ""
    end

    self:SetData(descr, rarity, price)
end

---Updates the window using custom data
---@param description string a description to display
---@param rarity string a text to display in the rarity section
---@param price string a text to display in the price section
function EditableSummaryWindow:SetData(description, rarity, price)
    self.description_box:SetAndFormatText(description)
    self.price_box:SetText(price)
    self.rarity:SetText(rarity)
end