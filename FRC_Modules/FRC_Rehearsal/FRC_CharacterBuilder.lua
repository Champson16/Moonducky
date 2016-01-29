-- ======================================================================
-- FRC Character Builder -
-- ======================================================================
local public   = {} -- Public interface
local private  = {} -- Private inteface

local enableLagFix = true 

-- ======================================================================
-- Requires
-- ======================================================================
local ui                      = require('ui')
local FRC_DataLib             = require('FRC_Modules.FRC_DataLib.FRC_DataLib')
local FRC_Layout              = require('FRC_Modules.FRC_Layout.FRC_Layout')
local FRC_AnimationManager    = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager')
local FRC_SetDesign_Settings  = require('FRC_Modules.FRC_SetDesign.FRC_SetDesign_Settings')
local FRC_Rehearsal_Settings  = require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Settings')
local FRC_Util                = require('FRC_Modules.FRC_Util.FRC_Util')


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
-- Localizations (for speedup and ease of typing)
-- ======================================================================
local mRand       = math.random
local strLower    = string.lower
local strMatch    = string.match
local strGSub     = string.gsub

-- ======================================================================
-- Locals
-- ======================================================================
local	screenW, screenH, contentW, contentH, centerX, centerY = FRC_Layout.getScreenDimensions()

local lastDanceNum      = math.random(1,2)
local snapDist          = 100 ^ 2
local characterScale    = 0.5 -- Scale all placed characters and instruments by this much
local instrumentScale   = 0.35
local stagePieces
local view, currentSongID, animationXMLBase, animationImageBase, itemsScroller, categoriesContainer
local editingEnabled    = true
local screenW, screenH = FRC_Layout.getScreenDimensions()
local currentStagePiece
local instrumentsInUse


local setData = FRC_DataLib.readJSON(FRC_SetDesign_Settings.DATA.SETS, system.ResourceDirectory)

-- ********************************
-- EFM Following may be temporary (revist these locals):
-- ********************************
--EFM REMOVE local animalsNames         = { "Chicken", "Cat", "Dog", "Hamster", "Pig", "Sheep", "Goat" }
local instrumentNames      = { "Bass", "Conga", "Guitar", "Harmonica", "Maracas", "Microphone", "Piano", "Sticks", "RhythmComboCheeseGrater", "RhythmComboCymbal" }
local songTitles           = { hamsters = "Hamsters Want To Be Free", mechanicalcow  = "Mechanical Cow" }
local hamsterInstruments   = { "Bass", "Conga", "Guitar", "Harmonica", "Maracas", "Microphone", "Sticks", "RhythmComboCheeseGrater" }
local cowInstruments       = { "Bass", "Conga", "Guitar", "Harmonica", "Microphone", "Piano", "RhythmComboCymbal" }
local allInstruments       = { "Bass", "Conga", "Guitar", "Harmonica", "Maracas", "Microphone", "Piano", "Sticks", "RhythmComboCheeseGrater", "RhythmComboCymbal" }

local textBoxDefaultTitles = { "A Hard Act To Follow", "One Day At The Theatre", "Over The Moon", "Animal Band", "The Show of Shows", 
                               "A Tough Act To Follow", "Party Hat", "Sing With The Animals" }


-- ======================================================================
-- Public Method Definitions
-- ======================================================================

--
-- markDirty() - Mark Scene as dirty
--
function public.markDirty(isDirty)
   dprint("markDirty ", isDirty) 
   if( isDirty == nil ) then isDirty = true end
   public.isDirty = isDirty   
end

--
-- dirtyTest() - Mark Scene as dirty
--
function public.dirtyTest( cb )
   dprint("public.dirtyTest() ", public.isDirty )
   if( public.isDirty ) then
      FRC_Util.easyAlert( 'Exit?', 
         'If you exit, your unsaved progress will be lost.\nIf you want to save first, tap Cancel now and then use the Save feature.',
         { { "OK", cb }, {"Cancel", nil }, } )      
   else
      cb()
   end
