local FRC_SetDesign_Settings = require('FRC_Modules.FRC_SetDesign.FRC_SetDesign_Settings');
local FRC_SetDesign_Scene = require('FRC_Modules.FRC_SetDesign.FRC_SetDesign_Scene');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local json = require('json');
local FRC_SetDesign = {};

local function DATA(key, baseDir)
	baseDir = baseDir or system.ResourceDirectory;
	return FRC_DataLib.readJSON(FRC_SetDesign_Settings.DATA[key], baseDir);
end

-- load saved data or save new data
local emptyDataFile = json.decode(FRC_SetDesign_Settings.DATA.EMPTY_DATAFILE);
local saveDataFilename = FRC_SetDesign_Settings.DATA.DATA_FILENAME;

FRC_SetDesign.saveData = FRC_DataLib.readJSON(saveDataFilename, system.DocumentsDirectory);
if (not FRC_SetDesign.saveData) then
	FRC_DataLib.saveJSON(saveDataFilename, emptyDataFile);
	FRC_SetDesign.saveData = emptyDataFile;
end

function FRC_SetDesign.newScene(settings)
	local settings = settings or {};

	for k1,v1 in pairs(settings) do
		for k2,v2 in pairs(FRC_SetDesign_Settings) do
			for k3,v3 in pairs(FRC_SetDesign_Settings[k2]) do
				if (k3 == k1) then
					FRC_SetDesign_Settings[k2][k1] = v1;
					break;
				end
			end
		end
	end

	return FRC_SetDesign_Scene;
end

return FRC_SetDesign;