-----------------------------------------------------------------------------
--  This module stores the timing information (length of each sound in ms) 
--	for each supported instrument/voice. 
--	(Factorio restricts loading external files so it's stored in this module
--	instead, there is probably a better method to accomplish this)
-----------------------------------------------------------------------------
local timings = {}

local voice1 = {149.1875,188.75,136.0625,165.5,153.6875,133.5,102.3125,132.1875,91.4375,52.875,151.1875,177.125,141.6875,121.25,63.75,102.9375,152.0,137.3125,123.25,143.5625,113.6875,112.6875,98.0625,122.25,146.3125,150.4375,143.8125,109.0625,123.0625,113.5,121.625,114.625,166.0625,124.125,100.875,87.75,112.5,94.4375,109.1875}

timings.timingsTable = {}

timings.timingsTable["voice1"] = voice1

return timings