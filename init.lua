local JSON = require "code.json"
print("Loading configs...")
local CONF_file		= io.open("painConfig.json", "r")
if not CONF_file then
	error([[
	Configuration file not found.
	A configuration file is necessary for this program to run.
	Please check whether there is a file named "painConfig.json" in the same directory as init.lua.
	If this issue persists despite this file existing, please contact the developer.
	]])
end
local CONF_str		= CONF_file:read("a")
---@type dictionary
local CONF_table	= JSON.decode(CONF_str)
print("Config reading success!")

print("PAIN - PAINful Allocative Item Network "..CONF_table.version)
print("Initializing setup program...")

print("Trying access to server...")

local function setupServer()
	require("server")()
end

local function setupClient()

end

local hasServer = not not rednet.lookup("pain.net", "SERVER")
if hasServer then
	print("Server found. Beginning client setup...")
	setupClient()
else
	print("Server not found. Beginning server setup...")
	setupServer()
end