-- Configuration file for M4 Bus Job

-- Use a global table so other scripts in this resource can access it
Config = {}

-- Job allowed to use the bus job system
Config.AllowedJob = "busdriver"

-- Bus spawn location
Config.BusSpawnLocation = vector3(452.31, -583.75, 28.5) -- Bus Depot

-- Bus model
Config.BusModel = 'bus'

-- Passenger settings
Config.MaxPassengers = 15
Config.PassengerReward = 15 -- Amount of money earned per passenger
Config.RouteCompletionBonus = 500 -- Bonus for completing the route

-- Discord Webhook Settings
Config.Webhook = "" -- Paste your Discord Webhook URL here

-- Passenger Chatter
Config.Chatter = {
    Enter = {
        "Good morning, driver!",
        "Finally, the bus is here.",
        "To the city center, please.",
        "Nice bus!",
        "Am I late?",
        "Can I pay with card?",
        "Is this the right bus?",
        "Hello!",
    },
    Exit = {
        "Thank you!",
        "Have a nice day!",
        "See you later.",
        "This is my stop.",
        "Thanks for the ride.",
        "Bye bye!",
        "Keep the change.",
        "Safe driving!",
    }
}

-- Target settings
Config.UseTarget = true

-- Damage settings
Config.DamagePenalty = 50 -- Amount to deduct if bus is damaged below 900 engine health

-- Uniform settings
Config.ClothingNPC = {
    model = 's_m_y_garbage',
    coords = vector4(463.52, -574.41, 27.5, 134.29)
}

Config.Uniforms = {
    male = {
        outfitData = {
            ['t-shirt'] = {item = 59, texture = 0},
            ['torso2'] = {item = 31, texture = 0},
            ['decals'] = {item = 0, texture = 0},
            ['arms'] = {item = 4, texture = 0},
            ['pants'] = {item = 36, texture = 0},
            ['shoes'] = {item = 10, texture = 0},
            ['hat'] = {item = -1, texture = 0},
            ['accessory'] = {item = -1, texture = 0},
            ['ear'] = {item = -1, texture = 0},
            ['mask'] = {item = 0, texture = 0},
        }
    },
    female = {
        outfitData = {
            ['t-shirt'] = {item = 36, texture = 0},
            ['torso2'] = {item = 58, texture = 0},
            ['decals'] = {item = 0, texture = 0},
            ['arms'] = {item = 4, texture = 0},
            ['pants'] = {item = 35, texture = 0},
            ['shoes'] = {item = 6, texture = 0},
            ['hat'] = {item = -1, texture = 0},
            ['accessory'] = {item = -1, texture = 0},
            ['ear'] = {item = -1, texture = 0},
            ['mask'] = {item = 0, texture = 0},
        }
    }
}

-- Passenger models
Config.PassengerModels = {
    'a_f_m_beach_01', 'a_f_m_bevhills_01', 'a_f_m_bevhills_02', 'a_f_m_bodybuild_01', 'a_f_m_business_02', 'a_f_m_downtown_01', 'a_f_m_eastsa_01', 'a_f_m_eastsa_02', 'a_f_m_fatbla_01', 'a_f_m_fatwhite_01', 'a_f_m_ktown_01', 'a_f_m_ktown_02', 'a_f_m_prolhost_01', 'a_f_m_salton_01'
}

-- Passenger seats
Config.PassengerSeats = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}

