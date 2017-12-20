-- Add dummy entities so we can use their sounds to play mod speech sounds using factorio api play_sound()
-- Must use dummy entities because we're limited to playing entity/tile sounds, utility sounds (not extensible), and ambient sounds (counts as music, people often mute ingame music, would have to reenable it etc... )
function add_dummy_entity (name, soundFileName)
  data:extend{
    {
			type = "simple-entity",
			name = name,
			flags = {"not-on-map"},
			mined_sound = {
        filename = soundFileName
      },
      pictures = {
        {
          filename = "__Text-To-Speech__/graphics/ttsIcon.png",
          height = 1,
          width = 1
		    }
      }
    }
  }

end

data:extend{
    {
      type="sprite",
      name="text-to-speech-logo-sprite",
      filename = "__Text-To-Speech__/graphics/ttsIcon.png",
      priority = "extra-high-no-scale",
      width = 32,
      height = 32,
    },
    {
      type="sprite",
      name="text-to-speech-submit-sprite",
      filename = "__Text-To-Speech__/graphics/submitIcon.png",
      priority = "extra-high-no-scale",
      width = 32,
      height = 32,
    }
}

add_dummy_entity("voice1-aa","__Text-To-Speech__/sound/voice1/aa.ogg")
add_dummy_entity("voice1-ae","__Text-To-Speech__/sound/voice1/ae.ogg")
add_dummy_entity("voice1-ah","__Text-To-Speech__/sound/voice1/ah.ogg")
add_dummy_entity("voice1-ao","__Text-To-Speech__/sound/voice1/ao.ogg")
add_dummy_entity("voice1-aw","__Text-To-Speech__/sound/voice1/aw.ogg")
add_dummy_entity("voice1-ay","__Text-To-Speech__/sound/voice1/ay.ogg")
add_dummy_entity("voice1-b","__Text-To-Speech__/sound/voice1/b.ogg")
add_dummy_entity("voice1-ch","__Text-To-Speech__/sound/voice1/ch.ogg")
add_dummy_entity("voice1-d","__Text-To-Speech__/sound/voice1/d.ogg")
add_dummy_entity("voice1-dh","__Text-To-Speech__/sound/voice1/dh.ogg")
add_dummy_entity("voice1-eh","__Text-To-Speech__/sound/voice1/eh.ogg")
add_dummy_entity("voice1-er","__Text-To-Speech__/sound/voice1/er.ogg")
add_dummy_entity("voice1-ey","__Text-To-Speech__/sound/voice1/ey.ogg")
add_dummy_entity("voice1-f","__Text-To-Speech__/sound/voice1/f.ogg")
add_dummy_entity("voice1-g","__Text-To-Speech__/sound/voice1/g.ogg")
add_dummy_entity("voice1-hh","__Text-To-Speech__/sound/voice1/hh.ogg")
add_dummy_entity("voice1-ih","__Text-To-Speech__/sound/voice1/ih.ogg")
add_dummy_entity("voice1-iy","__Text-To-Speech__/sound/voice1/iy.ogg")
add_dummy_entity("voice1-jh","__Text-To-Speech__/sound/voice1/jh.ogg")
add_dummy_entity("voice1-k","__Text-To-Speech__/sound/voice1/k.ogg")
add_dummy_entity("voice1-l","__Text-To-Speech__/sound/voice1/l.ogg")
add_dummy_entity("voice1-m","__Text-To-Speech__/sound/voice1/m.ogg")
add_dummy_entity("voice1-n","__Text-To-Speech__/sound/voice1/n.ogg")
add_dummy_entity("voice1-ng","__Text-To-Speech__/sound/voice1/ng.ogg")
add_dummy_entity("voice1-ow","__Text-To-Speech__/sound/voice1/ow.ogg")
add_dummy_entity("voice1-oy","__Text-To-Speech__/sound/voice1/oy.ogg")
add_dummy_entity("voice1-p","__Text-To-Speech__/sound/voice1/p.ogg")
add_dummy_entity("voice1-r","__Text-To-Speech__/sound/voice1/r.ogg")
add_dummy_entity("voice1-s","__Text-To-Speech__/sound/voice1/s.ogg")
add_dummy_entity("voice1-sh","__Text-To-Speech__/sound/voice1/sh.ogg")
add_dummy_entity("voice1-t","__Text-To-Speech__/sound/voice1/t.ogg")
add_dummy_entity("voice1-th","__Text-To-Speech__/sound/voice1/th.ogg")
add_dummy_entity("voice1-uh","__Text-To-Speech__/sound/voice1/uh.ogg")
add_dummy_entity("voice1-uw","__Text-To-Speech__/sound/voice1/uw.ogg")
add_dummy_entity("voice1-v","__Text-To-Speech__/sound/voice1/v.ogg")
add_dummy_entity("voice1-w","__Text-To-Speech__/sound/voice1/w.ogg")
add_dummy_entity("voice1-y","__Text-To-Speech__/sound/voice1/y.ogg")
add_dummy_entity("voice1-z","__Text-To-Speech__/sound/voice1/z.ogg")
add_dummy_entity("voice1-zh","__Text-To-Speech__/sound/voice1/zh.ogg")