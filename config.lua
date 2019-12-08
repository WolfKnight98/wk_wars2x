--[[------------------------------------------------------------------------

	Wraith ARS 2X
	Created by WolfKnight

------------------------------------------------------------------------]]--

-- Do not touch this
RADAR = {}
RADAR.config = {}

-- Radar Control Panel key 
-- The default key to open the radar control panel is 166 (F5 - INPUT_SELECT_CHARACTER_MICHAEL)
RADAR.config.remote_control_key = 166

-- Radar front antenna lock/unlock Key 
-- The default key to lock/unlock the front antenna is 111 (Numpad 8 - INPUT_VEH_FLY_PITCH_UP_ONLY)
RADAR.config.front_lock_key = 111

-- Radar rear antenna lock/unlock Key 
-- The default key to lock/unlock the rear antenna is 112 (Numpad 5 - INPUT_VEH_FLY_PITCH_DOWN_ONLY)
RADAR.config.rear_lock_key = 112

-- Fast Lock Blip
-- true = vehicles that go over the fast limit will have a blip added to the minimap for a short period of time
-- false = no blips
-- RADAR.config.fast_lock_blips = true

-- Debug mode
RADAR.config.debug_mode = false 