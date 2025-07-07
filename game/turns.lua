local class = require("lib.middleclass")
local Stateful = require("lib.stateful")

local Turns = class("Turn")
Turns:include(Stateful)

function Turns:initialize() end

return Turns
