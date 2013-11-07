local ui = require('FRC_Modules.FRC_UI.FRC_UI');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');

local DATA_PATH = 'FRC_Assets/FRC_ArtCenter/Data/FRC_ArtCenter_Textures.json';
local BUTTON_WIDTH = 100;
local BUTTON_HEIGHT = 50;
local BUTTON_PADDING = 16;

local TextureSelector = {};

-- Texture from palette is selected
local function onButtonRelease(event)
	local self = event.target;
	local scene = self._scene;
	local showSelectedTexture = true;

	if (scene.mode == scene.modes.BACKGROUND_SELECTION) then
		scene.canvas:setBackgroundTexture(self._texturePath);
		scene.canvas:fillBackground(scene.currentColor.preview.r, scene.currentColor.preview.g, scene.currentColor.preview.b, 1.0);
		showSelectedTexture = true;
	
	elseif (scene.mode == scene.modes.SHAPE_PLACEMENT) then

		if ((scene.objectSelection) and (scene.objectSelection.selectedObject)) then
			local obj = scene.objectSelection.selectedObject[1];
			if (scene.mode == scene.modes.SHAPE_PLACEMENT) then
				if (self.id == "Blank") then
					if ((scene.currentColor.preview.r == scene.DEFAULT_CANVAS_COLOR) and (scene.currentColor.preview.g == scene.DEFAULT_CANVAS_COLOR) and (scene.currentColor.preview.g == scene.DEFAULT_CANVAS_COLOR)) then
						obj:setFillColor(scene.currentColor.preview.r, scene.currentColor.preview.g, scene.currentColor.preview.b, 0);
						obj:setStrokeColor(0, 0, 0, 1.0);
						obj.strokeWidth = 5;
					else
						obj.fill = { type="image", filename=self._texturePath };
						obj:setFillColor(scene.currentColor.preview.r, scene.currentColor.preview.g, scene.currentColor.preview.b, 1.0);
						obj.strokeWidth = 0;
					end
				else
					obj.fill = { type="image", filename=self._texturePath };
					obj:setFillColor(scene.currentColor.preview.r, scene.currentColor.preview.g, scene.currentColor.preview.b, 1.0);
					obj.strokeWidth = 0;
				end
			else
				obj:setFillColor(scene.currentColor.preview.r, scene.currentColor.preview.g, scene.currentColor.preview.b, 1.0);
			end
		end
		showSelectedTexture = true;
	end

	if (showSelectedTexture) then
		scene.currentColor.texturePreview.id = self.id;
		self._parent:setTexture(self._texturePath);
	end
end

local function setTexture(self, imagePath)
	if (imagePath) then
		self._scene.currentColor.texturePreview.fill = { type="image", filename=imagePath };
		self._scene.currentColor.texturePreview._imagePath = imagePath;

		local r, g, b = self._scene.currentColor.preview.r, self._scene.currentColor.preview.g, self._scene.currentColor.preview.b;

		if ((r == self._scene.DEFAULT_CANVAS_COLOR) and (g == self._scene.DEFAULT_CANVAS_COLOR) and (b == self._scene.DEFAULT_CANVAS_COLOR)) then
			self._scene.currentColor.texturePreview:setFillColor(1.0, 1.0, 1.0, 1.0);
		else
			self._scene.currentColor.texturePreview:setFillColor(r, g, b, 0.5);
		end
	else
		self._scene.currentColor.texturePreview.fill = nil;
	end
end

TextureSelector.new = function(scene, width, height)
	local group = ui.scrollContainer.new({
		width = width,
		height = height,
		xScroll = false,
		topPadding = BUTTON_PADDING,
		bottomPadding = BUTTON_PADDING,
		bgColor = { 0.14, 0.14, 0.14 },
		borderRadius = 11,
		borderWidth = 6,
		borderColor = { 0, 0, 0, 1.0 }
	});
	local textures = FRC_DataLib.readJSON(DATA_PATH).textures;

	for i=1,#textures do
		local c = textures[i];
		local button = ui.button.new({
			id = textures[i].id,
			width = BUTTON_WIDTH,
			height = BUTTON_HEIGHT,
			rect = true,
			bgColor = { 1.0, 1.0, 1.0, 1.0 },
			pressAlpha = 0.5
		});
		button.id = textures[i].id;
		button._parent = group;
		button._scene = scene;
		button.anchorY = 0.5;
		button.x = 3;
		button.y = -(height * 0.5) + (button.height * 0.5) + BUTTON_PADDING + (i-1) * (BUTTON_HEIGHT + BUTTON_PADDING);

		button._texturePath = 'FRC_Assets/FRC_ArtCenter/Images/' .. textures[i].imageFile;
		button.up.fill = { type="image", filename=button._texturePath };
		button.down.fill = { type="image", filename=button._texturePath };
		
		button.up.fill.scaleX = 1.0;
		button.up.fill.scaleY = BUTTON_WIDTH / BUTTON_HEIGHT;
		button.down.fill.scaleX = 1.0;
		button.down.fill.scaleY = BUTTON_WIDTH / BUTTON_HEIGHT;
		
		button:addEventListener('release', onButtonRelease);
		group:insert(button);
	end

	group.setTexture = setTexture;
	group._scene = scene;

	if (scene) then scene.view:insert(group); end
	return group;
end

return TextureSelector;