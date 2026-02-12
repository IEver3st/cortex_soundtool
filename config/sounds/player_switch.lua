--[[
    Player Switch & Special Ability Sounds
    Build: Base Game (1604+)
    
    Character switching and special ability sounds.
]]

return {
    category = "Player Switch",
    build = 1604,
    sounds = {
        -- PLAYER_SWITCH_CUSTOM_SOUNDSET
        { sound = "1st_Person_Transition", set = "PLAYER_SWITCH_CUSTOM_SOUNDSET" },
        { sound = "Hit_out", set = "PLAYER_SWITCH_CUSTOM_SOUNDSET" },
        { sound = "Hit_In", set = "PLAYER_SWITCH_CUSTOM_SOUNDSET" },
        { sound = "Hit_Out", set = "PLAYER_SWITCH_CUSTOM_SOUNDSET" },
        { sound = "Short_Transition_In", set = "PLAYER_SWITCH_CUSTOM_SOUNDSET" },
        { sound = "Camera_Move_Loop", set = "PLAYER_SWITCH_CUSTOM_SOUNDSET" },
        
        -- SHORT_PLAYER_SWITCH_SOUND_SET
        { sound = "slow", set = "SHORT_PLAYER_SWITCH_SOUND_SET" },
        
        -- LONG_PLAYER_SWITCH_SOUNDS
        { sound = "Hit_1", set = "LONG_PLAYER_SWITCH_SOUNDS" },
        
        -- SPECIAL_ABILITY_SOUNDSET
        { sound = "SwitchRedWarning", set = "SPECIAL_ABILITY_SOUNDSET" },
        { sound = "SwitchWhiteWarning", set = "SPECIAL_ABILITY_SOUNDSET" },
    }
}
