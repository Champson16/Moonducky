local AudioHandle = {};

local AudioManager = require("FRC_Modules.FRC_AudioManager.FRC_AudioManager");
local AudioGroup = require("FRC_Modules.FRC_AudioManager.FRC_AudioGroup");

local function throw(errorMessage)
	error("[" .. AudioManager.name .. " ERROR]: " .. errorMessage);
end

local function warn(warnMessage)
	print("[" .. AudioManager.name .. " WARNING]: " .. warnMessage);
end

local public = {};

function public:play(options)
	options = options or {};
	local cached_onComplete = options.onComplete;
	options.onComplete = function(event)
		if (event.completed) then
			self.channel = nil;
		end
		if (cached_onComplete) then
			cached_onComplete(event);
		end
	end

	if (self.group) then
		local channel;
		if (self.channel and options.force) then
			channel = self.channel;
			self:stop();
		else
			channel = self.group:findFreeChannel();
		end

		if (channel) then
			options.channel = channel;
			local playChannel;
			pcall(function() playChannel = audio.play(self.handle, options); end);
			if (playChannel and playChannel ~= 0) then
				self.channel = playChannel;
			end

			-- append channel to end of group's channel array (so group.channels[1] is always least recently used)
			local removeCount = 0;
			for i=#self.group.channels,1,-1 do
				if (self.group.channels[i] == channel) then
					table.remove(self.group.channels, i);
					removeCount = removeCount + 1;
				end
			end
			if (removeCount > 0) then
				table.insert(self.group.channels, channel);
			end
		end
	else
		-- instance does not belong to a group; treat it as a raw call to audio.play()
		local playChannel;
		pcall(function() playChannel = audio.play(self.handle, options); end);
		if (playChannel and playChannel ~= 0) then
			self.channel = playChannel;
		end
	end
	return self.channel or 0;
end

function public:isPlaying()
	local result = false;
	if (self.channel) then
		result = true;
	end
	return result;
end

function public:stop(options)
	options = options or {};
	if (self.channel) then
		if (options.delay) then
			pcall(function() audio.stopWithDelay(options.delay, { channel = self.channel }); end);
		else
			pcall(function() audio.stop(self.channel); end);
		end
		self.channel = nil;
	end
	return self;
end

function public:pause()
	if (self.channel) then
		pcall(function() audio.pause(self.channel); end);
	end
	return self;
end

function public:rewindAudio()
	if (self.channel) then
		if (self.loadMethod == "loadSound") then
		  pcall(function() audio.rewind({channel = self.channel}); end);
		else
			pcall(function() audio.rewind(self.handle); end);
		end
	end
	return self;
end

function public:resume()
	if (self.channel) then
		pcall(function() audio.resume(self.channel); end);
	end
	return self;
end

function public:getDuration()
	local duration = 0;
	pcall(function() duration = audio.getDuration(self.handle); end);
	return duration;
end

function public:dispose()
	self:stop();
	self.name = nil;
	self.path = nil;
	self.group = nil;
	pcall(function() audio.dispose(self.handle); end);
	self.handle = nil;
end

function AudioHandle.new(options)
	options = options or {};
	-- valid options are: name (string), path (string), useLoadSound (boolean), group (group object or string)
	if (options.name) then
		if (AudioManager:isHandleNameTaken(options.name)) then
			local chosenName = options.name;
			options.name = AudioManager:getUniqueHandleName();
			warn("AudioHandle name " .. chosenName .. " is already in use; using unique name: " .. options.name);
		end
	end

	if (not options.path) then throw("You must specify a [path] options when instantiating a new AudioHandle."); end
	local audioHandle = {};
	if (options.useLoadSound) then
		audioHandle.handle = audio.loadSound(options.path);
		audioHandle.loadMethod = "loadSound";
	else
		audioHandle.handle = audio.loadStream(options.path);
		audioHandle.loadMethod = "loadStream";
	end
	audioHandle.name = options.name or AudioManager:getUniqueHandleName();
	audioHandle.path = options.path;

	-- add all public instance methods
	for k,v in pairs(public) do
		audioHandle[k] = v;
	end

	-- options.group can either be a group name (string) or an AudioGroup instance
	if (options.group) then
		local group;
		if (type(options.group) == "string") then
			group = AudioManager:findGroup(options.group);
		else
			group = options.group;
		end
		if (group) then
			group:addHandle(audioHandle);
		end
	end

	return audioHandle;
end

return AudioHandle;
