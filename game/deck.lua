local array = require("lib.array")
local class = require("lib.middleclass")
local inspect = require("lib.inspect")

local Stateful = require("lib.stateful")
local Card = require("game.card")
local Rules = require("game.rules")

local Deck = class("Deck")
Deck:include(Stateful)

local default_rules = Rules:new()

function Deck:initialize(rules, deck)
	local tmp_deck = {}

	-- default rules merging
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

	if deck == nil then
		-- deck stack
		self.cards = tmp_deck
	else
		self.cards = deck
	end
end

function RandomizeTable(tab)
	-- print(#tab)
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

function Deck:split_deck()
	print(tostring(#self.cards / 2))
	local deck_a = {}

	for i = 1, math.floor(#self.cards / 2) do
		deck_a[i] = self.cards[i]
	end

	local deck_b = {}
	for i = 1, math.floor(#self.cards / 2) do
		local other_half = math.floor(#self.cards / 2) + i
		deck_b[i] = self.cards[other_half]
	end

	return deck_a, deck_b
end

function Deck:draw_card()
	if #self.cards == 0 then
		print("deck is empty")
		return
	end

	local c = self.cards[#self.cards]

	print("do a card flip!!!")
	c:flip()

	table.remove(self.cards, #self.cards)

	print("how many left? " .. tostring(#self.cards))

	return c
end

return Deck
