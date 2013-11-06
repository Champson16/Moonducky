local ui = require('modules.ui');
local data = require('modules.data');
local layout = require('modules.layout');

local DATA_PATH = 'assets/data/UX/FRC_UX_ArtCenter_Tools_global_UI.json';
local BUTTON_WIDTH = 44;
local BUTTON_HEIGHT = 44;
local BUTTON_PADDING = 44;

local BackgroundArtSelector = {};

BackgroundArtSelector.new = function(scene, width, height)
	local group = display.newGroup();

	local bg = display.newRoundedRect(0, 0, width, height, 4);
	bg.anchorX = 0;
	bg.anchorY = 0;
	bg:setFillColor(1.0, 1.0, 1.0);
	bg:setStrokeColor(0, 0, 0, 0.5);
	bg.strokeWidth = 6;
	group:insert(bg);

	if (scene) then scene.view:insert(group); end
	return group;
end

return BackgroundArtSelector;