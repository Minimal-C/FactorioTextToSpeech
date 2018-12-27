local voiceData = require "voiceData"
local serpent = require("serpent")
require("Phoneme")
require("Utterance")
require("HL1Word")
require("utils")

if not textToSpeech then textToSpeech = {} end

isDoingCustomWord=false

function numberPass(text)
  text = string.gsub( text, "%-?%d+", convertNumberToWords)
  return text
end

function getPhonemesFromWord(word, voiceData)
  --ensure word is upper case for correct lookup
  local word = string.upper(word)
  local wordAsPhonemesString

  if not isDoingCustomWord then
    if string.sub(word, 1, 1) == "[" then
      isDoingCustomWord = true
      wordAsPhonemesString = string.sub(word, 2)
    else
      wordAsPhonemesString = voiceData.cmuTable[word]
      -- if the word isn't recognised, exit with failure
      if not wordAsPhonemesString then
        return nil, word
      end
    end
  else -- is doing custom word
    if string.sub(word, #word, #word) == "]" then
      isDoingCustomWord = false
      wordAsPhonemesString = string.sub(word, 1, #word-1)
      if not voiceData.phonemes[wordAsPhonemesString] then
        return nil, word
      end
    elseif voiceData.phonemes[word] then
        wordAsPhonemesString = word
    else
      return nil, word
    end
  end

  local wordPhonemes = {}

  for phonemeName in string.gmatch(wordAsPhonemesString,"[^%s]+") do    
    local phonemeDurationInTicks = millisecondsToTicks(voiceData.phonemes[phonemeName])
    table.insert(wordPhonemes,Phoneme:new(nil,phonemeName,phonemeDurationInTicks))
  end

  -- Add pause after word
  if not isDoingCustomWord then
    local pauseDurationInTicks = millisecondsToTicks(voiceData.phonemes["PAU"])
    table.insert(wordPhonemes,Phoneme:new(nil,"PAU",pauseDurationInTicks))
  end

  return wordPhonemes, nil
end

function getPhonemesFromSentence(text, voiceData)
  local sentencePhonemes = {}
  local unknownWords = {}

  for word in string.gmatch(text, "[^%s]+") do
    local wordPhonemes, errorWord = getPhonemesFromWord(word, voiceData)
    
    if wordPhonemes then
      for _,phoneme in pairs(wordPhonemes) do
        table.insert(sentencePhonemes,phoneme)
      end
    else
      table.insert(unknownWords, errorWord)
    end
  end
  return sentencePhonemes, unknownWords
end

function getHL1WordsFromSentence(text, hl1VoiceData)
  local sentenceHL1Words = {}
  local unknownWords = {}

  for word in string.gmatch(text, "[^%s]+") do
    if hl1VoiceData.phonemes[word] then
      local wordDurationInTicks = millisecondsToTicks(hl1VoiceData.phonemes[word])
      table.insert(sentenceHL1Words, HL1Word:new(nil,word,wordDurationInTicks))
      
      wordDurationInTicks = millisecondsToTicks(hl1VoiceData.phonemes["pau"])
      table.insert(sentenceHL1Words, HL1Word:new(nil,"pau",wordDurationInTicks))
    else
      table.insert(unknownWords, word)
    end
  end

  return sentenceHL1Words, unknownWords
end

function makeUtterance(text, voiceData)
  text = numberPass(text)
  if voiceData.name=="cmuData" then
    phonemes, unknownWords = getPhonemesFromSentence(text, voiceData)
    utterance = Utterance:new(nil,phonemes)
  elseif voiceData.name=="hl1Data" then
    hl1Words, unknownWords = getHL1WordsFromSentence(text, voiceData)
    utterance = Utterance:new(nil,hl1Words)
  end
  return utterance, unknownWords
end

function makeSpeakerEntity(entityNum, xPos, yPos, tick, instrumentId, noteIndex, isGlobalPlayback)
  entity= 
  {
    entity_number=entityNum,
    name="programmable-speaker",
    position=
      {
        x=xPos,
        y=yPos
      },
    direction=4,
    control_behavior=
      {
        circuit_condition=
          {
            first_signal=
            {
              type="virtual",
              name="signal-0"
            },
            constant=math.ceil(tick),
            comparator="="
          },
        circuit_parameters=
          {
            signal_value_is_pitch = false,
            instrument_id = instrumentId,
            note_id = noteIndex} 
      },
    connections=
    {
      ["1"]=
        {
          red=
            {
              {
                entity_id=entityNum-1,
                circuit_id=1
              }
            }
          }
    },
    parameters= 
      {
        playback_volume=1.0,
        playback_globally=isGlobalPlayback,
        allow_polyphony=true
      },
    alert_parameters=
      {
        show_alert = false,
        show_on_map = false,
        alert_message=""
      }
  }
  return entity
end

local function validateParameters(text, entityBlockLength)
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

  return errors
end

function makeBlueprintEntities(utterance, voiceData, instrumentId, isGlobalPlayback, arrangementWidth)
  local entities = {}

  local playbackTimeInTicks = utterance:getPlaybackTimeInTicks()
  local timerEntities = getTimerEntities(playbackTimeInTicks)
  for _,e in pairs(timerEntities) do
    table.insert(entities,e)
  end

  local entityNum = 3 -- entities 1 and 2 are the timer entities added above, so the speakers start at 3
  local tickCounter = 0
  local totalPhonemes = utterance:getNumberOfPhonemes()
  
  local entityPositions = arrangeEntities(totalPhonemes, {x=1,y=1}, arrangementWidth)
  
  local counter = 1
  for _,phoneme in pairs(utterance.phonemes) do
    -- get index of factorio instrument (these are indexed from 0, so we subtract 1 from lua index)
    -- each phoneme is represented by an individual instrument. Instrument term used for factorio specific things.
    noteIndex = indexOfValue(voiceData.phonemesNames,phoneme.name) - 1
    
    pos = entityPositions[counter]
    pos["y"] = pos["y"] + 3 -- offset y by 3 to leave room for timer entities
    entity = makeSpeakerEntity(entityNum, pos["x"], pos["y"], tickCounter, instrumentId, noteIndex, isGlobalPlayback) 

    table.insert(entities,entity)

    tickCounter = tickCounter+phoneme.durationInTicks

    entityNum = entityNum+1
    counter = counter + 1
  end
  return entities
end

function textToSpeech.convertTextToSpeakerEntities(text, voiceData, instrumentId, isGlobalPlayback, arrangementWidth)

  local errorOut = {}
  local parameterErrors = validateParameters(text, arrangementWidth)
  
  local utterance, unknownWords = makeUtterance(text, voiceData)
  
  table.insert(errorOut, unknownWords)
  table.insert(errorOut, parameterErrors)

  if (#unknownWords > 0) or (#parameterErrors > 0) then
    error(errorOut)
  else
    entities = makeBlueprintEntities(utterance, voiceData, instrumentId, isGlobalPlayback, arrangementWidth)
  end
  return errorOut, entities
end

return textToSpeech