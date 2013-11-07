local BUTTON_WIDTH = 44;
local BUTTON_HEIGHT = 44;
local BUTTON_PADDING = 44;

local FRC_ArtCenter_BackgroundArtSelector = {};

FRC_ArtCenter_BackgroundArtSelector.new = function(scene, width, height)
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

return FRC_ArtCenter_BackgroundArtSelector;