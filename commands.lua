local global   = js.global
local document = global.document

if (global.luaCommands == 1) then
  error ("Aborted attempt to reinitialize page commands. *quê?*")
end

local function doCommands()
  local commands = {{
    ["^%s*echo(%s*)(.*)$"] = function(...)
                               if zeroargumentLegitCall(...) then
                                 return (string.rep(" ",#(select(1,...))-1) .. (select(2,...)) or "") .. "\n" 
                               else
                                 return ""
                               end
                             end},{
    ["^%s*whoami(%s*)(.*)$"] = function(...)
                                  if zeroargumentLegitCall(...) then
                                    return "オップナー2608"
                                  else
                                    return ""
                                  end
                                end}
  }
  
  for __dummy,command in ipairs(commands) do
   table.insert(global.shellCommands, #global.shellCommands, command)
  end
end

function global.commandsWait()
  if (global.luaInit ~= 1) then
    print ("Waiting for page init...")
    global.window:setTimeout (global.commandsWait, 50)
    return
  end
  print ("Attempting to load commands now!")
  doCommands()
  global.luaCommands = 1
  return true
end

global.commandsWait()

