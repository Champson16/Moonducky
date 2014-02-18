local ui = require('ui');
local button = {};

-- cached functions
local math_abs = math.abs;

-- PUBLIC FUNCTIONS

button.new = function(options)
	local onPress, onRelease;
	
	-- Corona widgets compatibility
	if (options.default) then
		options.imageUp = options.default;
	end

	if (options.over) then
		options.imageDown = options.over;
	end

	if ((options.left) and (options.width)) then
		options.x = options.left;
	end

	if ((options.top) and (options.height)) then
		options.y = options.top;
	end

	if (options.onPress) then
		onPress = options.onPress;
	end

	if (options.onRelease) then
		onRelease = options.onRelease;
	end

	-- Begin --

	local view = display.newContainer(options.width, options.height);
	view._uiType = 'button';
	view.id = options.id or '';

	view.bg = display.newRect(-(options.width * 0.5), -(options.height * 0.5), options.width, options.height);
	view.bg:setFillColor(options.bgColor[1], options.bgColor[2], options.bgColor[3], options.bgColor[4] or 0);
	view:insert(view.bg, true);

	if (options.imageUp) then
		view.up = display.newImageRect(options.imageUp, options.baseDirectory, options.width, options.height);
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
		view.down = display.newImageRect(options.imageDown, options.baseDirectory, options.width, options.height);
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
		view.disabled = display.newImageRect(options.disabled, options.baseDirectory, options.width, options.height);
		view.disabled._path = options.disabled;
		view.disabled.isVisible = false;
		view.disabled.isVisible = false;
		view:insert(view.disabled, true);
	else
		view.disabled = {};
	end

	if (options.focusState) then
		view.focusState = display.newImageRect(options.focusState, options.baseDirectory, options.width, options.height);
		view.focusState._path = options.focusState;
		view.focusState.isVisible = false;
		view.focusState.isVisible = false;
		view:insert(view.focusState, true);
	else
		view.focusState = {};
	end

	-- add button touch listener to handle up/down state switching
	view:addEventListener("touch", button.touch);

	-- public properties and methods
	view.press = button.press;
	view.release = button.release;
	view.dispose = function(self) pcall(button.dispose, self); end
	view.x = options.x;
	view.y = options.y;
	view.pressAlpha = options.pressAlpha;
	view.pressColor = options.pressColor;
	view.setFocusState = button.setFocusState;
	view.setDisabledState = button.setDisabledState;
	view.setFillColor = button.setFillColor;
	view.setStrokeColor = button.setStrokeColor;
	view.setFill = button.setFill;
	view.setStrokeWidth = button.setStrokeWidth;

	if (options.parentScrollContainer) then
		view.parentScrollContainer = options.parentScrollContainer;
	end 

	if (onPress) then
		view:addEventListener('press', onPress);
	end

	if (onRelease) then
		view:addEventListener('release', onRelease);
	end

	ui:addDisposable(view);
	return view;
end

-- INSTANCE METHODS

button.touch = function(event)
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

button.release = function(self, callback)
	if (self.focused) then
		self.focusState.isVisible = true;
	else
		self.focusState.isVisible = false;
	end
	self.up.isVisible = true;
	self.down.isVisible = false;
	self.bg.isVisible = true;
	self.bg.alpha = 1.0;

	if (self.pressColor) then
		self.down:setFillColor(1.0, 1.0, 1.0, 1.0);
		self.bg:setFillColor(1.0, 1.0, 1.0, 1.0);
	end

	if ((callback) and (type(callback) == "function")) then
		callback();
	end
end

button.press = function(self, callback)
	self.focusState.isVisible = false;
	self.up.isVisible = false;
	self.down.isVisible = true;
	self.down.alpha = self.pressAlpha;
	self.bg.alpha = self.pressAlpha;

	if ((self.pressColor) and (#self.pressColor >= 3)) then
		self.down:setFillColor(self.pressColor[1], self.pressColor[2], self.pressColor[3], self.pressColor[4] or 1.0);
		self.bg:setFillColor(self.pressColor[1], self.pressColor[2], self.pressColor[3], self.pressColor[4] or 1.0);
	end

	if ((callback) and (type(callback) == "function")) then
		callback();
	end
end

button.setFocusState = function(self, focused)
	if (focused) then
		self.focusState.isVisible = true;
		self.disabled.isVisible = false;
		self.focused = true;
	else
		self.focusState.isVisible = false;
		self.focused = false;
	end
end

button.setDisabledState = function(self, disabled)
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

button.setFillColor = function(self, ...)
	if ((self.disabled) and (self.disabled.setFillColor)) then
		self.disabled:setFillColor(...);
	end
	if ((self.focusState) and (self.focusState.setFillColor)) then
		self.focusState:setFillColor(...);
	end

	self.up:setFillColor(...);
	self.down:setFillColor(...);
end

button.setStrokeColor = function(self, ...)
	if ((self.disabled) and (self.disabled.setStrokeColor)) then
		self.disabled:setStrokeColor(...);
	end
	if ((self.focusState) and (self.focusState.setStrokeColor)) then
		self.focusState:setStrokeColor(...);
	end

	self.up:setStrokeColor(...);
	self.down:setStrokeColor(...);
end

button.setFill = function(self, fillData)
	if (self.disabled) then
		self.disabled.fill = fillData;
	end
	if (self.focusState) then
		self.focusState.fill = fillData;
	end

	self.up.fill = fillData;
	self.down.fill = fillData;
end

button.setStrokeWidth = function(self, width)
	if (self.disabled) then
		self.disabled.strokeWidth = width;
	end
	if (self.focusState) then
		self.focusState.strokeWidth = width;
	end

	self.up.strokeWidth = width;
	self.down.strokeWidth = width;
end

button.dispose = function(self)
	if (self._hasFocus) then display.getCurrentStage():setFocus(nil); end
	if (self.removeEventListener) then
		self:removeEventListener("touch", button.touch);
	end

	self.parentScrollContainer = nil;
	if (self.removeSelf) then self:removeSelf(); end
end

return button;