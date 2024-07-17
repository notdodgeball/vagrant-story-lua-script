--========================================================
-- Screen output module for the pcsx-redux emulator
-- made by optrin
--========================================================

-- setOutput() expects a function as a parameter
-- all the logic 
-- setOutput() => setScale() => draw()

local p = {}

p.filename = 'out.lua'
p.isOutputSet = false

-- Minimal X and Y offsets, mainly because of the Menu Bar 
p.minX = 10
p.minY = 40


function p.setOutput(func)

  -- Entry point of the whole print on screen process
  -- loads p.filename onto output.lua
  PCSX.GUI.OutputShader.setDefaults()
  
  local f = Support.File.open(p.filename) -- Support.extra.open
  
  if not f:failed() then
    print('output.lua set with file ' .. p.filename .. ',size: ' .. f:size())
    PCSX.GUI.OutputShader.setTextL(f)
    p.isOutputSet = true
  else
    print('could not find file ' .. p.filename)
  end

  f:close()
  
  -- Sets p.func, this function will be executed every cycle
  p.func = func

end


function p.drawRectangle()

  -- ugly test rectangle
  nvg:beginPath()
  nvg:rect(p.minX - 3, p.minY - 0.7*p.lineHeight, 150*p.scaleX, 3 + ( p.offset * (p.lineHeight) ) )
  nvg:strokeColor(nvg.RGBA(0, 255, 0, 128))
  nvg:strokeWidth(2)
  nvg:stroke()
end


function p.text(x,y,text)

  -- equivalent to bizhawk gui.text
    nvg:text(p.minX + x, p.minY + y, tostring(text) )

end


-- Screen size
p.dstSizeX   = 0
p.dstSizeY   = 0
p.cx         = 0
p.cy         = 0

-- Scaling factor
p.scaleX     = 0
p.scaleY     = 0

-- Formatting
p.offset     = 0
p.fontSize   = 0
p.lineHeight = 0


function p.setScale(dstSizeX,dstSizeY,cx,cy)

  -- This function is called by the output rendering process

  -- Set screen size
  p.dstSizeX   = dstSizeX
  p.dstSizeY   = dstSizeY
  p.cx         = cx
  p.cy         = cy

  -- Scaling factor based on the default 4:3 aspect ratio
  p.scaleX     = dstSizeX / 320
  p.scaleY     = dstSizeY / 240

  -- Magic numbers
  p.fontSize   = 9 * p.scaleX
  p.lineHeight = 25

end


function p.screenLog(t)

  -- prints into the screen left size, can be called multiple times at the same cycle.
  if not p.isOutputSet then return end

  nvg:fontSize(p.fontSize)

  if (type(t)) == 'table' then
    for i,v in ipairs(t) do
      nvg:text(p.minX, p.minY + ( p.lineHeight*( p.offset+i-1) ), tostring(v) )
    end
      p.offset = p.offset + #t
  else
      nvg:text(p.minX, p.minY + ( p.lineHeight * p.offset ), t )
      p.offset = p.offset + 1
  end
end


function p.printCoordinates()

  -- Coordinates for debugging
  p.screenLog( {p.scaleX,p.scaleY,p.dstSizeX,p.dstSizeY,p.cx,p.cy} )
end


function p.draw()
  
  -- main function
  nvg:queueNvgRender(p.func)
  -- Every cycle we reset it so screenLog() will be at the same place
  p.offset = 0

end

return p