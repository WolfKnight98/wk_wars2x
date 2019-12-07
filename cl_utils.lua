--[[-----------------------------------------------------------------------

	Wraith ARS 2X
	Created by WolfKnight

-----------------------------------------------------------------------]]--
UTIL = {}

function UTIL:Round( num, numDecimalPlaces )
	return tonumber( string.format( "%." .. ( numDecimalPlaces or 0 ) .. "f", num ) )
end 

function UTIL:FormatSpeed( speed )
	if ( speed < 0 or speed > 999 ) then return "Err" end 

	local text = tostring( speed )
	local pipes = ""

	for i = 1, 3 - string.len( text ) do 
	    pipes = pipes .. "¦"
	end 
	
	return pipes .. text
end 

function UTIL:Clamp( val, min, max )
	if ( val < min ) then 
		return min 
	elseif ( val > max ) then 
		return max 
	end 

	return val 
end 

function UTIL:IsTableEmpty( t )
	local c = 0 

	for _ in pairs( t ) do c = c + 1 end 

	return c == 0
end 

-- Credit to Deltanic for this function
function UTIL:Values( xs )
	local i = 0

	return function()
		i = i + 1
		return xs[i]
	end
end

function UTIL:GetVehicleInDirection( entFrom, coordFrom, coordTo )
	local rayHandle = StartShapeTestCapsule( coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 20.0, 10, entFrom, 7 )
	local _, hitEntity, endCoords, surfaceNormal, vehicle = GetShapeTestResult( rayHandle )
	return vehicle
end

function UTIL:GetEntityRelativeDirection( myAng, tarAng )
	local angleDiff = math.abs( ( myAng - tarAng + 180 ) % 360 - 180 )

	if ( angleDiff < 45 ) then 
		return 1
	elseif ( angleDiff > 135 ) then 
		return 2
	end 

	return 0
end

function UTIL:Notify( text )
	SetNotificationTextEntry( "STRING" )
	AddTextComponentSubstringPlayerName( text )
	DrawNotification( false, true )
end

function UTIL:DrawDebugText( x, y, scale, centre, text )
	SetTextFont( 4 )
	SetTextProportional( 0 )
	SetTextScale( scale, scale )
	SetTextColour( 255, 255, 255, 255 )
	SetTextDropShadow( 0, 0, 0, 0, 255 )
	SetTextEdge( 2, 0, 0, 0, 255 )
	SetTextCentre( centre )
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry( "STRING" )
	AddTextComponentString( text )
	DrawText( x, y )
end

function UTIL:DrawDebugSphere( x, y, z, r, col )
	if ( RADAR.config.debug_mode ) then 
		local col = col or { 255, 255, 255, 255 }

		DrawMarker( 28, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, r, r, r, col[1], col[2], col[3], col[4], false, true, 2, false, false, false, false )
	end
end

function UTIL:DrawDebugLine( startP, endP, col )
	if ( RADAR.config.debug_mode ) then 
		local col = col or { 255, 255, 255, 255 }

		DrawLine( startP, endP, col[1], col[2], col[3], col[4] )
	end
end 

function UTIL:DebugPrint( text )
	if ( RADAR.config.debug_mode ) then 
		print( text )
	end 
end 

--[[The MIT License (MIT)

	Copyright (c) 2017 IllidanS4

	Permission is hereby granted, free of charge, to any person
	obtaining a copy of this software and associated documentation
	files (the "Software"), to deal in the Software without
	restriction, including without limitation the rights to use,
	copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following
	conditions:

	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
	OTHER DEALINGS IN THE SOFTWARE.

	The below code can be found at: https://gist.github.com/IllidanS4/9865ed17f60576425369fc1da70259b2
]]

local entityEnumerator = {
	__gc = function(enum)
		if enum.destructor and enum.handle then
			enum.destructor(enum.handle)
		end

		enum.destructor = nil
		enum.handle = nil
	end
}

local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
	return coroutine.wrap(function()
		local iter, id = initFunc()
		if not id or id == 0 then
			disposeFunc(iter)
			return
		end

		local enum = {handle = iter, destructor = disposeFunc}
		setmetatable(enum, entityEnumerator)

		local next = true
		repeat
			coroutine.yield(id)
			next, id = moveFunc(iter)
		until not next

		enum.destructor, enum.handle = nil, nil
		disposeFunc(iter)
	end)
end

function UTIL:EnumerateVehicles()
	return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end