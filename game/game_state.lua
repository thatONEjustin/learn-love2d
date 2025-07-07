local class = require("lib.middleclass")
local Stateful = require("lib.stateful")

local GameState = class("Turn")
GameState:include(Stateful)

function GameState:initialize()
	self.screens = {
		current = "MAIN_MENU",
		MAIN_MENU = {
			test = "Text That We Display, just variable",
		},
		GAME_SCREEN = {},
		GAME_OVER = {},
	}

	self.players = {
		player = {
			deck = nil,
			current_card = nil,
		},
		opponent = {
			deck = nil,
			current_card = {},
		},
	}
end

return GameState
