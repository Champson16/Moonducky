local storyboard = require('storyboard');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_Video = {};

local ANDROID_DEVICE = (system.getInfo("platformName") == "Android");
local NOOK_DEVICE = (system.getInfo("targetAppStore") == "nook");
local KINDLE_DEVICE = (system.getInfo("targetAppStore") == "amazon");
if ((NOOK_DEVICE) or (KINDLE_DEVICE)) then
  ANDROID_DEVICE = true;
end

FRC_Video.new = function(parentView, videoData)
	display.setDefault("background", 1.0, 1.0, 1.0);
  local screenW, screenH = FRC_Layout.getScreenDimensions();
	local videoGroup = display.newGroup();
  local currentVideoLength = 0;

  local bg = display.newRect(videoGroup, 0, 0, screenW, screenH);
  bg:setFillColor(1.0);
  FRC_Layout.alignToLeft(bg);
  FRC_Layout.alignToTop(bg);
  videoGroup.bg = bg;

	function videoGroup.freeMemory()
		if (videoGroup.currentVideo) then
      -- native.showAlert('DEBUG', 'Pausing video', { "OK" });
      videoGroup.currentVideo:removeEventListener("video", videoGroup.playVideo );
			videoGroup.currentVideo:pause();
      -- native.showAlert('DEBUG', 'Removing video', { "OK" });
			videoGroup.currentVideo:removeSelf();
			if (videoGroup.currentVideo) then videoGroup.currentVideo = nil; end
		end
    if (videoGroup.skipVideoButton) then
      videoGroup.skipVideoButton:removeEventListener('touch', videoGroup.skipVideo );
      videoGroup.skipVideoButton:removeSelf();
      if (videoGroup.skipVideoButton) then videoGroup.skipVideoButton = nil; end
    end
    if (videoGroup.videoTimer) then
      timer.cancel(videoGroup.videoTimer);
    end
	end

  function videoGroup.skipVideo(event)
    if (not event or event.phase == "began") then
      -- let the parent view know that the video is finished
      parentView:dispatchEvent({ name = 'videoComplete' });
      if videoGroup.bg then
        videoGroup.bg:removeSelf();
        videoGroup.bg = nil;
      end
      videoGroup.freeMemory();
      videoGroup:removeSelf();
      if (videoGroup) then videoGroup = nil; end
    end
    -- we handled the event
    return true;
  end

  function videoGroup.initVideo(videoData)
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
      videoGroup.currentVideo = native.newVideo(0, 0, videoDimensions.width, videoDimensions.height);
      videoGroup.currentVideo:load(videoFile);
      if (videoScale == "FULLSCREEN") then
        -- FRC_Layout.scaleToFit(videoGroup);
        -- figure out the scale
        xs = display.actualContentWidth/videoGroup.currentVideo.contentWidth;
        ys = display.actualContentHeight/videoGroup.currentVideo.contentHeight;
        videoGroup.currentVideo.xScale = xs;
        videoGroup.currentVideo.yScale = ys;
        -- native.showAlert('VIDEO SCALING', 'd.pWidth: ' .. display.pixelWidth .. 'd.pHeight: ' ..display.pixelHeight .. 'cVideo.width: ' .. videoGroup.currentVideo.width .. 'cVideo.height: ' ..videoGroup.currentVideo.height .. 'd.cWidth: ' .. display.contentWidth .. 'videoDimensions.width: ' .. videoDimensions.width .. 'd.cHeight: ' .. display.contentHeight .. 'videoDimensions.height: ' .. videoDimensions.height .. ' xs/ys: ' .. xs .. '/' .. ys , { "OK" });
      elseif (videoScale == "LETTERBOX") then
        -- do nothing for now
      else
        -- do nothing for now
      end
      videoGroup.currentVideo.x = display.contentCenterX; -- Width * 0.5;
      videoGroup.currentVideo.y = display.contentCenterY; -- Height * 0.5;
      videoGroup.currentVideo:addEventListener("video", videoGroup.playVideo );
      videoGroup.skipVideoButton = display.newRect(videoGroup, 0, 0, screenW, screenH);
      videoGroup.skipVideoButton.isVisible = false;
      videoGroup.skipVideoButton.anchorX = 0.5;
      videoGroup.skipVideoButton.anchorY = 0.5;
      videoGroup.skipVideoButton.x, videoGroup.skipVideoButton.y = display.contentCenterX, display.contentCenterY;
      videoGroup.skipVideoButton:addEventListener('touch', videoGroup.skipVideo );
      videoGroup.skipVideoButton.isHitTestable = true;
    else
      -- videoGroup.gotoNextScene();
    end
  end

  function videoGroup.playVideo(event)
    if (event.phase == "ready") then
      videoGroup.currentVideo:play();
      videoGroup.currentVideo:removeEventListener("video", videoGroup.playVideo );
      videoGroup.videoTimer = timer.performWithDelay(currentVideoLength, videoGroup.skipVideo, 1);
    end
  end

  -- check to see if we even have a video to play
  -- first, if we are in the simulator, nevermind
  if (system.getInfo("environment") == "simulator") then
    videoGroup.skipVideo();
  else
    -- next, find out whether or not we have video data
    if (videoData) then
      -- DEBUG:
      print(videoData.HD_VIDEO_PATH, videoData.SD_VIDEO_PATH,videoData.VIDEO_LENGTH);
      currentVideoLength = videoData.VIDEO_LENGTH;
      videoGroup.initVideo(videoData);
    end
  end

	return videoGroup;
end

return FRC_Video;
