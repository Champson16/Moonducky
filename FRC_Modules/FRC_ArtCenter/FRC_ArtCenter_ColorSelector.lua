local FRC_ArtCenter_Settings = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Settings');
local ui = require('ui');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_ArtCenter_SubToolSelector = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_SubToolSelector');

local FRC_ArtCenter_ColorSelector = {}; 

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

-- Color from palette is selected
local function onButtonRelease(event)
	local self = event.target;
	local scene = self._scene;
	local showSelectedColor = true;
	local canvasColor = FRC_ArtCenter_Settings.UI.DEFAULT_CANVAS_COLOR

	if (scene.mode == scene.modes.ERASE) then
		scene.selectedTool.a = scene.selectedTool.old_a;
		scene.selectedTool.graphic.image = scene.selectedTool.old_image;
		scene.selectedTool.graphic.width = scene.selectedTool.old_width;
		scene.selectedTool.graphic.height = scene.selectedTool.old_height;
		scene.selectedTool.arbRotate = scene.selectedTool.old_arbRotate;
		FRC_ArtCenter_SubToolSelector.selection.isVisible = true;
		scene.mode = scene.modes.FREEHAND_DRAW;
		scene.eraserGroup.button:setFocusState(false);
		scene.canvas:setEraseMode(false);

	elseif (scene.mode == scene.modes.BACKGROUND_SELECTION) then
		scene.canvas:fillBackground(self.r, self.g, self.b);
		showSelectedColor = true;
		scene.canvas.isDirty = true;
	
	elseif ((scene.mode == scene.modes.SHAPE_PLACEMENT) or (scene.mode == scene.modes.STAMP_PLACEMENT)) then

		local shapeSubTool;

		-- ensure all shape sub-tools reflect currently selected color/texture
		for i=1,#scene.subToolSelectors do
			if (scene.subToolSelectors[i].colorSubTools) then
				for j=1,scene.subToolSelectors[i].content.numChildren do
					if (scene.subToolSelectors[i].content[j].parentId) then
						local obj = scene.subToolSelectors[i].content[j];
						obj:setFill({ type="image", filename=scene.currentColor.texturePreview._imagePath });
						obj:setFillColor(self.r, self.g, self.b, 1.0);

						if ((self.r == canvasColor) and (self.g == canvasColor) and (self.b == canvasColor)) then
							if (scene.currentColor.texturePreview.id == "Blank") then
								obj:setFillColor(self.r, self.g, self.b, 0);

							else
								if (scene.mode == scene.modes.SHAPE_PLACEMENT) then
									obj:setFillColor(self.r, self.g, self.b, 1.0);
								else
									obj:setFillColor(1.0, 1.0, 1.0, 1.0);
								end
							end
						end
						obj:setStrokeColor(0, 0, 0, 1.0);
						obj:setStrokeWidth(5);
					end
				end
			end
		end

		-- change color for shape or stamp
		if ((scene.objectSelection) and (scene.objectSelection.selectedObject)) then
			local obj = scene.objectSelection.selectedObject[1];
			if (scene.mode == scene.modes.SHAPE_PLACEMENT) then
				obj.fill = { type="image", filename=scene.currentColor.texturePreview._imagePath };
				obj.parent.fillImage = scene.currentColor.texturePreview._imagePath;
			end
			obj:setFillColor(self.r, self.g, self.b, 1.0);
			obj.parent.fillColor = { self.r, self.g, self.b, 1.0 };

			if ((self.r == canvasColor) and (self.g == canvasColor) and (self.b == canvasColor)) then
				if ((scene.mode == scene.modes.SHAPE_PLACEMENT) and (scene.currentColor.texturePreview.id == "Blank")) then
					obj:setFillColor(self.r, self.g, self.b, 0);
					obj:setStrokeColor(0, 0, 0, 1.0);
					obj.strokeWidth = 5;

					obj.parent.fillColor = { self.r, self.g, self.b, 0 };
					obj.parent.strokeColor = { 0, 0, 0, 1.0 };
					obj.parent.strokeWidth = 5;

				else
					if (scene.mode == scene.modes.SHAPE_PLACEMENT) then
						obj:setFillColor(self.r, self.g, self.b, 1.0);
						obj.parent.fillColor = { self.r, self.g, self.b, 1.0 };
					else
						obj:setFillColor(1.0, 1.0, 1.0, 1.0);
						obj.parent.fillColor = { 1.0, 1.0, 1.0, 1.0 };
					end
				end
			elseif (scene.mode == scene.modes.SHAPE_PLACEMENT) then
				obj.strokeWidth = 0;
				obj.parent.strokeWidth = 0;
			end
		end
		showSelectedColor = true;
		scene.canvas.isDirty = true;
	end

	if (showSelectedColor) then
		self._parent:changeColor(self.r, self.g, self.b);
		self:setFocusState(true);
		for i=1,self.parent.numChildren do
			if (self.parent[i] ~= self) then
				self.parent[i]:setFocusState(false);
			end
		end

		-- change color of texture selector to reflect currently selected color
		for i=1,scene.textureSelector.content.numChildren do
			if (not scene.textureSelector.content[i].disableTint) then
				if ((self.r == canvasColor) and (self.g == canvasColor) and (self.b == canvasColor)) then
					scene.textureSelector.content[i]:setFillColor(1.0, 1.0, 1.0, 1.0);
				else
					scene.textureSelector.content[i]:setFillColor(self.r, self.g, self.b);
				end
			else
				scene.textureSelector.content[i]:setFillColor(1.0, 1.0, 1.0, 1.0);
			end
		end
	end
