function dec2hex( num )
  return ("%X"):format(math.abs(num))
end

function drawCheckbox(mem, address, name, valueOn, valueOff, isReadOnly)
  
  -- display only checkbox if isReadOnly is true, in which case valueOff is not even used
  
  local addressPtr = ffi.cast('uint8_t*', mem + bit.band(address, 0x1fffff))
  local changed
  local check
  if addressPtr[0] == valueOn then check = true else check = false end
  
  if isReadOnly then imgui.BeginDisabled() end
  changed, check = imgui.Checkbox(name, check)
  if isReadOnly then imgui.EndDisabled() end
  
  if changed and not isReadOnly then
    if check then addressPtr[0] = valueOn else addressPtr[0] = valueOff end
  end
  
end

function drawSlider(mem, address, name, ct, min, max)
  
  -- works nicely with min>max in cases where the logic is reversed
  
  local addressPtr = ffi.cast(ct, mem + bit.band(address, 0x1fffff))
  local value = addressPtr[0]
  local changed

  changed, value = imgui.SliderInt(name, value, min, max, '%d')
  if changed then addressPtr[0] = value end
end

function drawSliderLoop(mem, address, name, ct, min, max, range)
  
  -- same as drawSlider, also changes the bytes ahead 
  
  local addressPtr = ffi.cast(ct, mem + bit.band(address, 0x1fffff))
  local value = addressPtr[0]
  local changed

  changed, value = imgui.SliderInt(name, value, min, max, '%d')

  if changed then
    for i=0,range,1 do
      addressPtr[i] = value
    end
  end

end

function drawInput(mem, address, name, ct, step, isReversed )
  
  -- isReversed = true in the few cases in which the logic is reversed
  -- a optional parameter default value:
  step = step or 1
  
  local addressPtr
  if ffi.istype(ct, address) then addressPtr = address else addressPtr = ffi.cast(ct, mem + bit.band(address, 0x1fffff)) end
  
  local value = addressPtr[0]
  local changed
  
  changed, value  = imgui.InputInt(name, value, step );
  if changed then
    if isReversed then addressPtr[0] = 2*addressPtr[0] - value else addressPtr[0] = value end
  end
end

function drawDrag(mem, address, name, ct, min, max, speed )
  
  -- a optional parameter default value:
  speed = speed or 1
  
  local addressPtr
  if ffi.istype(ct, address) then addressPtr = address else addressPtr = ffi.cast(ct, mem + bit.band(address, 0x1fffff)) end
  
  local value = addressPtr[0]
  local changed
  
  --imgui.constant.SliderFlags.AlwaysClamp
  changed, value  = imgui.DragInt(name, value, speed, min, max, '%d')
  if changed then
    addressPtr[0] = value
  end
end

function drawRadio(mem, address, name )
  
  -- display a bunch of radio buttons in case you want to visually debug a single nibble
  local value  = mem[ bit.band(address, 0x1fffff) ]
  local nibble = bit.band( value , 0xf )  -- better than using math.fmod(value,16) ?
  imgui.SeparatorText(name)
  imgui.NewLine()
  for i = 0,15,1 do
    imgui.SameLine();
    imgui.RadioButton(dec2hex(i), nibble == i)
  end
  
end