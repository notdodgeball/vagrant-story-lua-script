# vagrant-story-lua-script
A collection of scripts to be used with the [PCSX-Redux emulator](https://pcsx-redux.consoledev.net/) for the game Vagrant Story. While being nothing special, it's being published here to help others wanting to learn the basics of using the lua scripting capabilities of said emulator.

pcsx.lua is the main file.

map.lua contains the area info for the game.

widgets.lua implements a few gui functions
* drawCheckbox
* drawSlider
* drawInput
* drawRadio

helpers.lua implements these two, manly as a showcase what can be done
* addBpWithCondition
* inputLogger
