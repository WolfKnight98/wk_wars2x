-- Radar Toggle Passenger Control
RegisterCommand( "rtpc", function( source, args, rawCommand )
	CONFIG.allow_passenger_control = not CONFIG.allow_passenger_control
end, false )
TriggerEvent( "chat:addSuggestion", "/rtpc", "Toggle CONFIG.allow_passenger_control" )

-- Radar Toggle Passenger View
RegisterCommand( "rtpv", function( source, args, rawCommand )
	CONFIG.allow_passenger_view = not CONFIG.allow_passenger_view
end, false )
TriggerEvent( "chat:addSuggestion", "/rtpv", "Toggle CONFIG.allow_passenger_view" )