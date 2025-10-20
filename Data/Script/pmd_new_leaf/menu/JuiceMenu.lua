--[[
    JuiceMenu
    by MistressNebula

    Opens a menu, potentially with multiple pages, that allows the player to select one or
    more items in their inventory, visualizing the effect of the resulting drinks on the target.
    It contains a run method for quick instantiation.
    This menu is NOT SAFE FOR REPLAYS. Do NOT use in dungeons until further notice.
]]
require 'origin.common'
require 'origin.menu.InventorySelectMenu'

--- @class JuiceMenu : InventorySelectMenu Menu for selecting items to make juice with from the player's inventory.
JuiceMenu = Class("JuiceMenu", InventorySelectMenu)

--- Creates a new ``JuiceMenu`` instance using the provided list and callbacks.
--- @param character Character the ``RogueEssence.Dungeon.Character`` object the resulting drink's effect is to be applied to.
--- @param ingredients CafeBoostEntry[] a list of key-value pairs where key is an item id and the value is a table of drink effects. See ``ground.base_camp_2.base_camp_2_juice`` for examples.
--- @param confirm_action fun(cart:InvItem[]) the function called when the selection is confirmed. It will have a table array of ``RogueEssence.Dungeon.InvSlot`` objects passed to it as a parameter.
--- @param refuse_action fun() the function called when the player presses the cancel or menu button.
--- @param include_equips boolean if true, the menu will include equipped items.
--- @param boost_function fun(cart:InvItem[],char:Character,table:table<string,CafeBoostEntry>) the function that will be used by the preview window to calculate the total boost.
--- @param max_choices integer if set, it will never be possible to select more than the amount of items defined here. Defaults to the amount of selectable items.
function JuiceMenu:initialize(character, ingredients, confirm_action, refuse_action, include_equips, boost_function, max_choices)
    -- parsing data
    self.character = character
    self.ingredients = ingredients
    self.boost_function = boost_function
    -- generate enabled slots filter function
    local filter = function(slot)
        if slot.IsEquipped then
            local item = _DATA.Save.ActiveTeam.Players[slot.Slot].EquippedItem
            return not not self.ingredients[item.ID]
        else
            local item = _DATA.Save.ActiveTeam:GetInv(slot.Slot)
            return not not self.ingredients[item.ID]
        end
    end

    InventorySelectMenu.initialize(self, STRINGS:FormatKey("MENU_ITEM_TITLE"), filter, confirm_action, refuse_action, "Give", 176, include_equips, max_choices)

    -- create the summary window
    local GraphicsManager = RogueEssence.Content.GraphicsManager
    local left = self.menu.Bounds.Right
    local right = self.summary.Bounds.Right
    local bottom = self.summary.Bounds.Top
    local top = bottom - 14*5 - GraphicsManager.MenuBG.TileHeight*2

    self.preview = JuicePreviewSummary:new(left, top, right, bottom, self.character, self.ingredients, boost_function)
    self.menu.SummaryMenus:Add(self.preview.window)

    self:updateSummary()
end

--- Returns the list of ids of the items contained in the selected item slots.
--- @return InvSlot[] #a list of selected InvSlots.
function JuiceMenu:getCart()
    local list = {}
    for i, choice in pairs(self.optionsList) do
        if choice.Selected then
            table.insert(list,self.slotList[i])
        end
    end
    return list
end

--- Returns the selected menu option and its corresponding slot
--- @return {option:Selectable,slot:InvSlot} #a table containing an ``option`` and a ``slot`` property
function JuiceMenu:getSelectedOption()
    local i = self.menu.CurrentChoiceTotal+1
    return {
        option = self.optionsList[i],
        slot = self.slotList[i]
    }
end

--- Returns a newly created copy of this object
--- @return JuiceMenu #a ``JuiceMenu``.
function JuiceMenu:cloneMenu()
    return JuiceMenu:new(self.character, self.ingredients, self.confirmAction, self.refuseAction, self.includeEquips, self.boost_function)
end

--- Updates the summary windows
function JuiceMenu:updateSummary()
    InventorySelectMenu.updateSummary(self)
    if self.preview then
        local cart = self:getCart()
        local selected = self:getSelectedOption()
        self.preview:setSlots(cart, selected)
    end
end





---@class JuicePreviewSummary : LuaClass Summary menu that previews a drink's effect on a character's stats.
JuicePreviewSummary = Class("JuicePreviewSummary")

