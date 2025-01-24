local serialization = require("serialization")
local component = require("component")

local componentDiscoverLib = require("lib.component-discover-lib")

---@class Ingredient
---@field name string
---@field count number

---@class Recipe
---@field name string
---@field aspects Ingredient[]
---@field ingredients Ingredient[]
---@field result Ingredient

---@class PatternAspect
---@field name string
---@field count number
---@field slot number

---@class Pattern
---@field name string
---@field result Ingredient
---@field slot number
---@field aspects PatternAspect[]
---@field ingredients Ingredient[]

---@class RecipeManagerConfig
---@field recipeMeInterfaceAddress string
---@field recipesFilePath string|nil

local recipeManager = {}

---Crate new RecipeManager object from config
---@param config RecipeManagerConfig
---@return RecipeManager
function recipeManager:newFormConfig(config)
  return self:new(config.recipeMeInterfaceAddress, config.recipesFilePath)
end

---Crate new RecipeManager object
---@param recipeMeInterfaceAddress string
---@param recipesFilePath string|nil
---@return RecipeManager
function recipeManager:new(recipeMeInterfaceAddress, recipesFilePath)

  ---@class RecipeManager
  local obj = {}

  obj.recipeMeInterfaceProxy = componentDiscoverLib.discoverProxy(recipeMeInterfaceAddress, "Recipe Me Interface", "me_interface")

  obj.recipesFilePath = recipesFilePath or "recipes.txt"

  obj.recipes = {}

  ---Load recipes from file
  function obj:load()
    local file = io.open(self.recipesFilePath, "r")

    if file == nil then
      return
    end

    self.recipes = serialization.unserialize(file:read("*a"))
    file:close()
  end

  ---Save recipes in file
  function obj:save()
    local file = assert(io.open(self.recipesFilePath, "w"))
		file:write(serialization.serialize(self.recipes))
		file:close()
  end

  ---Find recipe by ingredients
  ---@param ingredients Ingredient[]
  ---@return Recipe|nil
  function obj:findRecipeByIngredients(ingredients)
    for _, value in pairs(self.recipes) do
      if self:compareIngredients(ingredients, value.ingredients) then
        return value
      end
    end
		return nil
  end

  ---Add and save new recipe
  ---@param recipe Recipe
  function obj:addRecipe(recipe)
		table.insert(self.recipes, recipe)
    self:save()
	end

  ---Scan unknown patterns
  ---@return Pattern[]|nil
  ---@return string|nil
  function obj:scanPatterns()
    local databaseComponent = component.database
    local patterns = {}
    local slot = 1

    while self.recipeMeInterfaceProxy.getInterfacePattern(slot) ~= nil do
      local pattern = self.recipeMeInterfaceProxy.getInterfacePattern(slot)

      local parsedPattern = {
        name = pattern.outputs[1].name,
        result = pattern.outputs[1],
        slot = slot,
        ingredients = {},
        aspects = {}
      }

      for i, patternInput in pairs(pattern.inputs) do
        if patternInput.count ~= nil then
          if string.match(patternInput.name, "Aspect") then
            if patternInput.count > 127 then
              return nil, pattern.outputs[1].name
            end

            self.recipeMeInterfaceProxy.storeInterfacePatternInput(slot, i, databaseComponent.address, 1)

            table.insert(parsedPattern.aspects, {
              name = databaseComponent.get(1)["aspects"][1].name,
              count = patternInput.count,
              slot = i
            })
          else
            local isFound = false

            for j, knownIngredients in pairs(parsedPattern.ingredients) do
              if knownIngredients.name == patternInput.name then
                isFound = true
                parsedPattern.ingredients[j].count = parsedPattern.ingredients[j].count + patternInput.count
              end
            end

            if isFound == false then
              table.insert(parsedPattern.ingredients, patternInput)
            end
          end
        end
      end

      if self:findRecipeByIngredients(parsedPattern.ingredients) == nil then
        table.insert(patterns, parsedPattern)
      end

      slot = slot + 1
    end

    return patterns
  end

  ---Remove aspects from pattern
  ---@param pattern Pattern
  function obj:removeAspectsFromPattern(pattern)
    for i = #pattern.aspects, 1, -1 do
      self.recipeMeInterfaceProxy.clearInterfacePatternInput(pattern.slot, pattern.aspects[i].slot)
    end
  end

---Compare two ingredients lists
  ---@param first Ingredient[]
  ---@param second Ingredient[]
  ---@return boolean
  ---@private
  function obj:compareIngredients(first, second)
    if #first ~= #second then
      return false
    end

    for _, firstItem in ipairs(first) do
      local found = false
      for _, secondItem in ipairs(second) do
        if firstItem.name == secondItem.name and firstItem.count == secondItem.count then
          found = true
          break
        end
      end
      if not found then
        return false
      end
    end

    return true
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return recipeManager