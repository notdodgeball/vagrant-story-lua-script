# vagrant-story-lua-script
A collection of scripts to be used with the [PCSX-Redux emulator](https://pcsx-redux.consoledev.net/) for the game Vagrant Story. While being nothing special, it's being published here to help others wanting to learn the basics of using the lua scripting capabilities of said emulator.

It can display and edit values like Ashley's speed and coordinates, insert and decode text from memory, load any room, add any item, and freeze and unfreeze memory addresses.
All files go to the main pcsx folder.

Released in a beta state, bugs included.

__pcsx.lua__ is the main file and the one executed by the emulator.

__map.lua__ contains the area and text encoding info for the game.

__widgets.lua__ implements the imgui widgets functions
* drawCheckbox
* drawSlider
* drawInputInt
* drawDrag
* drawRadio
* drawInputText
* drawSaveButton
* drawLoadButton

__helpers.lua__ implements several support functions

Showcase video:
[![Showcase video](https://i3.ytimg.com/vi/Wyxv00NZJdc/maxresdefault.jpg)](https://youtu.be/Wyxv00NZJdc)
