local ui = require('modules.ui');
local data = require('modules.data');
local layout = require('modules.layout');
local screenW, screenH = layout.getScreenDimensions();

local DATA_PATH = 'assets/data/UX/FRC_UX_ArtCenter_Tools_global_UI.json';
local BUTTON_WIDTH = 50;
local BUTTON_HEIGHT = 50;
local BUTTON_PADDING = 44;

local SubToolSelector = {};
SubToolSelector.selection = display.newImageRect('assets/images/selected.png', 86, 86);
SubToolSelector.selection.isVisible = false;
SubToolSelector.selection.isActive = false;
SubToolSelector.selection.alpha = 0.80;

local function selectObject(scene, obj)
	local canvas = scene.canvas;

	-- create object selection polygon
	if (scene.objectSelection) then scene.objectSelection:removeSelf(); end
	local padding = 5;
	scene.objectSelection = display.newPolygon(canvas.layerSelection, obj.x, obj.y, { -obj.contentWidth*0.5-padding,-obj.contentHeight*0.5-padding, obj.contentWidth*0.5+padding,-obj.contentHeight*0.5-padding, obj.contentWidth*0.5+padding,obj.contentHeight*0.5+padding, -obj.contentWidth*0.5-padding,obj.contentHeight*0.5+padding });
	scene.objectSelection:setStrokeColor(scene.selectedTool.SELECTION_COLOR[1], scene.selectedTool.SELECTION_COLOR[2], scene.selectedTool.SELECTION_COLOR[3]);
	scene.objectSelection.strokeWidth = 3;
	scene.objectSelection:setFillColor(1.0, 1.0, 1.0, 0);
	scene.objectSelection.selectedObject = obj;
end

local function onBackgroundButtonRelease(event)
	local self = event.target;
	local scene = self._scene;

	scene.selectedTool = require('scenes.ArtCenter.Tools.' .. self.toolModule);
	scene.mode = scene.modes[self.toolMode];

	local bgImageLayer = scene.canvas.layerBgImage;
	local imageFile = 'assets/images/UX/MDSS_UX_ArtCenter_Backdrop_' .. self.id .. '.png'

	if (bgImageLayer.group.numChildren > 0) then
		bgImageLayer.group[1]:removeSelf();
		bgImageLayer.group[1] = nil;
	end

	local image = display.newImageRect(bgImageLayer.group, imageFile, 1152, 768);
	local x = scene.canvas.width / image.contentWidth;
	local y = scene.canvas.height / image.contentHeight;

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
	local scene = self._scene;

	scene.selectedTool = require('scenes.ArtCenter.Tools.' .. self.toolModule);
	scene.mode = scene.modes[self.toolMode];

	local tool = scene.selectedTool;
	tool.graphic.image = 'assets/images/UX/FRC_UX_ArtCenter_' .. self.parentId .. '_Brush_' .. self.id .. '.png';
	tool.graphic.width = self.brushSizes[1];
	tool.graphic.height = self.brushSizes[1];
	tool.a = self.brushAlpha;
	tool.arbRotate = self.arbRotate;

	scene.freehandImage = tool.graphic.image;
	scene.freehandWidth = tool.graphic.width;
	scene.freehandHeight = tool.graphic.height;
	scene.freehandAlpha = tool.a;
	scene.freehandArbRotate = tool.arbRotate;

	self.parent:insert(SubToolSelector.selection);
	SubToolSelector.selection.isVisible = true;
	SubToolSelector.selection.x = self.x;
	SubToolSelector.selection.y = self.y;
	SubToolSelector.selection.isActive = true;

	-- set color for tool to match currently selected color (in case eraser was previously selected)
	scene.colorSelector:changeColor(scene.currentColor.preview.r, scene.currentColor.preview.g, scene.currentColor.preview.b);
end

