local Card = require("game.obj.card")
-- local DeckClass = require("game.obj.deck")
local Deck = require("game.obj.deck")

-- Suits = { "hearts", "diamonds", "spades", "clubs" }
-- Faces = { "ace", "king", "queen", "jack" }
-- Ranks = 10

local player_deck = Deck:new()
-- local player_deck = Deck:new({ cards = { suits = { "hearts" } } })

function love.load()
	math.randomseed(os.time())
	math.random()

	player_deck:shuffle()

	for _ = 1, math.random(2, 53) do
		player_deck:draw()
	end
end

-- Increase the size of the rectangle every frame.
function love.update(dt) end

-- Draw a coloured rectangle.
function love.draw()
	-- love.graphics.print(Test, 100, 100)
end
