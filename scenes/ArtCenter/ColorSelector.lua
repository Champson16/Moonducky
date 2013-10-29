local ui = require('modules.ui');
local data = require('modules.data');
local layout = require('modules.layout');

local DATA_PATH = 'assets/data/UX/FRC_UX_ArtCenter_Colors.json';
local BUTTON_WIDTH = 54;
local BUTTON_HEIGHT = 100;
local BUTTON_PADDING = 24;

local ColorSelector = {};

local function onButtonPress(event)
	local self = event.target;
	local tool = self._scene.selectedTool;

	tool.r = self.r;
	tool.g = self.g;
	tool.b = self.b;
end

ColorSelector.new = function(scene, width, height)
	local group = display.newGroup();

	local bg = display.newRoundedRect(0, 0, width, height, 4);
	bg.anchorX = 0;
	bg.anchorY = 0;
	bg:setFillColor(1.0, 1.0, 1.0);
	bg:setStrokeColor(0, 0, 0, 0.5);
	bg.strokeWidth = 6;
	group:insert(bg);

	local colorData = data.readJSON(DATA_PATH).colors;

	for i=1,#colorData do
		local button = ui.button.new({
			id = i,
			imageUp = 'assets/images/UX/FRC_UX_ArtCenter_Color_Blank.png',
			imageDown = 'assets/images/UX/FRC_UX_ArtCenter_Color_Blank.png',
			width = BUTTON_WIDTH,
			height = BUTTON_HEIGHT
		});
		button._scene = scene;
		button.up:setFillColor(colorData[i].r, colorData[i].g, colorData[i].b);
		button.down:setFillColor(colorData[i].r, colorData[i].g, colorData[i].b, 0.90);
		button.anchorX = 0;
		button.x = BUTTON_PADDING + (i - 1) * (BUTTON_WIDTH + BUTTON_PADDING);
		button.y = height * 0.5;

		-- color data
		button.r = colorData[i].r;
		button.g = colorData[i].g;
		button.b = colorData[i].b;
		button:addEventListener('press', onButtonPress);

		group:insert(button);
	end

	if (scene) then scene.view:insert(group); end
	return group;
end

return ColorSelector;