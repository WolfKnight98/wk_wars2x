if ( CONFIG.debug ) then 
	-- Restart the resource
	RegisterCommand( "rre", function( source, args, rawCommand )
		UTIL:Notify( "[DEBUG]: Restarting resource" )
		ExecuteCommand( "restart wk_wars2x" )
	end, false )
	TriggerEvent( "chat:addSuggestion", "/rre", "Restarts wk_wars2x" )

	-- Radar Toggle Passenger Control
	RegisterCommand( "rtpc", function( source, args, rawCommand )
		CONFIG.allow_passenger_control = not CONFIG.allow_passenger_control
		UTIL:Notify( string.format( "[DEBUG]: CONFIG.allow_passenger_control set to %s", tostring( CONFIG.allow_passenger_control ) ) )
	end, false )
	TriggerEvent( "chat:addSuggestion", "/rtpc", "Toggle CONFIG.allow_passenger_control" )

	-- Radar Toggle Passenger View
	RegisterCommand( "rtpv", function( source, args, rawCommand )
		CONFIG.allow_passenger_view = not CONFIG.allow_passenger_view
		UTIL:Notify( string.format( "[DEBUG]: CONFIG.allow_passenger_view set to %s", tostring( CONFIG.allow_passenger_view ) ) )
	end, false )
	TriggerEvent( "chat:addSuggestion", "/rtpv", "Toggle CONFIG.allow_passenger_view" )
end