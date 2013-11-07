local ui = require('FRC_Modules.FRC_UI.FRC_UI');
local FRC_DataLib1 = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local screenW, screenH = FRC_Layout.getScreenDimensions();
local math_floor = math.floor;

local DATA_PATH = 'FRC_Assets/FRC_ArtCenter/Data/FRC_ArtCenter_Tools.json';
local SELECTION_IMAGE = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_SubToolSelection.png';
local SELECTION_IMAGE_WIDTH = 86;
local SELECTION_IMAGE_HEIGHT = 86;
local BUTTON_WIDTH = 50;
local BUTTON_HEIGHT = 50;
local BUTTON_PADDING = 15;

local SubToolSelector = {};
SubToolSelector.selection = display.newImageRect(SELECTION_IMAGE, SELECTION_IMAGE_WIDTH, SELECTION_IMAGE_HEIGHT);
SubToolSelector.selection.isVisible = false;
SubToolSelector.selection.isActive = false;
SubToolSelector.selection.alpha = 0.80;

local function selectObject(scene, obj)
	local canvas = scene.canvas;

	-- create object selection polygon
	if (scene.objectSelection) then scene.objectSelection:removeSelf(); end
	local padding = 5;
	scene.objectSelection = display.newRect(canvas.layerSelection, obj.x - ((obj.width * obj.xScale) * 0.5) - padding, obj.y - ((obj.height * obj.yScale) * 0.5) - padding, obj.width * obj.xScale + (padding * 2), obj.height * obj.yScale + (padding * 2));
	scene.objectSelection:setStrokeColor(scene.selectedTool.SELECTION_COLOR[1], scene.selectedTool.SELECTION_COLOR[2], scene.selectedTool.SELECTION_COLOR[3]);
	scene.objectSelection.strokeWidth = 3;
	scene.objectSelection:setFillColor(1.0, 1.0, 1.0, 0);
	scene.objectSelection.selectedObject = obj;
	scene.objectSelection.rotation = obj.rotation;
	scene.objectSelection.x = obj.x;
	scene.objectSelection.y = obj.y;

	scene.eraserGroup.button:setFocusState(false);
	scene.eraserGroup.button:setDisabledState(false);
end

local function onBackgroundButtonRelease(event)
	local self = event.target;
	local scene = self._scene;

	scene.selectedTool = require('FRC_Modules.FRC_ArtCenter.' .. self.toolModule);
	scene.mode = scene.modes[self.toolMode];
	scene.eraserGroup.button:setFocusState(false);

	local bgImageLayer = scene.canvas.layerBgImage;
	local imageFile = 'FRC_Assets/FRC_ArtCenter/Images/' .. self.imageFile;

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

