-- ABC

--------------- VARIABLES ---------------
local deviceContentWidth = display.viewableContentWidth
local deviceContentHeight = display.viewableContentHeight
local background
local failedSound
local pickUpSound
local powerUpSound
local menu
local score
local highScore
local gameIsOver = true
local scoreLabel
local rewardLabel
local rewardBar
local penaltyLabel
local penaltyBar
local physics
-- Used to control the various game modes.
local spawnConstraint = "no"
local playerA
local playerB
local playerC
-- Used to calculate the time delta between calls of the animate function.
local tPrevious = system.getTimer( )
-- The objects table holds all animated objects except the player and the menu.
local objects = {}
-- Used to alter the speed of the blue and black squares. Normal speed. Traffic rush. Traffic jam.
local speedFactor = 1

--------------- FUNCTION VARIABLES ---------------
-- Variables to hold the function pointers.
-- This is only to have one place to show them off.
local loadScores
local saveScores
local createPlayerA
local createPlayerB
local createPlayerC
local randomSpeed
local calculateNewVelocity
local showMenu
local showInstructions
local startGame
local createMenu
local gameOver
local coerceOnScreen
local onTouch
local spawn
local gameSpecial
local onCollision
local animate
local randomSpeed

--------------- FUNCTIONS ---------------
-- Load scores from file. Returns the score and the highScore. In this order.
loadScores = function( )--{{{
	local scores = {}
	local str = ""
	local n = 1
		 
	local path = system.pathForFile( "score.txt", system.DocumentsDirectory )

	local file = io.open ( path, "r" ) 
	if file == nil then 
		return 0, 0 
	end

	
	local contents = file:read( "*a" )
	file:close() 

	for i = 1, string.len( contents ) do
		local char = string.char( string.byte( contents, i ) )
  
		if char ~= "|" then
			str = str..char
		else
			scores[n] = tonumber( str )
			n = n + 1
			str = ""
		end
	end

	return scores[1], scores[2]
end --}}}

-- Stores scores to file. Takes two parameters. The last score and the highest score.
saveScores = function( s, hs )--{{{
	local path = system.pathForFile( "score.txt", system.DocumentsDirectory )

	local file = io.open ( path, "w" )

	local contents = tostring( s ).."|"..tostring( hs).."|"
	file:write( contents )


	file:close( ) 
end--}}}

-- Creates and returns a new player.
createPlayerA = function( x, y, radius, rotation, visible )--{{{
	local playerCollisionFilter = { categoryBits = 2, maskBits = 5 }
	local playerBodyElement = { filter=playerCollisionFilter }

	--  Player is a black square
	local p = display.newCircle(x, y, radius)
	-- p:setReferencePoint(display.CenterReferencePoint)
	p:setFillColor(0.3, 0.6, 0.9)
	p.isBullet = true
	p.objectType = "player"
	physics.addBody ( p, "dynamic", playerBodyElement )
	p.isVisible = visible
	p.rotation = rotation
	p.resize = false
	p.isSleepingAllowed = false
	
	return p
end--}}}

createPlayerB = function( x, y, radius, rotation, visible )--{{{
	local playerCollisionFilter = { categoryBits = 3, maskBits = 5 }
	local playerBodyElement = { filter=playerCollisionFilter }

	--  Player is a black square
	-- local p = display.newRect(x, y, width, height)
	local p = display.newCircle( x, y, radius )
	-- p:setReferencePoint(display.CenterReferencePoint)
	p:setFillColor(0.5, 0.3, 0.5)
	p.isBullet = true
	p.objectType = "player"
	physics.addBody ( p, "dynamic", playerBodyElement )
	p.isVisible = visible
	p.rotation = rotation
	p.resize = false
	p.isSleepingAllowed = false
	
	return p
end--}}}

createPlayerC = function( x, y, radius, rotation, visible )--{{{
	local playerCollisionFilter = { categoryBits = 4, maskBits = 5 }
	local playerBodyElement = { filter=playerCollisionFilter }

	--  Player is a black square
	local p = display.newCircle( x, y, radius )
	-- p:setReferencePoint(display.CenterReferencePoint)
	p:setFillColor( 0.5, 0.5, 0.5)
	p.isBullet = true
	p.objectType = "player"
	physics.addBody ( p, "dynamic", playerBodyElement )
	p.isVisible = visible
	p.rotation = rotation
	p.resize = false
	p.isSleepingAllowed = false
	
	return p
end--}}}

