local FRC_Rehearsal_Settings = {}

FRC_Rehearsal_Settings.UI = {
   IMAGES_PATH = 'FRC_Assets/FRC_Rehearsal/Images/',
   SCENE_BACKGROUND_IMAGE = 'FRC_Assets/FRC_Rehearsal/Images/MDMT_Rehearsal_Background.png',
   SCENE_BACKGROUND_WIDTH = 1152,
   SCENE_BACKGROUND_HEIGHT = 768,
   SCROLLER_NONE_IMAGE = 'FRC_Rehearsal_Scroller_None.png',
   SCROLLER_NONE_WIDTH = 128,
   SCROLLER_NONE_HEIGHT = 81,
   MYSTERYBOX_IMAGE = 'MDMT_Rehearsal_Scroller_MysteryBox.png',
   MYSTERYBOX_WIDTH = 169,
   MYSTERYBOX_HEIGHT = 128,
   THUMBNAIL_WIDTH = 256,
   THUMBNAIL_HEIGHT = 192,
   ANIMATION_XML_BASE = 'FRC_Assets/MDMT_Assets/Animation/XMLData/',
   ANIMATION_IMAGE_BASE = 'FRC_Assets/MDMT_Assets/Animation/Images/',
   NONE_BUTTON_UP       =  "FRC_Assets/FRC_Rehearsal/Images/FRC_Rehearsal_Scroller_None.png",
   NONE_BUTTON_DOWN     =  "FRC_Assets/FRC_Rehearsal/Images/FRC_Rehearsal_Scroller_None.png",
   NONE_BUTTON_FOCUSED  =  "FRC_Assets/FRC_Rehearsal/Images/FRC_Rehearsal_Scroller_None.png",
   NONE_BUTTON_DISABLED =  "FRC_Assets/FRC_Rehearsal/Images/FRC_Rehearsal_Scroller_None.png",
}

-- TODO: work on how to point to user data for SetDesign and Costume
FRC_Rehearsal_Settings.DATA = {
   SAVE_PROMPT = 'Save Your Show',
   PUBLISH_PROMPT = 'Create a Showtime Performance',
   LOAD_PROMPT = 'Load Your Show',
   CATEGORY = 'FRC_Assets/FRC_Rehearsal/Data/FRC_Rehearsal_Category.json',
   REHEARSAL = 'FRC_Assets/FRC_Rehearsal/Data/FRC_Rehearsal_RehearsalMode.json',
   SHOWTIME = 'FRC_Assets/FRC_Rehearsal/Data/FRC_Rehearsal_ShowtimeMode.json',
   SETDESIGN = 'FRC_SetDesign_SaveData.json',
   INSTRUMENT = 'FRC_Assets/FRC_Rehearsal/Data/FRC_Rehearsal_Instrument.json',
   CHARACTER = 'FRC_Assets/FRC_Rehearsal/Data/FRC_Rehearsal_Character.json',
   COSTUME = 'FRC_DressingRoom_SaveData.json',
   SCENELAYOUT = 'FRC_Assets/FRC_Rehearsal/Data/FRC_Rehearsal_SceneLayout.json',
   EMPTY_DATAFILE = '{ "owner": "FRC_Rehearsal", "savedItems": [] }',
   DATA_FILENAME = 'FRC_Rehearsal_SaveData.json',
   PUBLISH_FILENAME = 'FRC_Showtime_SaveData.json',
   SONG_TRACK_OFFSETS = 'FRC_Assets/FRC_Rehearsal/Data/FRC_Rehearsal_SongTrackOffsets.json',
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
