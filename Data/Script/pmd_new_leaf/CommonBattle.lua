
-- COMMON_FUNC.AssignBossMoves(_DATA.Save.ActiveTeam.Players[0], 1, 1, 1)
---Dynamically builds a boss moveset and assigns it to the character.
---The character's level should be assigned before running this script. Reduce the level afterwards to be illegal about it.
---The character is always allowed to have as many level-up moves as it can learn at its level.
---@param chara any the character to build.
---@param tm_allowed number the maximum number of tm moves that the character is allowed to have. Defaults to 0
---@param tutor_allowed number the maximum number of tutor moves that the character is allowed to have. Defaults to 0
---@param egg_allowed number the maximum number of egg moves that the character is allowed to have. Defaults to 0
---@return "stab"|"coverage"|"damage"|"status"[] #the list of slot types chosen, in the order they were applied. Slot types are "stab", "coverage", "damage" and "status". Useful to apply changes later on.
function COMMON_FUNC.AssignBossMoves(chara, tm_allowed, tutor_allowed, egg_allowed)
    -- prepare lists
    local allowed = {level = 4}
    allowed.tm, allowed.tutor, allowed.egg = tm_allowed or 0, tutor_allowed or 0, egg_allowed or 0
    local moveset_table = COMMON_FUNC._battle.filterMoveset(chara, allowed.tm>0, allowed.tutor>0, allowed.egg>0)
    local synergies = {_Completed = {}} --synergies = {move = {ApplySynergy = {string = bool}, RequestSynergy = {string = bool}, Type = type}, _Completed = {string = bool}}
    local move_slot_options = {
        {"stab", "coverage", "damage", "status"},
        {"stab", "coverage", "status", "status"}
    }
    local move_slots = COMMON_FUNC.WeightlessRoll(move_slot_options)
    local shuffled_slots = table.shuffle(move_slots)
    local slot_to_moves = {} -- {string = {string}}

    for _, slot_type in pairs(shuffled_slots) do
        slot_to_moves[slot_type] = slot_to_moves[slot_type] or {}
        table.insert(slot_to_moves[slot_type], COMMON_FUNC._battle[slot_type](moveset_table, synergies, allowed))
    end
    for i, slot_type in pairs(move_slots) do
        local move = slot_to_moves[slot_type][1]
        if move == "" then
            chara:DeleteSkill(i-1)
        else
            chara:ReplaceSkill(move, i-1, true)
        end
        table.remove(slot_to_moves[slot_type], 1)
    end
    return shuffled_slots
end

COMMON_FUNC._battle = {events = {}, states = {}}
COMMON_FUNC._battle.events.StatusPowerEvent = luanet.import_type('PMDC.Dungeon.StatusPowerEvent')
COMMON_FUNC._battle.events.StatusStackDifferentEvent = luanet.import_type('PMDC.Dungeon.StatusStackDifferentEvent')
COMMON_FUNC._battle.events.MajorStatusPowerEvent = luanet.import_type('PMDC.Dungeon.StatusPowerEvent')
COMMON_FUNC._battle.events.WeatherNeededEvent = luanet.import_type('PMDC.Dungeon.WeatherNeededEvent')
COMMON_FUNC._battle.events.ChargeOrReleaseEvent = luanet.import_type('PMDC.Dungeon.ChargeOrReleaseEvent')
COMMON_FUNC._battle.events.GiveMapStatusEvent = luanet.import_type('PMDC.Dungeon.GiveMapStatusEvent')
COMMON_FUNC._battle.events.StatusBattleEvent = luanet.import_type('PMDC.Dungeon.StatusBattleEvent')
COMMON_FUNC._battle.events.AdditionalEvent = luanet.import_type('PMDC.Dungeon.AdditionalEvent')
COMMON_FUNC._battle.events.AddContextStateEvent = luanet.import_type('PMDC.Dungeon.AddContextStateEvent')
COMMON_FUNC._battle.states.MajorStatusState = luanet.import_type('PMDC.Dungeon.MajorStatusState')
COMMON_FUNC._battle.states.SleepAttack = luanet.import_type('PMDC.Dungeon.SleepAttack')

