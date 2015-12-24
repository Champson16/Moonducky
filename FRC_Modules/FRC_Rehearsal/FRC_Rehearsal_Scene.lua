-- ====================================================================
-- Requires
-- ====================================================================
local storyboard              = require 'storyboard'
local ui                      = require('ui')
local FRC_Rehearsal_Settings  = require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Settings')
local FRC_Layout              = require('FRC_Modules.FRC_Layout.FRC_Layout')
local FRC_DataLib             = require('FRC_Modules.FRC_DataLib.FRC_DataLib')
local FRC_Rehearsal_Scene     = storyboard.newScene()
local FRC_AnimationManager    = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager')
local FRC_AudioManager        = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager')
local FRC_Util                = require("FRC_Modules.FRC_Util.FRC_Util")
local FRC_SetDesign_Settings  = require('FRC_Modules.FRC_SetDesign.FRC_SetDesign_Settings');
local FRC_SetDesign           = require('FRC_Modules.FRC_SetDesign.FRC_SetDesign');
local FRC_CharacterBuilder    = require('FRC_Modules.FRC_Rehearsal.FRC_CharacterBuilder') --EFM
local FRC_AppSettings   = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');

local FRC_ArtCenter;
local artCenterLoaded = pcall(function()
      FRC_ArtCenter = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter');
   end);

-- ====================================================================
-- Locals
-- ====================================================================
local	screenW, screenH, contentW, contentH, centerX, centerY = FRC_Layout.getScreenDimensions() -- TRS EFM

local currentSongID = "hamsters";

local sceneMode = "rehearsal" -- or "showtime"
local sceneRehearsalPaused = false;

local character_x = 0
local character_y = -16
local eyeTimer

local function UI(key)
   return FRC_Rehearsal_Settings.UI[key]
end
local function SETDESIGNUI(key)
   return FRC_SetDesign_Settings.UI[key]
end

local function DATA(key, baseDir)
   baseDir = baseDir or system.ResourceDirectory
   return FRC_DataLib.readJSON(FRC_Rehearsal_Settings.DATA[key], baseDir)
end
local function SETDESIGNDATA(key, baseDir)
   baseDir = baseDir or system.ResourceDirectory
   return FRC_DataLib.readJSON(FRC_SetDesign_Settings.DATA[key], baseDir)
end
local animationXMLBase = UI('ANIMATION_XML_BASE')
local animationImageBase = UI('ANIMATION_IMAGE_BASE')
local songTrackOffsetData = DATA('SONG_TRACK_OFFSETS')

-- Setup the audio groups for each song
FRC_AudioManager:newGroup({
      name = "songTracks",
      maxChannels = 18
   });
FRC_AudioManager:newGroup({
      name = "songPlayback",
      maxChannels = 9
   });

-- TODO MOVE THIS INTO JSON STRUCTURE
local instrumentTrackStartOffsets;
local songTrackTimers = {};
----[[ EFM - MOVED TO --> DATA('SONG_TRACK_OFFSETS')
--local
songTrackOffsetData = {
   hamsters_bass                     = 3797,
   hamsters_conga                    = 2208,
   hamsters_guitar                   = 3045,
   hamsters_harmonica                = 3449,
   hamsters_maracas                  = 1100,
   hamsters_microphone               = 4151,
   hamsters_rhythmcombocheesegrater  = 2777,
   hamsters_sticks                   = 1897,

   mechanicalcow_bass                = 1431,
   mechanicalcow_conga               = 5012,
   mechanicalcow_guitar              = 1502,
   mechanicalcow_harmonica           = 3993,
   mechanicalcow_microphone          = 9249,
   mechanicalcow_piano               = 1775,
   mechanicalcow_rhythmcombocymbal    = 0
};
--]]

-- load up the audio tracks for Hamsters song
FRC_AudioManager:newHandle({
      name = "hamsters_bass",
      path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_HamsterWantToBeFree_Bass.mp3",
      group = "songTracks",
      loadMethod = "loadStream"
   });
FRC_AudioManager:newHandle({
      name = "hamsters_conga",
      path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_HamsterWantToBeFree_Conga.mp3",
      group = "songTracks",
      loadMethod = "loadStream"
   });
FRC_AudioManager:newHandle({
      name = "hamsters_guitar",
      path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_HamsterWantToBeFree_Guitar.mp3",
      group = "songTracks",
      loadMethod = "loadStream"
   });
FRC_AudioManager:newHandle({
      name = "hamsters_harmonica",
      path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_HamsterWantToBeFree_Harmonica.mp3",
      group = "songTracks",
      loadMethod = "loadStream"
   });
FRC_AudioManager:newHandle({
      name = "hamsters_maracas",
      path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_HamsterWantToBeFree_Maracas.mp3",
      group = "songTracks",
      loadMethod = "loadStream"
   });
FRC_AudioManager:newHandle({
      name = "hamsters_microphone",
      path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_HamsterWantToBeFree_Microphone.mp3",
      group = "songTracks",
      loadMethod = "loadStream"
   });
FRC_AudioManager:newHandle({
      name = "hamsters_rhythmcombocheesegrater",
      path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_HamsterWantToBeFree_RhythmComboCheeseGrater.mp3",
      group = "songTracks",
      loadMethod = "loadStream"
   });
FRC_AudioManager:newHandle({
      name = "hamsters_sticks",
      path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_HamsterWantToBeFree_Sticks.mp3",
      group = "songTracks",
      loadMethod = "loadStream"
   });

-- load up the audio tracks for Mechanical Cow song
FRC_AudioManager:newHandle({
      name = "mechanicalcow_bass",
      path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_MechanicalCow_Bass.mp3",
      group = "songTracks",
      loadMethod = "loadStream"
   });
FRC_AudioManager:newHandle({
      name = "mechanicalcow_conga",
      path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_MechanicalCow_Conga.mp3",
      group = "songTracks",
      loadMethod = "loadStream"
   });
FRC_AudioManager:newHandle({
      name = "mechanicalcow_guitar",
      path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_MechanicalCow_Guitar.mp3",
      group = "songTracks",
      loadMethod = "loadStream"
   });
FRC_AudioManager:newHandle({
      name = "mechanicalcow_harmonica",
      path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_MechanicalCow_Harmonica.mp3",
      group = "songTracks",
      loadMethod = "loadStream"
   });
FRC_AudioManager:newHandle({
      name = "mechanicalcow_microphone",
      path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_MechanicalCow_Microphone.mp3",
      group = "songTracks",
      loadMethod = "loadStream"
   });
FRC_AudioManager:newHandle({
      name = "mechanicalcow_piano",
      path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_MechanicalCow_Piano.mp3",
      group = "songTracks",
      loadMethod = "loadStream"
   });
FRC_AudioManager:newHandle({
      name = "mechanicalcow_rhythmcombocymbal",
      path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_MechanicalCow_RhythmComboCymbal.mp3",
      group = "songTracks",
      loadMethod = "loadStream"
   });


