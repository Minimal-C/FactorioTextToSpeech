-----------------------------------------------------------------------------
-- Get the entities that make up a Factorio timer (constant combinator + decider cominator)
--
-- @param ticks        The length of the timer before it resets
--
-- @return              Returns a table containing the timer entities
-----------------------------------------------------------------------------
function getTimerEntities(ticks)
  return 
    {
      {
        entity_number=1,
        name="constant-combinator",
        position={x=0.0,y=0.0},
        direction=4,
        control_behavior=
        {
          filters=
          {
            {
              signal=
              {
                type="virtual",
                name="signal-0"
              },
              count=1,
              index=1
            }
          },
          is_on=false
        },
        connections=
          {
            ["1"]=
            {
              red=
              {
                {
                  entity_id=2,
                  circuit_id=1
                }
              }
            }
          }
      },
      {
        entity_number=2,
        name="decider-combinator",
        position={x=0.0,y=1.5},
        direction=4,
        control_behavior=
        {
          decider_conditions=
          {
            first_signal=
            {
              type="virtual",
              name="signal-0"
            },
            constant=ticks,
            comparator="<",
            output_signal=
            {
              type="virtual",
              name="signal-0"
            },
            copy_count_from_input=true
          },
          is_on=false
        },
        connections=
        {
          ["1"]=
          {
            red=
            {
              {
                entity_id=1,
                circuit_id=1
              },
              {
                entity_id=2,
                circuit_id=2
              }
            }
          },
          ["2"]=
          {
            red=
            {
              {
                entity_id=2,
                circuit_id=1
              }
            }
          }
        }
      }
    }
end

function arrangeEntities(numEntities, entitySize, arrangementWidth)

  local positions = {}
 
  local isArranged = false
  
  local leftToRight = 1
  local rightToLeft = 0

  local direction = leftToRight

  local x = 0
  local y = 0
  local counter = 0

  while not isArranged do
    table.insert(positions,{x=x,y=y})
    
    counter = counter+1

    if counter == numEntities then
      isArranged=true
    end
    
    if direction == leftToRight then
      x = x+entitySize["x"]
    else
      x = x-entitySize["x"]
    end
    
    if x >= arrangementWidth then
      x=arrangementWidth-1
      y = y+entitySize["y"]
      direction = rightToLeft
    elseif x < 0 then
      x=0
      y = y+entitySize["y"]
      direction = leftToRight
    end
  end

  return positions
end

function trimWhiteSpace(text)
  return (text:gsub("^%s*(.-)%s*$", "%1"))
end

-----------------------------------------------------------------------------
-- Get an integer back as a string of words. (e.g. input:42 textut:"forty two")
-- Function ported from http://rosettacode.org/wiki/Number_names#Java ,
-- some modifications made to make textut strings more readable
--
-- @param numbe       The integer to be converted.
--
-- @return            A string of words which describe the integer.
-----------------------------------------------------------------------------
function convertNumberToWords(number)

  number = tonumber(number)
  local small = {"one", "two", "three", "four", "five", "six",
        "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen",
        "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"}
  local tens = {"twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty",
        "ninety"}
  local big = {"thousand", "million", "billion", "trillion"}

  local num = 0
  local text = ""
  local unit = 0
  local tmpLng1 = 0

  if (number == 0) then
    return "zero"
  end

  local num = math.abs( number )

  while true do
    tmpLng1 = num % 100
    if (tmpLng1 >= 1 and tmpLng1 <= 19) then
      text = small[math.floor(tmpLng1)] .. " " .. text
    elseif (tmpLng1 >= 20 and tmpLng1 <= 99) then
      if (math.floor(tmpLng1 % 10) == 0) then
        text = tens[math.floor((tmpLng1 / 10) - 1)] .. " " .. text
        else 
          text = tens[math.floor((tmpLng1 / 10) - 1)] .. " "
            .. small[math.floor(tmpLng1 % 10) ] .. " " .. text
      end
    end
    
    tmpLng1 = (num % 1000) / 100
    if (math.floor(tmpLng1) ~= 0) then
      if text=="" then
        text = small[math.floor(tmpLng1)] .. " hundred "
        elseif isPresent(big,text) or isPresent(big,(string.match( text,"[^%s]+")))then
          text = small[math.floor(tmpLng1)] .. " hundred " .. text
        else
          text = small[math.floor(tmpLng1)] .. " hundred and " .. text
      end
    end

    num = num/1000
    if (num == 0) then
      break
    end

    tmpLng1 = num % 1000
    if (math.floor(tmpLng1) ~= 0) then
      if text=="" then
        text = big[unit + 1]
        elseif isPresent(big, text) then
          text = big[unit + 1] .. " " .. text
        else
          text = big[unit + 1] .. " and " .. text
      end
    end
    unit = unit + 1
  end -- end while loop

  if (number < 0) then
    text = "negative " .. text
  end

  text = trimWhiteSpace(text)

  return text

end

function millisecondsToTicks(milliseconds)
  local floatTicks = (milliseconds*60)/1000
  local ticks = math.floor(floatTicks+0.5)
  return ticks
end

-----------------------------------------------------------------------------
-- Finds the index of a value in a table.
--
-- @param table         The table to search for the value in.
-- @param value         The value to search for (string, int, etc.)
--
-- @return              The index of the value, otherwise if value not 
--                      present then return nil
-----------------------------------------------------------------------------
function indexOfValue(table,value)
  for k,v in pairs(table) do
    if v==value then
      return k
    end
  end
  return nil
end

-----------------------------------------------------------------------------
-- Check if value is present in table.
--
-- @param table         The table to search for the value in.
-- @param value         The value to search for (string, int, etc.)
--
-- @return              Boolean if present or not
-----------------------------------------------------------------------------
function isPresent(table, value)

  if indexOfValue(table,value) then
    return true
    else
      return false
  end
end