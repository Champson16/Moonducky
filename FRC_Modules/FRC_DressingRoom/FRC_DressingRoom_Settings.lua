local FRC_DressingRoom_Settings = {};

FRC_DressingRoom_Settings.UI = {
	IMAGES_PATH = 'FRC_Assets/FRC_DressingRoom/Images/',
	SCENE_BACKGROUND_IMAGE = 'FRC_Assets/FRC_DressingRoom/Images/MDMT_DressingRoom_Background.jpg',
	SCENE_BACKGROUND_WIDTH = 1152,
	SCENE_BACKGROUND_HEIGHT = 768,
	COSTUME_NONE_IMAGE = 'FRC_DressingRoom_Costume_None.png',
	COSTUME_NONE_WIDTH = 128,
	COSTUME_NONE_HEIGHT = 81,
	THUMBNAIL_WIDTH = 256,
	THUMBNAIL_HEIGHT = 192,
	ANIMATION_XML_BASE = 'FRC_Assets/MDMT_Assets/Animation/XMLData/',
	ANIMATION_IMAGE_BASE = 'FRC_Assets/MDMT_Assets/Animation/Images/'
};

FRC_DressingRoom_Settings.DATA = {
	SAVE_PROMPT = 'Save Your Character Design',
	LOAD_PROMPT = 'Load Your Character Design',
	CHARACTER = 'FRC_Assets/FRC_DressingRoom/Data/FRC_DressingRoom_Character.json',
	CATEGORY = 'FRC_Assets/FRC_DressingRoom/Data/FRC_DressingRoom_Category.json',
	SCENELAYOUT = 'FRC_Assets/FRC_DressingRoom/Data/FRC_DressingRoom_SceneLayout.json',
	EMPTY_DATAFILE = '{ "owner": "FRC_DressingRoom", "savedItems": [] }',
	DATA_FILENAME = 'FRC_DressingRoom_SaveData.json'
};

-- read data file: 'FRC_Assets/FRC_ArtCenter/Data/FRC_ArtCenter_Config.json' and store in 'CONFIG' key
local FRC_DataLib = require("FRC_Modules.FRC_DataLib.FRC_DataLib");
local config = FRC_DataLib.readJSON("FRC_Assets/FRC_DressingRoom/Data/FRC_DressingRoom_Config.json");
if (config) then
	FRC_DressingRoom_Settings.CONFIG = config;
else
	FRC_DressingRoom_Settings.CONFIG = {};
end

return FRC_DressingRoom_Settings;
