/*-----------------------------------------------------------------------------------------

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

-----------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
	Variables
------------------------------------------------------------------------------------*/
var uiEdited = false;

// All of the audio file names
const audioNames = 
{
	// Beeps
	beep: "beep.ogg",
	xmit_on: "xmit_on.ogg",
	xmit_off: "xmit_off.ogg",
	done: "done.ogg", 
	
	// Verbal lock 
	front: "front.ogg", 
	rear: "rear.ogg", 
	closing: "closing.ogg", 
	away: "away.ogg",

	// Plate reader
	plate_hit: "plate_hit.ogg",

	// Hmm 
	speed_alert: "speed_alert.ogg"
}

// Defines which audio needs to play for which direction 
const lockAudio = 
{
	front: { 
		1: "away",
		2: "closing"
	}, 

	rear: {
		1: "closing", 
		2: "away"
	}
}

// Setup the main const element structure, this way we can easily access elements without having the mess
// that was in the JS file for WraithRS
const elements = 
{
	radar: $( "#radarFrame" ),
	remote: $( "#rc" ), 
	plateReader: $( "#plateReaderFrame" ),

	pwrBtn: $( "#pwrBtn" ), 

	uiSettingsBtn: $( "#uiSettings" ), 
	uiSettingsBox: $( "#uiSettingsBox" ), 
	closeUiBtn: $( "#closeUiSettings" ),
	
	plateReaderBtn: $( "#plateReaderBtn" ), 
	plateReaderBox: $( "#plateReaderBox" ), 
	boloText: $( "#boloText" ), 
	setBoloBtn: $( "#setBoloPlate" ), 
	clearBoloBtn: $( "#clearBoloPlate" ), 
	closePrBtn: $( "#closePlateReaderSettings" ),

	openHelp: $( "#helpBtn" ), 
	helpWindow: $( "#helpWindow" ), 
	helpWeb: $( "#helpWeb" ), 
	closeHelp: $( "#closeHelp" ), 

	closeNewUser: $( "#closeNewUserMsg" ),
	newUser: $( "#newUser" ),
	openQsv: $( "#showQuickStartVideo" ),
	qsvWindow: $( "#quickStart" ), 
	qsvWeb: $( "#quickStartVideo" ),
	closeQsv: $( "#closeQuickStart" ),

	radarScaling: {
		increase: $( "#radarIncreaseScale" ),
		decrease: $( "#radarDecreaseScale" ),
		display: $( "#radarScaleDisplay" )
	}, 

	remoteScaling: {
		increase: $( "#remoteIncreaseScale" ),
		decrease: $( "#remoteDecreaseScale" ),
		display: $( "#remoteScaleDisplay" )
	},

	plateReaderScaling: {
		increase: $( "#readerIncreaseScale" ),
		decrease: $( "#readerDecreaseScale" ),
		display: $( "#readerScaleDisplay" )
	},

	plates: {
		front: {
			plate: $( "#frontPlate" ), 
			text: $( "#frontPlateText" ),
			fill: $( "#frontPlateTextFill" ),
			lolite: $( "#frontPlateTextLolite" ),
			img: $( "#frontPlateImg" ), 
			lock: $( "#frontPlateLock" )
		},

		rear: {
			plate: $( "#rearPlate" ),
			text: $( "#rearPlateText" ), 
			fill: $( "#rearPlateTextFill" ), 
			lolite: $( "#rearPlateTextLolite" ),
			img: $( "#rearPlateImg" ), 
			lock: $( "#rearPlateLock" )
		}
	},

	safezoneSlider: $( "#safezone" ), 
	safezoneDisplay: $( "#safezoneDisplay" ),
	
	keyLock: {
		label: $( "#keyLockLabel" ), 
		stateLabel: $( "#keyLockStateLabel" )
	},

	patrolSpeed: $( "#patrolSpeed" ),

	antennas: {
		front: {
			targetSpeed: $( "#frontSpeed" ),
			fastSpeed: $( "#frontFastSpeed" ),

			dirs: {
				fwd: $( "#frontDirAway" ),
				bwd: $( "#frontDirTowards" ),
				fwdFast: $( "#frontFastDirAway" ), 
				bwdFast: $( "#frontFastDirTowards" )
			},

			modes: {
				same: $( "#frontSame" ),
				opp: $( "#frontOpp" ),
				xmit: $( "#frontXmit" )
			},

			fast: {
				fastLabel: $( "#frontFastLabel" ),
				lockLabel: $( "#frontFastLockLabel" )
			}
		},

		rear: {
			targetSpeed: $( "#rearSpeed" ),
			fastSpeed: $( "#rearFastSpeed" ),

			dirs: {
				fwd: $( "#rearDirTowards" ),
				bwd: $( "#rearDirAway" ), 
				fwdFast: $( "#rearFastDirTowards" ), 
				bwdFast: $( "#rearFastDirAway" )
			},

			modes: {
				same: $( "#rearSame" ),
				opp: $( "#rearOpp" ),
				xmit: $( "#rearXmit" )
			},

			fast: {
				fastLabel: $( "#rearFastLabel" ),
				lockLabel: $( "#rearFastLockLabel" )
			}
		}
	}
}

