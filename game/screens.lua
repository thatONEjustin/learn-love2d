local class = require("lib.middleclass")
local Stateful = require("lib.stateful")

local Screens = class("Turn")
Screens:include(Stateful)

function Screens:initialize() end

-- local MainMenu = Screens:addState("MainMenu")

return Screens
