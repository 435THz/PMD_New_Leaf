--[[
    ShopInterface.lua

    These scripts deal with shop specific interaction, rerouting any shop-agnostic call to the right functions.
]]

_SHOP = {}
_SHOP.Order = {"home", "office", "market", "exporter", "tutor", "appraisal", "trader", "cafe"}
_SHOP.callbacks = {
    ---@type (fun(plot:PlotData))[]
    initialize =   {},
    ---@type (fun(plot:PlotData,index:PlotIndex,building:BuildingID):string|false)[]
    upgrade_flow = {},
    ---@type (fun(plot:PlotData,upgrade:string))[]
    upgrade =      {},
    ---@type (fun(plot:PlotData))[]
    endOfDay =     {},
    ---@type (fun(plot:PlotData,index:PlotIndex))[]
    interact =     {},
    ---@type (fun(plot:PlotData):string)[]
    description =  {}
}

require 'pmd_new_leaf.shops.Appraisal'
require 'pmd_new_leaf.shops.Cafe'
require 'pmd_new_leaf.shops.Exporter'
require 'pmd_new_leaf.shops.Market'
require 'pmd_new_leaf.shops.Office'
require 'pmd_new_leaf.shops.Trader'
require 'pmd_new_leaf.shops.Tutor'

--- Runs the initialize callback associated to the given plot id's building.
--- @param index PlotIndex home, office or any positive integer up to 15
--- @param building? BuildingID a building id. It is only considered if no building exists in the given plot yet
function _SHOP.InitializeShop(index, building)
    local plot = _HUB.getPlotData(index)
    if plot.building and plot.building ~= "" then building = plot.building end
    if _SHOP.callbacks.initialize[building] then
        _SHOP.callbacks.initialize[building](plot)
        plot.building = building --[[@as BuildingID]]
        PrintInfo("Initialized shop "..index)
    else
        plot.building = "" -- reset if invalid
    end
end

--- Applies the final changes after a newly built shop is initialized.
--- @param index PlotIndex home, office or any positive integer up to 15
function _SHOP.FinalizeShop(index)
    local plot = _HUB.getPlotData(index)
    local db = _HUB.ShopBase[plot.building]
    local npc, shiny = _HUB.DiscardUsed(db.Shopkeepers)
    plot.shopkeeper = COMMON_FUNC.WeightlessRoll(npc)
    plot.shopkeeper_shiny = shiny
end

--- Runs the upgrade_flow callback associated to the given plot id's building.
--- @param index PlotIndex home, office or any positive integer up to 15
--- @param building? BuildingID a building id. It is only considered if no building exists in the given plot yet
--- @return string|false #an upgrade to apply, or false if none was chosen
function _SHOP.ShopUpgradeFlow(index, building)
    local plot = _HUB.getPlotData(index)
    if plot.building and plot.building ~= "" then building = plot.building end
    ---@type string|false
    local ret = false
    if _SHOP.callbacks.upgrade_flow[building] then
        ---@cast building -?
        ret = _SHOP.callbacks.upgrade_flow[building](plot, index, building)
        PrintInfo("Ran upgrade flow for shop "..index)
    end
    return ret
end

--- Runs the upgrade flow callback associated to the given plot id's building.
--- @param index PlotIndex home, office or any positive integer up to 15
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
function _SHOP.OnDayEnd()
    _SHOP.EndOfDay("home")
    _SHOP.EndOfDay("office")
    for i = 1, 15, 1 do
        _SHOP.EndOfDay(i)
    end
end

--- Runs the endOfDay callback associated to the given plot id's building.
--- @param index PlotIndex home, office or any positive integer up to 15
function _SHOP.EndOfDay(index)
    local plot = _HUB.getPlotData(index)
    if _SHOP.callbacks.endOfDay[plot.building] then
        _SHOP.callbacks.endOfDay[plot.building](plot)
        PrintInfo("Ran EndOfDay for shop "..index)
    end
end

