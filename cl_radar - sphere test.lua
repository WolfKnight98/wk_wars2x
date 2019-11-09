--[[------------------------------------------------------------------------

	Wraith Radar System - v1.0.3
	Created by WolfKnight

------------------------------------------------------------------------]]--

--[[------------------------------------------------------------------------
	Resource Rename Fix 
------------------------------------------------------------------------]]--
Citizen.CreateThread( function()
	-- Wait for a short period of time to give the resource time to load
	Citizen.Wait( 5000 )

	-- Get the name of the resource, for example the default name is 'wk_wrs'
	local resourceName = GetCurrentResourceName()

	-- Send a message through the NUI system to the JavaScript file to 
	-- give the name of the resource 
	SendNUIMessage( { resourcename = resourceName } )
end )

--[[------------------------------------------------------------------------
	Radar variables
------------------------------------------------------------------------]]--
RADAR.vars = 
{
	-- Player's vehicle speed 
	patrolSpeed = 0,

	-- The speed type
	speedType = "mph",

	-- Table to store entity IDs of captured vehicles 
	capturedVehicles = {}, 

	captureOffsets = {},

	-- Antennas 
	antennas = {
		front = {

		}, 

		back = {

		}
	}
}

--[[------------------------------------------------------------------------
	Radar setters and getters 
------------------------------------------------------------------------]]--
function RADAR:SetPatrolSpeed( speed )
	if ( type( speed ) == "number" ) then 
		self.vars.patrolSpeed = speed
	end
end

function RADAR:GetPatrolSpeed()
	return self.vars.patrolSpeed
end 

--[[------------------------------------------------------------------------
	Radar functions 
------------------------------------------------------------------------]]--
function RADAR:GetVehSpeed( veh )
	if ( self.vars.speedType == "mph" ) then 
		return GetEntitySpeed( veh ) * 2.236936
	else 
		return GetEntitySpeed( veh ) * 3.6
	end 
end 

function RADAR:ResetCapturedVehicles()
	self.vars.capturedVehicles = {}
end


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

function EnumeratePeds()
  return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end

function EnumerateVehicles()
  return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end


local traces = 
{
	{ startVec = { x = 0.0, y = 5.0 }, endVec = { x = 0.0, y = 150.0 } },

	-- "Forward cone"
	{ startVec = { x = -5.0, y = 15.0 }, endVec = { x = -5.0, y = 150.0 } },
	{ startVec = { x = 5.0, y = 15.0 }, endVec = { x = 5.0, y = 150.0 } },
	{ startVec = { x = -10.0, y = 25.0 }, endVec = { x = -10.0, y = 150.0 } },
	{ startVec = { x = 10.0, y = 25.0 }, endVec = { x = 10.0, y = 150.0 } },
	{ startVec = { x = -15.0, y = 35.0 }, endVec = { x = -15.0, y = 150.0 } },
	{ startVec = { x = 15.0, y = 35.0 }, endVec = { x = 15.0, y = 150.0 } },

	-- "Rear cone"
	--[[{ startVec = { x = -2.5, y = 135.0 }, endVec = { x = -2.5, y = 15.0 } },
	{ startVec = { x = 2.5, y = 135.0 }, endVec = { x = 2.5, y = 15.0 } },
	{ startVec = { x = -7.5, y = 125.0 }, endVec = { x = -7.5, y = 25.0 } },
	{ startVec = { x = 7.5, y = 125.0 }, endVec = { x = 7.5, y = 25.0 } },
	{ startVec = { x = -12.5, y = 115.0 }, endVec = { x = -12.5, y = 35.0 } },
	{ startVec = { x = 12.5, y = 115.0 }, endVec = { x = 12.5, y = 35.0 } }]]
}

