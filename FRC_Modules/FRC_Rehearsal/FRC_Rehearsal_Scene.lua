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
   --[[
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
   --]]
end

function FRC_Rehearsal_Scene:load(e)
  --[[
   local id = e.id
   if ((not id) or (id == '')) then id = (FRC_Util.generateUniqueIdentifier(20)) end
   self.changeItem('Character', e.data.character, v)
   for k,v in pairs(e.data.categories) do
      self.changeItem(k, e.data.character, v)
   end
   self.id = id
   --]]
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

   -- Get lua tables from JSON data
   local categoryData = DATA('CATEGORY')
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
            bgColor = {0.27, 0.27, 0.27, 1.0} -- { 1.0, 1.0, 1.0, 1.0 }
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

   -- create SetDesign scroll container

   -- create Instruments scroll container

   -- create Character scroll container
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
               -- CODE TO HANDLE CHARACTER INSERTION/CHANGE GOES HERE
               -- changeItem('Character', self.id)
            end
         })
      button.categoryId = 'Character'
      scroller:insert(button)
      x = x + (button.contentWidth * 0.5)
      button.x, button.y = x, 0
      x = x + (button.contentWidth * 0.5) + (button_spacing * 1.5)
   end

   -- create the Costume scroll container

   -- create the clothing scroll containers using the first character's images

   --[[
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
   --]]

   view:insert(categoriesContainer)


   -- GUTS HERE *******************************************************************************
   -- GUTS HERE *******************************************************************************
   -- GUTS HERE *******************************************************************************
   local showToggles = false
   local autoRun = true
   local doit
   local testGroup = display.newGroup()
   view:insert( testGroup )
   
   local xmlFiles = {
      "MDMT_Animation_Chicken_Bass.xml",
      "MDMT_Animation_Chicken_Conga.xml",
      "MDMT_Animation_Chicken_Dance1.xml",
      "MDMT_Animation_Chicken_Dance2.xml",
      "MDMT_Animation_Chicken_Guitar.xml",
      "MDMT_Animation_Chicken_Harmonica.xml",
      "MDMT_Animation_Chicken_Maracas.xml",
      "MDMT_Animation_Chicken_Microphone.xml",
      "MDMT_Animation_Chicken_Piano.xml",
      "MDMT_Animation_Chicken_RhythmComboCheeseGrater.xml",
      "MDMT_Animation_Chicken_RhythmComboCymbal.xml",
      "MDMT_Animation_Chicken_Sticks.xml",
   }
   
   -- Create a menu to select and play the animations
   --
   local radioButtons = {}
   local startX = 120
   local startY = 120
   local curX = startX   
   local curY = startY
   local width = 220
   local height = 40
   for i = 1, #xmlFiles do
      local button = display.newRect( view, curX, curY, width - 10, height - 8 )
      button.strokeWidth = 2
      button:setFillColor(0.75, 0.75, 0.75)
      button:setStrokeColor(1,0,0)
      local text = xmlFiles[i]
      text = text:gsub( "MDMT_Animation_Chicken_", "" )
      text = text:gsub( ".xml", "" )
      button.label = display.newText( view, i .. " - " .. text, curX, curY, native.systemFont, 12 )
      button.label:setFillColor(0)
      radioButtons[i] = button
      button.touch = function(self,event)
         if(event.phase == "ended") then
            for j = 1, #radioButtons do
               radioButtons[j]:setFillColor(0.75, 0.75, 0.75)
               radioButtons[j]:setStrokeColor(1,0,0)
            end
            self:setFillColor(1)
            self:setStrokeColor(0,1,0)
            doit(i)
         end
      end
      button:addEventListener("touch")
      curY = curY + height
   end   
   
   
   local animationSequences = {}
   doit = function( seqNum )
      print(seqNum)
      for i = 1, #animationSequences do
         --animationSequences[i]:stop()
         local sequence = animationSequences[i]
         --print("BILLY ",  sequence.numChildren )
         for j = 1, sequence.numChildren do
            --sequence[j]:stop()
            sequence[j]:dispose()
         end
      end
      display.remove( testGroup )
      testGroup = display.newGroup()
      view:insert( testGroup )
      
   local FRC_Rehearsal_Tools = require("FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Tools")
   
      
      --local partsList = FRC_Rehearsal_Tools.getPartsList( "efm_unified.xml", animationXMLBase )
      
      local partsList = FRC_Rehearsal_Tools.getPartsList( xmlFiles[seqNum], animationXMLBase )
      
      --table.print_r( partsList )
      --table.dump2( partsList )
      for i = 1, #partsList do
         print(partsList[i].name, animationImageBase)
      end
      --Eyewear
      --Headwear
      --LowerTorso
      --Neckwear
      --UpperTorso
      --Body
      --Eyes
      --Instrument   
      
      -- Create a menu to select and play the animations
      --
      -- Parse animations from Unified file and select just animations we want
      local animationsToBuild = {}
      local dressingRoomImagBase = "FRC_Assets/FRC_DressingRoom/Images/"
      animationSequences = {}
      local allParts = {
         { "Body", animationImageBase },
         { "Torso", dressingRoomImagBase },
         { "Mouth", animationImageBase },
         { "Eyes", animationImageBase },
         { "Eyewear", dressingRoomImagBase },
         { "Headwear", dressingRoomImagBase },
         --{ "LowerTorso", dressingRoomImagBase },
         { "Neckwear", dressingRoomImagBase },
         --{ "UpperTorso", dressingRoomImagBase },
         { "Instrument", animationImageBase },
         { "LeftArm", animationImageBase },
         { "RightArm", animationImageBase }
      }
      for i = 1, #allParts do
         local partName = allParts[i][1]
         for j = 1, #partsList do
            print(j, partName )
            if( string.match( partsList[j].name, partName ) ~= nil ) then 
               FRC_Rehearsal_Tools.findAnimationParts( partsList, partName, animationsToBuild, allParts[i][2] )
            end
         end
      end
      
      table.print_r(animationsToBuild)
      
      -- Create animation groups (sequences) from our list of animations to build
      local animGroup = display.newGroup()
      local xOffset = (screenW - (display.contentWidth * bg.xScale)) * 0.5
      testGroup:insert(animGroup)
      for i = 1, #animationsToBuild do
         local animationGroupProperties = {}
         table.dump2(animationsToBuild[i])
         animationSequences[i] = FRC_Rehearsal_Tools.createUnifiedAnimationClipGroup( xmlFiles[seqNum], 
                                                                                      animationsToBuild[i], 
                                                                                      animationXMLBase, 
                                                                                      animationsToBuild[i][3], -- animationImageBase, 
                                                                                      animationGroupProperties )                              
         FRC_Layout.scaleToFit(animationSequences[i], 0, 0)
         
         animationSequences[i].x = animationSequences[i].x --+ xOffset
         animationSequences[i].y = animationSequences[i].y --+ bg.contentBounds.yMin
         animGroup:insert(animationSequences[i])
      end
      -- Yes, I'm placing these manually for now
      animGroup.x = 240
      animGroup.y = 200
      animGroup:scale(0.55,0.55)

      ----[[

      -- Create a menu to select and play the animations
      --
      local toggleButtons = {}
      local button = display.newRect( animGroup, 500, 400, 300, 600 ) 
      button.isHitTestable = true
      button:setFillColor(0.5, 1, 0.5 )
      button.alpha = 0
      button.touch = function( self, event )         
         if( event.phase == "ended" ) then 
            for i = 1, #toggleButtons do
               print( i, toggleButtons[i] ) 
               if( toggleButtons[i].toggled ) then
                  FRC_Rehearsal_Tools.playUnifiedAnimations( animationSequences, i )
               end
            end
         end
      end
      button:addEventListener("touch")
      if( autoRun ) then
         timer.performWithDelay( 100, 
            function()
               for i = 1, #animationSequences do
                  FRC_Rehearsal_Tools.playUnifiedAnimations( animationSequences, i )  
               end
            end )
      end

      local startX = 120
      local startY = display.contentHeight - 80
      local curX = startX   
      local curY = startY
      local width = 220
      local height = 30
      for i = 1, #animationsToBuild do
         local button = display.newRect( testGroup, curX, curY, width - 10, height )
         button.strokeWidth = 4
         button:setStrokeColor(0,1,0)         
         button.toggled = true
         button.label = display.newText( testGroup, i .. " " .. animationsToBuild[i][1], curX, curY, native.systemFont, 14 )
         button.label:setFillColor(0)
         button.isVisible = showToggles
         button.label.isVisible = showToggles
         toggleButtons[i] = button
         button.touch = function(self,event)
            if(event.phase == "ended") then
               self.toggled = not self.toggled
               if( self.toggled ) then
                  self:setStrokeColor(0,1,0)
               else
                  self:setStrokeColor(1,0,0)
               end
            end
         end
         button:addEventListener("touch")
         curX = curX + width
         if( curX > display.contentWidth - width ) then
            curX = startX
            curY = startY + 40 
         end
      end      
      --]]
      
   end
   radioButtons[1].touch( radioButtons[1], { phase = "ended" } )
   
   -- GUTS END HERE >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
   -- GUTS END HERE >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
   -- GUTS END HERE >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


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
