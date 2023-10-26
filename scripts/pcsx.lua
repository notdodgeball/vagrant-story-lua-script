--========================================================
-- Vagrant Story script for the pcsx-redux emulator
-- made by optrin
--========================================================

w = require 'widgets'
h = require 'helpers'
require 'map'

local mem             = PCSX.getMemPtr()
local areaDesc        = 'Select area'
local areaId          = 0

local joker           = 0x8005E1C0 -- 0x8005E238
local mode            = 0x8011FA10
local loadRoom        = 0x0F1A48
local roomIdToLoad    = 0x800F1AB0
local roomIdToLoadPtr = ffi.cast('uint16_t*', mem +  bit.band( roomIdToLoad, 0x1fffff))

local posX            = 0x801203C4
local posY            = 0x801203C0
local posZ            = 0x801203C2
local posZPtr         = ffi.cast('uint16_t*', mem + bit.band(posZ, 0x1fffff))
local maxSpeed        = 0x8011fa73
local curSpeed        = 0x80121BE4
local risk            = 0x8011FA60
local strength        = 0x8011FA62
local ashleySize      = 0x801203D0
local bossSize        = 0x80181550

local itemCount       = 0
local itemId          = 0x80060F68
local itemQtd         = 0x80060F6A
local itemIdPtr       = ffi.cast('uint8_t*', mem + bit.band(itemId, 0x1fffff))
local itemQtdPtr      = ffi.cast('uint8_t*', mem + bit.band(itemQtd, 0x1fffff))

local saveName        = ''
local charName        = 0x8011FA40
local currWeaponName  = 0x8011fa7c
local square          = PCSX.CONSTS.PAD.BUTTON.SQUARE
local canMoonJump     = false
local hexFlags        =  bit.bor ( 
  bit.bor( imgui.constant.InputTextFlags.CharsHexadecimal , imgui.constant.InputTextFlags.CharsNoBlank )
  , bit.bor( imgui.constant.InputTextFlags.EnterReturnsTrue , imgui.constant.InputTextFlags.CharsUppercase )
)

local file = Support.File.open('s1', 'READ')
if not file:failed() then
  PCSX.loadSaveState(file)
  print('Loaded file ' .. 's1')
end
file:close()

_vsync = PCSX.Events.createEventListener('GPU::Vsync', h.doFreeze )

function DrawImguiFrame()
  
  local show = imgui.Begin('Command', true)
  if not show then imgui.End() return end
  
  h.inputLogger(mem,joker)
  
  if imgui.BeginTabBar('MainBar') then
    

    if imgui.BeginTabItem('Values') then
      
      w.drawSlider(mem, maxSpeed , 'MaxSpeed', 'uint8_t*', 0, 40)
      w.drawSlider(mem, curSpeed, 'CurSpeed', 'uint8_t*', 0, 40)
      w.drawSlider(mem, strength, 'STR', 'uint8_t*', 0, 255)
      w.drawSliderLoop(mem, ashleySize , 'Size AS', 'int16_t*', 512, 14000, 2)
      
      -- Better than using a table actually
      imgui.SeparatorText('Coordinates')
      imgui.SetNextItemWidth(90); w.drawInputInt(mem, posX, 'X', 'int16_t*')
      imgui.SameLine();           w.drawSlider(mem, posX, '##x', 'int16_t*', -2500, 2500)
      imgui.SetNextItemWidth(90); w.drawInputInt(mem, posY, 'Y', 'int16_t*')
      imgui.SameLine();           w.drawSlider(mem, posY, '##y', 'int16_t*', -2500, 2500)
      imgui.SetNextItemWidth(90); w.drawInputInt(mem, posZ, 'Z', 'int16_t*', 1, true)
      imgui.SameLine();           w.drawSlider(mem, posZ, '##z', 'int16_t*', 150, -500)
      
      imgui.SeparatorText('Checks')
      w.drawCheckbox(mem, mode, 'Battle Mode', 0x01, 0x00, true)
      imgui.SameLine();
      _, canMoonJump = imgui.Checkbox('Moon Jump', canMoonJump)
      
      if canMoonJump then
        if PCSX.SIO0.slots[1].pads[1].getButton(square) then posZPtr[0] = posZPtr[0] - 20 end
      end
      
      imgui.SeparatorText('Freeze')
      _, h.canFreeze = imgui.Checkbox('Enable freeze', h.canFreeze)
      
      imgui.SetNextItemWidth(100); 
      local changed, freezeValue = imgui.extra.InputText('Add address', '' , hexFlags )
      if changed then 
        local freezeNumber = tonumber(freezeValue, 16)
        h.addFreeze(mem,freezeNumber)
      end
      
      imgui.SetNextItemWidth(180); 
      if imgui.BeginListBox( '##Frozen' ) then
        for k, v in pairs(h.frozenAddresses) do
          if imgui.SmallButton('x##'..k) then h.frozenAddresses[k] = nil end
          imgui.SameLine();
          imgui.Selectable( ("8%.7X"):format(math.abs(k)) .. ' - ' .. h.dec2hex( v[2] ) )
        end
        imgui.EndListBox()
      end
      
      imgui.EndTabItem()
    end -- Values
    
    
    if imgui.BeginTabItem('Rooms') then
      
      if imgui.Button('Trigger Load Room:') and mem[loadRoom] == 0 then mem[loadRoom] = 2 end
      imgui.SameLine(); imgui.TextUnformatted( string.format( '%04X', roomIdToLoadPtr[0] ) )
      imgui.PushItemWidth(190)
      
      if imgui.BeginCombo( '##Area', areaDesc ) then
        for k, v in ipairs(area_t) do
          if imgui.Selectable( v ) then areaId=k; areaDesc=v end
        end
        imgui.EndCombo()
      end
      imgui.PopItemWidth()
      
      if imgui.BeginListBox( '##Room' ) then        
        for k, v in pairs(map_t) do
          if v.area == areaId then
            if imgui.Selectable( v.desc ) then roomIdToLoadPtr[0] = v.id end
          end
        end
        imgui.EndListBox()
      end
      
      imgui.EndTabItem()
    end --Rooms
    
    
    if imgui.BeginTabItem('Items') then
      
      if imgui.BeginListBox( '##Item' ) then
        for i=0,255,4 do
          id = itemIdPtr[i]
          if id < 0x43 then itemCount = i; break end
          imgui.SetNextItemWidth(80);
          w.drawInputInt(mem, itemQtdPtr+i , items_t[ id ], 'uint8_t*' ) 
        end
        imgui.EndListBox()
      end
      
      imgui.SetNextItemWidth(150);
      if imgui.BeginCombo( '##New item', 'Add a new item:' ) then
        for k, v in pairs(items_t) do
          if imgui.Selectable( v ) then itemIdPtr[itemCount] = k; itemIdPtr[itemCount+1] = 1; itemQtdPtr[itemCount] = 1 end
        end
        imgui.EndCombo()
      end
      
      imgui.EndTabItem()
    end --Items
    
    
    if imgui.BeginTabItem('Strings') then
      
      w.drawInputText(mem, currWeaponName, 'Weapon\'s name', 16 )
      w.drawInputText(mem, charName, 'Character\'s name', 16 )
      
      imgui.EndTabItem()
    end -- Strings
    
      
    if imgui.BeginTabItem('Save/Load') then
      
      _, saveName = imgui.extra.InputText('save file name', saveName )
      w.drawSaveButton(saveName); imgui.SameLine(); w.drawLoadButton(saveName)
      
      imgui.EndTabItem()
    end -- Save/Load
    
    
    imgui.EndTabBar()
  end -- MainBar
  
  imgui.End()
end
