local FRC_DataLib = {};
local json = require "json";

FRC_DataLib.readFile = function(filename, baseDirectory)
	local baseDirectory = baseDirectory or system.ResourceDirectory;
	local path = system.pathForFile( filename, baseDirectory );
	local file = io.open(path, 'r');
	local data = file:read('*a');
	io.close( file );
	return data;
end

FRC_DataLib.readJSON = function(filename, baseDirectory)
	return json.decode(FRC_DataLib.readFile(filename, baseDirectory));
end

return FRC_DataLib;