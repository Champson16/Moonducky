local FRC_PinchLib = {}
local private = {}

local FRC_MathLib = require('FRC_Modules.FRC_MathLib.FRC_MathLib');

-- requires a collection of touch points
-- each point must have '.id' to be tracked otherwise it will be ignored
-- each point must be in world coordinates (default state of touch event coordinates)
function FRC_PinchLib.doPinchZoom( img, points, suppressRotation, suppressScaling, suppressTranslation )
   suppressTranslation = suppressTranslation or false

   -- must have an image to manipulate
   if (not img) then
      return
   end
   
   local goodPointList = true
   if( points and #points > 0) then
      for i = 1, #points do
         if( not points[i] or not points[i].x or not points[i].y ) then
            goodPointList = false
         end
      end
   end
   if( not goodPointList ) then
      img.__pinchZoomData = nil
      return
   end

   -- is this the end of the pinch?
   if (not points or not img.__pinchZoomData or #points ~= #img.__pinchZoomData.points) then
      -- reset data (when #points changes)
      img.__pinchZoomData = nil

      -- exit if there are no calculations to do
      if (not points or #points == 0) then
         return -- nothing to do
      end
   end

   -- get local ref to zoom data
   local oldData = img.__pinchZoomData

   -- create newData table
   local newData = {}

   -- store img x,y in world coordinates
   newData.imgPos = private.getImgPos( img )

   -- calc centre (build list of points for later - avoids storing actual event objects passed in)
   newData.centre, newData.points = private.getCentrePoints( points )

   -- calc distances and angles from centre point
   private.calcDistancesAndAngles( newData )

   -- does pinching need to be performed?
   if (oldData) then
      -- translation of centre
      newData.imgPos.x = newData.imgPos.x + newData.centre.x - oldData.centre.x
      newData.imgPos.y = newData.imgPos.y + newData.centre.y - oldData.centre.y

      -- get scaling factor and rotation difference
      if (#newData.points > 1) then
         newData.scaleFactor, newData.rotation = private.calcScaleAndRotation( oldData, newData )
         if (suppressScaling) then newData.scaleFactor = 1 end
         if (suppressRotation) then newData.rotation = 0 end
      else
         newData.scaleFactor, newData.rotation = 1, 0
      end

      -- scale around pinch centre (translation)
      newData.imgPos.x = newData.centre.x + ((newData.imgPos.x - newData.centre.x) * newData.scaleFactor)
      newData.imgPos.y = newData.centre.y + ((newData.imgPos.y - newData.centre.y) * newData.scaleFactor)

      -- rotate around pinch centre
      newData.imgPos = FRC_MathLib.rotateAboutPoint( newData.imgPos, newData.centre, newData.rotation, false )

      -- convert to local coordinates
      local x, y = img.parent:contentToLocal( newData.imgPos.x, newData.imgPos.y )

      -- apply pinch...
      if (not suppressTranslation) then img.x, img.y = x, y end
      img.rotation = img.rotation + newData.rotation
      if (img.minSize) then
         if (((img.width * (img.xScale * newData.scaleFactor)) <= img.minSize) or ((img.height * (img.yScale * newData.scaleFactor)) <= img.minSize)) then
            newData.scaleFactor = 1;
         end
      end

      if (img.maxSize) then
         if (((img.width * (img.xScale * newData.scaleFactor)) >= img.maxSize) or ((img.height * (img.yScale * newData.scaleFactor)) >= img.maxSize)) then
            newData.scaleFactor = 1;
         end
      end
      img.xScale, img.yScale = img.xScale * newData.scaleFactor, img.yScale * newData.scaleFactor;
   end

   -- store new data
   img.__pinchZoomData = newData
end

-- simply converts the display object's centre x,y into world coordinates
function private.getImgPos( img )
   local x, y = img:localToContent( 0, 0 )
   return { x=x, y=y }
end

-- calculates the centre of the points
-- generates a new list of points so we are not storing the list of events from calling code
function private.getCentrePoints( points )
   local x, y = 0, 0
   local newPoints = {}

   for i=1, #points do
      -- accumulate the centre values
      x = x + points[i].x
      y = y + points[i].y

      -- record the point with it's associated data
      newPoints[#newPoints+1] = { x=points[i].x, y=points[i].y, id=points[i].id }
   end

   -- return the list of points for next time and the centre point of this list
   return
   { x = x / #points, y = y / #points }, -- centre
   newPoints -- list of points
end

-- calculates the distance from the centre to each point and their angle if the centre is assumed to be 0,0
function private.calcDistancesAndAngles( data )
   for i=1, #data.points do
      data.points[i].length = FRC_MathLib.lengthOf( data.centre, data.points[i] )
      data.points[i].angle = FRC_MathLib.angleBetweenPoints( data.centre, data.points[i] )
   end
end

-- calculates the change in scale between the old and new points
-- also calculates the change in rotation around the centre point
-- uses their average change
function private.calcScaleAndRotation( oldData, newData )
   local scaleDiff, angleDiff = 0, 0

   for i=1, #newData.points do
      local oldPoint = private.getPointById( newData.points[i], oldData.points )

      scaleDiff = scaleDiff + newData.points[i].length / oldPoint.length
      angleDiff = angleDiff + FRC_MathLib.smallestAngleDiff(newData.points[i].angle, oldPoint.angle)
   end

   return
   scaleDiff / #newData.points, -- scale factor
   angleDiff / #newData.points -- rotation average
end

-- returns the newPoint if it does not have a previous version, or the old point if it has simply moved
function private.getPointById( newPoint, points )
   for i=1, #points do
      if (points[i].id == newPoint.id) then
         return points[i]
      end
   end
   return newPoint
end



----[[
--local SELECTION_COLOR = UI('SELECTION_COLOR') or { 0, 0.5, 1.0 };
--local STAMP_MIN_SIZE = UI('STAMP_MIN_SIZE') or 88;
--local STAMP_MAX_SCALE = UI('STAMP_MAX_SCALE') or 2;
--local STAMP_SELECTION_PADDING = UI('STAMP_SELECTION_PADDING') or 5;

--EDO
--[[
function FRC_PinchLib.onProxyPinch( self, event )
   event.target = self.target
   return FRC_PinchLib.onPinch( event )   
end
--]]

function FRC_PinchLib.onPinch( event )
   -- A bit of a cheat, but keeps the definition in ONE PLACE
   local FRC_ArtCenter_Tool_Stamps = require "FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Tool_Stamps"
   local SELECTION_COLOR            = FRC_ArtCenter_Tool_Stamps.SELECTION_COLOR
   local STAMP_MIN_SIZE             = FRC_ArtCenter_Tool_Stamps.STAMP_MIN_SIZE
   local STAMP_MAX_SCALE            = FRC_ArtCenter_Tool_Stamps.STAMP_MAX_SCALE
   local STAMP_SELECTION_PADDING    = FRC_ArtCenter_Tool_Stamps.STAMP_SELECTION_PADDING

	local target = event.target;
	local scene = target._scene;
	local canvas = scene.canvas;
	if ((scene.mode == scene.modes.FREEHAND_DRAW) or (scene.mode == scene.modes.ERASE)) then
      dprint("FRC_PinchLib calling onPinch")
		event.name = 'onPinch';
		event.target = scene.canvas.layerBgColor;
		scene.canvas.onCanvasTouch(event);
		return false;
	end
	if (scene.mode ~= scene.modes[target.toolMode]) then return false; end

	local padding = STAMP_SELECTION_PADDING;

	if (event.phase == "began") then
		--EFM if (FRC_ArtCenter_Tool_Stamps.currentlyPinchingObject) then
			--EFM return true;
		--EFM end

		FRC_PinchLib.doPinchZoom( event.target, {} );
		FRC_PinchLib.doPinchZoom( event.target, event.list );

		target._hasFocus = true;
		target.markX = target.x;
		target.markY = target.y;
		target.minSize = STAMP_MIN_SIZE;
		target.maxSize = math.floor(((canvas.width * 0.5) + (canvas.height * 0.5)) * 0.5) * STAMP_MAX_SCALE;

		-- create object selection polygon
		if (scene.objectSelection and scene.objectSelection.removeSelf) then scene.objectSelection:removeSelf(); end
		scene.objectSelection = display.newRect(canvas.layerSelection, target.x - ((target.width * target.xScale) * 0.5) - padding, target.y - ((target.height * target.yScale) * 0.5) - padding, target.width * target.xScale + (padding * 2), target.height * target.yScale + (padding * 2));
		scene.objectSelection:setStrokeColor(SELECTION_COLOR[1], SELECTION_COLOR[2], SELECTION_COLOR[3]);
		scene.objectSelection.strokeWidth = 2;
		scene.objectSelection.stroke.effect = "generator.marchingAnts"
		scene.objectSelection:setFillColor(1.0, 1.0, 1.0, 0);
		scene.objectSelection.selectedObject = target;
		scene.objectSelection.rotation = target.rotation;
		scene.objectSelection.x = target.x;
		scene.objectSelection.y = target.y;
		scene.eraserGroup.button:setDisabledState(false);

		target:toFront();

	elseif (target._hasFocus) then
		if (event.phase == "moved") then

			FRC_PinchLib.doPinchZoom( event.target, event.list );

			if (scene.objectSelection) then
				scene.objectSelection.x = target.x;
				scene.objectSelection.y = target.y;
				scene.objectSelection.rotation = target.rotation;
				scene.objectSelection.isVisible = false;
				scene.eraserGroup.button:setDisabledState(true);
			end

			target.maskX, target.maskY = 0, 0;
			target.maskScaleX, target.maskScaleY = 1.0, 1.0;

			-- store reference to this stamp as well as the event data
			-- used for pinch-scaling this stamp with one finger on the canvas
			--EFM FRC_ArtCenter_Tool_Stamps.currentlyPinchingObject = target;
			FRC_ArtCenter_Tool_Stamps.initialTouchList = event.list[1];
		else
			FRC_PinchLib.doPinchZoom( event.target, {} );

			-- create object selection polygon
			if (scene.objectSelection and scene.objectSelection.removeSelf) then scene.objectSelection:removeSelf(); end
			scene.objectSelection = display.newRect(canvas.layerSelection, target.x - ((target.width * target.xScale) * 0.5) - padding, target.y - ((target.height * target.yScale) * 0.5) - padding, target.width * target.xScale + (padding * 2), target.height * target.yScale + (padding * 2));
			scene.objectSelection:setStrokeColor(SELECTION_COLOR[1], SELECTION_COLOR[2], SELECTION_COLOR[3]);
			scene.objectSelection.strokeWidth = 2;
			scene.objectSelection.stroke.effect = "generator.marchingAnts"
			scene.objectSelection:setFillColor(1.0, 1.0, 1.0, 0);
			scene.objectSelection.selectedObject = target;
			scene.objectSelection.rotation = target.rotation;
			scene.objectSelection.x = target.x;
			scene.objectSelection.y = target.y;
			scene.eraserGroup.button:setDisabledState(false);

			target._hasFocus = false;

			-- free references
			--EFM FRC_ArtCenter_Tool_Stamps.currentlyPinchingObject = nil;
			FRC_ArtCenter_Tool_Stamps.initialTouchList = nil;
		end
	elseif (event.phase == "moved") then
		-- touched object does not have focus; pass event onto canvas
		-- this occurs when another finger initiated the touch on a different stamp
		-- prior to this event occurring -- this allows the stamp in focus to be pinch-scaled
		-- even if the other finger is on top of another shape/stamp
		FRC_ArtCenter_Tool_Stamps.onCanvasTouch(canvas, event);
	end

	return true;
end
--]]


return FRC_PinchLib
