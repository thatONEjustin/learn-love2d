local class = require("lib.middleclass")
local Stateful = require("lib.stateful")

Suits = { "hearts", "diamonds", "spades", "clubs" }
Faces = { "ace", "king", "queen", "jack" }
Ranks = 10

local Rules = class("Rules")
Rules:include(Stateful)

function Rules:initialize()
	self.cards = {
		suits = Suits,
		faces = Faces,
		ranks = Ranks,
	}
end

return Rules
