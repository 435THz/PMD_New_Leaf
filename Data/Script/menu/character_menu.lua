--[[
    character_menu.lua
    Implements the character menu used in New Leaf's character selection sequence
]]--
require 'common'
require 'Global'
require 'menu.GraphicsEssential'
require 'CommonFunctions'

function CharacterSelectionMenu()
    local CharacterSelectionMenu = Class('CharacterSelectionMenu')

    -- sub-menu initializations
    local CharacterChoiceListMenu =          Class('CharacterChoiceListMenu')
    local CharacterEggMoveMenu =             Class('CharacterEggMoveMenu')
    local CharacterEggMovePositionSelector = Class('CharacterEggMovePositionSelector')
    local CharacterSpeciesMenu =             Class('CharacterSpeciesMenu')
    local CharacterSignDocumentMenu =        Class('CharacterSignDocumentMenu')

    -------------------------------------------------------
    --region Initialization
    -------------------------------------------------------
    function CharacterSelectionMenu:initialize()
        assert(self, "SingleItemDealMenu:initialize(): self is nil!")
        self.menu_spacing = 20
        self.data = {
            nickname="",
            species = "alcremie",
            form = 0,
            skin = 'normal',
            gender = 2, -- 0 male, 1 female, 2 genderless
            intrinsic = "sweet_veil",
            egg_move = "",
            egg_move_index = -1
        }
        self.selected = {1, 1}  -- selected field, as {window, index} values
        self.focused = 1        -- currently focused window. 1 is left. 2 is right
        self.confirmed = false
        self.options = {
            --window left
            {
                {Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE + 4,     function() self:openNicknameMenu() end},
                {Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE * 2 + 4, function() self:openSpeciesMenu() end },
                {Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE * 3 + 4, function() self:openFormMenu() end },
                {Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE * 4 + 4, function() self:openGenderMenu() end},
                {Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE * 5 + 4, function() self:openAspectMenu() end},
            },
            --window right
            {
                {Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE     + 4, function() self:openAbilityMenu() end},
                {Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE * 3,     function() self:openEggMoveMenu() end},
                {Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE * 5 + 4, function() self:signDocument() end}
            }
        }
        self.form_active = true
        self.ability_active = true
        self.egg_move_active = true
        self:setupWindows()
        self:updateWindows(true, true, true)
    end

    function CharacterSelectionMenu:setupWindows()
        self:setupTitleWindow()
        self:setupPortrait()
        self:setupMoveSummary()
        self:setupFakeInteractables()
        self:setupRealInteractables()
    end

    function CharacterSelectionMenu:setupTitleWindow()
        local top_left = RogueElements.Loc(16, 8)
        local bottom_right = RogueElements.Loc(Graphics.Manager.ScreenWidth//2 - 8, 8 + Graphics.LINE_HEIGHT + Graphics.Manager.MenuBG.TileHeight*2)
        self.title_window = RogueEssence.Menu.SummaryMenu(RogueElements.Rect.FromPoints(top_left, bottom_right))
        local title = RogueEssence.Menu.MenuText(
                "ETF Identity Document",
                RogueElements.Loc(
                        self.title_window.Bounds.Width//2,
                        Graphics.Manager.MenuBG.TileHeight),
                RogueElements.DirH.None
        )
        self.title_window.Elements:Add(title)
    end

    function CharacterSelectionMenu:setupPortrait()
        local top_left = RogueElements.Loc(16, 16 + self.title_window.Bounds.Height)
        local bottom_right = RogueElements.Loc(54+Graphics.Manager.MenuBG.TileWidth*2, 50 + self.title_window.Bounds.Height + Graphics.Manager.MenuBG.TileHeight*2)
        self.portrait_box = RogueEssence.Menu.SummaryMenu(RogueElements.Rect.FromPoints(top_left, bottom_right))

        local id = self:toMonsterID()
        local emote = RogueEssence.Content.EmoteStyle(0)
        local loc = RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth-1,Graphics.Manager.MenuBG.TileHeight-3)
        self.portrait = RogueEssence.Menu.SpeakerPortrait(id, emote, loc, false)
        self.portrait_box.Elements:Add(self.portrait)
    end

    function CharacterSelectionMenu:setupMoveSummary()
        local top_left = RogueElements.Loc(Graphics.Manager.ScreenWidth//2 + 8, 8)
        local bottom_right = RogueElements.Loc(Graphics.Manager.ScreenWidth - 16, Graphics.Manager.ScreenHeight//2 - 4)
        self.base_summary = RogueEssence.Menu.SummaryMenu(RogueElements.Rect.FromPoints(top_left, bottom_right))
    end

    function CharacterSelectionMenu:setupFakeInteractables()
        local top_left_l = RogueElements.Loc(16, Graphics.Manager.ScreenHeight//2 + 4)
        local bottom_right_l = RogueElements.Loc(Graphics.Manager.ScreenWidth//2 - 8, Graphics.Manager.ScreenHeight - 12)
        self.left_summary = RogueEssence.Menu.SummaryMenu(RogueElements.Rect.FromPoints(top_left_l, bottom_right_l))

        local top_left_r = RogueElements.Loc(Graphics.Manager.ScreenWidth//2 + 8, Graphics.Manager.ScreenHeight//2 + 4)
        local bottom_right_r = RogueElements.Loc(Graphics.Manager.ScreenWidth - 16, Graphics.Manager.ScreenHeight - 12)
        self.right_summary = RogueEssence.Menu.SummaryMenu(RogueElements.Rect.FromPoints(top_left_r, bottom_right_r))
    end

    function CharacterSelectionMenu:setupRealInteractables()
        local x_left = 16
        local y = Graphics.Manager.ScreenHeight//2 + 4
        local w = Graphics.Manager.ScreenWidth//2 - 8 - x_left
        local h = Graphics.Manager.ScreenHeight - 12 - y

        local x_right = Graphics.Manager.ScreenWidth//2 + 8
        self.left  = RogueEssence.Menu.ScriptableMenu(x_left,  y, w, h, function(input) self:Update(input) end)
        self.right = RogueEssence.Menu.ScriptableMenu(x_right, y, w, h, function(input) self:Update(input) end)
        self.left.SummaryMenus:Add(self.title_window)
        self.left.SummaryMenus:Add(self.portrait_box)
        self.left.SummaryMenus:Add(self.base_summary)
        self.left.SummaryMenus:Add(self.right_summary)
        self.right.SummaryMenus:Add(self.title_window)
        self.right.SummaryMenus:Add(self.portrait_box)
        self.right.SummaryMenus:Add(self.base_summary)
        self.right.SummaryMenus:Add(self.left_summary)
        self.cursor_l = RogueEssence.Menu.MenuCursor(self.left)
        self.cursor_r = RogueEssence.Menu.MenuCursor(self.right)
    end

    -------------------------------------------------------
    --region VisualUpdating
    -------------------------------------------------------

    function CharacterSelectionMenu:updateWindows(portrait, summary, opposite)
        self:updateCurrent()
        if portrait then self:updatePortrait() end
        if summary  then self:updateSummary()  end
        if opposite then self:updateOpposite() end
    end

    function CharacterSelectionMenu:updateCurrent()
        if self.focused==1 then
            self:updateLeft()
        else
            self:updateRight()
        end
    end

    function CharacterSelectionMenu:updateLeft()
        self.monster = _DATA:GetMonster(self.data.species)
        self.left.MenuElements:Clear()
        self.left.MenuElements:Add(self.cursor_l)

        -- Title
        self.left.MenuElements:Add(RogueEssence.Menu.MenuText("Personal Information", RogueElements.Loc(self.menu_spacing, Graphics.Manager.MenuBG.TileHeight)))
        -- ------------------------------------
        self.left.MenuElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(12, 8 + Graphics.VERT_SPACE), self.left.Bounds.Width - 12 * 2))

        -- Name: nickname
        local nick_text = self.data.nickname
        if self.data.nickname == "" then
            nick_text = self.monster.Name:ToLocal()
        end
        self.left.MenuElements:Add(RogueEssence.Menu.MenuText("Name:", RogueElements.Loc(self.menu_spacing, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE + 4)))
        self.left.MenuElements:Add(RogueEssence.Menu.MenuText("[color=#FFC663]"..nick_text.."[color]", RogueElements.Loc((self.left.Bounds.Width*2)//3, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE + 4), RogueElements.DirH.None))

        -- Species: species
        local species_nam = self.monster.Name:ToLocal()
        self.left.MenuElements:Add(RogueEssence.Menu.MenuText("Species:", RogueElements.Loc(self.menu_spacing, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*2 + 4)))
        self.left.MenuElements:Add(RogueEssence.Menu.MenuText("[color=#FFC663]"..species_nam.."[color]", RogueElements.Loc((self.left.Bounds.Width*2)//3, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*2 + 4), RogueElements.DirH.None))

        -- Form: form
        local form = self.monster.Forms[self.data.form]
        local form_nam = form.FormName:ToLocal()
        if form_nam == species_nam or not self.form_active then
            form_nam = "Normal"
        else
            form_nam = form_nam:gsub(species_nam, "")
            form_nam = form_nam:gsub('^%s*(.-)%s*$', '%1')
        end
        local form_text_color, form_color = "#FFFFFF", "#FFC663"
        if not self.form_active then form_text_color, form_color = "#888888", "#886A35" end
        self.left.MenuElements:Add(RogueEssence.Menu.MenuText("[color="..form_text_color.."]Form:[color]", RogueElements.Loc(self.menu_spacing, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*3 + 4)))
        self.left.MenuElements:Add(RogueEssence.Menu.MenuText("[color="..form_color.."]"..form_nam.."[color]", RogueElements.Loc((self.left.Bounds.Width*2)//3, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*3 + 4), RogueElements.DirH.None))

        -- Gender: gender
        local gender_display_table = {"Male", "Female", "Non-Binary"}
        local gender = gender_display_table[self.data.gender+1]
        self.left.MenuElements:Add(RogueEssence.Menu.MenuText("Gender:", RogueElements.Loc(self.menu_spacing, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*4 + 4)))
        self.left.MenuElements:Add(RogueEssence.Menu.MenuText("[color=#FFC663]"..gender.."[color]", RogueElements.Loc((self.left.Bounds.Width*2)//3, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*4 + 4), RogueElements.DirH.None))

        -- Aspect: shinyness
        local shiny = "[color=#FFC663]Regular[color]"
        if self.data.skin == "shiny" then shiny = "[color=#FFFF00]Shiny\u{E10C}[color]" end
        self.left.MenuElements:Add(RogueEssence.Menu.MenuText("Aspect:", RogueElements.Loc(self.menu_spacing, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*5 + 4)))
        self.left.MenuElements:Add(RogueEssence.Menu.MenuText(shiny, RogueElements.Loc((self.left.Bounds.Width*2)//3, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*5 + 4), RogueElements.DirH.None))

        local cursor_y = self.options[self.selected[1]][self.selected[2]][1]
        if self.focused == 1 then
            self.cursor_l.Loc = RogueElements.Loc(10, cursor_y)
        else
            self.cursor_l.Loc = RogueElements.Loc(-100, cursor_y)
        end
    end

    function CharacterSelectionMenu:updateRight()
        self.right.MenuElements:Clear()
        self.right.MenuElements:Add(self.cursor_r)

        -- Title
        self.right.MenuElements:Add(RogueEssence.Menu.MenuText("Battle Details", RogueElements.Loc(self.right.Bounds.Width//2, Graphics.Manager.MenuBG.TileHeight), RogueElements.DirH.None))
        -- ------------------------------------
        self.right.MenuElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(12, 8 + Graphics.VERT_SPACE), self.right.Bounds.Width - 12 * 2))

        -- Ability: ability
        local ability_text_color, ability_color = "#FFFFFF", "#FFC663"
        if not self.ability_active then ability_text_color, ability_color = "#888888", "#886A35" end
        local ability_name = _DATA:GetIntrinsic(self.data.intrinsic).Name:ToLocal()
        self.right.MenuElements:Add(RogueEssence.Menu.MenuText("[color=".. ability_text_color .."]Ability:[color]", RogueElements.Loc(self.menu_spacing, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE + 4)))
        self.right.MenuElements:Add(RogueEssence.Menu.MenuText("[color=".. ability_color .."]"..ability_name.."[color]", RogueElements.Loc((self.right.Bounds.Width*2)//3, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE + 4), RogueElements.DirH.None))

        -- Egg Move
        local egg_move_text_color, egg_move_color = "#FFFFFF", "#FFC663"
        if not self.egg_move_active then egg_move_text_color, egg_move_color = "#888888", "#886A35" end
        self.right.MenuElements:Add(RogueEssence.Menu.MenuText("[color="..egg_move_text_color.."]Egg Move[color]", RogueElements.Loc(self.right.Bounds.Width//2, Graphics.Manager.MenuBG.TileHeight + (Graphics.VERT_SPACE*5)//2), RogueElements.DirH.None))

        -- egg_move
        local egg_move = "-----"
        if self.data.egg_move ~= "" then egg_move = _DATA:GetSkill(self.data.egg_move).Name:ToLocal() end
        self.right.MenuElements:Add(RogueEssence.Menu.MenuText("[color="..egg_move_color.."]"..egg_move.."[color]", RogueElements.Loc(self.right.Bounds.Width//2, Graphics.Manager.MenuBG.TileHeight + (Graphics.VERT_SPACE*7)//2), RogueElements.DirH.None))

        -- ------------------------------------
        self.right.MenuElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(12, 6 + Graphics.VERT_SPACE*5), self.right.Bounds.Width - 12 * 2))

        -- Sign Document
        self.right.MenuElements:Add(RogueEssence.Menu.MenuText("Sign document", RogueElements.Loc(self.menu_spacing, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*5 + 4)))

        local cursor_y = self.options[self.selected[1]][self.selected[2]][1]
        if self.focused == 2 then
            self.cursor_r.Loc = RogueElements.Loc(10, cursor_y)
        else
            self.cursor_r.Loc = RogueElements.Loc(-100, cursor_y)
        end
    end

    -------------------------------------------------------

    function CharacterSelectionMenu:updatePortrait()
        self.portrait.Speaker = self:toMonsterID()
    end

    -------------------------------------------------------

    function CharacterSelectionMenu:updateSummary()
        self.base_summary.Elements:Clear()
        local form = self.monster.Forms[self.data.form]
        self.moves = {}
        for i = 0, form.LevelSkills.Count - 1, 1 do
            local skill = form.LevelSkills[i].Skill
            if form.LevelSkills[i].Level <= 5 then
                table.insert(self.moves, skill) --add to end
                if #self.moves>4 then
                    table.remove(self.moves, 1) --emulate base pmdo behavior
                end
            end
        end
        local level = 5
        local hp = form:GetStat(level, RogueEssence.Data.Stat.HP, 0)
        self.base_summary.Elements:Add(RogueEssence.Menu.MenuText("Lv."..tostring(level), RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth*2, Graphics.Manager.MenuBG.TileHeight), RogueElements.DirH.Left))
        self.base_summary.Elements:Add(RogueEssence.Menu.MenuText(tostring(hp).." HP",    RogueElements.Loc(self.base_summary.Bounds.Width - Graphics.Manager.MenuBG.TileWidth*2, Graphics.Manager.MenuBG.TileHeight), RogueElements.DirH.Right))
        self.base_summary.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(12 + Graphics.DIVIDER_HEIGHT//2, 8 + Graphics.VERT_SPACE), self.base_summary.Bounds.Width - 12 * 2))

        local move_text = RogueEssence.Menu.MenuText("Moves:", RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth*2, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE + Graphics.DIVIDER_HEIGHT*2), RogueElements.DirH.Left)
        self.base_summary.Elements:Add(move_text)
        for i=1, 4, 1 do
            local move_id = self.moves[i]
            local move_name, move_pp
            if self.data.egg_move ~="" and i == self.data.egg_move_index then -- override with egg move
                local move = _DATA:GetSkill(self.data.egg_move)
                move_name = utf8.char(_DATA:GetElement(move.Data.Element).Symbol).."\u{2060}[color=#FFFF00]"..move.Name:ToLocal().."[color]"
                move_pp   = tostring(move.BaseCharges).." PP"
            elseif move_id ~= nil then -- basic move
                local move = _DATA:GetSkill(move_id)
                move_name = move:GetIconName()
                move_pp   = tostring(move.BaseCharges).." PP"
            else -- empty slot
                move_name = "-----"
                move_pp   = "-----"
            end
            self.base_summary.Elements:Add(RogueEssence.Menu.MenuText(move_name, RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth*2, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*(i+1) + Graphics.DIVIDER_HEIGHT*2), RogueElements.DirH.Left))
            self.base_summary.Elements:Add(RogueEssence.Menu.MenuText(move_pp, RogueElements.Loc(self.base_summary.Bounds.Width - Graphics.Manager.MenuBG.TileWidth*2, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*(i+1) + Graphics.DIVIDER_HEIGHT*2), RogueElements.DirH.Right))
        end
    end

    -------------------------------------------------------

    function CharacterSelectionMenu:updateOpposite()
        if self.focused==1 then
            self:updateFakeRight()
        else
            self:updateFakeLeft()
        end
    end

    function CharacterSelectionMenu:updateFakeLeft()
        self.monster = _DATA:GetMonster(self.data.species)
        self.left_summary.Elements:Clear()

        -- Title
        self.left_summary.Elements:Add(RogueEssence.Menu.MenuText("Personal Information", RogueElements.Loc(self.menu_spacing, Graphics.Manager.MenuBG.TileHeight)))
        -- ------------------------------------
        self.left_summary.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(12, 8 + Graphics.VERT_SPACE), self.left_summary.Bounds.Width - 12 * 2))

        -- Name: nickname
        local nick_text = self.data.nickname
        if self.data.nickname == "" then
            nick_text = self.monster.Name:ToLocal()
        end
        self.left_summary.Elements:Add(RogueEssence.Menu.MenuText("Name:", RogueElements.Loc(self.menu_spacing, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE + 4)))
        self.left_summary.Elements:Add(RogueEssence.Menu.MenuText("[color=#FFC663]"..nick_text.."[color]", RogueElements.Loc((self.left.Bounds.Width*2)//3, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE + 4), RogueElements.DirH.None))

        -- Species: species
        local species_nam = self.monster.Name:ToLocal()
        self.left_summary.Elements:Add(RogueEssence.Menu.MenuText("Species:", RogueElements.Loc(self.menu_spacing, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*2 + 4)))
        self.left_summary.Elements:Add(RogueEssence.Menu.MenuText("[color=#FFC663]"..species_nam.."[color]", RogueElements.Loc((self.left.Bounds.Width*2)//3, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*2 + 4), RogueElements.DirH.None))

        -- Form: form
        local form = self.monster.Forms[self.data.form]
        local form_nam = form.FormName:ToLocal()
        if form_nam == species_nam or not self.form_active then
            form_nam = "Normal"
        else
            form_nam = form_nam:gsub(species_nam, "")
            form_nam = form_nam:gsub('^%s*(.-)%s*$', '%1')
        end
        local form_text_color, form_color = "#FFFFFF", "#FFC663"
        if not self.form_active then form_text_color, form_color = "#888888", "#886A35" end
        self.left_summary.Elements:Add(RogueEssence.Menu.MenuText("[color="..form_text_color.."]Form:[color]", RogueElements.Loc(self.menu_spacing, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*3 + 4)))
        self.left_summary.Elements:Add(RogueEssence.Menu.MenuText("[color="..form_color.."]"..form_nam.."[color]", RogueElements.Loc((self.left.Bounds.Width*2)//3, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*3 + 4), RogueElements.DirH.None))

        -- Gender: gender
        local gender_display_table = {"Male", "Female", "Non-Binary"}
        local gender = gender_display_table[self.data.gender+1]
        self.left_summary.Elements:Add(RogueEssence.Menu.MenuText("Gender:", RogueElements.Loc(self.menu_spacing, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*4 + 4)))
        self.left_summary.Elements:Add(RogueEssence.Menu.MenuText("[color=#FFC663]"..gender.."[color]", RogueElements.Loc((self.left.Bounds.Width*2)//3, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*4 + 4), RogueElements.DirH.None))

        -- Aspect: shinyness
        local shiny = "[color=#FFC663]Regular[color]"
        if self.data.skin == "shiny" then shiny = "[color=#FFFF00]Shiny\u{E10C}[color]" end
        self.left_summary.Elements:Add(RogueEssence.Menu.MenuText("Aspect:", RogueElements.Loc(self.menu_spacing, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*5 + 4)))
        self.left_summary.Elements:Add(RogueEssence.Menu.MenuText(shiny, RogueElements.Loc((self.left.Bounds.Width*2)//3, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*5 + 4), RogueElements.DirH.None))
    end

    function CharacterSelectionMenu:updateFakeRight()
        self.right_summary.Elements:Clear()

        -- Title
        self.right_summary.Elements:Add(RogueEssence.Menu.MenuText("Battle Details", RogueElements.Loc(self.right.Bounds.Width//2, Graphics.Manager.MenuBG.TileHeight), RogueElements.DirH.None))
        -- ------------------------------------
        self.right_summary.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(12, 8 + Graphics.VERT_SPACE), self.right_summary.Bounds.Width - 12 * 2))

        -- Ability: ability
        local ability_text_color, ability_color = "#FFFFFF", "#FFC663"
        if not self.ability_active then ability_text_color, ability_color = "#888888", "#886A35" end
        local ability_name = _DATA:GetIntrinsic(self.data.intrinsic).Name:ToLocal()
        self.right_summary.Elements:Add(RogueEssence.Menu.MenuText("[color=".. ability_text_color .."]Ability:[color]", RogueElements.Loc(self.menu_spacing, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE + 4)))
        self.right_summary.Elements:Add(RogueEssence.Menu.MenuText("[color=".. ability_color .."]"..ability_name.."[color]", RogueElements.Loc((self.right.Bounds.Width*2)//3, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE + 4), RogueElements.DirH.None))

        -- Egg Move
        local egg_move_text_color, egg_move_color = "#FFFFFF", "#FFC663"
        if not self.egg_move_active then egg_move_text_color, egg_move_color = "#888888", "#886A35" end
        self.right_summary.Elements:Add(RogueEssence.Menu.MenuText("[color="..egg_move_text_color.."]Egg Move[color]", RogueElements.Loc(self.right.Bounds.Width//2, Graphics.Manager.MenuBG.TileHeight + (Graphics.VERT_SPACE*5)//2), RogueElements.DirH.None))

        -- egg_move
        local egg_move = "-----"
        if self.data.egg_move ~= "" then egg_move = _DATA:GetSkill(self.data.egg_move).Name:ToLocal() end
        self.right_summary.Elements:Add(RogueEssence.Menu.MenuText("[color="..egg_move_color.."]"..egg_move.."[color]", RogueElements.Loc(self.right.Bounds.Width//2, Graphics.Manager.MenuBG.TileHeight + (Graphics.VERT_SPACE*7)//2), RogueElements.DirH.None))

        -- ------------------------------------
        self.right_summary.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(12, 6 + Graphics.VERT_SPACE*5), self.right_summary.Bounds.Width - 12 * 2))

        self.right_summary.Elements:Add(RogueEssence.Menu.MenuText("Sign document", RogueElements.Loc(self.menu_spacing, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*5 + 4)))
    end

    -------------------------------------------------------
    --region Interaction
    -------------------------------------------------------

    function CharacterSelectionMenu:getFocusedWindow()
        return COMMON_FUNC.tri(self.focused == 1, self.left, self.right)
    end

    function CharacterSelectionMenu:Update(input)
        local window = self.selected[1]
        local option = self.selected[2]

        if input:JustPressed(RogueEssence.FrameInput.InputType.Confirm) then
            local callback = self.options[window][option][2]
            _GAME:SE("Menu/Confirm")
            print("callback id "..window..","..option.." called")
            callback()
        elseif not self.dirPressed then
            if input.Direction == RogueElements.Dir8.Right then
                if self.focused == 1 then
                    self:toggleFocus()
                else
                    _GAME:SE("Menu/Cancel")
                end
                self.dirPressed = true
            elseif input.Direction == RogueElements.Dir8.Left then
                if self.focused == 2 then
                    self:toggleFocus()
                else
                    _GAME:SE("Menu/Cancel")
                end
                self.dirPressed = true
            elseif input.Direction == RogueElements.Dir8.Up then
                if option > 1 then
                    self.selected[2] = option - 1
                else
                    self.selected[2] = 1
                end
                self:redirectSelectedOption(window, option)
                self:updateWindows()
                self.dirPressed = true
            elseif input.Direction == RogueElements.Dir8.Down then
                if option<#self.options[window] then
                    self.selected[2] = option + 1
                else
                    self.selected[2] = #self.options[window]
                end
                self:redirectSelectedOption(window, option)
                self:updateWindows()
                self.dirPressed = true
            end
        elseif input.Direction == RogueElements.Dir8.None then
            self.dirPressed = false
        end
    end

    -- skips inactive options. this is not pretty but the alternatives were way worse
    function CharacterSelectionMenu:redirectSelectedOption(start_window, start_option) --start_window and start_option mean which window option pair is the movement starting from
        local window = self.selected[1]
        local option = self.selected[2]
        if window == 1 and option == 3 then
            if not self.form_active then
                if start_window ~= window or start_option > option then option = 2 --coming from right or below, go up
                else option = 4 end --coming from on top, go down
            end
        elseif window == 2 then
            if option == 1 then
                if not self.ability_active then
                    if not self.egg_move_active then option = 3 --move to option 3 if option 2 is also inactive
                    else option = 2 end --always move to option 2 otherwise
                end
            elseif option == 2 then --this one's fun
                if not self.egg_move_active then
                    if self.ability_active then -- if 1 is active
                        if start_window ~= window and start_option<4 --move to 1 if coming from the right's 1 2 or 3
                                or start_window == window and start_option>option then --move to 1 if coming from below,
                            option = 1
                        end
                    end
                    if option == 2 then option = 3 end --if not moved to 1 already then always move to 3
                end
            end
        end
        --play correct sound
        if start_window == window and start_option == option then _GAME:SE("Menu/Cancel")
        else _GAME:SE("Menu/Skip") end
        --save new pos
        self.selected[1] = window
        self.selected[2] = option
    end

    function CharacterSelectionMenu:toggleFocus()
        local window = self.selected[1]
        local option = self.selected[2]
        local focusTarget = self.focused%2 + 1
        self.focused = focusTarget
        self.selected[1] = focusTarget

        local targets = {1,3,5}
        if(focusTarget == 2) then
            targets = {1,2,2,3,3}
        end
        self.selected[2] = targets[self.selected[2]]
        self:redirectSelectedOption(window, option)

        self:updateWindows(true, true, true)
        _MENU:RemoveMenu()
    end

    -------------------------------------------------------
    --region Data Processing
    -------------------------------------------------------

    function CharacterSelectionMenu:toMonsterID()
        local id = self.data
        local gender = self:toGender()
        return RogueEssence.Dungeon.MonsterID(id.species, id.form, id.skin, gender)
    end

    function CharacterSelectionMenu:toGender()
        return GLOBAL.GenderTable[self.data.gender+1]
    end

    function CharacterSelectionMenu:monsterFormCount()
        local count = 0
        for elem in luanet.each(self.monster.Forms) do
            if elem.Released and not elem.Temporary then
                count=count+1
            end
        end
        return count
    end

    function CharacterSelectionMenu:getMonsterEggMoves()
        local monster_species = self.data.species
        local monster_form = self.data.form
        local monster = _DATA:GetMonster(monster_species)
        while monster.PromoteFrom ~= '' do
            monster_form = monster.Forms[monster_form].PromoteForm
            monster_species = monster.PromoteFrom
            monster = _DATA:GetMonster(monster_species)
        end
        local form = monster.Forms[monster_form]
        local egg_moves = form.SharedSkills
        local moves = {}
        for move_learnable in luanet.each(egg_moves) do
            local move_id = move_learnable.Skill
            local move = _DATA:GetSkill(move_id)
            if move.Released then
                table.insert(moves, move_id)
            end
        end
        return moves
    end
    -------------------------------------------------------
    --region Callbacks
    -------------------------------------------------------

    function CharacterSelectionMenu:openNicknameMenu()
        local cb = function(ret)
            self.data.nickname = ret or self.data.nickname
            self:updateWindows(false, false, false)
        end
        local sub_menu = RogueEssence.Menu.NicknameMenu(cb, cb)
        sub_menu.Text:SetText(self.data.nickname)
        _MENU:AddMenu(sub_menu, true)
    end

    function CharacterSelectionMenu:openSpeciesMenu()
        local data_id = {"bulbasaur", "charmander", "squirtle"}

        --TODO generate list

        local cb = function(ret)
            if self.data.species ~= data_id[ret] then
                self.data.species = data_id[ret]
                self.data.form = 0
                self.data.intrinsic = self.monster.Forms[self.data.form].Intrinsic1
                self.data.egg_move = ""
                self.data.egg_move_index = -1
                self:updateWindows(true, true, true)
            end
        end

        local sub_menu = CharacterSpeciesMenu:new(self, data_id, table.index_of(data_id, self.data.species, 1), cb)
        _MENU:AddMenu(sub_menu.menu, true)
    end

    function CharacterSelectionMenu:openFormMenu()
        local forms = self.monster.Forms
        local species_name = self.monster.Name:ToLocal()
        local options = {}
        local data_id = {}

        for i=0, forms.Count-1, 1 do
            local form_name = forms[i].FormName:ToLocal()
            if form_name == species_name then
                form_name = "Normal"
            else
                form_name = form_name:gsub(species_name, "")
                form_name = form_name:gsub('^%s*(.-)%s*$', '%1')
            end
            if forms[i].Released and not forms[i].Temporary then
                table.insert(options, form_name)
                table.insert(data_id, i)
            end
        end

        local cb = function(ret)
            if self.data.form ~= data_id[ret] then
                self.data.form = data_id[ret]
                self.data.intrinsic = self.monster.Forms[self.data.form].Intrinsic1
                self.data.egg_move = ""
                self.data.egg_move_index = -1
            end
            self:updateWindows(true, true, true)
        end
        local offset = self.options[self.selected[1]][self.selected[2]][1]
        local sub_menu = CharacterChoiceListMenu:new(self, "Form:", offset, options, self.data.form+1, cb, -3)
        _MENU:AddMenu(sub_menu.menu, true)
    end

    function CharacterSelectionMenu:openGenderMenu()
        local options = {"Male", "Female", "Non-Binary"}
        local cb = function(ret)
            self.data.gender = ret-1
            self:updateWindows(true, false, false)
        end
        local offset = self.options[self.selected[1]][self.selected[2]][1]
        local sub_menu = CharacterChoiceListMenu:new(self, "Gender:", offset, options, self.data.gender+1, cb)
        _MENU:AddMenu(sub_menu.menu, true)
    end

    function CharacterSelectionMenu:openAbilityMenu()
        local form = self.monster.Forms[self.data.form]
        local options = {}
        local data_id = {}
        table.insert(data_id, form.Intrinsic1)
        if form.Intrinsic2 ~= "none" then table.insert(data_id, form.Intrinsic2) end
        if form.Intrinsic3 ~= "none" then table.insert(data_id, form.Intrinsic3) end

        for _, data in ipairs(data_id) do
            table.insert(options, _DATA:GetIntrinsic(data).Name:ToLocal())
        end
        local cb = function(ret)
            self.data.intrinsic = data_id[ret]
            self:updateWindows(false, false, false)
        end
        local offset = self.options[self.selected[1]][self.selected[2]][1]
        local sub_menu = CharacterChoiceListMenu:new(self, "Ability:", offset, options, table.index_of(data_id, self.data.intrinsic, 1), cb)
        _MENU:AddMenu(sub_menu.menu, true)
    end

    function CharacterSelectionMenu:openAspectMenu()
        local options = {"Regular", "[color=#FFFF00]Shiny\u{E10C}[color]"}
        local data_id = {"normal", "shiny"}
        local cb = function(ret)
            self.data.skin = data_id[ret]
            self:updateWindows(true, false, false)
        end
        local offset = self.options[self.selected[1]][self.selected[2]][1]
        local sub_menu = CharacterChoiceListMenu:new(self, "Aspect:", offset, options,  table.index_of(data_id, self.data.skin, 1), cb)
        _MENU:AddMenu(sub_menu.menu, true)
    end

    function CharacterSelectionMenu:openEggMoveMenu()
        local cb = function(move, index)
            self.data.egg_move = move
            self.data.egg_move_index = index
            self:updateWindows(false, true, false)
        end
        local sub_menu = CharacterEggMoveMenu:new(self, cb)
        _MENU:AddMenu(sub_menu.menu, true)
    end

    function CharacterSelectionMenu:signDocument()
        local cb = function(close_menu)
            self.confirmed = close_menu
            if self.confirmed then _MENU:RemoveMenu() end
        end
        local sub_menu = CharacterSignDocumentMenu:new(self, cb)
        _MENU:AddMenu(sub_menu.menu, true)
    end

    -------------------------------------------------------
    --region CharacterChoiceListMenu
    -------------------------------------------------------

    --Menu parent, string window_name, List<string> options, int current, function callback, int pos
    function CharacterChoiceListMenu:initialize(parent, window_name, window_offset, options, current, callback, pos)
        assert(self, "RecruitMainChoice:initialize(): self is nil!")
        self.parent = parent
        self.window_name = window_name
        self.selected = current -- starts from 1
        self.original = self.selected
        self.options = options
        self.callback = callback
        self.MAX_ELEM = 9
        self.ELEMS = math.min(#self.options, self.MAX_ELEM)

        self.pos = pos -- preferred starting position. can shift during initialization
        if pos == nil or self.ELEMS<self.MAX_ELEM then self.pos = self.selected end --set to selected if list too small or pos not supplied
        if self.pos<0 then self.pos = self.ELEMS+1 + self.pos end --count backwards if pos negative
        if self.selected == #self.options then
            self.pos = self.ELEMS
        elseif self.pos > self.ELEMS then
            self.pos = self.ELEMS-1
        end

        self.start_from = math.max(1,math.min(self.selected+1 - self.pos, (#self.options)+1 - self.ELEMS)) --cap display starting slot
        self.pos = self.selected+1 - self.start_from --readjust starting position

        -- calculate window position using parent data
        local w = parent:getFocusedWindow().Bounds.Width
        local h = Graphics.VERT_SPACE*self.ELEMS + Graphics.Manager.MenuBG.TileHeight*2
        local x = parent:getFocusedWindow().Bounds.Left
        local y = parent:getFocusedWindow().Bounds.Top + window_offset - Graphics.Manager.MenuBG.TileHeight - (Graphics.VERT_SPACE//2)*(self.ELEMS-1)

        -- this whole thing just for a goddamn visual adjustment
        local orig_y = y
        local y_min = parent:getFocusedWindow().Bounds.Top
        local y_max = parent:getFocusedWindow().Bounds.Bottom - h
        if y_min>y_max then
            if y_max < Graphics.Manager.ScreenHeight-12 - h then
                y_max = Graphics.Manager.ScreenHeight-12 - h
            end
        end
        if y_min>y_max then --if the previous adjustment was not enough
            if y_max > 8 then y_min=y_max else
                local y_mid = (y_min + y_max)//2
                y_min, y_max = y_mid, y_mid
            end
        end
        if y < y_min then y = y_min end
        if y > y_max then y = y_max end
        self.y_offset = orig_y - y

        self.menu  = RogueEssence.Menu.ScriptableMenu(x, y, w, h, function(input) self:Update(input) end)
        self.cursor = RogueEssence.Menu.MenuCursor(self.menu)
        self:DrawMenu()
    end

    function CharacterChoiceListMenu:DrawMenu()
        self.menu.MenuElements:Clear()
        local center_x = (self.menu.Bounds.Width*2)//3
        if self.window_name then self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(self.window_name, RogueElements.Loc(self.parent.menu_spacing, (self.menu.Bounds.Height - Graphics.VERT_SPACE)//2 + self.y_offset)))
        else center_x = self.menu.Bounds.Width//2 end
        local end_at = self.start_from+self.ELEMS - 1
        for i=self.start_from, end_at, 1 do
            local option = self.options[i]
            local slot = i - self.start_from
            self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("[color=#FFC663]"..option.."[color]", RogueElements.Loc(center_x, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*slot), RogueElements.DirH.None))
        end
        self.menu.MenuElements:Add(self.cursor)
        self.cursor.Loc = RogueElements.Loc(10, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*(self.pos-1))
        -- TODO add arrows
    end

    function CharacterChoiceListMenu:Update(input)
        if input:JustPressed(RogueEssence.FrameInput.InputType.Confirm) then
            _GAME:SE("Menu/Confirm")
            self.callback(self.selected)
            _MENU:RemoveMenu()
        elseif input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) or
               input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
            _GAME:SE("Menu/Cancel")
            self.callback(self.original)
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
            if self.selected<#self.options then
                _GAME:SE("Menu/Skip")
                self:updateSelection(1)
            else
                _GAME:SE("Menu/Cancel")
                self.selected = #self.options
                self.pos = self.ELEMS
                self.start_from = #self.options+1 - self.ELEMS
            end
            self:DrawMenu()
        end
    end

    function CharacterChoiceListMenu:directionHold(input, direction)
        local INPUT_WAIT = 30
        local INPUT_GAP = 6

        local new_dir = false
        local old_dir = false
        if input.Direction == direction then new_dir = true end
        if input.PrevDirection == direction then old_dir = true end

        local repeat_time = false
        if input.InputTime >= INPUT_WAIT and input.InputTime % INPUT_GAP == 0 then
            repeat_time = true
        end
        return new_dir and (not old_dir or repeat_time)
    end

    function CharacterChoiceListMenu:updateSelection(change)
        self.selected = math.clamp(1,self.selected + change, #self.options)
        if self.selected == 1 then self.pos = 1
        elseif self.selected == #self.options then self.pos = self.ELEMS
        else self.pos = math.clamp(2,self.pos + change, self.ELEMS-1) end
        self.start_from = self.selected+1 - self.pos
    end

    -------------------------------------------------------
    --region CharacterEggMoveMenu
    -------------------------------------------------------

    function CharacterEggMoveMenu:initialize(parent, updateCallback)
        assert(self, "RecruitMainChoice:initialize(): self is nil!")
        self.parent = parent
        self.updateCallback = updateCallback
        self.egg_move = self.parent.data.egg_move
        self.egg_move_index = self.parent.data.egg_move_index
        self.can_change_slot = (self.egg_move ~= "" and #self.parent.moves>3)
        self.autoOpenEggMovePosition = false
        self.callbacks = {
            function() self:openEggMoveSelection() end,
            function() self:openEggMovePosition() end,
            function() self:closeMenu() end
        }

        self.pos = 1

        local w = parent:getFocusedWindow().Bounds.Width
        local h = (Graphics.VERT_SPACE+Graphics.Manager.MenuBG.TileHeight+1)*3
        local x = parent:getFocusedWindow().Bounds.Left
        local y = parent:getFocusedWindow().Bounds.Top + (Graphics.VERT_SPACE*5)//2

        self.menu  = RogueEssence.Menu.ScriptableMenu(x, y, w, h, function(input) self:Update(input) end)
        self.cursor = RogueEssence.Menu.MenuCursor(self.menu)
        self:DrawMenu()
    end

    function CharacterEggMoveMenu:DrawMenu()
        self.menu.MenuElements:Clear()
        local egg_move = "-----"
        local change_slot_color = COMMON_FUNC.tri(self.can_change_slot, "#FFCEFF", "#886D88")
        if self.egg_move ~= "" then egg_move = _DATA:GetSkill(self.egg_move).Name:ToLocal() end

        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("Egg Move", RogueElements.Loc(self.menu.Bounds.Width//2, Graphics.Manager.MenuBG.TileHeight), RogueElements.DirH.None))
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("[color=#FFC663]"..egg_move.."[color]", RogueElements.Loc(self.menu.Bounds.Width//2, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE), RogueElements.DirH.None))
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("[color="..change_slot_color.."]Change Slot[color]", RogueElements.Loc(self.menu.Bounds.Width//2, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*2), RogueElements.DirH.None))
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("Confirm", RogueElements.Loc(self.menu.Bounds.Width//2, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*3), RogueElements.DirH.None))
        self.menu.MenuElements:Add(self.cursor)
        self.cursor.Loc = RogueElements.Loc(10, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*(self.pos))
    end

    function CharacterEggMoveMenu:Update(input)
        if self.autoOpenEggMovePosition then --if auto menu opening is requested, grant the request
            self.autoOpenEggMovePosition = false
            self:openEggMovePosition()
        elseif input:JustPressed(RogueEssence.FrameInput.InputType.Confirm) then
            local callback = self.callbacks[self.pos]
            _GAME:SE("Menu/Confirm")
            print("  callback id "..tostring(self.pos).." called")
            callback()
        elseif input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) or
                input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
            _GAME:SE("Menu/Cancel")
            self:closeMenu()
        elseif not self.dirPressed then
            if input.Direction == RogueElements.Dir8.Up then
                if self.pos > 1 then
                    _GAME:SE("Menu/Confirm")
                    self.pos = self.pos - 1
                    if self.pos == 2 and not self.can_change_slot then self.pos = self.pos - 1 end
                else
                    _GAME:SE("Menu/Cancel")
                    self.pos = 1
                end
                self.dirPressed = true
                self:DrawMenu()
            elseif input.Direction == RogueElements.Dir8.Down then
                if self.pos<3 then
                    _GAME:SE("Menu/Confirm")
                    self.pos = self.pos + 1
                    if self.pos == 2 and not self.can_change_slot then self.pos = self.pos + 1 end
                else
                    _GAME:SE("Menu/Cancel")
                    self.pos = 3
                end
                self.dirPressed = true
                self:DrawMenu()
            end
        elseif input.Direction == RogueElements.Dir8.None then
            self.dirPressed = false
        end
    end

    function CharacterEggMoveMenu:openEggMoveSelection()
        local egg_moves = self.parent:getMonsterEggMoves()
        local options = {}
        local data_id = {}

        table.insert(options, "-----")
        table.insert(data_id, "")
        for _, move_id in pairs(egg_moves) do
            local move = _DATA:GetSkill(move_id)
            local move_name = move.Name:ToLocal()
            if move.Released then
                table.insert(options, move_name)
                table.insert(data_id, move_id)
            end
        end

        -- this is where the fun is handled
        local cb = function(ret)
            local update = true
            self.egg_move = data_id[ret]
            if self.egg_move == "" then self.egg_move_index = -1 end         --remove swapped index if selection empty
            self.can_change_slot = (self.egg_move ~= "" and #self.parent.moves>3)
            self:DrawMenu()
            if self.can_change_slot then                                   --if set and move list is filled
                if self.egg_move_index < 1 or self.egg_move_index > 4 then  --if the old index is invalid
                    self.autoOpenEggMovePosition = true                      --call other menu automatically
                    update = false
                end
            elseif self.egg_move ~= "" then                               --if set but move list is not filled
                self.egg_move_index = #self.parent.moves+1                  --visually append
            end
            if update then
                self.updateCallback(self.egg_move, self.egg_move_index)    --update parent variables
            end
        end

        local offset = self.pos*Graphics.VERT_SPACE
        local sub_menu = CharacterChoiceListMenu:new(self, nil, offset, options, table.index_of(data_id, self.egg_move, 1), cb, 5)
        _MENU:AddMenu(sub_menu.menu, true)
    end

    function CharacterEggMoveMenu:openEggMovePosition()
        local cb = function(index)
            self.egg_move_index = index or -1
            if self.egg_move_index > 4 or self.egg_move_index<1 then
                self.egg_move = ""
                self.egg_move_index = -1
            end
            self.can_change_slot = (self.egg_move ~= "" and #self.parent.moves>3)
            self:DrawMenu()
            self.updateCallback(self.egg_move, self.egg_move_index)    --update parent variables
        end

        local sub_menu = CharacterEggMovePositionSelector:new(self, cb)
        _MENU:AddMenu(sub_menu.menu, true)
    end

    function CharacterEggMoveMenu:closeMenu()
        self.updateCallback(self.egg_move, self.egg_move_index)
        _MENU:RemoveMenu()
    end

    function CharacterEggMoveMenu:getFocusedWindow() return self.menu end

    -------------------------------------------------------
    --region CharacterEggMovePositionSelector
    -------------------------------------------------------

    function CharacterEggMovePositionSelector:initialize(parent, callback)
        self.parent = parent
        self.callback = callback

        self.pos = self.parent.egg_move_index
        self.original = self.pos
        if self.pos<0 or self.pos>4 then self.pos = 4 end

        local x = Graphics.Manager.ScreenWidth//2 + 8
        local y = 8
        local w = Graphics.Manager.ScreenWidth - 16 - x
        local h = Graphics.Manager.ScreenHeight//2 - 4 - y

        self.menu = RogueEssence.Menu.ScriptableMenu(x, y, w, h, function(input) self:Update(input) end)
        self.cursor = RogueEssence.Menu.MenuCursor(self.menu)
        self:DrawMenu()
    end

    function CharacterEggMovePositionSelector:DrawMenu()
        self.menu.MenuElements:Clear()
        self.moves = self.parent.parent.moves
        -- parent is CharacterEggMoveMenu, parent.parent is CharacterSelectionMenu

        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("Replacing what?", RogueElements.Loc(self.menu.Bounds.Width//2, Graphics.Manager.MenuBG.TileHeight), RogueElements.DirH.None))
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(12 + Graphics.DIVIDER_HEIGHT//2, 8 + Graphics.VERT_SPACE), self.menu.Bounds.Width - 12 * 2))

        local move_text = "Moves:"
        if self.pos == 0 then move_text = "[color=#FFFF00]Cancel[color]" end

        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(move_text, RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth*2, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE + Graphics.DIVIDER_HEIGHT*2), RogueElements.DirH.Left))
        for i=1, 4, 1 do
            local move_id = self.moves[i]
            local move_name, move_pp
            if i == self.pos then -- override with egg move
                local move = _DATA:GetSkill(self.parent.egg_move)
                move_name = utf8.char(_DATA:GetElement(move.Data.Element).Symbol).."\u{2060}[color=#FFFF00]"..move.Name:ToLocal().."[color]"
                move_pp   = tostring(move.BaseCharges).." PP"
            elseif move_id ~= nil then -- basic move
                local move = _DATA:GetSkill(move_id)
                move_name = move:GetIconName()
                move_pp   = tostring(move.BaseCharges).." PP"
            else -- empty slot. Should never be hit but we keep it anyway for safety reasons
                move_name = "-----"
                move_pp   = "-----"
            end
            self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(move_name, RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth*2, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*(i+1) + Graphics.DIVIDER_HEIGHT*2), RogueElements.DirH.Left))
            self.menu.MenuElements:Add(RogueEssence.Menu.MenuText(move_pp, RogueElements.Loc(self.menu.Bounds.Width - Graphics.Manager.MenuBG.TileWidth*2, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*(i+1) + Graphics.DIVIDER_HEIGHT*2), RogueElements.DirH.Right))
        end
        self.menu.MenuElements:Add(self.cursor)
        self.cursor.Loc = RogueElements.Loc(10, Graphics.Manager.MenuBG.TileHeight + Graphics.VERT_SPACE*(self.pos+1) + Graphics.DIVIDER_HEIGHT*2)
    end

    function CharacterEggMovePositionSelector:Update(input)
        if input:JustPressed(RogueEssence.FrameInput.InputType.Confirm) then
            _GAME:SE("Menu/Confirm")
            self.callback(self.pos)
            _MENU:RemoveMenu()
        elseif input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) or
               input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
            _GAME:SE("Menu/Cancel")
            self.callback(self.original)
            _MENU:RemoveMenu()
        elseif not self.dirPressed then
            if input.Direction == RogueElements.Dir8.Up then
                if self.pos > 0 then
                    _GAME:SE("Menu/Confirm")
                    self.pos = self.pos - 1
                else
                    _GAME:SE("Menu/Cancel")
                    self.pos = 0
                end
                self.dirPressed = true
                self:DrawMenu()
            elseif input.Direction == RogueElements.Dir8.Down then
                if self.pos<4 then
                    _GAME:SE("Menu/Confirm")
                    self.pos = self.pos + 1
                else
                    _GAME:SE("Menu/Cancel")
                    self.pos = 4
                end
                self.dirPressed = true
                self:DrawMenu()
            end
        elseif input.Direction == RogueElements.Dir8.None then
            self.dirPressed = false
        end
    end

    -------------------------------------------------------
    --region CharacterSpeciesMenu
    -------------------------------------------------------

    function CharacterSpeciesMenu:initialize(parent, list, current, callback)
        self.parent = parent
        self.list = list
        self.original = current
        self.selected = current
        self.callback = callback
        self.pos = 1

        self.monster = false

        local w = Graphics.Manager.ScreenWidth//2
        local h = Graphics.VERT_SPACE*5+Graphics.Manager.MenuBG.TileHeight*2
        local x = Graphics.Manager.ScreenWidth//4
        local y = (Graphics.Manager.ScreenHeight-h)//2

        self.menu = RogueEssence.Menu.ScriptableMenu(x, y, w, h, function(input) self:Update(input) end)
        self.cursor = RogueEssence.Menu.MenuCursor(self.menu)
        self.cursor.Loc = RogueElements.Loc(10, Graphics.Manager.MenuBG.TileHeight + (Graphics.VERT_SPACE*5//2))
        self:DrawMenu()
    end

    function CharacterSpeciesMenu:DrawMenu()
        self.menu.MenuElements:Clear()

        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("Choose your species", RogueElements.Loc(self.menu.Bounds.Width//2, Graphics.Manager.MenuBG.TileHeight), RogueElements.DirH.None))

        local num_x = 24
        local text_x = self.menu.Bounds.Width//2

        if self.selected>1 then
            local monster = _DATA:GetMonster(self.list[self.selected-1])
            self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("[color=#888888]"..tostring(monster.IndexNum).."[color]", RogueElements.Loc(num_x, Graphics.Manager.MenuBG.TileHeight + (Graphics.VERT_SPACE*3//2)), RogueElements.DirH.None))
            self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("[color=#886A35]"..monster.Name:ToLocal().."[color]", RogueElements.Loc(text_x, Graphics.Manager.MenuBG.TileHeight + (Graphics.VERT_SPACE*3//2)), RogueElements.DirH.None))
        end
        local mon = _DATA:GetMonster(self.list[self.selected])
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("[color=#FFFFFF]"..tostring(mon.IndexNum).."[color]", RogueElements.Loc(num_x, Graphics.Manager.MenuBG.TileHeight + (Graphics.VERT_SPACE*5//2)), RogueElements.DirH.None))
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("[color=#FFC663]"..mon.Name:ToLocal().."[color]", RogueElements.Loc(text_x, Graphics.Manager.MenuBG.TileHeight + (Graphics.VERT_SPACE*5//2)), RogueElements.DirH.None))
        if self.selected<#self.list then
            local monster = _DATA:GetMonster(self.list[self.selected+1])
            self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("[color=#888888]"..tostring(monster.IndexNum).."[color]", RogueElements.Loc(num_x, Graphics.Manager.MenuBG.TileHeight + (Graphics.VERT_SPACE*7//2)), RogueElements.DirH.None))
            self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("[color=#886A35]"..monster.Name:ToLocal().."[color]", RogueElements.Loc(text_x, Graphics.Manager.MenuBG.TileHeight + (Graphics.VERT_SPACE*7//2)), RogueElements.DirH.None))
        end

        self.menu.MenuElements:Add(self.cursor)
    end

    function CharacterSpeciesMenu:Update(input)
        if input:JustPressed(RogueEssence.FrameInput.InputType.Confirm) then
            _GAME:SE("Menu/Confirm")
            self.callback(self.selected)
            _MENU:RemoveMenu()
        elseif input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) or
               input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
            _GAME:SE("Menu/Cancel")
            self.callback(self.original)
            _MENU:RemoveMenu()
        elseif self:directionHold(input, RogueElements.Dir8.Up) then
            if self.selected > 1 then
                _GAME:SE("Menu/Skip")
                self.selected = self.selected -1
            else
                _GAME:SE("Menu/Cancel")
                self.selected = 1
            end
            self:DrawMenu()
        elseif self:directionHold(input, RogueElements.Dir8.Down) then
            if self.selected<#self.list then
                _GAME:SE("Menu/Skip")
                self.selected = self.selected +1
            else
                _GAME:SE("Menu/Cancel")
                self.selected = #self.list
            end
            self:DrawMenu()
        end
    end


    function CharacterSpeciesMenu:directionHold(input, direction)
        local INPUT_WAIT = 30
        local INPUT_GAP = 6

        local new_dir = false
        local old_dir = false
        if input.Direction == direction then new_dir = true end
        if input.PrevDirection == direction then old_dir = true end

        local repeat_time = false
        if input.InputTime >= INPUT_WAIT and input.InputTime % INPUT_GAP == 0 then
            repeat_time = true
        end
        return new_dir and (not old_dir or repeat_time)
    end

    -------------------------------------------------------
    --region CharacterSignDocumentMenu
    -------------------------------------------------------

    function CharacterSignDocumentMenu:initialize(parent, callback)
        self.parent = parent
        self.callback = callback

        self.answer = false

        local w = parent:getFocusedWindow().Bounds.Width
        local h = Graphics.VERT_SPACE+Graphics.Manager.MenuBG.TileHeight*2
        local x = parent:getFocusedWindow().Bounds.Left
        local y = parent:getFocusedWindow().Bounds.Top + parent.options[2][3][1] - Graphics.Manager.MenuBG.TileHeight

        self.menu = RogueEssence.Menu.ScriptableMenu(x, y, w, h, function(input) self:Update(input) end)
        self.cursor = RogueEssence.Menu.MenuCursor(self.menu)

        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("Are you sure?", RogueElements.Loc(parent.menu_spacing, Graphics.Manager.MenuBG.TileHeight)))
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("\u{E10A}", RogueElements.Loc(self.menu.Bounds.Width - Graphics.Manager.MenuBG.TileWidth - 3, Graphics.Manager.MenuBG.TileHeight), RogueElements.DirH.Right))
        self.menu.MenuElements:Add(RogueEssence.Menu.MenuText("\u{E10B}", RogueElements.Loc(self.menu.Bounds.Width - Graphics.Manager.MenuBG.TileWidth - 20, Graphics.Manager.MenuBG.TileHeight), RogueElements.DirH.Right))
        self.menu.MenuElements:Add(self.cursor)
        self.cursor.Loc = RogueElements.Loc(self.menu.Bounds.Width - Graphics.Manager.MenuBG.TileWidth - 34, Graphics.Manager.MenuBG.TileHeight)
    end

    function CharacterSignDocumentMenu:Update(input)
        if input:JustPressed(RogueEssence.FrameInput.InputType.Confirm) then
            _GAME:SE("Menu/Confirm")
            self.callback(self.pos)
            _MENU:RemoveMenu()
        elseif input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) or
                input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
            _GAME:SE("Menu/Cancel")
            self.callback(false)
            _MENU:RemoveMenu()
        elseif not self.dirPressed then
            if input.Direction == RogueElements.Dir8.Right then
                if not self.pos then _GAME:SE("Menu/Confirm")
                else _GAME:SE("Menu/Cancel") end
                self.pos = true
                self.dirPressed = true
                self.cursor.Loc = RogueElements.Loc(self.menu.Bounds.Width - Graphics.Manager.MenuBG.TileWidth - 16, Graphics.Manager.MenuBG.TileHeight)
            elseif input.Direction == RogueElements.Dir8.Left then
                if self.pos then _GAME:SE("Menu/Confirm")
                else _GAME:SE("Menu/Cancel") end
                self.pos = false
                self.dirPressed = true
                self.cursor.Loc = RogueElements.Loc(self.menu.Bounds.Width - Graphics.Manager.MenuBG.TileWidth - 34, Graphics.Manager.MenuBG.TileHeight)
            end
        elseif input.Direction == RogueElements.Dir8.None then
            self.dirPressed = false
        end
    end

    return CharacterSelectionMenu
end

--[[
copypasta for quick implementation idk

local CharacterMenu = CharacterSelectionMenu()
local menu = CharacterMenu:new()
while not menu.confirmed do
    UI:SetCustomMenu(menu:getFocusedWindow())
    UI:WaitForChoice()
end
]]