--[[-----------------------------------------------------------------------

	Wraith ARS 2X
	Created by WolfKnight

-----------------------------------------------------------------------]]--

local label = 
[[//
||    __          __        _ _   _                _____   _____   ___ __   __
||    \ \        / /       (_) | | |         /\   |  __ \ / ____| |__ \\ \ / /
||     \ \  /\  / / __ __ _ _| |_| |__      /  \  | |__) | (___      ) |\ V / 
||      \ \/  \/ / '__/ _` | | __| '_ \    / /\ \ |  _  / \___ \    / /  > <  
||       \  /\  /| | | (_| | | |_| | | |  / ____ \| | \ \ ____) |  / /_ / . \ 
||        \/  \/ |_|  \__,_|_|\__|_| |_| /_/    \_\_|  \_\_____/  |____/_/ \_\]]

function GetCurrentVersion()
	return GetResourceMetadata( GetCurrentResourceName(), "version" )
end 

PerformHttpRequest( "https://wolfknight98.github.io/wk_wars2x/version.txt", function( err, text, headers )
    Citizen.Wait( 2000 )

    print( label )

	local curVer = GetCurrentVersion()
	
	print( "||\n||    Current version: " .. curVer )
	print( "||    Latest version: " .. text .."\n||" )
	
	if ( text ~= curVer ) then
		print( "||    ^1Your Wraith ARS 2X version is outdated, visit the FiveM forum post to get the latest version.\n^0\\\\" )
	else
		print( "||    ^2Wraith ARS 2X is up to date!\n^0||\n\\\\" )
	end
end )