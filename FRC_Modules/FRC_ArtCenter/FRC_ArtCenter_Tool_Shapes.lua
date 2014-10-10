local FRC_ArtCenter_Tool_Stamps = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Tool_Stamps');
local FRC_ArtCenter_Tool_Shapes = {};

FRC_ArtCenter_Tool_Shapes.SELECTION_COLOR = FRC_ArtCenter_Tool_Stamps.SELECTION_COLOR;

FRC_ArtCenter_Tool_Shapes.onCanvasTouch = FRC_ArtCenter_Tool_Stamps.onCanvasTouch;

FRC_ArtCenter_Tool_Shapes.onShapePinch = FRC_ArtCenter_Tool_Stamps.onStampPinch;

return FRC_ArtCenter_Tool_Shapes;
