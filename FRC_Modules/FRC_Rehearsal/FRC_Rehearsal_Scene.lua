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

-- ====================================================================
-- Locals
-- ====================================================================
local character_x = 0
local character_y = -16
local eyeTimer

-- ====================================================================
-- EFM - TBD BEGIN
-- ====================================================================
local function UI(key)
   return FRC_Rehearsal_Settings.UI[key]
end

local function DATA(key, baseDir)
   baseDir = baseDir or system.ResourceDirectory
   return FRC_DataLib.readJSON(FRC_Rehearsal_Settings.DATA[key], baseDir)
end
local animationXMLBase = UI('ANIMATION_XML_BASE')
local animationImageBase = UI('ANIMATION_IMAGE_BASE')


function FRC_Rehearsal_Scene:save(e)
   local id = e.id
   if ((not id) or (id == '')) then id = (FRC_Util.generateUniqueIdentifier(20)) end
   local saveGroup = self.view.saveGroup

   -- create mask (to be used for Stamp in ArtCenter)
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
      character = self.view.currentData.character,
      categories = self.view.currentData.categories,
      index = self.view.currentData.index,
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
   FRC_DataLib.saveJSON(saveDataFilename, self.saveData)
   self.id = id
end

function FRC_Rehearsal_Scene:load(e)
   local id = e.id
   if ((not id) or (id == '')) then id = (FRC_Util.generateUniqueIdentifier(20)) end
   self.changeItem('Character', e.data.character, v)
   for k,v in pairs(e.data.categories) do
      self.changeItem(k, e.data.character, v)
   end
   self.id = id
