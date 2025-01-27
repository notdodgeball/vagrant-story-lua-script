--========================================================
-- Vagrant Story script for the pcsx-redux emulator
-- made by optrin
--========================================================

-- jit.off()

gui = require 'gui'
w   = require 'widgets'
require 'map'

--==========-- Variables

local mem             = PCSX.getMemPtr()
local areaDesc        = 'Select area'
local areaDesc        = 'Select area'
local areaId          = 0

local memWatch        = '80001888'
local memWatchInt     = tonumber(memWatch, 16)
local joker           = 0x05E1C0 -- 0x05E238
local loadRoom        = 0x0F1A48
local roomIdToLoad    = 0x0F1AB0
local roomIdToLoadPtr = ffi.cast('uint16_t*', mem +  bit.band(roomIdToLoad, 0x1fffff))

-- 8011FA10 starts character data
local mode            = 0x11FA10
local curHP           = 0x11FA58
local maxHP           = 0x11FA5A
local curMP           = 0x11FA5C
local maxMP           = 0x11FA5E
local risk            = 0x11FA60
local strength        = 0x11FA62
local maxSpeed        = 0x11FA73
local ashleySatus     = 0x120388
local ashleyState     = 0x1203AE

local posY            = 0x1203C0 -- mirrored at 0x1fff8c (on the stack)
local posZ            = 0x1203C2
local posX            = 0x1203C4
local rotationY       = 0x1203C6
local rotationZ       = 0x1203C8
local rotationX       = 0x1203CA
local posXPtr         = ffi.cast('uint16_t*', mem + bit.band(posX, 0x1fffff))
local posYPtr         = ffi.cast('uint16_t*', mem + bit.band(posY, 0x1fffff))
local posZPtr         = ffi.cast('uint16_t*', mem + bit.band(posZ, 0x1fffff))
local coor            = {
'x '.. w.dec2hex(posXPtr[0]),
'y '.. w.dec2hex(posYPtr[0]),
'z '.. w.dec2hex(posZPtr[0])
 }

local ashleySize      = 0x1203D0
local curAnimationID  = 0x12095C
local curSpeed        = 0x121BE4

local itemCount       = 20
local itemId          = 0x060F68
local itemQtd         = 0x060F6A
local itemIdPtr       = ffi.cast('uint8_t*', mem + bit.band(itemId, 0x1fffff))
local itemQtdPtr      = ffi.cast('uint8_t*', mem + bit.band(itemQtd, 0x1fffff))

local saveName        = ''
local charName        = 0x11FA40
local currWeaponName  = 0x11fA7C
local square          = PCSX.CONSTS.PAD.BUTTON.SQUARE
local canMoonJump     = false

local size_bytes      = 0
local size_bytes_t    = {8,16}

-- 0x0F1928: Actor Pointers Table (List all enemies / characters currently loaded in memory) 
-- also stored at 0x0F19FC
local actorPointer    = 0x11F9F0
local actorPointerPtr = ffi.cast('uint32_t*', mem +  bit.band(actorPointer, 0x1fffff))
local actors          = {actorPointerPtr}


local colors1        = {r=0,g=0,b=0}


--==========-- Flags

local hexFlags        =  bit.bor ( 
    bit.bor( imgui.constant.InputTextFlags.CharsHexadecimal , imgui.constant.InputTextFlags.CharsNoBlank )
  , bit.bor( imgui.constant.InputTextFlags.EnterReturnsTrue , imgui.constant.InputTextFlags.CharsUppercase )
)

local tableFlags      =  bit.bor ( 
    bit.bor( imgui.constant.TableFlags.NoSavedSettings , imgui.constant.TableFlags.NoClip ) -- Resizable
  , bit.bor( imgui.constant.TableFlags.NoPadOuterX   , imgui.constant.TableFlags.NoPadInnerX )
)

local tabFlags        = bit.bor ( imgui.constant.TabBarFlags.TabListPopupButton , imgui.constant.TabBarFlags.AutoSelectNewTabs )


