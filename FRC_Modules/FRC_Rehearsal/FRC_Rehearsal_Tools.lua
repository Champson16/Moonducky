local FRC_AnimationManager    = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager')

local public = {}
local private = {}
   -- GUTS HERE
   
function public.readXML( fileName, baseXMLDir )
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

function public.getPartsList( sourceFile, animationXMLBase )
   local xmltable = public.readXML( sourceFile, animationXMLBase  )
   local partsList = xmltable.Animation.Part
   for i = 1, #partsList do
      --print(partsList[i].name)   
   end
   return partsList
end

function public.findAnimationParts( parts, partSubName, toTable, animationImageBase )
   local subParts = {}
   for i = 1, #parts do
      if( string.match( parts[i].name, partSubName ) ) then
         subParts[#subParts+1] = i
      end
   end
   if(toTable) then 
      toTable[#toTable+1] = { partSubName, subParts, animationImageBase }
   end
   return subParts
end


function public.createUnifiedAnimationClipGroup( sourceFile, unifiedData, animationXMLBase, animationImageBase, animationGroupProperties )
   animationGroupProperties = animationGroupProperties or {}
   animationGroupProperties.unifiedData = unifiedData
   return FRC_AnimationManager.createAnimationClipGroup( { sourceFile }, animationXMLBase, animationImageBase, animationGroupProperties )
end


function public.playUnifiedAnimations( animationSequences, num )
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