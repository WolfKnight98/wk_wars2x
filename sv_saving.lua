--[[-----------------------------------------------------------------------

	Wraith ARS 2X
	Created by WolfKnight

-----------------------------------------------------------------------]]--

local DATASAVE = {}
DATASAVE.dir = "saves"

-- Change this to whatever ID type you want to use for saving user data 
-- Options are:
--  - steam
--  - license
--  - xbl 
--  - live
--  - discord
--  - fivem
--  - ip 
DATASAVE.idType = "license"

-- Saves the data for the given player into the saves folder within the resource
function DATASAVE:SavePlayerData( src, data )
	-- Get the player's identifier
	local id = self:GetIdentifier( src )

	-- Save the JSON file into the saves folder
	SaveResourceFile( GetCurrentResourceName(), self.dir .. "/" .. id .. ".json", json.encode( data ), -1 )
	
	-- Print out a message in the console to say the player's UI data has been saved
	self:Print( "Saved UI data for " .. GetPlayerName( src ) .. " (ID: " .. src .. ")" )
end 

-- Attempts to retrieve the UI data for the given player
function DATASAVE:GetPlayerData( src )
	-- Get the player's identifier
	local id = self:GetIdentifier( src )
	
	-- Try to grab the raw data from the player's JSON file 
	local rawData = LoadResourceFile( GetCurrentResourceName(), self.dir .. "/" .. id .. ".json" )

	-- In the event there is no file for the player, return nil 
	if ( rawData == nil ) then 
		return nil
	end 

	-- Decode the JSON data into a Lua table 
	local data = json.decode( rawData )

	-- Return the data
	return data
end 

-- Checks that the given data is valid, helps to stop modified data from being sent through the save system 
function DATASAVE:CheckDataIsValid( data )
	-- First we check to make sure the data being passed is actually a table 
	if ( type( data ) ~= "table" ) then return false end 

	-- Then we check to make sure that the data has only 3 elements, "remote", "radar", "reader" and "safezone"
	local c = 0 
	for _ in pairs( data ) do c = c + 1 end 

	-- If there isn't 4 elements, then the data isn't valid
	if ( c ~= 4 ) then return false end 

	return true 
end 

-- Gets the identifier for the given player based on the identifier type specified at the top 
function DATASAVE:GetIdentifier( src )
	-- Get the number of identifiers the player has
	local max = GetNumPlayerIdentifiers( src )

	-- Iterate through the identifier numerical range 
	for i = 0, max do
		-- Get the current identifier 
		local id = GetPlayerIdentifier( src, i )

		-- In the event the identifier is nil, report it to the server console and return nil 
		if ( id == nil ) then 
			self:Print( "^1It appears there was an error trying to find the specified ID (" .. self.idType .. ") for player " .. GetPlayerName( source ) )
			return nil
		end 
		
		-- If we find the identifier type set in DATASAVE.idType, then we have the identifier
		if ( string.find( id, self.idType, 1 ) ) then 
			-- Split the identifier so we just get the actual identifier
			local split = self:SplitString( id, ":" )

			-- Return the identifier
			return split[2]
		end 
	end 

	-- In the event we get nothing, return nil 
	return nil
end  

-- Your typical split string function! 
function DATASAVE:SplitString( inputstr, sep )
	if ( sep == nil ) then
		sep = "%s"
	end

	local t = {}
	local i = 1
	
	for str in string.gmatch( inputstr, "([^" .. sep .. "]+)" ) do
		t[i] = str
		i = i + 1
	end

	return t
end

-- Prints the given message with the resource name attached
function DATASAVE:Print( msg )
	print( "^3[wk_wars2x] ^0" .. msg .. "^0" )
end 

-- Serverside event for saving a player's UI data
RegisterServerEvent( "wk:saveUiData" )
AddEventHandler( "wk:saveUiData", function( data ) 
	-- Check to make sure that the data being sent by the client is valid 
	local valid = DATASAVE:CheckDataIsValid( data )

	-- Only proceed if the data is actually valid
	if ( valid ) then 
		DATASAVE:SavePlayerData( source, data )
	else 
		-- Print a message to the console saying the data sent by the client is not valid, this should rarely occur but it could be because
		-- the client has modified the data being sent (mods/injections)
		DATASAVE:Print( "^1Save data being sent from " .. GetPlayerName( source ) .. " (ID: " .. source .. ") is not valid, either something went wrong, or the player has modified the data being sent." )
	end 
end ) 

-- Serverside event for when the player loads in and the system needs to get their saved UI data 
RegisterServerEvent( "wk:getUiData" )
AddEventHandler( "wk:getUiData", function()
	-- Try and get the player's data 
	local data = DATASAVE:GetPlayerData( source )

	-- Send the client the data if we get any 
	if ( data ) then 
		TriggerClientEvent( "wk:loadUiData", source, data )
	else 
		-- When player's first use the radar, they won't have saved UI data
		DATASAVE:Print( "Player " .. GetPlayerName( source ) .. " (ID: " .. source .. ") doesn't have a UI settings file." )
	end 
end )