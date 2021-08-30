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

-- Cache some of the main Lua functions and libraries
local next = next
local dot = dot
local table = table
local type = type
local tostring = tostring
local math = math
local pairs = pairs


--[[----------------------------------------------------------------------------------
	UI loading and key binds registering
----------------------------------------------------------------------------------]]--
local function RegisterKeyBinds()
	if ( UTIL:IsResourceNameValid() ) then
		UTIL:Log( "Registering radar commands and key binds." )

		-- Opens the remote control
		RegisterCommand( "radar_remote", function()
			if ( not RADAR:GetKeyLockState() ) then
				RADAR:OpenRemote()
			end
		end )
		RegisterKeyMapping( "radar_remote", "Open Remote Control", "keyboard", CONFIG.keyDefaults.remote_control )

		-- Locks speed from front antenna
		RegisterCommand( "radar_fr_ant", function()
			if ( not RADAR:GetKeyLockState() and PLY:CanControlRadar() ) then
				RADAR:LockAntennaSpeed( "front", nil )

				SYNC:LockAntennaSpeed( "front", RADAR:GetAntennaDataPacket( "front" ) )
			end
		end )
		RegisterKeyMapping( "radar_fr_ant", "Front Antenna Lock/Unlock", "keyboard", CONFIG.keyDefaults.front_lock )

		-- Locks speed from rear antenna
		RegisterCommand( "radar_bk_ant", function()
			if ( not RADAR:GetKeyLockState() and PLY:CanControlRadar() ) then
				RADAR:LockAntennaSpeed( "rear", nil )

				SYNC:LockAntennaSpeed( "rear", RADAR:GetAntennaDataPacket( "rear" ) )
			end
		end )
		RegisterKeyMapping( "radar_bk_ant", "Rear Antenna Lock/Unlock", "keyboard", CONFIG.keyDefaults.rear_lock )

		-- Locks front plate reader
		RegisterCommand( "radar_fr_cam", function()
			if ( not RADAR:GetKeyLockState() and PLY:CanControlRadar() ) then
				READER:LockCam( "front", true, false )

				SYNC:LockReaderCam( "front", READER:GetCameraDataPacket( "front" ) )
			end
		end )
		RegisterKeyMapping( "radar_fr_cam", "Front Plate Reader Lock/Unlock", "keyboard", CONFIG.keyDefaults.plate_front_lock )

		-- Locks rear plate reader
		RegisterCommand( "radar_bk_cam", function()
			if ( not RADAR:GetKeyLockState() and PLY:CanControlRadar() ) then
				READER:LockCam( "rear", true, false )

				SYNC:LockReaderCam( "rear", READER:GetCameraDataPacket( "rear" ) )
			end
		end )
		RegisterKeyMapping( "radar_bk_cam", "Rear Plate Reader Lock/Unlock", "keyboard", CONFIG.keyDefaults.plate_rear_lock )

		-- Toggles the key lock state
		RegisterCommand( "radar_key_lock", function()
			RADAR:ToggleKeyLock()
		end )
		RegisterKeyMapping( "radar_key_lock", "Toggle Keybind Lock", "keyboard", CONFIG.keyDefaults.key_lock )

		-- Deletes all of the KVPs
		RegisterCommand( "reset_radar_data", function()
			DeleteResourceKvp( "wk_wars2x_ui_data" )
			DeleteResourceKvp( "wk_wars2x_om_data" )
			DeleteResourceKvp( "wk_wars2x_new_user" )

			UTIL:Notify( "Radar data deleted, please immediately restart your game without opening the radar's remote." )
		end, false )
		TriggerEvent( "chat:addSuggestion", "/reset_radar_data", "Resets the KVP data stored for the wk_wars2x resource." )
	else
		UTIL:Log( "ERROR: Resource name is not wk_wars2x. Key binds will not be registered for compatibility reasons. Contact the server owner and ask them to change the resource name back to wk_wars2x" )
	end
end

local function LoadUISettings()
	UTIL:Log( "Attempting to load saved UI settings data." )

	-- Try and get the saved UI data
	local uiData = GetResourceKvpString( "wk_wars2x_ui_data" )

	-- If the data exists, then we send it off!
	if ( uiData ~= nil ) then
		SendNUIMessage( { _type = "loadUiSettings", data = json.decode( uiData ) } )

		UTIL:Log( "Saved UI settings data loaded!" )
	-- If the data doesn't exist, then we send the defaults
	else
		SendNUIMessage( { _type = "setUiDefaults", data = CONFIG.uiDefaults } )

		UTIL:Log( "Could not find any saved UI settings data." )
	end
end


--[[----------------------------------------------------------------------------------
	Radar variables

	NOTE - This is not a config, do not touch anything unless you know what
	you are actually doing.
----------------------------------------------------------------------------------]]--
RADAR = {}
RADAR.vars =
{
	-- Whether or not the radar's UI is visible
	displayed = false,

	-- The radar's power, the system simulates the radar unit powering up when the user clicks the
	-- power button on the interface
	power = false,
	poweringUp = false,

	-- Whether or not the radar should be hidden, e.g. the display is active but the player then steps
	-- out of their vehicle
	hidden = false,

	-- These are the settings that are used in the operator menu
	settings = {
		-- Should the system calculate and display faster targets
		["fastDisplay"] = CONFIG.menuDefaults["fastDisplay"],

		-- Sensitivity for each radar mode, this changes how far the antennas will detect vehicles
		["same"] = CONFIG.menuDefaults["same"],
		["opp"] = CONFIG.menuDefaults["opp"],

		-- The volume of the audible beep
		["beep"] = CONFIG.menuDefaults["beep"],

		-- The volume of the verbal lock confirmation
		["voice"] = CONFIG.menuDefaults["voice"],

		-- The volume of the plate reader audio
		["plateAudio"] = CONFIG.menuDefaults["plateAudio"],

		-- The speed unit used in conversions
		["speedType"] = CONFIG.menuDefaults["speedType"],

		-- The state of automatic speed locking
		["fastLock"] = CONFIG.menuDefaults["fastLock"],

		-- The speed limit for automatic speed locking
		["fastLimit"] = CONFIG.menuDefaults["fastLimit"]
	},

	-- These 3 variables are for the in-radar menu that can be accessed through the remote control, the menuOptions table
	-- stores all of the information about each of the settings the user can change
	menuActive = false,
	currentOptionIndex = 1,
	menuOptions = {
		{ displayText = { "¦¦¦", "FAS" }, optionsText = { "On¦", "Off" }, options = { true, false }, optionIndex = -1, settingText = "fastDisplay" },
		{ displayText = { "¦SL", "SEn" }, optionsText = { "¦1¦", "¦2¦", "¦3¦", "¦4¦", "¦5¦" }, options = { 0.2, 0.4, 0.6, 0.8, 1.0 }, optionIndex = -1, settingText = "same" },
		{ displayText = { "¦OP", "SEn" }, optionsText = { "¦1¦", "¦2¦", "¦3¦", "¦4¦", "¦5¦" }, options = { 0.2, 0.4, 0.6, 0.8, 1.0 }, optionIndex = -1, settingText = "opp" },
		{ displayText = { "bEE", "P¦¦" }, optionsText = { "Off", "¦1¦", "¦2¦", "¦3¦", "¦4¦", "¦5¦" }, options = { 0.0, 0.2, 0.4, 0.6, 0.8, 1.0 }, optionIndex = -1, settingText = "beep" },
		{ displayText = { "VOI", "CE¦" }, optionsText = { "Off", "¦1¦", "¦2¦", "¦3¦", "¦4¦", "¦5¦" }, options = { 0.0, 0.2, 0.4, 0.6, 0.8, 1.0 }, optionIndex = -1, settingText = "voice" },
		{ displayText = { "PLt", "AUd" }, optionsText = { "Off", "¦1¦", "¦2¦", "¦3¦", "¦4¦", "¦5¦" }, options = { 0.0, 0.2, 0.4, 0.6, 0.8, 1.0 }, optionIndex = -1, settingText = "plateAudio" },
		{ displayText = { "Uni", "tS¦" }, optionsText = { "USA", "INT" }, options = { "mph", "kmh" }, optionIndex = -1, settingText = "speedType" }
	},

	-- Player's vehicle speed, mainly used in the dynamic thread wait update
	patrolSpeed = 0,

	-- Antennas, this table contains all of the data needed for operation of the front and rear antennas
	antennas = {
		-- Variables for the front antenna
		[ "front" ] = {
			xmit = false,			-- Whether the antenna is transmitting or in hold
			mode = 0,				-- Current antenna mode, 0 = none, 1 = same, 2 = opp, 3 = same and opp
			speed = 0,				-- Speed of the vehicle caught by the front antenna
			dir = nil, 				-- Direction the caught vehicle is going, 0 = towards, 1 = away
			fastSpeed = 0, 			-- Speed of the fastest vehicle caught by the front antenna
			fastDir = nil, 			-- Direction the fastest vehicle is going
			speedLocked = false, 	-- A speed has been locked for this antenna
			lockedSpeed = nil, 		-- The locked speed
			lockedDir = nil, 			-- The direction of the vehicle that was locked
			lockedType = nil        -- The locked type, 1 = strongest, 2 = fastest
		},

		-- Variables for the rear antenna
		[ "rear" ] = {
			xmit = false,			-- Whether the antenna is transmitting or in hold
			mode = 0,				-- Current antenna mode, 0 = none, 1 = same, 2 = opp, 3 = same and opp
			speed = 0,				-- Speed of the vehicle caught by the front antenna
			dir = nil, 				-- Direction the caught vehicle is going, 0 = towards, 1 = away
			fastSpeed = 0, 			-- Speed of the fastest vehicle caught by the front antenna
			fastDir = nil, 			-- Direction the fastest vehicle is going
			speedLocked = false,	-- A speed has been locked for this antenna
			lockedSpeed = nil,		-- The locked speed
			lockedDir = nil,			-- The direction of the vehicle that was locked
			lockedType = nil        -- The locked type, 1 = strongest, 2 = fastest
		}
	},

	-- The maximum distance that the radar system's ray traces can go, changing this will change the max
	-- distance in-game, but I wouldn't really put it more than 500.0
	maxCheckDist = 350.0,

	-- Cached dynamic vehicle sphere sizes, automatically populated when the system is running
	sphereSizes = {},

	-- Table to store tables for hit entities of captured vehicles
	capturedVehicles = {},

	-- Table to store the valid vehicle models
	validVehicles = {},

	-- The current vehicle data for display
	activeVehicles = {},

	-- Vehicle pool, automatically populated when the system is running, holds all of the current
	-- vehicle IDs for the player using entity enumeration (see cl_utils.lua)
	vehiclePool = {},

	-- Ray trace state, this is used so the radar system doesn't initiate another set of ray traces until
	-- the current set has finished
	rayTraceState = 0,

	-- Number of ray traces, automatically cached when the system first runs
	numberOfRays = 0,

	-- The wait time for the ray trace system, this changes dynamically based on if the player's vehicle is stationary
	-- or not
	threadWaitTime = 500,

	-- Key lock, when true, prevents any of the radar's key events from working, like the ELS key lock
	keyLock = false
}

