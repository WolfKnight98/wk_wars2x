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

// Hide the radar and remote, this way we can bypass setting a style of 'display: none;' in the HTML file
elements.radar.hide(); 
elements.remote.hide(); 

// This function is used to send data back through to the LUA side 
function sendData( name, data ) {
    $.post( "http://" + resourceName + "/" + name, JSON.stringify( data ), function( datab ) {
        if ( datab != "ok" ) {
            console.log( datab );
        }            
    } );
}

// Close the remote when the user presses the 'Escape' key 
document.onkeyup = function ( event ) {
    if ( event.keyCode == 27 ) 
    {
        sendData( "remote", "close" );
        $( "#rc" ).toggle(); 
    }
}

// The main event listener, this is what the NUI messages sent by the LUA side arrive at, they are 
// then handled properly via a switch/case that runs the relevant code
window.addEventListener( "message", function( event ) {
    var item = event.data;

    if ( item.pathName ) {
        resourceName = item.pathName; 
    } else if ( item.activateRemote ) {
        $( "#rc" ).toggle(); 
    }
} );