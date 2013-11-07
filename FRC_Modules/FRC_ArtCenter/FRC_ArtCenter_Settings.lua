local settings = {};

-- PER-APP CHANGEABLE SETTINGS

settings.UI = {
	IMAGE_BASE_PATH = 'FRC_Assets/FRC_ArtCenter/Images/',
	DEFAULT_CANVAS_COLOR = .956862745,
	CANVAS_TOP_MARGIN = 42,
	CANVAS_BORDER = 3,
	SELECTOR_WIDTH = 130,
	ELEMENT_PADDING = 4,
	ERASER_BRUSH = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_FreehandPaintBasic_Brush_PaintBrush1.png',
	ERASER_BUTTON_IMAGE = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Eraser.png',
	ERASER_BUTTON_IMAGE_FOCUSED = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Eraser_focused.png',
	ERASER_BUTTON_IMAGE_DISABLED = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Eraser_disabled.png',
	SCENE_BACKGROUND_IMAGE = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Background_global_main.jpg',
	SCENE_BACKGROUND_WIDTH = display.contentWidth,
	SCENE_BACKGROUND_HEIGHT = display.contentHeight,
	COLOR_PREVIEW_IMAGE = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Color_Blank.png',
	BLANK_TEXTURE_IMAGE = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Texture_Blank.jpg',
	NOCOLOR_COLOR = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Color_NoColor.png',
	BLANK_COLOR	= 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Color_Blank.png',
	COLOR_WIDTH = 64,
	COLOR_HEIGHT = 64,
	COLOR_PADDING = 16,
	TEXTURE_WIDTH = 100,
	TEXTURE_HEIGHT = 50,
	TEXTURE_PADDING = 16,
	SUBTOOL_SELECTION_IMAGE = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_SubToolSelection.png',
	SUBTOOL_SELECTION_WIDTH = 86,
	SUBTOOL_SELECTION_HEIGHT = 86,
	SUBTOOL_DEFAULT_BUTTON_SIZE = 50,
	SUBTOOL_BUTTON_PADDING = 15,
	BACKGROUND_SUBTOOL_BUTTON_WIDTH = 80,
	BACKGROUND_SUBTOOL_BUTTON_HEIGHT = 53,
	BACKGROUND_SUBTOOL_BUTTON_BGCOLOR = { 1.0, 1.0, 1.0, 1.0 },
	FREEHAND_SUBTOOL_BRUSH_BUTTON_SIZE = 50,
	FREEHAND_SUBTOOL_ICON_BUTTON_SIZE = 80,
	SHAPE_SUBTOOL_BUTTON_SIZE = 80,
	STAMP_SUBTOOL_BUTTON_WIDTH = 80
};

settings.DATA = {
	COLORS = 'FRC_Assets/FRC_ArtCenter/Data/FRC_ArtCenter_Colors.json',
	TEXTURES = 'FRC_Assets/FRC_ArtCenter/Data/FRC_ArtCenter_Textures.json',
	TOOLS = 'FRC_Assets/FRC_ArtCenter/Data/FRC_ArtCenter_Tools.json'
};

-- CONSTANTS:

settings.MODES = {
	FREEHAND_DRAW = 1,
	BACKGROUND_SELECTION = 2,
	SHAPE_PLACEMENT = 3,
	STAMP_PLACEMENT = 4,
	ERASE = 5	
};

return settings;