--- Generates a new JuicePreviewSummary object set in the provided coordinates using the provided data.
--- @param left integer the x coordinate of the left side of the window.
--- @param top integer the y coordinate of the top side of the window.
--- @param right integer the x coordinate of the right side of the window.
--- @param bottom integer the y coordinate of the bottom side of the window.
--- @param ingredient_effect_table table<string,CafeBoostEntry> a list of key-value pairs where key is an item id and the value is a table of drink effects. See ``ground.base_camp_2.base_camp_2_juice`` for examples.
--- @param boost_function fun(cart:InvItem[],char:Character,table:table<string,CafeBoostEntry>) the function that will be used by the preview window to calculate the total boost.
function JuicePreviewSummary:initialize(left, top, right, bottom, character, ingredient_effect_table, boost_function)
    self.boost_function = boost_function
    self.character = character
    self.ingredient_effect_table = ingredient_effect_table
    self.window = RogueEssence.Menu.SummaryMenu(RogueElements.Rect.FromPoints(
            RogueElements.Loc(left, top), RogueElements.Loc(right, bottom)))

    -- starting data
    self.startData = {
        MaxHPBonus = character.MaxHPBonus,
        AtkBonus   = character.AtkBonus,
        DefBonus   = character.DefBonus,
        MAtkBonus  = character.MAtkBonus,
        MDefBonus  = character.MDefBonus,
        SpeedBonus = character.SpeedBonus,
        }
    -- equal to base at the start. Apply drink changes here
    self.data = {
        MaxHPBonus = character.MaxHPBonus,
        AtkBonus   = character.AtkBonus,
        DefBonus   = character.DefBonus,
        MAtkBonus  = character.MAtkBonus,
        MDefBonus  = character.MDefBonus,
        SpeedBonus = character.SpeedBonus,
        Random = 0,
        MaxHPRand = 0,
        AtkRand   = 0,
        DefRand   = 0,
        MAtkRand  = 0,
        MDefRand  = 0,
        SpeedRand = 0
    }
    -- equal to base at the start. Changed every time the up-down arrows are pressed
    self.selection_data = {
        MaxHPBonus = character.MaxHPBonus,
        AtkBonus   = character.AtkBonus,
        DefBonus   = character.DefBonus,
        MAtkBonus  = character.MAtkBonus,
        MDefBonus  = character.MDefBonus,
        SpeedBonus = character.SpeedBonus,
        Random = 0,
        MaxHPRand = 0,
        AtkRand   = 0,
        DefRand   = 0,
        MAtkRand  = 0,
        MDefRand  = 0,
        SpeedRand = 0
    }

    local GraphicsManager = RogueEssence.Content.GraphicsManager
    local x_pos  = GraphicsManager.MenuBG.TileWidth * 2
    local x_pos2 = (self.window.Bounds.Width + GraphicsManager.MenuBG.TileWidth)//2 -3
    local x_pos3 = (self.window.Bounds.Width + GraphicsManager.MenuBG.TileWidth)//2 +3
    local x_pos4 = self.window.Bounds.Width - GraphicsManager.MenuBG.TileWidth * 2

    self.window.Elements:Add(RogueEssence.Menu.MenuText(character:GetDisplayName(false), RogueElements.Loc(x_pos, GraphicsManager.MenuBG.TileHeight)))
    self.window.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("CAFE_DRINK_BOOSTS"), RogueElements.Loc(x_pos, GraphicsManager.MenuBG.TileHeight+14)))

    local hp_label,  spd_label = STRINGS:FormatKey("_ENUM_Stat_HP_tinier"),      STRINGS:FormatKey("_ENUM_Stat_Speed_tinier")
    local atk_label, sat_label = STRINGS:FormatKey("_ENUM_Stat_Attack_tinier"),  STRINGS:FormatKey("_ENUM_Stat_MAtk_tinier")
    local def_label, sdf_label = STRINGS:FormatKey("_ENUM_Stat_Defense_tinier"), STRINGS:FormatKey("_ENUM_Stat_MDef_tinier")
    local rand_label = STRINGS:FormatKey("CAFE_DRINK_RANDOM")

    self.window.Elements:Add(RogueEssence.Menu.MenuText(hp_label,   RogueElements.Loc(x_pos,  GraphicsManager.MenuBG.TileHeight + 14*2)))
    self.window.Elements:Add(RogueEssence.Menu.MenuText(spd_label,  RogueElements.Loc(x_pos3, GraphicsManager.MenuBG.TileHeight + 14*2)))
    self.window.Elements:Add(RogueEssence.Menu.MenuText(atk_label,  RogueElements.Loc(x_pos,  GraphicsManager.MenuBG.TileHeight + 14*3)))
    self.window.Elements:Add(RogueEssence.Menu.MenuText(sat_label,  RogueElements.Loc(x_pos3, GraphicsManager.MenuBG.TileHeight + 14*3)))
    self.window.Elements:Add(RogueEssence.Menu.MenuText(def_label,  RogueElements.Loc(x_pos,  GraphicsManager.MenuBG.TileHeight + 14*4)))
    self.window.Elements:Add(RogueEssence.Menu.MenuText(sdf_label,  RogueElements.Loc(x_pos3, GraphicsManager.MenuBG.TileHeight + 14*4)))
    self.rand_label = RogueEssence.Menu.MenuText(rand_label, RogueElements.Loc(x_pos,  GraphicsManager.MenuBG.TileHeight + 14*5))

    self.hp_text   = RogueEssence.Menu.MenuText(tostring(self.data.MaxHPBonus),  RogueElements.Loc(x_pos2, GraphicsManager.MenuBG.TileHeight + 14*2),   RogueElements.DirH.Right)
    self.spd_text  = RogueEssence.Menu.MenuText(tostring(self.data.SpeedBonus),  RogueElements.Loc(x_pos4, GraphicsManager.MenuBG.TileHeight + 14*2),   RogueElements.DirH.Right)
    self.atk_text  = RogueEssence.Menu.MenuText(tostring(self.data.AtkBonus),    RogueElements.Loc(x_pos2, GraphicsManager.MenuBG.TileHeight + 14*3), RogueElements.DirH.Right)
    self.sat_text  = RogueEssence.Menu.MenuText(tostring(self.data.MAtkBonus),   RogueElements.Loc(x_pos4, GraphicsManager.MenuBG.TileHeight + 14*3), RogueElements.DirH.Right)
    self.def_text  = RogueEssence.Menu.MenuText(tostring(self.data.DefBonus),    RogueElements.Loc(x_pos2, GraphicsManager.MenuBG.TileHeight + 14*4), RogueElements.DirH.Right)
    self.sdf_text  = RogueEssence.Menu.MenuText(tostring(self.data.MDefBonus),   RogueElements.Loc(x_pos4, GraphicsManager.MenuBG.TileHeight + 14*4), RogueElements.DirH.Right)
    self.rand_text = RogueEssence.Menu.MenuText(tostring(self.data.Random),      RogueElements.Loc(x_pos3, GraphicsManager.MenuBG.TileHeight + 14*5))

    self.window.Elements:Add(self.hp_text)
    self.window.Elements:Add(self.spd_text)
    self.window.Elements:Add(self.atk_text)
    self.window.Elements:Add(self.sat_text)
    self.window.Elements:Add(self.def_text)
    self.window.Elements:Add(self.sdf_text)
    if SV.Intro.CafeRandomDiscovered then
        local bounds = self.window.Bounds
        self.window.Bounds = RogueElements.Rect(bounds.X, bounds.Y-14, bounds.Width, bounds.Height+14)
        self.window.Elements:Add(self.rand_label)
        self.window.Elements:Add(self.rand_text)
    end
