--[[-----------------------------------------------------------------------

	Wraith ARS 2X - v1.0.0
	Created by WolfKnight

-----------------------------------------------------------------------]]--
UTIL = {}

function UTIL:Round( num, numDecimalPlaces )
	-- return tonumber( string.format( "%.0f", num ) )
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

UTIL.car_colours = {
	[ "0" ] = "Metallic Black",
	[ "1" ] = "Metallic Graphite Black",
	[ "2" ] = "Metallic Black Steal",
	[ "3" ] = "Metallic Dark Silver",
	[ "4" ] = "Metallic Silver",
	[ "5" ] = "Metallic Blue Silver",
	[ "6" ] = "Metallic Steel Gray",
	[ "7" ] = "Metallic Shadow Silver",
	[ "8" ] = "Metallic Stone Silver",
	[ "9" ] = "Metallic Midnight Silver",
	[ "10" ] = "Metallic Gun Metal",
	[ "11" ] = "Metallic Anthracite Grey",
	[ "12" ] = "Matte Black",
	[ "13" ] = "Matte Gray",
	[ "14" ] = "Matte Light Grey",
	[ "15" ] = "Util Black",
	[ "16" ] = "Util Black Poly",
	[ "17" ] = "Util Dark Silver",
	[ "18" ] = "Util Silver",
	[ "19" ] = "Util Gun Metal",
	[ "20" ] = "Util Shadow Silver",
	[ "21" ] = "Worn Black",
	[ "22" ] = "Worn Graphite",
	[ "23" ] = "Worn Silver Grey",
	[ "24" ] = "Worn Silver",
	[ "25" ] = "Worn Blue Silver",
	[ "26" ] = "Worn Shadow Silver",
	[ "27" ] = "Metallic Red",
	[ "28" ] = "Metallic Torino Red",
	[ "29" ] = "Metallic Formula Red",
	[ "30" ] = "Metallic Blaze Red",
	[ "31" ] = "Metallic Graceful Red",
	[ "32" ] = "Metallic Garnet Red",
	[ "33" ] = "Metallic Desert Red",
	[ "34" ] = "Metallic Cabernet Red",
	[ "35" ] = "Metallic Candy Red",
	[ "36" ] = "Metallic Sunrise Orange",
	[ "37" ] = "Metallic Classic Gold",
	[ "38" ] = "Metallic Orange",
	[ "39" ] = "Matte Red",
	[ "40" ] = "Matte Dark Red",
	[ "41" ] = "Matte Orange",
	[ "42" ] = "Matte Yellow",
	[ "43" ] = "Util Red",
	[ "44" ] = "Util Bright Red",
	[ "45" ] = "Util Garnet Red",
	[ "46" ] = "Worn Red",
	[ "47" ] = "Worn Golden Red",
	[ "48" ] = "Worn Dark Red",
	[ "49" ] = "Metallic Dark Green",
	[ "50" ] = "Metallic Racing Green",
	[ "51" ] = "Metallic Sea Green",
	[ "52" ] = "Metallic Olive Green",
	[ "53" ] = "Metallic Green",
	[ "54" ] = "Metallic Gasoline Blue Green",
	[ "55" ] = "Matte Lime Green",
	[ "56" ] = "Util Dark Green",
	[ "57" ] = "Util Green",
	[ "58" ] = "Worn Dark Green",
	[ "59" ] = "Worn Green",
	[ "60" ] = "Worn Sea Wash",
	[ "61" ] = "Metallic Midnight Blue",
	[ "62" ] = "Metallic Dark Blue",
	[ "63" ] = "Metallic Saxony Blue",
	[ "64" ] = "Metallic Blue",
	[ "65" ] = "Metallic Mariner Blue",
	[ "66" ] = "Metallic Harbor Blue",
	[ "67" ] = "Metallic Diamond Blue",
	[ "68" ] = "Metallic Surf Blue",
	[ "69" ] = "Metallic Nautical Blue",
	[ "70" ] = "Metallic Bright Blue",
	[ "71" ] = "Metallic Purple Blue",
	[ "72" ] = "Metallic Spinnaker Blue",
	[ "73" ] = "Metallic Ultra Blue",
	[ "74" ] = "Metallic Bright Blue",
	[ "75" ] = "Util Dark Blue",
	[ "76" ] = "Util Midnight Blue",
	[ "77" ] = "Util Blue",
	[ "78" ] = "Util Sea Foam Blue",
	[ "79" ] = "Uil Lightning Blue",
	[ "80" ] = "Util Maui Blue Poly",
	[ "81" ] = "Util Bright Blue",
	[ "82" ] = "Matte Dark Blue",
	[ "83" ] = "Matte Blue",
	[ "84" ] = "Matte Midnight Blue",
	[ "85" ] = "Worn Dark Blue",
	[ "86" ] = "Worn Blue",
	[ "87" ] = "Worn Light Blue",
	[ "88" ] = "Metallic Taxi Yellow",
	[ "89" ] = "Metallic Race Yellow",
	[ "90" ] = "Metallic Bronze",
	[ "91" ] = "Metallic Yellow Bird",
	[ "92" ] = "Metallic Lime",
	[ "93" ] = "Metallic Champagne",
	[ "94" ] = "Metallic Pueblo Beige",
	[ "95" ] = "Metallic Dark Ivory",
	[ "96" ] = "Metallic Choco Brown",
	[ "97" ] = "Metallic Golden Brown",
	[ "98" ] = "Metallic Light Brown",
	[ "99" ] = "Metallic Straw Beige",
	[ "100" ] = "Metallic Moss Brown",
	[ "101" ] = "Metallic Biston Brown",
	[ "102" ] = "Metallic Beechwood",
	[ "103" ] = "Metallic Dark Beechwood",
	[ "104" ] = "Metallic Choco Orange",
	[ "105" ] = "Metallic Beach Sand",
	[ "106" ] = "Metallic Sun Bleeched Sand",
	[ "107" ] = "Metallic Cream",
	[ "108" ] = "Util Brown",
	[ "109" ] = "Util Medium Brown",
	[ "110" ] = "Util Light Brown",
	[ "111" ] = "Metallic White",
	[ "112" ] = "Metallic Frost White",
	[ "113" ] = "Worn Honey Beige",
	[ "114" ] = "Worn Brown",
	[ "115" ] = "Worn Dark Brown",
	[ "116" ] = "Worn Straw Beige",
	[ "117" ] = "Brushed Steel",
	[ "118" ] = "Brushed Black Steel",
	[ "119" ] = "Brushed Aluminium",
	[ "120" ] = "Chrome",
	[ "121" ] = "Worn Off White",
	[ "122" ] = "Util Off White",
	[ "123" ] = "Worn Orange",
	[ "124" ] = "Worn Light Orange",
	[ "125" ] = "Metallic Securicor Green",
	[ "126" ] = "Worn Taxi Yellow",
	[ "127" ] = "Police Car Blue",
	[ "128" ] = "Matte Green",
	[ "129" ] = "Matte Brown",
	[ "130" ] = "Worn Orange",
	[ "131" ] = "Matte White",
	[ "132" ] = "Worn White",
	[ "133" ] = "Worn Olive Army Green",
	[ "134" ] = "Pure White",
	[ "135" ] = "Hot Pink",
	[ "136" ] = "Salmon Pink",
	[ "137" ] = "Metallic Vermillion Pink",
	[ "138" ] = "Orange",
	[ "139" ] = "Green",
	[ "140" ] = "Blue",
	[ "141" ] = "Mettalic Black Blue",
	[ "142" ] = "Metallic Black Purple",
	[ "143" ] = "Metallic Black Red",
	[ "144" ] = "Hunter Green",
	[ "145" ] = "Metallic Purple",
	[ "146" ] = "Metaillic V Dark Blue",
	[ "147" ] = "MODSHOP BLACK1",
	[ "148" ] = "Matte Purple",
	[ "149" ] = "Matte Dark Purple",
	[ "150" ] = "Metallic Lava Red",
	[ "151" ] = "Matte Forest Green",
	[ "152" ] = "Matte Olive Drab",
	[ "153" ] = "Matte Desert Brown",
	[ "154" ] = "Matte Desert Tan",
	[ "155" ] = "Matte Foilage Green",
	[ "156" ] = "DEFAULT ALLOY COLOR",
	[ "157" ] = "Epsilon Blue"
}

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