// Antenna mode values
const modes = 
{
	off: 0, 
	same: 1, 
	opp: 2,
	both: 3
}

// Antenna direction values
const dirs = 
{
	none: 0, 
	closing: 1,
	away: 2
}


/*------------------------------------------------------------------------------------
	Hide elements
------------------------------------------------------------------------------------*/
elements.radar.hide(); 
elements.remote.hide(); 
elements.plateReader.hide(); 
elements.plateReaderBox.hide(); 
elements.uiSettingsBox.hide(); 
elements.keyLock.label.hide(); 
elements.helpWindow.hide(); 
elements.qsvWindow.hide();
elements.newUser.hide(); 

// Sets the action for the "UI SETTINGS" button on the remote to open the UI settings box
elements.uiSettingsBtn.click( function() {
	setEleVisible( elements.uiSettingsBox, true ); 
} )

// Sets the action for the "PLATE READER" button on the remote to open the plate reader box
elements.plateReaderBtn.click( function() {
	setEleVisible( elements.plateReaderBox, true ); 
} )

// Sets the action for the "HELP" button on the remote to open the help window and load the web page 
elements.openHelp.click( function() {
	setEleVisible( elements.helpWindow, true ); 
	loadHelp( true );
} )

// Sets the action for the "Close Help" button under the help window to close the help window and unload the web page 
elements.closeHelp.click( function() {
	setEleVisible( elements.helpWindow, false ); 
	loadHelp( false ); 
} )

// Sets the action for the "No" button on the new user popup to close the popup
elements.closeNewUser.click( function() {
	setEleVisible( elements.newUser, false ); 
	sendData( "qsvWatched", {} );
} )

// Sets the action for the "Yes" button on the new user popup to open the quick start window and load the video
elements.openQsv.click( function() {
	setEleVisible( elements.newUser, false ); 
	setEleVisible( elements.qsvWindow, true ); 
	loadQuickStartVideo( true );
} )

// Sets the action for the "Close Video" button under the quick start window to close the quick start window and unload the video 
elements.closeQsv.click( function() {
	setEleVisible( elements.qsvWindow, false ); 
	loadQuickStartVideo( false ); 
	sendData( "qsvWatched", {} );
} )


/*------------------------------------------------------------------------------------
	Setters
------------------------------------------------------------------------------------*/
// Sets the visibility of an element to the given state 
function setEleVisible( ele, state )
{
	state ? ele.fadeIn() : ele.fadeOut(); 
}

// Changes the class of the given element so it looks lit up 
function setLight( ant, cat, item, state )
{
	// Grab the obj element from the elements table
	let obj = elements.antennas[ant][cat][item]; 

	// Either add the active class or remove it 
	if ( state ) {
		obj.addClass( cat == "dirs" ? "active_arrow" : "active" ); 
	} else {
		obj.removeClass( cat == "dirs" ? "active_arrow" : "active" );
	}
}

// Sets the XMIT state of an antenna based on the passed state, makes the fast box display "HLd"
// when the state is false
function setAntennaXmit( ant, state )
{
	// Set the light state of the antenna's XMIT icon
	setLight( ant, "modes", "xmit", state ); 

	// Clear the antenna's directional arrows and speeds, display "HLd" in the fast box
	if ( !state ) {
		clearDirs( ant ); 
		elements.antennas[ant].targetSpeed.html( "¦¦¦" );
		elements.antennas[ant].fastSpeed.html( "HLd" ); 
		
	// Blank the fast box when the antenna is set to transmit 
	} else {
		elements.antennas[ant].fastSpeed.html( "¦¦¦" ); 
	}
}