--- Runs the interact callback associated to the given plot id's building.
--- @param index PlotIndex home, office or any positive integer up to 15
function _SHOP.ShopInteract(index)
    local plot = _HUB.getPlotData(index)
    if _SHOP.callbacks.interact[plot.building] then
        local npc = CH("NPC_"..index)
        local start_rotation = RogueElements.Dir8.Down
        if npc then
            start_rotation = npc.CharDir
            GROUND:CharTurnToCharAnimated(npc, CH("PLAYER"), 4)
        end
        _SHOP.callbacks.interact[plot.building](plot, index)
        PrintInfo("Interacted with shop "..index)
        if npc then
            GROUND:CharAnimateTurnTo(npc, start_rotation, 4)
        end
    end
    UI:ResetSpeaker()
end

--- Should only be called by a shop's upgrade callback when all validity checks have been ran successfully.
--- It adds the upgrade to the given shop structure.
--- @param plot PlotData the plot's data structure
--- @param upgrade string the upgrade to be applied to the building
function _SHOP.ConfirmShopUpgrade(plot, upgrade)
    if plot.upgrades[upgrade] then
        plot.upgrades[upgrade] = plot.upgrades[upgrade]+1
    else
        plot.upgrades[upgrade] = 1
    end
end

--- Returns the plot's description used by the plot management menu.
--- @param plot PlotData the plot's data structure
--- @return string? #the description to be displayed
function _SHOP.GetPlotDescription(plot, index)
    if _SHOP.callbacks.description[plot.building] then
        return _SHOP.callbacks.description[plot.building](plot)
    elseif plot.building == "" then
        if plot.unlocked then
            return STRINGS:FormatKey("PLOT_DESCRIPTION_UNLOCKED")
        else
            local list = { { item = "loot_building_tools" } }
            local func = function(entry)
                local amount = math.ceil((_HUB.getUnlockedNumber()+1)/2)
                return COMMON_FUNC.PrintItemAmount(entry.item, amount)
            end
            local cost = COMMON_FUNC.BuildStringWithSeparators(list,func)
            local ret = STRINGS:FormatKey("PLOT_DESCRIPTION_LOCKED", cost)
            if index > _HUB.getBuildLimit() then
                local level = _HUB.getHubLevel()
                while index > _HUB.getBuildLimit(level) do
                    level = level+1
                end
                ret = ret.."\n"..STRINGS:FormatKey("PLOT_DESCRIPTION_OUT_OF_LIMIT", _HUB.getHubSuffix(), level)
            end
            return ret
        end
    end
end

---Returns the cost of an upgrade at a specific level.
---@param upgrade string an upgrade id
---@param level integer the level to calculate the upgrade cost of
---@return ItemEntry[] #a list of `{item = string, amount = number}` values
function _SHOP.GetUpgradeCost(upgrade, level)
    local lv = level
    local ret = {}
    local price = _HUB.UpgradeTable[upgrade].price
    while not price[lv] do
        lv = lv-1
        if lv==0 then return ret end
    end
    local mult = level-lv+1
    for _, item in pairs(price[lv]) do
        table.insert(ret, {item = item.item, amount = item.amount*mult})
    end
    return ret
end

---Returns the cost of an upgrade at a specific level.
---@param upgrade string an upgrade id
---@param sub_choice string a sub_choice id
---@param level integer the level to which to calculate the upgrade cost
---@return ItemEntry[] #a list of `{item = string, amount = number}` values
function _SHOP.GetFullUpgradeCost(upgrade, sub_choice, level)
    local res = _SHOP.GetUpgradeCost(upgrade, level)
    COMMON_FUNC.MergeItemLists(res, _SHOP.GetUpgradeCost(sub_choice, level))
    return res
end