end

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
   editingEnabled       = true
   instrumentNames      = { "Bass", "Conga", "Guitar", "Harmonica", "Maracas", "Microphone", "Piano", "Sticks", "RhythmComboCheeseGrater", "RhythmComboCymbal" }
   
   public.markDirty( false )
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
   editingEnabled       = true
   showTimeMode         = false
   
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
   params.view.setDesignGroup:insert( stagePieces )
   instrumentsInUse     = {}   
   private.attachTouchClear()
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
   Runtime:addEventListener( "enterFrame", group )

   local blur = FRC_Util.easyBlur( group, 500, { 0, 0.4, 0.4, 0.8 } ) --  time, color )
   blur.touch = function( self, event )
      return true
   end
   blur:addEventListener( "touch" )

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

   local titleQueryLabel2 = display.newText( group2, "Rehearse A New Show?", centerX, fromButton, native.systemFontBold, fontSize )
   titleQueryLabel2:setFillColor(0)

   --
   -- Create New Show With: 'Hamsters Want To Be Free'
   --
   local hamsterButton = display.newRoundedRect( group2, centerX, titleQueryLabel2.y + fromButton, screenW - 100, 80, 4 )
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
   local hamsterButtonTitle = display.newText( group2, '"Hamsters Want To Be Free"', hamsterButton.x, hamsterButton.y, "MoonDucky", fontSize2 )
   hamsterButtonTitle:setFillColor(0)

   --
   -- Create New Show With: 'Mechanical Cow'
   --
   local cowButton = display.newRoundedRect( group2, centerX, hamsterButton.y + 120, screenW - 100, 80, 4 )
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
   local cowButtonTitle = display.newText( group2, '"Mechanical Cow"', cowButton.x, cowButton.y,  "MoonDucky", fontSize2 )
   cowButtonTitle:setFillColor(0)

   local titleQueryLabel = display.newText( group2, "or", centerX, cowButton.y + 120, native.systemFontBold, fontSize )
   titleQueryLabel:setFillColor(0)

   --
   -- Load Existing Show
   --
   local loadButton = display.newRoundedRect( group2, centerX, titleQueryLabel.y + 120, screenW - 100, 80, 8 )   
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
   local loadButtonLabel = display.newText( group2, "Load An Existing Show", loadButton.x, loadButton.y, native.systemFontBold, fontSize2 )
   loadButtonLabel:setFillColor(0)

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
      titleQueryLabel2.text = "Choose a Song to Rehearse"      
   end

end

