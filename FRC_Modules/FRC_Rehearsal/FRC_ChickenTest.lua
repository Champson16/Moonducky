local FRC_AnimationManager    = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager')
local FRC_Rehearsal_Tools = require("FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Tools")

local public = {}
local private = {}

function public.create( view, screenW, screenH, FRC_Layout, bg, animationXMLBase, animationImageBase ) 
   local showToggles = false
   local showRadioMenu = false
   local autoRun = false
   local testGroup = display.newGroup()
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
      button.isVisible = showRadioMenu
      button.label.isVisible = showRadioMenu
      radioButtons[i] = button
      button.touch = function(self,event)
         if(event.phase == "ended") then
            for j = 1, #radioButtons do
               radioButtons[j]:setFillColor(0.75, 0.75, 0.75)
               radioButtons[j]:setStrokeColor(1,0,0)
            end
            self:setFillColor(1)
            self:setStrokeColor(0,1,0)
            public.showIntrumentSample(i)            
         end
         return true
      end
      button:addEventListener("touch")
      curY = curY + height
   end


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
      timer.performWithDelay( 0,
         function()
            for i = 1, #animationSequences do
               FRC_Rehearsal_Tools.playUnifiedAnimations( animationSequences, i )
            end
         end )

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
            return true
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
   if( autoRun ) then
      radioButtons[1].touch( radioButtons[1], { phase = "ended" } )
   end
end

return public
