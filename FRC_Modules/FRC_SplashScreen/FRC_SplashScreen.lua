local storyboard = require('storyboard');
local FRC_SplashScreen_Settings = require('FRC_Modules.FRC_SplashScreen.FRC_SplashScreen_Settings');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_SplashScreen = {};

local	screenW, screenH, contentW, contentH, centerX, centerY = FRC_Layout.getScreenDimensions() -- TRS EFM


FRC_SplashScreen.new = function(nextScene)
   display.setDefault("background", 1.0, 1.0, 1.0);
   local splashGroup = display.newGroup();
   local currentVideoIndex = 0; -- the first video is at index 1
   local currentVideoLength = 0;

   function splashGroup.freeMemory()
      if (splashGroup.currentVideo) then         
         splashGroup.currentVideo:removeEventListener("video", splashGroup.playVideo );
         splashGroup.currentVideo:pause();
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
      storyboard.gotoScene(nextScene);
   end

   function splashGroup.skipSplash(event)
      if (event.phase == "began") then
         splashGroup.gotoNextScene();
      end
      return true;
   end

   local bg = display.newRect(splashGroup, centerX, centerY, screenW, screenH);
   bg:setFillColor(1.0);

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
      
      if (videoFile) then
         
         -- EFM - Make background black on intro video
         if( string.match( string.lower(videoFile), "intro") )  then
            bg:setFillColor(0);
         end
         
         
         --
         -- Bug Workaround - ANDROID not currently showing full screen videos correctly, so they always default to 'LETTERBOX'
         -- 12/29/2015 - Corona 2015.2799
         --
         if (videoScale == "FULLSCREEN" and ANDROID_DEVICE ) then
            videoScale = "LETTERBOX"
         end

         -- ======================================================================
         -- FULLSCREEN FULLSCREEN FULLSCREEN FULLSCREEN FULLSCREEN FULLSCREEN
         -- ======================================================================
         if (videoScale == "FULLSCREEN" and not ANDROID_DEVICE ) then
            splashGroup.currentVideo = native.newVideo( centerX, centerY, videoDimensions.width, videoDimensions.height)
            splashGroup.currentVideo:load(videoFile)
            splashGroup.currentVideo.xScale = display.viewableContentWidth/splashGroup.currentVideo.contentWidth
            splashGroup.currentVideo.yScale = display.viewableContentHeight/splashGroup.currentVideo.contentHeight
            
         -- ======================================================================
         -- LETTERBOX LETTERBOX LETTERBOX LETTERBOX LETTERBOX LETTERBOX
         -- ======================================================================
         elseif (videoScale == "LETTERBOX") then
            local ws = display.actualContentWidth/videoDimensions.width 
            local hs = display.actualContentHeight/videoDimensions.height
            local vidScale = ws
            if( ws * videoDimensions.height > display.actualContentHeight) then
               vidScale = hs
            end
            videoDimensions.width = videoDimensions.width * vidScale
            videoDimensions.height = videoDimensions.height * vidScale
            splashGroup.currentVideo = native.newVideo( centerX, centerY, videoDimensions.width, videoDimensions.height)
            splashGroup.currentVideo:load(videoFile)
         else
            splashGroup.currentVideo = native.newVideo( centerX, centerY, videoDimensions.width, videoDimensions.height)
            splashGroup.currentVideo:load(videoFile)

         end

         splashGroup.currentVideo:addEventListener( "video", splashGroup.playVideo )
         splashGroup.skipVideoButton = display.newRect(splashGroup, centerX, centerY, screenW, screenH)
         splashGroup.skipVideoButton.isVisible = false
         splashGroup.skipVideoButton:addEventListener('touch', splashGroup.skipSplash )
         splashGroup.skipVideoButton.isHitTestable = true      
         
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
