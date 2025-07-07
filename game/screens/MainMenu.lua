local class = require("lib.middleclass")
local Buttons = require("lib.buttons")

local MainMenu = class("MainMenu")

function MainMenu:initialize() end

function MainMenu:create()
	print("MainMenu created?")
	-- Buttons:toggleDebug()
	-- Buttons:toggleDebug()
	local startGame_button = Buttons:newRect(100, 200, 150, 75)

	startGame_button:setClick(function()
		print(GAME_STATE.screens.current)
		GAME_STATE.screens.current = "GAME_SCREEN"
	end)
end

function MainMenu:update(dt)
	Buttons:updateMain(dt)
end

function MainMenu:draw()
	Buttons:draw()
end

return MainMenu