// Sets the mode lights for the given antenna
function setAntennaMode( ant, mode )
{
	// Light up the 'same' led if the given mode is the same mode, otherwise blank it 
	setLight( ant, "modes", "same", mode == modes.same );
	
	// Light up the 'opp' led if the given mode is the opp mode, otherwise blank it 
	setLight( ant, "modes", "opp", mode == modes.opp );
}

// Sets the fast light for the given antenna
function setAntennaFastMode( ant, state )
{
	// Lighten or dull the fast led based on the given state
	setLight( ant, "fast", "fastLabel", state );
}

// Sets the lock light for the given antenna
function setAntennaLock( ant, state )
{
	// Lighten or dull the lock led based on the given state
	setLight( ant, "fast", "lockLabel", state ); 
}

// Sets the directional arrows light for the given antenna
function setAntennaDirs( ant, dir, fastDir )
{
	// Target forward
	setLight( ant, "dirs", "fwd", dir == dirs.closing );
	
	// Target backward 
	setLight( ant, "dirs", "bwd", dir == dirs.away );

	// Fast forward
	setLight( ant, "dirs", "fwdFast", fastDir == dirs.closing );
	
	// Fast backward
	setLight( ant, "dirs", "bwdFast", fastDir == dirs.away );
}

// sets the plate lock light for the given plate reader
function setPlateLock( cam, state, isBolo )
{
	// Get the plate reader lock object 
	let obj = elements.plates[cam]; 

	// Add or remove the active class
	if ( state ) {
		obj.lock.addClass( "active" ); 

		// Only flash the plate if it was a BOLO plate 
		if ( isBolo ) {
			// Make the hit plate flash for 3 seconds, acts as a visual aid
			obj.plate.addClass( "plate_hit" );

			setTimeout( function() {
				obj.plate.removeClass( "plate_hit" ); 
			}, 3000 );
		}
	} else {
		obj.lock.removeClass( "active" );
	}
}

// Sets the license text and plate image of the given plate reader
function setPlate( cam, plate, index )
{
	// Get the plate items
	let pl = elements.plates[cam]; 

	// Change the plate image 
	pl.img.attr( "src", "images/plates/" + index + ".png" );

	// Change the plate text colour depending on the plate itself
	( index == 1 || index == 2 ) ? pl.fill.removeClass( "plate_blue" ).addClass( "plate_yellow" ) : pl.fill.removeClass( "plate_yellow" ).addClass( "plate_blue" ); 
	
	// If the plate is black or blue then we hide the lolite effect 
	( index == 1 || index == 2 ) ? pl.lolite.hide() : pl.lolite.show(); 

	// Update all of the p elements with the new plate 
	pl.text.find( "p" ).each( function( i, obj ) {
		$( this ).html( plate );
	} );
}


/*------------------------------------------------------------------------------------
	Clearing functions 
------------------------------------------------------------------------------------*/
// Clears the same, opp, fast, and lock leds for the given antenna
function clearModes( ant )
{
	// Iterate through the modes and clear them 
	for ( let i in elements.antennas[ant].modes )
	{
		elements.antennas[ant].modes[i].removeClass( "active" ); 
	}

	// Iterate through the fast leds and clear them 
	for ( let a in elements.antennas[ant].fast )
	{
		elements.antennas[ant].fast[a].removeClass( "active" ); 
	}
}

// Clears the directional arrows for the given antenna
function clearDirs( ant )
{
	// Iterate through the directional arrows and clear them
	for ( let i in elements.antennas[ant].dirs )
	{
		elements.antennas[ant].dirs[i].removeClass( "active_arrow" ); 
	}
}

// Clears all of the elements of the given antenna
function clearAntenna( ant )
{
	// Clear the modes 
	clearModes( ant );
	
	// Clear the directional arrows
	clearDirs( ant );

	// Blank the target speed box 
	elements.antennas[ant].targetSpeed.html( "¦¦¦" );
	
	// Blank the fast speed box
	elements.antennas[ant].fastSpeed.html( "¦¦¦" );
}