-- Returns a random speed
randomSpeed = function( )--{{{
	return math.random(1, 2) / 10 * speedFactor
end--}}}

-- Cycles through all objects to adjust the velocity.
calculateNewVelocity = function( t )--{{{
	for _, object in pairs ( t ) do
		object.xVelocity = object.xVelocity * speedFactor
		object.yVelocity = object.yVelocity * speedFactor
	end
end--}}}

-- Shows / hides the menu.
showMenu = function( s )--{{{
	if s then
		--menu.isVisible = true
		-- menu.lastScoreLabel.text = "score " .. score
		-- menu.lastScoreLabel.x = display.viewableContentWidth / 2
		-- menu.highScoreLabel.text = "highest score " .. highScore
		-- menu.highScoreLabel.x = display.viewableContentWidth / 2
		transition.to ( menu, { y=0 } )
	else
		transition.to ( menu, { y=-display.viewableContentHeight } )
	end
end--}}}

-- Starts a new game round. Resets some properties first.
startGame = function( )--{{{
	showMenu( false )

	playerA.radius = 20
	playerA.x = display.viewableContentWidth / 2
	playerA.y = display.viewableContentHeight / 2
	playerA.resize = true

	playerB.radius = 25
	playerB.x = display.viewableContentWidth / 2
	playerB.y = display.viewableContentHeight / 2
	playerB.resize = true

	playerC.radius = 10
	playerC.x = display.viewableContentWidth / 2
	playerC.y = display.viewableContentHeight / 2
	playerC.resize = true

	speedFactor = 1
	score = 0
	scoreLabel.text = tostring ( score )
	gameIsOver = false

	playerA.isVisible = true
	playerB.isVisible = false
	playerC.isVisible = false

	scoreLabel.isVisible = false
	for _, object in pairs ( objects ) do
		-- Remove all objects from scene to force a re-spawn
		object.isVisible = false
	end

	startButton.isVisible = false
end--}}}

-- Creates a menu and returns a handle to it. 
createMenu = function( )--{{{
	local menu = display.newGroup ( )
	local menuBackground = display.newRect( menu, deviceContentWidth / 2, deviceContentHeight / 2, deviceContentWidth, deviceContentHeight )
	-- display.newRect( left, top, width, height )
	menuBackground:setFillColor ( 1, 1, 1 )
	menuBackground.alpha = 1

	-- local title = display.newText( menu, "ABC", 0, 0, native.systemFontBold, 75 )
	-- title.x = display.contentWidth / 2
	-- title.y = display.contentHeight / 2 - 50 
	-- title:setTextColor( 255, 0, 0 )

	startButton = display.newImage("../Assets/img/start.png")
	startButton.x = display.contentWidth / 2
	startButton.y = display.contentHeight / 2

	-- local steps = display.newText( menu, "Try to avoid B\nTry to help C.\nSometimes you must fight with B to survive.\nTry to DONT KILL B.\nDon't let B DIE.", 0, 0, 480, 250, native.systemFont, 35 )
	-- steps.x = deviceContentWidth / 2
	-- steps.y = deviceContentHeight / 2 + 290
	-- steps:setTextColor( 0, 0, 0 )

	-- Animate the start button. Scale up and down.
	-- local function startButtonAnimation( )
	-- 	local scaleUp = function( )
	-- 		startButtonTween = transition.to( startButton, { xScale=1, yScale=1, onComplete=startButtonAnimation } )
	-- 	end
			
	-- 	startButtonTween = transition.to( startButton, { xScale=0.9, yScale=0.9, onComplete=scaleUp } )
	-- end
	-- startButtonAnimation( )

	local function onStartButtonTouch(event)
		if "began" == event.phase then
			startButton.isFocus = true
		elseif "ended" == event.phase and startButton.isFocus then
			startButton.isFocus = false
			startGame( )
			playerB.isVisible=true
			playerC.isVisible=true
			--PosIniB=math.random(1,4)
			startButton.isVisible = false
		end
		-- Return true if touch event has been handled.
		return true
	end
	startButton:addEventListener ( "touch", onStartButtonTouch )

	local function onInstructionsButtonTouch(event)
		if "began" == event.phase then
			instructionsButton.isFocus = true
		elseif "ended" == event.phase and instructionsButton.isFocus then
			instructionsButton.isFocus = false
			showInstructions( )
		end

		-- Return true if touch event has been handled.
		return true
	end
	-- instructionsButton:addEventListener ( "touch", onInstructionsButtonTouch )

	-- local lastScoreLabel = display.newText( menu, "score " .. score, 0, 0, native.systemFont, 15 )
	-- lastScoreLabel.x = display.viewableContentWidth / 2
	-- lastScoreLabel.y = startButton.y + startButton.height - 10
	-- lastScoreLabel:setTextColor( 255, 0, 0, 100 )
	-- menu["lastScoreLabel"] = lastScoreLabel
	
	-- local highScoreLabel = display.newText( menu, "highest score " .. highScore, 0, 0, native.systemFont, 15 )
	-- highScoreLabel.x = display.viewableContentWidth / 2
	-- highScoreLabel.y = lastScoreLabel.y + lastScoreLabel.height
	-- highScoreLabel:setTextColor( 255, 0, 0, 100 )
	-- menu["highScoreLabel"] = highScoreLabel
	return menu
end--}}}

