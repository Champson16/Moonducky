local Module = require('Module');
local ui = Module.new('ui');

--- UI button
-- Basic button with up and down states.

ui.button = {
	new = function(args)
		local required = {
			width = 'number',
			height = 'number'
		};

		local defaults = {
			x = 0,
			y = 0,
			pressAlpha = 1.0,
			bgColor = { 1.0, 1.0, 1.0, 0 },
			baseDirectory = system.ResourceDirectory
		};

		local options = ui:checkArgs('ui.button.new', args, required, defaults);
		local button = require('ui.button').new(options);
		return button;
	end
};
ui.newButton = ui.button.new;

--- UI movieclip
-- Flipbook style animations.

ui.movieclip = {
	new = function(args)
		local required = {
			images = 'table',
			width = 'number',
			height = 'number'
		};

		local defaults = {};

		local options = ui:checkArgs('ui.movieclip.new', args, required, defaults);
		local movieclip = require('ui.movieclip').new(options);
		return movieclip;
	end
};
ui.newMovieclip = ui.movieclip.new;

--- UI slider
-- Horizontal slider ui element.

ui.slider = {
	new = function(args)
		local required = {
			width = 'number'
		};

		local defaults = {
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

		local options = ui:checkArgs('ui.slider.new', args, required, defaults);
		local slider = require('ui.slider').new(options);
		return slider;
	end
};
ui.newSlider = ui.slider.new;

--- UI scrollcontainer
-- Container with scrolling content (horizontal/vertical)

ui.scrollcontainer = {
	new = function(args)
		local required = {
			width = 'number',
			height = 'number'
		};

		local defaults = {
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

		local options = ui:checkArgs('ui.scrollcontainer.new', args, required, defaults);
		local scrollcontainer = require('ui.scrollcontainer').new(options);
		return scrollcontainer;
	end
};
ui.newScrollcontainer = ui.scrollcontainer.new;
ui.scrollContainer = ui.scrollcontainer;

--- UI pagecontainer
-- Scrollable pages.

ui.pagecontainer = {
	new = function(args)
		local required = {
			width = 'number',
			height = 'number'
		};

		local defaults = {
			borderWidth = 4,
			borderColor = { 0, 0, 0, 1.0 },
			hidePageIndicator = false,
			pageIndicatorRadius = 4.5,
			pageIndicatorColor = { 0, 0, 0 },
			pageIndicatorSpacing = 9,
			defaultPageBgColor = { 1.0, 1.0, 1.0, 1.0 }
		};

		local options = ui:checkArgs('ui.pagecontainer.new', args, required, defaults);
		local pagecontainer = require('ui.pagecontainer').new(options);
		return pagecontainer;
	end
};
ui.newPagecontainer = ui.pagecontainer.new;

return ui;