function COMMON_FUNC._battle.filterMoveset(chara, tm_allowed, tutor_allowed, egg_allowed)
    local moveset_table = {
        all = {
            --id = {sub = {stab, coverage, damage, status}, {level, tm, tutor, egg}, value = table}
        },
        level = {
            stab = {}, --{ID = string, Category = string, Weight = number, ApplySynergy = string[], RequestSynergy = string[]}
            coverage = {},
            damage = {},
            status = {}
        },
        tm = {
            stab = {},
            coverage = {},
            damage = {},
            status = {}
        },
        tutor = {
            stab = {},
            coverage = {},
            damage = {},
            status = {}
        },
        egg = {
            stab = {},
            coverage = {},
            damage = {},
            status = {}
        }
    }
    local workPhases = {
        {"level", true,          function(form) return form.LevelSkills end},
        {"tm",    tm_allowed,    function(form) return form.TeachSkills end},
        {"tutor", tutor_allowed, function(form) return form.SecretSkills end},
        {"egg",   egg_allowed,   function(form) return form.SharedSkills end}
    } 
    local stages = {}
    local evolutionStage = chara.BaseForm
    local stageData = _DATA:GetMonster(evolutionStage.Species)
    local stageForm = stageData.Forms[evolutionStage.Form]

    local types = {stageForm.Element1, stageForm.Element1}
    if stageForm.Element2 ~= "" then types[2] = stageForm.Element2 end
    local coverage = COMMON_FUNC._battle.GetCoverageTypes(types)
    local attackStats = {stageForm.BaseAtk, stageForm.BaseMAtk}
    while (evolutionStage:IsValid()) do
        stageData = _DATA:GetMonster(evolutionStage.Species)
        stageForm = stageData.Forms[evolutionStage.Form]
        table.insert(stages, stageForm)
        evolutionStage = RogueEssence.Dungeon.MonsterID(stageData.PromoteFrom, stageForm.PromoteForm, evolutionStage.Skin, evolutionStage.Gender);
    end

    for _, form in ipairs(stages) do
        for _, phase in ipairs(workPhases) do
            if phase[2] then
                local supertable = phase[1]
                local skillList = phase[3](form)
                for i=0, skillList.Count-1, 1 do
                    if not skillList[i].Level or skillList[i].Level<=chara.Level then
                        local skill = skillList[i].Skill
                        local value = {ID = skill, Category = "status", Weight = 1000, ApplySynergy = {}, RequestSynergy = {}}
                        if not moveset_table.all[skill] then
                            local skillData = _DATA:GetSkill(skill)
                            local category, subtables = -1, {}
                            if skillData.Data.Category == RogueEssence.Data.BattleData.SkillCategory.Status then
                                category, subtables = 0, {"status"}
                                COMMON_FUNC._battle.SynergyLookup(skillData, value)
                                table.insert(moveset_table[supertable].status, value) --we save now because the other categories are damage only anyway
                            elseif skillData.Data.Category == RogueEssence.Data.BattleData.SkillCategory.Physical then
                                category, subtables = 1, {"damage"}
                            elseif skillData.Data.Category == RogueEssence.Data.BattleData.SkillCategory.Magical then
                                category, subtables = 2, {"damage"}
                            end
                            if category > 0 then
                                value.Category = "damage"
                                COMMON_FUNC._battle.SynergyLookup(skillData, value)
                                local PowerStateType = luanet.import_type('RogueEssence.Dungeon.BasePowerState')
                                local power = skillData.Data.SkillStates:GetWithDefault(luanet.ctype(PowerStateType))
                                if power and power.Power>0 then power = power.Power else power = 40 end
                                local weight = power * skillData.Strikes * attackStats[category]
                                if table.contains(types, skillData.Data.Element) then
                                    weight = math.floor(weight*1.5)
                                    table.insert(subtables, "stab")
                                end
                                if table.contains(coverage, skillData.Data.Element) then
                                    table.insert(subtables, "coverage")
                                end
                                for _, subtable in ipairs(subtables) do
                                    value.Weight = weight
                                    table.insert(moveset_table[supertable][subtable], value)
                                end
                            end
                            if #subtables>0 then
                                moveset_table.all[skill] = {cat = subtables, tables = {supertable}, value = value}
                            end
                        else
                            for _, subtable in ipairs(moveset_table.all[skill].cat) do
                                table.insert(moveset_table[supertable][subtable], moveset_table.all[skill].value)
                            end
                            table.insert(moveset_table.all[skill].tables, supertable)
                        end
                    end
                end
            end
        end
    end

    return moveset_table
