local FRC_DataLib = {};
local json = require "json";

FRC_DataLib.readFile = function(filename, baseDirectory)
	baseDirectory = baseDirectory or system.ResourceDirectory;
	local path = system.pathForFile( filename, baseDirectory );
	local file = io.open(path, 'r');
	if (not file) then return false; end
	local data = file:read('*a');
	io.close( file );
	return data;
end

FRC_DataLib.saveFile = function(filename, saveData, baseDirectory)
	baseDirectory = baseDirectory or system.DocumentsDirectory;
	local path = system.pathForFile(filename, baseDirectory);
	local file = io.open(path, "w");
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

return FRC_DataLib;