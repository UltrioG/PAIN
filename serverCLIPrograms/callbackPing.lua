print("-!>[{ CALLBACK PING }]<!-")

os.queueEvent("PAINcallbackPing")

local inventories = {}

while true do
	local event, resultantInventories = os.pullEvent()
	if event == "PAINcallbackPingResult" then
		inventories = resultantInventories
	end
end

