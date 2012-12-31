screenWidth = MOAIEnvironment.screenWidth
screenHeight = MOAIEnvironment.screenHeight
print("Starting up on: " .. MOAIEnvironment.osBrand .. " version: " .. MOAIEnvironment.osVersion)

if screenWidth == nil then screenWidth = 1280 end
if screenHeight == nil then screenHeight = 720 end

stageWidth = 300
stageHeight = 200
scale = 10


MOAISim.openWindow("Window", screenWidth, screenHeight)

--setting up the viewport
viewport = MOAIViewport.new()
viewport:setSize(screenWidth, screenHeight)
viewport:setScale(stageWidth, stageHeight)

--setting up box2D world
world = MOAIBox2DWorld.new()
world:setGravity( 0, -10 )
world:setUnitsToMeters( 1 / scale )
world:setDebugDrawFlags( MOAIBox2DWorld.DEBUG_DRAW_SHAPES + MOAIBox2DWorld.DEBUG_DRAW_JOINTS +
                         MOAIBox2DWorld.DEBUG_DRAW_PAIRS + MOAIBox2DWorld.DEBUG_DRAW_CENTERS )

--setting up the main layer
layer = MOAILayer2D.new()
layer:setViewport(viewport)
layer:setBox2DWorld(world)
MOAIGfxDevice.setClearColor(1,1,1,1)


--Loading in smiley img so it stays in memory
texture = MOAIImage.new()
texture:load("smiley.png")

--Setting up the smiley player
sprite = MOAIGfxQuad2D.new()
sprite:setTexture(texture)
sprite:setRect(-5,-10, 5, 10)

