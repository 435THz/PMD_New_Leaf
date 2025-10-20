require 'pmd_new_leaf.menu.ChooseAmountMenu'

---@class CraftingMenu : Class Menu that handles crafting recipes
CraftingMenu = Class('CraftingMenu')

---Initializes a new CraftingMenu
---@param recipes CafeRecipe[] the list of recipes
---@param confirm_action fun(index:integer,amount:integer) the funtion called when a craft is decided
---@param refuse_action fun() the function called when the menu closes without any confirmation
---@param menu_width integer minimum width of the menu
function CraftingMenu:initialize(recipes, confirm_action, refuse_action, menu_width)
    -- constants
    self.MAX_ELEMENTS = 8

    -- parsing data
    self.title = STRINGS:FormatKey("CAFE_CRAFT_TITLE")
    self.confirmAction = confirm_action
    self.refuseAction = refuse_action
    self.menuWidth = menu_width or 176
    self.items, self.ingredients = self:generate_lists(recipes)
    self.optionsList = self:generate_options()

    -- creating the menu
    local origin = RogueElements.Loc(16,16)
    local option_array = luanet.make_array(RogueEssence.Menu.MenuElementChoice, self.optionsList)
    self.menu = RogueEssence.Menu.ScriptableMultiPageMenu(origin, self.menuWidth, self.title, option_array, 0, math.min(#self.items, self.MAX_ELEMENTS), refuse_action, refuse_action, false)
    self.menu.ChoiceChangedFunction = function() self:updateSummary() end

    -- create the summary window
    local GraphicsManager = RogueEssence.Content.GraphicsManager

    self.summary = RogueEssence.Menu.ItemSummary(RogueElements.Rect.FromPoints(
            RogueElements.Loc(16, GraphicsManager.ScreenHeight - 8 - GraphicsManager.MenuBG.TileHeight * 2 - 14 * 4), --LINE_HEIGHT = 12, VERT_SPACE = 14
            RogueElements.Loc(GraphicsManager.ScreenWidth - 16, GraphicsManager.ScreenHeight - 8)))
    self.menu.SummaryMenus:Add(self.summary)
    self.recipe_summary = RecipeSummary:new(self)
    self.menu.SummaryMenus:Add(self.recipe_summary.window)
    self:updateSummary()
end

---Generates the list of results and ingredients used by the menu
---@param recipes CafeRecipe[] the list of recipes
---@return ItemEntry[] #a list of results
---@return ItemEntry[][] #a list of ingredient lists. Their index is the same as their result' index
function CraftingMenu:generate_lists(recipes)
    local results, ingredients = {}, {}
    for _, recipe in ipairs(recipes) do
        local result_id = recipe.Item
        local result_amount = recipe.Amount or 1

        local ingredients_list = {}
        for _, item in ipairs(recipe.ReqItems) do
            local ingr_id, ingr_amount = "", 1
            if type(item) == "table" then ingr_id, ingr_amount = item[1], item[2]
            else ingr_id = item end
            table.insert(ingredients_list, {Item = ingr_id, Amount = ingr_amount})
        end
        if #ingredients_list>0 then
            table.insert(results, {Item = result_id, Amount = result_amount})
            table.insert(ingredients, ingredients_list)
        end
    end
    return results, ingredients
end

--- Processes the menu's properties and generates the ``RogueEssence.Menu.MenuElementChoice`` list that will be displayed.
--- @return userdata[] #a list of ``RogueEssence.Menu.MenuElementChoice`` objects.
function CraftingMenu:generate_options()
    local options = {}
    for i=1, #self.items, 1 do
        local entry = self.items[i]
        local item = RogueEssence.Dungeon.InvItem(entry.Item, false, entry.Amount)
        local enabled = math.floor(COMMON.GetPlayerItemCount(self.ingredients[i][1].Item, true)/(self.ingredients[i][1].Amount)) > 0
                        and (not self.ingredients[i][2] or math.floor(COMMON.GetPlayerItemCount(self.ingredients[i][2].Item, true)/(self.ingredients[i][2].Amount)) > 0)
        local color = Color.White
        if not enabled then color = Color.Red end

        local name = item:GetDisplayName()
        local text_name = RogueEssence.Menu.MenuText(name, RogueElements.Loc(2, 1), color)
        local option = RogueEssence.Menu.MenuElementChoice(function() self:choose(i) end, enabled, text_name)
        table.insert(options, option)
    end
    return options
end

--- Opens the CraftAmountMenu.
--- @param index integer the index of the chosen item
function CraftingMenu:choose(index)
    local choose = function(answer)
        if answer then
            _MENU:RemoveMenu()
            self.confirmAction(index, answer)
        end
    end
    local menu = CraftAmountMenu:new(self.items[index], self.ingredients[index], self.menu, self.recipe_summary, choose)
    _MENU:AddMenu(menu.menu, true)
end

--- Updates the summary window.
function CraftingMenu:updateSummary()
    local index = self.menu.CurrentChoiceTotal+1
    self.summary:SetItem(RogueEssence.Dungeon.InvItem(self.items[index].Item, false, self.items[index].Amount))
    self.recipe_summary:SetRecipe(self.ingredients[index], self.items[index])
end




---@class RecipeSummary : Class
RecipeSummary = Class('RecipeSummary')

---Initializes the summary window that handles recipes
---@param parent CraftingMenu the parent menu
function RecipeSummary:initialize(parent)
    local left, bottom, right = parent.menu.Bounds.Right, parent.summary.Bounds.Y, parent.summary.Bounds.Right
    local top = bottom - Graphics.Manager.MenuBG.TileHeight * 2 - 14 * 5
    self.window = RogueEssence.Menu.SummaryMenu(RogueElements.Rect(left, top, right-left, bottom-top))
    self.ingredients = {}
    self.result_item = nil
    self.crafts = 1

    self.window.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("CAFE_CRAFT_RECIPE"), RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth*1.5, Graphics.Manager.MenuBG.TileHeight)))
    self.ingredient1 = RogueEssence.Menu.MenuText("", RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth*1.5, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE))
    self.ingredient2 = RogueEssence.Menu.MenuText("", RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth*1.5, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*2))
    local arrow_dn = RogueEssence.Content.AnimData("arrow_dn", 1)
    self.window.Elements:Add(RogueEssence.Menu.MenuDirTex(RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth*3, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*3), RogueEssence.Menu.MenuDirTex.TexType.Object, arrow_dn))
    self.result = RogueEssence.Menu.MenuText("", RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth*1.5, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*4))

    self.window.Elements:Add(self.ingredient1)
    self.window.Elements:Add(self.ingredient2)
    self.window.Elements:Add(self.result)
