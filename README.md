# vagrant-story-lua-script
A script to be used with the [PCSX-Redux emulator](https://pcsx-redux.consoledev.net/) for the game Vagrant Story.

It can display and edit values like Ashley's speed and coordinates, insert and read text from memory, modify the inventory, load any room, and freeze and unfreeze memory addresses.

## Summary

__vg.lua__ is the main file and the one executed by the emulator.

__map.lua__ contains the area and text encoding info for the game.

__widgets.lua__ implements several support functions and the following imgui widgets:
* drawCheckbox
* drawSlider
* drawMemory
* drawInputInt
* drawDrag
* drawRadio
* drawInputText
* drawSaveButton
* drawLoadButton
* drawFreezeCheck

__prt.lua__ implements functions to print into the screen.
* p.setOutput
* p.screenLog
* p.printCoordinates
* p.text

__out.lua__ File to replace the content of output.lua to enable drawing into the screen.

Showcase video:
[![Showcase video](https://i3.ytimg.com/vi/Wyxv00NZJdc/maxresdefault.jpg)](https://youtu.be/Wyxv00NZJdc)

## Usage

Type either into the lua console:

`dofile 'vg.lua'`

`dofile 'C:\\Path\\to\\vg.lua'`

Or use the dofile command line argument

`pcsx.exe -dofile 'vg.lua'`

## As a module

You can use this script in your own project, an example:

```lua
p = require 'prt'
w = require 'widgets'

p.setOutput(function() 
  p.text(200,50,'Look at me')
end)

local address = 0x80000000

function DrawImguiFrame()
  
  imgui.safe.Begin('Command', true, function()
    w.drawSlider(PCSX.getMemPtr(), address, 'Something', 'uint8_t*', 0, 40)
  end)

end
```


