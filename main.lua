screenWidth = MOAIEnvironment.screenWidth
screenHeight = MOAIEnvironment.screenHeight
print("Starting up on: " .. MOAIEnvironment.osBrand .. " version: " .. MOAIEnvironment.osVersion)

if screenWidth == nil then screenWidth = 640 end
if screenHeight == nil then screenHeight = 480 end

MOAISim.openWindow("Window", screenWidth, screenHeight)

viewport = MOAIViewport.new()
viewport:setSize(screenWidth, screenHeight)
viewport:setScale(screenWidth, screenHeight)

layer = MOAILayer2D.new()
layer:setViewport(viewport)
MOAIGfxDevice.setClearColor(1,1,1,1)

MOAIRenderMgr.pushRenderPass(layer)

--Loading in smiley img so it stays in memory
texture = MOAIImage.new()
texture:load("smiley.png")

--Setting up the smiley player
sprite = MOAIGfxQuad2D.new()
sprite:setTexture(texture)
sprite:setRect(-50,-50, 50, 50)

player = MOAIProp2D.new()
player:setDeck(sprite)
player:setLoc(0,5)
layer:insertProp(player)

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


moveRight = false
moveLeft = false;
shooting = false;

function checkIfOutside(locX,locY)
	--print(locX .. " " .. locY)
	if (locX < 350 and locX > -350) and (locY < 260 and locY > -260) then
		return true
	else
		return false
	end
end

function makeBullet(targetX,targetY)
	local startX,startY = player:getLoc()
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
	if key == 100 and down == true then
		--print("pressing")
		moveRight = true
	elseif key == 100 and down == false then
		--print("not pressing")
		moveRight = false
	elseif key == 97 and down == true then
		--print("pressing")
		moveLeft = true
	elseif key == 97 and down == false then
		--print("not pressing")
		moveLeft = false
	elseif key == 32 and down == true then
		--print("pressing")
		shooting = true
	elseif key == 32 and down == false then
		--print("not pressing")
		shooting = false				
	end
end

--Sets up the movement thread to handle the movement based on input
movementThread = MOAICoroutine.new()
movementThread:run( function()
	while true do
		if moveRight == true then
			local locX,locY = player:getLoc()
			player:setLoc(locX+10,locY)
		elseif moveLeft == true then
			local locX,locY = player:getLoc()
			player:setLoc(locX-10,locY)			
		elseif shooting == true then
			local locX,locY = player:getLoc()
			makeBullet(locX,locY)			
		end		
		coroutine.yield()
	end
end)

--Gets the input from the user and passes it to the callback
if MOAIInputMgr.device.keyboard then
	--print(MOAIInputMgr.device.keyboard:keyUp("97"))
	--print(MOAIInputMgr.device.keyboard:keyIsDown("a"))
	MOAIInputMgr.device.keyboard:setCallback(handleKeyInput)
else
	print("No Keyboard")
end

if MOAIInputMgr.device.pointer then
	MOAIInputMgr.device.mouseLeft:setCallback(
		function(isMouseDown)
			if(isMouseDown) then
				print(player:getLoc())
				print(layer:wndToWorld(MOAIInputMgr.device.pointer:getLoc() ))
				makeBullet(layer:wndToWorld(MOAIInputMgr.device.pointer:getLoc()))
			end
		end		
	)	
else
	print("No Mouse")
end

