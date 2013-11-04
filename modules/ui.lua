-- ui widgets for Corona graphics 2.x engine (not compatible with 1.x)

local math_abs = math.abs;
local ui = {};
ui.scrollers = {};

local function removeScroller(scroller)
	for i=#ui.scrollers,1,-1 do
		if (ui.scrollers[i] == scroller) then
			table.remove(ui.scrollers, i);
		end
	end
end

-- checkoptions.callee should be set before calling any other method
local checkoptions = {};
checkoptions.callee = ''; -- name of function calling a checkoptions method

-- adds Corona 'DisplayObject' to Lua type() function
local cached_type = type;
type = function(obj)
	if ((cached_type(obj) == 'table') and (obj._class) and (obj._class.addEventListener)) then
		return "DisplayObject";
	else
		return cached_type(obj);
	end
end

-- check for required options; sets defaults
checkoptions.check = function(options, required, defaults)
	assert(options);
	assert(required);
	assert(defaults);

	if (required) then
		for k,v in pairs(required) do
			-- check for all required options
			assert(options[k], 'Missing Option: \'' .. k .. '\' is a required option for \'' .. checkoptions.callee .. '\'');

			-- ensure option is the proper type
			assert(type(options[k]) == v, 'Type Error: option' .. '\'' .. k .. '\' in \'' .. checkoptions.callee .. '\' must be a ' .. v);
		end
	end

	-- check options table for default keys (if key is not present, use default)
	if (defaults) then
		for k,v in pairs(defaults) do
			if (options[k] == nil) then
				options[k] = v;
			end
		end
	end

	return options;
end

--- ui.button
-- Simple button with up and down states.
ui.button = {};
ui.button.required = {
	--imageUp = "string",
	--imageDown = "string",
	width = "number",
	height = "number"
};
ui.button.defaults = {
	x = 0,
	y = 0,
	pressAlpha = 1.0,
	bgColor = { 1.0, 1.0, 1.0, 0 }
};

