--========================================================
-- Vagrant Story script for the pcsx-redux emulator
-- made by optrin
--========================================================

require "widgets"
require "map"
require "helpers"

local mem = PCSX.getMemPtr()
local mode = 0x8011FA10
local loadRoom = 0x0F1A48
local roomIdToLoad = 0x0F1AB0
local roomIdToLoadPtr = ffi.cast('uint16_t*', mem + roomIdToLoad )
local areaDesc = "Select area"
local areaId = 0
local posX = 0x801203C4
local posY = 0x801203C0
local posZ = 0x801203C2
local joker = 0x8005E1C0

function DrawImguiFrame()
  
  local show = imgui.Begin('Command', true)
  if not show then imgui.End() return end
  
  inputLogger(mem,joker)
  
  drawSlider(mem, 0x8011fa73, 'MaxSpeed', 'uint8_t*', 0, 40)
  drawSlider(mem, 0x80121BE4, 'CurSpeed', 'uint8_t*', 0, 40)
  drawSlider(mem, 0x8011FA60, 'RISK', 'uint8_t*', 0, 255)
  drawSlider(mem, 0x8011FA62, 'STR', 'uint8_t*', 0, 255)
  
  -- Better than using a table actually
  imgui.SeparatorText("Coordinates")
  imgui.SetNextItemWidth(90); drawInput(mem, posX, 'X', 'int16_t*')
  imgui.SameLine(); drawSlider(mem, posX, '_', 'int16_t*', -2500, 2500)
  imgui.SetNextItemWidth(90);  drawInput(mem, posY, 'Y', 'int16_t*')
  imgui.SameLine(); drawSlider(mem, posY, '__', 'int16_t*', -2500, 2500)
  imgui.SetNextItemWidth(90); drawInput(mem, posZ, 'Z', 'int16_t*', 1, true)
  imgui.SameLine(); drawSlider(mem, posZ, '___', 'int16_t*', 150, -500)

  imgui.SeparatorText("Checks")
  drawCheckbox(mem, mode, 'Battle Mode', 0x01, 0x00, true)

  imgui.SeparatorText("Rooms")
  if imgui.Button("Trigger Load Room") and mem[loadRoom] == 0 then mem[loadRoom] = 2 end
  
  imgui.SameLine(); imgui.BeginDisabled(); imgui.Button( string.format("%04X", roomIdToLoadPtr[0] ) ); imgui.EndDisabled()
  
  imgui.PushItemWidth(190)
  
  if imgui.BeginCombo( " ", areaDesc ) then
    for k, v in pairs(area_t) do
      if imgui.Selectable( v ) then areaId=k; areaDesc=v end
    end
    imgui.EndCombo()
  end

  imgui.PopItemWidth()
  
  imgui.SameLine()
  
  if imgui.BeginListBox( " " ) then
    
    for k, v in pairs(map_t) do
      if v.area == areaId then is_selected = imgui.Selectable( v.desc ) end
      if is_selected then roomIdToLoadPtr[0] = v.id end
    end
    
    imgui.EndListBox()
  end

  -- drawRadio(mem, loadRoom, "loadRoom" )

  imgui.End()
end

