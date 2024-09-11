--[[
    Office.lua

    Main town management.
    This file contains all office-specific callbacks and functionality data structures
]]

require 'pmd_new_leaf.menu.PlotManagerMenu'

function _SHOP.OfficeInitializer(plot)
    plot.data = {}
end

function _SHOP.OfficeUpgrade(plot, upgrade)
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
            PrintInfo("Result is "..tostring(PlotManagerMenu.run()))
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