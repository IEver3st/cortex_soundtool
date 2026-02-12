--[[
    es_soundtester Configuration
    Customize keybinds, volume, and playback behavior
]]

Config = {}

--------------------------------------------------------------------------------
-- KEYBINDS
--------------------------------------------------------------------------------
-- Key to open/close the sound tester UI
-- See: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
Config.OpenKey = "F9"

-- Key to replay the last selected sound without opening the menu
Config.ReplayKey = "F10"

--------------------------------------------------------------------------------
-- SOUND PLAYBACK
--------------------------------------------------------------------------------
-- Default volume for sound preview (0.0 to 1.0)
-- Note: GTA V frontend sounds don't support volume control, this is for future use
Config.DefaultVolume = 1.0

-- Play sounds at player position (true) or at a fixed world position (false)
Config.PlayAtPlayerPosition = true

-- Fixed world position for sound playback (used when PlayAtPlayerPosition is false)
Config.FixedPosition = vector3(0.0, 0.0, 0.0)

--------------------------------------------------------------------------------
-- UI SETTINGS
--------------------------------------------------------------------------------
-- Number of sounds to display per page in the list
Config.SoundsPerPage = 50

-- Enable debug logging to console
Config.Debug = false

--------------------------------------------------------------------------------
-- VEHICLE AUDIO PREVIEW
--------------------------------------------------------------------------------
-- Duration for vehicle audio preview before it stops automatically (milliseconds)
Config.VehiclePreviewDuration = 4000

-- Damage multiplier for vehicles while using the sound tester (0.0 to 1.0)
-- 0.1 means vehicles take only 10% of normal damage
Config.VehicleDamageMultiplier = 0.1

--------------------------------------------------------------------------------
-- NOTIFICATIONS
--------------------------------------------------------------------------------
-- Duration for notification display (milliseconds)
Config.NotificationDuration = 3000
