local math_random = math.random;
local math_floor = math.floor;
local math_sqrt = math.sqrt;
local math_abs = math.abs;
local BezierCurve = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_BezierCurve');
local FRC_ArtCenter_Tool_FreehandDraw = {};

local bezier = {};
local points = {};

FRC_ArtCenter_Tool_FreehandDraw.graphic = {
	image = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_FreehandPaintBasic_Brush_PaintBrush1.png',
	width = 40,
	height = 40
};

FRC_ArtCenter_Tool_FreehandDraw.r = 1.0;
FRC_ArtCenter_Tool_FreehandDraw.g = 0;
FRC_ArtCenter_Tool_FreehandDraw.b = 0;
FRC_ArtCenter_Tool_FreehandDraw.a = 0.05;

FRC_ArtCenter_Tool_FreehandDraw.arbRotate = true;

-- Returns square distance (faster than regular distance)
local function squareDistance(pointA, pointB)
	local dx = pointA.x - pointB.x
	local dy = pointA.y - pointB.y
	return dx*dx + dy*dy
end

-- Returns distance between two points
local function distance(pointA, pointB)
	return math.sqrt(squareDistance(pointA, pointB))
end

-- Returns perpendicular distance from point p0 to line defined by p1,p2
local function perpendicularDistance(p0, p1, p2)
	if (p1.x == p2.x) then
		return math.abs(p0.x - p1.x)
	end
	local m = (p2.y - p1.y) / (p2.x - p1.x) --slope
	local b = p1.y - m * p1.x --offset
	local dist = math.abs(p0.y - m * p0.x - b)
	dist = dist / math.sqrt(m*m + 1)
	return dist
end

-- Returns a normalized vector
local function normalizeVector(v)
	local magnitude = distance({x = 0, y = 0}, v)
	return {x = v.x/magnitude, y = v.y/magnitude}
end

-- Simplifies the path by eliminating points that are too close
local function polySimplify(tolerance)
	local newPoints = {}
	table.insert(newPoints, points[1])
	local lastPoint = points[1]
	
	local squareTolerance = tolerance*tolerance
	for i = 2, #points do
		if (squareDistance(points[i], lastPoint) >= squareTolerance) then
			table.insert(newPoints, points[i])
			lastPoint = points[i]
		end
	end
	points = newPoints
	hasMoved = true
end

