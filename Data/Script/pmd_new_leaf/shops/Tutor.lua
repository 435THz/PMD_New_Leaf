--[[
    Market.lua

    Sells items.
    This file contains all market-specific callbacks and functionality data structures
]]
require 'origin.menu.skill.SkillTutorMenu'
require 'origin.menu.team.AssemblySelectMenu'

function _SHOP.TutorInitializer(plot)
    plot.data = {
        level_limit = 0,
        category = "",
        category_frequency = 0,
        category_slots = 0,
        category_stock = {
            -- {ID = string, Price = int, days_left = int}
        },
        category_data = {
         -- species = {
         --     forms = {
         --         [form_number] = int
         --     }
         --     left = int
         -- }
        },
        category_permanent = false,
        permanent_stock = {
         -- string
        }
    }
end

function _SHOP.TutorUpgrade(plot, upgrade)
    local new_level = _HUB.getPlotLevel(plot)+1
    local sub
    if _SHOP.TutorTables.generic[new_level] then --any level except 5, 7 or 9
        if upgrade ~= "upgrade_generic" then return end
    elseif new_level == 5 then
        if not string.match(upgrade, "upgrade_tutor_5") then
            return
        end
        if string.match(upgrade, "sub_tutor") then
            sub = "tutor"
        elseif string.match(upgrade, "sub_egg") then
            sub = "egg"
        else
            return
        end
    else
        if not string.match(upgrade, "upgrade_tutor") then
            return
        end
        if string.match(upgrade, "sub_teach_frequency") then
            sub = "frequency"
        elseif string.match(upgrade, "sub_teach_count") then
            sub = "slot"
        else
            return
        end
    end

    _SHOP.ConfirmShopUpgrade(plot, upgrade)

    plot.data.level_limit = _SHOP.TutorTables.limit[new_level]
    if sub then
        if new_level == 5 then
            plot.data.category = sub
            plot.data.category_frequency = 3
            plot.data.category_slots = 1
            table.insert(plot.data.category_stock, _SHOP.TutorRollSlot(plot))
        else
            if sub == "frequency" then
                plot.data.category_frequency = plot.data.category_frequency-1
            else
                plot.data.category_slots = plot.data.category_slots+2
                table.insert(plot.data.category_stock, _SHOP.TutorRollSlot(plot))
                table.insert(plot.data.category_stock, _SHOP.TutorRollSlot(plot))
            end
        end
    end
    if new_level == 10 then
        plot.data.category_permanent = true
    elseif new_level == 1 then
        _SHOP.TutorUpdate(plot)
    end
end

_SHOP.TutorTables = {
    -- level    1   2   3   4   5   6   7   8   9   10
    limit   = {10, 18, 24, 30, 36, 44, 56, 70, 85, 100},
    -- level    1     2     3     4      5     6      7     8      9     10
    generic = {true, true, true, true, false, true, false, true, false, true},
    --          pp     1   2   3   4   5   6   7   8   9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
    charge_to_cost = {20, 18, 16, 14, 12, 12, 11, 11, 10, 10, 9, 9, 8, 8, 7, 7, 6, 6, 6, 5, 5, 5, 4, 4, 4, 4, 3, 3, 3, 3, 2}
}

function _SHOP.TutorUpdate(plot)
    local assembly = _SHOP.TutorGetCharacters()
    for _, member in pairs(assembly) do
        local species, form = member.BaseForm.Species, member.BaseForm.Form
        _SHOP.TutorAddSpecies(plot, species, form)
    end
    for _, slot in pairs(plot.data.category_stock) do
        -- {ID = string, Price = int, days_left = int}
        if slot.days_left>1 then
            slot.days_left = slot.days_left-1
        else
            slot.ID = ""
            slot = _SHOP.TutorRollSlot(plot)
        end
    end
end

function _SHOP.TutorAddSpecies(plot, species, form)
    local data = plot.data.category_data
    -- species = {
    --     forms = {
    --         [form_number] = int
    --     }
    --     left = int
    -- }
    if not data[species] then
        data[species] = {
            forms = {
                --   [form_number] = int
            },
            left = 0
        }
    end
    if not data[species][form] then
        local count _SHOP.TutorCountPool(plot, species, form)
        data[species].left = data[species].left + count
        data[species].forms[form] = count
    end
