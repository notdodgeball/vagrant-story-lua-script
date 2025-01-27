--========================================================
-- helper and dear imgui module for the pcsx-redux emulator
-- made by optrin
--========================================================

local w = {}


-- RNG functions
--========================================================

w.rngCounter = 0
w.RNGs = {}        -- our rand numbers
w.RNGsOut = {}     -- our formatted rand numbers for output


-- ANSI C Linear Congruential Pseudo-RNG
local function nextRNG(value)
  local high = (value * 0x41C6) % 0x10000
  local low  = (value * 0x4E6D) % 0x100000000
  return ((low + high * 0x10000) % 0x100000000) + 0x3039
end


-- Return previous, current and upcoming rng values
function w.rngTable(seedPtr,size,current)

  current = current or 2                            -- the position of the current seed in the array
  local newRNG = seedPtr[0]
  
  if newRNG ~= w.RNGs[current] then
    
    w.rngCounter = w.rngCounter + 1
    
    -- mismatch (a loaded save more likely)
    local mismatch = newRNG ~= w.RNGs[current+1]

    for i=1, size do
    
      if i < current and (mismatch or newRNG == 0)  -- When no seed has yet been calculated or a mismatch
        then w.RNGs[i] = 0
      elseif i == current
        then w.RNGs[i] = newRNG
      elseif i == size or mismatch                      -- new seeds when there is a mismatch or it's the last one
        then w.RNGs[i] = nextRNG( w.RNGs[i-1] )
      else                                              -- otherwise it's the following one
        w.RNGs[i] = w.RNGs[i+1]
      end
      
      w.RNGsOut[i] = string.format("%02d", i - current) .. ' - ' .. w.dec2hex( w.RNGs[i] , '%08X' ) -- bit.band(w.RNGs[i], 0xffffffff)
    end

  end

return w.RNGsOut

end


-- advances the RNG n steps, credits to ALAKTORN
local function RNGSteps(iRNG, steps)
  for i = 1, steps do
    iRNG = nextRNG(iRNG)
  end
  return iRNG
end



-- Controller input functions
--========================================================

local lastInput = 0

local input_t = {}
input_t[0x0001] = 'L2';       input_t[0x0002] = 'R2'
input_t[0x0004] = 'L1';       input_t[0x0008] = 'R1'
input_t[0x0010] = 'Triangle'; input_t[0x0020] = 'Circle'
input_t[0x0040] = 'X';        input_t[0x0080] = 'Square'
input_t[0x0100] = 'Select';   input_t[0x0200] = 'NULL'
input_t[0x0400] = 'NULL';     input_t[0x0800] = 'Start'
input_t[0x1000] = 'Up';       input_t[0x2000] = 'Right'
input_t[0x4000] = 'Down';     input_t[0x8000] = 'Left'


function w.inputLogger(mem, address)
  
  -- prints the controller input, needs to be called from inside DrawImguiFrame()
  
  local jokerPtr, value = w.validateAddress(mem,address,'uint16_t*')
  
  local input = ''
  
  if jokerPtr[0] ~= lastInput and jokerPtr[0] ~= 0 then
    for k, v in pairs(input_t) do
      if bit.band( jokerPtr[0] , k ) ~= 0 then
        if input == '' then input = v else input = input .. ' + ' .. v end
      end
    end
    print (input)
  end
  
  lastInput = value
end



-- Helpers functions
--========================================================

-- ctSize_t[ct] will return the size of ct in bytes
-- ffi.sizeof doesn't work with pointers because all pointers are 8 byte long in a 64 bit system 
-- even reflect.typeof(ct).size will get it "wrong"

local ctSize_t = {
 ['__int8']   = 1,   ['__int8*'] = 1
,['int8_t']   = 1,   ['int8_t*'] = 1
,['uint8_t']  = 1,  ['uint8_t*'] = 1

,['__int16']  = 2,  ['__int16*'] = 2
,['int16_t']  = 2,  ['int16_t*'] = 2
,['uint16_t'] = 2, ['uint16_t*'] = 2

,['__int32']  = 4,  ['__int32*'] = 4
,['int32_t']  = 4,  ['int32_t*'] = 4
,['uint32_t'] = 4, ['uint32_t*'] = 4
}

