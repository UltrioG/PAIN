-- MAIN
return function ()
	peripheral.find("modem", rednet.open)

	rednet.host("pain.net", "SERVER")
end