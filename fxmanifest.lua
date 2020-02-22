--[[-----------------------------------------------------------------------

	Wraith ARS 2X
	Created by WolfKnight

-----------------------------------------------------------------------]]--

-- Define the FX Server version and game type
fx_version "adamant"
game "gta5"

-- Define the resource metadata
name "Wraith ARS 2X"
description "Police radar and plate reader system for FiveM"
author "WolfKnight"
version "pre-release/beta5a"

-- Include the files
files {
    "nui/radar.html", 
    "nui/radar.css", 
    "nui/jquery-3.4.1.min.js", 
    "nui/radar.js",
    "nui/images/*.png",
    "nui/images/plates/*.png",
    "nui/fonts/*.ttf",
    "nui/fonts/Segment7Standard.otf",
    "nui/sounds/*.ogg"
}

-- Set the NUI page
ui_page "nui/radar.html"

-- Run the server scripts
server_script "sv_version_check.lua"
server_script "sv_saving.lua"

-- Run the client scripts
client_script "config.lua"
client_script "cl_utils.lua"
client_script "cl_radar.lua"
client_script "cl_plate_reader.lua"