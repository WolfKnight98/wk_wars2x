-- Radar Toggle Passenger Control
RegisterCommand( "rtpc", function( source, args, rawCommand )
	CONFIG.allow_passenger_control = not CONFIG.allow_passenger_control
end, false )
TriggerEvent( "chat:addSuggestion", "/rtpc", "Toggle CONFIG.allow_passenger_control" )