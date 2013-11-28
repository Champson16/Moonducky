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
local math_floor = math.floor;

FRC_ArtCenter_Scene.modes = FRC_ArtCenter_Settings.MODES;

-- Brush size (modal) popover for freehand sub-tools
local function newBrushSizePopover(scene, brushButton)
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
	--previewBg:setFillColor(.133333333, .133333333, .133333333);
	previewBg:setFillColor(1.0, 1.0, 1.0);
	preview:insert(previewBg, true);
	preview.x = bgRect.x;
	preview.y = bgRect.y + (preview_padding) - ((bgRect.height - preview.height) * 0.5);

	local size = brushButton.currentSize or scene.selectedTool.graphic.width;
	local brushPreview = display.newImageRect(preview, FRC_ArtCenter_Settings.UI.ERASER_BRUSH, brushButton.up.contentWidth, brushButton.up.contentHeight);
	brushPreview.xScale = size / brushButton.up.contentWidth;
	brushPreview.yScale = brushPreview.xScale;
	brushPreview:setFillColor(0, 0, 0);

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

	-- ensure the popup doesn't go below screen bounds
	if (scene.brushSizePopover.contentBounds.yMax > (screenH - 10)) then
		focusRect.y = (brushButton.contentBounds.yMin + brushButton.contentHeight * 0.5) + 5;
		scene.brushSizePopover.y = scene.brushSizePopover.y - (scene.brushSizePopover.contentBounds.yMax - screenH) - 10;
	end
end

local function onEraserButtonPress(event)
	require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter').notifyMenuBars();

	local self = event.target;
	local scene = self._scene;

	if ((scene.mode ~= scene.modes.ERASE) and (scene.mode ~= scene.modes.FREEHAND_DRAW)) then return; end

	self.popoverTimer = timer.performWithDelay(500, function()
		self.popoverTimer = nil;
		self:dispatchEvent({
			name = "release",
			target = self,
		});
		newBrushSizePopover(scene, self);
	end, 1);
end

local function onEraserButtonRelease(event)
	local self = event.target;
	local scene = self._scene;
	
	if (self.popoverTimer) then
		timer.cancel(self.popoverTimer);
		self.popoverTimer = nil;
	end

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
		scene.selectedTool.graphic.width = self.currentSize or 38;
		scene.selectedTool.graphic.height = self.currentSize or 38;
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

