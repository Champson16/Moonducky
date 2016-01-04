local FRC_ArtCenter_Settings = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Settings');
local ui = require('ui');
local FRC_DataLib1 = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_MultiTouch = require('FRC_Modules.FRC_MultiTouch.FRC_MultiTouch');

local FRC_Store;
if (not FRC_ArtCenter_Settings.DISABLE_STORE) then
	FRC_Store = require('FRC_Modules.FRC_Store.FRC_Store');
end
local screenW, screenH = FRC_Layout.getScreenDimensions();
local math_floor = math.floor;

local FRC_ArtCenter_SubToolSelector = {};

local function selectObject(scene, obj)
	local canvas = scene.canvas;

	-- create object selection polygon
	if (scene.objectSelection) then
		if scene.objectSelection.removeSelf then
			scene.objectSelection:removeSelf();
		end
	end
	local padding = 5;
	scene.objectSelection = display.newRect(canvas.layerSelection, obj.x - ((obj.width * obj.xScale) * 0.5) - padding, obj.y - ((obj.height * obj.yScale) * 0.5) - padding, obj.width * obj.xScale + (padding * 2), obj.height * obj.yScale + (padding * 2));
	scene.objectSelection:setStrokeColor(scene.selectedTool.SELECTION_COLOR[1], scene.selectedTool.SELECTION_COLOR[2], scene.selectedTool.SELECTION_COLOR[3]);
	scene.objectSelection.strokeWidth = 2;
	scene.objectSelection.stroke.effect = "generator.marchingAnts"
	scene.objectSelection:setFillColor(1.0, 1.0, 1.0, 0);
	scene.objectSelection.selectedObject = obj;
	scene.objectSelection.rotation = obj.rotation;
	scene.objectSelection.x = obj.x;
	scene.objectSelection.y = obj.y;

	scene.eraserGroup.button:setFocusState(false);
	scene.eraserGroup.button:setDisabledState(false);
	scene.canvas:setEraseMode(false);
end

