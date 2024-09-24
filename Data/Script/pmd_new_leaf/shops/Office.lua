--[[
    Office.lua

    Main town management.
    This file contains all office-specific callbacks and functionality data structures
]]

require 'pmd_new_leaf.menu.office.TownManagerMenu'
require 'pmd_new_leaf.menu.office.PlotManagerMenu'
require 'pmd_new_leaf.menu.office.PlotBuildMenu'

function _SHOP.OfficeUpdate(plot)
    --TODO refresh quests
end

function _SHOP.OfficeInteract(_, _)
    local npc = CH("Pelipper")
    local player = CH("PLAYER")
    UI:SetSpeaker(npc)
    local msg = STRINGS:FormatKey('OFFICE_INTRO', player:GetDisplayName())
    local exit = false
    while not exit do
        local choices = {
            STRINGS:FormatKey('OFFICE_OPTION_MANAGE', _HUB.getHubSuffix()),
            STRINGS:FormatKey('OFFICE_OPTION_QUESTS'),
            STRINGS:FormatKey("MENU_INFO"),
            STRINGS:FormatKey("MENU_EXIT")
        }

        UI:BeginChoiceMenu(msg, choices, 1, #choices)
        UI:WaitForChoice()
        msg = STRINGS:FormatKey('OFFICE_REPEAT')

        local result = UI:ChoiceResult()
        if result == 1 then
            local loop = true
            while loop do
                local chosen = TownManagerMenu.run()
                PrintInfo("Result is "..tostring(chosen))
                if chosen == "buildings" then
                    local loop2 = true --here we go again
                    while loop2 do
                        local plot_id = PlotManagerMenu.run()
                        if plot_id == -1 then loop2=false
                        else
                            local plot = _HUB.getPlotData(plot_id)
                            if not plot.unlocked then
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
                                        UI:WaitShowDialogue(STRINGS:FormatKey("OFFICE_GIVE_ITEM", item_name.." ("..cost..")"))
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
                                local loop_build = true
                                while loop_build do
                                    local build = PlotBuildMenu.run(plot_id)
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
                                local building = plot.building
                                local loop_plot = true
                                while loop_plot do
                                    local action = ShopManagerMenu.run(plot_id)
                                    if action == "exit" then
                                        loop_plot = false
                                    elseif action == "upgrade" then
                                    elseif action == "move" then
                                    elseif action == "demolish" then
                                    end
                                end
                            end
                        end
                    end
                elseif chosen == "rename" then
                    --TODO rename flow and toggle suffix flow
                elseif chosen == "upgrade" then
                    --TODO upgrade flow
                else
                    loop = false
                end
            end
        elseif result == 2 then
            --TODO
        elseif result == 3 then
            UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_INFO_1')) --TODO
            UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_INFO_2')) --TODO
            UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_INFO_3')) --TODO
            UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_INFO_4')) --TODO
            UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_INFO_5')) --TODO
            UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_INFO_6')) --TODO
        else
            UI:WaitShowDialogue(STRINGS:FormatKey('OFFICE_BYE'))
            exit = true
        end
    end
end

_SHOP.callbacks.endOfDay["office"] =   _SHOP.OfficeUpdate
_SHOP.callbacks.interact["office"] =   _SHOP.OfficeInteract