# vagrant-story-lua-script
A collection of scripts to be used with the [PCSX-Redux emulator](https://pcsx-redux.consoledev.net/) for the game Vagrant Story. While being nothing special, it's being published here to help others wanting to learn the basics of using the lua scripting capabilities of said emulator.

pcsx.lua is the main file and the one executed by the emulator.

map.lua contains the area and text encoding info for the game.

widgets.lua implements a few gui functions
* drawCheckbox
* drawSlider
* drawInputInt
* drawDrag
* drawRadio
* drawInputText
* drawSaveButton
* drawLoadButton

helpers.lua implements several support functions

Showcase video:
[![Showcase video](https://i3.ytimg.com/vi/Wyxv00NZJdc/maxresdefault.jpg)](https://youtu.be/Wyxv00NZJdc)
