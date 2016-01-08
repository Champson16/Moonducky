local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout')
local FRC_AnimationManager = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager')
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager')
local FRC_Video = require('FRC_Modules.FRC_Video.FRC_Video')

local ui = require('ui')
local settings = require('FRC_Modules.FRC_Jukebox.FRC_Jukebox_Settings')
local analytics = import("analytics")

local FRC_Jukebox = {}

local animationXMLBase = 'FRC_Assets/MDMT_Assets/Animation/XMLData/'
local animationImageBase = 'FRC_Assets/MDMT_Assets/Animation/Images/'

local jukeboxBackgroundAnimationSequences = {}

local imageBase = 'FRC_Assets/FRC_Jukebox/Images/'
local videoBase = 'FRC_Assets/MDMT_Assets/Videos/'

local videoPlayer

-- local function UI(key)
-- 	return FRC_Jukebox_Settings.UI[key]
-- end
--
-- local function DATA(key, baseDir)
-- 	baseDir = baseDir or system.ResourceDirectory
-- 	return FRC_DataLib.readJSON(FRC_Jukebox_Settings.DATA[key], baseDir)
-- end

local	screenW, screenH, contentW, contentH, centerX, centerY = FRC_Layout.getScreenDimensions() -- TRS EFM
local designWidth    = 1152 --1100 -- 1152
local designHeight   = 768 --700 --768
local borderSize     = settings.DEFAULTS.BORDER_SIZE
local elementPadding = settings.DEFAULTS.ELEMENT_PADDING
local mediaData      = settings.DATA.MEDIA
local pageCount      = math.ceil(#mediaData / 2)
local jukeboxPage    = 1

-- EFM - Jukebox alignment is hosed up at full design resolution?
local ox             = 63.5
local oy             = 0
-- Sizing is hosed too?
local ox2            = -60
local oy2            = -60

local animationScalingFactor = 1.07

-- setup the jukebox animations
local jukeboxBackgroundAnimationFiles =
{
   "MDMT_Jukebox_Background.xml"
}

local jukeboxForegroundAnimationFiles =
{
   "MDMT_Jukebox_AnimDiscPlay_d.xml",
   "MDMT_Jukebox_AnimDiscPlay_c.xml",
   "MDMT_Jukebox_AnimDiscPlay_b.xml",
   "MDMT_Jukebox_AnimDiscPlay_a.xml"
}

local toScale        = ( (screenW - 40) / designWidth )
toScale              = ( toScale * designHeight > (screenH - 40) ) and ( (screenH - 40) / designHeight ) or toScale

local debugEn        = false


-- ******************************************************
-- Jukebox Builder
-- ******************************************************
function FRC_Jukebox.new( options )
   options = options or {}

   -- ==
   --    Misc
   -- ==
   local currentPageIndex = 1
   FRC_Jukebox.jukeboxAudioGroup = FRC_AudioManager:newGroup({ name = "jukeboxAudio", maxChannels = 1 })

   -- ==
   --    Jukebox Group - The container to hold all parts of jukebox - Centered, but NOT scaled
   -- ==
   local jukeboxGroup = display.newGroup()
   jukeboxGroup.x = centerX
   jukeboxGroup.y = centerY
   jukeboxGroup.ctrl = {} -- Table to attach references to.  Gets rid of need for forward declarations
   FRC_Jukebox.jukeboxGroup = jukeboxGroup

   -- ==
   --    Debug - Aligment marker to help me get this layed out - EFM
   -- ==
   if( debugEn ) then
      local tmp = display.newLine( jukeboxGroup, -screenW/2, 0, screenW/2, 0 )
      local tmp2 = display.newLine( jukeboxGroup, 0, -screenH/2, 0, screenH/2 )
      timer.performWithDelay( 100,
         function()
            tmp.strokeWidth = 7
            tmp:setStrokeColor(1,0,0,0.7)
            tmp:toFront()
            tmp2.strokeWidth = 7
            tmp2:setStrokeColor(1,0,0,0.7)
            tmp2:toFront()
         end )
   end

   -- ==
   --    Touch and Tap Catcher
   -- ==
   local modalBackground = display.newRect(jukeboxGroup, 0, 0, screenW, screenH)
   modalBackground:setFillColor(0, 0, 0, 0.5)
   modalBackground.touch = function() return true end
   modalBackground:addEventListener('touch', modalBackground.touch)
   modalBackground:addEventListener('tap', modalBackground.touch)

   -- ==
   --    Jukebox Container - Master Cliper and ONLY object that will be scaled.  It will scale all other objects in it.
   --
   --    All objects should be placed according to design resolution rules. i.e. Where they should be at design resolution.
   --    Scaling this container last will handle all child object scaling.
   --
   -- ==
   local jukeboxContainer = display.newContainer( jukeboxGroup, designWidth, designHeight) -- Assumes 1152 x 768 was the design resolution

   -- ==
   --    Jukebox Background and Frame
   -- ==
   local border = display.newRect(jukeboxContainer, 0, 0, designWidth, designHeight) -- Let the container scale it
   border:setFillColor(1.0, 1.0, 1.0, 0.80)
   local back = display.newRect(jukeboxContainer, 0, 0, designWidth - borderSize * 2, designHeight - borderSize * 2 )
   back:setFillColor(.188235294, .188235294, .188235294, 1.0)

   -- ==
   --    Animated (?) Jukebox Background
   -- ==
   local animationContainer = display.newContainer( jukeboxContainer, designWidth, designHeight ) -- used to trim jukebox
   jukeboxBackgroundAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(jukeboxBackgroundAnimationFiles, animationXMLBase, animationImageBase)
   animationContainer:insert(jukeboxBackgroundAnimationSequences)
   jukeboxBackgroundAnimationSequences.x = -designWidth/2 + ox
   jukeboxBackgroundAnimationSequences.y = -designHeight/2 + oy

   jukeboxForegroundAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(jukeboxForegroundAnimationFiles, animationXMLBase, animationImageBase)
   animationContainer:insert(jukeboxForegroundAnimationSequences)
   jukeboxForegroundAnimationSequences.x = -designWidth/2 + ox
   jukeboxForegroundAnimationSequences.y = -designHeight/2 + oy

   animationContainer:scale(animationScalingFactor, animationScalingFactor);

   for i=1, jukeboxBackgroundAnimationSequences.numChildren do
      jukeboxBackgroundAnimationSequences[i]:play({
            showLastFrame = true,
            playBackward = false,
            autoLoop = false,
            palindromicLoop = false,
            delay = 0,
            intervalTime = 30,
            maxIterations = 1
         })
   end

   -- ==
   --    Ticker Crawler
   -- ==
   local tickerGroupContainer = display.newContainer( jukeboxContainer, 588 * animationScalingFactor, 44 ) -- Used to trim ticker
   --local tickerGroupContainer = display.newGroup()
   --jukeboxContainer:insert( tickerGroupContainer )
   tickerGroupContainer.y = 40

   local tickerGroup
   local startTickerTextCrawl = function( text )
      --dprint("Start new media ticker", text )
      if( tickerGroup ) then
         tickerGroup.destroying = true
         transition.cancel( tickerGroup )
      end
      display.remove( tickerGroup )
      tickerGroup = display.newGroup()
      tickerGroupContainer:insert(tickerGroup)

      local tickerText     = text or "WELCOME TO THE MOONDUCKY MUSIC THEATRE"
      local numLetters     = string.len( tickerText )

      local lastWidth   = 0
      local curX        = 0
      local totalWidth  = 0
      local firstWidth
      local padding     = (tickerText ~= "WELCOME TO THE MOONDUCKY MUSIC THEATRE") and 5 or 0

      for i=1, numLetters do
         local letter   = string.sub( tickerText, i, i )
         local ticker   = display.newText( tickerGroup, letter, curX + lastWidth, 0, "ticker", 32)
         curX           = ticker.x + padding
         firstWidth     = firstWidth or ticker.contentWidth
         lastWidth      = ticker.contentWidth
         totalWidth     = totalWidth + lastWidth
      end

      tickerGroup.x     = 590/2 + firstWidth
      tickerGroup.x0    = tickerGroup.x
      tickerGroup.x1    = tickerGroup.x0 - totalWidth - 590 - firstWidth + (numLetters * padding)
      local dist        = math.abs(tickerGroup.x0 - tickerGroup.x1)

      -- hack (EFM not sure why this is needed but it works across all cases)
      if( dist < 1200 ) then
         dist = 1200
         tickerGroup.x1 = tickerGroup.x0 - dist
      end

      local speed       = 120 -- pixels per second
      local time        = 1000 * dist/speed

      function tickerGroup.onComplete( self )
         if( self.destroying == true ) then return end
         if( self.removeSelf == nil ) then return end
         --dprint("tickerGroup.onComplete", text)
         self.x = self.x0
         transition.to( self, { x = self.x1, time = time, onComplete = self } )
      end
      tickerGroup:onComplete()

   end
   FRC_Jukebox.startTickerTextCrawl = startTickerTextCrawl
   startTickerTextCrawl()


   -- ==
   --    Video Playback Complete Listener
   -- ==
   local function videoPlaybackComplete( event )
      if( event ) then
         if (jukeboxGroup) then
            jukeboxGroup:removeEventListener('videoComplete', videoPlaybackComplete )
         end
      end
      if( videoPlayer ) then
         display.remove( videoPlayer )
         videoPlayer = nil
      end
      return true
   end

   -- ==
   --    Play Juke Box Media
   -- ==
   local function playJukeboxMedia( itemID )
      FRC_Jukebox.jukeboxAudioGroup:stop()
      if( FRC_Jukebox.currentAudio )then
         FRC_Jukebox.jukeboxAudioGroup:removeHandle( FRC_Jukebox.currentAudio )
      end

      local mData = mediaData[itemID]
      if not mData then return end

      -- Each button has a MEDIA_TYPE
      if mData.MEDIA_TYPE == "VIDEO" then
         analytics.logEvent("MDMT.Lobby.Jukebox.MediaSelection", { MEDIA_TYPE = "VIDEO", MEDIA_TITLE = mData.MEDIA_TITLE })

         FRC_Jukebox.startTickerTextCrawl(mData.MEDIA_TITLE)
         -- onRelease will playMedia and pass the indexID for the button
         -- playMedia function will call either FRC_Video or FRC_AudioManager
         local videoData =
         {
            HD_VIDEO_PATH  = videoBase .. mData.HD_VIDEO_PATH,
            HD_VIDEO_SIZE  = mData.HD_VIDEO_SIZE,
            SD_VIDEO_PATH  = videoBase .. mData.SD_VIDEO_PATH,
            SD_VIDEO_SIZE  = mData.SD_VIDEO_SIZE,
            VIDEO_SCALE    = mData.VIDEO_SCALE,
            VIDEO_LENGTH   = mData.VIDEO_LENGTH
         }

         videoPlayer = FRC_Video.new(jukeboxGroup, videoData)
         if videoPlayer then
            jukeboxGroup:addEventListener('videoComplete', videoPlaybackComplete )
         else
            -- this will fire because we are running in the Simulator and the video playback ends before it begins!
            videoPlaybackComplete()
         end
      elseif mData.MEDIA_TYPE == "AUDIO" then
         FRC_Jukebox.startTickerTextCrawl(mData.MEDIA_TITLE)
         FRC_Jukebox.currentAudio = FRC_AudioManager:newHandle({
               name = "song",
               path = "FRC_Assets/MDMT_Assets/Audio/" .. mData.AUDIO_PATH,
               group = "jukeboxAudio",
               loadMethod = "loadStream"
            })

         for i=1, jukeboxForegroundAnimationSequences.numChildren do
            jukeboxForegroundAnimationSequences[i]:play({
                  showLastFrame     = true,
                  playBackward      = false,
                  autoLoop          = false,
                  palindromicLoop   = false,
                  delay             = 0,
                  intervalTime      = 30,
                  maxIterations     = 1,
                  onCompletion      = function() FRC_Jukebox.currentAudio:play() end
               })
         end
         -- FRC_Jukebox.currentAudio:play()
      end
   end

   -- ==
   --    Load Jukebox Page
   -- ==
   local function loadJukeboxPage(pageIndex)
      local pageIndex = pageIndex or currentPageIndex
      currentPageIndex = pageIndex

      --
      -- LEFT MEDIA BUTTON / IMAGE
      --
      if( pageIndex == 1 ) then
         jukeboxGroup.ctrl.previousMediaButton:setDisabledState(true)
      else
         jukeboxGroup.ctrl.previousMediaButton:setDisabledState(false)
      end

      if( pageIndex == pageCount ) then
         jukeboxGroup.ctrl.nextMediaButton:setDisabledState(true)
      else
         jukeboxGroup.ctrl.nextMediaButton:setDisabledState(false)
      end

      local leftButtonDataIndex = (pageIndex * 2) - 1
      if( jukeboxGroup and jukeboxGroup.ctrl ) then
         display.remove( jukeboxGroup.ctrl.leftMediaButton )
         jukeboxGroup.ctrl.leftMediaButton = nil
      end

      if( leftButtonDataIndex > 0 and leftButtonDataIndex <= #mediaData ) then
         local leftButtonData = mediaData[leftButtonDataIndex]
         jukeboxGroup.ctrl.leftMediaButton = ui.button.new({
               id          = leftButtonDataIndex,
               imageUp     = imageBase .. leftButtonData.POSTER_FRAME,
               imageDown   = imageBase .. leftButtonData.POSTER_FRAME,
               width       = 265,
               height      = 201,
               x           = -160,
               y           = 200,
               onRelease = function(event)
                  analytics.logEvent( "MDMT.Lobby.Jukebox.MediaSelection" )
                  playJukeboxMedia( event.target.id )
               end
            })
         jukeboxContainer:insert(jukeboxGroup.ctrl.leftMediaButton)
      end

      --
      -- RIGHT MEDIA BUTTON  / IMAGE
      --
      local rightButtonDataIndex = pageIndex * 2
      if( jukeboxGroup and jukeboxGroup.ctrl ) then
         display.remove( jukeboxGroup.ctrl.rightMediaButton )
         jukeboxGroup.ctrl.rightMediaButton = nil
      end

      -- in case there are an odd number of items, the right media item may be blank
      if( rightButtonDataIndex > 0 and rightButtonDataIndex <= #mediaData ) then
         local rightButtonData = mediaData[rightButtonDataIndex]
         jukeboxGroup.ctrl.rightMediaButton = ui.button.new({
               id          = rightButtonDataIndex,
               imageUp     = imageBase .. rightButtonData.POSTER_FRAME,
               imageDown   = imageBase .. rightButtonData.POSTER_FRAME,
               width       = 265,
               height      = 201,
               x           = 160,
               y           = 200,
               onRelease   = function( event )
                  analytics.logEvent( "MDMT.Lobby.Jukebox.MediaSelection" )
                  playJukeboxMedia( event.target.id )
               end
            })
         jukeboxContainer:insert(jukeboxGroup.ctrl.rightMediaButton)
      end
   end

   -- ==
   --    Previous Media Selector (Button)
   -- ==
   jukeboxGroup.ctrl.previousMediaButton = ui.button.new({
         imageUp        = imageBase .. 'FRC_Jukebox_Button_Previous_up.png',
         imageDown      = imageBase .. 'FRC_Jukebox_Button_Previous_down.png',
         imageDisabled  = imageBase .. 'FRC_Jukebox_Button_Previous_disabled.png',
         imageFocused   = imageBase .. 'FRC_Jukebox_Button_Previous_focused.png',
         width          = 128,
         height         = 128,
         x              = -330,
         y              = 205,
         onRelease      = function()
            analytics.logEvent("MDMT.Lobby.Jukebox.PreviousMedia")
            if currentPageIndex > 1 then
               currentPageIndex = currentPageIndex - 1
               loadJukeboxPage()
            end
         end
      })
   jukeboxContainer:insert(jukeboxGroup.ctrl.previousMediaButton)

   -- ==
   --    Next Media Selector (Button)
   -- ==
   jukeboxGroup.ctrl.nextMediaButton = ui.button.new({
         imageUp        = imageBase .. 'FRC_Jukebox_Button_Next_up.png',
         imageDown      = imageBase .. 'FRC_Jukebox_Button_Next_down.png',
         imageDisabled  = imageBase .. 'FRC_Jukebox_Button_Next_disabled.png',
         imageFocused   = imageBase .. 'FRC_Jukebox_Button_Next_focused.png',
         width          = 128,
         height         = 128,
         x              = 330,
         y              = 205,
         onRelease      = function()
            analytics.logEvent("MDMT.Lobby.Jukebox.NextMedia")
            if currentPageIndex < pageCount then
               currentPageIndex = currentPageIndex + 1
               loadJukeboxPage()
            end
         end
      })
   jukeboxContainer:insert(jukeboxGroup.ctrl.nextMediaButton )

   -- ==
   --    Replay Media Selector (Button)
   -- ==
   jukeboxGroup.ctrl.replayMediaButton = ui.button.new({
         imageUp        = imageBase .. 'FRC_Jukebox_Button_Replay_up.png',
         imageDown      = imageBase .. 'FRC_Jukebox_Button_Replay_down.png',
         imageDisabled  = imageBase .. 'FRC_Jukebox_Button_Replay_disabled.png',
         imageFocused   = imageBase .. 'FRC_Jukebox_Button_Replay_focused.png',
         width          = 96,
         height         = 96,
         x              = -360,
         y              = 32,
         onRelease      = function()
            analytics.logEvent("MDMT.Lobby.Jukebox.ReplayMedia")
            if (FRC_Jukebox.currentAudio) then
               audio.rewind(FRC_Jukebox.currentAudio)
            end
         end
      })
   jukeboxContainer:insert(jukeboxGroup.ctrl.replayMediaButton)

   -- ==
   --    Pause Media Selector (Button)
   -- ==
   jukeboxGroup.ctrl.pauseMediaButton = ui.button.new({
         imageUp        = imageBase .. 'FRC_Jukebox_Button_Pause_up.png',
         imageDown      = imageBase .. 'FRC_Jukebox_Button_Pause_down.png',
         imageDisabled  = imageBase .. 'FRC_Jukebox_Button_Pause_disabled.png',
         imageFocused   = imageBase .. 'FRC_Jukebox_Button_Pause_focused.png',
         width          = 96,
         height         = 96,
         x              = 360,
         y              = 32,
         onRelease      = function()
            analytics.logEvent("MDMT.Lobby.Jukebox.PauseMedia")
            if (audio.isChannelPaused(FRC_Jukebox.currentAudio.channel)) then
               print("resuming jukebox audio") -- DEBUG
               FRC_Jukebox.currentAudio:resume()
            else
               print("pausing jukebox audio") -- DEBUG
               FRC_Jukebox.currentAudio:pause()
            end
         end
      })
   jukeboxContainer:insert(jukeboxGroup.ctrl.pauseMediaButton)

   -- ==
   --    Load the first page
   -- ==
   loadJukeboxPage()

   local closeButton = ui.button.new({
         imageUp     = settings.DEFAULTS.CLOSE_BUTTON_IMAGE,
         imageDown   = settings.DEFAULTS.CLOSE_BUTTON_IMAGE,
         pressAlpha  = 0.75,
         width       = settings.DEFAULTS.CLOSE_BUTTON_WIDTH,
         height      = settings.DEFAULTS.CLOSE_BUTTON_HEIGHT,
         onRelease   = function() FRC_Jukebox:dispose() end
      })
   closeButton.x = -designWidth/2 + closeButton.contentWidth/2
   closeButton.y = -designHeight/2 + closeButton.contentHeight/2
   jukeboxContainer:insert(closeButton)

   jukeboxGroup.dispose = FRC_Jukebox.dispose

   if (options.title) then
      local titleText = display.newText(popup, options.title, 0, 0, native.systemFontBold, 36)
      titleText:setFillColor(0, 0, 0, 1.0)
      titleText.x = 0
      titleText.y = -(popup.height * 0.5) + (titleText.contentHeight * 0.5) + (settings.DEFAULTS.THUMBNAIL_SPACING)
   end

   -- ==
   --    Insert group into 'parent' if one is supplied
   -- ==
   if (options.parent) then
      options.parent:insert( jukeboxGroup )
   end
   jukeboxContainer:scale( toScale, toScale ) -- EFM to TRS: HERE AND ONLY HERE DO YOU SCALE
   return jukeboxGroup
end


FRC_Jukebox.disposeAnimations = function(self)
   -- kill the animation objects
   if (jukeboxBackgroundAnimationSequences) then
      for i=1, jukeboxBackgroundAnimationSequences.numChildren do
         local anim = jukeboxBackgroundAnimationSequences[i]
         if (anim) then
            if (anim.isPlaying) then
               anim:stop()
            end
            anim:dispose()
         end
      end
      jukeboxBackgroundAnimationSequences = nil
   end

   if (jukeboxForegroundAnimationSequences) then
      for i=1, jukeboxForegroundAnimationSequences.numChildren do
         local anim = jukeboxForegroundAnimationSequences[i]
         if (anim) then
            if (anim.isPlaying) then
               anim:stop()
            end
            anim:dispose()
         end
      end
      jukeboxForegroundAnimationSequences = nil
   end
end

FRC_Jukebox.dispose = function(self)
   FRC_Jukebox.jukeboxAudioGroup:stop()
   -- remove active track
   if FRC_Jukebox.currentAudio then
      FRC_Jukebox.jukeboxAudioGroup:removeHandle(FRC_Jukebox.currentAudio)
   end
   -- remove the animations
   FRC_Jukebox:disposeAnimations()
   if (FRC_Jukebox.jukeboxGroup) then FRC_Jukebox.jukeboxGroup:removeSelf() end
end

return FRC_Jukebox
