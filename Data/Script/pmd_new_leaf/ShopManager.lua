_HUB.UpgradeTable = {
    market_unlock = {
        -- used as string reference when displaying
        string = "UPGRADE_MARKET_UNLOCK",
        -- list of prices required to pick this upgrade for every level.
        -- if the entry for a level exists, it will be used. otherwise the highest below the level is used,
        -- and the difference +1 will act as a multiplier
        -- if sub-choices are used, this process is applied to them as well, and only at the end the prices
        -- are added together.
        price = {
            { item = "loot_building_tools", amount = 2 }
        },
        -- all of these upgrades are required for this option to appear. Subchoice reference is {0} if per_sub_choice is true
        -- start with a ! for negation, end with : and a number to require a specific level or above
        requirements = {},
        -- description displayed when the choice is hovered
        description = "UPGRADE_MARKET_UNLOCK_DESCR", --TODO
        -- when this option is chosen, show a submenu with these choices
        -- the final reference id for a specific sub_choice is choiceId_subchoiceId
        -- sub_choices data should be defined somewhere else in this table
        sub_choices = {
            "sub_survival", "sub_recruitment", "sub_utilities", "sub_ammo", "sub_wands", "sub_orbs", "sub_tm"
        },
        -- maximum copies of this upgrade allowed on a single shop
        max = 1,
        -- if true, the "max" and "requirements" parameters will refer to the sub_choices instead
        -- has no meaning if sub_choices is nil
        per_sub_choice = true
    },
    market_expand = {
        string = "UPGRADE_MARKET_EXPAND",
        requirements = { "market_unlock_{0}" },
        description = "UPGRADE_MARKET_EXPAND_DESCR", --TODO
        sub_choices = {
            "sub_survival", "sub_recruitment", "sub_utilities", "sub_ammo", "sub_wands", "sub_orbs", "sub_tm"
        },
        per_sub_choice = true
    },
    market_tier = {
        string = "UPGRADE_MARKET_TIER",
        requirements = { "market_unlock_{0}" },
        description = "UPGRADE_MARKET_TIER_DESCR", --TODO
        sub_choices = {
            "sub_survival", "sub_recruitment", "sub_utilities", "sub_ammo", "sub_wands", "sub_orbs", "sub_tm"
        },
        max = 2,
        per_sub_choice = true
    },
    market_specialize = {
        string = "UPGRADE_MARKET_SPECIALIZE",
        requirements = { "market_unlock_{0}" },
        description = "UPGRADE_MARKET_SPECIALIZE_DESCR", --TODO
        sub_choices = {
            "sub_survival", "sub_recruitment", "sub_utilities", "sub_ammo", "sub_wands", "sub_orbs", "sub_tm"
        },
        max = 1,
        per_sub_choice = true
    },
    sub_survival = {
        -- sub-choices can contain just a string and description parameter if they're never used as main choices
        string = "MARKET_POOL_SURVIVAL",
        description = "MARKET_POOL_SURVIVAL_DESCR" --TODO
    },
    sub_recruitment = {
        string = "MARKET_POOL_RECRUITMENT",
        description = "MARKET_POOL_RECRUITMENT_DESCR" --TODO
    },
    sub_utilities = {
        string = "MARKET_POOL_UTILITIES",
        description = "MARKET_POOL_UTILITIES_DESCR" --TODO
    },
    sub_ammo = {
        string = "MARKET_POOL_AMMO",
        description = "MARKET_POOL_AMMO_DESCR" --TODO
    },
    sub_wands = {
        string = "MARKET_POOL_WANDS",
        description = "MARKET_POOL_WANDS_DESCR" --TODO
    },
    sub_orbs = {
        string = "MARKET_POOL_ORBS",
        description = "MARKET_POOL_ORBS_DESCR" --TODO
    },
    sub_tm = {
        string = "MARKET_POOL_TM",
        description = "MARKET_POOL_TM_DESCR" --TODO
    },
    upgrade_tutor_base = {
        string = "UPGRADE_GENERIC",
        requirements = {},
        max = 10
    },
    upgrade_tutor_tutor = {
        string = "TUTOR_POOL_TUTOR",
        description = "TUTOR_POOL_TUTOR_DESCR", --TODO
        requirements = {},
        max = 1
    },
    upgrade_tutor_egg = {
        string = "TUTOR_POOL_EGG",
        description = "TUTOR_POOL_EGG_DESCR", --TODO
        requirements = {},
        max = 1
    },
    upgrade_tutor_count = {
        string = "UPGRADE_TUTOR_COUNT",
        description = "UPGRADE_TUTOR_COUNT_DESCR", --TODO
        requirements = {},
        max = 2
    },
    upgrade_tutor_frequency = {
        string = "UPGRADE_TUTOR_FREQUENCY",
        description = "UPGRADE_TUTOR_FREQUENCY_DESCR", --TODO
        requirements = {},
        max = 2
    },
    upgrade_exporter_base = {
        string = "UPGRADE_GENERIC",
        requirements = {},
        max = 10
    },
    upgrade_trader_base = {
        string = "UPGRADE_GENERIC",
        requirements = {},
        max = 10
    }
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
                        X=46, Y=73, W=28, H=9
                    },
                    {
                        Name = "Storage",
                        Trigger = RogueEssence.Ground.GroundEntity.EEntityTriggerTypes.Action,
                        X=5,  Y=72, W=22, H=24
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
                        X=22, Y=73, W=28, H=9
                    },
                    {
                        Name = "Assembly",
                        Trigger = RogueEssence.Ground.GroundEntity.EEntityTriggerTypes.Action,
                        X=57, Y=64, W=30, H=32,
                        Display = {
                            Sprite = "Assembly",
                            FrameLength = 15,
                            End = 0
                        }
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
        Shopkeepers = {{species = "porygon"}, {species = "quagsire"}, {species = "kecleon"}, {species = "bibarel"}, {species = "audino"}, {species = "espurr"}, {species = "ribombee"}, {species = "greedent"}, {species = "maushold"}},
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
                        X = 16, Y = 56, W = 23, H = 24
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
                        X = 57, Y = 56, W = 23, H = 24
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
    tutor = {
        Shopkeepers = {{species = "marowak"}, {species = "ledian"}, {species = "blaziken"}, {species = "electivire"}, {species = "mienshao"}, {species = "pangoro"}, {species = "kommo_o"}, {species = "falinks"}, {species = "ceruledge"}},
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
        Shopkeepers = {{species = "dragonite"}, {species = "delibird"}, {species = "flygon"}, {species = "drifblim"}, {species = "scolipede"}, {species = "gogoat"}, {species = "mudsdale"}, {species = "corviknight"}, {species = "bombirdier"}},
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
                        X = 16, Y = 56, W = 23, H = 24
                    },
                    {
                        Name = "Left_Mid",
                        X = 0, Y = 32, W = 40, H = 24
                    },
                    {
                        Name = "Right_Front",
                        X = 57, Y = 56, W = 23, H = 24
                    },
                    {
                        Name = "Right_Mid",
                        X = 64, Y = 24, W = 24, H = 32
                    },
                    {
                        Name = "Back_fw",
                        X = 8, Y = 24, W = 56, H = 16
                    },
                    {
                        Name = "Back_bk",
                        X = 16, Y = 16, W = 64, H = 8
                    }
                }
            },
            {},
            {},
            {}
        }
    },
    --TODO the next three
    trader = {
        Shopkeepers = {{species = "gengar"}, {species = "murkrow"}, {species = "sableye"}, {species = "croagunk"}, {species = "zoroark"}, {species = "trevenant"}, {species = "mimikyu"}, {species = "thievul"}, {species = "meowscarada"}},
        Upgrades = { --TODO
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
        Graphics = { --TODO
            {},
            {},
            {},
            {}
        }
    },
    appraisal = {
        Shopkeepers = {{species = "voltorb"}, {species = "xatu"}, {species = "metang"}, {species = "bronzong"}, {species = "reuniclus"}, {species = "klefki"}, {species = "deciueye"}, {species = "runerigus"}, {species = "farigiraf"}},
        Upgrades = { --TODO
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
        Graphics = { --TODO
            {},
            {},
            {},
            {}
        }
    },
    cafe = {
        Shopkeepers = {{species = "kangaskhan"}, {species = "shuckle"}, {species = "spinda"}, {species = "mismagius"}, {species = "lilligant"}, {species = "gourgeist"}, {species = "oricorio", form = 0}, {species = "appletun"}, {species = "sinistcha"}},
        Upgrades = { --TODO
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
        Graphics = { --TODO
            {},
            {},
            {},
            {}
        }
    }
}

-- these look exactly like shops graphics data, but never contain NPC_Pos or Marker_Pos
_HUB.NotUnlockedVisuals = {
    -- these also never contain solid Bounds
    NonBlocking = {
        {
            Base = "free_empty_1"
        },
        {
            Base = "free_empty_2"
        },
        {
            Base = "free_empty_3",
            Decorations = {
                {
                    X=56, Y=64,
                    Display = {
                        Sprite = "Flowers_Town_3",
                        FrameLength = 30
                    }
                },
                {
                    X=16, Y=32,
                    Display = {
                        Sprite = "Flowers_Town_5",
                        FrameLength = 30
                    }
                }
            }
        },
        {
            Base = "free_empty_4",
            Decorations = {
                {
                    X=16, Y=24,
                    Display = {
                        Sprite = "Flowers_Town_4",
                        FrameLength = 30
                    }
                },
                {
                    X=72, Y=56,
                    Display = {
                        Sprite = "Flowers_Town_5",
                        FrameLength = 30
                    }
                },
                {
                    X=8, Y=72,
                    Display = {
                        Sprite = "Flowers_Town_5",
                        FrameLength = 30
                    }
                }
            }
        }
    },
    -- these do contain Bounds
    Blocking = {
        {
            Base = "empty_5",
            TopLayer = "empty_5_top",
            Bounds = {
                {
                    Name = "Tree",
                    X = 40, Y = 48, W = 16, H = 16
                }
            }
        },
        {
            Base = "empty_6",
            Bounds = {
                {
                    Name = "Bush",
                    X = 8, Y = 16, W = 24, H = 24
                },
                {
                    Name = "Rock",
                    X = 64, Y = 40, W = 16, H = 16
                }
            }
        },
        {
            Base = "empty_7",
            TopLayer = "empty_7_top",
            Bounds = {
                {
                    Name = "Tree_covered",
                    X = 48, Y = 32, W = 16, H = 16
                },
                {
                    Name = "Tree",
                    X = 32, Y = 72, W = 16, H = 16
                }
            }
        },
        {
            Base = "empty_8",
            Bounds = {
                {
                    Name = "Bush_left",
                    X = 16, Y = 24, W = 24, H = 24
                },
                {
                    Name = "Bush_right",
                    X = 64, Y = 40, W = 24, H = 24
                }
            },
            Decorations = {
                {
                    X=64, Y=16,
                    Display = {
                        Sprite = "Flowers_Town_4",
                        FrameLength = 30
                    }
                }
            }
        },
        {
            Base = "empty_9",
            Bounds = {
                {
                    Name = "Rock_left",
                    X = 8, Y = 16, W = 16, H = 16
                },
                {
                    Name = "Rock_right",
                    X = 72, Y = 48, W = 16, H = 16
                },
                {
                    Name = "Bush",
                    X = 24, Y = 64, W = 24, H = 24
                }
            },
            Decorations = {
                {
                    X=48, Y=8,
                    Display = {
                        Sprite = "Flowers_Town_3",
                        FrameLength = 30
                    }
                }
            }
        },
        {
            Base = "empty_10",
            Bounds = {
                {
                    Name = "Bush_left",
                    X = 8, Y = 32, W = 24, H = 24
                },
                {
                    Name = "Bush_right",
                    X = 56, Y = 48, W = 24, H = 24
                },
                {
                    Name = "Rock",
                    X = 48, Y = 8, W = 16, H = 16
                }
            }
        }
    }
}