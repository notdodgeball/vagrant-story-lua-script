g = require 'gui'

function Image(textureID, srcSizeX, srcSizeY, dstSizeX, dstSizeY)

  local cx, cy = PCSX.Helpers.UI.imageCoordinates(0, 0, 1.0, 1.0, dstSizeX, dstSizeY)

  g.setScale(dstSizeX,dstSizeY,cx,cy)

  g.draw()

  imgui.Image(textureID, dstSizeX, dstSizeY, 0, 0, 1, 1)

end
