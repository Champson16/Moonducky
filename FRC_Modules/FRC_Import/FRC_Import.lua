local version = "1.0.0";
local configPath = "FRC_Assets/FRC_Import/Data/FRC_Import_ModulePaths.json";

local json = require("json");
local path = system.pathForFile(configPath, system.ResourceDirectory);
local file = io.open(path, 'r');
local importPaths;
if (file) then
	importPaths = json.decode(file:read('*a'));
	io.close(file);
else
	importPaths = {};
end

_G.import = function(moduleName)
	if (importPaths[moduleName]) then
		return require(importPaths[moduleName]);
	else
		return require(moduleName);
	end
end

_G.importPath = function(moduleName, modulePath)
	importPaths[moduleName] = modulePath;
end
