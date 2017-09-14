-----------------------------------------------------------------------------
--  This module implements text-to-speech conversion functionality for
--  Factorio. It uses phoneme concatenation to synthesize speech with the 
-- 	in-game Factorio programmable-speaker-instruments using custom voices.
-----------------------------------------------------------------------------

local textToSpeech = {}

local cmuDict = require "cmuDict"
local timings = require "timings"

local phonemesList = {"AA","AE","AH","AO","AW","AY","B","CH","D","DH","EH","ER","EY","F","G","HH","IH","IY","JH","K","L","M","N",
	"NG","OW","OY","P","R","S","SH","T","TH","UH","UW","V","W","Y","Z","ZH"}

-- associate each phoneme with a signal value (1 signal for each phoneme, though it might make sense to spell the phoneme with signals to identify it)
local signalsList = {
	AA="signal-0",AE="signal-1",AH="signal-2",AO="signal-3",AW="signal-4",AY="signal-5", B="signal-6",
	CH="signal-7", D="signal-8",DH="signal-9",EH="signal-A",ER="signal-B",EY="signal-C", F="signal-D",
	 G="signal-E",HH="signal-F",IH="signal-G",IY="signal-H",JH="signal-I", K="signal-J", L="signal-K",
	 M="signal-L", N="signal-M",NG="signal-N",OW="signal-O",OY="signal-P", P="signal-Q", R="signal-R",
	 S="signal-S",SH="signal-T", T="signal-U",TH="signal-V",UH="signal-W",UW="signal-X", V="signal-Y",
	 W="signal-Z", Y="signal-black", Z="signal-blue",ZH="signal-cyan"
	}

local cmuDictFileTable = {}
local timingsTable = {}

-----------------------------------------------------------------------------
-- Finds the index of a value in a table.
--
-- @param table					The table to search for the value in.
-- @param value         The value to search for (string, int, etc.)
--
-- @return             	The index of the value, otherwise if value not 
--											present then return nil
-----------------------------------------------------------------------------
local function indexOf(table,value)
	for k,v in pairs(table) do
		if v==value then
			return k
		end
	end
	return nil
end

-----------------------------------------------------------------------------
-- Get the entities that make up a Factorio timer (constant combinator + decider cominator)
--
-- @param length				The length of the timer before it resets (ticks)
--
-- @return             	Returns a table containing the timer entities
-----------------------------------------------------------------------------
local function getTimerEntities(length)
	return {
		{entity_number=1, name="constant-combinator" ,position={x=0.0,y=0.0}, direction=4, 
		control_behavior={filters={{signal={type="virtual",name="signal-0"},count=1,index=1}},is_on=false},
  	connections= {["1"]={red={{entity_id=2,circuit_id=1}}}}},
		{entity_number=2,name="decider-combinator",position={x=0.0,y=1.5}, direction=4,
  	control_behavior={decider_conditions={first_signal={type="virtual",name="signal-0"},constant=length,
		comparator="<",output_signal={type="virtual",name="signal-0"},copy_count_from_input=true},is_on=false},
  	connections={["1"]={red={{entity_id=1,circuit_id=1},{entity_id=2,circuit_id=2}}},["2"]={red={{entity_id=2,circuit_id=1}}}}}
	}
end