local function onShapeButtonRelease(event)
	local self = event.target;
	local scene = self._scene;
	local canvas = scene.canvas;

	scene.selectedTool = require('scenes.ArtCenter.Tools.' .. self.toolModule);
	scene.mode = scene.modes[self.toolMode];

	local tool = scene.selectedTool;

	local size = 100;
	local vertices = {};
	for i=1,#self.vertices do
		table.insert(vertices, size * self.vertices[i]);
	end

	-- place shape on canvas
	local shapeGroup = display.newGroup();
	local shape;
	if (#vertices > 1) then
		shape = display.newPolygon(shapeGroup, 0, 0, vertices);
	else
		shape = display.newCircle(shapeGroup, 0, 0, size);
	end
	shape:setFillColor(scene.currentColor.preview.r, scene.currentColor.preview.g, scene.currentColor.preview.b, 1.0);
	shape.isHitTestable = true;
	shapeGroup.toolMode = self.toolMode;
	shapeGroup.isHitTestable = true;
	shapeGroup:addEventListener('multitouch', tool.onShapePinch);
	canvas.layerObjects:insert(shapeGroup);

	if ((scene.currentColor.preview.r == scene.DEFAULT_CANVAS_COLOR) and (scene.currentColor.preview.g == scene.DEFAULT_CANVAS_COLOR) and (scene.currentColor.preview.b == scene.DEFAULT_CANVAS_COLOR)) then
		shape:setStrokeColor(0, 0, 0, 1.0);
		shape.strokeWidth = 5;
	else
		shape.strokeWidth = 0;
	end

	shapeGroup._scene = scene;
	selectObject(scene, shapeGroup);
end

local function onStampButtonRelease(event)
	local self = event.target;
	local scene = self._scene;
	local canvas = scene.canvas;

	scene.selectedTool = require('scenes.ArtCenter.Tools.' .. self.toolModule);

	local tool = scene.selectedTool;

	local image = 'assets/images/UX/FRC_UX_ArtCenter_Stamp_' .. self.id .. '.png';
	local size = 150;

	-- place stamp on canvas
	local stampGroup = display.newGroup();
	local stamp = display.newImage(stampGroup, image);
	local scaleX = size / stamp.width;
	local scaleY = size / stamp.height;

	if (scaleX > scaleY) then
		stamp.xScale = scaleX;
		stamp.yScale = scaleX;
	else
		stamp.xScale = scaleY;
		stamp.yScale = scaleY;
	end

	stampGroup.toolMode = self.toolMode;
	stampGroup:addEventListener('multitouch', tool.onStampPinch);
	canvas.layerObjects:insert(stampGroup);

	stampGroup._scene = scene;
	selectObject(scene, stampGroup);
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

	local yPos = -(height * 0.5);

	for i=1,#subToolButtons do
		local image, shape, onButtonRelease, btnWidth, btnHeight, btnPadding, btnBgColor;

		btnPadding = BUTTON_PADDING;

		if (toolData.module == "BackgroundImage") then
			image = 'assets/images/UX/MDSS_UX_ArtCenter_Backdrop_' .. subToolButtons[i].id .. '.png';
			onButtonRelease = onBackgroundButtonRelease;
			btnWidth = 80;
			btnHeight = 53;
			btnBgColor = { 1.0, 1.0, 1.0, 1.0 };

		elseif (toolData.module == "FreehandDraw") then
			if (not subToolButtons[i].icon) then
				image = 'assets/images/UX/FRC_UX_ArtCenter_' .. id .. '_Brush_' .. subToolButtons[i].id .. '.png';
				btnWidth = BUTTON_WIDTH;
				btnHeight = BUTTON_HEIGHT;
			else
				image = 'assets/images/UX/FRC_UX_ArtCenter_' .. id .. '_Icon_' .. subToolButtons[i].id .. '.png';
				btnWidth = 80;
				btnHeight = 80;
			end

			onButtonRelease = onFreehandButtonRelease;

		elseif (toolData.module == "ShapePlacement") then
			image = nil;
			shape = subToolButtons[i].vertices;
			onButtonRelease = onShapeButtonRelease;
			btnWidth = 80;
			btnHeight = 80;
			btnPadding = BUTTON_PADDING + 16;

		elseif (toolData.module == "StampPlacement") then
			image = 'assets/images/UX/FRC_UX_ArtCenter_Stamp_' .. subToolButtons[i].id .. '.png';
			onButtonRelease = onStampButtonRelease;
			btnWidth = 80;
			btnHeight = subToolButtons[i].height * (80/subToolButtons[i].width);
			btnPadding = BUTTON_PADDING + 16;
		end

		btnHeight = btnHeight or BUTTON_HEIGHT;

		yPos = yPos + (btnHeight * 0.5) + 16;

		local button = ui.button.new({
			id = subToolButtons[i].id,
			imageUp = image,
			imageDown = image,
			shapeUp = shape,
			shapeDown = shape,
			width = btnWidth,
			height = btnHeight,
			pressAlpha = 0.5,
			bgColor = btnBgColor
		});
		button:addEventListener('release', onButtonRelease);
		button._scene = scene;
		button.anchorY = 0.5;
		button.x = -6;
		button.y = yPos; -- -(height * 0.5) + (button.height * 0.5) + 16 + (i-1) * (BUTTON_HEIGHT + BUTTON_PADDING);

		yPos = yPos + btnPadding;

		-- brush attributes
		button.parentId = id;
		button.toolModule = toolData.module;
		button.toolMode = toolData.mode;
		button.arbRotate = subToolButtons[i].arbRotate or false;
		button.brushAlpha = subToolButtons[i].alpha or 1.0;
		button.brushSizes = subToolButtons[i].brushSizes or {};
		button.stampWidth = subToolButtons[i].width or nil;
		button.stampHeight = subToolButtons[i].height or nil;
		button.vertices = subToolButtons[i].vertices or nil;
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