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


function dec2hex( num )
  return ("%X"):format(math.abs(num))
end

function inputLogger(mem, address)
  
  -- prints the controller input
  local jokerPtr = ffi.cast('uint16_t*', mem + bit.band(address, 0x1fffff))
  local input = ''
  
  if jokerPtr[0] ~= lastInput and jokerPtr[0] ~= 0 then
    for k, v in pairs(input_t) do
      if bit.band( jokerPtr[0] , k ) ~= 0 then
        if input == '' then input = v else input = input .. ' + ' .. v end
      end
    end
    print (input)
  end
  
  lastInput = jokerPtr[0]
  
  end

function addBpWithCondition(mem, address, width, cause, condition)
  
  -- only breaks if the value being written is equal the given input condition
  -- declared globaly using the cause parameter
  assert( not _G[cause] , ' ss ')
  
  _G[cause] = PCSX.addBreakpoint( address, 'Write', width, cause , function()
    
    local regs = PCSX.getRegisters()
    local pc = regs.pc
    local pc_ptr = ffi.cast('uint32_t*', mem + bit.band(pc, 0x1fffff))
    
    local regIndex = bit.band( bit.rshift( pc_ptr[0] , 16), 0x1f )     -- 0001 1111
    local regValue = PCSX.getRegisters().GPR.r[regIndex]               -- array starts at 0
    
    if regValue == condition then PCSX.pauseEmulator(); PCSX.GUI.jumpToPC(pc) end
  end)
end

resume = 0

function jfmsu(mem, address, maxTries)
  
  address = bit.band(address, 0x1fffff) + resume
  maxTries = maxTries or 2
  local tries = 0
  for i=0,200,1 do
    if mem[address+i] ~= 0 then
      mem[address+i] = mem[address+i] + 0xCC
      tries = tries+1
    end
    if tries == maxTries then resume = resume + i + 1; break end;
  end
end


function comboList(t)
  
  -- Formats lua table to be used with imgui.Combo:
  -- c, v = imgui.Combo("label", v, comboList(t) )
  local list = ''
  for k, v in pairs(t) do
    list = v .. '\0' .. list
  end
  return list
end


local function returnKey (t, value)
  
  -- Return the array key from the given value
    for k, v in ipairs(t) do
        if v == value then return k end
    end
end


function decode(mem,address)
  
  -- Decodes text from game memory using the text_t table file
  local address = ffi.cast('uint8_t*', mem + bit.band(address, 0x1fffff))
  local text = ''
  
  for i=0,64,1 do
    local charIndex = address[0+i]
    if charIndex ~= 0xE7 then text = text .. text_t[charIndex] else break end;
  end
  
  return text
end


function insert_string(mem,address,text,size)
  
  -- Inserts string into game memory using the text_t table file
  -- the size parameter is needed for zeroing out the following btyes and to prevent overflow 
  -- 0xE7 is the string terminator for Vagrant Story
  
  local address = ffi.cast('uint8_t*', mem + bit.band(address, 0x1fffff))

  text = string.sub(text,1,size-1)

  for i=0,size,1 do
    if #text -i > 0 then
      address[i] = returnKey( text_t, string.sub(text,i+1,i+1) )
    elseif #text -i == 0 and #text ~= 0 then
      address[i] = 0xE7
    else
      address[i] = 0
    end
  end
end
