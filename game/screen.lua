local class = require("lib.middleclass")
local Stateful = require("lib.stateful")

local Screen = class("Turn")
Screen:include(Stateful)

return Screen
