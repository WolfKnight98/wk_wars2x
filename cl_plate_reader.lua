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

READER = {}

--[[----------------------------------------------------------------------------------
	Plate reader variables

	NOTE - This is not a config, do not touch anything unless you know what
	you are actually doing.
----------------------------------------------------------------------------------]]--
READER.vars =
{
	-- Whether or not the plate reader's UI is visible
	displayed = false,

	-- Whether or not the plate reader should be hidden, e.g. the display is active but the player then steps
	-- out of their vehicle
	hidden = false,

	-- The BOLO plate
	boloPlate = "",

	-- Cameras, this table contains all of the data needed for operation of the front and rear plate reader
	cams = {
		-- Variables for the front camera
		["front"] = {
			plate = "",     -- The current plate caught by the reader
			index = "",     -- The index of the current plate
			locked = false  -- If the reader is locked
		},

		-- Variables for the rear camera
		["rear"] = {
			plate = "",     -- The current plate caught by the reader
			index = "",     -- The index of the current plate
			locked = false  -- If the reader is locked
		}
	}
}


--[[----------------------------------------------------------------------------------
	Plate reader functions
----------------------------------------------------------------------------------]]--
-- Gets the display state
function READER:GetDisplayState()
	return self.vars.displayed
end

-- Toggles the display state of the plate reader system
function READER:ToggleDisplayState()
	-- Toggle the display variable
	self.vars.displayed = not self.vars.displayed

	-- Send the toggle message to the NUI side
	SendNUIMessage( { _type = "setReaderDisplayState", state = self:GetDisplayState() } )
end

-- Getter and setter for the display hidden state
function READER:GetDisplayHidden() return self.vars.hidden end
function READER:SetDisplayHidden( state ) self.vars.hidden = state end

-- Getter and setter for the given camera's plate
function READER:GetPlate( cam )	return self.vars.cams[cam].plate end
function READER:SetPlate( cam, plate ) self.vars.cams[cam].plate = plate end

-- Getter and setter for the given camera's plate display index
function READER:GetIndex( cam ) return self.vars.cams[cam].index end
function READER:SetIndex( cam, index ) self.vars.cams[cam].index = index end

-- Returns the bolo plate
function READER:GetBoloPlate()
	if ( self.vars.boloPlate ~= nil ) then
		return self.vars.boloPlate
	end
end

-- Sets the bolo plate to the given plate
function READER:SetBoloPlate( plate )
	self.vars.boloPlate = plate
	UTIL:Notify( "BOLO plate set to: ~b~" .. plate )
end

-- Clears the BOLO plate
function READER:ClearBoloPlate()
	self.vars.boloPlate = nil
	UTIL:Notify( "~b~BOLO plate cleared!" )
end

-- Returns if the given reader is locked
function READER:GetCamLocked( cam )	return self.vars.cams[cam].locked end

-- Locks the given reader
function READER:LockCam( cam, playBeep, isBolo, override )
	-- Check that plate readers can actually be locked
	if ( PLY:VehicleStateValid() and self:CanPerformMainTask() and self:GetPlate( cam ) ~= "" ) then
		-- Toggle the lock state
		self.vars.cams[cam].locked = not self.vars.cams[cam].locked

		-- Play a beep
		if ( self:GetCamLocked( cam ) ) then
			-- Here we check if the override parameter is valid, if so then we set the reader's plate data to the
			-- plate data provided in the override table.
			if ( override ~= nil ) then
				self:SetPlate( cam, override[1] )
				self:SetIndex( cam, override[2] )

				self:ForceNUIUpdate( false )
			end

			if ( playBeep ) then
				SendNUIMessage( { _type = "audio", name = "beep", vol = RADAR:GetSettingValue( "plateAudio" ) } )
			end

			if ( isBolo ) then
				SendNUIMessage( { _type = "audio", name = "plate_hit", vol = RADAR:GetSettingValue( "plateAudio" ) } )
			end

			-- Trigger an event so developers can hook into the scanner every time a plate is locked
			TriggerServerEvent( "wk:onPlateLocked", cam, self:GetPlate( cam ), self:GetIndex( cam ) )
		end

		-- Tell the NUI side to show/hide the lock icon
		SendNUIMessage( { _type = "lockPlate", cam = cam, state = self:GetCamLocked( cam ), isBolo = isBolo } )
	end
end

-- Returns if the plate reader system can perform tasks
function READER:CanPerformMainTask()
	return self.vars.displayed and not self.vars.hidden
end

-- Returns if the given relative position value is for front or rear
function READER:GetCamFromNum( relPos )
	if ( relPos == 1 ) then
		return "front"
	elseif ( relPos == -1 ) then
		return "rear"
	end
end

-- Forces an NUI update, used by the passenger control system
function READER:ForceNUIUpdate( lock )
	for cam in UTIL:Values( { "front", "rear" } ) do
		local plate = self:GetPlate( cam )
		local index = self:GetIndex( cam )

		if ( plate ~= "" and index ~= "" ) then
			SendNUIMessage( { _type = "changePlate", cam = cam, plate = plate, index = index } )

			if ( lock ) then
				SendNUIMessage( { _type = "lockPlate", cam = cam, state = self:GetCamLocked( cam ), isBolo = false } )
			end
		end
	end
end

-- Returns a table with both antenna's speed data and directions
function READER:GetCameraDataPacket( cam )
	return {
		self:GetPlate( cam ),
		self:GetIndex( cam )
	}
end

RegisterNetEvent( "wk:togglePlateLock" )
AddEventHandler( "wk:togglePlateLock", function( cam, beep, bolo )
	READER:LockCam( cam, beep, bolo )
end )


