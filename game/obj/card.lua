local class = require("lib.middleclass")
local Stateful = require("lib.stateful")

local Card = class("Card")
Card:include(Stateful)

function Card:initialize(rank, suit, faces, hidden)
	self.rank = rank
	self.suit = suit
	self.faces = faces
	self.hidden = hidden

	-- love.graphics.setColor(255, 255, 255, 1)
	-- self.background = love.graphics.rectangle("fill", 100, 100, 150, 250, 8, 8, 3)
end

function Card:display_label()
	if self.rank <= 10 then
		return tostring(self.rank)
	end

	local faces_index = self.rank - 10

	return tostring(self.faces[faces_index])
end

function Card:flip()
	self.hidden = not self.hidden
	print("rank: " .. self:display_label() .. " suit: " .. self.suit)
end

function Card:isHidden()
	return self.hidden
end

local CardHidden = Card:addState("hidden")

return Card
