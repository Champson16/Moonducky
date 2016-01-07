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
	jukeboxGroup.x, jukeboxGroup.y = 0,0;
	jukeboxGroup.anchorX = 0.5;
	jukeboxGroup.anchorY = 0.5;
	jukeboxGroup.anchorChildren = true;
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
	local border = display.newRect(jukeboxGroup, 0, 0, options.width or screenW * .9, options.height or screenH * .9);
	border:setFillColor(1.0, 1.0, 1.0, 0.80);
	border.x, border.y = 0, 0;

	local back = display.newRect(jukeboxGroup, 0, 0, border.width - (borderSize * 2), border.height - (borderSize * 2));
	back:setFillColor(.188235294, .188235294, .188235294, 1.0);
	back.x, back.y = 0, 0;
	jukeboxGroup.winWidth = back.width;
	jukeboxGroup.winHeight = back.height;
	jukeboxGroup.winX = back.x;
	jukeboxGroup.winY = back.y;
	local jukeboxScaleX = jukeboxGroup.winWidth/1152; -- screenW;
	local jukeboxScaleY = jukeboxGroup.winHeight/768; -- screenH;

  -- setup the jukebox animations
	local jukeboxBackgroundAnimationFiles = {
		"MDMT_Jukebox_Background.xml"
	}
	local jukeboxForegroundAnimationFiles = {
		"MDMT_Jukebox_AnimDiscPlay_d.xml",
		"MDMT_Jukebox_AnimDiscPlay_c.xml",
		"MDMT_Jukebox_AnimDiscPlay_b.xml",
		"MDMT_Jukebox_AnimDiscPlay_a.xml"
	}

	local animationContainer = display.newContainer( jukeboxGroup.winWidth, jukeboxGroup.winHeight );
	-- animationContainer:translate(display.contentWidth*0.5, display.contentHeight*0.5 );

	animationContainer.x, animationContainer.y = jukeboxGroup.winX, jukeboxGroup.winY;
	print("animationContainer", animationContainer.width, animationContainer.height);
	print("animationContainer", animationContainer.x, animationContainer.y);

	jukeboxBackgroundAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(jukeboxBackgroundAnimationFiles, animationXMLBase, animationImageBase);
	animationContainer:insert(jukeboxBackgroundAnimationSequences);
	-- jukeboxGroup:insert(jukeboxBackgroundAnimationSequences);
	-- FRC_Layout.placeAnimation( jukeboxBackgroundAnimationSequences, { x = -jukeboxGroup.winWidth/2, y = -jukeboxGroup.winHeight/2 }, false );
	-- FRC_Layout.placeAnimation( jukeboxBackgroundAnimationSequences, { x = FRC_Layout.getScaleFactor() * -(screenW/2), y = FRC_Layout.getScaleFactor() * -(screenH/2) }, false ); -- temp version based on unscaled anim
	-- FRC_Layout.placeAnimation( jukeboxBackgroundAnimationSequences, { x = 0, y = 0}, false );
	-- jukeboxBackgroundAnimationSequences.anchorX = 0.5;
	-- jukeboxBackgroundAnimationSequences.anchorY = 0.5;

	-- FRC_Layout.placeAnimation( jukeboxBackgroundAnimationSequences, { x = -(576 * jukeboxScaleX), y = -(368 * jukeboxScaleY) }, false );
	-- jukeboxBackgroundAnimationSequences.anchorX, jukeboxBackgroundAnimationSequences.anchorY = 0.5, 0.5;
	-- jukeboxBackgroundAnimationSequences.x, jukeboxBackgroundAnimationSequences.y = -(576 * jukeboxScaleX), -(368 * jukeboxScaleY); -- 0,0;

	-- jukeboxBackgroundAnimationSequences.x, jukeboxBackgroundAnimationSequences.y = -(jukeboxGroup.winWidth * 0.5) + ((screenW - jukeboxGroup.winWidth)/2), -(jukeboxGroup.winHeight * 0.5 + ((screenH - jukeboxGroup.winHeight)/2)); -- 0,0;
	jukeboxBackgroundAnimationSequences.x, jukeboxBackgroundAnimationSequences.y = -(border.width * 0.5), -(border.height * 0.5 + ((screenH - border.height)/2)); -- 0,0;

	jukeboxForegroundAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(jukeboxForegroundAnimationFiles, animationXMLBase, animationImageBase);
	animationContainer:insert(jukeboxForegroundAnimationSequences);
	-- jukeboxGroup:insert(jukeboxForegroundAnimationSequences);
	-- FRC_Layout.placeAnimation( jukeboxBackgroundAnimationSequences, { x = -jukeboxGroup.winWidth/2, y = -jukeboxGroup.winHeight/2 }, false );
	-- FRC_Layout.placeAnimation( jukeboxBackgroundAnimationSequences, { x = FRC_Layout.getScaleFactor() * -(screenW/2), y = FRC_Layout.getScaleFactor() * -(screenH/2) }, false ); -- temp version based on unscaled anim
	-- FRC_Layout.placeAnimation( jukeboxBackgroundAnimationSequences, { x = 0, y = 0}, false );
	-- jukeboxForegroundAnimationSequences.anchorX = 0.5;
	-- jukeboxForegroundAnimationSequences.anchorY = 0.5;

	-- FRC_Layout.placeAnimation( jukeboxForegroundAnimationSequences, { x = -(576 * jukeboxScaleX), y = -(368 * jukeboxScaleY) }, false );

	jukeboxForegroundAnimationSequences.x, jukeboxForegroundAnimationSequences.y = -(border.width * 0.5), -(border.height * 0.5 + ((screenH - border.height)/2)); -- 0,0;


  -- DEBUG
	print("jukeboxBackgroundAnimationSequences", jukeboxBackgroundAnimationSequences.width, jukeboxBackgroundAnimationSequences.height);
	print("jukeboxBackgroundAnimationSequences", jukeboxBackgroundAnimationSequences.x, jukeboxBackgroundAnimationSequences.y);
	print("screen scaleX", screenW/1024);
	print("screen scaleY", screenH/768);
  print("xScaleTransform", jukeboxGroup.winWidth / jukeboxBackgroundAnimationSequences.width);
	print("yScaleTransform", jukeboxGroup.winHeight / jukeboxBackgroundAnimationSequences.height);
	print("jukebox X offset", (screenW - jukeboxGroup.winWidth)/2);

	for i=1, jukeboxBackgroundAnimationSequences.numChildren do
		jukeboxBackgroundAnimationSequences[i]:play({
			showLastFrame = true,
			playBackward = false,
			autoLoop = false,
			palindromicLoop = false,
			delay = 0,
			intervalTime = 30,
			maxIterations = 1,
			-- transformations = { xScaleTransform = jukeboxScaleX, yScaleTransform = jukeboxScaleY }
		});
	end

	jukeboxGroup:insert(animationContainer);
	-- animationContainer.x, animationContainer.y = jukeboxGroup.x, jukeboxGroup.y;
	-- animationContainer:translate( display.contentWidth*0.5, display.contentHeight*0.5 );


  -- TICKER TEXT
	local chunkSize=160
	-- This variable defines the number of characters by which to divide long ticker text
	-- strings. This prevents errors by ensuring that your ticker's width doesn't exceed the
	-- device's maximum display object width. If your ticker isn't displaying properly, decrease
	-- this number. But unless you are using an absurdly large font, you shouldn't need to adjust
	-- this variable.

	local tickerGroupContainer = display.newContainer( jukeboxScaleX * 600, jukeboxScaleY * 44 );
	FRC_Jukebox.tickerGroupContainer = tickerGroupContainer;
	tickerGroupContainer:translate( display.contentWidth*0.5, tickerGroupContainer.height*0.5 );
	local tickerGroup;
	tickerGroupContainer.y = jukeboxGroup.winHeight / 2 + (jukeboxScaleY * 90);

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
						tickerGroup:translate(-2,0); -- shift it to the left
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
			analytics.logEvent("MDMT.Lobby.Jukebox.MediaSelection", { MEDIA_TYPE = "VIDEO", MEDIA_TITLE = mData.MEDIA_TITLE });

			FRC_Jukebox.stopTickerTextCrawl();
			FRC_Jukebox.startTickerTextCrawl(mData.MEDIA_TITLE);
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
			FRC_Jukebox.startTickerTextCrawl(mData.MEDIA_TITLE);
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

			for i=1, jukeboxForegroundAnimationSequences.numChildren do
				jukeboxForegroundAnimationSequences[i]:play({
					showLastFrame = true,
					playBackward = false,
					autoLoop = false,
					palindromicLoop = false,
					delay = 0,
					intervalTime = 30,
					maxIterations = 1,
					-- transformations = { xScaleTransform = ( jukeboxGroup.winWidth/ 1152), yScaleTransform = (jukeboxGroup.winHeight/ 768) },
					onCompletion = function()
						currentAudio:play();
					end
				});
			end
			-- currentAudio:play();
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
				x = -160 * jukeboxScaleX,
				y = 180 * jukeboxScaleY,
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
		  -- FRC_Layout.placeUI(leftMediaButton);
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
				x = 160 * jukeboxScaleX,
				y = 180 * jukeboxScaleY,
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
		  -- FRC_Layout.placeUI(rightMediaButton);
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
		x = -370 * jukeboxScaleX,
		y = 185 * jukeboxScaleY,
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
  -- FRC_Layout.placeUI(previousMediaButton)

	-- next media selector
	nextMediaButton = ui.button.new({
		imageUp = imageBase .. 'FRC_Jukebox_Button_Next_up.png',
		imageDown = imageBase .. 'FRC_Jukebox_Button_Next_down.png',
		imageDisabled = imageBase .. 'FRC_Jukebox_Button_Next_disabled.png',
		imageFocused = imageBase .. 'FRC_Jukebox_Button_Next_focused.png',
		width = 128,
		height = 128,
		x = 370 * jukeboxScaleX,
		y = 195 * jukeboxScaleY,
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
	-- FRC_Layout.placeUI(nextMediaButton)

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
	-- FRC_Layout.placeUI(replayMediaButton)

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
	-- FRC_Layout.placeUI(pauseMediaButton)

  -- show the jukebox media selections
	loadJukeboxPage();

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

	if (options.parent) then
		options.parent:insert(jukeboxGroup);
	end
	-- center the jukebox
	-- jukeboxGroup.anchorX = 0;
	-- jukeboxGroup.anchorY = 0;
	jukeboxGroup.x, jukeboxGroup.y =  display.contentCenterX, display.contentCenterY; -- (screenW - jukeboxGroup.winWidth) * 0.5, (screenH - jukeboxGroup.winHeight) * 0.5; -- display.contentCenterX, display.contentCenterY;
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

	if (jukeboxForegroundAnimationSequences) then
		for i=1, jukeboxForegroundAnimationSequences.numChildren do
			local anim = jukeboxForegroundAnimationSequences[i];
			if (anim) then
				if (anim.isPlaying) then
					anim:stop();
				end
				anim:dispose();
			end
		end
		jukeboxForegroundAnimationSequences = nil;
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