w.ctSize_t_inv = {
 [1] = 'uint8_t*'
,[2] = 'uint16_t*'
,[4] = 'uint32_t*'
}


function w.roundTo2(n)
  return math.floor((math.floor(n*2) + 1)/2)
end


function w.isArrayAllZeros(array)

    -- Check if all values are zero
    for k, v in pairs(array) do
        if v ~= 0 then
            return false
        end
    end
    return true
end


function w.isArrayAllZeros2(array)

    -- Sum all the values in the array
    local sum = 0
    for k, v in pairs(array) do
        sum = sum + v
    end

    return sum == 0
end


function w.dec2hex(num, format)

  -- returns hex string
  format = format or "%X"
  return string.format(format , num)
end


function w.isValidAddress(n)
  return n > 0x80000000 and n < 0x80200000
end


function w.isEmpty(s)
  return s == nil or s == ''
end


function w.validateAddress(mem,address,ct)
  
  -- main function to deal with pointers
  -- the address parameter can be a pointer already, in which case we cast back to uintptr_t so we can get the address itself
  
  assert(reflect.typeof(ct).what == 'ptr' , ct .. ' is not a pointer type.')
  assert(address ~= nil , 'null address call to validateAddress() ' .. ct)

  local addressPtr

  if not ffi.istype(ct, address) then
    address = bit.band(address, 0x1fffff)
    addressPtr = ffi.cast(ct, mem + address)
  else
    addressPtr = address
    local temp = tonumber( ffi.cast("uintptr_t", address) )
    address = bit.band(temp, 0x1fffff)
  end
  
  return addressPtr, addressPtr[0], address
end


function w.comboList(t)
  
  -- Formats lua table to be used with imgui.Combo:
  -- c, v = imgui.Combo("label", v, w.comboList(t) )
  local list = ''
  for k, v in ipairs(t) do
    list = list .. v .. '\0'
  end
  return list
end


function w.returnKey (t, value)
  
  -- Return the array key for the given value
  for k, v in ipairs(t) do
    if v == value then return k end
  end
end


function w.decode(mem,address,size,tbl)
  
  -- Decodes text from game memory using the a text table file
  -- for ASCII, string.byte should work
  local addressPtr = ffi.cast('uint8_t*', mem + bit.band(address, 0x1fffff))
  local text = ''
  
  local i = 0
  while i < size do

    local charIndex = addressPtr[i]
    
    -- VG has some 16bit chars, which we can mostly ignore, sadly 0xFA06 is a space and so is 0x8F
    if charIndex == 0xFA then 
      i = i + 1; text = text .. " ";
    elseif charIndex == 0xE7 then 
      break
    else
      if tbl[charIndex] ~= nil then text = text .. tbl[charIndex] end
    end;
    
    i = i + 1
  end
  
  return text
end


function w.insert_string(mem,address,size,tbl,text)
  
  -- Inserts string into game memory using the a text table file

  local addressPtr = ffi.cast('uint8_t*', mem + bit.band(address, 0x1fffff))
  
  -- Trim down to size
  text = string.sub(text,1,size-1)
  
  for i=0,size,1 do
    if #text -i > 0 then
      -- returnKey uses a simple ipairs() and will return a space as 0x8F
      addressPtr[i] = w.returnKey( tbl, string.sub(text,i+1,i+1) )
    elseif #text -i == 0 and #text ~= 0 then
      -- 0xE7 is the string terminator for Vagrant Story
      addressPtr[i] = 0xE7
    else
      -- bytes ahead are cleared
      addressPtr[i] = 0
    end
  end
end



-- Event functions
--========================================================

--- A simple frame counter
w.vblankCtr = 0

eventVsyncCtr = PCSX.Events.createEventListener('GPU::Vsync', function()
    w.vblankCtr = w.vblankCtr +1
end )


