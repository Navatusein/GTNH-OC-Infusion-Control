local keyboard = require("keyboard")
local event = require("event")

local programLib = require("lib.program-lib")
local guiLib = require("lib.gui-lib")
local stateMachineLib = require("lib.state-machine-lib")
local consoleLib = require("lib.console-lib")

local scrollList = require("lib.gui-widgets.scroll-list")

package.loaded.config = nil
local config = require("config")

local version = require("version")

local repository = "Navatusein/GTNH-OC-Infusion-Control"
local archiveName = "InfusionControl"

local program = programLib:new(config.logger, config.enableAutoUpdate, version, repository, archiveName)
local gui = guiLib:new(program)
local stateMachine = stateMachineLib:new()
local console = consoleLib:new()

local logo = {
  " ___        __           _                ____            _             _ ",
  "|_ _|_ __  / _|_   _ ___(_) ___  _ __    / ___|___  _ __ | |_ _ __ ___ | |",
  " | || '_ \\| |_| | | / __| |/ _ \\| '_ \\  | |   / _ \\| '_ \\| __| '__/ _ \\| |",
  " | || | | |  _| |_| \\__ \\ | (_) | | | | | |__| (_) | | | | |_| | | (_) | |",
  "|___|_| |_|_|  \\__,_|___/_|\\___/|_| |_|  \\____\\___/|_| |_|\\__|_|  \\___/|_|"
}

local mainTemplate = {
  width = 60,
  background = gui.palette.black,
  foreground = gui.palette.white,
  widgets = {
    logsScrollList = scrollList:new("logsScrollList", "logs", keyboard.keys.up, keyboard.keys.down)
  },
  lines = {
    "Status: $state$",
    "Craft: $craft$",
    "",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#"
  }
}