--==========-- imgui drawing

function DrawImguiFrame()
  
  imgui.safe.Begin('Command', true, function()

    -- w.inputLogger(mem,joker)
    if imgui.Button(w.vblankCtr) then w.vblankCtr = 0 end
    
    imgui.safe.BeginTabBar('MainTabBar', tabFlags, function()
      
      imgui.safe.BeginTabItem('Actors', function()
        
        imgui.safe.BeginTabBar('ActorsChild', tabFlags, function()
          
          for actorIndex, currentActor in ipairs(actors) do
            
            -- Add the pointer to the next actor to the actors table
            local nextActor = currentActor[0]
            if not w.isValidAddress(nextActor) then
            
              if actorIndex > 1 then
                  print(tostring(actorIndex) .. ' ' .. w.dec2hex(nextActor))
              end
            
              break
            else
              local nextActorPtr = ffi.cast('uint32_t*', mem +  bit.band(nextActor , 0x1fffff))
              actors[actorIndex+1] = nextActorPtr
            end
            
            if actorIndex > 1 then
                
                local actorName = currentActor[0]+0x50
                -- print(tostring(actorIndex) .. ' ' .. actorName)
                -- print(w.dec2hex(nextActor))
                
                imgui.safe.BeginTabItem( w.decode(mem, actorName, 0x18, text_t) , function()
                
                  imgui.safe.BeginTable('Actor Table##'.. actorIndex, 2, tableFlags, function()
                    
                    for _, field in ipairs(actorStruct) do
                      local curAddress = currentActor[0] + field.offset

                      imgui.TableNextColumn()
                      -- If last column, we start instead at the next row
                      if imgui.TableGetColumnIndex() == 1 and (field.sameline or field.text) then imgui.TableNextColumn(); end;
                      
                      if field.text then
                        w.drawInputText(mem, curAddress, field.name, 23)
                      else
                        w.drawInputInt(mem, curAddress, field.name, w.ctSize_t_inv[field.size])
                      end
                    end -- ipairs(actorStruct)
                    
                  end) -- Actor Table
                end) -- actorName Tab
            
            end

          end -- ipairs(actors)
        end) -- ActorsChild TabBar
      end) -- Actors Tab
    
    
      imgui.safe.BeginTabItem('Ashley', function()

        w.drawSlider(mem, maxSpeed , 'MaxSpeed', 'uint8_t*', 0, 40)
        w.drawSlider(mem, curSpeed, 'CurSpeed', 'uint8_t*', 0, 40)
        w.drawSlider(mem, strength, 'STR', 'uint8_t*', 0, 255)
        w.drawSlider(mem, ashleySize , 'Size AS', 'int16_t*', 512, 14000, 2)
        
        imgui.SeparatorText('Coordinates')
        imgui.safe.BeginTable('TableCoordinates', 2, tableFlags, function() 
           imgui.TableSetupColumn('' , imgui.constant.TableColumnFlags.WidthFixed, 136 )

           imgui.TableNextColumn(); w.drawInputInt(mem, posX, 'X', 'int16_t*')
           imgui.TableNextColumn(); w.drawSlider(mem, posX, '##x', 'int16_t*', -2500, 2500)
           imgui.TableNextColumn(); w.drawInputInt(mem, posY, 'Y', 'int16_t*')
           imgui.TableNextColumn(); w.drawSlider(mem, posY, '##y', 'int16_t*', -2500, 2500)
           imgui.TableNextColumn(); w.drawInputInt(mem, posZ, 'Z', 'int16_t*', 1, true)
           imgui.TableNextColumn(); w.drawSlider(mem, posZ, '##z', 'int16_t*', 150, -500)
        end) -- TableCoordinates
        
        imgui.SeparatorText('Checks')
        w.drawCheckbox(mem, mode, 'Battle Mode', 0x01, 0x00, true)
        imgui.SameLine()
        _, canMoonJump = imgui.Checkbox('Moon Jump', canMoonJump)
        
        if canMoonJump then
          if PCSX.SIO0.slots[1].pads[1].getButton(square) then posZPtr[0] = posZPtr[0] - 20 end
        end
        
        imgui.SeparatorText('Strings')
        w.drawInputText(mem, currWeaponName, 'Weapon\'s name', 16 )
        w.drawInputText(mem, charName, 'Character\'s name', 16 )
        
      end) -- Ashley
      
      
      imgui.safe.BeginTabItem('Rooms', function()
        
        if imgui.Button('Trigger Load Room:') and mem[loadRoom] == 0 then mem[loadRoom] = 2 end
        imgui.SameLine(); imgui.TextUnformatted( string.format( '%04X', roomIdToLoadPtr[0] ) )

        imgui.PushItemWidth(190)
        imgui.safe.BeginCombo( '##Area', areaDesc , function()
          for k, v in ipairs(area_t) do
            if imgui.Selectable( v ) then areaId=k; areaDesc=v end
          end
        end) -- ##Area
        imgui.PopItemWidth()
        
        imgui.safe.BeginListBox('##Room', function()
          for k, v in pairs(map_t) do
            if v.area == areaId then
              if imgui.Selectable( v.desc ) then roomIdToLoadPtr[0] = v.id end
            end
          end
        end) -- ##Room
        
      end) -- Rooms
      
      
      imgui.safe.BeginTabItem('Items', function()
        
        imgui.safe.BeginListBox('##Item', 0, itemCount*12, function()
          for i=0, itemCount, 4 do
            local id = itemIdPtr[i]
            if id > 0x42 then
              itemCount = i+4
              imgui.SetNextItemWidth(90)
              -- '## .. i' is for a unique imgui ID
              w.drawInputInt(mem, itemQtd+i , items_t[ id ] .. '##' .. i, 'uint8_t*' )
            end
          end
        end)  -- ##Item
        
        imgui.SetNextItemWidth(150);
        imgui.safe.BeginCombo( '##New item', 'Add a new item:', function()
          for k, v in pairs(items_t) do
            if imgui.Selectable( v ) then itemIdPtr[itemCount] = k; itemIdPtr[itemCount+1] = 1; itemQtdPtr[itemCount] = 1 end
          end
        end) -- ##New item
        
      end) -- Items
      
      
      imgui.safe.BeginTabItem('Freeze', function()
        
        _, w.canFreeze = imgui.Checkbox('Enable?', w.canFreeze)
        imgui.SameLine()
        imgui.SetNextItemWidth(100)
        local changedFre, freezeValue = imgui.extra.InputText('Add address', '' , hexFlags )
        
        if changedFre and not w.isEmpty(freezeValue) then
          local freezeNumber = tonumber(freezeValue, 16)
          w.addFreeze(mem,freezeNumber)
        end
        
        imgui.SetNextItemWidth(280)
        w.DrawFrozen()
        
      end) -- Freeze


      imgui.safe.BeginTabItem('Memory', function()
        changedMen, memWatch = imgui.extra.InputText('Add address', memWatch , hexFlags)
        if changedMen then
          memWatchInt = tonumber(memWatch, 16)
        end
        imgui.SetNextItemWidth(150)
        _, size_bytes = imgui.Combo("label", size_bytes, w.comboList( size_bytes_t ) )
        w.drawMemory(mem,memWatchInt,size_bytes + 1)
      end) -- Memory
      

      imgui.safe.BeginTabItem('Save/Load', function()
        
        _, saveName = imgui.extra.InputText('save file name', saveName )
        w.drawSaveButton(saveName); imgui.SameLine(); w.drawLoadButton(saveName)

      end) -- Save/Load      
      
      imgui.safe.BeginTabItem('Colors', function()
        
        colors1 = w.drawColorPicker3('colors1',colors1)
        colors2 = w.drawColorPicker4('colors2',colors2)

      end) -- Save/Load      
      
    end) -- MainTabBar

  end) -- Command

end --DrawImguiFrame

