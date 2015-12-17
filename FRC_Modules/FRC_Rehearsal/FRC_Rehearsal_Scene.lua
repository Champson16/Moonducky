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

local FRC_ArtCenter;
local artCenterLoaded = pcall(function()
      FRC_ArtCenter = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter');
   end);

-- ====================================================================
-- Locals
-- ====================================================================
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

FRC_Rehearsal_Scene.setIndex = 0;
FRC_Rehearsal_Scene.backdropIndex = 0;

-- Setup the audio groups for each song
FRC_AudioManager:newGroup({
  name = "songTracks",
  maxChannels = 18
});
FRC_AudioManager:newGroup({
  name = "songPlayback",
  maxChannels = 9
});

-- load up the audio tracks for Hamsters song
FRC_AudioManager:newHandle({
  name = "hamsters_bass",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_HamsterWantToBeFree_Bass.mp3",
  group = "songTracks"
});
FRC_AudioManager:newHandle({
  name = "hamsters_conga",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_HamsterWantToBeFree_Conga.mp3",
  group = "songTracks"
});
FRC_AudioManager:newHandle({
  name = "hamsters_guitar",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_HamsterWantToBeFree_Guitar.mp3",
  group = "songTracks"
});
FRC_AudioManager:newHandle({
  name = "hamsters_harmonica",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_HamsterWantToBeFree_Harmonica.mp3",
  group = "songTracks"
});
FRC_AudioManager:newHandle({
  name = "hamsters_maracas",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_HamsterWantToBeFree_Maracas.mp3",
  group = "songTracks"
});
FRC_AudioManager:newHandle({
  name = "hamsters_microphone",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_HamsterWantToBeFree_Microphone.mp3",
  group = "songTracks"
});
FRC_AudioManager:newHandle({
  name = "hamsters_rhythmcombocheesegrater",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_HamsterWantToBeFree_RhythmComboCheeseGrater.mp3",
  group = "songTracks"
});
FRC_AudioManager:newHandle({
  name = "hamsters_sticks",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_HamsterWantToBeFree_Sticks.mp3",
  group = "songTracks"
});

-- load up the audio tracks for Mechanical Cow song
FRC_AudioManager:newHandle({
  name = "mechanicalcow_bass",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_MechanicalCow_Bass.mp3",
  group = "songTracks"
});
FRC_AudioManager:newHandle({
  name = "mechanicalcow_conga",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_MechanicalCow_Conga.mp3",
  group = "songTracks"
});
FRC_AudioManager:newHandle({
  name = "mechanicalcow_guitar",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_MechanicalCow_Guitar.mp3",
  group = "songTracks"
});
FRC_AudioManager:newHandle({
  name = "mechanicalcow_harmonica",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_MechanicalCow_Harmonica.mp3",
  group = "songTracks"
});
FRC_AudioManager:newHandle({
  name = "mechanicalcow_microphone",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_MechanicalCow_Microphone.mp3",
  group = "songTracks"
});
FRC_AudioManager:newHandle({
  name = "mechanicalcow_piano",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_MechanicalCow_Piano.mp3",
  group = "songTracks"
});
FRC_AudioManager:newHandle({
  name = "mechanicalcow_rhythmcombocymbal",
  path = "FRC_Assets/MDMT_Assets/Audio/MDMT_MusicTheatre_MechanicalCow_RhythmComboCymbal.mp3",
  group = "songTracks"
});