--
-- getCurtainPath() - Creat image path string for requested curtain.
--
function public.getCurtainPath( id )
   id = id or 1
   if( tonumber(id) == nil ) then
      id = 1
   end
   if( not id or id < 1 ) then id = 1 end
   return "FRC_Assets/FRC_SetDesign/Images/" .. setData[id].curtainFile
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
   Runtime:addEventListener( "enterFrame", group )

   local blur = FRC_Util.easyBlur( group, 500, { 0, 0.4, 0.4, 0.8 } ) --  time, color )
   blur.touch = function( self, event )
      return true
   end
   blur:addEventListener( "touch" )

   -- EFM Add temporary label for save
   local backH       = screenH/2 - 50
   local fontSize    = 60
   local fontSize2   = 20
   local titleLengthLimit = 35
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

   local textBox = native.newTextField( centerX, titleQueryBack.y, screenW - 80, fontSize + 36 )
   textBox.font = native.newFont( "OpenSans-Semibold", fontSize )
   local textBoxTitleIndex = mRand(1, #textBoxDefaultTitles)
   textBox.text = textBoxDefaultTitles[textBoxTitleIndex]
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
            native.setKeyboardFocus( nil ) -- TRS
            self.isFocus = false
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
function public.save(saveTable, publishingMode)
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

      if( not publishingMode ) then
         record.characterID      = stagePiece.characterID
      else
         if( type(  stagePiece.characterID ) == "table" ) then
            record.characterID = stagePiece.characterID
         else
            record.characterID   = private.getDressingRoomDataByID( stagePiece.characterID, 0 )
         end
      end
      record.publishingMode   = publishingMode
      savePieces[#savePieces+1] = record
   end
end


--
-- load() - Load and restore all stage elements (excluding stage backdrop which is handled in FRC_Rehearsal_Scene.)
--
function public.load(loadTable)
   public.cleanup()

   local restorePieces = loadTable.stagePieces or {}
   for i = 1, #restorePieces do
      local curPiece = restorePieces[i]
      if( curPiece.pieceType == "instrument" ) then
         public.placeNewInstrument( curPiece.x, curPiece.y, curPiece.instrument )

      elseif( curPiece.pieceType == "character" ) then
         public.placeNewCharacter(  curPiece.x, curPiece.y, curPiece.characterID, curPiece.instrument, 1 )
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
      public.placeNewCharacter(  currentStagePiece.x, currentStagePiece.y, currentStagePiece.characterID, nil, 1 ) -- currentStagePiece.danceNumber  )
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
      public.markDirty( true )
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
      FRC_Util.easyAlert( "Duplicate instrument",
         "Only one of each instrument can be placed.\n\n" .. instrumentName .. " is already on the stage.",
         { {"OK", nil} } )      
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
   
   public.markDirty( true )

   return stagePiece
end

--
-- placeNewCharacter() - Create a new character and place it on the stage.
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

   local animalType           = characterData.character
   danceNumber                = private.getNextDanceNum() -- danceNumber or mRand(1,2)

   if( instrumentName and string.match( string.lower(instrumentName), "dance" ) ) then
      instrumentName             = "Dance" .. danceNumber -- Assume all players as dancers
   else
      instrumentName             = instrumentName or ("Dance" .. danceNumber) -- Assume all players as dancers
   end
   local instrumentType       = private.instrumentNameMap(instrumentName)
   local costumeData          = private.getCostumeData( animalType )
   local xmlFiles             = private.getXMLFileNames( animalType )

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

   -- Only preclude re-use of instruments (not dancers)
   if( not strMatch( strLower( instrumentName ), "dance" ) ) then
      instrumentsInUse[instrumentName] = instrumentName
   end


   function stagePiece.destroy( self )
      instrumentsInUse[self.instrument] = nil
      
      local sequence = stagePiece.animationSequence
      for i = 1, sequence.numChildren do
         sequence[i]:stop()
      end      
   end

   -- Get all known parts for the selected instrument type within the previously selected character (animal) type
   local partsList, xmlTable = private.getPartsList( xmlFiles[instrumentType], animationXMLBase, false )
   
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
            --dprint( partName, partsList[j].name, partExcludeName ) 
            private.findAnimationParts( partsList, partName, partsList[j].name, partExcludeName, animationsToBuild, allParts[i][3] )
         end
      end
   end   

   --
   -- Adjust parts (costume names and offsets).
   --
   -- Note 1: Costume names are not applied till the moment animation manager prepares to build this animation.
   -- Note 2: Offset is used in this file after animation manager returns the new animation clip group.
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
   

   -- Copy the xml table, then trim it to just the parts we need to build this character
   --
   local xmlTable = table.deepCopy( xmlTable ) 
   local newPart = {}
   local part = xmlTable.Animation.Part
   
   for i = 1, #animationsToBuild do    
      local unifiedData = animationsToBuild[i]
      local partsList = unifiedData[2]
      for j = 1, #partsList do
         local aNewPart = table.deepCopy(part[partsList[j]])
         aNewPart.animationImageBase = unifiedData[3] 
         newPart[#newPart+1] = aNewPart
         if( unifiedData[4] ) then 
            aNewPart.name = string.gsub( string.lower(aNewPart.name), string.lower(unifiedData[4].fromPart), unifiedData[4].toPart )                  
         end
      end
   end
   xmlTable.Animation.Part = newPart   
   
   --
   --  Finally, build the character as a single clipgroup
   --
   local animGroup = display.newGroup()
   local xOffset = -(display.contentWidth/2)
   local yOffset = -(display.contentHeight/2)
   
   stagePiece.animationSequence = FRC_AnimationManager.createAnimationClipGroup( { xmlTable }, animationXMLBase, animationImageBase, 
      { unifiedData = { allParts = allParts, adjustments = adjustments } } )
   
   stagePiece.animationSequence.x = xOffset
   stagePiece.animationSequence.y = yOffset
   
   stagePiece:insert(stagePiece.animationSequence)   

   stagePiece:scale(characterScale,characterScale)
   private.attachDragger(stagePiece)
   
   local sequence = stagePiece.animationSequence   
   dprint( "sequence.numChildren == " ,  sequence.numChildren )   
   for i=1, sequence.numChildren do
      sequence[i]:play({
            showLastFrame     = true,
            playBackward      = false,
            autoLoop          = false,
            palindromicLoop   = false,
            delay             = 0,
            intervalTime      = 0, 
            maxIterations     = 1,
         })
   end   

   currentStagePiece = stagePiece

   private.addSelectionIndicator( stagePiece )

   private.highlightSelected()
   
   public.markDirty( true )
   
   --
   -- EFM - Debug meter to show what frame each animation clip is at relative to other clips
   --
   --FRC_Util.animMeter( sequence, stagePiece )
   
   
   --
   -- Lag Fix Code - Forces animation indexes to align every frame.
   --
   local firstChild = sequence[1]
   function firstChild.enterFrame( self )
      if( self.removeSelf == nil ) then
         Runtime:removeEventListener( "enterFrame", self )
         dprint("AUTO STOP ENTERFRAME")
         return
      end
      
      -- First child forces all frames to align
      local maxFrame = 0
      for k = 1, sequence.numChildren do
         local idx = sequence[k].currentIndex
         maxFrame = (idx > maxFrame) and idx or maxFrame
      end
      for k = 1, sequence.numChildren do
         sequence[k].currentIndex = maxFrame
      end
   end
   Runtime:addEventListener( "enterFrame", firstChild )
   
   return stagePiece   
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

   local instrumentData = DATA('INSTRUMENT')
   local songID = strGSub(songTitles[currentSongID], " ", "")

   local songInstruments = instrumentData[1]
   for i = 1, #instrumentData do
      if( instrumentData[i].id == songID ) then         
         songInstruments = instrumentData[i]
      end
   end

   local scroller = itemScrollers.Instrument

   -- Destroy OLD scroller content
   while( scroller.content.numChildren > 0 ) do
      display.remove( scroller.content[1] )
   end

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

   -- for now, just grab the first song's instrument list
   songInstruments = songInstruments.instruments
   for i=1,#songInstruments do
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
   local button = require('ui.button')
   local scroller = itemScrollers.Costume

   -- Destroy OLD scroller content
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
   local curChar = { id = "none" }
   local buttonScale = 0.96
   local filePath = "FRC_Assets/FRC_Rehearsal/Images/FRC_Rehearsal_Scroller_None.png"

   local button
   button = ui.button.new({
         id = curChar.id,
         imageUp = filePath,
         imageDown = filePath,
         imageFocused = filePath,
         imageDisabled = filePath,
         width = 100 * buttonScale,
         height = 63 * buttonScale,
         parentScrollContainer = scroller,
         pressAlpha = 0.5,
         --baseDirectory = system.DocumentsDirectory,
         onRelease = function(e)
            local self = e.target
            private.scrollerCostumeTouch( curChar )
            return true
         end
      })
   button.data = curChar
   button.x = x - 8
   scroller:insert(button)


   --
   -- 'Mystery Box' Button
   --
   if( #characters > 1 ) then
      x = x + button_spacing
      local curChar = { id = "mysterybox", character = currentCharacterType, characters = characters }
      local buttonScale = 0.2 * FRC_Layout.getScaleFactor()
      local filePath = "FRC_Assets/FRC_Rehearsal/Images/MDMT_Rehearsal_Scroller_MysteryBox.png"

      local button
      button = ui.button.new({
            id = curChar.id,
            imageUp = filePath,
            imageDown = filePath,
            imageFocused = filePath,
            imageDisabled = filePath,
            width = 338 * buttonScale,
            height = 256 * buttonScale,
            parentScrollContainer = scroller,
            pressAlpha = 0.5,
            --baseDirectory = system.DocumentsDirectory,
            onRelease = function(e)
               local self = e.target
               private.scrollerCostumeTouch( curChar )
               return true
            end
         })
      button.data = curChar
      button.x = x
      scroller:insert(button)
   end

   --
   -- 'No Costume' Button
   --
   x = x + button_spacing
   local curChar = { id = "nocostume", character = currentCharacterType, categories = { Headwear = 1,  LowerTorso = 1, Neckwear = 1, UpperTorso = 1, Eyewear = 1 } }
   local buttonScale = 0.42 * FRC_Layout.getScaleFactor()
   local filePath = "FRC_Assets/FRC_Rehearsal/Images/MDMT_Rehearsal_global_BaseCharacter_" .. currentCharacterType .. "_thumbnail.png"

   local button
   button = ui.button.new({
         id = curChar.id,
         imageUp = filePath,
         imageDown = filePath,
         imageFocused = filePath,
         imageDisabled = filePath,
         width = 109 * buttonScale,
         height = 192 * buttonScale,
         parentScrollContainer = scroller,
         pressAlpha = 0.5,
         --baseDirectory = system.DocumentsDirectory,
         onRelease = function(e)
            local self = e.target
            private.scrollerCostumeTouch( curChar )
            return true
         end
      })
   button.data = curChar
   button.x = x
   scroller:insert(button)


   --
   -- Costume Thumbnails
   --
   for i = 1, #characters do
      x = x + button_spacing
      local curChar = characters[i]
      local buttonScale = 0.50 * FRC_Layout.getScaleFactor()
      local filePath = curChar.id .. curChar.thumbSuffix

      local button
      button = ui.button.new({
            id = curChar.id,
            imageUp = filePath,
            imageDown = filePath,
            imageFocused = filePath,
            imageDisabled = filePath,
            width = curChar.thumbWidth * buttonScale,
            height = curChar.thumbHeight * buttonScale,
            parentScrollContainer = scroller,
            pressAlpha = 0.5,
            baseDirectory = system.DocumentsDirectory,
            onRelease = function(e)
               local self = e.target
               private.scrollerCostumeTouch( curChar )
               return true
            end
         })
      button.data = curChar
      button.x = x
      scroller:insert(button)
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
-- setEditEnable( enable ) - Allows us to enable and disable editing temporarily.
--
function public.setEditEnable( enable )
   if (enable == nil) then enable = false end
   editingEnabled = (enable)
   if( not editingEnabled ) then
      currentStagePiece = nil
      private.highlightSelected()
   end
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
   --dprint("getCharactersOnStage()", stagePieces.numChildren )
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
function public.playStageCharacters( instrumentTrackStartOffsets, expectedEndTime )
   local charactersOnStage = public.getCharactersOnStage()

   for i = 1, #charactersOnStage do
      local animationSequence = charactersOnStage[i].animationSequence

      local myInstrument = string.lower(charactersOnStage[i].instrument)
      local instrumentOffset = 30 -- default start offset for no instrument
      local instrumentEndTime = math.huge -- Dancers never stop dancing! Woohoo!
      for k,v in pairs(instrumentTrackStartOffsets) do
         if( string.match( k, myInstrument ) ) then
            instrumentOffset  = tonumber(v.startOffset)
            instrumentEndTime = tonumber(v.trackEndTime)
         end
      end
     
      local params = { intervalTime       = math.random( 30, 40 ),
                       iterations         = math.random( 1, 3 ),
                       instrumentOffset   = instrumentOffset,
                       instrumentEndTime  = instrumentEndTime,
                       isFirstCall        = true,
                       showEndTime        = expectedEndTime}

      local startTime = system.getTimer()
      private.playAllAnimations( animationSequence, params ) -- PING PONG
      local endTime = system.getTimer()
   end
end

--
-- stopStageCharacters() - Make all characters on stage stop playing.
--

function public.stopStageCharacters()   
   local charactersOnStage = public.getCharactersOnStage()

   for i = 1, #charactersOnStage do
      local animationSequence = charactersOnStage[i].animationSequence
      private.stopAllAnimations( animationSequence )
   end
end

if( edmode ) then
   local function onKey( event )
      local storyboard = require("storyboard")
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
         FRC_Util.easyAlert( "No saved costumes",
            "No characters/costumes saved, can't search for this animal type: " ..
            tostring(characterType) .. "\n\n Please go save some costumes first.",
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
         FRC_Util.easyAlert( "No saved costumes",
            "No characters/costumes saved for this animal type: " ..
            tostring(characterType) .. "\n\n Please go save some costumes first.",
            { {"OK", nil} } )
      end
   end
   if( debugLevel and debugLevel > 1 ) then
      table.print_r(characters)
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
         FRC_Util.easyAlert( "No saved costumes",
            "No characters/costumes saved, can't search for this id: " ..
            tostring(id) .. "\n\n Please go save some costumes first.",
            { {"OK", nil} } )
      end
      return nil
   end
   local savedItems = allSaved.savedItems
   for i = 1, #savedItems do
      local current = savedItems[i]
      if( current.id == id ) then
         --dprint("Found character by ID: ", id )
         return current
      end
   end

   if( debugLevel and debugLevel > 0 ) then
      FRC_Util.easyAlert( "Unknown Dressing Room ID",
         "No characters/costumes found matching this ID: " .. tostring(characterType),
         { {"OK", nil} } )
   end

   return nil
end

--
-- EFM() - EFM
--
function private.getCostumeData( animalType )
   local FRC_DressingRoom_Settings = require('FRC_Modules.FRC_DressingRoom.FRC_DressingRoom_Settings')
   local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib')
   local function DATA(key, baseDir)
      baseDir = baseDir or system.ResourceDirectory
      return FRC_DataLib.readJSON(FRC_DressingRoom_Settings.DATA[key], baseDir)
   end
   local characterData = DATA('CHARACTER')

   local costumeData
   for i=1,#characterData do
      if( characterData[i].id == animalType ) then
         costumeData = characterData[i]
         break
      end
   end
   if (not costumeData) then
      FRC_Util.easyAlert( "No character data found",
         tostring( animalType ) .. " had no data?",
         { {"OK", nil} } )
   end
   return costumeData
end


--
-- Scroller Costume Touch Handler
--
function private.scrollerCostumeTouch( data )
   if( currentStagePiece ) then
      if( currentStagePiece.pieceType == "instrument" ) then -- MODIFYING INSTRUMENT
         if( data.id == "none" ) then
            -- Do nothing
         elseif( data.id == "nocostume" ) then
            private.replaceWithCharacter( currentStagePiece, data )

         elseif( data.id == "mysterybox" ) then
            local character = data.characters[mRand(1,#data.characters)]
            private.replaceWithCharacter( currentStagePiece, character.id )

         else
            private.replaceWithCharacter( currentStagePiece, data.id )
         end

      else -- MODIFYING CHARACTER
         if( data.id == "none" ) then
            -- Remove character
            instrumentsInUse[currentStagePiece.instrument] = nil
            display.remove(currentStagePiece)
            currentStagePiece = nil
            private.highlightSelected()

         elseif( data.id == "nocostume" ) then
            private.replaceWithCharacter( currentStagePiece, data )

         elseif( data.id == "mysterybox" ) then
            local character = data.characters[mRand(1,#data.characters)]
            private.replaceWithCharacter( currentStagePiece, character.id )

         else
            private.replaceWithCharacter( currentStagePiece, data.id)
         end
      end

   else -- CREATING CHARACTER
      if( data.id == "none" ) then
         -- Do nothing
      elseif( data.id == "nocostume" ) then
         public.placeNewCharacter( nil, nil, data )

      elseif( data.id == "mysterybox" ) then
         local character = data.characters[mRand(1,#data.characters)]
         public.placeNewCharacter( nil, nil, character.id)         
      else
         public.placeNewCharacter( nil, nil, data.id)
      end
   end

   return false
end

--
-- Common Drag & Drop Handler
--
function private.attachDragger( obj )
   if( showTimeMode ) then
      return
   end   
   obj.touch = private.dragNDrop
   obj:addEventListener( "touch" )
end
function private.dragNDrop( self, event )
   if( not editingEnabled ) then
      return
   end
   
   public.markDirty( true )
   
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

      -- EFM - content width not working on animations?
      --local myLeft = self.x - self.contentWidth/2
      --local myRight = self.x + self.contentWidth/2
      local myLeft = self.x - 70
      local myRight = self.x + 70

      if( (dx < 0 and myLeft > private.left) or
         (dx > 0 and myRight < private.right ) ) then
         self.x = self.x + dx * (self.dragScale and self.dragScale or 1)
      end

      -- EFM - content height not working on animations?
      --local myTop = self.y - self.contentHeight/2
      --local myBottom = self.y + self.contentHeight/2
      local myTop = self.y - 120
      local myBottom = self.y + 120
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

      end
   end
   return true
end


-- EFM Candidate for data driven update ==>
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
         --{ "Instrument_RhythmComboCheeseGrater", "", animationImageBase },
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

--
-- getPartsList() - Get the parts list for this unified animation file (so we can parse and manipulate it).
--
function private.getPartsList( sourceFile, animationXMLBase, debugEn )
   --dprint( sourceFile, animationXMLBase, debugEn )
   local xmltable = FRC_AnimationManager.loadAnimationDataUnified( sourceFile, animationXMLBase  )
   local partsList = xmltable.Animation.Part
   if( debugEn == true ) then
      for i = 1, #partsList do
         dprint( "partsList[" .. i .. "] ", partsList[i].name, animationImageBase )
      end
   end
   return partsList, xmltable
end

--
-- findAnimationParts() - Find a specific animation in a unified animation export by name (with optional 'exclusion' match for names that match a sub-name in another animation)
--
function private.findAnimationParts( parts, partSubName, partExactName, partExcludeName, toTable, animationImageBase )
   local subParts = {}
   for i = 1, #parts do      
      if( partExcludeName and string.len(partExcludeName) > 0 ) then
         if( strMatch( parts[i].name, partExactName ) and            
            strMatch( parts[i].name, partExcludeName ) == nil ) then
            if( string.match( partSubName, "Instrument") ) then
            end
            subParts[#subParts+1] = i
         end
      else
         if( strMatch( parts[i].name, partExactName ) ) then
            if( string.match( partSubName, "Instrument") ) then
            end
            subParts[#subParts+1] = i
         end
      end
   end
   if(toTable and #subParts > 0) then
      toTable[#toTable+1] = { partSubName, subParts, animationImageBase }      
   end
   return subParts
end
function private.findAnimationParts_orig( parts, partSubName, partExcludeName, toTable, animationImageBase )
   local subParts = {}
   for i = 1, #parts do
      if( partExcludeName and string.len(partExcludeName) > 0 ) then
         if( strMatch( parts[i].name, partSubName ) and            
            strMatch( parts[i].name, partExcludeName ) == nil ) then
            --dprint("edochi a", i, parts[i].name )
            subParts[#subParts+1] = i
         end
      else
         if( strMatch( parts[i].name, partSubName ) ) then
            --dprint("edochi b", i, parts[i].name )
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
-- playAllAnimations() - Plays all of the character's animations
--
function private.playAllAnimations( animationSequence, params )
   local sequence                = animationSequence
   local totalClips              = sequence.numChildren
   animationSequence.completed   = {}
   local completed               = animationSequence.completed
   local framePeriod             = math.ceil(1000 / display.fps)
   
   -- Determine when this animation should stop
   if( params.isFirstCall ) then
      sequence._startedPlayingAt = system.getTimer()
      local stopTime = params.instrumentEndTime
      -- Dancers don't have a stop time, so just make it the end of ths show
      if( stopTime > params.showEndTime ) then
         stopTime = params.showEndTime
      end
      sequence._playDuration = stopTime
   end   

   -- play the clips
   for i=1, totalClips do
      completed[i] = false      
      local obj = sequence[i]

      local function onCompletionGate()
         completed[i] = true         
         if(obj.removeSelf == nil or obj.stop == nil) then return end
         
         obj:stop(obj.frameCount)
         
         local executeOnComplete = true
         for j = 1, #completed do
            executeOnComplete = executeOnComplete and completed[j]
         end

         local curTime     = system.getTimer()
         local dt          = curTime - sequence._startedPlayingAt
         local remaining   = sequence._playDuration - dt     
         
         local minTime = 500
         local maxTime = 4500
         local earlyQuitTime = maxTime/2
         
         local minIter = 1
         local maxIter = 3

         if( remaining < earlyQuitTime ) then
            dprint("SKIPPING RESTART ANIMATION" )
            return
         end
         
         if( remaining < maxTime ) then
            minIter = 1
            maxIter = 1
            minTime = (remaining - 30) / 2
            maxTime = remaining - minTime
            if( maxTime < minTime ) then
               maxTime = minTime
            end                        
            dprint("ADJUSTING LAST PLAY TIME TO BE CLOSER TO ACTUAL END TIME...", minTime, maxTime, minIter, maxIter )
         end

         if( remaining < (10 * maxTime) ) then
            minIter = 1
            maxIter = 1
            dprint("ADJUSTING ITERATIONS TOO CLOSE TO ACTUAL END TIME...", minTime, maxTime, minIter, maxIter )
         end


         if( executeOnComplete ) then             
            timer.performWithDelay( framePeriod * 2,
               function()
               local params2 =  { intervalTime        = params.intervalTime,
                                  iterations          = math.random( minIter, maxIter ),
                                  instrumentOffset    = math.random( minTime, maxTime ),
                                  instrumentEndTime   = params.instrumentEndTime}
               local startTime = system.getTimer()
               dprint("RESTART ANIMATION ", i, sequence, obj, system.getTimer() )
               if(sequence.removeSelf == nil) then return end
               private.playAllAnimations( animationSequence, params2 )               
            end )
         end
      end
      
      obj:play({
            showLastFrame     = not(autoLoop),
            playBackward      = false,
            autoLoop          = false, 
            palindromicLoop   = false,
            delay             = params.instrumentOffset,
            intervalTime      = params.intervalTime, --30, -- EFM TEARING FIX? SOURCE?
            maxIterations     = params.iterations, -- 1
            onCompletion      = onCompletionGate,
            stopGate          = true
         })
   end
end



--
-- Tested alternate method using 'pause' and 'resume' -- It didn't work great and eventually desynchronized
--
function private.playAllAnimations_pause( animationSequence, params )
   local sequence    = animationSequence
   local totalClips  = sequence.numChildren
   local framePeriod = math.ceil(1000 / display.fps)
   
   for i=1, totalClips do
      local obj = sequence[i]
      obj:play({
            showLastFrame     = false,
            playBackward      = false,
            autoLoop          = false, 
            palindromicLoop   = false,
            delay             = params.instrumentOffset,
            intervalTime      = 30, --, params.intervalTime, --30, -- EFM TEARING FIX? SOURCE?
            maxIterations     = 10000, --params.iterations, -- 1            
         })
      obj.__paused = false
   end
   
   -- Determine when this animation should stop
   sequence._startedPlayingAt = system.getTimer()
   local stopTime = params.instrumentEndTime
   -- Dancers don't have a stop time, so just make it the end of ths show
   if( stopTime > params.showEndTime ) then
      stopTime = params.showEndTime
   end
   sequence._playDuration = stopTime
   
   -- Clear any existing timer on this object      
   if( sequence.__myLastTimer ) then 
      timer.cancel( sequence.__myLastTimer )
      sequence.__myLastTimer = nil
   end
   
   -- Mark sequence as 'running' (not paused)   
   sequence.__isPaused = false
   
   -- Set a timer to pause/resume at random intervals till we need to stop
   sequence.timer = function( self )
      if( self.removeSelf == nil ) then
         self.__myLastTimer = nil         
         return
      end
      
      local curTime = system.getTimer()
      local dt             = curTime - sequence._startedPlayingAt
      local remainingTime  = sequence._playDuration - dt      
      local chance         = math.random(1,100)
      local nextTime       = math.random(1000,2000)      
      
      if(remainingTime < 1000) then 
         return 
      end      
      if( sequence.__isPaused ) then         
         for i=1, totalClips do
            local obj            = sequence[i]
            obj:resume()
         end
         sequence.__isPaused = false         
      
      elseif( chance > 66 ) then      
         for i=1, totalClips do
            local obj = sequence[i]
            obj:pause()
         end
         sequence.__isPaused = true
      end
      sequence.__myLastTimer = timer.performWithDelay( nextTime, sequence )
   end
   sequence.__myLastTimer = timer.performWithDelay( params.instrumentOffset + math.random(2000,4000), sequence )
end

--
-- stopAllAnimations() - Stops all of the character's animations (EFM needs work)
--
function private.stopAllAnimations( animationSequence )
   local sequence = animationSequence
   for i=1, sequence.numChildren do
      sequence[i]:stop()
      sequence[i]:play({
            showLastFrame  = true,
            delay          = 0,
            intervalTime   = 0,
            maxIterations  = 1,
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
               public.placeNewCharacter(  stagePiece.x, stagePiece.y, stagePiece.characterID, dropPiece.instrument, 1 ) --stagePiece.danceNumber  )
               display.remove( dropPiece )
               display.remove( stagePiece )

            elseif( dropPiece.pieceType == "character" ) then
               public.placeNewCharacter(  stagePiece.x, stagePiece.y, dropPiece.characterID, stagePiece.instrument, 1 ) --dropPiece.danceNumber  )
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
      public.placeNewCharacter(  target.x, target.y, target.characterID, instrument, 1 ) -- target.danceNumber  )
      display.remove( target )
   end
end

--
-- replaceWithCharacter() -
--
function private.replaceWithCharacter( target, characterID )

   if( target.pieceType == "instrument" ) then
      instrumentsInUse[target.instrument] = nil
      public.placeNewCharacter(  target.x, target.y, characterID, target.instrument, 1 ) -- target.danceNumber  )
      display.remove( target )

   elseif( target.pieceType == "character" ) then
      instrumentsInUse[target.instrument] = nil
      public.placeNewCharacter(  target.x, target.y, characterID, target.instrument, 1 ) -- target.danceNumber  )
      display.remove( target )
   end
end


--
-- attachTouchClear() - Adds a listener to clear the current selection when touching off of a character/instrument.
--
function private.attachTouchClear()
   function view.touch( self, event )
      if( event.phase == "ended" ) then
         currentStagePiece = nil
         private.highlightSelected()
      end
      return false
   end
   view:addEventListener("touch")
end

--
-- getNextDanceNum() - Alternate dance numbers instead of relying on random.
--
function private.getNextDanceNum()
   --dprint("getNextDanceNum()", lastDanceNum )
   lastDanceNum = lastDanceNum + 1
   if(lastDanceNum > 2 ) then
      lastDanceNum = 1
   end
   return lastDanceNum
end


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
