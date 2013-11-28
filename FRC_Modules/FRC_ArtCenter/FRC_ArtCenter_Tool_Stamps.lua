local FRC_ArtCenter_Scene = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Scene');
local math_random = math.random;
local math_floor = math.floor;
local math_sqrt = math.sqrt;
local math_abs = math.abs;

local FRC_ArtCenter_Tool_Stamps = {};

local SELECTION_COLOR = { 0, 0.5, 1.0 };
local MIN_STAMP_SIZE = 88;
local STAMP_SELECTION_PADDING = 5;

FRC_ArtCenter_Tool_Stamps.SELECTION_COLOR = SELECTION_COLOR;

FRC_ArtCenter_Tool_Stamps.onCanvasTouch = function(self, event)
	local scene = FRC_ArtCenter_Scene;

	if (event.phase == "began") then
		if (scene.objectSelection) then
			scene.objectSelection:removeSelf();
			scene.objectSelection = nil;
			scene.eraserGroup.button:setDisabledState(true);
		end
	end

	return true;
end

FRC_ArtCenter_Tool_Stamps.onStampPinch = function(e)
	local self = e.target;
	local scene = self._scene;
	local canvas = scene.canvas;
	if ((scene.mode == scene.modes.FREEHAND_DRAW) or (scene.mode == scene.modes.ERASE)) then
		e.name = 'multitouch';
		e.target = scene.canvas.layerBgColor;
		scene.canvas.onCanvasTouch(e);
		return false;
	end
	if (scene.mode ~= scene.modes[self.toolMode]) then return false; end

	local padding = STAMP_SELECTION_PADDING;

	if (e.phase == "began") then
		doPinchZoom( e.target, {} );
		doPinchZoom( e.target, e.list );

		self._hasFocus = true;
		self.markX = self.x;
		self.markY = self.y;
		self.minSize = MIN_STAMP_SIZE;
		self.maxSize = math.floor(((canvas.width * 0.5) + (canvas.height * 0.5)) * 0.5) * 2;

		-- create object selection polygon
		if (scene.objectSelection) then scene.objectSelection:removeSelf(); end
		scene.objectSelection = display.newRect(canvas.layerSelection, self.x - ((self.width * self.xScale) * 0.5) - padding, self.y - ((self.height * self.yScale) * 0.5) - padding, self.width * self.xScale + (padding * 2), self.height * self.yScale + (padding * 2));
		scene.objectSelection:setStrokeColor(SELECTION_COLOR[1], SELECTION_COLOR[2], SELECTION_COLOR[3]);
		scene.objectSelection.strokeWidth = 2;
		scene.objectSelection.stroke.effect = "generator.marchingAnts"
		scene.objectSelection:setFillColor(1.0, 1.0, 1.0, 0);
		scene.objectSelection.selectedObject = self;
		scene.objectSelection.rotation = self.rotation;
		scene.objectSelection.x = self.x;
		scene.objectSelection.y = self.y;
		scene.eraserGroup.button:setDisabledState(false);

		self:toFront();

	elseif (self._hasFocus) then
		if (e.phase == "moved") then
			
			doPinchZoom( e.target, e.list );

			if (scene.objectSelection) then
				scene.objectSelection.x = self.x;
				scene.objectSelection.y = self.y;
				scene.objectSelection.rotation = self.rotation;
				scene.objectSelection.isVisible = false;
				scene.eraserGroup.button:setDisabledState(true);
			end
		else
			doPinchZoom( e.target, {} );
			
			-- create object selection polygon
			if (scene.objectSelection) then scene.objectSelection:removeSelf(); end
			scene.objectSelection = display.newRect(canvas.layerSelection, self.x - ((self.width * self.xScale) * 0.5) - padding, self.y - ((self.height * self.yScale) * 0.5) - padding, self.width * self.xScale + (padding * 2), self.height * self.yScale + (padding * 2));
			scene.objectSelection:setStrokeColor(SELECTION_COLOR[1], SELECTION_COLOR[2], SELECTION_COLOR[3]);
			scene.objectSelection.strokeWidth = 2;
			scene.objectSelection.stroke.effect = "generator.marchingAnts"
			scene.objectSelection:setFillColor(1.0, 1.0, 1.0, 0);
			scene.objectSelection.selectedObject = self;
			scene.objectSelection.rotation = self.rotation;
			scene.objectSelection.x = self.x;
			scene.objectSelection.y = self.y;
			scene.eraserGroup.button:setDisabledState(false);

			self._hasFocus = false;
		end
	end

	return true;
end

return FRC_ArtCenter_Tool_Stamps;