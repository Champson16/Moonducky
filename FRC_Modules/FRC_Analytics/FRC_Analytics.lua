--
-- 30 DEC 2015 - This module has been updated by Ed Maurina to be more robust on Android devices.  
--               It will try to find a key matching the 'targetAppStore', but failing that will fall back through
--               A sequence of althernate keys.  See 'detectPlatform()' for the fallback sequences.
--
--               Supported keys: apple, windows, nook, amazon, tabeo, google, contents of 'targetAppStore'
--
require("FRC_Modules.FRC_Globals.FRC_Globals") -- IOS_DEVICE, etc.
local FRC_DataLib = require("FRC_Modules.FRC_DataLib.FRC_DataLib")

local version           = "1.0.0"
local configPath        = "FRC_Assets/FRC_Analytics/Data/FRC_Analytics_Config.json"
local defaultProvider   = "flurry"
local debugPlatform     = "google"
local debugMode         = false

local module = {}
local analytics

local targetAppStore = system.getInfo( "targetAppStore" ) or "none"   

-- ==
--    detectPlatform() - Select best match for Analytics ID
-- ==
local function detectPlatform()
   if ( ON_SIMULATOR ) then
      module.platform = debugPlatform
      debugMode = true

   elseif ( IOS_DEVICE ) then
      module.platform = "apple"

   elseif ( WINDOWS_PHONE ) then
      module.platform = "windows"

   elseif ( NOOK_DEVICE ) then      
      module.platform = { targetAppStore, "nook", "google" }

   elseif ( KINDLE_DEVICE ) then
      module.platform = { targetAppStore, "amazon", "google" }

   elseif ( TABEO_DEVICE ) then
      module.platform = { targetAppStore, "tabeo", "google" }

   elseif ( ANDROID_DEVICE ) then
      module.platform = { targetAppStore, "google" }

   else
      module.platform = targetAppStore
   end   

   if( debugMode ) then
      print( "detectPlatform() -    targetAppStore: ",  targetAppStore )
      print( "detectPlatform() - Selected platform: ",  module.platform )
   end
end
detectPlatform() -- Run as soon as module is loaded the first time

-- ==
--    init() - Initialize this module to use a specific provider.
-- ==
function module.init( provider )
   if (analytics) then return end -- already initialized
   module.provider   = provider or defaultProvider
   module.config     = FRC_DataLib.readJSON(configPath, system.ResourceDirectory)

   local usedFallback = true  -- If this stays true, the module had to use a fallback analytics ID
   -- This means, you either did not provide oen that matches the 'targetAppStore' 
   -- for this run.
   local initKey 

   -- Find an 'initKey' that matches this provider and:
   --
   -- On Simulator     - Whatever you selected in 'debugPlatform' at top of file.
   -- On iOS           - 'apple'
   -- On Windows Phone - 'windows'
   --
   -- On Android Device:  First tries to find key matching 'targetAppStore', 
   --                     Second proceeds to one matching device sub-type, and 
   --                     Last, default to 'google'.
   -- 
   if( type(module.platform) == "string" ) then
      initKey = module.config[module.provider][module.platform] 

   elseif( type(module.platform) == "table" ) then
      local i = 1
      while( initKey == nil and i <= #module.platform ) do
         local curPlat = module.platform[i]
         if (debugMode) then
            print("Searching for initKey ", i, curPlat )
         end
         initKey = module.config[module.provider][curPlat]
         if( initKey ) then 
            module.platform = curPlat 
         end
         usedFallback = (i>1)
         i = i + 1
      end
   end   

   if( not initKey or (initKey == "") ) then 
      if (debugMode) then
         print("init() - Failed to get init key?")
         print("init() - initKey == ", initKey )
         print("init() - usedFallback =? ", usedFallback )
         print("init() - targetAppStore == ", targetAppStore )
      end
      return 
   end

   analytics = require("analytics")
   analytics.init( initKey )

   if (debugMode) then
      print("Initialized analytics: ")
      print("", "provider: ", module.provider )
      print("", "platform: ", module.platform )
      print("", "key: ", initKey)
   end
end

module.logEvent = function(eventData)   
   if( debugMode ) then
      print( "flurry logEvent() - analytics == ", analytics )
   end

   if (not analytics) then return end   

   if( debugMode ) then
      print( "flurry logEvent() - eventData == ", eventData )
   end

   analytics.logEvent(eventData)

   if (debugMode) then
      if (type(eventData) ~= "table") then
         print("Logged analytics event (string): " .. tostring(eventData))		
      else
         print("Logged analytics event (table):")
         for k,v in pairs(eventData) do
            print("", k, v)
         end
      end
   end
end

return module