--setting up the font
charCode = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 _+-()[]{}|\/?.,<>!~`@#$%^&*\'":;'
fontScale = screenHeight/stageHeight

--setting up debug textbox, adding a new layer
status = MOAITextBox.new()
status:setRect( -160 * fontScale, -100 * fontScale, 160 * fontScale, 100 * fontScale )
status:setScl( 1 / fontScale )
status:setYFlip( true )
status:setColor( 1, 1, 1 )
status:setString( 'status' )
status.font = MOAIFont.new()
status.font:load( 'CaviarDreams.ttf' )
status.font:preloadGlyphs( charCode, math.ceil( 4 * fontScale ), 72 )
status:setFont( status.font )
layer2 = MOAILayer2D.new()
layer2:setViewport( viewport )
layer2:insertProp( status )

--set up the ground
ground = {}
ground.verts = {
    -160, 100,
    -160, 10,
    -120, 10,
    -120, -10,
    -15, -10,
    -15, 5,
    5, 5,
    20, 20,
    40, 20,
    40, -18,
    140, -18,
    140, 20,
    160, 20,
    160, 100
}
ground.body = world:addBody( MOAIBox2DBody.STATIC, 0, -60 )
ground.body.tag = 'ground'
ground.fixtures = {
    ground.body:addChain( ground.verts )
}
ground.fixtures[1]:setFriction( 0.3 )
---
---

--Setting up player
player = {}
player.onGround = false
player.currentContactCount = 0
player.action = {
	moveLeft = false,
	moveRight = false,
	shooting = false
}
player.platform = nil
player.doubleJumped = false
player.verts = {
    -5, 8,
    -5, -9,
    -4, -10,
    4, -10,
    5, -9,
    5, 8
}
player.body = world:addBody( MOAIBox2DBody.DYNAMIC )
player.body.tag = 'player'
player.body:setFixedRotation( true )
player.body:setMassData( 80 )
player.body:resetMassData()
player.fixtures = {
    player.body:addPolygon( player.verts ),
    player.body:addRect( -4.9, -10.1, 4.9, -9.9 )
}
player.fixtures[1]:setRestitution( 0 )
player.fixtures[1]:setFriction( 0 )
--player.fixtures[2]:setSensor( true )
---
---
playerProp = MOAIProp2D.new()
playerProp:setDeck(sprite)
playerProp:setParent(player.body)
layer:insertProp(playerProp)


--player foot sensor
function footSensorHandler( phase, fix_a, fix_b, arbiter )
    if player.currentContactCount == 0 then
        player.onGround = false
    else
        player.onGround = true
        player.doubleJumped = false
    end
end
player.fixtures[2]:setCollisionHandler( footSensorHandler, MOAIBox2DArbiter.BEGIN + MOAIBox2DArbiter.END )
---
---

--Make a new quad for the bullet
spriteBullet = MOAIGfxQuad2D.new()
spriteBullet:setTexture("shot.png")
spriteBullet:setRect(-32,-32,32,32)

--Angle For the Shot to be Fired in
function angle ( x1, y1, x2, y2 )
 
 return math.rad(math.atan2 ( y2 - y1, x2 - x1 ) * ( 180 / math.pi ))
end
--Distance Function
function distance ( x1, y1, x2, y2 )
 
 return math.sqrt ((( x2 - x1 ) ^ 2 ) + (( y2 - y1 ) ^ 2 ))
end


function checkIfOutside(locX,locY)
	--print(locX .. " " .. locY)
	if (locX < screenWidth+20 and locX > -(screenWidth+20)) and (locY < screenHeight+20 and locY > -(screenHeight+20)) then
		return true
	else
		return false
	end
end

function makeBullet(targetX,targetY)
	local startX,startY = player.prop:getLoc()
	--print("start " .. startX .. " " .. startY)
	local bullet = MOAIProp2D.new()
	local angle = angle (startX,startY, targetX, targetY )
	--print("angle " .. angle)
	
	local moveinX = math.cos(angle) * 10
	local moveinY = math.sin(angle)  * 10
	
	--print(moveinX .. " " .. moveinY)

	bullet:setDeck(spriteBullet)
	layer:insertProp(bullet)
	bullet:setLoc(player:getLoc())
	bullet:setRot (  )
	--print(angle)

	function bullet:moveBullet()
		--MOAICoroutine.blockOnAction ( self:seekLoc ( targetX, targetY, timeTraveled, MOAIEaseType.LINEAR ))
		local locX,locY = bullet:getLoc()
		while checkIfOutside(locX,locY) do
			locX,locY = bullet:getLoc()
			self:setLoc(locX+moveinX,locY+moveinY)
			--coroutine.yield()
			--print(self:getLoc())
			coroutine.yield()
		end
		layer:removeProp(self)
		self.thread:stop()
	end
	bullet.thread = MOAICoroutine.new()
	bullet.thread:run(bullet.moveBullet, bullet)	
end


--Keyboard Callback function
function handleKeyInput(key,down)
	print(key)
	if key == 100 then
		--print("pressing")
		player.action.moveRight = true
	elseif key == 97 then
		--print("pressing")
		player.action.moveLeft = true		
	end
end

--Sets up the movement thread to handle the movement based on input
playerMovementThread = MOAICoroutine.new()
playerMovementThread:run( function()
	while true do
        local dx, dy = player.body:getLinearVelocity()
        if player.onGround then
            if player.action.moveRight and not player.action.moveLeft then
                dx = 50
            elseif player.action.moveLeft and not player.action.moveRight then
                dx = -50
            else
                dx = 0
            end
        else
            if player.action.moveRight and not player.action.moveLeft and dx <= 0 then
                dx = 25
            elseif player.action.moveLeft and not player.action.moveRight and dx >= 0 then
                dx = -25
            end
        end
        if player.platform then
            dx = dx + player.platform:getLinearVelocity()
        end
        player.body:setLinearVelocity( dx, dy )
        coroutine.yield()
    end
end )


--Gets the input from the user and passes it to the callback
if MOAIInputMgr.device.keyboard then
	MOAIInputMgr.device.keyboard:setCallback(handleKeyInput)
else
	print("No Keyboard")
end

if MOAIInputMgr.device.pointer then
	MOAIInputMgr.device.mouseLeft:setCallback(
		function(isMouseDown)
			if(isMouseDown) then
				print(layer:wndToWorld(MOAIInputMgr.device.pointer:getLoc() ))
				--makeBullet(layer:wndToWorld(MOAIInputMgr.device.pointer:getLoc()))
			end
		end		
	)	
else
	print("No Mouse")
end

-- update function for status box
statusThread = MOAIThread.new()
statusThread:run( function()
    while true do
        local x, y = player.body:getWorldCenter()
        local dx, dy = player.body:getLinearVelocity()
        status:setString( 'x, y:   ' .. math.ceil( x ) .. ', ' .. math.ceil( y )
                     .. '\ndx, dy: ' .. math.ceil( dx ) .. ', ' .. math.ceil( dy )
                     .. '\nOn Ground: ' .. ( player.onGround and 'true' or 'false' )
                     .. '\nContact Count: ' .. player.currentContactCount
                     .. '\nPlatform: ' .. ( player.platform and 'true' or 'false' ) )
        coroutine.yield()
    end
end )


-- render scene and begin simulation
world:start()
MOAIRenderMgr.setRenderTable( { layer, layer2 } )