local Canvas = {};
local ArtCenter = require('scenes.ArtCenter.Scene');

local eraserColor = ArtCenter.DEFAULT_CANVAS_COLOR;

local function fillBackground(self, r, g, b, a)
	self.layerBgColor.bg:setFillColor(r, g, b, a or 1.0);
	self.layerBgColor.bg.r, self.layerBgColor.bg.g, self.layerBgColor.bg.b = r, g, b;
end

local function setBackgroundTexture(self, imagePath)
	if (imagePath) then
		self.layerBgColor.bg.fill = { type="image", filename=imagePath };

		-- The following has no effect ... Corona bug?
		self.layerBgColor.bg.fill.scaleX = 0.1;
		self.layerBgColor.bg.fill.scaleY = 0.1;
	else
		self.layerBgColor.bg.fill = nil;
	end
end

local function onCanvasTouch(event)
	if ((not ArtCenter) or (not ArtCenter.selectedTool)) then return; end
	local self = event.target;

	if (event.phase == "began") then
		self._hasFocus = true;

		ArtCenter.selectedTool.onCanvasTouch(self, event);

	elseif (self._hasFocus) then
	
		if (event.phase == "moved") then
			ArtCenter.selectedTool.onCanvasTouch(self, event);
			
		elseif ((event.phase == "cancelled") or (event.phase == "ended")) then
			ArtCenter.selectedTool.onCanvasTouch(self, event);
			
			self._hasFocus = false;
		end
	end
	return true;
end

local function repositionLayers(self)
	self.layerDrawing.x = self.x;
	self.layerDrawing.y = self.y;

	self.layerBgImage.x = self.x;
	self.layerBgImage.y = self.y;

	self.layerObjects.x = self.x;
	self.layerObjects.y = self.y;

	self.layerSelection.x = self.x;
	self.layerSelection.y = self.y;

	for i=4,self.numChildren do
		self[i].x = -(self.x);
		self[i].y = -(self.y);
	end
end

Canvas.new = function(width, height, x, y)
	local canvas = display.newContainer(width, height);
	canvas.layerBgColor = display.newGroup(); canvas:insert(canvas.layerBgColor);

	canvas.layerDrawing = display.newSnapshot(width, height);
	canvas.layerDrawing.canvasMode = "discard";

	canvas.layerBgImage = display.newSnapshot(width, height); --canvas:insert(canvas.layerBgImage);
	canvas.layerObjects = display.newContainer(width, height); --canvas:insert(canvas.layerObjects);
	canvas.layerSelection = display.newContainer(width, height); 
	canvas.layerOverlay = display.newGroup(); canvas:insert(canvas.layerOverlay);

	-- background for layerBgColor layer
	local bgRect = display.newRect(0, 0, width, height);
	bgRect:setFillColor(eraserColor, eraserColor, eraserColor);
	canvas.layerBgColor:insert(bgRect, true);
	canvas.layerBgColor.bg = bgRect;
	canvas.layerBgColor.bg.r, canvas.layerBgColor.bg.g, canvas.layerBgColor.bg.b = eraserColor, eraserColor, eraserColor;
	canvas.layerBgColor:addEventListener("multitouch", onCanvasTouch);

	canvas.x = x;
	canvas.y = y;
	repositionLayers(canvas);

	-- public methods
	canvas.fillBackground = fillBackground;
	canvas.setBackgroundTexture = setBackgroundTexture;
	canvas.repositionLayers = repositionLayers;

	return canvas;
end

return Canvas;