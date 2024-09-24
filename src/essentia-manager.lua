local component = require("component")

local consoleLib = require("lib.console-lib")

local console = consoleLib:new()

---@class Essentia
---@field aspect string
---@field name string
local essentia = {}

---@type table<string, Essentia>
local essentiaList = {
  gaseousaequalitasessentia = {aspect="aequalitas", name="Aequalitas"},
  gaseousaeressentia = {aspect="aer", name="Aer"},
  gaseousalienisessentia = {aspect="alienis", name="Alienis"},
  gaseousaquaessentia = {aspect="aqua", name="Aqua"},
  gaseousarboressentia = {aspect="arbor", name="Arbor"},
  gaseousastrumessentia = {aspect="astrum", name="Astrum"},
  gaseousauramessentia = {aspect="auram", name="Auram"},
  gaseousbestiaessentia = {aspect="bestia", name="Bestia"},
  gaseouscaelumessentia = {aspect="caelum", name="Caelum"},
  gaseouscognitioessentia = {aspect="cognitio", name="Cognitio"},
  gaseouscorpusessentia = {aspect="corpus", name="Corpus"},
  gaseousdesidiaessentia = {aspect="desidia", name="Desidia"},
  gaseouselectrumessentia = {aspect="electrum", name="Electrum"},
  gaseousexanimisessentia = {aspect="exanimis", name="Exanimis"},
  gaseousfabricoessentia = {aspect="fabrico", name="Fabrico"},
  gaseousfamesessentia = {aspect="fames", name="Fames"},
  gaseousgelumessentia = {aspect="gelum", name="Gelum"},
  gaseousgloriaessentia = {aspect="gloria", name="Gloria"},
  gaseousgulaessentia = {aspect="gula", name="Gula"},
  gaseousherbaessentia = {aspect="herba", name="Herba"},
  gaseoushumanusessentia = {aspect="humanus", name="Humanus"},
  gaseousignisessentia = {aspect="ignis", name="Ignis"},
  gaseousinfernusessentia = {aspect="infernus", name="Infernus"},
  gaseousinstrumentumessentia = {aspect="instrumentum", name="Instrumentum"},
  gaseousinvidiaessentia = {aspect="invidia", name="Invidia"},
  gaseousiraessentia = {aspect="ira", name="Ira"},
  gaseousiteressentia = {aspect="iter", name="Iter"},
  gaseouslimusessentia = {aspect="limus", name="Limus"},
  gaseouslucrumessentia = {aspect="lucrum", name="Lucrum"},
  gaseousluxessentia = {aspect="lux", name="Lux"},
  gaseousluxuriaessentia = {aspect="luxuria", name="Luxuria"},
  gaseousmachinaessentia = {aspect="machina", name="Machina"},
  gaseousmagnetoessentia = {aspect="magneto", name="Magneto"},
  gaseousmessisessentia = {aspect="messis", name="Messis"},
  gaseousmetallumessentia = {aspect="metallum", name="Metallum"},
  gaseousmetoessentia = {aspect="meto", name="Meto"},
  gaseousmortuusessentia = {aspect="mortuus", name="Mortuus"},
  gaseousmotusessentia = {aspect="motus", name="Motus"},
  gaseousnebrisumessentia = {aspect="nebrisum", name="Nebrisum"},
  gaseousordoessentia = {aspect="ordo", name="Ordo"},
  gaseouspannusessentia = {aspect="pannus", name="Pannus"},
  gaseousperditioessentia = {aspect="perditio", name="Perditio"},
  gaseousperfodioessentia = {aspect="perfodio", name="Perfodio"},
  gaseouspermutatioessentia = {aspect="permutatio", name="Permutatio"},
  gaseouspotentiaessentia = {aspect="potentia", name="Potentia"},
  gaseouspraecantatioessentia = {aspect="praecantatio", name="Praecantatio"},
  gaseousprimordiumessentia = {aspect="primordium", name="Primordium"},
  gaseousradioessentia = {aspect="radio", name="Radio"},
  gaseoussanoessentia = {aspect="sano", name="Sano"},
  gaseoussensusessentia = {aspect="sensus", name="Sensus"},
  gaseousspiritusessentia = {aspect="spiritus", name="Spiritus"},
  gaseousstrontioessentia = {aspect="strontio", name="Strontio"},
  gaseoussuperbiaessentia = {aspect="superbia", name="Superbia"},
  gaseoustabernusessentia = {aspect="tabernus", name="Tabernus"},
  gaseoustelumessentia = {aspect="telum", name="Telum"},
  gaseoustempestasessentia = {aspect="tempestas", name="Tempestas"},
  gaseoustempusessentia = {aspect="tempus", name="Tempus"},
  gaseoustenebraeessentia = {aspect="tenebrae", name="Tenebrae"},
  gaseousterminusessentia = {aspect="terminus", name="Terminus"},
  gaseousterraessentia = {aspect="terra", name="Terra"},
  gaseoustutamenessentia = {aspect="tutamen", name="Tutamen"},
  gaseousvacuosessentia = {aspect="vacuos", name="Vacuos"},
  gaseousvenenumessentia = {aspect="venenum", name="Venenum"},
  gaseousvesaniaessentia = {aspect="vesania", name="Vesania"},
  gaseousvictusessentia = {aspect="victus", name="Victus"},
  gaseousvinculumessentia = {aspect="vinculum", name="Vinculum"},
  gaseousvitiumessentia = {aspect="vitium", name="Vitium"},
  gaseousvitreusessentia = {aspect="vitreus", name="Vitreus"},
  gaseousvolatusessentia = {aspect="volatus", name="Volatus"}
}

