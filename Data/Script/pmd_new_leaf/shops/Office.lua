--[[
    Office.lua

    Main town management.
    This file contains all office-specific callbacks and functionality data structures
]]

require 'pmd_new_leaf.menu.office.TownManagerMenu'
require 'pmd_new_leaf.menu.office.PlotManagerMenu'
require 'pmd_new_leaf.menu.office.ShopManagerMenu'
require 'pmd_new_leaf.menu.office.PlotBuildMenu'
require 'pmd_new_leaf.menu.office.ShopMoveMenu'

---@alias OfficePlot {unlocked:boolean,building:BuildingID,upgrades:table<string,integer>,shopkeeper:ShopkeeperData,shopkeeper_shiny:boolean,data:OfficeData,empty:integer}
---@alias OfficeData {}

---Refreshes the quest board in the office
---@param plot OfficePlot the plot's data structire
function _SHOP.OfficeUpdate(plot)
    --TODO refresh quests
end

---Runs the interact flow for the town office
function _SHOP.OfficeInteract(_, _)
    local npc = CH("Pelipper")
    local player = CH("PLAYER")
    UI:SetSpeaker(npc)
    local msg = STRINGS:FormatKey('OFFICE_INTRO', _HUB.getFounder():GetDisplayName(true))
    local exit = false
    while not exit do
        -- MAIN FLOW
        local choices = {
            STRINGS:FormatKey('OFFICE_OPTION_MANAGE', _HUB.getHubSuffix()),
            STRINGS:FormatKey('OFFICE_TEAM_RENAME'),
            STRINGS:FormatKey('OFFICE_OPTION_QUESTS'),
            STRINGS:FormatKey("MENU_INFO"),
            STRINGS:FormatKey("MENU_EXIT")
        }

        UI:BeginChoiceMenu(msg, choices, 1, #choices)
        UI:WaitForChoice()
        msg = STRINGS:FormatKey('OFFICE_REPEAT')

        local result = UI:ChoiceResult()
        if result == 1 then
            -- HUB MANAGEMENT FLOW
            local town_start = 1
            local loop = true
            while loop do
                local chosen
                -- BASE TOWN MENU
                chosen = TownManagerMenu.run(town_start) --always slot 1 because it'll probably be the most used
                PrintInfo("Result is "..tostring(chosen))
                if chosen == "buildings" then
                    -- PLOT MANAGEMENT FLOW
                    local plot_start = 1
                    local loop2 = true --here we go again
                    while loop2 do
                        -- PLOT SELECTION MENU
                        local plot_id = PlotManagerMenu.run(plot_start)
                        if plot_id == -1 then loop2=false
                        else
                            plot_start = plot_id
                            local plot = _HUB.getPlotData(plot_id)
                            if not plot.unlocked then
                                -- RECLAIM FLOW
                                local item_id = "loot_building_tools"
                                local item_name = _DATA:GetItem(item_id):GetColoredName()
                                local cost = math.ceil((_HUB.getUnlockedNumber()+1)/2)
                                local number = COMMON.GetPlayerItemCount(item_id, true)
                                if cost<=number then
                                    UI:ChoiceMenuYesNo(STRINGS:FormatKey('OFFICE_RECLAIM_ASK', item_name, number, cost))
                                    UI:WaitForChoice()
                                    local ch = UI:ChoiceResult()
                                    if ch then
                                        UI:ResetSpeaker(false)
                                        SOUND:PlaySE("Fanfare/Item")
                                        UI:SetCenter(true)
                                        UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_GIVE_ITEM", item_name.." ("..cost..")"))
                                        UI:SetCenter(false)
                                        UI:SetSpeaker(npc)
                                        UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_ACTION_CONFIRM'))
                                        plot.unlocked = true
                                        COMMON_FUNC.RemoveItem("loot_building_tools", cost, true)
                                    end
                                else
                                    if number>0 then
                                        UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_RECLAIM_CANNOT', item_name, number))
                                    else
                                        UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_RECLAIM_ZERO', item_name))
                                    end
                                end
                            elseif plot.building == "" then
                                -- BUILD FLOW
                                local build_start = 1
                                local loop_build = true
                                while loop_build do
                                    local build
                                    -- SHOP SELECTION MENU
                                    build, build_start = PlotBuildMenu.run(plot_id, build_start)
                                    if build == "exit" then
                                        loop_build = false
                                    else
                                        local upgrade = _SHOP.ShopUpgradeFlow(plot_id, build)
                                        UI:SetSpeaker(npc)
                                        if upgrade then
                                            _SHOP.InitializeShop(plot_id, build)
                                            _SHOP.UpgradeShop(plot_id, upgrade)
                                            _SHOP.FinalizeShop(plot_id)
                                            UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_BUILD_SHOP", STRINGS:FormatKey("SHOP_OPTION_"..string.upper(build))))
                                            loop_build = false
                                        else
                                            _HUB.RemoveShop(plot_id)
                                        end
                                    end
                                end
                            else
                                -- SHOP MANAGEMENT FLOW
                                local shop_start = 1
                                local building = plot.building
                                local loop_plot = true
                                while loop_plot do
                                    local action
                                    -- SHOP ACTIONS MENU
                                    action, shop_start = ShopManagerMenu.run(plot_id, shop_start)
                                    if action == "exit" then
                                        loop_plot = false
                                    elseif action == "upgrade" then
                                        -- SHOP UPGRADE FLOW
                                        local upgrade = _SHOP.ShopUpgradeFlow(plot_id)
                                        UI:SetSpeaker(npc)
                                        if upgrade then
                                            _SHOP.UpgradeShop(plot_id, upgrade)
                                            UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_UPGRADE_SHOP", STRINGS:FormatKey("SHOP_OPTION_"..string.upper(building))))
                                            loop_plot = false
                                        end
                                    elseif action == "move" then
                                        -- SHOP MOVE FLOW
                                        local dest_id = ShopMoveMenu.run(plot_id)
                                        if dest_id ~= plot_id then
                                            _HUB.SwapPlots(plot_id, dest_id)
                                            UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_ACTION_CONFIRM"))
                                            plot_id = dest_id
                                        end
                                    elseif action == "demolish" then
                                        -- SHOP DEMOLISH FLOW
                                        UI:ChoiceMenuYesNo(STRINGS:FormatKey("OFFICE_DEMOLISH_ASK", STRINGS:FormatKey("SHOP_OPTION_"..string.upper(building))))
                                        UI:WaitForChoice()
                                        local ch = UI:ChoiceResult()
                                        if ch then
                                            local salvaged = _HUB.RemoveShop(plot_id)
                                            UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_DEMOLISH_SHOP"))
                                            UI:ResetSpeaker(false)
                                            UI:SetCenter(true)
                                            if #salvaged>0 then
                                                local func = function(entry) return COMMON_FUNC.PrintItemAmount(entry.Item, entry.Amount) end
                                                local salvage_str = COMMON_FUNC.BuildStringWithSeparators(salvaged, func)
                                                for _, item in ipairs(salvaged) do
                                                    GAME:GivePlayerStorageItem(item.Item, item.Amount)
                                                end
                                                SOUND:PlaySE("Fanfare/Item")
                                                UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_DEMOLISH_SHOP_SALVAGE", salvage_str))
                                                UI:WaitShowDialogue(STRINGS:FormatKey("DLG_ITEMS_TO_STORAGE"))
                                            else
                                                UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_DEMOLISH_SHOP_NO_SALVAGE"))
                                            end
                                            UI:SetCenter(false)
                                            UI:SetSpeaker(npc)
                                            loop_plot = false
                                        end
                                    end
                                end
                            end
                        end
                    end
                elseif chosen == "rename" then
                    -- TOWN RENAME FLOW
                    local loop_rename = true
                    while loop_rename do
                        local res = 1
                        if _HUB.getHubRank()<4 then
                            UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_TOWN_RENAME_ASK', _HUB.getHubSuffix()))
                            loop_rename = false
                        else
                            local part_key = "OFFICE_RANK_NAME_PROMPT_ADD_WORD"
                            if SV.HubData.UseSuffix then part_key = "OFFICE_RANK_NAME_PROMPT_REMOVE_WORD" end
                            local particle = STRINGS:FormatKey(part_key)
                            local rename_choices = {
                                STRINGS:FormatKey("OFFICE_OPTION_RENAME"),
                                STRINGS:FormatKey("OFFICE_OPTION_SUFFIX", particle),
                                STRINGS:FormatKey("MENU_EXIT")
                            }
                            UI:BeginChoiceMenu(STRINGS:FormatKey('OFFICE_TOWN_RENAME_ASK', _HUB.getHubSuffix()), rename_choices, 1, 3)
                            UI:WaitForChoice()
                            res = UI:ChoiceResult()
                        end
                        if res == 1 then
                            -- TOWN RENAME FLOW
                            local loop_input = true
                            while loop_input do
                                local name = COMMON_FUNC.runTextInputMenu(STRINGS:FormatKey("OFFICE_TOWN_RENAME_TITLE", _HUB.getHubSuffix()), STRINGS:FormatKey("OFFICE_TOWN_RENAME_NOTES"), SV.HubData.Name)
                                if name then
                                    local name_prev = name
                                    if SV.HubData.UseSuffix then name_prev = STRINGS:FormatKey(_HUB.RankNamePatterns[_HUB.getHubRank()], name, _HUB.getHubSuffix()) end
                                    UI:ChoiceMenuYesNo(STRINGS:FormatKey("OFFICE_TOWN_RENAME_CONFIRM", name_prev), true)
                                    UI:WaitForChoice()
                                    local ch = UI:ChoiceResult()
                                    if ch then
                                        SV.HubData.Name = name
                                        UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_TOWN_RENAME_END", _HUB.getHubSuffix(), _HUB.getHubName()))
                                        loop_input = false
                                    end
                                else
                                    loop_input = false
                                end
                            end
                        elseif res == 2 then
                            -- TOWN TOGGLE TITLE FLOW
                            local prompt = "OFFICE_RANK_NAME_PROMPT_ADD"
                            local particle = "OFFICE_RANK_NAME_PROMPT_ADD_PARTICLE"
                            if SV.HubData.UseSuffix then
                                prompt = "OFFICE_RANK_NAME_PROMPT_REMOVE"
                                particle = "OFFICE_RANK_NAME_PROMPT_REMOVE_PARTICLE"
                            end
                            UI:ChoiceMenuYesNo(STRINGS:FormatKey('OFFICE_RANK_NAME_PROMPT', STRINGS:FormatKey(prompt), _HUB.getHubSuffix(), STRINGS:FormatKey(particle)))
                            UI:WaitForChoice()
                            local ch = UI:ChoiceResult()
                            if ch then
                                SV.HubData.UseSuffix = not SV.HubData.UseSuffix
                            end
                            UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_TOWN_RENAME_END", _HUB.getHubSuffix(), _HUB.getHubName()))
                        else
                            loop_rename = false
                        end
                    end
                elseif chosen == "upgrade" then
                    -- TOWN UPGRADE FLOW
                    local cost = _HUB.getLevelUpItems(_HUB.getHubLevel()+1)
                    local rank_up = _HUB.getHubRank() < _HUB.LevelRankTable[_HUB.getHubLevel()+1]
                    if COMMON_FUNC.CheckCost(cost, true) then
                        local func = function(entry) return COMMON_FUNC.PrintItemAmount(entry.item, entry.amount) end
                        local cost_string = COMMON_FUNC.BuildStringWithSeparators(cost, func)
                        UI:ChoiceMenuYesNo(STRINGS:FormatKey("OFFICE_UPGRADE_TOWN_ASK", _HUB.getHubSuffix(), cost_string))
                        UI:WaitForChoice()
                        local ch = UI:ChoiceResult()

                        if ch then
                            COMMON_FUNC.RemoveItems(cost, true)
                            UI:ResetSpeaker(false)
                            SOUND:PlaySE("Fanfare/Item")
                            UI:SetCenter(true)
                            UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_GIVE_ITEM", cost_string))
                            UI:SetCenter(false)
                            UI:SetSpeaker(npc)
                            local prev_name = _HUB.getHubName()
                            UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_UPGRADE_TOWN", prev_name, _HUB.getHubLevel()+1))
                            _HUB.levelUpHub()
                            if rank_up then
                                UI:ResetSpeaker(false)
                                SOUND:PlaySE("Fanfare/LevelUp")
                                UI:SetCenter(true)
                                UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_RANK_UP_TOWN", prev_name, _HUB.getHubName()))
                                UI:SetCenter(false)
                                UI:SetSpeaker(npc)
                            end
                        end
                    else
                        UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_CANNOT_UPGRADE_TOWN", _HUB.getHubSuffix()))
                    end
                else
                    loop = false
                end
            end
        elseif result == 2 then
            -- TEAM RENAME FLOW
            local loop_input = true
            while loop_input do
                STRINGS:FormatKey("OFFICE_TEAM_RENAME_ASK")
                local name = COMMON_FUNC.runTextInputMenu(STRINGS:FormatKey("INPUT_TEAM_TITLE"), STRINGS:FormatKey("OFFICE_TEAM_RENAME_NOTES"), _DATA.Save.ActiveTeam.Name)
                if name then
                    UI:ChoiceMenuYesNo(STRINGS:FormatKey("OFFICE_TEAM_RENAME_CONFIRM", name), true)
                    UI:WaitForChoice()
                    local ch = UI:ChoiceResult()
                    if ch then
                        GAME:SetTeamName(name)
                        UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_TEAM_RENAME_END", name))
                        loop_input = false
                    end
                else
                    loop_input = false
                end
            end
        elseif result == 3 then
            -- QUEST FLOW
            UI:WaitShowDialogue("Sorry, i'm still getting the archive ready.[pause=0] Come back later.")
            --TODO quest system
        elseif result == 4 then
            -- INFO
            UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_INFO_1', _HUB.getHubName()))
            UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_INFO_2', _HUB.getHubSuffix(true)))
            if SV.Intro.ObtainedWishFragments or SV.Intro.HubTutorialProgress>=6 then
                if _HUB.getHubRank() == 1 then
                    UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_INFO_3', _HUB.getHubSuffix(true)))
                elseif _HUB.getHubLevel() < 10 then
                    UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_INFO_3b', _HUB.getHubSuffix(true)))
                else
                    UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_INFO_3c', _HUB.getHubSuffix(true)))
                end
            end
            UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_INFO_4'))
            UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_INFO_5'))
        else
            UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_BYE'))
            exit = true
        end
    end
end

_SHOP.callbacks.endOfDay["office"] = _SHOP.OfficeUpdate
_SHOP.callbacks.interact["office"] = _SHOP.OfficeInteract