local sides = require("sides")

local loggerLib = require("lib.logger-lib")
local discordLoggerHandler = require("lib.logger-handler.discord-logger-handler-lib")
local fileLoggerHandler = require("lib.logger-handler.file-logger-handler-lib")

local essentiaManager = require("src.essentia-manager")
local infusionManager = require("src.infusion-manager")
local recipeManager = require("src.recipe-manager")

local config = {
  logger = loggerLib:newFormConfig({
    name = "Infusion Control",
    timeZone = 3,
    handlers = {
      discordLoggerHandler:newFormConfig({
        logLevel = "warning",
        messageFormat = "{Time:%d.%m.%Y %H:%M:%S} [{LogLevel}]: {Message}",
        discordWebhookUrl = "" -- Discord Webhook URL
      }),
      fileLoggerHandler:newFormConfig({
        logLevel = "info",
        messageFormat = "{Time:%d.%m.%Y %H:%M:%S} [{LogLevel}]: {Message}",
        filePath = "logs.log"
      })
    }
  }),

  maxCpuUse = 3, -- Number of CPUs that can be used to order aspects

  essentiaManager = essentiaManager:newFormConfig({
    mainMeInterfaceAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of the me interface which connected to main ME
  }),

  infusionManager = infusionManager:newFormConfig({
    infusionMeInterfaceAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of the me interface which connected to infusion ME
    transposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",-- Address of the transposer
    mainMeSide = sides.south, -- Side of the transposer with ME IO Port which connected to main ME
    infusionMeSide = sides.north, -- Side of the transposer with ME IO Port which connected to infusion ME
    redstoneAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of the Redstone I/O
    infusionClawSide = sides.west, -- Side of the Redstone I/O with Redstone Transmitter of the infusion claw
    infusionClawAcceleratorSide = sides.south, -- Side of the Redstone I/O with Redstone Transmitter of the infusion claw accelerator
    acceleratorSide = sides.north, -- Side of the Redstone I/O with Redstone Transmitter of the matrix accelerator
    infusionClawActivationDelay = 0.1, -- Delay how long to signal the infusion claw
    infusionClawAcceleratorDelay = 1, -- Delay how long to signal the infusion claw accelerator
  }),

  recipeManager = recipeManager:newFormConfig({
    recipeMeInterfaceAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of me interface which will be used to add recipes
  }),
}

return config