showInstructions = function (  )
	
end


-- Saves the scores, shows the menu etc.
gameOver = function( )--{{{
	gameIsOver = true
	audio.play( failedSound )
	if score > highScore then
		highScore = score
	end
	saveScores( score, highScore )

	showMenu( true )
	
	rewardLabel.alpha = 0
	rewardBar.isVisible = false
	penaltyLabel.alpha = 0
	penaltyBar.isVisible = false
	
	playerA.isVisible = false
	scoreLabel.isVisible = false
	for _, object in pairs ( objects ) do
		object.alpha = gameIsOver and 20/255 or 255/255
	end
end--}}}

-- Forces the object  (player) to stay within the visible screen bounds.
coerceOnScreen = function( object )--{{{
	if object.x < object.width then
		object.x = object.width
	end
	if object.x > display.viewableContentWidth - object.width then
		object.x = display.viewableContentWidth - object.width
	end
	if object.y < object.height then
		object.y = object.height
	end
	if object.y > display.viewableContentHeight - object.height then
		object.y = display.viewableContentHeight - object.height
	end
end--}}}
	
-- Processes the touch events on the background. Moves the player object accordingly.
onTouch = function(event)--{{{
	if gameIsOver then
		return
	end
	
	if "began" == event.phase then
		playerA.isFocus = true

		playerA.x0 = event.x - playerA.x
		playerA.y0 = event.y - playerA.y
        elseif playerA.isFocus then
			if "moved" == event.phase then
                        playerA.x = event.x - playerA.x0
                        playerA.y = event.y - playerA.y0
                        coerceOnScreen( playerA )
                elseif "ended" == phase or "cancelled" == phase then
                        playerA.isFocus = false
                end
        end
 
        -- Return true if touch event has been handled.
        return true
end--}}}

-- objectType is "food", "enemy", "reward", or "penalty" 
spawn = function( objectType, xVelocity, yVelocity )--{{{
	local object
	local sizeXY = math.random( 10, 20 )
	local startX
	local startY
	
	if 0 == xVelocity then
		-- Object moves along the y-axis	
		startX = math.random( sizeXY, display.contentWidth - sizeXY )
	end
	if xVelocity < 0 then
		-- Object moves to the left
		startX = display.contentWidth
	end
	if xVelocity > 0 then
		-- Object moves to the right
		startX = -sizeXY
	end

	if 0 == yVelocity then
		-- Object moves along the x-axis
		startY = math.random( sizeXY, display.contentHeight - sizeXY )
	end
	if yVelocity < 0 then
		-- Object moves to the top
		startY = display.contentHeight
	end
	if yVelocity > 0 then
		-- Object moves to the bottom
		startY = -sizeXY
	end
		
	local collisionFilter = { categoryBits = 4, maskBits = 2 } -- collides with player only
	local body = { filter=collisionFilter, isSensor=true }
	if "food" == objectType or "enemy" == objectType then
		object = display.newRect(  startX, startY, sizeXY, sizeXY )
		object.sizeXY = sizeXY
	end
	if "reward" == objectType or "penalty" == objectType then
		object = display.newCircle( startX, startY, 15 )
		object.sizeXY = 30
	end
	local objectAlpha
	if "food" == objectType or "reward" == objectType then
		object:setFillColor ( 0, 0, 0, (gameIsOver and 20 or 255) )
	else
		object:setFillColor ( 0, 0, 255, (gameIsOver and 20 or 255) )
	end
	object.objectType = objectType
	object.xVelocity = xVelocity
	object.yVelocity = yVelocity
	physics.addBody ( object, body )
	object.isFixedRotation = true
	table.insert ( objects,  object )
end--}}}