end

function COMMON_FUNC._battle.GetCoverageTypes(types)
    local all_types = _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Element]:GetOrderedKeys(true)
    local weaknesses = {}
    local coverage = {}
    for id in luanet.each(all_types) do
        local matchup = 0
        for _, id2 in ipairs(types) do
            matchup = matchup + PMDC.Dungeon.PreTypeEvent.CalculateTypeMatchup(id, id2)
        end
        if matchup >= PMDC.Dungeon.PreTypeEvent.S_E_2 then
            table.insert(weaknesses, id)
        end
    end
    for id in luanet.each(all_types) do
        for _, id2 in ipairs(weaknesses) do
            local matchup = PMDC.Dungeon.PreTypeEvent.CalculateTypeMatchup(id, id2)
            if matchup >= PMDC.Dungeon.PreTypeEvent.S_E then
                table.insert(coverage, id)
                break
            end
        end
    end
    return coverage
end

function COMMON_FUNC._battle.SynergyLookup(skill, entry)
    local data = skill.Data
    local events = COMMON_FUNC._battle.events
    local states = COMMON_FUNC._battle.states

    local memory = {}
    for pair in luanet.each(LUA_ENGINE:MakeList(data.BeforeTryActions)) do
        if LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(events.WeatherNeededEvent) then
            --before try actions, WeatherNeededEvent and ChargeOrReleaseEvent, request "weather <WeatherID>"
            if memory.weather and memory.weather.chargerelease and not memory.weather.request then
                table.insert(entry.RequestSynergy, "weather "..pair.Value.WeatherID)
            end
            memory.weather = memory.weather or {}
            memory.weather.request = "weather "..pair.Value.WeatherID
        elseif LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(events.ChargeOrReleaseEvent) then
            --before try actions, WeatherNeededEvent and ChargeOrReleaseEvent, request "weather <WeatherID>"
            if memory.weather and memory.weather.request and not memory.weather.chargerelease then
                table.insert(entry.RequestSynergy, memory.weather.request)
            end
            memory.weather = memory.weather or {}
            memory.weather.chargerelease = true
        end
    end
    for pair in luanet.each(LUA_ENGINE:MakeList(data.BeforeActions)) do
        if LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(events.AddContextStateEvent) then
            --before actions, AddContextStateEvent.SleepAttack, request "user sleep"
            if not pair.Value.Global and LUA_ENGINE:TypeOf(pair.Value.AddedState) == luanet.ctype(states.SleepAttack) then
                table.insert(entry.RequestSynergy, "user sleep")
            end
        end
    end
    for pair in luanet.each(LUA_ENGINE:MakeList(data.OnActions)) do
        if LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(events.StatusStackDifferentEvent) then
            --on actions, StatusStackDifferentEvent, request "user <StatusID>"
            table.insert(entry.RequestSynergy, "user "..pair.Value.StatusID)
        elseif LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(events.MajorStatusPowerEvent) then
            --on actions, MajorStatusPowerEvent(num>den), request "<AffectedTarget> MajorStatus"
            if pair.Value.Numerator > pair.Value.Denominator then
                local target = "user"
                if pair.Value.AffectTarget == true then target = "target" end
                table.insert(entry.RequestSynergy, target.." major status")
            end
        end
    end
    for pair in luanet.each(LUA_ENGINE:MakeList(data.BeforeHits)) do
        if LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(events.StatusPowerEvent) then
            --before hits, StatusPowerEvent, request "<AffectTarget> <StatusID>"
            local target = "user"
            if pair.Value.AffectTarget == true then target = "target" end
            table.insert(entry.RequestSynergy, target.." "..pair.Value.StatusID)
        end
    end
    for pair in luanet.each(LUA_ENGINE:MakeList(data.OnHits)) do
        if LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(events.GiveMapStatusEvent) then
            --on hits, GiveMapStatusEvent, apply "weather <WeatherID>"
            table.insert(entry.ApplySynergy, "weather "..pair.Value.StatusID)
        elseif LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(events.StatusBattleEvent) then
            --on hits, StatusBattleEvent, apply "<AffectTarget> <StatusID>"
            local target = "user"
            if pair.Value.AffectTarget == true then target = "target" end
            local status = _DATA:GetStatus(pair.Value.StatusID)
            for state in luanet.each(status.StatusStates) do
                if LUA_ENGINE:TypeOf(state) == luanet.ctype(states.MajorStatusState) then
                    table.insert(entry.ApplySynergy, target.." major status")
                end
            end
            table.insert(entry.ApplySynergy, target.." "..pair.Value.StatusID)
        elseif LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(events.AdditionalEvent) then
            --on hits, AdditionalEvent.StatusBattleEvent, apply "<AffectTarget> <StatusID>"
            for event in luanet.each(pair.Value.BaseEvents) do
                if LUA_ENGINE:TypeOf(event) == luanet.ctype(events.StatusBattleEvent) then
                    local target = "user"
                    if pair.Value.AffectTarget == true then target = "target" end
                    local status = _DATA:GetStatus(event.StatusID)
                    for state in luanet.each(status.StatusStates) do
                        if LUA_ENGINE:TypeOf(state) == luanet.ctype(states.MajorStatusState) then
                            table.insert(entry.ApplySynergy, target.." major status")
                        end
                    end
                    table.insert(entry.ApplySynergy, target.." "..event.StatusID)
                end
            end
        end
    end
