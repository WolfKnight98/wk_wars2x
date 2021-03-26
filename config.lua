--[[---------------------------------------------------------------------------------------

	Wraith ARS 2X
	Created by WolfKnight

	For discussions, information on future updates, and more, join
	my Discord: https://discord.gg/fD4e6WD

	MIT License

	Copyright (c) 2020-2021 WolfKnight

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

---------------------------------------------------------------------------------------]]--

-- Do not touch this
CONFIG = {}

-- Radar fast limit locking
-- When enabled, the player will be able to define a fast limit within the radar's menu, when a vehicle
-- exceeds the fast limit, it will be locked into the fast box. Default setting is disabled to maintain realism
CONFIG.allow_fast_limit = true

-- Radar fast limit menu order
-- When enabled, the fast limit options menu will be displayed first followed by fast lock toggle, then all default menu options. 
CONFIG.fast_limit_first_in_menu = false

-- Radar only lock players with auto fast locking
-- When enabled, the radar will only automatically lock a speed if the caught vehicle has a real player in it.
CONFIG.only_lock_players = false

-- In-game first time quick start video
-- When enabled, the player will be asked if they'd like to view the quick start video the first time they
-- open the remote.
CONFIG.allow_quick_start_video = true

-- Allow passenger view
-- When enabled, the front seat passenger will be able to view the radar and plate reader from their end.
CONFIG.allow_passenger_view = false

-- Allow passenger control
-- Dependent on CONFIG.allow_passenger_view. When enabled, the front seat passenger will be able to open the
-- radar remote and control the radar and plate reader for themself and the driver.
CONFIG.allow_passenger_control = false

-- Set this to true if you use Sonoran CAD with the WraithV2 plugin
CONFIG.use_sonorancad = false

-- Sets the defaults of all keybinds
-- These keybinds can be changed by each person in their GTA Settings->Keybinds->FiveM
CONFIG.keyDefaults =
{
	-- Remote control key
	remote_control = "f5",

	-- Radar key lock key
	key_lock = "l",

	-- Radar front antenna lock/unlock Key
	front_lock = "numpad8",

	-- Radar rear antenna lock/unlock Key
	rear_lock = "numpad5",

	-- Plate reader front lock/unlock Key
	plate_front_lock = "numpad9",

	-- Plate reader rear lock/unlock Key
	plate_rear_lock = "numpad6"
}

-- Here you can change the default values for the operator menu, do note, if any of these values are not
-- one of the options listed, the script will not work.
CONFIG.menuDefaults =
{
	-- Should the system calculate and display faster targets
	-- Options: true or false
	["fastDisplay"] = true,

	-- Sensitivity for each radar mode, this changes how far the antennas will detect vehicles
	-- Options: 0.2, 0.4, 0.6, 0.8, 1.0
	["same"] = 0.6,
	["opp"] = 0.6,

	-- The volume of the audible beep
	-- Options: 0.0, 0.2, 0.4, 0.6, 0.8, 1.0
	["beep"] = 0.6,

	-- The volume of the verbal lock confirmation
	-- Options: 0.0, 0.2, 0.4, 0.6, 0.8, 1.0
	["voice"] = 0.6,

	-- The volume of the plate reader audio
	-- Options: 0.0, 0.2, 0.4, 0.6, 0.8, 1.0
	["plateAudio"] = 0.6,

	-- The speed unit used in conversions
	-- Options: mph or kmh
	["speedType"] = "mph",

	-- The state for automatic speed locking. This requires CONFIG.allow_fast_limit to be true.
	-- Options: true or false
	["fastLock"] = false,

	-- The speed limit required for automatic speed locking. This requires CONFIG.allow_fast_limit to be true.
	-- Options: 0 to 200
	["fastLimit"] = 60
}

-- Here you can change the default scale of the UI elements, as well as the safezone size
CONFIG.uiDefaults =
{
	-- The default scale of the UI elements.
	-- Options: 0.25 - 2.5
	scale =
	{
		radar = 0.75,
		remote = 0.75,
		plateReader = 0.75
	},

	-- The safezone size, must be a multiple of 5.
	-- Options: 0 - 100
	safezone = 20
}