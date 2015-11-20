local FRC_Lobby_Settings = require('FRC_Modules.FRC_Lobby.FRC_Lobby_Settings');
local FRC_Lobby_Scene = require('FRC_Modules.FRC_Lobby.FRC_Lobby_Scene');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local json = require "json";
local FRC_Lobby = {};

local function DATA(key, baseDir)
	baseDir = baseDir or system.ResourceDirectory;
	return FRC_DataLib.readJSON(FRC_Lobby_Settings.DATA[key], baseDir);
end

function FRC_Lobby.newScene(settings)
	local settings = settings or {};

	for k1,v1 in pairs(settings) do
		for k2,v2 in pairs(FRC_Lobby_Settings) do
			for k3,v3 in pairs(FRC_Lobby_Settings[k2]) do
				if (k3 == k1) then
					FRC_Lobby_Settings[k2][k1] = v1;
					break;
				end
			end
		end
	end

	return FRC_Lobby_Scene;
end

return FRC_Lobby;
