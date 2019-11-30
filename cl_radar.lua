--[[------------------------------------------------------------------------

	Wraith ARS 2X - v1.0.0
	Created by WolfKnight

------------------------------------------------------------------------]]--

local next = next 
local dot = dot 
local table = table 
local type = type
local tostring = tostring
local math = math 
local pairs = pairs 

--[[------------------------------------------------------------------------
	Resource Rename Fix - for those muppets who rename the resource and 
	complain that the NUI aspect doesn't work!
------------------------------------------------------------------------]]--
Citizen.SetTimeout( 1000, function()
	-- Get the name of the resource, for example the default name is 'wk_wrs2'
	local name = GetCurrentResourceName()

	print( "WK_WARS2X: Sending resource name (" .. name .. ") to JavaScript side." )

	-- Send a message through the NUI system to the JavaScript file to give the name of the resource 
	SendNUIMessage( { _type = "updatePathName", pathName = name } )
end )


--[[------------------------------------------------------------------------
	Player info variables
------------------------------------------------------------------------]]--
PLY = {}
PLY.ped = PlayerPedId()
PLY.veh = nil 
PLY.inDriverSeat = false 


--[[------------------------------------------------------------------------
	Radar variables
------------------------------------------------------------------------]]--
RADAR.vars = 
{
	-- The radar's power
	power = false, 
	poweringUp = false, 

	-- These are the settings that are used in the operator menu 
	settings = {
		menuActive = false, 
		fastDisplay = true, 
		oppSensitivity = 5, 
		sameSensitivity = 5, 
		alert = true 
	},

	-- Player's vehicle speed, this is used to update the patrol vehicle speed on the radar
	patrolSpeed = 0,
	patrolLocked = false, 
	psBlank = false, 

	-- The speed type, this is used when converting speeds to a readable format
	-- Either "mph" or "kmh", can be toggle in-game 
	speedType = "mph",

	-- Antennas, this table contains all of the data needed for operation of the front and rear antennas 
	antennas = {
		-- Variables for the front antenna 
		[ "front" ] = {
			xmit = false,		-- Whether the antenna is on or off
			mode = 0,			-- Current antenna mode, 0 = none, 1 = same, 2 = opp, 3 = same and opp 
			speed = 0,			-- Speed of the vehicle caught by the front antenna 
			dir = nil, 			-- Direction the caught vehicle is going, 0 = towards, 1 = away
			fastMode = 1, 		-- Current fast mode, 1 = polling, 2 = lock on at first fast vehicle 
			fastSpeed = 0, 		-- Speed of the fastest vehicle caught by the front antenna
			fastDir = nil, 		-- Direction the fastest vehicle is going, 0 = towards, 1 = away  
			fastLocked = false	-- Whether the fast speed is locked or not 
		}, 

		[ "rear" ] = {
			xmit = false,		-- Whether the antenna is on or off
			mode = 0,			-- Current antenna mode, 0 = none, 1 = same, 2 = opp, 3 = same and opp 
			speed = 0,			-- Speed of the vehicle caught by the front antenna 
			dir = nil, 			-- Direction the caught vehicle is going, 0 = towards, 1 = away
			fastMode = 1, 		-- Current fast mode, 1 = polling, 2 = lock on at first fast vehicle 
			fastSpeed = 0, 		-- Speed of the fastest vehicle caught by the front antenna
			fastDir = nil, 		-- Direction the fastest vehicle is going, 0 = towards, 1 = away  
			fastLocked = false	-- Whether the fast speed is locked or not 
		}
	}, 

	-- The maximum distance that the radar system's ray traces can go 
	maxCheckDist = 300.0,

	-- Cached dynamic vehicle sphere sizes, automatically populated when the system is running 
	sphereSizes = {}, 

	-- Vehicle pool, automatically populated when the system is running, holds all of the current
	-- vehicle IDs for the player using entity enumeration (see cl_utils.lua) 
	vehiclePool = {}, 

	-- Radar stage, this is used to tell the system what it should currently be doing, the stages are:
	--    - 0 = Gathering vehicles hit by the rays 
	--    - 1 = Filtering the vehicles caught (removing duplicates, etc) and calculating what needs to be shown 
	--	        to the user based on modes and settings
	--    - 2 = Sending all required data across to the NUI system for display 
	radarStage = 0,

	-- Ray trace state, this is used so the radar stage doesn't progress to the next stage unless 
	-- all of the ray trace threads have completed 
	rayTraceState = 0,

	-- Number of ray traces, automatically cached when the system first runs 
	numberOfRays = 0
}

