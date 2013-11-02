local ui = require('modules.ui');
local data = require('modules.data');
local layout = require('modules.layout');
local screenW, screenH = layout.getScreenDimensions();

local DATA_PATH = 'assets/data/UX/FRC_UX_ArtCenter_Tools_global_UI.json';
local BUTTON_WIDTH = 50;
local BUTTON_HEIGHT = 50;
local BUTTON_PADDING = 44;

local SubToolSelector = {};
SubToolSelector.selection = display.newImageRect('assets/images/selected.png', 48, 48);
SubToolSelector.selection.isVisible = false;

local function onBackgroundButtonRelease(event)
	local self = event.target;

	self._scene.eraserSelected = false;
	self._scene.selectedTool = require('scenes.ArtCenter.Tools.' .. self.toolModule);
	local bgImageLayer = self._scene.canvas.layerBgImage;
	local imageFile = 'assets/images/UX/MDSS_UX_ArtCenter_Backdrop_' .. self.id .. '.png'

	if (bgImageLayer.group.numChildren > 0) then
		bgImageLayer.group[1]:removeSelf();
		bgImageLayer.group[1] = nil;
	end

	local image = display.newImageRect(bgImageLayer.group, imageFile, 1152, 768);
	local x = self._scene.canvas.width / image.contentWidth;
	local y = self._scene.canvas.height / image.contentHeight;

	if (x > y) then
		image.yScale = x;
	else
		image.xScale = y;
		image.yScale = y;
	end
	bgImageLayer:invalidate();
end

local function onFreehandButtonRelease(event)
	local self = event.target;

	self._scene.eraserSelected = false;
	self._scene.selectedTool = require('scenes.ArtCenter.Tools.' .. self.toolModule);
	local tool = self._scene.selectedTool;
	tool.graphic.image = 'assets/images/UX/FRC_UX_ArtCenter_' .. self.parentId .. '_Brush_' .. self.id .. '.png';
	tool.graphic.width = self.brushSizes[1];
	tool.graphic.height = self.brushSizes[1];
	tool.a = self.brushAlpha;
	tool.arbRotate = self.arbRotate;
	self.parent:insert(SubToolSelector.selection);
	SubToolSelector.selection.isVisible = true;
	SubToolSelector.selection.x = self.x;
	SubToolSelector.selection.y = self.y;

	-- set color for tool to match currently selected color (in case eraser was previously selected)
	self._scene.colorSelector:changeColor(self._scene.currentColor.preview.r, self._scene.currentColor.preview.g, self._scene.currentColor.preview.b);
end

SubToolSelector.new = function(scene, id, width, height)
	local group = ui.scrollContainer.new({
		width = width,
		height = height,
		xScroll = false,
		topPadding = 16,
		bottomPadding = 16,
		bgColor = { 0.14, 0.14, 0.14 },
		borderRadius = 11,
		borderWidth = 6,
		borderColor = { 0, 0, 0, 1.0 }
	});
	--group.bg.fill.effect = "filter.crosshatch";
	--group.bg.fill.effect.grain = 0.2;

	local toolData = data.readJSON(DATA_PATH);
	local toolButtons = toolData.tools;
	local toolData, subToolButtons;

	for i=1,#toolButtons do
		if (toolButtons[i].id == id) then
			toolData = toolButtons[i];
			subToolButtons = toolButtons[i].subtools;
			break;
		end
	end
	if (not subToolButtons) then return; end

	for i=1,#subToolButtons do
		local image, onButtonRelease, btnWidth, btnHeight, btnBgColor;

		if (toolData.module == "BackgroundImage") then
			image = 'assets/images/UX/MDSS_UX_ArtCenter_Backdrop_' .. subToolButtons[i].id .. '.png';
			onButtonRelease = onBackgroundButtonRelease;
			btnWidth = 100;
			btnHeight = 66;
			btnBgColor = { 1.0, 1.0, 1.0, 1.0 };

		elseif (toolData.module == "FreehandDraw") then
			image = 'assets/images/UX/FRC_UX_ArtCenter_' .. id .. '_Brush_' .. subToolButtons[i].id .. '.png';
			onButtonRelease = onFreehandButtonRelease;
			btnWidth = BUTTON_WIDTH;
			btnHeight = BUTTON_HEIGHT;
		end

		local button = ui.button.new({
			id = subToolButtons[i].id,
			imageUp = image,
			imageDown = image,
			width = btnWidth,
			height = btnHeight,
			pressAlpha = 0.5,
			bgColor = btnBgColor
		});
		button:addEventListener('release', onButtonRelease);
		button._scene = scene;
		button.anchorY = 0.5;
		button.x = -6;
		button.y = -(height * 0.5) + (button.height * 0.5) + 16 + (i-1) * (BUTTON_HEIGHT + BUTTON_PADDING);

		-- brush attributes
		button.parentId = id;
		button.toolModule = toolData.module;
		button.arbRotate = subToolButtons[i].arbRotate or false;
		button.brushAlpha = subToolButtons[i].alpha or 1.0;
		button.brushSizes = subToolButtons[i].brushSizes or {};
		group:insert(button);

		local num = display.newText(i, 0, 0, native.systemFontBold, 12);
		num:setFillColor(1.0, 1.0, 1.0);
		num.anchorX = 0.5;
		num.anchorY = 0.5;
		num.x = button.x + (button.width * 0.5) + 8;
		num.y = button.y + (button.height * 0.5) - 2;
		group:insert(num);
	end

	group.parentId = id;
	if (scene) then scene.view:insert(group); end
	return group;
end

-- UDID: a085af91cce7c43021294b6f83e22faeecf5427e

return SubToolSelector;