function FRC_Rehearsal_Scene:save(e)
   local id = e.id
   if ((not id) or (id == '')) then id = (FRC_Util.generateUniqueIdentifier(20)) end
   --local saveGroup = self.view.saveGroup
   local saveGroup = self.view.setDesignGroup

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

   local screenW, screenH = FRC_Layout.getScreenDimensions()
   local saveDataFilename = FRC_Rehearsal_Settings.DATA.DATA_FILENAME
   local newSave = {
      id = id,
      setIndex = FRC_Rehearsal_Scene.setIndex,
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
   table.print_r(e)
   --[[
   local id = e.id
   if ((not id) or (id == '')) then id = (FRC_Util.generateUniqueIdentifier(20)) end
   self.changeItem('Character', e.data.character, v)
   for k,v in pairs(e.data.categories) do
      self.changeItem(k, e.data.character, v)
   end
   self.id = id
   --]]
   if( e.data.setIndex ) then
      FRC_Rehearsal_Scene.changeSet(e.data.setIndex)
   end
   FRC_CharacterBuilder.load(e.data)
end


-- ====================================================================
-- Scene Methods
-- ====================================================================

function FRC_Rehearsal_Scene:createScene(event)
   local view = self.view
   local screenW, screenH = FRC_Layout.getScreenDimensions()
   if ((not self.id) or (self.id == '')) then self.id = FRC_Util.generateUniqueIdentifier(20) end

   -- DEBUG:
   dprint("FRC_Rehearsal_Scene - createScene")

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
   local currentSongID = "hamsters"; -- TODO change this to dynamic information based on user selection or loading of a saved show

   -- FRC_Rehearsal.getSavedData()
   self.saveData = DATA('DATA_FILENAME', system.DocumentsDirectory)
   require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal').saveData = FRC_DataLib.readJSON(saveDataFilename, system.DocumentsDirectory)

   local bg = display.newImageRect(view, UI('SCENE_BACKGROUND_IMAGE'), UI('SCENE_BACKGROUND_WIDTH'), UI('SCENE_BACKGROUND_HEIGHT'))
   FRC_Layout.scaleToFit(bg)
   bg.x, bg.y = display.contentCenterX, display.contentCenterY

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
   local setDesignGroup = display.newGroup(); view:insert(setDesignGroup);
   view.setDesignGroup = setDesignGroup;
   local backdropGroup = display.newGroup(); view.setDesignGroup:insert(backdropGroup);
   local setGroup = display.newGroup(); view.setDesignGroup:insert(setGroup);

   local repositionSet = function()
      -- view.setDesignGroup.xScale = setScale;
      -- view.setDesignGroup.yScale = setScale;
      -- view.setDesignGroup.x = (display.contentWidth - (display.contentWidth * setScale)) * 0.5;
      -- view.setDesignGroup.y = (display.contentHeight - (display.contentHeight * setScale)) * 0.5;
      FRC_Layout.scaleToFit(setDesignGroup);
      -- view.setDesignGroup.y = view.setDesignGroup.y - 80;
   end

   local changeSet = function(index)

      -- EDF TODO: Handle index value of 0 and remove the backdrop and background
      -- THIS will be when I introduce the NONE option
      -- We may also want to support random value (-1) for the MysteryBox
      if (index == FRC_Rehearsal_Scene.setIndex) then return; end
      index = index or FRC_Rehearsal_Scene.setIndex;
      FRC_Rehearsal_Scene.setIndex = index;

      -- clear previous contents
      if (setGroup.numChildren > 0) then
         setGroup[1]:removeSelf();
         setGroup[1] = nil;
      end
      -- if we are clearing the set, we're done
      print("set index",index); -- DEBUG
      if (index == 0) then return; end

      local setBackground = display.newImageRect(setGroup, SETDESIGNUI('IMAGES_PATH') .. setData[index].imageFile, setData[index].width, setData[index].height);
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

   local changeBackdrop = function(index)
      if (index == FRC_Rehearsal_Scene.backdropIndex) then return; end
      -- ArtCenter image set as backdrop, but image was deleted (reset index to 1)
      if (not backdropData[index]) then index = 0; end
      index = index or FRC_Rehearsal_Scene.backdropIndex;
      FRC_Rehearsal_Scene.backdropIndex = index;
      -- clear previous contents
      if (backdropGroup.numChildren > 0) then
         backdropGroup[1]:removeSelf();
         backdropGroup[1] = nil;
      end
      -- if we are clearing the set, we're done
      print("backdrop index",index); -- DEBUG
      if (index == 0) then return; end

      local frameRect = setGroup[1].frameRect;
      local imageFile = SETDESIGNUI('IMAGES_PATH') .. backdropData[index].imageFile;
      local baseDir = system.ResourceDirectory;
      if (backdropData[index].baseDir) then
         imageFile = backdropData[index].imageFile;
         baseDir = system[backdropData[index].baseDir];
      end
      local backdropBackground = display.newImageRect(backdropGroup, imageFile, baseDir, backdropData[index].width, backdropData[index].height);
      backdropBackground.anchorX = 0;
      backdropBackground.anchorY = 0;
      backdropBackground.xScale = (frameRect.width / backdropData[index].width);
      backdropBackground.yScale = (frameRect.height / backdropData[index].height);
      backdropBackground.x = frameRect.left - ((setGroup[1].width - display.contentWidth) * 0.5);
      backdropBackground.y = frameRect.top - ((setGroup[1].height - display.contentHeight) * 0.5);
   end
   self.changeBackdrop = changeBackdrop;
   -- changeBackdrop();
   -- repositionSet();


   -- Get lua tables from JSON data
   local categoryData = DATA('CATEGORY')
   local rehearsalPlaybackData = DATA('REHEARSAL')
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

  FRC_Rehearsal_Scene.rewindPreview = function ()
    print("rewindPreview");
    songGroup = FRC_AudioManager:findGroup("songPlayback");
    if (songGroup) then
      if (#songGroup.handles) then
        for i=1,#songGroup.handles do
      		audio.rewind(songGroup.handles[i]);
      	end
      end
      -- for i, instr in pairs(instrumentList) do
      --   local h = songGroup:findHandle(currentSongID .. "_" .. string.lower(instr) )
      --   -- stop the track
      --   if (h) then
      --     print('rewinding ', h.name);
      --     audio.rewind(h.handle);
      --   end
      -- end
    end
  end

  FRC_Rehearsal_Scene.stopRehearsalMode = function ()
    print("StopRehearsal");
    -- eventually we will transition animate on offscreen and the other onscreen
    categoriesContainer.isVisible = true;
    if itemScrollers then
      for k,v in pairs( itemScrollers ) do
        if v then
          v.isVisible = false;
        end
      end
    end
    rehearsalContainer.isVisible = false;
    -- TODO turn back on the appropriate scroller's visibility (last one that was active)

    -- STOP ALL AUDIO PLAYBACK OF SONG
    local instrumentList = FRC_CharacterBuilder.getInstrumentsInUse();
    tracksGroup = FRC_AudioManager:findGroup("songTracks");
    songGroup = FRC_AudioManager:findGroup("songPlayback");
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
          tracksGroup:addHandle(h);
        end
      end
    end
  end

  FRC_Rehearsal_Scene.startRehearsalMode = function ()
    print("StartRehearsal");
    categoriesContainer.isVisible = false;
    if itemScrollers then
      for k,v in pairs( itemScrollers ) do
        if v then
          v.isVisible = false;
        end
      end
    end
    rehearsalContainer.isVisible = true;
    -- get a handle to the song group
    -- songGroup = FRC_AudioManager:newGroup({
    --   name = "songGroup",
    --   maxChannels = 8
    -- });
    -- get a list of the instruments that are active
    local instrumentList = FRC_CharacterBuilder.getInstrumentsInUse();
    table.dump(instrumentList);
    -- find the song for each instrument
    tracksGroup = FRC_AudioManager:findGroup("songTracks");
    songGroup = FRC_AudioManager:findGroup("songPlayback");
    print(tracksGroup); -- DEBUG
    if (songGroup and tracksGroup and instrumentList) then
      for i, instr in pairs(instrumentList) do
        print(i, instr);
        local h = tracksGroup:findHandle(currentSongID .. "_" .. string.lower(instr) )
        -- add the song to a playback group if it is legitimate for this song
        if (h) then
          print('playing ', h.name);
          songGroup:addHandle(h);
          -- h:play();
          -- h:play({ onComplete = function()
          --   FRC_Rehearsal_Scene.stopRehearsalMode();
          -- end });
        end
      end
      songGroup:playAll();
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
      --[[
      changeItem('Character', selectedCharacter, 0)
      for i=1,#categoryData do
         changeItem(categoryData[i].id, selectedCharacter, 1)
      end
      --]]
   end

   -- create sceneLayout items
   local sceneLayoutMethods = {}
   local sceneLayout = {}
   local sceneLayoutAnimationSequences

   for i=1,#sceneLayoutData do
      if sceneLayoutData[i].imageFile then
         sceneLayout[i] = display.newImageRect(view, UI('IMAGES_PATH') .. sceneLayoutData[i].imageFile, sceneLayoutData[i].width, sceneLayoutData[i].height)
         FRC_Layout.scaleToFit(sceneLayout[i])

         if (sceneLayoutData[i].left) then
            sceneLayoutData[i].left = (sceneLayoutData[i].left * bg.xScale)
            sceneLayout[i].x = sceneLayoutData[i].left - ((screenW - display.contentWidth) * 0.5) + (sceneLayout[i].contentWidth * 0.5)

         elseif (sceneLayoutData[i].right) then
            sceneLayoutData[i].right = (sceneLayoutData[i].right * bg.xScale)
            sceneLayout[i].x = display.contentWidth - sceneLayoutData[i].right + ((screenW - display.contentWidth) * 0.5) - (sceneLayout[i].contentWidth * 0.5)
         else
            sceneLayoutData[i].x = sceneLayoutData[i].x * bg.xScale
            sceneLayout[i].x = sceneLayoutData[i].x - ((screenW - display.contentWidth) * 0.5)
         end
         if (sceneLayoutData[i].top) then
            sceneLayout[i].y = sceneLayoutData[i].top - ((screenH - display.contentHeight) * 0.5) + (sceneLayout[i].contentHeight * 0.5)
         elseif (sceneLayoutData[i].bottom) then
            sceneLayout[i].y = display.contentHeight - sceneLayoutData[i].bottom + ((screenH - display.contentHeight) * 0.5) - (sceneLayout[i].contentHeight * 0.5)
         else
            sceneLayoutData[i].y = sceneLayoutData[i].y * bg.yScale
            sceneLayout[i].y = sceneLayoutData[i].y - ((screenH - display.contentHeight) * 0.5)
         end

         sceneLayout[i].y = sceneLayout[i].y + bg.contentBounds.yMin


      elseif sceneLayoutData[i].animationFiles then
         -- get the list of animation files and create the animation object
         -- preload the animation data (XML and images) early
         sceneLayout[i] = FRC_AnimationManager.createAnimationClipGroup(sceneLayoutData[i].animationFiles, animationXMLBase, animationImageBase)
         FRC_Layout.scaleToFit(sceneLayout[i])

         if (sceneLayoutData[i].left) then
            sceneLayoutData[i].left = (sceneLayoutData[i].left * bg.xScale)
            sceneLayout[i].x = sceneLayoutData[i].left - ((screenW - display.contentWidth) * 0.5) + (sceneLayout[i].contentWidth * 0.5)

         elseif (sceneLayoutData[i].right) then
            sceneLayoutData[i].right = (sceneLayoutData[i].right * bg.xScale)
            sceneLayout[i].x = display.contentWidth - sceneLayoutData[i].right + ((screenW - display.contentWidth) * 0.5) - (sceneLayout[i].contentWidth * 0.5)
         elseif (sceneLayoutData[i].x) then
            sceneLayoutData[i].x = sceneLayoutData[i].x * bg.xScale
            sceneLayout[i].x = sceneLayoutData[i].x - ((screenW - display.contentWidth) * 0.5)
         else
            local xOffset = (screenW - (display.contentWidth * bg.xScale)) * 0.5
            sceneLayout[i].x = ((bg.contentWidth - screenW) * 0.5) + bg.contentBounds.xMin + xOffset
         end

         if (sceneLayoutData[i].top) then
            sceneLayout[i].y = sceneLayoutData[i].top - ((screenH - display.contentHeight) * 0.5) + (sceneLayout[i].contentHeight * 0.5)
         elseif (sceneLayoutData[i].bottom) then
            sceneLayout[i].y = display.contentHeight - sceneLayoutData[i].bottom + ((screenH - display.contentHeight) * 0.5) - (sceneLayout[i].contentHeight * 0.5)
         elseif (sceneLayoutData[i].y) then
            sceneLayoutData[i].y = sceneLayoutData[i].y * bg.yScale
            sceneLayout[i].y = sceneLayoutData[i].y - ((screenH - display.contentHeight) * 0.5)
         end

         sceneLayout[i].y = sceneLayout[i].y + bg.contentBounds.yMin

         view:insert(sceneLayout[i])
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
   rehearsalContainerBg:setFillColor(0, 0, 0, 0.5); -- 1.0, 1.0, 1.0, 0.35)
   rehearsalContainerBg.x, rehearsalContainerBg.y = 0, 0
   rehearsalContainer.x = display.contentCenterX
   rehearsalContainer.y = display.contentHeight - (categoriesHeight * 0.5) + (category_button_spacing * 1.65)

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
               if (self.id == "StopRehearsal") then
                 FRC_Rehearsal_Scene.stopRehearsalMode();
               elseif (self.id == "RewindPreview") then
                 FRC_Rehearsal_Scene.rewindPreview();
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
   categoriesBg:setFillColor(0, 0, 0, 0.75); -- 1.0, 1.0, 1.0, 0.35)
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
            bgColor = {0.27, 0.27, 0.27, 0.35} -- { 1.0, 1.0, 1.0, 1.0 }
         })
      scroller.bg.alpha = 0.65
      view:insert(scroller)
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
				 setIndex = item.setIndex,
				 backdropIndex = item.backdropIndex,
				 baseDir = "DocumentsDirectory"
			 });
			  -- DEBUG
			  -- print('id:', item.id, 'width:', item.thumbWidth, 'height:', item.thumbHeight);
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
     setIndex = 0,
     backdropIndex = 0
   });

   for i=1,#setDesignData do
		 -- DEBUG
		 print('width', setDesignData[i].width * button_scale);
		 dprint('id:', setDesignData[i].id, 'width:', setDesignData[i].width, 'height:', setDesignData[i].height);

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
  	                changeSet(0)
  							    changeBackdrop(0);
  								  -- repositionSet();
	                else
                    changeSet(setDesignData[i].setIndex)
  							    changeBackdrop(setDesignData[i].backdropIndex);
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
      --table.dump2(songInstruments[i]) --EFM
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
      --table.dump2(characterData[i]) --EFM
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
               table.dump2( costumesButton )



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

   view:insert(categoriesContainer)

   FRC_CharacterBuilder.init( { view                  = view,
                                animationXMLBase      = animationXMLBase,
                                animationImageBase    = animationImageBase,
                                itemScrollers         = itemScrollers,
                                categoriesContainer   = categoriesContainer } ) -- EFM

   FRC_CharacterBuilder.rebuildCostumeScroller( )

   if (FRC_Rehearsal_Scene.postCreateScene) then
      FRC_Rehearsal_Scene:postCreateScene(event)
   end

end


function FRC_Rehearsal_Scene:enterScene(event)
   local view = self.view

   if (FRC_Rehearsal_Scene.preEnterScene) then
      FRC_Rehearsal_Scene:preEnterScene(event)
   end

   native.setActivityIndicator(false)

   if (FRC_Rehearsal_Scene.postEnterScene) then
      FRC_Rehearsal_Scene:postEnterScene(event)
   end

end


function FRC_Rehearsal_Scene:exitScene(event)
   local view = self.view
   if (FRC_Rehearsal_Scene.preExitScene) then
      FRC_Rehearsal_Scene:preExitScene(event)
   end

   -- FRC_Rehearsal_Scene.stopRehearsalMode(); - in case audio was playing just before the user is leaving the scene

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
