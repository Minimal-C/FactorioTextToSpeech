require "textToSpeechGui"

if not textToSpeechGui then textToSpeechGui = {} end

script.on_init(textToSpeechGui.mod_init)

script.on_load(textToSpeechGui.mod_on_load)

script.on_event(defines.events.on_gui_click, function(event)
	pcall(textToSpeechGui.on_gui_click, event)
	end)

