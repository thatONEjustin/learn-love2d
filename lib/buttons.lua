-- buttons Library Overview

-- This library provides functionality for managing interactive buttons.
-- It supports three shapes: rectangles, circles, and polygons, and includes methods for handling
-- events such as mouse movements, clicks, and state updates. Additionally, it allows for
-- translating all layers and scaling, providing flexible positioning and sizing of buttons.

-- Features:
-- - **Layer System**: The library implements a layer system where buttons are organized by layers.
--   Buttons in lower layers (with lower layer IDs) have higher priority, meaning they will respond to events
--   before buttons in higher layers.
-- - **Hover State Management**: Only one button can have a hover state or hover border state active at any given time,
--   ensuring clear visual feedback without ambiguity.
-- - **Overlapping Buttons**: The library handles overlapping buttons efficiently. When buttons overlap,
--   the topmost button (based on the layer system) will receive input events, while lower buttons remain unaffected,
--   preventing errors or unintended behavior.

-- Callback Functions:
-- - **BorderHover(xm, ym, dx, dy)**: Called every frame when the mouse is over the button border.
-- - **BorderUnHover(xm, ym, dx, dy)**: Called once when the mouse leaves the button border.
-- - **WhileBorderHover(self, xm, ym, dx, dy)**: Called every frame while the cursor is hovering over the button border.
-- - **WhileBorderPressed(self, xm, ym, dx, dy)**: Called every frame while the button border is pressed, even if the mouse leaves the button.
-- - **Hover(self, xm, ym, dx, dy)**: Called once when the mouse enters the button area.
-- - **WhileHover(self, xm, ym, dx, dy)**: Called every frame while the mouse is over the button.
-- - **WhilePressed(xm, ym, dx, dy)**: Called every frame when the button is pressed, even if the mouse leaves the button.
-- - **UnHover(self, xm, ym, dx, dy)**: Called once when the mouse leaves the button area.
-- - **BorderClick(self, xm, ym, button)**: Called once when the mouse clicks on the button border.
-- - **Click(self, xm, ym, button)**: Called once when the mouse clicks inside the button.
-- - **Release(self, xm, ym, button)**: Called once when the mouse releases a button inside the button's area.
-- - **BorderRelease(self, xm, ym, button)**: Called once when the mouse releases a button on the button's border.
-- - **WhileMoves(self, xm, ym, dx, dy, istouch)**: Called every time the mouse moves.
-- - **Scroll(dxm, dym)**: Called every time the user scrolls, capturing the scroll direction and amount.

------------------------------------------
--Built with love (and a bit of madness) for Love2D 11.5
----------------------------------------------

local buttons = {}

---------------------
-- Configuration
---------------------
-- Width where hover/click border detection works methods  :getBorderCheckWidht() :setBorderCheckWidht(num)
buttons.borderCheckWidth = 5

-- If set to false, the hover border won't be displayed and calculated   buttons.enableBorderHover()  buttons.disableBorderHover()  buttons.getBorderHoverState()
buttons.updateBorderHover = true

-- Will throw error when number exceed
-- Maximum number of buttons per layer
buttons.max_quantity_buttons_in_layer = 4000 -- Based on testing, more than 8000 rectangles drops FPS below 60 methods:setMaxQuantityButtonsInLayer(x) :getMaxQuantityButtonsInLayer(x)
-- Maximum number of layers methods:getMaxQuantityLayers(num) :setMaxQuantityLayers(num)
buttons.max_quantity_layers = 400
---------------------
-- END Configuration
---------------------
---------------------
-- Service variables, do not change
---------------------

buttons.IsDownBorderMain = { false, false, false } -- is some mouse button pressed on border
buttons.IsDownMain = { false, false, false } -- is some mouse button pressed on body

buttons.translate = {}
buttons.translate.x = 0 -- Translates all buttons. Use buttons:setTranslateX() to modify
buttons.translate.y = 0 -- Translates all buttons. Use buttons:setTranslateY() to modify
buttons.scale = 1 -- Scales all buttons. Use buttons:setScale() to modify

-- Use buttons:toggleDebug() to change the debug state
buttons.debug = false
buttons.debugText = false
buttons.debugLine = false
buttons.debugBorderHover = false

buttons.layers = {} -- Stores layers

buttons.layers[1] = {} -- Stores buttons
buttons.current_layer = 1 -- Sets the current active layer for adding new button

buttons.mousePosition = {} -- Stores the mouse delta between updates

buttons.rclr = {} -- Contains random colors for buttons in debug mode

buttons.hover_lock = false -- Prevents hover functionality
buttons.Prev_hover = false -- Stores the previous or currently hovered button (either on the body or border)
buttons.updateTime = 0 -- Time between updates for debug rendering

---------------------
-- Types of buttons -  number : name
-- 1: rectangle
-- 2: circle
-- 3: polygon
---------------------

--- Creates a new circle in the current layer

---@param x number X-coordinate of the circle's center
---@param y number Y-coordinate of the circle's center
---@param r number Radius of the circle
function buttons:newCircle(x, y, r)
	local btn = self:GetBtnBase(x, y, self:idCreate(), 2, { r = r }) -- Gets the base table for the button with type 2 and adds the radius
	self.layers[btn.layer][btn.id] = btn -- Adds the button to the layer
	return self.layers[btn.layer][btn.id] -- Returns a reference to the button
end

--- Creates a new rectangle in the current layer
---@param x number X-coordinate of the rectangle's top-left corner
---@param y number Y-coordinate of the rectangle's top-left corner
---@param w number Width of the rectangle
---@param h number Height of the rectangle
function buttons:newRect(x, y, w, h)
	local btn = self:GetBtnBase(x, y, self:idCreate(), 1, { h = h, w = w }) -- Gets the base table for the button with type 1 and adds width and height
	self.layers[btn.layer][btn.id] = btn -- Adds the button to the layer
	return self.layers[btn.layer][btn.id] -- Returns a reference to the button
end

--- Creates a new polygon in the current layer
---@param x number X-coordinate of the polygon's reference point
---@param y number Y-coordinate of the polygon's reference point
---@param vertex table List of vertex coordinates for the polygon
function buttons:newPoly(x, y, vertex)
	local btn = self:GetBtnBase(x, y, self:idCreate(), 3, { vertex = vertex }) -- Gets the base table for the button with type 3 and adds vertices
	self.layers[btn.layer][btn.id] = btn -- Adds the button to the layer
	return self.layers[btn.layer][btn.id] -- Returns a reference to the button
end

