--[[-----------------------------------------------------------------------

    Wraith ARS 2X - v1.0.0
    Created by WolfKnight

-----------------------------------------------------------------------]]--

resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

name 'Wraith ARS 2X'
description 'An advanced radar system for FiveM'
author 'WolfKnight'
version '1.0.0'

ui_page "nui/radar.html"

files {
	"nui/*"
}

client_script 'config.lua'
client_script 'cl_utils.lua'
client_script 'cl_radar.lua'
-- client_script 'cl_radar - sphere test.lua'