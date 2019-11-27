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

            dirs: {
                forward: $( "#frontDirAway" ),
                backward: $( "#frontDirTowards" )
            },

            modes: {
                same: $( "#frontSame" ),
                opp: $( "#frontOpp" ),
                xmit: $( "#frontXmit" )
            },

            fast: {
                speed: $( "#frontFastSpeed" ),
                fastLabel: $( "#frontFastLabel" ),
                lockLabel: $( "#frontFastLockLabel" )
            }
        },

        rear: {
            targetSpeed: $( "#rearSpeed" ),

            dirs: {
                forward: $( "#rearDirTowards" ),
                backward: $( "#rearDirAway" )
            },

            modes: {
                same: $( "#rearSame" ),
                opp: $( "#rearOpp" ),
                xmit: $( "#rearXmit" )
            },

            fast: {
                speed: $( "#rearFastSpeed" ),
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

const antennaModes = 
{
    off: 0, 
    same: 1, 
    opp: 2,
    both: 3
}

// Hide the radar and remote, this way we can bypass setting a style of 'display: none;' in the HTML file
// elements.radar.hide(); 
elements.remote.hide(); 

// Create the onclick event for the toggle display button
remoteButtons.toggleDisplay.click( function() {
    elements.radar.fadeToggle();
} )

function toggleRemote() 
{
    elements.remote.toggle();
}

function setLight( ant, cat, item, state )
{
    let obj = elements.antennas[ant][cat][item]; 

    if ( state ) {
        obj.addClass( "active" ); 
    } else {
        obj.removeClass( "active" );
    }
}

function setAntennaXmit( ant, state )
{
    setLight( ant, "modes", "xmit", state ); 

    if ( !state ) {
        elements.antennas[ant].targetSpeed.html( "¦¦¦" );
        elements.antennas[ant].fast.speed.html( "HLd" ); 
    } else {
        elements.antennas[ant].fast.speed.html( "¦¦¦" ); 
    }
}

function updateDisplays( ps, ants )
{
    elements.patrolSpeed.html( ps );

    if ( ants["front"].speed != null ) {
        elements.antennas["front"].targetSpeed.html( ants["front"].speed ); 
    }

    if ( ants["front"].fast != null ) {
        elements.antennas["front"].fast.speed.html( ants["front"].fast );
    }    

    if ( ants["rear"].speed != null ) {
        elements.antennas["rear"].targetSpeed.html( ants["rear"].speed ); 
    }

    if ( ants["rear"].fast != null ) {
        elements.antennas["rear"].fast.speed.html( ants["rear"].fast );
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
            setAntennaXmit( item.ant, item.on );
            break; 
        default:
            break;
    }
} );