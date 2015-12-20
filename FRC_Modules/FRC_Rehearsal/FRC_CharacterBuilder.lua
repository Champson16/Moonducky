-- ======================================================================
-- FRC Character Builder - 
-- ======================================================================
local public   = {} -- Public interface
local private  = {} -- Private inteface

-- ======================================================================
-- Requires
-- ======================================================================
local ui                      = require('ui')
local FRC_DataLib             = require('FRC_Modules.FRC_DataLib.FRC_DataLib')
local FRC_Layout              = require('FRC_Modules.FRC_Layout.FRC_Layout')
local FRC_AnimationManager    = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager')
local FRC_Rehearsal_Settings  = require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Settings')

local function UI(key)
   return FRC_Rehearsal_Settings.UI[key]
end   
local function DATA(key, baseDir)
   baseDir = baseDir or system.ResourceDirectory
   return FRC_DataLib.readJSON(FRC_Rehearsal_Settings.DATA[key], baseDir)
end

-- ======================================================================
-- Forward Declarations
-- ======================================================================

-- ======================================================================
-- Localizations (for speedup and simplicity)
-- ======================================================================
local mRand       = math.random
local strLower    = string.lower
local strMatch    = string.match
local strGSub     = string.gsub

-- ======================================================================
-- Locals
-- ======================================================================
local snapDist       = 100 ^ 2
local characterScale = 0.5 -- Scale all placed characters and instruments by this much
local instrumentScale = 0.35
local stagePieces 
local view, currentSongID, animationXMLBase, animationImageBase, itemsScroller, categoriesContainer
local screenW, screenH = FRC_Layout.getScreenDimensions()
local currentStagePiece
local instrumentsInUse

local	screenW, screenH, contentW, contentH, centerX, centerY = FRC_Layout.getScreenDimensions() 

-- ********************************  
-- EFM Following may be temporary (revist these locals):
-- ********************************  
local animalsNames         = { "Chicken", "Cat", "Dog", "Hamster", "Pig", "Sheep", "Goat" }
local instrumentNames      = { "Bass", "Conga", "Guitar", "Harmonica", "Maracas", "Microphone", "Piano", "Sticks", "RhythmComboCheeseGrater", "RhythmComboCymbal" }
local songTitles        = {}
songTitles.hamsters = "Hamsters Want To Be Free"
songTitles.mechanicalcow = "Mechanical Cow"

local hamsterInstruments   = { "Bass", "Conga", "Guitar", "Harmonica", "Maracas", "Microphone", "Sticks", "RhythmComboCheeseGrater" } 
local cowInstruments       = { "Bass", "Conga", "Guitar", "Harmonica", "Microphone", "Piano", "RhythmComboCymbal" } 
local allInstruments       = { "Bass", "Conga", "Guitar", "Harmonica", "Maracas", "Microphone", "Piano", "Sticks", "RhythmComboCheeseGrater", "RhythmComboCymbal" } 

-- ********************************  


-- ======================================================================
-- Public Method Definitions
-- ======================================================================

-- 
-- cleanup() - Purge local references to key rehearsal values and groups.
--
function public.cleanup()
   display.remove( stagePieces )
   stagePieces          = display.newGroup()
   instrumentsInUse     = {}
   view.setDesignGroup:insert( stagePieces )
end

-- 
-- cleanup() - Purge local references to key rehearsal values and groups.
--
function public.destroy()   
   view                 = nil
   currentSongID        = nil
   animationXMLBase     = nil
   animationImageBase   = nil
   itemScrollers        = nil
   categoriesContainer  = nil
   currentCharacterType = "Chicken"
   currentStagePiece    = nil
   instrumentsInUse     = nil
   showTimeMode         = false
   instrumentNames      = { "Bass", "Conga", "Guitar", "Harmonica", "Maracas", "Microphone", "Piano", "Sticks", "RhythmComboCheeseGrater", "RhythmComboCymbal" } 
   
   display.remove(stagePieces)
end

-- 
-- init() - Store local references to key rehearsal values and groups.
--
function public.init( params )    
   public.destroy()
   view                 = params.view
   currentSongID        = params.currentSongID
   animationXMLBase     = params.animationXMLBase
   animationImageBase   = params.animationImageBase
   itemScrollers        = params.itemScrollers
   categoriesContainer  = params.categoriesContainer
   
   if(params.showTimeMode ~= nil) then
      showTimeMode = params.showTimeMode
   end
   
   if( currentSongID == "hamsters" ) then
      instrumentNames = hamsterInstruments
   elseif( currentSongID == "mechanicalcow" ) then
      instrumentNames = cowInstruments
   else
      instrumentNames = allInstruments
   end
   
   stagePieces          = display.newGroup()
   instrumentsInUse     = {}
         
   params.view.setDesignGroup:insert( stagePieces )
   
   private.attachTouchClear()
   
   --dprint(">>>>>>>>>>>>>>>>>>>>>>>>>", songTitles[currentSongID] )
   
   --timer.performWithDelay( 1000, public.getShowTitle )   
end


