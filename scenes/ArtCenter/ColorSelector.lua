local ui = require('modules.ui');
local data = require('modules.data');
local layout = require('modules.layout');

local DATA_PATH = 'assets/data/UX/FRC_UX_ArtCenter_Colors.json';
local BLANK_COLOR_PATH = 'assets/images/UX/FRC_UX_ArtCenter_Color_Blank.png';
local BUTTON_WIDTH = 64;
local BUTTON_HEIGHT = 64;
local BUTTON_PADDING = 16;

local ColorSelector = {};

local function onButtonPress(event)
	self = event.target;
	self._parent:changeColor(self.r, self.g, self.b);
end

local function changeColor(self, r, g, b)
	local tool = self._scene.selectedTool;
	tool.r = r;
	tool.g = g;
	tool.b = b;

	self._scene.currentColor.preview.up:setFillColor(r, g, b);
	self._scene.currentColor.preview.down:setFillColor(r, g, b);
	self._scene.currentColor.preview.r = r;
	self._scene.currentColor.preview.g = g;
	self._scene.currentColor.preview.b = b;
end

ColorSelector.new = function(scene, width, height)
	local group = ui.scrollContainer.new({
		width = width,
		height = height,
		xScroll = false,
		topPadding = BUTTON_PADDING,
		bottomPadding = BUTTON_PADDING,
		bgColor = { 0.14, 0.14, 0.14 },
		borderRadius = 11,
		borderWidth = 6,
		borderColor = { 0, 0, 0, 1.0 }
	});
	--group.bg.fill.effect = "filter.crosshatch";
	--group.bg.fill.effect.grain = 0.2;
	local colorData = data.readJSON(DATA_PATH).colors;

	--[[
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
	--]]

	for i=1,#colorData do
		local button = ui.button.new({
			id = i,
			imageUp = BLANK_COLOR_PATH,
			imageDown = BLANK_COLOR_PATH,
			width = BUTTON_WIDTH,
			height = BUTTON_HEIGHT
		});
		button._scene = scene;
		button.up:setFillColor(colorData[i].r, colorData[i].g, colorData[i].b);
		button.down:setFillColor(colorData[i].r, colorData[i].g, colorData[i].b, 0.75);
		button.anchorY = 0.5;
		button.x = 0;
		button.y = -(height * 0.5) + (button.height * 0.5) + BUTTON_PADDING + (i-1) * (BUTTON_HEIGHT + BUTTON_PADDING);

		-- color attributes
		button._parent = group;
		button.r = colorData[i].r;
		button.g = colorData[i].g;
		button.b = colorData[i].b;
		button:addEventListener('press', onButtonPress);
		group:insert(button);

		--[[
		local num = display.newText(i, 0, 0, native.systemFontBold, 12);
		num:setFillColor(0, 0, 0);
		num.anchorX = 0.5;
		num.anchorY = 0.5;
		num.x = button.x + (button.width * 0.5) + 10;
		num.y = button.y + (button.height * 0.5) - 2;
		group:insert(num);
		--]]
	end

	group._scene = scene;
	group.changeColor = changeColor;

	if (scene) then scene.view:insert(group); end
	return group;
end

return ColorSelector;