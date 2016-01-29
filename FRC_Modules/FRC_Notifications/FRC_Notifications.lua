-- =============================================================
-- FRC_Notifications - One Signal Push (Notifications) Module
-- =============================================================

-- =============================================================
-- =============================================================
-- Key functions to understand in this module:
--
--                public.init() -- Initalizes pushes on this device.
--  private.oneSignalListener() -- Handles (REMOTE) pushes from OneSignal, processes them,
--                                 and acts on them or routes them to other modules.
--  public.localListener()     -- Handles (LOCAL) pushes.
-- =============================================================
-- =============================================================
local FRC_Util        = require('FRC_Modules.FRC_Util.FRC_Util')

local public   = {} -- Externally published functionality.
local private  = {} -- Internal functionality.


-- Required modules
local OneSignal = require("plugin.OneSignal");

-- Locals

-- EFM WE NEED TO CENTRALIZE PLATFORM DETECTION
local onSimulator    = system.getInfo( "environment" ) == "simulator"
local oniOS          = ( system.getInfo("platformName") == "iPhone OS")
local onAndroid      = ( system.getInfo("platformName") == "Android")
local onWinPhone     = (system.getInfo("platformName") == "WinPhone");
local onOSX          = ( system.getInfo("platformName") == "Mac OS X")
local onWin          = ( system.getInfo("platformName") == "Win")
local onNook         = (system.getInfo("targetAppStore") == "nook");
local onAmazon       = (system.getInfo("targetAppStore") == "amazon");
onAndroid            = onAndroid or onNook or onAmazon



-- Useful Localizations
local mRand             = math.random
local getInfo           = system.getInfo
local getTimer          = system.getTimer
local strMatch          = string.match
local strFormat         = string.format
local pairs             = pairs


-- =============================================================
-- PUBLIC PUBLIC PUBLIC PUBLIC PUBLIC PUBLIC PUBLIC PUBLIC PUBLIC
-- =============================================================
-- ==
--  public.init( params )
-- ==
--  params - Parameterized table of settings
--   >>    enableLogger - Enables pop-up logger if 'true'
--   >>        autoShow - If 'true' logger pops up automatically in specific cases (search for autoShow below).
--   >> discoverIdToken - If 'true' self-query and grab this devices id and token (shortly) after init
-- ==
function public.init( params )
   params = params or {}

   if( params.enableLogger == true ) then
      print("Enabling logger")
      private.logger = require( "FRC_Modules.FRC_Notifications.FRC_PushLogger" )
      private.logger.purge()
   else
      -- private.logger = {}
      -- private.logger.print = function() end
      -- private.logger.purge = function() end
      -- private.logger.show = function() end
      private.logger = {}
      private.logger.print = function() end
      private.logger.print_r = function() end
      private.logger.purge = function() end
      private.logger.show = function() end
   end

   private.enableLogger = params.enableLogger
   private.autoShow = params.autoShow

   --
   -- Initialize Push Notifications for/on iOS (automatic on Android)
   --
   local notifications = require( "plugin.notifications" )
   notifications.registerForPushNotifications()

   Runtime:addEventListener( "notification", public.localListener )


   -- Initialize One Signal
   --OneSignal.SetLogLevel(4, 4)   
   OneSignal.Init( params.oneSignalID, params.projectNumber, private.oneSignalListener)

   -- Tag This User In 'Push Dev Group'
   --OneSignal.SendTags({["group"] = "PushDev",["user"] = "RoamingGamer"})
   --OneSignal.SendTags({["group"] = "PushDev"})


   if( params.discoverIdToken == true) then
      print("Discover ID & Token")
      public.queryIDToken( )
   end

end


-- ==
--     public.queryIDToken( ) - Discover and store this device's push token and device ID for this session ONLY.
-- ==
function public.queryIDToken( )
   local function listener( id, token )
      private.logger.print( "queryIDToken() ID: " .. tostring(id) )
      private.logger.print( "TOKEN: ", token )
      --private.logger.show()
      if( id and token ) then
         public.setIDToken( id, token )
      else
         private.logger.print("Error retrieving ID and Token!")
         if( private.autoShow ) then private.logger.show(); end
      end
   end
   OneSignal.IdsAvailableCallback(listener)
end


-- ==
--     private.setIDToken( id, token ) - Store this device's push id/token for this session.
-- ==
function public.setIDToken( id, token )
   print("public.setIDToken()")
   private.data = private.data or {}
   private.data.id = id
   private.data.token = token
end

-- ==
--     private.getIDToken( id, token ) - Get this device's push id/token for this session.
-- ==
function public.getIDToken()
   print("public.getIDToken()")
   private.data = private.data or {}
   return private.data.id, private.data.token
end


-- =============================================================
-- PRIVATE PRIVATE PRIVATE PRIVATE PRIVATE PRIVATE PRIVATE PRIVATE
-- =============================================================

