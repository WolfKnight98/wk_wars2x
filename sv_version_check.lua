--[[-----------------------------------------------------------------------

	Wraith ARS 2X
	Created by WolfKnight

-----------------------------------------------------------------------]]--

function GetCurrentVersion()
	return GetResourceMetadata( GetCurrentResourceName(), "version" )
end 

PerformHttpRequest( "https://wolfknight98.github.io/wk_wars2x/version.txt", function( err, text, headers )
	Citizen.Wait( 2000 )

	local curVer = GetCurrentVersion()
	
	print( "\n//\n|| Current Wraith ARS 2X Version: " .. curVer )
	print( "|| Latest Wraith ARS 2X Version: " .. text .."\n||" )
	
	if ( text ~= curVer ) then
		print( "|| ^1Your Wraith ARS 2X version is outdated, visit the FiveM forum post to get the latest version.\n^0\\\\" )
	else
		print( "|| ^2Wraith ARS 2X is up to date!\n^0\\\\" )
	end
end )