// Clears all the elements on the radar's UI
function clearEverything()
{
	// Blank the patrol speed
	elements.patrolSpeed.html( "¦¦¦" ); 

	// Blank both the antennas
	for ( let i in elements.antennas ) 
	{
		clearAntenna( i ); 
	}
}


/*------------------------------------------------------------------------------------
	Radar power functions
------------------------------------------------------------------------------------*/
// Simulates the radar unit powering up by lighting all of the elements 
function poweringUp()
{
	// Set the patrol speed container to be fully lit
	elements.patrolSpeed.html( "888" ); 

	// Iterate through the front and rear antenna elements
	for ( let i of [ "front", "rear" ] )
	{
		// Get the antenna object to shorten the target reference
		let e = elements.antennas[i];

		// Set the target and fast speed box to be fully lit
		e.targetSpeed.html( "888" ); 
		e.fastSpeed.html( "888" ); 

		// Iterate through the rest of the antenna's elements 
		for ( let a of [ "dirs", "modes", "fast" ] )
		{
			// Iterate through the objects for the current category and add the active class
			for ( let obj in e[a] )
			{
				a == "dirs" ? e[a][obj].addClass( "active_arrow" ) : e[a][obj].addClass( "active" ); 
			}
		}
	}
} 

// Simulates the 'fully powered' state of the radar unit 
function poweredUp( fastDisplay )
{
	// Completely clear everything
	clearEverything(); 

	// Activate the 'fast' led for both antennas, and make sure the xmit led is off
	for ( let ant of [ "front", "rear" ] )
	{
		// Even though the clearEverything() function is called above, we run this so the fast window
		// displays 'HLd'
		setAntennaXmit( ant, false );
		setAntennaFastMode( ant, fastDisplay );    
	}
}

// Runs the startup process or clears everything, the Lua side calls for the full powered up state
function radarPower( state, override, fastDisplay )
{
	state ? ( override ? poweredUp( fastDisplay ) : poweringUp() ) : clearEverything();
}


/*------------------------------------------------------------------------------------
	Audio 
------------------------------------------------------------------------------------*/
// Plays the given audio file name from the audioNames list at the given volume 
function playAudio( name, vol )
{
	// Create the new audio object
	let audio = new Audio( "sounds/" + audioNames[name] );
	
	// Set the volume 
	audio.volume = vol; 
	
	// Play the audio clip 
	audio.play();
}

// Plays the verbal lock, this is a separate from the function above as it plays two sounds with a delay
function playLockAudio( ant, dir, vol )
{
	// Play the front/rear sound
	playAudio( ant, vol ); 

	// If the vehicle was closing or away, play that sound too 
	if ( dir > 0 ) 
	{
		setTimeout( function() {
			playAudio( lockAudio[ant][dir], vol ); 
		}, 500 );
	}
}


/*------------------------------------------------------------------------------------
	Radar updating  
------------------------------------------------------------------------------------*/
// Updates patrol speed as well as the speeds and directional arrows for the given antenna
function updateDisplays( ps, ants )
{
	// Update the patrol speed
	elements.patrolSpeed.html( ps );

	// Iterate through the antenna data 
	for ( let ant in ants ) 
	{
		// Make sure there is actually data for the current antenna data
		if ( ants[ant] != null ) {
			// Grab the antenna element from the elements table
			let e = elements.antennas[ant]; 

			// Update the target and fast speeds
			e.targetSpeed.html( ants[ant][0].speed ); 
			e.fastSpeed.html( ants[ant][1].speed ); 

			// Update the directional arrows
			setAntennaDirs( ant, ants[ant][0].dir, ants[ant][1].dir );
		}
	}
}

// Updates all of the mode leds on the radar interface
function settingUpdate( ants )
{
	for ( let ant in ants )
	{
		setAntennaXmit( ant, ants[ant].xmit );
		setAntennaMode( ant, ants[ant].mode ); 
		setAntennaFastMode( ant, ants[ant].fast );  
		setAntennaLock( ant, ants[ant].speedLocked );
	}
}