-- Bus lines
Config.BusLines = {
    {
        name = 'South Loop', number = 1, color = {r = 255, g = 0, b = 0}, 
        stations = {
            vector3(465.98, -632.11, 28.5), -- Bus Depot
            vector3(309.64, -765.13, 29.31), -- Station 1
            vector3(269.74, -1220.24, 29.51), -- Station 2
            vector3(-106.16, -1689.55, 29.32), -- Station 3
            vector3(-142.1, -1975.86, 22.82), -- Station 4
            vector3(200.29, -1972.3, 19.33), -- Station 5
            vector3(442.45, -1683.33, 28.75), -- Station 6
            vector3(468.06, -1413.67, 28.74),   -- Station 7
            vector3(269.72, -1220.39, 29.0),    -- Station 8
            vector3(358.17, -1061.67, 28.82),    -- Station 9
            vector3(471.82, -826.59, 25.81) -- Station 10
        }
    },    
    {
        name = 'Vespucci Line', number = 2, color = {r = 0, g = 0, b = 255},
        stations = {
            vector3(465.98, -632.11, 28.5), -- Bus Depot
            vector3(309.64, -765.13, 29.31), -- Station 1
            vector3(114.78, -787.79, 31.42), -- Station 2
            vector3(-170.96, -820.02, 30.7), -- Station 3
            vector3(-273.25, -823.37, 31.37), -- Station 4
            vector3(-598.03, -649.42, 31.5), -- Station 5
            vector3(-933.62, -461.04, 36.73), -- Station 6
            vector3(-1158.26, -401.45, 35.37), -- Station 7
            vector3(-1408.38, -571.79, 29.91), -- Station 8
            vector3(-1210.48, -1218.54, 7.23), -- Station 9
            vector3(-1167.78, -1468.44, 3.92), -- Station 10
            vector3(-1143.69, -1367.62, 4.63), -- Station 11
            vector3(-1255.36, -1030.5, 8.4), -- Station 12
            vector3(-1477.36, -629.93, 30.19), -- Station 13
            vector3(-1046.96, -387.6, 37.16), -- Station 14
            vector3(-692.09, -666.17, 30.45), -- Station 15
            vector3(-506.18, -665.73, 32.66), -- Station 16
            vector3(-241.58, -716.72, 33.03), -- Station 17
            vector3(-248.92, -880.45, 30.23), -- Station 18
            vector3(214.55, -847.17, 29.86), -- Station 19
            vector3(309.64, -765.13, 29.31),  -- Station 20
            vector3(471.82, -826.59, 25.81) -- Station 21
        }
    },
    {
        name = 'University Route', number = 3, color = {r = 0, g = 255, b = 0},
        stations = {
            vector3(1843.2, 3682.3, 34.3), -- Bus Depot
            vector3(1461.7, 3570.6, 34.4), -- Station 1
            vector3(989.2, 1567.3, 34.8), -- Station 2
            vector3(462.3, 1315.6, 30.9), -- Station 3
            vector3(260.1, 1193.3, 224.2), -- Station 4
            vector3(-161.6, 937.5, 234.0) -- Station 5
        }
    },
    {
        name = 'Industrial Circle', number = 4, color = {r = 255, g = 255, b = 0},
        stations = {
            vector3(1122.1, -3197.1, -40.4), -- Bus Depot
            vector3(880.2, -2351.9, 29.3), -- Station 1
            vector3(814.7, -1237.3, 26.0), -- Station 2
            vector3(763.2, -885.2, 25.1), -- Station 3
            vector3(960.3, -539.6, 58.9), -- Station 4
            vector3(2744.6, 1501.8, 24.5) -- Station 5
        }
    },
    {
        name = 'Rural Shuttle', number = 5, color = {r = 128, g = 0, b = 128},
        stations = {
            vector3(1702.4, 4916.5, 42.1), -- Bus Depot
            vector3(1965.6, 5184.3, 47.9), -- Station 1
            vector3(1842.3, 3655.5, 34.2), -- Station 2
            vector3(1152.4, 2653.9, 37.7), -- Station 3
            vector3(-180.2, 6271.4, 31.5), -- Station 4
            vector3(-2122.4, 3245.2, 32.8) -- Station 5
        }
    },
    {
        name = 'Tourist Loop', number = 6, color = {r = 255, g = 165, b = 0},
        stations = {
            vector3(-1612.9, -1024.5, 13.0), -- Bus Depot
            vector3(-1305.5, 252.3, 62.1), -- Station 1
            vector3(711.1, 1197.6, 325.4), -- Station 2
            vector3(364.9, 282.5, 103.6), -- Station 3
            vector3(1069.4, -686.6, 58.3), -- Station 4
            vector3(-1028.3, -1003.8, 1.0) -- Station 5
        }
    }
}

 -- No return; Config is global for this resource