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

DecorRegister( "wk_wars2x_sync_remoteOpen", 2 )

--[[----------------------------------------------------------------------------------
	Sync variables
----------------------------------------------------------------------------------]]--
SYNC = {}


--[[----------------------------------------------------------------------------------
	Sync functions
----------------------------------------------------------------------------------]]--
function SYNC:IsRemoteAlreadyOpen( ply )
	return DecorGetBool( ply, "wk_wars2x_sync_remoteOpen" )
end

function SYNC:SetRemoteOpenState( state )
	DecorSetBool( PLY.ped, "wk_wars2x_sync_remoteOpen", state )
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

-- Requests radar data from the driver if the player has just entered a valid vehicle as a front seat passenger
function SYNC:SyncDataOnEnter()
	-- Make sure passenger view is allowed, also, using PLY:IsPassenger() already checks that the player's
	-- vehicle meets the requirements of what the radar requires. This way we don't have to do additional
	-- checks manually.
	if ( RADAR:IsPassengerViewAllowed() ) then
		if ( PLY:IsPassenger() ) then
			-- UTIL:Notify( "Triggering server event to get radar data" )
			local driver = PLY:GetOtherPedServerId()

			-- Only trigger the event if there is actually a driver
			if ( driver ~= nil ) then
				TriggerServerEvent( "wk_wars2x_sync:requestRadarData", driver )
			end
		elseif ( PLY:IsDriver() ) then
			-- UTIL:Notify( "Restoring local radar data" )

			if ( RADAR:IsThereBackupData() ) then
				-- Restore the local data
				RADAR:RestoreFromBackup()
			end
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




RegisterNetEvent( "wk_wars2x_sync:getRadarDataFromDriver" )
AddEventHandler( "wk_wars2x_sync:getRadarDataFromDriver", function( playerFor )
	-- print( "Radar table has been requested by " .. tostring( GetPlayerName( playerFor ) ) )

	local data = RADAR:GetRadarDataForSync()

	-- print( "Got table (type: " .. type( data ) .. ")" )

	TriggerServerEvent( "wk_wars2x_sync:sendRadarDataForPassenger", playerFor, data )
end )

RegisterNetEvent( "wk_wars2x_sync:receiveRadarData" )
AddEventHandler( "wk_wars2x_sync:receiveRadarData", function( data )
	RADAR:LoadDataFromDriver( data )
end )