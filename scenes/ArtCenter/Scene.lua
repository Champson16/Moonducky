local storyboard = require('modules.stage');
local layout = require('modules.layout');
local ArtCenter = storyboard.newScene();
local ui = require('modules.ui');
local ToolSelector = require('scenes.ArtCenter.ToolSelector');
local BackgroundArtSelector = require('scenes.ArtCenter.BackgroundArtSelector');
local SubToolSelector = require('scenes.ArtCenter.SubToolSelector');
local ColorSelector = require('scenes.ArtCenter.ColorSelector');
local TextureSelector = require('scenes.ArtCenter.TextureSelector');

local const = {};
const.CANVAS_BORDER = 3;
const.SELECTOR_SIZE = 130;		-- width for vertical selectors; height for horizontal selectors
const.ELEMENT_PADDING = 4;		-- spacing between elements (such as drawing canvas, selectors, etc.)

const.TOOLS = {};
const.TOOLS.BackgroundImage = 'scenes.ArtCenter.Tools.BackgroundImage';
const.TOOLS.FreehandDraw = 'scenes.ArtCenter.Tools.FreehandDraw';

local screenW, screenH = layout.getScreenDimensions();
local canvas_width = screenW - ((const.SELECTOR_SIZE * 2) + (const.ELEMENT_PADDING * 2));
local canvas_height = screenH - ((const.SELECTOR_SIZE * 0.8) + 0);
local canvas_top = 42;

ArtCenter.DEFAULT_CANVAS_COLOR = .956862745;

ArtCenter.modes = {
	FREEHAND_DRAW = 1,
	BACKGROUND_SELECTION = 2,
	OBJECT_SELECTION = 3,
	SHAPE_PLACEMENT = 4,
	STAMP_PLACEMENT = 5,
	ERASE = 6
};

local function onEraserButtonRelease(event)
	local self = event.target;
	local scene = self._scene;
	if ((scene.mode == scene.modes.ERASE) or (scene.mode == scene.modes.BACKGROUND_SELECTION)) then return; end

	if (scene.mode == scene.modes.FREEHAND_DRAW) then
		-- Save prior settings (in case different color is selected)
		scene.selectedTool.old_r = scene.selectedTool.r;
		scene.selectedTool.old_g = scene.selectedTool.g;
		scene.selectedTool.old_b = scene.selectedTool.b;
		scene.selectedTool.old_a = scene.selectedTool.a;
		scene.selectedTool.old_image = scene.selectedTool.graphic.image;
		scene.selectedTool.old_width = scene.selectedTool.graphic.width;
		scene.selectedTool.old_height = scene.selectedTool.graphic.height;
		scene.selectedTool.old_arbRotate = scene.selectedTool.arbRotate;

		-- Eraser settings
		scene.selectedTool = require(const.TOOLS.FreehandDraw);
		scene.selectedTool.r = .956862745;
		scene.selectedTool.g = .956862745;
		scene.selectedTool.b = .956862745;
		scene.selectedTool.a = 1.0;
		scene.selectedTool.graphic.image = 'assets/images/UX/FRC_UX_ArtCenter_FreehandPaintBasic_Brush_PaintBrush1.png';
		scene.selectedTool.graphic.width = 38;
		scene.selectedTool.graphic.height = 38;
		scene.selectedTool.arbRotate = true;
		scene.mode = scene.modes.ERASE;
		scene.eraserGroup.button:setFocusState(true);

		SubToolSelector.selection.isVisible = false;
	else
		-- delete selected stamp or shape
		if ((scene.objectSelection) and (scene.objectSelection.selectedObject)) then
			scene.objectSelection.selectedObject:removeSelf();
			scene.objectSelection.selectedObject = nil;
			
			scene.objectSelection:removeSelf();
			scene.objectSelection = nil;
			scene.eraserGroup.button:setDisabledState(true);
		end
	end
end

local function onColorSampleRelease(event)
	local self = event.target;
	local scene = ArtCenter;

	scene.textureSelector.isVisible = not scene.textureSelector.isVisible;
	scene.colorSelector.isVisible = not scene.colorSelector.isVisible;