--- draws all buttons and debug info use button:toggleDebug() to change amount of info
function buttons:draw()
	-- Main cucle for drawing and printing
	if self.debug then
		self:mainUpdateCycleReversed(function(self, layer, key, btn)
			local x, y = self:Scale(math.floor(btn.x * 10 ^ 1) / 10 ^ 1, math.floor(btn.y * 10 ^ 1) / 10 ^ 1) -- Translate the button's coordinates with scaling and rounding
			x, y = self:Translate(x, y)
			if btn.id == nil then
				goto skip
			end -- Skip if the button has no ID

			-- Initialize random colors for the button if not already set
			if not self.rclr[key] then
				self.rclr[key] = {}
			end
			if not self.rclr[key][1] then
				self.rclr[key][1] = math.random(3, 8) / 10
			end -- Red color component
			if not self.rclr[key][2] then
				self.rclr[key][2] = math.random(3, 8) / 10
			end -- Green color component
			if not self.rclr[key][3] then
				self.rclr[key][3] = math.random(3, 8) / 10
			end -- Blue color component
			-- Set the button color: if disabled, apply gray with transparency
			if btn.Disabled then
				love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
			else
				-- Set the random color for the button
				love.graphics.setColor(self.rclr[key][1], self.rclr[key][2], self.rclr[key][3], 1)
			end

			-- If the button is hovered, change its color to light gray
			if btn.IsHover then
				love.graphics.setColor(0.8, 0.8, 0.8, 1)
			end

			-- Change color based on which mouse button is pressed
			if btn.IsDown[1] then
				love.graphics.setColor(1, 0, 0, 0.2) -- Left mouse button pressed, set red color
			elseif btn.IsDown[2] then
				love.graphics.setColor(0, 1, 0, 0.2) -- Right mouse button pressed, set green color
			elseif btn.IsDown[3] then
				love.graphics.setColor(0, 0, 1, 0.2) -- Middle mouse button pressed, set blue color
			end

			if btn.type == 1 then -- Check if the button is a rectangle
				local w, h = self:Scale(btn.w, btn.h) -- Scale the width and height of the button

				-- Set color to gray if the layer or button is disabled
				if btn.Disabled then
					love.graphics.setColor(0.5, 0.5, 0.5)
				end

				love.graphics.rectangle("fill", x, y, w, h) -- Draw the filled rectangle for the button
				-- Draw a line where the BorderHover is called in debug mode
				if self.debugLine then
					love.graphics.setColor(1, 0, 0.8) -- Set color for debug line

					-- Set gray color if the layer or button is disabled
					if btn.Disabled then
						love.graphics.setColor(0.5, 0.5, 0.5)
					end

					love.graphics.setPointSize(4) -- Set point size for debug points
					love.graphics.setLineWidth(2) -- Set line width for debug lines

					-- Define the points for the rectangle's corners
					local points = { x, y, x, y + h, x + w, y + h, x + w, y }
					local origin = {}
					-- Store original coordinates without scaling or transforming
					origin.points = {
						math.floor(btn.x * 10) / 10,
						math.floor(btn.y * 10) / 10,
						math.floor(btn.y * 10) / 10 + btn.h,
						math.floor(btn.x * 10) / 10 + btn.w,
						math.floor(btn.y * 10) / 10 + btn.h,
						math.floor(btn.x * 10) / 10 + btn.w,
					}

					love.graphics.points(points) -- Draw debug points at the corners

					-- Print the coordinates of the points above the respective points
					for i = 1, #origin.points - 1, 2 do
						love.graphics.print(
							"x:" .. origin.points[i] .. " y:" .. origin.points[i + 1],
							points[i],
							points[i + 1] - 20
						)
					end
					love.graphics.rectangle("line", x, y, w, h) -- Draw a border around the rectangle
				end

				-- Draw BorderHovers in debug mode if enabled
				if btn:hasBorderCallback() and self.debugBorderHover and self.updateBorderHover then
					if btn.IsBorderHover then
						love.graphics.setColor(1, 0, 0) -- Set color to red if hovering
					elseif not btn.IsBorderHover then
						love.graphics.setColor(0.5, 0, 0, 0.5) -- Set semi-transparent gray if not hovering
					end

					-- Set gray color if the layer or button is disabled
					if btn.Disabled then
						love.graphics.setColor(0.5, 0.5, 0.5)
					end
					love.graphics.setLineWidth(self.borderCheckWidth * 2) -- Set line width for the hover border
					love.graphics.rectangle("line", x, y, w, h) -- Draw the hover border around the rectangle
				end
				love.graphics.setColor(1, 1, 1) -- Reset color to white for further drawings
				love.graphics.setLineWidth(1) -- Reset line width to default
				origin = nil -- Clear the origin variable
			elseif btn.type == 3 then -- Check if the button is a polygon
				local vertex_temp = {} -- Temporary table to hold the scaled vertex positions
				for i = 1, #btn.vertex, 1 do
					if i % 2 == 1 then
						vertex_temp[i] = self:Scale(btn.vertex[i]) + x -- Scale and translate the x-coordinate
					else
						vertex_temp[i] = self:Scale(btn.vertex[i]) + y -- Scale and translate the y-coordinate
					end
				end

				love.graphics.polygon("fill", vertex_temp) -- Draw the filled polygon using the scaled vertices

				-- Draw BorderHover if enabled in debug mode
				if btn:hasBorderCallback() and self.debugBorderHover and self.updateBorderHover then
					if btn.IsBorderHover then
						love.graphics.setColor(1, 0, 0) -- Set color to red if hovering
					else
						love.graphics.setColor(1, 0, 0, 0.5) -- Set semi-transparent red if not hovering
					end

					-- Set gray color if the layer or button is disabled
					if btn.Disabled then
						love.graphics.setColor(0.5, 0.5, 0.5)
					end

					love.graphics.setLineWidth(self.borderCheckWidth * 2) -- Set line width for the hover border
					love.graphics.polygon("line", vertex_temp) -- Draw the hover border around the polygon
				end

				-- Draw debug lines if debugging is enabled
				if self.debugLine then
					love.graphics.setColor(0.5, 0.5, 0.5, 0.2) -- Set color for debug lines
					if btn.Disabled then
						love.graphics.setColor(0.5, 0.5, 0.5) -- Set color to gray if disabled
					end

					love.graphics.setLineWidth(self.borderCheckWidth) -- Set line width for debug lines
					love.graphics.polygon("line", vertex_temp) -- Draw the polygon outline for debugging

					local tring = love.math.triangulate(vertex_temp) -- Triangulate the polygon for debugging

					love.graphics.setColor(1, 0, 1, 0.5) -- Set color for triangulated lines
					for k, v in pairs(tring) do
						love.graphics.polygon("line", v) -- Draw each triangle from the triangulation
					end

					love.graphics.setColor(1, 0, 0.8) -- Set color for vertex debug output

					-- Print the coordinates of the polygon vertices
					for x = 1, #vertex_temp, 2 do
						love.graphics.print(
							"x:"
								.. math.floor((btn.vertex[x] + btn.x) * 10 ^ 1) / 10 ^ 1
								.. " y:"
								.. math.floor((btn.vertex[x + 1] + btn.y) * 10 ^ 1) / 10 ^ 1,
							vertex_temp[x],
							vertex_temp[x + 1] - 20
						)
					end

					love.graphics.setPointSize(4) -- Set point size for vertex points
					love.graphics.points(vertex_temp) -- Draw the vertex points for debugging
				end

				origin = nil -- Clear the origin variable
			elseif btn.type == 2 then -- Check if the button is a circle
				local r = self:Scale(btn.r) -- Scale the radius of the circle
				love.graphics.circle("fill", x, y, r) -- Draw the filled circle at position (x, y) with radius r

				-- Draw debug lines (white) and borders
				if self.debugLine then
					love.graphics.setColor(1, 1, 1) -- Set color to white for debug lines
					if btn.Disabled then
						love.graphics.setColor(0.5, 0.5, 0.5) -- Set color to gray if the layer or button is disabled
					end

					love.graphics.setLineWidth(2) -- Set line width for the debug outline
					love.graphics.circle("line", x, y, r) -- Draw the outline of the circle
					love.graphics.setColor(1, 0, 0.8) -- Set color for the debug point
					love.graphics.setPointSize(4) -- Set point size for the debug point

					love.graphics.points(x, y) -- Draw a point at the center of the circle for debugging
				end

				-- Draw BorderHover if enabled in debug mode
				if btn:hasBorderCallback() and self.debugBorderHover and self.updateBorderHover then
					if btn.IsBorderHover then
						love.graphics.setColor(1, 0, 0) -- Set color to red if hovering over the border
					elseif not btn.IsBorderHover then
						love.graphics.setColor(0.5, 0, 0, 0.5) -- Set semi-transparent red if not hovering
					end

					-- Set gray color if the layer or button is disabled
					if btn.Disabled then
						love.graphics.setColor(0.5, 0.5, 0.5) -- Set color to gray
					end

					love.graphics.setLineWidth(self.borderCheckWidth * 2) -- Set line width for the hover border
					love.graphics.circle("line", x, y, r) -- Draw the hover border around the circle
				end

				origin = nil -- Clear the origin variable
			end

			love.graphics.setColor(1, 0, 0.8)
			local info = "Absolute postion"

			x = math.floor(x * 10 ^ 1) / 10 ^ 1
			y = math.floor(y * 10 ^ 1) / 10 ^ 1

			info = info .. " X:" .. x .. " Y:" .. y
			--- button info
			if self.debugText then
				love.graphics.print(info, x - 20, y - 80, 0)
			end
			info = " layer: " .. btn.layer

			info = info .. " relative postion"

			info = info .. " X:" .. math.floor(btn.x * 10 ^ 1) / 10 ^ 1 .. " Y:" .. math.floor(btn.y * 10 ^ 1) / 10 ^ 1
			if btn.IsDown[1] then
				info = info .. " ,clck: 1"
			end
			if btn.IsDown[2] then
				info = info .. " ,clck: 2"
			end
			if btn.IsDown[3] then
				info = info .. ", clck: 3"
			end
			if btn.IsHover then
				info = info .. " Hover "
			end
			if btn:hasBorderCallback() and btn.IsBorderHover then
				info = info .. " , Border hover "
			end
			--- button info
			if self.debugText then
				love.graphics.print("Number : " .. key .. " " .. info, x - 20, y - 60)
			end

			::skip::
		end)

		-- Displays debug information in the top-left corner of the screen

		local xm, ym = love.mouse.getPosition() -- Get the current mouse position
		local length = 0 -- Total number of buttons across all layers
		local l, b = 0, 0 -- Counters for layers and buttons
		local layers_text = "" -- String to hold text

		-- Iterate through each layer and count the buttons
		for layer_n, layer in pairs(self.layers) do
			l = l + 1 -- Increment layer count
			for btn_n, btn in pairs(layer) do
				b = b + 1 -- Count buttons in the current layer
			end
			-- Append layer information to the layers_text string
			layers_text = layers_text
				.. ("\n layer #" .. layer_n .. " buttons: " .. b .. " max: " .. self.max_quantity_buttons_in_layer)

			length = length + b -- Add current layer button count to the total
			b = 0 -- Reset button count for the next layer
		end

		-- Calculate mouse position relative to button layers (accounting for scale and translation)
		local dmpXs = (xm / self:getScale() - self:getTranslateX())
		local dmpYs = (ym / self:getScale() - self:getTranslateY())

		-- Prepare the debug text to display
		local text = "Buttons debug data: \n"
			.. "Mouse position in button layers x: "
			.. math.floor(dmpXs * 10 ^ 1)
			.. " y: "
			.. math.floor(dmpYs * 10 ^ 1)
			.. "\n Absolute mouse position x: "
			.. math.floor(xm * 10 ^ 1)
			.. " y: "
			.. math.floor(ym * 10 ^ 1)
			.. "\n FPS: "
			.. love.timer.getFPS()
			.. "\n Hover block state: "
			.. tostring(self.hover_lock)
			.. "\n Main update time: "
			.. (math.floor(self.updateTime * 1000 * 10 ^ 1))
			.. " *10^-3 s"
			.. "\n IsBorderHoverActive: "
			.. tostring(self.updateBorderHover)
		-- Check if there was a hover event in the previous frame
		if self.Prev_hover and self.Prev_hover.layer then
			text = text
				.. "\n Hover in previous frame button: "
				.. self.Prev_hover.id
				.. " layer: "
				.. self.Prev_hover.layer
		else
			text = text .. "\n Previous hover: nil"
		end

		-- Append additional information about scale, translation, and button/layer quantities
		text = text
			.. "\n Scale: "
			.. self.scale
			.. "\n Translation x: "
			.. self.translate.x
			.. " y: "
			.. self.translate.y
			.. "\n Number of layers: "
			.. tostring(#self.layers)
			.. " max: "
			.. self.max_quantity_layers
			.. "\n Total buttons: "
			.. length
			.. "\n"
			.. layers_text

		-- Set color to white and display the debug text
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.print(text, 10, 10)
	end
end

--- main update cycle. Calls hover,unhover, whilehover  body/border
---@param dt at love.update
function buttons:updateMain(dt)
	-- saves time
	local Time
	if self.debug then
		Time = love.timer.getTime()
	end
	-- *
	-- get mouse delta so function can be called only in update and all callbacks can get mouse delta
	local xm = love.mouse.getX()
	local ym = love.mouse.getY()
	local dx = 0
	local dy = 0
	if self.mousePosition.x then
		dy = ym - self.mousePosition.y
		dx = xm - self.mousePosition.x
	end
	dx, dy = dx / self.scale, dy / self.scale --- correct mouse. It will work when buttons has changed translation or/and scale
	self.mousePosition.x = xm
	self.mousePosition.y = ym

	local ButtonsIsPressed = false -- checks if some button pressed on body or border
	for s = 1, 3, 1 do
		ButtonsIsPressed = ButtonsIsPressed or self.IsDownBorderMain[s]
		ButtonsIsPressed = ButtonsIsPressed or self.IsDownMain[s]
	end

	self:mainUpdateCycle(function(self, layer, key, btn)
		btn = self.layers[layer][key]
		if btn and not btn.Disabled then -- Proceed only if the button is not disabled
			-- Check for border hover calls
			if btn:hasBorderCallback() and self.updateBorderHover and btn:isPointInBorder(xm, ym) then
				if not self.hover_lock and not btn.IsBorderHover then -- If the cursor is on the button and hover border state is false
					self.Prev_hover = btn -- Save the currently hovered button
					self.hover_lock = true -- Enable hover lock
					btn.IsBorderHover = true -- Set the border hover state to true
					if btn.BorderHover then
						btn:BorderHover(xm, ym, dx, dy) -- CalIsBorderDownl the hover border function
						self:hover_lock_check(self.layers[layer][key]) -- Check if the button was deleted, then turn off hover lock
					end
				end

				-- If another button is already hovered or this button has a lower layer/position
				-- or this button has hover but mouse on border element of button so it will be BorderHover
				if
					self.hover_lock
					and self.Prev_hover
					and not ButtonsIsPressed
					and (
						self.Prev_hover.layer > layer
						or (self.Prev_hover.layer == layer and self.Prev_hover.id > key)
						or (btn.IsHover and self.Prev_hover.layer == layer and self.Prev_hover.id == key)
					)
				then
					-- Make the previous button unhovered
					if btn.UnHover then
						btn.UnHover(xm, ym, dx, dy)
					end
					if btn.BorderHover then
						btn.BorderHover(xm, ym, dx, dy)
					end
					self.Prev_hover.IsBorderHover = false
					self.Prev_hover.IsHover = false
					self.Prev_hover = nil -- Clear the reference to the previous button
					-- Save the current button as hovered
					self.Prev_hover = btn

					btn.IsBorderHover = true -- Enable border hover state
				end

				if self.layers[layer][key] and btn.WhileBorderHover and btn.IsBorderHover then
					btn:WhileBorderHover(xm, ym, dx, dy) -- Call the while hover border function
					self:hover_lock_check(self.layers[layer][key]) -- Check for deletion
				end
				goto skip_hover_check
			elseif self.updateBorderHover and (btn.IsBorderHover and self.hover_lock and not ButtonsIsPressed) then -- If the button is not under the cursor
				self.hover_lock = false -- Turn off hover lock
				btn.IsBorderHover = false -- Turn off the border hover state

				if self.Prev_hover then
					self.Prev_hover.IsBorderHover = false -- Turn off all hover states for the button
					self.Prev_hover.IsHover = false
					self.Prev_hover = nil -- Clear reference to the last hovered button
				end
				self.Prev_hover_lock_layer = false -- Reset the last hovered button layer

				if btn.BorderUnHover then -- Call unhover function if it exists
					btn:BorderUnHover(xm, ym, dx, dy)
				end
			end

			-- hover update
			if self.layers[layer][key] and btn:isPointInBody(xm, ym) then
				if not btn.IsHover and not self.hover_lock then -- Cursor on button and hover state is false
					if self.Prev_hover then
						self.Prev_hover.IsBorderHover = false -- Turn off previous button hover state
						self.Prev_hover.IsHover = false
						self.Prev_hover = nil -- Clear reference to the previous button
					end
					self.Prev_hover = btn -- Save the current button as hovered
					self.hover_lock = true -- Enable hover lock
					btn.IsHover = true -- Set hover state to true

					if btn.Hover then
						btn:Hover(xm, ym, dx, dy) -- Call the hover function
						self:hover_lock_check(self.layers[layer][key]) -- Check for deletion
					end
				end

				-- Run while hover function
				if self.layers[layer][key] and btn.WhileHover and btn.IsHover then
					btn:WhileHover(xm, ym, dx, dy) -- Call the while hover function
					self:hover_lock_check(self.layers[layer][key]) -- Check for deletion
				end

				-- If some button already hovered but appears some button with a lower layer or position
				if
					self.Prev_hover
					and self.Prev_hover.id
					and not ButtonsIsPressed
					and (
						not btn.IsHover
						and self.hover_lock
						and self.Prev_hover
						and self.Prev_hover.layer
						and (
							self.Prev_hover.layer > layer
							or (self.Prev_hover.layer == layer and self.Prev_hover.id > key)
						)
					)
				then
					self.Prev_hover.IsBorderHover = false -- Make previous button unhovered
					self.Prev_hover.IsHover = false
					self.Prev_hover = nil -- Clear reference to the last button
					self.Prev_hover = btn -- Save current button
					btn.IsHover = true -- Enable hover state
				end
			elseif btn.IsHover and self.hover_lock and not ButtonsIsPressed then -- If the button is not under the cursor
				self.hover_lock = false -- Turn off hover lock
				btn.IsHover = false -- Turn off hover state

				if self.Prev_hover then
					self.Prev_hover.IsBorderHover = false -- Turn off hover state for the previous button
					self.Prev_hover.IsHover = false
					self.Prev_hover = nil -- Clear reference to the last button
				end
				if btn.UnHover then -- Call unhover function if it exists
					btn:UnHover(xm, ym, dx, dy)
				end
			end
			::skip_hover_check::
			if
				self.layers[layer][key]
				and (btn.IsBorderDown[1] or btn.IsBorderDown[2] or btn.IsBorderDown[3])
				and btn.WhileBorderPressed
			then
				btn:WhileBorderPressed(xm, ym, dx, dy) -- Call the while pressed border function
			end

			-- Check if the button is still existing
			if self.layers[layer][key] and (btn.IsDown[1] or btn.IsDown[2] or btn.IsDown[3]) and btn.WhilePressed then
				btn:WhilePressed(xm, ym, dx, dy) -- Call the while pressed function
			end
			if (btn.IsBorderDown[1] or btn.IsBorderDown[2] or btn.IsBorderDown[3]) then
			end
		end
	end)

	-- calculates time for uodateing
	if self.debug then
		self.updateTime = love.timer.getTime() - Time
	end
end

--- func desc
---@param xm  number x mouse
---@param ym number y mouse
function buttons:updateMouseScroll(xm, ym)
	local keys = {}
	for k in pairs(self.layers) do
		table.insert(keys, k)
	end
	local x, y = love.mouse.getPosition()
	table.sort(keys)
	for k, layer in pairs(keys) do
		for key, btn in pairs(self.layers[layer]) do
			if not btn.Disabled then
				if btn.Scroll and btn.IsHover then
					btn:Scroll(xm, ym, self) -- callback click function
					self:hover_lock_check(self.layers[layer][key])
					return 0
				end
			end
		end
	end
end
--- func desc
---@param xm  number x mouse
---@param ym number y mouse
function buttons:updateMouseClick(xm, ym, button, istouch, presses)
	self:mainUpdateCycle(function(buttons, layer, key, btn)
		if not btn.Disabled then
			if btn.IsHover then
				if btn.Click then
					btn:Click(xm, ym, button, istouch, presses) -- callback click function
				end
				self:hover_lock_check(self.layers[layer][key])
				if self.layers[layer][key] then -- if button still exist in list set pressed button on
					btn.IsDown[button] = true
					self.IsDownMain[button] = true
				end
				return 0
			elseif btn.IsBorderHover and btn:hasBorderCallback() then
				if btn.ClickBorder then
					btn:ClickBorder(xm, ym, button, istouch, presses)
				end
				self:hover_lock_check(self.layers[layer][key])
				if self.layers[layer][key] then -- if button still exist in list set pressed button on
					btn.IsBorderDown[button] = true
					self.IsDownBorderMain[button] = true
				end
				return 0
			end
		end
	end)
end
--- func desc
---@param xm  number x mouse
---@param ym number y mouse
function buttons:updateMouseMoves(xm, ym, dx, dy, istouch)
	self:mainUpdateCycle(function(buttons, layer, key, btn)
		if (btn.Disabled == false and not btn.IsBorderHover and btn.WhileMoves) and (btn:isPointInBody(xm, ym)) then
			btn:WhileMoves(xm, ym, dx, dy, istouch)
			self:hover_lock_check(self.layers[layer][key])
			return 0
		end
	end)
end
--- func desc

---@param xm  number x mouse
---@param ym number y mouse
function buttons:updateMouseRelease(xm, ym, button, istouch, presses)
	self:mainUpdateCycle(function(buttons, layer, key, btn)
		if self.layers[layer][key].IsDown[button] then -- mouse button that pressed on button is released
			if btn.Release then
				btn:Release(xm, ym, button, istouch, presses)
			end
			if self.layers[layer][key] == nil then
				self.hover_lock = false
			end
			if self.layers[layer][key] then
				btn.IsDown[button] = false
				self.IsDownMain[button] = false
			end
			return 0
		elseif btn.IsBorderDown[button] then -- mouse button  that pressed on button border is released
			if btn.ReleaseBorder then
				btn:ReleaseBorder(xm, ym, button, istouch, presses)
			end
			self:hover_lock_check(self.layers[layer][key])
			if self.layers[layer][key] then -- if button still exist in list set pressed button on
				btn.IsBorderDown[button] = false
				self.IsDownBorderMain[button] = false
			end
			return 0
		end
	end)
end

-- return x,y + translate x,y or x + translate.x
--- func desc

---@param x number
---@param y number (can be nil)
function buttons:TranslateScaleMosue(xm, ym) -- for x,y coordinates
	local xt = (xm - self:getTranslateX()) / self:getScale()
	local yt = (ym - self:getTranslateY()) / self:getScale()
	return xt, yt
end

-- return x,y + translate x,y or x + translate.x
--- func desc

---@param x number
---@param y number (can be nil)
function buttons:Translate(x, y) -- for x,y coordinates
	local xt = (x + self.translate.x)
	local yt = (y + self.translate.y)
	return xt, yt
end

-- return x,y * scale  or x * scale
--- func desc

---@param x number
---@param y number (can be nil)
function buttons:Scale(x, y) -- for width, height,radius, vertex (only x1,y1,x2,x2 ) ect
	if y ~= nil then
		local xt = x * self.scale
		local yt = y * self.scale
		return xt, yt
	else
		local xt = x * self.scale
		return xt
	end
end

-- changes debug state for buttons:render()
function buttons:toggleDebug()
	if self.debug and self.debugLine and self.debugText and self.debugBorderHover then
		self.debug = false
		self.debugLine = false
		self.debugText = false
		self.debugBorderHover = false
		return 0
	end
	if self.debug and self.debugLine and self.debugBorderHover then
		self.debugText = true
		return 0
	end
	if self.debug and self.debugBorderHover then
		self.debugLine = true
		return 0
	end
	if self.debug then
		self.debugBorderHover = true
		return 0
	end
	if not self.debug then
		self.debug = true
		return 0
	end
end

-- set width range where border will calculated
function buttons:setBorderCheckWidht(x)
	if x < 0 then
		error("ivalid check width ")
	elseif type(x) ~= "number" then
		error("not number")
	end

	self.borderCheckWidth = x
end

-- set width range where border will calculated
function buttons:getBorderCheckWidht(width)
	return self.borderCheckWidth
end
-- set max quantity of layers
function buttons:setMaxQuantityLayers(x)
	if type(x) == "number" and x > 0 then
		self.max_quantity_layers = x
	else
		error("not number or zero")
	end
end
-- get max quantity of layers
function buttons:getMaxQuantityLayers(x)
	return self.max_quantity_layers
end
-- set max quantity of buttons in layer
function buttons:setMaxQuantityButtonsInLayer(x)
	if type(x) == "number" and x > 0 then
		self.max_quantity_buttons_in_layer = x
	else
		error("not number or zero")
	end
	self.max_quantity_buttons_in_layer = x
end

-- get max quantity of buttons in layer
function buttons:getMaxQuantityButtonsInLayer(x)
	return self.max_quantity_buttons_in_layer
end

-- disable all layers
function buttons:disable()
	for k, _ in pairs(self.layers) do
		self:disableLayer(k)
	end
end

-- enable all layers
function buttons:enable()
	for k, _ in pairs(self.layers) do
		self:enableLayer(k)
	end
end

-- disable layer by id clears all states in buttons in layer like hover,click ect
function buttons:disableLayer(number)
	local layer = self.layers[number]
	if layer then
		for k, v in pairs(layer) do
			if layer[k].IsHover or layer[k].IsBorderHover then
				self.hover_lock = false
			end
			layer[k].IsHover = false
			layer[k].IsBorderHover = false

			layer[k].IsDown = { false, false, false }
			layer[k].IsBorderDown = { false, false, false }
			layer[k]:disable()
		end
	else
		error("layer do not exist")
	end
end
-- enable layer by id
function buttons:enableLayer(number)
	local layer = self.layers[number]
	for k, v in pairs(layer) do
		layer[k]:enable()
	end
end
-- gets all existing layers returns table like { 1={btn,btn...},2={btn,btn...}  } 1,2 - lauer ids, btn - some buttons objects
function buttons:getLayers()
	local layers = {}
	for k, v in pairs(self.layers) do
		layers[k] = self.layers[k]
	end
	return layers
end
-- get layer by numbers returns table like {btn,btn...}
function buttons:getLayerByID(id)
	local layers = {}
	if self.layers[id] then
		return self.layers[id]
	else
		error("layer" .. id .. "do not exist")
	end
	return layers
end
-- check if layer exist returns true if exist
function buttons:checkLayer(l)
	if self.layers[l] then
		return true
	end
	return false
end

--- delete lyer by numebr will also change current layer if you deleted curent layer.
function buttons:delLayer(number)
	if type(number == "number") then
		assert(self.layers[number], "Layer: " .. number .. " do not exist or alredy deleted")

		print(self.layers[1])
		print(self.layers[5])
		local count = 0
		for k, v in pairs(self.layers) do
			count = count + 1
			if count >= 2 then
				break
			end
		end

		if count == 1 then
			error("You can`t delete last layer")
		end

		self.layers[number] = nil

		if self.Prev_hover and self.layers[self.Prev_hover.id] then
			self.Prev_hover = nil
		end

		if self.current_layer == number then
			self.current_layer = false
			for a, v in pairs(self.layers) do
				self.current_layer = a
				if a then
					break
				end
			end
		end
	elseif number == nil then
		error("Layer nil")
	else
		error("invalid layer " .. number)
	end
end

--get number of current layer
function buttons:getCurrentLayerID()
	return self.current_layer
end
--Sets Layer for creating also creates layer if it do not exist
function buttons:setLayer(number)
	local count = 1
	for k, v in pairs(self.layers) do
		count = count + 1
	end
	if count > self.max_quantity_layers then
		error("Too much layers current:" .. count .. " max:" .. self.max_quantity_layers)
	end
	if type(number == "number") then
		self.current_layer = number
	elseif number == nil then
		error("Layer nil ")
	else
		error("invalid layer " .. number)
	end
	if not self.layers[number] then
		self.layers[number] = {}
	end
end

function buttons:setTranslate(x, y)
	if (type(x) ~= "number") and (type(y) ~= "number") then
		error("not number value")
	end
	self.translate.x = x
	self.translate.y = y
end
function buttons:getTranslate()
	return self.translate.x, self.translate.y
end
function buttons:getTranslateX()
	return self.translate.x
end
function buttons:getTranslateY()
	return self.translate.y
end
function buttons:setTranslateX(x)
	if type(x) ~= "number" then
		error("not number value")
	end
	self.translate.x = x
end
function buttons:setTranslateY(y)
	if type(y) ~= "number" then
		error("not number value")
	end
	self.translate.y = y
end
function buttons:setScale(x)
	if x <= 0 then
		error("scale can't be 0 ")
	end
	self.scale = x
end
function buttons:getScale()
	return self.scale
end

-- toggle hover border
function buttons.enableBorderHover()
	buttons.updateBorderHover = true
end
function buttons.disableBorderHover()
	buttons.updateBorderHover = false
end
function buttons.getBorderHoverState()
	return buttons.updateBorderHover
end
function buttons.setBorderHoverState(x)
	buttons.updateBorderHover = not not x
end
-- Calls function  and gives to it (layer_k,b_key,button_object ) in order by id lyers and id buttons
function buttons:mainUpdateCycle(func)
	local keys = {}
	for layer_k in pairs(self.layers) do
		table.insert(keys, layer_k)
	end
	table.sort(keys)

	for _, layer_k in pairs(keys) do
		local Btns_keys = {}
		for btn_k, __ in pairs(self.layers[layer_k]) do
			table.insert(Btns_keys, btn_k)
		end
		table.sort(Btns_keys)
		--sort buttons inside layer
		for ___, key in pairs(Btns_keys) do
			func(self, layer_k, key, self.layers[layer_k][key])
		end
	end
end
function buttons:mainUpdateCycleReversed(func)
	local keys = {}
	for layer_k in pairs(self.layers) do
		table.insert(keys, layer_k)
	end

	table.sort(keys, function(a, b)
		return a > b
	end)
	for _, layer_k in pairs(keys) do
		local Btns_keys = {}
		for btn_k, __ in pairs(self.layers[layer_k]) do
			table.insert(Btns_keys, btn_k)
		end
		table.sort(Btns_keys, function(a, b)
			return a > b
		end)

		--sort buttons inside layer
		for ___, key in pairs(Btns_keys) do
			func(self, layer_k, key, self.layers[layer_k][key])
		end
	end
end
-- Calls function  and gives to it (layer_k,b_key,button_object ) in random order
function buttons:mainUpdateCycleUnsorted(func)
	for layer_k, layer in pairs(self.layers) do
		--sort buttons inside layer
		for key, button in pairs(layer) do
			func(self, layer_k, key, self.layers[layer_k][key])
		end
	end
end
-----------------------
-- service methods
-----------------------
--Creates new id
function buttons:idCreate()
	local count = 1
	-- counter from  .max_quantity_buttons_in_layer
	for i = 1, math.huge, 1 do
		if self.layers[self.current_layer][i] == nil then
			return i
		else
			count = count + 1
			if count > self.max_quantity_buttons_in_layer then
				error("max_quantity_buttons_in_layer:" .. count .. " Max exceed:" .. self.max_quantity_buttons_in_layer)
			end
		end
	end
	error("max quantity buttons in layer overflow")
end
--Checks if value do not exist sets hover lock to false to prevent blocking by deleted button
function buttons:hover_lock_check(var)
	if var == nil then
		self.hover_lock = false
	end
end
-- Base table for all button objects
function buttons:GetBtnBase(x, y, id, type, adds)
	local t = adds
	t.IsBorderDown = {
		[1] = false,
		[2] = false,
		[3] = false,
	}
	t.IsDown = {
		[1] = false,
		[2] = false,
		[3] = false,
	}
	t.Disabled = false
	t.IsHover = false
	t.IsBorderHover = false
	t.layer = self.current_layer
	t.id = id
	t.x = x
	t.y = y
	t.type = type
	setmetatable(t, {
		__index = function(table, key)
			local value = self.methods[key]
			if value then
				return value
			else
				return nil
			end
		end,
	})
	return t
end

------------------------
---- All function in buttons.methods avalivble for every button
-----------------------

buttons.methods = {}
buttons.methods.buttons = buttons
--delete button
function buttons.methods:del()
	if self.buttons.layers[self.layer][self.id] then
		if
			self.buttons.Prev_hover
			and self.buttons.Prev_hover.id == self.id
			and self.buttons.Prev_hover.layer == self.layer
		then
			self.buttons.Prev_hover = nil
		end

		if self.IsHover then
			if self.UnHover then
				local xm, ym = love.mouse.getPosition()
				self:UnHover(xm, ym, 0, 0)
			end
			buttons.hover_lock = false
		elseif self.IsBorderHover then
			if self.BorderUnHover then
				local xm, ym = love.mouse.getPosition()
				self:BorderUnHover(xm, ym, 0, 0)
			end
			buttons.hover_lock = false
		end

		self.buttons.layers[self.layer][self.id] = nil

		return 0
	else
		error("button already deleted")
	end
end
---------------------
-- Check is button has some type of fucntion
---------------------
-- is button has functions that realted to border :bool
---@return boolean
function buttons.methods:hasBorderCallback()
	if
		self.BorderUnHover
		or self.WhileBorderHover
		or self.BorderHover
		or self.ClickBorder
		or self.WhileBorderPressed
		or self.ReleaseBorder
	then
		return true
	else
		return false
	end
end
-- is button has funcs like hover unhover clicks that related to button body :bool
---@return boolean
function buttons.methods:hasBodyCallback()
	if
		self.UnHover
		or self.WhileHover
		or self.Hover
		or self.Hover
		or self.Click
		or self.WhilePressed
		or self.Release
		or self.Scroll
	then
		return true
	else
		return false
	end -- while pressed
end

---------------------
-- Setting callbacks
---------------------
-- callback that calls every fps while mouse pressed even if cursor leave the button
---@param WhilePressed function
function buttons.methods:setWhilePressed(WhilePressed)
	if type(WhilePressed) == "function" then
		self.WhilePressed = WhilePressed
	else
		error("invalid function")
	end
end
-- callback that calls every fps while mouse pressed border even if cursor leave the button
---@param WhilePressed function
function buttons.methods:setWhileBorderPressed(WhileBorderPressed)
	if type(WhileBorderPressed) == "function" then
		self.WhileBorderPressed = WhileBorderPressed
	else
		error("invalid function")
	end
end
-- callback that calls every "mouse moves" event
---@param WhilePressed function
function buttons.methods:setWhileMoves(WhileMoves)
	if type(WhileMoves) == "function" then
		self.WhileMoves = WhileMoves
	else
		error("invalid function")
	end
end
--- callback that calls once when mouse enters border range
---@param WhilePressed function
function buttons.methods:setBorderHover(BorderHover)
	if type(BorderHover) == "function" then
		self.BorderHover = BorderHover
	else
		error("invalid function")
	end
end
--- callback that calls once when mouse leaves border range
---@param WhilePressed function
function buttons.methods:setBorderUnHover(BorderHover)
	if type(BorderHover) == "function" then
		self.BorderUnHover = BorderHover
	else
		error("invalid function")
	end
end
--- callback that calls once when mouse clicks on border
---@param WhilePressed function
function buttons.methods:setClickBorder(ClcikBorder)
	if type(ClcikBorder) == "function" then
		self.ClickBorder = ClcikBorder
	else
		error("invalid function")
	end
end
--- callback that calls once when mouse leaves border range
---@param WhilePressed function
function buttons.methods:setWhileBorderHover(BorderHover)
	if type(BorderHover) == "function" then
		self.WhileBorderHover = BorderHover
	else
		error("invalid function")
	end
end
--- callback that calls once when button clicked
---@param WhilePressed function
function buttons.methods:setClick(func)
	if type(func) == "function" then
		self.Click = func
	else
		error("invalid function")
	end
end
--- callback that calls once when released any mouse button that pressed on button
---@param WhilePressed function
function buttons.methods:setRelease(func)
	if type(func) == "function" then
		self.Release = func
	else
		error("invalid function")
	end
end
--- callback that calls once when mouse released border
---@param WhilePressed function
function buttons.methods:setReleaseBorder(func)
	if type(func) == "function" then
		self.ReleaseBorder = func
	else
		error("invalid function")
	end
end
--- callback that calls once when mouse enters buttonn
---@param WhilePressed function
function buttons.methods:setHover(func)
	if type(func) == "function" then
		self.Hover = func
	else
		error("invalid function")
	end
end
--- callback that calls every fps while mouse in buttonn
---@param WhilePressed function
function buttons.methods:setWhileHover(func)
	if type(func) == "function" then
		self.WhileHover = func
	else
		error("invalid function")
	end
end
--- callback that calls once when mouse leaves buttonn
---@param WhilePressed function
function buttons.methods:setUnHover(func)
	if type(func) == "function" then
		self.UnHover = func
	else
		error("invalid function")
	end
end
--- callback that calls whent mouse scrolled
---@param WhilePressed function
function buttons.methods:setScroll(func)
	if type(func) == "function" then
		self.Scroll = func
	else
		error("invalid function")
	end
end

---------------------
-- Removing callbacks
---------------------
---Remove callback forWhilePressed
function buttons.methods:removeWhilePressed()
	self.WhilePressed = nil
end

---Remove callback forWhileBorderPressed
function buttons.methods:removeWhileBorderPressed()
	self.WhileBorderPressed = nil
end

---Remove callback forWhileMoves
function buttons.methods:removeWhileMoves()
	self.WhileMoves = nil
end

---Remove callback forBorderHover
function buttons.methods:removeBorderHover()
	self.BorderHover = nil
end

---Remove callback forBorderUnHover
function buttons.methods:removeBorderUnHover()
	self.BorderUnHover = nil
end

---Remove callback forClickBorder
function buttons.methods:removeClickBorder()
	self.ClickBorder = nil
end

---Remove callback forWhileBorderHover
function buttons.methods:removeWhileBorderHover()
	self.WhileBorderHover = nil
end

---Remove callback forClick
function buttons.methods:removeClick()
	self.Click = nil
end

---Remove callback forRelease
function buttons.methods:removeRelease()
	self.Release = nil
end

---Remove callback forReleaseBorder
function buttons.methods:removeReleaseBorder()
	self.ReleaseBorder = nil
end

---Remove callback forHover
function buttons.methods:removeHover()
	self.Hover = nil
end

---Remove callback forWhileHover
function buttons.methods:removeWhileHover()
	self.WhileHover = nil
end

---Remove callback forUnHover
function buttons.methods:removeUnHover()
	self.UnHover = nil
end

---Remove callback forScroll
function buttons.methods:removeScroll()
	self.Scroll = nil
end

---------------------
-- Get some parametr from button
---------------------

--check return button hover state :bool
---@return boolean
function buttons.methods:isHover()
	return self.IsHover
end
--check return button hover border state :bool
---@return boolean
function buttons.methods:isBorderHover()
	return self.IsBorderHover
end
-- get current mouse buttons that pressed on button  :table{1=state,...}
---@return boolean
function buttons.methods:isPressed()
	return self.IsDown
end
-- get current mouse buttons that pressed on button border :table{1=state,...}
---@return boolean
function buttons.methods:isBorderPressed()
	return self.IsBorderDown
end
-- Get the type of the object (  1 -rectangle, or 2- circle,3 - polygon)
---@return boolean
function buttons.methods:getType()
	return self.type -- Return the object's type
end
-- Get the numebr of layer of the button :number
---@return boolean
function buttons.methods:getLayer()
	return self.layer -- Return the layer of the button
end
-- Get id of the button :number
---@return boolean
function buttons.methods:getID()
	return self.id -- Return the layer of the button
end
---------------------
-- Position,size,vertex,radius change
---------------------
-- Get the position (x, y) of the object
---@return x,y
function buttons.methods:getPosition()
	return self.x, self.y -- Return both x and y coordinates
end

-- Set the position (x, y) of the object
--- func desc
---@param number x
---@param y
---@return void
function buttons.methods:setPosition(x, y)
	self.x = x -- Set the x-coordinate
	self.y = y -- Set the y-coordinate
end

-- Set the x-coordinate of the object
--- func desc
---@param number x
---@return void
function buttons.methods:setX(x)
	self.x = x -- Set the x-coordinate
end

-- Get the x-coordinate of the object
---@return numberx
function buttons.methods:getX()
	return self.x -- Return the x-coordinate
end

-- Set the y-coordinate of the object
---@param y
---@return void
function buttons.methods:setY(y)
	self.y = y -- Set the y-coordinate
end

-- Get the y-coordinate of the object
---@return y
function buttons.methods:getY()
	return self.y -- Return the y-coordinate
end

-- Get the vertices of the polygon :table{1,3,4,5,6,213,....}
---@return vertex {1,2,3,45,6,}
function buttons.methods:getVertex()
	if self.type == 3 then -- Check if the object is a polygon
		return self.vertex -- Return the vertices
	else
		error("Object is not polygon") -- Error if not a polygon
	end
end

-- Set the vertices of the polygon
--- func desc
---@param vertex {1,2,3,4,5,6....}
function buttons.methods:setVertex(vertex)
	if self.type == 3 then -- Check if the object is a polygon
		self.vertex = vertex -- Set the vertices
	else
		error("Object is not polygon") -- Error if not a polygon
	end
end

-- Get the size of the rectangle
---@return weight,height
function buttons.methods:getSize()
	if self.type == 1 then -- If the button is a rectangle
		return self.w, self.h
	else
		error("Object is not rectangle") -- Error if not a rectangle
	end
end
-- Set the size of the rectangle
---@param w
---@param h
---@return void
function buttons.methods:setSize(w, h)
	if h < 0 and w < 0 then -- Ensure the height is greater than 0
		error("Zero value")
	end

	if self.type == 1 then -- If the button is a rectangle
		self.w, self.h = w, h
	else
		error("Object is not rectangle") -- Error if not a rectangle
	end
end
-- Get the height of the rectangle
---@return height
function buttons.methods:getHeight()
	if self.type == 1 then -- If the button is a rectangle
		return self.h
	else
		error("Object is not rectangle") -- Error if not a rectangle
	end
end

-- Set the height of the rectangle
---@param h
---@return void
function buttons.methods:setHeight(h)
	if h < 0 then -- Ensure the height is greater than 0
		error("Zero value")
	end

	if self.type == 1 then -- If the button is a rectangle
		self.h = h
	else
		error("Object is not rectangle") -- Error if not a rectangle
	end
end

-- Get the width of the rectangle
---@return width
function buttons.methods:getWidth()
	if self.type == 1 then -- If the button is a rectangle
		return self.w
	else
		error("Object is not rectangle") -- Error if not a rectangle
	end
end

-- Set the width of the rectangle
--- func desc
---@param w
---@return void
function buttons.methods:setWidth(w)
	if w < 0 then -- Ensure the width is greater than 0
		error("Zero value")
	end

	if self.type == 1 then -- If the button is a rectangle
		self.w = w
	else
		error("Object is not rectangle") -- Error if not a rectangle
	end
end

-- Get the radius of the circle
---@return raidus
function buttons.methods:getRadius()
	if self.type == 2 then -- If the button is a circle
		return self.r
	else
		error("Object is not a circle") -- Error if not a circle
	end
end

-- Set the radius of the circle self
---@param r self
---@return void
function buttons.methods:setRadius(r)
	if r < 0 then -- Ensure the radius is greater than 0
		error("Zero value")
	end

	if self.type == 2 then -- If the button is a circle
		self.r = r
	else
		error("Object is not a circle") -- Error if not a circle
	end
end

-- Disable the button
---@return void
function buttons.methods:disable()
	if
		self.buttons.Prev_hover
		and self.id == self.buttons.Prev_hover.id
		and self.layer == self.buttons.Prev_hover.layer
	then -- If the button is the one being hovered
		self.buttons.hover_lock = false -- Disable hover lock
		self.buttons.Prev_hover = nil -- Clear previous hover
	end
	self.IsHover = false -- Disable hover
	self.IsBorderHover = false -- Disable border hover
	self.Disabled = true -- Disable the button
end
--- func desc Enable the button
---@return void
function buttons.methods:enable()
	if self.IsHover or self.IsBorderHover then -- If the button was previously hovered
		self.hover_lock = false -- Disable hover lock
	end
	self.Disabled = false -- Enable the button
end
---------------------
-- Check is point in the button or in border
-- if notScaleTranslate = nil/false will scale and transform xm and ym
---------------------
--- func desc checls if point xm,ym is in button border.
---@param number xm number
---@param ym number
---@param notScaleTranslate if true then gived point will not notScaled and translated
---@return boolean
function buttons.methods:isPointInBorder(xm, ym, notScaleTranslate)
	if
		(self.type == 2 and self:pointInCircleBorder(xm, ym, notScaleTranslate))
		or (self.type == 1 and self:pointInRectBorder(xm, ym, notScaleTranslate))
		or (self.type == 3 and self:pointInPolygonBorder(xm, ym, notScaleTranslate))
	then
		return true
	end
end
--- func desc checks if point xm,ym is in button.
---@param number xm number
---@param ym number
---@param notScaleTranslate if true then gived point will not notScaled and translated
---@return boolean
function buttons.methods:isPointInBody(xm, ym, notScaleTranslate)
	if
		(self.type == 1 and self:pointInRect(xm, ym, notScaleTranslate))
		or (self.type == 3 and self:pointInPolygon(xm, ym, notScaleTranslate))
		or (self.type == 2 and self:pointInCircle(xm, ym, notScaleTranslate))
	then
		return true
	end
end

-----------------------------------
-- Checks is xm,ym in button. Do not checking type
-- if notScaleTranslate = nil/false will scale and transform xm and ym
-----------------------------------
--- True if point in rectangel
---@param number xm number
---@param ym number
---@param notScaleTranslate bool
---@return boolean
function buttons.methods:pointInRect(xm, ym, notScaleTranslate)
	local x, y = self.x, self.y
	local w, h = self.w, self.h
	if not notScaleTranslate then
		x, y = self.buttons:Translate(self.buttons:Scale(x, y)) -- add translate and scale position

		w, h = self.buttons:Scale(w, h) -- scale size
	end

	return (xm >= x and ym >= y and ym <= y + h and xm <= x + w)
end
--- True if point in rectangel border
---@param number xm number
---@param ym number
---@param notScaleTranslate bool
function buttons.methods:pointInRectBorder(xm, ym, notScaleTranslate)
	local big_x, big_y = self.x - self.buttons.borderCheckWidth, self.y - self.buttons.borderCheckWidth -- add translate and scale position
	local big_w, big_h = self.w + self.buttons.borderCheckWidth * 2, self.h + self.buttons.borderCheckWidth * 2 -- scale size
	local small_w, small_h = self.w - self.buttons.borderCheckWidth * 2, self.h - self.buttons.borderCheckWidth * 2 -- scale size
	local small_x, small_y =
		self.buttons:Scale(self.x + self.buttons.borderCheckWidth, self.y + self.buttons.borderCheckWidth) -- add translate and scale position

	if not notScaleTranslate then
		big_x, big_y = self.buttons:Translate(self.buttons:Scale(big_x, big_y))
		big_w, big_h = self.buttons:Scale(big_w, big_h)
		small_x, small_y = self.buttons:Translate(small_x, small_y)
		small_w, small_h = self.buttons:Scale(small_w, small_h)
	end

	return (xm >= big_x and ym >= big_y and ym <= big_y + big_h and xm <= big_x + big_w)
		and not (xm >= small_x and ym >= small_y and ym <= small_y + small_h and xm <= small_x + small_w)
end
--- True if point in polygon border
---@param number xm number
---@param ym number
---@param notScaleTranslate bool
---@return boolean
function buttons.methods:pointInPolygonBorder(xm, ym, notScaleTranslate)
	if #self.vertex % 2 == 1 or #self.vertex < 6 then
		error("vertex error")
	end

	local x, y = self.x, self.y
	local triangles = {}
	if not notScaleTranslate then
		x, y = self.buttons:Translate(self.buttons:Scale(x, y))

		for k, v in pairs(self.vertex) do
			table.insert(triangles, self.buttons:Scale(v))
		end
	else
		for k, v in pairs(self.vertex) do
			table.insert(triangles, v)
		end
	end

	return self.math.inPolygonBorder(xm, ym, x, y, triangles, self.buttons.borderCheckWidth)
end

--- True if point in polygon
---@param number xm number
---@param ym number
---@param notScaleTranslate bool
---@return boolean
function buttons.methods:pointInPolygon(xm, ym, notScaleTranslate)
	if #self.vertex % 2 == 1 then
		error("veretx error")
	end
	local triangles = {}
	local x, y
	if not notScaleTranslate then
		for i = 1, #self.vertex, 1 do
			triangles[i] = self.buttons:Scale(self.vertex[i])
		end
		x, y = self.buttons:Translate(self.buttons:Scale(self.x, self.y))
	else
		for i = 1, #self.vertex, 1 do
			triangles[i] = self.vertex[i]
		end
		x, y = self.x, self.y
	end

	triangles = love.math.triangulate(triangles)

	for k, v in pairs(triangles) do
		if self.math.pointInTriangle(xm - x, ym - y, v) then
			return true
		end
	end
	return false
end
--- func desc
---@param number xm number
---@param ym number
---@param notScaleTranslate bool
---@return boolean
function buttons.methods:pointInCircle(xm, ym, notScaleTranslate)
	local x, y = self.x, self.y
	local radius = self.r
	if not notScaleTranslate then
		x, y = self.buttons:Translate(self.buttons:Scale(x, y))
		radius = self.buttons:Scale(radius)
	end
	local triangles = {}

	return self.math.pointInCircle(xm, ym, x, y, radius)
end
--- func desc
---@param number xm number
---@param ym number
---@param notScaleTranslate bool
---@return boolean
function buttons.methods:pointInCircleBorder(xm, ym, notScaleTranslate)
	local radius = self.r

	local x, y = self.x, self.y
	if not notScaleTranslate then
		x, y = self.buttons:Translate(self.buttons:Scale(x, y))
		radius = self.buttons:Scale(radius)
	end
	local triangles = {}

	return (
		self.math.pointInCircle(xm, ym, x, y, radius + self.buttons.borderCheckWidth)
		and not self.math.pointInCircle(xm, ym, x, y, radius - self.buttons.borderCheckWidth)
	)
end

buttons.methods.math = {}

function buttons.methods.math.rotate_point(px, py, cx, cy, angle)
	local radians = math.rad(angle)
	-- Переносим точку относительно центра
	local translated_x = px
	local translated_y = py
	-- Вычисляем новые координаты после вращения
	local rotated_x = translated_x * math.cos(radians) - translated_y * math.sin(radians)
	local rotated_y = translated_x * math.sin(radians) + translated_y * math.cos(radians)
	-- Возвращаем точку на место относительно центра
	return rotated_x + cx, rotated_y + cy
end
function buttons.methods.math.rotate_polygon(points, cx, cy, angle)
	local rotated_points = {}

	-- Проходим по массиву точек, рассматривая их как пары (x, y)
	for i = 1, #points, 2 do
		local x, y = points[i], points[i + 1]
		local new_x, new_y = buttons.methods.math.rotate_point(x, y, cx, cy, angle)

		-- Добавляем новые координаты в массив
		table.insert(rotated_points, new_x)
		table.insert(rotated_points, new_y)
	end

	return rotated_points
end
function buttons.methods.math.line_lenght(p1, p2)
	return math.sqrt((p1.x - p2.x) ^ 2 + (p1.y - p2.y) ^ 2)
end
function buttons.methods.math.squared_distance(x1, y1, x2, y2)
	return (x1 - x2) ^ 2 + (y1 - y2) ^ 2
end

function buttons.methods.math.pointInCircle(xm, ym, x, y, radius)
	j = xm - x
	k = ym - y
	j = j * j
	k = k * k

	if math.sqrt(j + k) < radius then
		return true
	else
		return false
	end
end

function buttons.methods.math.triangleArea(x1, y1, x2, y2, x3, y3)
	return math.abs((x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)) / 2)
