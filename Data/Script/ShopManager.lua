_HUB.UpgradeTable = {
    pool_unlock = {
        -- used as string reference when displaying
        string = "UPGRADE_POOL_UNLOCK",
        -- all of these upgrades are required for this option to appear. Subchoice reference is {0} if per_sub_choice is true
        -- start with a ! for negation, end with : and a number to require a specific level or above
        requirements = {},
        -- when this option is chosen, ask this question to the player and show the chosen sub_choices
        -- has no meaning if sub_choices is nil
        sub_question = "UPGRADE_POOL_UNLOCK_QUESTION",
        -- when this option is chosen, show a submenu with these choices
        -- the final reference id for a specific sub_choice is choiceId_subchoiceId
        -- subchoices should be defined somewhere else in this table
        sub_choices = {
            "sub_food", "sub_heal", "sub_special", "sub_seeds", "sub_tm", "sub_exploration", "sub_battle"
        },
        -- maximum copies of this upgrade allowed on a single shop
        max = 1,
        -- if true, the "max" and "requirements" parameters will refer to the sub_choices instead
        -- has no meaning if sub_choices is nil
        per_sub_choice = true
    },
    pool_expand = {
        string = "UPGRADE_POOL_EXPAND",
        requirements = {"pool_unlock_{0}"},
        sub_question = "UPGRADE_POOL_EXPAND_QUESTION",
        sub_choices = {
            "sub_food", "sub_heal", "sub_special", "sub_seeds", "sub_tm", "sub_exploration", "sub_battle"
        },
        max = 2,
        per_sub_choice = true
    },
    pool_tier = {
        string = "UPGRADE_POOL_TIER",
        requirements = {"pool_unlock_{0}"},
        sub_question = "UPGRADE_POOL_TIER_QUESTION",
        sub_choices = {
            "sub_food", "sub_heal", "sub_special", "sub_seeds", "sub_tm", "sub_exploration", "sub_battle"
        },
        max = 2,
        per_sub_choice = true
    },
    pool_specialize = {
        string = "UPGRADE_POOL_SPECIALIZE",
        requirements = {"pool_unlock_{0}"},
        sub_question = "UPGRADE_POOL_SPECIALIZE_QUESTION",
        sub_choices = {
            "sub_food", "sub_heal", "sub_special", "sub_seeds", "sub_tm", "sub_exploration", "sub_battle"
        },
        max = 1,
        per_sub_choice = true
    },
    sub_food = {
        -- sub-choices can contain just a string parameter if they're never used as main choices
        string = "UPGRADE_POOL_FOOD"
    },
    sub_heal = {
        string = "UPGRADE_POOL_HEAL"
    },
    sub_special = {
        string = "UPGRADE_POOL_SPECIAL"
    },
    sub_seeds = {
        string = "UPGRADE_POOL_SEEDS"
    },
    sub_tm = {
        string = "UPGRADE_POOL_TM"
    },
    sub_exploration = {
        string = "UPGRADE_POOL_EXPLORATION"
    },
    sub_battle = {
        string = "UPGRADE_POOL_BATTLE"
    },
    upgrade_generic = {
        string = "UPGRADE_GENERIC",
        requirements = {},
        max = 10
    },
    upgrade_tutor_5 = {
        string = "UPGRADE_GENERIC",
        requirements = {},
        sub_question = "UPGRADE_TUTOR_5_QUESTION",
        sub_choices = {"sub_tutor", "sub_egg"},
        max = 1
    },
    sub_tutor = {
        string = "UPGRADE_TEACH_TUTOR"
    },
    sub_egg = {
        string = "UPGRADE_TEACH_EGG"
    },
    upgrade_tutor = {
        string = "UPGRADE_GENERIC",
        requirements = {},
        sub_question = "UPGRADE_TUTOR_QUESTION",
        sub_choices = {"sub_teach_count", "sub_teach_chance"},
        max = 2
    },
    sub_teach_count = {
        string = "UPGRADE_TEACH_COUNT"
    },
    sub_teach_chance = {
        string = "UPGRADE_TEACH_CHANCE"
    }
    -- add more here if necessary
}

