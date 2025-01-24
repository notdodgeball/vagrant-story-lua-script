--========================================================
-- Screen output module for the pcsx-redux emulator
-- made by optrin
--========================================================

-- setOutput() expects a function as a parameter
-- The logic flow:
-- setOutput() => setScale() => draw()

  -- TODO:
  -- nvg:fillColor(nvg.Color.New(255,0,0))
  -- is given as string "0xrrggbbaa" (hex) or as a string name (e.g. "red"). 
  -- nvg:textBreakLines


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


function g.drawRectangle(x, y, width, height, strokeWidth, colors)
  
  -- equivalent to bizhawk gui.drawRectangle
  
  if not ffi.istype('NVGcolor', colors) then colors = w.ColorToNVG(colors, alpha) end
  
  nvg:beginPath()
  nvg:rect(x, y, width, height)
  nvg:strokeColor(colors)
  nvg:strokeWidth(strokeWidth)
  nvg:stroke()
  
end


function g.text(x,y,text,colors)

  -- equivalent to bizhawk gui.text
    nvg:fontSize(g.fontSize)
    
    nvg:text( g.minX + x, g.minY + y, tostring(text) )

end


function g.textBox(x,y,text,width,in_colors)

  -- gui.text within a box
    nvg:fontSize(g.fontSize)
    
    nvg:textBox( g.minX + x, g.minY + y, width, tostring(text) )
    local a = nvg:textBoxBounds(g.minX + x, g.minY + y, width, tostring(text))
    -- nvg:textBoxBounds returns [xmin,ymin, xmax,ymax]

    g.drawRectangle( a[0], a[1], a[2] - a[0] , a[3] - a[1] , 2 , in_colors)

end


function g.addmessage(t,in_colors)

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
  
  g.drawRectangle(g.minX - 3, g.minY - 0.7*g.lineHeight, 150*g.scaleX, 3 + ( g.offset * (g.lineHeight) ), 2, in_colors)
end


function g.addmessage2(t,in_colors)

  -- prints into the screen left size, can be called multiple times at the same cycle.
  -- equivalent to bizhawk gui.addmessage
  
  if not g.isOutputSet then return end

  nvg:fontSize(g.fontSize)
  
  texttt = ''

  if type(t) == 'string' or type(t) == 'number' then
    texttt = texttt .. '\n' .. t
  elseif type(t) == 'table' then
    for i,v in ipairs(t) do
      texttt = texttt .. '\n' .. tostring(v)
    end
  else
    error("wrong argument to addmessage()")
  end
  
  nvg:textBox( g.minX, g.minY , 1, tostring(texttt) )
  local a = nvg:textBoxBounds(g.minX , g.minY , 1, tostring(texttt))
  -- nvg:textBoxBounds returns [xmin,ymin, xmax,ymax]

  g.drawRectangle( a[0], a[1], a[2] - a[0] , a[3] - a[1] , 2, in_colors)

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