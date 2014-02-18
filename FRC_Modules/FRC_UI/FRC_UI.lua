-- ui widgets for Corona graphics 2.x engine (not compatible with 1.x)

local math_abs = math.abs;
local math_floor = math.floor;
local ui = {};

local function format_num(amount, decimal, prefix, neg_prefix)
	function comma_value(amount)
		local formatted = amount
		while true do  
			formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
			if (k==0) then
		  		break
			end
		end
		return formatted
	end

	function round(val, decimal)
		if (decimal) then
			return math_floor( (val * 10^decimal) + 0.5) / (10^decimal)
		else
			return math_floor(val+0.5)
		end
	end
	local str_amount,  formatted, famount, remain

	decimal = decimal or 2  -- default 2 decimal places
	neg_prefix = neg_prefix or "-" -- default negative sign

	famount = math_abs(round(amount,decimal))
	famount = math_floor(famount)

	remain = round(math_abs(amount) - famount, decimal)

	    -- comma to separate the thousands
	formatted = comma_value(famount)

	    -- attach the decimal portion
	if (decimal > 0) then
		remain = string.sub(tostring(remain),3)
		formatted = formatted .. "." .. remain .. string.rep("0", decimal - string.len(remain))
	end

	    -- attach prefix string e.g '$' 
	formatted = (prefix or "") .. formatted 

	    -- if value is negative then format accordingly
	if (amount<0) then
		if (neg_prefix=="()") then
			formatted = "("..formatted ..")"
		else
			formatted = neg_prefix .. formatted 
		end
	end

	return formatted
end

-- checkoptions.callee should be set before calling any other method
local checkoptions = {};
checkoptions.callee = ''; -- name of function calling a checkoptions method