/*------------------------------------------------------------------------------------
	Misc
------------------------------------------------------------------------------------*/
// Displays the given option text and current option value on the radar
function menu( optionText, option )
{
	// Clear everything 
	clearEverything(); 

	// Set the target and fast box to the option text
	elements.antennas.front.targetSpeed.html( optionText[0] );
	elements.antennas.front.fastSpeed.html( optionText[1] );

	// Set the patrol speed to the value 
	elements.patrolSpeed.html( option );
}

var keyLockTimeout; 

// Makes the key lock label fade in then fade out after 2 seconds
function displayKeyLock( state )
{
	let sl = elements.keyLock.stateLabel; 

	// Set the state label text to enabled or disabled
	sl.html( state ? "blocked" : "enabled" );

	// Change the colour of the altered text 
	state ? sl.addClass( "red" ).removeClass( "green" ) : sl.addClass( "green" ).removeClass( "red" );

	// Fade in the label 
	elements.keyLock.label.fadeIn();

	// Clear the timeout if it already exists 
	clearTimeout( keyLockTimeout );

	// Make the label fade out after 2 seconds
	keyLockTimeout = setTimeout( function() {
		elements.keyLock.label.fadeOut();
	}, 2000 ); 
}

// Prepare headers for HTTP requests
$.ajaxSetup({
	headers: {
        'Content-Type': 'application/json; charset=UTF-8',
    },
 });

// This function is used to send data back through to the LUA side 
function sendData( name, data ) {
	$.post( "https://wk_wars2x/" + name, JSON.stringify( data ), function( datab ) {
		if ( datab != "ok" ) {
			console.log( datab );
		}            
	} );
}

// Sets the ui edited variable to the given state, this is used in the UI save system 
function setUiHasBeenEdited( state )
{
	uiEdited = state; 
}

// Returns if the UI has been edited
function hasUiBeenEdited()
{
	return uiEdited;
}

// Gathers the UI data and sends it to the Lua side
function sendSaveData()
{
	// Make sure we only collect and send the UI data if it has been edited 
	if ( hasUiBeenEdited() ) {
		let data = 
		{
			remote: {
				left: elements.remote.css( "left" ),
				top: elements.remote.css( "top" ),
				scale: remoteScale
			},

			radar: {
				left: elements.radar.css( "left" ),
				top: elements.radar.css( "top" ),
				scale: radarScale
			},

			plateReader: {
				left: elements.plateReader.css( "left" ),
				top: elements.plateReader.css( "top" ),
				scale: readerScale
			},

			safezone: safezone 
		}

		// Send the data
		sendData( "saveUiData", data );
	}
}

// Loads the UI settings 
function loadUiSettings( data, isSave )
{
	// Iterate through "remote", "radar" and "plateReader"
	for ( let setting of [ "remote", "radar", "plateReader" ] ) 
	{
		let ele = elements[setting];

		if ( isSave ) {
			// Iterate through the settings
			for ( let i of [ "left", "top" ] )
			{
				// Update the position of the current element 
				ele.css( i, data[setting][i] );
			}
		
			// Set the scale and update the display
			setScaleAndDisplay( ele, data[setting].scale, elements[setting + "Scaling"].display ); 
		} else {
			// Set the scale and update the display
			setScaleAndDisplay( ele, data.scale[setting], elements[setting + "Scaling"].display ); 

			// Get the scaled width and height of the current element
			let w = ( ele.outerWidth() * data.scale[setting] );
			let h = ( ele.outerHeight() * data.scale[setting] ); 

			// The position of the element then needs to be updated. 
			switch ( setting ) {
				case "remote":
					ele.css( "left", "calc( 50% - " + w / 2 + "px )" );
					ele.css( "top", "calc( 50% - " + h / 2 + "px )" );
					break;
				case "radar":
					ele.css( "left", "calc( ( 100% - " + data.safezone + "px ) - " + w + "px )" );
					ele.css( "top", "calc( ( 100% - " + data.safezone + "px ) - " + h + "px )" );
					break; 
				case "plateReader":
					ele.css( "left", "calc( ( 100% - " + data.safezone + "px ) - " + w + "px )" );
					ele.css( "top", "calc( 50% - " + h / 2 + "px )" );
					break;
				default:
					break;
			}
		}
	}

	// Update the remote, radar and reader scale variables
	remoteScale = isSave ? data.remote.scale : data.scale.remote; 
	radarScale = isSave ? data.radar.scale : data.scale.radar; 
	readerScale = isSave ? data.plateReader.scale : data.scale.plateReader;

	// Set the safezone and update the display
	elements.safezoneSlider.val( data.safezone );
	elements.safezoneSlider.trigger( "input" ); 
}

