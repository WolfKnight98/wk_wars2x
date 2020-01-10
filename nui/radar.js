/*-------------------------------------------------------------------------

	Wraith ARS 2X
	Created by WolfKnight

	This JS file takes inspiration from RandomSean's RS9000 JS file, so 
	thanks to him!
	
-------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------
	Variables
------------------------------------------------------------------------------------*/
var resourceName; 

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
    away: "away.ogg"
}

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
	toggleDisplay: $( "#toggleDisplay" ), 
	pwrBtn: $( "#pwrBtn" ), 

	uiSettingsBtn: $( "#uiSettings" ), 
	uiSettingsBox: $( "#uiSettingsBox" ), 
	closeUiBtn: $( "#closeUiSettings" ),

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

const modes = 
{
	off: 0, 
	same: 1, 
	opp: 2,
	both: 3
}

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
elements.uiSettingsBox.hide(); 
elements.keyLock.label.hide(); 

elements.uiSettingsBtn.click( function() {
	setUISettingsVisible( true, true );
} )

elements.pwrBtn.click( function() {
	togglePower();
} )


/*------------------------------------------------------------------------------------
	Setters
------------------------------------------------------------------------------------*/
function setRadarVisible( state )
{
	state ? elements.radar.fadeIn() : elements.radar.fadeOut();
}

function setRemoteVisible( state ) 
{
	state ? elements.remote.fadeIn() : elements.remote.fadeOut();
}

function setLight( ant, cat, item, state )
{
	let obj = elements.antennas[ant][cat][item]; 

	if ( state ) {
        obj.addClass( cat == "dirs" ? "active_arrow" : "active" ); 
	} else {
        obj.removeClass( cat == "dirs" ? "active_arrow" : "active" );
	}
}

function setAntennaXmit( ant, state )
{
	setLight( ant, "modes", "xmit", state ); 

	if ( !state ) {
		clearDirs( ant ); 
		elements.antennas[ant].targetSpeed.html( "¦¦¦" );
		elements.antennas[ant].fastSpeed.html( "HLd" ); 
	} else {
		elements.antennas[ant].fastSpeed.html( "¦¦¦" ); 
	}
}

function setAntennaMode( ant, mode )
{
	setLight( ant, "modes", "same", mode == modes.same );
	setLight( ant, "modes", "opp", mode == modes.opp );
}

function setAntennaFastMode( ant, state )
{
	setLight( ant, "fast", "fastLabel", state );
}

function setAntennaLock( ant, state )
{
    setLight( ant, "fast", "lockLabel", state ); 
}

function setAntennaDirs( ant, dir, fastDir )
{
	setLight( ant, "dirs", "fwd", dir == dirs.closing );
	setLight( ant, "dirs", "bwd", dir == dirs.away );

	setLight( ant, "dirs", "fwdFast", fastDir == dirs.closing );
	setLight( ant, "dirs", "bwdFast", fastDir == dirs.away );
}


/*------------------------------------------------------------------------------------
	Clearing functions 
------------------------------------------------------------------------------------*/
function clearModes( ant )
{
	for ( let i in elements.antennas[ant].modes )
	{
		elements.antennas[ant].modes[i].removeClass( "active" ); 
	}

	for ( let a in elements.antennas[ant].fast )
	{
		elements.antennas[ant].fast[a].removeClass( "active" ); 
	}
}

function clearDirs( ant )
{
	for ( let i in elements.antennas[ant].dirs )
	{
		elements.antennas[ant].dirs[i].removeClass( "active_arrow" ); 
	}
}

function clearAntenna( ant )
{
	clearModes( ant );
	clearDirs( ant );

	elements.antennas[ant].targetSpeed.html( "¦¦¦" );
	elements.antennas[ant].fastSpeed.html( "¦¦¦" );
}

function clearEverything()
{
	elements.patrolSpeed.html( "¦¦¦" ); 

	for ( let i in elements.antennas ) 
	{
		clearAntenna( i ); 
	}
}


/*------------------------------------------------------------------------------------
	Radar power functions
------------------------------------------------------------------------------------*/
function togglePower()
{
	sendData( "togglePower", null ); 
}

function poweringUp()
{
	elements.patrolSpeed.html( "888" ); 

	for ( let i of [ "front", "rear" ] )
	{
		let e = elements.antennas[i];

		e.targetSpeed.html( "888" ); 
		e.fastSpeed.html( "888" ); 

		for ( let a of [ "dirs", "modes", "fast" ] )
		{
			for ( let obj in e[a] )
			{
				a == "dirs" ? e[a][obj].addClass( "active_arrow" ) : e[a][obj].addClass( "active" ); 
			}
		}
	}
} 

function poweredUp()
{
	clearEverything(); 

	for ( let ant of [ "front", "rear" ] )
	{
		setAntennaXmit( ant, false );
		setAntennaFastMode( ant, true );    
	}
}

function radarPower( state )
{
	state ? poweringUp() : clearEverything();
}


/*------------------------------------------------------------------------------------
	Audio 
------------------------------------------------------------------------------------*/
function playAudio( name, vol )
{
	let audio = new Audio( "sounds/" + audioNames[name] );
	audio.volume = vol; 
	audio.play();
}

