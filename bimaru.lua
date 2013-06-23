--[[
	Copyright (c) 2013 Bastien Clément

	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the
	"Software"), to deal in the Software without restriction, including
	without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to
	permit persons to whom the Software is furnished to do so, subject to
	the following conditions:

	The above copyright notice and this permission notice shall be included
	in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
	CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
	TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

	---

	Usage:  lua bimaru.lua  <rows>  <cols>  [intructions...]  [boats...]  [opts...]
	
	<rows> and <cols> are a sequence of numbers describing how many ship cells
	should be on this row / col. The separator can be any non-numeric symbol.
	
	[instructions...] are used to initialize the board
		Syntax:
			<row>:<col>={what}
		
		{what} can be:
			w, W, ~  |  a water cell
			b, B, #  |  a generic boat cell
			o, O, @  |  a one-square boat (submarine)
			<        |  the left-end of a boat
			>        |  the right-end of a boat
			v        |  the bottom-end of a boat
			^        |  the top-end of a boat
	
	[boats...] defines how many boats must be used for solving the board
		Syntax:
			<length>=<count>
		
		Examples:
			4=1  --> You must have exactly 1 boat 4 squares long
			2=3  --> You must have exactly 3 boats 2 squares long
		
	[opts...] changes the solver behavior.
		Available options:
			quick  |  Aborts after the first solution is found.
	
	---
	
	Example input grid:
		 ------------------------------ 
		|                   ~     ~    | 3
		|                              | 2
		|                              | 1
		|                              | 2
		|                              | 2
		|                              | 0
		|<#>                           | 1
		|                              | 1
		|                              | 7
		|                              | 1
		 ------------------------------ 
		  4  0  2  1  2  0  5  0  5  1
		  
	Command line:
		lua bimaru.lua 3,2,1,2,2,0,1,1,7,1 4,0,2,1,2,0,5,0,5,1  1:7=w 1:9=w 7:1=o  1=4 2=3 3=2 4=1
	
	In this case, the board will contains the following boats:
		4x <#>
		3x <# #>
		2x <# # #>
		1x <# # # #>
]]

-- SETUP -----------------------------------------------------------------------

local rowCounts, colCounts = {}, {}

