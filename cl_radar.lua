--[[------------------------------------------------------------------------

	Wraith Radar System - v2.0.0
	Created by WolfKnight

------------------------------------------------------------------------]]--

local next = next 
local dot = dot 
local table = table 
local type = type

--[[------------------------------------------------------------------------
	Resource Rename Fix 
------------------------------------------------------------------------]]--
Citizen.CreateThread( function()
	-- Wait for a short period of time to give the resource time to load
	Citizen.Wait( 10000 )

	-- Get the name of the resource, for example the default name is 'wk_wrs2'
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

	-- Antennas 
	antennas = {
		front = {

		}, 

		back = {

		}
	}, 

	sortMode = 1, 

	maxCheckDist = 300.0,

	-- Cached dynamic sphere sizes 
	sphereSizes = {}, 

	-- Vehicle pool 
	vehiclePool = {}, 

	-- Radar stage, this is used to tell the system what it should currently be doing, the stages are:
	--    - 0 = Gathering vehicles hit by the radar
	--    - 1 = Filtering the vehicles caught 
	--    - 2 = Calculating what vehicle speed to show based on modes
	radarStage = 0,

	-- Ray stage
	rayTraceState = 0,

	-- Number of rays
	numberOfRays = 0
}

-- Table to store entity IDs of captured vehicles 
RADAR.capturedVehicles = {}
RADAR.caughtEnt = 0 

RADAR.rayTraces = {
	{ startVec = { x = 0.0,   y = 5.0 },  endVec = { x = 0.0,   y = 150.0 } },
	{ startVec = { x = -5.0,  y = 15.0 }, endVec = { x = -5.0,  y = 150.0 } },
	{ startVec = { x = 5.0,   y = 15.0 }, endVec = { x = 5.0,   y = 150.0 } }
}

RADAR.sorting = {
	[1] = { 
		name = "CLOSEST", 
		func = function( a, b ) return a.dist < b.dist end 
	}, 
	[2] = { 
		name = "FASTEST", 
		func = function( a, b ) return a.speed > b.speed end 
	}, 
	[3] = { 
		name = "LARGEST", 
		func = function( a, b ) return a.size > b.size + 1.0 end
	},
	[4] = { 
		name = "LARGEST & FASTEST", 
		func = function( a, b ) 
			if ( a.size > b.size + 2.0 ) then 
				return true 
			elseif ( a.size - b.size <= 1.0 ) then 
				return false 
			end 

			return a.speed > b.speed 
		end 
	} 
}

--[[------------------------------------------------------------------------
	Radar variable functions  
------------------------------------------------------------------------]]--
function RADAR:SetPatrolSpeed( speed )
	if ( type( speed ) == "number" ) then 
		self.vars.patrolSpeed = speed
	end
end

function RADAR:GetPatrolSpeed()
	return self.vars.patrolSpeed
end 

function RADAR:SetVehiclePool( pool )
	if ( type( pool ) == "table" ) then 
		self.vars.vehiclePool = pool 
	end
end 

function RADAR:GetVehiclePool()
	return self.vars.vehiclePool 
end 

function RADAR:GetMaxCheckDist()
	return self.vars.maxCheckDist
end 

function RADAR:GetRayTraceState()
	return self.vars.rayTraceState
end 

function RADAR:IncreaseRayTraceState()
	self.vars.rayTraceState = self.vars.rayTraceState + 1
end 

function RADAR:ResetRayTraceState()
	self.vars.rayTraceState = 0
end 

function RADAR:GetRadarStage()
	return self.vars.radarStage
end

function RADAR:IncreaseRadarStage()
	self.vars.radarStage = self.vars.radarStage + 1
end 

function RADAR:ResetRadarStage()
	self.vars.radarStage = 0
end 

function RADAR:GetNumOfRays()
	return self.vars.numberOfRays
end 

function RADAR:CacheNumOfRays()
	self.vars.numberOfRays = #self.rayTraces
end 

function RADAR:GetSortModeText()
	return self.sorting[self.vars.sortMode].name
end 

function RADAR:GetSortModeFunc()
	return self.sorting[self.vars.sortMode].func
end 