end
-- ====================================================================
-- EFM - TBD END
-- ====================================================================


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
   
   ----[[
   -- FRC_Rehearsal.getSavedData()
   self.saveData = DATA('DATA_FILENAME', system.DocumentsDirectory)
   require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal').saveData = FRC_DataLib.readJSON(saveDataFilename, system.DocumentsDirectory)
   --]]

   local bg = display.newImageRect(view, UI('SCENE_BACKGROUND_IMAGE'), UI('SCENE_BACKGROUND_WIDTH'), UI('SCENE_BACKGROUND_HEIGHT'))
   FRC_Layout.scaleToFit(bg)
   bg.x, bg.y = display.contentCenterX, display.contentCenterY

   
   --[[
   -- setup a container that will hold character and all layers of clothing
   --local chartainer = display.newContainer(display.contentWidth, display.contentHeight)
   local chartainer = display.newGroup()
   chartainer.anchorChildren = true
   view:insert(chartainer)
   chartainer.x, chartainer.y = display.contentCenterX + 10, display.contentCenterY - 10
   chartainer:scale(0.80, 0.80)
   chartainer:scale(bg.xScale, bg.yScale)
   view.saveGroup = chartainer

   -- Get lua tables from JSON data
   local characterData = DATA('CHARACTER')
   local categoryData = DATA('CATEGORY')
   local sceneLayoutData = DATA('SCENELAYOUT')

   -- Insert 'None' as first item of all character costume categories
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

   -- create a new layer for each category, manually creating the first (character)
   -- at the bottom of the layer stack
   layers['Character'] = display.newGroup()
   chartainer:insert(layers['Character'])
   for i=#categoryData,2,-1 do
      layers[categoryData[i].id] = display.newGroup()
      chartainer:insert(layers[categoryData[i].id])
   end

   local getDataForCharacter = function(character)
      local charData
      for i=1,#characterData do
         if (characterData[i].id == character) then
            charData = characterData[i]
            break
         end
      end
      if (not charData) then
         error('No character data for "' .. character .. '"')
      end
      return charData
   end

   local function beginEyeAnimation(open, shut)
      if (eyeTimer) then pcall(timer.cancel, eyeTimer) end
      open.isVisible = true
      shut.isVisible = false
      eyeTimer = timer.performWithDelay(math.random(1000,3000), function()
            open.isVisible = false
            shut.isVisible = true
            eyeTimer = timer.performWithDelay(100, function()
                  open.isVisible = true
                  shut.isVisible = false
                  eyeTimer = timer.performWithDelay(200, function()
                        open.isVisible = false
                        shut.isVisible = true
                        eyeTimer = timer.performWithDelay(75, function()
                              open.isVisible = true
                              shut.isVisible = false
                              eyeTimer = timer.performWithDelay(math.random(1000,3000), function()
                                    eyeTimer = nil
                                    beginEyeAnimation(open, shut)
                                 end, 1)
                           end, 1)
                     end, 1)
               end, 1)
         end, 1)
   end

   local function clearLayer(categoryId)
      -- clear specified layer
      for k,v in pairs(layers) do
         if (categoryId == k) then
            for i=layers[k].numChildren,1,-1 do
               layers[k][i]:removeSelf()
               layers[k][i] = nil
            end
            break
         end
      end
   end

   -- handles swapping out of characters and specific clothing items
   local function changeItem(categoryId, character, index)
      clearLayer(categoryId)

      local charData = getDataForCharacter(character)

      if (categoryId == 'Character') then
         selectedCharacter = character
         local charBody = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.bodyImage, charData.bodyWidth, charData.bodyHeight)
         charBody.x, charBody.y = character_x, character_y

         -- DEBUG:
         print(charData.eyesOpenImage)
         print(UI('IMAGES_PATH') .. charData.eyesOpenImage)
         print(charData.eyesShutImage)
         print(UI('IMAGES_PATH') .. charData.eyesShutImage)
         if (charData.eyesOpenImage and charData.eyesShutImage) then
            local charEyesOpen = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.eyesOpenImage, charData.eyesOpenWidth, charData.eyesOpenHeight)
            charEyesOpen.x, charEyesOpen.y = charBody.x + charData.eyesX, charBody.y + charData.eyesY
            charEyesOpen.isVisible = true
            print(charEyesOpen.x, charEyesOpen.y) -- DEBUG

            local charEyesShut = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.eyesShutImage, charData.eyesShutWidth, charData.eyesShutHeight)
            charEyesShut.x, charEyesShut.y = charBody.x + charData.eyesX, charBody.y + charData.eyesY
            charEyesShut.isVisible = false
            print(charEyesShut.x, charEyesShut.y) -- DEBUG

            beginEyeAnimation(charEyesOpen, charEyesShut)
         end

         if (index ~= 0) then
            for i=2,#categoryData do
               changeItem(categoryData[i].id, selectedCharacter, layers[categoryData[i].id].selectedIndex or 1)
            end
         end
      else
         local clothingData = charData.clothing[categoryId][index]
         if (not clothingData) then return end
         if (clothingData.id ~= 'none') then
            local item = display.newImageRect(layers[categoryId], UI('IMAGES_PATH') .. clothingData.imageFile, clothingData.width, clothingData.height)
            -- ERRORCHECK
            if not item then
               assert(refImage, "ERROR: Missing costume media file: ", UI('IMAGES_PATH') .. clothingData.imageFile)
            end
            item.x, item.y = character_x + clothingData.xOffset, character_y + clothingData.yOffset
            -- check to see if we need to use the special altBodyImage
            if (categoryId == 'Headwear') then
               if (clothingData.altBodyImage) then
                  -- DEBUG:
                  -- print("Swapping in altBodyImage: ", UI('IMAGES_PATH') .. charData.altBodyImage)
                  clearLayer('Character')
                  charBody = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.altBodyImage, charData.bodyWidth, charData.bodyHeight)
                  charBody.x, charBody.y = character_x, character_y
               else
                  -- sloppy but we have to switch back to the baseimage
                  -- DEBUG:
                  -- print("Swapping in bodyImage: ", UI('IMAGES_PATH') .. charData.bodyImage)
                  clearLayer('Character')
                  charBody = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.bodyImage, charData.bodyWidth, charData.bodyHeight)
                  charBody.x, charBody.y = character_x, character_y
               end
            end
         else
            if (categoryId == 'Headwear') then
               -- we only reset the body if they chose the none option for Headwear
               clearLayer('Character')
               charBody = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.bodyImage, charData.bodyWidth, charData.bodyHeight)
               charBody.x, charBody.y = character_x, character_y
            end
         end
         layers[categoryId].selectedIndex = index
      end
      view.currentData = {
         character = character,
         categories = {}
      }
      for k,v in pairs(layers) do
         view.currentData.categories[k] = layers[k].selectedIndex
      end
   end
   self.changeItem = changeItem

   self.startOver = function()
      changeItem('Character', selectedCharacter, 0)
      for i=1,#categoryData do
         changeItem(categoryData[i].id, selectedCharacter, 1)
      end
   end
   
   -- create sceneLayout items
   local sceneLayoutMethods = {}
   local sceneLayout = {}
   -- setup the randomly fired mysteryBoxAnimations
   local mysteryBoxAnimationFiles = {}
   local mysteryBoxAnimationSequences = {}

   -- ambient loop sequence
   function sceneLayoutMethods.playMysteryBoxAnimationSequence()
      -- pick a random animation sequence
      local sequence = mysteryBoxAnimationSequences[math.random(1,4)]
      for i=1, sequence.numChildren do
         sequence[i]:play({
               showLastFrame = false,
               playBackward = false,
               autoLoop = false,
               palindromicLoop = false,
               delay = 0,
               intervalTime = 30,
               maxIterations = 1
            })
      end
      -- set a timer and after a delay, change the costume randomly
      timer.performWithDelay(1500,
         function ()
            for i=2,#categoryData do
               changeItem(categoryData[i].id, selectedCharacter, math.random(2, #getDataForCharacter(selectedCharacter).clothing[categoryData[i].id]))
            end
         end, 1)
   end

   function sceneLayoutMethods.randomCostume()
      -- play the mystery box animation
      sceneLayoutMethods.playMysteryBoxAnimationSequence()
   end

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

   mysteryBoxAnimationFiles[1] = {
      "SPMTM_Rehearsal_MysteryBox_v01_15.xml",
      "SPMTM_Rehearsal_MysteryBox_v01_14.xml",
      "SPMTM_Rehearsal_MysteryBox_v01_13.xml",
      "SPMTM_Rehearsal_MysteryBox_v01_12.xml",
      "SPMTM_Rehearsal_MysteryBox_v01_11.xml",
      "SPMTM_Rehearsal_MysteryBox_v01_10.xml",
      "SPMTM_Rehearsal_MysteryBox_v01_09.xml",
      "SPMTM_Rehearsal_MysteryBox_v01_08.xml",
      "SPMTM_Rehearsal_MysteryBox_v01_07.xml",
      "SPMTM_Rehearsal_MysteryBox_v01_06.xml",
      "SPMTM_Rehearsal_MysteryBox_v01_05.xml",
      "SPMTM_Rehearsal_MysteryBox_v01_04.xml",
      "SPMTM_Rehearsal_MysteryBox_v01_03.xml",
      "SPMTM_Rehearsal_MysteryBox_v01_02.xml",
      "SPMTM_Rehearsal_MysteryBox_v01_01.xml"
   }

   mysteryBoxAnimationFiles[2] = {
      "SPMTM_Rehearsal_MysteryBox_v02_15.xml",
      "SPMTM_Rehearsal_MysteryBox_v02_14.xml",
      "SPMTM_Rehearsal_MysteryBox_v02_13.xml",
      "SPMTM_Rehearsal_MysteryBox_v02_12.xml",
      "SPMTM_Rehearsal_MysteryBox_v02_11.xml",
      "SPMTM_Rehearsal_MysteryBox_v02_10.xml",
      "SPMTM_Rehearsal_MysteryBox_v02_09.xml",
      "SPMTM_Rehearsal_MysteryBox_v02_08.xml",
      "SPMTM_Rehearsal_MysteryBox_v02_07.xml",
      "SPMTM_Rehearsal_MysteryBox_v02_06.xml",
      "SPMTM_Rehearsal_MysteryBox_v02_05.xml",
      "SPMTM_Rehearsal_MysteryBox_v02_04.xml",
      "SPMTM_Rehearsal_MysteryBox_v02_03.xml",
      "SPMTM_Rehearsal_MysteryBox_v02_02.xml",
      "SPMTM_Rehearsal_MysteryBox_v02_01.xml"
   }

   mysteryBoxAnimationFiles[3] = {
      "SPMTM_Rehearsal_MysteryBox_v03_13.xml",
      "SPMTM_Rehearsal_MysteryBox_v03_12.xml",
      "SPMTM_Rehearsal_MysteryBox_v03_11.xml",
      "SPMTM_Rehearsal_MysteryBox_v03_10.xml",
      "SPMTM_Rehearsal_MysteryBox_v03_09.xml",
      "SPMTM_Rehearsal_MysteryBox_v03_08.xml",
      "SPMTM_Rehearsal_MysteryBox_v03_07.xml",
      "SPMTM_Rehearsal_MysteryBox_v03_06.xml",
      "SPMTM_Rehearsal_MysteryBox_v03_05.xml",
      "SPMTM_Rehearsal_MysteryBox_v03_04.xml",
      "SPMTM_Rehearsal_MysteryBox_v03_03.xml",
      "SPMTM_Rehearsal_MysteryBox_v03_02.xml",
      "SPMTM_Rehearsal_MysteryBox_v03_01.xml"
   }

   mysteryBoxAnimationFiles[4] = {
      "SPMTM_Rehearsal_MysteryBox_v05_15.xml",
      "SPMTM_Rehearsal_MysteryBox_v05_14.xml",
      "SPMTM_Rehearsal_MysteryBox_v05_13.xml",
      "SPMTM_Rehearsal_MysteryBox_v05_12.xml",
      "SPMTM_Rehearsal_MysteryBox_v05_11.xml",
      "SPMTM_Rehearsal_MysteryBox_v05_10.xml",
      "SPMTM_Rehearsal_MysteryBox_v05_09.xml",
      "SPMTM_Rehearsal_MysteryBox_v05_08.xml",
      "SPMTM_Rehearsal_MysteryBox_v05_07.xml",
      "SPMTM_Rehearsal_MysteryBox_v05_06.xml",
      "SPMTM_Rehearsal_MysteryBox_v05_05.xml",
      "SPMTM_Rehearsal_MysteryBox_v05_04.xml",
      "SPMTM_Rehearsal_MysteryBox_v05_03.xml",
      "SPMTM_Rehearsal_MysteryBox_v05_02.xml",
      "SPMTM_Rehearsal_MysteryBox_v05_01.xml"
   }

   for i=1,#mysteryBoxAnimationFiles do
      -- preload the animation data (XML and images) early

      mysteryBoxAnimationSequences[i] = FRC_AnimationManager.createAnimationClipGroup(mysteryBoxAnimationFiles[i], animationXMLBase, animationImageBase)
      FRC_Layout.scaleToFit(mysteryBoxAnimationSequences[i], -31, 42)
      local xOffset = (screenW - (display.contentWidth * bg.xScale)) * 0.5
      mysteryBoxAnimationSequences[i].x = mysteryBoxAnimationSequences[i].x + xOffset
      mysteryBoxAnimationSequences[i].y = mysteryBoxAnimationSequences[i].y + bg.contentBounds.yMin
      view:insert(mysteryBoxAnimationSequences[i])
   end

   -- by default, place naked first character onto the dressing room floor
   changeItem('Character', characterData[1].id, 0)
   view:insert(chartainer)

   local category_button_spacing = 48
   local button_spacing = 24
   local button_scale = 0.75
   local categoriesWidth = button_spacing
   local categoriesHeight = 0
   local itemScrollers = {}

   -- calculate panel dimensions for category buttons
   for i=1,#categoryData do
      categoriesWidth = categoriesWidth + (categoryData[i].width * button_scale) + category_button_spacing
      if ((categoryData[i].height * button_scale) > categoriesHeight) then
         categoriesHeight = categoryData[i].height * button_scale
      end
   end
   categoriesHeight = categoriesHeight + (category_button_spacing * 1.25) -- (category_button_spacing * 2)

   -- create button panel for categories (aligned to the bottom of the screen)
   local categoriesContainer = display.newContainer(categoriesWidth, categoriesHeight)
   local categoriesBg = display.newRoundedRect(categoriesContainer, 0, 0, categoriesWidth, categoriesHeight, 11)
   categoriesBg:setFillColor(1.0, 1.0, 1.0, 0.35)
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
               local self = e.target
               self:setFocusState(true)
               itemScrollers[self.id].isVisible = true
               for i=2,categoriesContainer.numChildren do
                  if (categoriesContainer[i] ~= self) then
                     categoriesContainer[i]:setFocusState(false)
                     itemScrollers[categoriesContainer[i].id].isVisible = false
                  end
               end
            end
         })
      categoriesContainer:insert(button)
      button.x = (-(categoriesWidth * 0.5) + (button.contentWidth * 0.5) + category_button_spacing) + (i - 1) * (button.contentWidth + category_button_spacing)
      button.y = -category_button_spacing * 0.75

      -- create corresponding item scroll containers
      local scroller = ui.scrollcontainer.new({
            width = screenW,
            height = (categoriesHeight * button_scale) - 5,
            xScroll = true,
            yScroll = false,
            leftPadding = button_spacing,
            rightPadding = button_spacing,
            bgColor = { 1.0, 1.0, 1.0, 1.0 }
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

   -- create character scroll container
   local x = -(screenW * 0.5) + button_spacing
   local buttonHeight = 0
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
               changeItem('Character', self.id)
            end
         })
      button.categoryId = 'Character'
      scroller:insert(button)
      x = x + (button.contentWidth * 0.5)
      button.x, button.y = x, 0
      x = x + (button.contentWidth * 0.5) + (button_spacing * 1.5)
   end

   -- create the clothing scroll containers using the first character's images

   local thumbnailExtension = ""
   if (FRC_Rehearsal_Settings.CONFIG.costumes) then
      if (FRC_Rehearsal_Settings.CONFIG.costumes.customThumbnails) then
         thumbnailExtension = "_thumbnail"
      end
   end
   -- DEBUG:
   print("costume thumbnail extension: ", thumbnailExtension)

   for k,v in pairs(characterData[1].clothing) do
      local categoryId = k
      local scroller = itemScrollers[categoryId]
      local x = -(scroller.contentWidth * 0.5) + scroller.leftPadding
      for j=1,#v do
         -- DEBUG:
         -- this is to find issues with bad character data
         -- print("characterData[1].clothing:" .. v[j].id)
         -- width = buttonHeight * (v[j].width / v[j].height),
         -- need to constrain the image to fit a maximum width area
         local scaledWidth = buttonHeight * (v[j].width / v[j].height)
         local constrainedWidth = buttonHeight * 1.5
         local tempwidth = math.min(scaledWidth, constrainedWidth)
         local tempheight = buttonHeight -- default
         if (tempwidth == constrainedWidth) then
            -- we had to constrain the width artificially so we need to scale down the height to reflect that
            tempheight = buttonHeight * (constrainedWidth / scaledWidth)
         end
         -- if there's a custom thumbnail extension (instead of using the first character's costume images)
         -- we need to rewrite the imageFile path
         local imageFilePath = UI('IMAGES_PATH') .. v[j].imageFile
         -- DEBUG:
         -- print(imageFilePath)
         if ( thumbnailExtension ~= "" ) then
            imageFilePath = string.gsub(imageFilePath, ".png", thumbnailExtension .. ".png", 1)
            -- DEBUG:
            -- print(imageFilePath)
         end
         local button = ui.button.new({
               id = v[j].id,
               imageUp = imageFilePath,
               imageDown = imageFilePath,
               width = tempwidth,
               height = tempheight,
               parentScrollContainer = scroller,
               pressAlpha = 0.5,
               onRelease = function(e)
                  local self = e.target
                  changeItem(self.categoryId, selectedCharacter, self.index)
               end
            })
         button.categoryId = categoryId
         button.index = j
         button.xOffset = v[j].xOffset
         button.yOffset = v[j].yOffset
         scroller:insert(button)
         x = x + (button.contentWidth * 0.5)
         button.x, button.y = x, 0
         x = x + (button.contentWidth * 0.5) + (button_spacing * 1.5)
      end
   end

   view:insert(categoriesContainer)

   --]]
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

   --[[
   if (eyeTimer) then
      pcall(timer.cancel, eyeTimer)
      eyeTimer = nil
   end
   --]]

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