function FRC_ArtCenter_Scene.onCreateScene(event)
	local self = event.target;
	local view = self.view;

	if ((self.preCreateScene) and (type(self.preCreateScene) == 'function')) then
		self.preCreateScene(event);
	end
	
	FRC_ArtCenter_Scene.canvasWidth = canvas_width;
	FRC_ArtCenter_Scene.canvasHeight = canvas_height;

	local background = display.newImageRect(FRC_ArtCenter_Settings.UI.SCENE_BACKGROUND_IMAGE, FRC_ArtCenter_Settings.UI.SCENE_BACKGROUND_WIDTH, FRC_ArtCenter_Settings.UI.SCENE_BACKGROUND_HEIGHT);
	background.anchorX = 0.5;
	background.anchorY = 0.5;
	background.xScale = screenW / display.contentWidth;
	background.yScale = background.xScale;
	background.x = display.contentWidth * 0.5;
	background.y = display.contentHeight * 0.5;
	view:insert(background);

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
	eraserGroupBg:setFillColor(0.14, 0.14, 0.14, 0);
	eraserGroupBg:setStrokeColor(0, 0, 0, 0);
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
	self.eraserGroup.button.currentSize = 38;
	self.eraserGroup.button.minSize = 25;
	self.eraserGroup.button.maxSize = 60;
	self.eraserGroup:insert(self.eraserGroup.button);
	self.eraserGroup.button:addEventListener('press', onEraserButtonPress);
	self.eraserGroup.button:addEventListener('release', onEraserButtonRelease);
	local function cancelPopupTimer(event)
		local self = event.target;
		if (self.popoverTimer) then
			timer.cancel(self.popoverTimer);
			self.popoverTimer = nil;
		end
	end
	self.eraserGroup.button:addEventListener('pressoutside', cancelPopupTimer);
	self.eraserGroup.button:addEventListener('moved', cancelPopupTimer);
	view:insert(self.eraserGroup);

	-- COLOR PALETTE (LEFT/BOTTOM)
	self.colorSelector = FRC_ArtCenter_ColorSelector.new(self, FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH + (FRC_ArtCenter_Settings.UI.ELEMENT_PADDING * 0.5), self.canvasHeight - (FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH + FRC_ArtCenter_Settings.UI.ELEMENT_PADDING) + (FRC_ArtCenter_Settings.UI.CANVAS_BORDER * 2));
	self.colorSelector.x = -((screenW - display.contentWidth) * 0.5) + (self.colorSelector.width * 0.5) - 6 - self.colorSelector.contentWidth - 25;
	self.colorSelector.y = (display.contentHeight * 0.5) + FRC_ArtCenter_Settings.UI.CANVAS_TOP_MARGIN + ((FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH + FRC_ArtCenter_Settings.UI.ELEMENT_PADDING) * 0.5);

	-- CURRENT COLOR (LEFT/TOP)
	self.currentColor = display.newGroup();
	local currentColorBg = display.newRoundedRect(self.currentColor, 0, 0, self.colorSelector.width - (FRC_ArtCenter_Settings.UI.CANVAS_BORDER * 2), self.colorSelector.width - (FRC_ArtCenter_Settings.UI.CANVAS_BORDER * 2), 11*0.5);
	currentColorBg:setFillColor(0.14, 0.14, 0.14, 0);
	currentColorBg:setStrokeColor(0, 0, 0, 0);
	currentColorBg.strokeWidth = 3;
	self.currentColor.x = self.colorSelector.x;
	self.currentColor.y = self.subToolSelectors[1].contentBounds.yMin + (self.currentColor.contentHeight * 0.5) + (FRC_ArtCenter_Settings.UI.CANVAS_BORDER * 0.5);
	self.currentColor.preview = ui.button.new({
		imageUp = FRC_ArtCenter_Settings.UI.COLOR_PREVIEW_IMAGE,
		imageDown = FRC_ArtCenter_Settings.UI.COLOR_PREVIEW_IMAGE,
		width = 100,
		height = 100,
		pressAlpha = 0.5,
		onPress = function()
			require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter').notifyMenuBars();
		end
	});
	self.currentColor.preview:addEventListener('release', onColorSampleRelease);
	self.currentColor:insert(self.currentColor.preview);
	self.currentColor.preview.r = self.colorSelector.content[2].r;
	self.currentColor.preview.g = self.colorSelector.content[2].g;
	self.currentColor.preview.b = self.colorSelector.content[2].b;
	view:insert(self.currentColor);

	-- TEXTURE SELECTOR (LEFT/BOTTOM)
	self.textureSelector = FRC_ArtCenter_TextureSelector.new(self, FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH + (FRC_ArtCenter_Settings.UI.ELEMENT_PADDING * 0.5), self.canvasHeight - (FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH + FRC_ArtCenter_Settings.UI.ELEMENT_PADDING) + (FRC_ArtCenter_Settings.UI.CANVAS_BORDER * 2));
	self.textureSelector.x = -((screenW - display.contentWidth) * 0.5) + (self.textureSelector.width * 0.5) - 6 - self.textureSelector.contentWidth - 25;
	self.textureSelector.y = (display.contentHeight * 0.5) + FRC_ArtCenter_Settings.UI.CANVAS_TOP_MARGIN + ((FRC_ArtCenter_Settings.UI.SELECTOR_WIDTH + FRC_ArtCenter_Settings.UI.ELEMENT_PADDING) * 0.5);
	self.textureSelector.isVisible = false;

	-- CURRENT TEXTURE (LEFT/TOP)
	self.currentColor.texturePreview = display.newCircle(0, 0, 50);
	self.currentColor.texturePreview:setFillColor(1.0, 1.0, 1.0, 0.5);
	self.currentColor.texturePreview:setStrokeColor(0, 0, 0, 1.0);
	self.currentColor.texturePreview.strokeWidth = 5;
	self.currentColor.texturePreview._imagePath = FRC_ArtCenter_Settings.UI.BLANK_TEXTURE_IMAGE;
	self.currentColor.texturePreview.id = "Blank";
	self.currentColor:insert(self.currentColor.texturePreview);

	self.colorSelector:toFront();

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

	-- color all shapes sub-tools to the correct color
	for i=1,#self.subToolSelectors do
		if (self.subToolSelectors[i].colorSubTools) then
			for j=1,self.subToolSelectors[i].content.numChildren do
				if (self.subToolSelectors[i].content[j].parentId) then
					self.subToolSelectors[i].content[j]:setFillColor(self.colorSelector.content[2].r, self.colorSelector.content[2].g, self.colorSelector.content[2].b);
				end
			end
		end
	end

	if ((self.postCreateScene) and (type(self.postCreateScene) == 'function')) then
		self.postCreateScene(event);
	end
end