ui.button.new = function(args)
	checkoptions.callee = 'ui.button.new';

	local onPress, onRelease;
	if (args) then
		if (args.default) then
			args.imageUp = args.default;
		end

		if (args.over) then
			args.imageDown = args.over;
		end

		if ((args.left) and (args.width)) then
			args.x = args.left;
		end

		if ((args.top) and (args.height)) then
			args.y = args.top;
		end

		if (args.onPress) then
			onPress = args.onPress;
		end

		if (args.onRelease) then
			onRelease = args.onRelease;
		end
	end

	local options = checkoptions.check(args, ui.button.required, ui.button.defaults);

	local view = display.newContainer(options.width, options.height);
	view._uiType = 'button';
	view.id = options.id or '';

	view.bg = display.newRect(-(options.width * 0.5), -(options.height * 0.5), options.width, options.height);
	view.bg:setFillColor(options.bgColor[1], options.bgColor[2], options.bgColor[3], options.bgColor[4] or 0);
	view:insert(view.bg, true);

	if (options.imageUp) then
		view.up = display.newImageRect(options.imageUp, options.width, options.height);
	elseif (options.shapeUp) then
		options.width = options.width - 10;
		options.height = options.height - 10;

		local vertices = {};
		for i=1,#options.shapeUp do
			if ((i % 2) == 0) then
				table.insert(vertices, options.shapeUp[i] * (options.height * 0.5));
			else
				table.insert(vertices, options.shapeUp[i] * (options.width * 0.5));
			end
		end
		if (#vertices > 1) then
			view.up = display.newPolygon(0, 0, vertices);
		else
			view.up = display.newCircle(0, 0, options.width * 0.5);
		end
		view.up:setFillColor(1.0, 1.0, 1.0, 0);
		view.up:setStrokeColor(1.0, 1.0, 1.0, 1.0);
		view.up.strokeWidth = 5;
		view.up.isHitTestable = true;
	end
	view:insert(view.up, true);

	if (options.imageDown) then
		view.down = display.newImageRect(options.imageDown, options.width, options.height);
	elseif (options.shapeDown) then
		options.width = options.width - 10;
		options.height = options.height - 10;

		local vertices = {};
		for i=1,#options.shapeDown do
			if ((i % 2) == 0) then
				table.insert(vertices, options.shapeDown[i] * (options.height * 0.5));
			else
				table.insert(vertices, options.shapeDown[i] * (options.width * 0.5));
			end
		end
		if (#vertices > 1) then
			view.down = display.newPolygon(0, 0, vertices);
		else
			view.down = display.newCircle(0, 0, options.width);
		end
		view.down:setFillColor(1.0, 1.0, 1.0, 0);
		view.down:setStrokeColor(0, 0, 0, 1.0);
		view.down.strokeWidth = 5;
		view.down.isHitTestable = true;
	end

	view.down.isVisible = false;
	view:insert(view.down, true);

	-- add button touch listener to handle up/down state switching
	view:addEventListener("touch", ui.button.touch);

	-- public properties and methods
	view.press = ui.button.press;
	view.release = ui.button.release;
	view.dispose = ui.button.dispose;
	view.x = options.x;
	view.y = options.y;
	view.pressAlpha = options.pressAlpha;

	if (onPress) then
		view:addEventListener('press', onPress);
	end

	if (onRelease) then
		view:addEventListener('release', onRelease);
	end

	return view;
end

ui.newButton = ui.button.new;

ui.button.touch = function(event)
	local self = event.target;
	local bounds = self.contentBounds;
	local isWithinBounds = bounds.xMin <= event.x and bounds.xMax >= event.x and bounds.yMin <= event.y and bounds.yMax >= event.y;

	if (event.phase == "began") then
		self._startX = event.x;
		self._startY = event.y;
		self._touchTimer = timer.performWithDelay(10, function()
			if (not self._proxy) then
				self._touchTimer = nil;
				for k,v in pairs(self) do
					self[k] = nil;
				end
				display.getCurrentStage():setFocus(nil);
				return;
			end
			display.getCurrentStage():setFocus(self);
			self:press();
			self._hasFocus = true;
			self._touchTimer = nil;
			self:dispatchEvent({
				name = "press",
				target = self,
				x = event.x,
				y = event.y
			});
		end, 1);

		return true;

	elseif (self._hasFocus) then
		if (event.phase == "moved") then
			if ((not self._startX) or (not self._startY)) then return true; end
			-- handle case where user pressed the button, but then begins to drag a scroller
			local dx = math_abs(event.x - self._startX);
			local dy = math_abs(event.y - self._startY);
			local thresh = 10;
			local eventPassedToScroller;
			if ((dx < thresh) and (dy < thresh)) then
				if (isWithinBounds) then
					self:press();
				else
					self:release();
					self:dispatchEvent({
						name = "pressoutside",
						target = self,
						x = event.x,
						y = event.y
					});
				end
			else
				if (self._touchTimer) then
					timer.cancel(self._touchTimer);
					self._touchTimer = nil;
				end

				for i=#ui.scrollers,1,-1 do
					local scrollerBounds = ui.scrollers[i].contentBounds;
					local isWithinScroller = scrollerBounds.xMin <= event.x and scrollerBounds.xMax >= event.x and scrollerBounds.yMin <= event.y and scrollerBounds.yMax >= event.y;
					if ((isWithinScroller) and (ui.scrollers[i].isVisible)) then
						eventPassedToScroller = true;
						ui.scrollers[i]:_focusTouch(event);
						break;
					end
				end
				if (eventPassedToScroller) then
					return false;
				end
			end

		elseif ((event.phase == "ended") or (event.phase == "cancelled")) then
			if (self._touchTimer) then
				timer.cancel(self._touchTimer);
				self._touchTimer = nil;
			end

			if (isWithinBounds) then
				self:dispatchEvent({
					name = "release",
					target = self,
					x = event.x,
					y = event.y
				});
			else
				self:dispatchEvent({
					name = "releaseoutside",
					target = self,
					x = event.x,
					y = event.y
				});
			end

			self:release();
			display.getCurrentStage():setFocus(nil);
			self._hasFocus = false;
		end
		return true;
	elseif ((event.phase == "moved") and(self._startX) and (self._startY)) then
		-- simple touches can sometimes caused "moved" phase to occur due to sensitive touch screens,
		-- so ensure finger moved at least a few pixelsfrom start of touch location to consider it moved
		local dx = math_abs(event.x - self._startX);
		local dy = math_abs(event.y - self._startY);
		local thresh = 3;
		if ((dx >= thresh) or (dy >= thresh)) then
			if (self._touchTimer) then
				timer.cancel(self._touchTimer);
				self._touchTimer = nil;
			end

			for i=#ui.scrollers,1,-1 do
				local scrollerBounds = ui.scrollers[i].contentBounds;
				local isWithinScroller = scrollerBounds.xMin <= event.x and scrollerBounds.xMax >= event.x and scrollerBounds.yMin <= event.y and scrollerBounds.yMax >= event.y;
				if (isWithinScroller) then
					ui.scrollers[i]:_focusTouch(event);
					break;
				end
			end
			display.getCurrentStage():setFocus(nil);
			self._hasFocus = false;
			return false;
		end
	else
		if (self._touchTimer) then
			timer.cancel(self._touchTimer);
			self._touchTimer = nil;
		end
		display.getCurrentStage():setFocus(nil);
		self._hasFocus = false;
		return false;		
	end
	return true;
end

ui.button.release = function(self, callback)
	self.up.isVisible = true;
	self.down.isVisible = false;
	self.bg.isVisible = true;
	self.bg.alpha = 1.0;

	if ((callback) and (type(callback) == "function")) then
		callback();
	end
end

ui.button.press = function(self, callback)
	self.up.isVisible = false;
	self.down.isVisible = true;
	self.down.alpha = self.pressAlpha;
	self.bg.alpha = self.pressAlpha;

	if ((callback) and (type(callback) == "function")) then
		callback();
	end
end

ui.button.dispose = function(self)
	if (self._hasFocus) then display.getCurrentStage():setFocus(nil); end
	self:removeEventListener("touch", ui.button.touch);

	if (self._touchTimer) then
		timer.cancel(self._touchTimer);
		self._touchTimer = nil;
	end

	if (self.up) then
		self.up:removeSelf();
		self.up = nil;
	end

	if (self.down) then
		self.down:removeSelf();
		self.down = nil;
	end

	self:removeSelf();
end

--- ui.scroller
-- Scrollable container.
ui.scroller = {};
ui.scroller.required = {
	width = "number",
	height = "number"
};
ui.scroller.defaults = {
	x = 0,
	y = 0,
	scrollLock = false,
	xScroll = true,
	yScroll = true
};

ui.scroller.new = function(args)
	checkoptions.callee = 'ui.scroller.new';
	local options = checkoptions.check(args, ui.scroller.required, ui.scroller.defaults);

	local view = display.newContainer(options.width, options.height);
	view.anchorChildren = true;
	view._uiType = 'scroller';

	-- if bgColor option is set, create a rectangle and insert directly into container (behind content group)
	if ((options.bgColor) and (type(options.bgColor) == "table") and (#options.bgColor == 3)) then
		local bg = display.newRect(-(options.width * 0.5), -(options.height * 0.5), options.width, options.height);
		bg:setFillColor(options.bgColor[1], options.bgColor[2], options.bgColor[3]);
		view:insert(bg, true);
	end

	view.body = display.newGroup();
	view.body.anchorChildren = true;
	view:insert(view.body, true);

	view.content = display.newGroup();
	view.content.anchorChildren = false;
	view.body:insert(view.content, true);

	-- override container's insert method to insert into 'content' group instead
	local cached_insert = view.insert;
	view.insert = function(self, displayObject)
		-- don't allow scrollers to be inserted into scrollers
		if (displayObject._uiType) then
			assert(displayObject._uiType ~= 'scroller', "Error: " .. "cannot insert a scroller object into another scroller.");
		end
		return self.content:insert(displayObject)
	end

	-- add scroller touch listener to handle scrolling
	view:addEventListener("touch", ui.scroller.touch);

	-- public properties and methods
	view.scrollToBounds = ui.scroller.scrollToBounds;
	view.positionChild = ui.scroller.positionChild;
	view.snapTop = ui.scroller.snapTop;
	view.snapBottom = ui.scroller.snapBottom;
	view.snapLeft = ui.scroller.snapLeft;
	view.snapRight = ui.scroller.snapRight;
	view.snapCenter = ui.scroller.snapCenter;
	view.snapCenterLeft = ui.scroller.snapCenterLeft;
	view.snapCenterRight = ui.scroller.snapCenterRight;
	view.snapTopLeft = ui.scroller.snapTopLeft;
	view.snapTopRight = ui.scroller.snapTopRight;
	view.snapTopCenter = ui.scroller.snapTopCenter;
	view.snapBottomLeft = ui.scroller.snapBottomLeft;
	view.snapBottomCenter = ui.scroller.snapBottomCenter;
	view.snapBottomRight = ui.scroller.snapBottomRight;
	view._focusTouch = ui.scroller._focusTouch;
	view.dispose = ui.scroller.dispose;
	view.x = options.x;
	view.y = options.y;

	-- scrolling properties
	view.scrollLock = options.scrollLock;
	view.xScroll = options.xScroll;
	view.yScroll = options.yScroll;
	view._trackingVelocity = false;
	view._prevTime = 0;
	view._markTime = 0;
	view._velocity = 0;
	view._friction = 0.935;
	view._moveDirection = nil; -- x: horizontal; y: vertical

	-- enterframe listener for view
	view.enterframe = function(event)
		-- make sure view object hasn't been removed (e.g. via parent group removal or other reason)
		if ((view) and (not view._proxy)) then
			Runtime:removeEventListener("enterframe", view.enterframe);
			removeScroller(view);
			for k,v in pairs(view) do
				view[k] = nil;
			end
			view = nil;
		end

		if ((not view._trackingVelocity) and (view._moveDirection)) then
			local time = event.time;
			local timePassed = time - view._prevTime;
			view._prevTime = time;

			-- handle scrolling based on velocity
			if (math_abs(view._velocity) >= 0.2) then
				view._velocity = view._velocity * view._friction;
				view.content[view._moveDirection] = view.content[view._moveDirection] + (view._velocity * timePassed);
				view:scrollToBounds();
			else
				-- scroller has stopped movement
				view:scrollToBounds();
				view._velocity = 0;
				view._moveDirection = nil;
				Runtime:removeEventListener("enterFrame", view.enterframe);
			end
		elseif (view._moveDirection) then
			-- user has their finger held down for more than 5 frames; stop movement
			if ((view._eventStepX == view.content.x) or (view._eventStepY == view.content.y)) then
				if (view._eventStep >= 5) then
					view._eventStepX = view.content.x;
					view._eventStepY = view.content.y;
					view._markX = view.content.x;
					view._markY = view.content.y;
					view._velocity = 0;
					view._eventStep = 0;
				else
					view._eventStep = view._eventStep + 1;
				end
			end
		end
	end

	table.insert(ui.scrollers, view);
	return view;
end

ui.scroller.scrollToBounds = function(self)
	if (not self or not self._moveDirection) then return; end
	local upperLimit = self:snapTop(self.content, true);
	local lowerLimit = self:snapBottom(self.content, true);
	local leftLimit = self:snapLeft(self.content, true);
	local rightLimit = self:snapRight(self.content, true);
	local xy = self.content[self._moveDirection];

	local onScrollComplete = function()
		self._moveTween = nil;
		self._moveDirection = nil;
	end

	local tweenContent = function(limit)
		if (self._moveTween) then transition.cancel(self._moveTween); end
		if (not self._hasFocus) then
			-- scroller is *not* currently being touched by user
			local endX, endY;
			if (limit == upperLimit) then
				endX = self.content.x;
				endY = upperLimit;
			elseif (limit == lowerLimit) then
				endX = self.content.x;
				endY = lowerLimit;
			elseif (limit == leftLimit) then
				endX = leftLimit;
				endY = self.content.y;
			elseif (limit == rightLimit) then
				endX = rightLimit;
				endY = self.content.y;
			end
			self._moveTween = transition.to(self.content, { time=400, x=endX, y=endY, transition=easing.outQuad, onComplete=onScrollComplete });
		end
	end

	if (self._moveDirection == 'y') then
		if (xy > upperLimit) then
			-- Content has moved below upper limit of scroller bounds
			-- Stop content movement and transition back up to the upperLimit

			self._velocity = 0;
			Runtime:removeEventListener("enterFrame", self.enterframe);
			tweenContent(upperLimit);

		elseif (xy < lowerLimit) then
			-- Content has moved above lower limit of scroller bounds
			-- Stop content movement and transition back  down to the lowerLimit

			self._velocity = 0;
			Runtime:removeEventListener("enterFrame", self.enterframe);
			tweenContent(lowerLimit);
		end
	elseif (self._moveDirection == 'x') then
		if (xy > leftLimit) then
			-- Content has moved past right limit of scroller bounds
			-- Stop content movement and transition back up to the upperLimit

			self._velocity = 0;
			Runtime:removeEventListener("enterFrame", self.enterframe);
			tweenContent(leftLimit);

		elseif (xy < rightLimit) then
			-- Content has moved past left limit of scroller bounds
			-- Stop content movement and transition back  down to the lowerLimit

			self._velocity = 0;
			Runtime:removeEventListener("enterFrame", self.enterframe);
			tweenContent(rightLimit);
		end
	end
end

ui.scroller.touch = function(event)
	local self = event.target;
	local bounds = self.contentBounds;
	local isWithinBounds = bounds.xMin <= event.x and bounds.xMax >= event.x and bounds.yMin <= event.y and bounds.yMax >= event.y;
	
	if ((not isWithinBounds) and (event.phase ~= "moved")) then
		display.getCurrentStage():setFocus(nil);
		self._hasFocus = false;
		self:scrollToBounds();
		return false;
	end

	if ((self.content.height < self.height) or (self.scrollLock)) then return true; end

	if (self._moveTween) then
		transition.cancel(self._moveTween);
		self._moveTween = nil;
	end

	if (event.phase == "began") then
		display.getCurrentStage():setFocus(self);
		self._hasFocus = true;

		-- Remove enterFrame listener first (to prevent unintended duplicate listeners being added)
		Runtime:removeEventListener("enterFrame", self.enterframe);

		self._velocity = 0;
		self._trackingVelocity = true;
		self._eventX = event.x;
		self._eventY = event.y;
		self._markX = self.content.x;
		self._markY = self.content.y;
		self._markTime = event.time;
		self._eventStep = 0;

		Runtime:addEventListener("enterFrame", self.enterframe);

	elseif (self._hasFocus) then
		if (event.phase == "moved") then

			-- determine scroll direction (if not already set)
			if ((not self._moveDirection) and ((self.xScroll) or (self.yScroll))) then
				local dx = math_abs(event.x - self._eventX);
				local dy = math_abs(event.y - self._eventY);
				local moveThresh = 8;

				if ((dx > moveThresh) or (dy > moveThresh)) then
					if (dx > dy) then
						self._moveDirection = 'x';
					else
						self._moveDirection = 'y';
					end
				end

				return true;
			end

			local delta, limit1, limit2, mark;

			if ((self._moveDirection == 'y') and (self.yScroll)) then
				delta = event.y - self._eventY;
				self._eventY = event.y;
				limit1 = self:snapTop(self.content, true);
				limit2 = self:snapBottom(self.content, true);
				mark = "_markX";
			elseif ((self._moveDirection == 'x') and (self.xScroll)) then
				delta = event.x - self._eventX;
				self._eventX = event.x;
				limit1 = self:snapLeft(self.content, true);
				limit2 = self:snapRight(self.content, true);
				mark = "_markY"
			end

			local xy = self.content[self._moveDirection];
			if ((not xy) or (not limit1) or not (limit2)) then return true; end

			if ((xy > limit1) or (xy < limit2)) then
				-- elastic movement if user attempts to drag outside of scroller bounds
				self.content[self._moveDirection] = self.content[self._moveDirection] + (delta/2);
			else
				self.content[self._moveDirection] = self.content[self._moveDirection] + delta;
			end

			-- modify velocity based on previous moved phase
			self._velocity = (self.content[self._moveDirection] - self[mark]) / (event.time - self._markTime);
			self._markTime = event.time;
			self[mark] = self.content[self._moveDirection];

		elseif ((event.phase == "ended") or (event.phase == "cancelled")) then
			display.getCurrentStage():setFocus(nil);
			self._hasFocus = false;
			self._prevTime = event.time;
			self._trackingVelocity = false;
			self._markTime = 0;

			if (self._velocity > 2) then
				self._velocity = 2;
			elseif (self._velocity < -2) then
				self._velocity = -2;
			end
		end
	end
	return true;
end

ui.scroller.positionChild = function(self, displayObject, x, y)
	self:snapTopLeft(displayObject);
	displayObject.x = displayObject.x + x;
	displayObject.y = displayObject.y + y;
end

ui.scroller.snapTop = function(self, displayObject, returnValue)
	if (displayObject ~= self.content) then
		if (not returnValue) then
			displayObject.y = displayObject.height * displayObject.anchorY;
		else
			return displayObject.height * displayObject.anchorY;
		end
	else
		if (not returnValue) then
			displayObject.y = (displayObject.height * displayObject.anchorY) - (self.height * 0.5);
		else
			return (displayObject.height * displayObject.anchorY) - (self.height * 0.5);
		end
	end
end

ui.scroller.snapBottom = function(self, displayObject, returnValue)
	if (displayObject ~= self.content) then
		if (not returnValue) then
			displayObject.y = -(displayObject.height * displayObject.anchorY) + self.height;
		else
			return -(displayObject.height * displayObject.anchorY) + self.height;
		end
	else
		if (not returnValue) then
			displayObject.y = -(displayObject.height * displayObject.anchorY) + (self.height * 0.5);
		else
			return -(displayObject.height * displayObject.anchorY) + (self.height * 0.5);
		end
	end
end

ui.scroller.snapLeft = function(self, displayObject, returnValue)
	if (displayObject ~= self.content) then
		if (not returnValue) then
			displayObject.x = displayObject.width * displayObject.anchorX;
		else
			return displayObject.width * displayObject.anchorX;
		end
	else
		if (not returnValue) then
			displayObject.x = (displayObject.width * displayObject.anchorX) - (self.width * 0.5);
		else
			return (displayObject.width * displayObject.anchorX) - (self.width * 0.5);
		end
	end
end

ui.scroller.snapRight = function(self, displayObject, returnValue)
	if (displayObject ~= self.content) then
		if (not returnValue) then
			displayObject.x = (displayObject.width * displayObject.anchorX) - displayObject.width + self.width;
		else
			return (displayObject.width * displayObject.anchorX) - displayObject.width + self.width;
		end
	else
		if (not returnValue) then
			displayObject.x = ((displayObject.width * displayObject.anchorX) - displayObject.width + (self.width * 0.5));
		else
			return ((displayObject.width * displayObject.anchorX) - displayObject.width + (self.width * 0.5));
		end
	end
end

ui.scroller.snapCenter = function(self, displayObject)
	if (displayObject ~= self.content) then
		displayObject.x = (displayObject.width * displayObject.anchorX) - ((displayObject.width - self.width) * 0.5);
		displayObject.y = (displayObject.height * displayObject.anchorY) - ((displayObject.height - self.height) * 0.5);
	else
		displayObject.x = (displayObject.width * displayObject.anchorX) - ((displayObject.width - self.width) * 0.5) - (self.width * 0.5);
		displayObject.y = (displayObject.height * displayObject.anchorY) - ((displayObject.height - self.height) * 0.5) - (self.height * 0.5);
	end
end

ui.scroller.snapCenterLeft = function(self, displayObject)
	if (displayObject ~= self.content) then
		displayObject.x = displayObject.width * displayObject.anchorX;
		displayObject.y = (displayObject.height * displayObject.anchorY) - ((displayObject.height - self.height) * 0.5);
	else
		displayObject.x = (displayObject.width * displayObject.anchorX) - (self.width * 0.5);
		displayObject.y = (displayObject.height * displayObject.anchorY) - ((displayObject.height - self.height) * 0.5) - (self.height * 0.5);
	end
end

ui.scroller.snapCenterRight = function(self, displayObject)
	if (displayObject ~= self.content) then
		displayObject.x = (displayObject.width * displayObject.anchorX) - displayObject.width + self.width;
		displayObject.y = (displayObject.height * displayObject.anchorY) - ((displayObject.height - self.height) * 0.5);
	else
		displayObject.x = ((displayObject.width * displayObject.anchorX) - displayObject.width + (self.width * 0.5));
		displayObject.y = (displayObject.height * displayObject.anchorY) - ((displayObject.height - self.height) * 0.5) - (self.height * 0.5);
	end
end

ui.scroller.snapTopLeft = function(self, displayObject)
	if (displayObject ~= self.content) then
		displayObject.x = displayObject.width * displayObject.anchorX;
		displayObject.y = displayObject.height * displayObject.anchorY;
	else
		displayObject.x = (displayObject.width * displayObject.anchorX) - (self.width * 0.5);
		displayObject.y = (displayObject.height * displayObject.anchorY) - (self.height * 0.5);
	end
end

ui.scroller.snapTopRight = function(self, displayObject)
	if (displayObject ~= self.content) then
		displayObject.x = (displayObject.width * displayObject.anchorX) - displayObject.width + self.width;
		displayObject.y = displayObject.height * displayObject.anchorY;
	else
		displayObject.x = ((displayObject.width * displayObject.anchorX) - displayObject.width + (self.width * 0.5));
		displayObject.y = (displayObject.height * displayObject.anchorY) - (self.height * 0.5);
	end
end

ui.scroller.snapTopCenter = function(self, displayObject)
	if (displayObject ~= self.content) then
		displayObject.x = (displayObject.width * displayObject.anchorX) - ((displayObject.width - self.width) * 0.5);
		displayObject.y = displayObject.height * displayObject.anchorY;
	else
		displayObject.x = (displayObject.width * displayObject.anchorX) - ((displayObject.width - self.width) * 0.5) - (self.width * 0.5);
		displayObject.y = (displayObject.height * displayObject.anchorY) - (self.height * 0.5);
	end
end

ui.scroller.snapBottomLeft = function(self, displayObject)
	if (displayObject ~= self.content) then
		displayObject.x = displayObject.width * displayObject.anchorX;
		displayObject.y = -(displayObject.height * displayObject.anchorY) + self.height;
	else
		displayObject.x = (displayObject.width * displayObject.anchorX) - (self.width * 0.5);
		displayObject.y = -(displayObject.height * displayObject.anchorY) + (self.height * 0.5);
	end
end

ui.scroller.snapBottomRight = function(self, displayObject)
	if (displayObject ~= self.content) then
		displayObject.x = (displayObject.width * displayObject.anchorX) - displayObject.width + self.width;
		displayObject.y = -(displayObject.height * displayObject.anchorY) + self.height;
	else
		displayObject.x = ((displayObject.width * displayObject.anchorX) - displayObject.width + (self.width * 0.5));
		displayObject.y = -(displayObject.height * displayObject.anchorY) + (self.height * 0.5);
	end
end

ui.scroller.snapBottomCenter = function(self, displayObject)
	if (displayObject ~= self.content) then
		displayObject.x = (displayObject.width * displayObject.anchorX) - ((displayObject.width - self.width) * 0.5);
		displayObject.y = -(displayObject.height * displayObject.anchorY) + self.height;
	else
		displayObject.x = (displayObject.width * displayObject.anchorX) - ((displayObject.width - self.width) * 0.5) - (self.width * 0.5);
		displayObject.y = -(displayObject.height * displayObject.anchorY) + (self.height * 0.5);
	end
end

ui.scroller._focusTouch = function(self, event)
	local target = event.target;
		
	-- if button, restore back to "default" state
	if ((target._uiType) and (target._uiType == "button")) then
		target:release();
	end

	-- remove focus from target
	display.getCurrentStage():setFocus(nil);
	target._hasFocus = false;
	if (target.isFocus) then target.isFocus = nil; end
	
	-- set event.target to scrollView and start back at "began" phase
	local nextTarget = self.bg or self;
	local e = {
		name = event.name,
		target = nextTarget,
		phase = "began",
		x = event.x,
		y = event.y
	};
	nextTarget:dispatchEvent(e);
end

ui.scroller.dispose = function(self)
	if (self._hasFocus) then display.getCurrentStage():setFocus(nil); end
	self:removeEventListener("touch", ui.scroller.touch);
	Runtime:removeEventListener("enterFrame", self.enterframe);
	if (self._moveTween) then
		transition.cancel(self._moveTween);
		self._moveTween = nil;
	end
	removeScroller(self);
	self:removeSelf();
end

--- ui.scrollContainer
-- Scrollable container with no momentum/physics simulation.
ui.scrollContainer = {};
ui.scrollContainer.required = {
	width = "number",
	height = "number"
};
ui.scrollContainer.defaults = {
	x = 0,
	y = 0,
	scrollLock = false,
	xScroll = true,
	yScroll = true,
	leftPadding = 0,
	rightPadding = 0,
	topPadding = 0,
	bottomPadding = 0,
	borderRadius = 0,
	borderWidth = 0,
	borderColor = { 0, 0, 0, 0 }
};

ui.scrollContainer.new = function(args)
	checkoptions.callee = 'ui.scrollContainer.new';
	local options = checkoptions.check(args, ui.scrollContainer.required, ui.scrollContainer.defaults);

	local view = display.newContainer(options.width, options.height);
	view.anchorChildren = true;
	view._uiType = 'scrollContainer';

	-- if bgColor option is set, create a rectangle and insert directly into container (behind content group)
	local rect = display.newRect;
	if (options.borderRadius > 0) then
		rect = display.newRoundedRect;
	end
	local bg = rect(-(options.width * 0.5), -(options.height * 0.5), options.width, options.height, options.borderRadius);
	if ((options.bgColor) and (type(options.bgColor) == "table") and (#options.bgColor == 3)) then
		bg:setFillColor(options.bgColor[1], options.bgColor[2], options.bgColor[3]);
	else
		bg:setFillColor(1, 1, 1);
	end

	if (options.borderWidth > 0) then
		bg:setStrokeColor(options.borderColor[1], options.borderColor[2], options.borderColor[3], options.borderColor[4] or 1);
		bg.strokeWidth = options.borderWidth;
	end

	view:insert(bg, true);
	view.bg = bg;
	bg:addEventListener("touch", ui.scrollContainer.touch);

	view.content = display.newGroup();
	view:insert(view.content, false);

	view.insert = function(self, obj)
		view.content:insert(obj);
	end

	-- set properties (or use defaults)
	for k,v in pairs(ui.scrollContainer.defaults) do
		if (options[k]) then
			view[k] = options[k];
		else
			view[k] = v;
		end
	end

	view._focusTouch = ui.scroller._focusTouch;

	table.insert(ui.scrollers, view);
	return view;
end

ui.scrollContainer.touch = function(event)
	local self = event.target;
	local content = self.parent.content;

	if (event.phase == "began") then
		display.getCurrentStage():setFocus(self);
		self._hasFocus = true;

		self.markX = content.x;
		self.markY = content.y;

	elseif (self._hasFocus) then
		if (event.phase == "moved") then

			if (self.parent.scrollLock) then return true; end
			local containerBounds = self.parent.contentBounds;
			local contentBounds = content.contentBounds;
			local dx = (event.x - event.xStart) + self.markX;
			local dy = (event.y - event.yStart) + self.markY;

			if (self.parent.xScroll) then
				if (self.parent.contentWidth < content.contentWidth) then
					content.x = dx;
					local left = containerBounds.xMin + self.parent.leftPadding;
					local right = containerBounds.xMax - self.parent.rightPadding;

					if (content.contentBounds.xMin > left) then
						content.x = content.x - (content.contentBounds.xMin - left);
					elseif (content.contentBounds.xMax < right) then
						content.x = content.x + (right - content.contentBounds.xMax);
					end
				end
			end

			if (self.parent.yScroll) then
				if (self.parent.contentHeight < content.contentHeight) then
					content.y = dy;
					local top = containerBounds.yMin + self.parent.topPadding;
					local bottom = containerBounds.yMax - self.parent.bottomPadding;

					if (content.contentBounds.yMin > top) then
						content.y = content.y - (content.contentBounds.yMin - top);
					elseif (content.contentBounds.yMax < bottom) then
						content.y = content.y + (bottom - content.contentBounds.yMax);
					end
				end
			end

		elseif ((event.phase == "cancelled") or (event.phase == "ended")) then

			display.getCurrentStage():setFocus(nil);
			self._hasFocus = false;
		end
	end
	return true;
end

return ui;