-- Speed conversion values
RADAR.speedConversions = { ["mph"] = 2.236936, ["kmh"] = 3.6 }

-- These vectors are used in the custom ray tracing system
RADAR.rayTraces = {
	{ startVec = { x = 0.0 }, endVec = { x = 0.0, y = 0.0 }, rayType = "same" },
	{ startVec = { x = -5.0 }, endVec = { x = -5.0, y = 0.0 }, rayType = "same" },
	{ startVec = { x = 5.0 }, endVec = { x = 5.0, y = 0.0 }, rayType = "same" },
	{ startVec = { x = -10.0 }, endVec = { x = -10.0, y = 0.0 }, rayType = "opp" },
	{ startVec = { x = -17.0 }, endVec = { x = -17.0, y = 0.0 }, rayType = "opp" }
}

-- Each of these are used for sorting the captured vehicle data, the 'strongest' filter is used for the main
-- target window of each antenna, whereas the 'fastest' filter is used for the fast target window of each antenna
RADAR.sorting = {
	strongest = function( a, b ) return a.size > b.size end,
	fastest = function( a, b ) return a.speed > b.speed end
}


--[[----------------------------------------------------------------------------------
	Radar essentials functions
----------------------------------------------------------------------------------]]--
-- Returns if the radar's power is on or off
function RADAR:IsPowerOn()
	return self.vars.power
end

-- Returns if the radar system is powering up, the powering up stage only takes 2 seconds
function RADAR:IsPoweringUp()
	return self.vars.poweringUp
end

-- Allows the powering up state variable to be set
function RADAR:SetPoweringUpState( state )
	self.vars.poweringUp = state
end

-- Toggles the radar power
function RADAR:SetPowerState( state, instantOverride )
	local currentState = self:IsPowerOn()

	-- Only power up if the system is not already powering up
	if ( not self:IsPoweringUp() and currentState ~= state ) then
		-- Toggle the power variable
		self.vars.power = state

		-- Send the NUI message to toggle the power
		SendNUIMessage( { _type = "radarPower", state = state, override = instantOverride, fast = self:IsFastDisplayEnabled() } )

		-- Power is now turned on
		if ( self:IsPowerOn() ) then
			-- Also make sure the operator menu is inactive
			self:SetMenuState( false )

			-- Only do the power up simulation if allowed
			if ( not instantOverride ) then
				-- Tell the system the radar is 'powering up'
				self:SetPoweringUpState( true )

				-- Set a 2 second countdown
				Citizen.SetTimeout( 2000, function()
					-- Tell the system the radar has 'powered up'
					self:SetPoweringUpState( false )

					-- Let the UI side know the system has loaded
					SendNUIMessage( { _type = "poweredUp", fast = self:IsFastDisplayEnabled() } )
				end )
			end
		else
			-- If the system is being turned off, then we reset the antennas
			self:ResetAntenna( "front" )
			self:ResetAntenna( "rear" )
		end
	end
end

-- Toggles the display state of the radar system
function RADAR:ToggleDisplayState()
	-- Toggle the display variable
	self.vars.displayed = not self.vars.displayed

	-- Send the toggle message to the NUI side
	SendNUIMessage( { _type = "setRadarDisplayState", state = self:GetDisplayState() } )
end

-- Gets the display state
function RADAR:GetDisplayState()
	return self.vars.displayed
end

-- Return the state of the fastDisplay setting, short hand direct way to check if the fast system is enabled
function RADAR:IsFastDisplayEnabled()
	return self:GetSettingValue( "fastDisplay" )
end

-- Returns if either of the antennas are transmitting
function RADAR:IsEitherAntennaOn()
	return self:IsAntennaTransmitting( "front" ) or self:IsAntennaTransmitting( "rear" )
end

-- Sends an update to the NUI side with the current state of the antennas and if the fast system is enabled
function RADAR:SendSettingUpdate()
	-- Create a table to store the setting information for the antennas
	local antennas = {}

	-- Iterate through each antenna and grab the relevant information
	for ant in UTIL:Values( { "front", "rear" } ) do
		antennas[ant] = {}
		antennas[ant].xmit = self:IsAntennaTransmitting( ant )
		antennas[ant].mode = self:GetAntennaMode( ant )
		antennas[ant].speedLocked = self:IsAntennaSpeedLocked( ant )
		antennas[ant].fast = self:ShouldFastBeDisplayed( ant )
	end

	-- Send a message to the NUI side with the current state of the antennas
	SendNUIMessage( { _type = "settingUpdate", antennaData = antennas } )
end

-- Returns if a main task can be performed
-- A main task such as the ray trace thread should only run if the radar's power is on, the system is not in the
-- process of powering up, and the operator menu is not open
function RADAR:CanPerformMainTask()
	return self:IsPowerOn() and not self:IsPoweringUp() and not self:IsMenuOpen()
end

-- Returns/sets what the dynamic thread wait time is
function RADAR:GetThreadWaitTime() return self.vars.threadWaitTime end
function RADAR:SetThreadWaitTime( time ) self.vars.threadWaitTime = time end

-- Returns/sets the radr's display hidden state
function RADAR:GetDisplayHidden() return self.vars.hidden end
function RADAR:SetDisplayHidden( state ) self.vars.hidden = state end

-- Opens the remote only if the pause menu is not open and the player's vehicle state is valid, as the
-- passenger can also open the remote, we check the config variable as well.
function RADAR:OpenRemote()
	if ( not IsPauseMenuActive() and PLY:CanViewRadar() ) then
		-- Get the remote open state from the other player
		local openByOtherPly = SYNC:IsRemoteAlreadyOpen( PLY:GetOtherPed() )

		-- Check that the remote can be opened
		if ( not openByOtherPly ) then
			-- Tell the NUI side to open the remote
			SendNUIMessage( { _type = "openRemote" } )

			SYNC:SetRemoteOpenState( true )

			if ( CONFIG.allow_quick_start_video ) then
				-- Display the new user popup if we can
				local show = GetResourceKvpInt( "wk_wars2x_new_user" )

				if ( show == 0 ) then
					SendNUIMessage( { _type = "showNewUser" } )
				end
			end

			-- Bring focus to the NUI side
			SetNuiFocus( true, true )
		else
			UTIL:Notify( "Another player already has the remote open." )
		end
	end
end

-- Event to open the remote
RegisterNetEvent( "wk:openRemote" )
AddEventHandler( "wk:openRemote", function()
	RADAR:OpenRemote()
end )

-- Returns if the passenger can view the radar too
function RADAR:IsPassengerViewAllowed()
	return CONFIG.allow_passenger_view
end

-- Returns if the passenger can control the radar and plate reader, reliant on the passenger being
-- able to view the radar and plate reader too
function RADAR:IsPassengerControlAllowed()
	return CONFIG.allow_passenger_view and CONFIG.allow_passenger_control
end

-- Returns if we only auto lock vehicle speeds if said vehicle is a player
function RADAR:OnlyLockFastPlayers()
	return CONFIG.only_lock_players
end

-- Returns if the fast limit option should be available for the radar
function RADAR:IsFastLimitAllowed()
	return CONFIG.allow_fast_limit