local function init()
  gui:setTemplate(mainTemplate)

  config.recipeManager:load()

  config.infusionManager:reset()

  stateMachine.states.idle = stateMachine:createState("Idle")
  stateMachine.states.idle.update = function()
    local ingredients = config.infusionManager:getIngredients()
    local recipe = config.recipeManager:findRecipeByIngredients(ingredients)

    if recipe ~= nil then
      stateMachine.data.recipe = recipe
      stateMachine.data.recipeName = recipe.name

      event.push("log_info", "Start: "..recipe.name)
      stateMachine:setState(stateMachine.states.checkAspects)
    end
  end

  stateMachine.states.checkAspects = stateMachine:createState("Check Aspects")
  stateMachine.states.checkAspects.init = function()
    local missingAspects = config.essentiaManager:checkAspects(stateMachine.data.recipe)

    if #missingAspects == 0 then
      stateMachine:setState(stateMachine.states.craft)
    else
      for _, aspect in ipairs(missingAspects) do
        event.push("log_warning", "  "..config.essentiaManager:getEssentiaByKey(aspect.name).name..": "..aspect.count)
      end

      event.push("log_warning", "&white;Missing aspects:")

      stateMachine.data.missingAspects = missingAspects
      stateMachine:setState(stateMachine.states.craftAspects)
    end
  end

  stateMachine.states.craftAspects = stateMachine:createState("Craft Aspects")
  stateMachine.states.craftAspects.init = function()
    local missingAspects = stateMachine.data.missingAspects
    local missingAspectsCrafts = {}

    local useCpus = config.maxCpuUse
    local freeCpus = config.essentiaManager:getFreeCpusCount()

    if freeCpus < useCpus then
      useCpus = freeCpus
    end

    local missingRecipes = {}

    for _, missingAspect in pairs(missingAspects) do
      if useCpus == 0 then
        break
      end

      useCpus = useCpus - 1
      local craft = config.essentiaManager:craftAspect(missingAspect)

      if craft == nil then
        table.insert(missingRecipes, config.essentiaManager:getEssentiaByKey(missingAspect.name).name)
      else
        table.insert(missingAspectsCrafts, craft)
      end
    end

    if #missingRecipes ~= 0 then
      stateMachine.data = {}
      stateMachine.data.errorMessage = "No recipe for: "..table.concat(missingRecipes, ", ")
      stateMachine:setState(stateMachine.states.error)
      return
    end

    stateMachine.data.missingAspectsCrafts = missingAspectsCrafts
  end
  stateMachine.states.craftAspects.update = function()
    local missingAspects = stateMachine.data.missingAspects
    local missingAspectsCrafts = stateMachine.data.missingAspectsCrafts

    for key, craft in pairs(missingAspectsCrafts) do
      if craft.isCanceled() then
        stateMachine.data.errorMessage = "Fail craft ".. config.essentiaManager:getEssentiaByKey(missingAspects[key].name).name
        stateMachine:setState(stateMachine.states.error)
      elseif craft.isDone() then
        event.push("log_info", config.essentiaManager:getEssentiaByKey(missingAspects[key].name).name .. " crafted")
        table.remove(missingAspects, key)
        table.remove(missingAspectsCrafts, key)
      end
    end

    if #missingAspectsCrafts == 0 then 
      if #missingAspects == 0 then
        stateMachine.data.missingAspects = {}
        stateMachine.data.missingAspectsCrafts = {}
        stateMachine:setState(stateMachine.states.checkAspects)
      else
        stateMachine:setState(stateMachine.states.craftAspects)
      end
    end
  end

  stateMachine.states.craft = stateMachine:createState("Craft")
  stateMachine.states.craft.init = function()
    config.infusionManager:start()
  end
  stateMachine.states.craft.update = function()
    if config.infusionManager:isEnd(stateMachine.data.recipe) == true then
      stateMachine:setState(stateMachine.states.finishCraft)
    end
  end

  stateMachine.states.finishCraft = stateMachine:createState("Finish Craft")
  stateMachine.states.finishCraft.init = function()
    config.infusionManager:finish()

    event.push("log_info", "Craft completed: "..stateMachine.data.recipeName)

    stateMachine.data.recipe = nil
    stateMachine.data.recipeName = ""

    stateMachine:setState(stateMachine.states.idle)
  end

  stateMachine.states.error = stateMachine:createState("Error")
  stateMachine.states.error.init = function()
    event.push("log_error", stateMachine.data.errorMessage)
    event.push("log_info","&red;Press Enter to confirm")
  end

  stateMachine.states.scanPatterns = stateMachine:createState("Scan Patterns")
  stateMachine.states.scanPatterns.init = function()
    event.push("log_info", "Scanning for new recipes")

    os.sleep(0.1)

    local patterns, recept = config.recipeManager:scanPatterns()

    if patterns == nil then
      event.push("log_warning", "[Warning] invalid aspect count in: "..recept)
      stateMachine:setState(stateMachine.states.idle)
      return
    end

    if #patterns == 0 then
      event.push("log_info", "No new recipes found")
      stateMachine:setState(stateMachine.states.idle)
      return
    end

    stateMachine.data.patterns = patterns
    stateMachine:setState(stateMachine.states.confirmPattern)
  end

  stateMachine.states.confirmPattern = stateMachine:createState("Confirm Pattern")
  stateMachine.states.confirmPattern.init = function()
    if #stateMachine.data.patterns == 0 then
      gui:resetToTemplate()
      gui.allowRender = true
      stateMachine.data.currentPattern = nil
      stateMachine:setState(stateMachine.states.idle)
      return
    end

    gui.allowRender = false
    gui:resetScreen()

    local pattern = stateMachine.data.patterns[1]
    table.remove(stateMachine.data.patterns, 1)

    console:writeLine("New recipe found: "..pattern.name.." add it? [Y/N]")

    local reader = console:createBooleanReader()
    local result = console:read(reader)

    if result then
      stateMachine.data.currentPattern = pattern
      stateMachine:setState(stateMachine.states.addAspects)
      return
    end

    stateMachine:setState(stateMachine.states.confirmPattern)
  end

  stateMachine.states.addAspects = stateMachine:createState("Add Aspects")
  stateMachine.states.addAspects.init = function()
    local aspects = {}

    if #stateMachine.data.currentPattern.aspects ~= 0 then
      for _, rawAspect in pairs(stateMachine.data.currentPattern.aspects) do
        local aspect = {}
        aspect.name = config.essentiaManager:getKeyByName(rawAspect.name)
        aspect.count = rawAspect.count
        table.insert(aspects, aspect)
      end
    end

    aspects = config.essentiaManager:editAspects(aspects, stateMachine.data.currentPattern.name)

    local reader = console:createBooleanReader()

    console:writeLine("")
    console:writeLine("Save recipe? [Y/N]")
    local result = console:read(reader)

    if result then
      local recipe = {
        name = stateMachine.data.currentPattern.name,
        result = stateMachine.data.currentPattern.result,
        ingredients = stateMachine.data.currentPattern.ingredients,
        aspects = aspects
      }

      config.recipeManager:addRecipe(recipe)
      config.recipeManager:removeAspectsFromPattern(stateMachine.data.currentPattern)
    end

    stateMachine:setState(stateMachine.states.confirmPattern)
  end

  stateMachine.states.editRecipe = stateMachine:createState("Edit Recipe")
  stateMachine.states.editRecipe.init = function()
    gui.allowRender = false
    gui:resetScreen()

    if stateMachine.data.editPage == nil then
      stateMachine.data.editPage = 0
    end

    local _, height = console:getResolution()
    local pageSize = height - 6
    local pageCount = math.floor(#config.recipeManager.recipes / pageSize) + 1
    local elementsOnPage = math.min(pageSize, #config.recipeManager.recipes - (stateMachine.data.editPage * pageSize))
    local first = math.floor((stateMachine.data.editPage * pageSize) + 1)
    local last = math.floor(first + elementsOnPage - 1)

    for i = first, last, 1 do
      console:writeLine("["..i.."] "..config.recipeManager.recipes[i].name)
    end

    local reader = console:createReader()
    reader.conditions.index = console:createCondition()
    reader.conditions.index.userInputToNumber = true
    reader.conditions.index.condition = function(userInput)
      return userInput >= 0 and userInput <= #config.recipeManager.recipes
    end
    reader.conditions.page = console:createCondition()
    reader.conditions.page.userInputToLower = true
    reader.conditions.page.condition = function(userInput)
      local page = string.match(userInput, "^p(%d+)$")
      page = tonumber(page)
      return page ~= nil and page > 0 and page <= pageCount
    end
    reader.conditions.page.callback = function(userInput)
      local page = string.match(userInput, "^p(%d+)$")

      stateMachine.data.editPage = tonumber(page - 1)
      stateMachine:setState(stateMachine.states.editRecipe)
    end

    console:writeLine("")
    console:writeLine("Enter [0] to exit")
    console:writeLine("Enter ["..first.."-"..last.."] recipe index")
    console:writeLine("Enter [p1-p"..pageCount.."] to select page")

    local index, condition  = console:read(reader)

    if condition == "index" then
      if index ~= 0 then 
        local reader = console:createBooleanReader()

        console:writeLine("")
        console:writeLine("Confirm remove? [Y/N]")
        local result = console:read(reader)

        if result then
          table.remove(config.recipeManager.recipes, index)
          config.recipeManager:save()
        end
      end

      stateMachine:setState(stateMachine.states.idle)

      gui.allowRender = true
      gui:resetToTemplate()
    end
  end

  stateMachine:setState(stateMachine.states.idle)
end

local function loop()
  while true do
    stateMachine:update()
    os.sleep(1)
  end
end

local function guiLoop()
  gui:render({
    state = stateMachine.currentState.name,
    recipeName = stateMachine.data.recipeName,
    logs = config.logger.handlers[3]["logs"].list
  })
end

local function errorButtonHandler()
  if stateMachine.currentState == stateMachine.states.error then
    stateMachine:setState(stateMachine.states.idle)
  end
end

local function addButtonHandler()
  if stateMachine.currentState == stateMachine.states.idle then
    stateMachine:setState(stateMachine.states.scanPatterns)
  end
end

local function editButtonHandler()
  if stateMachine.currentState == stateMachine.states.idle then
    stateMachine:setState(stateMachine.states.editRecipe)
  end
end

program:registerLogo(logo)
program:registerInit(init)
program:registerKeyHandler(keyboard.keys.enter, errorButtonHandler)
program:registerKeyHandler(keyboard.keys.a, addButtonHandler)
program:registerKeyHandler(keyboard.keys.e, editButtonHandler)
program:registerThread(loop)
program:registerTimer(guiLoop, math.huge)
program:start()