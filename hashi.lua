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
]]

local grid = {}
local gridW, gridH = 0, 0

local nodes = {}
local links = {}

-- Parse

do
	local node_mt = {}
	node_mt.__index = node_mt
	
	function node_mt:Next(i)
		local link = self.links[i]
		return (link.a == self) and b or a
	end
	
	function node_mt:NextValue(i)
		local node = self:Next(i)
		return node and node.value or 0
	end
	
	function node_mt:Sum()
		local sum = 0
		for _, link in ipairs(self.links) do
			sum = sum + link.type
		end
		return sum
	end
	
	local function makeNode(r, c, value)
		local v = tonumber(value)
		if not v then return end
		
		local node = {
			node = true,
			done = false,
			value = v,
			row = r,
			col = c,
			links = {}
		}
		
		setmetatable(node, node_mt)
	
		nodes[#nodes + 1] = node
		return node
	end
	
	local r = 1
	for line in io.lines() do
		if r > gridH then
			gridH = r
		end
	
		grid[r] = {}
	
		local c = 1
		for char in line:gmatch(".") do
			if c > gridW then
				gridW = c
			end
		
			grid[r][c] = makeNode(r, c, char)
			c = c + 1
		end
	
		r = r + 1
	end
end

-- Linking

do
	local function link(a, aSide, b, bSide)
		local o = bSide == "top" and "vertical" or "horizontal"
		
		local link = {
			link = true,
			type = 0,
			a = a,
			b = b,
			o = o
		}
		
		if o == "vertical" then
			local c = a.col
				for r = a.row + 1, b.row - 1 do
				grid[r][c] = link
			end
		else
			local r = a.row
			for c = a.col + 1, b.col - 1 do
				grid[r][c] = link
			end
		end
		
		a[aSide] = link
		b[bSide] = link
		
		a.links[#a.links + 1] = link
		b.links[#b.links + 1] = link
		
		links[#links + 1] = links
	end
	
	for r = 1, gridH do
		for c = 1, gridW do
			local cell = grid[r][c]
			if cell and cell.node then
				for rr = r + 1, gridH do
					if grid[rr][c] and grid[rr][c].node then
						link(cell, "bottom", grid[rr][c], "top")
						break
					end
				end
			
				for cc = c + 1, gridW do
					if grid[r][cc]  and grid[r][cc].node then
						link(cell, "right", grid[r][cc], "left")
						break
					end
				end
			end
		end
	end
end

-- Print

local print_grid
do
	local circled = {
		[1] = "①",
		[2] = "②",
		[3] = "③",
		[4] = "④",
		[5] = "⑤",
		[6] = "⑥",
		[7] = "⑦",
		[8] = "⑧"
	}
	
	function print_grid()
		local out_grid = {}
		
		for r = 1, gridH do
			out_grid[r] = {}
		
			for c = 1, gridW do
				local cell = grid[r][c]
				if cell and cell.node then
						out_grid[r][c] = " " .. cell.value .. " "
				elseif cell and cell.link and cell.type ~= 0 then
					if cell.o == "vertical" then
						if cell.type == 1 then
							out_grid[r][c] = " │ "
						else
							out_grid[r][c] = " ║ "
						end
					else
						if cell.type == 1 then
							out_grid[r][c] = "───"
						else
							out_grid[r][c] = "═══"
						end
					end
				else
					out_grid[r][c] = "   "
				end
			end
		end
	
		print()
		for i = 1, #out_grid do print(table.concat(out_grid[i], "")) end
		print()
	end
end

print "Input:"
print_grid()

--[[
do
	local change_made = true
	
	local function set_link(link, type)
		if link.type ~= type then
			link.type = type
			change_made = true
		end
	end
	
	while change_made do
		change_made = false
		
		for _, node in ipairs(nodes) do
			if not node.done then
				if node:Sum() == node.value then
					node.done = true
				else
					if #node.links == 1 then
						set_link(node.links[1], node.value)
						node.done = true
					end
					
					local possible_links = 0
					for i = 1, #node.links do
						if node:NextValue(i) == 1 and node.value == 1 then
							-- Impossible
						elseif node.value == 1 or node:NextValue(i) == 1 or (node:NextValue(i) == 2 and node.value == 2) then
							possible_links = possible_links + 1
						else
							possible_links = possible_links + 2
						end
					end
					
					if possible_links == node.value then
						for i, link in ipairs(node.links) do
							if (node:NextValue(i) == 1 and node.value ~= 1) or (node:NextValue(i) == 2 and node.value == 2) then
								set_link(link, 1)
							else
								set_link(link, 2)
							end
						end
					elseif possible_links == node.value + 1 then
						for i, link in ipairs(node.links) do
							set_link(link, 1)
						end
					end
				end
			end
		end
	end
end
]]

print "Solved:"
print_grid()
