local FRC_AnimationManager    = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager')

--local animals = { "Chicken", "Cat", "Dog", "Hamster", "Pig", "Sheep", "Goat" }

-- EFM missing some cat instruments
--local instruments = { "Bass", "Conga", "Guitar", "Harmonica", "Maracas", "Microphone", "Piano", "Sticks", "RhythmComboCheeseGrater", "RhythmComboCymbal" }
local instruments = {}
instruments.Cat      = { "Bass", "Conga", "Guitar", "Harmonica", "Microphone", "Piano" }
instruments.Chicken  = { "Bass", "Conga", "Guitar", "Harmonica", "Maracas", "Microphone", "Piano", "Sticks", "RhythmComboCheeseGrater", "RhythmComboCymbal" }

local instrumentAvailable = {}
instrumentAvailable.Cat = {}
instrumentAvailable.Chicken = {}
for i = 1, #instruments.Cat do
   instrumentAvailable.Cat[i] = true
end
for i = 1, #instruments.Chicken do
   instrumentAvailable.Chicken[i] = true
end


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



function private.getPartName( costumeData, category, index )
   if( index == 1 )  then
      return "NONE"
   end
   return string.gsub(costumeData.clothing[category][index-1].imageFile, ".png", "" )
end

function private.getPartOffset( costumeData, category, index )
   if( index == 1 ) then 
      return { 0, 0 }
   end
   index = index - 1
   local b = costumeData.clothing[category][1]
   local t = costumeData.clothing[category][index]
   return { -b.xOffset + t.xOffset, -b.yOffset + t.yOffset }
end