end

---Loads the given recipe into the display elements
---@param ingredients ItemEntry[]
---@param result ItemEntry
function RecipeSummary:SetRecipe(ingredients, result)
    self.ingredients = { ingredients[1], ingredients[2] }
    self.result_item = result
    self:UpdateText()
end
---Multiplies the amount of ingredients and results according to the given amount of crafts
---@param value integer the number of crafts to calculate
function RecipeSummary:SetMultiplier(value)
    self.crafts = value
    self:UpdateText()
end

---Updates the display text based on the values stored in the menu's fields
function RecipeSummary:UpdateText()
    local text1, enough1 = self:PrintIngredientAmount(1)
    local text2, enough2 = self:PrintIngredientAmount(2)
    self.ingredient1:SetText(text1)
    self.ingredient2:SetText(text2)
    if enough1 then self.ingredient1.Color = Color.White else self.ingredient1.Color = Color.Red end
    if enough2 then self.ingredient2.Color = Color.White else self.ingredient2.Color = Color.Red end
    self.result:SetText(COMMON_FUNC.PrintItemAmount(self.result_item.Item, self.result_item.Amount * self.crafts, true))
    if enough1 and enough2 then self.result.Color = Color.White else self.result.Color = Color.Red end
end

---Returns the display text for the given ingredient, and a boolean that represents whether or not the player has enough copies of the item.
---@param index integer the index of the ingredient in the recipe
---@return string #the display text for the ingredient
---@return boolean #true if the player has enough copies to craft the recipe, false otherwise
function RecipeSummary:PrintIngredientAmount(index)
    if #self.ingredients < index then return "", true end
    local item_id = self.ingredients[index].Item
    local amount = self.ingredients[index].Amount * self.crafts
    amount = math.max(0, amount or 0)
    if item_id == "(P)" then
        local amount_player = COMMON_FUNC.GetMoney(true)
        return STRINGS:FormatKey("MONEY_AMOUNT", STRINGS:Format("{0}/{1}", string.format("%d", amount_player), string.format("%d", amount))), amount_player>=amount
    end
    local data = _DATA:GetItem(item_id)
    local name = data.Name:ToLocal()
    local amount_player = COMMON.GetPlayerItemCount(self.ingredients[index].Item, true)
    local str = STRINGS:Format("[color=#FFCEFF]{0} ({1}/{2})[color]", name, string.format("%d", amount_player), string.format("%d", amount))

    return str, amount_player>=amount