end

--- Updates the list of currently selected items in the menu and then updates the menu itself.
--- @param list InvSlot[] a list of ``string`` item ids.
--- @param current_option {option:Selectable,slot:InvSlot} a table containing an ``option`` and a ``slot`` property
function JuicePreviewSummary:setSlots(list, current_option)
    self.cart = list
    self.selected_option = current_option
    self:updateData()
    self:updateMenu()
end

--- Updates the list of currently selected items in the menu and runs the total boost calculation, storing
--- all the data necessary for drawing the final effect of the boosts.
function JuicePreviewSummary:updateData()
    local selected = self.selected_option.option.Selected
    local slot = self.selected_option.slot

    local cart = {}
    local adj_cart = {}
    if not selected then table.insert(adj_cart, slot) end
    for _, elem in pairs(self.cart) do
        if not selected or elem.Slot~=slot.Slot or elem.IsEquipped~=slot.IsEquipped then
            table.insert(cart, elem)
        end
        table.insert(adj_cart, elem)
    end

    local changes,          random          = self.boost_function(cart,     self.character, self.ingredient_effect_table)
    local selected_changes, selected_random = self.boost_function(adj_cart, self.character, self.ingredient_effect_table)

    self.data.MaxHPBonus = self.startData.MaxHPBonus + changes.boosts.HP
    self.data.AtkBonus   = self.startData.AtkBonus   + changes.boosts.Atk
    self.data.DefBonus   = self.startData.DefBonus   + changes.boosts.Def
    self.data.MAtkBonus  = self.startData.MAtkBonus  + changes.boosts.SpAtk
    self.data.MDefBonus  = self.startData.MDefBonus  + changes.boosts.SpDef
    self.data.SpeedBonus = self.startData.SpeedBonus + changes.boosts.Speed
    self.data.Random     = random

    self.selection_data.MaxHPBonus = self.startData.MaxHPBonus + selected_changes.boosts.HP
    self.selection_data.AtkBonus   = self.startData.AtkBonus   + selected_changes.boosts.Atk
    self.selection_data.DefBonus   = self.startData.DefBonus   + selected_changes.boosts.Def
    self.selection_data.MAtkBonus  = self.startData.MAtkBonus  + selected_changes.boosts.SpAtk
    self.selection_data.MDefBonus  = self.startData.MDefBonus  + selected_changes.boosts.SpDef
    self.selection_data.SpeedBonus = self.startData.SpeedBonus + selected_changes.boosts.Speed
    self.selection_data.Random     = selected_random

    -- -------------------------------------------------------------- --

    local combine = function(value, rand)
        if rand > 0 then
            if value%2==0 then value=value+1 end --if 00 -> 01, if 10 -> 11
        elseif rand<0 then
            if value==0 or value==1 then value=value+2 end --if 00 -> 10, if 01 -> 11
        end
        return value
    end
    local store = function(data, changes_list)
        data.MaxHPRand, data.AtkRand, data.DefRand, data.MAtkRand, data.MDefRand, data.SpeedRand = 0, 0, 0, 0, 0, 0 --CLEAN UP, DAMMIT
        local mult = 1
        if changes_list.reverse_random then mult =-1 end
        for _, rand in ipairs(changes_list.random) do
            if rand.HP    then data.MaxHPRand = combine(data.MaxHPRand, rand.Amount*mult) end
            if rand.Atk   then data.AtkRand =   combine(data.AtkRand,   rand.Amount*mult) end
            if rand.Def   then data.DefRand =   combine(data.DefRand,   rand.Amount*mult) end
            if rand.SpAtk then data.MAtkRand =  combine(data.MAtkRand,  rand.Amount*mult) end
            if rand.SpDef then data.MDefRand =  combine(data.MDefRand,  rand.Amount*mult) end
            if rand.Speed then data.SpeedRand = combine(data.SpeedRand, rand.Amount*mult) end
        end
    end
    store(self.data,           changes)
    store(self.selection_data, selected_changes)

    -- -------------------------------------------------------------- --

    self.data.MaxHPBonus = math.max(0,math.min(self.data.MaxHPBonus, 256))
    self.data.AtkBonus   = math.max(0,math.min(self.data.AtkBonus,   256))
    self.data.DefBonus   = math.max(0,math.min(self.data.DefBonus,   256))
    self.data.MAtkBonus  = math.max(0,math.min(self.data.MAtkBonus,  256))
    self.data.MDefBonus  = math.max(0,math.min(self.data.MDefBonus,  256))
    self.data.SpeedBonus = math.max(0,math.min(self.data.SpeedBonus, 256))

    self.selection_data.MaxHPBonus = math.max(0,math.min(self.selection_data.MaxHPBonus, 256))
    self.selection_data.AtkBonus   = math.max(0,math.min(self.selection_data.AtkBonus,   256))
    self.selection_data.DefBonus   = math.max(0,math.min(self.selection_data.DefBonus,   256))
    self.selection_data.MAtkBonus  = math.max(0,math.min(self.selection_data.MAtkBonus,  256))
    self.selection_data.MDefBonus  = math.max(0,math.min(self.selection_data.MDefBonus,  256))
    self.selection_data.SpeedBonus = math.max(0,math.min(self.selection_data.SpeedBonus, 256))