-- Brush size (modal) popover for freehand sub-tools
local function newBrushSizePopover(scene, brushButton)
	local screenW, screenH = FRC_Layout.getScreenDimensions();

	if (scene.brushSizePopover) then scene.brushSizePopover:removeSelf(); end

	-- create a full-screen rect to "modalize" the popover (touching it will close the popover)
	local modalRect = display.newRect(-((screenW - display.contentWidth) * 0.5), -((screenH - display.contentHeight) * 0.5), screenW, screenH);
	modalRect.anchorX = 0;
	modalRect.anchorY = 0;
	modalRect.isVisible = false;
	modalRect.isHitTestable = true;
	modalRect:addEventListener('touch', function(event)
		if (event.phase == "began") then
			modalRect:removeSelf();
			modalRect = nil;

			if (scene.brushSizePopover) then
				scene.brushSizePopover:removeSelf();
				scene.brushSizePopover = nil;
			end
		end
		return false;
	end);

	-- create group to hold popover elements
	scene.brushSizePopover = display.newGroup();

	local brushLeft = brushButton.contentBounds.xMin;
	local brushY = brushButton.contentBounds.yMin + (brushButton.contentHeight * 0.5);

	local focusRect = display.newRect(scene.brushSizePopover, 0, 0, 32, 32);
	focusRect:setFillColor(0.27, 0.27, 0.27, 1.0);
	focusRect.rotation = 45;
	focusRect.x = brushLeft - (focusRect.contentWidth * 0.5) - 5;
	focusRect.y = brushY;

	local bgRect = display.newRoundedRect(scene.brushSizePopover, 0, 0, 210, 210, 11);
	bgRect:setFillColor(0.27, 0.27, 0.27, 1.0);
	bgRect.x = brushLeft - (bgRect.width * 0.5) - 25;
	bgRect.y = brushY;

	-- container will show a preview of the brush at it's selected size
	local preview_padding = 8;
	local preview = display.newContainer(scene.brushSizePopover, bgRect.width - (preview_padding * 2), (bgRect.height - (preview_padding * 2)) * 0.75 );
	local previewBg = display.newRoundedRect(0, 0, preview.width, preview.height, 11);
	previewBg:setFillColor(.133333333, .133333333, .133333333);
	preview:insert(previewBg, true);
	preview.x = bgRect.x;
	preview.y = bgRect.y + (preview_padding) - ((bgRect.height - preview.height) * 0.5);

	local size = brushButton.currentSize or scene.selectedTool.graphic.width;
	local brushPreview = display.newImageRect(preview, brushButton.up._path, brushButton.up.contentWidth, brushButton.up.contentHeight);
	brushPreview.xScale = size / brushButton.up.contentWidth;
	brushPreview.yScale = brushPreview.xScale;

	-- create slider to control brush size
	local slider = ui.slider.new({
		width = preview.width,
		min = brushButton.minSize,
		max = brushButton.maxSize,
		startValue = size
	});
	brushButton.currentSize = slider.value;
	scene.brushSizePopover:insert(slider);
	slider.x = preview.x;
	slider.y = preview.contentBounds.yMax + ((bgRect.contentBounds.yMax - preview.contentBounds.yMax) * 0.5);
	slider:addEventListener("change", function(e)
		local value = math_floor(e.value);
		brushPreview.xScale = value / brushButton.up.contentWidth;
		brushPreview.yScale = brushPreview.xScale;

		scene.selectedTool.graphic.width = value;
		scene.selectedTool.graphic.height = value;
		brushButton.currentSize = value;
	end);

	-- ensure the popup doesn't go above or below screen bounds
	if (scene.brushSizePopover.contentBounds.yMin < 10) then
		focusRect.y = brushY + (brushButton.contentHeight * 0.5) - 5;
		bgRect.y = bgRect.y + -(scene.brushSizePopover.contentBounds.yMin) + 10;

	elseif (scene.brushSizePopover.contentBounds.yMax > (screenH - 10)) then
		focusRect.y = brushY - (brushButton.contentHeight * 0.5) + 5;
		bgRect.y = bgRect.y - (scene.brushSizePopover.contentBounds.yMax - screenH) - 10;
	end
end

-- For sizeable brushes, brush size adjuster popover will show up if brush is held down for 0.5 seconds or more
local function onFreehandButtonPress(event)
	local self = event.target;
	local scene = self._scene;

	self.popoverTimer = timer.performWithDelay(500, function()
		self.popoverTimer = nil;
		self:dispatchEvent({
			name = "release",
			target = self,
		});
		newBrushSizePopover(scene, self);
	end, 1);
end

local function onFreehandButtonRelease(event)
	local self = event.target;
	local scene = self._scene;

	if (self.popoverTimer) then
		timer.cancel(self.popoverTimer);
		self.popoverTimer = nil;
	end

	scene.selectedTool = require('FRC_Modules.FRC_ArtCenter.' .. self.toolModule);
	scene.mode = scene.modes[self.toolMode];
	scene.eraserGroup.button:setFocusState(false);

	local tool = scene.selectedTool;
	tool.graphic.image = 'FRC_Assets/FRC_ArtCenter/Images/' .. self.imageFile;
	tool.graphic.width = self.currentSize or self.defaultSize;
	tool.graphic.height = self.currentSize or self.defaultSize;
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
	SubToolSelector.selection.y = self.y + (SubToolSelector.selection.contentHeight * 0.5) - 16;
	SubToolSelector.selection.isActive = true;

	-- set color for tool to match currently selected color (in case eraser was previously selected)
	scene.colorSelector:changeColor(scene.currentColor.preview.r, scene.currentColor.preview.g, scene.currentColor.preview.b);
end

