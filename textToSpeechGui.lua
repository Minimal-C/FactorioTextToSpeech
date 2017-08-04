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
    -- for _, p in pairs(game.players) do
    --   p.print(serpent.block(p.cursor_stack.get_blueprint_entities()))
    -- end
    elseif event.element.name == "toggle_gui_button" then
      textToSpeechGui.toggle_gui(game.players[event.player_index])
  end
end

function textToSpeechGui.generate_blueprint(player)
  -- for _, p in pairs(game.players) do

    local root = player.gui.top.text_to_speech_gui_root

    -- p.print(root.action_buttons.input_field.text)
    unrecognisedWords,entities = textToSpeech.convertText(root.main_frame.action_buttons.input_field.text, 
                                                          tonumber(root.main_frame.settings_container.block_width_field.text),
                                                          tonumber(root.main_frame.settings_container.time_between_words_field.text),
                                                          textToSpeechGui.getCompatibleVoiceInstrumentId(root.main_frame.settings_container.voice_dropdown.caption) )

    -- if the old error frame is up, remove it in preparation for new sentence
    if root.main_frame.error_frame then
      root.main_frame.error_frame.destroy()
    end
    
    if #unrecognisedWords == 0 then
      player.cursor_stack.set_blueprint_entities(entities)
      else
        textToSpeechGui.show_unrecognised_words(unrecognisedWords, player)
    end
    
end

function textToSpeechGui.toggle_gui(player)
  
  if guiHidden then
    --show gui
      guiHidden = false
      -- for _, p in pairs(game.players) do
        player.gui.top.text_to_speech_gui_root.destroy()
        textToSpeechGui.create_gui(player)
      -- end
    else
      -- hide gui
      guiHidden = true

      -- for _, p in pairs(game.players) do
        player.gui.top.text_to_speech_gui_root.destroy()
        textToSpeechGui.create_gui(player)
      -- end      
  end
end

function textToSpeechGui.show_unrecognised_words(unrecognisedWords, player)
  
  -- put unrecognised words table into a more readable string
  outputStr = ""
  for _,word in ipairs(unrecognisedWords) do
    outputStr = outputStr .. word .. ", "
    if outputStr:len() > 40 then
      outputStr = outputStr .. "\n"
    end
  end

  -- remove last ", " in string
  outputStr = outputStr:sub(1, -3)

  player.gui.top.text_to_speech_gui_root.main_frame.add{type="frame",
                                        name="error_frame",
                                        direction="vertical"}

  player.gui.top.text_to_speech_gui_root.main_frame.error_frame.add{type="label",
                                                            name="unrecognised_words_label",
                                                            caption="Error - Unrecognised Words",
                                                            style="bold_red_label_style"}
  player.gui.top.text_to_speech_gui_root.main_frame.error_frame.add{type="text-box",
                                                            name="unrecognised_words_textbox",
                                                            text=outputStr,
                                                            style="notice_textbox_style"}

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
  local root = player.gui.top.add{type="frame",
                                    name="text_to_speech_gui_root",
                                    direction="horizontal",
                                    style="outer_frame_style"}

  root.add{type="sprite-button",
                      name="toggle_gui_button",
                      sprite="text-to-speech-logo-sprite",
                      style="icon_button_style"}

end

function textToSpeechGui.create_main_gui(player)

  local root = player.gui.top.add{type="frame",
                                      name="text_to_speech_gui_root",
                                      direction="vertical",
                                      style="outer_frame_style"}


  root.add{type="sprite-button",
                      name="toggle_gui_button",
                      sprite="text-to-speech-logo-sprite",
                      style="icon_button_style"}

  local main_frame = root.add{type="frame",
                              name="main_frame",
                              direction="vertical"}
  main_frame.add{type="label",
                 name="title_label",
                 caption="Text To Speech",
                 style="frame_caption_label_style"}

  local action_buttons = main_frame.add{type="flow",
                                  name="action_buttons",
                                  direction="horizontal",
                                  style="description_flow_style"}
  
  action_buttons.add{type="textfield",
                      name="input_field",
                      text="this is some text"}

  action_buttons.add{type="sprite-button",
                      name="submit_button",
                      sprite="text-to-speech-submit-sprite",
                      tooltip="Click here with an empty blueprint",
                      style="slot_button_style"}
  
  local settings_container = main_frame.add{type="table",
                                    name="settings_container",
                                    colspan=2}

  settings_container.add{type="label",
                         name="voice_label",
                         caption="Voice"}

  settings_container.add{type="drop-down",
                         name="voice_dropdown",
                         items= textToSpeechGui.getCompatibleVoiceList(),
                         selected_index = 1}

  settings_container.add{type="label",
                     name="block_width_label",
                     caption="Blueprint Width"}

  settings_container.add{type="textfield",
                     name="block_width_field",
                     text="16",
                     style="number_textfield_style"}

  settings_container.add{type="label",
                     name="time_between_words_label",
                     caption="Pause Length (ticks)"}

  settings_container.add{type="textfield",
                     name="time_between_words_field",
                     text="15",
                     style="number_textfield_style"}

end

function textToSpeechGui.getCompatibleVoiceList()

-- populate list of compatible voices for dropdown menu
  local voices = {}

  for k,v in pairs(game.entity_prototypes["programmable-speaker"].instruments) do
    if string.sub(v["name"],1,string.len("voice")) == "voice" then 
      table.insert( voices, {"programmable-speaker-instrument." .. v["name"]})
    end
  end

  return voices
end

function textToSpeechGui.getCompatibleVoiceInstrumentId(name)
  for k,v in pairs(game.entity_prototypes["programmable-speaker"].instruments) do
    if {"programmable-speaker-instrument." .. v["name"]} == name then 
      return k
    end
  end
  -- if it can't find the voice, which shouldn't happen, default to 12 (first custom instrument index)
  return 12
end