end

---picks one stab move if the list is not empty. Otherwise, coverage gets called
function COMMON_FUNC._battle.stab(moveset_table, synergies, allowed)
    local fallback = function() return COMMON_FUNC._battle.coverage(moveset_table, synergies, allowed) end
    return COMMON_FUNC._battle.selectMove(moveset_table, synergies, allowed, "stab", fallback)
end

---picks one coverage move if the list is not empty. Otherwise, damaging gets called
function COMMON_FUNC._battle.coverage(moveset_table, synergies, allowed)
    local fallback = function() return COMMON_FUNC._battle.damage(moveset_table, synergies, allowed) end
    return COMMON_FUNC._battle.selectMove(moveset_table, synergies, allowed, "coverage", fallback)
end

---picks one damaging move if the list is not empty. Otherwise, it picks one status move. If that list is also empty, it selects nothing.
function COMMON_FUNC._battle.damage(moveset_table, synergies, allowed)
    local pick_none = function() return "" end
    local fallback = function() return COMMON_FUNC._battle.selectMove(moveset_table, synergies, allowed, "status", pick_none) end
    return COMMON_FUNC._battle.selectMove(moveset_table, synergies, allowed, "damage", fallback)
end

---picks one status move if the list is not empty. Otherwise, it picks one damaging move. If that list is also empty, it selects nothing.
function COMMON_FUNC._battle.status(moveset_table, synergies, allowed)
    local pick_none = function() return "" end
    local fallback = function() return COMMON_FUNC._battle.selectMove(moveset_table, synergies, allowed, "damage", pick_none) end
    return COMMON_FUNC._battle.selectMove(moveset_table, synergies, allowed, "status", fallback)