-- The game has different modes to make it interesting.
gameSpecial = function( objectType )--{{{
	local r = math.random ( 1, 3 )
			
	if "reward" == objectType then
		-- Decide which reward we are playing
		if 1 == r then
			-- Play weight loss - small player
			playerA.width = 15
			playerA.height = 15
			playerA.resize = true
			rewardLabel.text = "weight loss"
			rewardLabel.alpha = 0.25
			transition.to ( rewardLabel, { time=1000, alpha=0, delay=3000 } )
		elseif 2 == r then
			-- Play all you can eat - all enemies will turn into food
			rewardLabel.text = "all you can eat"
			rewardLabel.alpha = 0.25
			transition.to ( rewardLabel, { time=500, alpha=0, delay=4500 } )
			rewardBar.isVisible = true
			spawnConstraint = "allyoucaneat"
			local closure = function()
				spawnConstraint = "no"
				rewardBar.width = 280
				rewardBar.isVisible = false
		end
			transition.to ( rewardBar, { time=5000, width=0, onComplete=closure } )
		else
			-- Play traffic jam - all objects move with half the speed
			if speedFactor ~= 1 then
				-- Skip this special, because rush hour seems to be running
				return
			end
			rewardLabel.text = "traffic jam"
			rewardLabel.alpha = 0.25
			transition.to ( rewardLabel, { time=500, alpha=0, delay=4500 } )
			speedFactor = 0.5
			calculateNewVelocity( objects )
			rewardBar.isVisible = true
			local closure = function()
				speedFactor = 2
				calculateNewVelocity( objects )
				speedFactor = 1
				rewardBar.width = 280
				rewardBar.isVisible = false
		end
			transition.to ( rewardBar, { time=5000, width=0, onComplete=closure } )
		end
	elseif "penalty" == objectType then
		-- Decide which penalty we are playing
		if 1 == r then
			-- Play weight gain - big player
			playerA.width = 50
			playerA.height = 50
			playerA.resize = true
			penaltyLabel.text = "weight gain"
			penaltyLabel.alpha = 0.25
			transition.to ( penaltyLabel, { time=1000, alpha=0, delay=3000 } )
		elseif 2 == r then
			-- Play food contaminated - all food will turn into enemies
			penaltyLabel.text = "food contaminated"
			penaltyLabel.alpha = 0.25
			transition.to ( penaltyLabel, { time=500, alpha=0, delay=4500 } )
			penaltyBar.isVisible = true
			spawnConstraint = "foodcontaminated"
			local closure = function()
				spawnConstraint = "no"
				penaltyBar.width = 280
				penaltyBar.isVisible = false;
		end
			transition.to ( penaltyBar, { time=5000, width=0, onComplete=closure } )
		else
			-- Play rush hour - all objects move with double speed
			if speedFactor ~= 1 then
				-- Skip this special, because traffic jam seems to be running
				return
			end
			penaltyLabel.text = "rush hour"
			penaltyLabel.alpha = 0.25
			transition.to ( penaltyLabel, { time=500, alpha=0, delay=4500 } )
			speedFactor = 2
			calculateNewVelocity( objects )
			penaltyBar.isVisible = true
			local closure = function()
				speedFactor = 0.5
				calculateNewVelocity( objects )
				speedFactor = 1
				penaltyBar.width = 280
				penaltyBar.isVisible = false;
		end
			transition.to ( penaltyBar, { time=5000, width=0, onComplete=closure } )
		end
	end
	rewardLabel.x = display.viewableContentWidth / 2
	penaltyLabel.x = display.viewableContentWidth / 2
end--}}}

