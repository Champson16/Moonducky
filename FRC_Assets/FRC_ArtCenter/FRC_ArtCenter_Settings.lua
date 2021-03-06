local settings = {};

-- PER-APP CHANGEABLE SETTINGS

settings.DISABLE_STORE = true;

settings.UI = {
	IMAGE_BASE_PATH = 'FRC_Assets/FRC_ArtCenter/Images/',
	DEFAULT_CANVAS_COLOR = .956862745,
	PALETTE_TOP_MARGIN = 38; -- 42,
	CANVAS_TOP_MARGIN = 42,
	CANVAS_BORDER = 3,
	SELECTOR_WIDTH = 130,
	ELEMENT_PADDING = 4,
	ERASER_BRUSH = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_FreehandPaintBasic_Brush_Eraser.png',
	ERASER_BUTTON_IMAGE = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Eraser.png',
	ERASER_BUTTON_IMAGE_FOCUSED = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Eraser_focused.png',
	ERASER_BUTTON_IMAGE_DISABLED = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Eraser_disabled.png',
	SCENE_BACKGROUND_IMAGE = 'FRC_Assets/FRC_ArtCenter/Images/FRC_ArtCenter_Background.png',
	SCENE_BACKGROUND_WIDTH = 1440,
	SCENE_BACKGROUND_HEIGHT = 768,
	SCALE_BACKGROUND = true,
	COLOR_PREVIEW_IMAGE = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Color_Blank.png',
	BLANK_TEXTURE_IMAGE = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Texture_Blank.jpg',
	NOCOLOR_COLOR = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Color_NoColor.png',
	BLANK_COLOR	= 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Color_Blank.png',
	BLANK_COLOR_FOCUSED = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_Color_Blank_focused.png',
	COLOR_PALETTE_LEFT_PADDING = 50,
	COLOR_PALETTE_BOTTOM_PADDING = 0,
	COLOR_WIDTH = 64,
	COLOR_HEIGHT = 64,
	COLOR_PADDING = 16,
	TEXTURE_WIDTH = 100,
	TEXTURE_HEIGHT = 50,
	TEXTURE_PADDING = 16,
	TEXTURE_BGCOLOR = { 1.0, 1.0, 1.0, 0 },
	TEXTURE_BORDER_COLOR = { 0, 0, 0, 1.0 },
	TEXTURE_BORDER_RADIUS = 11,
	TEXTURE_BORDER_WIDTH = 0,
	SUBTOOL_PALETTE_LEFT_PADDING = 50,
	SUBTOOL_SELECTION_IMAGE = 'FRC_Assets/FRC_ArtCenter/Images/FRC_UX_ArtCenter_SubToolSelection.png',
	SUBTOOL_SELECTION_WIDTH = 86,
	SUBTOOL_SELECTION_HEIGHT = 86,
	SUBTOOL_DEFAULT_BUTTON_SIZE = 50,
	SUBTOOL_BUTTON_PADDING = 15,
	BACKGROUND_SUBTOOL_BUTTON_WIDTH = 100,
	BACKGROUND_SUBTOOL_BUTTON_HEIGHT = 66,
	BACKGROUND_SUBTOOL_BUTTON_BGCOLOR = { 1.0, 1.0, 1.0, 1.0 },
	FREEHAND_SUBTOOL_BRUSH_BUTTON_SIZE = 50,
	FREEHAND_SUBTOOL_ICON_BUTTON_SIZE = 80,
	SHAPE_SUBTOOL_BUTTON_SIZE = 100,
	STAMP_SUBTOOL_BUTTON_WIDTH = 100,
	STYLE_SELECTION_ARROW_IMAGE = 'FRC_Assets/FRC_ArtCenter/Images/FRC_ArtCenter_global_StyleSelectionArrow.png',
	STYLE_SELECTION_ARROW_WIDTH = 18,
	STYLE_SELECTION_ARROW_HEIGHT = 18,
	ANIMATION_XML_BASE = 'FRC_Assets/MDMT_Assets/Animation/XMLData/',
	ANIMATION_IMAGE_BASE = 'FRC_Assets/MDMT_Assets/Animation/Images/',
	STAMP_SELECTION_COLOR = { 0, 0.5, 1.0 },
	STAMP_MIN_SIZE = 60,
	STAMP_MAX_SCALE = 3,
	STAMP_SELECTION_PADDING = 5
};

settings.DATA = {
	DATA_FILENAME = 'FRC_ArtCenter_Saved.json',
	SAVE_PROMPT = 'Save Your MoonDucky Artwork',
	LOAD_PROMPT = 'Load Your MoonDucky Artwork',
	COLORS = 'FRC_Assets/FRC_ArtCenter/Data/FRC_ArtCenter_Colors.json',
	TEXTURES = 'FRC_Assets/FRC_ArtCenter/Data/FRC_ArtCenter_Textures.json',
	TOOLS = 'FRC_Assets/FRC_ArtCenter/Data/FRC_ArtCenter_Tools.json',
	SCENELAYOUT = 'FRC_Assets/FRC_ArtCenter/Data/FRC_ArtCenter_SceneLayout.json',
	EMPTY_DATAFILE = '{ "owner": "FRC_ArtCenter", "savedItems": [] }'
};

settings.AUDIO = {
	MENU_SWOOSH_AUDIO = 'FRC_Assets/FRC_ArtCenter/Audio/FRC_global_ArtCenter_MenuSwoosh.mp3'
};

settings.CONFIG = {
    subtools = {
        left = {
            disableAnimation = false,
            hideBackground = false,
            left = 0
        },
        right =  {
            disableAnimation = false,
            hideBackground = false,
            right = 0
        }
    }
};

settings.MODES = {
	FREEHAND_DRAW = 1,
	BACKGROUND_SELECTION = 2,
	SHAPE_PLACEMENT = 3,
	STAMP_PLACEMENT = 4,
	ERASE = 5
};

return settings;
