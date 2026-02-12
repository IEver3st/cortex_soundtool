--[[
    Doomsday Heist DLC Sounds
    Build: 1604+ (The Doomsday Heist - December 2017)
    
    Facility, Avenger, and orbital cannon sounds.
]]

return {
    category = "Doomsday Heist DLC",
    build = 1604,
    sounds = {
        -- dlc_xm_facility_entry_exit_sounds
        { sound = "elevator_ascend_loop", set = "dlc_xm_facility_entry_exit_sounds" },
        { sound = "elevator_descend_loop", set = "dlc_xm_facility_entry_exit_sounds" },
        { sound = "hangar_doors_loop", set = "dlc_xm_facility_entry_exit_sounds" },
        { sound = "hangar_doors_open", set = "dlc_xm_facility_entry_exit_sounds" },
        { sound = "hangar_doors_close", set = "dlc_xm_facility_entry_exit_sounds" },
        { sound = "hangar_doors_limit", set = "dlc_xm_facility_entry_exit_sounds" },
        
        -- dlc_xm_facility_ambient_sounds
        { sound = "Activate_Privacy_Glass", set = "dlc_xm_facility_ambient_sounds" },
        { sound = "Deactivate_Privacy_Glass", set = "dlc_xm_facility_ambient_sounds" },
        
        -- dlc_xm_iaa_player_facility_sounds
        { sound = "scanner_alarm_os", set = "dlc_xm_iaa_player_facility_sounds" },
        
        -- dlc_xm_orbital_cannon_sounds
        { sound = "cannon_active", set = "dlc_xm_orbital_cannon_sounds" },
        { sound = "inactive_fire_fail", set = "dlc_xm_orbital_cannon_sounds" },
        { sound = "menu_select", set = "dlc_xm_orbital_cannon_sounds" },
        { sound = "menu_back", set = "dlc_xm_orbital_cannon_sounds" },
        { sound = "menu_reset", set = "dlc_xm_orbital_cannon_sounds" },
        { sound = "menu_up_down", set = "dlc_xm_orbital_cannon_sounds" },
        { sound = "zoom_out_loop", set = "dlc_xm_orbital_cannon_sounds" },
        { sound = "cannon_charge_fire_loop", set = "dlc_xm_orbital_cannon_sounds" },
        { sound = "pan_loop", set = "dlc_xm_orbital_cannon_sounds" },
        { sound = "background_loop", set = "dlc_xm_orbital_cannon_sounds" },
        { sound = "cannon_activating_loop", set = "dlc_xm_orbital_cannon_sounds" },
        
        -- dlc_xm_orbital_cannon_remote_sounds
        { sound = "cannon_active_loop", set = "dlc_xm_orbital_cannon_remote_sounds" },
        { sound = "3_2_1_fire", set = "dlc_xm_orbital_cannon_remote_sounds" },
        { sound = "cannon_charge_fire_loop", set = "dlc_xm_orbital_cannon_remote_sounds" },
        
        -- dlc_xm_avngr_sounds
        { sound = "Fly_Loop", set = "dlc_xm_avngr_sounds" },
        
        -- DLC_XM17_Facility_Strike_PC_Sounds
        { sound = "Background", set = "DLC_XM17_Facility_Strike_PC_Sounds" },
        
        -- DLC_XM_Vehicle_Interior_Security_Camera_Sounds
        { sound = "Background_Hum", set = "DLC_XM_Vehicle_Interior_Security_Camera_Sounds" },
    }
}
