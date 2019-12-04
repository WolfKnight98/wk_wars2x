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
local PLY = {}
PLY.ped = PlayerPedId()
PLY.veh = nil 
PLY.inDriverSeat = false 
PLY.vehClassValid = false

-- Updates the local player information 
Citizen.CreateThread( function()
	while ( true ) do 
		PLY.ped = PlayerPedId()
		PLY.veh = GetVehiclePedIsIn( PLY.ped, false )
		PLY.inDriverSeat = GetPedInVehicleSeat( PLY.veh, -1 ) == PLY.ped 
		PLY.vehClassValid = GetVehicleClass( PLY.veh ) == 18

		Citizen.Wait( 500 )
	end 
end )


--[[------------------------------------------------------------------------
	Radar variables
------------------------------------------------------------------------]]--
RADAR.vars = 
{
	-- The display state
	displayed = false,

	-- The radar's power
	power = false, 
	poweringUp = false, 

	-- Whether the radar is hidden or not
	hidden = false,

	-- These are the settings that are used in the operator menu 
	settings = {
		["fastDisplay"] = true, 

		-- Sensitivty for each mode, 1-5
		["same"] = 3, 
		["opp"] = 3, 

		["alert"] = true,

		["beep"] = 0.6,

		["speedType"] = "mph"
	},

	menuActive = false, 
	currentOptionIndex = 1, 
	menuOptions = {
		{ displayText = { "¦¦¦", "FAS" }, optionsText = { "On¦", "Off" }, options = { true, false }, optionIndex = 1, settingText = "fastDisplay" },
		{ displayText = { "¦SL", "SEn" }, optionsText = { "¦1¦", "¦2¦", "¦3¦", "¦4¦", "¦5¦" }, options = { 0.2, 0.4, 0.6, 0.8, 1.0 }, optionIndex = 3, settingText = "same" },
		{ displayText = { "¦OP", "SEn" }, optionsText = { "¦1¦", "¦2¦", "¦3¦", "¦4¦", "¦5¦" }, options = { 0.2, 0.4, 0.6, 0.8, 1.0 }, optionIndex = 3, settingText = "opp" },
		{ displayText = { "BEE", "P¦¦" }, optionsText = { "Off", "¦1¦", "¦2¦", "¦3¦", "¦4¦", "¦5¦" }, options = { 0.0, 0.2, 0.4, 0.6, 0.8, 1.0 }, optionIndex = 4, settingText = "beep" },
		{ displayText = { "Uni", "tS¦" }, optionsText = { "USA", "INT" }, options = { "mph", "kmh" }, optionIndex = 1, settingText = "speedType" }
	},

	-- Player's vehicle speed, this is used to update the patrol vehicle speed on the radar
	patrolSpeed = 0,
	patrolLocked = false, 
	psBlank = false, 

	-- Antennas, this table contains all of the data needed for operation of the front and rear antennas 
	antennas = {
		-- Variables for the front antenna 
		[ "front" ] = {
			xmit = false,		-- Whether the antenna is on or off
			mode = 0,			-- Current antenna mode, 0 = none, 1 = same, 2 = opp, 3 = same and opp 
			speed = 0,			-- Speed of the vehicle caught by the front antenna 
			dir = nil, 			-- Direction the caught vehicle is going, 0 = towards, 1 = away
			fastSpeed = 0, 		-- Speed of the fastest vehicle caught by the front antenna
			fastDir = nil, 		-- Direction the fastest vehicle is going, 0 = towards, 1 = away  
			speedLocked = false,
			lockedSpeed = 0,
			lockedDir = 0
		}, 

		[ "rear" ] = {
			xmit = false,		-- Whether the antenna is on or off
			mode = 0,			-- Current antenna mode, 0 = none, 1 = same, 2 = opp, 3 = same and opp 
			speed = 0,			-- Speed of the vehicle caught by the front antenna 
			dir = nil, 			-- Direction the caught vehicle is going, 0 = towards, 1 = away
			fastSpeed = 0, 		-- Speed of the fastest vehicle caught by the front antenna
			fastDir = nil, 		-- Direction the fastest vehicle is going, 0 = towards, 1 = away  
			speedLocked = false,
			lockedSpeed = 0,
			lockedDir = 0
		}
	}, 

	-- The maximum distance that the radar system's ray traces can go 
	maxCheckDist = 300.0,

	-- Cached dynamic vehicle sphere sizes, automatically populated when the system is running 
	sphereSizes = {}, 

	-- Table to store tables for hit entities of captured vehicles 
	capturedVehicles = {},

	-- Table for temp id storage to stop unnecessary trace checks
	tempVehicleIDs = {},

	-- The current vehicle data for display 
	activeVehicles = {},

	-- Vehicle pool, automatically populated when the system is running, holds all of the current
	-- vehicle IDs for the player using entity enumeration (see cl_utils.lua) 
	vehiclePool = {}, 

	-- Ray trace state, this is used so the radar stage doesn't progress to the next stage unless 
	-- all of the ray trace threads have completed 
	rayTraceState = 0,

	-- Number of ray traces, automatically cached when the system first runs 
	numberOfRays = 0,

	threadWaitTime = 500 
}

