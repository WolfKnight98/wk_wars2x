/*-------------------------------------------------------------------------

    Wraith ARS 2X - v1.0.0
    Created by WolfKnight

    This JS file takes inspiration from RandomSean's RS9000 JS file, so 
    thanks to him!
    
-------------------------------------------------------------------------*/

// Variables
var resourceName; 

// Setup the main const element structure, this way we can easily access elements without having the mess
// that was in the JS file for WraithRS
const elements = 
{
    radar: $( "#radarFrame" ),
    remote: $( "#rc" ), 

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

const remoteButtons = 
{
    toggleDisplay: $( "#toggleDisplay" ), 
    menu: $( "#menuButton" ),
    volAndTest: $( "#volAndTest" ), 
    psBlank: $( "#psBlank" ), 
    uiSettings: $( "#uiSettings" ), 

    antennas: {
        front: {
            sameMode: $( "#frontSameMode" ),
            oppMode: $( "#frontOppMode" ),
            xmitToggle: $( "#frontXmitToggle" )
        },

        rear: {
            sameMode: $( "#rearSameMode" ),
            oppMode: $( "#rearOppMode" ),
            xmitToggle: $( "#rearXmitToggle" )
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

// Hide the radar and remote, this way we can bypass setting a style of 'display: none;' in the HTML file
// elements.radar.hide(); 
elements.remote.hide(); 

// Create the onclick event for the toggle display button
remoteButtons.toggleDisplay.click( function() {
    toggleRadar();
} )

function toggleRadar()
{
    elements.radar.fadeToggle();
}

function toggleRemote() 
{
    elements.remote.toggle();
}

function clearModes( ant )
{
    for ( let i in elements.antennas[ant].modes )
    {
        elements.antennas[ant].modes[i].removeClass( "active" ); 
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

function setLight( ant, cat, item, state )
{
    let obj = elements.antennas[ant][cat][item]; 

    if ( state ) {
        // if ( cat == "dirs" ) { obj.addClass( "active_arrow" ) } else { obj.addClass( "active" ) }; 
        cat == "dirs" ? obj.addClass( "active_arrow" ) : obj.addClass( "active" ); 
    } else {
        // if ( cat == "dirs" ) { obj.removeClass( "active_arrow" ) } else { obj.removeClass( "active" ) }; 
        cat == "dirs" ? obj.removeClass( "active_arrow" ) : obj.removeClass( "active" ); 
    }
}

function setAntennaXmit( ant, state, mode )
{
    setLight( ant, "modes", "xmit", state ); 

    if ( !state ) {
        clearAntenna( ant ); 
        elements.antennas[ant].fastSpeed.html( "HLd" ); 
    } else {
        elements.antennas[ant].fastSpeed.html( "¦¦¦" ); 
        setAntennaMode( ant, mode );
    }
}

function setAntennaMode( ant, mode )
{
    setLight( ant, "modes", "same", mode == modes.same );
    setLight( ant, "modes", "opp", mode == modes.opp );
}

function setAntennaDirs( ant, dir, fastDir )
{
    setLight( ant, "dirs", "fwd", dir == dirs.closing );
    setLight( ant, "dirs", "bwd", dir == dirs.away );

    setLight( ant, "dirs", "fwdFast", fastDir == dirs.closing );
    setLight( ant, "dirs", "bwdFast", fastDir == dirs.away );
}

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

// This function is used to send data back through to the LUA side 
function sendData( name, data ) {
    $.post( "http://" + resourceName + "/" + name, JSON.stringify( data ), function( datab ) {
        if ( datab != "ok" ) {
            console.log( datab );
        }            
    } );
}

// This runs when the JS file is loaded, loops through all of the remote buttons and assigns them an onclick function
elements.remote.find( "button" ).each( function( i, obj ) {
    if ( $( this ).attr( "data-nuitype" ) && $( this ).attr( "data-value" ) ) {
        $( this ).click( function() { 
            let type = $( this ).data( "nuitype" ); 
            let value = $( this ).data( "value" ); 
            let mode = $( this ).attr( "data-mode" ) ? $( this ).data( "mode" ) : null; 

            sendData( type, { value, mode } ); 
        } )
    }
} );

// Close the remote when the user presses the 'Escape' key 
document.onkeyup = function ( event ) {
    if ( event.keyCode == 27 ) 
    {
        sendData( "closeRemote", null );
        toggleRemote();
    }
}

// The main event listener, this is what the NUI messages sent by the LUA side arrive at, they are 
// then handled properly via a switch/case that runs the relevant code
window.addEventListener( "message", function( event ) {
    var item = event.data; 
    var type = event.data._type; 

    switch ( type ) {
        case "updatePathName":
            resourceName = item.pathName
            break;
        case "openRemote":
            toggleRemote();
            break; 
        case "update":
            updateDisplays( item.speed, item.antennas );
            break; 
        case "antennaXmit":
            setAntennaXmit( item.ant, item.on, item.on ? item.mode : 0 );
            break; 
        case "antennaMode":
            setAntennaMode( item.ant, item.mode ); 
            break; 
        default:
            break;
    }
} );