--========================================================
-- Vagrant Story script for the pcsx-redux emulator
-- made by optrin
--========================================================

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

function drawSlider(mem, address, name, init, min, max)
  
  -- works nicely with min>max in cases where the logic is reversed
  
  local addressPtr = ffi.cast(init, mem + bit.band(address, 0x1fffff))
  local value = addressPtr[0]
  local changed
  
  -- it deals with signed types automatically despite the format string:
  changed, value = imgui.SliderInt(name, value, min, max, '%d' )
  if changed then addressPtr[0] = value end
end

function drawInput(mem, address, name, init, step, isReversed )
  
  -- isReversed = true in the few cases in which the logic is reversed
  -- a optional parameter default value:
  step = step or 1
  
  local addressPtr = ffi.cast(init, mem + bit.band(address, 0x1fffff))
  local value = addressPtr[0]
  local changed
  
  changed, value  = imgui.InputInt(name, value, step );
  if changed then
    if isReversed then addressPtr[0] = 2*addressPtr[0] - value else addressPtr[0] = value end
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
