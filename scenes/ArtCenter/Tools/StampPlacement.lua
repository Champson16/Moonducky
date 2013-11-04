local ArtCenter = require('scenes.ArtCenter.Scene');
local layout = require('modules.layout');
local screenW, screenH = layout.getScreenDimensions();
local math_random = math.random;
local math_floor = math.floor;
local math_sqrt = math.sqrt;
local math_abs = math.abs;

local Stamp = {};

local SELECTION_COLOR = { 0, 0.5, 1.0 };
local MIN_STAMP_SIZE = 88;

Stamp.onCanvasTouch = function(self, event)
	local scene = ArtCenter;

	if (event.phase == "began") then
		if (scene.objectSelection) then
			scene.objectSelection:removeSelf();
			scene.objectSelection = nil;
		end
	end

	return true;
end

Stamp.onStampTouch = function(event)
	local self = event.target;
	local scene = self._scene;
	local canvas = scene.canvas;

	if (scene.mode ~= scene.modes.STAMP_PLACEMENT) then return false; end
	
	if (event.phase == "began") then

		display.getCurrentStage():setFocus(self);
		self._hasFocus = true;

		self.markX = self.x;
		self.markY = self.y;

		-- create object selection polygon
		if (scene.objectSelection) then scene.objectSelection:removeSelf(); end
		local padding = 5;
		scene.objectSelection = display.newPolygon(canvas.layerSelection, self.x, self.y, { -self.contentWidth*0.5-padding,-self.contentHeight*0.5-padding, self.contentWidth*0.5+padding,-self.contentHeight*0.5-padding, self.contentWidth*0.5+padding,self.contentHeight*0.5+padding, -self.contentWidth*0.5-padding,self.contentHeight*0.5+padding });
		scene.objectSelection:setStrokeColor(SELECTION_COLOR[1], SELECTION_COLOR[2], SELECTION_COLOR[3]);
		scene.objectSelection.strokeWidth = 3;
		scene.objectSelection:setFillColor(1.0, 1.0, 1.0, 0);
		scene.objectSelection.selectedObject = self;

	elseif (self._hasFocus) then
		if (event.phase == "moved") then

			self.x = (event.x - event.xStart) + self.markX;
			self.y = (event.y - event.yStart) + self.markY;

			scene.objectSelection.x = self.x;
			scene.objectSelection.y = self.y;
			scene.objectSelection.isVisible = false;

		elseif ((event.phase == "cancelled") or (event.phase == "ended")) then

			scene.objectSelection.isVisible = true;
			self._hasFocus = false;
			display.getCurrentStage():setFocus(nil);
		end
	end

	return true;
end

Stamp.onStampPinch = function(e)
	local self = e.target;
	local scene = self._scene;
	local canvas = scene.canvas;
	if (scene.mode ~= scene.modes[self.toolMode]) then return false; end

	local padding = 5;

	if (e.phase == "began") then
		doPinchZoom( e.target, {} );
		doPinchZoom( e.target, e.list );

		self._hasFocus = true;
		self.markX = self.x;
		self.markY = self.y;
		self.minSize = MIN_STAMP_SIZE;
		self.maxSize = math.floor((canvas.width + canvas.height) * 0.5) * 2;

		-- create object selection polygon
		if (scene.objectSelection) then scene.objectSelection:removeSelf(); end
		scene.objectSelection = display.newPolygon(canvas.layerSelection, self.x, self.y, { -self.contentWidth*0.5-padding,-self.contentHeight*0.5-padding, self.contentWidth*0.5+padding,-self.contentHeight*0.5-padding, self.contentWidth*0.5+padding,self.contentHeight*0.5+padding, -self.contentWidth*0.5-padding,self.contentHeight*0.5+padding });
		scene.objectSelection:setStrokeColor(SELECTION_COLOR[1], SELECTION_COLOR[2], SELECTION_COLOR[3]);
		scene.objectSelection.strokeWidth = 3;
		scene.objectSelection:setFillColor(1.0, 1.0, 1.0, 0);
		scene.objectSelection.selectedObject = self;

		self:toFront();

	elseif (self._hasFocus) then
		if (e.phase == "moved") then
			
			doPinchZoom( e.target, e.list );

			if (scene.objectSelection) then
				scene.objectSelection.x = self.x;
				scene.objectSelection.y = self.y;
				scene.objectSelection.isVisible = false;
			end
		else
			doPinchZoom( e.target, {} );
			
			-- create object selection polygon
			if (scene.objectSelection) then scene.objectSelection:removeSelf(); end
			scene.objectSelection = display.newPolygon(canvas.layerSelection, self.x, self.y, { -self.contentWidth*0.5-padding,-self.contentHeight*0.5-padding, self.contentWidth*0.5+padding,-self.contentHeight*0.5-padding, self.contentWidth*0.5+padding,self.contentHeight*0.5+padding, -self.contentWidth*0.5-padding,self.contentHeight*0.5+padding });
			scene.objectSelection:setStrokeColor(SELECTION_COLOR[1], SELECTION_COLOR[2], SELECTION_COLOR[3]);
			scene.objectSelection.strokeWidth = 3;
			scene.objectSelection:setFillColor(1.0, 1.0, 1.0, 0);
			scene.objectSelection.selectedObject = self;

			self._hasFocus = false;
		end
	end

	return true;
end

return Stamp;