-- We want to get notified when a collision occurs
onCollision = function( event )--{{{
	if gameIsOver then
		return
	end
	
	--[[if "began" == event.phase then
		local o
		local ot
		if "player" == event.object1.objectType then
			o = event.object2
			ot = event.object2.objectType
		else
			o = event.object1
			ot = event.object1.objectType
		end
		if ("food" == ot and "no" == spawnConstraint) or "allyoucaneat" == spawnConstraint then
			-- Increase the score
			score = score + 1
			scoreLabel.text = tostring(score)
			audio.play ( pickUpSound  )
			-- Freddy eats, so Freddy gets bigger
			if playerA.width < 50 then
				-- We need to create a new player, because we change the player's width and height.
				-- Scaling of physics objects is not yet supported by Corona.
				playerA.width = playerA.width + 1
				playerA.height = playerA.height + 1
				playerA.resize = true
			end
			o.isVisible = false
		elseif "enemy" == ot  or "foodcontaminated" == spawnConstraint then
			gameOver()
		elseif "reward" == ot or "penalty" == ot then
			-- Object type is "reward" or "penalty"
			audio.play( powerUpSound  )
			o.isVisible = false
			gameSpecial(ot)
		end
	end]]--
end--}}}

-- Animates all objects. Also resizes the player by removing and readding it to the physics world.
animate = function( event )--{{{
    local tDelta = event.time - tPrevious
    tPrevious = event.time

	for _, object in pairs ( objects ) do
        local xDelta = object.xVelocity * tDelta
        local yDelta = object.yVelocity * tDelta
        local xPos = xDelta + object.x 
        local yPos = yDelta + object.y
        
		if (yPos > display.contentHeight + object.sizeXY) or (yPos < -object.sizeXY) or
				(xPos > display.contentWidth + object.sizeXY) or (xPos < -object.sizeXY) then
			object.isVisible = false
		end
 
        object:translate( xDelta, yDelta)
	end
	
	for key, object in pairs ( objects ) do
		if false == object.isVisible then
			local xVelocity = 0
			local yVelocity = 0
			if "food" == object.objectType or "enemy" == object.objectType then
				-- New object should move in same direction as the one which will be deleted
				if object.xVelocity < 0 then
					xVelocity = - randomSpeed()
				elseif object.xVelocity > 0 then
					xVelocity = randomSpeed()
				end
				if object.yVelocity < 0 then
					yVelocity = - randomSpeed()
				elseif object.yVelocity > 0 then
					yVelocity = randomSpeed()
				end
				-- Create new food and new enemies instantly
				spawn(object.objectType, xVelocity, yVelocity )
			else
				-- Create new rewards and new penalties after a random delay
				local sign = {1, -1}
				if 1 == math.random( 1, 2 ) then
					-- Move along x-axis. From top to bottom or bottom to top.
					xVelocity = randomSpeed() * sign[math.random(1, 2)]
				else
					-- Move along y-axis. From top to bottom or bottom to top.
					yVelocity = randomSpeed() * sign[math.random(1, 2)]
				end
				local bombshell
				-- Rewards and penalties will be spawned on a rotating basis.
				if "reward" == object.objectType then
					bombshell = "penalty"
				else
					bombshell = "reward"
				end
			local closure = function() return spawn(bombshell, xVelocity, yVelocity) end
				timer.performWithDelay ( math.random(6, 12) * 1000, closure, 1 )
			end
			object:removeSelf()
			table.remove(objects, key)
		end
	end

end--}}}
local llego=false
animateB=function ( event )

	if llego==false then
	moverIncB( )
	--print( playerB.x.. " y " ..playerB.y)

	end
	if llego==true then
 	MovB( )

	end	
end


local llegoC=false
animateC=function ( event )

	if llegoC==false then
		moverIncC( )
	--print( playerB.x.. " y " ..playerB.y)
	print("moverIncC")

	end
	if llegoC==true then
 		MovC( )
 		print( "MovC" )
	end


	
end

