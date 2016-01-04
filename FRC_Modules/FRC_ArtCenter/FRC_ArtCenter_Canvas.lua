local FRC_ArtCenter_Settings = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Settings');
local FRC_ArtCenter_Scene = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Scene');
local FRC_ArtCenter = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_MultiTouch = require('FRC_Modules.FRC_MultiTouch.FRC_MultiTouch');
local Canvas = {};

local function fillBackground(self, r, g, b, a)
	self.layerBgColor.bg:setFillColor(r, g, b, a or 1.0);
	self.layerBgColor.bg.r, self.layerBgColor.bg.g, self.layerBgColor.bg.b = r, g, b;
end

local function setBackgroundTexture(self, imagePath)
	if (imagePath) then
		--display.setDefault( "textureWrapX", "repeat" );
		--display.setDefault( "textureWrapY", "repeat" );

		self.layerBgColor.bg.fill = { type="image", filename=imagePath };
		self.layerBgColor.fillImage = imagePath;

		-- Uncomment the following once texture repeating works on device (Corona bug)
		--self.layerBgColor.bg.fill.scaleX = 0.25;
		--self.layerBgColor.bg.fill.scaleY = 0.25;

		-- reset texture wrap mode (so it doesn't affect other display objects; on device)
		--display.setDefault( "textureWrapX", "clampToEdge" );
		--display.setDefault( "textureWrapY", "clampToEdge" );
	else
		self.layerBgColor.bg.fill = nil;
	end
end

local function onCanvasTouch(event)
	require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter').notifyMenuBars();
	if ((not FRC_ArtCenter_Scene) or (not FRC_ArtCenter_Scene.selectedTool)) then return; end
	local target = event.target;

	if (event.phase == "began") then
		target._hasFocus = true;

		FRC_ArtCenter_Scene.selectedTool.onCanvasTouch(target, event);

	elseif (target._hasFocus) then

		if (event.phase == "moved") then
			FRC_ArtCenter_Scene.selectedTool.onCanvasTouch(target, event);
			FRC_ArtCenter_Scene.canvas.isDirty = true;

		elseif ((event.phase == "cancelled") or (event.phase == "ended")) then
			FRC_ArtCenter_Scene.selectedTool.onCanvasTouch(target, event);

			target._hasFocus = false;
		end
	end
	return true;
end

local function repositionLayers(self)
	self.layerBgImageColor.x = self.x;
	self.layerBgImageColor.y = self.y;

	self.layerDrawing.x = self.x;
	self.layerDrawing.y = self.y;

	self.layerBgImage.x = self.x;
	self.layerBgImage.y = self.y;

	self.layerObjects.x = self.x;
	self.layerObjects.y = self.y;

	self.layerSelection.x = self.x;
	self.layerSelection.y = self.y;

	if (self.frame) then
		self.frame.x = self.x;
		self.frame.y = self.y;

		--[[
		if (FRC_ArtCenter_Settings.CONFIG.frame.xOffset) then
			self.frame.x = self.frame.x + FRC_ArtCenter_Settings.CONFIG.frame.xOffset;
		end

		if (FRC_ArtCenter_Settings.CONFIG.frame.yOffset) then
			self.frame.y = self.frame.y + FRC_ArtCenter_Settings.CONFIG.frame.yOffset;
		end
		--]]

		if (self.frameMask) then
			self.frameMask.x = self.frame.x;
			self.frameMask.y = self.frame.y;
		end
	end

	for i=4,self.numChildren do
		self[i].x = -(self.x);
		self[i].y = -(self.y);
	end
end

local function save(self, id)
	self.layerSelection.isVisible = false;
	self.layerOverlay.isVisible = false;

  if (self.frameMask) then
		self.frameMask.isVisible = true;
	end

	if ((id ~= nil) and (id ~= '')) then
		self.id = id;
	else
		id = nil;
	end

	-- freehand drawing layer
	display.save(self.layerDrawing, self.id .. '_freehand.png', system.DocumentsDirectory);

	-- hide all layers that we don't want shown in the mask
	--[[
	self.layerBgColor.isVisible = false;
	self.layerBgImageColor.isVisible = false;
	self.layerBgImage.isVisible = false;
	self.layerObjects.isVisible = false;
	self.layerSelection.isVisible = false;
	--self.border:setFillColor(0.5, 0.5, 0.5, 1.0);

	-- save mask
	self.layerDrawing.fill.effect = 'filter.colorMatrix';
	self.layerDrawing.fill.effect.coefficients =
	{
	    0, 0, 0, 1,  --red coefficients
	    0, 0, 0, 1,  --green coefficients
	    0, 0, 0, 1,  --blue coefficients
	    0, 0, 0, 0   --alpha coefficients
	};
	self.layerDrawing.fill.effect.bias = { 0, 0, 0, 1 };
	display.save(self.layerDrawing, self.id .. '_mask.jpg', system.DocumentsDirectory);
	self.layerDrawing.fill.effect = nil;

	--self.border:setFillColor(0, 0, 0, 1.0);
	self.layerBgColor.isVisible = true;
	self.layerBgImageColor.isVisible = true;
	self.layerBgImage.isVisible = true;REPO
	self.layerObjects.isVisible = true;
	self.layerSelection.isVisible = true;
	--]]

	-- full-size image
	local capture;
	if (self.frame) then
		capture = display.captureBounds(self.frame.contentBounds);
		capture.x = self.frame.x;
		capture.y = self.frame.y;
	else
		capture = display.captureBounds(self.contentBounds);
		capture.x = self.x;
		capture.y = self.y;
	end
	display.save(capture, self.id .. '_full.jpg', system.DocumentsDirectory);

	-- thumbnail
	local thumbHeight = 152;
	local thumbWidth = (capture.contentWidth/capture.contentHeight) * thumbHeight;
	capture.yScale = thumbHeight/capture.contentHeight;
	capture.xScale = capture.yScale;
	display.save(capture, self.id .. '_thumbnail.jpg', system.DocumentsDirectory);
	capture:removeSelf();

	self.layerSelection.isVisible = true;
	self.layerOverlay.isVisible = true;

	if (self.frameMask) then
		self.frameMask.isVisible = false;
	end

	-- collect data for freehand, thumbnails, canvas color, coloring page
	local saveData = {
		id = self.id,
		thumbSuffix = '_thumbnail.jpg',
		fullSuffix = '_full.jpg',
		freehandSuffix = '_freehand.png',
		thumbWidth = thumbWidth,
		thumbHeight = thumbHeight,
		fullWidth = self.width,
		fullHeight = self.height,
		canvasTexture = self.layerBgColor.fillImage,
		canvasColor = { self.layerBgColor.bg.r, self.layerBgColor.bg.g, self.layerBgColor.bg.b, 1.0 },
		coloringPage = {
			image = self.coloringPageFile,
			width = self.coloringPageWidth,
			height = self.coloringPageHeight,
			x = self.coloringPageX,
			y = self.coloringPageY,
			color = self.coloringPageIsColor
		},
		objectsLayer = {}
	};

	-- collect data for shapes and stamps
	for i=1,self.layerObjects.numChildren do
		local obj = self.layerObjects[i];
		if (obj.objectType) then
			local objData = {};

			if ((obj.objectType) == 'shape') then

				objData.vertices = obj.vertices;
				objData.fillImage = obj.fillImage;
				objData.strokeColor = obj.strokeColor;
				objData.strokeWidth = obj.strokeWidth;

            -- Save Fill Settings -- EFM
            if(obj.numChildren == 1) then
               local child = obj[1]
               if( child.fill ) then
                  objData.fill_scaleX = child.fill.scaleX
                  objData.fill_scaleY = child.fill.scaleY
               end
            end

			elseif ((obj.objectType) == 'stamp') then

				objData.imagePath = obj.imagePath;
				objData.maskFile = obj.maskFile;

				print("SAVING STAMP DATA WITH MASK INFO:", obj.maskFile);
			end

			objData.objectType = obj.objectType;
			objData.fillColor = obj.fillColor;
			objData.xScale = obj.xScale;
			objData.yScale = obj.yScale;
			objData.rotation = obj.rotation;
			objData.x = obj.x;
			objData.y = obj.y;

			-- DEBUG:
			print("saving baseDir: ",obj.baseDir);
			objData.baseDir = obj.baseDir;

			table.insert(saveData.objectsLayer, objData);
		end
	end

	-- add to the ArtCenter savedData.savedItems table and save to disk
	if (id) then
		local saved = false;
		for i=1,#FRC_ArtCenter.savedData.savedItems do
			if (FRC_ArtCenter.savedData.savedItems[i].id == id) then
				FRC_ArtCenter.savedData.savedItems[i] = saveData;
				saved = true;
			end
		end
		if (not saved) then
			table.insert(FRC_ArtCenter.savedData.savedItems, saveData);
		end
	else
		table.insert(FRC_ArtCenter.savedData.savedItems, saveData);
	end
	FRC_ArtCenter.saveDataToFile();
end

local load = function(self, data)
	-- clear canvas and generate a new id
	FRC_ArtCenter_Scene.clearCanvas(true);
	self.id = FRC_ArtCenter.generateUniqueIdentifier();

	if (type(data) == "string") then
		local loadId = data;
		local saved = FRC_DataLib.readJSON(FRC_ArtCenter_Settings.DATA.DATA_FILENAME, system.DocumentsDirectory);
		for i=1,#saved.savedItems do
			if (saved.savedItems[i].id == loadId) then
				data = saved.savedItems[i];
				break;
			end
		end
	end

	-- load freehand drawing layer
	local loadedImage = display.newImageRect(data.id .. data.freehandSuffix, system.DocumentsDirectory, self.width, self.height);
	loadedImage.x = self.x;
	loadedImage.y = self.y;
	self.layerDrawing.canvas:insert(loadedImage);
	loadedImage.x = loadedImage.x - self.x;
	loadedImage.y = loadedImage.y - self.y;
	self.layerDrawing:invalidate("canvas");

	-- set canvas texture
	if (data.canvasTexture) then
		self:setBackgroundTexture(data.canvasTexture);
	end

	-- set canvas color
	self:fillBackground(data.canvasColor[1], data.canvasColor[2], data.canvasColor[3], data.canvasColor[4]);

	-- set selected background coloring page
	local bgImageLayer = self.layerBgImage;
	if (data.coloringPage.color) then
		bgImageLayer = self.layerBgImageColor;
	end
	local imageFile = data.coloringPage.image;
	local image = display.newImageRect(bgImageLayer.canvas, imageFile, 1152, 768);
	local x = self.width / image.contentWidth;
	local y = self.height / image.contentHeight;
	self.coloringPageFile = imageFile;
	self.coloringPageWidth = 1152;
	self.coloringPageHeight = 768;
	self.coloringPageX = x;
	self.coloringPageY = y;
	self.coloringPageIsColor = data.coloringPage.color;
	if (x > y) then
		image.yScale = x;
	else
		image.xScale = y;
		image.yScale = y;
	end
	bgImageLayer:invalidate("canvas");

	-- store properties for saving
	self.coloringPageFile = imageFile;
	self.coloringPageWidth = 1152;
	self.coloringPageHeight = 768;
	self.coloringPageX = x;
	self.coloringPageY = y;

	if (x > y) then
		image.yScale = x;
	else
		image.xScale = y;
		image.yScale = y;
	end
	bgImageLayer:invalidate("canvas");

	-- load stamps
	FRC_ArtCenter_SubToolSelector = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_SubToolSelector');
	for i=1,#data.objectsLayer do
		local scene = FRC_ArtCenter_Scene;

		if (data.objectsLayer[i].objectType == 'shape') then
			-- SHAPE
			local size = 100;
			local vertices = {};
			for j=1,#data.objectsLayer[i].vertices do
				table.insert(vertices, size * data.objectsLayer[i].vertices[j]);
			end

			-- place shape on canvas
			local shapeGroup = display.newGroup();
			local shape;
			if (#vertices > 1) then
				shape = display.newPolygon(shapeGroup, 0, 0, vertices);
			else
				shape = display.newCircle(shapeGroup, 0, 0, size);
			end
			if (data.objectsLayer[i].fillImage) then

            -- change to repeat
            display.setDefault( "textureWrapX", "repeat" )
            display.setDefault( "textureWrapY", "repeat" )

            local newPath = string.gsub( data.objectsLayer[i].fillImage, "Images/CCC", "Images/fills/CCC" )
            shape.fill = { type="image", filename=newPath };

            if( data.objectsLayer[i].fill_scaleX ) then
               shape.fill.scaleX = data.objectsLayer[i].fill_scaleX
            end
            if( data.objectsLayer[i].fill_scaleY ) then
               shape.fill.scaleY = data.objectsLayer[i].fill_scaleY
            end

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
                  --dprint(self.__id, self.fill.scaleX, self.parent.xScale)
               end
               Runtime:addEventListener( "enterFrame", shape )
            end


				--shape.fill = { type="image", filename=data.objectsLayer[i].fillImage };
			end
			shape:setFillColor(data.objectsLayer[i].fillColor[1], data.objectsLayer[i].fillColor[2], data.objectsLayer[i].fillColor[3], data.objectsLayer[i].fillColor[4]);

			shape.isHitTestable = true;
			shapeGroup.objectType = 'shape';
			shapeGroup.vertices = data.objectsLayer[i].vertices;
			shapeGroup.fillImage = data.objectsLayer[i].fillImage;
			shapeGroup.fillColor = data.objectsLayer[i].fillColor;
			shapeGroup.toolMode = 'SHAPE_PLACEMENT';
			shapeGroup.isHitTestable = true;
			shapeGroup:addEventListener('touch', FRC_MultiTouch.handleTouch);
         shapeGroup:addEventListener('onPinch', require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Tool_Shapes').onPinch );
			self.layerObjects:insert(shapeGroup);

			if (data.objectsLayer[i].strokeColor) then
				shape:setStrokeColor(data.objectsLayer[i].strokeColor[1], data.objectsLayer[i].strokeColor[2], data.objectsLayer[i].strokeColor[3], data.objectsLayer[i].strokeColor[4]);
			end

			if (data.objectsLayer[i].strokeWidth) then
				shape.strokeWidth = data.objectsLayer[i].strokeWidth;
			end

			shapeGroup.x = data.objectsLayer[i].x;
			shapeGroup.y = data.objectsLayer[i].y;
			shapeGroup.rotation = data.objectsLayer[i].rotation;
			shapeGroup.xScale = data.objectsLayer[i].xScale;
			shapeGroup.yScale = data.objectsLayer[i].yScale;
			shapeGroup._scene = scene;

		elseif (data.objectsLayer[i].objectType == 'stamp') then
			local image = data.objectsLayer[i].imagePath;
			local size = 150;

			-- place stamp on canvas
			local stampGroup = display.newGroup();
			local baseDir = system.ResourceDirectory;
			if (data.objectsLayer[i].baseDir) then
				stampGroup.baseDir = data.objectsLayer[i].baseDir; -- new code to fix stamp resaving bug
				baseDir = system[data.objectsLayer[i].baseDir];
				-- DEBUG:
				print("Loading stamp with baseDir: ", data.objectsLayer[i].baseDir, baseDir);
			end

			local stamp = display.newImage(stampGroup, image, baseDir);
			-- if we hit bad data, we need to skip this
			if stamp then
				local scaleX = size / stamp.width;
				local scaleY = size / stamp.height;

				if (data.objectsLayer[i].maskFile) then
					local mask = graphics.newMask(data.objectsLayer[i].maskFile, baseDir);
					stamp:setMask(mask);
					stamp.isHitTestMasked = true;
					stampGroup.maskFile = data.objectsLayer[i].maskFile;
				end

				stampGroup.objectType = 'stamp';
				stampGroup.imagePath = image; -- used for saving/loading
				stampGroup.toolMode = 'STAMP_PLACEMENT';
				stampGroup:addEventListener('touch', FRC_MultiTouch.handleTouch);
				stampGroup:addEventListener('onPinch', require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Tool_Stamps').onPinch );
				self.layerObjects:insert(stampGroup);

				if (data.objectsLayer[i].fillColor) then
					stamp:setFillColor(data.objectsLayer[i].fillColor[1], data.objectsLayer[i].fillColor[2], data.objectsLayer[i].fillColor[3], data.objectsLayer[i].fillColor[4]);
					stampGroup.fillColor = data.objectsLayer[i].fillColor;
				else
					stampGroup.fillColor = { 1.0, 1.0, 1.0, 1.0 };
				end

				if (data.objectsLayer[i].rotation) then
					stampGroup.x = data.objectsLayer[i].x;
					stampGroup.y = data.objectsLayer[i].y;
					stampGroup.rotation = data.objectsLayer[i].rotation;
					stampGroup.xScale = data.objectsLayer[i].xScale;
					stampGroup.yScale = data.objectsLayer[i].yScale;
				end

				stampGroup._scene = scene;
			end
		end
	end
end

local function setEraseMode(self, enableEraseMode)
	if (not enableEraseMode) then
		self.eraseMode = false;
		self.layerDrawing.fill.effect = nil;
	else
		self.eraseMode = true;
	end
end

local function dispose(self)
	if (self.layerBgColor) then
		self.layerBgColor:removeSelf();
		self.layerBgColor = nil;
	end

	if (self.layerBgImageColor) then
		self.layerBgImageColor:removeSelf();
		self.layerBgImageColor = nil;
	end

	if (self.layerDrawing) then
		self.layerDrawing:removeSelf();
		self.layerDrawing = nil;
	end

	if (self.layerBgImage) then
		self.layerBgImage:removeSelf();
		self.layerBgImage = nil;
	end

	if (self.layerObjects) then
		self.layerObjects:removeSelf();
		self.layerObjects = nil;
	end

	if (self.layerSelection) then
		self.layerSelection:removeSelf();
		self.layerSelection = nil;
	end

	if (self.layerOverlay) then
		self.layerOverlay:removeSelf();
		self.layerOverlay = nil;
	end

	if (self.frame) then
		self.frame:removeSelf();
		self.frame = nil;
	end

	if (self.frameMask) then
		self.frameMask:removeSelf();
		self.frameMask = nil;
	end

	self:removeSelf();
end

Canvas.new = function(width, height, x, y, borderWidth, borderHeight)

		-- create frame to overlay the canvas
	local includeFrame = false;
	if (FRC_ArtCenter_Settings.CONFIG.frame) then
		width = FRC_ArtCenter_Settings.CONFIG.frame.width * FRC_ArtCenter_Scene.background.xScale;
		height = FRC_ArtCenter_Settings.CONFIG.frame.height * FRC_ArtCenter_Scene.background.yScale;
		-- DEBUG:
		print("ArtCanvas:  Custom frame width/height = ", width, "/", height);
		includeFrame = true;
	end

	local eraserColor = FRC_ArtCenter_Settings.UI.DEFAULT_CANVAS_COLOR;
	local canvas = display.newContainer(width, height);
	canvas.id = FRC_ArtCenter.generateUniqueIdentifier();
	canvas.layerBgColor = display.newGroup(); canvas:insert(canvas.layerBgColor);
	canvas.layerBgImageColor = display.newSnapshot(width, height); canvas.layerBgImageColor.canvasMode = "discard";

	canvas.layerDrawing = display.newSnapshot(width, height);
	canvas.layerDrawing.canvasMode = "discard";

	canvas.layerBgImage = display.newSnapshot(width, height); canvas.layerBgImage.canvasMode = "discard";
	canvas.layerObjects = display.newContainer(width, height);
	canvas.layerSelection = display.newContainer(width, height);
	canvas.layerOverlay = display.newGroup(); canvas:insert(canvas.layerOverlay);

	if (includeFrame) then
		canvas.frame = display.newImageRect(FRC_ArtCenter_Settings.CONFIG.frame.image, FRC_ArtCenter_Settings.CONFIG.frame.width, FRC_ArtCenter_Settings.CONFIG.frame.height);
		canvas.frame.anchorX = 0.5;
		canvas.frame.anchorY = 0.5;
		canvas.frame.xScale = FRC_ArtCenter_Scene.background.xScale;
		canvas.frame.yScale = canvas.frame.xScale;
		canvas.frame.x = display.contentWidth * 0.5;
		canvas.frame.y = display.contentHeight * 0.5;

		if (FRC_ArtCenter_Settings.CONFIG.frame.xOffset) then
			canvas.frame.x = canvas.frame.x + FRC_ArtCenter_Settings.CONFIG.frame.xOffset;
		end

		if (FRC_ArtCenter_Settings.CONFIG.frame.yOffset) then
			canvas.frame.y = canvas.frame.y + FRC_ArtCenter_Settings.CONFIG.frame.yOffset;
		end

		canvas.frameMask = display.newImageRect(FRC_ArtCenter_Settings.CONFIG.frame.saveMask, FRC_ArtCenter_Settings.CONFIG.frame.width, FRC_ArtCenter_Settings.CONFIG.frame.height);
		canvas.frameMask.anchorX = 0.5;
		canvas.frameMask.anchorY = 0.5;
		canvas.frameMask.xScale = canvas.frame.xScale;
		canvas.frameMask.yScale = canvas.frame.yScale;
		canvas.frameMask.x = canvas.frame.x;
		canvas.frameMask.y = canvas.frame.y;
		x = canvas.frameMask.x;
		y = canvas.frameMask.y;
		canvas.frameMask.isVisible = false;
	end

	-- background for layerBgColor layer
	local bgRect = display.newRect(0, 0, width, height);
	bgRect:setFillColor(eraserColor, eraserColor, eraserColor);
	canvas.layerBgColor:insert(bgRect, true);
	canvas.layerBgColor.bg = bgRect;
	canvas.layerBgColor.bg.r, canvas.layerBgColor.bg.g, canvas.layerBgColor.bg.b = eraserColor, eraserColor, eraserColor;
	canvas.layerBgColor:addEventListener('touch', FRC_MultiTouch.handleTouch);
	canvas.layerBgColor:addEventListener("onPinch", onCanvasTouch );
	canvas.onCanvasTouch = onCanvasTouch;

	canvas.x = x;
	canvas.y = y;
	repositionLayers(canvas);

	-- public methods
	canvas.fillBackground = fillBackground;
	canvas.setBackgroundTexture = setBackgroundTexture;
	canvas.repositionLayers = repositionLayers;
	canvas.save = save;
	canvas.load = load;
	canvas.setEraseMode = setEraseMode;
	canvas.dispose = function(self) pcall(dispose, self); end
	canvas.isDirty = false;

	return canvas;
end

return Canvas;