-- Algorithm to simplify a curve and keep major curve points
local function DouglasPeucker(pts, epsilon)
	--Find the point with the maximum distance
	local dmax = 0
	local index = 0
	for i = 3, #pts do 
		d = perpendicularDistance(pts[i], pts[1], pts[#pts])
		if d > dmax then
			index = i
			dmax = d
		end
	end
	
	local results = {}
	
	--If max distance is greater than epsilon, recursively simplify
	if dmax >= epsilon then
		--Recursive call
		local tempPts = {}
		for i = 1, index-1 do table.insert(tempPts, pts[i]) end
		local results1 = DouglasPeucker(tempPts, epsilon)
		
		local tempPts = {}
		for i = index, #pts do table.insert(tempPts, pts[i]) end
		local results2 = DouglasPeucker(tempPts, epsilon)

		-- Build the result list
		for i = 1, #results1-1 do table.insert(results, results1[i]) end
		for i = 1, #results2 do table.insert(results, results2[i]) end
	else
		for i = 1, #pts do table.insert(results, pts[i]) end
	end
	
	--Return the result
	return results
end

-- Creates a bezier path that crosses through all points
local function bezierInterpolation(ssGroup, isErase)
	local p = points
	if (#p < 2) then return true end
	
	local scale = 0.3
	local c = {}
	
	for i = 1, #p do
		if (i == 1) then
			local scale = scale * 10
			local tangent = {x = p[2].x - p[1].x, y = p[2].y - p[1].y}
			local nT = normalizeVector(tangent)
			local c1 = {x = p[1].x + scale * nT.x, y = p[1].y + scale * nT.y}
			table.insert(c, p[1])
			table.insert(c, c1)
		elseif (i == #p) then
			local scale = scale * 10
			local tangent = {x = p[#p].x - p[#p-1].x, y = p[#p].y - p[#p-1].y}
			local nT = normalizeVector(tangent)
			local c2 = {x = p[#p].x - scale * nT.x, y = p[#p].y - scale * nT.y}
			table.insert(c, p[#p])
			table.insert(c, c2)
		else
			local tangent = {x = p[i+1].x - p[i-1].x, y = p[i+1].y - p[i-1].y}
			local nT = normalizeVector(tangent)
			local dist1 = distance(p[i-1],p[i])
			local dist2 = distance(p[i],p[i+1])
			local c1 = {x = p[i].x - scale * nT.x * dist1, y = p[i].y - scale * nT.y * dist1}
			local c2 = {x = p[i].x + scale * nT.x * dist2, y = p[i].y + scale * nT.y * dist2}
			table.insert(c, p[i])
			table.insert(c, c1)
			table.insert(c, p[i])
			table.insert(c, c2)
		end
	end
	
	if (not isErase) then
		BezierCurve.imageFile = FRC_ArtCenter_Tool_FreehandDraw.graphic.image;
		BezierCurve.blotColor[1] = FRC_ArtCenter_Tool_FreehandDraw.r;
		BezierCurve.blotColor[2] = FRC_ArtCenter_Tool_FreehandDraw.g;
		BezierCurve.blotColor[3] = FRC_ArtCenter_Tool_FreehandDraw.b;
		BezierCurve.blotColor[4] = FRC_ArtCenter_Tool_FreehandDraw.a;
	else
		BezierCurve.imageFile = nil;
		BezierCurve.blotColor[1] = 1.0;
		BezierCurve.blotColor[2] = 0;
		BezierCurve.blotColor[3] = 1.0;
		BezierCurve.blotColor[4] = 1.0;
	end
	BezierCurve.blotWidth = FRC_ArtCenter_Tool_FreehandDraw.graphic.width;
	BezierCurve.blotHeight = FRC_ArtCenter_Tool_FreehandDraw.graphic.height;
	if ((BezierCurve.blotWidth % 4) ~= 0) then
		BezierCurve.blotWidth = BezierCurve.blotWidth - (BezierCurve.blotWidth % 4);
	end
	if ((BezierCurve.blotHeight % 4) ~= 0) then
		BezierCurve.blotHeight = BezierCurve.blotHeight - (BezierCurve.blotHeight % 4);
	end

	local actualWidth = BezierCurve.blotWidth + (BezierCurve.blotWidth * display.contentScaleX);
	local actualHeight = BezierCurve.blotHeight + (BezierCurve.blotHeight * display.contentScaleY);

	if ((actualWidth % 4) ~= 0) then
		BezierCurve.blotWidth = actualWidth - (actualWidth % 4);
	end
	if ((actualHeight % 4) ~= 0) then
		BezierCurve.blotHeight = actualHeight - (actualHeight % 4);
	end
	
	for i = 1, #c, 4 do
		local bezier = BezierCurve.new(ssGroup.canvas, c[i], c[i+1], c[i+2], c[i+3], FRC_ArtCenter_Tool_FreehandDraw.arbRotate);
	end
	ssGroup:invalidate('canvas');
end

FRC_ArtCenter_Tool_FreehandDraw.onCanvasTouch = function(self, e)
	if (not FRC_ArtCenter_Tool_FreehandDraw.graphic.image) then return; end
	-- if (self.isProcessingErase) then return; end
	
	local event = {};
	for k,v in pairs(e) do
		event[k] = v;
	end

	event.x = event.x - self.parent.x;
	event.y = event.y - self.parent.y;
	
	if ((event.phase == "began") or (event.phase == "moved")) then
		local scene = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Scene');
		if (_G.ANDROID_DEVICE and scene.canvas.freehandSaveTimer) then
			pcall(function() timer.cancel(scene.canvas.freehandSaveTimer); scene.canvas.freehandSaveTimer = nil; end);
		end
		local point = {x = event.x, y = event.y };
		table.insert(points, point);
		hasMoved = true;

		if (#points >= 4) then
			polySimplify(5);
			bezierInterpolation(self.parent.layerDrawing, (scene.mode == scene.modes.ERASE));

			local x, y = points[#points].x, points[#points].y;
			points = {{x=x, y=y}};
		end

	else
		-- on Android, call display.save() on the freehand draw layer after 1 second of inactivity
		if (event.phase == "ended" and _G.ANDROID_DEVICE) then
			local canvas = require("FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Scene").canvas;
			if (canvas.freehandSaveTimer) then
				pcall(function() timer.cancel(canvas.freehandSaveTimer); end);
			end
			canvas.freehandSaveTimer = timer.performWithDelay(1000, function()
				if (canvas.layerDrawing and canvas.layerDrawing.invalidate) then
					canvas.layerDrawing:invalidate("canvas");
				end
				timer.performWithDelay(1, function()
					canvas.freehandTempSaved = true;
					display.save(canvas.layerDrawing, "temp_freehandsave.png", system.DocumentsDirectory);
				end, 1);
			end, 1);
		end
		points = {};
	end
end

return FRC_ArtCenter_Tool_FreehandDraw;