for c in select(1, ...):gmatch("(%d+)") do
	local count = tonumber(c)
	rowCounts[#rowCounts + 1] = count
end

for c in select(2, ...):gmatch("(%d+)") do
	local count = tonumber(c)
	colCounts[#colCounts + 1] = count
end

local boardW = #colCounts
local boardH = #rowCounts

if boardW < 1 or boardH < 1 then
	print("Invalid board size:", boardW, boardH)
	return
end

local FULL_SOLVE = true

local grid = {}
for i = 1, boardH do
	grid[i] = {}
	for j = 1, boardW do
		grid[i][j] = { type = "UNKNOWN", locked = false }
	end
end

local CHECK_BOATS = false
local boats_available = {}

local cmds = {
	quick = function() FULL_SOLVE = false end
}

local change_made = true
local function set_cell(r, c, type)
	local row = grid[r]
	if not row then return end
	
	local cell = row[c]
	if not cell then return end
	
	if cell.type == type then return end
	if cell.locked then return end
	
	cell.type = type
	cell.locked = true
	
	change_made = true
end

for i = 3, select("#", ...) do
	local arg = select(i, ...)
	local value = nil
	
	local split_at = arg:find("=")
	if split_at then
		value = arg:sub(split_at + 1)
		arg = arg:sub(1, split_at - 1)
	end
	
	if cmds[arg] then
		cmds[arg](value)
	else
		if not value then
			print("Invalid instruction:", arg)
			return
		end
	
		split_at = arg:find(":")
		if not split_at then
			CHECK_BOATS = true
			boats_available[tonumber(arg)] = tonumber(value)
		else
			local r = tonumber(arg:sub(1, split_at - 1))
			local c = tonumber(arg:sub(split_at + 1))
	
			if r > boardH or r < 1 or c > boardW or c < 1 then
				print("Invalid cell:", cell)
				return
			end
	
			if value == "b" or value == "B" or value == "#" then
				set_cell(r, c, "BOAT")
			elseif value == "w" or value == "W" or value == "~" then
				set_cell(r, c, "WATER")
			elseif value == "o" or value == "O" then
				set_cell(r, c, "BOAT")
				set_cell(r-1, c, "WATER")
				set_cell(r+1, c, "WATER")
				set_cell(r, c-1, "WATER")
				set_cell(r, c+1, "WATER")
			elseif value == "<" then
				set_cell(r, c, "BOAT")
				set_cell(r, c+1, "BOAT")
			elseif value == ">" then
				set_cell(r, c, "BOAT")
				set_cell(r, c-1, "BOAT")
			elseif value == "v" then
				set_cell(r, c, "BOAT")
				set_cell(r-1, c, "BOAT")
			elseif value == "^" or value == "Λ" then
				set_cell(r, c, "BOAT")
				set_cell(r+1, c, "BOAT")
			end
		end
	end
end

local function count_boats()
	local boats = {}
	local boats_grid = {}
	
	for r = 1, boardH do
		boats_grid[r] = {}
		for c = 1, boardW do
			if grid[r][c].type == "BOAT" then
				if boats_grid[r][c-1] then
					boats_grid[r][c] = boats_grid[r][c-1]
				elseif boats_grid[r-1] and boats_grid[r-1][c] then
					boats_grid[r][c] = boats_grid[r-1][c]
				else
					boats_grid[r][c] = { length = 0 }
					boats[#boats + 1] = boats_grid[r][c]
				end
				
				local boat_cell = boats_grid[r][c];
				boat_cell.length = boat_cell.length + 1
			end
		end
	end
	
	local boat_length = {}
	local max_length = 0
	for _, b in ipairs(boats) do
		if b.length > max_length then
			max_length = b.length
		end
		if not boat_length[b.length] then
			boat_length[b.length] = 1
		else
			boat_length[b.length] = boat_length[b.length] + 1
		end
	end
	
	return boat_length, max_length
end

local function cell_is(r, c, type)
	local row = grid[r]
	if not row then return type == "WATER" end
	
	local cell = row[c]
	if not cell then return type == "WATER" end
	
	if cell.type == type then
		return true
	else
		return false
	end
end

local function print_grid()
	local done = true
	
	local border = " " .. ("-"):rep(boardW * 3) .. " "
	print(border)
	for r = 1, boardH do
		io.write("|")
		for c = 1, boardW do
			local type = grid[r][c].type
			if type == "WATER" then
				io.write(" ~ ")
			elseif type == "BOAT" then
				if cell_is(r-1, c, "BOAT") and cell_is(r+1, c, "WATER") then
					io.write(" V ")
				elseif cell_is(r+1, c, "BOAT") and cell_is(r-1, c, "WATER") then
					io.write(" Λ ")
				elseif cell_is(r, c+1, "BOAT") and cell_is(r, c-1, "WATER") then
					io.write(" <#")
				elseif cell_is(r, c-1, "BOAT") and cell_is(r, c+1, "WATER") then
					io.write("#> ")
				elseif cell_is(r-1, c, "WATER") and cell_is(r+1, c, "WATER") and cell_is(r, c-1, "WATER") and cell_is(r, c+1, "WATER") then
					io.write("<#>")
				else
					io.write(" # ")
				end
			else
				done = false
				io.write("   ")
			end
		end
		print("| " .. rowCounts[r])
	end
	print(border)
	io.write(" ")
	for c = 1, boardW do
		local count = colCounts[c]
		if count > 9 then
			io.write(" " .. count)
		else
			io.write(" " .. count .. " ")
		end
	end
	
	if done then
		local boat_length, max_length = count_boats()
		
		print("\n")
		for l = 1, max_length do
			c = boat_length[l]
			if c then
				io.write("  ", c, "  ")
				local boat
				if l > 1 then
					boat = "<#" .. ("#"):rep(l-2) .. "#>"
				else
					boat = "<#>"
				end
				for i = 1, c do
					io.write(boat)
					io.write(" ")
				end
				if l ~= max_length then
					print()
				end
			end
		end
	end
	
	print("\n")
end


local function count_row(r)
	local row = grid[r]
	
	local boatCount = 0
	local unknownCount = 0
		
	for c = 1, boardH do
		local type = row[c].type
		if type == "BOAT" then
			boatCount = boatCount + 1
		elseif type == "UNKNOWN" then
			unknownCount = unknownCount + 1
		end
	end
	
	return boatCount, unknownCount
end

local function count_col(c)
	local boatCount = 0
	local unknownCount = 0
		
	for r = 1, boardW do
		local type = grid[r][c].type
		if type == "BOAT" then
			boatCount = boatCount + 1
		elseif type == "UNKNOWN" then
			unknownCount = unknownCount + 1
		end
	end
	
	return boatCount, unknownCount
end

local function validate(partial)
	local boatCount, unknownCount
	
	for c = 1, boardW do
		boatCount, unknownCount = count_col(c)
		if boatCount + unknownCount < colCounts[c] or boatCount > colCounts[c] then
			return false
		end
	end
	
	for r = 1, boardH do
		boatCount, unknownCount = count_row(r)
		if boatCount + unknownCount < rowCounts[r] or boatCount > rowCounts[r] then
			return false
		end
	end
	
	for r = 1, boardH do
		for c = 1, boardW do
			if grid[r][c].type == "BOAT" then
				if (cell_is(r, c-1, "BOAT") or cell_is(r, c+1, "BOAT")) and (cell_is(r-1, c, "BOAT") or cell_is(r+1, c, "BOAT")) then
					return false
				elseif cell_is(r-1, c-1, "BOAT") or cell_is(r-1, c+1, "BOAT") or cell_is(r+1, c-1, "BOAT") or cell_is(r+1, c+1, "BOAT") then
					return false
				end
			end
		end
	end
	
	if CHECK_BOATS and not partial then
		local boat_length = count_boats()
		for l, c in pairs(boats_available) do
			if boat_length[l] ~= c then
				return false
			end
		end
	end
	
	return true
end

print "Input grid:"
print_grid()

if not validate(true) then
	print "Input grid seems impossible!"
	return
end

-- Pre-solving -----------------------------------------------------------------

print "Pre-solving..."

for r = 1, boardH do
	if rowCounts[r] == 0 then
		for c = 1, boardW do
			grid[r][c] = { type = "WATER", locked = true }
		end
	end
end

for c = 1, boardW do
	if colCounts[c] == 0 then
		for r = 1, boardH do
			grid[r][c] = { type = "WATER", locked = true }
		end
	end
end

change_made = true
while change_made do
	change_made = false
	
	for r = 1, boardH do
		for c = 1, boardW do
			local cell = grid[r][c]
			if cell.type == "BOAT" then
				set_cell(r-1, c-1, "WATER")
				set_cell(r-1, c+1, "WATER")
				set_cell(r+1, c-1, "WATER")
				set_cell(r+1, c+1, "WATER")
			end
		end
	end
	
	for r = 1, boardH do
		boatCount, unknownCount = count_row(r)
		if boatCount == rowCounts[r] and unknownCount > 0 then
			for c = 1, boardW do
				if grid[r][c].type == "UNKNOWN" then
					set_cell(r, c, "WATER")
				end
			end
		elseif unknownCount > 0 and rowCounts[r] - boatCount == unknownCount then
			for c = 1, boardW do
				if grid[r][c].type == "UNKNOWN" then
					set_cell(r, c, "BOAT")
				end
			end
		end
	end
	
	for c = 1, boardW do
		boatCount, unknownCount = count_col(c)
		if boatCount == colCounts[c] and unknownCount > 0 then
			for r = 1, boardH do
				if grid[r][c].type == "UNKNOWN" then
					set_cell(r, c, "WATER")
				end
			end
		elseif unknownCount > 0 and colCounts[c] - boatCount == unknownCount then
			for r = 1, boardH do
				if grid[r][c].type == "UNKNOWN" then
					set_cell(r, c, "BOAT")
				end
			end
		end
	end
end

print_grid()

if not validate(true) then
	print "Grid seems impossible!"
	return
end

-- SOLVING ---------------------------------------------------------------------

local function next(r, c)
	c = c + 1
	
	if c > boardW then
		c = 1
		r = r + 1
	end
	
	if r > boardH then
		return nil
	end
	
	if grid[r][c].locked then
		return next(r, c)
	else
		return r, c
	end
end

if not next(1, 0) then
	print "Pre-solving solved the grid. Done!"
	return
else
	print "Solving..."
end

local count = 0
local iterations = 0
local function solve(r, c)
	if not r then
		if FULL_SOLVE then
			count = count + 1
			print_grid()
			return false
		else
			return true
		end
	end
	
	local n_r, n_c = next(r, c)
	
	iterations = iterations + 1
	grid[r][c].type = "WATER"
	
	if validate(n_r) and solve(n_r, n_c) then
		return true
	end
	
	iterations = iterations + 1
	grid[r][c].type = "BOAT"
	
	if validate(n_r) and solve(n_r, n_c) then
		return true
	end
	
	grid[r][c].type = "UNKNOWN"
	return false
end

if not solve(next(1, 0)) then
	if FULL_SOLVE and count > 0 then
		print("Found " .. count .. " solutions!")
	else
		print "Unable to solve!"
	end
else
	print_grid()
	print "Done !"
end

print(iterations .. " iterations")
