-- FRC_AnimationManager
-- FRC_AnimationManager.getAnimationData
---- transforms a Lua table containing data from Flash, preloads required bitmap assets
-- FRC_AnimationManager.createAnimationClip
---- transforms animation data into a playable animation clip
---- animationClip:showFrame()
---- animationClip:play(options)
------ options:
-- noLoop:boolean (false means do whatever maxIterations says, otherwise play once)
-- delay:milliseconds before animation starts
-- startFrame:integer starting frame
-- maxIterations: nil or -1 means loop forever, >0 means loop that many times (unless noLoop = true which sets maxIterations = 1)
-- showLastFrame:boolean (false means call dispose() when the animation is over so it goes away, otherwise leave the last frame visible at the end)
-- showFirstFrame:boolean (true means call show() when the animation is about to play, even if there's a delay specified so that the first frame of the animation is shown ASAP)
---- animationClip:stop(showLastFrame)
---- animationClip:dispose()
-- pause()
-- resume()
-- show()
-- hide()

-- TODO:
-- orchestration logic

-- media tracks
-- TEXT
-- BGMUSIC
-- VO
-- BGANIM (Basically an ANIMATION SEQUENCE)
-- ANIMATION SEQUENCES (unlimited)
-- VOFX
-- SFX (up to 20 or so)

-- Master tracks:
-- VO
-- ANIMATION SEQUENCE
-- all other tracks are slaved to either the START, END or DELAY FROM START of a Master Track

-- model of Scene 1 timeline

-- START ANIMSEQ (BGANIM)
-- DELAY FROM START BGANIM nn ms:  START AMBIENT BIRDS BGMUSIC (which plays naturally)
-- END OF BGANIM:  START VO
-- START OF VO:  START VO TEXT
-- DELAY FROM START VO:  START SUNSHINE AMBIENT BGMUSIC
-- DELAY FROM START VO:  START CHARLIE BARK SFX
-- END OF VO:  START VO
-- START OF VO:  START VO TEXT, START DREAMY BGMUSIC, START DREAM BUBBLE ANIMATION, START DREAM BUBBLE SFX
-- DELAY FROM START VO:  START DOGS PLAYING BALL SFX




local FRC_AnimationManager = {};

-- Uncomment line below to remove all print statements for this module
-- local function print() return; end

-- this is only needed if you want to call table.dump to inspect a table during debugging
local FRC_Util = require('FRC_Modules.FRC_Util.FRC_Util');

-- dependencies
local xmlapi = require( "FRC_Modules.FRC_XML.FRC_XMLParser" ).new();

-- PUBLIC functions

-- this function processes an XML filename and loads the XML data into a Lua table
FRC_AnimationManager.loadXMLData = function(inputFile, baseDir)
   -- DEBUG:
   -- print("FRC_AnimationManager.loadXMLData : ", inputFile, " - ", baseDir);
   local xmlDataTable = xmlapi:loadFile( inputFile, baseDir );
   if not xmlDataTable then print("ERROR: XML animation data was not successfully converted into a table: ", inputFile, " - ", baseDir); end
   -- reduce the raw Animation.XML to a Lua table
   local xmltable = xmlapi:simplify( xmlDataTable );
   return xmltable;
end

--
-- loadAnimationData() 
--
-- This function will load an existing LUA file containing the animation data for 
-- the existing XML file.  If it cannot find a LUA equivalent, it will read the XML source
-- and save a LUA file to the documents folder.
--
function FRC_AnimationManager.loadAnimationData( fileName, baseXMLDir )
   --dprint( "-------------------------------------", fileName, baseXMLDir )
   --
   -- 1. Try to find and load an existing lua table version of XML file
   --   
   fileName = string.gsub( fileName, "%.xml", "" )
   local luaPath = string.gsub( baseXMLDir .. fileName, "%/", "." )
   local luaFileExists = pcall( require, luaPath )
   if( luaFileExists ) then   
      local retVal = require( luaPath )
      return retVal
   end

   --
   -- 2. Failing that, read the XML file, save a lua file to the DocumentsDirectory and return xml table.
   --   
   local xmlPath  = baseXMLDir .. fileName .. ".xml"
   fileName = fileName .. ".lua"
   xmltable = FRC_AnimationManager.loadXMLData( xmlPath, system.ResourceDirectory );     
   local tmp = table.serialize( "xmltable", xmltable, "" );
   io.writeFile( tmp, fileName  )   

   return xmltable
end
--EFM This method is being used exclusively for unified XML files because the serialization processing failing for large tables.  Not sure why
local unifiedCache = {}
function FRC_AnimationManager.loadAnimationDataUnified( fileName, baseXMLDir )
   --dprint( "-------------------------------------", fileName, baseXMLDir )

   --
   -- 0. Speedup code till we figure out serialization (load from 'disk' first time; get from memory next time)
   --
   if( unifiedCache[baseXMLDir..fileName] ) then
      --return table.deepcopy(unifiedCache[baseXMLDir..fileName])
      return unifiedCache[baseXMLDir..fileName]
   end

   --
   -- 1. Try to find and load an existing lua table version of XML file
   --   
   fileName = string.gsub( fileName, "%.xml", "" )
   local jsonPath = baseXMLDir .. fileName .. ".xjson" 
   local xmltable = table.load( jsonPath, system.ResourceDirectory )   
   if( xmltable ) then      
      unifiedCache[baseXMLDir..fileName] = xmltable
      return xmltable
   end

   --
   -- 2. Failing that, read the XML file, save a lua file to the DocumentsDirectory and return xml table.
   --   
   local xmlPath  = baseXMLDir .. fileName .. ".xml"
   xmltable = FRC_AnimationManager.loadXMLData( xmlPath, system.ResourceDirectory );   
   --local xmltable = FRC_AnimationManager.loadXMLData( fileName .. ".xml", baseXMLDir );
   table.save( xmltable, fileName  .. ".xjson" ) 
   unifiedCache[baseXMLDir..fileName] = xmltable   
   return xmltable
end


-- this function processes a Lua table of XML animation data from Flash into
-- a table that we can use with createAnimationClip in Corona
FRC_AnimationManager.getAnimationData = function(xmltable, baseImageDir)

   if not baseImageDir then
      baseImageDir = system.ResourceDirectory
   end
   -- local path = system.pathForFile( xmlFilename, baseImageDir )

   -- moved to .loadXMLData call above
   -- local xmltable = xmlapi:simplify( xmlDataTable );

   -- setup the table to store the transformed data
   local newtable = {};
   -- intended format of newtable
   -- { #id : str, #frameCount : nn, #frameData :
   -- index value based array of
   -- { #part : string, #x : nn, #y : nn, #scaleX : nn, #scaleY : nn, #rotation : nn}
   -- }
   -- }

   -- get the animation ID (from the data, not the file)
   newtable.id = xmltable.Animation.name;
   -- DEBUG:
   -- print("id", newtable.id);
   -- get the total number of frames
   newtable.frameCount = xmltable.Animation.frameCount;

   -- now organize the animation data
   local frameData = {};
   -- count the number of Part elements
   local p = xmltable.Animation.Part;
   local partList = {};
   local partListData = {};
   local pc = #p;
   local singlePartParsing = false; 
   -- DEBUG:
   -- print("There are ", pc, "parts in this animation");
   -- if there is only one Part in the table structure, for some reason I don't understand,
   -- Corona returns a 0 for the expression #xmltable.Animation.Part
   -- KLUDGE: so, we will implement a workaround
   -- DEBUG:
   -- print(pc);
   -- print("Part table is type: ", type(p));
   if (pc == 0 and type(p) == "table") then
      pc = 1;
      singlePartParsing = true;
      -- dumptable(xmltable.Animation.Part);
      -- dumptable(p);
      -- dumptable(xmltable.Animation.Part.name);
      -- dumptable(p[1].name);
   end
   -- loop through each and build an array based on index
   for i=1, pc do
      -- deconstruct and transform the incoming data into our new frameData structure
      -- { #part : string, #x : nn, #y : nn, #scaleX : nn, #scaleY : nn, #rotation : nn}
      -- get the part name
      local pn;
      if (singlePartParsing == true) then
         pn = xmltable.Animation.Part.name;
      else
         pn = p[i].name;
         --table.dump2(p[i])
         baseImageDir = p[i].animationImageBase or baseImageDir -- EFM Unified clip groups can have alternate paths 
      end
      -- DEBUG:
      -- print("PARSING PART: ", pn);
      partList[i] = pn;
      -- load the part so we can get its height and width
      -- TODO:  replace this with a dictionary OR code that can read the width and height of a PNG/JPG image (google:  Corona PNGLib)
      -- TODO:  Put test code in to call assert if an image is missing!
      --table.dump2( partList )
      --dprint("FRC_AnimationManager.getAnimationData() newImage =>", baseImageDir, pn ) -- EFM 
      local refImage = display.newImage(baseImageDir .. pn .. ".png", true); 
      -- ERRORCHECK:
      assert(refImage, "ERROR: Missing media file: ", baseImageDir .. pn .. ".png");
      local h = refImage.height;
      local w = refImage.width;
      -- DEBUG:
      -- print("Loading image: ", baseImageDir .. pn .. ".png with h,w: " .. h .."/".. w);
      local hwtable = {};
      hwtable.h = h;
      hwtable.w = w;
      -- preload the dynamic part and store it in the table
      hwtable.refImage = display.newImageRect(baseImageDir .. pn .. ".png", w, h);
      -- now that we've stored the image width and height, destroy the evidence
      -- TODO:  could we cache this object instead so we can use it later with the animation sequence?  we have effectively preloaded the image
      refImage:removeSelf();
      refImage = nil;
      -- hwtable.refImage.anchorX = 0.5;
      -- hwtable.refImage.anchorY = 0.5;
      -- hwtable.refImage.x = display.contentCenterX;
      -- hwtable.refImage.y = display.contentCenterY;
      -- hide the image
      hwtable.refImage.isVisible = false;
      -- store it's id
      hwtable.refImage.id = pn;
      -- remove it from the display list
      -- add the new part list data to the table
      partListData[pn] = hwtable;
      -- now loop through the part data
      local ft;
      if (singlePartParsing == true) then
         ft = xmltable.Animation.Part.Frame;
      else         
         ft = xmltable.Animation.Part[i].Frame;
      end
      -- DEBUG:
      -- print("PARSING PART FRAME DATA");
      -- make sure there are frames for this part
      if (ft) then
         -- loop through all of the animation frames and store the translated data into our animation table
         for j=1, #ft do
            local fi = tonumber(ft[j].index)+1; -- we need to increment from 0-based (Flash export to XML) to 1-based

            -- grab the frame's data from the table
            local x = ft[j].x;
            local y = ft[j].y;
            local scaleX = ft[j].scaleX;
            local scaleY = ft[j].scaleY;
            local rot = ft[j].rotation;
            local a = ft[j].alpha;
            -- only store the data we need
            local fd = {};
            -- add the part name (required)
            fd.part = pn;
            -- add the index (for debugging)
            fd.index = fi;
            -- add x and y (required)
            fd.x = x;
            fd.y = y;
            -- add scaleX and scaleY (optional)
            -- in Flash, these properties are called scaleX and scaleY
            -- in Corona, these properties are called xScale and yScale
            if (scaleX) then fd.xScale = scaleX; end
            if (scaleY) then fd.yScale = scaleY; end
            -- add rotation (optional)
            if (rot) then fd.rotation = rot; end
            -- add alpha (optional)
            if (a) then fd.alpha = a; end
            -- add our new frame data to our storage array
            -- note that we use the frame number as our index into the array
            -- effectively, we are creating a sorted table listing all animation frames
            frameData[tostring(fi)] = fd;
            -- table.insert(frameData, fi, fd);         
         end
      else
         -- WARNING:
         print("WARNING: An animation (", newtable.id, ") had a Part (", pn, ") which was missing frame data!");
      end
   end

   -- store our list of parts
   newtable.partList = partList;
   newtable.partListData = partListData;
   -- store our frame by frame animation data into our new table
   newtable.frameData = frameData;

   return newtable;
end

FRC_AnimationManager.createAnimationClip = function(data)
   local required = {
      data = "table",
   };

   local defaults = {};
   -- ui.checkoptions.callee = 'FRC_AnimationManager.createAnimationClip';
   -- local options = ui.checkoptions.check(args, required, defaults);

   local animData = data;

   -- set up the display group for the animation sequence
   local animationClip = display.newGroup();
   animationClip.currentIndex = 1;
   animationClip.frameCount = tonumber(data.frameCount);
   print(animationClip.frameCount); -- DEBUG
   animationClip.intervalTime = 33.33; -- 30fps default

   animationClip.currentPart = nil; -- "";
   -- for debugging, we track the id
   animationClip.id = animData.id;

   animationClip.isPlaying = false;
   animationClip.isPaused = false;

   animationClip.xTransform = 0;
   animationClip.yTransform = 0;
   --[[animationClip.alphaTransform = 1;
  animationClip.scaleTransform = 1
  animationClip.xScaleTransform = 1;
  animationClip.yScaleTransform = 1;
  --]]

   -- to increase animation smoothness, we need to pre-attach the animation frame assets to this display group
   animationClip.animationParts = display.newGroup();
   animationClip:insert(animationClip.animationParts);
   -- DEBUG:
   -- print("animationParts: ", animationParts);

   -- attach the animation parts to a subgroup (pre-caching the insert operation)
   for i=1, #animData.partList do
      local pn = animData.partList[i];
      -- DEBUG:
      -- print("Adding part ",pn," to animationParts");
      local refImage = animData.partListData[pn].refImage;
      -- hide the part by default - not sure if this has to be done after insert or not
      refImage.isVisible = false;
      -- add the image data to the parts array
      animationClip.animationParts[pn] = refImage;
      -- attach the image to the display array
      animationClip.animationParts:insert(refImage);
      -- DEBUG:
      -- print("Part data being attached to animationClip: ", refImage.id, " Parent: ", refImage.parent);

   end

   animationClip.showFrame = function(self, index)
      -- DEBUG:
      -- print("showFrame index/self: ", index, self);
      -- print("showFrame self.frameCount: ", self.frameCount);
      -- defend against an attempt to play a non-existent frame of animation
      if (self.frameCount == nil) then
         return
      end
      if (index > self.frameCount) then
         return
      end
      -- grab the new frame's data
      local frameData = animData.frameData[tostring(index)];
      -- check if there is frame data for this frame in the sequence

      --[[
      
      -- These changes broke marque and cow
      if (not frameData) then
         if (animationClip.animationParts and animationClip.currentPart) then
            if (animationClip.animationParts[animationClip.currentPart]) then
               newPart = animationClip.animationParts[animationClip.currentPart];
            end
         end
      elseif (frameData) then
      --]]

      if (frameData) then
         -- get the part
         local p = frameData.part;
         -- if the part is different, then switch the graphic
         -- DEBUG:
         -- print("animationClip.currentPart: " , type(animationClip.currentPart), " current part: ", animationClip.currentPart, " - next part: ", p);
         if (animationClip.currentPart ~= p) then
            -- hide the current part (if there is one)
            if animationClip.currentPart then
               if (animationClip.animationParts[animationClip.currentPart]) then
                  -- TODO:  We can use disable this line to create a trails effect for the animation
                  animationClip.animationParts[animationClip.currentPart].isVisible = false;
               end
            end
            animationClip.currentPart = p;
            -- DEBUG:
            -- print("NEW animationClip.currentPart: ", animationClip.currentPart, " at frame ", index, " part id: ", animationClip.animationParts[animationClip.currentPart].id);
         else
            -- force the part visible in case another animation that used this part was stopped (hidden) in the
            -- CCC 1.2.15 mod in attempt to fix pause/fastforward bug
            if (animationClip.animationParts and animationClip.currentPart) then
               if (animationClip.animationParts[animationClip.currentPart]) then
                  animationClip.animationParts[animationClip.currentPart].isVisible = true;
               end
            end
         end
         local newPart;
         if (animationClip.animationParts and animationClip.currentPart) then
            if (animationClip.animationParts[animationClip.currentPart]) then
               newPart = animationClip.animationParts[animationClip.currentPart];
            end
         end
         -- position and transform the object
         if (newPart) then
            -- scale, rotate, translate - this is the order used by Corona
            if (animationClip.scaleTransform) then
               newPart.xScale = animationClip.scaleTransform;
               newPart.yScale = animationClip.scaleTransform;
            else
               if (animationClip.xScaleTransform) then
                  newPart.xScale = animationClip.xScaleTransform;
               else
                  newPart.xScale = frameData.xScale or 1;
               end
               if (animationClip.yScaleTransform) then
                  newPart.yScale = animationClip.yScaleTransform;
               else
                  newPart.yScale = frameData.yScale or 1;
               end
               --[[
          newPart.xScale = frameData.xScale or 1;
          newPart.xScale = animationClip.xScaleTransform or newPart.xScale;
          newPart.yScale = frameData.yScale or 1;
          newPart.yScale = animationClip.yScaleTransform or newPart.yScale;
          --]]
            end
            -- DEBUG:
            -- if (frameData.xScale ~= newPart.xScale) then print("NOTE: newPart.xScale DOES NOT MATCH frameData.xScale"); end
            -- if (frameData.yScale ~= newPart.yScale) then print("NOTE: newPart.yScale DOES NOT MATCH frameData.yScale"); end

            newPart.rotation = frameData.rotation or 0;
            if (animationClip.rotationTransform) then
               newPart.rotation = newPart.rotation + animationClip.rotationTransform; -- this adjusts the value range from -180,180
            end
            newPart.x = frameData.x or 0;
            newPart.y = frameData.y or 0;
            -- DEBUG:
            -- print("animationClip.currentPart: ", animationClip.currentPart, " visible at frame ", index);
            -- now apply flip transformations
            local flipTransform = animationClip.flip;
            if (flipTransform) then
               -- DEBUG:
               -- print("FLIP TRANSFORM:");
               -- table.dump(flipTransform);
               for f=1, #flipTransform do
                  local flipProperty = flipTransform[f];
                  -- should only apply to x, y and rotation
                  if (flipProperty == "x") then
                     if (newPart.x > 0) then
                        newPart.x = -newPart.x;
                     else
                        newPart.x = math.abs(newPart.x);
                     end
                  elseif (flipProperty == "y") then
                     if (newPart.y > 0) then
                        newPart.y = -newPart.y;
                     else
                        newPart.y = math.abs(newPart.y);
                     end
                  elseif (flipProperty == "rotation") then
                     if (newPart.rotation >= 0 and newPart.rotation <= 180) then
                        newPart.rotation = -newPart.rotation;
                     elseif (newPart.rotation < 0 and newPart.rotation >= -180) then
                        newPart.rotation = math.abs(newPart.rotation);
                     elseif (newPart.rotation > 180) then
                        newPart.rotation = newPart.rotation - 180;
                     else
                        newPart.rotation = newPart.rotation + 180;
                     end
                  elseif (flipProperty == "horizontal") then
                     newPart.xScale = -newPart.xScale;
                  elseif (flipProperty == "vertical") then
                     newPart.yScale = -newPart.yScale;
                  end
               end
            end

            -- center the current part to the current display
            if (newPart.translate ~= nil) then
               newPart:translate(display.contentCenterX + animationClip.xTransform, display.contentCenterY + animationClip.yTransform);
            end
            -- DEBUG:
            -- if (newPart.xScale < 0) then print("NOTE: newPart.xScale is NEGATIVE - HORIZONTAL FLIP"); end
            -- if (newPart.yScale < 0) then print("NOTE: newPart.yScale is NEGATIVE - VERTICAL CLIP"); end
            -- print("newPart.rotation: ", newPart.rotation);
            -- print("newPart.x: ", newPart.x);
            -- print("newPart.y: ", newPart.y);
            -- set the global alpha - usually 1
            newPart.alpha = frameData.alpha or 1;
            -- make the new part visible
            newPart.isVisible = true;
         end
      else
         -- DEBUG:
         -- print("Warning... no frame data found at frame: ", index, " Last part was: ",animationClip.currentPart);
         -- -- we have to clear everything from the frame since there was no data for this frame number
         -- hide the current part (if there is one)
         if (animationClip.animationParts and animationClip.currentPart) then -- (animationClip.currentPart ~= "")) then
            if (animationClip.animationParts[animationClip.currentPart]) then
               animationClip.animationParts[animationClip.currentPart].isVisible = false;
               -- DEBUG:
               -- print("Making :", animationClip.currentPart, " invisible due to lack of frame data at frame #: ", index);
            end
         end
         -- animationClip.currentPart = "";
      end
   end

   animationClip.play = function(self, options)
      local gotoNext; -- forward declaration
      -- DEBUG:
      -- print("animationClip.play: ", animationClip.id);
      -- table.dump(options);
      animationClip.isPlaying = true;
      animationClip.isPaused = false;
      -- DEBUG:
      -- print("options.showLastFrame: ", options.showLastFrame);
      ------ options:
      -- autoLoop:boolean (true means loop indefinitely, otherwise do whatever maxIterations says or play once)
      -- delay:milliseconds before animation starts
      -- startFrame:integer starting frame
      -- maxIterations: nil or -1 means loop forever, >0 means loop that many times (unless noLoop = true which sets maxIterations = 1)
      -- showLastFrame:boolean (false means call dispose() when the animation is over so it goes away, otherwise leave the last frame visible at the end)
      -- palindromicLoop:boolean (true means to reverse direction for the next iteration)
      -- playBackward: false (default), true means to play from the last frame to the first frame

      animationClip.stopDelay = options.stopDelay; 

      animationClip.stopGate = options.stopGate; 

      animationClip.autoLoop = options.autoLoop or false;
      animationClip.palindromicLoop = options.palindromicLoop or false;
      animationClip.showFirstFrame = options.showFirstFrame or false;
      animationClip.showLastFrame = options.showLastFrame or false;
      animationClip.playBackward = options.playBackward or false;
      animationClip.onCompletion = options.onCompletion or nil;
      animationClip.transformations = options.transformations or nil;
      animationClip.flip = options.flipProperties or nil;
      -- DEBUG:
      if (animationClip.flip) then
         -- print("animationClip.flip: ");
         table.dump(animationClip.flip);
      end
      -- animationClip.onTouch = options.onTouch or nil;
      -- maxIterations is based on an override from noLoop
      if (animationClip.autoLoop) then
         -- loop forever until the stop() or dispose() functions are called
         animationClip.maxIterations = -1;
         -- DEBUG:
         -- print(animationClip.id, " autoLooping enabled! Framecount: ", animationClip.frameCount);
      else
         animationClip.maxIterations = tonumber(options.maxIterations);
         -- check for a nil value or a bad value
         if ((not animationClip.maxIterations) or (animationClip.maxIterations < 0)) then
            animationClip.maxIterations = 1;
         end
      end
      -- DEBUG:
      -- print("self.maxIterations: ", self.maxIterations);


      if (animationClip.playBackward) then
         -- DEBUG:
         -- print("initial play is backwards");
         animationClip.startFrame = options.startFrame or animationClip.frameCount;
         animationClip.currentIndex = tonumber(animationClip.startFrame);
      else
         animationClip.startFrame = options.startFrame or 1;
         animationClip.currentIndex = animationClip.startFrame or 1;
      end
      -- DEBUG:
      -- print("starting playback at animationClip.currentIndex: ", animationClip.currentIndex);

      if (options.intervalTime) then
         animationClip.intervalTime = tonumber(options.intervalTime);
      end
      -- DEBUG:
      -- print("animation target frame rate: ", 1000/animationClip.intervalTime);

      -- we haven't played through any iterations of the animation cycle
      animationClip.iterations = 0;
      -- play the first frame with no delay
      animationClip.nextIntervalTime = 0; -- animationClip.intervalTime; -- 0;

      -- setup the animationClip.transformations
      if (animationClip.transformations) then
         -- DEBUG:
         -- print("applying ANIMATION TRANSFORMATIONS");
         -- table.dump(animationClip.transformations);
         animationClip.xTransform = animationClip.transformations.xTransform or 0;
         animationClip.yTransform = animationClip.transformations.yTransform or 0;
         -- NOTE: alpha is set directly on the animationClip object and not on individual frames of clips
         animationClip.alpha = animationClip.transformations.alphaTransform or 1;
         animationClip.scaleTransform = animationClip.transformations.scaleTransform;
         animationClip.xScaleTransform = animationClip.transformations.xScaleTransform;
         animationClip.yScaleTransform = animationClip.transformations.yScaleTransform;
         animationClip.rotationTransform = animationClip.transformations.rotationTransform;
      end

      -- DEBUG:
      local animationStartTime = system.getTimer();
      -- we need to account for the startup delay
      if (options.delay) then
         animationStartTime = animationStartTime + tonumber(options.delay);
      end
      -- print("Animation Play started at ", animationStartTime);

      function gotoNext(isDelay)
         if (not animationClip or not animationClip.isPlaying or animationClip.isPaused) then return; end

         -- make a local variable for faster access since we are in a time critical loop
         local system_getTimer = system.getTimer;
         local nextIndex = animationClip.currentIndex;
         -- this is where the rendering magic happens
         local startRenderTime = system_getTimer();
         animationClip:showFrame(nextIndex);
         -- DEBUG:
         -- print(animationClip.id, " frame ", nextIndex, " rendered in: ", system_getTimer() - startRenderTime, " ms");

         -- check if this is our first time entering gotoNext
         if not (animationClip.lastFrameStartTime) then
            animationClip.lastFrameStartTime = system_getTimer() - animationClip.intervalTime;
            -- we need to account for the startup delay
            --[[ if (options.delay) then
          animationClip.lastFrameStartTime = animationClip.lastFrameStartTime + options.delay;
        end
        --]]
         end
         -- determine how long it took to render the animation frame
         local actualFrameTime = system_getTimer() - animationClip.lastFrameStartTime;
         -- print(animationClip.id, " frame ", animationClip.currentIndex - 1, " took: ", actualFrameTime, " ms");
         -- local variance =  math.max(animationClip.intervalTime - actualEndTimeDiff, 0);
         local actualEndTimeVariance =  animationClip.intervalTime - actualFrameTime;

         -- This implements a frame dropping and adjustable interval mechanism
         -- so if frame rendering falls behind
         -- we can smoothly get back in alignment

         -- hopefully, we are running faster than we need to or close to the target just advance to the next frame
         -- wait until we are reasonably behind before skipping frames
         if (actualFrameTime < (animationClip.intervalTime * 2)) then
            -- we will wait for the remainder of the interval (or 0) before rendering the next frame
            if (actualFrameTime < animationClip.intervalTime) then
               -- TODO:  move this code to later or adjust it to reduce self.nextIntervalTime down to account for the code execution overhead
               animationClip.nextIntervalTime = animationClip.intervalTime + actualEndTimeVariance;
            else
               -- we are running behind, so render the next frame right away
               animationClip.nextIntervalTime = 0;
            end

            animationClip.nextIntervalTime = animationClip.intervalTime + actualEndTimeVariance;
            -- increment the frame
            if (animationClip.playBackward) then
               nextIndex = nextIndex - 1;
            else
               nextIndex = nextIndex + 1;
            end
            -- DEBUG:
            -- print("Frame ", self.currentIndex, " to ", nextIndex, " in ", self.nextIntervalTime, "ms");
         else
            -- we are running slower than we need to (more than 1 frame behind)
            -- we need to skip frames by calculating how many frames behind we are
            -- if elapsedTime = self.intervalTime exactly, we will simply advance to the next frame
            -- if elapsedTime >= self.intervalTime * 2 then we will need to actually skip frames
            -- we are going to use floor to round down to the nearest whole number because
            -- we will be using the remainder (modula) to determine how long we need to wait before rendering
            local skipFrames = math.floor(actualFrameTime / animationClip.intervalTime) + 1;
            if (animationClip.playBackward) then
               nextIndex = nextIndex - skipFrames;
            else
               nextIndex = nextIndex + skipFrames;
            end
            -- originally I was thinking we should wait the perfect amount but
            -- since we already know we are behind, why wait at all?
            --self.nextIntervalTime = 0;
            animationClip.nextIntervalTime = animationClip.intervalTime - (actualFrameTime % animationClip.intervalTime); -- + actualEndTimeVariance;
            -- DEBUG:
            -- print(animationClip.id, " animation - Skipping ", skipFrames, " frames to index ", nextIndex, " in ", animationClip.nextIntervalTime, " ms");
         end

         local advanceFrame = false;
         if (animationClip.playBackward) then
            if (nextIndex >= 1) then
               advanceFrame = true;
            end
         else
            if (nextIndex <= animationClip.frameCount) then
               advanceFrame = true;
            end
         end

         -- check to see if we're past the maximum number of frames
         if (advanceFrame) then
            -- set the animation to the designated "next" frame
            animationClip.currentIndex = nextIndex;
            -- capture the time so we can figure out how long it takes to render the frame
            animationClip.lastFrameStartTime = system_getTimer();
            -- wait the specified amount of time
            timer.cancel(animationClip.animationTimer);
            animationClip.animationTimer = timer.performWithDelay(animationClip.nextIntervalTime, gotoNext, 1);
         else
            -- we've hit the end of the sequence, increment the iterations counter
            animationClip.iterations = animationClip.iterations + 1;
            -- DEBUG:
            -- if not animationClip.autoLoop then print("Animation loop: ", self.iterations, " ending at frame ", nextIndex, " currentIndex: ", animationClip.currentIndex); end
            if ((animationClip.maxIterations < 0) or (animationClip.iterations < animationClip.maxIterations)) then
               -- reset back to the beginning of the sequence
               -- DEBUG:
               -- print("looping");
               -- this is where we will test for palindromic playback
               if (animationClip.palindromicLoop) then
                  -- DEBUG:
                  -- print("palindromic switch");
                  animationClip.playBackward = not animationClip.playBackward;
               end
               if (animationClip.playBackward) then
                  animationClip.currentIndex = animationClip.frameCount;
                  -- DEBUG:
                  -- print("looping backwards, resetting to frame: ", animationClip.currentIndex);
               else
                  animationClip.currentIndex = animationClip.startFrame;
               end
               -- now reset the timer
               if (isDelay == true) then
                  timer.cancel(animationClip.animationTimer);
                  animationClip.animationTimer = timer.performWithDelay(options.delay, function()
                        -- capture the time so we can figure out how long it takes to render the frame
                        animationClip.lastFrameStartTime = system_getTimer();
                        animationClip.animationTimer = timer.performWithDelay(animationClip.nextIntervalTime, function() gotoNext(true); end, 1);
                     end, 1);
               else
                  -- capture the time so we can figure out how long it takes to render the frame
                  animationClip.lastFrameStartTime = system_getTimer();
                  -- wait the specified amount of time
                  timer.cancel(animationClip.animationTimer);
                  animationClip.animationTimer = timer.performWithDelay(animationClip.nextIntervalTime, gotoNext, 1);
               end
            else
               -- we are finished animating!
               -- DEBUG:
               local animationEndTime = system.getTimer();
               -- DEBUG
               -- print(animationClip.id, " animation played ", animationClip.frameCount, " frames at ", (1000 / ((animationEndTime - animationStartTime) / animationClip.frameCount)), " fps");
               -- trigger any completion action before shutting down
               if (animationClip.onCompletion) then
                  animationClip.onCompletion();
               end
               -- either stop the animation showing the last frame or self dispose
               if (animationClip.showLastFrame) then
                  -- reset iterations in case we get called to play again
                  animationClip.iterations = 0;
                  animationClip:stop(animationClip.frameCount);
               else
                  -- wait a frame so that the screen doesn't flash between chained animation sequences
                  -- timer.performWithDelay(animationClip.intervalTime * 2, function() animationClip:stop(); end, 1);
                  -- CCC 1.2.15 mod in attempt to fix pause/fastforward bug (line above was commented out)

                  if( animationClip.stopGate == true ) then 
                     --dprint("STOP GATED")

                  elseif( animationClip.stopDelay and animationClip.stopDelay > 0 ) then
                     --dprint("STOP DELAYED delay == ", animationClip.stopDelay)
                     timer.performWithDelay(animationClip.stopDelay, function() animationClip:stop(); end )

                  else
                     animationClip:stop();
                  end
               end
            end
         end
      end
      -- copy the function in for later access
      animationClip.gotoNext = gotoNext;

      -- if maxIterations = 0 then don't play anything
      if (animationClip.maxIterations == 0) then
         -- shut down the animation immediately
         -- this is used to stage touchpoint animations
         animationClip.isPlaying = false;
      else
         if (animationClip.showFirstFrame) then
            -- we need to show the first frame right away
            animationClip:showFrame(animationClip.currentIndex);
            -- DEBUG:
            -- print(animationClip.id, " ANIMATION SHOW FIRST FRAME at frame: ", animationClip.currentIndex);
         end
         -- this fires up the animation sequence
         if (options.delay) then
            animationClip.animationTimer = timer.performWithDelay(options.delay, function()
                  animationClip.animationTimer = timer.performWithDelay(animationClip.nextIntervalTime, function() gotoNext(true); end, 1);
               end, 1);
         else
            animationClip.animationTimer = timer.performWithDelay(animationClip.nextIntervalTime, gotoNext, 1);
         end
      end
   end

   animationClip.reverse = function(self)
      -- we need to set the visibility of the animationClip
      animationClip.playBackward = not animationClip.playBackward;
   end

   animationClip.pause = function(self, autoHide)
      -- DEBUG:
      -- print(animationClip.id, " animationClip.pause");
      animationClip.isPlaying = false;
      animationClip.isPaused = true;
      if (autoHide) then
         timer.performWithDelay(animationClip.intervalTime * 2, function() animationClip:hide(); end, 1);
         -- CCC 1.2.15 mod in attempt to fix pause/fastforward bug (line above was commented out)
         -- animationClip:hide();
      end
      if (animationClip.animationTimer) then
         timer.cancel(animationClip.animationTimer);
         animationClip.animationTimer = nil;
      end
   end

   animationClip.resume = function(self, autoShow)
      -- DEBUG:
      -- print(animationClip.id, " animationClip.resume");
      animationClip.isPlaying = true;
      animationClip.isPaused = false;
      if (autoShow) then
         animationClip:show();
      end
      --[[
    if (animationClip.animationTimer) then
      timer.resume(animationClip.animationTimer);
    end
    --]]
      -- reset the lastFrameStartTime so when the animation resumes, it doesn't jump ahead to where it should have been if it wasn't paused
      animationClip.lastFrameStartTime = system.getTimer(); -- nil;
      animationClip.animationTimer = timer.performWithDelay(animationClip.nextIntervalTime, animationClip.gotoNext, 1);
      -- animationClip.nextIntervalTime = animationClip.intervalTime;
      -- animationClip:show();
      -- animationClip.animationTimer = timer.performWithDelay(animationClip.nextIntervalTime, animationClip.play.gotoNext, 1);
   end

   animationClip.show = function(self)
      -- we need to set the visibility of the animationClip
      if (animationClip.animationParts) then
         if (animationClip.currentPart) then
            local animationPart = animationClip.animationParts[animationClip.currentPart];
            -- DEBUG
            -- print("animationPart: ", animationPart);
            if (animationPart) then
               animationPart.isVisible = true;
            end
         end
      end
   end

   animationClip.hide = function(self)
      -- we need to set the visibility of the animationClip
      if (animationClip.animationParts) then
         if (animationClip.currentPart) then
            -- DEBUG:
            -- print("animationClip.hide: ", animationClip.currentPart);
            -- print("animationPart: ", animationPart);
            local animationPart = animationClip.animationParts[animationClip.currentPart];
            if (animationPart) then
               animationPart.isVisible = false;
            end
         end
      end
   end

   animationClip.stop = function(self, atFrame)
      -- reset
      animationClip.lastFrameStartTime = nil;
      -- DEBUG
      -- print(animationClip.id, " ANIMATION STOP at frame: ", animationClip.currentIndex, " - atFrame: ", atFrame, " - last part: ", animationClip.currentPart);
      if (animationClip.animationTimer) then
         timer.cancel(animationClip.animationTimer);
         animationClip.animationTimer = nil;
         animationClip.nextIntervalTime = animationClip.intervalTime;
      end
      if (atFrame) then
         -- DEBUG:
         -- print("animationClip.stop - leaving specified frame visible: ", atFrame);
         animationClip:showFrame(atFrame);
         animationClip.isPlaying = true;
         animationClip.isPaused = false;
         --[[  elseif (animationClip.showLastFrame) then
      -- DEBUG:
      -- print("animationClip.stop - leaving last frame visible: ", animationClip.currentIndex);
      animationClip:showFrame(animationClip.currentIndex);
      animationClip.isPlaying = true;
      --]]
      else
         animationClip:hide();
         animationClip.isPlaying = false;
         animationClip.isPaused = false;
      end
   end

   animationClip.dispose = function(self)
      -- DEBUG
      -- print("ANIMATION DISPOSE: ", animationClip.id);
      if (animationClip.animationTimer) then
         timer.cancel(animationClip.animationTimer);
         animationClip.animationTimer = nil;
      end
      -- remove the entire set of animation parts
      -- for i=1, #animationParts do
      -- if (animationParts[i]) then
      -- animationParts[i]:removeSelf();
      -- animationParts[i] = nil;
      -- end
      -- end
      if (animationClip.animationParts) then
         animationClip.animationParts:removeSelf();
         animationClip.animationParts = nil;
      end
      animationClip.nextIntervalTime = animationClip.intervalTime;
   end

   return animationClip;
end

-- this function creates a group of clips based on an array of XML filenames
FRC_AnimationManager.createAnimationClipGroup = function(inputFiles, baseXMLDir, baseImageDir, animationGroupProperties)
   -- DEBUG:
   -- print("FRC_AnimationManager.createAnimationClipGroup baseXMLDir, baseImageDir: ", baseXMLDir, " - ", baseImageDir);
   local animationClipGroup = display.newGroup();
   -- if we have been provided global properties for the group, store them into the group object
   if (animationGroupProperties) then
      animationClipGroup.showLastFrame = animationGroupProperties.showLastFrame;
      animationClipGroup.showFirstFrame = animationGroupProperties.showFirstFrame;
      animationClipGroup.playBackward = animationGroupProperties.playBackward;
      animationClipGroup.autoLoop = animationGroupProperties.autoLoop;
      animationClipGroup.palindromicLoop = animationGroupProperties.palindromicLoop;
      animationClipGroup.delay = animationGroupProperties.delay;
      animationClipGroup.intervalTime = animationGroupProperties.intervalTime;
      animationClipGroup.maxIterations = animationGroupProperties.maxIterations;
      animationClipGroup.transformations = animationGroupProperties.transformations;
      animationClipGroup.flip = animationGroupProperties.flip;
      animationClipGroup.maskSource = animationGroupProperties.maskSource;
      animationClipGroup.maskRect = animationGroupProperties.maskRect; 
      animationClipGroup.onMaskTouch = animationGroupProperties.onMaskTouch; 
      animationClipGroup.maskDebugEn = animationGroupProperties.maskDebugEn; 
      animationClipGroup.unifiedData = animationGroupProperties.unifiedData; --EFM

      -- DEBUG:
      if animationClipGroup.maskSource then 
         dprint("FRC_AnimationManager.createAnimationClipGroup animationClipGroup.maskSource ASSIGNED! ", animationClipGroup.maskSource); 
      end
      animationClipGroup.onCompletion = animationGroupProperties.onCompletion;
      animationClipGroup.onTouch = animationGroupProperties.onTouch;
      animationClipGroup.onShake = animationGroupProperties.onShake;
      animationClipGroup.onPlay = animationGroupProperties.onPlay;
   else
      -- DEBUG:
      print("FRC_AnimationManager.createAnimationClipGroup CALLED WITHOUT PROPERTIES");
   end


   -- Original code can be located at bottom of file marked EFM151212_OLD

   -- Load (and if need be generate LUA files from) XML animation data from files.
   if (inputFiles) then      
      for i=1, #inputFiles do
         local sourceFile = inputFiles[i];         
         local xmltable = sourceFile -- assume 'file name' is actually an xmltable ...
         --
         --  ... However, check to see if it is not and load it if we need to (this is the default functionality)
         --
         local isUnified = false
         if( type( sourceFile ) == "string" ) then
            xmltable = FRC_AnimationManager.loadAnimationData( sourceFile, baseXMLDir  )   
         else
            isUnified = true
            --table.dump2( xmltable )
         end

         if( isUnified ) then
            --dprint("*****************************************")
            --dprint("** IS UNIFIED * IS UNIFIED * IS UNIFIED * ")
            --dprint("*****************************************")

            local originalPart   = xmltable.Animation.Part
            local baseName       = xmltable.Animation.name

            local allParts       = animationClipGroup.unifiedData.allParts
            local adjustments    = animationClipGroup.unifiedData.adjustments 
            --table.print_r( allParts )

            local partSubNames      = {}            
            for j = 1, #allParts do
               partSubNames[j] = { allParts[j][1], allParts[j][2] }
            end            
            --table.print_r( partSubNames )

            local strMatch = string.match

            for j = 1, #partSubNames do
               --for j = 1, 3 do
               local partSubName    = partSubNames[j][1]
               local partExcludeName = partSubNames[j][2]
               local newPart = {}
               xmltable.Animation.Part = newPart
               local found = false
               for k = 1, #originalPart do
                  local curPart = originalPart[k]
                  --dprint( "LOOKING ", curPart )                  
                  if( partExcludeName and string.len(partExcludeName) > 0 ) then
                     if( strMatch( curPart.name, partSubName ) and            
                        strMatch( curPart.name, partExcludeName ) == nil ) then
                        --dprint("edochi a", i, curPart.name )
                        newPart[#newPart+1] = curPart
                        found = true
                        --dprint( "MATCH ", curPart.name, partSubName, partExcludeName  )
                     end
                  else
                     if( strMatch( curPart.name, partSubName ) ) then
                        --dprint("edochi b", i, curPart.name )
                        newPart[#newPart+1] = curPart
                        found = true
                        --dprint( "MATCH ", curPart.name, partSubName, partExcludeName  )
                     end
                  end
               end

               if( found ) then
                  local adjustment = adjustments[ partSubName ]

                  local animData = FRC_AnimationManager.getAnimationData(xmltable, baseImageDir);
                  local clip = FRC_AnimationManager.createAnimationClip(animData)

                  if( adjustment ) then
                     clip[i].x = clip[i].x + adjustment.offset[1]
                     clip[i].y = clip[i].y + adjustment.offset[2]
                  end                 

                  animationClipGroup:insert(clip);               
               else
                  --dprint( "PART NOT FOUND ... SKIPPING: ", partType ) -- EFM THIS SEEMS LIKE A BUG (MISSING DATA?)
               end
            end

            --dprint("*****************************************")
            --dprint("*****************************************")
            --dprint("*****************************************")
         else
            local animData = FRC_AnimationManager.getAnimationData(xmltable, baseImageDir);
            animationClipGroup:insert(FRC_AnimationManager.createAnimationClip(animData));
         end
      end
   else
      print("WARNING:  FRC_AnimationManager.createAnimationClipGroup was called without specifying XML files.");   
   end


   animationClipGroup.play = function(self, options)
      -- store special functions for the last clip
      local onCompletion = options.onCompletion;
      local onTouch = options.onTouch;
      local onShake = options.onShake;
      local onPlay = options.onPlay;

      options.onCompletion = nil;
      options.onTouch = nil;
      options.onShake = nil;
      options.onPlay = nil;

      -- loop through the subclips
      local totalClips = #self;
      for i=1,totalClips do
         local animation = self[i];
         if (animation) then
            if (i < totalClips) then
               animation:play(options);
            else
               --animation:play(options); 
               -- attach special events to the last subclip only
               -- TODO:  attach these to the group object only instead
               options.onCompletion = onCompletion;
               options.onTouch = onTouch;
               options.onShake = onShake;
               options.onPlay = onPlay;
               animation:play(options);
            end
         end
      end
   end

   if (animationClipGroup.maskSource and animationClipGroup.maskRect) then 
      ----[[
      local maskRect = animationClipGroup.maskRect
      local maskPath = baseImageDir .. animationClipGroup.maskSource
      local onTouch  = animationClipGroup.onTouch
      local x = display.contentCenterX + maskRect.x
      local y = display.contentCenterY + maskRect.y
      --local touchProxy = display.newRect(animationClipGroup, x, y, maskRect.w, maskRect.h )
      local touchProxy = display.newRect( x, y, maskRect.w, maskRect.h )

      local storyboard = require "storyboard"
      local sceneName = storyboard.getCurrentSceneName()
      local currentScene = storyboard.getScene( sceneName )
      currentScene.view:insert( touchProxy ) -- No affect on insertion
      if( animationClipGroup.maskDebugEn == true ) then
         touchProxy:setFillColor(1,0,1)
      else
         touchProxy:toBack()  
         touchProxy.isVisible = false
         timer.performWithDelay( 100, 
            function()
               -- In case it was removed in the interim:
               if( not touchProxy or not touchProxy.removeSelf ) then return end 
               -- Otherwise, proceed:
               touchProxy.isVisible = true
               currentScene.view:insert( 4, touchProxy )
            end )
      end

      animationClipGroup.touchProxy = touchProxy
      touchProxy.alpha = 0.5
      local mask = graphics.newMask( maskPath )
      touchProxy:setMask( mask )
      touchProxy.isHitTestMasked = true

      function touchProxy.finalize( self )
         Runtime:removeEventListener("enterFrame", self) 
      end
      touchProxy:addEventListener("finalize")

   end

   return animationClipGroup;
end

FRC_AnimationManager.getAnimationClips = function(scene, options) -- local; forward declaration at top
   -- look for animation objects
   local animations = {};
   for i=#scene.sceneObjects,1,-1 do
      local obj = scene.sceneObjects[i];
      if (obj.type) then
         if (obj.type == "animationgroup") then
            -- display of all the objects
            for j=1, obj.numChildren do
               table.insert(animations, obj[j]);
            end
         end
      end
   end
   return animations;
end

FRC_AnimationManager.pauseAnimations = function(scene)
   -- loop through all current animations
   local animations = FRC_AnimationManager.getAnimationClips(scene);
   for i=1,#animations do
      local animation = animations[i];
      if (animation) then
         -- don't impact animations which aren't playing yet
         if (animation.isPlaying) then
            -- DEBUG:
            -- print("PAUSING ANIMATION: ", animation.id);
            animation:pause(false);
         end
      end
   end
end

FRC_AnimationManager.resumeAnimations = function(scene)
   -- loop through all current animations
   local animations = FRC_AnimationManager.getAnimationClips(scene);
   for i=1,#animations do
      local animation = animations[i];
      if (animation) then
         if (animation.isPaused) then
            -- DEBUG:
            -- print("RESUMING ANIMATION: ", animation.id);
            animation:resume();
         end
      end
   end
end

FRC_AnimationManager.fastForwardAnimations = function(scene)
   -- loop through all current animations
   local animations = FRC_AnimationManager.getAnimationClips(scene);
   for i=1,#animations do
      local animation = animations[i];
      if (animation) then
         -- call resume or play?
         if (animation.isPlaying) then
            -- set their intervalTime to 1ms
            animation.intervalTime = 1;
         end
      end
   end
end

FRC_AnimationManager.disposeAnimations = function(scene)
   -- loop through all current animations
   local animations = FRC_AnimationManager.getAnimationClips(scene);
   for i=#animations,1,-1 do
      animations[i]:dispose();
      animations[i] = nil;
   end
   animations = nil;
end

return FRC_AnimationManager;
