local textToSpeech = require "textToSpeech"
local serpent = require "serpent"

if not textToSpeechGui then textToSpeechGui = {} end

-- const values for different speech modes
BLUEPRINT_MODE = 1
PREVIEW_MODE = 2
CHAT_MODE = 3

-----------------------------------------------------------------------------
-- Gets a list of the names of tts compatible voices.
--
-- @return        A table containing the localized names of compatible voices
-----------------------------------------------------------------------------
local function getCompatibleVoiceList()

  local voices = {}

  -- go through all instruments, if the name starts with "voice" then it's compatible,
  -- return the *localised* names in a list
  for k,v in pairs(game.entity_prototypes["programmable-speaker"].instruments) do
    if string.sub(v["name"],1,string.len("voice")) == "voice" then 
      table.insert( voices, {"programmable-speaker-instrument." .. v["name"]})
    end
  end

  return voices
end

-- TODO: refactor gui and logic apart

-----------------------------------------------------------------------------
-- Creates the main gui (expanded gui) for a player.
--
-- @param player        The player who you wish to draw the gui for.
-----------------------------------------------------------------------------
local function createMainGui(player)

  local root
  
  if player.gui["top"].textToSpeechGuiRoot then
    root = player.gui["top"].textToSpeechGuiRoot
    else
      root = player.gui["top"].add{
        type="frame",
        name="textToSpeechGuiRoot",
        direction="vertical",
        style="outer_frame"
      }
  end


  root.add{
    type="sprite-button",
    name="toggleGuiButton",
    sprite="text-to-speech-logo-sprite",
    style="icon_button"
  }

  local mainFrame = root.add{
    type="frame",
    name="mainFrame",
    direction="vertical"
  }

  mainFrame.add{
    type="label",
    name="titleLabel",
    caption="Text To Speech",
    style="frame_caption_label"
  }

  local actionButtons = mainFrame.add{
    type="flow",
    name="actionButtons",
    direction="horizontal"
  }
  
  actionButtons.add{
    type="textfield",
    name="inputField",
    text="",
    tooltip="Type input sentence here. You can create a custom word by writing a sequence of phonemes ".. 
    "(39 phonemes defined by CMU Pronouncing Dictionary, based on ARPAbet) each separated by a whitespace ".. 
    "and encapsulated with square brackets, e.g.\n\"[F AE K T AO R IY OW] is pretty neat\" \n would pronounce the ".. 
    "sentence:\n\"Factorio is pretty neat.\"" 
  }

  actionButtons.add{
    type="sprite-button",
    name="submitButton",
    sprite="text-to-speech-submit-sprite",
    tooltip="Click here with an empty blueprint to convert text to a speaker blueprint",
    style="slot_button"
  }

  actionButtons.add{
    type="sprite-button",
    name="previewButton",
    sprite="text-to-speech-preview-sprite",
    tooltip="Preview (only audible to you)",
    style="slot_button"
  }

  actionButtons.add{
    type="sprite-button",
    name="chatButton",
    sprite="text-to-speech-global-sprite",
    tooltip="Play message in chat (audible to all players)",
    style="slot_button"
  }
  
  local settingsContainer = mainFrame.add{
    type="table",
    name="settingsContainer",
    column_count=2
  }

  settingsContainer.add{
    type="label",
    name="voiceLabel",
    caption="Voice"
  }

  settingsContainer.add{
    type="drop-down",
    name="voiceDropdown",
    items= getCompatibleVoiceList(),
    selected_index = 1
  }

    settingsContainer.add{
    type="label",
    name="globalPlaybackLabel",
    caption="Global Playback"
  }

  settingsContainer.add{
    type="checkbox",
    name="globalPlaybackCheckbox",
    state=true
  }

  settingsContainer.add{
    type="label",
    name="blockWidthLabel",
    caption="Blueprint Width"
  }

  settingsContainer.add{
    type="textfield",
    name="blockWidthField",
    text="16",
    style="number_textfield"
  }

  settingsContainer.add{
    type="label",
    name="timeBetweenWordsLabel",
    caption="Pause Length (ticks)"
  }

  settingsContainer.add{
    type="textfield",
    name="timeBetweenWordsField",
    text="15",
    style="number_textfield"
  }