---Builds the upgrade tree for the specified plot at the specified level.
---@param plot_id any home, office or any positive integer up to 15
---@param level integer the target level to generate the upgrade tree for
---@param building? BuildingID a building id. It is only considered if no building exists in the given plot yet
---@return UpgradeTree, string[] #an upgrade tree, and the keys corresponding to the surface level entries
function _SHOP.MakeUpgradeTree(plot_id, level, building)
    local plot = _HUB.getPlotData(plot_id)
    if plot.building and plot.building ~= "" then building = plot.building end
    local keys = {}
    ---@type UpgradeTree
    local structure = {}
    local upgrades = _HUB.ShopBase[building].Upgrades[level] --[[@as string[] ]]
    for _, upgrade in pairs(upgrades) do
        local data = _HUB.UpgradeTable[upgrade]
        ---@type UpgradeBranch
        local branch = {
            has_sub = false,
            sub = nil
        }
        local add = (not data.sub_choices) or #data.sub_choices==0
        if data.per_sub_choice then
            branch.has_sub = true
            local sub = {}
            for _, sub_choice in pairs(data.sub_choices) do
                if _SHOP.CheckSubUpgradeRequirements(data.requirements, upgrade, sub_choice, plot) then
                    table.insert(sub, sub_choice)
                    sub[sub_choice] = plot.upgrades[STRINGS:Format("{0}_{1}", upgrade, sub_choice)]
                    add = true
                end
            end
            if #sub>0 then
                branch.sub = sub
            end
        else
            add = _SHOP.CheckUpgradeRequirements(data.requirements, upgrade, _HUB.getPlotData(plot_id))
        end
        if add then
            table.insert(keys, upgrade)
            structure[upgrade] = branch
        end
    end
    return structure, keys
end

---Checks if the plot contains all necessary requirements for a specific upgrade
---@param requirements string[] the list of requirements this upgrade has
---@param upgrade string the upgrade to test for
---@param plot PlotData the plot's data structure
---@param sub? string used to test sub-choices. Can be nil. If set, it will check for the specific sub-choice
---@return boolean #true if all requirements are met, false otherwise
function _SHOP.CheckUpgradeRequirements(requirements, upgrade, plot, sub)
    local formatted = upgrade
    if sub then formatted = STRINGS:Format("{0}_{1}", upgrade, sub) end
    local level = math.max(0, #plot.upgrades[formatted] or 0)
    local max = _HUB.UpgradeTable[upgrade].max or 10
    if level >= max then return false end
    for _, requirement in pairs(requirements) do --requirement example: "!upgrade_generic:4"
        local neg = string.sub(requirement, 1, 1) == "!" --in the example, neg would be true
        local min_lv = 1
        local match_lv = string.match(requirement, ":%d+$") --in the example, match_lv would be ":4"
        if match_lv then min_lv = tonumber(string.sub(match_lv, 2)) or min_lv end --in the example, min_lv would be 4
        local s, e = 1, string.len(requirement)
        if neg then s = 2 end
        if match_lv then e = e-string.len(match_lv) end
        local req = string.sub(requirement, s, e) -- in the example, req would be "upgrade_generic"

        local check = neg  --in the example, check would be true here
        if plot.upgrades[req] and plot.upgrades[req] >= min_lv then
            check = not check --in the example, check would be false if the plot has 4 or more "upgrade_generic"s
        end
        if check == false then return false end
    end
    return true
end


---Checks if the plot contains all necessary requirements for a specific sub-upgrade branch
---@param requirements string[] the list of requirements this upgrade has
---@param upgrade string the upgrade to test for
---@param sub_choice string the specific sub_choice to test for
---@param plot PlotData the plot's data structure
---@return boolean #true if all requirements are met, false otherwise
function _SHOP.CheckSubUpgradeRequirements(requirements, upgrade, sub_choice, plot)
    local formatted = {}
    for _, requirement in pairs(requirements) do --requirement example: "market_unlock_{0}"
        table.insert(formatted, STRINGS:Format(requirement, sub_choice)) --sub {0} out with the sub_choice in question
    end
    return _SHOP.CheckUpgradeRequirements(formatted, upgrade, plot, sub_choice)
end