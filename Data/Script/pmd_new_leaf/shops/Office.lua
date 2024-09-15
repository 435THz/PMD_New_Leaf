--[[
    Office.lua

    Main town management.
    This file contains all office-specific callbacks and functionality data structures
]]

require 'pmd_new_leaf.menu.TownManagerMenu'
require 'pmd_new_leaf.menu.PlotManagerMenu'
--TODO require 'pmd_new_leaf.menu.PlotBuildMenu'

function _SHOP.OfficeInitializer(plot)
    plot.data = {}
end

function _SHOP.OfficeUpgrade(plot, upgrade) --TODO probably get rid of
    if upgrade ~= "upgrade_generic" then
        _SHOP.ConfirmShopUpgrade(plot, upgrade)
        _HUB.LevelUp()
    end
end

function _SHOP.OfficeUpdate(plot)
    --TODO refresh quests
end

function _SHOP.OfficeInteract(plot, _)
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
        msg = STRINGS:FormatKey('TUTOR_REPEAT')

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
                                local item_name = _DATA.GetItem(item_id):GetColoredName()
                                local cost = math.ceil((_HUB.getUnlockedNumber()+1)/2)
                                local number = COMMON.GetPlayerItemCount(item_id, true)
                                if cost<=number then
                                    UI:ChoiceMenuYesNo(STRINGS:FormatKey('OFFICE_RECLAIM_ASK', item_name, number, cost))
                                    UI:WaitForChoice()
                                    local ch = UI:ChoiceResult()
                                    if ch then
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
                                --TODO Build flow
                            else
                                --TODO "Upgrade, Move, Demolish" plot editor menu
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
                if loop then
                    --TODO continue message
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

_SHOP.callbacks.initialize["office"] = _SHOP.OfficeInitializer
_SHOP.callbacks.upgrade["office"] =    _SHOP.OfficeUpgrade
_SHOP.callbacks.endOfDay["office"] =   _SHOP.OfficeUpdate
_SHOP.callbacks.interact["office"] =   _SHOP.OfficeInteract