function FRC_Rehearsal_Scene:save(e)
   local id = e.id
   if ((not id) or (id == '')) then id = (FRC_Util.generateUniqueIdentifier(20)) end

   --local saveGroup = self.view.setDesignGroup --EFM
   local saveGroup = self.view._content --EFM

   -- create mask
   -- mask must have a minimum of 3px padding on all sides, and be a multiple of 4
   local capture = display.capture(saveGroup)
   local cw = ((capture.contentWidth + 12) * display.contentScaleX)
   local ch = ((capture.contentHeight + 12) * display.contentScaleY)
   local sx = display.contentScaleX
   local sy = display.contentScaleY
   if (display.contentScaleX < 1.0) then
      cw = cw * 2
      capture.xScale = display.contentScaleX
      sx = 1.0
   end
   if (display.contentScaleY < 1.0) then
      ch = ch * 2
      capture.yScale = display.contentScaleY
      sy = 1.0
   end
   local maskWidth = math.round(((cw) - ((cw) % 4)) * sx)
   local maskHeight = math.round(((ch) - ((ch) % 4)) * sy)
   local maskContainer = display.newContainer(maskWidth, maskHeight)
   local blackRect = display.newRect(maskContainer, 0, 0, maskWidth, maskHeight)
   blackRect:setFillColor(0, 0, 0, 1.0)
   blackRect.x, blackRect.y = 0, 0
   maskContainer:insert(capture)
   capture.fill.effect = 'filter.colorMatrix'
   capture.fill.effect.coefficients =
   {
      0, 0, 0, 1,  --red coefficients
      0, 0, 0, 1,  --green coefficients
      0, 0, 0, 1,  --blue coefficients
      0, 0, 0, 0   --alpha coefficients
   }
   capture.fill.effect.bias = { 0, 0, 0, 1 }
   maskContainer.x = display.contentCenterX
   maskContainer.y = display.contentCenterY
   --display.save(maskContainer, id .. '_mask.png', system.DocumentsDirectory)
   display.save(maskContainer, {
         filename = id .. '_mask.png',
         baseDir = system.DocumentsDirectory,
         isFullResolution = false
      })
   capture.fill.effect = nil

   -- save full-size image (to be used as Stamp in ArtCenter)
   blackRect:removeSelf() blackRect = nil
   display.save(maskContainer, { filename=id .. '_full.jpg', baseDir=system.DocumentsDirectory })
   local fullWidth = maskContainer.contentWidth
   local fullHeight = maskContainer.contentHeight

   -- save thumbnail
   maskContainer.yScale = UI('THUMBNAIL_HEIGHT') / maskContainer.contentHeight
   maskContainer.xScale = maskContainer.yScale
   local thumbWidth = maskContainer.contentWidth
   local thumbHeight = maskContainer.contentHeight
   display.save(maskContainer, { filename=id .. '_thumbnail.png', baseDir=system.DocumentsDirectory })
   maskContainer:removeSelf() maskContainer = nil


   local saveDataFilename = FRC_Rehearsal_Settings.DATA.DATA_FILENAME
   local newSave = {
      id = id,
      currentSongID = currentSongID, -- EFM Load/Create New Show Logic ++
      setID = FRC_Rehearsal_Scene.setID,
      setIndex = FRC_Rehearsal_Scene.setIndex,
      backdropName = FRC_Rehearsal_Scene.backdropName,
      thumbWidth = thumbWidth,
      thumbHeight = thumbHeight,
      thumbSuffix = '_thumbnail.png',
      maskSuffix = '_mask.png',
      fullSuffix = '_full.jpg',
      fullWidth = fullWidth,
      fullHeight = fullHeight
   }
   local exists = false
   for i=1,#self.saveData.savedItems do
      if (self.saveData.savedItems[i].id == id) then
         self.saveData.savedItems[i] = newSave
         exists = true
      end
   end
   if (not exists) then
      table.insert(self.saveData.savedItems, newSave)
   end
   FRC_CharacterBuilder.save(newSave)
   FRC_DataLib.saveJSON(saveDataFilename, self.saveData)
   self.id = id
end

function FRC_Rehearsal_Scene:load(e)
   if( e.data.setID ) then
      local setDesignData = DATA('SETDESIGN') -- EFM best place?
      FRC_Rehearsal_Scene.setID = e.data.setID
      for i = 1, #FRC_SetDesign.saveData.savedItems do
         if(FRC_SetDesign.saveData.savedItems[i].id == FRC_Rehearsal_Scene.setID ) then
            FRC_Rehearsal_Scene.changeSet(FRC_SetDesign.saveData.savedItems[i].setIndex)
            FRC_Rehearsal_Scene.changeBackdrop(FRC_SetDesign.saveData.savedItems[i].backdropName);
         end
      end
   end

   currentSongID = e.data.currentSongID

   FRC_CharacterBuilder.init( {
         view                  = FRC_Rehearsal_Scene.view,
         currentSongID         = currentSongID,
         animationXMLBase      = animationXMLBase,
         animationImageBase    = animationImageBase,
         itemScrollers         = itemScrollers,
         showTimeMode          = ( sceneMode == "showtime"),
         categoriesContainer   = categoriesContainer } )
   FRC_CharacterBuilder.rebuildInstrumenScroller( )
   FRC_CharacterBuilder.load(e.data)

   ----[[
   function FRC_Rehearsal_Scene.doStartOver()
      FRC_CharacterBuilder.init( {
            view                  = FRC_Rehearsal_Scene.view,
            currentSongID         = currentSongID,
            animationXMLBase      = animationXMLBase,
            animationImageBase    = animationImageBase,
            itemScrollers         = itemScrollers,
            showTimeMode          = false,
            categoriesContainer   = categoriesContainer } ) 
      FRC_CharacterBuilder.rebuildInstrumenScroller( )
      FRC_Rehearsal_Scene.changeSet(0)
      FRC_Rehearsal_Scene.changeBackdrop("None");
      FRC_Rehearsal_Scene.setIndex = nil
      FRC_Rehearsal_Scene.backdropName = nil
      FRC_Rehearsal_Scene.setID = nil
   end
   --]]

end

-- TEMPORARY COPY OF SAVE W/ TITLE Editing code (so I can fix save)
function FRC_Rehearsal_Scene:publish(e)
   local id = e.id
   if ((not id) or (id == '')) then id = (FRC_Util.generateUniqueIdentifier(20)) end

   local function completeSave( songTitle, showTitle )
      --dprint( "completeSave() ",  songTitle, showTitle )
      --local saveGroup = self.view.setDesignGroup --EFM
      local saveGroup = self.view._content --EFM

      -- EFM Add temporary label for save
      local backH    = 130
      local songTitleFontSize = 70
      local showTitleFontSize = 50
      local labelsGroup = display.newGroup()
      saveGroup:insert( labelsGroup )

      local songTitleBack = display.newRect( labelsGroup, centerX, centerY - screenH/2 + backH/2, screenW - 10, backH - 10 )
      songTitleBack.strokeWidth = 8
      songTitleBack:setStrokeColor(0)
      songTitleBack:setFillColor( 0,0,0,1.0 )

      local showTitleBack = display.newRect( labelsGroup, centerX, centerY + screenH/2 - backH/2, screenW - 10, backH - 10 )
      showTitleBack.strokeWidth = 8
      showTitleBack:setStrokeColor(0)
      showTitleBack:setFillColor( 0,0,0,1.0 )

      local songTitleLabel = display.newText( labelsGroup, songTitle, songTitleBack.x, songTitleBack.y, _G.fontMoonDucky, songTitleFontSize )
      --songTitleLabel:setFillColor(0)

      local showTitleLabel = display.newText( labelsGroup, showTitle, showTitleBack.x, showTitleBack.y, _G.fontOpenSans, showTitleFontSize )
      --showTitleLabel:setFillColor(0)

      -- create mask
      -- mask must have a minimum of 3px padding on all sides, and be a multiple of 4
      local capture = display.capture(saveGroup)
      local cw = ((capture.contentWidth + 12) * display.contentScaleX)
      local ch = ((capture.contentHeight + 12) * display.contentScaleY)
      local sx = display.contentScaleX
      local sy = display.contentScaleY
      if (display.contentScaleX < 1.0) then
         cw = cw * 2
         capture.xScale = display.contentScaleX
         sx = 1.0
      end
      if (display.contentScaleY < 1.0) then
         ch = ch * 2
         capture.yScale = display.contentScaleY
         sy = 1.0
      end
      local maskWidth = math.round(((cw) - ((cw) % 4)) * sx)
      local maskHeight = math.round(((ch) - ((ch) % 4)) * sy)
      local maskContainer = display.newContainer(maskWidth, maskHeight)
      local blackRect = display.newRect(maskContainer, 0, 0, maskWidth, maskHeight)
      blackRect:setFillColor(0, 0, 0, 1.0)
      blackRect.x, blackRect.y = 0, 0
      maskContainer:insert(capture)
      capture.fill.effect = 'filter.colorMatrix'
      capture.fill.effect.coefficients =
      {
         0, 0, 0, 1,  --red coefficients
         0, 0, 0, 1,  --green coefficients
         0, 0, 0, 1,  --blue coefficients
         0, 0, 0, 0   --alpha coefficients
      }
      capture.fill.effect.bias = { 0, 0, 0, 1 }
      maskContainer.x = display.contentCenterX
      maskContainer.y = display.contentCenterY
      --display.save(maskContainer, id .. '_mask.png', system.DocumentsDirectory)
      display.save(maskContainer, {
            filename = id .. '_mask.png',
            baseDir = system.DocumentsDirectory,
            isFullResolution = false
         })
      capture.fill.effect = nil

      -- save full-size image (to be used as Stamp in ArtCenter)
      blackRect:removeSelf() blackRect = nil
      display.save(maskContainer, { filename=id .. '_full.jpg', baseDir=system.DocumentsDirectory })
      local fullWidth = maskContainer.contentWidth
      local fullHeight = maskContainer.contentHeight

      -- save thumbnail
      maskContainer.yScale = UI('THUMBNAIL_HEIGHT') / maskContainer.contentHeight
      maskContainer.xScale = maskContainer.yScale
      local thumbWidth = maskContainer.contentWidth
      local thumbHeight = maskContainer.contentHeight
      display.save(maskContainer, { filename=id .. '_thumbnail.png', baseDir=system.DocumentsDirectory })
      maskContainer:removeSelf() maskContainer = nil


      local publishDataFilename = FRC_Rehearsal_Settings.DATA.PUBLISH_FILENAME
      local newSave = {
         id = id,
         currentSongID = currentSongID, -- EFM Load/Create New Show Logic ++
         setID = FRC_Rehearsal_Scene.setID,
         setIndex = FRC_Rehearsal_Scene.setIndex,
         backdropName = FRC_Rehearsal_Scene.backdropName,
         thumbWidth = thumbWidth,
         thumbHeight = thumbHeight,
         thumbSuffix = '_thumbnail.png',
         maskSuffix = '_mask.png',
         fullSuffix = '_full.jpg',
         fullWidth = fullWidth,
         fullHeight = fullHeight
      }
      local exists = false
      for i=1,#self.publishData.savedItems do
         if (self.publishData.savedItems[i].id == id) then
            self.publishData.savedItems[i] = newSave
            exists = true
         end
      end
      if (not exists) then
         table.insert(self.publishData.savedItems, newSave)
      end
      FRC_CharacterBuilder.save(newSave, true)
      FRC_DataLib.saveJSON(publishDataFilename, self.publishData)
      self.id = id

      -- EFM Add temporary label for save
      display.remove(labelsGroup)

   end

   --completeSave( "Hamsters Want To Be Free", "Test Save Title" )
   FRC_CharacterBuilder.getShowTitle( completeSave, nil )
