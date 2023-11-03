local helpers = {}

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


function helpers.inputLogger(mem, address)
  
  -- prints the controller input
  local jokerPtr, value = helpers.validateAddress(mem,address,'uint16_t*')
  
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


function helpers.dec2hex( num )

  -- returns string
  return ("%X"):format(math.abs(num))
end


function helpers.validateAddress(mem,address,ct)

  --ffi.istype(ct, address)
  local address = bit.band(address, 0x1fffff)
  local addressPtr = ffi.cast(ct, mem + address)
 
  return addressPtr, addressPtr[0], address
end


function helpers.isEmpty(s)
  return s == nil or s == ''
end


function helpers.addBpWithCondition(mem, address, width, cause, condition)
  
  -- only breaks if the value being written is equal the given input condition
  -- declared using the cause parameter
  assert( not helpers[cause] , cause .. ' already exists.')
  
  helpers[cause] = PCSX.addBreakpoint( address, 'Write', width, cause , function()
    
  local regs = PCSX.getRegisters()
  local pc = regs.pc
    
  local pc_ptr, value = helpers.validateAddress(mem,pc,'uint32_t*')
    
  local regIndex = bit.band( bit.rshift(value , 16), 0x1f )
  local regValue = PCSX.getRegisters().GPR.r[regIndex]               -- array starts at 0
    
  if regValue == condition then PCSX.pauseEmulator(); PCSX.GUI.jumpToPC(pc) end
  end)
end


local resume = 0

function helpers.jfmsu(mem, address, value, maxTries)
  
  -- For poking adresses and seeing what changes
  address = bit.band(address, 0x1fffff) + resume
  maxTries = maxTries or 2
  local tries = 0
  for i=0,200,1 do
    if mem[address+i] ~= 0 then
      mem[address+i] = mem[address+i] + value
      tries = tries+1
    end
    if tries == maxTries then resume = resume + i + 1; break end;
  end
end


function helpers.comboList(t)
  
  -- Formats lua table to be used with imgui.Combo:
  -- c, v = imgui.Combo("label", v, comboList(t) )
  local list = ''
  for k, v in pairs(t) do
    list = v .. '\0' .. list
  end
  return list
end


function helpers.returnKey (t, value)
  
  -- Return the array key from the given value
  for k, v in ipairs(t) do
    if v == value then return k end
  end
end


function helpers.decode(mem,address,size,tbl)
  
  -- Decodes text from game memory using the a text table file
  -- for ASCII, string.byte should work
  local addressPtr = ffi.cast('uint8_t*', mem + bit.band(address, 0x1fffff))
  local text = ''
  
  for i=0,size,1 do
    local charIndex = addressPtr[0+i]
    if charIndex ~= 0xE7 then text = text .. tbl[charIndex] else break end;
  end
  
  return text
end


function helpers.insert_string(mem,address,size,tbl,text)
  
  -- Inserts string into game memory using the a text table file
  -- bytes ahead are cleared
  -- 0xE7 is the string terminator for Vagrant Story
  local addressPtr = ffi.cast('uint8_t*', mem + bit.band(address, 0x1fffff))
  
  text = string.sub(text,1,size-1)
  
  for i=0,size,1 do
    if #text -i > 0 then
      addressPtr[i] = helpers.returnKey( tbl, string.sub(text,i+1,i+1) )
    elseif #text -i == 0 and #text ~= 0 then
      addressPtr[i] = 0xE7
    else
      addressPtr[i] = 0
    end
  end
end


helpers.frozenAddresses = {}

function helpers.addFreeze(mem,address,value)
  
  -- Add a address to the frozenAddresses table, value is optional
  local addressPtr, cur_value, address = helpers.validateAddress(mem,address,'uint8_t*')
  local value = value or cur_value
  helpers.frozenAddresses[address] = { addressPtr, value }
end 


helpers.canFreeze = true

function helpers.doFreeze()
  
  -- used like:
  -- PCSX.Events.createEventListener('GPU::Vsync', helpers.doFreeze )
  if helpers.canFreeze then 
    for k, v in pairs(helpers.frozenAddresses) do
      v[1][0] = v[2] -- pointer[0] = value
    end
  end
end


return helpers