function public.createNewAnimal( characterData ) 
   local testGroup -- EFM to be self-contained later
   local animationSequences  = {} -- EFM to be self-contained later

   dprint( "public.createNewAnimal()" )
   local animalType           = characterData.character
   local instrumentType       = characterData.instrument or "Bass" -- EFM TBD
   local costumeData          = private.getCostumeData( animalType )   
   local xmlFiles             = private.getXMLFileNames( animalType )
   
   -- EDO Temporarily choose random instrument for demoing
   local instrumentsLeft = false
   for i = 1, #instrumentAvailable[animalType] do
      instrumentsLeft = instrumentsLeft or instrumentAvailable[animalType][i]
   end
   if( not instrumentsLeft ) then return end 
   local instrumentNum = mRand(1,#instruments[animalType])
   while( instrumentAvailable[animalType][instrumentNum] == false ) do
      instrumentNum = mRand(1,#instruments[animalType])
   end
   instrumentAvailable[animalType][instrumentNum] = false   
   instrumentType = instruments[animalType][instrumentNum]   
   
   local adjustments = {}
   for k,v in pairs( characterData.categories ) do
      adjustments[k] = 
      { 
         fromPart = private.getPartName( costumeData, k, 2 ),
         toPart = private.getPartName( costumeData, k, v ),
         offset = private.getPartOffset( costumeData, k, v )
      }
   end
      
   
   if( tonumber(instrumentType) == nil ) then
      --dprint("Before ", animalType, instrumentType)
      instrumentType = private.instrumentNameMap(instrumentType)
      --dprint("After ", animalType, instrumentType)
   end
   
   -- EFM - TEMPORARY
   if( animalType ~= "Chicken" and animalType ~= "Cat" ) then 
      private.easyAlert( "Chickens and Cats", 
                "Only chickens and cats are supported right now.\n\nThe rest are coming soon!", 
                { {"OK", nil} } )
      dprint("Only chickens and cats supported right now....")
      return
   end
   dprint(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
   dprint(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
   dprint(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
   --table.print_r( characterData )
   --table.print_r( costumeData )
   --table.print_r( adjustments )
   dprint("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
   dprint("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
   dprint("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
   
   --[[
   -- EFM - MODIFY TO BE DRAGGABLE and SELF-TRACKING
   for i = 1, #animationSequences do
      local sequence = animationSequences[i]
      for j = 1, sequence.numChildren do
         --sequence[j]:dispose() -- EDO SOMETHING WRONG HERE!
         sequence[j]:stop() -- EDO SOMETHING WRONG HERE!  CRASH WHEN REMOVE PLAYING ANIMATION
      end
   end
   --]]
   display.remove( testGroup )
   testGroup   = display.newGroup()
   testGroup.x = display.contentCenterX
   testGroup.y = display.contentCenterY
   view:insert( testGroup )

   local partsList = private.getPartsList( xmlFiles[instrumentType], animationXMLBase, false )
   for i = 1, #partsList do
      dprint( "partsList[" .. i .. "] ", partsList[i].name, animationImageBase )      
   end
   
   -- Create a menu to select and play the animations
   --
   -- Parse animations from Unified file and select just animations we want
   local animationsToBuild = {}   
   local allParts = private.getAllPartsList( instrumentType )
   
   -- 
   -- Core Logic for building up characters animations 
   --
   for i = 1, #allParts do
      local partName = allParts[i][1]
      local partExcludeName = allParts[i][2]
      for j = 1, #partsList do
         if( string.match( partsList[j].name, partName ) ~= nil ) then
            private.findAnimationParts( partsList, partName, partExcludeName, animationsToBuild, allParts[i][3] )
         end
      end
   end
   
   --
   -- Attach adjustment to parts if present.  (Allows us to replace artwork at create time in animationManager, and to adjust art offset after creation.)
   --
   local tmp = {}
   for i = 1, #animationsToBuild do
      local adjustment = adjustments[animationsToBuild[i][1]]
      if( adjustment and adjustment.toPart == "NONE" ) then
         -- skip
      else
         animationsToBuild[i][4] =  adjustment
         tmp[#tmp+1] = animationsToBuild[i]
      end
   end
   animationsToBuild = tmp
   tmp = nil
   --table.print_r(animationsToBuild)  
   
   -- Create animation groups (sequences) from our list of animations to build
   local animGroup = display.newGroup()
   local xOffset = -(display.actualContentWidth/2)
   local yOffset = -(display.actualContentHeight/2)
   testGroup:insert(animGroup)
   for i = 1, #animationsToBuild do
      local adjustment = adjustments[animationsToBuild[i][1]]
      local animationGroupProperties = {}
      animationSequences[i] = private.createUnifiedAnimationClipGroup( 
         xmlFiles[instrumentType],
         animationsToBuild[i],
         animationXMLBase,
         animationsToBuild[i][3], -- animationImageBase,
         animationGroupProperties )
      --FRC_Layout.scaleToFit(animationSequences[i], 0, 0)
      animationSequences[i].x = xOffset
      animationSequences[i].y = yOffset
      if( adjustment ) then
         animationSequences[i].x = animationSequences[i].x + adjustment.offset[1]
         animationSequences[i].y = animationSequences[i].y + adjustment.offset[2]
      end
      animGroup:insert(animationSequences[i])
   end
   
   testGroup:scale(0.5, 0.5)
   --testGroup.dragScale = 2
   private.attachDragger(testGroup)
   
   --dprint("EFM - ", testGroup.contentWidth, testGroup.contentHeight )
   
     
   --table.print_r(animationSequences)
   -- Yes, I'm placing these manually for now
   --animGroup.x = 240
   --animGroup.y = 200
   --animGroup:scale(0.55,0.55)
   -- Create a menu to select and play the animations
   --
   for i = 1, #animationSequences do
      private.playUnifiedAnimations( animationSequences, i )
   end
   
   return animationSequences
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
   local characters = public.getDressingRoomDataByAnimalType( currentCharacterType, 1 ) --EFM
   
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
   tmp.touch = private.scrollerCostumeTouch
   tmp:addEventListener( "touch" ) 
   
   for i = 1, #characters do      
      x = x + button_spacing
      local curChar = characters[i]
      --local tmp = display.newCircle( x, 0, 20 )
      local tmp = display.newImage( curChar.id .. curChar.thumbSuffix, system.DocumentsDirectory )
      tmp:scale(0.5,0.5)
      tmp.x = x 
      tmp.data = curChar
      tmp.touch = private.scrollerCostumeTouch
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
   --table.print_r(data)
   --public.createNewAnimal( "Chicken", "Bass" )
   --public.showIntrumentSample(1)
   public.createNewAnimal( data )
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
-- getDressingRoomDataByAnimalType( characterType ) - Extract just 'characterType' characters from saved list of (dressing room) characters
--
function public.getDressingRoomDataByAnimalType( characterType, debugLevel )
   
   local characters = {}
   local dressingRoomDataPath = "FRC_DressingRoom_SaveData.json"
   local allSaved = table.load( dressingRoomDataPath ) or {}   
   if( not allSaved.savedItems ) then 
      if( debugLevel and debugLevel > 0 ) then
         dprint("No charactes/costumes saved, can't search for this animal type: ", characterType )
         private.easyAlert( "No saved costumes", 
                            "No charactes/costumes saved, can't search for this animal type: " .. 
                            tostring(characterType) .. "\n\n Please go save some constumes first.", 
                            { {"OK", nil} } )
      end
      return characters 
   end   
   local savedItems = allSaved.savedItems      
   for i = 1, #savedItems do
      local current = savedItems[i]      
      if( current.character == characterType ) then
         characters[#characters+1] = current
      end
   end  
   if( debugLevel and debugLevel > 0 ) then
      if( #characters == 0 ) then
         private.easyAlert( "No saved costumes", 
                            "No charactes/costumes saved for this animal type: " .. 
                            tostring(characterType) .. "\n\n Please go save some constumes first.", 
                            { {"OK", nil} } )                        
      end         
      dprint("Found ", tostring(#characters), " of charactes/costumes of this type: ", characterType )
   end
   if( debugLevel and debugLevel > 1 ) then
      table.print_r(characters)
      dprint("getDressingRoomDataByAnimalType()")
   end
   
   return characters
end

-- 
-- getDressingRoomDataByID( characterType ) - Extract just 'characterType' characters from saved list of (dressing room) characters
--
function public.getDressingRoomDataByID( id, debugLevel )
   local dressingRoomDataPath = "FRC_DressingRoom_SaveData.json"
   local allSaved = table.load( dressingRoomDataPath ) or {}   
   if( not allSaved.savedItems ) then 
      if( debugLevel and debugLevel > 0 ) then
         private.easyAlert( "No saved costumes", 
                            "No charactes/costumes saved, can't search for this id: " .. 
                            tostring(id) .. "\n\n Please go save some constumes first.", 
                            { {"OK", nil} } )
         
         dprint("No charactes/costumes saved, can't search for this id: ", id )
      end
      return nil 
   end   
   local savedItems = allSaved.savedItems      
   for i = 1, #savedItems do
      local current = savedItems[i]      
      if( current.id == id ) then
         dprint("Found character by ID: ", id )
         return character
      end
   end     
   
   if( debugLevel and debugLevel > 0 ) then  
      private.easyAlert( "Unknown Dressing Room ID", 
                      "No charactes/costumes found matching this ID: " .. tostring(characterType), 
                      { {"OK", nil} } )
   end

   return nil
end


function private.getCostumeData( animalType )
   
   local FRC_DressingRoom_Settings = require('FRC_Modules.FRC_DressingRoom.FRC_DressingRoom_Settings');      
   local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');   
   local function DATA(key, baseDir)
      baseDir = baseDir or system.ResourceDirectory;
      return FRC_DataLib.readJSON(FRC_DressingRoom_Settings.DATA[key], baseDir);
   end
   local characterData = DATA('CHARACTER');
   
   
   local costumeData;
   for i=1,#characterData do
      if( characterData[i].id == animalType ) then
         costumeData = characterData[i];
         break;
      end
   end
   if (not costumeData) then
      private.easyAlert( "No character data found", 
                         tostring( animalType ) .. " had no data?", 
                         { {"OK", nil} } )
   end
   return costumeData
end


--
-- Costume Touch Handler
--
function private.scrollerCostumeTouch( self, event ) 
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
               --table.print_r(self.data)
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
      self:toFront()
   elseif( self.isFocus ) then
      local bounds = self.stageBounds
      local x,y = event.x, event.y
      local isWithinBounds = 
         bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
         
      local dx = event.x - event.xStart
      local dy = event.y - event.yStart
      self.x = self.x0 + dx * (self.dragScale and self.dragScale or 1)
      self.y = self.y0 + dy * (self.dragScale and self.dragScale or 1)
      
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


function private.getAllPartsList( instrumentType )
   local dressingRoomImageBase = "FRC_Assets/FRC_DressingRoom/Images/"
   local allParts
   dprint("Getting allParts layer ordering table for instrument type: ", instrumentType, private.instrumentNameMap(instrumentType) )
   if( instrumentType == 5 ) then -- Guitar
      allParts = {
         { "Body", "", animationImageBase },
         { "Torso_Guitar", "", animationImageBase },
         { "Neckwear", "", dressingRoomImageBase },
         { "LowerTorso", "", dressingRoomImageBase },
         { "UpperTorso", "", dressingRoomImageBase },
         { "Mouth", "", animationImageBase },
         { "Eyes", "WithEyes", dressingRoomImageBase },
         { "Eyewear", "", dressingRoomImageBase },
         { "Headwear", "", dressingRoomImageBase },
         { "Instrument", "", animationImageBase },
         { "LeftArm", "", animationImageBase },
         { "RightArm", "", animationImageBase },
      }
   elseif( instrumentType == 7 ) then -- Maracas
      allParts = {
         { "Body", "", animationImageBase },
         { "Neckwear", "", dressingRoomImageBase },
         { "LowerTorso", "", dressingRoomImageBase },
         { "UpperTorso", "", dressingRoomImageBase },
         { "Mouth", "", animationImageBase },
         { "Eyes", "WithEyes", dressingRoomImageBase },
         { "Eyewear", "", dressingRoomImageBase },
         { "Headwear", "", dressingRoomImageBase },
         { "Instrument_Maracas_Left", "", animationImageBase },
         { "Instrument_Maracas_Right", "", animationImageBase },
         { "LeftArm", "", animationImageBase },
         { "RightArm", "", animationImageBase },
      }
   elseif( instrumentType == 10 ) then -- Cheese Grater
      allParts = {
         { "Body", "", animationImageBase },
         { "Neckwear", "", dressingRoomImageBase },
         { "LowerTorso", "", dressingRoomImageBase },
         { "UpperTorso", "", dressingRoomImageBase },
         { "Mouth", "", animationImageBase },
         { "Eyes", "WithEyes", dressingRoomImageBase },
         { "Eyewear", "", dressingRoomImageBase },
         { "Headwear", "", dressingRoomImageBase },
         { "Instrument_RhythmComboCheeseGrater", "Instrument_RhythmComboCheeseGrater_Fork", animationImageBase },
         { "RightArm", "", animationImageBase },
         { "Instrument_RhythmComboCheeseGrater_Fork", "", animationImageBase },
         { "LeftArm", "", animationImageBase },
      }
   elseif( instrumentType == 11 ) then -- Combo Cymbal
      allParts = {
         { "Body", "", animationImageBase },
         { "Neckwear", "", dressingRoomImageBase },
         { "LowerTorso", "", dressingRoomImageBase },
         { "UpperTorso", "", dressingRoomImageBase },
         { "Mouth", "", animationImageBase },
         { "Eyes", "WithEyes", dressingRoomImageBase },
         { "Eyewear", "", dressingRoomImageBase },
         { "Headwear", "", dressingRoomImageBase },
         { "Instrument_RhythmComboCymbal", "Instrument_RhythmComboCymbal_Stick", animationImageBase },
         { "Instrument_RhythmComboCymbal_Stick", "", animationImageBase },
         { "LeftArm", "", animationImageBase },
         { "RightArm", "", animationImageBase },

      }
   elseif( instrumentType == 12 ) then -- Sticks
      allParts = {
         { "Body", "", animationImageBase },
         { "Neckwear", "", dressingRoomImageBase },
         { "LowerTorso", "", dressingRoomImageBase },
         { "UpperTorso", "", dressingRoomImageBase },
         { "Mouth", "", animationImageBase },
         { "Eyes", "WithEyes", dressingRoomImageBase },
         { "Eyewear", "", dressingRoomImageBase },
         { "Headwear", "", dressingRoomImageBase },
         { "Instrument_Sticks_Left", "", animationImageBase },
         { "Instrument_Sticks_Right", "", animationImageBase },
         { "LeftArm", "", animationImageBase },
         { "RightArm", "", animationImageBase },
      }

   else
      allParts = {
         { "Body", "", animationImageBase },
         { "Neckwear", "", dressingRoomImageBase },
         { "LowerTorso", "", dressingRoomImageBase },
         { "UpperTorso", "", dressingRoomImageBase },
         { "Mouth", "", animationImageBase },
         { "Eyes", "WithEyes", dressingRoomImageBase },
         { "Eyewear", "", dressingRoomImageBase },
         { "Headwear", "", dressingRoomImageBase },
         { "Instrument", "", animationImageBase },
         { "LeftArm", "", animationImageBase },
         { "RightArm", "", animationImageBase },
      }
   end
   return allParts
end


-- Easy alert popup
--
-- title - Name on popup.
-- msg - message in popup.
-- buttons - table of tables like this:
-- { { "button 1", opt_func1 }, { "button 2", opt_func2 }, ...}
--
function private.easyAlert( title, msg, buttons )

	local function onComplete( event )
		local action = event.action
		local index = event.index
		if( action == "clicked" ) then
			local func = buttons[index][2]
			if( func ) then func() end 
	    end
	    --native.cancelAlert()
	end

	local names = {}
	for i = 1, #buttons do
		names[i] = buttons[i][1]
	end
	--print( title, msg, names, onComplete )
	local alert = native.showAlert( title, msg, names, onComplete )
	return alert
end


function private.instrumentNameMap( toMap )
   local map = {}
   map.Microphone = 8
   map.Bass = 1
   map.Conga = 2
   map.Guitar = 5
   map.Piano = 9
   map.Harmonica = 6
   map.Maracas = 7
   map.Sticks = 12
   map.RhythmComboCheeseGrater = 10
   map.RhythmComboCymbal = 11
   map[1] = "Bass"
   map[2] = "Conga"
   map[5] = "Guitar"
   map[6] = "Harmonica"
   map[7] = "Maracas"
   map[8] = "Microphone"
   map[9] = "Piano"
   map[12] = "Sticks"
   map[10] = "RhythmComboCheeseGrater"
   map[11] = "RhythmComboCymbal"
   return map[toMap]
end


function private.getXMLFileNames( animalType )
   local xmlFiles = {
      "MDMT_Animation_" .. animalType .. "_Bass.xml", -- 1
      "MDMT_Animation_" .. animalType .. "_Conga.xml", -- 2
      "MDMT_Animation_" .. animalType .. "_Dance1.xml", -- 3
      "MDMT_Animation_" .. animalType .. "_Dance2.xml", -- 4
      "MDMT_Animation_" .. animalType .. "_Guitar.xml", -- 5
      "MDMT_Animation_" .. animalType .. "_Harmonica.xml", -- 6
      "MDMT_Animation_" .. animalType .. "_Maracas.xml", -- 7
      "MDMT_Animation_" .. animalType .. "_Microphone.xml", -- 8
      "MDMT_Animation_" .. animalType .. "_Piano.xml", -- 9
      "MDMT_Animation_" .. animalType .. "_RhythmComboCheeseGrater.xml", -- 10
      "MDMT_Animation_" .. animalType .. "_RhythmComboCymbal.xml", -- 11
      "MDMT_Animation_" .. animalType .. "_Sticks.xml", -- 12
   }
   return xmlFiles
end

function private.readXML( fileName, baseXMLDir )
   local rawLUAcode, xmltable, preexistingFile, newLuaFile, err, dataToSave, appLUApath, docLUApath;
   local XMLfilename = fileName;
   local XMLLUAfilename = string.sub(XMLfilename, 1, string.len(XMLfilename)-3) .."lua";
   local XMLfilepath = baseXMLDir .. XMLfilename;
   appLUApath = system.pathForFile( baseXMLDir .. XMLLUAfilename );
   docLUApath = system.pathForFile( XMLLUAfilename, system.DocumentsDirectory );

   if (appLUApath) then -- or docLUApath) then
      local path = appLUApath; -- or docLUApath;
      preexistingFile, err = io.open(path,"r");

      if (preexistingFile and not err) then
         io.close(preexistingFile);
         if (appLUApath) then
            local appLUAFilename = string.gsub( string.gsub(baseXMLDir .. XMLLUAfilename, "/", "."), ".lua", "");
            rawLUAcode = require(appLUAFilename);
            xmltable = rawLUAcode; -- .xmltable;
         end
      else
         xmltable = FRC_AnimationManager.loadXMLData( XMLfilepath );
         if ( ON_SIMULATOR ) then
            dataToSave = table.serialize( "xmltable", xmltable, "" );
            newLuaFile, err = io.open(path,"w");
            newLuaFile:write( dataToSave );
            io.close(newLuaFile);
         end
      end
   else
      xmltable = FRC_AnimationManager.loadXMLData( XMLfilepath );

      if ( ON_SIMULATOR ) then
         dataToSave = table.serialize( "xmltable", xmltable, "" );
         --table.dump(dataToSave);
         newLuaFile, err = io.open(docLUApath,"w");
         newLuaFile:write( dataToSave );
         io.close(newLuaFile);
      end
   end
   return xmltable
end

function private.getPartsList( sourceFile, animationXMLBase, debugEn )
   local xmltable = private.readXML( sourceFile, animationXMLBase  )
   local partsList = xmltable.Animation.Part
   if( debugEn == true ) then
      for i = 1, #partsList do
         dprint(partsList[i].name)
      end
   end
   return partsList
end

function private.findAnimationParts( parts, partSubName, partExcludeName, toTable, animationImageBase )
   local subParts = {}
   for i = 1, #parts do
      if( partExcludeName and string.len(partExcludeName) > 0 ) then
         if( string.match( parts[i].name, partSubName ) and
            string.match( parts[i].name, partExcludeName ) == nil ) then
            subParts[#subParts+1] = i
         end
      else            
         if( string.match( parts[i].name, partSubName ) ) then
            subParts[#subParts+1] = i
         end
      end
   end
   if(toTable and #subParts > 0) then
      toTable[#toTable+1] = { partSubName, subParts, animationImageBase }
   end
   return subParts
end


function private.createUnifiedAnimationClipGroup( sourceFile, unifiedData, animationXMLBase, animationImageBase, animationGroupProperties )
   animationGroupProperties = animationGroupProperties or {}
   animationGroupProperties.unifiedData = unifiedData
   return FRC_AnimationManager.createAnimationClipGroup( { sourceFile }, animationXMLBase, animationImageBase, animationGroupProperties )
end


function private.playUnifiedAnimations( animationSequences, num )
   num = num or math.random(1,#animationSequences)
   -- pick a random animation sequence
   local sequence = animationSequences[num]

   --print("BILLY ",  sequence.numChildren )
   for i=1, sequence.numChildren do

      sequence[i]:play({
            showLastFrame = true,
            playBackward = false,
            autoLoop = false,
            palindromicLoop = false,
            delay = 0,
            intervalTime = 30,
            maxIterations = 1,
            --onCompletion = onCompletion,
            --stopGate = true -- Not transfered yet
         })
      --timer.performWithDelay(33, function() sequence[i]:pause() end )
   end
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