-- adds Corona 'DisplayObject' to Lua type() function
--[[
local cached_type = type;
type = function(obj)
	if ((cached_type(obj) == 'table') and (obj._class) and (obj._class.addEventListener)) then
		return "DisplayObject";
	else
		return cached_type(obj);
	end
end
--]]

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
		view.up._path = options.imageUp;

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
		view.up:setStrokeColor(0, 0, 0, 1.0);
		view.up.strokeWidth = 5;
		view.up.isHitTestable = true;

	elseif (options.rect) then
		view.up = display.newRoundedRect(0, 0, options.width, options.height, 11);
		view.up:setFillColor(options.bgColor[1], options.bgColor[2], options.bgColor[3], 1.0);
		view.up:setStrokeColor(0, 0, 0, 1.0);
		view.up.strokeWidth = 10;
		view.up.isHitTestable = true;
	end
	view:insert(view.up, true);
	view.default = view.up;

	if (options.imageDown) then
		view.down = display.newImageRect(options.imageDown, options.width, options.height);
		view.down._path = options.imageDown;

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
		view.down:setFillColor(0, 0, 0, 0);
		view.down:setStrokeColor(0, 0, 0, 1.0);
		view.down.strokeWidth = 5;
		view.down.isHitTestable = true;

	elseif (options.rect) then
		view.down = display.newRoundedRect(0, 0, options.width, options.height, 11);
		view.down:setFillColor(options.bgColor[1], options.bgColor[2], options.bgColor[3], 1.0);
		view.down:setStrokeColor(0, 0, 0, 1.0);
		view.down.strokeWidth = 10;
		view.down.isHitTestable = true;
	end
	view.down.isVisible = false;
	view:insert(view.down, true);
	view.over = view.down;

	if (options.disabled) then
		view.disabled = display.newImageRect(options.disabled, options.width, options.height);
		view.disabled._path = options.disabled;
		view.disabled.isVisible = false;
		view.disabled.isVisible = false;
		view:insert(view.disabled, true);
	else
		view.disabled = {};
	end

	if (options.focusState) then
		view.focusState = display.newImageRect(options.focusState, options.width, options.height);
		view.focusState._path = options.focusState;
		view.focusState.isVisible = false;
		view.focusState.isVisible = false;
		view:insert(view.focusState, true);
	else
		view.focusState = {};
	end

	-- add button touch listener to handle up/down state switching
	view:addEventListener("touch", ui.button.touch);

	-- public properties and methods
	view.press = ui.button.press;
	view.release = ui.button.release;
	view.dispose = function(self) pcall(ui.button.dispose, self); end
	view.x = options.x;
	view.y = options.y;
	view.pressAlpha = options.pressAlpha;
	view.setFocusState = ui.button.setFocusState;
	view.setDisabledState = ui.button.setDisabledState;
	view.setFillColor = ui.button.setFillColor;
	view.setStrokeColor = ui.button.setStrokeColor;
	view.setFill = ui.button.setFill;
	view.setStrokeWidth = ui.button.setStrokeWidth;

	if (options.parentScrollContainer) then
		view.parentScrollContainer = options.parentScrollContainer;
	end 

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
	if (self.isDisabled) then return true; end

	if (event.phase == "began") then
		display.getCurrentStage():setFocus(self);
		self._hasFocus = true;
		self._startX = event.x;
		self._startY = event.y;
		self:press();
		self:dispatchEvent({
			name = "press",
			target = self,
			x = event.x,
			y = event.y
		});

		return true;

	elseif (self._hasFocus) then
		if (event.phase == "moved") then
			if ((not self._startX) or (not self._startY)) then return true; end
			-- handle case where user pressed the button, but then begins to drag a scroller
			local dx = math_abs(event.x - self._startX);
			local dy = math_abs(event.y - self._startY);
			local thresh = 5;
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
				self:dispatchEvent({
					name = "moved",
					target = self,
					x = event.x,
					y = event.y,
					xStart = event.xStart,
					yStart = event.yStart
				});
				
				if (self.parentScrollContainer) then
					local scrollerBounds = self.parentScrollContainer.contentBounds;
					local isWithinScroller = scrollerBounds.xMin <= event.x and scrollerBounds.xMax >= event.x and scrollerBounds.yMin <= event.y and scrollerBounds.yMax >= event.y;
					if ((isWithinScroller) and (self.parentScrollContainer.isVisible)) then
						eventPassedToScroller = true;
						self.parentScrollContainer:_focusTouch(event);
					end
				end

				if (eventPassedToScroller) then
					return false;
				end
			end

		elseif ((event.phase == "ended") or (event.phase == "cancelled")) then
			self:release();

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

			display.getCurrentStage():setFocus(nil);
			self._hasFocus = false;
		end
		return true;

	elseif ((event.phase == "moved") and (self._startX) and (self._startY)) then
		-- simple touches can sometimes caused "moved" phase to occur due to sensitive touch screens,
		-- so ensure finger moved at least a few pixelsfrom start of touch location to consider it moved
		local dx = math_abs(event.x - self._startX);
		local dy = math_abs(event.y - self._startY);
		local thresh = 3;
		if ((dx >= thresh) or (dy >= thresh)) then
			if (self.parentScrollContainer) then
				local scrollerBounds = self.parentScrollContainer.contentBounds;
				local isWithinScroller = scrollerBounds.xMin <= event.x and scrollerBounds.xMax >= event.x and scrollerBounds.yMin <= event.y and scrollerBounds.yMax >= event.y;
				if ((isWithinScroller) and (self.parentScrollContainer.isVisible)) then
					eventPassedToScroller = true;
					self.parentScrollContainer:_focusTouch(event);
				end
			end
			display.getCurrentStage():setFocus(nil);
			self._hasFocus = false;
			return false;
		end
	else
		display.getCurrentStage():setFocus(nil);
		self._hasFocus = false;
		return false;		
	end
	return true;
end

ui.button.release = function(self, callback)
	if (self.focused) then
		self.focusState.isVisible = true;
	else
		self.focusState.isVisible = false;
	end
	self.up.isVisible = true;
	self.down.isVisible = false;
	self.bg.isVisible = true;
	self.bg.alpha = 1.0;

	if ((callback) and (type(callback) == "function")) then
		callback();
	end
end

ui.button.press = function(self, callback)
	self.focusState.isVisible = false;
	self.up.isVisible = false;
	self.down.isVisible = true;
	self.down.alpha = self.pressAlpha;
	self.bg.alpha = self.pressAlpha;

	if ((callback) and (type(callback) == "function")) then
		callback();
	end
end

ui.button.setFocusState = function(self, focused)
	if (focused) then
		self.focusState.isVisible = true;
		self.disabled.isVisible = false;
		self.focused = true;
	else
		self.focusState.isVisible = false;
		self.focused = false;
	end
end

ui.button.setDisabledState = function(self, disabled)
	if (disabled) then
		self.disabled.isVisible = true;
		self.focusState.isVisible = false;
		self.up.isVisible = false;
		self.isDisabled = true;
	else
		self.disabled.isVisible = false;
		self.up.isVisible = true;
		self.isDisabled = false;
	end
end