-- ==
--   private.oneSignalListener( msg, data, isActive )  - One signal compatible push listener.
-- ==
--        msg  - Text string containg push message CONTENT.
--
--       data  - A string indexed table containing arbitrary values.
--         >>      msgType - 'message' or 'promo'
--         >>        title - Message TITLE.
--         >> promoDetails - Arbitrary string to contain 'promotional' instructions to future code and modules.
--         >> promoURLXXX - A URL to open when the users clicks 'Get The App'
--            XX == IOS, GOOGLE, AMAZON, NOOK, MAC, WINDOWS
--         >> Other?  TBD in future
--
--   isActive  - Unknown (EFM?)
--
-- ==
function private.oneSignalListener( msg, data, isActive )
   --
   -- Clean up the 'data' field to ensure it is ready for consumption by logic below
   --
   data = data or {}
   local isEmpty = true
   for k,v in pairs( data ) do
      isEmpty = false
   end
   data = ( isEmpty ) and {} or data

   -- Force message type if not specified.
   data.title     = data.title or "Missing Title"
   data.msgType   = data.msgType or "message"


   --
   -- Dump details to logger (if not enabled this goes to the bit bucket)
   --
   private.logger.print( "Got Push Notification: ", data.title )
   private.logger.print( "Content ==> " )
   private.logger.print_r( msg )
   private.logger.print( "isActive ==> ", isActive )
   --
   -- Automatically pop up logger?
   --
   if( private.autoShow ) then private.logger.show(); end

   -- ==================================
   -- Push Type 1 - 'message'
   --
   -- Display message and body in a dialog with one option:  'OK' to close
   --
   -- ==================================
   if( data.msgType == "message" ) then
      FRC_Util.easyAlert( data.title, msg , { { "OK", nil } } )

      -- ==================================
      -- Push Type 2 - 'promo' (Promotional push)
      --
      -- Functionality TBD.  For now display: message, body, and promoDetails string.
      --
      -- In the future we will use the promoDetails and perhaps more data to show a promotional dialog.
      -- There may be similarities to  the 'New Home For Charlie' discover feature.
      --
      -- ==================================
   elseif( data.msgType == "promo" ) then
      local promoDetails = data.promoDetails or "None"
      local promoType    = data.promoType or "None"
      local promoURL     = "None"

      if( oniOS ) then
         promoURL = data.promoURLIOS or promoURL

      elseif( onWinPhone ) then
         promoURL = data.promoURLWINPHONE or promoURL

      elseif( onNook ) then
         promoURL = data.promoURLNOOK or data.promoURLGOOGLE or promoURL

      elseif( onAmazon ) then
         promoURL = data.promoURLAMAZON or data.promoURLGOOGLE or promoURL

      elseif( onAndroid ) then
         promoURL = data.promoURLGOOGLE or promoURL

      elseif( onOSX ) then
         promoURL = data.promoURLMAC or promoURL

      elseif( onWin ) then
         promoURL = data.promoURLWINDOWS or promoURL
      end


      private.logger.print( "promoDetails ==> " )
      private.logger.print_r( promoDetails )

      private.logger.print( "promoType ==> " )
      private.logger.print_r( promoType )

      private.logger.print( "promoURL ==> " )
      private.logger.print_r( promoURL )


      if( ( promoType and promoType == "appstore" ) and
         ( promoURL and promoURL ~= "None" ) ) then
         -- private.easyAlert( data.title, msg .. "\n\nPromo Details: " .. promoDetails,
         FRC_Util.easyAlert( data.title, msg .. "\n\n" .. promoDetails,
            {
               { "Cancel", nil },
               { "Get The App", function() system.openURL( promoURL ) end } } )
      else
         -- private.easyAlert( data.title, msg .. "\n\nPromo Details: " .. promoDetails,
         FRC_Util.easyAlert( data.title, msg .. "\n\n" .. promoDetails,
            { { "OK", nil } } )
      end
   end
end


-- ==
--   public.localListener( event )  - Corona push listener
-- ==
--        msg  - Text string containg basic push message.
function public.localListener( event )
   private.logger.print("In Local Listener")
   private.logger.print_r(event)

   --
   -- Clean up the 'custom' field to ensure it is ready for consumption by logic below
   --
   event = event or {}
   event.alert = event.alert or ""
   event.custom = event.custom or {}
   local isEmpty = true
   for k,v in pairs( event.custom ) do
      isEmpty = false
   end
   local custom = ( isEmpty ) and { msgType = "message", title = event.alert } or event.custom


   --
   -- Only handle local alerts here
   --
   if( event.type == "remoteRegistration" ) then
      -- Ignore this

   elseif( not event.type ) then
      -- Ignore this

   elseif( event.type == "local" ) then
      --
      -- Route through oneSignalListener() for handling
      --
      private.oneSignalListener( event.alert, custom, false )
   else
      -- What!?
      FRC_Util.easyAlert( "Wrong Handler", "Got non-local push in this handler.\nIgnoring it.\n" .. tostring( event.type ) , { { "OK", nil } } )
   end
end

return public