// Sets the on click function for the set BOLO plate button
elements.setBoloBtn.click( function() {
	// Grab the value of the text input box
	let plate = elements.boloText.val().toUpperCase();

	// Gets the amount of whitespace there should be 
	let spaceAmount = 8 - plate.length;

	if ( spaceAmount > 0 ) 
	{
		// Splits the amount in half
		let split = spaceAmount / 2; 

		// Calculates how many whitespace characters there should be at the start and end of the string. As GTA
		// formats a licence plate string by padding it, with the end of the string being biased compared to
		// the start of the string. 
		let startSpace = Math.floor( split ); 
		let endSpace = Math.ceil( split ); 

		// Add the padding to the string
		let text = plate.padStart( plate.length + startSpace );
		text = text.padEnd( text.length + endSpace );  

		// Send the plate to the Lua side
		sendData( "setBoloPlate", text ); 
	} else {
		sendData( "setBoloPlate", plate ); 
	}
} )

// Sets the on click function for the clear BOLO button
elements.clearBoloBtn.click( function() {
	sendData( "clearBoloPlate", null ); 
} )

// Checks what the user is typing into the plate box
function checkPlateInput( event )
{
	// See if what has been typed is a valid key, GTA only seems to like A-Z and 0-9
	let valid = /[a-zA-Z0-9 ]/g.test( event.key ); 

	// If the key is not valid, prevent the key from being input into the box
	if ( !valid ) {
		event.preventDefault(); 
	}
}

// Sets the src of the in-game help element, when true it loads the manual, when false it blanks the element
function loadHelp( state )
{
	if ( state ) {
		elements.helpWeb.attr( "src", "https://wolfknight98.github.io/wk_wars2x_web/manual.pdf" ); 
	} else {
		elements.helpWeb.attr( "src", "about:blank" ); 
	}
}

function loadQuickStartVideo( state )
{
	if ( state ) {
		elements.qsvWeb.attr( "src", "https://www.youtube-nocookie.com/embed/B-6VD8pXNYE" ); 
	} else {
		elements.qsvWeb.attr( "src", "about:blank" ); 
	}
}


/*------------------------------------------------------------------------------------
	UI scaling and positioning 
	
	This whole bit could most likely be streamlined and made more efficient, it 
	works for now though. Redo it at a later date.
------------------------------------------------------------------------------------*/
var remoteScale = 1.0;
var remoteMoving = false; 
var remoteOffset = [ 0, 0 ]; 

var radarScale = 1.0;
var radarMoving = false; 
var radarOffset = [ 0, 0 ]; 

var readerScale = 1.0; 
var readerMoving = false;
var readerOffset = [ 0, 0 ]; 

var windowWidth = 0; 
var windowHeight = 0; 
var safezone = 0; 

// Close the UI settings window when the 'Close' button is pressed
elements.closeUiBtn.click( function() {
	setEleVisible( elements.uiSettingsBox, false );
} )

// Close the plate reader settings window when the 'Close' button is pressed
elements.closePrBtn.click( function() {
	setEleVisible( elements.plateReaderBox, false ); 
} )

// Set the remote scale buttons to change the remote's scale 
elements.remoteScaling.increase.click( function() {
	remoteScale = changeEleScale( elements.remote, remoteScale, 0.05, elements.remoteScaling.display ); 
} )

elements.remoteScaling.decrease.click( function() {
	remoteScale = changeEleScale( elements.remote, remoteScale, -0.05, elements.remoteScaling.display ); 
} )

// Set the radar scale buttons to change the radar's scale 
elements.radarScaling.increase.click( function() {
	radarScale = changeEleScale( elements.radar, radarScale, 0.05, elements.radarScaling.display ); 
} )

elements.radarScaling.decrease.click( function() {
	radarScale = changeEleScale( elements.radar, radarScale, -0.05, elements.radarScaling.display ); 
} )

// Set the reader scale buttons to change the reader's scale 
elements.plateReaderScaling.increase.click( function() {
	readerScale = changeEleScale( elements.plateReader, readerScale, 0.05, elements.plateReaderScaling.display ); 
} )