-----------------------------------------------------------------------------
-- Get an integer back as a string of words. (e.g. input:42 output:"forty two")
-- Function ported from http://rosettacode.org/wiki/Number_names#Java ,
-- some modifications made to make output strings more readable
--
-- @param number				The integer to be converted.
--
-- @return             	A string of words which describe the integer.
-----------------------------------------------------------------------------
local function number_to_words(number)
	number = tonumber(number)
	local small = {"one", "two", "three", "four", "five", "six",
				"seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen",
				"fifteen", "sixteen", "seventeen", "eighteen", "nineteen"}
	local tens = {"twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty",
				"ninety"}
	local big = {"thousand", "million", "billion", "trillion"}

	local num = 0
	local outP = ""
	local unit = 0
	local tmpLng1 = 0

	if (number == 0) then
		return "zero"
	end

	local num = math.abs( number )

	while true do
		tmpLng1 = num % 100
		if (tmpLng1 >= 1 and tmpLng1 <= 19) then
			outP = small[math.floor(tmpLng1)] .. " " .. outP
		elseif (tmpLng1 >= 20 and tmpLng1 <= 99) then
			if (math.floor(tmpLng1 % 10) == 0) then
				outP = tens[math.floor((tmpLng1 / 10) - 1)] .. " " .. outP
				else 
					outP = tens[math.floor((tmpLng1 / 10) - 1)] .. " "
						.. small[math.floor(tmpLng1 % 10) ] .. " " .. outP
			end
		end
		
		tmpLng1 = (num % 1000) / 100
		if (math.floor(tmpLng1) ~= 0) then
			if outP=="" then
				outP = small[math.floor(tmpLng1)] .. " hundred "
				elseif indexOf(big,outP) or indexOf(big,(string.match( outP,"[^%s]+")))then
					outP = small[math.floor(tmpLng1)] .. " hundred " .. outP
				else
					outP = small[math.floor(tmpLng1)] .. " hundred and " .. outP
			end
		end

		num = num/1000
		if (num == 0) then
			break
		end

		tmpLng1 = num % 1000
		if (math.floor(tmpLng1) ~= 0) then
			if outP=="" then
				outP = big[unit + 1]
				elseif indexOf(big, outP) then
					outP = big[unit + 1] .. " " .. outP
				else
					outP = big[unit + 1] .. " and " .. outP
			end
		end
		unit = unit + 1
	end -- end while loop

	if (number < 0) then
		outP = "negative " .. outP
	end

	-- return trimmed string
	return (outP:gsub("^%s*(.-)%s*$", "%1"))

end

-----------------------------------------------------------------------------
-- Checks the validity the supplied parameters, checks parameters are correct range & 
-- type, if not valid specific errors are returned.
--
-- @param text											The input text string for text-to-speech conversion
-- @param entityBlockLength         The in-game integer width of the entity blueprint
-- @param timeBetweenWords					The pause time between words being spoken (ticks)
--
-- @return             							A table of errors containing specific errors if
--																	present, if no errors then table contains nil
-----------------------------------------------------------------------------
local function validateParameters(text, entityBlockLength, timeBetweenWords)
	
	local errors = {}

	-- if no text present
	if #text==0 then
		local noTextError = {"Error - No Input Text",""}
		table.insert(errors,noTextError)
	end

	-- if the earlier conversion to number failed, aka it's not a number, then show error message
	if not entityBlockLength then
		local blockError = {"Error - Invalid Width Value","Blueprint width must be a number"}
		table.insert(errors,blockError)
		
		-- if its a number and it's value is less than 1, show error message
		elseif entityBlockLength < 1 then
			local blockError = {"Error - Width Out Of Range", "Blueprint width must be greater than 0"}
			table.insert(errors,blockError)
	end

	if not timeBetweenWords then
		local timeError = {"Error - Invalid Pause Value", "Pause time must be a number"}
		table.insert(errors,timeError)

		-- if pause time is a number and it's value is negative, show error message
		elseif timeBetweenWords < 0 then
			local timeError = {"Error - Pause Out Of Range", "Pause time must be greater than or equal to 0"}
			table.insert(errors,timeError)
	end

	return errors
end

