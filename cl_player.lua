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

--[[----------------------------------------------------------------------------------
	Player info variables
----------------------------------------------------------------------------------]]--
PLY =
{
	ped = PlayerPedId(),
	veh = nil,
	inDriverSeat = false,
	inPassengerSeat = false,
	vehClassValid = false
}

function PLY:VehicleStateValid()
	return DoesEntityExist( self.veh ) and self.veh > 0 and self.vehClassValid
end

-- Used to check if the player is in a position where the radar should be allowed operation
function PLY:IsDriver()
	return self:VehicleStateValid() and self.inDriverSeat
end

-- Returns if the player is in the front passenger seat of an emergency vehicle
function PLY:IsPassenger()
	return self:VehicleStateValid() and self.inPassengerSeat
end

-- Returns if the player can view the radar, ensures their vehicle state is valid and that they are a driver or
-- a passenger (where valid)
function PLY:CanViewRadar()
	return self:IsDriver() or ( self:IsPassenger() and RADAR:IsPassengerViewAllowed() )
end

-- Returns if the player is allowed to control the radar from the passenger seat
function PLY:CanControlRadar()
	return self:IsDriver() or ( self:IsPassenger() and RADAR:IsPassengerControlAllowed() )
end

-- Returns the ped in the opposite seat to the player, e.g. if we're the passenger, then return the driver
function PLY:GetOtherPed()
	if ( self:IsDriver() ) then
		return GetPedInVehicleSeat( PLY.veh, 0 )
	elseif ( self:IsPassenger() ) then
		return GetPedInVehicleSeat( PLY.veh, -1 )
	end

	return nil
end

-- The main purpose of this thread is to update the information about the local player, including their
-- ped id, the vehicle id (if they're in one), whether they're in a driver seat, and if the vehicle's class
-- is valid or not
Citizen.CreateThread( function()
	while ( true ) do
		PLY.ped = PlayerPedId()
		PLY.veh = GetVehiclePedIsIn( PLY.ped, false )
		PLY.inDriverSeat = GetPedInVehicleSeat( PLY.veh, -1 ) == PLY.ped
		PLY.inPassengerSeat = GetPedInVehicleSeat( PLY.veh, 0 ) == PLY.ped
		PLY.vehClassValid = GetVehicleClass( PLY.veh ) == 18

		Citizen.Wait( 500 )
	end
end )

Citizen.CreateThread( function()
	while ( true ) do
		if ( IsPedGettingIntoAVehicle( PLY.ped ) ) then
			UTIL:Notify( "DEBUG: Player getting in vehicle" )
			local vehEntering = GetVehiclePedIsEntering( PLY.ped )

			Citizen.Wait( 2000 )

			local veh = GetVehiclePedIsIn( PLY.ped, false )

			if ( veh == vehEntering ) then
				UTIL:Notify( "DEBUG: Trigger sync" )
			end
		end

		Citizen.Wait( 500 )
	end
end )