function moverIncB( )
	
	
	
	PosInix= 100
	PosIniy= 50


	if( playerB.x>PosInix+10 and  playerB.x<PosInix +20 )or  (playerB.x<PosInix-10 and  playerB.x>PosInix -20 ) and ( playerB.y>PosIniy+10 and  playerB.y<PosIniy +20 )or  (playerB.y<PosIniy-10 and  playerB.y>PosIniy-20 ) then
	llego=true
	end
	if playerB.x>=PosInix then
			playerB.x=playerB.x-1
	end
	if playerB.x<=PosInix then

			playerB.x=playerB.x+10
		-- body
	end
	

	if playerB.y>=PosIniy then
	
			playerB.y=playerB.y-1
	end
	if playerB.y<=PosIniy then

			playerB.y=playerB.y+1

		-- body
	end
	return llego
end
function MovB( )
	print("dife"..playerA.x-playerB.x )
	if (playerA.x-playerB.x<=200  and playerA.x-playerB.x>=-200) and (playerA.y-playerB.y<=200  and playerA.y-playerB.y>=-200)  then
		if (not(playerA.x ==playerB.x )) then

			print( "sigoA" )
			if playerA.x>playerB.x then
				playerB.x=playerB.x+1
			elseif playerA.x<playerB.x then
				playerB.x=playerB.x-1
			end
		end
		if  (not( playerA.y==playerB.y )) then

				if playerA.y>playerB.y then
					playerB.y=playerB.y+1
				elseif playerA.y<playerB.y then
					playerB.y=playerB.y-1
				end
		end
	else
		if (not(playerA.c ==playerB.x))  then
					print( "sigoC" )
						if playerC.x>playerB.x then
							playerB.x=playerB.x+1
						end
						if playerC.x<playerB.x then
							playerB.x=playerB.x-1
						end
					
					end


					if  (not( playerC.y==playerB.y ))  then

						if playerC.y>playerB.y then
							playerB.y=playerB.y+1
						end
						if playerC.y<playerB.y then
							playerB.y=playerB.y-1
						end
					end
		
	end
	--[[if (playerA.x-playerB.x<=.1 or playerA.x-playerB.x >-.1) and (playerA.y-playerB.y<=.1 or playerA.y-playerB.y>=-.1)then
		if (not(playerA.x ==playerB.x )) then

			print( "sigoA" )
			if playerA.x>playerB.x then
				playerB.x=playerB.x+1
			elseif playerA.x<playerB.x then
				playerB.x=playerB.x-1
			end
		end
		if  (not( playerA.y==playerB.y )) then

				if playerA.y>playerB.y then
					playerB.y=playerB.y+1
				elseif playerA.y<playerB.y then
					playerB.y=playerB.y-1
				end
		end
	
	else]]--
		
	

	-- body
end



function moverIncC( )
	PosInix= deviceContentWidth - 100
	PosIniy= deviceContentHeight - 100

	if( playerC.x<PosInix-10 and  playerC.x>PosInix -20 )or  (playerC.x>PosInix+10 and  playerC.x<PosInix+20 ) and ( playerC.y<PosIniy-10 and  playerC.y>PosIniy -20 )or  (playerC.y>PosIniy+10 and  playerC.y<PosIniy+20 ) then
		llegoC=true
	end
	if playerC.x<=PosInix then
			playerC.x=playerC.x+1
	end
	if playerC.x>=PosInix then
			playerC.x=playerC.x-10
	end
	

	if playerC.y<=PosIniy then
			playerC.y=playerC.y+1
	end
	if playerC.y>=PosIniy then
			playerC.y=playerC.y-1
	end
	return llegoC
end
function MovC( )
	print("dife"..playerA.x-playerB.x )
	if (playerC.x - playerB.x <= 200 and playerC.x - playerB.x >= -200) and (playerC.y-playerB.y <=200 and playerC.y-playerB.y >= -200)  then
		if (not(playerC.x == playerB.x)) then
			print( "alejate de B" )
			if playerC.x > playerB.x then
				playerC.x = playerC.x + 1
			elseif playerC.x < playerB.x then
				playerC.x = playerC.x - 1
			end
		end
		if  (not( playerC.y == playerB.y )) then
				if playerC.y > playerC.y then
					playerC.y = playerC.y+1
				elseif playerC.y < playerB.y then
					playerC.y = playerC.y-1
				end
		end
		-- if (playerC.x == deviceContentWidth or playerC.y == deviceContentHeight) then
		-- 		playerC.x = playerC.x - 1
		-- 		playerC.y = playerC.y - 1
		-- 	elseif (playerC.x == 0 or playerC.y == 0) then
		-- 		playerC.x = playerC.x + 1
		-- 		playerC.y = playerC.y + 1
		-- 	end
	-- 		print( "Muevete C" )
			
	end


