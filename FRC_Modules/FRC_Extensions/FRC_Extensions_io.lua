-- Extensions to the io.* library
local json = require( "json" )

--
-- Localizations (for speedup)
--
local mRand = math.random


function io.exists( fileName, base )
   local base = base or system.DocumentsDirectory	
   local fileName = fileName

   if( base ) then
      fileName = system.pathForFile( fileName, base )
   end
   if not fileName then return false end
   local f=io.open(fileName,"r")
   if (f == nil) then 
      return false
   end
   io.close(f)
   return true 
end


if( io.readFile ) then
   print("ERROR! io.readFile() exists already")
else
   function io.readFile( fileName, base )
      local base = base or system.DocumentsDirectory
      local fileContents

      if( io.exists( fileName, base ) == false ) then
         return nil
      end

      local fileName = fileName
      if( base ) then
         fileName = system.pathForFile( fileName, base )
      end

      local f=io.open(fileName,"r")
      if (f == nil) then 
         return nil
      end

      fileContents = f:read( "*a" )

      io.close(f)

      return fileContents
   end
end

if( io.writeFile ) then
   print("ERROR! io.writeFile() exists already")
else
   function io.writeFile( dataToWrite, fileName, base )
      local base = base or system.DocumentsDirectory

      local fileName = fileName
      if( base ) then
         fileName = system.pathForFile( fileName, base )
      end

      local f=io.open(fileName,"w")
      if (f == nil) then 
         return nil
      end

      f:write( dataToWrite )

      io.close(f)

   end
end

if( io.appendFile ) then
   print("ERROR! io.appendFile() exists already")
else
   function io.appendFile( dataToWrite, fileName, base )
      local base = base or system.DocumentsDirectory

      local fileName = fileName
      if( base ) then
         fileName = system.pathForFile( fileName, base )
      end

      local f=io.open(fileName,"a")
      if (f == nil) then 
         return nil
      end

      f:write( dataToWrite )

      io.close(f)
   end
end


if( io.readFileTable ) then
   print("ERROR! io.readFileTable() exists already")
else
   function io.readFileTable( fileName, base )
      local base = base or system.DocumentsDirectory
      local fileContents = {}

      if( io.exists( fileName, base ) == false ) then
         return fileContents
      end

      local fileName = fileName
      if( base ) then
         fileName = system.pathForFile( fileName, base )
      end

      local f=io.open(fileName,"r")
      if (f == nil) then 
         return fileContents
      end

      for line in f:lines() do
         fileContents[ #fileContents + 1 ] = line
      end

      io.close( f )

      return fileContents
   end
end


