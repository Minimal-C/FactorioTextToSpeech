Utterance = {phonemes={}}
Utterance.__index = Utterance

function Utterance:new(o, phonemes)
  local o = {}
  setmetatable(o, Utterance)
  o.phonemes = phonemes
  return o
end

function Utterance:getPlaybackTimeInTicks()
  ticks = 0
  for _,phoneme in pairs(self.phonemes) do
    ticks = ticks+phoneme.durationInTicks
  end
  return ticks
end

function Utterance:getNumberOfPhonemes()
  return #self.phonemes
end