--- A simple cycle counter, it's printed to console when the emulator is paused
--- needs commit 4869d306391c6889adfa4a00c4e80dad4006d938 (pull request #1559)
w.cycleCtr = 0

eventPauseCtr = PCSX.Events.createEventListener('ExecutionFlow::Pause', function()
  print( string.format('%d',PCSX.getCPUCycles() - w.cycleCtr) .. ' cycles' )
  w.cycleCtr = PCSX.getCPUCycles()
end )



-- Breakpoint functions
--========================================================

function w.addBpWrittenAs(mem, address, width, id, condition)
  
  -- only breaks if the value being written is equal the given parameter
  -- declared using the id parameter
  assert( not w[id] , id .. ' already defined.')
  
  w[id] = PCSX.addBreakpoint(address, 'Write', width, id , function()
    
  local regs = PCSX.getRegisters()
  local pc = regs.pc
    
  local pc_ptr, value = w.validateAddress(mem,pc,'uint32_t*')
    
  local regIndex = bit.band( bit.rshift(value , 16), 0x1f )
  local regValue = PCSX.getRegisters().GPR.r[regIndex]               -- array starts at 0
    
  if regValue == condition then PCSX.pauseEmulator(); PCSX.GUI.jumpToPC(pc) end
  end)
end


function w.addBpNotReadAt(mem, address, width, id, condition)
  
  -- only breaks if the value is being read at the given address
  -- declared using the id parameter
  assert( not w[id] , id .. ' already defined.')
  
  w[id] = PCSX.addBreakpoint( address, 'Read', width, id , function()
  
  local regs = PCSX.getRegisters()
  local pc = regs.pc

  if pc ~= condition then
    PCSX.pauseEmulator(); PCSX.GUI.jumpToPC(pc)
  -- else
    -- print("breakpoint " .. id .. " was discarted" )
  end
  end)
end



-- Freeze functions
--========================================================

w.canFreeze = false
w.frozenAddresses = {}


function w.isFrozen(address)
  return w.frozenAddresses[address] ~= nil
end


function w.addFreeze(mem,address,ct,value)
  
  -- Add a address to the frozenAddresses table, value is optional
  local ct = ct or 'uint8_t*'
  local addressPtr, cur_value, address = w.validateAddress(mem,address,ct)
  
  if not w.frozenAddresses[address] then 
    local value = value or cur_value
    w.frozenAddresses[address] = { true, addressPtr, value }
  end
end 


function w.doFreeze()
  
  -- Does the actual freezing, used like:
  -- PCSX.Events.createEventListener('GPU::Vsync', w.doFreeze )
  if w.canFreeze then 
    for k, v in pairs(w.frozenAddresses) do
      v[2][0] = v[3] -- pointer[0] = value
    end
  end
end


function w.drawFreezeCheckbox(mem, address, name, ct, range)

  -- Freeze checkbox for a specific range
  -- useful when it's bigger than one byte as it freezes them all
  local isFrozen = w.isFrozen(address)
  if not w.canFreeze then imgui.BeginDisabled() end
  local changed, isFrozen = imgui.Checkbox('Freeze##' .. name, isFrozen )
  if not w.canFreeze then imgui.EndDisabled() end

  -- ctSize_t[ct] Returns the size of ct in bytes
  if changed then
    for i=0, range*ctSize_t[ct], ctSize_t[ct] do
      if isFrozen then w.addFreeze(mem,address+i,ct,value) else w.frozenAddresses[address+i] = nil end
    end
  end

  -- We might as well return it
  return isFrozen

end


function w.DrawFrozen()

  -- Draws a ListBox with the all frozen addresses
  imgui.safe.BeginListBox('##Frozen', function()
    for k, v in pairs(w.frozenAddresses) do
      if imgui.SmallButton('x##'..k) then w.frozenAddresses[k] = nil end
      imgui.SameLine();
      if imgui.Selectable(("8%.7X"):format(math.abs(k)) .. ' - ' .. w.dec2hex( v[3] )) then
        PCSX.GUI.jumpToMemory(k,4)
      end
    end
  end)
end

-- Executes doFreeze every frame
eventVsyncFreeze = PCSX.Events.createEventListener('GPU::Vsync', w.doFreeze )



-- Color functions
--========================================================

function w.ColorToNVG(acolors, alpha)
    
    -- color table to NVGcolor struct
    if acolors == nil or w.isArrayAllZeros(acolors) then
      acolors = {r = 0, g = 1, b = 0}
    end
    
    alpha = alpha or 200

    return  nvg.transRGBA( nvg.Color.New(acolors.r, acolors.g, acolors.b) , alpha)
    -- return nvg.Color.New(acolors.r, acolors.g, acolors.b, alpha)
    -- return nvg.RGBA(colors.r* 255, colors.g* 255, colors.b* 255, colors.a* 255)
end


local function rgbTableToHex(colorTable)
    
    --  math.ceil or floor won't work
    local r, g, b = w.roundTo2(colorTable.r * 255), w.roundTo2(colorTable.g * 255), w.roundTo2(colorTable.b * 255)
    return string.format("#%02X%02X%02X", r, g, b)
end


local ColorPickerFlags     = 0

function w.drawColorPicker3(label,colors)
    
    if imgui.Button(label) then w[label] = not w[label] end
    
    if w[label] then
      imgui.SetNextItemWidth(150)
      
      _, colors = imgui.extra.ColorPicker3(label,colors,ColorPickerFlags)
      
      -- if _ then print(rgbTableToHex(colors)) end
      
    end
    
    return colors
end


function w.drawColorPicker4(label,colors)

    if imgui.Button(label) then w[label] = not w[label] end
    
    if w[label] then
      imgui.SetNextItemWidth(150)
      
      _,colors = imgui.extra.ColorPicker4(label,colors,ColorPickerFlags)
      
      -- if _ then print(rgbTableToHex(colors)) end
      
    end
    return colors
    
end



-- Widget functions
--========================================================

w.fontsize = imgui.GetFontSize()

function w.drawCheckbox(mem, address, name, valueOn, valueOff, isReadOnly)
  
  -- display only checkbox if isReadOnly is true, in which case valueOff is not even used
  local addressPtr, value = w.validateAddress(mem,address,'uint8_t*')
  
  local check
  if value == valueOn then check = true else check = false end
  
  if isReadOnly then imgui.BeginDisabled() end
  
  local changed, check = imgui.Checkbox(name, check)
  if changed and not isReadOnly then
    if check then addressPtr[0] = valueOn else addressPtr[0] = valueOff end
  end
  
  if isReadOnly then imgui.EndDisabled() end

end


function w.drawSlider(mem, address, name, ct, min, max, range)
  
  -- works nicely with min>max in cases where the logic is reversed
  -- also changes the bytes ahead, defined by range
  local range = range or 0
  local addressPtr, value, address = w.validateAddress(mem,address,ct)
  local changed, value = imgui.SliderInt(name, value, min, max, '%d', imgui.constant.SliderFlags.AlwaysClamp)

  local isfrozen = w.isFrozen(address)
  -- imgui.SameLine(); w.drawFreezeCheckbox(mem, address, name, ct, range)

  if changed and not isfrozen then
    for i=0,range,1 do
      addressPtr[i] = value
    end
  end
  
end


function w.drawMemory(mem, address, bytes, range)
  
  -- Display the memory as simple text, only useful for copying it basically
  local range = range or 143
  local bytes = bytes or 0
  local ct = ''
  local formato = ''
  
  if bytes == 1 then 
    ct = 'uint8_t*'
    formato = '%02X'
  elseif bytes == 2 then
    ct = 'uint16_t*'
    formato = '%04X'
  else error ("")
  end
  
  local addressPtr, value, address = w.validateAddress(mem,address,ct)
  local text = ''
  
  for i=0,range,1 do
    if math.fmod(i,16) == 0 then text = text .. '\n' .. w.dec2hex(address + 8*i*bytes, '%08X') .. ': ' end
    text =  text .. w.dec2hex( addressPtr[i] , formato )  .. ' ' 
  end
  
  -- imgui.safe.BeginListBox('Address', function()
  PCSX.GUI.useMonoFont()
  imgui.TextUnformatted( text )
  imgui.PopFont()
  -- end)
  
  if imgui.Button('Copy')  then
    imgui.LogToClipboard()
    imgui.extra.logText(text)
    imgui.LogFinish()
  end
  
end


function w.drawInputInt(mem, address, name, ct, step, isReversed, width )
  
  -- isReversed = true in the few cases in which the logic is reversed
  local step = step or 1
  local width = width or 100
  imgui.SetNextItemWidth(width);
  
  local addressPtr, value = w.validateAddress(mem,address,ct)
  local changed, value  = imgui.InputInt(name, value, step)
  
  if changed then
    if isReversed then addressPtr[0] = 2*addressPtr[0] - value else addressPtr[0] = value end
  end
  
end


function w.drawDrag(mem, address, name, ct, min, max, speed )
  
  -- it needs AlwaysClamp otherwise it updates the values as soon you start typing
  local speed = speed or 1
  local addressPtr, value = w.validateAddress(mem,address,ct)
  local changed, value  = imgui.DragInt(name, value, speed, min, max, '%d', imgui.constant.SliderFlags.AlwaysClamp)
  
  if changed then
    addressPtr[0] = value
  end
  
end


function w.drawRadio(mem, address, name )
  
  -- display a bunch of radio buttons in case you want to visually debug a single nibble
  local addressPtr, value = w.validateAddress(mem,address,'uint8_t*')
  local nibble = bit.band( value , 0x0f )  -- better than using math.fmod(value,16) ?
  imgui.SeparatorText(name)
  imgui.NewLine()
  imgui.BeginGroup()
  for i = 0,15,1 do
    imgui.SameLine()
    if imgui.RadioButton(w.dec2hex(i), nibble == i) then
      addressPtr[0] = bit.bor ( bit.band( value , 0xf0) ,  i )
    end
  end
  imgui.EndGroup()
  
end


function w.drawJumpButton(address)

  -- display button to jump to the address at the Memory Editor
  imgui.SameLine();
    if imgui.Button( '>##' .. address ) then
       PCSX.GUI.jumpToMemory(address,4)
    end

  if imgui.IsItemHovered(imgui.constant.HoveredFlags.ForTooltip) and imgui.BeginTooltip() then
      imgui.TextUnformatted('Jump to memory');
    imgui.EndTooltip();
  end

end


function w.drawInputText(mem, address, name, size, width)
  
  -- Last input is used as hint, otherwise it is read from memory
  local hint = w[address] or w.decode(mem,address,size,text_t)
  local width = width or 200
  imgui.SetNextItemWidth(width)
  
  local changed, value = imgui.extra.InputText(name, hint, imgui.constant.InputTextFlags.EnterReturnsTrue)

  if changed then
    w.insert_string(mem,address,size,text_t,value)
    w[address] = string.sub(value,1,size-1)
  end

  w.drawJumpButton(address)
  
end



-- Save state functions
-- these two below save and load uncompressed files and therefore are incompatible with saves created from the pcsx interface
--========================================================

function w.drawSaveButton(saveName)

  if imgui.Button('Save') and not w.isEmpty(saveName) then
    local save = PCSX.createSaveState()
    local file = Support.File.open(saveName, 'TRUNCATE')
    if not file:failed() then
      file:writeMoveSlice(save)
      print('Saved file' .. saveName)
    end
    file:close()
  end

end


function w.drawLoadButton(saveName)

  if imgui.Button('Load') and not w.isEmpty(saveName) then
    local file = Support.File.open(saveName, 'READ')
    if not file:failed() then
      PCSX.loadSaveState(file)
      print('Loaded file ' .. saveName)
    end
    file:close()
  end

end


return w
