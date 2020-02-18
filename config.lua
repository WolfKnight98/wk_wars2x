--[[------------------------------------------------------------------------

	Wraith ARS 2X
	Created by WolfKnight

------------------------------------------------------------------------]]--

-- Do not touch this
CONFIG = {}

-- Remote control key 
-- The default key to open the remote control is 166 (F5 - INPUT_SELECT_CHARACTER_MICHAEL)
CONFIG.remote_control_key = 166

-- Radar front antenna lock/unlock Key 
-- The default key to lock/unlock the front antenna is 111 (Numpad 8 - INPUT_VEH_FLY_PITCH_UP_ONLY)
CONFIG.front_lock_key = 111

-- Radar rear antenna lock/unlock Key 
-- The default key to lock/unlock the rear antenna is 112 (Numpad 5 - INPUT_VEH_FLY_PITCH_DOWN_ONLY)
CONFIG.rear_lock_key = 112

-- Radar key lock key 
-- The default key to enable/disable the radar key lock is 311 (K - INPUT_REPLAY_SHOWHOTKEY)
CONFIG.key_lock_key = 311 

-- Plate reader front lock/unlock Key 
-- The default key to lock/unlock the front plate reader is 118 (Numpad 9 - INPUT_VEH_FLY_SELECT_TARGET_RIGHT)
CONFIG.plate_front_lock_key = 118

-- Plate reader rear lock/unlock Key 
-- The default key to lock/unlock the rear plate reader is 109 (Numpad 6 - INPUT_VEH_FLY_ROLL_RIGHT_ONLY)
CONFIG.plate_rear_lock_key = 109

-- Radar fast limit locking
-- When enabled, the player will be able to define a fast limit within the radar's menu, when a vehicle 
-- exceeds the fast limit, it will be locked into the fast box. Default setting is disabled to maintain realism
CONFIG.allow_fast_limit = true 