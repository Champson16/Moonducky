local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local ui = require('ui');
local FRC_SettingsBar = Runtime._super:new();

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

local activeMenu;

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

local requiredOptions = {
	imageUp = 'string',
	buttonWidth = 'number',
	buttonHeight = 'number',
	parent = 'table'
};

local defaultOptions = {
	items = {},
	bgColor = { 0, 0, 0, 0.25 },
	top = 7,
	right = 10,
	buttons = {},
	buttonPadding = 0
};

local function onMenuTogglePress(event)
	local self = event.target;
	local menu = self.parent;
	if (menu.showTransition) then
		transition.cancel(menu.showTransition);
		menu.showTransition = nil;
		menu.alpha = 1.0;
		menu.isHidden = false;
	end
	menu:show();
end

local function onMenuToggleRelease(event)
	local self = event.target;
	local menu = self.parent;
	menu:show();
	if (menu.expandTransition) then return; end

	if (menu.isExpanded) then
		-- contract menu
		menu.expandTransition = transition.to(menu.menuItems, { time=400, x=menu.menuItems.xHidden, alpha=0, transition=easing.inOutExpo, onComplete=function()
			self:setFocusState(false);
			menu.isExpanded = false;
			menu.expandTransition = nil;

			Runtime:dispatchEvent({
				name = "FRC_MenuClose",
				type = "FRC_SettingsBar",
				time = 400
			});
		end });

	else
		-- expand menu
		menu.expandTransition = transition.to(menu.menuItems, { time=400, x=menu.menuItems.xShown, alpha=1.0, transition=easing.inOutExpo, onComplete=function()
			self:setFocusState(true);
			menu.isExpanded = true;
			menu.expandTransition = nil;
		end });

		Runtime:dispatchEvent({
			name = "FRC_MenuExpand",
			type = "FRC_SettingsBar",
			time = 400
		});
	end
end

local function show(self)
	if (self.hideTimer) then timer.cancel(self.hideTimer); self.hideTimer = nil; end

	self.hideTimer = timer.performWithDelay(5000, function()
		self.hideTimer = nil;
		self:hide();
	end, 1);

	if (not self.isHidden) then self.alpha = 1.0; return; end
	if (self.showTransition) then transition.cancel(self.showTransition); self.showTransition = nil; end
	self.showTransition = transition.to(self, { time=400, alpha=1.0, onComplete=function()
		self.isHidden = false;
	end });
end

local function hide(self, doNotDispatch)
	if (self.hideTimer) then timer.cancel(self.hideTimer); self.hideTimer = nil; end
	if (self.isHidden) then self.alpha = 0; return; end
	if (self.showTransition) then transition.cancel(self.showTransition); self.showTransition = nil; end

	self.showTransition = transition.to(self, { time=400, alpha=0, onComplete=function()
		self.isHidden = true;
		self.menuItems.x = self.menuItems.xHidden;
		self.menuItems.alpha = 0;
		self.isExpanded = false;
		self.toggleButton:setFocusState(false);

		if (not doNotDispatch) then
			Runtime:dispatchEvent({
				name = "FRC_MenuClose",
				type = "FRC_SettingsBar",
				time = 400
			});
		end
	end });
end

local function pauseHideTimer(self)
	if (self.hideTimer) then timer.pause(self.hideTimer); end
end

local function resumeHideTimer(self)
	if (self.hideTimer) then timer.resume(self.hideTimer); end
end

local function getItem(self, id)
	if (not id) then return; end
	local item;

	for i=1,self.menuItems.numChildren do
		if (self.menuItems[i].id and self.menuItems[i].id == id) then
			item = self.menuItems[i];
			break;
		end
	end

	return item;
end

local function dispose(self)
	if (self.isDisposed) then return; end
	if (self.hideTimer) then timer.cancel(self.hideTimer); self.hideTimer = nil; end
	if (self.showTransition) then transition.cancel(self.showTransition); self.showTransition = nil; end
	if (self.expandTransition) then transition.cancel(self.expandTransition); self.expandTransition = nil; end

	if (self.toggleButton) then
		self.toggleButton:dispose();
		self.toggleButton = nil;
	end

	if ((self.menuItems) and (self.menuItems.numChildren > 0)) then
		for i=self.menuItems.numChildren,1,-1 do
			if (self.menuItems[i].dispose) then
				self.menuItems[i]:dispose();
			else
				self.menuItems[i]:removeSelf();
			end
		end
		self.menuItems:removeSelf();
		self.menuItems = nil;
	end

	Runtime:removeEventListener("FRC_MenuExpand", self.onMenuExpand);

	if (activeMenu == self) then
		activeMenu = nil;
	end

	if (self.menuActivator) then
		self.menuActivator:removeSelf(); self.menuActivator = nil;
	end
	self:removeSelf();
	collectgarbage("collect");
	self.isDisposed = true;
end

