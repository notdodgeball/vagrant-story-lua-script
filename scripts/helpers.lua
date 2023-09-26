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
  
  if _G[cause] then error('') end
  
  _G[cause] = PCSX.addBreakpoint( address, 'Write', width, cause , function()
    
    local regs = PCSX.getRegisters()
    local pc = regs.pc
    local pc_ptr = ffi.cast('uint32_t*', mem + bit.band(pc, 0x1fffff))
    
    local regIndex = bit.band( bit.rshift( pc_ptr[0] , 16), 0x1f )     -- 0001 1111
    local regValue = PCSX.getRegisters().GPR.r[regIndex]               -- array starts at 0
    
    if regValue == condition then PCSX.pauseEmulator(); PCSX.GUI.jumpToPC(pc) end
  end)
end


