local FRC_Rehearsal_Settings  = require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Settings')
local FRC_Rehearsal_Scene     = require('FRC_Modules.FRC_Rehearsal.FRC_Rehearsal_Scene')
local FRC_DataLib             = require('FRC_Modules.FRC_DataLib.FRC_DataLib')
local FRC_Util                = require('FRC_Modules.FRC_Util.FRC_Util')
local json                    = require "json"

local FRC_Rehearsal = {}

local function DATA(key, baseDir)
   baseDir = baseDir or system.ResourceDirectory
   return FRC_DataLib.readJSON(FRC_Rehearsal_Settings.DATA[key], baseDir)
end

local emptyDataFile = json.decode(FRC_Rehearsal_Settings.DATA.EMPTY_DATAFILE)

-- load saved data or save new data
local saveDataFilename = FRC_Rehearsal_Settings.DATA.DATA_FILENAME

local saveDataToFile = function()
   FRC_DataLib.saveJSON(saveDataFilename, FRC_Rehearsal.saveData, system.DocumentsDirectory)
end
-- copy this function into FRC_Rehearsal
FRC_Rehearsal.saveDataToFile = saveDataToFile

local getSavedData = function()
   FRC_Rehearsal.saveData = FRC_DataLib.readJSON(saveDataFilename, system.DocumentsDirectory)
   -- DEBUG
   print("FRC_Rehearsal.savedData loaded:")
   table.dump(FRC_Rehearsal.saveData)
   if (not FRC_Rehearsal.saveData) then
      -- DEBUG:
      print("FRC_Rehearsal - CREATING NEW SAVE FILE!")
      FRC_Rehearsal.saveData = emptyDataFile
      FRC_Rehearsal.saveDataToFile()
   end
end
FRC_Rehearsal.getSavedData = getSavedData

local newScene = function(settings)
   settings = settings or {}
   for k1,v1 in pairs(settings) do
      for k2,v2 in pairs(FRC_Rehearsal_Settings) do
         for k3,v3 in pairs(FRC_Rehearsal_Settings[k2]) do
            if (k3 == k1) then
               FRC_Rehearsal_Settings[k2][k1] = v1
               break
            end
         end
      end
   end
   FRC_Rehearsal.getSavedData()
   return FRC_Rehearsal_Scene
end
FRC_Rehearsal.newScene = newScene

return FRC_Rehearsal