--
-- createOrLoadShow() - Pop up dialog to select between loading a show or creating a new show.
--
function public.createOrLoadShow( onLoad, onCreateHamster, onCreateCow, canLoad )
   local group = display.newGroup()
   local group2 = display.newGroup()
   group:insert( group2 )
   group.enterFrame = function( self ) 
      if( self.removeSelf == nil ) then
         Runtime:removeEventListener( "enterFrame", self )
         return
      end
      self:toFront()
      group2:toFront()
   end
   Runtime:addEventListener( "enterFrame", group ) -- EDOCHI
   
   --local back = display.newRect( centerX, centerY, 10000, 10000 )
   --back:setFillColor(0)
   --back.alpha = 0
   --transition.to( back, { alpha = 0.2, time = 500 } )
   
   local blur = private.easyBlur( group, 500, { 0, 0.4, 0.4, 0.8 } ) --  time, color )
   blur.touch = function( self, event )
      return true
   end
   blur:addEventListener( "touch" )
   
   -- EFM Add temporary label for save
   local backH       = screenH - 50
   local fontSize    = 60
   local fontSize2   = 44
   local fromButton = 100
   local titleLengthLimit = 20
   local selColor1    = { 0, 1, 0, 0.2 }
   local selColor2    = { 0, 0, 1, 0.2 }
   local unSelColor   = { 1, 1, 1 }
   
   local titleQueryBack = display.newRoundedRect( group, centerX, centerY, screenW - 50, backH, 8 )
   titleQueryBack.strokeWidth = 8
   titleQueryBack:setStrokeColor(0)

   local titleQueryLabel = display.newText( group2, "or", centerX, centerY - 100, native.systemFontBold, fontSize )
   titleQueryLabel:setFillColor(0)
   local titleQueryLabel2 = display.newText( group2, "Arrange A New One?", centerX, centerY - 20, native.systemFontBold, fontSize )
   titleQueryLabel2:setFillColor(0)
      
   --
   -- Load Existing Show
   --      
   local loadButton = display.newRoundedRect( group2, centerX, titleQueryLabel.y - fromButton , screenW - 100, 80, 8 )
   loadButton.strokeWidth = 4
   loadButton:setStrokeColor(0)
   loadButton.selColor = selColor1
   loadButton.cb = function()
      Runtime:removeEventListener( "enterFrame", group )
      display.remove( group )
      if( onLoad ) then
         onLoad( )          
      end
   end   
   local loadButtonLabel = display.newText( group2, "Load An Old Show", loadButton.x, loadButton.y, native.systemFontBold, fontSize2 )
   loadButtonLabel:setFillColor(0)

   --
   -- Create New Show With: 'Hamsters Want To Be Free'
   --
   local hamsterButton = display.newRoundedRect( group2, loadButton.x, titleQueryLabel2.y + fromButton, screenW - 100, 80, 4 )
   hamsterButton.strokeWidth = 4
   hamsterButton:setStrokeColor(0)
   hamsterButton.selColor = selColor2
   hamsterButton.cb = function()
      Runtime:removeEventListener( "enterFrame", group )
      display.remove( group )
      if( onCreateHamster ) then
         onCreateHamster( )          
      end
   end         
   local hamsterButtonTitle = display.newText( group2, "'Hamsters Want To Be Free'", hamsterButton.x, hamsterButton.y, native.systemFontBold, fontSize2 )
   hamsterButtonTitle:setFillColor(0)
      
   --
   -- Create New Show With: 'Mechanical Cow'
   --
   local cowButton = display.newRoundedRect( group2, hamsterButton.x, hamsterButton.y + 120, screenW - 100, 80, 4 )
   cowButton.strokeWidth = 4
   cowButton:setStrokeColor(0)
   cowButton.selColor = selColor2
   cowButton.cb = function()
      Runtime:removeEventListener( "enterFrame", group )
      display.remove( group )
      if( onCreateCow ) then
         onCreateCow( )          
      end
   end   
   local cowButtonTitle = display.newText( group2, "'Mechanical Cow'", cowButton.x, cowButton.y, native.systemFontBold, fontSize2 )
   cowButtonTitle:setFillColor(0)
   

   
   local function onTouch( self, event ) 
      if( event.phase == "began" ) then
         display.currentStage:setFocus( self, event.id )
         self.isFocus = true
         self:setFillColor( unpack( self.selColor ) )
      elseif( self.isFocus ) then
         local bounds = self.stageBounds
         local x,y = event.x, event.y
         local isWithinBounds = 
            bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
         
         if( isWithinBounds ) then
            self:setFillColor( unpack( self.selColor ) )
         else
            self:setFillColor( unpack( unSelColor ) )
         end
         
         if( event.phase == "ended" ) then
            display.currentStage:setFocus( self, nil )
            self.isFocus = false
            --table.print_r(self)
            if( isWithinBounds ) then     
               if( self.cb ) then self.cb() end 
            end
         end
      end
      return true
   end
   
   loadButton.touch = onTouch
   hamsterButton.touch = onTouch
   cowButton.touch = onTouch
   loadButton:addEventListener("touch")
   hamsterButton:addEventListener("touch")
   cowButton:addEventListener("touch")
   
   if( not canLoad ) then
      loadButton.isVisible = false
      loadButtonLabel.isVisible = false
      titleQueryLabel.isVisible = false
      titleQueryLabel2.text = "Choose a Song"
      group2.y = group2.y - 150     
   end
   
end




--
-- getShowTitle() - Pop up input field to get show title
--
function public.getShowTitle( onSuccess, onCancel )
   local group = display.newGroup()
   group.enterFrame = function( self ) 
      if( self.removeSelf == nil ) then
         Runtime:removeEventListener( "enterFrame", self )
         return
      end
      self:toFront()
   end
   Runtime:addEventListener( "enterFrame", group ) -- EDOCHI
   
   --local back = display.newRect( centerX, centerY, 10000, 10000 )
   --back:setFillColor(0)
   --back.alpha = 0
   --transition.to( back, { alpha = 0.2, time = 500 } )
   
   local blur = private.easyBlur( group, 500, { 0, 0.4, 0.4, 0.8 } ) --  time, color )
   blur.touch = function( self, event )
      return true
   end
   blur:addEventListener( "touch" )
   
   -- EFM Add temporary label for save
   local backH       = screenH/2 - 50
   local fontSize    = 60
   local fontSize2   = 20
   local titleLengthLimit = 20
   local selColor1    = { 0, 1, 0, 0.2 }
   local selColor2    = { 1, 0, 0, 0.2 }
   local unSelColor   = { 1, 1, 1 }
   
   local titleQueryBack = display.newRoundedRect( group, centerX, centerY - screenH/2 + backH/2 + 20, screenW - 10, backH, 8 )
   titleQueryBack.strokeWidth = 8
   titleQueryBack:setStrokeColor(0)
   
   local titleQueryLabel = display.newText( group, "What Should We Call This Show?", titleQueryBack.x, titleQueryBack.y - backH/2 + 60, native.systemFontBold, fontSize )
   titleQueryLabel:setFillColor(0)

   local function inputListener( self, event )
      table.dump(event.phase)
      if( event.text and string.len( event.text ) > titleLengthLimit ) then
         self.text = string.sub( event.text, 1, titleLengthLimit )
      end
   end

   local textBox = native.newTextField( centerX, titleQueryBack.y, screenW - 80, fontSize + 20 )
   textBox.font = native.newFont( native.systemFontBold, fontSize )
   textBox.text = "A Hard Act To Follow"
   textBox.isEditable = true
   textBox.userInput = inputListener
   textBox:addEventListener( "userInput"  )
   group:insert( textBox ) 


   local okButton = display.newRoundedRect( group, centerX + 150, titleQueryBack.y + 100, 160, 40, 8 )
   okButton.strokeWidth = 2
   okButton:setStrokeColor(0)
   okButton.selColor = selColor1
   okButton.cb = function()
      Runtime:removeEventListener( "enterFrame", group )
      display.remove( group )
      if( onSuccess ) then
         onSuccess( songTitles[currentSongID], textBox.text )          
      end
   end
   
   local okButtonLabel = display.newText( group, "OK", okButton.x, okButton.y, native.systemFontBold, fontSize2 )
   okButtonLabel:setFillColor(0)

   local cancelButton = display.newRoundedRect( group, centerX - 150, titleQueryBack.y + 100, 180, 40, 4 )
   cancelButton.strokeWidth = 2
   cancelButton:setStrokeColor(0)
   cancelButton.selColor = selColor2
   cancelButton.cb = function()
      Runtime:removeEventListener( "enterFrame", group )
      display.remove( group )
      if( onCancel ) then         
         onCancel( )
      end
   end
   
   local cancelButtonLabel = display.newText( group, "CANCEL", cancelButton.x, cancelButton.y, native.systemFontBold, fontSize2 )
   cancelButtonLabel:setFillColor(0)
   
   local function onTouch( self, event ) 
      if( event.phase == "began" ) then
         display.currentStage:setFocus( self, event.id )
         self.isFocus = true
         self:setFillColor( unpack( self.selColor ) )
      elseif( self.isFocus ) then
         local bounds = self.stageBounds
         local x,y = event.x, event.y
         local isWithinBounds = 
            bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
         
         if( isWithinBounds ) then
            self:setFillColor( unpack( self.selColor ) )
         else
            self:setFillColor( unpack( unSelColor ) )
         end
         
         if( event.phase == "ended" ) then
            display.currentStage:setFocus( self, nil )
            self.isFocus = false
            --table.print_r(self)
            if( isWithinBounds ) then     
               if( self.cb ) then self.cb() end 
            end
         end
      end
      return true
   end
   
   okButton.touch = onTouch
   cancelButton.touch = onTouch
   cancelButton:addEventListener("touch")
   okButton:addEventListener("touch")


