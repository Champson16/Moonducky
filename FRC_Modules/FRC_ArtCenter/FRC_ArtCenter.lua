local FRC_ArtCenter_Settings = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Settings');
local FRC_ArtCenter_Scene = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Scene');
local FRC_ArtCenter = {};

local function newScene(settings)
	local settings = settings or {};

	for k1,v1 in pairs(settings) do
		for k2,v2 in pairs(FRC_ArtCenter_Settings) do
			for k3,v3 in pairs(FRC_ArtCenter_Settings[k2]) do
				if (k3 == k1) then
					FRC_ArtCenter_Settings[k2][k1] = v1;
					break;
				end
			end
		end
	end

	return FRC_ArtCenter_Scene;
end
FRC_ArtCenter.newScene = newScene;

FRC_ArtCenter.notifyMenuBars = function()
	require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar'):dispatchEvent({ name="unrelatedTouch" });
	require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar'):dispatchEvent({ name="unrelatedTouch" });
end

return FRC_ArtCenter;