local function onShapeButtonRelease(event)
	local self = event.target;
	local scene = self._scene;
	local canvas = scene.canvas;

	scene.selectedTool = require('FRC_Modules.FRC_ArtCenter.' .. self.toolModule);
	scene.mode = scene.modes[self.toolMode];
	scene.eraserGroup.button:setFocusState(false);

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
	shape.fill = { type="image", filename=scene.currentColor.texturePreview._imagePath };
	shape:setFillColor(scene.currentColor.preview.r, scene.currentColor.preview.g, scene.currentColor.preview.b, 1.0);

	shape.isHitTestable = true;
	shapeGroup.toolMode = self.toolMode;
	shapeGroup.isHitTestable = true;
	shapeGroup:addEventListener('multitouch', tool.onShapePinch);
	canvas.layerObjects:insert(shapeGroup);

	if ((scene.currentColor.preview.r == scene.DEFAULT_CANVAS_COLOR) and (scene.currentColor.preview.g == scene.DEFAULT_CANVAS_COLOR) and (scene.currentColor.preview.b == scene.DEFAULT_CANVAS_COLOR)) then
		local a = 1.0;
		local strokeWidth;
		if (scene.currentColor.texturePreview.id == "Blank") then
			a = 0;
			strokeWidth = 5;
		end
		shape:setFillColor(scene.currentColor.preview.r, scene.currentColor.preview.g, scene.currentColor.preview.b, a);
		if (strokeWidth) then
			shape:setStrokeColor(0, 0, 0, 1.0);
			shape.strokeWidth = strokeWidth;
		end
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

	scene.selectedTool = require('FRC_Modules.FRC_ArtCenter.' .. self.toolModule);
	scene.eraserGroup.button:setFocusState(false);

	local tool = scene.selectedTool;

	local image = 'FRC_Assets/FRC_ArtCenter/Images/' .. self.imageFile;
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
	
	local toolData = FRC_DataLib1.readJSON(DATA_PATH);
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

		if (toolData.module == "FRC_ArtCenter_Tool_BackgroundImage") then
			image = 'FRC_Assets/FRC_ArtCenter/Images/' .. subToolButtons[i].imageFile;
			onButtonRelease = onBackgroundButtonRelease;
			btnWidth = 80;
			btnHeight = 53;
			btnBgColor = { 1.0, 1.0, 1.0, 1.0 };

		elseif (toolData.module == "FRC_ArtCenter_Tool_FreehandDraw") then
			if (not subToolButtons[i].iconFile) then
				image = 'FRC_Assets/FRC_ArtCenter/Images/' .. subToolButtons[i].imageFile;
				btnWidth = BUTTON_WIDTH;
				btnHeight = BUTTON_HEIGHT;
			else
				image = 'FRC_Assets/FRC_ArtCenter/Images/' .. subToolButtons[i].iconFile;
				btnWidth = 80;
				btnHeight = 80;
			end

			onButtonRelease = onFreehandButtonRelease;

		elseif (toolData.module == "FRC_ArtCenter_Tool_Shapes") then
			image = nil;
			shape = subToolButtons[i].vertices;
			onButtonRelease = onShapeButtonRelease;
			btnWidth = 80;
			btnHeight = 80;
			btnPadding = BUTTON_PADDING + 16;

		elseif (toolData.module == "FRC_ArtCenter_Tool_Stamps") then
			image = 'FRC_Assets/FRC_ArtCenter/Images/' .. subToolButtons[i].imageFile;
			onButtonRelease = onStampButtonRelease;
			btnWidth = 80;
			btnHeight = subToolButtons[i].height * (80/subToolButtons[i].width);
			btnPadding = BUTTON_PADDING + 16;
		end

		btnHeight = btnHeight or BUTTON_HEIGHT;
		yPos = yPos + 16;

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
		button.anchorY = 0;

		if (toolData.module == 'FRC_ArtCenter_Tool_FreehandDraw') then
			button:addEventListener('press', onFreehandButtonPress);

			local function cancelPopupTimer(event)
				local self = event.target;
				if (self.popoverTimer) then
					timer.cancel(self.popoverTimer);
					self.popoverTimer = nil;
				end
			end
			button:addEventListener('pressoutside', cancelPopupTimer);
			button:addEventListener('moved', cancelPopupTimer);

			-- brush size properties
			button.defaultSize = subToolButtons[i].defaultSize;
			button.minSize = subToolButtons[i].minSize;
			button.maxSize = subToolButtons[i].maxSize;
		end

		button:addEventListener('release', onButtonRelease);
		button._scene = scene;
		button.x = -6;
		button.y = yPos;

		yPos = yPos + btnHeight + btnPadding;

		-- brush attributes
		button.parentId = id;
		button.toolModule = toolData.module;
		button.toolMode = toolData.mode;
		button.imageFile = subToolButtons[i].imageFile;
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
		num.y = button.y + (button.height) - 5;
		group:insert(num);
	end

	group.parentId = id;
	if (scene) then scene.view:insert(group); end
	return group;
end

return SubToolSelector;