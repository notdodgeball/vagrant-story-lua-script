--========================================================
-- Vagrant Story script for the pcsx-redux emulator
-- made by optrin
--========================================================

require "widgets"
require "map"
require "helpers"

local mem = PCSX.getMemPtr()
local areaDesc = "Select area"
local areaId = 0

local joker = 0x8005E1C0
local mode = 0x8011FA10
local loadRoom = 0x0F1A48
local roomIdToLoad = 0x0F1AB0
local roomIdToLoadPtr = ffi.cast('uint16_t*', mem + roomIdToLoad )

local posX = 0x801203C4
local posY = 0x801203C0
local posZ = 0x801203C2
local maxSpeed = 0x8011fa73
local curSpeed = 0x80121BE4
local risk = 0x8011FA60
local strength = 0x8011FA62

local itemId  = 0x80060F68
local itemQtd = 0x80060F6A
local itemIdPtr = ffi.cast('uint8_t*', mem + bit.band(itemId, 0x1fffff))
local itemQtdPtr = ffi.cast('uint8_t*', mem + bit.band(itemQtd, 0x1fffff))

function DrawImguiFrame()
  
  local show = imgui.Begin('Command', true)
  if not show then imgui.End() return end
  
  inputLogger(mem,joker)
  
  drawSlider(mem, maxSpeed , 'MaxSpeed', 'uint8_t*', 0, 40)
  drawSlider(mem, curSpeed, 'CurSpeed', 'uint8_t*', 0, 40)
--drawSlider(mem, risk, 'RISK', 'uint8_t*', 0, 255)
  drawSlider(mem, strength, 'STR', 'uint8_t*', 0, 255)
  drawSliderLoop(mem, 0x801203D0 , 'size', 'int16_t*', 512, 14000, 2)
  
  -- Better than using a table actually
  imgui.SeparatorText("Coordinates")
  imgui.SetNextItemWidth(90); drawInput(mem, posX, 'X', 'int16_t*')
  imgui.SameLine();           drawSlider(mem, posX, '##x', 'int16_t*', -2500, 2500)
  imgui.SetNextItemWidth(90); drawInput(mem, posY, 'Y', 'int16_t*')
  imgui.SameLine();           drawSlider(mem, posY, '##y', 'int16_t*', -2500, 2500)
  imgui.SetNextItemWidth(90); drawInput(mem, posZ, 'Z', 'int16_t*', 1, true)
  imgui.SameLine();           drawSlider(mem, posZ, '##z', 'int16_t*', 150, -500)
  
  imgui.SeparatorText("Checks")
  drawCheckbox(mem, mode, 'Battle Mode', 0x01, 0x00, true)
  
  imgui.SeparatorText("Rooms")
  if imgui.Button("Trigger Load Room") and mem[loadRoom] == 0 then mem[loadRoom] = 2 end
  
  imgui.SameLine(); imgui.BeginDisabled(); imgui.Button( string.format("%04X", roomIdToLoadPtr[0] ) ); imgui.EndDisabled()
  
  imgui.PushItemWidth(190)

  if imgui.BeginCombo( "##Area", areaDesc ) then
    for k, v in pairs(area_t) do
      if imgui.Selectable( v ) then areaId=k; areaDesc=v end
    end
    imgui.EndCombo()
  end
  
  imgui.PopItemWidth()
  
  if imgui.BeginListBox( "##Room" ) then
    
    for k, v in pairs(map_t) do
      if v.area == areaId then is_selected = imgui.Selectable( v.desc ) end
      if is_selected then roomIdToLoadPtr[0] = v.id end
    end
    
    imgui.EndListBox()
  end
  
  imgui.SeparatorText("Items")
  
  if imgui.BeginListBox( "##Item" ) then
    for i=0,200,4 do
      id = itemIdPtr[i]
      if id < 0x43 then break end
      imgui.SetNextItemWidth(60);
      drawDrag(mem, itemIdPtr+i, '##'.. i, 'uint8_t*', 67, 100)
      imgui.SetNextItemWidth(80);
      imgui.SameLine(); drawInput(mem, itemQtdPtr+i , items_t[ id ], 'uint8_t*' ) 
    end
    
    imgui.EndListBox()
  end
  
  -- drawRadio(mem, loadRoom, "loadRoom" )
  
  imgui.End()
end

