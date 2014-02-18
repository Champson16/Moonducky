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
	THUMBNAIL_HEIGHT = 192
};

FRC_DressingRoom_Settings.DATA = {
	CHARACTER = 'FRC_Assets/FRC_DressingRoom/Data/FRC_DressingRoom_Character.json',
	CATEGORY = 'FRC_Assets/FRC_DressingRoom/Data/FRC_DressingRoom_Category.json',
	FURNITURE = 'FRC_Assets/FRC_DressingRoom/Data/FRC_DressingRoom_Furniture.json',
	EMPTY_DATAFILE = '{ "owner": "FRC_DressingRoom", "savedItems": [] }',
	DATA_FILENAME = 'FRC_DressingRoom_SaveData.json'
};

return FRC_DressingRoom_Settings; 