end

local function onCreateScene(event)
	print('ArtCenter:createScene');
	local self = event.target;
	local view = self.view;
	local map = {};
	for y=0,canvas_height do
		map[y] = {};
		for x=0,canvas_width do
			map[y][x] = 0;
		end
	end
	
	ArtCenter.canvasWidth = canvas_width;
	ArtCenter.canvasHeight = canvas_height;

	local background = display.newImageRect('assets/images/UX/FRC_UX_ArtCenter_Background_global_main.jpg', display.contentWidth, display.contentHeight);
	background.anchorX = 0.5;
	background.anchorY = 0.5;
	background.alpha = 0.2;
	background.xScale = screenW / display.contentWidth;
	background.yScale = background.xScale;
	background.x = display.contentWidth * 0.5;
	background.y = display.contentHeight * 0.5;
	view:insert(background);

	local actionButton = ui.button.new({
		imageUp = 'assets/images/UX/FRC_UX_ArtCenter_Icon_ActionBar_up.png',
		imageDown = 'assets/images/UX/FRC_UX_ArtCenter_Icon_ActionBar_down.png',
		width = 75,
		height = 75
	});
	view:insert(actionButton);
	layout.alignToLeft(actionButton, const.ELEMENT_PADDING);
	layout.alignToTop(actionButton, const.ELEMENT_PADDING * 0.5);

	local settingsButton = ui.button.new({
		imageUp = 'assets/images/UX/FRC_UX_ArtCenter_Icon_SettingsBar_up.png',
		imageDown = 'assets/images/UX/FRC_UX_ArtCenter_Icon_SettingsBar_down.png',
		width = 75,
		height = 75
	});
	view:insert(settingsButton);
	layout.alignToRight(settingsButton, const.ELEMENT_PADDING);
	layout.alignToTop(settingsButton, const.ELEMENT_PADDING * 0.5);

	-- DRAWING CANVAS (and border)
	local canvas_border = display.newRoundedRect(0, 0, canvas_width + (const.CANVAS_BORDER * 2), canvas_height + (const.CANVAS_BORDER * 2), 4);
	canvas_border:setFillColor(0, 0, 0, 1.0);
	canvas_border.x = display.contentWidth * 0.5;
	canvas_border.y = (display.contentHeight * 0.5) + canvas_top + canvas_height;
	view:insert(canvas_border);

	local canvas = require('scenes.ArtCenter.Canvas').new(canvas_width, canvas_height, display.contentWidth * 0.5, (display.contentHeight * 0.5) + canvas_top + canvas_height);
	view:insert(canvas);
	canvas.border = canvas_border;
	self.canvas = canvas;

	-- TOOL SELECTOR BUTTONS (TOP)
	self.toolSelector = ToolSelector.new(self, 100);
	self.toolSelector.x = (display.contentWidth * 0.5);
	self.toolSelector.y = const.ELEMENT_PADDING * 0.5;

	-- SUB-TOOL SELECTORS (RIGHT/TOP)
	self.subToolSelectors = {};
	for i=1,self.toolSelector.buttons.numChildren do
		self.subToolSelectors[i] = SubToolSelector.new(self, self.toolSelector.buttons[i].id, const.SELECTOR_SIZE + (const.ELEMENT_PADDING * 0.5), self.canvasHeight - (const.SELECTOR_SIZE + const.ELEMENT_PADDING) + (const.CANVAS_BORDER * 2));
		self.subToolSelectors[i].x = screenW - ((screenW - display.contentWidth) * 0.5) - (self.subToolSelectors[i].width * 0.5) + 6;
		if (i == 1) then
			self.subToolSelectors[i].x = self.subToolSelectors[i].x + self.subToolSelectors[i].contentWidth;
		end
		self.subToolSelectors[i].y = (display.contentHeight * 0.5) + canvas_top - ((const.SELECTOR_SIZE + const.ELEMENT_PADDING) * 0.5);

		if (i ~= 1) then
			self.subToolSelectors[i].isVisible = false;
		end
	end

	-- ERASER TOOL
	local subToolWidth = self.subToolSelectors[1].width - (const.ELEMENT_PADDING * 2);
	self.eraserGroup = display.newGroup();
	local eraserGroupBg = display.newRoundedRect(self.eraserGroup, 0, 0, subToolWidth + (const.ELEMENT_PADDING), subToolWidth, 11*0.5);
	eraserGroupBg:setFillColor(0.14, 0.14, 0.14, 1.0);
	eraserGroupBg:setStrokeColor(0, 0, 0, 1.0);
	eraserGroupBg.strokeWidth = 3;
	self.eraserGroup.x = screenW - ((screenW - display.contentWidth) * 0.5) - (self.subToolSelectors[1].width * 0.5) + 6 + self.eraserGroup.contentWidth;
	self.eraserGroup.y = self.subToolSelectors[1].contentBounds.yMax + (self.eraserGroup.contentHeight * 0.5) + (const.CANVAS_BORDER * 2);
	self.eraserGroup.button = ui.button.new({
		imageUp = "assets/images/UX/FRC_UX_ArtCenter_Eraser.png",
		imageDown = "assets/images/UX/FRC_UX_ArtCenter_Eraser.png",
		focusState = "assets/images/UX/FRC_UX_ArtCenter_Eraser_focused.png",
		disabled = "assets/images/UX/FRC_UX_ArtCenter_Eraser_disabled.png",
		width = 100,
		height = 100,
		pressAlpha = 0.5
	});
	self.eraserGroup.button._scene = self;
	self.eraserGroup:insert(self.eraserGroup.button);
	self.eraserGroup.button:addEventListener('release', onEraserButtonRelease);
	view:insert(self.eraserGroup);

	-- COLOR PALETTE (LEFT/BOTTOM)
	self.colorSelector = ColorSelector.new(self, const.SELECTOR_SIZE + (const.ELEMENT_PADDING * 0.5), self.canvasHeight - (const.SELECTOR_SIZE + const.ELEMENT_PADDING) + (const.CANVAS_BORDER * 2));
	self.colorSelector.x = -((screenW - display.contentWidth) * 0.5) + (self.colorSelector.width * 0.5) - 6 - self.colorSelector.contentWidth;
	self.colorSelector.y = (display.contentHeight * 0.5) + canvas_top + ((const.SELECTOR_SIZE + const.ELEMENT_PADDING) * 0.5);

	self.textureSelector = TextureSelector.new(self, const.SELECTOR_SIZE + (const.ELEMENT_PADDING * 0.5), self.canvasHeight - (const.SELECTOR_SIZE + const.ELEMENT_PADDING) + (const.CANVAS_BORDER * 2));
	self.textureSelector.x = -((screenW - display.contentWidth) * 0.5) + (self.textureSelector.width * 0.5) - 6 - self.textureSelector.contentWidth;
	self.textureSelector.y = (display.contentHeight * 0.5) + canvas_top + ((const.SELECTOR_SIZE + const.ELEMENT_PADDING) * 0.5);
	self.textureSelector.isVisible = false;

	-- CURRENT COLOR/TEXTURE (LEFT/TOP)
	self.currentColor = display.newGroup();
	local currentColorBg = display.newRoundedRect(self.currentColor, 0, 0, self.colorSelector.width - (const.CANVAS_BORDER * 2), self.colorSelector.width - (const.CANVAS_BORDER * 2), 11*0.5);
	currentColorBg:setFillColor(0.14, 0.14, 0.14, 1.0);
	currentColorBg:setStrokeColor(0, 0, 0, 1.0);
	currentColorBg.strokeWidth = 3;
	self.currentColor.x = self.colorSelector.x;
	self.currentColor.y = self.subToolSelectors[1].contentBounds.yMin + (self.currentColor.contentHeight * 0.5) + (const.CANVAS_BORDER * 0.5);
	self.currentColor.preview = ui.button.new({
		imageUp = "assets/images/UX/FRC_UX_ArtCenter_Color_Blank.png",
		imageDown = "assets/images/UX/FRC_UX_ArtCenter_Color_Blank.png",
		width = 100,
		height = 100,
		pressAlpha = 0.5
	});
	self.currentColor.preview:addEventListener('release', onColorSampleRelease);
	self.currentColor:insert(self.currentColor.preview);
	view:insert(self.currentColor);

	self.currentColor.texturePreview = display.newCircle(0, 0, 50);
	self.currentColor.texturePreview:setFillColor(1.0, 1.0, 1.0, 0.5);
	self.currentColor.texturePreview:setStrokeColor(0, 0, 0, 1.0);
	self.currentColor.texturePreview.strokeWidth = 5;
	self.currentColor.texturePreview._imagePath = 'assets/images/UX/FRC_UX_ArtCenter_Texture_Blank.jpg';
	self.currentColor.texturePreview.id = "Blank";
	self.currentColor:insert(self.currentColor.texturePreview);

	-- set selected tool button
	self.toolSelector.buttons[1]:setFocusState(true);
	self.eraserGroup.button:setDisabledState(true); -- eraser is disabled in background selection mode

	-- set selected sub-tool
	self.selectedTool = require(const.TOOLS.BackgroundImage);
	self.subToolSelectors[1].content[1]:dispatchEvent({
		name = "release",
		target = self.subToolSelectors[1].content[1]
	});
	self.mode = self.modes.BACKGROUND_SELECTION;

	-- set current color to first in palette
	self.colorSelector:changeColor(self.colorSelector.content[2].r, self.colorSelector.content[2].g, self.colorSelector.content[2].b);

	local buildText = display.newText(view, _G.APP_VERSION, 0, 0, native.systemFontBold, 14);
	buildText:setFillColor(1.0, 1.0, 1.0);
	buildText.anchorX = 1.0;
	buildText.anchorY = 1.0;
	buildText.x = screenW - 3;
	buildText.y = screenH - 10;
