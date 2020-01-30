--[[-----------------------------------------------------------------------

	Wraith ARS 2X
	Created by WolfKnight

-----------------------------------------------------------------------]]--

READER = {}

--[[----------------------------------------------------------------------------------
	Plate reader variables

	NOTE - This is not a config, do not touch anything unless you know what
	you are actually doing. 
----------------------------------------------------------------------------------]]--
READER.vars = 
{
    -- Whether or not the radar's UI is visible 
	displayed = false,

	-- Whether or not the radar should be hidden, e.g. the display is active but the player then steps
	-- out of their vehicle
    hidden = false,

    boloPlate = "", 
    
    cams = {
        ["front"] = {
            plate = "", 
            index = "", 
            locked = false 
        }, 

        ["rear"] = {
            plate = "", 
            index = "", 
            lockec = false 
        }
    }
}

-- Runs when the "Toggle Display" button is pressed on the plate reder box 
RegisterNUICallback( "togglePlateReaderDisplay", function()
	-- Toggle the display state 
	READER:ToggleDisplayState()
end )

-- Runs when the "Toggle Display" button is pressed on the plate reder box 
RegisterNUICallback( "setBoloPlate", function( plate, cb )
    READER:SetBoloPlate( plate )
end )

-- Gets the display state
function READER:GetDisplayState()
	return self.vars.displayed
end 

-- Toggles the display state of the radar system
function READER:ToggleDisplayState()
	-- Toggle the display variable 
	self.vars.displayed = not self.vars.displayed 

	-- Send the toggle message to the NUI side 
	SendNUIMessage( { _type = "setReaderDisplayState", state = self:GetDisplayState() } )
end 

-- Sets the display's hidden state to the given state 
function READER:SetDisplayHidden( state )
	self.vars.hidden = state 
end 

-- Returns if the display is hidden 
function READER:GetDisplayHidden()
	return self.vars.hidden 
end

function READER:GetPlate( cam )
    return self.vars.cams[cam].plate 
end 

function READER:SetPlate( cam, plate )
    self.vars.cams[cam].plate = plate 
end 

function READER:GetIndex( cam )
    return self.vars.cams[cam].index
end 

function READER:SetIndex( cam, index )
    self.vars.cams[cam].index = index 
end 

function READER:GetBoloPlate()
    return self.vars.boloPlate
end 

function READER:SetBoloPlate( plate )
    self.vars.boloPlate = plate 
end 

function READER:GetCamLocked( cam )
    return self.vars.cams[cam].locked
end 

function READER:LockCam( cam )
    if ( PLY:VehicleStateValid() and self:CanPerformMainTask() ) then 
        self.vars.cams[cam].locked = not self.vars.cams[cam].locked

        SendNUIMessage( { _type = "lockPlate", cam = cam, state = self:GetCamLocked( cam ) } )
        SendNUIMessage( { _type = "audio", name = "beep", vol = RADAR:GetSettingValue( "beep" ) } )
    end 
end 

function READER:CanPerformMainTask()
    return self.vars.displayed and not self.vars.hidden
end 

function READER:GetCamFromNum( relPos )
    if ( relPos == 1 ) then 
        return "front"
    elseif ( relPos == -1 ) then 
        return "rear"
    end 
end 

function READER:Main()
    if ( PLY:VehicleStateValid() and self:CanPerformMainTask() ) then 
        for i = 1, -1, -2 do 
            local start = GetEntityCoords( PLY.veh )
            local offset = GetOffsetFromEntityInWorldCoords( PLY.veh, 0.0, ( 40.0 * i ), 0.0 )
            local veh = UTIL:GetVehicleInDirection( PLY.veh, start, offset )

            local cam = self:GetCamFromNum( i )
            
            if ( DoesEntityExist( veh ) and IsEntityAVehicle( veh ) and not self:GetCamLocked( cam ) ) then 
                local plate = GetVehicleNumberPlateText( veh )
                local index = GetVehicleNumberPlateTextIndex( veh )

                if ( self:GetPlate( cam ) ~= plate ) then 
                    self:SetPlate( cam, plate )
                    self:SetIndex( cam, index )

                    if ( plate == self:GetBoloPlate() ) then 
                        UTIL:Notify( "DEBUG: BOLO plate hit!" )
                        self:LockCam( cam )
                    end 

                    SendNUIMessage( { _type = "changePlate", cam = cam, plate = plate, index = index } )
                end 
            end 
        end 
    end 
end 

Citizen.CreateThread( function()
    while ( true ) do
        READER:Main()

        Citizen.Wait( 500 )
    end 
end )

function READER:RunDisplayValidationCheck()
	if ( ( ( PLY.veh == 0 or ( PLY.veh > 0 and not PLY.vehClassValid ) ) and self:GetDisplayState() and not self:GetDisplayHidden() ) or IsPauseMenuActive() and self:GetDisplayState() ) then
		self:SetDisplayHidden( true ) 
		SendNUIMessage( { _type = "setReaderDisplayState", state = false } )
	elseif ( PLY.veh > 0 and PLY.vehClassValid and PLY.inDriverSeat and self:GetDisplayState() and self:GetDisplayHidden() ) then 
		self:SetDisplayHidden( false ) 
		SendNUIMessage( { _type = "setReaderDisplayState", state = true } )
	end 
end

Citizen.CreateThread( function() 
	Citizen.Wait( 100 )

	while ( true ) do 
		READER:RunDisplayValidationCheck()

		Citizen.Wait( 500 )
	end 
end )