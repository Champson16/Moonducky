local FRC_Rehearsal_Settings = {}

FRC_Rehearsal_Settings.UI = {
   IMAGES_PATH = 'FRC_Assets/FRC_Rehearsal/Images/',
   SCENE_BACKGROUND_IMAGE = 'FRC_Assets/FRC_Rehearsal/Images/MDMT_Rehearsal_Background.png',
   SCENE_BACKGROUND_WIDTH = 1152,
   SCENE_BACKGROUND_HEIGHT = 768,
   COSTUME_NONE_IMAGE = 'FRC_Rehearsal_Scroller_None.png',
   COSTUME_NONE_WIDTH = 128,
   COSTUME_NONE_HEIGHT = 81,
   COSTUME_NONE_IMAGE = 'FRC_Rehearsal_Scroller_None.png',
   COSTUME_NONE_WIDTH = 128,
   COSTUME_NONE_HEIGHT = 81,
   THUMBNAIL_WIDTH = 256,
   THUMBNAIL_HEIGHT = 192,
   ANIMATION_XML_BASE = 'FRC_Assets/MDMT_Assets/Animation/XMLData/',
   ANIMATION_IMAGE_BASE = 'FRC_Assets/MDMT_Assets/Animation/Images/'
}

-- TODO: work on how to point to user data for SetDesign and Costume
FRC_Rehearsal_Settings.DATA = {
   SAVE_PROMPT = 'Save Your Show',
   LOAD_PROMPT = 'Load Your Show',
   PUBLISH_PROMPT = 'Publish Your Show',
   CATEGORY = 'FRC_Assets/FRC_Rehearsal/Data/FRC_Rehearsal_Category.json',
   SETDESIGN = 'FRC_SetDesign_SaveData.json',
   INSTRUMENT = 'FRC_Assets/FRC_Rehearsal/Data/FRC_Rehearsal_Character.json',
   CHARACTER = 'FRC_Assets/FRC_Rehearsal/Data/FRC_Rehearsal_Character.json',
   COSTUME = 'FRC_DressingRoom_SaveData.json',
   SCENELAYOUT = 'FRC_Assets/FRC_Rehearsal/Data/FRC_Rehearsal_SceneLayout.json',
   EMPTY_DATAFILE = '{ "owner": "FRC_Rehearsal", "savedItems": [] }',
   DATA_FILENAME = 'FRC_Rehearsal_SaveData.json'
}

-- read data file: 'FRC_Assets/FRC_ArtCenter/Data/FRC_ArtCenter_Config.json' and store in 'CONFIG' key
local FRC_DataLib = require("FRC_Modules.FRC_DataLib.FRC_DataLib")
local config = FRC_DataLib.readJSON("FRC_Assets/FRC_Rehearsal/Data/FRC_Rehearsal_Config.json")
if (config) then
   FRC_Rehearsal_Settings.CONFIG = config
else
   FRC_Rehearsal_Settings.CONFIG = {}
end

return FRC_Rehearsal_Settings