--
-- EFM - This module has been wholly re-organized and partially re-written to make it safer, more modular,
-- and to fix the multi-touch issues we had with small pinch-zoom objects.
--
local FRC_MultiTouch = {}
local private = {}

private.circles = {}


local FRC_PinchLib = require "FRC_Modules.FRC_MultiTouch.FRC_PinchLib"

local stage = display.getCurrentStage()
local isSim = system.getInfo( "environment" ) == "simulator"
local simAlpha = 0.5;

--
--  The actual touch handling code starts here...
--
function private.newTouchPoint(e)   
   dprint("Entering newTouchPoint()")
   
   local circle = display.newCircle( stage, e.x, e.y, 25 )
   private.circles[circle] = circle
   --circle.edo = math.random(1,100)
   circle:setFillColor(1,0,0)
   circle.strokeWidth = 5
   circle:setStrokeColor(0,0,255)
   if (isSim) then circle.alpha = simAlpha; else circle.alpha = 0; end
   circle.isHitTestable = true
   circle.isTouchPoint = true
   circle.target = e.target
   circle.id = e.id
   private.touches:add(circle)
   stage:setFocus(circle,e.id)

   function circle.touch(e)
      local self = e.target;      
      if (e.phase == "began") then
         stage:setFocus(e.target,e.id)
         circle.x, circle.y = e.x, e.y
         -- dispatch onPinch event here
         if ((circle.target) and (circle.target.dispatchEvent)) then
            --dprint("dispatch onPinch 1")
            local list = private.touches:get(circle.target)
            circle.target:dispatchEvent{ name="onPinch", phase="moved", target=circle.target, x=e.x, y=e.y, list=list }
         else
            circle.target = nil;
         end
         return true
      elseif (e.phase == "moved") then
         circle.x, circle.y = e.x, e.y
         -- dispatch onPinch event here
         if ((circle.target) and (circle.target.dispatchEvent)) then
            --dprint("dispatch onPinch 2")
            local list = private.touches:get(circle.target)
            circle.target:dispatchEvent{ name="onPinch", phase="moved", target=circle.target, x=e.x, y=e.y, list=list }
         else
            circle.target = nil;
         end
         --print('moved',circle.target,circle.target.name)
         return true
      else
         circle.x, circle.y = e.x, e.y
         if (not isSim) then private.touches:remove(circle) end
         -- dispatch onPinch event here
         local phase = "ended"
         if (isSim) then phase = "moved" end
         if ((circle.target) and (circle.target.dispatchEvent)) then
            --dprint("dispatch onPinch 3")
            local list=private.touches:get(circle.target)
            circle.target:dispatchEvent{ name="onPinch", phase=phase, target=circle.target, x=e.x, y=e.y, list = list }
         else
            circle.target = nil;
         end
         stage:setFocus(e.target,nil)
         if (not isSim) then circle:removeSelf() end
         return true
      end
      return false
   end
   circle:addEventListener("touch",circle.touch)

   function circle.tap(e)
      local self = e.target;
      if (e.numTaps == 1) then
         private.touches:remove(circle)
         if ((circle.target) and (circle.target.dispatchEvent)) then
            circle.target:dispatchEvent{ name="onPinch", phase="ended", x=e.x, y=e.y, target=circle.target, list=private.touches:get(circle.target) }
         else
            circle.target = nil;
         end
         display.remove( circle ) 
         private.circles[circle] = nil
         
      end
      return true
   end
   if (isSim) then circle:addEventListener("tap",circle.tap) end

   return circle
end

function private.createPinchProxy( newCircle )
   dprint("Entering createPinchProxy()")
  
   local target = newCircle.target
   local proxy = private.touches:getPinchProxy()
      
   if( target.toolMode ~= "SHAPE_PLACEMENT" and target.toolMode ~= "STAMP_PLACEMENT" ) then
      display.remove( private.touches._pinchProxy ) 
      private.touches._pinchProxy = nil
      proxy = private.touches:getPinchProxy()      
   end
   
   -- If the pinch proxy exists, simply copy a reference to the new circle
   if(proxy) then
      dprint("Proxy exists!  Do not re-create!")
      return
   end   
   
   proxy = display.newRect( target.parent, 0, 0, 10000, 10000 )
   proxy.target   = target
   proxy.alpha    = 0
   proxy:setFillColor(1,1,0)  
   proxy.isHitTestable = true
   
   proxy.touch = FRC_MultiTouch.handleProxyTouch
   proxy:addEventListener( "touch" ) 
   
   private.touches:setPinchProxy(proxy)
     
   --[[
   function proxy:finalize( event )
      print("FINALIZING")
      FRC_MultiTouch.init()
   end
   proxy:addEventListener( "finalize" )
   --]]

