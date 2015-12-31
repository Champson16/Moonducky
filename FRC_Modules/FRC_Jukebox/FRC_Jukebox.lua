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

	local currentPageIndex = 1;


	local jukeboxGroup = display.newContainer(screenW, screenH); -- display.newGroup();
	FRC_Jukebox.jukeboxGroup = jukeboxGroup;

	-- forward declarations
	local currentAudio;
	FRC_Jukebox.currentAudio = currentAudio;

	local previousMediaButton;
	local leftMediaButton;
	local rightMediaButton;
	local nextMediaButton;
	local replayMediaButton;
	local pauseMediaButton;

	local jukeboxAudioGroup = FRC_AudioManager:newGroup({
	      name = "jukeboxAudio",
	      maxChannels = 1
	   });
	FRC_Jukebox.jukeboxAudioGroup = jukeboxAudioGroup;

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
	local jukeboxScaleX = jukeboxGroup.winWidth/screenW;
	local jukeboxScaleY = jukeboxGroup.winHeight/screenH;
	-- animationContainer:translate(display.contentWidth*0.5, display.contentHeight*0.5 );
	print("animationContainer", animationContainer.width, animationContainer.height);
	print("animationContainer", animationContainer.x, animationContainer.y);

	jukeboxBackgroundAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(jukeboxBackgroundAnimationFiles, animationXMLBase, animationImageBase);
	animationContainer:insert(jukeboxBackgroundAnimationSequences);
	-- FRC_Layout.placeAnimation( jukeboxBackgroundAnimationSequences, { x = -jukeboxGroup.winWidth/2, y = -jukeboxGroup.winHeight/2 }, false );
	-- FRC_Layout.placeAnimation( jukeboxBackgroundAnimationSequences, { x = FRC_Layout.getScaleFactor() * -(screenW/2), y = FRC_Layout.getScaleFactor() * -(screenH/2) }, false ); -- temp version based on unscaled anim
	-- FRC_Layout.placeAnimation( jukeboxBackgroundAnimationSequences, { x = 0, y = 0}, false );
	jukeboxBackgroundAnimationSequences.anchorX = 0.5;
	jukeboxBackgroundAnimationSequences.anchorY = 0.5;

	FRC_Layout.placeAnimation( jukeboxBackgroundAnimationSequences, { x = -512, y = -384 }, false );

	print("jukeboxBackgroundAnimationSequences", jukeboxBackgroundAnimationSequences.width, jukeboxBackgroundAnimationSequences.height);
	print("jukeboxBackgroundAnimationSequences", jukeboxBackgroundAnimationSequences.x, jukeboxBackgroundAnimationSequences.y);
	print("screen scaleX", screenW/1024);
	print("screen scaleY", screenH/768);
  print("xScaleTransform", (screenW/1024) * (jukeboxGroup.winWidth / jukeboxBackgroundAnimationSequences.width));
	print("yScaleTransform", (screenH/768) * (jukeboxGroup.winHeight / jukeboxBackgroundAnimationSequences.height));

	for i=1, jukeboxBackgroundAnimationSequences.numChildren do
		jukeboxBackgroundAnimationSequences[i]:play({
			showLastFrame = false,
			playBackward = false,
			autoLoop = true,
			palindromicLoop = false,
			delay = 0,
			intervalTime = 30,
			maxIterations = 1,
			transformations = { xScaleTransform = (screenW/1024) * (jukeboxGroup.winWidth / jukeboxBackgroundAnimationSequences.width),
			yScaleTransform = (screenH/768) * (jukeboxGroup.winHeight / jukeboxBackgroundAnimationSequences.height) }
		});
	end

	jukeboxGroup:insert(animationContainer);

  -- TICKER TEXT
	local chunkSize=160
	-- This variable defines the number of characters by which to divide long ticker text
	-- strings. This prevents errors by ensuring that your ticker's width doesn't exceed the
	-- device's maximum display object width. If your ticker isn't displaying properly, decrease
	-- this number. But unless you are using an absurdly large font, you shouldn't need to adjust
	-- this variable.

	local tickerGroupContainer = display.newContainer( FRC_Layout.getScaleFactor() * 500, FRC_Layout.getScaleFactor() * 44 );
	FRC_Jukebox.tickerGroupContainer = tickerGroupContainer;
	tickerGroupContainer:translate( display.contentWidth*0.5, tickerGroupContainer.height*0.5 );
	local tickerGroup;
	tickerGroupContainer.y = jukeboxGroup.height / 2 + (FRC_Layout.getScaleFactor() * 35);

	local startTickerTextCrawl = function(text)
		tickerGroup = display.newGroup();
		tickerGroupContainer:insert(tickerGroup);

		local tickerText = text or "WELCOME TO THE MOONDUCKY MUSIC THEATRE";

		local tickerLength = string.len(tickerText)
		local objectCount = math.ceil(tickerLength/chunkSize)

		for i=1,objectCount do
			local ticker = display.newText(string.sub(tickerText, chunkSize*(i-1)+1, chunkSize*i),0,0,"ticker",32)

			if (i == 1) then
				ticker.x = jukeboxGroup.winWidth/2;
			else
				ticker.x = tickerGroup[i-1].x + tickerGroup[i-1].contentWidth;
			end

			ticker:setTextColor(255,255,255);
			tickerGroup:insert(ticker);
			ticker = nil;
		end

		local textMove = function()
			if tickerGroupContainer then
				if tickerGroup then
					if tickerGroup.x + tickerGroup.contentWidth + tickerGroupContainer.contentWidth > 0 then
						tickerGroup:translate(-1,0); -- shift it to the left
					else
						tickerGroup.x = 0; -- tickerGroupContainer.contentWidth; -- 0;
					end
				end
			end
		end
		FRC_Jukebox.textMove = textMove;
		Runtime:addEventListener("enterFrame",FRC_Jukebox.textMove)
	end
	FRC_Jukebox.startTickerTextCrawl = startTickerTextCrawl;

	local stopTickerTextCrawl = function()
		Runtime:removeEventListener("enterFrame",FRC_Jukebox.textMove);
		for i=tickerGroup.numChildren,1,-1 do
			if (tickerGroup[i].remove) then
				tickerGroup[i]:remove();
			end
		end
		tickerGroup:removeSelf();
		tickerGroup = nil;
	end
	FRC_Jukebox.stopTickerTextCrawl = stopTickerTextCrawl;

	startTickerTextCrawl(); -- Loads and starts the Text Ticker

	-- MEDIA HANDLING FUNCTIONS AND LAYOUT
	local videoPlaybackComplete = function(event)
		-- reEnableSound()

		-- if this function was called directly, we don't need to remove the listener
		if (event) then
			if (jukeboxGroup) then
				jukeboxGroup:removeEventListener('videoComplete', videoPlaybackComplete );
			end
		end

		if (videoPlayer) then
			videoPlayer:removeSelf();
			videoPlayer = nil;
		end
		return true
	end

	-- build the media display (for the first two items)
	local mediaData = settings.DATA.MEDIA;
	local pageCount = math.ceil(#mediaData / 2);
	local jukeboxPage = 1;

	local playJukeboxMedia = function(itemID)
		-- shut down any active audio
		jukeboxAudioGroup:stop();
		-- remove active track
		if currentAudio then
			jukeboxAudioGroup:removeHandle(currentAudio);
		end

		local mData = mediaData[itemID];
		if not mData then return; end

		-- each button has a MEDIA_TYPE
		if mData.MEDIA_TYPE == "VIDEO" then

			-- onRelease will playMedia and pass the indexID for the button
			-- playMedia function will call either FRC_Video or FRC_AudioManager
			local videoData = {
			HD_VIDEO_PATH = videoBase .. mData.HD_VIDEO_PATH,
			HD_VIDEO_SIZE = mData.HD_VIDEO_SIZE,
			SD_VIDEO_PATH = videoBase .. mData.SD_VIDEO_PATH,
			SD_VIDEO_SIZE = mData.SD_VIDEO_SIZE,
			VIDEO_SCALE = mData.VIDEO_SCALE,
			VIDEO_LENGTH = mData.VIDEO_LENGTH };

			videoPlayer = FRC_Video.new(jukeboxGroup, videoData);
			if videoPlayer then
				jukeboxGroup:addEventListener('videoComplete', videoPlaybackComplete );
			else
				-- this will fire because we are running in the Simulator and the video playback ends before it begins!
				videoPlaybackComplete();
			end
		elseif mData.MEDIA_TYPE == "AUDIO" then
			FRC_Jukebox.stopTickerTextCrawl();
			FRC_Jukebox.startTickerTextCrawl(mData.SONG_TITLE);
			-- if MEDIA_TYPE== "SONG" then enable display of replayMedia and pauseMedia controls
			-- replayMedia.isVisible = true;
			-- pauseMedia.isVisible = true;
			-- play the AUDIO
			currentAudio = FRC_AudioManager:newHandle({
						name = "song",
						path = "FRC_Assets/MDMT_Assets/Audio/" .. mData.AUDIO_PATH,
						group = "jukeboxAudio",
						loadMethod = "loadStream"
				 });
			currentAudio:play();
		end
	end


	local loadJukeboxPage = function(pageIndex)
		local pageIndex = pageIndex or currentPageIndex;
		currentPageIndex = pageIndex;
		-- set up the left media button
		-- set up the right media button
		-- decide whether or not to disable the prev or next media buttons
		if pageIndex == 1 then
		  previousMediaButton:setDisabledState(true);
		else
			previousMediaButton:setDisabledState(false);
		end
		if pageIndex == pageCount then
			nextMediaButton:setDisabledState(true);
		else
			nextMediaButton:setDisabledState(false);
		end
		-- get the data for the buttons
		local leftButtonDataIndex = (pageIndex * 2) - 1;
		if leftMediaButton then
			if (leftMediaButton.removeSelf) then
				leftMediaButton:removeSelf();
				leftMediaButton = nil
			end
		end

		if (leftButtonDataIndex > 0 and leftButtonDataIndex <= #mediaData) then
			-- we have a valid index position
			-- get the DATA
			local leftButtonData = mediaData[leftButtonDataIndex];
			-- make the button

			leftMediaButton = ui.button.new({
				id = leftButtonDataIndex,
				imageUp = imageBase .. leftButtonData.POSTER_FRAME,
				imageDown = imageBase .. leftButtonData.POSTER_FRAME,
				width = 225, -- 274,
				height = 171, -- 208,
				x = -130,
				y = 180,
				onRelease = function(event)
					local self = event.target;
					analytics.logEvent("MDMT.Lobby.Jukebox.MediaSelection");
		      -- play media
					playJukeboxMedia(self.id)
				end
			});
			leftMediaButton.anchorX = 0.5;
			leftMediaButton.anchorY = 0.5;
		  jukeboxGroup:insert(leftMediaButton);
		  FRC_Layout.placeUI(leftMediaButton);
		end

		local rightButtonDataIndex = pageIndex * 2;
		if (rightMediaButton) then
			if (rightMediaButton.removeSelf) then
				rightMediaButton:removeSelf();
				rightMediaButton = nil
			end
		end
		-- in case there are an odd number of items, the right media item may be blank
		if (rightButtonDataIndex > 0 and rightButtonDataIndex <= #mediaData) then
			-- we have a valid index position
			-- get the DATA
			local rightButtonData = mediaData[rightButtonDataIndex];
			-- make the button

			rightMediaButton = ui.button.new({
				id = rightButtonDataIndex,
				imageUp = imageBase .. rightButtonData.POSTER_FRAME,
				imageDown = imageBase .. rightButtonData.POSTER_FRAME,
				width = 225, -- 274,
				height = 171, -- 208,
				x = 130,
				y = 180,
				onRelease = function(event)
					local self = event.target;
					analytics.logEvent("MDMT.Lobby.Jukebox.MediaSelection");
		      -- play media
					playJukeboxMedia(self.id)
				end
			});
			rightMediaButton.anchorX = 0.5;
			rightMediaButton.anchorY = 0.5;
		  jukeboxGroup:insert(rightMediaButton);
		  FRC_Layout.placeUI(rightMediaButton);
		end

	end

	-- prev media selector
	previousMediaButton = ui.button.new({
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
			if currentPageIndex > 1 then
				currentPageIndex = currentPageIndex - 1;
				loadJukeboxPage();
			end
		end
	});
	previousMediaButton.anchorX = 0.5;
	previousMediaButton.anchorY = 0.5;
  jukeboxGroup:insert(previousMediaButton);
	jukeboxGroup.previousMediaButton = previousMediaButton;
  FRC_Layout.placeUI(previousMediaButton)

	-- next media selector
	nextMediaButton = ui.button.new({
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
			if currentPageIndex < pageCount then
				currentPageIndex = currentPageIndex + 1;
				loadJukeboxPage();
			end
		end
	});
	nextMediaButton.anchorX = 0.5;
	nextMediaButton.anchorY = 0.5;
	jukeboxGroup:insert(nextMediaButton);
	jukeboxGroup.nextMediaButton = nextMediaButton;
	FRC_Layout.placeUI(nextMediaButton)

	-- replay media
	replayMediaButton = ui.button.new({
		imageUp = imageBase .. 'FRC_Jukebox_Button_Replay_up.png',
		imageDown = imageBase .. 'FRC_Jukebox_Button_Replay_down.png',
		imageDisabled = imageBase .. 'FRC_Jukebox_Button_Replay_disabled.png',
		imageFocused = imageBase .. 'FRC_Jukebox_Button_Replay_focused.png',
		width = 96,
		height = 96,
		x = -290,
		y = 28,
		onRelease = function()
			analytics.logEvent("MDMT.Lobby.Jukebox.ReplayMedia");
			-- navigate media
			if (currentAudio) then
        audio.rewind(currentAudio);
      end
		end
	});
	replayMediaButton.anchorX = 0.5;
	replayMediaButton.anchorY = 0.5;
	jukeboxGroup:insert(replayMediaButton);
	jukeboxGroup.replayMediaButton = replayMediaButton;
	FRC_Layout.placeUI(replayMediaButton)

	-- pause media
	pauseMediaButton = ui.button.new({
		imageUp = imageBase .. 'FRC_Jukebox_Button_Pause_up.png',
		imageDown = imageBase .. 'FRC_Jukebox_Button_Pause_down.png',
		imageDisabled = imageBase .. 'FRC_Jukebox_Button_Pause_disabled.png',
		imageFocused = imageBase .. 'FRC_Jukebox_Button_Pause_focused.png',
		width = 96,
		height = 96,
		x = 290,
		y = 28,
		onRelease = function()
			analytics.logEvent("MDMT.Lobby.Jukebox.PauseMedia");
			-- navigate media
			if (audio.isChannelPaused(currentAudio.channel)) then
				print("resuming jukebox audio"); -- DEBUG
				currentAudio:resume();
			else
				print("pausing jukebox audio"); -- DEBUG
        currentAudio:pause();
      end
		end
	});
	pauseMediaButton.anchorX = 0.5;
	pauseMediaButton.anchorY = 0.5;
	jukeboxGroup:insert(pauseMediaButton);
	jukeboxGroup.pauseMediaButton = pauseMediaButton;
	FRC_Layout.placeUI(pauseMediaButton)

  -- show the jukebox media selections
	loadJukeboxPage();




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
	FRC_Jukebox.jukeboxAudioGroup:stop();
	-- remove active track
	if FRC_Jukebox.currentAudio then
		FRC_Jukebox.jukeboxAudioGroup:removeHandle(FRC_Jukebox.currentAudio);
	end
	FRC_Jukebox.modalBackground:removeSelf();
	FRC_Jukebox.stopTickerTextCrawl();
	FRC_Jukebox.tickerGroupContainer:removeSelf();
	FRC_Jukebox.tickerGroupContainer = nil;
	-- remove the animations
	FRC_Jukebox:disposeAnimations();
	if (FRC_Jukebox.jukeboxGroup) then FRC_Jukebox.jukeboxGroup:removeSelf(); end
end

return FRC_Jukebox;
