version = "1.0"
list = {}
height = 5
lastSent = 0 --last turtle that an order was sent to
bridgeCode = "Ennec7t8" --the pastebin code for the code for the bridge turtles

function main()
	rednet.open("back")
	rednet.open("right")
	
	print("Sending restart")
	rednet.broadcast(true,"restart")
	
	while true do
		inputs()
	end
end

function inputs()
	local event, p1,p2,p3 = os.pullEvent()
	
	if event == "redstone" then
		if redstone.getInput("left") then
			buttonPress()
			return
		end
	end
	
	if event == "rednet_message" then
		if p3 == "gateAuth" then
			getAuth(p1,p2,p3)
			return
		end
		
		if p3 == "bridgeID" then
			turtleList(p1,p2,p3)
			return
		end
		
		if p3 == "doneBridge" then
			bridgeDone(p1,p2,p3)
			return
		end
		
		if p3 == "updateCheck" then
			redstone.setOutput("bottom",false)
			updateBridgeTurtles(p1,p2,p3)
			redstone.setOutput("bottom",true)
			return
		end
	end
end

function dance()
	if next(list) == nil then
		return
	end
	
	local turtle = math.random(1, #list)
	local move = math.random(1,3)
	
	rednet.send(list[turtle],move,"dance")
	print(list[turtle],move)
	--local senderId, message, protocol = rednet.receive("danceC")
	
end

function turtleList(senderId, message, protocol)
	--local senderId, message, protocol = rednet.receive("bridgeID")
	rednet.send(senderId,"","controllerID")
	local insert = true
	for i,turtle in ipairs(list) do
		if turtle == senderId then
			insert = false
		end
	end
	if insert then
		table.insert(list,senderId)
		print("Added turtle:", senderId)
	end
end

function buttonPress()
	--local event, p1, p2, p3 = os.pullEvent("redstone")
	redstone.setOutput("bottom",false)
	os.sleep(.1)
	cycleGate()

end

function getAuth(senderId, message, protocol)
	--local senderId, message, protocol = rednet.receive("gateAuth")
	
	if message == "b5bea41b6c623f7c09f1bf24dcae58ebab3c0cdd90ad966bc43a45b44867e12b" then
		rednet.send(senderId, true, "gateAuth")
		redstone.setOutput("bottom",false)
		os.sleep(.1)
		cycleGate()
	elseif message == "2937013f2181810606b2a799b05bda2849f3e369a20982a4138f0e0a55984ce4" then
		rednet.send(senderId, true, "gateAuth")
		pingTurtles()
		updateBridgeCheck()
	else
		rednet.send(senderId, false, "gateAuth")
	end
end

function cycleGate()
	
	if list[1] == nil then
		print("No turtles in list!")
		print("Unlocking bridge controls")
		return
	end
	
	print("Requesting y val from", list[1])
	rednet.send(list[1],"","coords")
	local senderId, message, protocol = rednet.receive("Tcoords",2)
	local dir = ""
	local all = true
	
	while message == nil do
		all = pingTurtles()
		print("Requesting y val from", list[1])
		rednet.send(list[1],"","coords")
		senderId, message, protocol = rednet.receive("Tcoords",2)
		if not all then
			print("All turtles accounted for! Perhaps there is a gps issue?")
		end
	end
	
	print("Got height!", message)
	if message < height then
		dir = "up"
	else
		dir = "down"
	end
	
	
	del = shuffleTurtles()
	print("Pinging turtles")
	
	pingTurtles()
	
	print("Moving turtles!")
	lastSent = list[#list]
	
	for i,turtle in ipairs(list) do
		rednet.send(turtle,{height,i*del},dir)
	end
	
	print("Last turtle sent: ", lastSent)
end

function bridgeDone(senderId, message, protocol)
	--local senderId, message, protocol = rednet.receive("doneBridge")
	--print("Turtle", senderId, "done")
	if message and senderId == lastSent then
		print("Unlocking bridge controls")
		redstone.setOutput("bottom",true)
	end
end

function pingTurtles()
	local all = true
	local inList = false
	for i = #list,1,-1 do
		inList = ping(list[i])
		if not inList then
			print("Removed", list[i])
			all = false
			table.remove(list,i)
		end
	end
	if all then
		print("All turtles accounted for!")
	end
	return all
end

function ping(turtle)
	--print("Pinging", turtle)
	rednet.send(turtle,true,"ping")
	local senderId, message, protocol = rednet.receive("pong",1)
	
	if message then
		--print("Pong from", turtle)
		return true
	end
	
	print("No response from", turtle)
	return false
end

function updateBridgeCheck()
	print("Sending update order")
	rednet.send(list[1],bridgeCode,"updateCheck")
end

function updateBridgeTurtles(senderId, message, protocol)
	--local senderId, message, protocol = rednet.receive("updateCheck")
	if message then
		print("Update required, updating turtles!")
		rednet.broadcast(bridgeCode,"bridgeUpdate")
		os.sleep(5)
		print("Sending restart!")
		rednet.broadcast(true,"restart")
		
		return
	end
	
	print("No update needed!")
end

function update(code)
--this will only work if the top of the program has a variable 'version = "version_num" '
	
	fs.delete("checkVersion.lua")
	shell.run("pastebin", "get", code, "checkVersion.lua")
	local v = {}
	local check = fs.open("checkVersion.lua", "r")
	local data = "{" .. check.readLine() .. "}"
	v = textutils.unserialize(data)
	
	if tonumber(v["version"]) > tonumber(version) then
		fs.delete("start.lua")
		shell.run("pastebin", "get", code, "start.lua")
		fs.delete("start.lua")
		fs.copy("checkVersion.lua", "start.lua")
		fs.delete("checkVersion.lua")
		shell.run("start")
	else
		fs.delete("checkVersion.lua")
		shell.run("start")
	end
	
end

function shuffleTurtles()
	shuffled = {}
	for i, v in ipairs(list) do
		local pos = math.random(1, #shuffled+1)
		table.insert(shuffled, pos, v)
	end
	list = shuffled
	local del = 4.2 / table.getn(list)
	if del < .025 then
		del = 0
	end
	return del
end

main()