end

local function changeColor(self, r, g, b)
	local canvasColor = FRC_ArtCenter_Settings.UI.DEFAULT_CANVAS_COLOR;
	local tool = self._scene.selectedTool;
	tool.r = r;
	tool.g = g;
	tool.b = b;

	self._scene.currentColor.preview.up:setFillColor(r, g, b);
	self._scene.currentColor.preview.down:setFillColor(r, g, b);
	self._scene.currentColor.preview.r = r;
	self._scene.currentColor.preview.g = g;
	self._scene.currentColor.preview.b = b;

	if ((r == canvasColor) and (g == canvasColor) and (b == canvasColor)) then
		self._scene.currentColor.texturePreview:setFillColor(1.0, 1.0, 1.0, 1.0);
	else
		self._scene.currentColor.texturePreview:setFillColor(r, g, b, 0.25);
	end
end

local function noColorVisible(self, visible)
	if ((visible) and (self.content[1].isVisible == false)) then
		self.content[1].isVisible = true;

		for i=2,self.content.numChildren do
			self.content[i].y = self.content[i].y + self.shiftDistance;
		end
	elseif ((not visible) and (self.content[1].isVisible)) then
		self.content[1].isVisible = false;

		for i=2,self.content.numChildren do
			self.content[i].y = self.content[i].y - self.shiftDistance;
		end
	end
end

FRC_ArtCenter_ColorSelector.new = function(scene, width, height)
	local BUTTON_WIDTH = FRC_ArtCenter_Settings.UI.COLOR_WIDTH;
	local BUTTON_HEIGHT = FRC_ArtCenter_Settings.UI.COLOR_HEIGHT;
	local BUTTON_PADDING = FRC_ArtCenter_Settings.UI.COLOR_PADDING;

	local canvasColor = FRC_ArtCenter_Settings.UI.DEFAULT_CANVAS_COLOR
	local group = ui.scrollContainer.new({
		width = width,
		height = height,
		xScroll = false,
		topPadding = BUTTON_PADDING,
		bottomPadding = BUTTON_PADDING,
		bgColor = { 1.0, 1.0, 1.0, 0.75 },
		borderRadius = 11,
		borderWidth = 0,
		borderColor = { 0, 0, 0, 1.0 }
	});
	local colorData = FRC_DataLib.readJSON(FRC_ArtCenter_Settings.DATA.COLORS).colors;
	local colors = {};

	for i=1,#colorData do
		colors[#colors+1] = HexToRGB(colorData[i]);
	end
	colors = sortByHue(colors);

	for i=1,#colors do
		local c = colors[i];
		local button = ui.button.new({
			id = i,
			imageUp = FRC_ArtCenter_Settings.UI.BLANK_COLOR,
			imageDown = FRC_ArtCenter_Settings.UI.BLANK_COLOR,
			focusState = FRC_ArtCenter_Settings.UI.BLANK_COLOR_FOCUSED,
			width = BUTTON_WIDTH,
			height = BUTTON_HEIGHT,
			parentScrollContainer = group
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
				imageUp = FRC_ArtCenter_Settings.UI.NOCOLOR_COLOR,
				imageDown = FRC_ArtCenter_Settings.UI.NOCOLOR_COLOR,
				focusState = FRC_ArtCenter_Settings.UI.BLANK_COLOR_FOCUSED,
				width = BUTTON_WIDTH,
				height = BUTTON_HEIGHT,
				onPress = function()
					require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter').notifyMenuBars();
				end
			});
			noColor._scene = scene;
			noColor.down:setFillColor(1.0, 1.0, 1.0, 0.75);
			noColor.anchorY = 0.5;
			noColor.x = 0;
			noColor.y = -(height * 0.5) + (noColor.height * 0.5) + BUTTON_PADDING + (i-1) * (BUTTON_HEIGHT + BUTTON_PADDING);
			noColor.isVisible = false;

			noColor._parent = group;
			noColor.r = canvasColor;
			noColor.g = canvasColor;
			noColor.b = canvasColor;
			noColor:addEventListener('release', onButtonRelease);
			group:insert(noColor);
			button:setFocusState(true);
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

return FRC_ArtCenter_ColorSelector;
