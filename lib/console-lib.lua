-- Console Lib
-- Author: Navatusein
-- License: MIT
-- Version: 1.1

local term = require("term")

---@class Condition
---@field condition fun(userInput: string|number): boolean
---@field callback fun(userInput: string|number)|nil
---@field userInputToNumber boolean
---@field userInputToLower boolean
---@field resultValue any

---@class Reader
---@field conditions table<string, Condition>

local console = {}

---Crate new Console object
---@return Console
function console:new()

  ---@class Console
  local obj = {}

  ---Clear console
  function obj:clear()
    term.clear()
  end

  ---Write to console
  ---@param text string
  function obj:write(text)
    term.write(text)
  end

  ---Write line to console
  ---@param text string
  function obj:writeLine(text)
    term.write(text.."\n")
  end

  ---Get screen Resolution
  ---@return number
  ---@return number
  function obj:getResolution()
    local width, height = term.getViewport()
    return width, height
  end

  ---Create new Reader object
  ---@return Reader
  function obj:createReader()
    return {conditions = {}}
  end

  ---Create new boolean Reader object
  ---@return Reader
  function obj:createBooleanReader()
    return {
      conditions = {
        yes = {
          condition = function(userInput)
            return userInput == "y"
          end,
          userInputToLower = true,
          resultValue = true
        },
        no = {
          condition = function(userInput)
            return userInput == "n"
          end,
          userInputToLower = true,
          resultValue = false
        }
      }
    }
  end

  ---Create new Condition object
  ---@return Condition
  function obj:createCondition()
    return {
      condition = nil,
      callback = nil,
      userInputNumber = false,
      resultValue = nil
    }
  end

  ---Read from console
  ---@param reader Reader|nil
  ---@return any
  ---@return string|nil
  ---@return string|number
  function obj:read(reader)
    local _, startRow = term.getCursor()

    while true do
      self:write("==>")
      local userInput = io.read()

      if reader == nil then
        return userInput, nil, userInput
      end

      for key, value in pairs(reader.conditions) do
        local input = userInput

        if value.userInputToNumber then
          input = tonumber(input)
        end

        if value.userInputToLower then
          input = string.lower(input)
        end

        if input and value.condition(input) then
          if value.callback ~= nil then
            value.callback(input)
          end

          if value.resultValue ~= nil then
            return value.resultValue, key, input
          end

          return input, key, input
        end
      end

      term.setCursor(1, startRow)
      term.clearLine()
    end
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return console