elements.plateReaderScaling.decrease.click( function() {
	readerScale = changeEleScale( elements.plateReader, readerScale, -0.05, elements.plateReaderScaling.display ); 
} )

// Remote mouse down and up event
elements.remote.mousedown( function( event ) {
	remoteMoving = true; 

	let offset = $( this ).offset();

	remoteOffset = getOffset( offset, event.clientX, event.clientY );
} )

// Radar mouse down and up event
elements.radar.mousedown( function( event ) {
	radarMoving = true; 

	let offset = $( this ).offset();

	radarOffset = getOffset( offset, event.clientX, event.clientY );
} )

// Plate reader mouse down and up event
elements.plateReader.mousedown( function( event ) {
	readerMoving = true; 

	let offset = $( this ).offset();

	readerOffset = getOffset( offset, event.clientX, event.clientY );
} )

$( document ).mouseup( function( event ) {
	// Reset the remote and radar moving variables
	remoteMoving = false; 
	radarMoving = false; 
	readerMoving = false;
} )

$( document ).mousemove( function( event ) {
	let x = event.clientX; 
	let y = event.clientY; 

	if ( remoteMoving )
	{
		event.preventDefault();

		calculatePos( elements.remote, x, y, windowWidth, windowHeight, remoteOffset, remoteScale, safezone );
	}

	if ( radarMoving )
	{
		event.preventDefault(); 

		calculatePos( elements.radar, x, y, windowWidth, windowHeight, radarOffset, radarScale, safezone );
	}

	if ( readerMoving )
	{
		event.preventDefault(); 

		calculatePos( elements.plateReader, x, y, windowWidth, windowHeight, readerOffset, readerScale, safezone );
	}
} )

$( window ).resize( function() {
	windowWidth = $( this ).width(); 
	windowHeight = $( this ).height(); 
} )

$( document ).ready( function() {
	windowWidth = $( window ).width(); 
	windowHeight = $( window ).height();
} )

elements.safezoneSlider.on( "input", function() {
	let val = $( this ).val();
	safezone = parseInt( val, 10 ); 

	elements.safezoneDisplay.html( val + "px" ); 
} )

function calculatePos( ele, x, y, w, h, offset, scale, safezone )
{
	let eleWidth = ( ele.outerWidth() * scale );
	let eleHeight = ( ele.outerHeight() * scale );
	let eleWidthPerct = ( eleWidth / w ) * 100; 
	let eleHeightPerct = ( eleHeight / h ) * 100; 
	let eleWidthPerctHalf = eleWidthPerct / 2; 
	let eleHeightPerctHalf = eleHeightPerct / 2;

	let maxWidth = w - eleWidth;
	let maxHeight = h - eleHeight; 

	let left = clamp( x + offset[0], 0 + safezone, maxWidth - safezone );
	let top = clamp( y + offset[1], 0 + safezone, maxHeight - safezone );

	let leftPos = ( left / w ) * 100; 
	let topPos = ( top / h ) * 100; 

	let leftLockGap = leftPos + eleWidthPerctHalf; 
	let topLockGap = topPos + eleHeightPerctHalf;

	// Lock pos check 
	if ( leftLockGap >= 49.0 && leftLockGap <= 51.0 ) 
	{
		leftPos = 50.0 - eleWidthPerctHalf; 
	}

	if ( topLockGap >= 49.0 && topLockGap <= 51.0 ) 
	{
		topPos = 50.0 - eleHeightPerctHalf; 
	}

	updatePosition( ele, leftPos, topPos );
	setUiHasBeenEdited( true ); 
}

function updatePosition( ele, left, top )
{
	ele.css( "left", left + "%" );
	ele.css( "top", top + "%" );
}

function getOffset( offset, x, y )
{
	return [
		offset.left - x, 
		offset.top - y
	]
}

function changeEleScale( ele, scaleVar, amount, display )
{
	// Change the scale of the element and update it's displayer
	let scale = changeScale( ele, scaleVar, amount ); 
	display.html( scale.toFixed( 2 ) + "x" );

	// Tell the system the UI has been edited
	setUiHasBeenEdited( true ); 

	return scale; 
}

