# vagrant-story-lua-script
A script to be used with the [PCSX-Redux emulator](https://pcsx-redux.consoledev.net/) for the game Vagrant Story.

It can display and edit values like Ashley's speed and coordinates, insert and read text from memory, modify the inventory, load any room, freeze memory addresses and output text on top of the screen.

## Summary

__vg.lua__ is the main file and the one executed by the emulator.

__map.lua__ contains the area and text encoding info for the game.

__widgets.lua__ implements several support functions and some imgui helpers:
* drawFreezeCheck
* drawCheckbox
* drawSlider
* drawMemory
* drawInputInt
* drawDrag
* drawRadio
* drawJumpButton
* drawInputText
* drawSaveButton
* drawLoadButton

__gui.lua__ implements the output process, and some helpers:
* drawRectangle
* text
* addmessage

__out.lua__ is the file to replace the content of output.lua to enable drawing into the screen.

Showcase video of older version:
[![Showcase video](https://i3.ytimg.com/vi/Wyxv00NZJdc/maxresdefault.jpg)](https://youtu.be/Wyxv00NZJdc)

## Usage

Type into the lua console:

`dofile 'C:\\Path\\to\\vg.lua'`

Or use the command line arguments

`pcsx.exe -loadiso "Vagrant Story.bin" -dofile "vg.lua" `

## As a module

You can use this script in your own project, an example:

```lua
gui = require 'gui'
w   = require 'widgets'

gui.setOutput(function() 
  gui.text(200,50,'Look at me')
end)

function DrawImguiFrame()
  
  imgui.safe.Begin('Command', true, function()
    w.drawSlider(PCSX.getMemPtr(),  0x80000000, 'Something', 'uint8_t*', 0, 0xFF)
  end)

end
```


