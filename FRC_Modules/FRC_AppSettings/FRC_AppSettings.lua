local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');

local FRC_AppSettings = {};
local currentSettingsPath = "FRC_Assets/FRC_AppSettings/Data/AppSettings.json";
local cachedSettingsPath = "Cached_AppSettings.json";
local settings = {};

local function splitStr(inputStr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputStr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

local function getGreaterVersion(v1, v2)
	local v1parts = splitStr(v1, ".");
	local v2parts = splitStr(v2, ".");
	local greater;

	if (#v1parts == 1) then
		v1parts[2], v1parts[3] = "0", "0";
	elseif (#v2 == 2) then
		v1parts[3] = "0";
	end

	if (#v2parts == 1) then
		v2parts[2], v2parts[3] = "0", "0";
	elseif (#v2parts == 2) then
		v2parts[3] = "0";
	end

	for i=1,3 do
		if (tonumber(v1parts[i]) > tonumber(v2parts[i])) then
			greater = v1;
			break;
		elseif (tonumber(v1parts[i]) < tonumber(v2parts[i])) then
			greater = v2;
			break;
		end
	end

	return greater;
end

local function extendTable(oldT, newT, preferNew)
	for k,v in pairs(oldT) do
		-- Never overwrite the version key
		if (k ~= "version") then
			if (not preferNew) then
				newT[k] = oldT[k];
			elseif (not newT[k]) then
				newT[k] = oldT[k];
			end
		end
	end
	return newT;
end

local function addNewKeys(oldT, newT)
	for k,v in pairs(newT) do
		if (oldT[k] == nil) then
			oldT[k] = newT[k];
		end
	end
	return oldT;
end

FRC_AppSettings.save = function()
	FRC_DataLib.saveTable(settings, cachedSettingsPath);
end

FRC_AppSettings.get = function(key)
	return settings[key];
end

FRC_AppSettings.set = function(key, value)
	settings[key] = value;
	FRC_AppSettings.save();
end

FRC_AppSettings.hasKey = function(key)
	if (settings[key] ~= nil) then
		return true;
	end
	return false;
end

FRC_AppSettings.init = function()
	local currentSettings = FRC_DataLib.loadTable(currentSettingsPath, system.ResourceDirectory);
	local loadedSettings = FRC_DataLib.loadTable(cachedSettingsPath);

	if ((not loadedSettings) or (not loadedSettings.version)) then
		settings = currentSettings;
		if (not settings.version) then
			settings.version = "0.0.1";
		end
		
	else
		-- If version number is greater than the settings that are saved to cache, overwrite
		if (getGreaterVersion(currentSettings.version, loadedSettings.version) == currentSettings.version) then
			settings = extendTable(loadedSettings, currentSettings);
		else
			settings = addNewKeys(loadedSettings, currentSettings);
		end
	end

	FRC_AppSettings.save();
end

return FRC_AppSettings;