end

function buttons.methods.math.DpointSegment(px, py, ax, ay, bx, by)
	-- Сначала вычисляем длину отрезка AB
	local ab_squared = buttons.methods.math.squared_distance(ax, ay, bx, by)

	-- Если A и B совпадают, расстояние от точки P до A (или B)
	if ab_squared == 0 then
		return math.sqrt(buttons.methods.math.squared_distance(px, py, ax, ay))
	end

	-- Вычисляем t, проекцию точки P на отрезок AB
	local t = ((px - ax) * (bx - ax) + (py - ay) * (by - ay)) / ab_squared

	-- Проверяем, лежит ли проекция внутри отрезка
	if t < 0 then
		-- Проекция находится за пределами A, используем A
		return math.sqrt(buttons.methods.math.squared_distance(px, py, ax, ay))
	elseif t > 1 then
		-- Проекция находится за пределами B, используем B
		return math.sqrt(buttons.methods.math.squared_distance(px, py, bx, by))
	end

	-- Если проекция находится на отрезке, вычисляем перпендикулярное расстояние
	local nearest_x = ax + t * (bx - ax)
	local nearest_y = ay + t * (by - ay)

	return math.sqrt(buttons.methods.math.squared_distance(px, py, nearest_x, nearest_y))
end

function buttons.methods.math.inPolygonBorder(xm, ym, x, y, triangles, distance_origin)
	pm = {
		x = xm,
		y = ym,
	}
	for i = 2, #triangles, 2 do
		local p1 = {}
		local p2 = {}
		p1X = triangles[i - 1] + x
		p1Y = triangles[i] + y

		if triangles[i + 2] then
			p2X = triangles[i + 1] + x
			p2Y = triangles[i + 2] + y
		else
			p2X = triangles[1] + x
			p2Y = triangles[2] + y
		end

		local distance = buttons.methods.math.DpointSegment(pm.x, pm.y, p1X, p1Y, p2X, p2Y)

		if distance < distance_origin then
			return true
		end
	end
	return false
end

function buttons.methods.math.pointInTriangle(px, py, v)
	ax = v[1]
	ay = v[2]
	bx = v[3]
	by = v[4]
	cx = v[5]
	cy = v[6]
	-- Площадь треугольника ABC
	local areaABC = buttons.methods.math.triangleArea(ax, ay, bx, by, cx, cy)
	-- Площади треугольников PAB, PBC, PCA
	local areaPAB = buttons.methods.math.triangleArea(px, py, ax, ay, bx, by)
	local areaPBC = buttons.methods.math.triangleArea(px, py, bx, by, cx, cy)
	local areaPCA = buttons.methods.math.triangleArea(px, py, cx, cy, ax, ay)
	-- Проверка: сумма площадей треугольников PAB, PBC, PCA должна быть равна площади ABC
	return math.abs(areaPAB + areaPBC + areaPCA - areaABC) < 1e-6
end

return buttons
