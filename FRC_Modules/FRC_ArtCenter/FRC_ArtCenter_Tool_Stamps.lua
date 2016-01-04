-- version 09252014

local FRC_ArtCenter_Scene = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Scene');
local FRC_ArtCenter_Settings = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Settings');
local FRC_PinchLib = require "FRC_Modules.FRC_MultiTouch.FRC_PinchLib"
local math_random = math.random;
local math_floor = math.floor;
local math_sqrt = math.sqrt;
local math_abs = math.abs;

local FRC_ArtCenter_Tool_Stamps = {};

local function UI(key)
	return FRC_ArtCenter_Settings.UI[key];
end

-- Define these here, but make them visible elsewhere via (late) require of this module.
local SELECTION_COLOR = UI('SELECTION_COLOR') or { 0, 0.5, 1.0 };
local STAMP_MIN_SIZE = UI('STAMP_MIN_SIZE') or 88;
local STAMP_MAX_SCALE = UI('STAMP_MAX_SCALE') or 2;
local STAMP_SELECTION_PADDING = UI('STAMP_SELECTION_PADDING') or 5;
FRC_ArtCenter_Tool_Stamps.SELECTION_COLOR          = SELECTION_COLOR;
FRC_ArtCenter_Tool_Stamps.STAMP_MIN_SIZE           = STAMP_MIN_SIZE;
FRC_ArtCenter_Tool_Stamps.STAMP_MAX_SCALE          = STAMP_MAX_SCALE;
FRC_ArtCenter_Tool_Stamps.STAMP_SELECTION_PADDING  = STAMP_SELECTION_PADDING;

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
      --EFM 
      --[[
		if (event.list and FRC_ArtCenter_Tool_Stamps.currentlyPinchingObject and FRC_ArtCenter_Tool_Stamps.initialTouchList) then
			local list = {};
			list[1] = FRC_ArtCenter_Tool_Stamps.initialTouchList;
			list[2] = event.list[1];
			FRC_PinchLib.doPinchZoom(FRC_ArtCenter_Tool_Stamps.currentlyPinchingObject, list);
		end
      --]]
	end

	return true;
end

FRC_ArtCenter_Tool_Stamps.onPinch =  FRC_PinchLib.onPinch

return FRC_ArtCenter_Tool_Stamps;