ui.button.setFillColor = function(self, ...)
	if ((self.disabled) and (self.disabled.setFillColor)) then
		self.disabled:setFillColor(...);
	end
	if ((self.focusState) and (self.focusState.setFillColor)) then
		self.focusState:setFillColor(...);
	end

	self.up:setFillColor(...);
	self.down:setFillColor(...);
end

ui.button.setStrokeColor = function(self, ...)
	if ((self.disabled) and (self.disabled.setStrokeColor)) then
		self.disabled:setStrokeColor(...);
	end
	if ((self.focusState) and (self.focusState.setStrokeColor)) then
		self.focusState:setStrokeColor(...);
	end

	self.up:setStrokeColor(...);
	self.down:setStrokeColor(...);
end

ui.button.setFill = function(self, fillData)
	if (self.disabled) then
		self.disabled.fill = fillData;
	end
	if (self.focusState) then
		self.focusState.fill = fillData;
	end

	self.up.fill = fillData;
	self.down.fill = fillData;
end

ui.button.setStrokeWidth = function(self, width)
	if (self.disabled) then
		self.disabled.strokeWidth = width;
	end
	if (self.focusState) then
		self.focusState.strokeWidth = width;
	end

	self.up.strokeWidth = width;
	self.down.strokeWidth = width;
end

ui.button.dispose = function(self)
	if (self._hasFocus) then display.getCurrentStage():setFocus(nil); end
	self:removeEventListener("touch", ui.button.touch);

	if (self.up) then
		self.up:removeSelf();
		self.up = nil;
	end

	if (self.down) then
		self.down:removeSelf();
		self.down = nil;
	end

	if ((self.focusState) and (self.focusState.removeSelf)) then
		self.focusState:removeSelf();
		self.focusState = nil;
	end

	if ((self.disabled) and (self.disabled.removeSelf)) then
		self.disabled:removeSelf();
		self.disabled = nil;
	end

	self.parentScrollContainer = nil;
	self:removeSelf();
end

