--[[---------------------------------------------------------------------------------------

	Wraith ARS 2X
	Created by WolfKnight

	For discussions, information on future updates, and more, join
	my Discord: https://discord.gg/fD4e6WD

	MIT License

	Copyright (c) 2020-2021 WolfKnight

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

---------------------------------------------------------------------------------------]]--

-- Define the FX Server version and game type
fx_version "cerulean"
game "gta5"

-- Define the resource metadata
name "Wraith ARS 2X"
description "Police radar and plate reader system for FiveM"
author "WolfKnight"
version "1.3.1"

-- Include the files
files {
	"nui/radar.html",
	"nui/radar.css",
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
server_script "sv_exports.lua"
server_script "sv_sync.lua"
server_export "TogglePlateLock"

-- Run the client scripts
client_script "config.lua"
client_script "cl_utils.lua"
client_script "cl_player.lua"
client_script "cl_radar.lua"
client_script "cl_plate_reader.lua"
client_script "cl_sync.lua"