-- These vectors are used in the custom ray tracing system 
RADAR.rayTraces = {
	{ startVec = { x = 0.0 }, endVec = { x = 0.0, y = 0.0 }, rayType = "same" },
	{ startVec = { x = -5.0 }, endVec = { x = -5.0, y = 0.0 }, rayType = "same" },
	{ startVec = { x = 5.0 }, endVec = { x = 5.0, y = 0.0 }, rayType = "same" },
	-- { startVec = { x = 3.0 }, endVec = { x = 3.0, y = 0.0, baseY = 400.0 }, rayType = "same" },
	-- { startVec = { x = -3.0 }, endVec = { x = -3.0, y = 0.0, baseY = 400.0 }, rayType = "same" },
	{ startVec = { x = -9.0 }, endVec = { x = -10.0, y = 0.0 }, rayType = "opp" },
	{ startVec = { x = -16.0 }, endVec = { x = -16.0, y = 0.0 }, rayType = "opp" }
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

function RADAR:ToggleDisplayState()
	self.vars.displayed = not self.vars.displayed 
	SendNUIMessage( { _type = "toggleDisplay" } )
end 

function RADAR:GetDisplayState()
	return self.vars.displayed
end 

function RADAR:SetSettingValue( setting, value )
	if ( value ~= nil ) then 
		self.vars.settings[setting] = value 

		if ( setting == "same" or setting == "opp" ) then 
			self:UpdateRayEndCoords()
		end 
	end 
end 

function RADAR:GetSettingValue( setting )
	return self.vars.settings[setting]
end

function RADAR:IsFastDisplayEnabled()
	return self.vars.settings["fastDisplay"]
end 

function RADAR:IsEitherAntennaOn()
	return self:IsAntennaTransmitting( "front" ) or self:IsAntennaTransmitting( "rear" )
end 

function RADAR:SendSettingUpdate()
	local antennas = self.vars.antennas 
	local fast = self:IsFastDisplayEnabled()

	SendNUIMessage( { _type = "settingUpdate", antennaData = antennas, fast = fast } )
end 

function RADAR:CanPerformMainTask()
	return self:IsPowerOn() and not self:IsPoweringUp() and not self:IsMenuOpen()
end 

function RADAR:GetThreadWaitTime()
	return self.vars.threadWaitTime
end 

function RADAR:SetThreadWaitTime( time )
	self.vars.threadWaitTime = time 
end 

function RADAR:SetDisplayHidden( state )
	self.vars.hidden = state 
end 

function RADAR:GetDisplayHidden()
	return self.vars.hidden 
end

function RADAR:OpenRemote()
	if ( not IsPauseMenuActive() and PLY.veh > 0 ) then 
		SendNUIMessage( { _type = "openRemote" } )
		SetNuiFocus( true, true )
	end
end 


--[[------------------------------------------------------------------------
	Radar menu functions  
------------------------------------------------------------------------]]--
function RADAR:SetMenuState( state )
	if ( self:IsPowerOn() ) then 
		self.vars.menuActive = state

		if ( state ) then 
			self.vars.currentOptionIndex = 1
		end
	end
end 

function RADAR:IsMenuOpen()
	return self.vars.menuActive
end 

function RADAR:ChangeMenuIndex()
	local temp = self.vars.currentOptionIndex + 1

	if ( temp > #self.vars.menuOptions ) then 
		temp = 1 
	end 

	self.vars.currentOptionIndex = temp

	self:SendMenuUpdate()
end 

function RADAR:GetMenuOptionTable()
	return self.vars.menuOptions[self.vars.currentOptionIndex]
end 

function RADAR:SetMenuOptionIndex( index )
	self.vars.menuOptions[self.vars.currentOptionIndex].optionIndex = index
end 

function RADAR:GetMenuOptionValue()
	local opt = self:GetMenuOptionTable()
	local index = opt.optionIndex

	return opt.options[index]
end 

function RADAR:ChangeMenuOption( dir )
	local opt = self:GetMenuOptionTable()
	local index = opt.optionIndex

	if ( dir == "front" ) then 
		index = index + 1
		if ( index > #opt.options ) then index = 1 end 
	elseif ( dir == "rear" ) then 
		index = index - 1
		if ( index < 1 ) then index = #opt.options end 
	end

	self:SetMenuOptionIndex( index )

	self:SetSettingValue( opt.settingText, self:GetMenuOptionValue() )

	self:SendMenuUpdate()
end 

function RADAR:GetMenuOptionDisplayText()
	return self:GetMenuOptionTable().displayText
end 

function RADAR:GetMenuOptionText()
	local opt = self:GetMenuOptionTable()

	return opt.optionsText[opt.optionIndex]
end 

function RADAR:SendMenuUpdate()
	SendNUIMessage( { _type = "menu", text = self:GetMenuOptionDisplayText(), option = self:GetMenuOptionText() } )
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
	return self.vars.activeVehicles
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
		self.vars.activeVehicles = vehs
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
	if ( t > 8.0 ) then 
		return 1 -- vehicle is in front 
	elseif ( t < -8.0 ) then 
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

	local key = tostring( veh )

	if ( DoesEntityExist( veh ) and veh ~= plyVeh and dist < self:GetMaxCheckDist() and not self:HasVehicleAlreadyBeenHit( key ) ) then 
		local entSpeed = GetEntitySpeed( veh )
		local visible = HasEntityClearLosToEntity( plyVeh, veh, 15 ) -- 13 seems okay, 15 too (doesn't grab ents through ents)

		if ( entSpeed > 0.1 and visible ) then 
			local radius, size = self:GetDynamicRadius( veh )

			local hit, relPos = self:GetLineHitsSphereAndDir( pos, radius, s, e )

			if ( hit ) then 
				-- UTIL:DrawDebugSphere( pos.x, pos.y, pos.z, radius, { 255, 0, 0, 40 } )

				self:SetVehicleHasBeenHit( key )

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

function RADAR:UpdateRayEndCoords()
	for k, v in pairs( self.rayTraces ) do 
		local endY = self:GetSettingValue( v.rayType ) * self:GetMaxCheckDist()
		v.endVec.y = endY
	end 	
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

function RADAR:GetAntennaSpeed( ant )
	return self.vars.antennas[ant].speed 
end 

function RADAR:SetAntennaSpeed( ant, speed ) 
	self.vars.antennas[ant].speed = speed
end 

function RADAR:GetAntennaDir( ant )
	return self.vars.antennas[ant].dir 
end 

function RADAR:SetAntennaDir( ant, dir )
	self.vars.antennas[ant].dir = dir 
end  

function RADAR:GetAntennaFastSpeed( ant )
	return self.vars.antennas[ant].fastSpeed 
end 

function RADAR:SetAntennaFastSpeed( ant, speed ) 
	self.vars.antennas[ant].fastSpeed = speed
end 

function RADAR:GetAntennaFastDir( ant )
	return self.vars.antennas[ant].fastDir
end 

function RADAR:SetAntennaFastDir( ant, dir )
	self.vars.antennas[ant].fastDir = dir 
end 

function RADAR:DoesAntennaHaveValidData( ant )
	return self:GetAntennaSpeed( ant ) ~= nil 
end 

function RADAR:DoesAntennaHaveValidFastData( ant )
	return self:GetAntennaFastSpeed( ant ) ~= nil 
end 

function RADAR:IsAntennaSpeedLocked( ant )
	return self.vars.antennas[ant].speedLocked
end

function RADAR:SetAntennaSpeedIsLocked( ant, state )
	self.vars.antennas[ant].speedLocked = state
end 

function RADAR:SetAntennaSpeedLock( ant, speed, dir )
	if ( speed ~= nil and dir ~= nil ) then 
		self.vars.antennas[ant].lockedSpeed = speed 
		self.vars.antennas[ant].lockedDir = dir 
		
		self:SetAntennaSpeedIsLocked( ant, true )

		SendNUIMessage( { _type = "audio", name = "beep", vol = RADAR:GetSettingValue( "beep" ) } )
	end
end 

function RADAR:ResetAntennaSpeedLock( ant )
	self.vars.antennas[ant].lockedSpeed = nil 
	self.vars.antennas[ant].lockedDir = nil  
	
	self:SetAntennaSpeedIsLocked( ant, false )
end

function RADAR:LockAntennaSpeed( ant )
	if ( self:IsAntennaSpeedLocked( ant ) ) then 
		self:ResetAntennaSpeedLock( ant )
	else 
		local data = { nil, nil }

		if ( self:IsFastDisplayEnabled() and self:DoesAntennaHaveValidFastData( ant ) ) then 
			data[1] = self:GetAntennaFastSpeed( ant )
			data[2] = self:GetAntennaFastDir( ant )	
		else 
			data[1] = self:GetAntennaSpeed( ant )
			data[2] = self:GetAntennaDir( ant )
		end

		self:SetAntennaSpeedLock( ant, data[1], data[2] )
	end 

	SendNUIMessage( { _type = "antennaLock", ant = ant, state = self:IsAntennaSpeedLocked( ant ) } )
end 

function RADAR:ResetAntenna( ant )
	-- Overwrite default behaviour, this is because when the system is turned off, the temporary memory is
	-- technically reset, as the setter functions require either the radar power to be on or the antenna to 
	-- be transmitting, this is the only way to reset the values
	self.vars.antennas[ant].xmit = false 
	self.vars.antennas[ant].mode = 0

	self:ResetAntennaSpeedLock( ant )
end 


--[[------------------------------------------------------------------------
	Radar captured vehicle functions 
------------------------------------------------------------------------]]--
function RADAR:GetCapturedVehicles()
	return self.vars.capturedVehicles
end

function RADAR:ResetCapturedVehicles()
	self.vars.capturedVehicles = {}
end

function RADAR:InsertCapturedVehicleData( t, rt )
	if ( type( t ) == "table" and not UTIL:IsTableEmpty( t ) ) then 
		for _, v in pairs( t ) do
			v.rayType = rt 
			table.insert( self.vars.capturedVehicles, v )
		end
	end 
end 

function RADAR:HasVehicleAlreadyBeenHit( key )
	return self.vars.tempVehicleIDs[key]
end 

function RADAR:SetVehicleHasBeenHit( key )
	self.vars.tempVehicleIDs[key] = true 
end 

function RADAR:ResetTempVehicleIDs()
	self.vars.tempVehicleIDs = {}
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
		local dynamicRadius = UTIL:Clamp( ( numericSize * numericSize ) / 12, 6.0, 10.0 )

		self:InsertDynamicRadiusData( key, dynamicRadius, numericSize )

		return dynamicRadius, numericSize
	end 

	return self:GetRadiusData( key )
end


--[[------------------------------------------------------------------------
	Radar functions 
------------------------------------------------------------------------]]--
function RADAR:GetVehSpeedFormatted( speed )
	if ( self:GetSettingValue( "speedType" ) == "mph" ) then 
		-- return UTIL:Round( math.ceil( speed * 2.236936 ), 0 )
		return UTIL:Round( speed * 2.236936, 0 )
	else 
		-- return UTIL:Round( math.ceil( speed * 3.6 ), 0 )
		return UTIL:Round( speed * 3.6, 0 )
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

				local temp = results[ant][1]

				for k, v in pairs( vehs[ant] ) do 
					if ( self:CheckVehicleDataFitsMode( ant, v.rayType ) and v.veh ~= temp.veh and v.size < temp.size and v.speed > temp.speed ) then 
						results[ant][2] = v 
						break
					end 
				end 
			end
		end 
	end

	return { ["front"] = { results["front"][1], results["front"][2] }, ["rear"] = { results["rear"][1], results["rear"][2] } }
end 


--[[------------------------------------------------------------------------
	NUI callback
------------------------------------------------------------------------]]--
RegisterNUICallback( "toggleDisplay", function()
	RADAR:ToggleDisplayState()
end )

RegisterNUICallback( "togglePower", function()
	RADAR:TogglePower()
end )

RegisterNUICallback( "closeRemote", function()
	SetNuiFocus( false, false )
end )

RegisterNUICallback( "setAntennaMode", function( data ) 
	if ( RADAR:IsPowerOn() and RADAR:IsMenuOpen() ) then 
		RADAR:SetMenuState( false )
		RADAR:SendSettingUpdate()
		SendNUIMessage( { _type = "audio", name = "done", vol = RADAR:GetSettingValue( "beep" ) } )
	else
		RADAR:SetAntennaMode( data.value, tonumber( data.mode ), function()
			SendNUIMessage( { _type = "antennaMode", ant = data.value, mode = tonumber( data.mode ) } )
			SendNUIMessage( { _type = "audio", name = "beep", vol = RADAR:GetSettingValue( "beep" ) } )
		end )
	end 
end )

RegisterNUICallback( "toggleAntenna", function( data ) 
	if ( RADAR:IsPowerOn() and RADAR:IsMenuOpen() ) then 
		RADAR:ChangeMenuOption( data.value )
		SendNUIMessage( { _type = "audio", name = "beep", vol = RADAR:GetSettingValue( "beep" ) } )
	else
		RADAR:ToggleAntenna( data.value, function()
			SendNUIMessage( { _type = "antennaXmit", ant = data.value, on = RADAR:IsAntennaTransmitting( data.value ) } )
			SendNUIMessage( { _type = "audio", name = RADAR:IsAntennaTransmitting( data.value ) and "xmit_on" or "xmit_off", vol = RADAR:GetSettingValue( "beep" ) } )
		end )
	end 
end )

RegisterNUICallback( "menu", function()
	if ( RADAR:IsMenuOpen() ) then 
		RADAR:ChangeMenuIndex()
	else 
		-- Set the menu state to open, which will prevent anything else from working
		RADAR:SetMenuState( true )
		RADAR:SendMenuUpdate()
	end

	SendNUIMessage( { _type = "audio", name = "beep", vol = RADAR:GetSettingValue( "beep" ) } )
end )


--[[------------------------------------------------------------------------
	Main threads   
------------------------------------------------------------------------]]--
function RADAR:RunDynamicThreadWaitCheck()
	local speed = self:GetPatrolSpeed()

	if ( speed < 0.1 ) then 
		self:SetThreadWaitTime( 200 )
	else 
		self:SetThreadWaitTime( 500 )
	end 
end 

Citizen.CreateThread( function()
	while ( true ) do 
		RADAR:RunDynamicThreadWaitCheck()

		Citizen.Wait( 2000 )
	end 
end )

function RADAR:RunThreads()
	if ( DoesEntityExist( PLY.veh ) and PLY.inDriverSeat and PLY.vehClassValid and self:CanPerformMainTask() and self:IsEitherAntennaOn() ) then 
		if ( self:GetRayTraceState() == 0 ) then 
			local vehs = self:GetVehiclePool()

			self:ResetCapturedVehicles()
			self:ResetRayTraceState()
			self:CreateRayThreads( PLY.veh, vehs )

			Citizen.Wait( self:GetThreadWaitTime() )
		elseif ( self:GetRayTraceState() == self:GetNumOfRays() ) then 
			self:ResetRayTraceState()
		end
	end 
end 

Citizen.CreateThread( function()
	while ( true ) do 
		RADAR:RunThreads()

		Citizen.Wait( 0 )
	end 
end )

function RADAR:Main()
	-- Check to make sure the player is in the driver's seat, and also that the vehicle has a class of VC_EMERGENCY (18)
	if ( DoesEntityExist( PLY.veh ) and PLY.inDriverSeat and PLY.vehClassValid and self:CanPerformMainTask() ) then 
		local data = {} 

		-- Get the player's vehicle speed
		local entSpeed = GetEntitySpeed( PLY.veh )
		self:SetPatrolSpeed( entSpeed )

		if ( entSpeed == 0 ) then 
			data.patrolSpeed = "¦[]"
		else 
			local speed = self:GetVehSpeedFormatted( entSpeed )
			data.patrolSpeed = UTIL:FormatSpeed( speed )
		end 

		-- Only grab data to send if there have actually been vehicles captured by the radar
		if ( not UTIL:IsTableEmpty( self:GetCapturedVehicles() ) ) then 
			local vehsForDisplay = self:GetVehiclesForAntenna()

			self:SetActiveVehicles( vehsForDisplay ) 
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

					if ( i == 2 and self:IsAntennaSpeedLocked( ant ) ) then 
						data.antennas[ant][i].speed = self.vars.antennas[ant].lockedSpeed
						data.antennas[ant][i].dir = self.vars.antennas[ant].lockedDir
					else 
						-- The vehicle data exists for this slot 
						if ( av[ant][i] ~= nil ) then 
							-- We already have the vehicle speed as we needed it earlier on for filtering 
							local uSpeed = GetEntitySpeed( av[ant][i].veh )
							data.antennas[ant][i].speed = UTIL:FormatSpeed( self:GetVehSpeedFormatted( uSpeed ) )

							-- Work out if the vehicle is closing or away 
							local ownH = UTIL:Round( GetEntityHeading( PLY.veh ), 0 )
							local tarH = UTIL:Round( GetEntityHeading( av[ant][i].veh ), 0 )
							data.antennas[ant][i].dir = UTIL:GetEntityRelativeDirection( ownH, tarH )

							-- Set the internal antenna data as this actual dataset is valid 
							if ( i % 2 == 0 ) then 
								self:SetAntennaFastSpeed( ant, data.antennas[ant][i].speed )
								self:SetAntennaFastDir( ant, data.antennas[ant][i].dir )
							else 
								self:SetAntennaSpeed( ant, data.antennas[ant][i].speed )
								self:SetAntennaDir( ant, data.antennas[ant][i].dir )
							end 
						else 
							-- If the active vehicle is not valid, we reset the internal data
							if ( i % 2 == 0 ) then 
								self:SetAntennaFastSpeed( ant, nil )
								self:SetAntennaFastDir( ant, nil )
							else 
								self:SetAntennaSpeed( ant, nil )
								self:SetAntennaDir( ant, nil )
							end
						end 
					end 
				end 
			end 
		end 

		-- Send the update to the NUI side
		SendNUIMessage( { _type = "update", speed = data.patrolSpeed, antennas = data.antennas } )

		self:ResetTempVehicleIDs()
		self:ResetRayTraceState()
	end 
end 

-- Main thread
Citizen.CreateThread( function()
	SetNuiFocus( false, false )

	RADAR:CacheNumRays()
	RADAR:UpdateRayEndCoords()

	while ( true ) do
		RADAR:Main()

		Citizen.Wait( 50 )
	end
end )

function RADAR:RunDisplayValidationCheck()
	if ( ( ( PLY.veh == 0 or ( PLY.veh > 0 and not PLY.vehClassValid ) ) and self:GetDisplayState() and not self:GetDisplayHidden() ) or IsPauseMenuActive() and self:GetDisplayState() ) then
		self:SetDisplayHidden( true ) 
		SendNUIMessage( { _type = "hideDisplay", state = true } )
	elseif ( PLY.veh > 0 and PLY.vehClassValid and self:GetDisplayState() and self:GetDisplayHidden() ) then 
		self:SetDisplayHidden( false ) 
		SendNUIMessage( { _type = "hideDisplay", state = false } )
	end 
end

Citizen.CreateThread( function() 
	Citizen.Wait( 100 )

	while ( true ) do 
		RADAR:RunDisplayValidationCheck()

		Citizen.Wait( 100 )
	end 
end )

-- Update the vehicle pool every 3 seconds
function RADAR:UpdateVehiclePool()
	if ( DoesEntityExist( PLY.veh ) and PLY.inDriverSeat and PLY.vehClassValid and self:CanPerformMainTask() and self:IsEitherAntennaOn() ) then 
		local vehs = self:GetAllVehicles()
		self:SetVehiclePool( vehs )
	end 
end 

Citizen.CreateThread( function() 
	while ( true ) do
		RADAR:UpdateVehiclePool()

		Citizen.Wait( 3000 )
	end 
end )

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
		self:OpenRemote()
	end 

	--[[ if ( IsDisabledControlJustPressed( 1, 117 ) ) then 
		self:TogglePower()
		UTIL:Notify( "Radar power toggled." )
	end ]]

	--[[ if ( IsDisabledControlJustPressed( 1, 118 ) ) then 
		self:ToggleFastDisplay()
		UTIL:Notify( "Fast display toggled." )
	end ]]

	-- 'Num8' key, locks speed from front antenna
	if ( IsDisabledControlJustPressed( 1, 111 ) ) then 
		self:LockAntennaSpeed( "front" )
	end 

	-- 'Num5' key, locks speed from rear antenna
	if ( IsDisabledControlJustPressed( 1, 112 ) ) then 
		self:LockAntennaSpeed( "rear" )
	end 
end 

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
		if ( RADAR.config.debug_mode ) then 
			for k, v in pairs( RADAR.rayTraces ) do 
				for i = -1, 1, 2 do 
					local startP = GetOffsetFromEntityInWorldCoords( PLY.veh, v.startVec.x, 0.0, 0.0 )
					local endP = GetOffsetFromEntityInWorldCoords( PLY.veh, v.endVec.x, v.endVec.y * i, 0.0 )

					UTIL:DrawDebugLine( startP, endP )
				end
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
		else
			Citizen.Wait( 500 )
		end 
	end 
end ) 