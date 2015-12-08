local public = {}
--
-- This file contains extensions to existing Lua and Corona Libraries
--
-- Note: This content was originally in FRC_Util.
--

local json = require( "json" )
--
-- Localizations (for speedup)
--
local mRand = math.random

--
-- io.* Extensions
--

function io.exists( fileName, base )
	local base = base or system.DocumentsDirectory	
	local fileName = fileName

	if( base ) then
		fileName = system.pathForFile( fileName, base )
	end
	if not fileName then return false end
	local f=io.open(fileName,"r")
	if (f == nil) then 
		return false
	end
	io.close(f)
	return true 
end


if( io.readFile ) then
	print("ERROR! io.readFile() exists already")
else
	function io.readFile( fileName, base )
		local base = base or system.DocumentsDirectory
		local fileContents

		if( io.exists( fileName, base ) == false ) then
			return nil
		end

		local fileName = fileName
		if( base ) then
			fileName = system.pathForFile( fileName, base )
		end

		local f=io.open(fileName,"r")
		if (f == nil) then 
			return nil
		end

		fileContents = f:read( "*a" )

		io.close(f)

		return fileContents
	end
end

if( io.writeFile ) then
	print("ERROR! io.writeFile() exists already")
else
	function io.writeFile( dataToWrite, fileName, base )
		local base = base or system.DocumentsDirectory

		local fileName = fileName
		if( base ) then
			fileName = system.pathForFile( fileName, base )
		end

		local f=io.open(fileName,"w")
		if (f == nil) then 
			return nil
		end

		f:write( dataToWrite )

		io.close(f)

	end
end

if( io.appendFile ) then
	print("ERROR! io.appendFile() exists already")
else
	function io.appendFile( dataToWrite, fileName, base )
		local base = base or system.DocumentsDirectory

		local fileName = fileName
		if( base ) then
			fileName = system.pathForFile( fileName, base )
		end

		local f=io.open(fileName,"a")
		if (f == nil) then 
			return nil
		end

		f:write( dataToWrite )

		io.close(f)
	end
end


if( io.readFileTable ) then
	print("ERROR! io.readFileTable() exists already")