end

--- Uses the currently stored data to apply changes to the display elements of the menu.
function JuicePreviewSummary:updateMenu()
    local getColor = function(change, pos, def, neg)
        if change>0 then return pos end
        if change<0 then return neg end
        return def
    end
    local getTextColor = function(change) return getColor(change, Color.Cyan, Color.White, Color.Red) end
    local getAdjustColor = function(change) return getColor(change, Color.Lime, Color.White, Color.Red) end
    local stat_randomness = function(data)
        local ret = ""
        if data%2==1 then ret = ret.."+" end
        data = math.floor(data/2)
        if data%2==1 then ret = ret.."-" end
        return ret
    end
    local stat_random_decimal = function(rand)
        local data = math.abs(rand)
        local sign = 0
        if data==0 then return 0 else sign = rand/data end
        local ret = 0
        if data%2==1 then ret = ret+0.2 end
        data = math.floor(data/2)
        if data%2==1 then ret = ret-0.1 end
        return ret*sign
    end

    -- compute stat difference for coloring. factor in random sign
    local hp_change   = self.data.MaxHPBonus + stat_random_decimal(self.data.MaxHPRand) - self.startData.MaxHPBonus
    local atk_change  = self.data.AtkBonus   + stat_random_decimal(self.data.AtkRand)   - self.startData.AtkBonus
    local def_change  = self.data.DefBonus   + stat_random_decimal(self.data.DefRand)   - self.startData.DefBonus
    local sat_change  = self.data.MAtkBonus  + stat_random_decimal(self.data.MAtkRand)  - self.startData.MAtkBonus
    local sdf_change  = self.data.MDefBonus  + stat_random_decimal(self.data.MDefRand)  - self.startData.MDefBonus
    local spd_change  = self.data.SpeedBonus + stat_random_decimal(self.data.SpeedRand) - self.startData.SpeedBonus
    local rand_change = self.data.Random
    -- compute stat adjustment for coloring. factor in random sign
    local hp_adjust   = self.selection_data.MaxHPBonus - self.data.MaxHPBonus + stat_random_decimal(self.selection_data.MaxHPRand - self.data.MaxHPRand)
    local atk_adjust  = self.selection_data.AtkBonus -   self.data.AtkBonus   + stat_random_decimal(self.selection_data.AtkRand   - self.data.AtkRand)
    local def_adjust  = self.selection_data.DefBonus -   self.data.DefBonus   + stat_random_decimal(self.selection_data.DefRand   - self.data.DefRand)
    local sat_adjust  = self.selection_data.MAtkBonus -  self.data.MAtkBonus  + stat_random_decimal(self.selection_data.MAtkRand  - self.data.MDefRand)
    local sdf_adjust  = self.selection_data.MDefBonus -  self.data.MDefBonus  + stat_random_decimal(self.selection_data.MDefRand  - self.data.MDefRand)
    local spd_adjust  = self.selection_data.SpeedBonus - self.data.SpeedBonus + stat_random_decimal(self.selection_data.SpeedRand - self.data.SpeedRand)
    local rand_adjust = self.selection_data.Random - self.data.Random

    -- define +- text for stats
    local hp_rand  = stat_randomness(self.selection_data.MaxHPRand)
    local atk_rand = stat_randomness(self.selection_data.AtkRand)
    local def_rand = stat_randomness(self.selection_data.DefRand)
    local sat_rand = stat_randomness(self.selection_data.MAtkRand)
    local sdf_rand = stat_randomness(self.selection_data.MDefRand)
    local spd_rand = stat_randomness(self.selection_data.SpeedRand)

    -- compute color for text
    self.hp_text:SetText(tostring(self.selection_data.MaxHPBonus)..hp_rand)
    self.hp_text.Color = getTextColor(hp_change)
    if hp_adjust ~= 0   then self.hp_text.Color   = getAdjustColor(hp_adjust)   end
    self.atk_text:SetText(tostring(self.selection_data.AtkBonus)..atk_rand)
    self.atk_text.Color = getTextColor(atk_change)
    if atk_adjust ~= 0  then self.atk_text.Color  = getAdjustColor(atk_adjust)  end
    self.def_text:SetText(tostring(self.selection_data.DefBonus)..def_rand)
    self.def_text.Color = getTextColor(def_change)
    if def_adjust ~= 0  then self.def_text.Color  = getAdjustColor(def_adjust)  end
    self.sat_text:SetText(tostring(self.selection_data.MAtkBonus)..sat_rand)
    self.sat_text.Color = getTextColor(sat_change)
    if sat_adjust ~= 0  then self.sat_text.Color  = getAdjustColor(sat_adjust)  end
    self.sdf_text:SetText(tostring(self.selection_data.MDefBonus)..sdf_rand)
    self.sdf_text.Color = getTextColor(sdf_change)
    if sdf_adjust ~= 0  then self.sdf_text.Color  = getAdjustColor(sdf_adjust)  end
    self.spd_text:SetText(tostring(self.selection_data.SpeedBonus)..spd_rand)
    self.spd_text.Color = getTextColor(spd_change)
    if spd_adjust ~= 0  then self.spd_text.Color  = getAdjustColor(spd_adjust)  end
    self.rand_text:SetText(tostring(self.selection_data.Random))
    self.rand_text.Color = getTextColor(rand_change)
    if rand_adjust ~= 0 then self.rand_text.Color = getAdjustColor(rand_adjust) end

    --write "Max" in yellow if 256
    if self.selection_data.MaxHPBonus == 256 then
        self.hp_text:SetText(STRINGS:FormatKey("MENU_TEAM_MAX"))
        if self.hp_text.Color == Color.White then self.hp_text.Color = Color.Yellow end
    end
    if self.selection_data.AtkBonus   == 256 then
        self.atk_text:SetText(STRINGS:FormatKey("MENU_TEAM_MAX"))
        if self.atk_text.Color == Color.White then self.atk_text.Color = Color.Yellow end
    end
    if self.selection_data.DefBonus   == 256 then
        self.def_text:SetText(STRINGS:FormatKey("MENU_TEAM_MAX"))
        if self.def_text.Color == Color.White then self.def_text.Color = Color.Yellow end
    end
    if self.selection_data.MAtkBonus  == 256 then
        self.sat_text:SetText(STRINGS:FormatKey("MENU_TEAM_MAX"))
        if self.sat_text.Color == Color.White then self.sat_text.Color = Color.Yellow end
    end
    if self.selection_data.MDefBonus  == 256 then
        self.sdf_text:SetText(STRINGS:FormatKey("MENU_TEAM_MAX"))
        if self.sdf_text.Color == Color.White then self.sdf_text.Color = Color.Yellow end
    end
    if self.selection_data.SpeedBonus == 256 then
        self.spd_text:SetText(STRINGS:FormatKey("MENU_TEAM_MAX"))
        if self.spd_text.Color == Color.White then self.spd_text.Color = Color.Yellow end
    end

    if not SV.Intro.CafeRandomDiscovered then
        if self.selection_data.Random ~= 0 then
            local bounds = self.window.Bounds
            self.window.Bounds = RogueElements.Rect(bounds.X, bounds.Y-14, bounds.Width, bounds.Height+14)
            self.window.Elements:Add(self.rand_label)
            self.window.Elements:Add(self.rand_text)
            SV.Intro.CafeRandomDiscovered = true
        end
    end
end





--- Creates a ``JuiceMenu`` instance using the provided parameters, then runs it and returns its output.
--- @param character Character the ``RogueEssence.Dungeon.Character`` that will receive this drink.
--- @param ingredients table<string,CafeBoostEntry> a list of key-value pairs where the keys are item ids and the values are the drink effects, as specified in ``ground.base_camp_2.base_camp_2_juice``. Only items in this list will be enabled.
--- @param includeEquips boolean if true, the party's equipped items will be included in the menu. Defaults to true.
--- @param boost_function function the function that will be used by the preview window to calculate the total boost.
--- @param max_choices? integer if set, it will never be possible to select more than the amount of items defined here. Defaults to the amount of selectable items.
--- @return InvSlot[] #a table array containing the chosen ``RogueEssence.Dungeon.InvSlot`` objects.
function JuiceMenu.run(character, ingredients, includeEquips, boost_function, max_choices)
    local ret = {}
    local choose = function(list) ret = list end
    local refuse = function() _MENU:RemoveMenu() end
    local menu = JuiceMenu:new(character, ingredients, choose, refuse, includeEquips, boost_function, max_choices)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end