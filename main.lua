local Deck = require("game.deck")

local Buttons = require("lib.buttons")

local GameState = require("game.game_state")
-- local Screens = require("game.screens")

-- Default deck rules
-- local game_deck = Deck:new()

MAIN_MENU = require("game.screens.MainMenu")
GAME_SCREEN = require("game.screens.Game")
GAME_STATE = GameState:new()

-- Example of editing deck rules
-- local player_deck = Deck:new({ cards = { suits = { "hearts" } } })

-- local current_card

function love.load()
	math.randomseed(os.time())

	MAIN_MENU:create()
	GAME_SCREEN:create()

	-- if GAME_STATE.screens.current == "MAIN_MENU" then
	-- end
	--
	-- if GAME_STATE.screens.current == "GAME_SCREEN" then
	-- end

	-- game_deck:shuffle()
	--
	Buttons:toggleDebug()
	Buttons:toggleDebug()
	--
	-- local rect = Buttons:newRect(100, 200, 150, 75)
	-- local a, b = game_deck:split_deck()
	--
	-- local playerDeck = Deck:new(nil, a)
	-- local opponentDeck = Deck:new(nil, b)
	--
	-- rect:setClick(function()
	-- 	playerDeck:shuffle()
	-- 	playerDeck:draw_card()
	--
	-- 	opponentDeck:shuffle()
	-- 	opponentDeck():draw_card()
	-- end)
end

function love.update(dt)
	Buttons:updateMain(dt)

	if GAME_STATE.screens.current == "MAIN_MENU" then
		MAIN_MENU:update(dt)
	end

	if GAME_STATE.screens.current == "GAME_SCREEN" then
		GAME_SCREEN:update(dt)
	end
end

function love.draw()
	Buttons:draw()

	if GAME_STATE.screens.current == "MAIN_MENU" then
		MAIN_MENU:draw()
	else
		love.graphics.discard()
	end

	if GAME_STATE.screens.current == "GAME_SCREEN" then
		GAME_SCREEN:draw()
	else
		love.graphics.discard()
	end
end

function love.mousepressed(x, y, button, istouch, presses)
	Buttons:updateMouseClick(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
	Buttons:updateMouseRelease(x, y, button, istouch, presses)
end
