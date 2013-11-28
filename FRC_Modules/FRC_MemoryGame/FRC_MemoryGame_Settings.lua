local FRC_MemoryGame_Settings = {}

FRC_MemoryGame_Settings.UI = {
	IMAGE_BASE_PATH = "FRC_Assets/FRC_MemoryGame/Images/",
	SCENE_BACKGROUND = "FRC_Assets/FRC_MemoryGame/Images/PUFF_Games_global_LandingPage_Background.jpg",
	SCENE_BACKGROUND_WIDTH = 1152,
	SCENE_BACKGROUND_HEIGHT = 768,
	CHOOSER_BUTTON_PADDING = 100,
	CARD_WIDTH = 142,
	CARD_HEIGHT = 162,
	CARDBACK_IMAGE = "FRC_Assets/FRC_MemoryGame/Images/PUFF_MemoryGame_global_Tile_Cardback.png",
	CARDFRONT_IMAGE = "FRC_Assets/FRC_MemoryGame/Images/PUFF_MemoryGame_global_Tile_Cardfront.png",
	CARD_PADDING_X = 25,
	CARD_PADDING_Y = 4,
	CARD_FLIP_TIME = 300,
	CARD_HIDE_TIME = 200
};

FRC_MemoryGame_Settings.DATA = {
	CARDS = "FRC_Assets/FRC_MemoryGame/Data/FRC_MemoryGame_Cards.json",
	CHOOSER_BUTTONS = "FRC_Assets/FRC_MemoryGame/Data/FRC_MemoryGame_DifficultyButtons.json"
};

return FRC_MemoryGame_Settings;