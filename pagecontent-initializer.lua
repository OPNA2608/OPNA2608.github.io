local global = js.global
local document = global.document

if (global.luaInit == 1) then
  error ("Aborted attempt to reinitialize page script. *What were they thinking?!*")
end

print("Starting ...")

local function jsexceptionhandler(jsexception)
  return jsexception
end

function zeroargumentLegitCall(...)
  local spaces = select(1,...)
  local rest = select(2,...)
  if #spaces == 0 and #rest > 0 then
    return false
  else
    return true
  end
end

function registerLuaFunctionInJS (name, func)
  if type (name) == "string" and type (func) == "function" then
    global[name] = func
    return name.."()"
  end
end

global.shellCommands = {{
  --default
  ["^(.*)$"] = function(...)
             local line = select(1,...):match("^%s*(.-)$"):match("^(.-)%s*$")
             return (not line or line == "") and "" or ("Invalid command: " .. line:match("^(%S+)"))
           end
}}

local function nodeGenerator( lonsubstructure )
  local nodeTag = lonsubstructure.tag or "p"
  local nodeText = lonsubstructure.text or ""
  local nodeAttributes = lonsubstructure.attributes or {}
  local nodeStyle = lonsubstructure.style or {}
  local nodeSubnodes = lonsubstructure.subnodes or {}
  
  local successCreation, element = xpcall(document.createElement, jsexceptionhandler, document, nodeTag)
  if successCreation then
    element:appendChild(document:createTextNode(nodeText))
    for attributename, attributevalue in pairs(nodeAttributes) do
      element:setAttribute (attributename, type (attributevalue) == "function" and registerLuaFunctionInJS (attributevalue()) or attributevalue)
    end
    for styleelement, stylevalue in pairs(nodeStyle) do
      element.style[styleelement] = stylevalue
    end
    for __dummy, lonsubnodeconstruct in ipairs(nodeSubnodes) do
      element:appendChild(nodeGenerator(lonsubnodeconstruct))
    end
  else
    local err = element
    element = document:createElement("b")
    local errorelement = document:createElement("var")
    errorelement:appendChild(document:createTextNode("FAILED TO CREATE '"..nodeTag.."'-TAG"))
    errorelement:appendChild(document:createElement("br"))
    errorelement:appendChild(document:createTextNode(err or ""))
    element:appendChild(errorelement)
  end
  return element
end

function _G.content( lon )
  print("Loading LON...")
  for attachNode,construct in pairs(lon) do
    print("Probing HTML for Node with ID '"..attachNode.."'...")
    local startNode = document:getElementById(attachNode)
    if startNode then
      print("Node with ID '"..attachNode.."' found. Implanting Subnodes...")
      for __dummy,subNode in ipairs(construct) do
        startNode:appendChild(nodeGenerator(subNode))
      end
    else
      print("Failed to find Node with ID '"..attachNode.."', skipping...")
    end
  end
  print("LON processed.")
end

if (global.luaInit == 0) then
  global.luaInit = 1
end

print("Initialization done.")

