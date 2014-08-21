local version = "1.0.0";

local configPath = "FRC_Assets/FRC_Ratings/Data/FRC_Ratings_Config.json";
local saveFile = "FRC_Ratings_Save.json";
local debugPlatform = "apple"; -- used by the Corona Simulator

local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local module = {};

local function getSaveData()
	module.saveData = FRC_DataLib.readJSON(saveFile, system.DocumentsDirectory);
	if (not module.saveData) then
		module.saveData = {
			launchCount = 0,
			disableRateDialog = false
		};
		FRC_DataLib.saveTable(module.saveData, saveFile);
	end
end

local function detectPlatform()
	if (system.getInfo("environment") == "simulator") then
		module.platform = debugPlatform;
		return;
	end

	local platform = system.getInfo("platformName");
	if (platformName == "iPhone OS") then
		module.platform = "apple";
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

local function getURLForPlatform()
	if (module.config[module.platform] and module.config[module.platform] ~= "") then
		local data = module.config[module.platform];

		-- handle each platform specifically
		if (module.platform == "apple") then
			if (tonumber(system.getInfo("platformVersion").sub(1, 1)) >= 7) then
				-- Greater than or equal to iOS 7
				module.externalURL = "itms-apps://itunes.apple.com/app/id" .. data .. "?onlyLatestVersion=false";
			else
				module.externalURL = "itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=" .. data;
			end
		elseif (module.platform == "google") then
			module.externalURL = "market://details?id=" .. data;
		else
			-- all other platforms (that are not Apple or Google) require a full absolute URL
			module.externalURL = data;
		end
	end
end

local function initiateUserRating()
	if (not module.externalURL) then return; end
	system.openURL(module.externalURL);
end

-- Initialize the module; recommended that you call this in main.lua,
-- sometime well before you call the ask() method.
module.init = function()
	if (module.externalURL) then return; end -- already initialized
	module.config = FRC_DataLib.readJSON(configPath, system.ResourceDirectory);
	getSaveData();
	detectPlatform();
	getURLForPlatform();

	-- Get dialog settings from config or use default values
	if (not module.config.dialog) then
		module.config.dialog = {};
	end
	if (not module.config.dialog.title) then
		module.config.dialog.title = "Rate this app";
	end
	if (not module.config.dialog.description) then
		module.config.dialog.description = "Would you like to rate this app?";
	end
	if (not module.config.dialog.option_rateit) then
		module.config.dialog.option_rateit = "Yes, rate it!";
	end
	if (not module.config.dialog.option_dontask) then
		module.config.dialog.option_dontask = "Don't ask again";
	end
	if (not module.config.dialog.option_remindlater) then
		module.config.dialog.option_remindlater = "Remind me later";
	end
	if (not module.config.dialog.snooze) then
		-- number of app launches to "snooze" the rate dialog (Unless option_dontask was chosen)
		module.config.dialog.snooze = 5;
	end
	return module;
end

-- This method should be called where you intend for the "Rate this app" dialog to be shown
-- Ensure init() is called prior to this.
module.ask = function(bypassLaunchCount)
	if (not module.externalURL) then return; end
	module.saveData.launchCount = module.saveData.launchCount + 1;
	if (not bypassLaunchCount) then
		if ((module.saveData.launchCount < module.config.dialog.snooze) or (module.saveData.disableRateDialog)) then return; end
	end

	-- check for internet connection; if one exists, then show dialog to user
	network.request("http://www.google.com/", "GET", function(event)
		if (event.isError) then return; end
		module.saveData.launchCount = 0; -- reset launch count

		-- Handler that gets notified when the alert closes
		local function onComplete( event )
			if "clicked" == event.action then
				if 1 == event.index then
					-- Rate this app
					initiateUserRating();
					module.saveData.disableRateDialog = true;

				elseif 2 == event.index then
					-- Don't show again
					module.saveData.disableRateDialog = true;

				elseif 3 == event.index then
					-- Remind me later; dismiss the dialog
				end
			end
		end
		-- Show alert with two buttons
		local alert = native.showAlert(module.config.dialog.title, module.config.dialog.description, { module.config.dialog.option_rateit, module.config.dialog.option_dontask, module.config.dialog.option_remindlater }, onComplete);
	end);
end

-- On app exit/suspend re-save module save data
Runtime:addEventListener("system", function(event)
	if (event.type == "applicationExit" or event.type == "applicationSuspend") then
		if (module.saveData) then
			FRC_DataLib.saveTable(module.saveData, saveFile);
		end
	end
end);

return module;
