--[[
    ShopInterface.lua

    These scripts deal with shop specific interaction, rerouting any shop-agnostic call to the right functions.
]]

_SHOP = {}
_SHOP.callbacks = {
    initialize = {}, --arguments: plot
    upgrade =    {}, --arguments: plot, upgrade
    endOfDay =   {}, --arguments: plot
    interact =   {}  --arguments: plot, index
}
--TODO note that everything has been tested only at level 1. Leveling shops up beyond that is still a big question.
require 'pmd_new_leaf.shops.Market'
require 'pmd_new_leaf.shops.Exporter'
require 'pmd_new_leaf.shops.Tutor'

--- Runs the initialize callback associated to thr given plot id's building.
--- @param index number the plot id to initialize
function _SHOP.InitializeShop(index)
    local plot = _HUB.getPlotData(index)
    if _SHOP.callbacks.initialize[plot.building] then
        _SHOP.callbacks.initialize[plot.building](plot)
        PrintInfo("Initialized shop "..index)
    end
end

--- Runs the upgrade callback associated to thr given plot id's building.
--- @param index number the plot id to upgrade
--- @param upgrade string the upgrade to be applied to the building
function _SHOP.UpgradeShop(index, upgrade)
    local plot = _HUB.getPlotData(index)
    if(_HUB.getPlotLevel(plot)) >= 10 then
        PrintError("Tried to apply upgrade to plot id "..index.." after reaching maximum level.")
        return
    end
    if _SHOP.callbacks.upgrade[plot.building] then
        _SHOP.callbacks.upgrade[plot.building](plot, upgrade)
        PrintInfo("Upgraded shop "..index)
    end
end

--- Runs the endOfDay callback for every single plot.
function _SHOP:OnDayEnd()
    _SHOP.EndOfDay("home")
    _SHOP.EndOfDay("office")
    for i = 1, 15, 1 do
        _SHOP.EndOfDay(i)
    end
end

--- Runs the endOfDay callback associated to thr given plot id's building.
--- @param index number the plot id to update
function _SHOP.EndOfDay(index)
    local plot = _HUB.getPlotData(index)
    if _SHOP.callbacks.endOfDay[plot.building] then
        _SHOP.callbacks.endOfDay[plot.building](plot)
        PrintInfo("Ran EndOfDay for shop "..index)
    end
end

--- Runs the interact callback associated to thr given plot id's building.
--- @param index number the plot that is being interacted with
function _SHOP.ShopInteract(index)
    local plot = _HUB.getPlotData(index)
    if _SHOP.callbacks.interact[plot.building] then
        local npc = CH("NPC_"..index)
        local start_rotation = npc.CharDir
        GROUND:CharTurnToCharAnimated(npc, CH("PLAYER"), 4)
        _SHOP.callbacks.interact[plot.building](plot, index)
        PrintInfo("Interacted with shop "..index)
        GROUND:CharAnimateTurnTo(npc, start_rotation, 4)
    end
    UI:ResetSpeaker()
end

--- Should only be called by a shop's upgrade callback when all validity checks have been ran successfully.
--- It adds the upgrade to the given shop structure.
--- @param plot table the plot's data structure
--- @param upgrade string the upgrade to be applied to the building
function _SHOP.ConfirmShopUpgrade(plot, upgrade)
    local found = false
    for _, upgr in pairs(plot.upgrades) do
        if upgr.type == upgrade then
            upgr.count = upgr.count+1
            found = true
            break
        end
    end
    if not found then table.insert(plot.upgrades, {type = upgrade, count = 1}) end
end