local FRC_AnimationManager    = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager')
local FRC_Rehearsal_Tools = require("FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Tools")


local mRand = math.random

local currentInstrument
local currentInstrumentType = "none"

local currentCharacterType = "Chicken"
local view, screenW, screenH, FRC_Layout, bg, animationXMLBase, animationImageBase, itemsScroller, categoriesContainer

local public = {}
local private = {}

function public.init( _view, _screenW, _screenH, _FRC_Layout, _bg, _animationXMLBase, _animationImageBase, _itemScrollers, _categoriesContainer )    
   view                 = _view
   screenW              = _screenW
   screenH              = _screenH
   FRC_Layout           = _FRC_Layout
   bg                   = _bg
   animationXMLBase     = _animationXMLBase
   animationImageBase   = _animationImageBase
   itemScrollers        = _itemScrollers
   categoriesContainer  = _categoriesContainer
   
end

function public.create_orig( _view, _screenW, _screenH, _FRC_Layout, _bg, _animationXMLBase, _animationImageBase, _itemScrollers, _categoriesContainer )    
   view                 = _view
   screenW              = _screenW
   screenH              = _screenH
   FRC_Layout           = _FRC_Layout
   bg                   = _bg
   animationXMLBase     = _animationXMLBase
   animationImageBase   = _animationImageBase
   itemScrollers        = _itemScrollers
   categoriesContainer  = _categoriesContainer
   
   local testGroup      = display.newGroup()
   view:insert( testGroup )

   local idToFileMap = {}
   idToFileMap.Microphone = 8
   idToFileMap.Bass = 1
   idToFileMap.Conga = 2
   idToFileMap.Guitar = 5
   idToFileMap.Piano = 9
   idToFileMap.Harmonica = 6
   idToFileMap.Maracas = 7
   idToFileMap.Sticks = 12
   idToFileMap.RhythmComboCheeseGrater = 10
   idToFileMap.RhythmComboCymbal = 11

   local xmlFiles = {
      "MDMT_Animation_Chicken_Bass.xml", -- 1
      "MDMT_Animation_Chicken_Conga.xml", -- 2
      "MDMT_Animation_Chicken_Dance1.xml", -- 3
      "MDMT_Animation_Chicken_Dance2.xml", -- 4
      "MDMT_Animation_Chicken_Guitar.xml", -- 5
      "MDMT_Animation_Chicken_Harmonica.xml", -- 6
      "MDMT_Animation_Chicken_Maracas.xml", -- 7
      "MDMT_Animation_Chicken_Microphone.xml", -- 8
      "MDMT_Animation_Chicken_Piano.xml", -- 9
      "MDMT_Animation_Chicken_RhythmComboCheeseGrater.xml", -- 10
      "MDMT_Animation_Chicken_RhythmComboCymbal.xml", -- 11
      "MDMT_Animation_Chicken_Sticks.xml", -- 12
   }


   local animationSequences = {}
   public.showIntrumentSample = function( xmlNum )
      if( type(xmlNum) == "string") then
         dprint("Before ", xmlNum)
         xmlNum = idToFileMap[xmlNum]
      end
      dprint(xmlNum)
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

      --local partsList = FRC_Rehearsal_Tools.getPartsList( "efm_unified.xml", animationXMLBase )

      local partsList = FRC_Rehearsal_Tools.getPartsList( xmlFiles[xmlNum], animationXMLBase )

      --table.print_r( partsList )
      --table.dump2( partsList )
      for i = 1, #partsList do
         dprint(partsList[i].name, animationImageBase)
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
      local allParts

      if( xmlNum == 5 ) then -- Guitar
         allParts = {
            { "Body", "", animationImageBase },
            { "Torso_Guitar", "", animationImageBase },
            { "Neckwear", "", dressingRoomImagBase },
            { "LowerTorso", "", dressingRoomImagBase },
            { "UpperTorso", "", dressingRoomImagBase },
            { "Mouth", "", animationImageBase },
            { "Eyes", "", animationImageBase },
            { "Eyewear", "", dressingRoomImagBase },
            { "Headwear", "", dressingRoomImagBase },
            { "Instrument", "", animationImageBase },
            { "LeftArm", "", animationImageBase },
            { "RightArm", "", animationImageBase },
         }
      elseif( xmlNum == 7 ) then -- Maracas
         allParts = {
            { "Body", "", animationImageBase },
            { "Neckwear", "", dressingRoomImagBase },
            { "LowerTorso", "", dressingRoomImagBase },
            { "UpperTorso", "", dressingRoomImagBase },
            { "Mouth", "", animationImageBase },
            { "Eyes", "", animationImageBase },
            { "Eyewear", "", dressingRoomImagBase },
            { "Headwear", "", dressingRoomImagBase },
            { "Instrument_Maracas_Left", "", animationImageBase },
            { "Instrument_Maracas_Right", "", animationImageBase },
            { "LeftArm", "", animationImageBase },
            { "RightArm", "", animationImageBase },
         }
      elseif( xmlNum == 10 ) then -- Cheese Grater
         allParts = {
            { "Body", "", animationImageBase },
            { "Neckwear", "", dressingRoomImagBase },
            { "LowerTorso", "", dressingRoomImagBase },
            { "UpperTorso", "", dressingRoomImagBase },
            { "Mouth", "", animationImageBase },
            { "Eyes", "", animationImageBase },
            { "Eyewear", "", dressingRoomImagBase },
            { "Headwear", "", dressingRoomImagBase },
            { "Instrument_RhythmComboCheeseGrater", "Instrument_RhythmComboCheeseGrater_Fork", animationImageBase },
            { "RightArm", "", animationImageBase },
            { "Instrument_RhythmComboCheeseGrater_Fork", "", animationImageBase },
            { "LeftArm", "", animationImageBase },
         }
      elseif( xmlNum == 11 ) then -- Combo Cymbal
         dprint("xmlNum 11")
         allParts = {
            { "Body", "", animationImageBase },
            { "Neckwear", "", dressingRoomImagBase },
            { "LowerTorso", "", dressingRoomImagBase },
            { "UpperTorso", "", dressingRoomImagBase },
            { "Mouth", "", animationImageBase },
            { "Eyes", "", animationImageBase },
            { "Eyewear", "", dressingRoomImagBase },
            { "Headwear", "", dressingRoomImagBase },
            { "Instrument_RhythmComboCymbal", "Instrument_RhythmComboCymbal_Stick", animationImageBase },
            { "Instrument_RhythmComboCymbal_Stick", "", animationImageBase },
            { "LeftArm", "", animationImageBase },
            { "RightArm", "", animationImageBase },

         }
      elseif( xmlNum == 12 ) then -- Sticks
         allParts = {
            { "Body", "", animationImageBase },
            { "Neckwear", "", dressingRoomImagBase },
            { "LowerTorso", "", dressingRoomImagBase },
            { "UpperTorso", "", dressingRoomImagBase },
            { "Mouth", "", animationImageBase },
            { "Eyes", "", animationImageBase },
            { "Eyewear", "", dressingRoomImagBase },
            { "Headwear", "", dressingRoomImagBase },
            { "Instrument_Sticks_Left", "", animationImageBase },
            { "Instrument_Sticks_Right", "", animationImageBase },
            { "LeftArm", "", animationImageBase },
            { "RightArm", "", animationImageBase },
         }

      else
         allParts = {
            { "Body", "", animationImageBase },
            { "Neckwear", "", dressingRoomImagBase },
            { "LowerTorso", "", dressingRoomImagBase },
            { "UpperTorso", "", dressingRoomImagBase },
            { "Mouth", "", animationImageBase },
            { "Eyes", "", animationImageBase },
            { "Eyewear", "", dressingRoomImagBase },
            { "Headwear", "", dressingRoomImagBase },
            { "Instrument", "", animationImageBase },
            { "LeftArm", "", animationImageBase },
            { "RightArm", "", animationImageBase },
         }
      end

      for i = 1, #allParts do
         local partName = allParts[i][1]
         local partExcludeName = allParts[i][2]
         for j = 1, #partsList do
            --dprint(j, partName )
            if( string.match( partsList[j].name, partName ) ~= nil ) then
               dprint(j, partName )
               FRC_Rehearsal_Tools.findAnimationParts( partsList, partName, partExcludeName, animationsToBuild, allParts[i][3] )
            end
         end
      end

      --table.print_r(animationsToBuild)

      -- Create animation groups (sequences) from our list of animations to build
      local animGroup = display.newGroup()
      local xOffset = (screenW - (display.contentWidth * bg.xScale)) * 0.5
      testGroup:insert(animGroup)
      for i = 1, #animationsToBuild do
         local animationGroupProperties = {}
         --table.dump2(animationsToBuild[i])
         animationSequences[i] = FRC_Rehearsal_Tools.createUnifiedAnimationClipGroup( xmlFiles[xmlNum],
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

      -- Create a menu to select and play the animations
      --
      timer.performWithDelay( 0,
         function()
            for i = 1, #animationSequences do
               FRC_Rehearsal_Tools.playUnifiedAnimations( animationSequences, i )
            end
         end )

   end
      
end



-- 
-- rebuildCostumeScroller() - Builds the costume scroller based on the currently selected character type
--
function public.rebuildCostumeScroller( )
   local ui = require('ui')
   
   local scroller = itemScrollers.Costume
   
   -- Destroy OLD scroller CONTENT ONLY
   while( scroller.content.numChildren > 0 ) do
      display.remove( scroller.content[1] )
   end
   
   -- Get current characters
   local characters = public.getCharacters( currentCharacterType, 2 ) --EFM
   
   
   
   -- Insert costumes for current animal type into scroller 
   local button_spacing = 80
   local x = -(screenW * 0.5) + button_spacing   
   -- Add 'None' as firs button
   --local tmp = display.newCircle( x, 0, 20 )
   --tmp:setFillColor( mRand(), mRand(), mRand() )
   local tmp = display.newImage( "FRC_Assets/FRC_Rehearsal/Images/FRC_Rehearsal_Scroller_None.png"  )
   tmp.x = x
   tmp.data = "none"
   scroller:insert( tmp )
   tmp.touch = private.costumeTouch
   tmp:addEventListener( "touch" ) 
   
   for i = 1, #characters do      
      x = x + button_spacing
      local curChar = characters[i]
      --local tmp = display.newCircle( x, 0, 20 )
      local tmp = display.newImage( curChar.id .. curChar.thumbSuffix, system.DocumentsDirectory )
      tmp:scale(0.5,0.5)
      tmp.x = x 
      tmp.data = curChar
      tmp.touch = private.costumeTouch
      tmp:addEventListener( "touch" ) 
      scroller:insert( tmp )
   end
end

-- 
-- setCurrentCharacterType() - Builds the costume scroller based on the currently selected character type
--
function public.setCurrentCharacterType( characterType )
   currentCharacterType = characterType
end

-- 
-- placeNewCharacter() - 
--
function public.placeNewCharacter( data )
   public.showIntrumentSample(1)
end

-- 
-- placeNewInstrument() - 
--
function public.placeNewInstrument( instrumentName )
   display.remove( currentInstrument )
   dprint("Place instrument: ", instrumentName )
   
   currentInstrumentType = instrumentName
   
   currentInstrument = display.newImage( view, "FRC_Assets/FRC_Rehearsal/Images/MDMT_Rehearsal_Icon_Instrument_" .. instrumentName .. ".png"  )
   currentInstrument.x = display.contentCenterX
   currentInstrument.y = display.contentCenterY   
   private.attachDragger( currentInstrument )
   currentInstrument:scale(0.5,0.5)
end

-- 
-- getCharacters( characterType ) - Extract just 'characterType' characters from saved list of (dressing room) characters
--
function public.getCharacters( characterType, debugLevel )
   
   local characters = {}
   local dressingRoomDataPath = "FRC_DressingRoom_SaveData.json"
   local allSaved = table.load( dressingRoomDataPath ) or {}   
   if( not allSaved.savedItems ) then 
      if( debugLevel and debugLevel > 0 ) then
         dprint("No charactes/costumes of this type found: ", characterType )
      end
      return characters 
   end   
   local savedItems = allSaved.savedItems   
   --table.print_r( savedItems )
   for i = 1, #savedItems do
      local current = savedItems[i]
      --table.dump2( current )
      if( current.character == characterType ) then
         characters[#characters+1] = current
      end
   end  
   if( debugLevel and debugLevel > 0 ) then
      dprint("Found ", tostring(#characters), " of charactes/costumes of this type: ", characterType )
   end
   if( debugLevel and debugLevel > 1 ) then
      table.print_r(characters)
   end
   
   return characters
end


function public.misc()
   
   local FRC_DressingRoom_Settings = require('FRC_Modules.FRC_DressingRoom.FRC_DressingRoom_Settings');      
   local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');   
   local function DATA(key, baseDir)
      baseDir = baseDir or system.ResourceDirectory;
      return FRC_DataLib.readJSON(FRC_DressingRoom_Settings.DATA[key], baseDir);
   end
   local characterData = DATA('CHARACTER');
   
   table.dump2( characterData[2] )
   table.dump2( characterData[2].clothing )
--[[
	local none = {
		id = 'none',
		imageFile = UI('COSTUME_NONE_IMAGE'),
		width = UI('COSTUME_NONE_WIDTH'),
		height = UI('COSTUME_NONE_HEIGHT'),
		xOffset = 0,
		yOffset = 0
	};
	for i=1,#characterData do
		for k,v in pairs(characterData[i].clothing) do
			table.insert(characterData[i].clothing[k], 1, none);
		end
	end
--]]

end



--
-- Costume Touch Handler
--
function private.costumeTouch( self, event ) 
   if( event.phase == "began" ) then
      display.currentStage:setFocus( self, event.id )
      self.isFocus = true
   elseif( self.isFocus ) then
      local bounds = self.stageBounds
      local x,y = event.x, event.y
      local isWithinBounds = 
         bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
      
      if( event.phase == "ended" ) then
         display.currentStage:setFocus( self, nil )
         self.isFocus = false
         if( isWithinBounds ) then
            if( self.data == "none" ) then 
               dprint( "Remove costume" )
            else 
               table.print_r(self.data)
               public.placeNewCharacter(self.data)
            end
         end
      end
   end
   return true
end

--
-- Common Drag & Drop Handler
--
function private.attachDragger( obj )
   obj.touch = private.dragNDrop
   obj:addEventListener( "touch" )
end
function private.dragNDrop( self, event ) 
   if( event.phase == "began" ) then
      display.currentStage:setFocus( self, event.id )
      self.isFocus = true
      self.x0 = self.x
      self.y0 = self.y
   elseif( self.isFocus ) then
      local bounds = self.stageBounds
      local x,y = event.x, event.y
      local isWithinBounds = 
         bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
         
      local dx = event.x - event.xStart
      local dy = event.y - event.yStart
      self.x = self.x0 + dx
      self.y = self.y0 + dy
      
      if( event.phase == "ended" ) then
         display.currentStage:setFocus( self, nil )
         self.isFocus = false
         if( isWithinBounds ) then
            if( self.data == "none" ) then 
               --dprint( "Remove costume" )
            else 
               --table.print_r(self.data)
               --public.placeNewCharacter(self.data)
            end
         end
      end
   end
   return true
end

return public


--
-- SCRATCH PAD  SCRATCH PAD  SCRATCH PAD  SCRATCH PAD  SCRATCH PAD  
-- SCRATCH PAD  SCRATCH PAD  SCRATCH PAD  SCRATCH PAD  SCRATCH PAD  
-- SCRATCH PAD  SCRATCH PAD  SCRATCH PAD  SCRATCH PAD  SCRATCH PAD  
--

--[[
-- handles swapping out of characters and specific clothing items
	local function changeItem(categoryId, character, index)
		clearLayer(categoryId);

		local charData = getDataForCharacter(character);

		if (categoryId == 'Character') then
			selectedCharacter = character;
			local charBody = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.bodyImage, charData.bodyWidth, charData.bodyHeight);
			charBody.x, charBody.y = character_x, character_y;

      -- DEBUG:
			print(charData.eyesOpenImage);
			print(UI('IMAGES_PATH') .. charData.eyesOpenImage);
			print(charData.eyesShutImage);
			print(UI('IMAGES_PATH') .. charData.eyesShutImage);
			if (charData.eyesOpenImage and charData.eyesShutImage) then
				local charEyesOpen = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.eyesOpenImage, charData.eyesOpenWidth, charData.eyesOpenHeight);
				charEyesOpen.x, charEyesOpen.y = charBody.x + charData.eyesX, charBody.y + charData.eyesY;
				charEyesOpen.isVisible = true;
				print(charEyesOpen.x, charEyesOpen.y); -- DEBUG

				local charEyesShut = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.eyesShutImage, charData.eyesShutWidth, charData.eyesShutHeight);
				charEyesShut.x, charEyesShut.y = charBody.x + charData.eyesX, charBody.y + charData.eyesY;
				charEyesShut.isVisible = false;
				print(charEyesShut.x, charEyesShut.y); -- DEBUG

				beginEyeAnimation(charEyesOpen, charEyesShut);
			end

			if (index ~= 0) then
				for i=2,#categoryData do
					changeItem(categoryData[i].id, selectedCharacter, layers[categoryData[i].id].selectedIndex or 1);
				end
			end
		else
			local clothingData = charData.clothing[categoryId][index];
			if (not clothingData) then return; end
			if (clothingData.id ~= 'none') then
				local item = display.newImageRect(layers[categoryId], UI('IMAGES_PATH') .. clothingData.imageFile, clothingData.width, clothingData.height);
				-- ERRORCHECK
				if not item then
					assert(refImage, "ERROR: Missing costume media file: ", UI('IMAGES_PATH') .. clothingData.imageFile);
				end
				item.x, item.y = character_x + clothingData.xOffset, character_y + clothingData.yOffset;
				-- check to see if we need to use the special altBodyImage
				if (categoryId == 'Headwear') then
					if (clothingData.altBodyImage) then
						-- DEBUG:
						-- print("Swapping in altBodyImage: ", UI('IMAGES_PATH') .. charData.altBodyImage);
						clearLayer('Character');
						charBody = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.altBodyImage, charData.bodyWidth, charData.bodyHeight);
						charBody.x, charBody.y = character_x, character_y;
					else
						-- sloppy but we have to switch back to the baseimage
						-- DEBUG:
						-- print("Swapping in bodyImage: ", UI('IMAGES_PATH') .. charData.bodyImage);
						clearLayer('Character');
						charBody = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.bodyImage, charData.bodyWidth, charData.bodyHeight);
						charBody.x, charBody.y = character_x, character_y;
					end
				end
			else
				if (categoryId == 'Headwear') then
					-- we only reset the body if they chose the none option for Headwear
					clearLayer('Character');
					charBody = display.newImageRect(layers['Character'], UI('IMAGES_PATH') .. charData.bodyImage, charData.bodyWidth, charData.bodyHeight);
			  	charBody.x, charBody.y = character_x, character_y;
				end
			end
			layers[categoryId].selectedIndex = index;
		end
		view.currentData = {
			character = character,
			categories = {}
		};
		for k,v in pairs(layers) do
			view.currentData.categories[k] = layers[k].selectedIndex;
		end
	end
	self.changeItem = changeItem;
--]]



--[[
   local songInstruments = instrumentData[1].instruments;
   for i=1,#songInstruments do
      local scroller = itemScrollers['Instrument']
      buttonHeight = scroller.contentHeight - button_spacing
      table.dump2(songInstruments[i]) --EFM
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
               -- CODE TO HANDLE INSTRUMENT INSERTION/CHANGE GOES HERE
               -- changeItem('Instrument', self.id)
               FRC_CharacterBuilder.showIntrumentSample( self.id )
               --print(self.id)
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

--]]



--[[
function public.rebuildCostumeScroller_attempt1_failed( )  -- got disconnectd from costume select button?
   local ui = require('ui')

   -- Destroy OLD scroller
   display.remove( itemScrollers.Costume., )
   
   -- Create new Scroller 
   -- create corresponding item scroll containers
   local category_button_spacing = 48
   local button_spacing = 24
   local button_scale = 0.75
   local categoriesWidth = button_spacing
   local categoriesHeight = 0   
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
   scroller.isVisible = true   
   itemScrollers.Costume = scroller   
end
--]]
