local storyboard = require('storyboard');
local FRC_SplashScreen_Settings = require('FRC_Modules.FRC_SplashScreen.FRC_SplashScreen_Settings');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_SplashScreen = {};

FRC_SplashScreen.new = function(nextScene)
	display.setDefault("background", 1.0, 1.0, 1.0);
  local screenW, screenH = FRC_Layout.getScreenDimensions();
	local splashGroup = display.newGroup();
  local currentVideoIndex = 0; -- the first video is at index 1
  local currentVideoLength = 0;

	function splashGroup.freeMemory()
		if (splashGroup.currentVideo) then
      -- native.showAlert('DEBUG', 'Pausing video', { "OK" });
      splashGroup.currentVideo:removeEventListener("video", splashGroup.playVideo );
			splashGroup.currentVideo:pause();
      -- native.showAlert('DEBUG', 'Removing video', { "OK" });
			splashGroup.currentVideo:removeSelf();
			if (splashGroup.currentVideo) then splashGroup.currentVideo = nil; end
		end
    if (splashGroup.skipVideoButton) then
      splashGroup.skipVideoButton:removeEventListener('touch', splashGroup.skipSplash );
      splashGroup.skipVideoButton:removeSelf();
      if (splashGroup.skipVideoButton) then splashGroup.skipVideoButton = nil; end
    end
    if (splashGroup.videoTimer) then
      timer.cancel(splashGroup.videoTimer);
    end
	end

	function splashGroup.gotoNextScene()
    splashGroup.freeMemory();
    splashGroup:removeSelf();
    if (splashGroup) then splashGroup = nil; end
    -- native.showAlert('DEBUG', 'Leaving for scene: '.. nextScene, { "OK" });
    storyboard.gotoScene(nextScene);
	end

  function splashGroup.skipSplash(event)
    if (event.phase == "began") then
      -- skip the videos
      splashGroup.gotoNextScene();
    end
    return true;
  end

  local bg = display.newRect(splashGroup, 0, 0, screenW, screenH);
  bg:setFillColor(1.0);
  FRC_Layout.alignToLeft(bg);
  FRC_Layout.alignToTop(bg);

  function splashGroup.initVideo(videoData)
    local videoFile = videoData.HD_VIDEO_PATH;
    local videoDimensions = videoData.HD_VIDEO_SIZE;
    local videoScale = videoData.VIDEO_SCALE;
    -- forward declarations
    local xs, ys;
    if ((ANDROID_DEVICE) or (NOOK_DEVICE) or (KINDLE_DEVICE)) then
      -- android devices generally require lower res videos for backward compatibility
      videoFile = videoData.SD_VIDEO_PATH;
      videoDimensions = videoData.SD_VIDEO_SIZE;
    end
    -- DEBUG
    dprint("Playing video: ", videoFile);
    if (videoFile) then
      -- we're going to fill the screen
      splashGroup.currentVideo = native.newVideo(0, 0, videoDimensions.width, videoDimensions.height);
      splashGroup.currentVideo:load(videoFile);
      if (videoScale == "FULLSCREEN") then
        -- FRC_Layout.scaleToFit(splashGroup);
        -- figure out the scale
        xs = display.actualContentWidth/splashGroup.currentVideo.contentWidth;
        ys = display.actualContentHeight/splashGroup.currentVideo.contentHeight;
        splashGroup.currentVideo.xScale = xs;
        splashGroup.currentVideo.yScale = ys;
        -- native.showAlert('VIDEO SCALING', 'd.pWidth: ' .. display.pixelWidth .. 'd.pHeight: ' ..display.pixelHeight .. 'cVideo.width: ' .. splashGroup.currentVideo.width .. 'cVideo.height: ' ..splashGroup.currentVideo.height .. 'd.cWidth: ' .. display.contentWidth .. 'videoDimensions.width: ' .. videoDimensions.width .. 'd.cHeight: ' .. display.contentHeight .. 'videoDimensions.height: ' .. videoDimensions.height .. ' xs/ys: ' .. xs .. '/' .. ys , { "OK" });
      elseif (videoScale == "LETTERBOX") then
        -- do nothing for now
      else
        -- do nothing for now
      end
      splashGroup.currentVideo.x = display.contentCenterX; -- Width * 0.5;
      splashGroup.currentVideo.y = display.contentCenterY; -- Height * 0.5;
      splashGroup.currentVideo:addEventListener("video", splashGroup.playVideo );
      splashGroup.skipVideoButton = display.newRect(splashGroup, 0, 0, screenW, screenH);
      splashGroup.skipVideoButton.isVisible = false;
      splashGroup.skipVideoButton.anchorX = 0.5;
      splashGroup.skipVideoButton.anchorY = 0.5;
      splashGroup.skipVideoButton.x, splashGroup.skipVideoButton.y = display.contentCenterX, display.contentCenterY;
      splashGroup.skipVideoButton:addEventListener('touch', splashGroup.skipSplash );
      splashGroup.skipVideoButton.isHitTestable = true;
    else
      splashGroup.gotoNextScene();
    end
  end

  function splashGroup.playVideo(event)
    if (event.phase == "ready") then
      splashGroup.currentVideo:play();
      splashGroup.currentVideo:removeEventListener("video", splashGroup.playVideo );
      splashGroup.videoTimer = timer.performWithDelay(currentVideoLength, splashGroup.getNextVideo, 1);
    end
  end

  -- ok so we are on device and we have videos to play
  -- let's play them one at a time
  function splashGroup.getNextVideo()
     
    splashGroup.freeMemory();
    currentVideoIndex = currentVideoIndex + 1;
    local nextVideoData = FRC_SplashScreen_Settings.DATA.VIDEOS[currentVideoIndex];
    if nextVideoData then
      -- DEBUG
      print(nextVideoData.HD_VIDEO_PATH, nextVideoData.SD_VIDEO_PATH,nextVideoData.VIDEO_LENGTH);
      currentVideoLength = nextVideoData.VIDEO_LENGTH;
      splashGroup.initVideo(nextVideoData);
    else
      -- no more videos to play
      splashGroup.gotoNextScene();
    end
  end

  -- check to see if we even have videos to play
  -- first, if we are in the simulator, nevermind
  if ( ON_SIMULATOR ) then
    splashGroup.gotoNextScene();
  else
    -- next, find out whether or not we have videos
    if (not FRC_SplashScreen_Settings.DATA.VIDEOS) then
      -- no videos so let's move on
      splashGroup.gotoNextScene();
    else
      -- there are videos defined, let's play them
      splashGroup.getNextVideo();
    end
  end

	return splashGroup;
end

return FRC_SplashScreen;
