local ui = require('modules.ui');
local data = require('modules.data');
local layout = require('modules.layout');

local DATA_PATH = 'assets/data/UX/FRC_UX_ArtCenter_Colors.json';
local NO_COLOR_PATH = 'assets/images/UX/FRC_UX_ArtCenter_Color_NoColor.png';
local BLANK_COLOR_PATH = 'assets/images/UX/FRC_UX_ArtCenter_Color_Blank.png';
local BUTTON_WIDTH = 64;
local BUTTON_HEIGHT = 64;
local BUTTON_PADDING = 16;

local ColorSelector = {};

local function HexToRGB(color)
	local newcolor = {
		r = tonumber((string.sub(color,1,2)),16)/255,
		g = tonumber((string.sub(color,3,4)),16)/255,
		b = tonumber((string.sub(color,5,6)),16)/255,
		hex = color
	};
	return newcolor;
end

local function sortByHue(colors)
	for i=1,#colors do
		local r, g, b = colors[i].r, colors[i].g, colors[i].b;

		-- Get max and min values for chroma
		local max = math.max(r, g, b);
		local min = math.min(r, g, b);

		-- Variables for HSV value of hex color
		local chr = max - min;
		local hue = 0;
		local val = max;
		local sat = 0;

		if (val > 0) then
			-- Calculate saturation only if value isn't 0
			sat = chr / val;
			if (sat > 0) then
				if (r == max) then
					hue = 60 * (((g-min) - (b-min)) / chr);
					if (hue < 0) then hue = hue + 360; end
				elseif (g == max) then
					hue = 120 + 60 * (((b-min) - (r-min)) / chr);
				elseif (b == max) then
					hue = 240 + 60 * (((r-min) - (g-min)) / chr);
				end
			end
		end

		-- modify existing object by adding HSV values
		colors[i].hue = hue;
		colors[i].sat = sat;
		colors[i].val = val;
	end

	table.sort(colors, function(a, b) return a.hue < b.hue; end);
	return colors;
end

local function onButtonRelease(event)
	local self = event.target;
	local scene = self._scene;
	local showSelectedColor = true;

	if (scene.eraserSelected) then
		scene.selectedTool.a = scene.selectedTool.old_a;
		scene.selectedTool.graphic.image = scene.selectedTool.old_image;
		scene.selectedTool.graphic.width = scene.selectedTool.old_width;
		scene.selectedTool.graphic.height = scene.selectedTool.old_height;
		scene.selectedTool.arbRotate = scene.selectedTool.old_arbRotate;
		scene.eraserSelected = false;
		require('scenes.ArtCenter.SubToolSelector').selection.isVisible = true;

	elseif (scene.backgroundSelectionMode) then
		scene.canvas:fillBackground(self.r, self.g, self.b);
		showSelectedColor = false;
	end

	if (showSelectedColor) then
		self._parent:changeColor(self.r, self.g, self.b);
	end
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

local function noColorVisible(self, visible)
	if ((visible) and (self.content[1].isVisible == false)) then
		self.content[1].isVisible = true;

		for i=2,self.content.numChildren do
			self.content[i].y = self.content[i].y + self.shiftDistance;
		end
	elseif (self.content[1].isVisible) then
		self.content[1].isVisible = false;

		for i=2,self.content.numChildren do
			self.content[i].y = self.content[i].y - self.shiftDistance;
		end
	end
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
	local colors = {};

	for i=1,#colorData do
		colors[#colors+1] = HexToRGB(colorData[i]);
	end
	colors = sortByHue(colors);

	for i=1,#colors do
		local c = colors[i];
		local button = ui.button.new({
			id = i,
			imageUp = BLANK_COLOR_PATH,
			imageDown = BLANK_COLOR_PATH,
			width = BUTTON_WIDTH,
			height = BUTTON_HEIGHT
		});
		button._scene = scene;
		button.up:setFillColor(c.r, c.g, c.b);
		button.down:setFillColor(c.r, c.g, c.b, 0.75);
		button.anchorY = 0.5;
		button.x = 0;
		button.y = -(height * 0.5) + (button.height * 0.5) + BUTTON_PADDING + (i-1) * (BUTTON_HEIGHT + BUTTON_PADDING);

		if (i == 1) then
			local noColor = ui.button.new({
				id = i,
				imageUp = NO_COLOR_PATH,
				imageDown = NO_COLOR_PATH,
				width = BUTTON_WIDTH,
				height = BUTTON_HEIGHT
			});
			noColor._scene = scene;
			noColor.down:setFillColor(1.0, 1.0, 1.0, 0.75);
			noColor.anchorY = 0.5;
			noColor.x = 0;
			noColor.y = -(height * 0.5) + (noColor.height * 0.5) + BUTTON_PADDING + (i-1) * (BUTTON_HEIGHT + BUTTON_PADDING);
			noColor.isVisible = false;

			noColor._parent = group;
			noColor.r = .956862745;
			noColor.g = .956862745;
			noColor.b = .956862745;
			noColor:addEventListener('release', onButtonRelease);
			group:insert(noColor);
		end

		-- color attributes
		button._parent = group;
		button.r = c.r;
		button.g = c.g;
		button.b = c.b;
		button:addEventListener('release', onButtonRelease);
		group:insert(button);
	end

	group._scene = scene;
	group.shiftDistance = group.content[3].y - group.content[2].y;
	group.changeColor = changeColor;
	group.noColorVisible = noColorVisible;
	group:noColorVisible(true);

	if (scene) then scene.view:insert(group); end
	return group;
end

return ColorSelector;