-----------------------------------------------------------------------------
-- Arranges blueprint entities in a zig-zag pattern, usually forming a rectangular
-- block of entities in-game (depending on parameters). This method updates the x and
-- y values for the next entity you wish to place.
--
-- @param x													The x position in blueprint
-- @param y													The y position in blueprint
-- @param goRight										Boolean describing the direction entities are being placed
-- @param xSize											The size of the entity in the x axis (horizontal)
-- @param ySize											The size of the entity in the y axis (vertical)
-- @param entityBlockLength         The in-game width of the entity blueprint
--
-- @return													The updated values for x, y and goRight for the next entity
-----------------------------------------------------------------------------
local function doEntityArrangement(x, y, goRight, xSize, ySize, entityBlockLength)
	
	if goRight==nil then
		goRight=true
	end

			
	if goRight then
		x = x+xSize
	else 
		x = x-xSize
	end
	
	-- increment y onto new line if needed
	-- change direction if needed
	if x==-1 then
		goRight = true
		x = 0
		y = y+ySize
		elseif x==entityBlockLength then
			goRight = false
			x = entityBlockLength-1
			y = y+ySize
	end

	return x,y,goRight

end

-----------------------------------------------------------------------------
-- Initializes the module, loading the CMU Dictionary (word to phoneme definitions),
-- as well as loading the timing information for each voice (how long each sound lasts).
-----------------------------------------------------------------------------
function textToSpeech.init()
	-- get word phoneme definitions, and phoneme timings from respective modules, 
	-- (factorio lua doesn't include file io so this is a workaround, though requires explicit reload on game load)
	-- almost certainly there is a better way to do it than this (this way requires calling this every time game is loaded)
	cmuDictFileTable = cmuDict.cmuTable
	
	timingsTable = timings.timingsTable
end

-----------------------------------------------------------------------------
-- Convert a string of words into a table of Factorio entities which when
-- placed in-game, plays the input text as a synthesized voice using programmable
-- speakers sounds.
--
-- @param text											The input text string for text-to-speech conversion (a sentence)
-- @param globalPlayback						Boolean for selecting if in-game speakers playback globally or locally
-- @param entityBlockLength         The in-game width of the entity blueprint
-- @param timeBetweenWords					The pause time between words being spoken (ticks)
-- @param instrumentId							The in-game programmable-speaker-instrument ID to use
-- @param instrumentName						The programmatic name (not localized name) of the instrument to use
--
-- @return													Returns errors encountered (table containing nil if none), and returns the
--																	table of entities.
-----------------------------------------------------------------------------
function textToSpeech.convertText(text, globalPlayback, entityBlockLength, timeBetweenWords, instrumentId, instrumentName)

	-- get errors if parameters have invalid values etc
	local parameterErrors = validateParameters(text, entityBlockLength, timeBetweenWords)

	-- strip non-word chars from text, except for ' - and [  ]
	local text = string.gsub(text,"[^A-Za-z0-9_'%[%]%-]"," ")
	
	local voiceTimings = timingsTable[instrumentName]
	
	local errorOutput = {}
	local unrecognisedWords = {}
	local unrecognisedPhonemes = {}

	local phonemesTable = {}
	local wordIndexes = {}

	local isDoingCustomWord = false
	local phonemeCounter = 0
	
	--replace numbers with word equivalents
	text = string.gsub( text, "%-?%d+", number_to_words)

	-- process input text into phoneme representation
	-- and record where words end, for pauses (see next for loop)
	-- TODO: improve readability, logic flow too complex
	for word in string.gmatch(text, "[^%s]+") do
		word = string.upper( word )
		
		if isDoingCustomWord then
			
			if string.sub(word,#word,#word) == "]" then
				isDoingCustomWord = false
				table.insert( phonemesTable, string.sub( word, 1, #word-1 ) )

				-- if phoneme is unrecognised, try to add it to error list
				if not indexOf(phonemesList, string.sub( word, 1, #word-1 )) then
					if not indexOf(unrecognisedPhonemes, string.sub( word, 1, #word-1 )) then
						table.insert(unrecognisedPhonemes, string.sub( word, 1, #word-1 ))
					end
				end

				phonemeCounter = phonemeCounter + 1

				-- record end of word position
				table.insert( wordIndexes, phonemeCounter )

				else
					table.insert( phonemesTable, word )
					-- if phoneme is unrecognised, try to add it to error list
					if not indexOf(phonemesList, word) then
						if not indexOf(unrecognisedPhonemes, word) then
							table.insert(unrecognisedPhonemes, word)
						end
					end
					phonemeCounter = phonemeCounter + 1
			end

		elseif cmuDictFileTable[word] then
			phonemesString = cmuDictFileTable[word]
			for v in string.gmatch(phonemesString, "[^%s]+") do
				table.insert(phonemesTable, v)
				phonemeCounter = phonemeCounter + 1
			end
			-- record end of word position
			table.insert( wordIndexes, phonemeCounter )
		elseif string.sub(word,1,1) == "[" then
			isDoingCustomWord = true
			table.insert( phonemesTable, string.sub( word, 2, #word ) )
			-- if phoneme is unrecognised, try to add it to error list
			if not indexOf(phonemesList, string.sub( word, 2, #word )) then
				if not indexOf(unrecognisedPhonemes, string.sub( word, 2, #word )) then
					table.insert(unrecognisedPhonemes, string.sub( word, 2, #word ))
				end
			end
			phonemeCounter = phonemeCounter + 1
		elseif not indexOf(unrecognisedWords, word) then
			table.insert( unrecognisedWords, word)
		end
	end -- end for loop

	-- throw error if unrecognised things present
	if #unrecognisedWords > 0 or #unrecognisedPhonemes > 0 or #parameterErrors>0 then
		table.insert(errorOutput, unrecognisedPhonemes)
		table.insert(errorOutput, unrecognisedWords)
		table.insert(errorOutput, parameterErrors)
		error(errorOutput)
	end

	local entities = {}
	local usedNotesSet = {}
	local timeCounter = 1

	-- go through each phoneme and work out total time
	for k,v in pairs(phonemesTable) do
	
		local noteIndex = indexOf(phonemesList,v) - 1

		if indexOf(usedNotesSet,noteIndex) then
			else
			table.insert( usedNotesSet, noteIndex)
		end

		if indexOf(wordIndexes, k) then
			-- if at end of word add phoneme length plus pause to timer
			timeCounter = timeCounter + ((voiceTimings[indexOf(phonemesList,v)]*60)/1000) + timeBetweenWords
			else
				-- otherwise just increment the timer by the length of the phoneme
				timeCounter = timeCounter + (voiceTimings[indexOf(phonemesList,v)]*60)/1000
		end
	end -- end for loop

	local numUniqueNotes = #usedNotesSet

	local length = math.ceil( timeCounter )

	local timerEntities = getTimerEntities(length)
	table.insert( entities,  timerEntities[1] )
	table.insert( entities,  timerEntities[2] )

	local entityNum = 3
	local xPos = 0.0
	local yPos= 3.5
	timeCounter=1
	local goRight=true
	local len = #phonemesTable

	for k,v in pairs(phonemesTable) do
		
		if k == 1 then
			
			entity = {
				entity_number=entityNum,name="decider-combinator",position={x=xPos,y=yPos}, direction=4, 
				control_behavior={decider_conditions={first_signal={type="virtual",name="signal-0"},constant=math.ceil( timeCounter ),
				comparator="=",output_signal={type="virtual",name=signalsList[v]},copy_count_from_input=false}},
				connections={["1"]={red={{entity_id=entityNum - 1,circuit_id=1}}}}
			}
			elseif k == len then
				entity = {
					entity_number=entityNum,name="decider-combinator",position={x=xPos,y=yPos}, direction=4, 
					control_behavior={decider_conditions={first_signal={type="virtual",name="signal-0"},constant=math.ceil( timeCounter ),
					comparator="=",output_signal={type="virtual",name=signalsList[v]},copy_count_from_input=false}},
					connections={
						["1"]={red={{entity_id=entityNum - 1,circuit_id=1}}},
						["2"]={red={{entity_id=entityNum - 1, circuit_id=2},{entity_id=entityNum + 1}}}
					}
				}
				else
					entity = {
						entity_number=entityNum,name="decider-combinator",position={x=xPos,y=yPos}, direction=4, 
						control_behavior={decider_conditions={first_signal={type="virtual",name="signal-0"},constant=math.ceil( timeCounter ),
						comparator="=",output_signal={type="virtual",name=signalsList[v]},copy_count_from_input=false}},
						connections={
							["1"]={red={{entity_id=entityNum - 1,circuit_id=1}}},
							["2"]={red={{entity_id=entityNum - 1, circuit_id=2}}}
						}
					}
		end
		
		table.insert(entities,entity)

		entityNum= entityNum+1

		xPos, yPos, goRight = doEntityArrangement(xPos, yPos, goRight, 1, 2, entityBlockLength)

		-- increment timer
		if indexOf(wordIndexes, k) then
			-- add time for phoneme plus gap between words
			timeCounter = timeCounter + ((voiceTimings[indexOf(phonemesList,v)]*60)/1000) + timeBetweenWords
			else
				-- just add the time for phoneme
				timeCounter = timeCounter + (voiceTimings[indexOf(phonemesList,v)]*60)/1000
		end
	end
	
	-- add speaker entities
	-- usedNotesSet for creating only 1 speaker per phoneme/note
	local usedNotesSet = {}
	for k,v in pairs(phonemesTable) do

		noteIndex = indexOf(phonemesList,v) - 1

		-- if speaker for note already exists don't add speaker
		if indexOf(usedNotesSet,noteIndex) then
			
			else
				if k == 1 then
					-- don't specify the connections for the first speaker (previous and next entities do it. Not quite sure why it needs to be specified like this but it works)
					entity = {
						entity_number=entityNum,name="programmable-speaker",position={x=xPos,y=yPos}, direction=4, 
						control_behavior={circuit_condition={first_signal={type="virtual",name=signalsList[v]},constant=1,comparator="="},
						circuit_parameters={signal_value_is_pitch = false, instrument_id = instrumentId, note_id = noteIndex}},
						parameters={playback_volume=1.0,playback_globally=globalPlayback,allow_polyphony=true},
						alert_parameters = {show_alert = false, show_on_map = false, alert_message=""}
					}
					else
						-- specify the connections
						entity = {
							entity_number=entityNum,name="programmable-speaker",position={x=xPos,y=yPos}, direction=4, 
							control_behavior={circuit_condition={first_signal={type="virtual",name=signalsList[v]},constant=1,comparator="="},
								circuit_parameters = {signal_value_is_pitch = false, instrument_id = instrumentId, note_id = noteIndex} },
							connections={
								["1"]={red={{entity_id=entityNum - 1}}}
							},
							parameters = {playback_volume=1.0,playback_globally=globalPlayback,allow_polyphony=true},
							alert_parameters = {show_alert = false, show_on_map = false, alert_message=""}
						}
				end

				table.insert(entities,entity)
				table.insert(usedNotesSet,noteIndex)
				
				entityNum= entityNum+1
				
				xPos, yPos, goRight = doEntityArrangement(xPos, yPos, goRight, 1, 1, entityBlockLength)
		end
	end
		table.insert(errorOutput, unrecognisedPhonemes)
		table.insert(errorOutput, unrecognisedWords)
		table.insert(errorOutput, parameterErrors)
	return errorOutput,entities
end

-----------------------------------------------------------------------------
-- Checks if the word phoneme definitions and sound timings are loaded.
--
-- @return				boolean value
-----------------------------------------------------------------------------
function textToSpeech.are_definitions_loaded()
	if cmuDictFileTable==nil or timingsTable==nil then
		return false
		else
		return true
	end
end

return textToSpeech
