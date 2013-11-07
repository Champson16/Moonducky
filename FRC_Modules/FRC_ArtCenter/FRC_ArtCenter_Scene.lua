local FRC_ArtCenter_Settings = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Settings');
local FRC_SceneManager = require('FRC_Modules.FRC_SceneManager.FRC_SceneManager');
local layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_ArtCenter_Scene = FRC_SceneManager.newScene();
local ui = require('FRC_Modules.FRC_UI.FRC_UI');
local FRC_ArtCenter_ToolSelector = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_ToolSelector');
local FRC_ArtCenter_SubToolSelector = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_SubToolSelector');
local FRC_ArtCenter_ColorSelector = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_ColorSelector');
local FRC_ArtCenter_TextureSelector = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_TextureSelector');
local FRC_ArtCenter_Tool_FreehandDraw = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Tool_FreehandDraw');
local FRC_ArtCenter_Tool_BackgroundImage = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Tool_BackgroundImage');

local screenW, screenH = layout.getScreenDimensions();
local canvas_width = screenW - ((FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH * 2) + (FRC_ArtCenter_Settings.UI.ELEMENT_PADDING * 2));
local canvas_height = screenH - ((FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH * 0.8) + 0);

FRC_ArtCenter_Scene.modes = FRC_ArtCenter_Settings.MODES;

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
		scene.selectedTool = FRC_ArtCenter_Tool_FreehandDraw;
		scene.selectedTool.r = FRC_ArtCenter_Settings.UI.DEFAULT_CANVAS_COLOR;
		scene.selectedTool.g = FRC_ArtCenter_Settings.UI.DEFAULT_CANVAS_COLOR;
		scene.selectedTool.b = FRC_ArtCenter_Settings.UI.DEFAULT_CANVAS_COLOR;
		scene.selectedTool.a = 1.0;
		scene.selectedTool.graphic.image = FRC_ArtCenter_Settings.UI.ERASER_BRUSH;
		scene.selectedTool.graphic.width = 38;
		scene.selectedTool.graphic.height = 38;
		scene.selectedTool.arbRotate = true;
		scene.mode = scene.modes.ERASE;
		scene.eraserGroup.button:setFocusState(true);

		FRC_ArtCenter_SubToolSelector.selection.isVisible = false;
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
	local scene = FRC_ArtCenter_Scene;

	scene.textureSelector.isVisible = not scene.textureSelector.isVisible;
	scene.colorSelector.isVisible = not scene.colorSelector.isVisible;
end