end

function FRC_MultiTouch.handleTouch(event)
   if (event.phase == "began") then   
      local circle = private.newTouchPoint(event)
      
      private.createPinchProxy( circle )

      if ((circle.target) and (circle.target.dispatchEvent)) then
         circle.target:dispatchEvent{ name="onPinch", phase="began", x=event.x, y=event.y, target=circle.target, list=list }
      else
         circle.target = nil;
      end
   end
   --print('handleTouch(event)',event.target)
   return true
end

function FRC_MultiTouch.handleProxyTouch( self, event )   
   local proxy = private.touches:getPinchProxy()         
   if( not proxy ) then return false end
   
   dprint(" handleProxyTouch ", event.phase )
   if (event.phase == "began") then   
      event.target = proxy.target
      local circle = private.newTouchPoint(event)
      
      private.createPinchProxy( circle )

      if ((circle.target) and (circle.target.dispatchEvent)) then
         circle.target:dispatchEvent{ name="onPinch", phase="began", x=event.x, y=event.y, target=circle.target, list=list }
      else
         circle.target = nil;
      end
   end
   --print('handleTouch(event)',event.target)
   return true
end

--
-- Local touch repository
--

private.touches = {}
function private.touches:add( circle )
   for i=1, #self do
      local touch = self[i]
      if (touch.target == circle.target) then
         local list = touch.list
         for t=1, #list do
            if (list[t] == circle) then
               return
            end
         end
         -- add new touch point to existing image
         --local list = touch.list
         list[ #list+1 ] = circle
         return
      end
   end
   -- add new image and its first touch circle
   self[ #self+1 ] = { target = circle.target, list = { circle } }
end
function private.touches:remove( circle )   
   for i=#self, 1, -1 do
      local touch = self[i]
      if (touch.target == circle.target) then
         local list = touch.list
         for t=#list, 1, -1 do
            if (list[t] == circle) then
               table.remove(list,t)
               break
            end
         end
         if (#list == 0) then
            dprint("Removed last circle!  Destroy pinchProxy.")
            display.remove( self._pinchProxy ) 
            self._pinchProxy = nil
            table.remove(self,i)
            break
         end
      end
   end
end
function private.touches:get(target)
   for i=1, #self do
      if (self[i].target == target) then
         return self[i].list
      end
   end
   return {}
end

function private.touches:setPinchProxy( proxy )
   self._pinchProxy = proxy
end
function private.touches:getPinchProxy()
   if( self._pinchProxy and self._pinchProxy.removeSelf == nil ) then
      self._pinchProxy = nil
   end
   return self._pinchProxy
end

--[[
function private.touches:purge()
   while( #self > 0) do
      dprint("private.touches:purge() " , #self )
      display.remove( self[1] )   
      table.remove(self,1)
   end
   
   for k, v in pairs( private.circles ) do
      display.remove(v)
   end   
   private.circles = {}
end
--]]


function FRC_MultiTouch.init()   
   dprint("Entering FRC_MultiTouch.init() @ " .. system.getTimer() )
   
   display.remove( private.touches._pinchProxy ) 
   private.touches._pinchProxy = nil
   while( #private.touches > 0) do
      dprint("private.touches:purge() " , #private.touches )
      display.remove( private.touches[1] )   
      table.remove(private.touches,1)
   end   
   for k, v in pairs( private.circles ) do
      display.remove(v)
      private.circles[k] = nil
   end   
   --private.circles = {}
end

return FRC_MultiTouch



-- EFM retained temoprarily, but I've checked and these don't seem to be used anywhere.
--[[
-- Easy-access function for adding event listeners to the stage
function addEventListener( name, event )
	stage:addEventListener( name, event )
end

-- Easy-access function for removing event listeners to the stage
function removeEventListener( name, event )
	stage:removeEventListener( name, event )
end
--]]
