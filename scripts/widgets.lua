function drawCheckbox(mem, address, name, valueOn, valueOff, isReadOnly)
  
  -- display only checkbox if isReadOnly is true, in which case valueOff is not even used
  
  local addressPtr, value = validateAddress(mem,address,'uint8_t*')

  local check
  if value == valueOn then check = true else check = false end
  
  if isReadOnly then imgui.BeginDisabled() end
  
  local changed, check = imgui.Checkbox(name, check)
  if changed and not isReadOnly then
    if check then addressPtr[0] = valueOn else addressPtr[0] = valueOff end
  end
  
  if isReadOnly then imgui.EndDisabled() end
end


function drawSlider(mem, address, name, ct, min, max)
  
  -- works nicely with min>max in cases where the logic is reversed
  
  local addressPtr, value = validateAddress(mem,address,ct)
  local changed, value = imgui.SliderInt(name, value, min, max, '%d')
  
  if changed then addressPtr[0] = value end
  
end


function drawSliderLoop(mem, address, name, ct, min, max, range)
  
  -- same as drawSlider, also changes the bytes ahead, defined by range
  
  local addressPtr, value = validateAddress(mem,address,ct)
  local changed, value = imgui.SliderInt(name, value, min, max, '%d')

  if changed then
    for i=0,range,1 do
      addressPtr[i] = value
    end
  end

end


function drawInputInt(mem, address, name, ct, step, isReversed )
  
  -- isReversed = true in the few cases in which the logic is reversed
  -- a optional parameter default value:
  local step = step or 1
  
  local addressPtr, value = validateAddress(mem,address,ct)
  local changed, value  = imgui.InputInt(name, value, step)
  
  if changed then
    if isReversed then addressPtr[0] = 2*addressPtr[0] - value else addressPtr[0] = value end
  end
  
end


function drawDrag(mem, address, name, ct, min, max, speed )
  
  -- a optional parameter default value:
  local speed = speed or 1

  -- it needs AlwaysClamp otherwise it updates the values as soon you start typing
  local addressPtr, value = validateAddress(mem,address,ct)
  local changed, value  = imgui.DragInt(name, value, speed, min, max, '%d', imgui.constant.SliderFlags.AlwaysClamp)
  
  if changed then
    addressPtr[0] = value
  end
  
end


function drawRadio(mem, address, name )
  
  -- display a bunch of radio buttons in case you want to visually debug a single nibble
  local addressPtr, value = validateAddress(mem,address,'uint8_t*')
  local nibble = bit.band( value , 0x0f )  -- better than using math.fmod(value,16) ?
  imgui.SeparatorText(name)
  imgui.NewLine()
  imgui.BeginGroup()
  for i = 0,15,1 do
    imgui.SameLine()
    if imgui.RadioButton(dec2hex(i), nibble == i) then
      addressPtr[0] = bit.bor ( bit.band( value , 0xf0) ,  i )
    end
  end
  imgui.EndGroup()
  
end


function drawInputText(mem, address, name, size )
  
  -- if this function returned a value to it's own name, we'd lose keyboard focus for every char typed, not sure why
  -- And given that lua strings are alwyas passed as value, always
  -- we use the _G environment to bypass that

  local hint = _G[name] or name
  local changed, value = imgui.extra.InputText('##'..name, hint , imgui.constant.InputTextFlags.EnterReturnsTrue)
  if changed then
    insert_string(mem,address,value,size)
    _G[name] = value
  end
  
end


function drawSaveButton(saveName)
      if imgui.Button('Save') and not isEmpty(saveName) then
        local save = PCSX.createSaveState()
        local file = Support.File.open(saveName, 'TRUNCATE')
        if not file:failed() then
          file:writeMoveSlice(save)
          print('Saved file' .. saveName)
        end
        file:close()
      end
end


function drawLoadButton(saveName)
    if imgui.Button('Load') and not isEmpty(saveName) then
      local file = Support.File.open(saveName, 'READ')
      if not file:failed() then
        PCSX.loadSaveState(file)
        print('Loaded file ' .. saveName)
      end
    file:close()
  end
end

function validateAddress(mem,address,ct)
  
  -- istype checks if it's already a pointer
  local addressPtr
  
  if ffi.istype(ct, address) then
    addressPtr = address
  else
    addressPtr = ffi.cast(ct, mem + bit.band(address, 0x1fffff))
  end
  
  return addressPtr, addressPtr[0]
  
end