--[[----------------------------------------------------------------------------------
	Plate reader NUI callbacks
----------------------------------------------------------------------------------]]--
-- Runs when the "Toggle Display" button is pressed on the plate reder box
RegisterNUICallback( "togglePlateReaderDisplay", function( data, cb )
	-- Toggle the display state
	READER:ToggleDisplayState()
	cb( "ok" )
end )

-- Runs when the "Set BOLO Plate" button is pressed on the plate reader box
RegisterNUICallback( "setBoloPlate", function( plate, cb )
	-- Set the BOLO plate
	READER:SetBoloPlate( plate )
	cb( "ok" )
end )

-- Runs when the "Clear BOLO Plate" button is pressed on the plate reader box
RegisterNUICallback( "clearBoloPlate", function( plate, cb )
	-- Clear the BOLO plate
	READER:ClearBoloPlate()
	cb( "ok" )
end )


--[[----------------------------------------------------------------------------------
	Plate reader threads
----------------------------------------------------------------------------------]]--
-- This is the main function that runs and scans all vehicles in front and behind the patrol vehicle
function READER:Main()
	-- Check that the system can actually run
	if ( PLY:VehicleStateValid() and self:CanPerformMainTask() ) then
		-- Loop through front (1) and rear (-1)
		for i = 1, -1, -2 do
			-- Get the world position of the player's vehicle
			local pos = GetEntityCoords( PLY.veh )

			-- Get a start position 5m in front/behind the player's vehicle
			local start = GetOffsetFromEntityInWorldCoords( PLY.veh, 0.0, ( 5.0 * i ), 0.0 )

			-- Get the end position 50m in front/behind the player's vehicle
			local offset = GetOffsetFromEntityInWorldCoords( PLY.veh, -2.5, ( 50.0 * i ), 0.0 )

			-- Run the ray trace to get a vehicle
			local veh = UTIL:GetVehicleInDirection( PLY.veh, start, offset )

			-- Get the plate reader text for front/rear
			local cam = self:GetCamFromNum( i )

			-- Only proceed to read a plate if the hit entity is a valid vehicle and the current camera isn't locked
			if ( DoesEntityExist( veh ) and IsEntityAVehicle( veh ) and not self:GetCamLocked( cam ) ) then
				-- Get the heading of the player's vehicle and the hit vehicle
				local ownH = UTIL:Round( GetEntityHeading( PLY.veh ), 0 )
				local tarH = UTIL:Round( GetEntityHeading( veh ), 0 )

				-- Get the relative direction between the player's vehicle and the hit vehicle
				local dir = UTIL:GetEntityRelativeDirection( ownH, tarH )

				-- Only run the rest of the plate check code if we can see the front or rear of the vehicle
				if ( dir > 0 ) then
					-- Get the licence plate text from the vehicle
					local plate = GetVehicleNumberPlateText( veh )

					-- Get the licence plate index from the vehicle
					local index = GetVehicleNumberPlateTextIndex( veh )

					-- Only update the stored plate if it's different, otherwise we'd keep sending a NUI message to update the displayed
					-- plate and image even though they're the same
					if ( self:GetPlate( cam ) ~= plate ) then
						-- Set the plate for the current reader
						self:SetPlate( cam, plate )

						-- Set the plate index for the current reader
						self:SetIndex( cam, index )

						-- Automatically lock the plate if the scanned plate matches the BOLO
						if ( plate == self:GetBoloPlate() ) then
							self:LockCam( cam, false, true )

							SYNC:LockReaderCam( cam, READER:GetCameraDataPacket( cam ) )
						end

						-- Send the plate information to the NUI side to update the UI
						SendNUIMessage( { _type = "changePlate", cam = cam, plate = plate, index = index } )

						-- If we use Sonoran CAD, reduce the plate events to just player's vehicle, otherwise life as normal
						if ( ( CONFIG.use_sonorancad and ( UTIL:IsPlayerInVeh( veh ) or IsVehiclePreviouslyOwnedByPlayer( veh ) ) and GetVehicleClass( veh ) ~= 18 ) or not CONFIG.use_sonorancad ) then
							-- Trigger the event so developers can hook into the scanner every time a plate is scanned
							TriggerServerEvent( "wk:onPlateScanned", cam, plate, index )
						end
					end
				end
			end
		end
	end
end

-- Main thread
Citizen.CreateThread( function()
	while ( true ) do
		-- Run the main plate reader function
		READER:Main()

		-- Wait half a second
		Citizen.Wait( 500 )
	end
end )

-- This function is pretty much straight from WraithRS, it does the job so I didn't see the point in not
-- using it. Hides the radar UI when certain criteria is met, e.g. in pause menu or stepped out ot the
-- patrol vehicle
function READER:RunDisplayValidationCheck()
	if ( ( ( PLY.veh == 0 or ( PLY.veh > 0 and not PLY.vehClassValid ) ) and self:GetDisplayState() and not self:GetDisplayHidden() ) or IsPauseMenuActive() and self:GetDisplayState() ) then
		self:SetDisplayHidden( true )
		SendNUIMessage( { _type = "setReaderDisplayState", state = false } )
	elseif ( PLY:CanViewRadar() and self:GetDisplayState() and self:GetDisplayHidden() ) then
		self:SetDisplayHidden( false )
		SendNUIMessage( { _type = "setReaderDisplayState", state = true } )
	end
end

-- Runs the display validation check for the radar
Citizen.CreateThread( function()
	Citizen.Wait( 100 )

	while ( true ) do
		-- Run the check
		READER:RunDisplayValidationCheck()

		-- Wait half a second
		Citizen.Wait( 500 )
	end
end )