HL1Word = {name="", durationInTicks=0}
HL1Word.__index = HL1Word

function HL1Word:new(o, name, durationInTicks)
  local o = {}
  setmetatable(o, HL1Word)
  o.name = name
  o.durationInTicks = durationInTicks
  return o
end