FRC_SettingsBar.new = function(args)
	checkoptions.callee = 'FRC_SettingsBar.new';
	local options = checkoptions.check(args, requiredOptions, defaultOptions);
	local screenW, screenH = FRC_Layout.getScreenDimensions();
	if (not options.imageDown) then
		options.imageDown = options.imageUp;
	end

	local menuGroup = display.newGroup();
	local screenOverlayGroup = display.newGroup(); menuGroup:insert(screenOverlayGroup)
	local menuItems = display.newGroup(); menuGroup:insert(menuItems);

	local toggleButton = ui.button.new({
		id = options.id,
		imageUp = options.imageUp,
		imageDown = options.imageDown,
		focusState = options.focusState,
		disabled = options.disabled,
		width = options.buttonWidth,
		height = options.buttonHeight,
		onPress = function(e) menuGroup:show(); onMenuTogglePress(e); end,
		onRelease = onMenuToggleRelease
	});
	menuGroup:insert(toggleButton);

	if (options.right) then
		FRC_Layout.alignToRight(toggleButton, options.right);
	elseif (options.left) then
		FRC_Layout.alignToLeft(toggleButton, options.left);
	end

	if (options.bottom) then
		FRC_Layout.alignToBottom(toggleButton, options.bottom);
	elseif (options.top) then
		FRC_Layout.alignToTop(toggleButton, options.top);
	end

	-- Create sub-menu buttons
	local x, y = toggleButton.x, toggleButton.y;
	for i=#options.buttons,1,-1 do
		local button = ui.button.new({
			id = options.buttons[i].id,
			imageUp = options.buttons[i].imageUp,
			imageDown = options.buttons[i].imageDown,
			focusState = options.buttons[i].focusState,
			disabled = options.buttons[i].disabled,
			width = options.buttonWidth,
			height = options.buttonHeight,
			onPress = function(e)
				menuGroup:show();
				if (e.target.onPress) then e.target.onPress(e); end
			end,
			onRelease = options.buttons[i].onRelease
		});
		button.onPress = options.buttons[i].onPress;
		if (options.buttons[i].isFocused) then
			button:setFocusState(true);
		end
		if (options.buttons[i].isDisabled) then
			button:setDisabledState(true);
		end
		menuItems:insert(button);
		x = x - button.contentWidth - options.buttonPadding;
		button.x = x;
		button.y = y;
	end

	local bgRect = display.newRoundedRect(0, 0, options.right + (options.buttonWidth * (#options.buttons + 1)) + (options.buttonPadding * #options.buttons) + options.right + (options.buttonPadding * 0.5) + 10, options.top + options.buttonHeight + (options.top) + 10, 11);
	bgRect:setFillColor( unpack(options.bgColor) );
	menuItems:insert(1, bgRect);
	bgRect.x = screenW - (bgRect.width * 0.5) - ((screenW - display.contentWidth) * 0.5) + 15;
	bgRect.y = (bgRect.height * 0.5) - ((screenH - display.contentHeight) * 0.5) - 10;

	menuItems.xShown = menuItems.x;
	menuItems.xHidden = menuItems.x + bgRect.width * 0.5;
	menuItems.x = menuItems.xHidden;
	menuItems.alpha = 0;

	-- create background overlay to capture touches behind everything else
	menuGroup.menuActivator = display.newRect(0, 0, screenW, screenH);
	menuGroup.menuActivator.isVisible = false;
	menuGroup.menuActivator.isHitTestable = true;
	options.parent:insert(2, menuGroup.menuActivator);
	--options.parent:insert(menuGroup);
	menuGroup.menuActivator.x = display.contentCenterX;
	menuGroup.menuActivator.y = display.contentCenterY;

	menuGroup.menuActivator:addEventListener('touch', function(event)
		if (event.phase == "began") then
			if (menuGroup.isHidden) then
				menuGroup:show();
			else
				menuGroup:hide();
			end
		end
		return false;
	end);

	-- properties and methods
	menuGroup.menuItems = menuItems;
	menuGroup.toggleButton = toggleButton;
	menuGroup.alpha = 0;
	menuGroup.isHidden = true;
	menuGroup.isExpanded = false;
	menuGroup.show = show;
	menuGroup.hide = hide;
	menuGroup.pauseHideTimer = pauseHideTimer;
	menuGroup.resumeHideTimer = resumeHideTimer;
	menuGroup.getItem = getItem;
	menuGroup.dispose = function(self) pcall(dispose, self); end
	menuGroup.toggleMenu = function()
		onMenuToggleRelease({target=toggleButton});
	end
	menuGroup.onMenuExpand = function(event)
		if (event.type ~= "FRC_SettingsBar") then
			if (menuGroup.isExpanded) then
				menuGroup.expandTransition = transition.to(menuGroup.menuItems, { time=400, x=menuGroup.menuItems.xHidden, alpha=0, transition=easing.inOutExpo, onComplete=function()
					menuGroup.toggleButton:setFocusState(false);
					menuGroup.isExpanded = false;
					menuGroup.expandTransition = nil;
				end });
			end
		end
	end
	Runtime:addEventListener("FRC_MenuExpand", menuGroup.onMenuExpand);

	activeMenu = menuGroup;
	return menuGroup;
end

function FRC_SettingsBar.onUnrelatedTouch(event)
	if (not activeMenu) then return; end
	activeMenu:hide();
end

function FRC_SettingsBar.onSimulatedTouch(event)
	if (activeMenu.menuItems) then
		-- unpack the event target
		local targetid = event.targetid;
		for i=1, activeMenu.menuItems.numChildren do
			if (activeMenu.menuItems[i].id == targetid) then
				activeMenu.menuItems[i]:dispatchEvent( { name = 'press', target = activeMenu.menuItems[i] } );
			end
		end
	end
end

FRC_SettingsBar:addEventListener('unrelatedTouch', FRC_SettingsBar.onUnrelatedTouch);
FRC_SettingsBar:addEventListener('simulatedTouch', FRC_SettingsBar.onSimulatedTouch);

return FRC_SettingsBar;
