--[[
    Property & Apartment Sounds
    Build: Base Game (1604+)
    
    Property, apartment, and elevator sounds.
]]

return {
    category = "Properties",
    build = 1604,
    sounds = {
        -- MP_PROPERTIES_ELEVATOR_DOORS
        { sound = "OPENING", set = "MP_PROPERTIES_ELEVATOR_DOORS" },
        { sound = "OPENED", set = "MP_PROPERTIES_ELEVATOR_DOORS" },
        { sound = "CLOSING", set = "MP_PROPERTIES_ELEVATOR_DOORS" },
        { sound = "CLOSED", set = "MP_PROPERTIES_ELEVATOR_DOORS" },
        { sound = "BUTTON", set = "MP_PROPERTIES_ELEVATOR_DOORS" },
        { sound = "FAKE_ARRIVE", set = "MP_PROPERTIES_ELEVATOR_DOORS" },
        
        -- LIFT_NORMAL_SOUNDSET
        { sound = "Bell", set = "LIFT_NORMAL_SOUNDSET" },
        { sound = "Move", set = "LIFT_NORMAL_SOUNDSET" },
        
        -- LIFT_POSH_SOUNDSET
        { sound = "Tone", set = "LIFT_POSH_SOUNDSET" },
        
        -- MP_PLAYER_APARTMENT
        { sound = "DOOR_BUZZ", set = "MP_PLAYER_APARTMENT" },
        
        -- DLC_APT_Apartment_SoundSet
        { sound = "Apt_Style_Purchase", set = "DLC_APT_Apartment_SoundSet" },
        
        -- DLC_APT_YACHT_DOOR_SOUNDS
        { sound = "PUSH", set = "DLC_APT_YACHT_DOOR_SOUNDS" },
        { sound = "LIMIT", set = "DLC_APT_YACHT_DOOR_SOUNDS" },
        { sound = "Closed", set = "DLC_APT_YACHT_DOOR_SOUNDS" },
        { sound = "CLOSED", set = "DLC_APT_YACHT_DOOR_SOUNDS" },
        
        -- GTAO_APT_DOOR_DOWNSTAIRS_GLASS_SOUNDS
        { sound = "LIMIT", set = "GTAO_APT_DOOR_DOWNSTAIRS_GLASS_SOUNDS" },
        { sound = "PUSH", set = "GTAO_APT_DOOR_DOWNSTAIRS_GLASS_SOUNDS" },
        { sound = "SWING_SHUT", set = "GTAO_APT_DOOR_DOWNSTAIRS_GLASS_SOUNDS" },
        { sound = "DOOR_BUZZ_ONESHOT_MASTER", set = "GTAO_APT_DOOR_DOWNSTAIRS_GLASS_SOUNDS" },
        
        -- GTAO_APT_DOOR_DOWNSTAIRS_WOOD_SOUNDS
        { sound = "PUSH", set = "GTAO_APT_DOOR_DOWNSTAIRS_WOOD_SOUNDS" },
        { sound = "LIMIT", set = "GTAO_APT_DOOR_DOWNSTAIRS_WOOD_SOUNDS" },
        { sound = "SWING_SHUT", set = "GTAO_APT_DOOR_DOWNSTAIRS_WOOD_SOUNDS" },
        
        -- GTAO_APT_DOOR_DOWNSTAIRS_GENERIC_SOUNDS
        { sound = "PUSH", set = "GTAO_APT_DOOR_DOWNSTAIRS_GENERIC_SOUNDS" },
        { sound = "LIMIT", set = "GTAO_APT_DOOR_DOWNSTAIRS_GENERIC_SOUNDS" },
        { sound = "SWING_SHUT", set = "GTAO_APT_DOOR_DOWNSTAIRS_GENERIC_SOUNDS" },
        
        -- GTAO_APT_DOOR_ROOF_METAL_SOUNDS
        { sound = "PUSH", set = "GTAO_APT_DOOR_ROOF_METAL_SOUNDS" },
        { sound = "LIMIT", set = "GTAO_APT_DOOR_ROOF_METAL_SOUNDS" },
        { sound = "SWING_SHUT", set = "GTAO_APT_DOOR_ROOF_METAL_SOUNDS" },
        
        -- GTAO_Script_Doors_Sounds
        { sound = "Garage_Door_Open_Loop", set = "GTAO_Script_Doors_Sounds" },
        { sound = "Garage_Door_Close_Loop", set = "GTAO_Script_Doors_Sounds" },
        
        -- GTAO_Script_Doors_Faded_Screen_Sounds
        { sound = "Garage_Door_Open", set = "GTAO_Script_Doors_Faded_Screen_Sounds" },
        { sound = "Garage_Door_Close", set = "GTAO_Script_Doors_Faded_Screen_Sounds" },
    }
}