end


--------------- END FUNCTIONS ---------------

-- Hide the status bar.
display.setStatusBar( display.HiddenStatusBar )

-- Preload the sounds.
failedSound = audio.loadSound( "failed.wav" )
pickUpSound = audio.loadSound( "pickup.wav" )
powerUpSound = audio.loadSound( "powerup.wav" )

-- Set the background color to white.
background = display.newRect( deviceContentWidth / 2, deviceContentHeight / 2, deviceContentWidth, deviceContentHeight )
background:setFillColor ( 1 )
-- Only the background receives touches. 
background:addEventListener( "touch", onTouch)

-- Load the last score and the highest score.
score, highScore = loadScores( )

-- Labels need to be centered after creation.
scoreLabel = display.newText( score, 0, 0, native.systemFontBold, 120 )
scoreLabel.x = display.viewableContentWidth / 2
scoreLabel.y = display.viewableContentHeight / 2
scoreLabel:setTextColor( 0, 0, 0, 10 )
scoreLabel.isVisible = false
	
rewardLabel = display.newText( "penalty", 0, 0, native.systemFontBold, 20 )
rewardLabel.x = display.viewableContentWidth / 2
rewardLabel.y = 95
rewardLabel:setTextColor( 0, 0, 0 )
rewardLabel.alpha = 0

rewardBar = display.newRect(  100, 80, 280, 30 )
rewardBar:setFillColor ( 0, 0, 0, 50 )
rewardBar.isVisible = false

penaltyLabel = display.newText( "penalty", 0, 0, native.systemFontBold, 20 )
penaltyLabel.x = display.viewableContentWidth / 2
penaltyLabel.y = display.viewableContentHeight - 15 - 80
penaltyLabel:setTextColor( 0, 0, 255 )
penaltyLabel.alpha = 0

penaltyBar = display.newRect(  100, display.viewableContentHeight -30 - 80, 280, 30 )
penaltyBar:setFillColor ( 0, 0, 255, 50 )
penaltyBar.isVisible = false

--Set up the physics world
physics = require("physics")
physics.start()
--physics.setDrawMode( "hybrid" )
physics.setScale( 60 )
-- Overhead view, like looking at a pool table. No gravity.
physics.setGravity( 0, 0 )

-- Create the player, a rotating black square.
playerA = createPlayerA( display.viewableContentWidth / 2, display.viewableContentHeight / 2, 20, 0, false )
playerB = createPlayerB( display.viewableContentWidth / 2, display.viewableContentHeight / 2, 25, 0, false )
playerC = createPlayerC( display.viewableContentWidth / 2, display.viewableContentHeight / 2, 10, 0, false )
-- Runtime:addEventListener( "enterFrame", function( ) player.rotation = player.rotation + 1; end )


-- Start listening to collision events.
Runtime:addEventListener ( "collision", onCollision )

-- Start the animations of all moving objects - except the player object.
Runtime:addEventListener( "enterFrame", animate );
Runtime:addEventListener( "enterFrame", animateB );
Runtime:addEventListener( "enterFrame", animateC );


-- spawn( "food", 0, randomSpeed() )
-- spawn( "food", 0, -randomSpeed() )
-- spawn( "food", randomSpeed(), 0 )
-- spawn( "food", -randomSpeed(), 0 )
-- spawn( "enemy", 0, randomSpeed() )
-- spawn( "enemy", 0, -randomSpeed() )
-- spawn( "enemy", randomSpeed(), 0 )
-- spawn( "enemy", -randomSpeed(), 0 )
spawn( "reward", randomSpeed(), 0 )

-- This is the actual entry point. The start.
menu = createMenu( )