function RADAR:RayTraceFromVeh( playerVeh )
	local playerVehPos = GetEntityCoords( playerVeh, true )
	local forwardVector = GetEntityForwardVector( playerVeh ) 

	-- Vector3 source = playerVehPos + forwardVector * Start.Y (15.0) + Game.Player.Character.CurrentVehicle.RightVector * Start.X (-5.0)
	--local rayStart1 = playerVehPos + ( forwardVector * vector3( -5.0, 15.0, 0.0 ) ) + GetEntityRotation( playerVeh, false )
	--local rayEnd1 = playerVehPos + ( forwardVector * vector3( -5.0, 300.0, 0.0 ) ) + GetEntityRotation( playerVeh, false )

	local offset = GetOffsetFromEntityInWorldCoords( playerVeh, 0.0, 60.0, 0.0 )

	-- for veh in EnumerateVehicles() do 
	-- 	local pos = GetEntityCoords( veh, true )

	-- 	local dist = GetDistanceBetweenCoords( pos.x, pos.y, pos.z, offset.x, offset.y, offset.z, true )

	-- 	UTIL:DrawDebugText( 0.50, 0.50, 0.60, true, "Dist: " .. tostring( dist ), 255, 255, 255, 255 )
	-- end 

	for k, v in pairs( traces ) do
		local rayStart1 = GetOffsetFromEntityInWorldCoords( playerVeh, v.startVec.x, v.startVec.y, 0.0 )
		local rayEnd1 = GetOffsetFromEntityInWorldCoords( playerVeh, v.endVec.x, v.endVec.y, 0.0 )

		DrawLine( rayStart1.x, rayStart1.y, rayStart1.z, rayEnd1.x, rayEnd1.y, rayEnd1.z, 255, 255, 255, 255 )

		local rayHandle = StartShapeTestCapsule( rayStart1.x, rayStart1.y, rayStart1.z, rayEnd1.x, rayEnd1.y, rayEnd1.z, 20.0, 10, playerVeh )
		local _, hitEntity, endCoords, surfaceNormal, vehicle = GetShapeTestResult( rayHandle )

		-- SetEntityAsMissionEntity( vehicle )

		UTIL:DrawDebugText( 0.50, ( k * 0.040 ) + 0.6, 0.60, true, "Found entity: " .. tostring( vehicle ), 255, 255, 255, 255 )

		local hitEntPos = GetEntityCoords( vehicle, true  )
		DrawMarker( 28, hitEntPos.x, hitEntPos.y, hitEntPos.z + 6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 0.5, 0, 250, 0, 200, false, true, 2, false, false, false, false )
	end
end

function RADAR:DoesLineIntersectSphere( centre, radiusSqr, rayStart, rayEnd )
	-- First we get the normalised ray, this way we then know the direction the ray is going 
	local rayNorm = norm( rayEnd - rayStart )

	-- Then we calculate the ray to the centre position of the sphere
	local rayToCentre = vehPos - startPoint 

	-- Now that we have the ray to the centre of the sphere, and the normalised ray direction, we 
	-- can calculate the shortest point from the centre of the sphere onto the ray itself. This 
	-- would then give us the opposite side of the right angled triangle. All of the resulting 
	-- values are also in squared form, as performing sqrt functions is slower. 
	local tProj = dot( rayToCentre, rayNorm )
	local oppLenSqr = dot( rayToCentre, rayToCentre ) - ( tProj * tProj )

	-- Now all we have to do is compare the squared opposite length and the radius squared, this 
	-- will then tell us if the ray intersects with the sphere.
	if ( oppLenSqr < radiusSqr ) then 
		return true 
	end

	return false
end 

--[[------------------------------------------------------------------------
	Test time 
------------------------------------------------------------------------]]--
function GetBoundingBox( ent )
	local mdl = GetEntityModel( ent )
	local min, max = GetModelDimensions( mdl )
	-- local radius = 5.0 

	-- min = min + -radius
	-- max = max + radius

	local points = {
		vector3( min.x, min.y, min.z ), -- Bottom back left 
		vector3( max.x, min.y, min.z ), -- Bottom back right 
		vector3( min.x, max.y, min.z ), -- Bottom front left
		vector3( max.x, max.y, min.z ), -- Bottom front right 
		vector3( min.x, min.y, max.z ), -- Top back left 
		vector3( max.x, min.y, max.z ), -- Top back right 
		vector3( min.x, max.y, max.z ), -- Top front left
		vector3( max.x, max.y, max.z )  -- Top front right 
	}

	return points
end 

function GetDrawableFromBoundingBox( box )
	local points = {
		{ box[1], box[3] },
		{ box[3], box[4] },
		{ box[4], box[2] }, 
		{ box[2], box[1] },

		{ box[1], box[5] }, 
		{ box[3], box[7] },
		{ box[4], box[8] }, 
		{ box[2], box[6] },

		{ box[5], box[7] },
		{ box[7], box[8] }, 
		{ box[8], box[6] },
		{ box[6], box[5] }
	}

	return points 
end

function DrawBoundingBox( ent, box )
	for _, v in pairs( box ) do
		local a = GetOffsetFromEntityInWorldCoords( ent, v[1] )
		local b = GetOffsetFromEntityInWorldCoords( ent, v[2] )

		DrawLine( a.x, a.y, a.z, b.x, b.y, b.z, 255, 255, 255, 255 )
	end
