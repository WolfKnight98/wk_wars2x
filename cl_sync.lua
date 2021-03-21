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

-- Register the decorator used to tell if the other player has the remote open
DecorRegister( "wk_wars2x_sync_remoteOpen", 2 )

-- Takes the given backup functions and restores the data
local function RestoreData( obj, getFunc, setFunc, setBackupFunc, key )
	if ( key ~= nil ) then
		local data = getFunc( obj, key )

		if ( data ~= nil ) then
			setFunc( obj, key, data )
			setBackupFunc( obj, key, nil )
		end
	else
		local data = getFunc( obj )

		if ( data ~= nil ) then
			setFunc( obj, data )
			setBackupFunc( obj, nil )
		end
	end
end


--[[----------------------------------------------------------------------------------
	Plate reader sync variables and functions
----------------------------------------------------------------------------------]]--
-- Declares a table that is used to backup the player's plate reader data
READER.backupData =
{
	cams = {
		["front"] = nil,
		["rear"] = nil
	}
}

-- Returns a table with the front and rear plate reader data
function READER:GetReaderDataForSync()
	return {
		["front"] = self.vars.cams["front"],
		["rear"] = self.vars.cams["rear"]
	}
end

-- Sets the internal plate reader data for the given camera
function READER:SetReaderCamData( cam, data )
	if ( type( data ) == "table" ) then
		self.vars.cams[cam] = data
	end
end

-- Getter and setter for the backup plate reader data
function READER:GetBackupReaderData( cam ) return self.backupData.cams[cam] end
function READER:SetBackupReaderData( cam, data ) self.backupData.cams[cam] = data end

-- Returns if there is any backup data for the plate reader
function READER:IsThereBackupData()
	return self:GetBackupReaderData( "front" ) ~= nil or self:GetBackupReaderData( "rear" ) ~= nil
end

-- Backs up the player's plate reader data
function READER:BackupData()
	-- Get the player's data
	local data = self:GetReaderDataForSync()

	-- Iterate through the front and rear camera
	for cam in UTIL:Values( { "front", "rear" } ) do
		-- Check that there isn't already backup data, then if not, back up the player's data
		if ( self:GetBackupReaderData( cam ) == nil ) then
			self:SetBackupReaderData( cam, data[cam] )
		end
	end
end

-- Replaces the internal plate reader data with the data provided
function READER:LoadDataFromDriver( data )
	-- Backup the local data first
	self:BackupData()

	-- As a precaution, give the system 50ms before it replaces the local data with the data from the driver
	Citizen.SetTimeout( 50, function()
		-- Set the camera data
		for cam in UTIL:Values( { "front", "rear" } ) do
			self:SetReaderCamData( cam, data[cam] )
		end

		-- Force the NUI side to update the plate reader display with the new data
		self:ForceNUIUpdate( true )
	end )
end

-- Restores the backed up plate reader data
function READER:RestoreFromBackup()
	-- Iterate through the cameras and restore their backups
	for cam in UTIL:Values( { "front", "rear" } ) do
		RestoreData( READER, READER.GetBackupReaderData, READER.SetReaderCamData, READER.SetBackupReaderData, cam )
	end

	-- Force the NUI side to update the plate reader display with the restored data
	self:ForceNUIUpdate( true )
end


--[[----------------------------------------------------------------------------------
	Radar sync variables and functions
----------------------------------------------------------------------------------]]--
-- Declares a table that is used to backup the player's radar data
RADAR.backupData = {
	power = nil,
	om = nil,
	antennas = {
		["front"] = nil,
		["rear"] = nil
	}
}

-- Returns a table with the power state, operator meny, front and rear radar data
function RADAR:GetRadarDataForSync()
	return {
		power = self.vars.power,
		om = self.vars.settings,
		["front"] = self.vars.antennas["front"],
		["rear"] = self.vars.antennas["rear"]
	}
end

-- Returns the radar's internal operator menu settings table
function RADAR:GetOMTableData()	return self.vars.settings end

-- Sets the operator menu settings table within the radar's main variables table
function RADAR:SetOMTableData( data )
	if ( type( data ) == "table" ) then
		self.vars.settings = data
		self:UpdateOptionIndexes( false )
	end
end

-- Sets the antenna settings table for the given antenna within the radar's main variables table
function RADAR:SetAntennaTableData( ant, data )
	if ( type( data ) == "table" ) then
		self.vars.antennas[ant] = data
	end
end

-- Getter and setter for the backup radar power state
function RADAR:GetBackupPowerState() return self.backupData.power end
function RADAR:SetBackupPowerState( state ) self.backupData.power = state end

-- Getter and setter for the backup radar operator menu data
function RADAR:GetBackupOMData() return self.backupData.om end
function RADAR:SetBackupOMData( data ) self.backupData.om = data end

