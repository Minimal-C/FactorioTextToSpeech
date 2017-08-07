local textToSpeech = {}

local serpent = require "serpent"
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

-- return index of a value in a table
-- if not found return nil
local function indexOf(table,value)
	for k,v in pairs(table) do
		if v==value then
			return k
		end
	end
	return nil
end

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

function textToSpeech.init()
	-- get word phoneme definitions, and phoneme timings from respective modules, 
	-- (factorio lua doesn't include file io so this is a workaround, though requires explicit reload on game load)
	cmuDictFileTable = cmuDict.cmuTable
	timingsTable = timings.timingsTable
end

function textToSpeech.convertText(text, entityBlockLength, timeBetweenWords, instrumentId)

	-- strip non-word chars from text, except for ' and [  ]
	local text = string.gsub(text,"[^A-Za-z0-9_'%[%]]"," ")

	local phonemesTable = {}
	local wordIndexes = {}

	local isDoingCustomWord = false
	local phonemeCounter = 0
	local unrecognisedWords = {}
	local unrecognisedPhonemes = {}

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

	if #unrecognisedWords > 0 then
		return {},unrecognisedWords,{}
	end
	if #unrecognisedPhonemes > 0 then
		return unrecognisedPhonemes,{},{}
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
			timeCounter = timeCounter + ((timingsTable[indexOf(phonemesList,v)]*60)/1000) + timeBetweenWords
			else
				-- otherwise just increment the timer by the length of the phoneme
				timeCounter = timeCounter + (timingsTable[indexOf(phonemesList,v)]*60)/1000
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
		
		-- print(k,v,indexOf(phonemesList,v),timingsTable[k])

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

		xPos, yPos, goRight = textToSpeech.doEntityArrangement(xPos, yPos, goRight, 1, 2, entityBlockLength)

		-- increment timer
		if indexOf(wordIndexes, k) then
			-- add time for phoneme plus gap between words
			timeCounter = timeCounter + ((timingsTable[indexOf(phonemesList,v)]*60)/1000) + timeBetweenWords
			else
				-- just add the time for phoneme
				timeCounter = timeCounter + (timingsTable[indexOf(phonemesList,v)]*60)/1000
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
						parameters={playback_volume=1.0,playback_globally=true,allow_polyphony=true},
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
							parameters = {playback_volume=1.0,playback_globally=true,allow_polyphony=true},
							alert_parameters = {show_alert = false, show_on_map = false, alert_message=""}
						}
				end

				table.insert(entities,entity)
				table.insert(usedNotesSet,noteIndex)
				
				entityNum= entityNum+1
				
				xPos, yPos, goRight = textToSpeech.doEntityArrangement(xPos, yPos, goRight, 1, 1, entityBlockLength)
		end
	end

	return unrecognisedPhonemes, unrecognisedWords,entities
end

function textToSpeech.doEntityArrangement(x, y, goRight, xSize, ySize, entityBlockLength)
	
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

-- Check if the word phoneme definitions and sound timings are loaded.
function textToSpeech.are_definitions_loaded()
	if cmuDictFileTable==nil or timingsTable==nil then
		return false
		else
		return true
	end
end
return textToSpeech