local function onBackgroundButtonRelease(event)
	local self = event.target;
	local scene = self._scene;

	if (not FRC_ArtCenter_Settings.DISABLE_STORE) and (self.lockImage) then
		FRC_Store:show(self.IAPBundleID, self.up._path);
		return;
	end

	scene.selectedTool = require('FRC_Modules.FRC_ArtCenter.' .. self.toolModule);
	scene.mode = scene.modes[self.toolMode];
	scene.eraserGroup.button:setFocusState(false);
	scene.canvas:setEraseMode(false);

	local bgImageLayer = scene.canvas.layerBgImage;
	if (bgImageLayer.group.numChildren > 0) then
		bgImageLayer.group[1]:removeSelf();
		bgImageLayer.group[1] = nil;
	end
	bgImageLayer:invalidate();

	bgImageLayer = scene.canvas.layerBgImageColor;
	if (bgImageLayer.group.numChildren > 0) then
		bgImageLayer.group[1]:removeSelf();
		bgImageLayer.group[1] = nil;
	end
	bgImageLayer:invalidate();

	if (self.isColorBg) then
		bgImageLayer = scene.canvas.layerBgImageColor;
	else
		bgImageLayer = scene.canvas.layerBgImage;
	end

	local imageFile = FRC_ArtCenter_Settings.UI.IMAGE_BASE_PATH .. self.imageFile;
	local image = display.newImageRect(bgImageLayer.canvas, imageFile, 1152, 768);
	local x = scene.canvas.width / image.contentWidth;
	local y = scene.canvas.height / image.contentHeight;

	-- store properties for saving
	scene.canvas.coloringPageFile = imageFile;
	scene.canvas.coloringPageWidth = 1152;
	scene.canvas.coloringPageHeight = 768;
	scene.canvas.coloringPageX = x;
	scene.canvas.coloringPageY = y;
	scene.canvas.coloringPageIsColor = self.isColorBg;

	if (x > y) then
		image.yScale = x;
	else
		image.xScale = y;
		image.yScale = y;
	end
	bgImageLayer:invalidate("canvas");
	if (not event.noDirty) then scene.canvas.isDirty = true; end
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

	local bgRect = display.newRoundedRect(scene.brushSizePopover, 0, 0, 210, 250, 11);
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
	local brushPreview = display.newImageRect(preview, brushButton.up._path, brushButton.up.contentWidth, brushButton.up.contentHeight);
	brushPreview.xScale = size / brushButton.up.contentWidth;
	brushPreview.yScale = brushPreview.xScale;
	brushPreview:setFillColor(0, 0, 0);
	brushPreview.y = -(preview.contentHeight * 0.5) + (brushPreview.height * 0.5) + 10;

	local styleText = display.newText(preview, 'Tap to select style:', 0, 0, native.systemFontBold, 12);
	styleText:setFillColor(0, 0, 0);
	styleText.y = -9;

	local strokeGroup1 = display.newGroup(); strokeGroup1.anchorChildren = true;
	local strokeWidth = preview.width * 0.5;
	local strokes = 150;
	local spacing = strokeWidth / strokes;
	for i=1,150 do
		local size = 28;
		if (brushButton.brushSizes[#brushButton.brushSizes] < size) then
			size = brushButton.brushSizes[#brushButton.brushSizes];
		end
		local blot = display.newImageRect(strokeGroup1, brushButton.up._path, brushButton.up.contentWidth, brushButton.up.contentHeight);
		blot.xScale = size / brushButton.up.width;
		blot.yScale = blot.xScale;
		blot.alpha = brushButton.brushAlpha;
		blot:setFillColor(0, 0, 0);
		blot.x = spacing * i;
	end
	preview:insert(strokeGroup1);
	strokeGroup1.y = 22;

	local selection = display.newImageRect(preview, FRC_ArtCenter_Settings.UI.STYLE_SELECTION_ARROW_IMAGE, FRC_ArtCenter_Settings.UI.STYLE_SELECTION_ARROW_WIDTH, FRC_ArtCenter_Settings.UI.STYLE_SELECTION_ARROW_HEIGHT);
	selection.x = -(preview.contentWidth * 0.5) + (selection.contentWidth * 0.5) + 10;
	selection.y = strokeGroup1.y;

	local strokeGroup2 = display.newGroup(); strokeGroup2.anchorChildren = true;
	local strokeWidth = preview.width * 0.5;
	local strokes = 150;
	local spacing = strokeWidth / strokes;
	for i=1,150 do
		local size = 28;
		if (brushButton.brushSizes[#brushButton.brushSizes] < size) then
			size = brushButton.brushSizes[#brushButton.brushSizes];
		end
		local blot = display.newImageRect(strokeGroup2, brushButton.up._path, brushButton.up.contentWidth, brushButton.up.contentHeight);
		blot.xScale = size / brushButton.up.width;
		blot.yScale = blot.xScale;
		blot.alpha = brushButton.brushAlpha;
		blot:setFillColor(0, 0, 0);
		blot.x = spacing * i;
		blot.rotation = math.random(0, 359);
	end
	preview:insert(strokeGroup2);
	strokeGroup2.y = strokeGroup1.y + 35;

	if (scene.selectedTool.arbRotate) then
		selection.y = strokeGroup2.y;
	end

	strokeGroup1:addEventListener('touch', function(e)
		brushButton.arbRotate = false;
		scene.selectedTool.arbRotate = false;
		selection.y = e.target.y;
		return true;
	end);

	strokeGroup2:addEventListener('touch', function(e)
		brushButton.arbRotate = true;
		scene.selectedTool.arbRotate = true;
		selection.y = e.target.y;
		return true;
	end);

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
	require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter').notifyMenuBars();
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
	scene.canvas:setEraseMode(false);

	local tool = scene.selectedTool;
	tool.graphic.image = FRC_ArtCenter_Settings.UI.IMAGE_BASE_PATH .. self.imageFile;
	tool.graphic.width = self.currentSize or self.defaultSize;
	tool.graphic.height = self.currentSize or self.defaultSize;
	tool.a = self.brushAlpha;
	tool.arbRotate = self.arbRotate;

	scene.freehandImage = tool.graphic.image;
	scene.freehandWidth = tool.graphic.width;
	scene.freehandHeight = tool.graphic.height;
	scene.freehandAlpha = tool.a;
	scene.freehandArbRotate = tool.arbRotate;

	self.parent:insert(FRC_ArtCenter_SubToolSelector.selection);
	FRC_ArtCenter_SubToolSelector.selection.isVisible = true;
	FRC_ArtCenter_SubToolSelector.selection.x = self.x;
	FRC_ArtCenter_SubToolSelector.selection.y = self.y + (FRC_ArtCenter_SubToolSelector.selection.contentHeight * 0.5) - 16;
	FRC_ArtCenter_SubToolSelector.selection.isActive = true;
	scene.selectedSubTool = self;

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
	scene.canvas:setEraseMode(false);

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

   -- cache settings
   local textureWrapX = display.getDefault( "textureWrapX" )
   local textureWrapY = display.getDefault( "textureWrapY" )
   -- change to repeat
   display.setDefault( "textureWrapX", "repeat" )
   display.setDefault( "textureWrapY", "repeat" )


	--shape.fill = { type="image", filename=scene.currentColor.texturePreview._imagePath };
   local newPath = string.gsub( scene.currentColor.texturePreview._imagePath, "Images/CCC", "Images/fills/CCC" )
   shape.fill = { type="image", filename = newPath };
	shape:setFillColor(scene.currentColor.preview.r, scene.currentColor.preview.g, scene.currentColor.preview.b, 1.0);

   -- restore settings
   display.setDefault( "textureWrapX", textureWrapX )
   display.setDefault( "textureWrapY", textureWrapY )

   -- dynamic re-scaler
   if( not shape.enterFrame ) then
      function shape.enterFrame( self )
         if( not self ) then return end
         if( not self.fill or not self.removeSelf ) then
            Runtime:removeEventListener( "enterFrame", self )
            self.enterFrame = nil
            return
         end
         -- EFM initially I didn't notice the scale was being applied to the parent.
         self.fill.scaleX = 1/self.parent.xScale
         self.fill.scaleY = 1/self.parent.yScale
      end
      Runtime:addEventListener( "enterFrame", shape )
   end

   -- ORIG
   --[[
	shape.fill = { type="image", filename=scene.currentColor.texturePreview._imagePath };
	shape:setFillColor(scene.currentColor.preview.r, scene.currentColor.preview.g, scene.currentColor.preview.b, 1.0);
   --]]


	shape.isHitTestable = true;
	shapeGroup.objectType = 'shape';
	shapeGroup.vertices = self.vertices;
	shapeGroup.fillImage = scene.currentColor.texturePreview._imagePath;
	shapeGroup.fillColor = { scene.currentColor.preview.r, scene.currentColor.preview.g, scene.currentColor.preview.b, 1.0 };
	shapeGroup.toolMode = self.toolMode;
	shapeGroup.isHitTestable = true;
	shapeGroup:addEventListener('touch', FRC_MultiTouch.handleTouch);
   shapeGroup:addEventListener('onPinch', tool.onPinch );
	canvas.layerObjects:insert(shapeGroup);

	local canvasColor = FRC_ArtCenter_Settings.UI.DEFAULT_CANVAS_COLOR;
	if ((scene.currentColor.preview.r == canvasColor) and (scene.currentColor.preview.g == canvasColor) and (scene.currentColor.preview.b == canvasColor)) then
		local a = 1.0;
		local strokeWidth;
		if (scene.currentColor.texturePreview.id == "Blank") then
			a = 0;
			strokeWidth = 5;
		end
		shape:setFillColor(scene.currentColor.preview.r, scene.currentColor.preview.g, scene.currentColor.preview.b, a);
		if (strokeWidth) then
			shape:setStrokeColor(0, 0, 0, 1.0);
			shapeGroup.strokeColor = { 0, 0, 0, 1.0 };
			shape.strokeWidth = strokeWidth;
			shapeGroup.strokeWidth = strokeWidth;
		end
	else
		shape.strokeWidth = 0;
		shapeGroup.strokeWidth = 0;
	end

	shapeGroup._scene = scene;
	selectObject(scene, shapeGroup);
	scene.canvas.isDirty = true;
end
FRC_ArtCenter_SubToolSelector.onShapeButtonRelease = onShapeButtonRelease;

local function onStampButtonRelease(event)
	local self = event.target;
	local scene = self._scene;
	local canvas = scene.canvas;

	if (not FRC_ArtCenter_Settings.DISABLE_STORE) and (self.lockImage) then
		FRC_Store:show(self.IAPBundleID, self.up._path);
		return;
	end

	scene.selectedTool = require('FRC_Modules.FRC_ArtCenter.' .. self.toolModule);
	scene.eraserGroup.button:setFocusState(false);
	scene.canvas:setEraseMode(false);

	local tool = scene.selectedTool;

	local image = FRC_ArtCenter_Settings.UI.IMAGE_BASE_PATH .. self.imageFile;
	if (self.baseDir and self.baseDir == system.DocumentsDirectory) then
		image = self.imageFile;
	end
	local size = 150;

	-- place stamp on canvas
	local stampGroup = display.newGroup();
	local stamp = display.newImage(stampGroup, image, self.baseDir or system.ResourceDirectory);
	local scaleX = size / stamp.width;
	local scaleY = size / stamp.height;

	if (self.stampDefaultScale) then
		scaleX = self.stampDefaultScale;
		scaleY = self.stampDefaultScale;
	end

	if (scaleX > scaleY) then
		stampGroup.xScale = scaleX;
		stampGroup.yScale = scaleX;
	else
		stampGroup.xScale = scaleY;
		stampGroup.yScale = scaleY;
	end

	if (self.maskFile) then
		local maskPath = FRC_ArtCenter_Settings.UI.IMAGE_BASE_PATH .. self.maskFile;
		local baseDir = system.ResourceDirectory;
		if (self.baseDir and self.baseDir == system.DocumentsDirectory) then
			baseDir = self.baseDir;
			maskPath = self.maskFile;
		end
		local mask = graphics.newMask(maskPath, baseDir);
		stamp:setMask(mask);
		stamp.isHitTestMasked = true;
		stampGroup.maskFile = maskPath;
		stamp.maskX = 0;
		stamp.maskY = 0;
		stamp.maskScaleX = 1.0;
		stamp.maskScaleY = 1.0;
	end

	stampGroup.objectType = 'stamp';
	stampGroup.imagePath = image; -- used for saving/loading
	stampGroup.fillColor = { 1.0, 1.0, 1.0, 1.0 };
	stampGroup.toolMode = self.toolMode;
	stampGroup:addEventListener('touch', FRC_MultiTouch.handleTouch);
	stampGroup:addEventListener('onPinch', tool.onPinch );
	canvas.layerObjects:insert(stampGroup);
	if (self.baseDir) then
		if (self.baseDir == system.DocumentsDirectory) then
			stampGroup.baseDir = "DocumentsDirectory";
		end
	else
		stampGroup.baseDir = "ResourceDirectory";
	end

	stampGroup._scene = scene;
	selectObject(scene, stampGroup);

	scene.canvas.isDirty = true;
end
FRC_ArtCenter_SubToolSelector.onStampButtonRelease = onStampButtonRelease;

local function dispose(self)
	if (self.numChildren) then
		for i=self.numChildren,1,-1 do
			if (self[i].dispose) then
				self[i]:dispose();
			elseif (self[i].removeSelf) then
				self[i]:removeSelf();
			end
			self[i] = nil;
		end
	end
	if (FRC_ArtCenter_SubToolSelector.selection) then
		FRC_ArtCenter_SubToolSelector.selection:removeSelf();
		FRC_ArtCenter_SubToolSelector.selection = nil;
	end
	if (self.removeSelf) then
		self:removeSelf();
	end
end

FRC_ArtCenter_SubToolSelector.new = function(scene, id, width, height)
	if (not FRC_ArtCenter_SubToolSelector.selection) then
		FRC_ArtCenter_SubToolSelector.selection = display.newImageRect(FRC_ArtCenter_Settings.UI.SUBTOOL_SELECTION_IMAGE, FRC_ArtCenter_Settings.UI.SUBTOOL_SELECTION_WIDTH, FRC_ArtCenter_Settings.UI.SUBTOOL_SELECTION_HEIGHT);
		FRC_ArtCenter_SubToolSelector.selection.isVisible = false;
		FRC_ArtCenter_SubToolSelector.selection.isActive = false;
		FRC_ArtCenter_SubToolSelector.selection.alpha = 0.80;
	end

	local bgAlpha = 0.75;

	if (FRC_ArtCenter_Settings.CONFIG.subtools) then
		if (FRC_ArtCenter_Settings.CONFIG.subtools.right) then
			if (FRC_ArtCenter_Settings.CONFIG.subtools.right.hideBackground) then
				bgAlpha = 0;
			end
		end
	end

	local group = ui.scrollContainer.new({
		width = width,
		height = height,
		xScroll = false,
		topPadding = 16,
		bottomPadding = 16,
		bgColor = { 1.0, 1.0, 1.0, bgAlpha }, --{ 0.14, 0.14, 0.14 },
		borderRadius = 11,
		borderWidth = 0,
		borderColor = { 0, 0, 0, 1.0 }
	});

	local toolData = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter').toolData or FRC_DataLib1.readJSON(FRC_ArtCenter_Settings.DATA.TOOLS);
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
	local BUTTON_WIDTH = FRC_ArtCenter_Settings.UI.SUBTOOL_DEFAULT_BUTTON_SIZE;
	local BUTTON_HEIGHT = FRC_ArtCenter_Settings.UI.SUBTOOL_DEFAULT_BUTTON_SIZE;
	local BUTTON_PADDING = FRC_ArtCenter_Settings.UI.SUBTOOL_BUTTON_PADDING;

	for i=1,#subToolButtons do
		local image, shape, onButtonRelease, btnWidth, btnHeight, btnPadding, btnBgColor, isColorBg;

		btnPadding = BUTTON_PADDING;
		local baseDir = system.ResourceDirectory;

		if (toolData.module == "FRC_ArtCenter_Tool_BackgroundImage") then
			image = FRC_ArtCenter_Settings.UI.IMAGE_BASE_PATH .. (subToolButtons[i].thumbFile or subToolButtons[i].imageFile);
			onButtonRelease = onBackgroundButtonRelease;
			btnWidth = FRC_ArtCenter_Settings.UI.BACKGROUND_SUBTOOL_BUTTON_WIDTH;
			btnHeight = FRC_ArtCenter_Settings.UI.BACKGROUND_SUBTOOL_BUTTON_HEIGHT;
			btnBgColor = FRC_ArtCenter_Settings.UI.BACKGROUND_SUBTOOL_BUTTON_BGCOLOR;

		elseif (toolData.module == "FRC_ArtCenter_Tool_FreehandDraw") then
			if (not subToolButtons[i].iconFile) then
				image = FRC_ArtCenter_Settings.UI.IMAGE_BASE_PATH .. subToolButtons[i].imageFile;
				btnWidth = FRC_ArtCenter_Settings.UI.FREEHAND_SUBTOOL_BRUSH_BUTTON_SIZE;
				btnHeight = FRC_ArtCenter_Settings.UI.FREEHAND_SUBTOOL_BRUSH_BUTTON_SIZE;
			else
				image = FRC_ArtCenter_Settings.UI.IMAGE_BASE_PATH .. subToolButtons[i].iconFile;
				btnWidth = FRC_ArtCenter_Settings.UI.FREEHAND_SUBTOOL_ICON_BUTTON_SIZE;
				btnHeight = FRC_ArtCenter_Settings.UI.FREEHAND_SUBTOOL_ICON_BUTTON_SIZE;
			end

			onButtonRelease = onFreehandButtonRelease;

		elseif (toolData.module == "FRC_ArtCenter_Tool_Shapes") then
			image = nil;
			shape = subToolButtons[i].vertices;
			onButtonRelease = onShapeButtonRelease;
			btnWidth = FRC_ArtCenter_Settings.UI.SHAPE_SUBTOOL_BUTTON_SIZE;
			btnHeight = FRC_ArtCenter_Settings.UI.SHAPE_SUBTOOL_BUTTON_SIZE;
			btnPadding = BUTTON_PADDING + 16;

		elseif (toolData.module == "FRC_ArtCenter_Tool_Stamps") then
			image = FRC_ArtCenter_Settings.UI.IMAGE_BASE_PATH .. subToolButtons[i].thumbFile;
			onButtonRelease = onStampButtonRelease;
			btnWidth = FRC_ArtCenter_Settings.UI.STAMP_SUBTOOL_BUTTON_WIDTH;
			btnHeight = subToolButtons[i].height * (btnWidth/subToolButtons[i].width);
			btnPadding = BUTTON_PADDING + 16;
			if (subToolButtons[i].baseDir) then
				baseDir = system[subToolButtons[i].baseDir];
				if (subToolButtons[i].baseDir == "DocumentsDirectory") then
					image = subToolButtons[i].thumbFile;
				end
			end
		end

		btnHeight = btnHeight or BUTTON_HEIGHT;
		yPos = yPos + 16;

		-- DEBUG:
		print("id: ", id);
		print("image: ", image);

		local button = ui.button.new({
			id = subToolButtons[i].id,
			imageUp = image,
			imageDown = image,
			shapeUp = shape,
			shapeDown = shape,
			width = btnWidth,
			height = btnHeight,
			pressAlpha = 0.5,
			bgColor = btnBgColor,
			parentScrollContainer = group,
			baseDirectory = baseDir
		});
		button.anchorY = 0;
		button.baseDir = baseDir;

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
		else
			button:addEventListener('press', function()
				require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter').notifyMenuBars();
			end);
		end

		button:addEventListener('release', onButtonRelease);
		button._scene = scene;
		button.x = -2;
		button.y = yPos;

		yPos = yPos + btnHeight + btnPadding;

		-- brush attributes
		button.parentId = id;
		button.toolModule = toolData.module;
		button.toolMode = toolData.mode;
		button.isColorBg = subToolButtons[i].color;
		button.imageFile = subToolButtons[i].imageFile;
		button.arbRotate = subToolButtons[i].arbRotate or false;
		button.brushAlpha = subToolButtons[i].alpha or 1.0;
		button.brushSizes = subToolButtons[i].brushSizes or {};
		button.stampWidth = subToolButtons[i].width or nil;
		button.stampHeight = subToolButtons[i].height or nil;
		button.stampDefaultScale = subToolButtons[i].defaultScale or nil;
		button.maskFile = subToolButtons[i].maskFile or nil;
		button.vertices = subToolButtons[i].vertices or nil;
		group.colorSubTools = toolData.colorSubTools or false;
		group:insert(button);

		if (not FRC_ArtCenter_Settings.DISABLE_STORE) and (subToolButtons[i].IAPBundleID and subToolButtons[i].IAPBundleID ~= "free") then
			if (not FRC_Store:checkPurchased(subToolButtons[i].IAPBundleID)) then
				local lockImage = display.newImageRect(FRC_Store.settings.lockImagePath, FRC_Store.settings.lockImageWidth, FRC_Store.settings.lockImageHeight);
				if (button.contentWidth > button.contentHeight) then
					-- scale lock to height
					lockImage.yScale = button.contentHeight / lockImage.contentHeight;
					lockImage.xScale = lockImage.yScale;
				else
					-- scale lock to width
					lockImage.xScale = button.contentWidth / lockImage.contentWidth;
					lockImage.yScale = lockImage.xScale;
				end
				lockImage.alpha = 0.75;
				button:insert(lockImage);
				lockImage.x, lockImage.y = 0, 0;
				button.lockImage = lockImage;
				button.IAPBundleID = subToolButtons[i].IAPBundleID;
			end
		end

		-- invert brush (for freehand draw subtools)
		if ((toolData.module == "FRC_ArtCenter_Tool_FreehandDraw") and (id ~= "FreehandDraw")) then
			button:setFillColor(0, 0, 0);
		end

		--[[
		local num = display.newText(i, 0, 0, native.systemFontBold, 12);
		num:setFillColor(0, 0, 0);
		num.anchorX = 0.5;
		num.anchorY = 0.5;
		num.x = button.x + (button.width * 0.5) + 8;
		num.y = button.y + (button.height) - 5;
		group:insert(num);
		--]]
	end

	group.parentId = id;
	group.dispose = dispose;
	if (scene) then scene.view:insert(group); end
	return group;
end

return FRC_ArtCenter_SubToolSelector;