function FRC_ArtCenter_Scene.clearCanvas()
	native.showAlert("Start Over?", "If you start over, your progress will be lost.", { "Cancel", "OK" }, function(event)
		if (event.action == "clicked") then
			if (event.index == 1) then
				return;
			elseif (event.index == 2) then
				local canvas = FRC_ArtCenter_Scene.canvas;
				if (not canvas) then return; end

				-- clear the drawing layer and background image
				canvas.layerDrawing:invalidate();
				canvas.layerBgImage:invalidate();

				-- remove object selection
				if (FRC_ArtCenter_Scene.objectSelection) then
					FRC_ArtCenter_Scene.objectSelection:removeSelf();
					FRC_ArtCenter_Scene.objectSelection = nil;
					FRC_ArtCenter_Scene.eraserGroup.button:setDisabledState(true);
				end

				-- clear shapes and stamps
				for i=canvas.layerObjects.numChildren,1,-1 do
					canvas.layerObjects[i]:removeSelf();
					canvas.layerObjects[i] = nil;
				end

				-- clear anything in the overlay group
				for i=canvas.layerOverlay.numChildren,1,-1 do
					canvas.layerOverlay[i]:removeSelf();
					canvas.layerOverlay[i] = nil;
				end

				collectgarbage("collect");

				-- set selected tool button
				FRC_ArtCenter_Scene.eraserGroup.button:setDisabledState(true); -- eraser is disabled in background selection mode

				-- set current color to first in palette
				--FRC_ArtCenter_Scene.colorSelector:changeColor(FRC_ArtCenter_Scene.colorSelector.content[2].r, FRC_ArtCenter_Scene.colorSelector.content[2].g, FRC_ArtCenter_Scene.colorSelector.content[2].b);
				canvas:setBackgroundTexture(nil);
				canvas:fillBackground(FRC_ArtCenter_Settings.UI.DEFAULT_CANVAS_COLOR, FRC_ArtCenter_Settings.UI.DEFAULT_CANVAS_COLOR, FRC_ArtCenter_Settings.UI.DEFAULT_CANVAS_COLOR);
			end
		end
	end);
end

local function onShake(event)
	local canvas = FRC_ArtCenter_Scene.canvas;
	if (not canvas) then return; end

	if event.isShake then
		-- Device was shaken, clear the canvas
		FRC_ArtCenter_Scene.clearCanvas();
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

-- called when FRC_ActionBar or FRC_SettingsBar is expanded
local function onMenuExpand(event)
	local bounceTime = 150;
	local bounceDelay = 50;
	local slidePastDistance = 20;
	local slideTime = event.time * 0.5;

	-- SLIDE UP TOOL SELECTOR OUT OF VIEW
	FRC_ArtCenter_Scene.toolSelectorTransition = transition.to(FRC_ArtCenter_Scene.toolSelector, {
		time = slideTime,
		y = -(FRC_ArtCenter_Scene.toolSelector.contentHeight) - 25,
		transition = ease,
		onComplete = function()
			FRC_ArtCenter_Scene.toolSelectorTransition = nil;
		end
	});
end

-- called when FRC_ActionBar or FRC_SettingsBar is closed
local function onMenuClose(event)
	local bounceTime = 150;
	local bounceDelay = 50;
	local slidePastDistance = 20;
	local slideTime = event.time;

	FRC_ArtCenter_Scene.actionBarMenu:hide(true);
	FRC_ArtCenter_Scene.settingsBarMenu:hide(true);

	-- SLIDE IN TOOL SELECTOR FROM TOP
	FRC_ArtCenter_Scene.toolSelectorTransition = transition.to(FRC_ArtCenter_Scene.toolSelector, {
		time = slideTime,
		y = FRC_ArtCenter_Settings.UI.ELEMENT_PADDING * 0.5,
		transition = ease,
		onComplete = function()
			FRC_ArtCenter_Scene.toolSelectorTransition = nil;
		end
	});
end

function FRC_ArtCenter_Scene.onEnterScene(event)
	local self = event.target;

	if ((self.preEnterScene) and (type(self.preEnterScene) == 'function')) then
		self.preEnterScene(event);
	end

	timer.performWithDelay(300, function()
		slideInControls(self);
	end, 1);

	Runtime:addEventListener("FRC_MenuExpand", onMenuExpand);
	Runtime:addEventListener("FRC_MenuClose", onMenuClose);

	if ((self.postEnterScene) and (type(self.postEnterScene) == 'function')) then
		self.postEnterScene(event);
	end
end

function FRC_ArtCenter_Scene.onDidExitScene(event)
	local scene = event.target;
	local view = scene.view;

	if ((scene.preDidExitScene) and (type(scene.preDidExitScene) == 'function')) then
		scene.preDidExitScene(event);
	end

	Runtime:removeEventListener("FRC_MenuExpand", onMenuExpand);
	Runtime:removeEventListener("FRC_MenuClose", onMenuClose);

	for i=1,#scene.subToolSelectors do
		scene.subToolSelectors[i]:dispose();
	end
	scene.subToolSelectors = nil;

	-- dispose of individual scene elements
	for k,v in pairs(scene) do
		if (((type(scene[k]) == 'table') or (type(scene[k]) == 'DisplayObject')) and (scene[k].dispose)) then
			scene[k]:dispose();
			scene[k] = nil;
		elseif (((type(scene[k]) == 'table') or (type(scene[k]) == 'DisplayObject')) and (scene[k].removeSelf)) then
			scene[k]:removeSelf();
			scene[k] = nil;
		end
	end
	collectgarbage("collect");

	if ((scene.postDidExitScene) and (type(scene.postDidExitScene) == 'function')) then
		scene.postDidExitScene(event);
	end
end

-- scene events
FRC_ArtCenter_Scene:addEventListener('createScene', FRC_ArtCenter_Scene.onCreateScene);
FRC_ArtCenter_Scene:addEventListener('enterScene', FRC_ArtCenter_Scene.onEnterScene);
FRC_ArtCenter_Scene:addEventListener('didExitScene', FRC_ArtCenter_Scene.onDidExitScene);

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