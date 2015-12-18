-- =============================================================
-- FRC_Notifications - One Signal Push (Notifications) Module
-- =============================================================

-- =============================================================
-- =============================================================
-- Key functions to understand in this module: 
--
--           public.init() -- Initalizes pushes on this device.
--  private.pushListener() -- Handles pushes from OneSignal, processes them, 
--                            and acts on them or routes them to other modules.
-- =============================================================
-- =============================================================

local public   = {} -- Externally published functionality.
local private  = {} -- Internal functionality.


-- Required modules
local notifications        = require( "plugin.notifications" )
local OneSignal            = require("plugin.OneSignal");
local FRC_Notifications    = require "FRC_Modules.FRC_Notifications.FRC_Notifications"

-- Locals

-- Useful Localizations
local mRand             = math.random
local getInfo           = system.getInfo
local getTimer          = system.getTimer
local strMatch          = string.match
local strFormat         = string.format
local pairs             = pairs

-- =============================================================
--  Remote Push Testing
-- =============================================================

-- ==
--     public.remoteTest1( ) - Send self simple message style push.  Kept for example of data layout.
-- ==
function public.remoteTest1( )
   logger = require( "FRC_Modules.FRC_Notifications.FRC_PushLogger" )
   logger.print("Attempting to execute remote push test #1")
   local id,token = FRC_Notifications.getIDToken()
   if( not id or not token ) then
      logger.print("Get ID and Token Before Submitting Push Test")
      if( private.autoShow ) then logger.show(); end
      return
   else

      local notification = {}
      notification.include_player_ids = { id }

      local data                 = {}
      data.msgType               = "message"
      data.title                 = "Test Message #1"
      notification.data          = data
      notification.contents      = {}
      notification.contents.en   = "This is the content of remote test #1.\n Sweet!"


      local function onSuccess(jsonData)
         logger.print("SUCCESS - Posted push to server.")
         if( jsonData ) then private.print_r( jsonData ) end
      end

      local function onFail(jsonData)
         logger.print("ERROR - Failed to post push to server.")
         if( jsonData ) then private.print_r( jsonData ) end
      end

      OneSignal.PostNotification( notification, onSuccess, onFail )
   end
end   

-- ==
--     public.remoteTest2( ) - Send self simple promo style push.  Kept for example of data layout.
-- ==
function public.remoteTest2( )
   logger = require( "FRC_Modules.FRC_Notifications.FRC_PushLogger" )
   logger.print("Attempting to execute remote push test #2")
   local id,token = FRC_Notifications.getIDToken()
   if( not id or not token ) then
      logger.print("Get ID and Token Before Submitting Push Test")
      if( private.autoShow ) then logger.show(); end
      return
   else

      local notification = {}
      notification.include_player_ids = { id }

      local data                 = {}
      data.msgType               = "promo"
      data.title                 = "Test Message #2"
      data.promoDetails          = "Some arbitrary string here"
      notification.data          = data
      notification.contents      = {}
      notification.contents.en   = "This is the content of remote test #2.\n Sweet Promo!"

      local function onSuccess(jsonData)
         logger.print("SUCCESS - Posted push to server.")
         if( jsonData ) then private.print_r( jsonData ) end
      end

      local function onFail(jsonData)
         logger.print("ERROR - Failed to post push to server.")
         if( jsonData ) then private.print_r( jsonData ) end
      end

      OneSignal.PostNotification( notification, onSuccess, onFail )
   end
end   

-- =============================================================
--  Local Push Testing
-- =============================================================

-- ==
--     public.localTest1( ) - Send self simple message style push, using local pushes
-- ==
function public.localTest1( )
   logger = require( "FRC_Modules.FRC_Notifications.FRC_PushLogger" )
   logger.print("Attempting to execute local push test #1")
        

   local options = {}
   local custom = {}
   options.custom   = custom
   
   options.alert     = "Test content for local test #1." -- Equivalent to content
   options.badge     = 2
   options.sound     = "alarm.caf"   
   custom.msgType    = "message"
   custom.title      = "Local Message Test #1"
      
   local tmp = notifications.scheduleNotification( 5, options )
   
end   

-- ==
--     public.localTest2( ) - Send self simple promo style push, using local pushes.
-- ==
function public.localTest2( )
   logger = require( "FRC_Modules.FRC_Notifications.FRC_PushLogger" )
   logger.print("Attempting to execute local push test #2")
        

   local options = {}
   local custom = {}
   options.custom   = custom
   
   options.alert        = "This is the content local test #2.\n Sweet Promo!" -- Equivalent to content 
   options.badge        = 2
   options.sound        = "alarm.caf"

   custom.msgType       = "promo"
   custom.title         = "Local Message Test #2"
   custom.promoDetails  = "Some arbitrary string here"

   local tmp = notifications.scheduleNotification( 5, options )
end   

return public


