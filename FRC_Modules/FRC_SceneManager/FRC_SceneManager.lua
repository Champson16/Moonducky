local FRC_SceneManager = {};
FRC_SceneManager.stage = display.newGroup();
FRC_SceneManager.previousSceneName = '';
FRC_SceneManager.currentSceneName = '';

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

FRC_SceneManager.newScene = function(sceneName)
	return Runtime._super:new();
end

FRC_SceneManager.getPrevious = function()
	return FRC_SceneManager.previousSceneName;
end

FRC_SceneManager.getCurrentSceneName = function()
	return FRC_SceneManager.currentSceneName;
end

FRC_SceneManager.getScene = function(sceneName)
	return package.loaded[sceneName];
end

FRC_SceneManager.getCurrentScene = function()
	return package.loaded[FRC_SceneManager.currentSceneName];
end

FRC_SceneManager.loadScene = function(sceneName, data)
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
		FRC_SceneManager.stage:insert(scene.view);

		scene:dispatchEvent({ name="createScene", target=scene, data=data });
	end
	return scene;
end

FRC_SceneManager.gotoScene = function(sceneName, options)
	assert(sceneName);
	local options = options or {};
	local current = FRC_SceneManager.getCurrentScene();
	
	if (current) then
		FRC_SceneManager.purgeScene(FRC_SceneManager.currentSceneName);
	end

	FRC_SceneManager.previousSceneName = FRC_SceneManager.currentSceneName;
	FRC_SceneManager.currentSceneName = sceneName;
	
	local scene = FRC_SceneManager.loadScene(sceneName, options.data);
	scene:dispatchEvent({ name="willEnterScene", target=scene, data=options.data});
	scene.view.isVisible = true;
	scene:dispatchEvent({ name="enterScene", target=scene, data=options.data});
end

FRC_SceneManager.purgeScene = function(sceneName, data)
	local scene = FRC_SceneManager.getScene(sceneName);
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

FRC_SceneManager.removeScene = function(sceneName, data)
	local scene = FRC_SceneManager.getScene(sceneName);

	if (scene) then
		FRC_SceneManager.purgeScene(sceneName);
		package.loaded[sceneName] = nil;
		return true;
	end

	return false;
end

FRC_SceneManager.purgeAll = function()
	--FRC_SceneManager.purgeScene(FRC_SceneManager.currentSceneName);
end

FRC_SceneManager.removeAll = function()
	-- stub
	return true;
end

return FRC_SceneManager;