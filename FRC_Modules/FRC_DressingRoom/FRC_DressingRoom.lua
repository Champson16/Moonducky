local FRC_DressingRoom_Settings = require('FRC_Modules.FRC_DressingRoom.FRC_DressingRoom_Settings');
local FRC_DressingRoom_Scene = require('FRC_Modules.FRC_DressingRoom.FRC_DressingRoom_Scene');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local json = require "json";
-- this is only needed if you want to call table.dump to inspect a table during debugging
local FRC_Util = require('FRC_Modules.FRC_Util.FRC_Util');
local FRC_DressingRoom = {};

local function DATA(key, baseDir)
	baseDir = baseDir or system.ResourceDirectory;
	return FRC_DataLib.readJSON(FRC_DressingRoom_Settings.DATA[key], baseDir);
end

local emptyDataFile = json.decode(FRC_DressingRoom_Settings.DATA.EMPTY_DATAFILE);
-- load saved data or save new data
local saveDataFilename = FRC_DressingRoom_Settings.DATA.DATA_FILENAME;

local saveDataToFile = function()
	FRC_DataLib.saveJSON(saveDataFilename, FRC_DressingRoom.saveData, system.DocumentsDirectory);
end
-- copy this function into FRC_DressingRoom
FRC_DressingRoom.saveDataToFile = saveDataToFile;

local getSavedData = function()
	FRC_DressingRoom.saveData = FRC_DataLib.readJSON(saveDataFilename, system.DocumentsDirectory);
	-- DEBUG
	print("FRC_DressingRoom.savedData loaded:");
	table.dump(FRC_DressingRoom.saveData);
	if (not FRC_DressingRoom.saveData) then
		-- DEBUG:
		print("FRC_DressingRoom - CREATING NEW SAVE FILE!")
		FRC_DressingRoom.saveData = emptyDataFile;
		FRC_DressingRoom.saveDataToFile();
	end
end
FRC_DressingRoom.getSavedData = getSavedData;

local newScene = function(settings)
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

	FRC_DressingRoom.getSavedData();

	return FRC_DressingRoom_Scene;
end
FRC_DressingRoom.newScene = newScene;

return FRC_DressingRoom;
