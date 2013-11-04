local StampPlacement = require('scenes.ArtCenter.Tools.StampPlacement');
local Shape = {};

Shape.onCanvasTouch = StampPlacement.onCanvasTouch;

Shape.onShapePinch = StampPlacement.onStampPinch;

return Shape;