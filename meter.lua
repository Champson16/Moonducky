-- =============================================================
-- Copyright Roaming Gamer, LLC. 2009-2015 
-- =============================================================
-- This content produced for Corona Geek Hangouts audience.
-- You may use any and all contents in this example to make a game or app.
-- =============================================================

-- Extracted from SSK sampler and modified for this example.
-- https://github.com/roaminggamer/SSKCorona/sampler
--
local public = {}

local private = {}

-- ==
--    round(val, n) - Rounds a number to the nearest decimal places. (http://lua-users.org/wiki/FormattingNumbers)
--    val - The value to round.
--    n - Number of decimal places to round to.
-- ==
function private.round(val, n)
  if (n) then
    return math.floor( (val * 10^n) + 0.5) / (10^n)
  else
    return math.floor(val+0.5)
  end
end

function private.calcMeasurementSpacing(debugEn)
	private.w 				   = display.contentWidth
	private.h 				   = display.contentHeight
	private.centerX 			= display.contentCenterX
	private.centerY 			= display.contentCenterY
	private.fullw			   = display.actualContentWidth 
	private.fullh			   = display.actualContentHeight
	private.unusedWidth		= private.fullw - private.w
	private.unusedHeight		= private.fullh - private.h
	private.deviceWidth		= math.floor((private.fullw/display.contentScaleX) + 0.5)
	private.deviceHeight 	= math.floor((private.fullh/display.contentScaleY) + 0.5)
	private.left				= 0 - private.unusedWidth/2
	private.top 				= 0 - private.unusedHeight/2
	private.right 			   = private.w + private.unusedWidth/2
	private.bottom 			= private.h + private.unusedHeight/2


	private.w 				   = private.round(private.w)
	private.h 				   = private.round(private.h)
	private.left			   = private.round(private.left)
	private.top				   = private.round(private.top)
	private.right			   = private.round(private.right)
	private.bottom			   = private.round(private.bottom)
	private.fullw			   = private.round(private.fullw)
	private.fullh			   = private.round(private.fullh)

	private.orientation  	= ( private.w > private.h ) and "landscape"  or "portrait"
	private.isLandscape 		= ( private.w > private.h )
	private.isPortrait 		= ( private.h > private.w )

	private.left 			   = (private.left >= 0) and math.abs(private.left) or private.left
	private.top 				= (private.top >= 0) and math.abs(private.top) or private.top
	
	if( debugEn ) then
		dprint("\n---------- calcMeasurementSpacing() @ " .. system.getTimer() )	
		dprint( "w       = " 	.. private.w )
		dprint( "h       = " 	.. private.h )
		dprint( "centerX = " .. private.centerX )
		dprint( "centerY = " .. private.centerY )
		dprint( "fullw   = " 	.. private.fullw )
		dprint( "fullh   = " 	.. private.fullh )
		dprint( "left    = " 	.. private.left )
		dprint( "right   = " 	.. private.right )
		dprint( "top     = " 	.. private.top )
		dprint( "bottom  = " 	.. private.bottom )
		dprint("---------------\n\n")
	end
end
private.calcMeasurementSpacing(false)



local getTimer = system.getTimer
function public.create_fps()
	local fpsMeter = display.newGroup()
	fpsMeter.back = display.newRect( fpsMeter, private.left + 2, private.top + 105, 100, 25 )
	fpsMeter.back.anchorX = 0
	fpsMeter.back.anchorY = 0
	fpsMeter.back:setFillColor(0.2,0.2,0.2)
	fpsMeter.back:setStrokeColor(1,1,0)
	fpsMeter.back.strokeWidth = 1
   
	fpsMeter.lastTime = getTimer()
	local cx = fpsMeter.back.x + fpsMeter.back.contentWidth/2
	local cy = fpsMeter.back.y + fpsMeter.back.contentHeight/2
	fpsMeter.label = display.newText(fpsMeter, "initializing...", cx, cy, native.systemFont, 12 )
	--fpsMeter.label:setFillColor( 0,0,0 )
	fpsMeter.avgWindow = {}
	fpsMeter.maxWindowSize = display.fps * 2 or 60

	fpsMeter.enterFrame = function(self)
		self:toFront()
		self.back.x = private.left + 2
		self.back.y = private.top + 105
		self.label.x = self.back.x + self.back.contentWidth/2
		self.label.y = self.back.y + self.back.contentHeight/2

		local avgWindow = fpsMeter.avgWindow	
		local curTime = getTimer()
		local dt = curTime - self.lastTime
		self.lastTime = curTime
		if( dt == 0 ) then return end
		avgWindow[#avgWindow+1] = 1000/dt
		while( #avgWindow > self.maxWindowSize ) do table.remove(avgWindow,1) end
		if( #avgWindow ~= self.maxWindowSize ) then return end
		local sum = 0
		for i = 1, #avgWindow do
			sum = avgWindow[i] + sum
		end
		fpsMeter.label.text = private.round(sum/#avgWindow) .. " FPS"			
	end; 
	timer.performWithDelay(1000, function() Runtime:addEventListener("enterFrame", fpsMeter) end )
end


function public.create_mem()
	local hud = display.newGroup()
	local hudFrame = display.newRect( hud, 0, 0, 240, 80)
	hudFrame:setFillColor(0.2,0.2,0.2)
	hudFrame:setStrokeColor(1,1,0)
	hudFrame.strokeWidth = 1
	hudFrame.x = private.right - hudFrame.contentWidth/2 - 5
	hudFrame.y = private.top + hudFrame.contentHeight/2 + 105

	local mMemLabel = display.newText( hud, "Main Mem:", hudFrame.x - hudFrame.contentWidth/2 + 10, hudFrame.y - 15, native.systemFont, 16 )
	mMemLabel:setFillColor(1,0.4,0)
	mMemLabel.anchorX = 0

	local tMemLabel = display.newText( hud, "Texture Mem:", hudFrame.x - hudFrame.contentWidth/2 + 10, hudFrame.y + 15, native.systemFont, 16 )
	tMemLabel:setFillColor(0.2,1,0)
	tMemLabel.anchorX = 0

	hud.enterFrame = function( self )
		self:toFront()
		hudFrame.x = private.right - hudFrame.contentWidth/2 - 5
		hudFrame.y = private.top + hudFrame.contentHeight/2 + 105
		mMemLabel.x = hudFrame.x - hudFrame.contentWidth/2 + 10
		mMemLabel.y = hudFrame.y - 15
		tMemLabel.x = hudFrame.x - hudFrame.contentWidth/2 + 10
		tMemLabel.y = hudFrame.y + 15

		-- Fill in current main memory usage
		collectgarbage("collect") -- Collect garbage every frame to get 'true' current memory usage
		local mmem = collectgarbage( "count" ) 
		mMemLabel.text = "Main Mem: " .. private.round(mmem/(1024),2) .. " MB"

		-- Fill in current texture memory usage
		local tmem = system.getInfo( "textureMemoryUsed" )
		tMemLabel.text = "Texture Mem: " .. private.round(tmem/(1024 * 1024),2) .. " MB"
	end; Runtime:addEventListener( "enterFrame", hud )

end
return public

