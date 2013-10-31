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
		display.getCurrentStage():setFocus(self);
		self.isFocused = true;

		ArtCenter.selectedTool.onCanvasTouch(event.target, event);

	elseif (self.isFocused) then
	
		if (event.phase == "moved") then
			ArtCenter.selectedTool.onCanvasTouch(event.target, event);
			
		elseif ((event.phase == "cancelled") or (event.phase == "ended")) then
			ArtCenter.selectedTool.onCanvasTouch(event.target, event);
			
			display.getCurrentStage():setFocus(nil);
			self.isFocused = false;
		end
	end
	return true;
end

local function repositionLayers(self)
	self.layerDrawing.x = self.x;
	self.layerDrawing.y = self.y;

	for i=2,self.numChildren do
		self[i].x = -(self.x);
		self[i].y = -(self.y);
	end

	-- TODO: once display.captureBounds works on device, uncoment the following:
	if (system.getInfo("environment") == "simulator") then
		self.drawingBuffer.x = self.x;
		self.drawingBuffer.y = self.y;
	end
end

Canvas.new = function(width, height, x, y)
	local canvas = display.newContainer(width, height);
	canvas.layerBgColor = display.newGroup(); canvas:insert(canvas.layerBgColor);

	if (system.getInfo("environment") == "simulator") then
		canvas.drawingBuffer = display.newSnapshot(width, height); -- TODO: uncomment this line once display.captureBounds works on device
	end
	canvas.layerDrawing = display.newSnapshot(width, height);

	-- TODO: once display.captureBounds() works on device, remove the following lines:
	if (system.getInfo("environment") ~= "simulator") then
		canvas.snapshots = {};
		table.insert(canvas.snapshots, canvas.layerDrawing);
	end

	canvas.layerBgImage = display.newGroup(); canvas:insert(canvas.layerBgImage);
	canvas.layerObjects = display.newGroup(); canvas:insert(canvas.layerObjects);
	canvas.layerOverlay = display.newGroup(); canvas:insert(canvas.layerOverlay);

	-- background for layerBgColor layer
	local bgRect = display.newRect(0, 0, width, height);
	bgRect:setFillColor(eraserColor[1], eraserColor[2], eraserColor[3]);
	canvas.layerBgColor:insert(bgRect, true);
	canvas.layerBgColor.bg = bgRect;
	canvas.layerBgColor:addEventListener("touch", onCanvasTouch);

	canvas.x = x; --display.contentWidth * 0.5;
	canvas.y = y; --display.contentHeight * 0.5;
	repositionLayers(canvas);

	-- public methods
	canvas.fillBackground = fillBackground;
	canvas.repositionLayers = repositionLayers;

	return canvas;
end

return Canvas;