function changeScale( ele, current, amount )
{
	let scale = clamp( current + amount, 0.25, 2.5 ); 
	ele.css( "transform", "scale(" + scale + ")" );

	return scale; 
}

function setScaleAndDisplay( ele, scale, display )
{
	ele.css( "transform", "scale(" + scale + ")" );
	display.html( scale.toFixed( 2 ) + "x" );
}

function clamp( num, min, max )
{
	return num < min ? min : num > max ? max : num;
}


/*------------------------------------------------------------------------------------
	Button click event assigning 
------------------------------------------------------------------------------------*/
// This runs when the JS file is loaded, loops through all of the remote buttons and assigns them an onclick function
// elements.remote.find( "button" ).each( function( i, obj ) {
$( "body" ).find( "button, div" ).each( function( i, obj ) {
	if ( $( this ).attr( "data-nuitype" ) ) {
		$( this ).click( function() { 
			let type = $( this ).data( "nuitype" ); 
			let value = $( this ).attr( "data-value" ) ? $( this ).data( "value" ) : null; 
			let mode = $( this ).attr( "data-mode" ) ? $( this ).data( "mode" ) : null; 

			sendData( type, { value, mode } ); 
		} )
	}
} );


/*------------------------------------------------------------------------------------
	Close the remote when the user presses the 'Escape' key or the right mouse button 
------------------------------------------------------------------------------------*/
function closeRemote()
{
	sendData( "closeRemote", {} );

	setEleVisible( elements.plateReaderBox, false ); 
	setEleVisible( elements.uiSettingsBox, false ); 
	setEleVisible( elements.helpWindow, false );
	setEleVisible( elements.newUser, false );
	setEleVisible( elements.qsvWindow, false ); 
	loadHelp( false ); 
	loadQuickStartVideo( false );

	setEleVisible( elements.remote, false );
	
	sendSaveData(); 
}

$( document ).keyup( function( event ) {
	if ( event.keyCode == 27 ) 
	{
		closeRemote();
	}
} );

$( document ).contextmenu( function() {
	closeRemote(); 
} );


/*------------------------------------------------------------------------------------
	The main event listener, this is where the NUI messages sent by the LUA side arrive 
	at, they are then handled properly via a switch/case that runs the relevant code
------------------------------------------------------------------------------------*/
window.addEventListener( "message", function( event ) {
	var item = event.data; 
	var type = event.data._type; 

	switch ( type ) {
		// System events 
		case "loadUiSettings":
			loadUiSettings( item.data, true );
			break;
		case "setUiDefaults":
			loadUiSettings( item.data, false ); 
			break; 
		case "displayKeyLock":
			displayKeyLock( item.state );
			break; 
		case "showNewUser":
			setEleVisible( elements.newUser, true );
			break; 

		// Radar events
		case "openRemote":
			setEleVisible( elements.remote, true ); 
			setUiHasBeenEdited( false ); 
			break; 
		case "setRadarDisplayState":
			setEleVisible( elements.radar, item.state ); 
			break; 
		case "radarPower":
			radarPower( item.state, item.override, item.fast );
			break; 
		case "poweredUp":
			poweredUp( item.fast );
			break;
		case "update":
			updateDisplays( item.speed, item.antennas );
			break; 
		case "antennaXmit":
			setAntennaXmit( item.ant, item.on );
			break; 
		case "antennaMode":
			setAntennaMode( item.ant, item.mode ); 
			break; 
		case "antennaLock":
			setAntennaLock( item.ant, item.state );
			break; 
		case "antennaFast":
			setAntennaFastMode( item.ant, item.state ); 
			break; 
		case "menu":
			menu( item.text, item.option ); 
			break;
		case "settingUpdate":
			settingUpdate( item.antennaData ); 
			break; 

		// Plate reader events
		case "setReaderDisplayState":
			setEleVisible( elements.plateReader, item.state ); 
			break; 
		case "changePlate":
			setPlate( item.cam, item.plate, item.index );
			break;
		case "lockPlate":
			setPlateLock( item.cam, item.state, item.isBolo ); 
			break; 
			
		// Audio events
		case "audio":
			playAudio( item.name, item.vol ); 
			break; 
		case "lockAudio":
			playLockAudio( item.ant, item.dir, item.vol ); 
			break; 
		
		// default
		default:
			break;
	}
} );