end

-- Only create the functions if the fast limit config option is enabled
if ( RADAR:IsFastLimitAllowed() ) then
	-- Adds settings into the radar's variables for when the allow_fast_limit variable is true
	function RADAR:CreateFastLimitConfig()
		-- Create the options for the menu
		local fastOptions =
		{
			{ displayText = { "FAS", "Loc" }, optionsText = { "On¦", "Off" }, options = { true, false }, optionIndex = 2, settingText = "fastLock" },
			{ displayText = { "FAS", "SPd" }, optionsText = {}, options = {}, optionIndex = 12, settingText = "fastLimit" }
		}

		-- Iterate from 5 to 200 in steps of 5 and insert into the fast limit option
		for i = 5, 200, 5 do
			local text = UTIL:FormatSpeed( i )

			table.insert( fastOptions[2].optionsText, text )
			table.insert( fastOptions[2].options, i )
		end

		-- Add the fast options to the main menu options table
		if ( CONFIG.fast_limit_first_in_menu ) then
			table.insert( self.vars.menuOptions, 1, fastOptions[2] )	--FasSpd
			table.insert( self.vars.menuOptions, 2, fastOptions[1] )	--FasLoc
		else
			table.insert( self.vars.menuOptions, fastOptions[1] )	--FasLoc
			table.insert( self.vars.menuOptions, fastOptions[2] )	--FasSpd
		end
	end

	-- Returns the numerical fast limit
	function RADAR:GetFastLimit()
		return self:GetSettingValue( "fastLimit" )
	end

	-- Returns if the fast lock menu option is on or off
	function RADAR:IsFastLockEnabled()
		return self:GetSettingValue( "fastLock" )
	end
end

-- Toggles the internal key lock state, which stops any of the radar's key binds from working
function RADAR:ToggleKeyLock()
	-- Check the player state is valid
	if ( PLY:CanViewRadar() ) then
		-- Toggle the key lock variable
		self.vars.keyLock = not self.vars.keyLock

		-- Tell the NUI side to display the key lock message
		SendNUIMessage( { _type = "displayKeyLock", state = self:GetKeyLockState() } )
	end
end

-- Returns the key lock state
function RADAR:GetKeyLockState()
	return self.vars.keyLock
end


--[[----------------------------------------------------------------------------------
	Radar menu functions
----------------------------------------------------------------------------------]]--
-- Sets the menu state to the given state
function RADAR:SetMenuState( state )
	-- Make sure that the radar's power is on
	if ( self:IsPowerOn() ) then
		-- Set the menuActive variable to the given state
		self.vars.menuActive = state

		-- If we are opening the menu, make sure the first item is displayed
		if ( state ) then
			self.vars.currentOptionIndex = 1
		end
	end
end

-- Closes the operator menu
function RADAR:CloseMenu( playAudio )
	-- Set the internal menu state to be closed (false)
	RADAR:SetMenuState( false )

	-- Send a setting update to the NUI side
	RADAR:SendSettingUpdate()

	-- Play a menu done beep
	if ( playAudio or playAudio == nil ) then
		SendNUIMessage( { _type = "audio", name = "done", vol = RADAR:GetSettingValue( "beep" ) } )
	end

	-- Save the operator menu values
	local omData = json.encode( RADAR.vars.settings )
	SetResourceKvp( "wk_wars2x_om_data", omData )

	-- Send the operator menu to the passenger if allowed
	if ( self:IsPassengerViewAllowed() ) then
		local updatedOMData = self:GetOMTableData()
		SYNC:SendUpdatedOMData( updatedOMData )
	end
end

-- Returns if the operator menu is open
function RADAR:IsMenuOpen()
	return self.vars.menuActive
end

