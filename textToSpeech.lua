local voiceData = require "voiceData"
local serpent = require("serpent")
require("Phoneme")
require("Utterance")
require("utils")

function numberPass(text)
  text = string.gsub( text, "%-?%d+", convertNumberToWords)
  return text
end

function getPhonemesFromWord(word, voiceData)
  --ensure word is upper case for correct lookup
  local word = string.upper(word)
  local wordAsPhonemesString = voiceData.cmuTable[word]
  
  -- if the word isn't recognised, exit with failure
  if not wordAsPhonemesString then
    return nil, word
  end

  local wordPhonemes = {}

  for phonemeName in string.gmatch(wordAsPhonemesString,"[^%s]+") do    
    local phonemeDurationInTicks = millisecondsToTicks(voiceData.phonemes[phonemeName])
    table.insert(wordPhonemes,Phoneme:new(nil,phonemeName,phonemeDurationInTicks))
  end

  -- Add pause after word
  local pauseDurationInTicks = millisecondsToTicks(voiceData.phonemes["PAUSE"])
  table.insert(wordPhonemes,Phoneme:new(nil,"PAUSE",pauseDurationInTicks))

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

function makeUtterance(text, voiceData)
  text = numberPass(text)
  phonemes, unknownWords = getPhonemesFromSentence(text, voiceData)
  utterance = Utterance:new(nil,phonemes)
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

function getBlueprintEntities(utterance, voiceData, instrumentId, isGlobalPlayback)
  local entities = {}

  local playbackTimeInTicks = utterance:getPlaybackTimeInTicks()
  local timerEntities = getTimerEntities(playbackTimeInTicks)
  for _,e in pairs(timerEntities) do
    table.insert(entities,e)
  end

  local entityNum = 3 -- entities 1 and 2 are the timer entities added above, so the speakers start at 3
  local tickCounter = 0
  local totalPhonemes = utterance:getNumberOfPhonemes()

  local entityPositions = arrangeEntities(totalPhonemes, {x=1,y=1}, 10)

  local counter = 1

  for _,phoneme in pairs(utterance.phonemes) do
    -- get index of factorio instrument (these are indexed from 0, so we subtract 1 from lua index)
    -- each phoneme is represented by an individual instrument. Instrument term used for factorio specific things.
    noteIndex = indexOfValue(voiceData.phonemesNames,phoneme.name) - 1
    tickCounter = tickCounter+phoneme.durationInTicks
    pos = entityPositions[counter]
    pos["y"] = pos["y"]+3 -- offset speaker y position by 3, to make room for timer entities
    entity = makeSpeakerEntity(entityNum, pos[1], pos[2], tickCounter, instrumentId, noteIndex, isGlobalPlayback) 

    table.insert(entities,entity)

    entityNum = entityNum+1
  end
  return entities
end


u, unknownWords = makeUtterance("Hel123lo Wo1rld aFox Antz 69", voiceData.cmuData)
out = getBlueprintEntities(u,voiceData.cmuData,11,false)
print(serpent.block(u))
print(serpent.block(unknownWords))