end

local function onShake(event)
	local canvas = ArtCenter.canvas;
	if (not canvas) then return; end

	if event.isShake then
		-- Device was shaken, clear the canvas
		--[[
		if (not _G.COMPAT_DRAWING_MODE) then
			for i=canvas.drawingBuffer.group.numChildren,1,-1 do
				canvas.drawingBuffer.group[i]:removeSelf();
				canvas.drawingBuffer.group[i] = nil;
			end
			canvas.drawingBuffer:invalidate();
			collectgarbage("collect");
		else
			-- TODO: once display.captureBounds() works on device; remove this else condition
			local lastItem = canvas.snapshots[#canvas.snapshots];
			for i=#canvas.snapshots-1,1,-1 do
				canvas.snapshots[i]:removeSelf();
				canvas.snapshots[i] = nil;			
			end
			canvas.snapshots[1] = lastItem;
			collectgarbage("collect");
		end
		--]]
	end
end

local function onEnterScene(event)
	print('ArtCenter:enterScene');
	local self = event.target;

	local slideTime = 500;
	local bounceTime = 100;
	local bounceDelay = 50;
	local slidePastDistance = 20;
	local ease = easing.inOutExpo;

	-- SLIDE IN CURRENT COLOR AND COLOR PALETTE FROM THE LEFT
	self.currentColorTransition = transition.to(self.currentColor, {
		time = slideTime,
		x = -((screenW - display.contentWidth) * 0.5) + (self.colorSelector.width * 0.5) - 6 + slidePastDistance,
		transition = ease,
		onComplete = function()
			self.currentColorTransition = transition.to(self.currentColor, {
				time = bounceTime,
				delay = bounceDelay,
				x = -((screenW - display.contentWidth) * 0.5) + (self.colorSelector.width * 0.5) - 6
			});
		end
	});

	self.colorSelectorTransition = transition.to(self.colorSelector, {
		time = slideTime,
		x = -((screenW - display.contentWidth) * 0.5) + (self.colorSelector.width * 0.5) - 6 + slidePastDistance,
		transition = ease,
		onComplete = function()
			self.colorSelectorTransition = transition.to(self.colorSelector, {
				time = bounceTime,
				delay = bounceDelay,
				x = -((screenW - display.contentWidth) * 0.5) + (self.colorSelector.width * 0.5) - 6
			});
		end
	});

	self.textureSelectorTransition = transition.to(self.textureSelector, {
		time = slideTime,
		x = -((screenW - display.contentWidth) * 0.5) + (self.textureSelector.width * 0.5) - 6 + slidePastDistance,
		transition = ease,
		onComplete = function()
			self.textureSelectorTransition = transition.to(self.textureSelector, {
				time = bounceTime,
				delay = bounceDelay,
				x = -((screenW - display.contentWidth) * 0.5) + (self.textureSelector.width * 0.5) - 6
			});
		end
	});

	-- SLIDE IN SUB-TOOL SELECTOR AND ERASER GROUP FROM THE RIGHT
	local subToolSelector = self.subToolSelectors[1];
	self.subToolTransition = transition.to(subToolSelector, {
		time = slideTime,
		x = screenW - ((screenW - display.contentWidth) * 0.5) - (subToolSelector.width * 0.5) + 6 - slidePastDistance,
		transition = ease,
		onComplete = function()
			self.subToolTransition = transition.to(subToolSelector, {
				time = bounceTime,
				delay = bounceDelay,
				x = screenW - ((screenW - display.contentWidth) * 0.5) - (subToolSelector.width * 0.5) + 6
			});
		end
	});

	self.eraserTransition = transition.to(self.eraserGroup, {
		time = slideTime,
		x = screenW - ((screenW - display.contentWidth) * 0.5) - (subToolSelector.width * 0.5) + 6 - slidePastDistance,
		transition = ease,
		onComplete = function()
			self.eraserTransition = transition.to(self.eraserGroup, {
				time = bounceTime,
				delay = bounceDelay,
				x = screenW - ((screenW - display.contentWidth) * 0.5) - (subToolSelector.width * 0.5) + 6
			});
		end
	});

	-- SLIDE IN THE DRAWING CANVAS FROM BOTTOM
	self.canvasTransition = transition.to(self.canvas, {
		time = slideTime + bounceDelay,
		y = (display.contentHeight * 0.5) + canvas_top - slidePastDistance,
		transition = ease,
		onComplete = function()
			self.canvasTransition = transition.to(self.canvas, {
				delay = bounceDelay,
				time = bounceTime,
				y = (display.contentHeight * 0.5) + canvas_top,
				onComplete = function()
					self.canvas:repositionLayers();
				end
			});
		end
	});

	self.canvasBorderTransition = transition.to(self.canvas.border, {
		time = slideTime + bounceDelay,
		y = (display.contentHeight * 0.5) + canvas_top - slidePastDistance,
		transition = ease,
		onComplete = function()
			self.canvasBorderTransition = transition.to(self.canvas.border, {
				delay = bounceDelay,
				time = bounceTime,
				y = (display.contentHeight * 0.5) + canvas_top
			});
		end
	});

	-- Create a runtime listener for the shake event
	Runtime:addEventListener("accelerometer", onShake)
end

local function onDidExitScene(event)
	print('ArtCenter:didExitScene');
	local self = event.target;
end

-- scene events
ArtCenter:addEventListener('createScene', onCreateScene);
ArtCenter:addEventListener('enterScene', onEnterScene);
ArtCenter:addEventListener('didExitScene', onDidExitScene);

-- ArtCenter-specific events
local function onToolSelection(event)
	local self = event.target;

	for i=1,#self.subToolSelectors do
		if (self.subToolSelectors[i].parentId == event.tool) then
			self.subToolSelectors[i].isVisible = true;
		else
			self.subToolSelectors[i].isVisible = false;
		end
	end
end
ArtCenter:addEventListener('toolSelection', onToolSelection);

return ArtCenter;