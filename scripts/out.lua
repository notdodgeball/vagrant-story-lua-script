p = require 'prt'

function Image(textureID, srcSizeX, srcSizeY, dstSizeX, dstSizeY)

  local cx, cy = PCSX.Helpers.UI.imageCoordinates(0, 0, 1.0, 1.0, dstSizeX, dstSizeY)

  p.setScale(dstSizeX,dstSizeY,cx,cy)

  p.draw()

  imgui.Image(textureID, dstSizeX, dstSizeY, 0, 0, 1, 1)

end