function RADAR:ToggleSortMode()
	if ( self.vars.sortMode < #self.sorting ) then 
		self.vars.sortMode = self.vars.sortMode + 1
	else 
		self.vars.sortMode = 1 
	end 

	UTIL:Notify( "Radar mode set to " .. self:GetSortModeText() )
end 

--[[------------------------------------------------------------------------
	Radar functions 
------------------------------------------------------------------------]]--
function RADAR:GetVehSpeedFormatted( speed )
	if ( self.vars.speedType == "mph" ) then 
		return math.ceil( speed * 2.236936 )
	else 
		return math.ceil( speed * 3.6 )
	end 
end 

function RADAR:ResetCapturedVehicles()
	self.capturedVehicles = {}
end

function RADAR:InsertCapturedVehicleData( t )
	if ( type( t ) == "table" and not UTIL:IsTableEmpty( t ) ) then 
		for _, v in pairs( t ) do
			table.insert( self.capturedVehicles, v )
		end
	end 
end 

function RADAR:GetCapturedVehicles()
	return self.capturedVehicles
end

function RADAR:FilterCapturedVehicles()
	for k, vehTable in pairs( self.capturedVehicles ) do 
		local veh = vehTable.veh 

		for b, v in pairs( self.capturedVehicles ) do 
			if ( v.veh == veh and k ~= b ) then table.remove( self.capturedVehicles, b ) end
		end 
	end
end 

function RADAR:GetAllVehicles()
	local t = {}

	for v in UTIL:EnumerateVehicles() do
		table.insert( t, v )
	end 

	return t
end 

function RADAR:GetDynamicDataValue( key )
	return self.vars.sphereSizes[key]
end 

function RADAR:DoesDynamicRadiusDataExist( key )
	return self:GetDynamicDataValue( key ) ~= nil 
end

function RADAR:SetDynamicRadiusKey( key, t )
	self.vars.sphereSizes[key] = t
end 

function RADAR:InsertDynamicRadiusData( key, radius, actualSize )
	if ( self:GetDynamicDataValue( key ) == nil ) then 
		local tbl = {}

		tbl.radius = radius 
		tbl.actualSize = actualSize

		self:SetDynamicRadiusKey( key, tbl )
	end 
end 

function RADAR:GetRadiusData( key )
	return self.vars.sphereSizes[key].radius or 5.0, self.vars.sphereSizes[key].actualSize
end 

function RADAR:GetDynamicRadius( veh )
	local mdl = GetEntityModel( veh )
	local key = tostring( mdl )
	local dataExists = self:DoesDynamicRadiusDataExist( key )
	
	if ( not dataExists ) then 
		local min, max = GetModelDimensions( mdl )
		local size = max - min 
		local numericSize = size.x + size.y + size.z 
		local dynamicRadius = UTIL:Clamp( ( numericSize * numericSize ) / 10, 4.0, 10.0 )

		self:InsertDynamicRadiusData( key, dynamicRadius, numericSize )

		return dynamicRadius, numericSize
	end 

	return self:GetRadiusData( key )
end 

function RADAR:GetIntersectedVehIsFrontOrRear( t )
	if ( t > 10.0 ) then 
		return 1 -- vehicle is in front 
	elseif ( t < -10.0 ) then 
		return -1 -- vehicle is behind
	end 

	return 0 -- vehicle is next to self
end 

function RADAR:GetLineHitsSphereAndDir( centre, radius, rayStart, rayEnd )
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

	local rayDist = #( rayEnd - rayStart )
	local distToCentre = #( rayStart - centre ) - ( radius * 2 )

	-- Now all we have to do is compare the squared opposite length and the radius squared, this 
	-- will then tell us if the ray intersects with the sphere.
	-- if ( oppLenSqr < radiusSqr and ( t0 < ( dist + radius ) ) ) then 
	if ( oppLenSqr < radiusSqr and not ( distToCentre > rayDist ) ) then 
		return true, self:GetIntersectedVehIsFrontOrRear( tProj )
	end

	return false, nil 
end 

function RADAR:ShootCustomRay( localVeh, veh, s, e )
	local pos = GetEntityCoords( veh )
	local dist = #( pos - s )

	if ( DoesEntityExist( veh ) and veh ~= localVeh and dist < self:GetMaxCheckDist() ) then 
		local entSpeed = GetEntitySpeed( veh )
		local visible = HasEntityClearLosToEntity( localVeh, veh, 15 ) -- 13 seems okay, 15 too (doesn't grab ents through ents)

		if ( entSpeed > 0.1 and visible ) then 
			local radius, size = self:GetDynamicRadius( veh )

			local hit, relPos = self:GetLineHitsSphereAndDir( pos, radius, s, e )

			if ( hit ) then 
				UTIL:DrawDebugSphere( pos.x, pos.y, pos.z, radius, { 255, 0, 0, 40 } )

				return true, relPos, dist, entSpeed, size
			end 
		end
	end 

	return false, nil, nil, nil, nil
end 

function RADAR:GetVehsHitByRay( ownVeh, vehs, s, e )
	local t = {}
	local hasData = false 

	for _, veh in pairs( vehs ) do 
		local hit, relativePos, distance, speed, size = self:ShootCustomRay( ownVeh, veh, s, e )

		if ( hit ) then 
			local d = {}
			d.veh = veh 
			d.relPos = relativePos
			d.dist = UTIL:Round( distance, 2 )
			d.speed = UTIL:Round( speed, 3 )
			d.size = math.ceil( size )

			table.insert( t, d )

			hasData = true 
		end 
	end 

	if ( hasData ) then return t end
end 

function RADAR:CreateRayThread( vehs, from, startX, endX, endY )
	local startP = GetOffsetFromEntityInWorldCoords( from, startX, 0.0, 0.0 )
	local endP = GetOffsetFromEntityInWorldCoords( from, endX, endY, 0.0 )

	UTIL:DrawDebugLine( startP, endP )

	local hitVehs = self:GetVehsHitByRay( from, vehs, startP, endP )

	self:InsertCapturedVehicleData( hitVehs )

	print( "Ray thread: increasing ray state from " .. tostring( self:GetRayTraceState() ) .. " to " .. tostring( self:GetRayTraceState() + 1 ) )
	self:IncreaseRayTraceState()
end 

function RADAR:RunControlManager()
	-- 'Z' key, toggles debug mode 
	if ( IsDisabledControlJustPressed( 1, 20 ) ) then 
		self.config.debug_mode = not self.config.debug_mode
	end 

	-- Change the sort mode 
	if ( IsDisabledControlJustPressed( 1, 105 ) ) then 
		self:ToggleSortMode()
	end 
end 

--[[------------------------------------------------------------------------
	Test time 
------------------------------------------------------------------------]]--
function RADAR:Main()
	-- Get the local player's ped and store it in a variable 
	local ped = PlayerPedId()

	-- Get the vehicle the player is sitting in 
	local plyVeh = GetVehiclePedIsIn( ped, false )

	-- Check to make sure the player is in the driver's seat, and also that the vehicle has a class of VC_EMERGENCY (18)
	if ( DoesEntityExist( plyVeh ) and GetPedInVehicleSeat( plyVeh, -1 ) == ped and GetVehicleClass( plyVeh ) == 18 ) then 
		local plyVehPos = GetEntityCoords( plyVeh )

		-- First stage of the radar - get all of the vehicles hit by the radar
		if ( self:GetRadarStage() == 0 ) then 
			if ( self:GetRayTraceState() == 0 ) then 
				print( "Radar stage at 0, starting ray trace." )
				local vehs = self:GetVehiclePool()

				print( "Resetting captured vehicles and ray trace state." )
				self:ResetCapturedVehicles()
				self:ResetRayTraceState()

				print( "Creating ray threads." )
				for _, v in pairs( self.rayTraces ) do 
					self:CreateRayThread( vehs, plyVeh, v.startVec.x, v.endVec.x, v.endVec.y )
				end 

				print( "Reached end of stage 0." )
				print( "Stage = " .. tostring( self:GetRadarStage() ) .. "\tTrace state = " .. tostring( self:GetRayTraceState() ) )
			elseif ( self:GetRayTraceState() == self:GetNumOfRays() ) then 
				print( "Ray traces finished, increasing radar stage." )
				self:IncreaseRadarStage()
			end 
		elseif ( self:GetRadarStage() == 1 ) then 
			print( "Radar stage now 1." )

			self:FilterCapturedVehicles()
			local caughtVehs = self:GetCapturedVehicles()

			if ( not UTIL:IsTableEmpty( caughtVehs ) ) then 
				table.sort( caughtVehs, self:GetSortModeFunc() )

				print( "Printing table for sort mode " .. self:GetSortModeText() )
				for k, v in pairs( caughtVehs ) do 
					print( tostring( k ) .. " - " .. tostring( v.veh ) .. " - " .. tostring( v.relPos ) .. " - " .. tostring( v.dist ) .. " - " .. tostring( v.speed ) .. " - " .. tostring( v.size ) )
				end

				self.caughtEnt = caughtVehs[1].veh
			else
				self.caughtEnt = 0
			end

			self:ResetRadarStage()
			self:ResetRayTraceState()
		end 
	end 
end 

function RADAR:Mainold()
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

-- Update the vehicle pool every 3 seconds
Citizen.CreateThread( function() 
	while ( true ) do
		local vehs = RADAR:GetAllVehicles()

		RADAR:SetVehiclePool( vehs )

		Citizen.Wait( 3000 )
	end 
end )

-- Main thread
Citizen.CreateThread( function()
	RADAR:CacheNumOfRays()

	while ( true ) do
		RADAR:Main()
		-- RADAR:Test()

		Citizen.Wait( 50 )
	end
end )

-- Control manager 
Citizen.CreateThread( function()
	while ( true ) do 
		RADAR:RunControlManager()

		Citizen.Wait( 0 )
	end 
end )

Citizen.CreateThread( function()
	while ( true ) do
		local pos = GetEntityCoords( RADAR.caughtEnt )
		local speed = GetEntitySpeed( RADAR.caughtEnt )

		DrawMarker( 28, pos.x, pos.y, pos.z + 6, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.5, 0.5, 3.0, 255, 255, 255, 255, false, true, 2, nil, nil, false )

		UTIL:DrawDebugText( 0.500, 0.700, 0.80, true, "Ent: " .. tostring( RADAR.caughtEnt ) .. "\nSpeed: " .. RADAR:GetVehSpeedFormatted( speed ) .. "mph" )

		Citizen.Wait( 0 )
	end 
end )