end

function GetAllVehicleEnts()
	local ents = {}

	for v in EnumerateVehicles() do 
		table.insert( ents, v )
	end

	return ents
end

function CustomShapeTest( startPos, endPos, entToIgnore )
	local flags = 1 | 2 | 4 | 16 | 256
	local trace = StartShapeTestRay( startPos, endPos, flags, entToIgnore, 7 )
	local _, didHit, hitPos, _, hitEnt = GetShapeTestResult( trace )

	UTIL:DrawDebugText( 0.500, 0.850, 0.55, true, "Hit?: " .. tostring( didHit ) .. "\nHit pos: " .. tostring( hitPos ) .. "\nHit ent: " .. tostring( hitEnt ) )	

	if ( hitPos ) then 
		DrawMarker( 28, hitPos.x, hitPos.y, hitPos.z + 5.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.25, 0, 250, 120, 200, false, true, 2, false, false, false, false )
	end 
end

function values(xs)
  local i = 0
  return function()
	i = i + 1;
	return xs[i]
  end
end

function map(xs, fn)
  local t = {}
  for i,v in ipairs(xs) do
	local r = fn(v, i, xs)
	table.insert(t, r)
  end
  return t
end

function filter(xs, fn)
  local t = {}
  for i,v in ipairs(xs) do
	if fn(v, i, xs) then
	  table.insert(t, v)
	end
  end
  return t
end


function DoesLineIntersectAABB( p1, p2, min, max )
	-- I know this probably isn't the best way to check if a line with a 'radius' intersects with 
	-- a bounding box, but it's a lot less resource intensive so...
	--local min = min + -3.0 
	--local max = max + 3.0

	-- This checks to make sure the origin of the line doesn't start inside the box
	-- Also known as "IsPointInsideAABB"
	if ( ( p1.x > min.x and p1.x < max.x and p1.y > min.y and p1.y < max.y and p1.z > min.z and p1.z < max.z ) or
		 ( p2.x > min.x and p2.x < max.x and p2.y > min.y and p2.y < max.y and p2.z > min.z and p2.z < max.z ) ) then 
		return true 
	end

	-- This checks to make sure the line itself is not even near the box
    for a in values( { 'x', 'y', 'z' } ) do
    	-- The first half of this statement checks to see if the axis origin and end line points 
    	-- are less than the minimum of the bounding box, the second half checks the start and 
    	-- end line points are beyond the maximum of the bounding box 
    	if ( ( p1[a] < min[a] and p2[a] < min[a] ) or ( p1[a] > max[a] and p2[a] > max[a] ) ) then
    		return false
    	end
    end

    -- Still trying to work out how this one works 
    for p in values( { min, max } ) do
    	for a, o in pairs( { x = { 'y', 'z' }, y = { 'x', 'z' }, z = { 'x', 'y' } } ) do

    		-- p = min or max as vector 
    		-- a = x, y or z 
    		-- o = 'y''z', 'x''z' or 'x''y' respectively
    		-- eg h = l1 + ( l1[x] - min[x] ) / ( l1[x] - l2[x] ) * ( l2 - l1 )
    		-- eg o1, o2 = [o1], o[2] = 'y', 'z'

    		-- The below variable h appears to calculate the values that allow for x1, x2, y1, and y2
    		-- This way the intersection point can be found 
    		local h = p1 + ( p1[a] - p[a] ) / ( p1[a] - p2[a] ) * ( p2 - p1 )
    		local o1, o2 = o[1], o[2]

    		if ( h[o1] >= min[o1] and h[o1] <= max[o1] and h[o2] >= min[o2] and h[o2] <= max[o2] ) then
    			return true
    		end
    	end
    end

    return false
end

function DoesLineIntersectSphere()
end

function DoesLineIntersectEntityBoundingBox(p1, p2, entity)
  local model = GetEntityModel(entity)
  local min, max = GetModelDimensions(model)

  local l1 = GetOffsetFromEntityGivenWorldCoords( entity, p1 )
  local l2 = GetOffsetFromEntityGivenWorldCoords( entity, p2 )

  -- Citizen.Trace( "\np1: " .. tostring( p1 ) .. "\tp2: " .. tostring( p2 ) .. "\tl1: " .. tostring( l1 ) .. "\tl2: " .. tostring( l2 ) )

  return DoesLineIntersectAABB(l1, l2, min, max)
