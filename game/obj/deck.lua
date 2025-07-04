local class = require("lib.middleclass")

local Stateful = require("lib.stateful")
local Card = require("game.obj.card")
local Rules = require("game.obj.rules")

local Deck = class("Deck")
Deck:include(Stateful)

local default_rules = Rules:new()

function Deck:initialize(rules)
	local tmp_deck = {}

	self.rules = default_rules

	if rules ~= nil then
		for k, v in pairs(rules.cards) do
			self.rules.cards[k] = v
		end
	end

	for _, suit in ipairs(self.rules.cards.suits) do
		for i = 2, self.rules.cards.ranks + #self.rules.cards.faces do
			table.insert(tmp_deck, Card:new(i, suit, self.rules.cards.faces, false))
		end
	end

	self.cards = tmp_deck
end

function RandomizeTable(tab)
	local len = #tab
	local r
	for i = 1, len do
		r = math.random(i, len)

		tab[i], tab[r] =
			type(tab[r]) == "table" and RandomizeTable(tab[r]) or tab[r],
			type(tab[i]) == "table" and RandomizeTable(tab[i]) or tab[i]
	end

	return tab
end

function Deck:shuffle()
	self.cards = RandomizeTable(self.cards)
end

function Deck:draw()
	if #self.cards == 0 then
		print("deck is empty")
		return
	end

	local c = self.cards[#self.cards]

	print("do a card flip!!!")
	c:flip()

	table.remove(self.cards, #self.cards)

	print("how many left? " .. tostring(#self.cards))
end

return Deck