-- Getter and setter for the backup radar antennas data
function RADAR:GetBackupAntennaData( ant ) return self.backupData.antennas[ant] end
function RADAR:SetBackupAntennaData( ant, data ) self.backupData.antennas[ant] = data end

-- Retuns if there is any backup radar data
function RADAR:IsThereBackupData()
	return self:GetBackupOMData() ~= nil or self:GetBackupAntennaData( "front" ) ~= nil or self:GetBackupAntennaData( "rear" ) ~= nil
end

-- Used when the player becomes a passenger in another vehicle. The local data is backed up to make way for the data
-- provided by the driver. When the player becomes the driver again, the local data is restored.
function RADAR:BackupData()
	local data = self:GetRadarDataForSync()

	-- Backup the power state
	if ( self:GetBackupPowerState() == nil ) then
		self:SetBackupPowerState( data.power )
	end

	-- Backup operator menu data
	if ( self:GetBackupOMData() == nil ) then
		self:SetBackupOMData( data.om )
	end

	-- Only backup the radar data if the player has the power on. There's no point backing up the data as it'll just
	-- get reset when they turn the power on anyway
	if ( data.power ) then
		-- Backup front and rear antenna data
		for ant in UTIL:Values( { "front", "rear" } ) do
			if ( self:GetBackupAntennaData( ant ) == nil ) then
				self:SetBackupAntennaData( ant, data[ant] )
			end
		end
	end
end

-- Backs up the local radar data and then replaces it with the data provided by the driver
function RADAR:LoadDataFromDriver( data )
	-- Backup the local data first
	self:BackupData()

	-- As a precaution, give the system 50ms before it replaces the local data with the data from the driver
	Citizen.SetTimeout( 50, function()
		-- Set the operator menu settings
		self:SetOMTableData( data.om )

		-- Set the antenna data
		for ant in UTIL:Values( { "front", "rear" } ) do
			self:SetAntennaTableData( ant, data[ant] )
		end

		-- Set the power state
		self:SetPowerState( data.power, true )

		-- Update the display
		if ( data.power ) then
			self:SendSettingUpdate()
		end
	end )
end

-- Restores the local player's operator menu and antenna data
function RADAR:RestoreFromBackup()
	-- Restore the operator menu data
	RestoreData( RADAR, RADAR.GetBackupOMData, RADAR.SetOMTableData, RADAR.SetBackupOMData )

	-- Iterate through the antennas and restore their backups
	for ant in UTIL:Values( { "front", "rear" } ) do
		RestoreData( RADAR, RADAR.GetBackupAntennaData, RADAR.SetAntennaTableData, RADAR.SetBackupAntennaData, ant )
	end

	-- Get the power state
	local pwrState = self:GetBackupPowerState()

	-- Restore the power state
	if ( pwrState ~= nil ) then
		self:SetPowerState( pwrState, true )
		self:SetBackupPowerState( nil )
	end

	-- Update the display
	if ( pwrState ) then
		Citizen.SetTimeout( 50, function()
			self:SendSettingUpdate()
		end )
	end
end


--[[----------------------------------------------------------------------------------
	Sync variables
----------------------------------------------------------------------------------]]--
SYNC = {}


--[[----------------------------------------------------------------------------------
	Sync functions
----------------------------------------------------------------------------------]]--
-- Returns if the given player has the remote open
function SYNC:IsRemoteAlreadyOpen( ply )
	if ( not RADAR:IsPassengerViewAllowed() ) then
		return false
	else
		return DecorGetBool( ply, "wk_wars2x_sync_remoteOpen" )
	end
end

-- Sets the remote open decor for the local player to the given state
function SYNC:SetRemoteOpenState( state )
	if ( RADAR:IsPassengerViewAllowed() ) then
		DecorSetBool( PLY.ped, "wk_wars2x_sync_remoteOpen", state )
	end
end

-- Used to get the other ped (driver/passenger) in a vehicle and calls the given callback. This function will only work
-- if the player can control the radar, it also ensures that the other ped (if found) exists and is a player. The other
-- player's server ID is passed to the given callback as an argument.
function SYNC:SyncData( cb )
	if ( PLY:CanControlRadar() ) then
		local otherPly = PLY:GetOtherPedServerId()

		if ( otherPly ~= nil ) then
			cb( otherPly )
		end
	end
end

-- Sends the radar's power state to the other player (driver/passenger)
function SYNC:SendPowerState( state )
	self:SyncData( function( ply )
		TriggerServerEvent( "wk_wars2x_sync:sendPowerState", ply, state )
	end )
end

-- Sends the power state for the given antenna to the other player (driver/passenger)
function SYNC:SendAntennaPowerState( state, ant )
	self:SyncData( function( ply )
		TriggerServerEvent( "wk_wars2x_sync:sendAntennaPowerState", ply, state, ant )
	end )
end

