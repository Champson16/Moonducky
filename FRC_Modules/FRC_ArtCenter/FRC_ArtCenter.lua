local FRC_ArtCenter_Settings = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Settings');
local FRC_ArtCenter_Scene = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Scene');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_ArtCenter = {};
math.randomseed(os.time());

-- used to generate a unique 20-digit internal identifier for each drawing (for saving/loading)
local generateUniqueIdentifier = function(digits)
	digits = digits or 20;
	local alphabet = { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z' };
	local s = '';
	for i=1,digits do
		if (i == 1) then
			s = s .. alphabet[math.random(1, #alphabet)];
		elseif (math.random(0,1) == 1) then
			s = s .. math.random(0, 9);
		else
			s = s .. alphabet[math.random(1, #alphabet)];
		end
	end
	return tostring(s);
end
FRC_ArtCenter.generateUniqueIdentifier = generateUniqueIdentifier;

local saveDataToFile = function()
	FRC_DataLib.saveJSON(FRC_ArtCenter_Settings.DATA.SAVED_DATAFILE, FRC_ArtCenter.savedData, system.DocumentsDirectory);
end
FRC_ArtCenter.saveDataToFile = saveDataToFile;

local getSavedData = function()
	FRC_ArtCenter.savedData = FRC_DataLib.readJSON(FRC_ArtCenter_Settings.DATA.SAVED_DATAFILE, system.DocumentsDirectory);
	if (not FRC_ArtCenter.savedData) then
		FRC_ArtCenter.savedData = { owner='FRC_ArtCenter', savedItems={} };
		saveDataToFile();
	end
end
FRC_ArtCenter.getSavedData = getSavedData;

local newScene = function(settings)
	local settings = settings or {};

	for k1,v1 in pairs(settings) do
		for k2,v2 in pairs(FRC_ArtCenter_Settings) do
			if (type(v2) == "table") then
				for k3,v3 in pairs(FRC_ArtCenter_Settings[k2]) do
					if (k3 == k1) then
						FRC_ArtCenter_Settings[k2][k1] = v1;
						break;
					end
				end
			end
		end
	end

	getSavedData();

	return FRC_ArtCenter_Scene;
end
FRC_ArtCenter.newScene = newScene;

FRC_ArtCenter.notifyMenuBars = function()
	require('FRC_Modules.FRC_ActionBar.FRC_ActionBar'):dispatchEvent({ name="unrelatedTouch" });
	require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar'):dispatchEvent({ name="unrelatedTouch" });
end

return FRC_ArtCenter;