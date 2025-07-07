local class = require("lib.middleclass")
local Buttons = require("lib.buttons")

local Game = class("Game")

local Deck = require("game.deck")
local game_deck = Deck:new()

function Game:initialize() end

function Game:create()
	local draw_button = Buttons:newRect(100, 200, 150, 75)
	local a, b = game_deck:split_deck()

	local playerDeck = Deck:new(nil, a)
	local opponentDeck = Deck:new(nil, b)

	draw_button:setClick(function()
		playerDeck:shuffle()
		playerDeck:draw_card()

		opponentDeck:shuffle()
		opponentDeck():draw_card()
	end)
end

function Game:update(dt)
	Buttons:updateMain(dt)
end

function Game:draw()
	Buttons:draw()
end

return Game
