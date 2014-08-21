
local version = "1.0.0";

local configPath = "FRC_Assets/FRC_Analytics/Data/FRC_Analytics_Config.json";
local defaultProvider = "flurry";
local debugPlatform = "apple";
local debugMode = false;

local FRC_DataLib = require("FRC_Modules.FRC_DataLib.FRC_DataLib");
local module = {};
local analytics;

local function detectPlatform()
	if (system.getInfo("environment") == "simulator") then
		module.platform = debugPlatform;
		debugMode = true;
		return;
	end

	local platform = system.getInfo("platformName");
	if (platformName == "iPhone OS") then
		module.platform = "apple";
		return;
	elseif (platformName == "WinPhone") then
		module.platform = "windows";
		return;
	else
		local targetAppStore = system.getInfo("targetAppStore");
		if (targetAppStore == "nook") then
			module.platform = "nook";
		elseif (targetAppStore == "amazon") then
			module.platform = "amazon";
		elseif (targetAppStore == "samsung") then
			module.platform = "samsung";
		elseif (platformName == "Android") then
			-- check for Tabeo device
			if (string.find(system.getInfo("model"), "TABEO")) then
				module.platform = "tabeo";
			else
				module.platform = "google";
			end
		else
			module.platform = platform;
		end
	end
end

module.init = function(provider)
	if (analytics) then return; end -- already initialized
	module.provider = provider or defaultProvider;
	module.config = FRC_DataLib.readJSON(configPath, system.ResourceDirectory);
	detectPlatform();

	local initKey = module.config[module.provider][module.platform];
	if (not initKey or (initKey == "")) then return; end

	analytics = require("analytics");
	analytics.init(initKey);

	if (debugMode) then
		print("Initialized analytics: ");
		print("", "provider: " .. module.provider);
		print("", "platform: " .. module.platform);
		print("", "key: " .. initKey);
	end
end

module.logEvent = function(eventData)
	if (not analytics) then return; end
	analytics.logEvent(eventData);
	if (debugMode) then
		if (type(eventData) ~= "table") then
			print("Logged analytics event (string): " .. tostring(eventData));
		else
			print("Logged analytics event (table):");
			for k,v in pairs(eventData) do
				print("", k, v);
			end
		end
	end
end

return module;
