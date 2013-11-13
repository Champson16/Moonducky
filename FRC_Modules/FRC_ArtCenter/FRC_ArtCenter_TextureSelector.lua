local FRC_ArtCenter_Settings = require('FRC_Modules.FRC_ArtCenter.FRC_ArtCenter_Settings');
local ui = require('FRC_Modules.FRC_UI.FRC_UI');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');

local TextureSelector = {};

-- Texture from palette is selected
local function onButtonRelease(event)
	local self = event.target;
	local scene = self._scene;
	local showSelectedTexture = true;
	local canvasColor = FRC_ArtCenter_Settings.UI.DEFAULT_CANVAS_COLOR;

	if (scene.mode == scene.modes.BACKGROUND_SELECTION) then
		scene.canvas:setBackgroundTexture(self._texturePath);
		scene.canvas:fillBackground(scene.currentColor.preview.r, scene.currentColor.preview.g, scene.currentColor.preview.b, 1.0);
		showSelectedTexture = true;
	
	elseif (scene.mode == scene.modes.SHAPE_PLACEMENT) then

		if ((scene.objectSelection) and (scene.objectSelection.selectedObject)) then
			local obj = scene.objectSelection.selectedObject[1];
			if (scene.mode == scene.modes.SHAPE_PLACEMENT) then
				if (self.id == "Blank") then
					if ((scene.currentColor.preview.r == canvasColor) and (scene.currentColor.preview.g == canvasColor) and (scene.currentColor.preview.g == canvasColor)) then
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
		local canvasColor = FRC_ArtCenter_Settings.UI.DEFAULT_CANVAS_COLOR;

		if ((r == canvasColor) and (g == canvasColor) and (b == canvasColor)) then
			self._scene.currentColor.texturePreview:setFillColor(1.0, 1.0, 1.0, 1.0);
		else
			self._scene.currentColor.texturePreview:setFillColor(r, g, b, 0.5);
		end
	else
		self._scene.currentColor.texturePreview.fill = nil;
	end
end

TextureSelector.new = function(scene, width, height)
	local BUTTON_WIDTH = FRC_ArtCenter_Settings.UI.TEXTURE_WIDTH;
	local BUTTON_HEIGHT = FRC_ArtCenter_Settings.UI.TEXTURE_HEIGHT;
	local BUTTON_PADDING = FRC_ArtCenter_Settings.UI.TEXTURE_PADDING;

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
	local textures = FRC_DataLib.readJSON(FRC_ArtCenter_Settings.DATA.TEXTURES).textures;

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

		button._texturePath = FRC_ArtCenter_Settings.UI.IMAGE_BASE_PATH .. textures[i].imageFile;
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