end

-----------------------------------------------------------------------------
-- Creates the hidden gui (collapsed gui, only tts icon) for a player.
--
-- @param player        The player who you wish to draw the gui for.
-----------------------------------------------------------------------------
local function createHiddenGui(player)
  local root

  if player.gui["top"].textToSpeechGuiRoot then
    root = player.gui["top"].textToSpeechGuiRoot
    else
      root = player.gui["top"].add{
        type="frame",
        name="textToSpeechGuiRoot",
        direction="vertical",
        style="outer_frame"
      }
  end

  root.add{
    type="sprite-button",
    name="toggleGuiButton",
    sprite="text-to-speech-logo-sprite",
    style="icon_button"
  }
end

-----------------------------------------------------------------------------
-- Toggles drawing either the hidden gui or the main gui.
--
-- @param player        The player who you wish to draw the gui for.
-----------------------------------------------------------------------------
local function toggleGui(player)
  
  -- if root has exactly one child (the hide button), create main gui
  if (#player.gui["top"].textToSpeechGuiRoot.children == 1) then
    --show gui
      player.gui["top"].textToSpeechGuiRoot.clear()
      createMainGui(player)
    else
      -- hide gui
      player.gui["top"].textToSpeechGuiRoot.clear()
      createHiddenGui(player)
  end
end

-----------------------------------------------------------------------------
-- Show an error gui (appends a frame to the bottom of the main gui) which
-- describes any errors that have occured for the player.
--
-- @param title       The title to use for the frame
-- @param message     The error message to show
-- @param player      The player who you wish to draw the gui for.
-----------------------------------------------------------------------------
local function showErrorGui(title, message, player)
  
  local root = player.gui["top"].textToSpeechGuiRoot

  if not root.mainFrame.errorFrame then
    root.mainFrame.add{
      type="frame",
      name="errorFrame",
      direction="vertical"
    }
  end

  local errNum = #root.mainFrame.errorFrame.children/2

  root.mainFrame.errorFrame.add{
    type="label",
    name="errorLabel" .. errNum,
    caption=title,
    style="bold_red_label"
  }

  root.mainFrame.errorFrame.add{
    type="text-box",
    name="errorTextbox" .. errNum,
    text=message,
    style="notice_textbox"
  }
  -- doesn't work inside instantiation?
  -- get last child from error frame
  root.mainFrame.errorFrame.children[#root.mainFrame.errorFrame.children].read_only = true
  root.mainFrame.errorFrame.children[#root.mainFrame.errorFrame.children].selectable = false
end

-----------------------------------------------------------------------------
-- Show a success gui (appends a frame to the bottom of the main gui) which
-- affirms to the player that the tts conversion was successful.
--
-- @param title       The title to use for the frame
-- @param message     The success message to show
-- @param player      The player who you wish to draw the gui for.
-----------------------------------------------------------------------------
local function show_success_gui(title, message, player)
  
  local root = player.gui["top"].textToSpeechGuiRoot

  if not root.mainFrame.successFrame then
    root.mainFrame.add{
      type="frame",
      name="successFrame",
      direction="vertical"
    }
  end

  root.mainFrame.successFrame.add{
    type="label",
    name="successLabel",
    caption=title,
    style="bold_green_label"
  }

  root.mainFrame.successFrame.add{
    type="text-box",
    name="successTextbox",
    text=message,
    style="notice_textbox"
  }
  -- doesn't work inside instantiation?
  -- get last child from success frame, and do the thing
  root.mainFrame.successFrame.children[#root.mainFrame.successFrame.children].read_only = true
  root.mainFrame.successFrame.children[#root.mainFrame.successFrame.children].selectable = false
end

local function showWarningGui(title, message, player)

  local root = player.gui["top"].textToSpeechGuiRoot

    if not root.mainFrame.warningFrame then
      root.mainFrame.add{
        type="frame",
        name="warningFrame",
        direction="vertical"
      }
    end

    root.mainFrame.warningFrame.add{
      type="label",
      name="warningLabel",
      caption=title,
      style="menu_message"
    }

    root.mainFrame.warningFrame.add{
      type="text-box",
      name="warningTextbox",
      text=message,
      style="notice_textbox"
    }
    -- doesn't work inside instantiation?
    -- get last child from success frame, and do the thing
    root.mainFrame.warningFrame.children[#root.mainFrame.warningFrame.children].read_only = true
    root.mainFrame.warningFrame.children[#root.mainFrame.warningFrame.children].selectable = false

end

-----------------------------------------------------------------------------
-- Get the instrument ID of a voice/instrument based on dropdown selection index.
--
-- @param selectedIndex       The index of the dropdown selection
--
-- @return                    The corresponding instrument ID
-----------------------------------------------------------------------------
local function getDropDownVoiceInstrumentId(selectedIndex)

  -- same as getCompatibleVoiceList()
  -- but counts each compatible voice until it reaches the selected one.

  local counter = 1
  -- go through all instruments, if the name starts with "voice" (e.g. "voice1") then it's compatible,
  -- return the *localised* names as a table
  for k,v in pairs(game.entity_prototypes["programmable-speaker"].instruments) do
    if string.sub(v["name"],1,string.len("voice")) == "voice" then 
      if counter == selectedIndex then
        return k - 1
      end
      counter = counter + 1
    end
  end

end

-----------------------------------------------------------------------------
-- Formats a list of strings into one readable string and display it in an
-- error gui (showErrorGui).
--
-- @param title                     The title to use for the frame
-- @param unrecognisedThings        A table containing strings of unrecognised 
--                                  things, e.g. words, phonemes
-- @param player                    The player who you wish to draw the gui for.
--                                  table of entities.
-----------------------------------------------------------------------------
local function showUnrecognisedThingsError(title, unrecognisedThings, player)
  
  -- put unrecognised things table into a more readable string
  local outputStr = ""
  local counter = 0
  for _,word in ipairs(unrecognisedThings) do
    outputStr = outputStr .. word .. ", "
    counter = counter + 1
    if counter > 40 then
      outputStr = outputStr .. "\n"
      counter = 0
    end
  end

  -- remove last ", " in string
  outputStr = outputStr:sub(1, -3)

  showErrorGui(title, outputStr, player)

end


-----------------------------------------------------------------------------
-- Set a sentence to be played (see onTick), takes entities from the text to
-- speech conversion and sets up the variables/tables for the onTick method to use.
--
-- @param entities                     The entities you wish to play
-----------------------------------------------------------------------------
local function setupDataForIngameSpeechOutput(entities, isSpeechGlobal, player, voiceName)
  
  -- TODO: rename method, ugly name
  global = {}

  global.playSpeechGlobal = isSpeechGlobal
  global.isSpeaking = true
  global.speechOwner = player
  global.voiceName = voiceName

  global.times = {}
  global.noteIds = {}
  global.speechCounter = 3
  global.numSounds = #entities

  -- start at 3, we ignore the timer entities which are 1 and 2
  -- go through each speaker entity and get relevant info
  for i = 3,global.numSounds do
    
    global.times[i] = entities[i]["control_behavior"]["circuit_condition"]["constant"]
    
    -- add one to note id because it is indexed from 0
    global.noteIds[i] = entities[i]["control_behavior"]["circuit_parameters"]["note_id"] + 1

  end

  global.startTime = game.tick

end


local function evaluate_errors(err, player)
  
    local unrecognisedPhonemes = err[1]
    local unrecognisedWords = err[2]
    local parameterErrors = err[3]
  
    -- if has unrecognised phonemes show error
    if #unrecognisedPhonemes>0 then
      showUnrecognisedThingsError("Error - Unrecognised Phonemes",unrecognisedPhonemes, player)
    end
    -- if has unrecognised words show error
    if #unrecognisedWords>0 then
      showUnrecognisedThingsError("Error - Unrecognised Words",unrecognisedWords, player)
    end
  
    -- if has any parameter errors show them
    if #parameterErrors>0 then
  
      for _,info in pairs(parameterErrors) do
        local title = info[1]
        local message = info[2]
        showErrorGui(title, message, player)
      end
  
    end
  end

-----------------------------------------------------------------------------
-- Takes input from the in-game gui and uses
-- those parameters to do the text-to-speech conversion. Then either plays sound
-- in local preview mode, global chat mode or generates a speaker blueprint.
--
-- @param player        The player who made the tts request
-- @param mode          Integer specifying what we want to do [1=set entities to cusor blueprint] [2=preview speech] [3=global chat play speech]
-----------------------------------------------------------------------------
local function performSpeechTask(player, mode)

  -- TODO: this method does too much, should be refactored

  local root = player.gui["top"].textToSpeechGuiRoot
  
  local inputText = root.mainFrame.actionButtons.inputField.text
  local globalPlayback = root.mainFrame.settingsContainer.globalPlaybackCheckbox.state
  local blockWidth = tonumber(root.mainFrame.settingsContainer.blockWidthField.text)
  local pauseTime = tonumber(root.mainFrame.settingsContainer.timeBetweenWordsField.text)
  local instrumentID = getDropDownVoiceInstrumentId( root.mainFrame.settingsContainer.voiceDropdown.selected_index )
  
  -- only take text after the period (e.g. programmable-speaker-instrument.voice1 -> voice1 )
  local instrumentName = string.match(root.mainFrame.settingsContainer.voiceDropdown.get_item(root.mainFrame.settingsContainer.voiceDropdown.selected_index)[1], "[^.]+$")

  -- if the old error frame is up, remove it in preparation for new errors
  if root.mainFrame.errorFrame then
    root.mainFrame.errorFrame.destroy()
  end
  -- same for the success frame
  if root.mainFrame.successFrame then
    root.mainFrame.successFrame.destroy()
  end
  -- and the warning frame
  if root.mainFrame.warningFrame then
    root.mainFrame.warningFrame.destroy()
  end

  if instrumentName == "voiceHL1" then
    showWarningGui("Warning - Small Vocabulary Available", "This voice has a small vocabulary, \nit's recommended to browse the available\nwords/phonemes before using. You may\ndo this by manually viewing the\navailable sound names for this voice\non a programmable speaker.\n\nThis voice works best when Pause Length\nis set to 0.",
      player)
  end

  -- attempt to convert text to speech
  local status, err, entities = pcall(textToSpeech.convertText,
      inputText,
      globalPlayback,
      blockWidth,
      pauseTime,
      instrumentID,
      instrumentName
    )

  if mode == BLUEPRINT_MODE then

    if (status) and (player.cursor_stack.valid_for_read) and (player.cursor_stack.name == "blueprint") then
      show_success_gui("Success!", "The sentence has been added to your blueprint.", player)
      player.cursor_stack.set_blueprint_entities(entities)
    else
      -- if the player clicks the submit button with an empty cursor show error
      if not player.cursor_stack.valid_for_read then
        showErrorGui("Error - Cannot Detect Blueprint", "You clicked with an empty cursor\n"..
          "Click the button with an empty blueprint on the cursor instead.", player)
        
        -- if the player clicks with something that isn't a blueprint show error
        -- done in nested if because attempt to read cursor_stack of empty cursor fails and does not return nil,
        elseif not (player.cursor_stack.name == "blueprint") then
          showErrorGui("Error - Cannot Detect Blueprint", "You clicked with something that wasn't a blueprint.\n"..
            "Click the button with an empty blueprint on the cursor instead.", player)
      end
    end

  elseif mode == PREVIEW_MODE then
      
    if status then
      setupDataForIngameSpeechOutput(entities, false, player, instrumentName)
    end

  elseif mode == CHAT_MODE then
    
    if status then
      setupDataForIngameSpeechOutput(entities, true, player, instrumentName)
      game.print("[TTS] "..player.name..": "..inputText)
    end

  end

  evaluate_errors(err, player)

end

-----------------------------------------------------------------------------
-- Initializes the mod: initializes the textToSpeech module and draws the
-- gui for all players.
-----------------------------------------------------------------------------
function textToSpeechGui.mod_init()
  
  -- load word definitions and sound timings
  textToSpeech.init()

  for _, player in pairs(game.players) do
    createHiddenGui(player)
  end

end

-----------------------------------------------------------------------------
-- On load the mod is initialized: initializes the textToSpeech module
-----------------------------------------------------------------------------
function textToSpeechGui.mod_on_load()
  textToSpeech.init()

end

-----------------------------------------------------------------------------
-- On new player joining, draw the gui for them.
-----------------------------------------------------------------------------
function textToSpeechGui.new_player(event)
  
  local player = game.players[event.player_index]
  
  createHiddenGui(player)
    
end

-----------------------------------------------------------------------------
-- Should the mod be updated this function will be called to redraw the gui,
-- and reload stuff. (much here is unnecessary, but better safe than sorry?)
-----------------------------------------------------------------------------
function textToSpeechGui.mod_update(data)
  if data.mod_changes then
        if data.mod_changes["Text-To-Speech"] then
          --reload and redraw
          for _, player in pairs(game.players) do
            player.gui["top"].textToSpeechGuiRoot.destroy()
          end
          textToSpeechGui.mod_init()
        end
  end
end

-----------------------------------------------------------------------------
-- When a gui clickable is clicked by a player, take the corresponding action.
-----------------------------------------------------------------------------
function textToSpeechGui.on_gui_click(event)
  
  local player = game.players[event.player_index] 

  if event.element.name == "submitButton" then
    
    performSpeechTask(player, BLUEPRINT_MODE)

    elseif event.element.name == "previewButton" then
      
      performSpeechTask(player, PREVIEW_MODE)

      elseif event.element.name == "chatButton" then

        performSpeechTask(player, CHAT_MODE)

        elseif event.element.name == "toggleGuiButton" then
          toggleGui(game.players[event.player_index])
  end
  
end

-----------------------------------------------------------------------------
-- If a sentence is set to be played in-game (from setupDataForIngameSpeechOutput method), play it here.
-----------------------------------------------------------------------------
function textToSpeechGui.on_tick(event)
  
  if global.isSpeaking then

    -- elapsed ticks since method play_entities was called, used for sound timing
    local elapsedTicks = game.tick-global.startTime

    if elapsedTicks >= global.times[global.speechCounter] then

      -- speech lookup table, holds phoneme/sound names
      local speechLUT = {}

      if global.voiceName == "voiceHL1" then
        speechLUT = textToSpeech.hl1WordsTable
      else
        speechLUT = textToSpeech.phonemesList
      end
      -- create the soundPath for this speech sound, note it uses the entity mined sounds from the dummy entities created in control.lua
      local speechPath = "entity-mined/"
      speechPath = speechPath .. global.voiceName .. "-"
      speechPath = speechPath .. string.lower(speechLUT[global.noteIds[global.speechCounter]])

      if global.playSpeechGlobal then
        game.play_sound{path = speechPath}
      else
        global.speechOwner.play_sound{path = speechPath}
      end

      -- if we're done with the sentence
      if global.speechCounter == global.numSounds then
        global.isSpeaking = false
      end

      global.speechCounter = global.speechCounter + 1
    end
  end
end