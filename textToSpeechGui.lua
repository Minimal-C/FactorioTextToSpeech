local textToSpeech = require "textToSpeech"
local serpent = require "serpent"

if not textToSpeechGui then textToSpeechGui = {} end

local guiHidden = false

function textToSpeechGui.mod_init()
  
  textToSpeech.init()

  for _, player in pairs(game.players) do
    textToSpeechGui.create_gui(player)
  end

end

function textToSpeechGui.mod_on_load()
    textToSpeech.init()
end

function textToSpeechGui.new_player(event)
  
  local player = game.players[event.player_index]
  
  textToSpeechGui.create_gui(player)
    
end

function textToSpeechGui.on_gui_click(event)

  if event.element.name == "submit_button" then
    textToSpeechGui.generate_blueprint(game.players[event.player_index])
    elseif event.element.name == "toggle_gui_button" then
      textToSpeechGui.toggle_gui(game.players[event.player_index])
  end
  
end

function textToSpeechGui.generate_blueprint(player)

    local root = player.gui.top.text_to_speech_gui_root

    local inputText = root.main_frame.action_buttons.input_field.text
    local blockWidth = tonumber(root.main_frame.settings_container.block_width_field.text)
    local pauseTime = tonumber(root.main_frame.settings_container.time_between_words_field.text)
    
    -- if the old error frame is up, remove it in preparation for new errors
    if root.main_frame.error_frame then
      root.main_frame.error_frame.destroy()
    end

    -- do validation of various fields, show relevant error messages

    if #inputText==0 then
      textToSpeechGui.show_error_gui("Error - No Input Text", "", player)
      return
    end

    -- if the earlier conversion to number failed, aka it's not a number, then show error message
    if not blockWidth then
      textToSpeechGui.show_error_gui("Error - Invalid Width Value", "Blueprint width must be a number", player)
      return
    end

    -- same as above
    if not pauseTime then
      textToSpeechGui.show_error_gui("Error - Invalid Pause Value", "Pause time must be a number", player)
      return
    end

    if blockWidth < 1 then
      textToSpeechGui.show_error_gui("Error - Width Out Of Range", "Blueprint width must be greater than 0", player)
      return
    end

    if pauseTime < 0 then
      textToSpeechGui.show_error_gui("Error - Pause Out Of Range", "Pause time must be greater than or equal to 0", player)
      return
    end


    unrecognisedPhonemes, unrecognisedWords, entities = textToSpeech.convertText(
      inputText, 
      blockWidth,
      pauseTime,
      textToSpeechGui.getCompatibleVoiceInstrumentId(root.main_frame.settings_container.voice_dropdown.caption) 
    )
    
    -- make the blueprint or show appropriate error
    -- TODO: show more than one error at a time
    if #unrecognisedWords == 0 and #unrecognisedPhonemes == 0 then
      player.cursor_stack.set_blueprint_entities(entities)
    end
    if #unrecognisedWords > 0 then
      textToSpeechGui.show_unrecognised_things_error("Error - Unrecognised Words",unrecognisedWords, player)
    end
    if #unrecognisedPhonemes > 0 then
      textToSpeechGui.show_unrecognised_things_error("Error - Unrecognised Phonemes",unrecognisedPhonemes, player)
    end
    
end

function textToSpeechGui.toggle_gui(player)
  
  if guiHidden then
    --show gui
      guiHidden = false
      player.gui.top.text_to_speech_gui_root.destroy()
      textToSpeechGui.create_gui(player)
    else
      -- hide gui
      guiHidden = true
      player.gui.top.text_to_speech_gui_root.destroy()
      textToSpeechGui.create_gui(player)
  end
end

function textToSpeechGui.show_unrecognised_things_error(title, unrecognisedThings, player)
  
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

  textToSpeechGui.show_error_gui(title, outputStr, player)

end