end


function RaytraceBoundingBox(p1, p2, ignoredEntity)
  local entities = GetAllVehicleEnts()
  local matches = filter(entities, function (entity)
	if entity == ignoredEntity then return false end
	if not IsEntityOnScreen(entity) then return false end
	-- if not IsEntityTargetable(entity) then return false end
	return DoesLineIntersectEntityBoundingBox(p1, p2, entity)
  end)

  table.sort(matches, function (a, b)
	local h1 = GetEntityCoords(a)
	local h2 = GetEntityCoords(b)
	return #(p1 - h1) < #(p1 - h2)
  end)

  if matches[1] then
	local pos = GetEntityCoords(matches[1])
	return pos, matches[1]
  end

  return nil, nil
end


function RADAR:Test()
	-- Get the player's ped 
	local ped = GetPlayerPed( -1 )

	-- Make sure the player is sitting in a vehicle 
	if ( IsPedSittingInAnyVehicle( ped ) ) then 
		-- Get the vehicle the player is in 
		local plyVeh = GetVehiclePedIsIn( ped, false )
		local plyVehPos = GetEntityCoords( plyVeh )

		-- Check the vehicle actually exists and that the player is in the driver's seat
		if ( DoesEntityExist( plyVeh ) and GetPedInVehicleSeat( plyVeh, -1 ) ) then 
			local startPoint = GetOffsetFromEntityInWorldCoords( plyVeh, 0.0, 5.0, 0.0 )
			local endPoint = GetOffsetFromEntityInWorldCoords( plyVeh, 0.0, 50.0, 1.0 )
			DrawLine( startPoint, endPoint, 0, 255, 0, 255 )

			--for veh in EnumerateVehicles() do

			local veh = UTIL:GetVehicleInDirection( plyVeh, startPoint, endPoint )

			if ( DoesEntityExist( veh ) ) then 
				local vehPos = GetEntityCoords( veh )
				local vehPosRel = GetOffsetFromEntityGivenWorldCoords( plyVeh, vehPos )

				--[[local vehBox = GetBoundingBox( veh )
				local drawableBox = GetDrawableFromBoundingBox( vehBox )
				DrawBoundingBox( veh, drawableBox )]]

				if ( veh ~= plyVeh ) then 
					DrawMarker( 28, vehPos.x, vehPos.y, vehPos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 10.0, 10.0, 10.0, 255, 120, 80, 40, false, true, 2, false, false, false, false )

					-- First attempt, didn't really work 
					-- local r = 5.0 
					-- local ro = startPoint 
					-- local s = vehPos
					-- local rd = norm( startPoint )
					-- local t = dot( s - ro, rd )
					-- local p = ro + ( rd * t )

					-- UTIL:DrawDebugSphere( ro.x, ro.y, ro.z, 0.5 )
					-- UTIL:DrawDebugSphere( s.x, s.y, s.z, 0.5 )
					-- UTIL:DrawDebugSphere( p.x, p.y, p.z, 0.5 )

					-- local y = #( s - p )

					-- if ( y < r ) then 
					-- 	local x = math.sqrt( ( r * r ) - ( y * y ) )
					-- 	local t1 = t - x
					-- 	local t2 = t + x

					-- 	UTIL:DrawDebugText( 0.500, 0.700, 0.50, true, "t1: " .. tostring( t1 ) .. "\nt2: " .. tostring( t2 ) )
					-- end

					-- Second attempt 
					-- local ra = 20.0 
					-- local ce = vehPos 
					-- local ro = startPoint 
					-- local rd = norm( startPoint )

					-- local oc = ro - ce 
					-- local b = dot( oc, rd )
					-- local c = dot( oc, oc ) - ( ra * ra )
					-- local h = ( b * b ) - c 

					-- if ( h > 0.0 ) then 
					-- 	h = math.sqrt( h )
					-- 	local result = vector2( -b-h, -b+h )

					-- 	UTIL:DrawDebugText( 0.500, 0.700, 0.50, true, "Result: " .. tostring( result ) )
					-- end 

					-- Third bloody attempt 
					-- local center = vehPos 
					-- local radius = 5.0 
					-- local ro = startPoint 
					-- local rd = norm( startPoint )

					-- local oc = startPoint - center 
					-- local a = dot( rd, rd )
					-- local b = 2.0 * dot( oc, rd )
					-- local c = dot( oc, oc ) - radius * radius 
					-- local dis = b * b - 4 * a * c 

					-- if ( dis < 0 ) then 
					-- 	UTIL:DrawDebugText( 0.500, 0.650, 0.50, true, "-1" )
					-- else 
					-- 	local val = ( -b - math.sqrt( dis ) ) / ( 2.0 * a )
					-- 	UTIL:DrawDebugText( 0.500, 0.650, 0.50, true, "yes" )
					-- end 

					-- Fourth attempt 
					local offset = GetOffsetFromEntityGivenWorldCoords( veh, startPoint )
					UTIL:DrawDebugText( 0.500, 0.550, 0.50, true, tostring( offset ) )

					local radius = 10.0 
					local radiusSqr = radius * radius 

					local rayNorm = norm( endPoint - startPoint )
					UTIL:DrawDebugText( 0.500, 0.600, 0.50, true, "rayNorm: " .. tostring( rayNorm ) )

					local rayToCenter = vehPos - startPoint 
					DrawLine( startPoint, vehPos, 255, 255, 255, 255 )

					local tProj = dot( rayToCenter, rayNorm )
					UTIL:DrawDebugText( 0.500, 0.625, 0.50, true, "tProj: " .. tostring( tProj ) )

					UTIL:DrawDebugText( 0.500, 0.100, 0.60, true, "Veh in front? = " .. tostring( ( tProj > 0 ) ) )

					local iPos = ( rayNorm * tProj ) + startPoint 
					DrawLine( vehPos, iPos, 255, 255, 255, 255 ) -- draw the smallest point 
					DrawLine( startPoint, iPos, 255, 255, 255, 255 ) -- draw a line on the opposite 

					local oppLenSqr = dot( rayToCenter, rayToCenter ) - ( tProj * tProj )
					UTIL:DrawDebugText( 0.500, 0.650, 0.50, true, "radiusSqr: " .. tostring( radiusSqr ) )
					UTIL:DrawDebugText( 0.500, 0.675, 0.50, true, "oppLenSqr: " .. tostring( oppLenSqr ) )

					if ( oppLenSqr > radiusSqr ) then 
						UTIL:DrawDebugText( 0.500, 0.800, 0.50, true, "Projection point outside radius" )
					elseif ( oppLenSqr == radiusSqr ) then 
						UTIL:DrawDebugText( 0.500, 0.825, 0.50, true, "Single point intersection" )
					end 

					local oLen = math.sqrt( radiusSqr - oppLenSqr )
					UTIL:DrawDebugText( 0.500, 0.700, 0.50, true, "oLen: " .. tostring( oLen ) )

					local t0 = tProj - oLen 
					local t1 = tProj + oLen 

					if ( t1 < t0 ) then 
						local tmp = t0 
						t0 = t1 
						t1 = tmp 
					end 

					UTIL:DrawDebugText( 0.500, 0.725, 0.50, true, "t0: " .. tostring( t0 ) .. "\nt1: " .. tostring( t1 ) )

					local t0p = ( rayNorm * t0 ) + startPoint
					local t1p = ( rayNorm * t1 ) + startPoint

					UTIL:DrawDebugSphere( t0p.x, t0p.y, t0p.z, 0.25 )
					UTIL:DrawDebugSphere( t1p.x, t1p.y, t1p.z, 0.25 )

					DrawLine( vehPos, t0p, 255, 255, 0, 255 )
					DrawLine( vehPos, t1p, 255, 255, 0, 255 )

					if ( oppLenSqr < radiusSqr ) then 
						UTIL:DrawDebugText( 0.500, 0.875, 0.55, true, "Intersects sphere" )
					else
						UTIL:DrawDebugText( 0.500, 0.925, 0.55, true, "Doesn't intersect sphere" )
					end
				end
			end
		end
	end 
