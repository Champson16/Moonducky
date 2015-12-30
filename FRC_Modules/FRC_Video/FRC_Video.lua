local storyboard = require('storyboard')
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout')
local FRC_Video = {}

local	screenW, screenH, contentW, contentH, centerX, centerY = FRC_Layout.getScreenDimensions() -- TRS EFM

-- updated 12092015 TRS

FRC_Video.new = function(parentView, videoData, useWhiteFill )
   --table.print_r( videoData )   
   
   if(  ON_SIMULATOR ) then
      return 
   end   

   local videoGroup = display.newGroup()
   local currentVideoLength = 0

   -- Add either a white or black background depending on 'useWhiteFill'
   local bg = display.newRect(videoGroup, centerX, centerY, screenW, screenH)
   if( useWhiteFill == true ) then
      display.setDefault("background", 1.0, 1.0, 1.0)
      bg:setFillColor(1) --EFM
   else
      display.setDefault("background", 0, 0, 0)
      bg:setFillColor(0) --EFM
   end

   videoGroup.bg = bg

   --
   -- Free Memory
   function videoGroup.freeMemory()
      if (videoGroup.currentVideo) then
         videoGroup.currentVideo:removeEventListener("video", videoGroup.playVideo )
         videoGroup.currentVideo:pause()         
         videoGroup.currentVideo:removeSelf()
         videoGroup.currentVideo = nil
      end
      if (videoGroup.skipVideoButton) then
         videoGroup.skipVideoButton:removeEventListener('touch', videoGroup.skipVideo )
         display.remove(videoGroup.skipVideoButton)
         videoGroup.skipVideoButton = nil
      end
      if (videoGroup.videoTimer) then
         timer.cancel(videoGroup.videoTimer)
      end
   end

   --
   -- Skip Video
   local startTime = system.getTimer()
   function videoGroup.skipVideo(event)
      local curTime = system.getTimer()
      if( curTime - startTime < 333 ) then
         return true
      end
      if (not event or event.phase == "ended") then
         if videoGroup.bg then
            display.remove(videoGroup.bg)
            videoGroup.bg = nil
         end
         videoGroup.freeMemory()
         display.remove(videoGroup)
         videoGroup = nil
         -- let the parent view know that the video is finished
         if (parentView) then
            if ( parentView.dispatchEvent and type(parentView.dispatchEvent) == "function" ) then
               parentView:dispatchEvent({ name = 'videoComplete' })
            end
         end
      end
      -- we handled the event
      return true
   end

   --
   -- Init Video
   function videoGroup.initVideo(videoData)
      local videoFile = videoData.HD_VIDEO_PATH
      local videoDimensions = videoData.HD_VIDEO_SIZE
      local videoScale = videoData.VIDEO_SCALE
      -- forward declarations      
      if ((ANDROID_DEVICE) or (NOOK_DEVICE) or (KINDLE_DEVICE)) then
         -- android devices generally require lower res videos for backward compatibility
         videoFile = videoData.SD_VIDEO_PATH
         videoDimensions = videoData.SD_VIDEO_SIZE
      end

      print("Playing video: ", videoFile) -- DEBUG
      if( videoFile ) then
         
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
            videoGroup.currentVideo = native.newVideo( centerX, centerY, videoDimensions.width, videoDimensions.height)
            videoGroup.currentVideo:load(videoFile)
            videoGroup.currentVideo.xScale = display.viewableContentWidth/videoGroup.currentVideo.contentWidth
            videoGroup.currentVideo.yScale = display.viewableContentHeight/videoGroup.currentVideo.contentHeight
            
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
            videoGroup.currentVideo = native.newVideo( centerX, centerY, videoDimensions.width, videoDimensions.height)
            videoGroup.currentVideo:load(videoFile)
         
         else
            videoGroup.currentVideo = native.newVideo( centerX, centerY, videoDimensions.width, videoDimensions.height)
            videoGroup.currentVideo:load(videoFile)

         end

         videoGroup.currentVideo:addEventListener( "video", videoGroup.playVideo )
         videoGroup.skipVideoButton = display.newRect(videoGroup, centerX, centerY, screenW, screenH)
         videoGroup.skipVideoButton.isVisible = false
         videoGroup.skipVideoButton:addEventListener('touch', videoGroup.skipVideo )
         videoGroup.skipVideoButton.isHitTestable = true
      else
         if videoGroup.bg then
            display.remove(videoGroup.bg)
            videoGroup.bg = nil
         end
         videoGroup.freeMemory()
         display.remove(videoGroup)
         videoGroup = nil
         if (parentView) then
            if ( parentView.dispatchEvent and type(parentView.dispatchEvent) == "function" ) then
               parentView:dispatchEvent({ name = 'videoComplete' })
            end
         end
      end
   end

   --
   -- Play Video
   function videoGroup.playVideo(event)
      if (event.phase == "ready") then
         videoGroup.currentVideo:play()
         videoGroup.currentVideo:removeEventListener("video", videoGroup.playVideo )
         videoGroup.videoTimer = timer.performWithDelay(currentVideoLength, videoGroup.skipVideo, 1)
      end
   end

   -- check to see if we even have a video to play
   -- first, if we are in the simulator, nevermind
   if(  ON_SIMULATOR ) then
      videoGroup.skipVideo()
   else
      -- next, find out whether or not we have video data
      if (videoData) then         
         print(videoData.HD_VIDEO_PATH, videoData.SD_VIDEO_PATH,videoData.VIDEO_LENGTH) -- DEBUG:
         currentVideoLength = videoData.VIDEO_LENGTH
         videoGroup.initVideo(videoData)
      end
   end

   return videoGroup
end

return FRC_Video
