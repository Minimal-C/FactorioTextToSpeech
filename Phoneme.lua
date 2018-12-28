Phoneme = {name="", durationInTicks=0}
Phoneme.__index = Phoneme

function Phoneme:new(o, name, durationInTicks)
  local o = {}
  setmetatable(o, Phoneme)
  o.name = name
  o.durationInTicks = durationInTicks
  return o
end