--- ui.scrollContainer
-- Scrollable container with momentum/physics simulation.
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
	if ((options.bgColor) and (type(options.bgColor) == "table") and (#options.bgColor >= 3)) then
		bg:setFillColor(options.bgColor[1], options.bgColor[2], options.bgColor[3], options.bgColor[4] or 1.0);
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

	view._focusTouch = ui.scrollContainer._focusTouch;

	view._trackingVelocity = false;
	view._prevTime = 0;
	view._markTime = 0;
	view._velocity = 0;
	view._friction = 0.9; --0.935;
	view._moveDirection = nil; -- 'x': horizontal; 'y': vertical

	view.limitMovement = function()
		local content = view.content;
		local containerBounds = view.contentBounds;
		local contentAtLimit = false;

		if (view.xScroll) then
			if (view.contentWidth < content.contentWidth) then
				local left = containerBounds.xMin + view.leftPadding;
				local right = containerBounds.xMax - view.rightPadding;

				if (content.contentBounds.xMin > left) then
					content.x = content.x - (content.contentBounds.xMin - left);
					contentAtLimit = true;
				elseif (content.contentBounds.xMax < right) then
					content.x = content.x + (right - content.contentBounds.xMax);
					contentAtLimit = true;
				end
			end
		end

		if (view.yScroll) then
			if (view.contentHeight < content.contentHeight) then
				local top = containerBounds.yMin + view.topPadding;
				local bottom = containerBounds.yMax - view.bottomPadding;

				if (content.contentBounds.yMin > top) then
					content.y = content.y - (content.contentBounds.yMin - top);
					contentAtLimit = true;
				elseif (content.contentBounds.yMax < bottom) then
					content.y = content.y + (bottom - content.contentBounds.yMax);
					contentAtLimit = true;
				end
			end
		end

		return contentAtLimit;
	end

	-- enterframe listener for view
	view.enterframe = function(event)
		local time = event.time;
		local timePassed = time - view._prevTime;
		view._prevTime = time;

		if ((not view.isVisible) or (not view.content.isVisible)) then
			view._velocity = 0;
			view._moveDirection = nil;
			Runtime:removeEventListener('enterFrame', view.enterframe);
			return;
		end

		if ((not view._trackingVelocity) and (view._moveDirection)) then
			-- handle scrolling based on velocity
			if (math_abs(view._velocity) >= 0.2) then
				view._velocity = view._velocity * view._friction;
				view.content[view._moveDirection] = view.content[view._moveDirection] + (view._velocity * timePassed);
			else
				-- scroller has stopped movement
				view._velocity = 0;
				view._moveDirection = nil;
				Runtime:removeEventListener("enterFrame", view.enterframe);
			end
		end

		local contentAtLimit = view.limitMovement();
		if (contentAtLimit) then
			view._velocity = 0;
			view._moveDirection = nil;
			Runtime:removeEventListener("enterFrame", view.enterframe);
		end
	end

	return view;
end

ui.scrollContainer._focusTouch = function(self, event)
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

ui.scrollContainer.touch = function(event)
	local self = event.target;
	local view = self.parent;
	local content = view.content;

	if ((event.phase == "began") and (view.isVisible) and (content.isVisible)) then
		display.getCurrentStage():setFocus(self);
		self._hasFocus = true;

		self.markX = content.x;
		self.markY = content.y;

		-- Remove enterFrame listener first (to prevent unintended duplicate listeners being added)
		Runtime:removeEventListener("enterFrame", view.enterframe);

		view._velocity = 0;
		view._trackingVelocity = true;
		view._eventX = event.x;
		view._eventY = event.y;
		view._markX = view.content.x;
		view._markY = view.content.y;
		view._markTime = event.time or 0;
		view._eventStep = 0;

		Runtime:addEventListener("enterFrame", view.enterframe);

	elseif (self._hasFocus) then
		if (event.phase == "moved") then

			if (self.parent.scrollLock) then return true; end
			local containerBounds = self.parent.contentBounds;
			local contentBounds = content.contentBounds;
			local dx = (event.x - event.xStart) + self.markX;
			local dy = (event.y - event.yStart) + self.markY;
			local mark, scrollable;

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
					view._moveDirection = 'x';
					mark = "_markX";
					scrollable = true;
				else
					scrollable = false;
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
					view._moveDirection = 'y';
					mark = "_markY";
					scrollable = true;
				end
			end

			if ((view._moveDirection) and (scrollable)) then
				view._velocity = (view.content[view._moveDirection] - view[mark]) / (event.time - view._markTime);
				view._markTime = event.time or 0;
				view[mark] = view.content[view._moveDirection];
			else
				Runtime:removeEventListener("enterFrame", view.enterframe);
			end

		elseif ((event.phase == "cancelled") or (event.phase == "ended")) then

			view._prevTime = event.time;
			view._trackingVelocity = false;
			view._markTime = 0;

			display.getCurrentStage():setFocus(nil);
			self._hasFocus = false;
		end
	elseif ((event.phase == "cancelled") or (event.phase == "ended")) then
		view._prevTime = event.time;
		view._trackingVelocity = false;
		view._markTime = 0;
		
		display.getCurrentStage():setFocus(nil);
		self._hasFocus = false;
	end
	return true;
end

--- ui.slider
-- Simple horizontal slider ui widget
ui.slider = {};
ui.slider.required = {
	width = "number"
};
ui.slider.defaults = {
	x = 0,
	y = 0,
	height = 8,
	min = 0,
	max = 100,
	sliderColor = { .133333333, .133333333, .133333333, 1.0 },
	handleColor = { .658823529, .701960784, .91372549, 1.0 },
	handleRadius = 20,
	startValue = 50
};

ui.slider.new = function(args)
	checkoptions.callee = "ui.slider.new";
	local options = checkoptions.check(args, ui.slider.required, ui.slider.defaults);

	local slider = display.newGroup();
	slider.min = options.min or 0;
	slider.max = options.max or 100;
	slider.value = options.startValue or 50;

	local bg = display.newRoundedRect(slider, 0, 0, options.width, options.height, 4);
	bg:setFillColor(options.sliderColor[1], options.sliderColor[2], options.sliderColor[3], options.sliderColor[4] or 1.0);

	local handle = display.newCircle(slider, 0, 0, options.handleRadius);
	handle:setFillColor(options.handleColor[1], options.handleColor[2], options.handleColor[3], options.handleColor[4] or 1.0);
	handle:addEventListener('touch', ui.slider.touch);
	handle.minX = -(options.width * 0.5) + (handle.contentWidth * 0.5) - 2;
	handle.maxX = (options.width * 0.5) - (handle.contentWidth * 0.5) + 2;
	handle.range = handle.maxX - handle.minX;
	slider.handle = handle;
	slider.setValue = ui.slider.setValue;

	-- position handle at correct starting location
	local startDecimalValue = format_num((slider.value - slider.min) / (slider.max - slider.min), 2);
	handle.x = handle.minX + ((handle.maxX - handle.minX) * startDecimalValue);
	slider.percent = math_floor(startDecimalValue * 100);

	return slider;
end

ui.slider.setValue = function(self, value)
	self.value = value;
	
	local decimalValue = format_num((self.value - self.min) / (self.max - self.min), 2);
	self.handle.x = self.handle.minX + ((self.handle.maxX - self.handle.minX) * decimalValue);
	self.percent = math_floor(decimalValue * 100);
end

ui.slider.touch = function(event)
	local self = event.target;
	local slider = self.parent;
	local width = slider.contentWidth;

	if (event.phase == "began") then
		display.getCurrentStage():setFocus(self);
		self._hasFocus = true;
		self.markX = self.x;

	elseif (self._hasFocus) then
		if (event.phase == "moved") then
			local x = (event.x - event.xStart) + self.markX;
			if (x < self.minX) then x = self.minX; end
			if (x > self.maxX) then x = self.maxX; end
			self.x = x;

			local decimalValue = format_num((self.x - self.minX) / self.range, 2);
			slider.value = slider.min + ((slider.max - slider.min) * decimalValue);
			slider.percent = math_floor(decimalValue * 100);
			
			local endTouch = slider:dispatchEvent({
				name = "change",
				target = slider,
				value = slider.value,
				percent = slider.percent,
				handle = self
			});
			
			if (endTouch == true) then
				self._hasFocus = false;
				display.getCurrentStage():setFocus(nil);
				return true;
			end
		else
			slider:dispatchEvent({
				name = "touchEnded",
				target = slider,
				value = slider.value,
				percent = slider.percent,
				handle = self
			});
			self._hasFocus = false;
			display.getCurrentStage():setFocus(nil);
		end
	end

	return true;
end

--- ui.movieClip
-- Simple flip-book style animation group
ui.movieClip = {};
ui.movieClip.required = {
	images = "table",
	width = "number",
	height = "number"
};
ui.movieClip.defaults = {};

ui.movieClip.new = function(args)
	checkoptions.callee = 'ui.movieClip.new';
	local options = checkoptions.check(args, ui.movieClip.required, ui.movieClip.defaults);
	
	local group = display.newGroup();
	group.currentIndex = 1;
	group.intervalTime = 100;
	
	for i=1,#options.images do
		local frame = display.newImageRect(group, options.images[i], options.width, options.height);
		frame.x = 0;
		frame.y = 0;
	end
	
	group.showFrame = function(self, index)
		for i=self.numChildren,1,-1 do
			if (i == index) then
				self[i].isVisible = true;
			else
				self[i].isVisible = false;
			end
		end
		self.currentIndex = index;
	end
	
	group.play = function(self, options)
		local maxIterations = 0;
		if (options.noLoop) then
			maxIterations = self.numChildren - self.currentIndex;
			if (maxIterations <= 0) then
				maxIterations = 1;
			end 
		end
		
		if (options.startFrame) then
			self:showFrame(options.startFrame);
		end
		
		if (options.intervalTime) then
			self.intervalTime = options.intervalTime;
		end
		
		self.iterations = 0;
		
		local function gotoNext(isDelay)
			local nextIndex = self.currentIndex + 1;
			if (nextIndex > self.numChildren) then
				self.iterations = self.iterations + 1;
				nextIndex = 1;
				
				if ((self.iterations > maxIterations) and (maxIterations > 0)) then
					self.iterations = 0;
					timer.cancel(self.animationTimer);
					self.animationTimer = nil;
				else
					if (isDelay == true) then
						timer.cancel(self.animationTimer);
						self.animationTimer = timer.performWithDelay(options.delay, function()
							self.animationTimer = timer.performWithDelay(self.intervalTime, function() gotoNext(true); end, 0);
						end, 1);
					end
				end
			end
			self:showFrame(nextIndex);
		end
		
		if (options.delay) then
			self.animationTimer = timer.performWithDelay(options.delay, function()
				self.animationTimer = timer.performWithDelay(self.intervalTime, function() gotoNext(true); end, 0);
			end, 1);
		else
			self.animationTimer = timer.performWithDelay(self.intervalTime, gotoNext, 0);
		end 
	end
	
	
	group.stop = function(self, atFrame)
		if (group.animationTimer) then timer.cancel(group.animationTimer); group.animationTimer = nil; end
		if (atFrame) then group:showFrame(atFrame); end
	end
	
	group.dispose = function(self)
		if (group.animationTimer) then timer.cancel(group.animationTimer); group.animationTimer = nil; end
		group:removeSelf();
	end
	
	return group;
end
	
return ui;