end

function FRC_Rehearsal_Scene:loadShowTime(e)
   local curtainIndex = e.data.setIndex or 1
   FRC_Rehearsal_Scene.changeSet(e.data.setIndex or 0)
   FRC_Rehearsal_Scene.changeBackdrop(e.data.backdropName or "None");

   currentSongID = e.data.currentSongID

   FRC_CharacterBuilder.init( {
         view                  = FRC_Rehearsal_Scene.view,
         currentSongID         = currentSongID,
         animationXMLBase      = animationXMLBase,
         animationImageBase    = animationImageBase,
         itemScrollers         = itemScrollers,
         showTimeMode          = ( sceneMode == "showtime"),
         categoriesContainer   = categoriesContainer } )
   FRC_CharacterBuilder.rebuildInstrumenScroller( )
   FRC_CharacterBuilder.load(e.data)

   -- Showtime Work
   if( sceneMode == "showtime") then
      FRC_CharacterBuilder:stopStageCharacters()
      FRC_CharacterBuilder.setEditEnable( true )

      local curtainPath = FRC_CharacterBuilder.getCurtainPath( curtainIndex )
      local curtain = display.newImageRect( FRC_Rehearsal_Scene.view._content, curtainPath, screenW, screenH )
      curtain.x = centerX
      curtain.y = centerY
      curtain.y0 = curtain.y

      FRC_Rehearsal_Scene.startRehearsalMode( 1500, false )

      transition.to( curtain, { y = curtain.y0 - screenH, delay = 1000, time = 1500, transition = easing.inCirc } ) -- , onComplete = onComplete } )

      function FRC_Rehearsal_Scene.replayCurtains( downUpTime, tweenDelay )       
         FRC_Rehearsal_Scene.stopRehearsalMode( false )
         transition.cancel( curtain )
         if( math.abs(curtain.y - centerY) < 2 ) then
            transition.to( curtain, { y = curtain.y0 - screenH, delay = 0, time = downUpTime/2, transition = easing.inCirc } )         
         else
            curtain.y = curtain.y0 - screenH
            transition.to( curtain, { y = curtain.y0 , delay = 0, time = downUpTime/2, transition = easing.outCirc } ) 
            transition.to( curtain, { y = curtain.y0 - screenH, delay = downUpTime + tweenDelay, time = downUpTime/2, transition = easing.inCirc } )         
         end
      end   
   
      function FRC_Rehearsal_Scene.closeCurtains( downTime  )       
         transition.cancel( curtain )
         curtain.y = curtain.y0 - screenH
         local function onComplete( self )
            if( self.removeSelf == nil ) then  return end            
            FRC_Rehearsal_Scene.stopRehearsalMode( false )
            timer.performWithDelay( 500,
               function()
                  storyboard.gotoScene('Scenes.Lobby', { effect="crossFade", time=1000 })                  
               end)
         end
         transition.to( curtain, { y = curtain.y0 ,  time = downTime, transition = easing.outCirc, onComplete = onComplete } )          
      end   
   end   
end


-- ====================================================================
-- Scene Methods
-- ====================================================================

