local StampPlacement = require('scenes.ArtCenter.Tools.StampPlacement');
local Shape = {};

Shape.SELECTION_COLOR = StampPlacement.SELECTION_COLOR;

Shape.onCanvasTouch = StampPlacement.onCanvasTouch;

Shape.onShapePinch = StampPlacement.onStampPinch;

return Shape;