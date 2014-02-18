local storyboard = require 'storyboard';
local Module = {};

-- PUBLIC FUNCTIONS

Module.new = function(modulePath, customAttributes)
	local m = {};
	m.callee = '';

	-- methods
	m.checkArgs = Module.checkArgs;
	m.newScene = Module.newScene;
	m.addAssetPath = Module.addAssetPath;
	m.assetPath = Module.assetPath;
	m.getDisposable = Module.getDisposable;
	m.addDisposable = Module.addDisposable;
	m.freeDisposables = Module.freeDisposables;
	m.newTimer = Module.newTimer;
	m.newTransition = Module.newTransition;
	m.cancelTimer = Module.cancelTimer;
	m.cancelTransition = Module.cancelTransition;
	m.dispose = Module.dispose;
	m.disposeSelf = Module.disposeSelf;

	-- modules should keep track of their own (and their submodule's) timers & transitions
	m.timers = {};
	m.transitions = {};

	-- Any objects that are created that need to have 'dispose()' called to completely
	-- free from memory should be stored in the primary module's 'disposables' array.
	m.disposables = {};

	-- Any assets (e.g. file paths) required by module or submodules should be stored in
	-- the 'assetPaths' table.
	m.assetPaths = {};

	-- get attributes from 'attributes.lua' module in modulePath
	local attributes_exist = pcall(function() m.attributes = require(modulePath .. '.attributes'); end);
	if (not attributes_exist) then
		m.attributes = {};
	end
	if (not m.attributes.assetPaths) then
		m.attributes.assetPaths = {};
	end

	-- override any custom attributes with user-defined values
	if (customAttributes) then
		for k,v in pairs(customAttributes) do
			if (type(v) == 'table') then
				if (not m.attributes[k]) then m.attributes[k] = {}; end
				for key,value in pairs(v) do
					m.attributes[k][key] = value;
				end
			else
				m.attributes[k] = v;
			end
		end
	end

	-- add any overriden assetPaths passed into the constructor
	for k,v in pairs(m.attributes.assetPaths) do
		if ((#m.attributes.assetPaths[k]) == 2) then
			-- custom assets should be passed as a 2-item array [1] assetIdentifier [2] path
			self:assetPath(m.attributes.assetPaths[k][1], m.attributes.assetPaths[k][2]);
		else
			print('Custom assets passed to modules must be an array with 2 items: [1] assetIdenfitier [2] path');
		end
	end

	return m;
end

-- INSTANCE METHODS

Module.checkArgs = function(self, callee, options, required, defaults)
 	assert(callee);
 	assert(type(callee) == 'string');
	assert(options);
	assert(required);

	self.callee = callee;
	local missing_required = {};
	local wrongtype_required = {};

	for k,v in pairs(required) do
		-- check for all required options
		if (not options[k]) then
			table.insert(missing_required, k);
		else
			if (type(options[k]) ~= v) then
				table.insert(wrongtype_required, k);
			end
		end
	end

	if (#missing_required > 0) then
		error('Missing options for ' .. self.callee .. ': ' .. tostring(unpack(missing_required)));
	end

	if (#wrongtype_required > 0) then
		local unpacked = ''
		for i=1,#wrongtype_required do
			if (i ~= 1) then unpacked = unpacked .. ', '; end
			unpacked = unpacked .. wrongtype_required[i] .. ' (' .. required[wrongtype_required[i]] .. ')';
		end
		error('Wrong type for option(s) in ' .. self.callee .. ': ' .. unpacked);
	end

	-- check options table for default keys (if key is not present, use default)
	if (defaults) then
		for k,v in pairs(defaults) do
			if (options[k] == nil) then
				options[k] = v;
			end
		end
	end

	return options;
end

Module.newScene = function(self, sceneName)
	local scene;
	if (sceneName) then
		scene = storyboard.newScene(sceneName);
	else
		scene = storyboard.newScene();
	end

	local sceneEvents = {
		'createScene',
		'destroyScene',
		'didExitScene',
		'enterScene',
		'exitScene',
		'overlayBegan',
		'overlayEnded',
		'willEnterScene'
	};

	for i=1,#sceneEvents do
		local eventName = sceneEvents[i];
		local onSceneEvent = function(event)
			local targetScene = event.target;

			if (targetScene['pre_' .. eventName]) then
				targetScene['pre_' .. eventName](targetScene, event);
			end

			if (targetScene[eventName]) then
				targetScene[eventName](targetScene, event);
			end

			if (targetScene['post_' .. eventName]) then
				targetScene['post_' .. eventName](targetScene, event);
			end
		end
		scene:addEventListener(eventName, onSceneEvent);
	end

	return scene;
end

Module.assetPath = function(self, assetName, path)
	if (path) then
		local overwritten = false;
		if (self.assetPaths[assetName]) then
			overwritten = true;
			self.assetPaths[assetName] = path;
		end
		return overwritten;
	else
		local assetPath = false;
		if (self.assetPaths[assetName]) then
			asset = self.assetPaths[assetName];
		end
		return assetPath;
	end
end

Module.getDisposable = function(self, obj)
	if ((not self.disposables) or (#self.disposables == 0) or (not obj)) then return false; end
	local result = false;
	for i=1,#self.disposables do
		if (self.disposables[i] == obj) then
			result = self.disposables[i];
			break;
		end
	end
	return result;
end

Module.addDisposable = function(self, obj)
	assert(obj, 'You must specify object to add as disposable (did you use \'.\' instead of \':\'?)');
	local added = self:getDisposable(obj);
	if (not added) then
		table.insert(self.disposables, obj);
	end
end

Module.freeDisposables = function(self, disableGC)
	assert(self, 'You must use \':\' instead of a \'.\' when calling this method.');
	if ((not self.disposables) or (#self.disposables == 0)) then return; end
	for i=1,#self.disposables do
		self:dispose(self.disposables[i]);
	end
	self.disposables = {};
	if (not disableGC) then collectgarbage('collect'); end
end

Module.newTimer = function(self, ...)
	local t = timer.performWithDelay(...);
	self.timers[#self.timers+1] = t;
	return t;
end

Module.newTransition = function(self, ...)
	local t = transition.to(...);
	self.transitions[#self.transitions+1] = t;
	return t;
end

Module.cancelTimer = function(self, timerInstance)
	if (not self.timers) then return false; end

	for i=#self.timers,1,-1 do
		if (self.timers[i] == timerInstance) then
			pcall(function() timer.cancel(self.timers[i]); end);
			self.timers[i] = nil;
			break;
		end
	end
	return nil;
end

Module.cancelTransition = function(self, transitionInstance)
	if (not self.transitions) then return false; end
	local result = false;

	for i=#self.transitions,1,-1 do
		if (self.transitions[i] == transitionInstance) then
			pcall(function() transition.cancel(self.transitions[i]); end);
			self.transitions[i] = nil;
			result = true;
			break;
		end
	end
	return nil;
end

Module.dispose = function(self, obj)
	if (not obj) then
		self:disposeSelf();
	else
		if ((obj.dispose) and (type(obj.dispose) == 'function')) then
			if (obj.enterframe) then
				Runtime:removeEventListener('enterFrame', obj.enterframe);
				obj.enterframe = nil;
			end
			if (obj.enterFrame) then
				Runtime:removeEventListener('enterFrame', obj.enterFrame);
				obj.enterFrame = nil;
			end
			obj:dispose();

			-- remove object from disposables array
			for i=1,#self.disposables do
				if (self.disposables[i] == obj) then
					table.remove(self.disposables, i);
				end
			end
		end
	end
end

Module.disposeSelf = function(self)
	assert(self, 'You must use \':\' instead of a \'.\' when calling this method.');
	
	-- Cancel and free all timers
	if (self.timers) then
		for i=#self.timers,1,-1 do
			self:cancelTimer(self.timers[i]);
		end
		self.timers = {};
	end

	-- Cancel and free all transitions
	if (self.transitions) then
		for i=#self.transitions,1,-1 do
			self:cancelTransition(self.transitions[i]);
		end
		self.transitions = {};
	end

	-- Dispose of any tracked disposable objects
	self:freeDisposables(true);

	self.assetPaths = {};
	self.attributes = {};
	collectgarbage('collect');
end

return Module;