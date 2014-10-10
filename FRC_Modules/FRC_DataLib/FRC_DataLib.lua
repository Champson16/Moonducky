local FRC_DataLib = {};
local json = require "json";

FRC_DataLib.readFile = function(filename, baseDirectory)
	baseDirectory = baseDirectory or system.ResourceDirectory;
	local path = system.pathForFile( filename, baseDirectory );
	if (not path) then return false; end
	local file = io.open(path, 'r');
	if (not file) then return false; end
	local data = file:read('*a');
	io.close( file );
	return data;
end

FRC_DataLib.saveFile = function(filename, saveData, baseDirectory)
	baseDirectory = baseDirectory or system.DocumentsDirectory;
	local path = system.pathForFile(filename, baseDirectory);
	if (not path) then return false; end
	local file = io.open(path, "w")
	if (not file) then return false; end
	file:write(saveData)
	io.close(file);
end

FRC_DataLib.readJSON = function(filename, baseDirectory)
	local data = FRC_DataLib.readFile(filename, baseDirectory);
	if (data) then
		return json.decode(data);
	else
		return false;
	end
end

FRC_DataLib.saveJSON = function(filename, tableData, baseDirectory)
	FRC_DataLib.saveFile(filename, json.encode(tableData), baseDirectory);
end

function FRC_DataLib.saveTable(t, filename)
	local path = system.pathForFile( filename, system.DocumentsDirectory)
	local file = io.open(path, "w")
	if file then
		local contents = json.encode(t)
		file:write( contents )
		io.close( file )
		return true
	else
		return false
	end
end

function FRC_DataLib.loadTable(filename, baseDirectory)
	if (not baseDirectory) then
		baseDirectory = system.DocumentsDirectory;
	end
	local path = system.pathForFile(filename, baseDirectory)
	local contents = ""
	local myTable = {}
	local file = io.open( path, "r" )
	if file then
		local contents = file:read( "*a" )
		myTable = json.decode(contents);
		io.close( file )
		return myTable
	end
	print(filename, "file not found")
	return nil
end

function FRC_DataLib.makeTimeStamp(dateString, mode)
    local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)([%+%-])(%d+)%:(%d+)"
    local xyear, xmonth, xday, xhour, xminute, xseconds, xoffset, xoffsethour, xoffsetmin
    local monthLookup = {Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12}
    local convertedTimestamp
    local offset = 0
    if mode and mode == "ctime" then
        pattern = "%w+%s+(%w+)%s+(%d+)%s+(%d+)%:(%d+)%:(%d+)%s+(.+)%s+(%d+)"
        local monthName, TZName
        monthName, xday, xhour, xminute, xseconds, TZName, xyear = dateString:match(pattern)
        xmonth = monthLookup[monthName]
        convertedTimestamp = os.time({year = xyear, month = xmonth,
        day = xday, hour = xhour, min = xminute, sec = xseconds})
    else
        xyear, xmonth, xday, xhour, xminute, xseconds, xoffset, xoffsethour, xoffsetmin = dateString:match(pattern)
        convertedTimestamp = os.time({year = xyear, month = xmonth,
        day = xday, hour = xhour, min = xminute, sec = xseconds})
        offset = xoffsethour * 60 + xoffsetmin
        if xoffset == "-" then offset = offset * -1 end
    end
    return convertedTimestamp + offset
end

return FRC_DataLib;
