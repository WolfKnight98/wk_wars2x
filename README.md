# Wraith ARS 2X
The **Wraith ARS 2X** (Wraith Advanced Radar System) is a realistic police radar that takes heavy inspiration from the real Stalker DSR 2X radar system. It includes a plethora of features from the DSR 2X such as the new operator menu, to improve the realism and experience whilst using the newest instalment from the collection of Wraith radar systems. Previously with WraithRS, vehicle speeds were only displayed in the target window, with no priority to certain vehicles (such as large and slower vehicles, or smaller and faster vehicles). The Wraith ARS 2X tracks both large and faster, smaller targets and displays the speeds of both in the target windows, meaning the radar can track 4 different speeds with both antennas turned on and transmitting. Alongside the new radar system is also a plate reader that scans in front and behind the patrol vehicle, a BOLO plate can also be set, but developers can also hook into the scanner to link it into other resources. 
ORIGINAL FORK LOCATED [HERE](https://github.com/WolfKnight98/wk_wars2x/releases)
## Installation
Installing the Wraith ARS 2X FORK into your FiveM can be done by following the listed steps below. 
1. Download the latest version of the resource from [here](https://github.com/domjr04/wk_wars2x/releases)
2. Open the zip file and place the `wk_wars2x` folder into your server's resource folder
3. Open up your server configuration file and add `ensure wk_wars2x` to your resource start list 

It's now installed! When you boot your server you should see a Wraith ARS 2X message as well as the version check message. 

## Default key binds
Although these can be viewed ingame through the operator manual, the default key binds are listed below. 
| Action                    | Key                       | Description |
| ------------------------- | ------------------------- | ----------- |
| Open remote               | F5                        | Opens the remote control, this only works if you are the driver of a police vehicle (must have the vehicle class VC_EMERGENCY). |
| Close remote              | ESC or right mouse button | Closes the remote/all of the displayed UI elements, and returns focus to the game. |
| Lock/unlock front antenna | Numpad 8                  | Locks the current speed of the front antenna. If there is a fast speed displayed, the system will lock the fast speed. Otherwise it will lock the strong speed. When you lock a speed, the radar will audibly tell you which antenna is being locked, and the relative direction of the target compared to the patrol vehicle (e.g. "Front Closing"). |
| Lock/unlock rear antenna  | Numpad 5                  | Locks the current speed of the rear antenna. If there is a fast speed displayed, the system will lock the fast speed. Otherwise it will lock the strong speed. When you lock a speed, the radar will audibly tell you which antenna is being locked, and the relative direction of the target compared to the patrol vehicle (e.g. "Rear Away"). |
| Lock/unlock front plate   | Numpad 9                  | Locks the plate currently caught by the front plate reader, an audible beep will also be heard unless the plate reader audio option in the operator menu is changed. |
| Lock/unlock rear plate    | Numpad 6                  | Locks the plate currently caught by the rear plate reader, an audible beep will also be heard unless the plate reader audio option in the operator menu is changed. |
| Toggle keylock            | L                         | Toggles the keylock state. When enabled, none of the keybinds will work until keylock is toggled again. |
| Toggle Doppler            | Home                      | Toggles the Doppler sound effect. |
| Doppler Volume Up         | Page Up                   | Turns the Doppler volume up. |
| Doppler Volume Down       | Page Down                 | Turns the Doppler volume down. |


## Script configuration
All of the configuration for the Wraith ARS 2X is done inside the `config.lua` file, below is a copy of the configuration file. All of the options have comments to describe what they do, along with the available options you can set. You have the ability to change the key binds for the large and small key set, the default operator menu options, and the default UI element scale and safezone. 

## Suggestions
If there is an improvement that you think should be made, open a pull request with your modified code, I will then review your request and either accept/deny it. Code in a pull request should be well formatted and commented, it will make it much easier for others to read and understand. In the event that you want to suggest something, but don't know how to code, open an issue with the enhancement tag and then fully describe your suggestion. 

## Reporting issues/bugs
Open an issue if you encounter any problems with the resource, if applicable, try to include detailed information on the issue and how to reproduce it. This will make it much easier to find and fix. 