local function onCreateScene(event)
	print('FRC_ArtCenter_Scene:createScene');
	local self = event.target;
	local view = self.view;
	local map = {};
	for y=0,canvas_height do
		map[y] = {};
		for x=0,canvas_width do
			map[y][x] = 0;
		end
	end
	
	FRC_ArtCenter_Scene.canvasWidth = canvas_width;
	FRC_ArtCenter_Scene.canvasHeight = canvas_height;

	local background = display.newImageRect(FRC_ArtCenter_Settings.UI.SCENE_BACKGROUND_IMAGE, FRC_ArtCenter_Settings.UI.SCENE_BACKGROUND_WIDTH, FRC_ArtCenter_Settings.UI.SCENE_BACKGROUND_HEIGHT);
	background.anchorX = 0.5;
	background.anchorY = 0.5;
	background.alpha = 0.2;
	background.xScale = screenW / display.contentWidth;
	background.yScale = background.xScale;
	background.x = display.contentWidth * 0.5;
	background.y = display.contentHeight * 0.5;
	view:insert(background);

	local actionButton = ui.button.new({
		imageUp = 'AppAssets/Images/FRC_UX_ArtCenter_Icon_ActionBar_up.png',
		imageDown = 'AppAssets/Images/FRC_UX_ArtCenter_Icon_ActionBar_down.png',
		width = 75,
		height = 75
	});
	view:insert(actionButton);
	layout.alignToLeft(actionButton, FRC_ArtCenter_Settings.UI.ELEMENT_PADDING);
	layout.alignToTop(actionButton, FRC_ArtCenter_Settings.UI.ELEMENT_PADDING * 0.5);

	local settingsButton = ui.button.new({
		imageUp = 'AppAssets/Images/FRC_UX_ArtCenter_Icon_SettingsBar_up.png',
		imageDown = 'AppAssets/Images/FRC_UX_ArtCenter_Icon_SettingsBar_down.png',
		width = 75,
		height = 75
	});
	view:insert(settingsButton);
	layout.alignToRight(settingsButton, FRC_ArtCenter_Settings.UI.ELEMENT_PADDING);
	layout.alignToTop(settingsButton, FRC_ArtCenter_Settings.UI.ELEMENT_PADDING * 0.5);

	-- DRAWING CANVAS (and border)
	local canvas_border = display.newRoundedRect(0, 0, canvas_width + (FRC_ArtCenter_Settings.UI.CANVAS_BORDER * 2), canvas_height + (FRC_ArtCenter_Settings.UI.CANVAS_BORDER * 2), 4);
	canvas_border:setFillColor(0, 0, 0, 1.0);
	canvas_border.x = display.contentWidth * 0.5;
	canvas_border.y = (display.contentHeight * 0.5) + FRC_ArtCenter_Settings.UI.CANVAS_TOP_MARGIN + canvas_height + 100;
	view:insert(canvas_border);

	local canvas = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Canvas').new(canvas_width, canvas_height, display.contentWidth * 0.5, (display.contentHeight * 0.5) + FRC_ArtCenter_Settings.UI.CANVAS_TOP_MARGIN + canvas_height + 100);
	view:insert(canvas);
	canvas.border = canvas_border;
	self.canvas = canvas;

	-- TOOL SELECTOR BUTTONS (TOP)
	self.toolSelector = FRC_ArtCenter_ToolSelector.new(self, 100);
	self.toolSelector.x = (display.contentWidth * 0.5);
	self.toolSelector.y = -(self.toolSelector.contentHeight) - 25;

	-- SUB-TOOL SELECTORS (RIGHT/TOP)
	self.subToolSelectors = {};
	for i=1,self.toolSelector.buttons.numChildren do
		self.subToolSelectors[i] = FRC_ArtCenter_SubToolSelector.new(self, self.toolSelector.buttons[i].id, FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH + (FRC_ArtCenter_Settings.UI.ELEMENT_PADDING * 0.5), self.canvasHeight - (FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH + FRC_ArtCenter_Settings.UI.ELEMENT_PADDING) + (FRC_ArtCenter_Settings.UI.CANVAS_BORDER * 2));
		self.subToolSelectors[i].x = screenW - ((screenW - display.contentWidth) * 0.5) - (self.subToolSelectors[i].width * 0.5) + 6;

		-- move first sub-tool selector off-screen since it needs to slide in
		if (i == 1) then
			self.subToolSelectors[i].x = self.subToolSelectors[i].x + self.subToolSelectors[i].contentWidth + 25;
		end
		self.subToolSelectors[i].y = (display.contentHeight * 0.5) + FRC_ArtCenter_Settings.UI.CANVAS_TOP_MARGIN - ((FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH + FRC_ArtCenter_Settings.UI.ELEMENT_PADDING) * 0.5);

		if (i ~= 1) then
			self.subToolSelectors[i].isVisible = false;
		end
	end

	-- ERASER TOOL
	local subToolWidth = self.subToolSelectors[1].width - (FRC_ArtCenter_Settings.UI.ELEMENT_PADDING * 2);
	self.eraserGroup = display.newGroup();
	local eraserGroupBg = display.newRoundedRect(self.eraserGroup, 0, 0, subToolWidth + (FRC_ArtCenter_Settings.UI.ELEMENT_PADDING), subToolWidth, 11*0.5);
	eraserGroupBg:setFillColor(0.14, 0.14, 0.14, 1.0);
	eraserGroupBg:setStrokeColor(0, 0, 0, 1.0);
	eraserGroupBg.strokeWidth = 3;
	self.eraserGroup.x = screenW - ((screenW - display.contentWidth) * 0.5) - (self.subToolSelectors[1].width * 0.5) + 6 + self.eraserGroup.contentWidth + 25;
	self.eraserGroup.y = self.subToolSelectors[1].contentBounds.yMax + (self.eraserGroup.contentHeight * 0.5) + (FRC_ArtCenter_Settings.UI.CANVAS_BORDER * 2);
	self.eraserGroup.button = ui.button.new({
		imageUp = FRC_ArtCenter_Settings.UI.ERASER_BUTTON_IMAGE,
		imageDown = FRC_ArtCenter_Settings.UI.ERASER_BUTTON_IMAGE,
		focusState = FRC_ArtCenter_Settings.UI.ERASER_BUTTON_IMAGE_FOCUSED,
		disabled = FRC_ArtCenter_Settings.UI.ERASER_BUTTON_IMAGE_DISABLED,
		width = 100,
		height = 100,
		pressAlpha = 0.5
	});
	self.eraserGroup.button._scene = self;
	self.eraserGroup:insert(self.eraserGroup.button);
	self.eraserGroup.button:addEventListener('release', onEraserButtonRelease);
	view:insert(self.eraserGroup);

	-- COLOR PALETTE (LEFT/BOTTOM)
	self.colorSelector = FRC_ArtCenter_ColorSelector.new(self, FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH + (FRC_ArtCenter_Settings.UI.ELEMENT_PADDING * 0.5), self.canvasHeight - (FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH + FRC_ArtCenter_Settings.UI.ELEMENT_PADDING) + (FRC_ArtCenter_Settings.UI.CANVAS_BORDER * 2));
	self.colorSelector.x = -((screenW - display.contentWidth) * 0.5) + (self.colorSelector.width * 0.5) - 6 - self.colorSelector.contentWidth - 25;
	self.colorSelector.y = (display.contentHeight * 0.5) + FRC_ArtCenter_Settings.UI.CANVAS_TOP_MARGIN + ((FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH + FRC_ArtCenter_Settings.UI.ELEMENT_PADDING) * 0.5);

	self.textureSelector = FRC_ArtCenter_TextureSelector.new(self, FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH + (FRC_ArtCenter_Settings.UI.ELEMENT_PADDING * 0.5), self.canvasHeight - (FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH + FRC_ArtCenter_Settings.UI.ELEMENT_PADDING) + (FRC_ArtCenter_Settings.UI.CANVAS_BORDER * 2));
	self.textureSelector.x = -((screenW - display.contentWidth) * 0.5) + (self.textureSelector.width * 0.5) - 6 - self.textureSelector.contentWidth - 25;
	self.textureSelector.y = (display.contentHeight * 0.5) + FRC_ArtCenter_Settings.UI.CANVAS_TOP_MARGIN + ((FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH + FRC_ArtCenter_Settings.UI.ELEMENT_PADDING) * 0.5);
	self.textureSelector.isVisible = false;

	-- CURRENT COLOR/TEXTURE (LEFT/TOP)
	self.currentColor = display.newGroup();
	local currentColorBg = display.newRoundedRect(self.currentColor, 0, 0, self.colorSelector.width - (FRC_ArtCenter_Settings.UI.CANVAS_BORDER * 2), self.colorSelector.width - (FRC_ArtCenter_Settings.UI.CANVAS_BORDER * 2), 11*0.5);
	currentColorBg:setFillColor(0.14, 0.14, 0.14, 1.0);
	currentColorBg:setStrokeColor(0, 0, 0, 1.0);
	currentColorBg.strokeWidth = 3;
	self.currentColor.x = self.colorSelector.x;
	self.currentColor.y = self.subToolSelectors[1].contentBounds.yMin + (self.currentColor.contentHeight * 0.5) + (FRC_ArtCenter_Settings.UI.CANVAS_BORDER * 0.5);
	self.currentColor.preview = ui.button.new({
		imageUp = FRC_ArtCenter_Settings.UI.COLOR_PREVIEW_IMAGE,
		imageDown = FRC_ArtCenter_Settings.UI.COLOR_PREVIEW_IMAGE,
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
	self.currentColor.texturePreview._imagePath = FRC_ArtCenter_Settings.UI.BLANK_TEXTURE_IMAGE;
	self.currentColor.texturePreview.id = "Blank";
	self.currentColor:insert(self.currentColor.texturePreview);

	-- set selected tool button
	self.toolSelector.buttons[1]:setFocusState(true);
	self.eraserGroup.button:setDisabledState(true); -- eraser is disabled in background selection mode

	-- set selected sub-tool
	self.selectedTool = FRC_ArtCenter_Tool_BackgroundImage;
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
	local canvas = FRC_ArtCenter_Scene.canvas;
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

local function slideInControls(self)
	local slideTime = 500;
	local bounceTime = 150;
	local bounceDelay = 50;
	local slidePastDistance = 20;
	local ease = easing.linear;

	-- SLIDE IN TOOL SELECTOR FROM TOP
	self.toolSelectorTransition = transition.to(self.toolSelector, {
		time = slideTime,
		y = FRC_ArtCenter_Settings.UI.ELEMENT_PADDING * 0.5 + slidePastDistance,
		transition = ease,
		onComplete = function()
			self.toolSelectorTransition = transition.to(self.toolSelector, {
				time = bounceTime,
				delay = bounceDelay,
				y = FRC_ArtCenter_Settings.UI.ELEMENT_PADDING * 0.5
			});
		end
	});

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
		delay = slideTime * 0.25,
		time = slideTime + bounceDelay,
		y = (display.contentHeight * 0.5) + FRC_ArtCenter_Settings.UI.CANVAS_TOP_MARGIN - slidePastDistance,
		transition = ease,
		onComplete = function()
			self.canvasTransition = transition.to(self.canvas, {
				delay = bounceDelay,
				time = bounceTime,
				y = (display.contentHeight * 0.5) + FRC_ArtCenter_Settings.UI.CANVAS_TOP_MARGIN,
				onComplete = function()
					self.canvas:repositionLayers();
				end
			});
		end
	});

	self.canvasBorderTransition = transition.to(self.canvas.border, {
		delay = slideTime * 0.25,
		time = slideTime + bounceDelay,
		y = (display.contentHeight * 0.5) + FRC_ArtCenter_Settings.UI.CANVAS_TOP_MARGIN - slidePastDistance,
		transition = ease,
		onComplete = function()
			self.canvasBorderTransition = transition.to(self.canvas.border, {
				delay = bounceDelay,
				time = bounceTime,
				y = (display.contentHeight * 0.5) + FRC_ArtCenter_Settings.UI.CANVAS_TOP_MARGIN
			});
		end
	});

	-- Create a runtime listener for the shake event
	Runtime:addEventListener("accelerometer", onShake)
end

local function onEnterScene(event)
	print('FRC_ArtCenter_Scene:enterScene');
	local self = event.target;
	timer.performWithDelay(300, function()
		slideInControls(self);
	end, 1);
end

local function onDidExitScene(event)
	print('FRC_ArtCenter_Scene:didExitScene');
	local self = event.target;
end

-- scene events
FRC_ArtCenter_Scene:addEventListener('createScene', onCreateScene);
FRC_ArtCenter_Scene:addEventListener('enterScene', onEnterScene);
FRC_ArtCenter_Scene:addEventListener('didExitScene', onDidExitScene);

-- FRC_ArtCenter_Scene-specific events
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
FRC_ArtCenter_Scene:addEventListener('toolSelection', onToolSelection);

return FRC_ArtCenter_Scene;