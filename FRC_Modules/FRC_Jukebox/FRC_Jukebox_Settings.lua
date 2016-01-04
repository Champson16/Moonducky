local FRC_Jukebox_Settings = {};

FRC_Jukebox_Settings.DEFAULTS = {
	POPUP_WIDTH = 1100,
	POPUP_HEIGHT = 700,
	BORDER_SIZE = 12,
	ELEMENT_PADDING = 12,
	BLANK_SLOT_IMAGE = 'FRC_Assets/FRC_GalleryPopup/Images/FRC_GalleryPopup_Icon_Blank.png',
	BLANK_SLOT_WIDTH = 142,
	BLANK_SLOT_HEIGHT = 125,
	PER_PAGE_ROWS = 1,
	PER_PAGE_COLS = 2,
	TOTAL_PAGES = 1,
	CLOSE_BUTTON_IMAGE = 'FRC_Assets/FRC_Jukebox/Images/FRC_Jukebox_Button_Close.png',
  CLOSE_BUTTON_HEIGHT = 50,
  CLOSE_BUTTON_WIDTH = 50
};

FRC_Jukebox_Settings.DATA = {
	MEDIA = {
		{
			MEDIA_TYPE = "VIDEO",
			MEDIA_TITLE = "HAMSTERS WANT TO BE FREE",
			POSTER_FRAME = 'MDMT_MusicVideo_HamsterWantToBeFree_Poster.png',
			HD_VIDEO_PATH = 'MDMT_MusicVideo_HamsterWantToBeFree.mp4',
			HD_VIDEO_SIZE = { width = 960, height = 540 },
			SD_VIDEO_PATH = 'MDMT_MusicVideo_HamsterWantToBeFree.mp4',
			SD_VIDEO_SIZE = { width = 960, height = 540 },
			VIDEO_SCALE = 'FULLSCREEN',
			VIDEO_LENGTH = 146000 },
		{
			MEDIA_TYPE = "VIDEO",
			MEDIA_TITLE = "MECHANICAL COW",
			POSTER_FRAME = 'MDMT_MusicVideo_MechanicalCow_Poster.png',
			HD_VIDEO_PATH = 'MDMT_MusicVideo_MechanicalCow.mp4',
			HD_VIDEO_SIZE = { width = 960, height = 540 },
			SD_VIDEO_PATH = 'MDMT_MusicVideo_MechanicalCow.mp4',
			SD_VIDEO_SIZE = { width = 960, height = 540 },
			VIDEO_SCALE = 'FULLSCREEN',
			VIDEO_LENGTH = 204000 },
		{
			MEDIA_TYPE = "VIDEO",
			MEDIA_TITLE = "KITTY CAT COMES TO TOWN",
			POSTER_FRAME = 'MDMT_MusicVideo_KittyCatComesToTown_Poster.png',
			HD_VIDEO_PATH = 'MDMT_MusicVideo_KittyCatComesToTown.mp4',
			HD_VIDEO_SIZE = { width = 960, height = 540 },
			SD_VIDEO_PATH = 'MDMT_MusicVideo_KittyCatComesToTown.mp4',
			SD_VIDEO_SIZE = { width = 960, height = 540 },
			VIDEO_SCALE = 'FULLSCREEN',
			VIDEO_LENGTH = 133000 },
		{
			MEDIA_TYPE = "VIDEO",
			MEDIA_TITLE = "PIE IN THE SKY",
			POSTER_FRAME = 'MDMT_MusicVideo_FloatingNotes_PieInTheSky_Poster.png',
			HD_VIDEO_PATH = 'MDMT_MusicVideo_FloatingNotes_PieInTheSky.mp4',
			HD_VIDEO_SIZE = { width = 960, height = 540 },
			SD_VIDEO_PATH = 'MDMT_MusicVideo_FloatingNotes_PieInTheSky.mp4',
			SD_VIDEO_SIZE = { width = 960, height = 540 },
			VIDEO_SCALE = 'FULLSCREEN',
			VIDEO_LENGTH = 176000 },
		{
			MEDIA_TYPE = "VIDEO",
			MEDIA_TITLE = "KANGAROOS UPSIDE DOWN",
			POSTER_FRAME = 'MDMT_MusicVideo_FloatingNotes_KangaroosUpsideDown_Poster.png',
			HD_VIDEO_PATH = 'MDMT_MusicVideo_FloatingNotes_KangaroosUpsideDown.mp4',
			HD_VIDEO_SIZE = { width = 960, height = 540 },
			SD_VIDEO_PATH = 'MDMT_MusicVideo_FloatingNotes_KangaroosUpsideDown.mp4',
			SD_VIDEO_SIZE = { width = 960, height = 540 },
			VIDEO_SCALE = 'FULLSCREEN',
			VIDEO_LENGTH = 129000 },
		{
			MEDIA_TYPE = "VIDEO",
			MEDIA_TITLE = "DREAM TIME",
			POSTER_FRAME = 'MDMT_MusicVideo_FloatingNotes_DreamTime_Poster.png',
			HD_VIDEO_PATH = 'MDMT_MusicVideo_FloatingNotes_DreamTime.mp4',
			HD_VIDEO_SIZE = { width = 960, height = 540 },
			SD_VIDEO_PATH = 'MDMT_MusicVideo_FloatingNotes_DreamTime.mp4',
			SD_VIDEO_SIZE = { width = 960, height = 540 },
			VIDEO_SCALE = 'FULLSCREEN',
			VIDEO_LENGTH = 164000 },
		{
			MEDIA_TYPE = "VIDEO",
			MEDIA_TITLE = "RAIN COME DOWN",
			POSTER_FRAME = 'MDMT_MusicVideo_FloatingNotes_RainComeDown_Poster.png',
			HD_VIDEO_PATH = 'MDMT_MusicVideo_FloatingNotes_RainComeDown.mp4',
			HD_VIDEO_SIZE = { width = 960, height = 540 },
			SD_VIDEO_PATH = 'MDMT_MusicVideo_FloatingNotes_RainComeDown.mp4',
			SD_VIDEO_SIZE = { width = 960, height = 540 },
			VIDEO_SCALE = 'FULLSCREEN',
			VIDEO_LENGTH = 127000 },
		{
			MEDIA_TYPE = "AUDIO",
			POSTER_FRAME = 'MDMT_MusicTheatre_HamsterWantToBeFree_Poster.png',
			MEDIA_TITLE = 'HAMSTERS WANT TO BE FREE',
			AUDIO_PATH = 'MDMT_global_BGMUSIC_HamstersJustWantToBeFree.mp3',
			AUDIO_LENGTH = 148000 },
		{
			MEDIA_TYPE = "AUDIO",
			POSTER_FRAME = 'MDMT_MusicTheatre_MechanicalCow_Poster.png',
			MEDIA_TITLE = 'MECHANICAL COW',
			AUDIO_PATH = 'MDMT_global_BGMUSIC_MechanicalCow.mp3',
			AUDIO_LENGTH = 210000 },
		{
			MEDIA_TYPE = "AUDIO",
			POSTER_FRAME = 'MDMT_MusicTheatre_KittyCatComesToTown_Poster.png',
			MEDIA_TITLE = 'KITTY CAT COMES TO TOWN',
			AUDIO_PATH = 'MDMT_global_BGMUSIC_KittyCatComesToTown.mp3',
			AUDIO_LENGTH = 135000 },
		{
			MEDIA_TYPE = "AUDIO",
			POSTER_FRAME = 'MDMT_MusicTheatre_Imagination_Poster.png',
			MEDIA_TITLE = 'IMAGINATION',
			AUDIO_PATH = 'MDMT_global_BGMUSIC_Imagination.mp3',
			AUDIO_LENGTH = 231000 },
		{
			MEDIA_TYPE = "AUDIO",
			POSTER_FRAME = 'MDMT_MusicTheatre_O-De-O_Poster.png',
			MEDIA_TITLE = 'O-DE-O',
			AUDIO_PATH = 'MDMT_global_BGMUSIC_O-De-O.mp3',
			AUDIO_LENGTH = 172000 },
	}
};

return FRC_Jukebox_Settings;
