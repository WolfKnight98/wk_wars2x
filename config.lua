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

-- Radar fast limit locking
-- When enabled, the player will be able to define a fast limit within the radar's menu, when a vehicle 
-- exceeds the fast limit, it will be locked into the fast box. Default setting is disabled to maintain realism
RADAR.config.allow_fast_limit = true 

-- Debug mode
RADAR.config.debug_mode = false 