-- This function changes the menu index variable so the user can iterate through the options in the operator menu
function RADAR:ChangeMenuIndex()
	-- Create a temporary variable of the current menu index plus 1
	local temp = self.vars.currentOptionIndex + 1

	-- If the temporary value is larger than how many options there are, set it to 1, this way the menu
	-- loops back round to the start of the menu
	if ( temp > #self.vars.menuOptions ) then
		temp = 1
	end

	-- Set the menu index variable to the temporary value we created
	self.vars.currentOptionIndex = temp

	-- Call the function to send an update to the NUI side
	self:SendMenuUpdate()
end

-- Returns the option table of the current menu index
function RADAR:GetMenuOptionTable()
	return self.vars.menuOptions[self.vars.currentOptionIndex]
end

-- Changes the index for an individual option
-- E.g. { "On" "Off" }, index = 2 would be "Off"
function RADAR:SetMenuOptionIndex( index )
	self.vars.menuOptions[self.vars.currentOptionIndex].optionIndex = index
end

-- Returns the option value for the current option
function RADAR:GetMenuOptionValue()
	local opt = self:GetMenuOptionTable()
	local index = opt.optionIndex

	return opt.options[index]
end

-- This function is similar to RADAR:ChangeMenuIndex() but allows for iterating forward and backward through options
function RADAR:ChangeMenuOption( dir )
	-- Get the option table of the currently selected option
	local opt = self:GetMenuOptionTable()

	-- Get the current option index of the selected option
	local index = opt.optionIndex

	-- Cache the size of this setting's options table
	local size = #opt.options

	-- As the XMIT/HOLD buttons are used for changing the option values, we have to check which button is being pressed
	if ( dir == "front" ) then
		index = index + 1
		if ( index > size ) then index = 1 end
	elseif ( dir == "rear" ) then
		index = index - 1
		if ( index < 1 ) then index = size end
	end

	-- Update the option's index
	self:SetMenuOptionIndex( index )

	-- Change the value of the setting in the main RADAR.vars.settings table
	self:SetSettingValue( opt.settingText, self:GetMenuOptionValue() )

	-- Call the function to send an update to the NUI side
	self:SendMenuUpdate()
end

-- Returns what text should be displayed in the boxes for the current option
-- E.g. "¦SL" "SEN"
function RADAR:GetMenuOptionDisplayText()
	return self:GetMenuOptionTable().displayText
end

-- Returns the option text of the currently selected setting
function RADAR:GetMenuOptionText()
	local opt = self:GetMenuOptionTable()

	return opt.optionsText[opt.optionIndex]
end

-- Sends a message to the NUI side with updated information on what should be displayed for the menu
function RADAR:SendMenuUpdate()
	SendNUIMessage( { _type = "menu", text = self:GetMenuOptionDisplayText(), option = self:GetMenuOptionText() } )
end

-- Used to set individual settings within RADAR.vars.settings, as all of the settings use string keys, using this
-- function makes updating settings easier
function RADAR:SetSettingValue( setting, value )
	-- Make sure that we're not trying to set a nil value for the setting
	if ( value ~= nil ) then
		-- Set the setting's value
		self.vars.settings[setting] = value

		-- If the setting that's being updated is same or opp, then we update the end coordinates for the ray tracer
		if ( setting == "same" or setting == "opp" ) then
			self:UpdateRayEndCoords()
		end
	end
end

-- Returns the value of the given setting
function RADAR:GetSettingValue( setting )
	return self.vars.settings[setting]
end

-- Attempts to load the saved operator menu data
function RADAR:LoadOMData()
	UTIL:Log( "Attempting to load saved operator menu data." )

	-- Try and get the data
	local rawData = GetResourceKvpString( "wk_wars2x_om_data" )

	-- If the data exists, decode it and replace the operator menu table
	if ( rawData ~= nil ) then
		local omData = json.decode( rawData )
		self.vars.settings = omData

		UTIL:Log( "Saved operator menu data loaded!" )
	else
		UTIL:Log( "Could not find any saved operator menu data." )
	end
end

-- Updates the operator menu option indexes, as the default menu values can be changed in the config, we
-- need to update the indexes otherwise the menu will display the wrong values
function RADAR:UpdateOptionIndexes( loadSaved )
	if ( loadSaved ) then
		self:LoadOMData()
	end

	-- Iterate through each of the internal settings
	for k, v in pairs( self.vars.settings ) do
		-- Iterate through all of the menu options
		for i, t in pairs( self.vars.menuOptions ) do
			-- If the current menu option is the same as the current setting
			if ( t.settingText == k ) then
				-- Iterate through the option values of the current menu option
				for oi, ov in pairs( t.options ) do
					-- If the value of the current option set in the config matches the current value of
					-- the option value, then we update the option index variable
					if ( v == ov ) then
						t.optionIndex = oi
					end
				end
			end
		end
	end
end


--[[----------------------------------------------------------------------------------
	Radar basics functions
----------------------------------------------------------------------------------]]--
-- Returns the patrol speed value stored
function RADAR:GetPatrolSpeed()	return self.vars.patrolSpeed end

-- Returns the current vehicle pool
function RADAR:GetVehiclePool()	return self.vars.vehiclePool end

-- Returns the maximum distance a ray trace can go
function RADAR:GetMaxCheckDist() return self.vars.maxCheckDist end

-- Returns the table sorting function 'strongest'
function RADAR:GetStrongestSortFunc() return self.sorting.strongest end

-- Returns the table sorting function 'fastest'
function RADAR:GetFastestSortFunc() return self.sorting.fastest end

-- Sets the patrol speed to a formatted version of the given number
function RADAR:SetPatrolSpeed( speed )
	if ( type( speed ) == "number" ) then
		self.vars.patrolSpeed = self:GetVehSpeedConverted( speed )
	end
end

-- Sets the vehicle pool to the given value if it's a table
function RADAR:SetVehiclePool( pool )
	if ( type( pool ) == "table" ) then
		self.vars.vehiclePool = pool
	end
end


--[[----------------------------------------------------------------------------------
	Radar ray trace functions
----------------------------------------------------------------------------------]]--
-- Returns what the current ray trace state is
function RADAR:GetRayTraceState() return self.vars.rayTraceState end

-- Caches the number of ray traces in RADAR.rayTraces
function RADAR:CacheNumRays() self.vars.numberOfRays = #self.rayTraces end

-- Returns the number of ray traces the system has
function RADAR:GetNumOfRays() return self.vars.numberOfRays end

-- Increases the system's ray trace state ny 1
function RADAR:IncreaseRayTraceState() self.vars.rayTraceState = self.vars.rayTraceState + 1 end

-- Resets the ray trace state to 0
function RADAR:ResetRayTraceState() self.vars.rayTraceState = 0 end

-- This function is used to determine if a sphere intersect is in front or behind the player's vehicle, the
-- sphere intersect calculation has a 'tProj' value that is a line from the centre of the sphere that goes onto
-- the line being traced. This value will either be positive or negative and can be used to work out the
-- relative position of a point.
function RADAR:GetIntersectedVehIsFrontOrRear( t )
	if ( t > 8.0 ) then
		return 1 -- vehicle is in front
	elseif ( t < -8.0 ) then
		return -1 -- vehicle is behind
	end

	return 0 -- vehicle is next to self
end

-- This function is used to check if a line going from point A to B intersects with a given sphere, it's used in
-- the radar system to check if the patrol vehicle can detect any vehicles. As the default ray trace system in GTA
-- cannot detect vehicles beyond 40~ units, my system acts as a replacement that allows the detection of vehicles
-- much further away (400+ units). Also, as my system uses sphere intersections, each sphere can have a different
-- radius, which means that larger vehicles can have larger spheres, and smaller vehicles can have smaller spheres.
function RADAR:GetLineHitsSphereAndDir( c, radius, rs, re )
	-- Take the vector3's and turn them into vector2's, this way all of the calculations below are for an
	-- infinite cylinder rather than a sphere, which also means that vehicles can be detected even when on
	-- an incline!
	local rayStart = vector2( rs.x, rs.y )
	local rayEnd = vector2( re.x, re.y )
	local centre = vector2( c.x, c.y )

	-- First we get the normalised ray, this way we then know the direction the ray is going
	local rayNorm = norm( rayEnd - rayStart )

	-- Then we calculate the ray from the start point to the centre position of the sphere
	local rayToCentre = centre - rayStart

	-- Now that we have the ray to the centre of the sphere, and the normalised ray direction, we
	-- can calculate the shortest point from the centre of the sphere onto the ray itself. This
	-- would then give us the opposite side of the right angled triangle. All of the resulting
	-- values are also in squared form, as performing square root functions is slower.
	local tProj = dot( rayToCentre, rayNorm )
	local oppLenSqr = dot( rayToCentre, rayToCentre ) - ( tProj * tProj )

	-- Square the radius
	local radiusSqr = radius * radius

	-- Calculate the distance of the ray trace to make sure we only return valid results if the trace
	-- is actually within the distance
	local rayDist = #( rayEnd - rayStart )
	local distToCentre = #( rayStart - centre ) - ( radius * 2 )

	-- Now all we have to do is compare the squared opposite length and the radius squared, this
	-- will then tell us if the ray intersects with the sphere.
	if ( oppLenSqr < radiusSqr and not ( distToCentre > rayDist ) ) then
		return true, self:GetIntersectedVehIsFrontOrRear( tProj )
	end

	return false, nil
end

-- This function is used to check if the target vehicle is in the same general traffic flow as the player's vehicle
-- is sitting. If the angle is too great, then the radar would have an incorrect return for the speed.
function RADAR:IsVehicleInTraffic( tgtVeh, relPos )
	local tgtHdg = GetEntityHeading( tgtVeh )
	local plyHdg = GetEntityHeading( PLY.veh )

	-- Work out the heading difference, but also take into account extreme opposites (e.g. 5deg and 350deg)
	local hdgDiff = math.abs( ( plyHdg - tgtHdg + 180 ) % 360 - 180 )

	if ( relPos == 1 and hdgDiff > 45 and hdgDiff < 135 ) then
		return false
	elseif ( relPos == -1 and hdgDiff > 45 and ( hdgDiff < 135 or hdgDiff > 215 ) ) then
		return false
	end

	return true
end

-- This function is the main custom ray trace function, it performs most of the major tasks for checking a vehicle
-- is valid and should be tested. It also makes use of the LOS native to make sure that we can only trace a vehicle
-- if actually nas a direct line of sight with the player's vehicle, this way we don't pick up vehicles behind walls
-- for example. It then creates a dynamic sphere for the vehicle based on the actual model dimensions of it, adds a
-- small bit of realism, as real radars usually return the strongest target speed.
function RADAR:ShootCustomRay( plyVeh, veh, s, e )
	-- Get the world coordinates of the target vehicle
	local pos = GetEntityCoords( veh )

	-- Calculate the distance between the target vehicle and the start point of the ray trace, note how we don't
	-- use GetDistanceBetweenCoords or Vdist, the method below still returns the same result with less cpu time
	local dist = #( pos - s )

	-- We only perform a trace on the target vehicle if it exists, isn't the player's vehicle, and the distance is
	-- less than the max distance defined by the system
	if ( DoesEntityExist( veh ) and veh ~= plyVeh and dist < self:GetMaxCheckDist() ) then
		-- Get the speed of the target vehicle
		local entSpeed = GetEntitySpeed( veh )

		-- Check that the target vehicle is within the line of sight of the player's vehicle
		local visible = HasEntityClearLosToEntity( plyVeh, veh, 15 ) -- 13 seems okay, 15 too (doesn't grab ents through ents)

		-- Get the pitch of the player's vehicle
		local pitch = GetEntityPitch( plyVeh )

		-- Now we check that the target vehicle is moving and is visible
		if ( entSpeed > 0.1 and ( pitch > -35 and pitch < 35 ) and visible ) then
			-- Get the dynamic radius as well as the size of the target vehicle
			local radius, size = self:GetDynamicRadius( veh )

			-- Check that the trace line intersects with the target vehicle's sphere
			local hit, relPos = self:GetLineHitsSphereAndDir( pos, radius, s, e )

			-- Return all of the information if the vehicle was hit and is in the flow of traffic
			if ( hit and self:IsVehicleInTraffic( veh, relPos ) ) then
				return true, relPos, dist, entSpeed, size
			end
		end
	end

	-- Return a whole lot of nothing
	return false, nil, nil, nil, nil
end

-- This function is used to gather all of the data on vehicles that have been hit by the given trace line, when
-- a vehicle is hit, all of the information about that vehicle is put into a keyless table which is then inserted
-- into a main table. When the loop has finished, the function then returns the table with all of the data.
function RADAR:GetVehsHitByRay( ownVeh, vehs, s, e )
	-- Create the table that will be used to store all of the results
	local caughtVehs = {}

	-- Set the variable to say if there has been data collected
	local hasData = false

	-- Iterate through all of the vehicles
	for _, veh in pairs( vehs ) do
		-- Shoot a custom ray trace to see if the vehicle gets hit
		local hit, relativePos, distance, speed, size = self:ShootCustomRay( ownVeh, veh, s, e )

		-- If the vehicle is hit, then we create a table containing all of the information
		if ( hit ) then
			-- Create the table to store the data
			local vehData = {}
			vehData.veh = veh
			vehData.relPos = relativePos
			vehData.dist = distance
			vehData.speed = speed
			vehData.size = size

			-- Insert the table into the caught vehicles table
			table.insert( caughtVehs, vehData )

			-- Change the has data variable to true, this way the table will be returned
			hasData = true
		end
	end

	-- If the caughtVehs table actually has data, then return it
	if ( hasData ) then return caughtVehs end
end

-- This function is used to gather all of the vehicles hit by a given line trace, and then insert it into the
-- internal captured vehicles table.
function RADAR:CreateRayThread( vehs, from, startX, endX, endY, rayType )
	-- Get the start and end points for the ray trace based on the given start and end coordinates
	local startPoint = GetOffsetFromEntityInWorldCoords( from, startX, 0.0, 0.0 )
	local endPoint = GetOffsetFromEntityInWorldCoords( from, endX, endY, 0.0 )

	-- Get all of the vehicles hit by the ray
	local hitVehs = self:GetVehsHitByRay( from, vehs, startPoint, endPoint )

	-- Insert the captured vehicle data and pass the ray type too
	self:InsertCapturedVehicleData( hitVehs, rayType )

	-- Increase the ray trace state
	self:IncreaseRayTraceState()
end

-- This function iterates through each of the traces defined in RADAR.rayTraces and creates a 'thread' for
-- them, passing along all of the vehicle pool data and the player's vehicle
function RADAR:CreateRayThreads( ownVeh, vehicles )
	for _, v in pairs( self.rayTraces ) do
		self:CreateRayThread( vehicles, ownVeh, v.startVec.x, v.endVec.x, v.endVec.y, v.rayType )
	end
end

-- When the user changes either the same lane or opp lane sensitivity from within the operator menu, this function
-- is then called to update the end coordinates for all of the traces
function RADAR:UpdateRayEndCoords()
	for _, v in pairs( self.rayTraces ) do
		-- Calculate what the new end coordinate should be
		local endY = self:GetSettingValue( v.rayType ) * self:GetMaxCheckDist()

		-- Update the end Y coordinate in the traces table
		v.endVec.y = endY
	end
end


--[[----------------------------------------------------------------------------------
	Radar antenna functions
----------------------------------------------------------------------------------]]--
-- Toggles the state of the given antenna between hold and transmitting, only works if the radar's power is
-- on. Also runs a callback function when present.
function RADAR:ToggleAntenna( ant )
	-- Check power is on
	if ( self:IsPowerOn() ) then
		-- Toggle the given antennas state
		self.vars.antennas[ant].xmit = not self.vars.antennas[ant].xmit

		-- Update the interface with the new antenna transmit state
		SendNUIMessage( { _type = "antennaXmit", ant = ant, on = self:IsAntennaTransmitting( ant ) } )

		-- Play some audio specific to the transmit state
		SendNUIMessage( { _type = "audio", name = self:IsAntennaTransmitting( ant ) and "xmit_on" or "xmit_off", vol = self:GetSettingValue( "beep" ) } )
	end
end

-- Returns if the given antenna is transmitting
function RADAR:IsAntennaTransmitting( ant ) return self.vars.antennas[ant].xmit end

-- Returns if the given relative position value is for the front or rear antenna
function RADAR:GetAntennaTextFromNum( relPos )
	if ( relPos == 1 ) then
		return "front"
	elseif ( relPos == -1 ) then
		return "rear"
	end
end

-- Returns the mode of the given antenna
function RADAR:GetAntennaMode( ant ) return self.vars.antennas[ant].mode end

-- Sets the mode of the given antenna if the mode is valid and the power is on. Also runs a callback function
-- when present.
function RADAR:SetAntennaMode( ant, mode )
	-- Check the mode is actually a number, this is needed as the radar system relies on the mode to be
	-- a number to work
	if ( type( mode ) == "number" ) then
		-- Check the mode is in the valid range for modes, and that the power is on
		if ( mode >= 0 and mode <= 3 and self:IsPowerOn() ) then
			-- Update the mode for the antenna
			self.vars.antennas[ant].mode = mode

			-- Update the interface with the new mode
			SendNUIMessage( { _type = "antennaMode", ant = ant, mode = mode } )

			-- Play a beep
			SendNUIMessage( { _type = "audio", name = "beep", vol = self:GetSettingValue( "beep" ) } )
		end
	end
end

-- Returns/sets the speed for the given antenna
function RADAR:GetAntennaSpeed( ant ) return self.vars.antennas[ant].speed end
function RADAR:SetAntennaSpeed( ant, speed ) self.vars.antennas[ant].speed = speed end

-- Returns/sets the direction for the given antenna
function RADAR:GetAntennaDir( ant ) return self.vars.antennas[ant].dir end
function RADAR:SetAntennaDir( ant, dir ) self.vars.antennas[ant].dir = dir end

-- Sets the speed and direction in one go
function RADAR:SetAntennaData( ant, speed, dir )
	self:SetAntennaSpeed( ant, speed )
	self:SetAntennaDir( ant, dir )
end

-- Returns/sets the fast speed for the given antenna
function RADAR:GetAntennaFastSpeed( ant ) return self.vars.antennas[ant].fastSpeed end
function RADAR:SetAntennaFastSpeed( ant, speed ) self.vars.antennas[ant].fastSpeed = speed end

-- Returns/sets the fast direction for the given antenna
function RADAR:GetAntennaFastDir( ant ) return self.vars.antennas[ant].fastDir end
function RADAR:SetAntennaFastDir( ant, dir ) self.vars.antennas[ant].fastDir = dir end

-- Sets the fast speed and direction in one go
function RADAR:SetAntennaFastData( ant, speed, dir )
	self:SetAntennaFastSpeed( ant, speed )
	self:SetAntennaFastDir( ant, dir )
end

-- Returns if the stored speed for the given antenna is valid
function RADAR:DoesAntennaHaveValidData( ant )
	return self:GetAntennaSpeed( ant ) ~= nil
end

-- Returns if the stored fast speed for the given antenna is valid
function RADAR:DoesAntennaHaveValidFastData( ant )
	return self:GetAntennaFastSpeed( ant ) ~= nil
end

-- Returns if the fast label should be displayed
function RADAR:ShouldFastBeDisplayed( ant )
	if ( self:IsAntennaSpeedLocked( ant ) ) then
		return self:GetAntennaLockedType( ant ) == 2
	else
		return self:IsFastDisplayEnabled()
	end
end

-- Returns if the given antenna has a locked speed
function RADAR:IsAntennaSpeedLocked( ant )
	return self.vars.antennas[ant].speedLocked
end

-- Sets the state of speed lock for the given antenna to the given state
function RADAR:SetAntennaSpeedIsLocked( ant, state )
	self.vars.antennas[ant].speedLocked = state
end

-- Sets a speed and direction to be locked in for the given antenna
function RADAR:SetAntennaSpeedLock( ant, speed, dir, lockType, playAudio )
	-- Check that the passed speed and direction are actually valid
	if ( speed ~= nil and dir ~= nil and lockType ~= nil ) then
		-- Set the locked speed and direction to the passed values
		self.vars.antennas[ant].lockedSpeed = speed
		self.vars.antennas[ant].lockedDir = dir
		self.vars.antennas[ant].lockedType = lockType

		-- Tell the system that a speed has been locked for the given antenna
		self:SetAntennaSpeedIsLocked( ant, true )

		if ( playAudio ) then
			-- Send a message to the NUI side to play the beep sound with the current volume setting
			SendNUIMessage( { _type = "audio", name = "beep", vol = self:GetSettingValue( "beep" ) } )

			-- Send a message to the NUI side to play the lock audio with the current voice volume setting
			SendNUIMessage( { _type = "lockAudio", ant = ant, dir = dir, vol = self:GetSettingValue( "voice" ) } )
		end

		-- Great Scott!
		if ( speed == "¦88" and self:GetSettingValue( "speedType" ) == "mph" ) then
			math.randomseed( GetGameTimer() )

			local chance = math.random()

			-- 15% chance
			if ( chance <= 0.15 ) then
				SendNUIMessage( { _type = "audio", name = "speed_alert", vol = self:GetSettingValue( "beep" ) } )
			end
		end
	end
end

-- Returns the locked speed for the given antenna
function RADAR:GetAntennaLockedSpeed( ant )
	return self.vars.antennas[ant].lockedSpeed
end

-- Returns the locked direction for the given antenna
function RADAR:GetAntennaLockedDir( ant )
	return self.vars.antennas[ant].lockedDir
end

-- Returns the lock type for the given antenna
function RADAR:GetAntennaLockedType( ant )
	return self.vars.antennas[ant].lockedType
end

-- Resets the speed lock info to do with the given antenna
function RADAR:ResetAntennaSpeedLock( ant )
	-- Blank the locked speed and direction
	self.vars.antennas[ant].lockedSpeed = nil
	self.vars.antennas[ant].lockedDir = nil
	self.vars.antennas[ant].lockedType = nil

	-- Set the locked state to false
	self:SetAntennaSpeedIsLocked( ant, false )
end

-- When the user presses the speed lock key for either antenna, this function is called to get the
-- necessary information from the antenna, and then lock it into the display
function RADAR:LockAntennaSpeed( ant, override, lockRegardless )
	-- Only lock a speed if the antenna is on and the UI is displayed
	if ( self:IsPowerOn() and ( ( self:GetDisplayState() and not self:GetDisplayHidden() ) or lockRegardless ) and self:IsAntennaTransmitting( ant ) ) then
		-- Used to determine whether or not to play the audio and update the display. This is mainly for the passenger
		-- control system, as in theory one player could be in the operator menu, and the other player could lock a speed.
		local isMenuOpen = self:IsMenuOpen()

		-- Check if the antenna doesn't have a locked speed, if it doesn't then we lock in the speed, otherwise we
		-- reset the lock
		if ( not self:IsAntennaSpeedLocked( ant ) ) then
			-- Here we check if the override parameter is valid, if so then we set the radar's speed data to the
			-- speed data provided in the override table.
			if ( override ~= nil ) then
				self:SetAntennaData( ant, override[1], override[2] )
				self:SetAntennaFastData( ant, override[3], override[4] )
			end

			-- This override parameter is used for the passenger control system, as the speeds displayed on the
			-- recipients display can't be trusted. When the player who locks the speed triggers the sync, their
			-- speed data is collected and sent to the other player so that their speed data is overriden to be the same.
			override = override or { nil, nil, nil, nil }

			-- Set up a temporary table with 3 nil values, this way if the system isn't able to get a speed or
			-- direction, the speed lock function won't work
			local data = { nil, nil, nil }

			-- As the lock system is based on which speed is displayed, we have to check if there is a speed in the
			-- fast box, if there is then we lock in the fast speed, otherwise we lock in the strongest speed
			if ( self:IsFastDisplayEnabled() and self:DoesAntennaHaveValidFastData( ant ) ) then
				data[1] = self:GetAntennaFastSpeed( ant )
				data[2] = self:GetAntennaFastDir( ant )
				data[3] = 2
			else
				data[1] = self:GetAntennaSpeed( ant )
				data[2] = self:GetAntennaDir( ant )
				data[3] = 1
			end

			-- Lock in the speed data for the antenna
			self:SetAntennaSpeedLock( ant, data[1], data[2], data[3], not isMenuOpen )
		else
			self:ResetAntennaSpeedLock( ant )
		end

		if ( not isMenuOpen ) then
			-- Send an NUI message to change the lock label, otherwise we'd have to wait until the next main loop
			SendNUIMessage( { _type = "antennaLock", ant = ant, state = self:IsAntennaSpeedLocked( ant ) } )
			SendNUIMessage( { _type = "antennaFast", ant = ant, state = self:ShouldFastBeDisplayed( ant ) } )
		end
	end
end

-- Resets an antenna, used when the system is turned off
function RADAR:ResetAntenna( ant )
	-- Overwrite default behaviour, this is because when the system is turned off, the temporary memory is
	-- technically reset, as the setter functions require either the radar power to be on or the antenna to
	-- be transmitting, this is the only way to reset the values
	self.vars.antennas[ant].xmit = false
	self.vars.antennas[ant].mode = 0

	self:ResetAntennaSpeedLock( ant )
end

-- Returns a table with the given antenna's speed data and directions
function RADAR:GetAntennaDataPacket( ant )
	return {
		self:GetAntennaSpeed( ant ),
		self:GetAntennaDir( ant ),
		self:GetAntennaFastSpeed( ant ),
		self:GetAntennaFastDir( ant )
	}
end


--[[----------------------------------------------------------------------------------
	Radar captured vehicle functions
----------------------------------------------------------------------------------]]--
-- Returns the captured vehicles table
function RADAR:GetCapturedVehicles()
	return self.vars.capturedVehicles
end

-- Resets the captured vehicles table to an empty table
function RADAR:ResetCapturedVehicles()
	self.vars.capturedVehicles = {}
end

-- Takes the vehicle data from RADAR:CreateRayThread() and puts it into the main captured vehicles table, along
-- with the ray type for that vehicle data set (e.g. same or opp)
function RADAR:InsertCapturedVehicleData( t, rt )
	-- Make sure the table being passed is valid and not empty
	if ( type( t ) == "table" and not UTIL:IsTableEmpty( t ) ) then
		-- Iterate through the given table
		for _, v in pairs( t ) do
			-- Add the ray type to the current row
			v.rayType = rt

			-- Insert it into the main captured vehicles table
			table.insert( self.vars.capturedVehicles, v )
		end
	end
end


--[[----------------------------------------------------------------------------------
	Radar dynamic sphere radius functions
----------------------------------------------------------------------------------]]--
-- Returns the dynamic sphere data for the given key if there is any
function RADAR:GetDynamicDataValue( key )
	return self.vars.sphereSizes[key]
end

-- Returns if dynamic sphere data exists for the given key
function RADAR:DoesDynamicRadiusDataExist( key )
	return self:GetDynamicDataValue( key ) ~= nil
end

-- Sets the dynamic sohere data for the given key to the given table
function RADAR:SetDynamicRadiusKey( key, t )
	self.vars.sphereSizes[key] = t
end

-- Inserts the given data into the dynamic spheres table, stores the radius and the actual summed up
-- vehicle size. The key is just the model of a vehicle put into string form
function RADAR:InsertDynamicRadiusData( key, radius, actualSize )
	-- Check to make sure there is no data for the vehicle
	if ( self:GetDynamicDataValue( key ) == nil ) then
		-- Create a table to store the data in
		local data = {}

		-- Put the data into the temporary table
		data.radius = radius
		data.actualSize = actualSize

		-- Set the dynamic sphere data for the vehicle
		self:SetDynamicRadiusKey( key, data )
	end
end

-- Returns the dynamic sphere data for the given vehicle
function RADAR:GetRadiusData( key )
	return self.vars.sphereSizes[key].radius, self.vars.sphereSizes[key].actualSize
end

-- This function is used to get the dynamic sphere data for a vehicle, if data already exists for the
-- given vehicle, then the system just returns the already made data, otherwise the data gets created
function RADAR:GetDynamicRadius( veh )
	-- Get the model of the vehicle
	local mdl = GetEntityModel( veh )

	-- Create a key based on the model
	local key = tostring( mdl )

	-- Check to see if data already exists
	local dataExists = self:DoesDynamicRadiusDataExist( key )

	-- If the data doesn't already exist, then we create it
	if ( not dataExists ) then
		-- Get the min and max points of the vehicle model
		local min, max = GetModelDimensions( mdl )

		-- Calculate the size, as the min value is negative
		local size = max - min

		-- Get a numeric size which composes of the x, y, and z size combined
		local numericSize = size.x + size.y + size.z

		-- Get a dynamic radius for the given vehicle model that fits into the world of GTA
		local dynamicRadius = UTIL:Clamp( ( numericSize * numericSize ) / 12, 5.0, 11.0 )

		-- Insert the newly created sphere data into the sphere data table
		self:InsertDynamicRadiusData( key, dynamicRadius, numericSize )

		-- Return the data
		return dynamicRadius, numericSize
	end

	-- Return the stored data
	return self:GetRadiusData( key )
end


--[[----------------------------------------------------------------------------------
	Radar functions
----------------------------------------------------------------------------------]]--
-- Takes a GTA speed and converts it into the type defined by the user in the operator menu
function RADAR:GetVehSpeedConverted( speed )
	-- Get the speed unit from the settings
	local unit = self:GetSettingValue( "speedType" )

	-- Return the coverted speed rounded to a whole number
	return UTIL:Round( speed * self.speedConversions[unit], 0 )
end

-- Returns/sets the validity of the given vehicle model
function RADAR:GetVehicleValidity( key ) return self.vars.validVehicles[key] end
function RADAR:SetVehicleValidity( key, validity ) self.vars.validVehicles[key] = validity end

-- Returns if vehicle validity data exists for the given vehicle model
function RADAR:DoesVehicleValidityExist( key )
	return self:GetVehicleValidity( key ) ~= nil
end

-- Returns if the given vehicle is valid, as we don't want the radar to detect boats, helicopters, or planes!
function RADAR:IsVehicleValid( veh )
	-- Get the model of the vehicle
	local mdl = GetEntityModel( veh )

	-- Create a key based on the model
	local key = tostring( mdl )

	-- Check if the vehicle model is valid
	local valid = self:GetVehicleValidity( key )

	-- If the validity value hasn't been set for the vehicle model, then we do it now
	if ( valid == nil ) then
		-- If the model is not what we want, then set the validity to false
		if ( IsThisModelABoat( mdl ) or IsThisModelAHeli( mdl ) or IsThisModelAPlane( mdl ) ) then
			self:SetVehicleValidity( key, false )
			return false
		else
			self:SetVehicleValidity( key, true )
			return true
		end
	end

	return valid
end

-- Gathers all of the vehicles in the local area of the player
function RADAR:GetAllVehicles()
	-- Create a temporary table
	local t = {}

	-- Iterate through vehicles
	for v in UTIL:EnumerateVehicles() do
		if ( self:IsVehicleValid( v ) ) then
			-- Insert the vehicle id into the temporary table
			table.insert( t, v )
		end
	end

	-- Return the table
	return t
end

-- Used to check if an antennas mode fits with a ray type from the ray trace system
function RADAR:CheckVehicleDataFitsMode( ant, rt )
	-- Get the current mode value for the given antenna
	local mode = self:GetAntennaMode( ant )

	-- Check that the given ray type matches up with the antenna's current mode
	if ( ( mode == 3 ) or ( mode == 1 and rt == "same" ) or ( mode == 2 and rt == "opp" ) ) then return true end

	-- Otherwise, return false as a last resort
	return false
end

-- This function is used to filter through the captured vehicles and work out what vehicles should be used for display
-- on the radar interface
function RADAR:GetVehiclesForAntenna()
	-- Create the vehs table to store the split up captured vehicle data
	local vehs = { ["front"] = {}, ["rear"] = {} }

	-- Create the results table to store the vehicle results, the first index is for the 'strongest' vehicle and the
	-- second index is for the 'fastest' vehicle
	local results = { ["front"] = { nil, nil }, ["rear"] = { nil, nil } }

	-- Loop through and split up the vehicles based on front and rear, this is simply because the actual system
	-- that gets all of the vehicles hit by the radar only has a relative position of either 1 or -1, which we
	-- then convert below into an antenna string!
	for ant in UTIL:Values( { "front", "rear" } ) do
		-- Check that the antenna is actually transmitting
		if ( self:IsAntennaTransmitting( ant ) ) then
			-- Iterate through the captured vehicles
			for k, v in pairs( self:GetCapturedVehicles() ) do
				-- Convert the relative position to antenna text
				local antText = self:GetAntennaTextFromNum( v.relPos )

				-- Check the current vehicle's relative position is the same as the current antenna
				if ( ant == antText ) then
					-- Insert the vehicle into the table for the current antenna
					table.insert( vehs[ant], v )
				end
			end

			-- As the radar is based on how the real Stalker DSR 2X works, we now sort the dataset by
			-- the 'strongest' (largest) target, this way the first result for the front and rear data
			-- will be the one that gets displayed in the target boxes.
			table.sort( vehs[ant], self:GetStrongestSortFunc() )
		end
	end

	-- Now that we have all of the vehicles split into front and rear, we can iterate through both sets and get
	-- the strongest and fastest vehicle for display
	for ant in UTIL:Values( { "front", "rear" } ) do
		-- Check that the table for the current antenna is not empty
		if ( not UTIL:IsTableEmpty( vehs[ant] ) ) then
			-- Get the 'strongest' vehicle for the antenna
			for k, v in pairs( vehs[ant] ) do
				-- Check if the current vehicle item fits the mode set by the user
				if ( self:CheckVehicleDataFitsMode( ant, v.rayType ) ) then
					-- Set the result for the current antenna
					results[ant][1] = v
					break
				end
			end

			-- Here we get the vehicle for the fastest section, but only if the user has the fast mode enabled
			-- in the operator menu
			if ( self:IsFastDisplayEnabled() ) then
				-- Get the 'fastest' vehicle for the antenna
				table.sort( vehs[ant], self:GetFastestSortFunc() )

				-- Create a temporary variable for the first result, reduces line length
				local temp = results[ant][1]

				-- Iterate through the vehicles for the current antenna
				for k, v in pairs( vehs[ant] ) do
					-- When we grab a vehicle for the fastest section, as it is like how the real system works, there are a few
					-- additional checks that have to be made
					if ( self:CheckVehicleDataFitsMode( ant, v.rayType ) and v.veh ~= temp.veh and v.size < temp.size and v.speed > temp.speed + 1.0 ) then
						-- Set the result for the current antenna
						results[ant][2] = v
						break
					end
				end
			end
		end
	end

	-- Return the results
	return { ["front"] = { results["front"][1], results["front"][2] }, ["rear"] = { results["rear"][1], results["rear"][2] } }
end


--[[----------------------------------------------------------------------------------
	NUI callback
----------------------------------------------------------------------------------]]--
-- Runs when the "Toggle Display" button is pressed on the remote control
RegisterNUICallback( "toggleRadarDisplay", function( data, cb )
	-- Toggle the display state
	RADAR:ToggleDisplayState()
	cb( "ok" )
end )

-- Runs when the user presses the power button on the radar ui
RegisterNUICallback( "togglePower", function( data, cb )
	if ( PLY:CanControlRadar() ) then
		if ( not RADAR:IsPoweringUp() ) then
			-- Toggle the radar's power
			RADAR:SetPowerState( not RADAR:IsPowerOn(), false )

			SYNC:SendPowerState( RADAR:IsPowerOn() )
		end
	end

	cb( "ok" )
end )

-- Runs when the user presses the ESC or RMB when the remote is open
RegisterNUICallback( "closeRemote", function( data, cb )
	-- Remove focus to the NUI side
	SetNuiFocus( false, false )

	if ( RADAR:IsMenuOpen() ) then
		RADAR:CloseMenu( false )
	end

	SYNC:SetRemoteOpenState( false )

	cb( "ok" )
end )

-- Runs when the user presses any of the antenna mode buttons on the remote
RegisterNUICallback( "setAntennaMode", function( data, cb )
	if ( PLY:CanControlRadar() ) then
		-- Only run the codw if the radar has power and is not powering up
		if ( RADAR:IsPowerOn() and not RADAR:IsPoweringUp() ) then
			-- As the mode buttons are used to exit the menu, we check for that
			if ( RADAR:IsMenuOpen() ) then
				RADAR:CloseMenu()
			else
				-- Change the mode for the designated antenna, pass along a callback which contains data from this NUI callback
				RADAR:SetAntennaMode( data.value, tonumber( data.mode ) )

				-- Sync
				SYNC:SendAntennaMode( data.value, tonumber( data.mode ) )
			end
		end
	end

	cb( "ok" )
end )

-- Runs when the user presses either of the XMIT/HOLD buttons on the remote
RegisterNUICallback( "toggleAntenna", function( data, cb )
	if ( PLY:CanControlRadar() ) then
		-- Only run the codw if the radar has power and is not powering up
		if ( RADAR:IsPowerOn() and not RADAR:IsPoweringUp() ) then
			-- As the xmit/hold buttons are used to change settings in the menu, we check for that
			if ( RADAR:IsMenuOpen() ) then
				-- Change the menu option based on which button is pressed
				RADAR:ChangeMenuOption( data.value )

				-- Play a beep noise
				SendNUIMessage( { _type = "audio", name = "beep", vol = RADAR:GetSettingValue( "beep" ) } )
			else
				-- Toggle the transmit state for the designated antenna, pass along a callback which contains data from this NUI callback
				RADAR:ToggleAntenna( data.value )

				-- Sync
				SYNC:SendAntennaPowerState( RADAR:IsAntennaTransmitting( data.value ), data.value )
			end
		end
	end

	cb( "ok" )
end )

-- Runs when the user presses the menu button on the remote control
RegisterNUICallback( "menu", function( data, cb )
	if ( PLY:CanControlRadar() ) then
		-- Only run the codw if the radar has power and is not powering up
		if ( RADAR:IsPowerOn() and not RADAR:IsPoweringUp() ) then
			-- As the menu button is a multipurpose button, we first check to see if the menu is already open
			if ( RADAR:IsMenuOpen() ) then
				-- As the menu is already open, we then iterate to the next option in the settings list
				RADAR:ChangeMenuIndex()
			else
				-- Set the menu state to open, which will prevent anything else within the radar from working
				RADAR:SetMenuState( true )

				-- Send an update to the NUI side
				RADAR:SendMenuUpdate()
			end

			-- Play the standard audio beep
			SendNUIMessage( { _type = "audio", name = "beep", vol = RADAR:GetSettingValue( "beep" ) } )
		end
	end

	cb( "ok" )
end )

-- Runs when the JavaScript side sends the UI data for saving
RegisterNUICallback( "saveUiData", function( data, cb )
	UTIL:Log( "Saving updated UI settings data." )
	SetResourceKvp( "wk_wars2x_ui_data", json.encode( data ) )
	cb( "ok" )
end )

-- Runs when the JavaScript side sends the quick start video has been watched
RegisterNUICallback( "qsvWatched", function( data, cb )
	SetResourceKvpInt( "wk_wars2x_new_user", 1 )
	cb( "ok" )
end )


--[[----------------------------------------------------------------------------------
	Main threads
----------------------------------------------------------------------------------]]--
-- Some people might not like the idea of the resource having a CPU MSEC over 0.10, but due to the functions
-- and the way the whole radar system works, it will use over 0.10 a decent amount. In this function, we
-- dynamically adjust the wait time in the main thread, so that when the player is driving their vehicle and
-- moving, the system doesn't run as fast so as to use less CPU time. When they have their vehicle
-- stationary, the system runs more often, which means that if a situation occurs such as a vehicle flying
-- past them at a high rate of speed, the system will be able to pick it up as it is running faster. Also, as
-- the user is stationary, if the system takes up an additional one or two frames per second, it won't really
-- be noticeable.
function RADAR:RunDynamicThreadWaitCheck()
	-- Get the speed of the local players vehicle
	local speed = self:GetPatrolSpeed()

	-- Check that the vehicle speed is less than 0.1
	if ( speed < 0.1 ) then
		-- Change the thread wait time to 200 ms, the trace system will now run five times per second
		self:SetThreadWaitTime( 200 )
	else
		-- Change the thread wait time to 500 ms, the trace system will now run two times a second
		self:SetThreadWaitTime( 500 )
	end
end

-- Create the thread that will run the dynamic thread wait check, this check only runs every two seconds
Citizen.CreateThread( function()
	while ( true ) do
		-- Run the function
		RADAR:RunDynamicThreadWaitCheck()

		-- Make the thread wait two seconds
		Citizen.Wait( 2000 )
	end
end )

-- This function handles the custom ray trace system that is used to gather all of the vehicles hit by
-- the ray traces defined in RADAR.rayTraces.
function RADAR:RunThreads()
	-- For the system to even run, the player needs to be sat in the driver's seat of a class 18 vehicle, the
	-- radar has to be visible and the power must be on, and either one of the antennas must be enabled.
	if ( PLY:CanViewRadar() and self:CanPerformMainTask() and self:IsEitherAntennaOn() ) then
		-- Before we create any of the custom ray trace threads, we need to make sure that the ray trace state
		-- is at zero, if it is not at zero, then it means the system is still currently tracing
		if ( self:GetRayTraceState() == 0 ) then
			-- Grab a copy of the vehicle pool
			local vehs = self:GetVehiclePool()

			-- Reset the main captured vehicles table
			self:ResetCapturedVehicles()

			-- Here we run the function that creates all of the main ray threads
			self:CreateRayThreads( PLY.veh, vehs )

			-- Make the thread this function runs in wait the dynamic time defined by the system
			Citizen.Wait( self:GetThreadWaitTime() )

		-- If the current ray trace state is the same as the total number of rays, then we reset the ray trace
		-- state back to 0 so the thread system can run again
		elseif ( self:GetRayTraceState() == self:GetNumOfRays() ) then
			-- Reset the ray trace state to 0
			self:ResetRayTraceState()
		end
	end
end

-- Create the main thread that will run the threads function, the function itself is run every frame as the
-- dynamic wait time is ran inside the function
Citizen.CreateThread( function()
	while ( true ) do
		-- Run the function
		RADAR:RunThreads()

		-- Make the thread wait 0 ms
		Citizen.Wait( 0 )
	end
end )

-- This is the main function that runs and handles all information that is sent to the NUI side for display, all
-- speed values are converted on the Lua side into a format that is displayable using the custom font on the NUI side
function RADAR:Main()
	-- Only run any of the main code if all of the states are met, player in the driver's seat of a class 18 vehicle, and
	-- the system has to be able to perform main tasks
	if ( PLY:CanViewRadar() and self:CanPerformMainTask() ) then
		-- Create a table that will be used to store all of the data to be sent to the NUI side
		local data = {}

		-- Get the player's vehicle speed
		local entSpeed = GetEntitySpeed( PLY.veh )

		-- Set the internal patrol speed to the speed obtained above, this is then used in the dynamic thread wait calculation
		self:SetPatrolSpeed( entSpeed )

		-- Change what is displayed in the patrol speed box on the radar interface depending on if the players vehicle is
		-- stationary or moving
		if ( entSpeed == 0 ) then
			data.patrolSpeed = "¦[]"
		else
			local speed = self:GetVehSpeedConverted( entSpeed )
			data.patrolSpeed = UTIL:FormatSpeed( speed )
		end

		-- Get the vehicles to be displayed for the antenna, then we take the results from that and send the relevant
		-- information to the NUI side
		local av = self:GetVehiclesForAntenna()
		data.antennas = { ["front"] = nil, ["rear"] = nil }

		-- Iterate through the front and rear data and obtain the information to be displayed
		for ant in UTIL:Values( { "front", "rear" } ) do
			-- Check that the antenna is actually transmitting, no point in running all the checks below if the antenna is off
			if ( self:IsAntennaTransmitting( ant ) ) then
				-- Create a table for the current antenna to store the information
				data.antennas[ant] = {}

				-- When the system works out what vehicles to be used, both the "front" and "rear" keys have two items located
				-- at index 1 and 2. Index 1 stores the vehicle data for the antenna's 'strongest' vehicle, and index 2 stores
				-- the vehicle data for the 'fastest' vehicle. Here we iterate through both the indexes and just run checks to
				-- see if it is a particular type (e.g. if i % 2 == 0 then it's the 'fastest' vehicle)
				for i = 1, 2 do
					-- Create the table to store the speed and direction for this vehicle data
					data.antennas[ant][i] = { speed = "¦¦¦", dir = 0 }

					-- If the current iteration is the number 2 ('fastest') and there's a speed locked, grab the locked speed
					-- and direction
					if ( i == 2 and self:IsAntennaSpeedLocked( ant ) ) then
						data.antennas[ant][i].speed = self:GetAntennaLockedSpeed( ant )
						data.antennas[ant][i].dir = self:GetAntennaLockedDir( ant )

					-- Otherwise, continue with getting speed and direction data
					else
						-- The vehicle data exists for this slot
						if ( av[ant][i] ~= nil ) then
							-- Here we get the entity speed of the vehicle, the speed for this vehicle would've been obtained
							-- and stored in the trace stage, but the speed would've only been obtained and stored once, which
							-- means that it woulsn't be the current speed
							local vehSpeed = GetEntitySpeed( av[ant][i].veh )
							local convertedSpeed = self:GetVehSpeedConverted( vehSpeed )
							data.antennas[ant][i].speed = UTIL:FormatSpeed( convertedSpeed )

							-- Work out if the vehicle is closing or away
							local ownH = UTIL:Round( GetEntityHeading( PLY.veh ), 0 )
							local tarH = UTIL:Round( GetEntityHeading( av[ant][i].veh ), 0 )
							data.antennas[ant][i].dir = UTIL:GetEntityRelativeDirection( ownH, tarH )

							-- Set the internal antenna data as this actual dataset is valid
							if ( i % 2 == 0 ) then
								self:SetAntennaFastData( ant, data.antennas[ant][i].speed, data.antennas[ant][i].dir )
							else
								self:SetAntennaData( ant, data.antennas[ant][i].speed, data.antennas[ant][i].dir )
							end

							-- Lock the speed automatically if the fast limit system is allowed
							if ( self:IsFastLimitAllowed() ) then
								-- Make sure the speed is larger than the limit, and that there isn't already a locked speed
								if ( self:IsFastLockEnabled() and convertedSpeed > self:GetFastLimit() and not self:IsAntennaSpeedLocked( ant ) ) then
									if ( ( self:OnlyLockFastPlayers() and UTIL:IsPlayerInVeh( av[ant][i].veh ) ) or not self:OnlyLockFastPlayers() ) then
										if ( PLY:IsDriver() ) then
											self:LockAntennaSpeed( ant, nil, false )
											SYNC:LockAntennaSpeed( ant, RADAR:GetAntennaDataPacket( ant ) )
										end
									end
								end
							end
						else
							-- If the active vehicle is not valid, we reset the internal data
							if ( i % 2 == 0 ) then
								self:SetAntennaFastData( ant, nil, nil )
							else
								self:SetAntennaData( ant, nil, nil )
							end
						end
					end
				end
			end
		end

		-- Send the update to the NUI side
		SendNUIMessage( { _type = "update", speed = data.patrolSpeed, antennas = data.antennas } )
	end
end

-- Main thread
Citizen.CreateThread( function()
	-- Remove the NUI focus just in case
	SetNuiFocus( false, false )

	-- Run the function to cache the number of rays, this way a hard coded number is never needed
	RADAR:CacheNumRays()

	-- Update the end coordinates for the ray traces based on the config, again, reduced hard coding
	RADAR:UpdateRayEndCoords()

	-- If the fast limit feature is allowed, create the config in the radar variables
	if ( RADAR:IsFastLimitAllowed() ) then
		RADAR:CreateFastLimitConfig()
	end

	-- Register the key binds
	RegisterKeyBinds()

	-- Wait a short period of time
	Citizen.Wait( 1000 )

	-- Load the saved UI settings (if available)
	LoadUISettings()

	-- Set the player's remoteOpen decorator to false
	DecorSetBool( PlayerPedId(), "wk_wars2x_sync_remoteOpen", false )

	-- Update the operator menu positions
	RADAR:UpdateOptionIndexes( true )

	-- Run the main radar function
	while ( true ) do
		RADAR:Main()

		Citizen.Wait( 100 )
	end
end )

-- This function is pretty much straight from WraithRS, it does the job so I didn't see the point in not
-- using it. Hides the radar UI when certain criteria is met, e.g. in pause menu or stepped out ot the
-- patrol vehicle
function RADAR:RunDisplayValidationCheck()
	if ( ( ( PLY.veh == 0 or ( PLY.veh > 0 and not PLY.vehClassValid ) ) and self:GetDisplayState() and not self:GetDisplayHidden() ) or IsPauseMenuActive() and self:GetDisplayState() ) then
		self:SetDisplayHidden( true )
		SendNUIMessage( { _type = "setRadarDisplayState", state = false } )
	elseif ( PLY:CanViewRadar() and self:GetDisplayState() and self:GetDisplayHidden() ) then
		self:SetDisplayHidden( false )
		SendNUIMessage( { _type = "setRadarDisplayState", state = true } )
	end
end

-- Runs the display validation check for the radar
Citizen.CreateThread( function()
	Citizen.Wait( 100 )

	while ( true ) do
		-- Run the check
		RADAR:RunDisplayValidationCheck()

		-- Wait half a second
		Citizen.Wait( 500 )
	end
end )

-- Update the vehicle pool every 3 seconds
function RADAR:UpdateVehiclePool()
	-- Only update the vehicle pool if we need to
	if ( PLY:CanViewRadar() and self:CanPerformMainTask() and self:IsEitherAntennaOn() ) then
		-- Get the active vehicle set
		local vehs = self:GetAllVehicles()

		-- Update the vehicle pool
		self:SetVehiclePool( vehs )
	end
end

-- Runs the vehicle pool updater
Citizen.CreateThread( function()
	while ( true ) do
		-- Update the vehicle pool
		RADAR:UpdateVehiclePool()

		-- Wait 3 seconds
		Citizen.Wait( 3000 )
	end
end )