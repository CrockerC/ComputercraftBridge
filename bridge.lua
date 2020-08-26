version = "1.998" 
--decimals must never "roll over" ie "1.20" is an earlier build than "1.100" but is a larger value
-- instead do this "1.99" -> "1.991" to represent the 20th build

function main()
	os.pullEvent = os.pullEventRaw
	rednet.open("right")
	
	while turtle.down() do
	
	end
	
	os.sleep(math.random(2,22)/10)
	
	getGPS()
	ystart = y
	
	contID = sendID()
	

	while true do
		--turtle.refuel(64)
		parallel.waitForAny(listenForUp,listenForDown,sendCoords,listenForRestart,ping,checkUpdate,update,dance)
	end
end

function sendID()
	rednet.broadcast("","bridgeID") --asking for the ID of the controller while sending the ID of this turtle
	local senderId, message, protocol = rednet.receive("controllerID",2) --getting the id of the controller back
	while not senderId do
		--print("Failed to get response, retrying!")
		rednet.broadcast("","bridgeID") --asking for the ID of the controller while sending the ID of this turtle
		senderId, message, protocol = rednet.receive("controllerID",2) --getting the id of the controller back
	end
	
	--print("Got response!")
	
	return senderId
end

function sendCoords()
	local senderId, message, protocol = rednet.receive("coords")
	if senderId ~= contID then
		return
	end

	--print("Sending Coords!")
	rednet.send(senderId, y, "Tcoords")
end

function listenForRestart()
	local senderId, message, protocol = rednet.receive("restart")
	print("getting restart")
	
	if message then
		os.sleep(math.random(1,40)/10)
		print("restarting")
		while turtle.down() do
			y = y - 1
		end
		os.reboot()
	end
end

function listenForUp()
	local senderId, message, protocol = rednet.receive("up")
	--print("Going up!")
	
	if senderId ~= contID then
		return
	end
	
	local h,t = unpack(message)
	os.sleep(t)
	
	while y < h	 do
		turtle.up()
		y = y + 1
	end
	print(y)
	rednet.send(senderId,true,"doneBridge")
end

function listenForDown()
	local senderId, message, protocol = rednet.receive("down")
	
	if senderId ~= contID then
		return
	end
	
	local h,t = unpack(message)
	os.sleep(t)
	
	while turtle.down() do
		y = y - 1
	end
	y = ystart
	rednet.send(senderId,true,"doneBridge")
end

function ping()
	local senderId, message, protocol = rednet.receive("ping")
	rednet.send(senderId,true,"pong")
end

function dance()
	--be weary of this function, never could get it working right
	local senderId, message, protocol = rednet.receive("dance")
	
	if message == 1 then
		turtle.turnRight()
		os.sleep(1)
		turtle.turnLeft()
	elseif message == 2 then
		turtle.turnLeft()
		os.sleep(1)
		turtle.turnRight()
	else
		turtle.up()
		os.sleep(1)
		turtle.down()
	end

	
	rednet.send(senderId,true,"danceC")
end

function checkUpdate()

	local senderId, message, protocol = rednet.receive("updateCheck")
	
	fs.delete("checkVersion.lua")
	shell.run("pastebin", "get", message, "checkVersion.lua")
	local v = {}
	local check = fs.open("checkVersion.lua", "r")
	local data = "{" .. check.readLine() .. "}"
	v = textutils.unserialize(data)
	
	if tonumber(v["version"]) > tonumber(version) then
		rednet.send(senderId,true,"updateCheck")
	else
		rednet.send(senderId,false,"updateCheck")
	end
end

function getGPS()
	x,y,z = gps.locate(2)
	
	while tostring(x) == tostring(0/0) do
		--print("Failed to get gps location, retrying!")
		x,y,z = gps.locate(2)
	end
end

function update()
--this will only work if the top of the program has a variable 'version = "version_num" '
	
	local senderId, message, protocol = rednet.receive("bridgeUpdate")
	
	os.sleep(math.random(2,22)/10)
	
	local code = message
	fs.delete("checkVersion.lua")
	shell.run("pastebin", "get", code, "checkVersion.lua")
	local v = {}
	local check = fs.open("checkVersion.lua", "r")
	local data = "{" .. check.readLine() .. "}"
	v = textutils.unserialize(data)
	
	if tonumber(v["version"]) > tonumber(version) then
		print("Updating")
		--fs.delete("startup.lua")
		--shell.run("pastebin", "get", code, "startup.lua")
		fs.delete("startup")
		fs.copy("checkVersion.lua", "startup")
		fs.delete("checkVersion.lua")
		print("update complete! executing script!")
		shell.run("startup")
	else
		fs.delete("checkVersion.lua")
		shell.run("startup")
	end
	
end

main()
