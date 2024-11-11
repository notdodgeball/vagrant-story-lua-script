--========================================================
-- Screen output module for the pcsx-redux emulator
-- made by optrin
--========================================================

-- setOutput() expects a function as a parameter
-- The logic flow:
-- setOutput() => setScale() => draw()

local g = {}

g.filename = 'out.lua'
g.isOutputSet = false

-- Minimal X and Y offsets, mainly because of the Menu Bar 
g.minX = 10
g.minY = 40


function g.setOutput(func)

  -- Entry point of the whole print on screen process
  -- loads g.filename onto output.lua
  PCSX.GUI.OutputShader.setDefaults()
  
  local f = Support.File.open(g.filename) -- Support.extra.open
  
  if not f:failed() then
    print('output.lua set with file ' .. g.filename .. ',size: ' .. f:size())
    PCSX.GUI.OutputShader.setTextL(f)
    g.isOutputSet = true
  else
    print('could not find file ' .. g.filename)
  end

  f:close()
  
  -- Sets g.func, this function will be executed every cycle
  g.func = func

end


-- rect(x, y, width, height)
-- Draws a rectangle whose top-left corner is specified by (x, y) with the specified width and height.

-- Before this method is executed, the moveTo() method is automatically called with the parameters (x,y). In other words, the current -pen position is automatically reset to the default coordinates.


function g.drawRectangle(x, y, width, height)

  -- ugly test rectangle
  -- equivalent to bizhawk gui.drawRectangle

  nvg:beginPath()
  nvg:rect(g.minX - 3, g.minY - 0.7*g.lineHeight, 150*g.scaleX, 3 + ( g.offset * (g.lineHeight) ) )
  nvg:strokeColor(nvg.RGBA(0, 255, 0, 128))
  nvg:strokeWidth(2)
  nvg:stroke()
end


function g.text(x,y,text)

  -- equivalent to bizhawk gui.text
    nvg:text(g.minX + x, g.minY + y, tostring(text) )

end


-- Screen size
g.dstSizeX   = 0
g.dstSizeY   = 0
g.cx         = 0
g.cy         = 0

-- Scaling factor
g.scaleX     = 0
g.scaleY     = 0

-- Formatting
g.offset     = 0
g.fontSize   = 0
g.lineHeight = 0


function g.setScale(dstSizeX,dstSizeY,cx,cy)

  -- This function is called by the output rendering process

  -- Set screen size
  g.dstSizeX   = dstSizeX
  g.dstSizeY   = dstSizeY
  g.cx         = cx
  g.cy         = cy

  -- Scaling factor based on the default 4:3 aspect ratio
  g.scaleX     = dstSizeX / 320
  g.scaleY     = dstSizeY / 240

  -- Magic numbers
  g.fontSize   = 9 * g.scaleX
  g.lineHeight = 25

end


function g.addmessage(t)

  -- prints into the screen left size, can be called multiple times at the same cycle.
  -- equivalent to bizhawk gui.addmessage
  
  if not g.isOutputSet then return end

  nvg:fontSize(g.fontSize)

  if type(t) == 'string' or type(t) == 'number' then
      nvg:text(g.minX, g.minY + ( g.lineHeight * g.offset ), t )
      g.offset = g.offset + 1
  elseif type(t) == 'table' then
    for i,v in ipairs(t) do
      nvg:text(g.minX, g.minY + ( g.lineHeight*( g.offset+i-1) ), tostring(v) )
    end
      g.offset = g.offset + #t
  else
    error("wrong argument to addmessage()")
  end
end


function g.printCoordinates()

  -- Coordinates for debugging
  g.addmessage( {g.scaleX,g.scaleY,g.dstSizeX,g.dstSizeY,g.cx,g.cy} )
end


function g.draw()
  
  -- main function
  nvg:queueNvgRender(g.func)
  -- Every cycle we reset it so addmessage() will be at the same place
  g.offset = 0

end

return g