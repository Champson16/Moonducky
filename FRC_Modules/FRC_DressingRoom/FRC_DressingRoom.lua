local FRC_DressingRoom_Settings = require('FRC_Modules.FRC_DressingRoom.FRC_DressingRoom_Settings');
local FRC_DressingRoom_Scene = require('FRC_Modules.FRC_DressingRoom.FRC_DressingRoom_Scene');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local json = require "json";
local FRC_DressingRoom = {};

local function DATA(key, baseDir)
	baseDir = baseDir or system.ResourceDirectory;
	return FRC_DataLib.readJSON(FRC_DressingRoom_Settings.DATA[key], baseDir);
end

-- load saved data or save new data
local emptyDataFile = json.decode(FRC_DressingRoom_Settings.DATA.EMPTY_DATAFILE);
local saveDataFilename = FRC_DressingRoom_Settings.DATA.DATA_FILENAME;

local saveDataToFile = function()
	FRC_DataLib.saveJSON(saveDataFilename, FRC_DressingRoom.savedData, system.DocumentsDirectory);
end
FRC_DressingRoom.saveDataToFile = saveDataToFile;

local getSavedData = function()
	FRC_DressingRoom.savedData = FRC_DataLib.readJSON(saveDataFilename, system.DocumentsDirectory);
	if (not FRC_DressingRoom.savedData) then
		FRC_DressingRoom.savedData = emptyDataFile;
		saveDataToFile();
	end
end
FRC_DressingRoom.getSavedData = getSavedData;

function FRC_DressingRoom.newScene(settings)
	local settings = settings or {};

	for k1,v1 in pairs(settings) do
		for k2,v2 in pairs(FRC_DressingRoom_Settings) do
			for k3,v3 in pairs(FRC_DressingRoom_Settings[k2]) do
				if (k3 == k1) then
					FRC_DressingRoom_Settings[k2][k1] = v1;
					break;
				end
			end
		end
	end

	return FRC_DressingRoom_Scene;
end

return FRC_DressingRoom;
