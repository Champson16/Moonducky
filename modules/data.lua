local data = {};
local json = require "json";

data.readFile = function(filename, baseDirectory)
	local baseDirectory = baseDirectory or system.ResourceDirectory;
	local path = system.pathForFile( filename, baseDirectory );
	local file = io.open(path, 'r');
	local data = file:read('*a');
	io.close( file );
	return data;
end

data.readJSON = function(filename, baseDirectory)
	return json.decode(data.readFile(filename, baseDirectory));
end

return data;