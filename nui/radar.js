/*-------------------------------------------------------------------------

    Wraith ARS 2X - v1.0.0
    Created by WolfKnight

    This JS file takes inspiration from RandomSean's RS9000 JS file, so 
    thanks to him!
    
-------------------------------------------------------------------------*/

// Setup the main const element structure, this way we can easily access elements without having the mess
// that was in the JS file for WraithRS
const elements = 
{
    radar: $( "radarFrame" ),
    patrolSpeed: $( "patrolSpeed" ),

    antennas: {
        front: {
            targetSpeed: $( "frontSpeed" ),

            dirs: {
                forward: $( "frontDirAway" ),
                backward: $( "frontDirTowards" )
            },

            modes: {
                same: $( "frontSame" ),
                opp: $( "frontOpp" ),
                xmit: $( "frontXmit" )
            },

            fast: {
                speed: $( "frontFastSpeed" ),
                fastLabel: $( "frontFastLabel" ),
                lockLabel: $( "frontFastLockLabel" )
            }
        },

        rear: {
            targetSpeed: $( "rearSpeed" ),

            dirs: {
                forward: $( "rearDirTowards" ),
                backward: $( "rearDirAway" )
            },

            modes: {
                same: $( "rearSame" ),
                opp: $( "rearOpp" ),
                xmit: $( "rearXmit" )
            },

            fast: {
                speed: $( "rearFastSpeed" ),
                fastLabel: $( "rearFastLabel" ),
                lockLabel: $( "rearFastLockLabel" )
            }
        }
    }
}

// The main event listener, this is what the NUI messages sent by the LUA side arrive at, they are 
// then handled properly via a switch/case that runs the relevant code
window.addEventListener( "message", function( event ) {
    var item = event.data;
} );