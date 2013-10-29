local stage = {};
stage.stage = display.newGroup();
stage.previousSceneName = '';
stage.currentSceneName = '';

--[[
Scene events:

- createScene

- willEnterScene (pre)
- enterScene (post)

- exitScene (pre)
- didExitScene (post)

- overlayBegan
- overlayEnded

- destroyScene
--]]

--- Gets screen full screen dimensions (including margins outside of content bounds)
local getScreenDimensions = function()
	local screenW = display.actualContentWidth;
	local screenH = display.actualContentHeight;
	if (display.contentWidth > display.contentHeight) then
		screenW = display.actualContentHeight;
		screenH = display.actualContentWidth;
	end
	return screenW, screenH;
end

stage.newScene = function(sceneName)
	return Runtime._super:new();
end

stage.getPrevious = function()
	return stage.previousSceneName;
end

stage.getCurrentSceneName = function()
	return stage.currentSceneName;
end

stage.getScene = function(sceneName)
	return package.loaded[sceneName];
end

stage.getCurrentScene = function()
	return package.loaded[stage.currentSceneName];
end

stage.loadScene = function(sceneName, data)
	assert(sceneName);
	local scene = require(sceneName);
	if (not scene.view) then
		local w, h = getScreenDimensions();
		--scene.view = display.newContainer(w, h);
		--scene.view.anchorChildren = false;
		--scene.view.anchorX = 0;
		--scene.view.anchorY = 0;
		scene.view = display.newGroup();
		scene.view.isVisible = false;
		stage.stage:insert(scene.view);

		scene:dispatchEvent({ name="createScene", target=scene, data=data });
	end
	return scene;
end

stage.gotoScene = function(sceneName, options)
	assert(sceneName);
	local options = options or {};
	local current = stage.getCurrentScene();
	
	if (current) then
		stage.purgeScene(stage.currentSceneName);
	end

	stage.previousSceneName = stage.currentSceneName;
	stage.currentSceneName = sceneName;
	
	local scene = stage.loadScene(sceneName, options.data);
	scene:dispatchEvent({ name="willEnterScene", target=scene, data=options.data});
	scene.view.isVisible = true;
	scene:dispatchEvent({ name="enterScene", target=scene, data=options.data});
end

stage.purgeScene = function(sceneName, data)
	local scene = stage.getScene(sceneName);
	if (scene) then
		if (scene.view) then
			if (scene.view.isVisible) then
				scene:dispatchEvent({ name="exitScene", target=scene, data=data });
				scene.view.isVisible = false;
				scene:dispatchEvent({ name="didExitScene", target=scene, data=data });
			end
			scene:dispatchEvent({ name="destroyScene", target=scene, data=data });
			if (scene.view) then
				scene.view:removeSelf();
				scene.view = nil;
			end
			return true
		end
	end
	return false;
end

stage.removeScene = function(sceneName, data)
	local scene = stage.getScene(sceneName);

	if (scene) then
		stage.purgeScene(sceneName);
		package.loaded[sceneName] = nil;
		return true;
	end

	return false;
end

stage.purgeAll = function()
	--stage.purgeScene(stage.currentSceneName);
end

stage.removeAll = function()
	-- stub
	return true;
end

return stage;