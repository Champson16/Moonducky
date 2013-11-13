local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local ui = require('FRC_Modules.FRC_UI.FRC_UI');
local FRC_GlobalMenu = {};

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

local requiredOptions = {
	imageUp = 'string',
	buttonWidth = 'number',
	buttonHeight = 'number'
};

local defaultOptions = {
	items = {},
	bgColor = { 0.14, 0.14, 0.14, 1.0 },
	top = 10,
	left = 10
};

local function onMenuToggleRelease(event)
	local self = event.target;
	print('Touched and released menu button.');
end

FRC_GlobalMenu.new = function(args)
	checkoptions.callee = 'FRC_GlobalMenu.new';
	local options = checkoptions.check(args, requiredOptions, defaultOptions);
	local screenW, screenH = FRC_Layout.getScreenDimensions();
	if (not options.imageDown) then
		options.imageDown = options.imageUp;
	end

	local menuGroup = display.newGroup();
	local screenOverlayGroup = display.newGroup(); menuGroup:insert(screenOverlayGroup)
	local menuItems = display.newGroup(); menuGroup:insert(menuItems);

	local toggleButton = ui.button.new({
		imageUp = options.imageUp,
		imageDown = options.imageDown,
		focusState = options.focusState,
		disabled = options.disabled,
		width = options.buttonWidth,
		height = options.buttonHeight,
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

	return menuGroup;
end

return FRC_GlobalMenu;