function FRC_Rehearsal_Scene:createScene(event)
   event.params = event.params or {}
   sceneMode = event.params.mode or sceneMode

   local view = self.view
   if ((not self.id) or (self.id == '')) then self.id = FRC_Util.generateUniqueIdentifier(20) end

   -- DEBUG:
   --dprint("FRC_Rehearsal_Scene - createScene() sceneMode == ", sceneMode)

   if ((self.preCreateScene) and (type(self.preCreateScene) == 'function')) then
      self.preCreateScene(self, event);
   end

   -- FORWARD declarations
   local startRehearsalMode;
   local stopRehearsalMode;
   local categoriesContainer;
   local categoriesBg;
   local rehearsalContainer;
   local rehearsalContainerBg;
   local itemScrollers;
   local tracksGroup;
   local songGroup;
   --local currentSongID = "hamsters";  -- EFM MOVED TO TOP OF FILE

   -- FRC_Rehearsal.getSavedData()
   self.saveData = DATA('DATA_FILENAME', system.DocumentsDirectory)
   require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal').saveData = FRC_DataLib.readJSON(saveDataFilename, system.DocumentsDirectory)

   local publishDataFileName = FRC_Rehearsal_Settings.DATA.PUBLISH_FILENAME
   local publishData = FRC_DataLib.readJSON(publishDataFileName, system.DocumentsDirectory) or { savedItems = {} }
   require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal').publishData = publishData
   self.publishData = publishData


   -- TRS EFM - Please, see changes/notes below.
   
   -- 1. Create a set of standard rendering layers
   FRC_Layout.createLayers( view )

   -- 2. (Optionally) configure the reference width/height for this scene
   --
   -- Reference dimensions must be speficied before scaling anything.
   -- You can do this once in the 'FRC_Layout' module and never change it, or change it per scene.
   --
   --FRC_Layout.setRefDimensions( UI('SCENE_BACKGROUND_WIDTH'), UI('SCENE_BACKGROUND_HEIGHT') )

   -- 3. Create a background
   local bg = display.newImageRect(view._content, UI('SCENE_BACKGROUND_IMAGE'), UI('SCENE_BACKGROUND_WIDTH'), UI('SCENE_BACKGROUND_HEIGHT'));

   -- 4. Scale first
   FRC_Layout.scaleToFit( bg )

   -- 5. Then position it.
   bg.x = centerX
   bg.y = centerY


   -- Get lua tables from JSON data
   local setData = SETDESIGNDATA('SETS');
   local backdropData = SETDESIGNDATA('BACKDROPS');

   -- Load in existing ArtCenter images as Backdrops
   if (artCenterLoaded) then
      FRC_ArtCenter.getSavedData();
      if ((FRC_ArtCenter.savedData) and (#FRC_ArtCenter.savedData.savedItems > 0)) then
         for i=#FRC_ArtCenter.savedData.savedItems,1,-1 do
            local item = FRC_ArtCenter.savedData.savedItems[i];
            table.insert(backdropData, 1, {
                  id = item.id,
                  imageFile = item.id .. item.fullSuffix,
                  thumbFile = item.id .. item.thumbSuffix,
                  width = item.fullWidth,
                  height = item.fullHeight,
                  baseDir = "DocumentsDirectory"
               });
         end
      end
   end

   local setScale = 1;
   local setDesignGroup = display.newGroup(); view._content:insert(setDesignGroup); 
   view.setDesignGroup = setDesignGroup;
   local backdropGroup = display.newGroup(); view.setDesignGroup:insert(backdropGroup);
   local setGroup = display.newGroup(); view.setDesignGroup:insert(setGroup);

   local repositionSet = function()
      -- view.setDesignGroup.xScale = setScale;
      -- view.setDesignGroup.yScale = setScale;
      -- view.setDesignGroup.x = (display.contentWidth - (display.contentWidth * setScale)) * 0.5;
      -- view.setDesignGroup.y = (display.contentHeight - (display.contentHeight * setScale)) * 0.5;
      --FRC_Layout.scaleToFit(setDesignGroup);
      -- view.setDesignGroup.y = view.setDesignGroup.y - 80;
   end

   -- EFM not best place for this.  Temporary while I work out scaling on custom backdrops which are still off.
   local setScale = 1
   --local function round(val, n) if (n) then  return math.floor( (val * 10^n) + 0.5) / (10^n); else return math.floor(val+0.5); end end
   local changeSet = function(index)
      -- clear previous contents
      if (setGroup.numChildren > 0) then
         setGroup[1]:removeSelf();
         setGroup[1] = nil;
      end
      -- if we are clearing the set, we're done
      print("set index",index); -- DEBUG

      FRC_Rehearsal_Scene.setIndex = index
      if (index == 0) then return; end

      local setBackground = display.newImageRect(setGroup, SETDESIGNUI('IMAGES_PATH') .. setData[index].imageFile, setData[index].width, setData[index].height);

      local xs = display.actualContentWidth/setBackground.contentWidth
      local ys = display.actualContentHeight/setBackground.contentHeight
      --dprint(backdropData[index].width, backdropData[index].height,xs,ys);
      if( xs > ys ) then
         setScale = xs
      else
         setScale  = ys
      end
      setBackground:scale( setScale, setScale )
      --local setBackground = display.newImageRect(setGroup, SETDESIGNUI('IMAGES_PATH') .. setData[index].imageFile, screenW, screenH);
      --FRC_Layout.placeImage(setBackground, nil, false )  --EFM
      setBackground.x = display.contentCenterX;
      setBackground.y = display.contentCenterY;
      local frameRect = setData[index].frameRect;
      setBackground.frameRect = frameRect;

      -- resize selected backdrop to fit in selected set
      local selectedBackdrop = backdropGroup[1];
      if (not selectedBackdrop) then return; end

      local currentWidth = backdropData[FRC_Rehearsal_Scene.backdropIndex].width;
      local currentHeight = backdropData[FRC_Rehearsal_Scene.backdropIndex].height;
      selectedBackdrop.xScale = (frameRect.width / currentWidth);
      selectedBackdrop.yScale = (frameRect.height / currentHeight);
      selectedBackdrop.x = frameRect.left - ((setBackground.width - display.contentWidth) * 0.5);
      selectedBackdrop.y = frameRect.top - ((setBackground.height - display.contentHeight) * 0.5);
   end
   self.changeSet = changeSet;
   -- changeSet();

   local changeBackdrop = function(name)

      local index = 1
      for i = 1, #backdropData do
         if( backdropData[i].id == name ) then
            index = i
         end
      end

      -- ArtCenter image set as backdrop, but image was deleted (reset index to 1)
      if (not backdropData[index]) then index = 0; end
      index = index or FRC_Rehearsal_Scene.backdropIndex;
      FRC_Rehearsal_Scene.backdropIndex = index;
      FRC_Rehearsal_Scene.backdropName = name;
      -- clear previous contents
      if (backdropGroup.numChildren > 0) then
         backdropGroup[1]:removeSelf();
         backdropGroup[1] = nil;
      end
      -- if we are clearing the set, we're done
      print("backdrop index",index); -- DEBUG
      if (name == "None") then return; end

      local frameRect = setGroup[1].frameRect;

      local imageFile = SETDESIGNUI('IMAGES_PATH') .. backdropData[index].imageFile;
      local baseDir = system.ResourceDirectory;
      if (backdropData[index].baseDir) then
         imageFile = backdropData[index].imageFile;
         baseDir = system[backdropData[index].baseDir];
      end
      local backdropBackground = display.newImageRect(backdropGroup, imageFile, baseDir, backdropData[index].width, backdropData[index].height);

      local bdScale = setScale
      -- EFM Initially I thought it was just custom images, but I see it in some default images too, when coupled with certain stages.
      --if( string.len(name) > 18 ) then -- custom backdrop
      --bdScale = bdScale + 0.05
      --end
      --if( bdScale > 1 ) then
      bdScale = bdScale + 0.04
      --end

      --backdropBackground.anchorX = 0;
      backdropBackground.anchorY = 0;
      backdropBackground.xScale = (frameRect.width / backdropData[index].width);
      backdropBackground.yScale = (frameRect.height / backdropData[index].height);
      --backdropBackground.x = frameRect.left - ((setGroup[1].width - display.contentWidth) * 0.5);
      --backdropBackground.x = frameRect.left * setScale - ((setGroup[1].width - 1152/2) * 0.5) * setScale;
      backdropBackground.x = centerX
      --backdropBackground.y = frameRect.top * setScale - ((setGroup[1].height - display.contentHeight) * 0.5);
      backdropBackground.y = frameRect.top * bdScale - ((setGroup[1].height * bdScale - 768) * 0.5);
      -- EFM TEMPORARY FIX - There is a discrepancy in scaling right now. Maybe rounding?  So, I'm rounding up a little

      backdropBackground:scale(bdScale,bdScale)
      --dprint("bdScale", bdScale, string.len( name ), name )
   end
   self.changeBackdrop = changeBackdrop;

   -- Get lua tables from JSON data
   local categoryData = DATA('CATEGORY')
   local rehearsalPlaybackData;
   if (sceneMode == "showtime") then
      rehearsalPlaybackData = DATA('SHOWTIME')
   else
      rehearsalPlaybackData = DATA('REHEARSAL')
   end
   local setDesignData = DATA('SETDESIGN')
   local instrumentData = DATA('INSTRUMENT')
   local characterData = DATA('CHARACTER')
   local costumeData = DATA('COSTUME')
   local sceneLayoutData = DATA('SCENELAYOUT')

   -- Insert 'None' as first item of all character costume categories
   --[[
   local none = {
      id = 'none',
      imageFile = UI('COSTUME_NONE_IMAGE'),
      width = UI('COSTUME_NONE_WIDTH'),
      height = UI('COSTUME_NONE_HEIGHT'),
      xOffset = 0,
      yOffset = 0
   }
   for i=1,#characterData do
      for k,v in pairs(characterData[i].clothing) do
         table.insert(characterData[i].clothing[k], 1, none)
      end
   end

   local layers = {}
   local selectedCharacter = ''
   --]]

   local getCostumeForCharacter = function(character)
      local charData
      for i=1,#characterData do
         if (characterData[i].id == character) then
            charData = characterData[i]
            break
         end
      end
      if (not charData) then
         error('No costume data for "' .. character .. '"')
      end
      return charData
   end

   --  local function clearLayer(categoryId)
   --     -- clear specified layer
   --     for k,v in pairs(layers) do
   --        if (categoryId == k) then
   --           for i=layers[k].numChildren,1,-1 do
   --              layers[k][i]:removeSelf()
   --              layers[k][i] = nil
   --           end
   --           break
   --        end
   --     end
   --  end

   FRC_Rehearsal_Scene.rewindPreview = function (autoPlay)
      -- logic flow:  stop audio, rewind it, if it was playing when we rewound, start it again
      print("rewindPreview");
      songGroup = FRC_AudioManager:findGroup("songPlayback");
      local trackStartDelay;
      local activeHandle;
      if (songGroup) then
         if (#songGroup.handles) then
            for i=1,#songGroup.handles do
               activeHandle = songGroup.handles[i];
               -- audio.pause(activeHandle);
               audio.rewind(activeHandle);
               -- trackStartDelay = instrumentTrackStartOffsets[activeHandle.name];
               -- if (trackStartDelay > 0) then
               --   -- wait before playing the audio
               --   timer.performWithDelay( trackStartDelay, function()
               --       audio.resume(activeHandle);
               --    end )
               -- else
               --   audio.resume(activeHandle);
               -- end
            end
         end
      end
      if (autoPlay) then
         FRC_Rehearsal_Scene.stopRehearsalMode(true);
         FRC_Rehearsal_Scene.startRehearsalMode(0, true);
      end
   end

   FRC_Rehearsal_Scene.stopRehearsalMode = function (pausing)
      --dprint("stopRehearsalMode() @ ", system.getTimer()) 
      
      -- Do we have an 'automatic' stopRehearsal() call pending?  If so, cancel it!
      --
      if( FRC_Rehearsal_Scene._autoStoRehearsalTimer ) then
         timer.cancel( FRC_Rehearsal_Scene._autoStoRehearsalTimer )
         FRC_Rehearsal_Scene._autoStoRehearsalTimer = nil
      end
      
      print("StopRehearsal - sceneMode: ", sceneMode);
      if not pausing then
         -- eventually we will transition animate on offscreen and the other onscreen
         categoriesContainer.isVisible = ( sceneMode ~= "showtime" );
         if itemScrollers then
            for k,v in pairs( itemScrollers ) do
               if v then
                  v.isVisible = false;
               end
            end
         end
         rehearsalContainer.isVisible = ( sceneMode == "showtime" );

         if( view._overlay.touchGroup and view._overlay.touchGroup.enterFrame ) then
            Runtime:removeEventListener( "enterFrame", view._overlay.touchGroup )
            view._overlay.touchGroup = nil
            display.remove(view._overlay.touchGroup)
         end
         display.remove(view._overlay.controlTouch)
         transition.cancel( rehearsalContainer )
         rehearsalContainer.y = rehearsalContainer.y0

         -- TODO turn back on the appropriate scroller's visibility (last one that was active)

         FRC_CharacterBuilder.setEditEnable( true )
         FRC_Rehearsal_Scene.rewindPreview();
      end

      FRC_CharacterBuilder.stopStageCharacters();

      -- STOP ALL AUDIO PLAYBACK OF SONG
      local instrumentList = FRC_CharacterBuilder.getInstrumentsInUse();
      tracksGroup = FRC_AudioManager:findGroup("songTracks");
      songGroup = FRC_AudioManager:findGroup("songPlayback");
      -- kill track timers
      for i=#songTrackTimers, 1,-1 do
         timer.cancel(songTrackTimers[i]);
         songTrackTimers[i] = nil;
      end
      if (songGroup and tracksGroup and instrumentList) then
         for i, instr in pairs(instrumentList) do
            local h = songGroup:findHandle(currentSongID .. "_" .. string.lower(instr) )
            -- stop the track
            if (h) then
               print('stopping ', h.name);
               h:stop();
               -- DISABLED BECAUSE THERE IS A SEPARATE REWIND FUNCTION
               -- audio.rewind(h.handle);
               -- h:rewindAudio(); THIS SHOULD WORK BUT DOESN'T
               -- this removes h from the songGroup
               songGroup:removeHandle(h);
               -- add the handle back to the tracksGroup
               tracksGroup:addHandle(h);

            end
         end
      end
      rehearsalContainer.isPlaying = false
   end

   FRC_Rehearsal_Scene.startRehearsalMode = function( playDelay, restartingMusic )
      playDelay = playDelay or 0
      print("StartRehearsal");
      categoriesContainer.isVisible = false;
      if itemScrollers then
         for k,v in pairs( itemScrollers ) do
            if v then
               v.isVisible = false;
            end
         end
      end

      -- Code to handle transitioning controls on/off screen based on time and touches.
      local touchGroup = display.newGroup()
      view._overlay.touchGroup = touchGroup
      touchGroup.enterFrame = function( self )
         if( self.removeSelf == nil ) then
            Runtime:removeEventListener( "enterFrame", self )
            return
         end
         if( self.toFront ) then
            self:toFront()
         end
      end
      Runtime:addEventListener( "enterFrame", touchGroup )

      view._overlay.controlTouch = display.newRect( touchGroup, centerX, centerY, screenW, screenH )
      view._overlay.controlTouch.isHitTestable = true
      view._overlay.controlTouch.alpha = 0
      view._overlay.controlTouch.touch = function( self, event )
         if( event.phase == "began") then
            transition.cancel( rehearsalContainer )
            local function onComplete()
               transition.to( rehearsalContainer, { delay = 1000, time = 700, y = rehearsalContainer.y0 + rehearsalContainer.contentHeight } )
            end
            transition.to( rehearsalContainer, { time = 700, y = rehearsalContainer.y0, onComplete = onComplete } )
         end
         return false
      end
      view._overlay.controlTouch:addEventListener("touch")


      rehearsalContainer.isVisible = true;

      -- EFM my version
      local function startPlaying()
         
         -- Do we have an 'automatic' stopRehearsal() call pending?  If so, cancel it!
         --
         if( FRC_Rehearsal_Scene._autoStoRehearsalTimer ) then
            timer.cancel( FRC_Rehearsal_Scene._autoStoRehearsalTimer )
            FRC_Rehearsal_Scene._autoStoRehearsalTimer = nil
         end
         
         tracksGroup = FRC_AudioManager:findGroup("songTracks")
         songGroup = FRC_AudioManager:findGroup("songPlayback")
         local expectedEndTime = 0;
         local trackEndTime;

         print(tracksGroup) -- DEBUG

         --
         -- get a list of the instruments that are active
         local instrumentList = FRC_CharacterBuilder.getInstrumentsInUse();

         --
         -- Find the shortest offset
         local shortestOffset = math.huge
         for i, instr in pairs(instrumentList) do
            local offset = tonumber(songTrackOffsetData[ currentSongID .. "_" .. string.lower(instr) ])
            if( offset < shortestOffset ) then
               shortestOffset = offset
            end
         end

         --
         -- Build list of offsets for all instrument in use, subtracting 'shortestOffset'
         -- from their starting time.
         instrumentTrackStartOffsets = {};
         for i, instr in pairs(instrumentList) do
            local instrID = currentSongID .. "_" .. string.lower(instr)
            local details = {} 
            details.startOffset = (songTrackOffsetData[instrID] - shortestOffset)
            instrumentTrackStartOffsets[instrID] = details

            -- analyze the start time offset + track duration to see if the track ends later (last eventually)
            if (tracksGroup) then
               local h = tracksGroup:findHandle(instrID);
               if (h) then
                  trackEndTime = tonumber(songTrackOffsetData[instrID] + h:getDuration() - shortestOffset);
                  local details = instrumentTrackStartOffsets[instrID]
                  details.trackEndTime = trackEndTime

                  if (trackEndTime > expectedEndTime) then
                     -- we have a new max end time
                     expectedEndTime = trackEndTime;
                     --dprint("expectedEndTime is now: ", expectedEndTime); -- DEBUG
                  end
               end
            end

         end
         
         --[[  -- Uncomment for quick debugging of this code.
         for k,v in pairs(instrumentTrackStartOffsets) do
            v.startOffset = math.random(500,1000)
            v.trackEndTime = math.random(1200,1600)
         end 
         expectedEndTime = 10000
         --]]

         --
         -- Find the song for each instrument
         if (songGroup and tracksGroup and instrumentList) then
            for i, instr in pairs(instrumentList) do
               print(i, instr);
               instrID = currentSongID .. "_" .. string.lower(instr)
               local h = tracksGroup:findHandle(instrID)
               -- add the song to a playback group if it is legitimate for this song
               if (h) then
                  print('playing ', h.name)
                  songGroup:addHandle(h)
                  local trackStartDelay = instrumentTrackStartOffsets[instrID].startOffset
                  if (trackStartDelay > 0) then
                     -- wait before playing the audio
                     --dprint("Wait to play", instrID, instrumentTrackStartOffsets[instrID] ) 
                     songTrackTimers[#songTrackTimers+1] = timer.performWithDelay( trackStartDelay,
                        function()
                           h:play()
                        end )
                  else
                     h:play()
                  end
               end
            end

            FRC_CharacterBuilder.setEditEnable( false )
            FRC_CharacterBuilder.playStageCharacters( instrumentTrackStartOffsets, expectedEndTime )
            
            -- Stop any outstanding stop timer we may have
            FRC_Rehearsal_Scene._autoStoRehearsalTimer = timer.performWithDelay( expectedEndTime + 500,
               function()
                  FRC_Rehearsal_Scene._autoStoRehearsalTimer = nil
                  if( sceneMode == "showtime" ) then                  
                     FRC_Rehearsal_Scene.closeCurtains(1500)
                  else
                     FRC_Rehearsal_Scene.stopRehearsalMode(false)
                  end                  
               end )
         end

         rehearsalContainer.isPlaying = true
      end

      transition.cancel( rehearsalContainer )
      rehearsalContainer.y = rehearsalContainer.y0
      if( restartingMusic == true ) then
         startPlaying()
         transition.to( rehearsalContainer, { delay = 0, time = 700, y = rehearsalContainer.y0 + rehearsalContainer.contentHeight } )
      elseif( sceneMode == "showtime" ) then
         transition.to( rehearsalContainer, { delay = 1800, time = 700, y = rehearsalContainer.y0 + rehearsalContainer.contentHeight } )
         timer.performWithDelay( 2500, function()
               if( view.removeSelf == nil ) then return end
               startPlaying()
            end )
      else
         startPlaying()
         transition.to( rehearsalContainer, { delay = 1800, time = 700, y = rehearsalContainer.y0 + rehearsalContainer.contentHeight } )
      end


      -- play the entire group
      --[[
    if songGroup then
      songGroup:playAll({ onComplete = function()
        FRC_Rehearsal_Scene.stopRehearsalMode();
      end } );
    end
    --]]
   end

   self.startOver = function()
      FRC_CharacterBuilder.easyAlert( "Start Over?",
         "Would you like to:",
         {
            {"Clear The Stage", function() FRC_Rehearsal_Scene.doStartOver() end },
            {"Rehearse A New Song", function()  FRC_Rehearsal_Scene.doStartOver(); FRC_Rehearsal_Scene.redo_createOrLoadShow(); end },
            {"Cancel", function()  end },
            } )
   end

   -- create sceneLayout items
   local sceneLayoutMethods = {}
   local sceneLayout = {}
   local sceneLayoutAnimationSequences

   for i=1,#sceneLayoutData do
      if sceneLayoutData[i].imageFile then
         sceneLayout[i] = display.newImageRect(view._content, UI('IMAGES_PATH') .. sceneLayoutData[i].imageFile, sceneLayoutData[i].width, sceneLayoutData[i].height)
         FRC_Layout.placeImage(sceneLayout[i],  sceneLayoutData[i], false )  --EFM


      elseif sceneLayoutData[i].animationFiles then
         -- get the list of animation files and create the animation object
         -- preload the animation data (XML and images) early
         sceneLayout[i] = FRC_AnimationManager.createAnimationClipGroup(sceneLayoutData[i].animationFiles, animationXMLBase, animationImageBase)
         view._content:insert(sceneLayout[i]);
         FRC_Layout.placeAnimation(sceneLayout[i], sceneLayoutData[i], false ) --EFM

         for j=1, sceneLayout[i].numChildren do
            sceneLayout[i][j]:play({
                  showLastFrame = false,
                  playBackward = false,
                  autoLoop = true,
                  palindromicLoop = false,
                  delay = 0,
                  intervalTime = 30,
                  maxIterations = 1
               })
         end
      end

      if (sceneLayoutData[i].onTouch) then
         sceneLayout[i].onTouch = sceneLayoutMethods[sceneLayoutData[i].onTouch]
         if (sceneLayout[i].onTouch) then
            sceneLayout[i]:addEventListener('touch', function(e)
                  if (e.phase == "began") then
                     e.target.onTouch()
                  end
                  return true
               end)
         end
      end
   end

   local category_button_spacing = 48
   local button_spacing = 24
   local button_scale = 0.75
   local categoriesWidth = button_spacing
   local categoriesHeight = 0

   -- SETUP OF REHEARSAL MODE CATEGORY SELECTOR
   -- calculate panel dimensions for category buttons
   for i=1,#rehearsalPlaybackData do
      categoriesWidth = categoriesWidth + (rehearsalPlaybackData[i].width * button_scale) + category_button_spacing;
      if ((rehearsalPlaybackData[i].height * button_scale) > categoriesHeight) then
         categoriesHeight = rehearsalPlaybackData[i].height * button_scale;
      end
   end
   categoriesHeight = categoriesHeight + (category_button_spacing * 1.25); -- (category_button_spacing * 2)

   -- create button panel for categories (aligned to the bottom of the screen)
   rehearsalContainer = display.newContainer(categoriesWidth, categoriesHeight)
   rehearsalContainerBg = display.newRoundedRect(rehearsalContainer, 0, 0, categoriesWidth, categoriesHeight, 11)
   rehearsalContainerBg:setFillColor(1.0, 1.0, 1.0, 0.85); -- 1.0, 1.0, 1.0, 0.35)
   rehearsalContainerBg.x, rehearsalContainerBg.y = 0, 0
   rehearsalContainer.x = display.contentCenterX
   rehearsalContainer.y = display.contentHeight - (categoriesHeight * 0.5) + (category_button_spacing * 1.65)
   rehearsalContainer.y0 = rehearsalContainer.y

   view._playControls:insert(rehearsalContainer)

   FRC_Rehearsal_Scene.lastStartTime = system.getTimer()    -- EFM hack!! To avoid early clicks on replay that do nothing
   local replayDelay = 4000                                 -- EFM hack!! To avoid early clicks on replay that do nothing
   for i=1,#rehearsalPlaybackData do
      local button = ui.button.new({
            id = rehearsalPlaybackData[i].id,
            imageUp = UI('IMAGES_PATH') .. rehearsalPlaybackData[i].imageUp,
            imageDown = UI('IMAGES_PATH') .. rehearsalPlaybackData[i].imageDown,
            focusState = UI('IMAGES_PATH') .. rehearsalPlaybackData[i].imageFocused,
            disabled = UI('IMAGES_PATH') .. rehearsalPlaybackData[i].imageDisabled,
            width = rehearsalPlaybackData[i].width * button_scale,
            height = rehearsalPlaybackData[i].height * button_scale,
            onPress = function(e)
               -- show the focused state for the selected category icon
               local self = e.target
               print("Rehearsal control selected: ",self.id);
               if (self.id == "StopPreview") then
                  -- print("self.id == StopPreview");
                  FRC_Rehearsal_Scene.stopRehearsalMode();
                  if ( sceneMode == "showtime" ) then
                     storyboard.gotoScene('Scenes.Lobby');
                  end
               elseif (self.id == "PausePreview") then
                  if( rehearsalContainer.isPlaying == true ) then
                     FRC_Rehearsal_Scene.stopRehearsalMode(true);
                  else
                     FRC_Rehearsal_Scene.startRehearsalMode(0, true);
                  end
               elseif (self.id == "RewindPreview") then
                  FRC_Rehearsal_Scene.rewindPreview(true);
               elseif (self.id == "ReplayShowtime") then
                  local curTime = system.getTimer() 
                  if( curTime - FRC_Rehearsal_Scene.lastStartTime < replayDelay ) then return end
                  replayDelay = 3000
                  FRC_Rehearsal_Scene.stopRehearsalMode(true);                  
                  FRC_Rehearsal_Scene.startRehearsalMode( 1600, false );
                  FRC_Rehearsal_Scene.replayCurtains( 1500, 100 )
                  FRC_Rehearsal_Scene.lastStartTime = curTime
               elseif self:getFocusState() then
                  -- hide the itemScroller
                  rehearsalItemScrollers[self.id].isVisible = false;
                  self:setFocusState(false)
               else
                  self:setFocusState(true)
                  -- present the scroller contain the selected category's content
                  rehearsalItemScrollers[self.id].isVisible = true
                  for i=2,rehearsalContainer.numChildren do
                     if (rehearsalContainer[i] ~= self) then
                        rehearsalContainer[i]:setFocusState(false)
                        rehearsalItemScrollers[rehearsalContainer[i].id].isVisible = false
                     end
                  end
               end
            end
         })
      rehearsalContainer:insert(button);
      button.x = (-(categoriesWidth * 0.5) + (button.contentWidth * 0.5) + category_button_spacing) + (i - 1) * (button.contentWidth + category_button_spacing)
      button.y = -category_button_spacing * 0.75
      -- hide this by default
      rehearsalContainer.isVisible = false;
   end

   itemScrollers = {}
   categoriesWidth = button_spacing;
   categoriesHeight = 0;
   x = -(screenW * 0.5) + button_spacing;

   -- calculate panel dimensions for category buttons
   for i=1,#categoryData do
      categoriesWidth = categoriesWidth + (categoryData[i].width * button_scale) + category_button_spacing
      if ((categoryData[i].height * button_scale) > categoriesHeight) then
         categoriesHeight = categoryData[i].height * button_scale
      end
   end
   categoriesHeight = categoriesHeight + (category_button_spacing * 1.25) -- (category_button_spacing * 2)

   -- create button panel for categories (aligned to the bottom of the screen)
   categoriesContainer = display.newContainer(categoriesWidth, categoriesHeight)
   categoriesBg = display.newRoundedRect(categoriesContainer, 0, 0, categoriesWidth, categoriesHeight, 11)
   categoriesBg:setFillColor(1.0, 1.0, 1.0, 0.85); -- 1.0, 1.0, 1.0, 0.35)
   categoriesBg.x, categoriesBg.y = 0, 0
   categoriesContainer.x = display.contentCenterX
   categoriesContainer.y = display.contentHeight - (categoriesHeight * 0.5) + (category_button_spacing * 1.65)

   for i=1,#categoryData do
      local button = ui.button.new({
            id = categoryData[i].id,
            imageUp = UI('IMAGES_PATH') .. categoryData[i].imageUp,
            imageDown = UI('IMAGES_PATH') .. categoryData[i].imageDown,
            focusState = UI('IMAGES_PATH') .. categoryData[i].imageFocused,
            disabled = UI('IMAGES_PATH') .. categoryData[i].imageDisabled,
            width = categoryData[i].width * button_scale,
            height = categoryData[i].height * button_scale,
            onPress = function(e)
               -- show the focused state for the selected category icon
               local self = e.target --EDO
               if (self.id == "StartRehearsal") then
                  FRC_Rehearsal_Scene.startRehearsalMode();
               elseif self:getFocusState() then
                  -- hide the itemScroller
                  itemScrollers[self.id].isVisible = false;
                  self:setFocusState(false)
               else
                  self:setFocusState(true)
                  -- present the scroller contain the selected category's content
                  itemScrollers[self.id].isVisible = true
                  for i=2,categoriesContainer.numChildren do
                     if (categoriesContainer[i] ~= self) then
                        categoriesContainer[i]:setFocusState(false)
                        itemScrollers[categoriesContainer[i].id].isVisible = false
                     end
                  end
               end
            end
         })
      categoriesContainer:insert(button)
      button.x = (-(categoriesWidth * 0.5) + (button.contentWidth * 0.5) + category_button_spacing) + (i - 1) * (button.contentWidth + category_button_spacing)
      button.y = -category_button_spacing * 0.75

      -- create corresponding item scroll containers
      local scroller = ui.scrollcontainer.new({   -- EFM EDO
            width = screenW,
            height = (categoriesHeight * button_scale) - 5,
            xScroll = true,
            yScroll = false,
            leftPadding = button_spacing,
            rightPadding = button_spacing,
            bgColor = {1.0, 1.0, 1.0, 0.65} -- { 1.0, 1.0, 1.0, 1.0 }
         })
      -- scroller.bg.alpha = 0.65
      view._overlay:insert(scroller)
      scroller.x = display.contentCenterX
      scroller.y = categoriesContainer.contentBounds.yMin - (scroller.contentHeight * 0.5)
      scroller.isVisible = false
      itemScrollers[categoryData[i].id] = scroller
      if (i == 1) then
         button:setFocusState(true)
         scroller.isVisible = true
      end
   end

   -- setup for container construction
   button_scale = 0.75;
   x = -(screenW * 0.5) + button_spacing
   local buttonHeight = 0

   -- create SetDesign scroll container
   local setDesignData = {}; -- scene.saveData.savedItems

   -- get previously saved SetDesigns
   FRC_SetDesign.getSavedData();

   if ((FRC_SetDesign.saveData) and (#FRC_SetDesign.saveData.savedItems > 0)) then
      for i=#FRC_SetDesign.saveData.savedItems,1,-1 do
         local item = FRC_SetDesign.saveData.savedItems[i];
         table.insert(setDesignData, 1, {
               id = item.id,
               imageFile = item.id .. item.thumbSuffix,
               width = item.thumbWidth,
               height = item.thumbHeight,
               baseDir = "DocumentsDirectory"
            });
      end
   end

   -- setup the "none" option for SetDesigns
   table.insert(setDesignData, 1, {
         id = 'none',
         imageFile = UI('IMAGES_PATH').. UI('SCROLLER_NONE_IMAGE'),
         width = UI('SCROLLER_NONE_WIDTH'),
         height = UI('SCROLLER_NONE_HEIGHT'),
         xOffset = 0,
         yOffset = 0,
      });

   for i=1,#setDesignData do
      -- DEBUG
      --print('width', setDesignData[i].width * button_scale);
      --dprint('id:', setDesignData[i].id, 'width:', setDesignData[i].width, 'height:', setDesignData[i].height);

      local scroller = itemScrollers['SetDesign']
      buttonHeight = scroller.contentHeight - button_spacing;

      local button = ui.button.new({
            id = setDesignData[i].id,
            imageUp = setDesignData[i].imageFile,
            imageDown = setDesignData[i].imageFile,
            width = setDesignData[i].width * button_scale,
            height = setDesignData[i].height * button_scale,
            baseDirectory = system[setDesignData[i].baseDir],
            parentScrollContainer = scroller,
            pressAlpha = 0.5,
            onRelease = function(e)
               local self = e.target
               -- CODE TO HANDLE SETDESIGN CHANGE GOES HERE
               for i=1,#setDesignData do
                  if (setDesignData[i].id == self.id) then
                     if (self.id == 'none') then                        
                        FRC_Rehearsal_Scene.changeSet(0)
                        FRC_Rehearsal_Scene.changeBackdrop("None");
                        -- repositionSet();
                        FRC_Rehearsal_Scene.setID = nil
                     else                        
                        FRC_Rehearsal_Scene.setID = setDesignData[i].id
                        for i = 1, #FRC_SetDesign.saveData.savedItems do
                           if(FRC_SetDesign.saveData.savedItems[i].id == FRC_Rehearsal_Scene.setID ) then
                              FRC_Rehearsal_Scene.changeSet(FRC_SetDesign.saveData.savedItems[i].setIndex)
                              FRC_Rehearsal_Scene.changeBackdrop(FRC_SetDesign.saveData.savedItems[i].backdropName);
                           end
                        end

                        repositionSet();
                     end
                     return;
                  end
               end
               --print(self.id)
            end
         })
      button.categoryId = 'SetDesign'
      scroller:insert(button)
      x = x + (button.contentWidth * 0.5)
      button.x, button.y = x, 0
      x = x + (button.contentWidth * 0.5) + (button_spacing * 1.5)
   end

   -- locate the user's existing SetDesign data
   -- CODE SNIPPET
   --  local function DATA(key, baseDir)
   --  	baseDir = baseDir or system.ResourceDirectory;
   --  	return FRC_DataLib.readJSON(FRC_SetDesign_Settings.DATA[key], baseDir);
   --  end
   ----------- Another snippet
   -- FRC_SetDesign.saveData = FRC_DataLib.readJSON(saveDataFilename, system.DocumentsDirectory);
   -- if (not FRC_SetDesign.saveData) then
   -- 	FRC_DataLib.saveJSON(saveDataFilename, emptyDataFile);
   -- 	FRC_SetDesign.saveData = emptyDataFile;
   -- end
   ---------- code used to pass saved data structure to FRC_GalleryPopup
   -- data = scene.saveData.savedItems,
   -- basically we need to have the scroller operate like a differently laid out version of FRC_GalleryPopup

   -- create Instruments scroll container
   x = -(screenW * 0.5) + button_spacing

   --
   -- 'None' Button
   --
   local scroller = itemScrollers['Instrument']
   local button = ui.button.new({
         id = "NONE",
         imageUp = UI('NONE_BUTTON_UP') ,
         imageDown = UI('NONE_BUTTON_DOWN'),
         imageFocused = UI('NONE_BUTTON_FOCUSED'),
         imageDisabled = UI('NONE_BUTTON_DISABLED'),
         width = 100 * 0.96, -- * button_scale, -- EFM why is 1.0 not same as stage none?
         height = 63 * 0.96, -- * button_scale, -- EFM why is 1.0 not same as stage none?
         parentScrollContainer = scroller,
         pressAlpha = 0.5,
         onRelease = function(e)
            FRC_CharacterBuilder.removeInstrument()
            return true
         end
      })
   button.categoryId = 'Instrument'
   scroller:insert(button)
   x = x + (button.contentWidth * 0.5)
   button.x, button.y = x, 0
   x = x + (button.contentWidth * 0.5) + (button_spacing * 1.5)

   -- for now, just grab the first song's instrument list
   local songInstruments = instrumentData[1].instruments;
   for i=1,#songInstruments do
      local scroller = itemScrollers['Instrument']
      buttonHeight = scroller.contentHeight - button_spacing
      local button = ui.button.new({
            id = songInstruments[i].id,
            imageUp = UI('IMAGES_PATH') .. songInstruments[i].imageUp,
            imageDown = UI('IMAGES_PATH') .. songInstruments[i].imageDown,
            imageFocused = UI('IMAGES_PATH') .. songInstruments[i].imageFocused,
            imageDisabled = UI('IMAGES_PATH') .. songInstruments[i].imageDisabled,
            width = songInstruments[i].width * button_scale,
            height = songInstruments[i].height * button_scale,
            parentScrollContainer = scroller,
            pressAlpha = 0.5,
            onRelease = function(e)
               local self = e.target
               FRC_CharacterBuilder.newInstrument( self.id )
               return true
            end
         })
      button.categoryId = 'Instrument'
      scroller:insert(button)
      x = x + (button.contentWidth * 0.5)
      button.x, button.y = x, 0
      x = x + (button.contentWidth * 0.5) + (button_spacing * 1.5)
   end

   -- create Character scroll container
   -- reset x
   x = -(screenW * 0.5) + button_spacing

   local scroller = itemScrollers['Character']
   local button = ui.button.new({
         id = "NONE",
         imageUp = UI('NONE_BUTTON_UP') ,
         imageDown = UI('NONE_BUTTON_DOWN'),
         imageFocused = UI('NONE_BUTTON_FOCUSED'),
         imageDisabled = UI('NONE_BUTTON_DISABLED'),
         width = 100 * 0.96, -- * button_scale, -- EFM why is 1.0 not same as stage none?
         height = 63 * 0.96, -- * button_scale, -- EFM why is 1.0 not same as stage none?
         parentScrollContainer = scroller,
         pressAlpha = 0.5,
         onRelease = function(e)
            FRC_CharacterBuilder.removeCharacter()
            return true
         end
      })
   button.categoryId = 'Instrument'
   scroller:insert(button)
   x = x + (button.contentWidth * 0.5)
   button.x, button.y = x, 0
   x = x + (button.contentWidth * 0.5) + (button_spacing * 1.5)

   for i=1,#characterData do
      local scroller = itemScrollers['Character']
      buttonHeight = scroller.contentHeight - button_spacing
      local button = ui.button.new({
            id = characterData[i].id,
            imageUp = UI('IMAGES_PATH') .. (characterData[i].bodyThumb or characterData[i].bodyImage),
            imageDown = UI('IMAGES_PATH') .. (characterData[i].bodyThumb or characterData[i].bodyImage),
            width = buttonHeight * (characterData[i].bodyWidth / characterData[i].bodyHeight),
            height = buttonHeight,
            parentScrollContainer = scroller,
            pressAlpha = 0.5,
            onRelease = function(e)
               local self = e.target
               FRC_CharacterBuilder.setCurrentCharacterType( self.id ) --EFM
               FRC_CharacterBuilder.rebuildCostumeScroller() --EFM
               local charactersButton = categoriesContainer[4] --EDO
               local costumesButton = categoriesContainer[5] --EDO
               charactersButton:setFocusState(false)
               costumesButton:setFocusState(true)
               for k,v in pairs( itemScrollers ) do
                  v.isVisible = false
               end
               itemScrollers.Costume.isVisible = true
               costumesButton:press()
               costumesButton:release()
            end
         })
      button.categoryId = 'Character'
      scroller:insert(button)
      x = x + (button.contentWidth * 0.5)
      button.x, button.y = x, 0
      x = x + (button.contentWidth * 0.5) + (button_spacing * 1.5)
   end

   --
   -- EFM costume scroller is filled on demand in FRC_CharacterBuilder.lua as a side-effect of selecting the current'animal' category
   --
   view._overlay:insert(categoriesContainer)

   FRC_CharacterBuilder.init( { view                  = view,
         currentSongID         = currentSongID,
         animationXMLBase      = animationXMLBase,
         animationImageBase    = animationImageBase,
         itemScrollers         = itemScrollers,
         categoriesContainer   = categoriesContainer } )
   FRC_CharacterBuilder.rebuildInstrumenScroller( ) -- EFM Load/Create New Show Logic ++
   FRC_CharacterBuilder.rebuildCostumeScroller( ) -- EFM Load/Create New Show Logic ++


   ----[[
   function FRC_Rehearsal_Scene.doStartOver()
      FRC_CharacterBuilder.init( {
            view                  = FRC_Rehearsal_Scene.view,
            currentSongID         = currentSongID,
            animationXMLBase      = animationXMLBase,
            animationImageBase    = animationImageBase,
            itemScrollers         = itemScrollers,
            showTimeMode          = false,
            categoriesContainer   = categoriesContainer } ) 
      FRC_CharacterBuilder.rebuildInstrumenScroller( )
      FRC_Rehearsal_Scene.changeSet(0)
      FRC_Rehearsal_Scene.changeBackdrop("None");
      FRC_Rehearsal_Scene.setIndex = nil
      FRC_Rehearsal_Scene.backdropName = nil
      FRC_Rehearsal_Scene.setID = nil
   end
   --]]

   local canLoad
   if( sceneMode == "showtime" ) then
      canLoad = not ((FRC_Rehearsal_Scene.publishData.savedItems == nil) or (#FRC_Rehearsal_Scene.publishData.savedItems < 1))
   else
      canLoad = not ((FRC_Rehearsal_Scene.saveData.savedItems == nil) or (#FRC_Rehearsal_Scene.saveData.savedItems < 1))
   end

   local function showLoadPopup( goHomeOnCancel )
      local FRC_GalleryPopup = require('FRC_Modules.FRC_GalleryPopup.FRC_GalleryPopup');

      local onCancel
      if( goHomeOnCancel ) then
         onCancel = function()
            storyboard.gotoScene('Scenes.Lobby')
         end
      end

      local galleryPopup

      galleryPopup = FRC_GalleryPopup.new({
            title = FRC_Rehearsal_Settings.DATA.LOAD_PROMPT,
            isLoadPopup = true,
            hideBlank = true,
            width = screenW * 0.85,
            height = screenH * 0.75,
            data = ( sceneMode == "showtime" ) and FRC_Rehearsal_Scene.publishData.savedItems or FRC_Rehearsal_Scene.saveData.savedItems,
            onCancel = onCancel,
            callback = function(e)
               galleryPopup:dispose();
               galleryPopup = nil;
               if( sceneMode == "showtime" ) then
                  FRC_Rehearsal_Scene:loadShowTime(e);
               else
                  FRC_Rehearsal_Scene:load(e);
               end
            end
         });
   end
   local function onLoad()
      showLoadPopup( false ); -- TEMP DISABLED UNTIL WE ARCHITECT DATA FORMAT FOR SHOWS
   end

   -- EFM Load/Create New Show Logic
   local function onCreateHamster()
      currentSongID = "hamsters";
      FRC_CharacterBuilder.init( {
            view                  = view,
            currentSongID         = currentSongID,
            animationXMLBase      = animationXMLBase,
            animationImageBase    = animationImageBase,
            itemScrollers         = itemScrollers,
            categoriesContainer   = categoriesContainer } )
      FRC_CharacterBuilder.rebuildInstrumenScroller( )
   end

   local function onCreateCow()
      currentSongID = "mechanicalcow";
      FRC_CharacterBuilder.init( {
            view                  = view,
            currentSongID         = currentSongID,
            animationXMLBase      = animationXMLBase,
            animationImageBase    = animationImageBase,
            itemScrollers         = itemScrollers,
            categoriesContainer   = categoriesContainer } )
      FRC_CharacterBuilder.rebuildInstrumenScroller( )
   end


   function FRC_Rehearsal_Scene.redo_createOrLoadShow()
      FRC_CharacterBuilder.createOrLoadShow( onLoad, onCreateHamster, onCreateCow, canLoad )
   end


   if( sceneMode == "rehearsal" ) then
      if( not event.params.skipCreateLoad ) then
         FRC_CharacterBuilder.createOrLoadShow( onLoad, onCreateHamster, onCreateCow, canLoad )
      end
   else
      if( canLoad ) then
         showLoadPopup( true )
      else
         -- commented out because we get into trouble reloading Rehearsal from within itself
         --[[
        local canLoadShow = not ((FRC_Rehearsal_Scene.saveData.savedItems == nil) or (#FRC_Rehearsal_Scene.saveData.savedItems < 1));
         FRC_CharacterBuilder.easyAlert( "No Saved Performances",
            "You didn't created any performances yet.\n\nWould you like to go to Rehearsal\nto make a show or create a performance?",
            {
               {"Yes", function() FRC_CharacterBuilder.createOrLoadShow( onLoad, onCreateHamster, onCreateCow, canLoadShow ) end },
               {"No", function() storyboard.gotoScene('Scenes.Lobby') end },
               } )
        --]]
         FRC_CharacterBuilder.easyAlert( "No Saved Performances",
            "You didn't created any performances yet.\n\nPlease go to Rehearsal to make a show or create a performance.",
            {
               {"OK", function() storyboard.gotoScene('Scenes.Lobby') end },
               } )
      end
   end

   if( sceneMode == "showtime") then
      view._overlay.isVisible = false
   end

   if (FRC_Rehearsal_Scene.postCreateScene) then
      FRC_Rehearsal_Scene:postCreateScene(event)
   end
end





function FRC_Rehearsal_Scene:enterScene(event)
   local view = self.view

   if (FRC_Rehearsal_Scene.preEnterScene) then
      FRC_Rehearsal_Scene:preEnterScene(event)
   end

   native.setActivityIndicator(false);

   -- pause background music (if enabled)
   if (FRC_AppSettings.get("soundOn")) then
      local musicGroup = FRC_AudioManager:findGroup("music");
      if musicGroup then
         musicGroup:pause();
      end
   end

   if (FRC_Rehearsal_Scene.postEnterScene) then
      FRC_Rehearsal_Scene:postEnterScene(event)
   end

end


function FRC_Rehearsal_Scene:exitScene(event)
   local view = self.view
   if (FRC_Rehearsal_Scene.preExitScene) then
      FRC_Rehearsal_Scene:preExitScene(event)
   end

   -- in case audio was playing just before the user is leaving the scene
   FRC_Rehearsal_Scene.stopRehearsalMode();

   -- resume background music (if enabled)
   if (FRC_AppSettings.get("soundOn")) then
      local musicGroup = FRC_AudioManager:findGroup("music");
      if musicGroup then
         musicGroup:resume();
      end
   end

   if (FRC_Rehearsal_Scene.postExitScene) then
      FRC_Rehearsal_Scene:postExitScene(event)
   end

end

function FRC_Rehearsal_Scene:didExitScene(event)
   local view = self.view
   if (FRC_Rehearsal_Scene.preDidExitScene) then
      FRC_Rehearsal_Scene:preDidExitScene(event)
   end

   if (FRC_Rehearsal_Scene.postDidExitScene) then
      FRC_Rehearsal_Scene:postDidExitScene(event)
   end
end


FRC_Rehearsal_Scene:addEventListener('createScene', FRC_Rehearsal_Scene)
FRC_Rehearsal_Scene:addEventListener('enterScene', FRC_Rehearsal_Scene)
FRC_Rehearsal_Scene:addEventListener('exitScene', FRC_Rehearsal_Scene)
FRC_Rehearsal_Scene:addEventListener('didExitScene', FRC_Rehearsal_Scene)

return FRC_Rehearsal_Scene
