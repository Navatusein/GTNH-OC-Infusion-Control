local component = require("component")

local componentDiscoverLib = require("lib.component-discover-lib")

---@class InfusionManagerConfig
---@field infusionMeInterfaceAddress string
---@field transposerAddress string
---@field mainMeSide number
---@field infusionMeSide number
---@field redstoneAddress string
---@field infusionClawSide number
---@field infusionClawAcceleratorSide number
---@field acceleratorSide number
---@field infusionClawActivationDelay number|nil
---@field infusionClawAcceleratorDelay number|nil

local infusionManager = {}

---Crate new InfusionManager object from config
---@param config InfusionManagerConfig
---@return InfusionManager
function infusionManager:newFormConfig(config)
  return self:new(
    config.infusionMeInterfaceAddress,
    config.transposerAddress,
    config.mainMeSide,
    config.infusionMeSide,
    config.redstoneAddress,
    config.infusionClawSide,
    config.infusionClawAcceleratorSide,
    config.acceleratorSide,
    config.infusionClawActivationDelay,
    config.infusionClawAcceleratorDelay
  )
end

---Crate new InfusionManager object
---@param infusionMeInterfaceAddress string
---@param transposerAddress string
---@param mainMeSide number
---@param infusionMeSide number
---@param redstoneAddress string
---@param infusionClawSide number
---@param infusionClawAcceleratorSide number
---@param acceleratorSide number
---@param infusionClawActivationDelay number|nil
---@param infusionClawAcceleratorDelay number|nil
---@return InfusionManager
function infusionManager:new(
  infusionMeInterfaceAddress,
  transposerAddress,
  mainMeSide,
  infusionMeSide,
  redstoneAddress,
  infusionClawSide,
  infusionClawAcceleratorSide,
  acceleratorSide,
  infusionClawActivationDelay,
  infusionClawAcceleratorDelay
)

  ---@class InfusionManager
  local obj = {}

  obj.infusionMeInterfaceProxy = componentDiscoverLib.discoverProxy(infusionMeInterfaceAddress, "Infusion Me Interface", "me_interface")

  obj.transposerProxy = componentDiscoverLib.discoverProxy(transposerAddress, "ME IO Port Transposer", "transposer")

  obj.mainMeSide = mainMeSide
  obj.infusionMeSide = infusionMeSide

  obj.redstoneProxy = componentDiscoverLib.discoverProxy(redstoneAddress, "Redstone I/O", "redstone")

  obj.infusionClawSide = infusionClawSide
  obj.infusionClawAcceleratorSide = infusionClawAcceleratorSide
  obj.acceleratorSide = acceleratorSide

  obj.infusionClawActivationDelay = infusionClawActivationDelay or 0.1
  obj.infusionClawAcceleratorDelay = infusionClawAcceleratorDelay or 0.1

  ---Get ingredients from infusion ae
  ---@return Ingredient[]
  function obj:getIngredients()
    local networkItems = self.infusionMeInterfaceProxy.getItemsInNetwork({})
    local items = {}

    for _, value in pairs(networkItems) do
      table.insert(items, {name = value.label, count = value.size})
    end

    return items
  end

  ---Reset infusion state
  function obj:reset()
    self.redstoneProxy.setOutput(self.infusionClawSide, 0)
    self.redstoneProxy.setOutput(self.infusionClawAcceleratorSide, 0)
    self.redstoneProxy.setOutput(self.acceleratorSide, 0)
  end

  ---Start infusion craft
  function obj:start()
    self.redstoneProxy.setOutput(self.infusionClawSide, 15)
    os.sleep(self.infusionClawActivationDelay)
    self.redstoneProxy.setOutput(self.infusionClawSide, 0)
    os.sleep(self.infusionClawActivationDelay)

    self.redstoneProxy.setOutput(self.acceleratorSide, 15)
    self.redstoneProxy.setOutput(self.infusionClawAcceleratorSide, 15)

    os.sleep(self.infusionClawAcceleratorDelay)

    self.redstoneProxy.setOutput(self.infusionClawAcceleratorSide, 0)
  end

  ---Finish infusion craft
  function obj:finish()
    self.redstoneProxy.setOutput(self.acceleratorSide, 0)
    self.transposerProxy.transferItem(self.mainMeSide, self.infusionMeSide, 1, 7, 1)

    while self.transposerProxy.getSlotStackSize(self.infusionMeSide, 7) ~= 1 do
    end

    self.transposerProxy.transferItem(self.infusionMeSide, self.mainMeSide, 1, 7, 1)
  end

  ---Check if infusion craft is end
  ---@param recipe Recipe
  ---@return boolean
  function obj:isEnd(recipe)
    for _, value in pairs(self:getIngredients()) do
      if value.name == recipe.result.name and value.count == recipe.result.count then
        return true
      end
    end

    return false
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return infusionManager