end 

function RADAR:Main()
	-- Get the local player's ped and store it in a variable 
	local ped = GetPlayerPed( -1 )

	-- As we only want the radar to work when a player is sitting in a
	-- vehicle, we run that check first
	if ( IsPedSittingInAnyVehicle( ped ) ) then 
		-- Get the vehicle the player is sitting in 
		local vehicle = GetVehiclePedIsIn( ped, false )

		UTIL:DrawDebugText( 0.50, 0.020, 0.60, true, "Found player vehicle: " .. tostring( vehicle ), 255, 255, 255, 255 )

		-- Check to make sure the player is in the driver's seat, and also 
		-- that the vehicle has a class of VC_EMERGENCY (18)
		if ( GetPedInVehicleSeat( vehicle, -1 ) == ped --[[ and GetVehicleClass( vehicle ) == 18 ]] ) then 
			local vehicleSpeed = UTIL:Round( self:GetVehSpeed( vehicle ), 0 )
			local vehicleHeading = UTIL:Round( GetEntityHeading( vehicle ), 0 )

			UTIL:DrawDebugText( 0.50, 0.060, 0.60, true, "Self speed: " .. tostring( vehicleSpeed ), 255, 255, 255, 255 )

			local vehiclePos = GetEntityCoords( vehicle, true )
			-- local edge = GetOffsetFromEntityInWorldCoords( vehicle, 20.0, 50.0, 0.0 ) 
		   
			local newX = UTIL:Round( vehiclePos.x, 0 )
			local newY = UTIL:Round( vehiclePos.y, 0 )
			local newZ = UTIL:Round( vehiclePos.z, 0 )

			UTIL:DrawDebugText( 0.50, 0.100, 0.60, true, "Vehicle X: " .. tostring( newX ) .. "  Vehicle Y: " .. tostring( newY ) .. " Vehicle Z: " .. tostring( newZ ), 255, 255, 255, 255 )

			local model = GetEntityModel( vehicle )
			local min, max = GetModelDimensions( model )
			local format = "Min X: " .. tostring( min.x ) .. " Min Y: " .. tostring( min.y ) .. " Min Z: " .. tostring( min.z )
			local format2 = "Max X: " .. tostring( max.x ) .. " Max Y: " .. tostring( max.y ) .. " Max Z: " .. tostring( max.z )

			UTIL:DrawDebugText( 0.50, 0.180, 0.60, true, "Model: " .. tostring( model ), 255, 255, 255, 255 )
			UTIL:DrawDebugText( 0.50, 0.220, 0.60, true, format, 255, 255, 255, 255 )
			UTIL:DrawDebugText( 0.50, 0.260, 0.60, true, format2, 255, 255, 255, 255 )

			for veh in EnumerateVehicles() do
				if ( GetEntitySpeed( veh ) > 1.0 and veh ~= vehicle ) then 
					local aiVehHeading = UTIL:Round( GetEntityHeading( veh ), 0 )
					local sameHeading = UTIL:IsEntityInMyHeading( vehicleHeading, aiVehHeading, 45 )

					if ( sameHeading ) then 
						local mdl = GetEntityModel( veh )

						if ( IsThisModelACar( mdl ) or IsThisModelABike( mdl ) or IsThisModelAQuadbike( mdl ) ) then 
							local bounds = getBoundingBox( veh )	
							local boundsDrawable = getBoundingBoxDrawable( bounds )
							drawBoundingBox( veh, boundsDrawable )
						end
					end
				end
			end

			-- self:RayTraceFromVeh( vehicle )

			-- local newPos = GetOffsetFromEntityInWorldCoords( vehicle, 0.0, 10.0, 0.0 )

			-- UTIL:DrawSphere( newPos.x, newPos.y, newPos.z, 6.0, 128, 255, 0, 0.15 )

			-- local ranVeh = GetRandomVehicleInSphere( newPos.x, newPos.y, newPos.z, 6.0, 0, 23 )

			-- UTIL:DrawDebugText( 0.50, 0.140, 0.60, true, "Found random vehicle: " .. tostring( ranVeh ), 255, 255, 255, 255 )

			-- if ( DoesEntityExist( ranVeh ) and IsEntityAVehicle( ranVeh ) ) then 
			-- 	local targetPos = GetEntityCoords( ranVeh, true )
			-- 	DrawMarker(2, targetPos.x, targetPos.y, targetPos.z + 6, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 2.0, 2.0, 2.0, 255, 128, 0, 50, false, true, 2, nil, nil, false)
			-- end

			-- begin bubble test 
			-- for i = 1, 5 do 
			-- 	local newPos = GetOffsetFromEntityInWorldCoords( vehicle, 0.0, i * 10.0, 0.0 )
			-- 	-- UTIL:DrawSphere( newPos1.x, newPos1.y, newPos1.z, 2.0, 128, 255, 20, 0.4 )
			-- 	DrawMarker( 28, newPos.x, newPos.y, newPos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, i * 2.0, i * 2.0, 0.5, 0, 250, 0, 200, false, true, 2, false, false, false, false )
			-- end
		end
	end
end 

Citizen.CreateThread( function()
	while ( true ) do
		-- RADAR:Main()
		RADAR:Test()

		Citizen.Wait( 0 )
	end
end )