end

function _SHOP.TutorCountPool(plot, species, form)
    local f = _DATA:GetMonster(species).Forms[form]
    local count = 0
    local movepool = f.SecretSkills --tutor
    if plot.data.category == "egg" then
        movepool = f.SharedSkills --egg
    end
    for i = 0, movepool.Count-1, 1 do
        if not table.contains(plot.data.permanent_stock ,movepool[i].Skill) then
            count = count + 1
        end
    end
    return count
end

function _SHOP.TutorRollSlot(plot)
    local roll_table = {}
    local added = {}
    local assembly = _SHOP.TutorGetCharacters()
    local move

    for _, mon in pairs(assembly) do
        local species, form = mon.BaseForm.Species, mon.BaseForm.Form
        if not added[species] or not added[species][form] then
            if plot.data.category_data[species].left > 0 and plot.data.category_data[species].forms[form] > 0 then
                local count = plot.data.category_data[species].forms[form]
                table.insert(roll_table, {Species = species, Form = form, Weight = count})
                added[species] = added[species] or {}
                added[species][form] = true
            end
        end
    end

    while not move do
        if #roll_table == 0 then
            move = ""
            break
        end
        local result, index = COMMON_FUNC.WeightedRoll(roll_table)
        local form = _DATA:GetMonster(result.Species).Forms[result.Form]
        local movepool = form.SecretSkills --tutor
        if plot.data.category == "egg" then
            movepool = form.SharedSkills --egg
        end

        local move_table = {}
        local count = 0
        for i = 0, movepool.Count-1, 1 do
            if not table.contains(plot.data.permanent_stock, movepool[i].Skill) then
                count = count + 1
                for _, slot in pairs(plot.data.category_stock) do
                    if slot.ID ~= movepool[i].Skill then
                        table.insert(move_table, slot.ID)
                    end
                end
            end
        end
        plot.data.category_data[result.Species].forms[result.Form] = count
        if #move_table == 0 then
            table.remove(roll_table, index)
        else
            move = COMMON_FUNC.WeightlessRoll(move_table)
        end
    end

    local days = math.random(plot.data.category_frequency)
    local price = _SHOP.TutorTables.charge_to_cost[#_SHOP.TutorTables.charge_to_cost]
    if move ~= "" then
        local move_data = _DATA:GetSkill(move)
        if move_data.BaseCharges <= #_SHOP.TutorTables.charge_to_cost then
            price =_SHOP.TutorTables.charge_to_cost[move_data.BaseCharges]
        end
    end
    return {ID = move, Price = price, days_left = days}
end

function _SHOP.TutorInteract(plot, index)
    local npc = CH("NPC_"..index)
    UI:SetSpeaker(npc)
    local msg = STRINGS:FormatKey('TUTOR_INTRO', npc:GetDisplayName())
    local exit = false
    while not exit do
        local choices = {
            STRINGS:FormatKey('MENU_ITEM_LEARN'),
            STRINGS:FormatKey('TUTOR_OPTION_FORGET'),
            STRINGS:FormatKey('TUTOR_OPTION_TUTOR'),
            STRINGS:FormatKey("MENU_INFO"),
            STRINGS:FormatKey("MENU_EXIT")
        }
        if plot.data.category == "" then table.remove(choices, 3) end

        UI:BeginChoiceMenu(msg, choices, 1, #choices)
        UI:WaitForChoice()

        msg = STRINGS:FormatKey('TUTOR_REPEAT')

        local result = UI:ChoiceResult()
        if plot.data.category == "" and result > 2 then result = result + 1 end
        if result == 1 then
            UI:WaitShowDialogue(STRINGS:FormatKey('TUTOR_LEARN_WHO'))
            local loop = true
            while loop do
                local chosen_member = AssemblySelectMenu.run(function(c) return _SHOP.TutorCanRelearn(plot, c) end, false)

                if chosen_member == nil then
                    loop = false
                else
                    local skills, ids, prices = _SHOP.TutorGetLearnables(plot, chosen_member)

                    local loop2 = true --electric booleanoo
                    while loop and loop2 do
                        local chosen_move = ""
                        local choose = function(move) chosen_move = move end
                        local refuse = function() _MENU:RemoveMenu() end
                        local menu = SkillTutorMenu:new(STRINGS:FormatKey("MENU_ITEM_LEARN"), ids, prices, choose, refuse)
                        UI:SetCustomMenu(menu.menu)
                        UI:WaitForChoice()

                        if chosen_move == "" then
                            loop2 = false
                        else
                            local moveEntry = _DATA:GetSkill(chosen_move)
                            local learnedMove = COMMON.LearnMoveFlow(chosen_member, chosen_move, STRINGS:FormatKey('TUTOR_REPLACE'))

                            if learnedMove then
                                SOUND:PlayBattleSE("DUN_Money")
                                GAME:RemoveFromPlayerMoney(skills[chosen_move])
                                UI:WaitShowDialogue(STRINGS:FormatKey('TUTOR_BEGIN'))
                                _SHOP.TutorAnimation(npc)
                                SOUND:PlayFanfare("Fanfare/LearnSkill")
                                UI:WaitShowDialogue(STRINGS:FormatKey('TUTOR_LEARN_END', chosen_member:GetDisplayName(true), moveEntry:GetIconName()))
                                loop = false
                            end
                        end
                    end
                end
            end
        elseif result == 2 then
            UI:WaitShowDialogue(STRINGS:FormatKey('TUTOR_FORGET_WHO'))
            local chosen_member = AssemblySelectMenu.run(function(c) return GAME:CanForget(c) end, false)
            local loop = true
            while loop do
                if chosen_member == nil then
                    loop = false
                else
                    UI:ForgetMenu(chosen_member)
                    UI:WaitForChoice()
                    local chosen_slot = UI:ChoiceResult()
                    if chosen_slot > -1 then
                        UI:WaitShowDialogue(STRINGS:FormatKey('TUTOR_BEGIN'))
                        local move = GAME:GetCharacterSkill(chosen_member, chosen_slot)
                        local moveEntry = _DATA:GetSkill(move)
                        GAME:ForgetSkill(chosen_member, chosen_slot)
                        _SHOP.TutorAnimation(npc)
                        SOUND:PlayFanfare("Fanfare/LearnSkill")
                        UI:WaitShowDialogue(STRINGS:FormatKey('TUTOR_FORGET_END', chosen_member:GetDisplayName(true), moveEntry:GetIconName()))
                        loop = false
                    end
                end
            end
        elseif result == 3 then
            UI:WaitShowDialogue(STRINGS:FormatKey('TUTOR_LEARN_WHO'))
            local chosen_member = AssemblySelectMenu.run(function(chara) return _SHOP.TutorCanTutor(plot, chara) end, false)
            local loop = true
            while loop do
                if chosen_member == nil then
                    loop = false
                else
                    local skills = _SHOP.TutorGetTutorMoves(plot, chosen_member)

                    local loop2 = true --electric booleanoo
                    while loop and loop2 do
                        local chosen_move = SkillTutorMenu.runTutorMenu(skills, "loot_heart_scale")
                        if chosen_move ~= "" then
                            local moveEntry = _DATA:GetSkill(chosen_move)
                            local learnedMove = COMMON.LearnMoveFlow(chosen_member, chosen_move, STRINGS:Format('Tutor_Remember_Replace'))

                            if learnedMove then
                                local price = skills[chosen_move].Cost
                                SOUND:PlayBattleSE("DUN_Money")
                                for _ = 1, price, 1 do
                                    local item_slot = GAME:FindPlayerItem("loot_heart_scale", true, true)
                                    if not item_slot:IsValid() then
                                        --it is a certainty that there is an item in storage, due to checks inside the menu
                                        GAME:TakePlayerStorageItem("loot_heart_scale")
                                    elseif item_slot.IsEquipped then
                                        GAME:TakePlayerEquippedItem(item_slot.Slot)
                                    else
                                        GAME:TakePlayerBagItem(item_slot.Slot)
                                    end
                                end
                                UI:WaitShowDialogue(STRINGS:Format('TUTOR_BEGIN'))
                                _SHOP.TutorAnimation(npc)
                                SOUND:PlayFanfare("Fanfare/LearnSkill")
                                UI:WaitShowDialogue(STRINGS:Format('TUTOR_LEARN_END', chosen_member:GetDisplayName(true), moveEntry:GetIconName()))
                                loop = false
                            end
                        else
                            loop2 = false
                        end
                    end
                end
            end
        elseif result == 4 then
            UI:WaitShowDialogue(STRINGS:FormatKey('TUTOR_INFO_1'))
            UI:WaitShowDialogue(STRINGS:FormatKey('TUTOR_INFO_2'))
            UI:WaitShowDialogue(STRINGS:FormatKey('TUTOR_INFO_3'))
            UI:WaitShowDialogue(STRINGS:FormatKey('TUTOR_INFO_4'))
            if plot.data.category ~= "" then
                local category_str = STRINGS:FormatKey('TUTOR_CATEGORY_'..string.upper(plot.data.category))
                UI:WaitShowDialogue(STRINGS:FormatKey('TUTOR_INFO_5', category_str))
                if _HUB.getPlotLevel(plot) < 10 then
                    UI:WaitShowDialogue(STRINGS:FormatKey('TUTOR_INFO_6b', category_str))
                end
            else
                UI:WaitShowDialogue(STRINGS:FormatKey('TUTOR_INFO_6'))
            end
        else
            UI:WaitShowDialogue(STRINGS:FormatKey('TUTOR_BYE'))
            exit = true
        end
    end
end

function _SHOP.TutorGetCharacters()
    local characters = {}
    for char in luanet.each(LUA_ENGINE:MakeList(_DATA.Save.ActiveTeam.Players)) do table.insert(characters, char) end
    local assembly = GAME:GetPlayerAssemblyTable()
    table.move(assembly, 1, #assembly, #characters+1)
    return characters
end

function _SHOP.TutorGetLearnables(plot, character)
    local mapping = {}
    local skills = {}
    local prices = {}
    local loop = function(form_data)
        for i = 0, form_data.LevelSkills.Count-1, 1 do
            local skill = form_data.LevelSkills[i].Skill
            local level = form_data.LevelSkills[i].Level
            if level <= plot.data.level_limit and not character:HasBaseSkill(skill) then
                local price = math.max(100, level * 50)
                if not mapping[skill] then
                    table.insert(skills, skill)
                end
                if not mapping[skill] or mapping[skill] > price then
                    mapping[skill] = price
                end
            end
        end
    end
    local comp = function(a,b)
        if mapping[a] == mapping[b] then
            return _DATA:GetSkill(a).Name:ToLocal() < _DATA:GetSkill(b).Name:ToLocal()
        end
        return mapping[a] < mapping[b]
    end

    local species = _DATA:GetMonster(character.BaseForm.Species)
    local form = species.Forms[character.BaseForm.Form]
    loop(form)
    while species.PromoteFrom ~= "" do
        species = _DATA:GetMonster(species.promoteFrom)
        form = species.Forms[form.PromoteForm]
        loop(form)
    end

    table.sort(skills, comp)

    for _, skill in pairs(skills) do
        table.insert(prices, {mapping[skill], ""})
    end
    return mapping, skills, prices
end

function _SHOP.TutorGetTutorMoves(plot, character)
    local mapping = {}

    local check = function(pool, skill)
        if character:HasBaseSkill(skill) then return false end
        for i=0, pool.Count-1, 1 do
            if pool[i].Skill == skill then
                return true
            end
        end
        return false
    end

    local species = _DATA:GetMonster(character.BaseForm.Species)
    local form = species.Forms[character.BaseForm.Form]
    local movepool = form.SecretSkills --tutor
    if plot.data.category == "egg" then
        movepool = form.SharedSkills --egg
    end

    for _, slot in pairs(plot.data.category_stock) do
        if check(form, slot.ID) then
            local entry = {Cost = _SHOP.TutorGetPrice(slot.ID)}
            mapping[slot.ID] = entry
        end
    end
    for _, skill in pairs(plot.data.permanent_stock) do
        if check(form, skill) then
            local entry = {Cost = _SHOP.TutorGetPrice(skill)}
            mapping[skill] = entry
        end
    end

    return mapping
end

function _SHOP.TutorCanRelearn(plot, character)
    local loop = function(form_data)
        for i = 0, form_data.LevelSkills.Count-1, 1 do
            local skill = form_data.LevelSkills[i].Skill
            local level = form_data.LevelSkills[i].Level
            if level <= plot.data.level_limit then
                if not character:HasBaseSkill(skill) then return true end
            end
        end
        return false
    end

    local species = _DATA:GetMonster(character.BaseForm.Species)
    local form = species.Forms[character.BaseForm.Form]
    if loop(form) then return true end
    while species.PromoteFrom ~= "" do
        species = _DATA:GetMonster(species.promoteFrom)
        form = species.Forms[form.PromoteForm]
        if loop(form) then return true end
    end

    return false
end

function _SHOP.TutorCanTutor(plot, character)
    local check = function(pool, skill)
        if character:HasBaseSkill(skill) then return false end
        for i=0, pool.Count-1, 1 do
            if pool[i].Skill == skill then
                return true
            end
        end
        return false
    end

    local species = _DATA:GetMonster(character.BaseForm.Species)
    local form = species.Forms[character.BaseForm.Form]
    local movepool = form.SecretSkills --tutor
    if plot.data.category == "egg" then
        movepool = form.SharedSkills --egg
    end

    for _, slot in pairs(plot.data.category_stock) do
        if check(movepool, slot.ID) then return true end
    end
    for _, skill in pairs(plot.data.permanent_stock) do
        if check(movepool, skill) then return true end
    end
    return false
end

function _SHOP.TutorGetPrice(skill)
    local move = _DATA:GetSkill(skill)
    local price = _SHOP.TutorTables.charge_to_cost[#_SHOP.TutorTables.charge_to_cost]
    if move.BaseCharges <= #_SHOP.TutorTables.charge_to_cost then
        price = _SHOP.TutorTables.charge_to_cost[move.BaseCharges]
    end
    return price
end

function _SHOP.TutorAnimation(chara)
    GAME:WaitFrames(10)
    GROUND:CharSetAnim(chara, "Strike", false)
    GAME:WaitFrames(15)
    local emitter = RogueEssence.Content.FlashEmitter()
    emitter.FadeInTime = 2
    emitter.HoldTime = 4
    emitter.FadeOutTime = 2
    emitter.StartColor = Color(0, 0, 0, 0)
    emitter.Layer = DrawLayer.Top
    emitter.Anim = RogueEssence.Content.BGAnimData("White", 0)
    GROUND:PlayVFX(emitter, chara.MapLoc.X, chara.MapLoc.Y)
    SOUND:PlayBattleSE("EVT_Battle_Flash")
    GAME:WaitFrames(10)
    GROUND:CharSetAnim(chara, "Idle", true)
    GAME:WaitFrames(30)
end

function _SHOP.TutorGetDescription(plot)
    local description = STRINGS:FormatKey("PLOT_DESCRIPTION_TUTOR_BASE", plot.data.level_limit)
    if plot.data.category ~= "" then STRINGS:FormatKey("PLOT_DESCRIPTION_TUTOR_CATEGORY", STRINGS:FormatKey("UPGRADE_TEACH_"..string.upper(plot.data.category)), plot.data.category_slots) end
    if plot.data.category_permanent then STRINGS:FormatKey("PLOT_DESCRIPTION_TUTOR_PERMANENT", STRINGS:FormatKey("UPGRADE_TEACH_"..string.upper(plot.data.category))) end
    if #plot.data.permanent_stock > 0 then STRINGS:FormatKey("PLOT_DESCRIPTION_TUTOR_PERMANENT_NUM", STRINGS:FormatKey("UPGRADE_TEACH_"..string.upper(plot.data.category)), #plot.data.permanent_stock) end
    return description
end

_SHOP.callbacks.initialize["tutor"] =  _SHOP.TutorInitializer
_SHOP.callbacks.upgrade["tutor"] =     _SHOP.TutorUpgrade
_SHOP.callbacks.endOfDay["tutor"] =    _SHOP.TutorUpdate
_SHOP.callbacks.interact["tutor"] =    _SHOP.TutorInteract
_SHOP.callbacks.description["tutor"] = _SHOP.TutorGetDescription