_HUB.ShopBase = {
    -- TODO all tiers 2 and up
    home = {
        Shopkeepers = {}, --only for home and office, no shopkeepers are not only allowed but also expected
        Upgrades = {
            {"upgrade_generic"},    --level 1
            {"upgrade_generic"},    --level 2
            {"upgrade_generic"},    --level 3
            {"upgrade_generic"},    --level 4
            {"upgrade_generic"},    --level 5
            {"upgrade_generic"},    --level 6
            {"upgrade_generic"},    --level 7
            {"upgrade_generic"},    --level 8
            {"upgrade_generic"},    --level 9
            {"upgrade_generic"},    --level 10
        },
        Graphics = {
            {
                -- name of the Object sprite. It must be a square, and it will be centered automatically if it is not 96x
                Base = "home_tier1",
                -- name of the Object sprite to be drawn on top of NPCs. It must be a square, and it will be centered automatically if it is not 96x
                TopLayer = "home_tier1_top",
                -- Location of this building's Marker.
                -- Every single coordinate will be an offset from the plot's origin (not the image, the plot itself)
                Marker_Loc = {X = 55, Y = 82},
                -- list of bounding box data
                Bounds = {
                    {
                        -- every bounding box name must be unique for a specific sprite.
                        -- for scripting purposes, box entity names will be <box_name>_<plot_id>.
                        Name = "Entrance",
                        -- if true, it won't be possible to walk on top of the box. defaults to true
                        Solid = true,
                        -- trigger type. defaults to None
                        Trigger = RogueEssence.Ground.GroundEntity.EEntityTriggerTypes.TouchOnce,
                        -- box coordinates and sizes
                        X=46, Y=73, W=34, H=8
                    },
                    {
                        Name = "Storage",
                        Trigger = RogueEssence.Ground.GroundEntity.EEntityTriggerTypes.Action,
                        X=5,  Y=72, W=22, H=2455
                    },
                    {
                        Name = "Right",
                        X=74, Y=51, W=14, H=31
                    },
                    {
                        Name = "Left",
                        X=9,  Y=47, W=37, H=49
                    },
                    {
                        Name = "Back",
                        X=46, Y=47, W=28, H=26
                    }
                }
            },
            {},
            {},
            {}
        }
    },
    office = {
        Shopkeepers = {}, --only for home and office, no shopkeepers are not only allowed but also expected
        Upgrades = {
            {"upgrade_generic"},    --level 1
            {"upgrade_generic"},    --level 2
            {"upgrade_generic"},    --level 3
            {"upgrade_generic"},    --level 4
            {"upgrade_generic"},    --level 5
            {"upgrade_generic"},    --level 6
            {"upgrade_generic"},    --level 7
            {"upgrade_generic"},    --level 8
            {"upgrade_generic"},    --level 9
            {"upgrade_generic"},    --level 10
        },
        Graphics = {
            {
                Base = "office_tier1",
                TopLayer = "office_tier1_top",
                Marker_Loc = {X = 25, Y = 82},
                Bounds = {
                    {
                        Name = "Entrance",
                        Solid = true,
                        Trigger = RogueEssence.Ground.GroundEntity.EEntityTriggerTypes.TouchOnce,
                        X=16, Y=73, W=34, H=8
                    },
                    {
                        Name = "Left",
                        X=8, Y=51, W=14, H=31
                    },
                    {
                        Name = "Right",
                        X=50,  Y=47, W=21, H=49
                    },
                    {
                        Name = "Right2",
                        X=71,  Y=47, W=16, H=43
                    },
                    {
                        Name = "Back",
                        X=22, Y=47, W=28, H=26
                    }
                }
            },
            {},
            {},
            {}
        }
    },
    market = {
        -- list of species ids. No two shops will ever pick the same shopkeeper species unless the pool is fully used up.
        -- If that's the case, MonsterID details will be edited so that two shopkeepers still never look the same
        Shopkeepers = {"porygon", "shuckle", "kecleon", "maushold"},
        -- list of possible upgrades that can be picked for every level of the shop
        Upgrades = {
            {"pool_unlock"},                                              --shop level 1
            {"pool_unlock","pool_expand","pool_tier"},                    --shop level 2
            {"pool_unlock","pool_expand","pool_tier"},                    --shop level 3
            {"pool_unlock","pool_expand","pool_tier"},                    --shop level 4
            {"pool_unlock","pool_expand","pool_tier"},                    --shop level 5
            {"pool_unlock","pool_expand","pool_tier", "pool_specialize"}, --shop level 6
            {"pool_unlock","pool_expand","pool_tier"},                    --shop level 7
            {"pool_unlock","pool_expand","pool_tier"},                    --shop level 8
            {"pool_unlock","pool_expand","pool_tier"},                    --shop level 9
            {"pool_unlock","pool_expand","pool_tier"},                    --shop level 10
        },
        -- Data structure containing graphics and hitbox data for spawning and displaying the shop
        Graphics = {
            {
                Base = "market_tier1",
                -- Spawn location of this building's NPC.
                -- For scripting purposes, NPC name will be NPC_<plot_id>
                NPC_Loc = { X = 40, Y = 56 },
                Bounds = {
                    {
                        Name = "Left_Front",
                        X = 16, Y = 56, W = 24, H = 24
                    },
                    {
                        Name = "Left_Mid",
                        X = 8, Y = 40, W = 24, H = 24
                    },
                    {
                        Name = "Left_Back",
                        X = 16, Y = 24, W = 24, H = 24
                    },
                    {
                        Name = "Right_Front",
                        X = 56, Y = 56, W = 24, H = 24
                    },
                    {
                        Name = "Right_Mid",
                        X = 64, Y = 40, W = 24, H = 24
                    },
                    {
                        Name = "Right_Back",
                        X = 56, Y = 24, W = 24, H = 24
                    },
                    {
                        Name = "Back",
                        X = 40, Y = 16, W = 16, H = 24
                    }
                }
            },
            {},
            {},
            {}
        }
    },
    move_tutor = {
        Shopkeepers = {"machoke", "blaziken", "electivire", "mienshao"},
        Upgrades = {
            {"upgrade_generic"},    --shop level 1
            {"upgrade_generic"},    --shop level 2
            {"upgrade_generic"},    --shop level 3
            {"upgrade_generic"},    --shop level 4
            {"upgrade_tutor_5"},    --shop level 5
            {"upgrade_generic"},    --shop level 6
            {"upgrade_tutor"},      --shop level 7
            {"upgrade_generic"},    --shop level 8
            {"upgrade_tutor"},      --shop level 9
            {"upgrade_generic"},    --shop level 10
        },
        Graphics = {
            {
                Base = "tutor_tier1",
                NPC_Loc = { X = 40, Y = 40 },
                Bounds = {
                    {
                        Name = "Left_Front",
                        X = 0, Y = 48, W = 24, H = 24
                    },
                    {
                        Name = "Left_Mid",
                        X = 8, Y = 16, W = 16, H = 32
                    },
                    {
                        Name = "Left_Back",
                        X = 24, Y = 16, W = 8, H = 24
                    },
                    {
                        Name = "Right_Front",
                        X = 72, Y = 48, W = 24, H = 24
                    },
                    {
                        Name = "Right_Mid",
                        X = 72, Y = 16, W = 16, H = 32
                    },
                    {
                        Name = "Right_Back",
                        X = 64, Y = 16, W = 8, H = 24
                    },
                    {
                        Name = "Back",
                        X = 32, Y = 8, W = 32, H = 24
                    }
                }
            },
            {},
            {},
            {}
        }
    },
    exporter = {
        Shopkeepers = {"dragonite", "flygon", "mudsdale", "dubwool"},
        Upgrades = {
            {"upgrade_generic"},    --shop level 1
            {"upgrade_generic"},    --shop level 2
            {"upgrade_generic"},    --shop level 3
            {"upgrade_generic"},    --shop level 4
            {"upgrade_generic"},    --shop level 5
            {"upgrade_generic"},    --shop level 6
            {"upgrade_generic"},    --shop level 7
            {"upgrade_generic"},    --shop level 8
            {"upgrade_generic"},    --shop level 9
            {"upgrade_generic"},    --shop level 10
        },
        Graphics = {
            {
                Base = "export_tier1",
                TopLayer = "export_tier1_top",
                NPC_Loc = { X = 40, Y = 56 },
                Bounds = {
                    {
                        Name = "Left_Front",
                        X = 24, Y = 64, W = 24, H = 24
                    },
                    {
                        Name = "Left_Mid",
                        X = 8, Y = 40, W = 40, H = 24
                    },
                    {
                        Name = "Right_Front",
                        X = 64, Y = 64, W = 24, H = 24
                    },
                    {
                        Name = "Right_Mid",
                        X = 72, Y = 32, W = 24, H = 32
                    },
                    {
                        Name = "Back_fw",
                        X = 24, Y = 24, W = 64, H = 8
                    }
                }
            },
            {},
            {},
            {}
        }
    },
    --TODO the next two
    trader = {
        Shopkeepers = {"sableye", "croagunk", "sigyliph"},
        Upgrades = {
            {"upgrade_generic"},    --shop level 1
            {"upgrade_generic"},    --shop level 2
            {"upgrade_generic"},    --shop level 3
            {"upgrade_generic"},    --shop level 4
            {"upgrade_generic"},    --shop level 5
            {"upgrade_generic"},    --shop level 6
            {"upgrade_generic"},    --shop level 7
            {"upgrade_generic"},    --shop level 8
            {"upgrade_generic"},    --shop level 9
            {"upgrade_generic"},    --shop level 10
        },
        Graphics = {
            {},
            {},
            {},
            {}
        }
    },
    appraisal = {
        Shopkeepers = {"voltorb", "xatu"},
        Upgrades = {
            {"upgrade_generic"},    --shop level 1
            {"upgrade_generic"},    --shop level 2
            {"upgrade_generic"},    --shop level 3
            {"upgrade_generic"},    --shop level 4
            {"upgrade_generic"},    --shop level 5
            {"upgrade_generic"},    --shop level 6
            {"upgrade_generic"},    --shop level 7
            {"upgrade_generic"},    --shop level 8
            {"upgrade_generic"},    --shop level 9
            {"upgrade_generic"},    --shop level 10
        },
        Graphics = {
            {},
            {},
            {},
            {}
        }
    }
}