function textToSpeechGui.show_error_gui(title, message, player)

  player.gui.top.text_to_speech_gui_root.main_frame.add{
    type="frame",
    name="error_frame",
    direction="vertical"
  }

  player.gui.top.text_to_speech_gui_root.main_frame.error_frame.add{
    type="label",
    name="error_label",
    caption=title,
    style="bold_red_label_style"
  }

  player.gui.top.text_to_speech_gui_root.main_frame.error_frame.add{
    type="text-box",
    name="error_textbox",
    text=message,
    style="notice_textbox_style"
  }

  player.gui.top.text_to_speech_gui_root.main_frame.error_frame.unrecognised_words_textbox.read_only=true

end

function textToSpeechGui.create_gui(player)

  if guiHidden then
    textToSpeechGui.create_hidden_gui(player)
    else
      textToSpeechGui.create_main_gui(player)
  end
        
end

function textToSpeechGui.create_hidden_gui(player)
  
  local root = player.gui.top.add{
    type="frame",
    name="text_to_speech_gui_root",
    direction="horizontal",
    style="outer_frame_style"
  }

  root.add{
    type="sprite-button",
    name="toggle_gui_button",
    sprite="text-to-speech-logo-sprite",
    style="icon_button_style"
  }

end

function textToSpeechGui.create_main_gui(player)

  local root = player.gui.top.add{
    type="frame",
    name="text_to_speech_gui_root",
    direction="vertical",
    style="outer_frame_style"
  }


  root.add{
    type="sprite-button",
    name="toggle_gui_button",
    sprite="text-to-speech-logo-sprite",
    style="icon_button_style"
  }

  local main_frame = root.add{
    type="frame",
    name="main_frame",
    direction="vertical"
  }

  main_frame.add{
    type="label",
    name="title_label",
    caption="Text To Speech",
    style="frame_caption_label_style"
  }

  local action_buttons = main_frame.add{
    type="flow",
    name="action_buttons",
    direction="horizontal",
    style="description_flow_style"
  }
  
  action_buttons.add{
    type="textfield",
    name="input_field",
    text="",
    tooltip="Type input sentence here. You can create a custom word by writing a sequence of phonemes ".. 
    "(39 phonemes defined by CMU Pronouncing Dictionary, based on ARPAbet) each separated by a whitespace ".. 
    "and encapsulated with square brackets, e.g.\n\"[F AE K T AO R IY OW] is pretty neat\" \n would pronounce the ".. 
    "sentence:\n\"Factorio is pretty neat.\"" 
  }

  action_buttons.add{
    type="sprite-button",
    name="submit_button",
    sprite="text-to-speech-submit-sprite",
    tooltip="Click here with an empty blueprint to convert text to a speaker blueprint",
    style="slot_button_style"
  }
  
  local settings_container = main_frame.add{
    type="table",
    name="settings_container",
    colspan=2
  }

  settings_container.add{
    type="label",
    name="voice_label",
    caption="Voice"
  }

  settings_container.add{
    type="drop-down",
    name="voice_dropdown",
    items= textToSpeechGui.getCompatibleVoiceList(),
    selected_index = 1
  }

  settings_container.add{
    type="label",
    name="block_width_label",
    caption="Blueprint Width"
  }

  settings_container.add{
    type="textfield",
    name="block_width_field",
    text="16",
    style="number_textfield_style"
  }

  settings_container.add{
    type="label",
    name="time_between_words_label",
    caption="Pause Length (ticks)"
  }

  settings_container.add{
    type="textfield",
    name="time_between_words_field",
    text="15",
    style="number_textfield_style"
  }

end

-- return list of compatible voices for dropdown menu
function textToSpeechGui.getCompatibleVoiceList()

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

-- return ID of voice/instrument with the specified name,
function textToSpeechGui.getCompatibleVoiceInstrumentId(name)
  
  -- if you find an instrument with localised name equal to parameter name, return index
  for k,v in pairs(game.entity_prototypes["programmable-speaker"].instruments) do
    if {"programmable-speaker-instrument." .. v["name"]} == name then 
      return k
    end
  end
  -- if it can't find the voice, which shouldn't happen, default to 12 (first custom instrument index)
  return 12
end