end



-- 
-- save() - Save all stage elements (excluding stage backdrop which is handled in FRC_Rehearsal_Scene.)
--
function public.save(saveTable)
   --table.print_r(saveTable)
   
   currentStagePiece = nil
   private.highlightSelected() 
   
   local savePieces = {}
   saveTable.stagePieces = savePieces
   
   for i = 1, stagePieces.numChildren do
      local record = {}
      local stagePiece        = stagePieces[i]
      record.x                = stagePiece.x
      record.y                = stagePiece.y
      record.pieceType        = stagePiece.pieceType
      record.instrument       = stagePiece.instrument
      record.danceNumber      = stagePiece.danceNumber 
      record.characterID      = stagePiece.characterID
      savePieces[#savePieces+1] = record
   end
   --table.print_r( savePieces ) 
end


-- 
-- load() - Load and restore all stage elements (excluding stage backdrop which is handled in FRC_Rehearsal_Scene.)
--
function public.load(loadTable)
   --dprint("LOADING>>>>")
   --table.print_r(loadTable)
   
   public.cleanup()
   
   local restorePieces = loadTable.stagePieces or {}
   for i = 1, #restorePieces do      
      local curPiece = restorePieces[i]
      --table.dump2( curPiece,nil, "LOADING " .. tostring(i) .. " " .. tostring(curPiece.pieceType))

      if( curPiece.pieceType == "instrument" ) then
         public.placeNewInstrument( curPiece.x, curPiece.y, curPiece.instrument ) 
      
      elseif( curPiece.pieceType == "character" ) then
         public.placeNewCharacter(  curPiece.x, curPiece.y, curPiece.characterID, curPiece.instrument, curPiece.danceNumber  ) 
      end
   end
   
   currentStagePiece = nil
   private.highlightSelected() 

end

-- 
-- removeInstrument() - If an instrument is selected, remove it from the stage.
--
function public.removeInstrument()
   if( not currentStagePiece ) then return end
   if( currentStagePiece.pieceType == "instrument" ) then       
      instrumentsInUse[currentStagePiece.instrument] = nil
      display.remove(currentStagePiece)
      currentStagePiece = nil
      private.highlightSelected()
   else
      if( strMatch( strLower( currentStagePiece.instrument ), "dance" ) ) then
         return
      end
      instrumentsInUse[currentStagePiece.instrument] = nil
      local tmp = currentStagePiece      
      public.placeNewCharacter(  currentStagePiece.x, currentStagePiece.y, currentStagePiece.characterID, nil, currentStagePiece.danceNumber  )       
      display.remove( tmp )
   end
end

-- 
-- removeCharacter() - If an instrument is selected, remove it from the stage.
--
function public.removeCharacter()
   if( not currentStagePiece ) then return end
   if( currentStagePiece.pieceType == "instrument" ) then       
      return
   else
      local instrumentToLeave = currentStagePiece.instrument
      local tmp = currentStagePiece
      
      if( strMatch( strLower( instrumentToLeave ), "dance" ) ) then
         instrumentToLeave = nil
      else
         instrumentsInUse[instrumentToLeave] = nil
         public.placeNewInstrument( currentStagePiece.x, currentStagePiece.y, instrumentToLeave )         
      end
      display.remove( tmp )
   end
end

-- 
-- placeNewInstrument() - Create an instrument and place it in the center of the stage.
--
function public.placeNewInstrument( x, y, instrumentName )
   x = x or display.contentCenterX
   y = y or display.contentCenterY
   dprint( "public.placeNewInstrument( " .. tostring(instrumentName) .. " )" )
   
   if( instrumentsInUse[instrumentName] ) then
      private.easyAlert( "Duplicate instrument", 
                "Only one of each instrument can be placed.\n\n" .. instrumentName .. " is already on the stage.", 
                { {"OK", nil} } )
      dprint("Duplicate instrument", "Only one of each instrument can be placed.\n\n" .. instrumentName .. " is already on the stage." )
      return
   end
   
   
   local stagePiece = display.newImage( stagePieces, "FRC_Assets/FRC_Rehearsal/Images/MDMT_Rehearsal_Stage_Instrument_" .. instrumentName .. ".png"  ) --EFM: hardcoded
   stagePiece.x = x
   stagePiece.y = y
   stagePiece.pieceType = "instrument"
   stagePiece.instrument = instrumentName 
   
   private.attachDragger(stagePiece)
   
   stagePiece:scale(instrumentScale,instrumentScale)   
   
   instrumentsInUse[instrumentName] = instrumentName
   function stagePiece.destroy( self )
      instrumentsInUse[self.instrument] = nil
   end 
   
   currentStagePiece = stagePiece
   
   private.addSelectionIndicator( stagePiece )
   
   private.highlightSelected()   
   
   return stagePiece
end

-- 
-- placeNewCharacter() - 
--
function public.placeNewCharacter( x, y, characterID, instrumentName, danceNumber  ) 
   x = x or display.contentCenterX
   y = y or display.contentCenterY

   local characterData 
   if( type( characterID ) == "table" ) then
      characterData = characterID
   else
      characterData = private.getDressingRoomDataByID( characterID, 0 )
   end
   
   --table.print_r(characterData)
   
   local animalType           = characterData.character
   -- ***************************************** -- EFM - TEMPORARY
   --animalType = ( animalType ~= "Chicken" and animalType ~= "Cat" ) and "Chicken" or animalType
   -- *****************************************
   danceNumber                = danceNumber or mRand(1,2)   
   instrumentName             = instrumentName or ("Dance" .. danceNumber) -- Assume all players as dancers
   local instrumentType       = private.instrumentNameMap(instrumentName)
   local costumeData          = private.getCostumeData( animalType )   
   local xmlFiles             = private.getXMLFileNames( animalType )
   local animationSequences   = {} 

   --
   -- Get costume adjustment data for this character
   --   
   local adjustments = {}
   for k,v in pairs( characterData.categories ) do
      adjustments[k] = 
      { 
         fromPart = private.getPartName( costumeData, k, 2 ),
         toPart = private.getPartName( costumeData, k, v ),
         offset = private.getPartOffset( costumeData, k, v )
      }
   end            
      
   local stagePiece = display.newGroup()
   stagePieces:insert( stagePiece )
   
   stagePiece.x                  = x
   stagePiece.y                  = y
   stagePiece.pieceType          = "character"
   stagePiece.instrument         = instrumentName
   stagePiece.danceNumber        = danceNumber
   stagePiece.characterID        = characterID
   stagePiece.animationSequences = animationSequences
   
   -- Only preclude re-use of instruments (not dancers)
   if( not strMatch( strLower( instrumentName ), "dance" ) ) then
      instrumentsInUse[instrumentName] = instrumentName
   end   
   
   
   function stagePiece.destroy( self )
      instrumentsInUse[self.instrument] = nil
      
      -- ****************************************
      -- EFM SOMETHING WRONG HERE!  CRASHES IF STILL PLAYING ANIMATION
      -- ****************************************
      for i = 1, #animationSequences do
         local sequence = animationSequences[i]
         for j = 1, sequence.numChildren do
            --sequence[j]:dispose()
            sequence[j]:stop() 
         end
      end
      -- ****************************************
   end
   
   -- Get all known parts for the selected instrument type within the previously selected character (animal) type
   local partsList = private.getPartsList( xmlFiles[instrumentType], animationXMLBase, false )
   
   -- 
   -- Generate a list of the animation parts we need for this particular character
   --
   -- Note: Later, this info will be used by the animation manager to create ONLY these pieces from the unified set.
   --
   local animationsToBuild = {}   
   local allParts = private.getAllPartsList( instrumentType )
   for i = 1, #allParts do
      local partName = allParts[i][1]
      local partExcludeName = allParts[i][2]
      for j = 1, #partsList do
         if( strMatch( partsList[j].name, partName ) ~= nil ) then
            private.findAnimationParts( partsList, partName, partExcludeName, animationsToBuild, allParts[i][3] )
         end
      end
   end
   
   --
   -- Adjust parts (costume names and offsets).  
   --
   -- Note 1: Costume names are not applied till the moment animation manager prepares to build this animation.
   -- Note 2: Offet is used in this file after animation manager returns the new animation clip group.
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
     
   --
   -- Finally, create animation groups (sequences) from our list of animations to build
   --
   local animGroup = display.newGroup()
   local xOffset = -(display.contentWidth/2)
   local yOffset = -(display.contentHeight/2)
   stagePiece:insert(animGroup)
   for i = 1, #animationsToBuild do
      local adjustment = adjustments[animationsToBuild[i][1]]
      local animationGroupProperties = {}
      animationSequences[i] = private.createUnifiedAnimationClipGroup( 
         xmlFiles[instrumentType],
         animationsToBuild[i],
         animationXMLBase,
         animationsToBuild[i][3], -- animationImageBase,
         animationGroupProperties )
      animationSequences[i].x = xOffset
      animationSequences[i].y = yOffset
      if( adjustment ) then
         animationSequences[i].x = animationSequences[i].x + adjustment.offset[1]
         animationSequences[i].y = animationSequences[i].y + adjustment.offset[2]
      end
      animGroup:insert(animationSequences[i])
   end  
   
   --table.print_r(animationsToBuild)
   
   stagePiece:scale(characterScale,characterScale)
   private.attachDragger(stagePiece)

   -- EFM start stopped or play one cycle?
   for i = 1, #animationSequences do
      private.playAllAnimations( animationSequences, i )
      --private.stopAllAnimations( animationSequences, i )
   end
   
   currentStagePiece = stagePiece
   
   private.addSelectionIndicator( stagePiece )
   
   private.highlightSelected()   
   
   --dprint("Conga in use?", public.getInstrumentInUse( "Conga" ) )
   --table.dump2( public.getInstrumentsInUse() )
   
   return stagePiece   
   
   --return animationSequences
end

-- 
-- setCurrentCharacterType() - Builds the costume scroller based on the currently selected character type
--
function public.setCurrentCharacterType( characterType )
   currentCharacterType = characterType
end

-- 
-- rebuildInstrumenScroller() - Builds the costume scroller based on the currently selected character type
--
function public.rebuildInstrumenScroller( )
   local ui = require('ui')
   
   --if(true) then return end
   
   local instrumentData = DATA('INSTRUMENT')
   local songID = strGSub(songTitles[currentSongID], " ", "")
   
   local songInstruments = instrumentData[1]
   for i = 1, #instrumentData do
      if( instrumentData[i].id == songID ) then
         dprint("Selected instrument data for ", i, songID )
         songInstruments = instrumentData[i]
      end
   end
   
   local scroller = itemScrollers.Instrument
   
   -- Destroy OLD scroller CONTENT ONLY
   while( scroller.content.numChildren > 0 ) do
      display.remove( scroller.content[1] )
   end
   
   --local button_spacing = 80
   local category_button_spacing = 48
   local button_spacing = 24
   local button_scale = 0.75
   local categoriesWidth = button_spacing
   local categoriesHeight = 0
   local x = -(screenW * 0.5) + button_spacing   


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
            public.removeInstrument()
            return true
         end
      })
   button.categoryId = 'Instrument'
   scroller:insert(button)
   x = x + (button.contentWidth * 0.5)
   button.x, button.y = x, 0
   
   x = x + (button.contentWidth * 0.5) + (button_spacing * 1.5)      
   
   --table.print_r(songInstruments)
   
   -- for now, just grab the first song's instrument list
   songInstruments = songInstruments.instruments
   for i=1,#songInstruments do
      --dprint("EDOCHI", songInstruments[i].id)
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
               public.newInstrument( self.id )
               return true
            end
         })
      button.categoryId = 'Instrument'
      scroller:insert(button)
      x = x + (button.contentWidth * 0.5)
      button.x, button.y = x, 0
      x = x + (button.contentWidth * 0.5) + (button_spacing * 1.5)
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
   local characters = private.getDressingRoomDataByAnimalType( currentCharacterType, 0 ) --EFM
   
   -- Insert costumes for current animal type into scroller    
   --
   -- 'None' Button
   --
   local button_spacing = 80
   local x = -(screenW * 0.5) + button_spacing   
   local tmp = display.newImage( "FRC_Assets/FRC_Rehearsal/Images/FRC_Rehearsal_Scroller_None.png"  )
   tmp.x = x
   tmp.data = { id = "none" }
   scroller:insert( tmp )
   tmp.touch = private.scrollerCostumeTouch
   tmp:addEventListener( "touch" ) 

   --
   -- 'Mystery Box' Button
   --
   if( #characters > 1 ) then
      x = x + button_spacing
      local tmp = display.newImage( "FRC_Assets/FRC_Rehearsal/Images/MDMT_Rehearsal_Scroller_MysteryBox.png"  )
      tmp:scale(0.20, 0.20)
      tmp.x = x
      tmp.data = { id = "mysterybox", character = currentCharacterType, characters = characters }
      scroller:insert( tmp )
      tmp.touch = private.scrollerCostumeTouch
      tmp:addEventListener( "touch" ) 
   end
      
   --
   -- 'No Costume' Button
   --
   x = x + button_spacing
   local tmp = display.newImage( "FRC_Assets/FRC_Rehearsal/Images/MDMT_Rehearsal_global_BaseCharacter_" .. currentCharacterType .. "_thumbnail.png"  )
   tmp:scale(0.32, 0.32)
   tmp.x = x
   tmp.data = { id = "nocostume", character = currentCharacterType, categories = { Headwear = 1,  LowerTorso = 1, Neckwear = 1, UpperTorso = 1, Eyewear = 1 } }
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
-- Scroller Instrument Touch Handler
--
function public.newInstrument( instrument ) 
   if( currentStagePiece ) then
      private.replaceInstrument( currentStagePiece, instrument )
   else
      public.placeNewInstrument( nil, nil, instrument )
   end
end

--
-- getInstrumentsInUse() - Returns a numerically indexed list containing the names of instruments currently on the stage.
--
function public.getInstrumentsInUse()
   local tmp = {}
   for k,v in pairs( instrumentsInUse ) do
      tmp[#tmp+1] = k
   end
   return tmp
end

--
-- getInstrumentInUse() - Returns true if 'instrument' is in use
--
function public.getInstrumentInUse( instrument )
   return ( instrumentsInUse[instrument] ~= nil ) 
end


--
-- getCharactersOnStage() - Return list of all characters on stage.
--
function public.getCharactersOnStage()
   local tmp = {}
   dprint("getCharactersOnStage()", stagePieces.numChildren )
   for i = 1, stagePieces.numChildren do
      local curPiece = stagePieces[i]
      if( curPiece and  curPiece.pieceType == "character" ) then
         tmp[#tmp+1] = curPiece
      end
   end
   return tmp
end


--
-- playStageCharacters() - Make all characters on stage play.
--
function public.playStageCharacters() 
   local charactersOnStage = public.getCharactersOnStage() 
   --table.print_r( charactersOnStage )
   
   for i = 1, #charactersOnStage do
      local animationSequences = charactersOnStage[i].animationSequences
      for j = 1, #animationSequences do
         private.playAllAnimations( animationSequences, j, true )
      end
   end
end

--
-- stopStageCharacters() - Make all characters on stage stop playing.
--

function public.stopStageCharacters() 
   local charactersOnStage = public.getCharactersOnStage() 
   --table.print_r( charactersOnStage )
   
   for i = 1, #charactersOnStage do
      local animationSequences = charactersOnStage[i].animationSequences
      for j = 1, #animationSequences do
         private.stopAllAnimations( animationSequences, j )
      end
   end
end

if( edmode ) then
   local function onKey( event )
      local storyboard = require("storyboard");
      if( event.phase ~= "up" ) then return false end
      
      if( event.keyName == "p" ) then
         public.playStageCharacters() 
      
      elseif( event.keyName == "s" ) then
         public.stopStageCharacters() 
      
      elseif( event.keyName == "g" ) then
         public.getCharactersOnStage() 
      end
   
   end
   Runtime:addEventListener( "key", onKey )   
end


-- ======================================================================
-- Private Method Definitions
-- ======================================================================

-- 
-- getDressingRoomDataByAnimalType( characterType ) - Extract just 'characterType' characters from saved list of (dressing room) characters
--
function private.getDressingRoomDataByAnimalType( characterType, debugLevel )
   
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
function private.getDressingRoomDataByID( id, debugLevel )
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
         return current
      end
   end     
   
   if( debugLevel and debugLevel > 0 ) then  
      private.easyAlert( "Unknown Dressing Room ID", 
                      "No charactes/costumes found matching this ID: " .. tostring(characterType), 
                      { {"OK", nil} } )
   end
   
   return nil
end

--
-- EFM() - EFM
--
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
-- Scroller Costume Touch Handler
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
         --table.print_r(self)
         if( isWithinBounds ) then
            
            if( currentStagePiece ) then
               if( currentStagePiece.pieceType == "instrument" ) then -- MODIFYING INSTRUMENT
                  if( self.data.id == "none" ) then 
                     -- Do nothing
                  elseif( self.data.id == "nocostume" ) then 
                     private.replaceWithCharacter( currentStagePiece, self.data )
                     
                  elseif( self.data.id == "mysterybox" ) then 
                     local character = self.data.characters[mRand(1,#self.data.characters)]
                     private.replaceWithCharacter( currentStagePiece, character.id )
                     
                  else 
                     private.replaceWithCharacter( currentStagePiece, self.data.id )
                  end  

               else -- MODIFYING CHARACTER
                  if( self.data.id == "none" ) then 
                     -- Remove character
                     instrumentsInUse[currentStagePiece.instrument] = nil
                     display.remove(currentStagePiece)
                     currentStagePiece = nil
                     private.highlightSelected()

                  elseif( self.data.id == "nocostume" ) then 
                     private.replaceWithCharacter( currentStagePiece, self.data )
                  
                  elseif( self.data.id == "mysterybox" ) then
                     local character = self.data.characters[mRand(1,#self.data.characters)]
                     private.replaceWithCharacter( currentStagePiece, character.id )
                     
                  else                      
                     private.replaceWithCharacter( currentStagePiece, self.data.id)
                  end
               end

            else -- CREATING CHARACTER
               if( self.data.id == "none" ) then 
                  -- Do nothing
               elseif( self.data.id == "nocostume" ) then 
                  public.placeNewCharacter( nil, nil, self.data )
               
               elseif( self.data.id == "mysterybox" ) then 
                  local character = self.data.characters[mRand(1,#self.data.characters)]
                  public.placeNewCharacter( nil, nil, character.id)
                  dprint( "Mystery Box" )
               else 
                  --table.print_r(self.data)
                  public.placeNewCharacter( nil, nil, self.data.id)
               end
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
   if( showTimeMode ) then return end
   --obj.isHitTestMasked = true
   obj.touch = private.dragNDrop
   obj:addEventListener( "touch" )
end
function private.dragNDrop( self, event ) 
   if( event.phase == "began" ) then
      display.currentStage:setFocus( self, event.id )
      self.isFocus = true
      self.x0 = event.x
      self.y0 = event.y
      self:toFront()
      currentStagePiece = self
      private.highlightSelected()
   elseif( self.isFocus ) then
      local bounds = self.stageBounds
      local x,y = event.x, event.y
      local isWithinBounds = 
         bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
         
      local dx = event.x - self.x0
      local dy = event.y - self.y0
      
      self.x0 = event.x
      self.y0 = event.y
      
      local myLeft = self.x - self.contentWidth/2
      local myRight = self.x + self.contentWidth/2
      if( (dx < 0 and myLeft > private.left) or 
          (dx > 0 and myRight < private.right ) ) then
         self.x = self.x + dx * (self.dragScale and self.dragScale or 1)
      end
      
      local myTop = self.y - self.contentHeight/2
      local myBottom = self.y + self.contentHeight/2
      if( (dy < 0 and myTop > private.top) or 
          (dy > 0 and myBottom < private.bottom ) ) then
         self.y = self.y + dy * (self.dragScale and self.dragScale or 1)
      end
      
      if( event.phase == "ended" ) then
         display.currentStage:setFocus( self, nil )
         self.isFocus = false
         if( isWithinBounds ) then
            private.doDrop( self )
         end
         --currentStagePiece = nil
         --private.highlightSelected()
         
      end
   end
   return true
end

--[[
function private.dragNDrop( self, event ) 
   if( event.phase == "began" ) then
      display.currentStage:setFocus( self, event.id )
      self.isFocus = true
      self.x0 = self.x
      self.y0 = self.y
      self:toFront()
      currentStagePiece = self
      private.highlightSelected()
   elseif( self.isFocus ) then
      local bounds = self.stageBounds
      local x,y = event.x, event.y
      local isWithinBounds = 
         bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
         
      local dx = event.x - event.xStart
      local dy = event.y - event.yStart
      
      local myLeft = self.x - self.contentWidth/2
      local myRight = self.x + self.contentWidth/2
      if( (dx < 0 and myLeft > private.left) or 
          (dx > 0 and myRight < private.right ) ) then
         self.x = self.x0 + dx * (self.dragScale and self.dragScale or 1)
      end
      self.y = self.y0 + dy * (self.dragScale and self.dragScale or 1)
      
      if( event.phase == "ended" ) then
         display.currentStage:setFocus( self, nil )
         self.isFocus = false
         if( isWithinBounds ) then
            private.doDrop( self )
         end
         --currentStagePiece = nil
         --private.highlightSelected()
         
      end
   end
   return true
end
--]]


--
-- getAllPartsList() - Returns a part list for a specific instrument style.  (Some require special processing.)
--
function private.getAllPartsList( instrumentType )
   local dressingRoomImageBase = "FRC_Assets/FRC_DressingRoom/Images/"
   local allParts
   --dprint("Getting allParts layer ordering table for instrument type: ", instrumentType, private.instrumentNameMap(instrumentType) )
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
         { "Instrument_Sticks", "", animationImageBase },
         --{ "Instrument_Sticks_001_002", "", animationImageBase },
         --{ "Instrument_Sticks_002_002", "", animationImageBase },
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



--
-- instrumentNameMap() - Instrument string to numeric ID mapper (and vice versa)
--
function private.instrumentNameMap( toMap )
   local map = {}
   map.Bass                      = 1
   map.Conga                     = 2
   map.Dance1                    = 3
   map.Dance2                    = 4
   map.Guitar                    = 5
   map.Harmonica                 = 6
   map.Maracas                   = 7
   map.Microphone                = 8
   map.Piano                     = 9
   map.RhythmComboCheeseGrater   = 10
   map.RhythmComboCymbal         = 11
   map.Sticks                    = 12   
   map[1]                        = "Bass"
   map[2]                        = "Conga"
   map[3]                        = "Dance1"
   map[4]                        = "Dance2"
   map[5]                        = "Guitar"
   map[6]                        = "Harmonica"
   map[7]                        = "Maracas"
   map[8]                        = "Microphone"
   map[9]                        = "Piano"
   map[10]                       = "RhythmComboCheeseGrater"
   map[11]                       = "RhythmComboCymbal"
   map[12]                       = "Sticks"
   return map[toMap]
end


--
-- getXMLFileNames() - Generate a XML filename table based on a specifi animal type
--
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

--[[
--
-- readXML() - Extracted XML reader (from animationManager) (EFM - Needs additional changes when I fix LUA bug)
--
function private.readXML( fileName, baseXMLDir )
   dprint( "-------------------------------------", fileName, baseXMLDir )
   --
   -- 1. Try to find and load an existing lua table version of XML file
   --   
   fileName = strGSub( fileName, "%.xml", "" )
   local luaPath = strGSub( baseXMLDir .. fileName, "%/", "." )
   local luaFileExists = pcall( require, luaPath )
   if( luaFileExists ) then      
      return require( luaPath )
   end
   
   --
   -- 2. Failing that, read the XML file, save a lua file to the DocumentsDirectory and return xml table.
   --   
   local xmlPath  = baseXMLDir .. fileName .. ".xml"
   local xmltable = FRC_AnimationManager.loadXMLData( xmlPath, system.ResourceDirectory );   
   --local xmltable = FRC_AnimationManager.loadXMLData( fileName .. ".xml", baseXMLDir );
   table.save( xmltable, fileName ) 
   
   return xmltable
end
--]]

--
-- getPartsList() - Get the parts list for this unified animation file (so we can parse and manipulate it).
--
function private.getPartsList( sourceFile, animationXMLBase, debugEn )
   dprint( sourceFile, animationXMLBase, debugEn )
   local xmltable = FRC_AnimationManager.loadAnimationDataUnified( sourceFile, animationXMLBase  )
   local partsList = xmltable.Animation.Part
   if( debugEn == true ) then
      for i = 1, #partsList do
         dprint( "partsList[" .. i .. "] ", partsList[i].name, animationImageBase )      
      end
   end
   return partsList
end

--
-- findAnimationParts() - Find a specific animation in a unified animation export by name (with optional 'exclusion' match for names that match a sub-name in another animation)
--
function private.findAnimationParts( parts, partSubName, partExcludeName, toTable, animationImageBase )
   local subParts = {}
   for i = 1, #parts do
      if( partExcludeName and string.len(partExcludeName) > 0 ) then
         if( strMatch( parts[i].name, partSubName ) and
            strMatch( parts[i].name, partExcludeName ) == nil ) then
            subParts[#subParts+1] = i
         end
      else            
         if( strMatch( parts[i].name, partSubName ) ) then
            subParts[#subParts+1] = i
         end
      end
   end
   if(toTable and #subParts > 0) then
      toTable[#toTable+1] = { partSubName, subParts, animationImageBase }
   end
   return subParts
end

--
-- createUnifiedAnimationClipGroup() - Creates a set of animation clipgroups from a unified export and unified data (reduction) mapping.
--
function private.createUnifiedAnimationClipGroup( sourceFile, unifiedData, animationXMLBase, animationImageBase, animationGroupProperties )
   animationGroupProperties = animationGroupProperties or {}
   animationGroupProperties.unifiedData = unifiedData
   return FRC_AnimationManager.createAnimationClipGroup( { sourceFile }, animationXMLBase, animationImageBase, animationGroupProperties )
end

--
-- playAllAnimations() - Plays all of the character's animations (EFM needs work) 
--
function private.playAllAnimations( animationSequences, num, autoLoop )
   num = num or mRand(1,#animationSequences)
   local sequence = animationSequences[num]
   for i=1, sequence.numChildren do

      sequence[i]:play({
            showLastFrame = not(autoLoop),
            playBackward = false,
            autoLoop = autoLoop,
            palindromicLoop = false,
            delay = 30,
            intervalTime = 30,
            maxIterations = 1,
            --onCompletion = onCompletion,
            --stopGate = true -- Not transfered yet
         })
      --timer.performWithDelay(33, function() sequence[i]:pause() end )
   end
end

--
-- stopAllAnimations() - Stops all of the character's animations (EFM needs work) 
--
function private.stopAllAnimations( animationSequences, num )
   num = num or mRand(1,#animationSequences)
   local sequence = animationSequences[num]
   for i=1, sequence.numChildren do
      sequence[i]:stop()
      sequence[i]:play({
            showLastFrame = true,
            delay = 0,
            intervalTime = 0,
            maxIterations = 1,
         })
   end
end


--
-- getPartName() - Extract replacment part (art) name from this character type's JSON/Lua data.
--
function private.getPartName( costumeData, category, index )
   if( index == 1 )  then
      return "NONE"
   end
   return strGSub(costumeData.clothing[category][index-1].imageFile, ".png", "" )
end

--
-- getPartOffset() - Calculates part offsets based on replacement costume/part.
--
function private.getPartOffset( costumeData, category, index )
   if( index == 1 ) then 
      return { 0, 0 }
   end
   index = index - 1
   local b = costumeData.clothing[category][1]
   local t = costumeData.clothing[category][index]
   return { -b.xOffset + t.xOffset, -b.yOffset + t.yOffset }
end


--
-- highlightSelected() - Show selection effect for this object
--
function private.addSelectionIndicator( stagePiece )
   if( stagePiece.pieceType == "instrument" ) then
      stagePiece.indicator = stagePiece
      stagePiece.strokeWidth = (showTimeMode) and 0 or 6
      return 
   end
   local indicator = display.newRect( stagePiece, 0, 0, stagePiece.contentWidth * 1/characterScale + 40, stagePiece.contentHeight * 1/characterScale + 60 )
   indicator:setFillColor(0,0,0,0)
   indicator.strokeWidth = (showTimeMode) and 0 or 6
   indicator:toBack()
   stagePiece.indicator = indicator
end

--
-- highlightSelected() - Show selection effect for this object
--
function private.highlightSelected()
   for i = 1, stagePieces.numChildren do
      local stagePiece = stagePieces[i]
      stagePiece.indicator.strokeWidth = 0
      stagePiece.indicator.stroke.effect = nil
   end
   if( not currentStagePiece ) then return end
   currentStagePiece.indicator.strokeWidth = 6
   currentStagePiece.indicator.stroke.effect = "generator.marchingAnts"
end

--
-- doDrop() - Test for correct drop and combine pieces if rules are met.
--
function private.doDrop( dropPiece )   
   for i = 1, stagePieces.numChildren do
      local stagePiece = stagePieces[i]
      if( stagePiece ~= dropPiece ) then
         local dx = dropPiece.x - stagePiece.x
         local dy = dropPiece.y - stagePiece.y
         local dist2 = dx * dx + dy * dy
         if( dist2 <= snapDist and 
             dropPiece.pieceType ~= stagePiece.pieceType ) then
            
            instrumentsInUse[dropPiece.instrument] = nil
            instrumentsInUse[stagePiece.instrument] = nil
            
            if( dropPiece.pieceType == "instrument" ) then               
               public.placeNewCharacter(  stagePiece.x, stagePiece.y, stagePiece.characterID, dropPiece.instrument, stagePiece.danceNumber  ) 
               display.remove( dropPiece ) 
               display.remove( stagePiece ) 
         
            elseif( dropPiece.pieceType == "character" ) then
               public.placeNewCharacter(  stagePiece.x, stagePiece.y, dropPiece.characterID, stagePiece.instrument, dropPiece.danceNumber  ) 
               display.remove( dropPiece ) 
               display.remove( stagePiece ) 
            end  
            return
         end
      end         
   end   
end

--
-- replaceInstrument() - 
--
function private.replaceInstrument( target, instrument )
   if( instrumentsInUse[instrument] ) then return end
   
   if( target.pieceType == "instrument" ) then               
      instrumentsInUse[target.instrument] = nil      
      public.placeNewInstrument(  target.x, target.y, instrument  ) 
      display.remove( target )       

   elseif( target.pieceType == "character" ) then
      instrumentsInUse[target.instrument] = nil
      public.placeNewCharacter(  target.x, target.y, target.characterID, instrument, target.danceNumber  ) 
      display.remove( target ) 
   end  
end

--
-- replaceWithCharacter() - 
--
function private.replaceWithCharacter( target, characterID )
   
   if( target.pieceType == "instrument" ) then               
      instrumentsInUse[target.instrument] = nil
      public.placeNewCharacter(  target.x, target.y, characterID, target.instrument, target.danceNumber  ) 
      display.remove( target ) 

   elseif( target.pieceType == "character" ) then
      instrumentsInUse[target.instrument] = nil
      public.placeNewCharacter(  target.x, target.y, characterID, target.instrument, target.danceNumber  ) 
      display.remove( target ) 
   end  
end


--
-- attachTouchClear() - Adds a listener to clear the current selection when touching off of a character/instrument.
--
function private.attachTouchClear()
   function view.touch( self, event )
         --table.dump2(event)
         if( event.phase == "ended" ) then
            currentStagePiece = nil
            private.highlightSelected() 
         end
         return false
   end
   view:addEventListener("touch")
end


-- Easy Blur
--
private.easyBlur = function( group, time, color )
	group = group or display.getCurrentStage()
	time = time or 0
	color = color or {0.5,0.5,0.5}
	local blur = display.captureScreen()
	blur.x, blur.y = centerX, centerY
	blur:setFillColor(unpack(color))
	--blur.fill.effect = "filter.blur"
	blur.alpha = 0
	group:insert( blur )
	transition.to( blur, { alpha = 1, time = time } )
	return blur
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
-- EFM temporarily exposed for use in FRC_Reheasal_Scene.lua till we come up with a better plan.
public.easyAlert = private.easyAlert

-- ==
--    round(val, n) - Rounds a number to the nearest decimal places. (http://lua-users.org/wiki/FormattingNumbers)
--    val - The value to round.
--    n - Number of decimal places to round to.
-- ==
function private.round(val, n)
  if (n) then
    return math.floor( (val * 10^n) + 0.5) / (10^n)
  else
    return math.floor(val+0.5)
  end
end

function private.calcMeasurementSpacing(debugEn)
	private.w 				   = display.contentWidth
	private.h 				   = display.contentHeight
	private.centerX 			= display.contentCenterX
	private.centerY 			= display.contentCenterY
	private.fullw			   = display.actualContentWidth 
	private.fullh			   = display.actualContentHeight
	private.unusedWidth		= private.fullw - private.w
	private.unusedHeight		= private.fullh - private.h
	private.deviceWidth		= math.floor((private.fullw/display.contentScaleX) + 0.5)
	private.deviceHeight 	= math.floor((private.fullh/display.contentScaleY) + 0.5)
	private.left				= 0 - private.unusedWidth/2
	private.top 				= 0 - private.unusedHeight/2
	private.right 			   = private.w + private.unusedWidth/2
	private.bottom 			= private.h + private.unusedHeight/2


	private.w 				   = private.round(private.w)
	private.h 				   = private.round(private.h)
	private.left			   = private.round(private.left)
	private.top				   = private.round(private.top)
	private.right			   = private.round(private.right)
	private.bottom			   = private.round(private.bottom)
	private.fullw			   = private.round(private.fullw)
	private.fullh			   = private.round(private.fullh)

	private.orientation  	= ( private.w > private.h ) and "landscape"  or "portrait"
	private.isLandscape 		= ( private.w > private.h )
	private.isPortrait 		= ( private.h > private.w )

	private.left 			   = (private.left >= 0) and math.abs(private.left) or private.left
	private.top 				= (private.top >= 0) and math.abs(private.top) or private.top
	
	if( debugEn ) then
		dprint("\n---------- calcMeasurementSpacing() @ " .. system.getTimer() )	
		dprint( "w       = " 	.. private.w )
		dprint( "h       = " 	.. private.h )
		dprint( "centerX = " .. private.centerX )
		dprint( "centerY = " .. private.centerY )
		dprint( "fullw   = " 	.. private.fullw )
		dprint( "fullh   = " 	.. private.fullh )
		dprint( "left    = " 	.. private.left )
		dprint( "right   = " 	.. private.right )
		dprint( "top     = " 	.. private.top )
		dprint( "bottom  = " 	.. private.bottom )
		dprint("---------------\n\n")
	end
end
private.calcMeasurementSpacing(false)

return public

-- ======================================================================
-- Module Methods Index
--[[
      Public:
         EFM() - EFM
         EFM() - EFM
         EFM() - EFM
         EFM() - EFM
         EFM() - EFM
         EFM() - EFM
         EFM() - EFM
         EFM() - EFM
         EFM() - EFM
         EFM() - EFM


      Private:
         EFM() - EFM
         EFM() - EFM
         EFM() - EFM
         EFM() - EFM
         EFM() - EFM
         EFM() - EFM
         EFM() - EFM
         EFM() - EFM
         EFM() - EFM
         EFM() - EFM
--]]
-- ======================================================================

--[[

--
-- readXML() - Extracted XML reader (from animationManager) (EFM - Needs additional changes when I fix LUA bug)
--
function private.readXML( fileName, baseXMLDir )
   dprint( fileName, baseXMLDir )
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
            local appLUAFilename = strGSub( strGSub(baseXMLDir .. XMLLUAfilename, "/", "."), ".lua", "");
            rawLUAcode = require(appLUAFilename);
            xmltable = rawLUAcode; -- .xmltable;
         end
      else
         --dprint( "EDO 1", XMLfilepath )
         xmltable = FRC_AnimationManager.loadXMLData( XMLfilepath );
         if ( ON_SIMULATOR ) then
            dataToSave = table.serialize( "xmltable", xmltable, "" );
            newLuaFile, err = io.open(path,"w");
            newLuaFile:write( dataToSave );
            io.close(newLuaFile);
         end
      end
   else
      --dprint( "EDO 2", XMLfilepath )
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
--]]
