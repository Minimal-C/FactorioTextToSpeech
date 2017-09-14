require "textToSpeechGui"

if not textToSpeechGui then textToSpeechGui = {} end

script.on_init(textToSpeechGui.mod_init)

script.on_configuration_changed(textToSpeechGui.mod_update)

script.on_load(textToSpeechGui.mod_on_load)

script.on_event(defines.events.on_gui_click, function(event)
  pcall(textToSpeechGui.on_gui_click, event)
  end)

script.on_event(defines.events.on_player_created, function(event)
    pcall(textToSpeechGui.new_player, event)
end)