function playLockAudio( ant, dir, vol )
{
    playAudio( ant, vol ); 

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
function updateDisplays( ps, ants )
{
	elements.patrolSpeed.html( ps );

	for ( let ant in ants ) 
	{
		if ( ants[ant] != null ) {
			let e = elements.antennas[ant]; 

			e.targetSpeed.html( ants[ant][0].speed ); 
			e.fastSpeed.html( ants[ant][1].speed ); 

			setAntennaDirs( ant, ants[ant][0].dir, ants[ant][1].dir );
		}
	}
}

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
function menu( optionText, option )
{
	clearEverything(); 

	elements.antennas.front.targetSpeed.html( optionText[0] );
	elements.antennas.front.fastSpeed.html( optionText[1] );

	elements.patrolSpeed.html( option );
}

function displayKeyLock( state )
{
    elements.keyLock.stateLabel.html( state ? "enabled" : "disabled" );

    elements.keyLock.label.fadeIn();

    setTimeout( function() {
        elements.keyLock.label.fadeOut();
    }, 2000 ); 
}

// This function is used to send data back through to the LUA side 
function sendData( name, data ) {
	$.post( "http://" + resourceName + "/" + name, JSON.stringify( data ), function( datab ) {
		if ( datab != "ok" ) {
			console.log( datab );
		}            
	} );
}

/*------------------------------------------------------------------------------------
	UI scaling and positioning 
------------------------------------------------------------------------------------*/
var remoteScale = 1.0;
var remoteMoving = false; 
var remoteOffset = [ 0, 0 ]; 

var radarScale = 1.0;
var radarMoving = false; 
var radarOffset = [ 0, 0 ]; 

var windowWidth = 0; 
var windowHeight = 0; 
var safezone = 0; 

// Close the UI settings window when the 'Close' button is pressed
elements.closeUiBtn.click( function() {
	setUISettingsVisible( false, true );
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

$( document ).mouseup( function( event ) {
    remoteMoving = false; 
    radarMoving = false; 
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

    let maxWidth = w - eleWidth;
    let maxHeight = h - eleHeight; 

    let left = clamp( x + offset[0], 0 + safezone, maxWidth - safezone );
    let top = clamp( y + offset[1], 0 + safezone, maxHeight - safezone );

    let leftPos = ( left / w ) * 100; 
    let topPos = ( top / h ) * 100; 

    // Lock pos check 
    if ( ( leftPos + ( eleWidthPerct / 2 ) ) >= 49.0 && ( leftPos + ( eleWidthPerct / 2 ) ) <= 51.0 ) 
    {
        leftPos = 50.0 - ( eleWidthPerct / 2 ); 
    }

    if ( ( topPos + ( eleHeightPerct / 2 ) ) >= 49.0 && ( topPos + ( eleHeightPerct / 2 ) ) <= 51.0 ) 
    {
        topPos = 50.0 - ( eleHeightPerct / 2 ); 
    }

    updatePosition( ele, leftPos, topPos );
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

function setUISettingsVisible( state, remote )
{
	state ? elements.uiSettingsBox.fadeIn() : elements.uiSettingsBox.fadeOut(); 
	// if ( remote ) { setRemoteVisible( !state ); }
}

function hideUISettings()
{
	if ( !elements.uiSettingsBox.is( ":hidden" ) ) {
		elements.uiSettingsBox.hide(); 
	}
}

function changeEleScale( ele, scaleVar, amount, display )
{
    let scale = changeScale( ele, scaleVar, amount ); 
    display.html( scale.toFixed( 2 ) + "x" );

    return scale; 
}

function changeScale( ele, current, amount )
{
    let scale = clamp( current + amount, 0.25, 2.5 ); 
    ele.css( "transform", "scale(" + scale + ")" );

    return scale; 
}

function clamp( num, min, max )
{
	return num < min ? min : num > max ? max : num;
}

/*------------------------------------------------------------------------------------
	Button click event assigning 
------------------------------------------------------------------------------------*/
/* elements.uiSettingsBox.find( "button" ).each( function( i, obj ) {
	if ( $( this ).attr( "data-value" ) && $( this ).attr( "data-scale" ) ) {
		$( this ).click( function() { 
			let align = $( this ).data( "value" ); 
			let origin = $( this ).data( "scale" );

			elements.radar.removeClass().addClass( align );
			elements.radar.css( "transform-origin", origin );
		} )
	}
} ); */

// This runs when the JS file is loaded, loops through all of the remote buttons and assigns them an onclick function
elements.remote.find( "button" ).each( function( i, obj ) {
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
    sendData( "closeRemote", null );
	setRemoteVisible( false );
	setUISettingsVisible( false, false );
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
		case "updatePathName":
			resourceName = item.pathName
			break;
		case "openRemote":
			setRemoteVisible( true );
			break; 
		case "toggleDisplay":
			setRadarVisible( item.state );
			break; 
		case "radarPower":
			radarPower( item.state );
			break; 
		case "poweredUp":
			poweredUp();
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
		case "audio":
			playAudio( item.name, item.vol ); 
            break; 
        case "lockAudio":
            playLockAudio( item.ant, item.dir, item.vol ); 
            break; 
        case "displayKeyLock":
            displayKeyLock( item.state );
            break; 
		default:
			break;
	}
} );