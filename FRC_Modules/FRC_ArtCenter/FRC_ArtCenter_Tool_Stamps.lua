-- version 09252014

local FRC_ArtCenter_Scene = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Scene');
local FRC_ArtCenter_Settings = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Settings');
local math_random = math.random;
local math_floor = math.floor;
local math_sqrt = math.sqrt;
local math_abs = math.abs;

local FRC_ArtCenter_Tool_Stamps = {};

local function UI(key)
	return FRC_ArtCenter_Settings.UI[key];
end

local SELECTION_COLOR = UI('SELECTION_COLOR') or { 0, 0.5, 1.0 };
local STAMP_MIN_SIZE = UI('STAMP_MIN_SIZE') or 88;
local STAMP_MAX_SCALE = UI('STAMP_MAX_SCALE') or 2;
local STAMP_SELECTION_PADDING = UI('STAMP_SELECTION_PADDING') or 5;


FRC_ArtCenter_Tool_Stamps.SELECTION_COLOR = SELECTION_COLOR;

FRC_ArtCenter_Tool_Stamps.onCanvasTouch = function(self, event)
	local scene = FRC_ArtCenter_Scene;

	if (event.phase == "began") then
		if (scene.objectSelection and scene.objectSelection.removeSelf) then
			scene.objectSelection:removeSelf();
			scene.objectSelection = nil;
			scene.eraserGroup.button:setDisabledState(true);
		end
	elseif (event.phase == "moved") then
		-- enable pinch-scaling when one finger is on a shape/stamp and the other on the canvas
		if (event.list and FRC_ArtCenter_Tool_Stamps.currentlyPinchingObject and FRC_ArtCenter_Tool_Stamps.initialTouchList) then
			local list = {};
			list[1] = FRC_ArtCenter_Tool_Stamps.initialTouchList;
			list[2] = event.list[1];
			doPinchZoom(FRC_ArtCenter_Tool_Stamps.currentlyPinchingObject, list);
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
		if (FRC_ArtCenter_Tool_Stamps.currentlyPinchingObject) then
			return true;
		end

		doPinchZoom( e.target, {} );
		doPinchZoom( e.target, e.list );

		self._hasFocus = true;
		self.markX = self.x;
		self.markY = self.y;
		self.minSize = STAMP_MIN_SIZE;
		self.maxSize = math.floor(((canvas.width * 0.5) + (canvas.height * 0.5)) * 0.5) * STAMP_MAX_SCALE;

		-- create object selection polygon
		if (scene.objectSelection and scene.objectSelection.removeSelf) then scene.objectSelection:removeSelf(); end
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

			self.maskX, self.maskY = 0, 0;
			self.maskScaleX, self.maskScaleY = 1.0, 1.0;

			-- store reference to this stamp as well as the event data
			-- used for pinch-scaling this stamp with one finger on the canvas
			FRC_ArtCenter_Tool_Stamps.currentlyPinchingObject = self;
			FRC_ArtCenter_Tool_Stamps.initialTouchList = e.list[1];
		else
			doPinchZoom( e.target, {} );

			-- create object selection polygon
			if (scene.objectSelection and scene.objectSelection.removeSelf) then scene.objectSelection:removeSelf(); end
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

			-- free references
			FRC_ArtCenter_Tool_Stamps.currentlyPinchingObject = nil;
			FRC_ArtCenter_Tool_Stamps.initialTouchList = nil;
		end
	elseif (e.phase == "moved") then
		-- touched object does not have focus; pass event onto canvas
		-- this occurs when another finger initiated the touch on a different stamp
		-- prior to this event occurring -- this allows the stamp in focus to be pinch-scaled
		-- even if the other finger is on top of another shape/stamp
		FRC_ArtCenter_Tool_Stamps.onCanvasTouch(canvas, e);
	end

	return true;
end

return FRC_ArtCenter_Tool_Stamps;
