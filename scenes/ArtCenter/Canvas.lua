local Canvas = {};
local ArtCenter = require('scenes.ArtCenter.Scene');

local eraserColor = { .956862745, .956862745, .956862745 };

local function fillBackground(self, r, g, b)
	self.layerBgColor.bg:setFillColor(r, g, b);
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

	-- TODO: once display.captureBounds works on device, uncoment the following:
	if (not _G.COMPAT_DRAWING_MODE) then
		self.drawingBuffer.x = self.x;
		self.drawingBuffer.y = self.y;
	end
end

Canvas.new = function(width, height, x, y)
	local canvas = display.newContainer(width, height);
	canvas.layerBgColor = display.newGroup(); canvas:insert(canvas.layerBgColor);

	if (not _G.COMPAT_DRAWING_MODE) then
		canvas.drawingBuffer = display.newSnapshot(width, height); -- TODO: uncomment this line once display.captureBounds works on device
	end
	canvas.layerDrawing = display.newSnapshot(width, height);

	-- TODO: once display.captureBounds() works on device, remove the following lines:
	if (_G.COMPAT_DRAWING_MODE) then
		canvas.snapshots = {};
		table.insert(canvas.snapshots, canvas.layerDrawing);
	end

	canvas.layerBgImage = display.newSnapshot(width, height); --canvas:insert(canvas.layerBgImage);
	canvas.layerObjects = display.newContainer(width, height); --canvas:insert(canvas.layerObjects);
	canvas.layerSelection = display.newContainer(width, height); 
	canvas.layerOverlay = display.newGroup(); canvas:insert(canvas.layerOverlay);

	-- background for layerBgColor layer
	local bgRect = display.newRect(0, 0, width, height);
	bgRect:setFillColor(eraserColor[1], eraserColor[2], eraserColor[3]);
	canvas.layerBgColor:insert(bgRect, true);
	canvas.layerBgColor.bg = bgRect;
	canvas.layerBgColor:addEventListener("multitouch", onCanvasTouch);

	canvas.x = x;
	canvas.y = y;
	repositionLayers(canvas);

	-- public methods
	canvas.fillBackground = fillBackground;
	canvas.repositionLayers = repositionLayers;

	return canvas;
end

return Canvas;