---@class EssentiaManagerConfig
---@field mainMeInterfaceAddress string
local configParams = {}

local essentiaManager = {}

---Crate new EssentiaManager object from config
---@param config EssentiaManagerConfig
---@return EssentiaManager
function essentiaManager:newFormConfig(config)
  return self:new(config.mainMeInterfaceAddress)
end

---Crate new InfusionManager object
---@param mainMeInterfaceAddress string
---@return EssentiaManager
function essentiaManager:new(mainMeInterfaceAddress)

  ---@class EssentiaManager
  local obj = {}

  obj.mainMeInterfaceProxy = component.proxy(mainMeInterfaceAddress)

  ---Edit aspects in recipe
  ---@param aspects Ingredient[]
  ---@param recipeName string
  function obj:editAspects(aspects, recipeName)
    local reader = console:createReader()

    reader.conditions.finish = console:createCondition()
    reader.conditions.finish.userInputToNumber = true
    reader.conditions.finish.condition = function(userInput)
      return userInput == 0
    end

    reader.conditions.edit = console:createCondition()
    reader.conditions.edit.userInputToNumber = true
    reader.conditions.edit.condition = function(userInput)
      return userInput > 0 and userInput <= #aspects and #aspects > 0
    end
    reader.conditions.edit.callback = function(userInput)
      local index = tonumber(userInput)

      console:writeLine("")
      console:writeLine("Enter [0] to remove")
      console:writeLine("Enter new amount of "..self:getEssentiaByKey(aspects[index].name).name.." aspect")

      local reader = console:createReader()

      reader.conditions.count = console:createCondition()
      reader.conditions.count.userInputToNumber = true
      reader.conditions.count.condition = function(userInput)
        return userInput >= 0
      end

      local count = console:read(reader)

      if count == 0 then
        table.remove(aspects, index)
      else
        aspects[index].count = count
      end
    end

    reader.conditions.add = console:createCondition()
    reader.conditions.add.condition = function(userInput)
      return string.match(userInput, "[a-zA-Z]+")
    end
    reader.conditions.add.callback = function(userInput)
      local essentias = self:getKeyByPartName(tostring(userInput))

      console:writeLine("")

      if #essentias == 0 then
        console:writeLine("Matches not found. Press Enter to try again.")
        console:read()
      else
        console:writeLine("[0] Choose another")

        for index, essentia in pairs(essentias) do
          console:writeLine("["..index.."] "..self:getEssentiaByKey(essentia).name)
        end

        console:writeLine("Enter [1-"..#essentias.."] to add aspect")

        local reader = console:createReader()
        reader.conditions.index = console:createCondition()
        reader.conditions.index.userInputToNumber = true
        reader.conditions.index.condition = function(userInput)
          return userInput >= 0 and userInput <= #essentias
        end

        local index = console:read(reader)

        if index ~= 0 then
          console:writeLine("Enter the amount")

          local reader = console:createReader()

          reader.conditions.count = console:createCondition()
          reader.conditions.count.userInputToNumber = true
          reader.conditions.count.condition = function(userInput)
            return userInput > 0
          end

          local count = console:read(reader)

          table.insert(aspects, {name = essentias[index], count = count})
        end
      end
    end

    while true do
      console:clear()
      console:writeLine("Recipe: ".. recipeName)
      console:writeLine("Aspects: ")

      for index, aspect in pairs(aspects) do
        console:writeLine(" ["..index.."] "..self:getEssentiaByKey(aspect.name).name..": "..aspect.count)
      end

      console:writeLine("")
      console:writeLine("Enter [0] to finish")
      console:writeLine("Enter [1-"..#aspects.."] to edit aspect")
      console:writeLine("Enter aspect name [praec or victu] to add aspect")

      local _, condition = console:read(reader)

      if condition == "finish" then
        break
      end
    end

    return aspects
  end

  ---Get essentia by key
  ---@param key string
  ---@return Essentia
  function obj:getEssentiaByKey(key)
    return essentiaList[key]
  end

  ---Get key by name
  ---@param name string
  ---@return string|nil
  function obj:getKeyByName(name)
    for key, essentia in pairs(essentiaList) do
      if essentia.name == name then
        return key
      end
    end

    return nil
  end

  ---Get essentia by part name
  ---@param partName string
  ---@return string[]
  function obj:getKeyByPartName(partName)
		local result = {}

		for key, value in pairs(essentiaList) do
			if type(value) == "table" then
				if string.find(value.name, partName) ~= nil or string.find(value.aspect, partName) ~= nil then
					table.insert(result, key)
				end
			end
		end

		return result
	end

  ---Get free cpus
  ---@return integer
  function obj:getFreeCpusCount()
		local cpus = self.mainMeInterfaceProxy.getCpus()
    local freeCpusCount = 0

    for _, value in pairs(cpus) do
      if value.busy == false then
        freeCpusCount = freeCpusCount + 1
      end
    end

    return freeCpusCount
	end

  ---Craft missing aspects
  ---@param aspect Ingredient
  ---@return table|nil
  function obj:craftAspect(aspect)
    local craft = self.mainMeInterfaceProxy.getCraftables({
      aspect = essentiaList[aspect.name].aspect,
      name = "thaumicenergistics:crafting.aspect"
    })

    if craft[1] == nil then
      return nil
    end

    return craft[1].request(aspect.count)
  end

  ---Check for missing aspects
  ---@param recipe Recipe
  ---@return Ingredient[]
  function obj:checkAspects(recipe)
    local availableAspects = self.mainMeInterfaceProxy.getEssentiaInNetwork()
    local missingAspects = {}

    for _, recipeAspect in pairs(recipe.aspects) do
      local missingCount = recipeAspect.count

      for _, availableAspect in pairs(availableAspects) do
        if availableAspect.name == recipeAspect.name then
          if availableAspect.amount >= recipeAspect.count then
            missingCount = 0
            break
          else
            missingCount = recipeAspect.count - availableAspect.amount
            break
          end
        end
      end

      if missingCount ~= 0 then
        table.insert(missingAspects, {name = recipeAspect.name, count = missingCount})
      end
    end

    return missingAspects
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return essentiaManager