end






---@class CraftAmountMenu : ChooseAmountMenu the menu handler for selecting the number of crafts to make
CraftAmountMenu = Class('CraftAmountMenu', ChooseAmountMenu)

---Initializes a new CraftAmountMenu
---@param result ItemEntry the result of the recipe
---@param ingredients ItemEntry[] the ingredients of the recipe
---@param parent Menu the parent menu
---@param summary RecipeSummary the recipe summary menu
---@param callback fun(amount:integer) a function that is called when the desired amount of crafts to make is chosen
function CraftAmountMenu:initialize(result, ingredients, parent, summary, callback)
    self.item = result
    self.ingredients = ingredients
    self.summary = summary
    local max = math.floor(COMMON.GetPlayerItemCount(ingredients[1].Item, true)/(ingredients[1].Amount))
    if ingredients[2] then max = math.min(math.floor(COMMON.GetPlayerItemCount(ingredients[2].Item, true)/(ingredients[2].Amount)), max) end

    local x, y = parent.Bounds.Right, self.summary.window.Bounds.Top-50
    local w, h = 64, 50
    ChooseAmountMenu.initialize(self, x, y, w, h, "", 1, 1, max, callback)
end

---Processes inputs
---@param input any the input object
function CraftAmountMenu:Update(input)
    if input:JustPressed(RogueEssence.FrameInput.InputType.Confirm) then
        _GAME:SE("Menu/Confirm")
        self.callback(self.number)
        _MENU:RemoveMenu()
    elseif input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) or
            input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
        _GAME:SE("Menu/Skip")
        self.summary:SetMultiplier(1)
        self.callback()
        _MENU:RemoveMenu()
    elseif self:directionHold(input, RogueElements.Dir8.Up) then
        self:change_number( 1)
        self.summary:SetMultiplier(self.number)
    elseif self:directionHold(input, RogueElements.Dir8.Down) then
        self:change_number(-1)
        self.summary:SetMultiplier(self.number)
    elseif self:directionHold(input, RogueElements.Dir8.Left) then
        if self.selected<self.digits then
            _GAME:SE("Menu/Skip")
            self.selected = self.selected+1
            self:DrawMenu()
        else
            self.selected = self.digits
            _GAME:SE("Menu/Cancel")
        end
    elseif self:directionHold(input, RogueElements.Dir8.Right) then
        if self.selected>0 then
            _GAME:SE("Menu/Skip")
            self.selected = self.selected-1
            self:DrawMenu()
        else
            self.selected = 0
            _GAME:SE("Menu/Cancel")
        end
    end
end






---Runs a new Crafting Menu using the provided list of recipes
---@param recipes CafeRecipe[] the recipes to display
---@return integer #the index of the selected entry
---@return integer #the number of times the craft has been requested
function CraftingMenu.run(recipes)
    local ret, ret2
    local choose = function(index, amount) ret, ret2 = recipes[index], amount end
    local refuse = function() _MENU:RemoveMenu() end
    local menu = CraftingMenu:new(recipes, choose, refuse, 162)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret, ret2
end