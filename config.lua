--[[------------------------------------------------------------------------

    Wraith ARS 2X - v1.0.0
    Created by WolfKnight

------------------------------------------------------------------------]]--

-- Do not touch this
RADAR = {}
RADAR.config = {}

-- Radar Control Panel key 
-- The default key to open the radar control panel is 166 (F5 - INPUT_SELECT_CHARACTER_MICHAEL)
RADAR.config.control_panel_key = 166

-- Radar Unlock/Reset Key 
-- The default key to unlock/reset the radar is 244 (M - INPUT_INTERACTION_MENU)
RADAR.config.reset_key = 244

-- Fast Lock Blip
-- true = vehicles that go over the fast limit will have a blip added to the minimap for a short period of time
-- false = no blips
RADAR.config.fast_lock_blips = true

-- Debug mode
RADAR.config.debug_mode = true 