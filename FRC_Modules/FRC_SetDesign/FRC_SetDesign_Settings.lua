local FRC_SetDesign_Settings = {};

FRC_SetDesign_Settings.UI = {
	IMAGES_PATH = 'FRC_Assets/FRC_SetDesign/Images/',
	SCENE_BACKGROUND_IMAGE = 'FRC_Assets/FRC_SetDesign/Images/MDMT_SetDesign_global_Background.jpg',
	SCENE_BACKGROUND_WIDTH = 1152,
	SCENE_BACKGROUND_HEIGHT = 768,
	THUMBNAIL_WIDTH = 192,
	THUMBNAIL_HEIGHT = 128
};

FRC_SetDesign_Settings.DATA = {
	CATEGORIES = 'FRC_Assets/FRC_SetDesign/Data/FRC_SetDesign_Categories.json',
	SETS = 'FRC_Assets/FRC_SetDesign/Data/FRC_SetDesign_Sets.json',
	BACKDROPS = 'FRC_Assets/FRC_SetDesign/Data/FRC_SetDesign_Backdrops.json',
	--LIGHTING = 'FRC_Assets/FRC_SetDesign/Data/FRC_SetDesign_Lighting.json',
	EMPTY_DATAFILE = '{ "owner": "FRC_SetDesign", "savedItems": [] }',
	DATA_FILENAME = 'FRC_SetDesign_SaveData.json'
};

return FRC_SetDesign_Settings;