-- Sends the mode for the given antenna to the other player (driver/passenger)
function SYNC:SendAntennaMode( ant, mode )
	self:SyncData( function( ply )
		TriggerServerEvent( "wk_wars2x_sync:sendAntennaMode", ply, ant, mode )
	end )
end

-- Sends a lock/unlock state, as well as the current player's displayed data to the other player (driver/passenger)
function SYNC:LockAntennaSpeed( ant, data )
	self:SyncData( function( ply )
		TriggerServerEvent( "wk_wars2x_sync:sendLockAntennaSpeed", ply, ant, data )
	end )
end

-- Sends the given operator menu table data to the other player
function SYNC:SendUpdatedOMData( data )
	self:SyncData( function( ply )
		TriggerServerEvent( "wk_wars2x_sync:sendUpdatedOMData", ply, data )
	end )
end

-- Sends the plate reader lock event with the data from the reader that was locked
function SYNC:LockReaderCam( cam, data )
	self:SyncData( function( ply )
		TriggerServerEvent( "wk_wars2x_sync:sendLockCameraPlate", ply, cam, data )
	end )
end

-- Requests radar data from the driver if the player has just entered a valid vehicle as a front seat passenger
function SYNC:SyncDataOnEnter()
	-- Make sure passenger view is allowed, also, using PLY:IsPassenger() already checks that the player's
	-- vehicle meets the requirements of what the radar requires. This way we don't have to do additional
	-- checks manually.
	if ( PLY:IsPassenger() ) then
		local driver = PLY:GetOtherPedServerId()

		-- Only trigger the event if there is actually a driver
		if ( driver ~= nil ) then
			TriggerServerEvent( "wk_wars2x_sync:requestRadarData", driver )
		end
	elseif ( PLY:IsDriver() ) then
		if ( RADAR:IsThereBackupData() ) then
			-- Restore the local data
			RADAR:RestoreFromBackup()
			READER:RestoreFromBackup()
		end
	end
end


--[[----------------------------------------------------------------------------------
	Sync client events
----------------------------------------------------------------------------------]]--
-- Event for receiving the radar powet state
RegisterNetEvent( "wk_wars2x_sync:receivePowerState" )
AddEventHandler( "wk_wars2x_sync:receivePowerState", function( state )
	-- Set the radar's power
	RADAR:SetPowerState( state, false )
end )

-- Event for receiving a power state for the given antenna
RegisterNetEvent( "wk_wars2x_sync:receiveAntennaPowerState" )
AddEventHandler( "wk_wars2x_sync:receiveAntennaPowerState", function( state, antenna )
	-- Get the current local antenna power state
	local power = RADAR:IsAntennaTransmitting( antenna )

	-- If the local power state is not the same as the given state, toggle the antenna's power
	if ( power ~= state ) then
		RADAR:ToggleAntenna( antenna )
	end
end )

-- Event for receiving a mode for the given antenna
RegisterNetEvent( "wk_wars2x_sync:receiveAntennaMode" )
AddEventHandler( "wk_wars2x_sync:receiveAntennaMode", function( antenna, mode )
	RADAR:SetAntennaMode( antenna, mode )
end )

-- Event for receiving a lock state and speed data for the given antenna
RegisterNetEvent( "wk_wars2x_sync:receiveLockAntennaSpeed" )
AddEventHandler( "wk_wars2x_sync:receiveLockAntennaSpeed", function( antenna, data )
	RADAR:LockAntennaSpeed( antenna, data, true )
end )

RegisterNetEvent( "wk_wars2x_sync:receiveLockCameraPlate" )
AddEventHandler( "wk_wars2x_sync:receiveLockCameraPlate", function( camera, data )
	READER:LockCam( camera, true, false, data )
end )

-- Event for gathering the radar data and sending it to another player
RegisterNetEvent( "wk_wars2x_sync:getRadarDataFromDriver" )
AddEventHandler( "wk_wars2x_sync:getRadarDataFromDriver", function( playerFor )
	local radarData = RADAR:GetRadarDataForSync()
	local readerData = READER:GetReaderDataForSync()

	TriggerServerEvent( "wk_wars2x_sync:sendRadarDataForPassenger", playerFor, { radarData, readerData } )
end )

-- Event for receiving radar data from another player
RegisterNetEvent( "wk_wars2x_sync:receiveRadarData" )
AddEventHandler( "wk_wars2x_sync:receiveRadarData", function( data )
	RADAR:LoadDataFromDriver( data[1] )
	READER:LoadDataFromDriver( data[2] )
end )

-- Event for receiving updated operator menu data from another player
RegisterNetEvent( "wk_wars2x_sync:receiveUpdatedOMData" )
AddEventHandler( "wk_wars2x_sync:receiveUpdatedOMData", function( data )
	if ( PLY:IsDriver() or ( PLY:IsPassenger() and RADAR:IsThereBackupData() ) ) then
		RADAR:SetOMTableData( data )
		RADAR:SendSettingUpdate()
	end
end )