-- Table to store entity IDs of captured vehicles 
RADAR.capturedVehicles = {}

-- The current vehicle data for display 
RADAR.activeVehicles = {}

-- These vectors are used in the custom ray tracing system 
RADAR.rayTraces = {
	-- { startVec = { x = 0.0,   y = 5.0  }, endVec = { x = 0.0,    y = 150.0 }, rayType = "same" },
	-- { startVec = { x = -5.0,  y = 15.0 }, endVec = { x = -5.0,   y = 150.0 }, rayType = "same" },
	-- { startVec = { x = 5.0,   y = 15.0 }, endVec = { x = 5.0,    y = 150.0 }, rayType = "same" },
	{ startVec = { x = 3.0 }, endVec = { x = 3.0, y = 150.0 }, rayType = "same" },
	{ startVec = { x = -2.0 }, endVec = { x = -2.0, y = 150.0 }, rayType = "same" },
	{ startVec = { x = -10.0 }, endVec = { x = -10.0, y = 150.0 }, rayType = "opp" },
	{ startVec = { x = -15.0 }, endVec = { x = -15.0, y = 150.0 }, rayType = "opp" }
}

-- Each of these are used for sorting the captured vehicle data, the 'strongest' filter is used for the main 
-- target window of each antenna, whereas the 'fastest' filter is used for the fast target window of each antenna
RADAR.sorting = {
	strongest = function( a, b ) return a.size > b.size end, 
	fastest = function( a, b ) return a.speed > b.speed end
}


--[[------------------------------------------------------------------------
	Radar essentials functions  
------------------------------------------------------------------------]]--
function RADAR:IsPowerOn()
	return self.vars.power 
end 

function RADAR:IsPoweringUp()
	return self.vars.poweringUp
end 

function RADAR:SetPoweringUpState( state )
	self.vars.poweringUp = state 
end 

function RADAR:TogglePower()
	self.vars.power = not self.vars.power 

	SendNUIMessage( { _type = "radarPower", state = self:IsPowerOn() } )

	-- Power is now turned on 
	if ( self:IsPowerOn() ) then 
		self:SetPoweringUpState( true )

		Citizen.SetTimeout( 2000, function()
			self:SetPoweringUpState( false )

			SendNUIMessage( { _type = "poweredUp" } )
		end )
	else 
		self:ResetAntenna( "front" )
		self:ResetAntenna( "rear" )
	end
end

function RADAR:IsFastDisplayEnabled()
	return self.vars.settings.fastDisplay
end 

function RADAR:ToggleFastDisplay()
	self.vars.settings.fastDisplay = not self.vars.settings.fastDisplay
end 

function RADAR:IsEitherAntennaOn()
	return self:IsAntennaTransmitting( "front" ) or self:IsAntennaTransmitting( "rear" )
end 


--[[------------------------------------------------------------------------
	Radar basics functions  
------------------------------------------------------------------------]]--
function RADAR:GetPatrolSpeed()	
	return self.vars.patrolSpeed
end 

function RADAR:GetVehiclePool()
	return self.vars.vehiclePool
end 

function RADAR:GetMaxCheckDist()
	return self.vars.maxCheckDist
end 

function RADAR:GetActiveVehicles()
	return self.activeVehicles
end 

function RADAR:GetStrongestSortFunc()
	return self.sorting.strongest 
end 

function RADAR:GetFastestSortFunc()
	return self.sorting.fastest
end 

function RADAR:SetPatrolSpeed( speed )
	if ( type( speed ) == "number" ) then 
		self.vars.patrolSpeed = self:GetVehSpeedFormatted( speed )
	end
end

function RADAR:SetVehiclePool( pool )
	if ( type( pool ) == "table" ) then 
		self.vars.vehiclePool = pool 
	end
end 

function RADAR:SetActiveVehicles( vehs )
	if ( type( vehs ) == "table" ) then 
		self.activeVehicles = vehs
	end 