else
	function io.readFileTable( fileName, base )
		local base = base or system.DocumentsDirectory
		local fileContents = {}

		if( io.exists( fileName, base ) == false ) then
			return fileContents
		end

		local fileName = fileName
		if( base ) then
			fileName = system.pathForFile( fileName, base )
		end

		local f=io.open(fileName,"r")
		if (f == nil) then 
			return fileContents
		end

		for line in f:lines() do
			fileContents[ #fileContents + 1 ] = line
		end

		io.close( f )

		return fileContents
	end
end



--
-- math.* Extensions
--
function math.round(num, idp)
   return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

--
-- table.* Extensions
--
table.shuffle = function(t)
	local n = #t;

	while n >= 2 do
		-- n is now the last pertinent index
		local k = mRand(n); -- 1 <= k <= n
		-- Quick swap
		t[n], t[k] = t[k], t[n];
		n = n - 1;
	end
	return t;
end


-- ==
--    table.combineUnique( ... ) - Combines n tables into a single table containing only unique members from each source table.
-- ==
function table.combineUnique( ... )
	local newTable = {}
	
	for i=1, #arg do
		for k,v in pairs( arg[i] ) do
			newTable[v] = v
		end
	end

	return newTable
end

-- ==
--    table.combineUnique_i( ... ) - Combines n tables into a single table containing only unique members from each source table.
-- ==
function table.combineUnique_i( ... )
	local newTable = {}
	local tmpTable = table.combineUnique( unpack(arg) )	
	local i = 1
	for k,v in pairs( tmpTable ) do
		newTable[i] = tmpTable[k]
		i = i + 1
	end
	return newTable
end

-- ==
--    table.shallowCopy( src [ , dst ]) - Copies single-level tables; handles non-integer indexes; does not copy metatable
-- ==
function table.shallowCopy( src, dst )
	local dst = dst or {}
	if( not src ) then return dst end
	for k,v in pairs(src) do 
		dst[k] = v
	end
	return dst
end

-- ==
--    table.deepCopy( src [ , dst ]) - Copies multi-level tables; handles non-integer indexes; does not copy metatable
-- ==
function table.deepCopy( src, dst )
	local dst = dst or {}
	for k,v in pairs(src) do 
		if( type(v) == "table" ) then
			dst[k] = table.deepCopy( v, nil )
		else
			dst[k] = v
		end		
	end
	return dst
end

-- ==
--    table.deepStripCopy( src [ , dst ]) - Copies multi-level tables, but strips out metatable(s) and ...
--
--    Fields with these value types: 
--       functions
--       userdata
--
--    Fields with these these names: 
--       _class
--       __index
--
--
--  This function is primarily meant to be used in preparation for serializing a table to a file.
--  Because you can't serialize a table with the above types and fields, they need to be removed first.
--  Of course, when you load the file back up, it will be up to  you to reattach the removed parts.
-- 
-- ==
function table.deepStripCopy( src, dst )
	local dst = dst or {}
	for k,v in pairs(src) do 
		local key = tostring(k)
		local value = tostring(v)
		local keyType = type(k)
		local valueType = type(v)

		if( valueType == "function" or 
		    valueType == "userdata" or 
			key == "_class"         or
			key == "__index"           ) then

			-- STRIP (SKIP IT)

		elseif( valueType == "table" ) then

			dst[k] = table.deepStripCopy( v, nil )

		else
			dst[k] = v
		end		
	end
	return dst
end

-- ==
--    table.save( theTable, fileName [, base ] ) - Saves table to file (Uses JSON library as intermediary)
-- ==
function table.save( theTable, fileName, base  )
	local base = base or  system.DocumentsDirectory
	local path = system.pathForFile( fileName, base )
	local fh = io.open( path, "w" )

	if(fh) then
		fh:write(json.encode( theTable ))
		io.close( fh )
		return true
	end	
	return false
end

-- ==
--    table.stripSave( theTable, fileName [, base ] ) - Saves table to file (Uses JSON library as intermediary)
-- ==
function table.stripSave( theTable, fileName, base )
	local base = base or  system.DocumentsDirectory
	local path = system.pathForFile( fileName, base )
	local fh = io.open( path, "w" )

	local tmpTable = table.deepStripCopy(theTable)

	if(fh) then
		fh:write(json.encode( tmpTable ))
		io.close( fh )
		return true
	end	
	return false
end

-- ==
--    table.load( fileName [, base ] ) - Loads table from file (Uses JSON library as intermediary)
-- ==
function table.load( fileName, base )
	local base = base or  system.DocumentsDirectory
	local path = system.pathForFile( fileName, base )
	if(path == nil) then return nil end
	local fh, reason = io.open( path, "r" )
	
	if fh then
		local contents = fh:read( "*a" )
		io.close( fh )
		local newTable = json.decode( contents )
		return newTable
	else
		return nil
	end
end


-- utility function for dumping out a table of data
table.dump = function(t, indent)
	local notindent = (indent == nil);
	if (notindent) then print('-----table-----'); indent='{}'; end
	if (t and type(t) == 'table') then
		for k, v in pairs(t) do
			if (type(k) ~= 'number') then
				print(indent .. '.' .. k .. ' = ' .. tostring(v))
				if (indent) then
					table.dump(v, indent..'.'..k);
				end
			end
		end
		for i=1, #t do
			print(indent .. '[' .. i .. '] = ' .. tostring(t[i]));
			table.dump(t[i], indent .. '[' .. i .. ']');
		end
	end
	if (notindent) then print('-----table-----'); end
end


-- ==
--    table.print_r( theTable ) - Dumps indexes and values inside multi-level table (for debug)
-- ==
local print = _G.print
table.print_r = function ( t ) 
	--local depth   = depth or math.huge
	local print_r_cache={}
	local function sub_print_r(t,indent)
		if (print_r_cache[tostring(t)]) then
			print(indent.."*"..tostring(t))
		else
			print_r_cache[tostring(t)]=true
			if (type(t)=="table") then
				for pos,val in pairs(t) do
					if (type(val)=="table") then
						print(indent.."["..pos.."] => "..tostring(t).." {")
						sub_print_r(val,indent..string.rep(" ",string.len(pos)+1))
						print(indent..string.rep(" ",string.len(pos)+1).."}")
					elseif (type(val)=="string") then
						print(indent.."["..pos..'] => "'..val..'"')
					else
						print(indent.."["..pos.."] => "..tostring(val))
					end
				end
			else
				print(indent..tostring(t))
			end			
		end
	end
	if (type(t)=="table") then
		print(tostring(t).." {")
		sub_print_r(t," ")
		print("}")
	else
		sub_print_r(t," ")
	end
end

-- ==
--    string:rpad( len, char ) - Places padding on right side of a string, such that the new string is at least len characters long.
-- ==
local print = _G.print
function string:rpad(len, char)
	local theStr = self
    if char == nil then char = ' ' end
    return theStr .. string.rep(char, len - #theStr)
end
function table.dump2(theTable, padding, marker ) -- Sorted
	marker = marker or ""
	local theTable = theTable or  {}
	local function compare(a,b)
	  return tostring(a) < tostring(b)
	end
	local tmp = {}
	for n in pairs(theTable) do table.insert(tmp, n) end
	table.sort(tmp,compare)

	local padding = padding or 30
	print("\Table Dump:")
	print("-----")
	if(#tmp > 0) then
		for i,n in ipairs(tmp) do 		

			local key = tmp[i]
			local keyType = type(key)
			local valueType = type(theTable[key])
			local value = tostring(theTable[key])
			local keyString = tostring(key) .. " (" .. keyType .. ")"
			local valueString = tostring(value) .. " (" .. valueType .. ")" 

			keyString = keyString:rpad(padding)
			valueString = valueString:rpad(padding)

			print( keyString .. " == " .. valueString ) 
		end
	else
		print("empty")
	end
	print( marker .. "-----\n")
end


-- ==
--    table.serialize(name, object, tabs) -
-- ==
table.serialize = function (name, object, tabs)
	local function serializeKeyForTable(k)
		if type(k)=="number" then
			return "[" .. k .. "]"; -- return /[1337]/ if number
		end
		if string.find(k,"[^A-z_-]") then --special symbols in it?
			return "[\"" .. k .. "\"]";
		end
		return k; -- /leet/ if string
	end

	local function serializeKey(k)
		if type(k)=="number" then
			return "\t[" .. k .."] = ";
		end
		if string.find(k,"[^A-z_-]") then
			return "\t[\"" .. k .. "\"] = ";
		end
		return "\t" .. k .. " = ";
	end

	if not tabs then tabs = ""; end

	local function serialize(name, object, tabs)
		local output = tabs .. name .. " = {" .. "\n";
		for k,v in pairs(object) do
			local valueType = type(v);
			if valueType == "string" then
				output = output .. tabs .. serializeKey(k) .. string.format("%q",v);
			elseif valueType == "table" then
				output = output .. serialize(serializeKeyForTable(k), v, tabs.."\t");
			elseif valueType == "number" then
				output = output .. tabs .. serializeKey(k) .. v;
			elseif valueType == "boolean" then
				output = output .. tabs .. serializeKey(k) .. tostring(v);
			else
				output = output .. tabs .. serializeKey(k) .. "\"" .. tostring(v) .. "\"";
			end
			if next(object,k) then
				output = output .. ",\n";
			end
		end
		return output .. "\n" .. tabs .. "}";
	end
	return serialize(name, object, tabs)  .. "\n" .. "return xmltable;";
end

--
-- storyboard.*
--
local storyboard        = require "storyboard"
local FRC_Layout        = require('FRC_Modules.FRC_Layout.FRC_Layout');

local cached_gotoScene  = storyboard.gotoScene;
local loader_scene      = storyboard.newScene('LoaderScene');
function loader_scene.createScene(self, event)
	local scene = self;
	local view = scene.view;

	local screenW, screenH = FRC_Layout.getScreenDimensions();
	local bg = display.newRect(view, 0, 0, screenW, screenH);
	bg.x = display.contentCenterX;
	bg.y = display.contentCenterY;
	bg:setFillColor(0, 0, 0, 1.0);
	view:insert(bg);
end
function loader_scene.enterScene(self, event)
	local scene = self;
	local view = scene.view;

	storyboard.purgeScene(event.params.nextScene);
	cached_gotoScene(event.params.nextScene, { effect=nil, time=0 });
end
loader_scene:addEventListener('createScene');
loader_scene:addEventListener('enterScene');
storyboard.gotoScene = function(sceneName, options)
	if (not options) then options = {}; end
	if (not options.params) then options.params = {}; end
	options.params.nextScene = sceneName;
	options.effect = nil;
	options.time = 0;

	if (options.useLoader) then
		cached_gotoScene('LoaderScene', options);
	else
		cached_gotoScene(sceneName, options);
	end
end

return public
