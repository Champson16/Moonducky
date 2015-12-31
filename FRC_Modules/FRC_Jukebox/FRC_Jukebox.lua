local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_AnimationManager = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_Video = require('FRC_Modules.FRC_Video.FRC_Video');

local ui = require('ui');
local settings = require('FRC_Modules.FRC_Jukebox.FRC_Jukebox_Settings');
local analytics = import("analytics");

local FRC_Jukebox = {};

local animationXMLBase = 'FRC_Assets/MDMT_Assets/Animation/XMLData/';
local animationImageBase = 'FRC_Assets/MDMT_Assets/Animation/Images/';

local jukeboxBackgroundAnimationSequences = {};

local imageBase = 'FRC_Assets/FRC_Jukebox/Images/';
local videoBase = 'FRC_Assets/MDMT_Assets/Videos/';

local videoPlayer;
local jukeboxSounds;

-- local function UI(key)
-- 	return FRC_Jukebox_Settings.UI[key];
-- end
--
-- local function DATA(key, baseDir)
-- 	baseDir = baseDir or system.ResourceDirectory;
-- 	return FRC_DataLib.readJSON(FRC_Jukebox_Settings.DATA[key], baseDir);
-- end

FRC_Jukebox.new = function(options)
	options = options or {};

	local screenW, screenH = FRC_Layout.getScreenDimensions();
	local borderSize = settings.DEFAULTS.BORDER_SIZE;
	local elementPadding = settings.DEFAULTS.ELEMENT_PADDING;

	local jukeboxGroup = display.newContainer(screenW, screenH); -- display.newGroup();
	FRC_Jukebox.jukeboxGroup = jukeboxGroup;

	local cancelTouch = function(e)
		if (e.phase == 'began') then
			jukeboxGroup:dispatchEvent({ name = "cancelled" });
         if( options and options.onCancel ) then
            options.onCancel()
         end
			FRC_Jukebox:dispose();
		end
		return true;
	end

  -- modal background
	local modalBackground = display.newRect(jukeboxGroup, 0, 0, screenW, screenH);
	modalBackground:setFillColor(0, 0, 0, 0.5);
	modalBackground.isHitTestable = true;
	modalBackground.x, modalBackground.y = 0, 0;
	modalBackground.touch = function() return true; end
	modalBackground:addEventListener('touch', modalBackground.touch);
	modalBackground:addEventListener('tap', modalBackground.touch);
	FRC_Jukebox.modalBackground = modalBackground;

	-- setup the frame and background
	local border = display.newRect(jukeboxGroup, 0, 0, options.width or screenW, options.height or screenH);
	border:setFillColor(1.0, 1.0, 1.0, 0.80);
	border.x, border.y = 0, 0;

	local back = display.newRect(jukeboxGroup, 0, 0, border.width - (borderSize * 2), border.height - (borderSize * 2));
	back:setFillColor(.188235294, .188235294, .188235294, 1.0);
	back.x, back.y = 0, 0;
	jukeboxGroup.winWidth = back.width;
	jukeboxGroup.winHeight = back.height;

  -- setup the background animation
	local jukeboxBackgroundAnimationFiles = {
		"MDMT_Jukebox_Background.xml"
	}

	local animationContainer = display.newContainer( jukeboxGroup.winWidth, jukeboxGroup.winHeight );
	-- animationContainer:translate(display.contentWidth*0.5, display.contentHeight*0.5 );
	print("animationContainer", animationContainer.width, animationContainer.height);
	print("animationContainer", animationContainer.x, animationContainer.y);

	jukeboxBackgroundAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(jukeboxBackgroundAnimationFiles, animationXMLBase, animationImageBase);
	animationContainer:insert(jukeboxBackgroundAnimationSequences);
	-- FRC_Layout.placeAnimation( jukeboxBackgroundAnimationSequences, { x = -jukeboxGroup.winWidth/2, y = -jukeboxGroup.winHeight/2 }, false );
	FRC_Layout.placeAnimation( jukeboxBackgroundAnimationSequences, { x = -(screenW/2), y = -(screenH/2) }, false ); -- temp version based on unscaled anim
	print("jukeboxBackgroundAnimationSequences", jukeboxBackgroundAnimationSequences.width, jukeboxBackgroundAnimationSequences.height);
	print("jukeboxBackgroundAnimationSequences", jukeboxBackgroundAnimationSequences.x, jukeboxBackgroundAnimationSequences.y);

	for i=1, jukeboxBackgroundAnimationSequences.numChildren do
		jukeboxBackgroundAnimationSequences[i]:play({
			showLastFrame = false,
			playBackward = false,
			autoLoop = true,
			palindromicLoop = false,
			delay = 0,
			intervalTime = 30,
			maxIterations = 1,
			transformations = { xScaleTransform = jukeboxGroup.winWidth / jukeboxBackgroundAnimationSequences.width,
			yScaleTransform = jukeboxGroup.winHeight / jukeboxBackgroundAnimationSequences.height }
		});
	end

	jukeboxGroup:insert(animationContainer);

	-- startover control
	-- pause control
	-- ticker box
	-- ticker text
	local tickerText = "COMING IN THE NEXT BUILD WILL BE AN INTERACTIVE JUKEBOX WHICH WILL SHOW SONG TITLES IN A TICKER DISPLAY LIKE THIS!"

	local chunkSize=160
	-- This variable defines the number of characters by which to divide long ticker text
	-- strings. This prevents errors by ensuring that your ticker's width doesn't exceed the
	-- device's maximum display object width. If your ticker isn't displaying properly, decrease
	-- this number. But unless you are using an absurdly large font, you shouldn't need to adjust
	-- this variable.

	-- local tickerGroupContainer = display.newContainer( jukeboxGroup, jukeboxGroup.winWidth, FRC_Layout.getScaleFactor() * 40 );
	local tickerGroup = display.newGroup();
	-- tickerGroupContainer:insert(tickerGroup);

	local startTickerTextCrawl = function()

		local tickerLength = string.len(tickerText)
		local objectCount = math.ceil(tickerLength/chunkSize)

		for i=1,objectCount do
			local ticker = display.newText(string.sub(tickerText, chunkSize*(i-1)+1, chunkSize*i),0,0,"ticker",28)

			if (i == 1) then
				ticker.x = display.contentWidth/2; -- TODO change this
			else
				ticker.x = tickerGroup[i-1].x + tickerGroup[i-1].contentWidth
			end

			ticker.y = jukeboxGroup.height / 2 + (FRC_Layout.getScaleFactor() * 38);
			ticker:setTextColor(255,255,255)
			tickerGroup:insert(ticker)
			ticker = nil
		end

		local textMove = function()
			if tickerGroup then
				if tickerGroup.x + tickerGroup.contentWidth + display.contentWidth > 0 then
					tickerGroup:translate(-3,0)
				else
					tickerGroup.x = display.contentWidth; -- 0;
				end
			end
		end

		Runtime:addEventListener("enterFrame",textMove)
	end
	FRC_Jukebox.startTickerTextCrawl = startTickerTextCrawl;

	-- print("tickerGroupContainer", tickerGroupContainer.width, tickerGroupContainer.height);
	-- print("tickerGroupContainer", tickerGroupContainer.x, tickerGroupContainer.y);

	local stopTickerTextCrawl = function()
		Runtime:removeEventListener("enterFrame",textMove);
		tickerGroup:removeSelf();
		tickerGroup = nil;
	end
	FRC_Jukebox.stopTickerTextCrawl = stopTickerTextCrawl;

	startTickerTextCrawl(); -- Loads and starts the Text Ticker

	print("tickerGroup", tickerGroup.width, tickerGroup.height);
	print("tickerGroup", tickerGroup.x, tickerGroup.y);

	-- selection box
	-- prev media selector

	local previousMediaButton = ui.button.new({
		imageUp = imageBase .. 'FRC_Jukebox_Button_Previous_up.png',
		imageDown = imageBase .. 'FRC_Jukebox_Button_Previous_down.png',
		imageDisabled = imageBase .. 'FRC_Jukebox_Button_Previous_disabled.png',
		imageFocused = imageBase .. 'FRC_Jukebox_Button_Previous_focused.png',
		width = 128,
		height = 128,
		x = -270,
		y = 185,
		onRelease = function()
			analytics.logEvent("MDMT.Lobby.Jukebox.PreviousMedia");
      -- navigate media
		end
	});
	previousMediaButton.anchorX = 0.5;
	previousMediaButton.anchorY = 0.5;
  jukeboxGroup:insert(previousMediaButton);
  FRC_Layout.placeUI(previousMediaButton)

	-- left media selector
	-- right media selector
	-- next media selector

	local nextMediaButton = ui.button.new({
		imageUp = imageBase .. 'FRC_Jukebox_Button_Next_up.png',
		imageDown = imageBase .. 'FRC_Jukebox_Button_Next_down.png',
		imageDisabled = imageBase .. 'FRC_Jukebox_Button_Next_disabled.png',
		imageFocused = imageBase .. 'FRC_Jukebox_Button_Next_focused.png',
		width = 128,
		height = 128,
		x = 270,
		y = 185,
		onRelease = function()
			analytics.logEvent("MDMT.Lobby.Jukebox.NextMedia");
			-- navigate media
		end
	});
	nextMediaButton.anchorX = 0.5;
	nextMediaButton.anchorY = 0.5;
	jukeboxGroup:insert(nextMediaButton);
	FRC_Layout.placeUI(nextMediaButton)


  --[[
	local thumbImage, baseDirectory, thumbWidth, thumbHeight;
	thumbWidth = settings.DEFAULTS.BLANK_SLOT_WIDTH;
	thumbHeight = settings.DEFAULTS.BLANK_SLOT_HEIGHT;
	local largestThumbWidth = thumbWidth;
	local largestThumbHeight = thumbHeight;

  local pageCount = settings.DEFAULTS.TOTAL_PAGES;
	local j = 1;
	local removeIndexes = {};
	for i=1,pageCount do
		local x, y = 0, 0;
		local max = 0; --settings.UI.PER_PAGE_ROWS * settings.UI.PER_PAGE_COLS;
		if (options.data) then
			max = #options.data;
		end

		local blankCount = 0;
		local totalThumbs = settings.DEFAULTS.PER_PAGE_ROWS * settings.DEFAULTS.PER_PAGE_COLS;

		for row=1,settings.DEFAULTS.PER_PAGE_ROWS do
			x = 0;
			for col=1,settings.DEFAULTS.PER_PAGE_COLS do
				local baseDirectory = system.ResourceDirectory;
				local id = nil;
				local item;

				if ((options.data) and (options.data[j])) then
					item = options.data[j];
					id = item.id;
					thumbImage = id .. item.thumbSuffix;
					if (item.thumbWidth > thumbWidth) then
						largestThumbWidth = item.thumbWidth;
					end
					if (item.thumbHeight > thumbHeight) then
						largestThumbHeight = item.thumbHeight;
					end
					thumbWidth = item.thumbWidth;
					thumbHeight = item.thumbHeight;
					baseDirectory = system.DocumentsDirectory;
				else
					id = nil;
					thumbImage = settings.DEFAULTS.BLANK_SLOT_IMAGE;
					if (settings.DEFAULTS.BLANK_SLOT_WIDTH > thumbWidth) then
						largestThumbWidth = settings.DEFAULTS.BLANK_SLOT_WIDTH;
					end
					if (settings.DEFAULTS.BLANK_SLOT_HEIGHT > thumbHeight) then
						largestThumbHeight = settings.DEFAULTS.BLANK_SLOT_HEIGHT;
					end
					thumbWidth = settings.DEFAULTS.BLANK_SLOT_WIDTH;
					thumbHeight = settings.DEFAULTS.BLANK_SLOT_HEIGHT;
					baseDirectory = system.ResourceDirectory;
				end

				local thumbButton = ui.button.new({
					id = id,
					baseDirectory = baseDirectory,
					imageUp = thumbImage,
					imageDown = thumbImage,
					width = thumbWidth,
					height = thumbHeight,
					pressAlpha = 0.5,
					onRelease = function(e)
						local self = e.target;
						local function proceedToPlay()
							if (options.callback) then
								options.callback({
									id = self.id,
									page = i,
									row = row,
									column = col,
									data = item
								});
							end
						proceedToPlay();
					end
				});
			end
		end
	end
  --]]

	-- close button
	local closeButton = ui.button.new({
		imageUp = settings.DEFAULTS.CLOSE_BUTTON_IMAGE,
		imageDown = settings.DEFAULTS.CLOSE_BUTTON_IMAGE,
		pressAlpha = 0.75,
		width = settings.DEFAULTS.CLOSE_BUTTON_WIDTH,
		height = settings.DEFAULTS.CLOSE_BUTTON_HEIGHT,
		onRelease = function()
			FRC_Jukebox:dispose();
		end
	});
	closeButton.x = -(jukeboxGroup.winWidth * 0.5) - elementPadding + (closeButton.contentWidth * 0.5);
	closeButton.y = -(jukeboxGroup.winHeight * 0.5) - elementPadding + (closeButton.contentHeight * 0.5);
	jukeboxGroup:insert(closeButton);

	jukeboxGroup.dispose = FRC_Jukebox.dispose;

	if (options.title) then
		local titleText = display.newText(popup, options.title, 0, 0, native.systemFontBold, 36);
		titleText:setFillColor(0, 0, 0, 1.0);
		titleText.x = 0;
		titleText.y = -(popup.height * 0.5) + (titleText.contentHeight * 0.5) + (settings.DEFAULTS.THUMBNAIL_SPACING);
	end

	if (options.parent) then options.parent:insert(jukeboxGroup); end
	jukeboxGroup.x, jukeboxGroup.y = display.contentCenterX, display.contentCenterY;
	return jukeboxGroup;

end

FRC_Jukebox.disposeAnimations = function(self)

	-- kill the animation objects
	if (jukeboxBackgroundAnimationSequences) then

		for i=1, jukeboxBackgroundAnimationSequences.numChildren do
			local anim = jukeboxBackgroundAnimationSequences[i];
			if (anim) then
				if (anim.isPlaying) then
					anim:stop();
				end
				anim:dispose();
			end
		end
		jukeboxBackgroundAnimationSequences = nil;
	end
end

FRC_Jukebox.dispose = function(self)
	FRC_Jukebox.modalBackground:removeSelf();
	FRC_Jukebox.stopTickerTextCrawl();
	-- remove the animations
	FRC_Jukebox:disposeAnimations();
	if (FRC_Jukebox.jukeboxGroup) then FRC_Jukebox.jukeboxGroup:removeSelf(); end
end

return FRC_Jukebox;