end 


--[[------------------------------------------------------------------------
	Radar ray trace functions 
------------------------------------------------------------------------]]--
function RADAR:GetRayTraceState()
	return self.vars.rayTraceState
end

function RADAR:CacheNumRays()
	self.vars.numberOfRays = #self.rayTraces
end 

function RADAR:GetNumOfRays()
	return self.vars.numberOfRays
end

function RADAR:IncreaseRayTraceState()
	self.vars.rayTraceState = self.vars.rayTraceState + 1
end 

function RADAR:ResetRayTraceState()
	self.vars.rayTraceState = 0
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

function RADAR:ShootCustomRay( plyVeh, veh, s, e )
	local pos = GetEntityCoords( veh )
	local dist = #( pos - s )

	if ( DoesEntityExist( veh ) and veh ~= plyVeh and dist < self:GetMaxCheckDist() ) then 
		local entSpeed = GetEntitySpeed( veh )
		local visible = HasEntityClearLosToEntity( plyVeh, veh, 15 ) -- 13 seems okay, 15 too (doesn't grab ents through ents)

		if ( entSpeed > 0.1 and visible ) then 
			local radius, size = self:GetDynamicRadius( veh )

			local hit, relPos = self:GetLineHitsSphereAndDir( pos, radius, s, e )

			if ( hit ) then 
				-- UTIL:DrawDebugSphere( pos.x, pos.y, pos.z, radius, { 255, 0, 0, 40 } )

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
			-- d.dist = UTIL:Round( distance, 2 ) -- Possibly remove 
			-- d.speed = UTIL:Round( speed, 3 )
			d.dist = distance
			d.speed = speed
			d.size = size

			table.insert( t, d )

			hasData = true 
		end 
	end 

	if ( hasData ) then return t end
end 

function RADAR:CreateRayThread( vehs, from, startX, endX, endY, rayType )
	local startPoint = GetOffsetFromEntityInWorldCoords( from, startX, 0.0, 0.0 )
	local endPoint = GetOffsetFromEntityInWorldCoords( from, endX, endY, 0.0 )

	local hitVehs = self:GetVehsHitByRay( from, vehs, startPoint, endPoint )

	self:InsertCapturedVehicleData( hitVehs, rayType )

	self:IncreaseRayTraceState()
end 

function RADAR:CreateRayThreads( ownVeh, vehicles )
	for _, v in pairs( self.rayTraces ) do 
		self:CreateRayThread( vehicles, ownVeh, v.startVec.x, v.endVec.x, v.endVec.y, v.rayType )
	end 
end 


--[[------------------------------------------------------------------------
	Radar stage functions 
------------------------------------------------------------------------]]--
function RADAR:GetRadarStage()
	return self.vars.radarStage
end

function RADAR:IncreaseRadarStage()
	self.vars.radarStage = self.vars.radarStage + 1
end 

function RADAR:ResetRadarStage()
	self.vars.radarStage = 0
end


--[[------------------------------------------------------------------------
	Radar antenna functions 
------------------------------------------------------------------------]]--
function RADAR:ToggleAntenna( ant, cb )
	if ( self:IsPowerOn() ) then 
		self.vars.antennas[ant].xmit = not self.vars.antennas[ant].xmit 

		if ( cb ) then cb() end 
	end 
end 

function RADAR:IsAntennaTransmitting( ant )
	return self.vars.antennas[ant].xmit 
end 

function RADAR:GetAntennaTextFromNum( relPos )
	if ( relPos == 1 ) then 
		return "front"
	elseif ( relPos == -1 ) then 
		return "rear"
	end 
end 

function RADAR:GetAntennaMode( ant )
	return self.vars.antennas[ant].mode 
end 

function RADAR:SetAntennaMode( ant, mode, cb )
	if ( type( mode ) == "number" ) then 
		if ( mode >= 0 and mode <= 3 and self:IsPowerOn() ) then 
			self.vars.antennas[ant].mode = mode 

			if ( cb ) then cb() end 
		end 
	end 
end 

function RADAR:SetAntennaSpeed( ant, speed ) 
	if ( type( speed ) == "number" ) then 
		if ( speed >= 0 and speed <= 999 ) then 
			self.vars.antennas[ant].speed = speed
		end 
	end 
end 

function RADAR:SetAntennaDir( ant, dir )
	if ( type( dir ) == "number" ) then 
		if ( dir == 0 or dir == 1 ) then 
			self.vars.antennas[ant].dir = dir 
		end 
	end 
end 

function RADAR:SetAntennaFastMode( ant, mode )
	if ( type( mode ) == "number" ) then 
		if ( mode == 1 or mode == 2 ) then 
			self.vars.antennas[ant].fastMode = mode 
		end 
	end 
end 

function RADAR:SetAntennaFastSpeed( ant, speed ) 
	if ( type( speed ) == "number" ) then 
		if ( speed >= 0 and speed <= 999 ) then 
			self.vars.antennas[ant].fastSpeed = speed
		end 
	end 
end 

function RADAR:SetAntennaFastDir( ant, dir )
	if ( type( dir ) == "number" ) then 
		if ( dir == 0 or dir == 1 ) then 
			self.vars.antennas[ant].fastDir = dir 
		end 
	end 
end 

function RADAR:SetAntennaFastLock( ant, state )
	if ( type( state ) == "boolean" ) then 
		self.vars.antennas[ant].fastLocked = state 
	end 
end 

function RADAR:ResetAntenna( ant )
	-- Overwrite default behaviour, this is because when the system is turned off, the temporary memory is
	-- technically reset, as the setter functions require either the radar power to be on or the antenna to 
	-- be transmitting, this is the only way to reset the values
	self.vars.antennas[ant].xmit = false 
	self.vars.antennas[ant].mode = 0
end 


--[[------------------------------------------------------------------------
	Radar captured vehicle functions 
------------------------------------------------------------------------]]--
function RADAR:GetCapturedVehicles()
	return self.capturedVehicles
end

function RADAR:ResetCapturedVehicles()
	self.capturedVehicles = {}
end

function RADAR:InsertCapturedVehicleData( t, rt )
	if ( type( t ) == "table" and not UTIL:IsTableEmpty( t ) ) then 
		for _, v in pairs( t ) do
			v.rayType = rt 
			table.insert( self.capturedVehicles, v )
		end
	end 
end 


--[[------------------------------------------------------------------------
	Radar dynamic sphere radius functions 
------------------------------------------------------------------------]]--
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
		local t = {}

		t.radius = radius 
		t.actualSize = actualSize

		self:SetDynamicRadiusKey( key, t )
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
		local dynamicRadius = UTIL:Clamp( ( numericSize * numericSize ) / 12, 4.0, 10.0 )

		self:InsertDynamicRadiusData( key, dynamicRadius, numericSize )

		return dynamicRadius, numericSize
	end 

	return self:GetRadiusData( key )
end


--[[------------------------------------------------------------------------
	Radar functions 
------------------------------------------------------------------------]]--
function RADAR:GetVehSpeedFormatted( speed )
	if ( self.vars.speedType == "mph" ) then 
		return UTIL:Round( math.ceil( speed * 2.236936 ), 0 )
	else 
		return UTIL:Round( math.ceil( speed * 3.6 ), 0 )
	end 
end 
 
function RADAR:GetAllVehicles()
	local t = {}

	for v in UTIL:EnumerateVehicles() do
		table.insert( t, v )
	end 

	return t
end 

function RADAR:CheckVehicleDataFitsMode( ant, rt )
	local mode = self:GetAntennaMode( ant )

	if ( ( mode == 3 ) or ( mode == 1 and rt == "same" ) or ( mode == 2 and rt == "opp" ) ) then return true end 

	return false  
end

function RADAR:GetVehiclesForAntenna()
	local vehs = { ["front"] = {}, ["rear"] = {} }
	local results = { ["front"] = { nil, nil }, ["rear"] = { nil, nil } }

	-- Loop through and split up the vehicles based on front and rear, this is simply because the actual system 
	-- that gets all of the vehicles hit by the radar only has a relative position of either 1 or -1, which we 
	-- then convert below into an antenna string!
	for ant in UTIL:Values( { "front", "rear" } ) do 
		if ( self:IsAntennaTransmitting( ant ) ) then 
			for k, v in pairs( self:GetCapturedVehicles() ) do 
				local antText = self:GetAntennaTextFromNum( v.relPos )

				if ( ant == antText ) then 
					table.insert( vehs[ant], v )
				end 
			end 

			-- As the radar is based on how the real Stalker DSR 2X works, we now sort the dataset by
			-- the 'strongest' (largest) target, this way the first result for the front and rear data
			-- will be the one that gets displayed in the target boxes.
			table.sort( vehs[ant], self:GetStrongestSortFunc() )
		end
	end 

	for ant in UTIL:Values( { "front", "rear" } ) do 
		if ( not UTIL:IsTableEmpty( vehs[ant] ) ) then
			-- Get the 'strongest' vehicle for the antenna 
			for k, v in pairs( vehs[ant] ) do 
				if ( self:CheckVehicleDataFitsMode( ant, v.rayType ) ) then 
					results[ant][1] = v
					break
				end 
			end 

			if ( self:IsFastDisplayEnabled() ) then 
				-- Get the 'fastest' vehicle for the antenna 
				table.sort( vehs[ant], self:GetFastestSortFunc() )

				for k, v in pairs( vehs[ant] ) do 
					if ( self:CheckVehicleDataFitsMode( ant, v.rayType ) and v.veh ~= results[ant][1].veh and v.size + 0.75 < results[ant][1].size ) then 
						results[ant][2] = v 
						break
					end 
				end 
			end
		end 
	end

	return { ["front"] = { results["front"][1], results["front"][2] }, ["rear"] = { results["rear"][1], results["rear"][2] } }
end 

-- Num4 = 108 - INPUT_VEH_FLY_ROLL_LEFT_ONLY
-- Num5 = 112 - INPUT_VEH_FLY_PITCH_DOWN_ONLY
-- Num6 = 109 - INPUT_VEH_FLY_ROLL_RIGHT_ONLY
-- Num7 = 117 - INPUT_VEH_FLY_SELECT_TARGET_LEFT
-- Num8 = 111 - INPUT_VEH_FLY_PITCH_UP_ONLY
-- Num9 = 118 - INPUT_VEH_FLY_SELECT_TARGET_RIGHT
-- F5 = 166 - INPUT_SELECT_CHARACTER_MICHAEL
function RADAR:RunControlManager()
	-- 'Z' key, toggles debug mode 
	if ( IsDisabledControlJustPressed( 1, 20 ) ) then 
		self.config.debug_mode = not self.config.debug_mode
	end
	
	if ( IsDisabledControlJustPressed( 1, 166 ) ) then 
		SendNUIMessage( { _type = "openRemote" } )
		SetNuiFocus( true, true )
	end 

	if ( IsDisabledControlJustPressed( 1, 117 ) ) then 
		self:TogglePower()
		UTIL:Notify( "Radar power toggled." )
	end 

	if ( IsDisabledControlJustPressed( 1, 118 ) ) then 
		self:ToggleFastDisplay()
		UTIL:Notify( "Fast display toggled." )
	end 

	-- 'Num8' key, toggles front antenna
	--[[ if ( IsDisabledControlJustPressed( 1, 111 ) ) then 
		self:ToggleAntenna( "front" )
		UTIL:Notify( "Front antenna toggled." )
	end 

	-- 'Num5' key, toggles rear antenna
	if ( IsDisabledControlJustPressed( 1, 112 ) ) then 
		self:ToggleAntenna( "rear" )
		UTIL:Notify( "Rear antenna toggled." )
	end ]]
end 


--[[------------------------------------------------------------------------
	NUI callback
------------------------------------------------------------------------]]--
RegisterNUICallback( "togglePower", function()
	RADAR:TogglePower()
end )

RegisterNUICallback( "closeRemote", function()
	SetNuiFocus( false, false )
end )

RegisterNUICallback( "setAntennaMode", function( data ) 
	RADAR:SetAntennaMode( data.value, tonumber( data.mode ), function()
		SendNUIMessage( { _type = "antennaMode", ant = data.value, mode = tonumber( data.mode ) } )
	end )
end )

RegisterNUICallback( "toggleAntenna", function( data ) 
	RADAR:ToggleAntenna( data.value, function()
		SendNUIMessage( { _type = "antennaXmit", ant = data.value, on = RADAR:IsAntennaTransmitting( data.value ) } )
	end )
end )


--[[------------------------------------------------------------------------
	Main function  
------------------------------------------------------------------------]]--
function RADAR:Main()
	-- Check to make sure the player is in the driver's seat, and also that the vehicle has a class of VC_EMERGENCY (18)
	if ( DoesEntityExist( PLY.veh ) and PLY.inDriverSeat and GetVehicleClass( PLY.veh ) == 18 and self:IsPowerOn() and not self:IsPoweringUp() ) then 
		local plyVehPos = GetEntityCoords( PLY.veh )

		-- First stage of the radar - get all of the vehicles hit by the radar
		if ( self:GetRadarStage() == 0 ) then 
			if ( self:GetRayTraceState() == 0 ) then 
				local vehs = self:GetVehiclePool()

				self:ResetCapturedVehicles()
				self:ResetRayTraceState()
				self:CreateRayThreads( PLY.veh, vehs )
			elseif ( self:GetRayTraceState() == self:GetNumOfRays() ) then 
				self:IncreaseRadarStage()
			end 
		elseif ( self:GetRadarStage() == 1 ) then 
			local data = {} 

			-- Get the player's vehicle speed
			local entSpeed = GetEntitySpeed( PLY.veh )

			if ( entSpeed == 0 ) then 
				data.patrolSpeed = "¦[]"
			else 
				local speed = self:GetVehSpeedFormatted( entSpeed )
				data.patrolSpeed = UTIL:FormatSpeed( speed )
			end 

			-- Only grab data to send if there have actually been vehicles captured by the radar
			if ( not UTIL:IsTableEmpty( self:GetCapturedVehicles() ) ) then 
				local vehsForDisplay = self:GetVehiclesForAntenna()

				self:SetActiveVehicles( vehsForDisplay ) -- not really any point in setting this 
			else
				self:SetActiveVehicles( { ["front"] = { nil, nil }, ["rear"] = { nil, nil } } )
			end

			-- Work out what has to be sent 
			local av = self:GetActiveVehicles()
			data.antennas = { ["front"] = nil, ["rear"] = nil }

			for ant in UTIL:Values( { "front", "rear" } ) do 
				if ( self:IsAntennaTransmitting( ant ) ) then
					data.antennas[ant] = {}

					for i = 1, 2 do 
						data.antennas[ant][i] = { speed = "¦¦¦", dir = 0 }

						-- The vehicle data exists for this slot 
						if ( av[ant][i] ~= nil ) then 
							-- We already have the vehicle speed as we needed it earlier on for filtering 
							data.antennas[ant][i].speed = UTIL:FormatSpeed( self:GetVehSpeedFormatted( av[ant][i].speed ) )

							-- Work out if the vehicle is closing or away 
							local ownH = GetEntityHeading( PLY.veh )
							local tarH = GetEntityHeading( av[ant][i].veh )
							data.antennas[ant][i].dir = UTIL:GetEntityRelativeDirection( ownH, tarH, 120 )
						end 
					end 
				end 
			end 

			-- Send the update to the NUI side
			SendNUIMessage( { _type = "update", speed = data.patrolSpeed, antennas = data.antennas } )

			self:ResetRadarStage()
			self:ResetRayTraceState()
		end 
	end 
end 

-- Updates the local player information 
Citizen.CreateThread( function()
	while ( true ) do 
		PLY.ped = PlayerPedId()
		PLY.veh = GetVehiclePedIsIn( PLY.ped, false )
		PLY.inDriverSeat = GetPedInVehicleSeat( PLY.veh, -1 ) == PLY.ped 

		Citizen.Wait( 250 )
	end 
end )

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
	SetNuiFocus( false, false )

	RADAR:CacheNumRays()

	while ( true ) do
		RADAR:Main()

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




------------------------------ DEBUG ------------------------------
Citizen.CreateThread( function()
	while ( true ) do 
		-- Ray line drawing
		-- local veh = GetVehiclePedIsIn( PlayerPedId(), false )

		for k, v in pairs( RADAR.rayTraces ) do 
			local startP = GetOffsetFromEntityInWorldCoords( PLY.veh, v.startVec.x, 0.0, 0.0 )
			local endP = GetOffsetFromEntityInWorldCoords( PLY.veh, v.endVec.x, v.endVec.y, 0.0 )

			UTIL:DrawDebugLine( startP, endP )
		end

		local av = RADAR:GetActiveVehicles()

		for ant in UTIL:Values( { "front", "rear" } ) do 
			for i = 1, 2, 1 do 
				if ( av[ant] ~= nil and av[ant][i] ~= nil ) then 
					local pos = GetEntityCoords( av[ant][i].veh )
					local r = RADAR:GetDynamicRadius( av[ant][i].veh )

					if ( i == 1 ) then 
						UTIL:DrawDebugSphere( pos.x, pos.y, pos.z, r, { 255, 127, 0, 100 } )
					else 
						UTIL:DrawDebugSphere( pos.x, pos.y, pos.z, r, { 255, 0, 0, 100 } )
					end 
				end 
			end
		end 

		Citizen.Wait( 0 )
	end 
end )

--[[ local types = { "FRONT", "FRONT FAST", "REAR", "REAR FAST" }

Citizen.CreateThread( function()
	while ( true ) do
		-- Caught veh debug printing 
		local av = RADAR:GetActiveVehicles()

		DrawRect( 0.500, 0.850, 0.400, 0.220, 0, 0, 0, 150 )

		for i = 1, 4, 1 do 
			UTIL:DrawDebugText( 0.250 + ( 0.100 * i ), 0.750, 0.60, true, types[i] )

			if ( av[i] ~= nil ) then 
				local pos = GetEntityCoords( av[i].veh )
				local speed = RADAR:GetVehSpeedFormatted( GetEntitySpeed( av[i].veh ) )
				local veh = av[i].veh
				local rt = av[i].rayType
				local dir = UTIL:GetEntityRelativeDirection( GetEntityHeading( GetVehiclePedIsIn( PlayerPedId(), false ) ), GetEntityHeading( veh ), 100 )
				
				if ( dir == 1 ) then dir = "/\\" elseif ( dir == 2 ) then dir = "\\/" else dir = "none" end

				DrawMarker( 2, pos.x, pos.y, pos.z + 3, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 0, 70, false, true, 2, nil, nil, false )

				if ( i % 2 == 0 ) then 
					UTIL:DrawDebugText( 0.250 + ( 0.100 * i ), 0.800, 0.60, true, "Ent: " .. tostring( veh ) .. "\nSpeed: ~r~" .. tostring( speed ) .. "~s~mph" .. "\nRay type: " .. tostring( rt ) .. "\nDir: " .. tostring( dir ) )
				else 
					UTIL:DrawDebugText( 0.250 + ( 0.100 * i ), 0.800, 0.60, true, "Ent: " .. tostring( veh ) .. "\nSpeed: " .. tostring( speed ) .. "mph" .. "\nRay type: " .. tostring( rt ) .. "\nDir: " .. tostring( dir ) )
				end 
			else 
				UTIL:DrawDebugText( 0.250 + ( 0.100 * i ), 0.800, 0.60, true, "Ent: nil" .. "\nSpeed: nil" .. "\nRay type: nil" .. "\nDir: nil" )
			end 
		end

		-- Ray line drawing
		local veh = GetVehiclePedIsIn( PlayerPedId(), false )

		for k, v in pairs( RADAR.rayTraces ) do 
			local startP = GetOffsetFromEntityInWorldCoords( veh, v.startVec.x, 0.0, 0.0 )
			local endP = GetOffsetFromEntityInWorldCoords( veh, v.endVec.x, v.endVec.y, 0.0 )

			UTIL:DrawDebugLine( startP, endP )
		end 

		Citizen.Wait( 0 )
	end 
end ) ]]

-- Commands for debugging 
RegisterCommand( "rdr", function( src, args, raw )
	if ( args[1] == "setlimit" ) then 
		RADAR:SetFastLimit( tonumber( args[2] ) ) 
	elseif ( args[1] == "setmode" ) then 
		if ( args[2] == "front" or args[2] == "rear" ) then 
			RADAR:SetAntennaMode( args[2], tonumber( args[3] ) )
		end 
	end 
end, false )