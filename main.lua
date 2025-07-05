local Deck = require("game.obj.deck")

local Buttons = require("lib.buttons")

-- Default deck rules
local game_deck = Deck:new()

-- Example of editing deck rules
-- local player_deck = Deck:new({ cards = { suits = { "hearts" } } })

-- local current_card

local game_state = {
	player = {
		current = {},
	},
	opponet = {
		current = {},
	},
}

function love.load()
	math.randomseed(os.time())

	game_deck:shuffle()

	-- Buttons:toggleDebug()

	local rect = Buttons:newRect(100, 200, 150, 75)
	local a, b = game_deck:split_deck()

	local playerDeck = Deck:new(nil, a)
	local opponentDeck = Deck:new(nil, b)

	rect:setClick(function()
		playerDeck:shuffle()
		game_state.player.current = playerDeck:draw_card()

		if game_state.player.current ~= nil then
			print(game_state.player.current.rank)
		end

		opponentDeck:shuffle()
		game_state.opponet.current = opponentDeck:draw_card()
	end)
end

function love.update(dt)
	Buttons:updateMain(dt)
end

function love.draw()
	Buttons:draw()
end

function love.mousepressed(x, y, button, istouch, presses)
	-- Handle mouse click events by updating button states
	Buttons:updateMouseClick(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
	-- Handle mouse release events (must be paired with a click event for proper functionality)
	Buttons:updateMouseRelease(x, y, button, istouch, presses)
end