end

---picks one move from the subtable if the list is not empty. Otherwise, fallback gets called
function COMMON_FUNC._battle.selectMove(moveset_table, synergies, allowed, subtable, fallback)
    local data_list = {}
    local id_list = {}
    local optional = {"tm", "tutor", "egg"}
    local phases = {"level"}
    for i, phase in ipairs(optional) do
        if allowed[phase]>0 then table.insert(phases, optional[i]) end
    end
    local maxweight = 0
    for _, tbl in ipairs(phases) do
        local list = table.deepcopy(moveset_table[tbl][subtable])
        for _, data in ipairs(list) do
            if not id_list[data.ID] then
                id_list[data.ID] = true
                if moveset_table.all[data.ID] then
                    table.insert(data_list, data)
                    --boost moves that would complete a synergy
                    data.Weight = data.Weight * COMMON_FUNC._battle.GetSynergyMultiplier(data, synergies)
                    maxweight = math.max(maxweight, data.Weight or 0)
                end
            end
        end
    end
    --heavily penalize lower weights, potentially removing them completely
    if #data_list>0 then
        local len = #data_list
        for i=1, len, 1 do
            local j = len -i + 1
            local data = data_list[j]
            local new_wt = data.Weight - (maxweight-data.Weight)
            if new_wt<=0 then table.remove(data_list, j)
            else
                data.Weight = math.floor(new_wt)
            end
        end
    end
    local result
    if #data_list > 0 then
        result = COMMON_FUNC.WeightedRoll(data_list)
        ---@cast result -?
        COMMON_FUNC._battle.UpdateSynergies(result, synergies)
        result = result.ID
        local supertables = moveset_table.all[result].tables
        allowed[supertables[1]] = allowed[supertables[1]]-1
        moveset_table.all[result] = nil
    else
        result = fallback()
    end
    return result
end

function COMMON_FUNC._battle.GetSynergyMultiplier(data, synergies)
    local mult = 1
    local fulfilled = false
    for _, syn_data in ipairs(synergies) do
        --move allows a synergy another move requests
        for _, syn in ipairs(data.ApplySynergy) do
            if syn_data.RequestSynergy[syn] then
                mult = mult*1.75
                break
            end
        end
        --move requests a synergy another move allows
        for _, syn in ipairs(data.RequestSynergy) do
            if syn_data.ApplySynergy[syn] then
                mult = mult*1.25
                break
            end
        end
        if data.Category ~= "status" and syn_data.Type == data.Type then
            mult = mult * 0.85
        end
    end
    --no move allows this synergy and this is the last move
    if #synergies == 3 and #data.RequestSynergy>0 and not fulfilled then
        return 0
    end
    return mult
end

function COMMON_FUNC._battle.UpdateSynergies(data, synergies)
    local newdata = {RequestSynergy = {}, ApplySynergy = {}, Type = data.Type} -- {synergy = true}
    for _, syn in ipairs(data.ApplySynergy) do
        if not synergies._Completed[syn] then
            for _, syn_data in ipairs(synergies) do
                if syn_data.RequestSynergy[syn] then
                    synergies._Completed[syn] = true
                end
                if synergies._Completed[syn] then
                    syn_data.RequestSynergy = {}
                end
            end
            if not synergies._Completed[syn] then
                newdata.ApplySynergy[syn] = true
            end
        end
    end
    for _, syn in ipairs(data.RequestSynergy) do
        if not synergies._Completed[syn] then
            for _, syn_data in ipairs(synergies) do
                if syn_data.ApplySynergy[syn] then
                    synergies._Completed[syn] = true
                    syn_data.ApplySynergy[syn] = nil
                    synergies = newdata
                end
            end
        end
        if synergies._Completed[syn] then
            newdata.RequestSynergy = {}
            break
        end
        newdata.RequestSynergy[syn] = true
    end
    table.insert(synergies, newdata)
end