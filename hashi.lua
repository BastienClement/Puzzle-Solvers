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

-- The game grid and its dimensions
local grid = {}
local gridW, gridH = 0, 0

-- A list of all nodes
local nodes = {}

-- Aliases for node sides
local TOP, RIGHT, BOTTOM, LEFT = 1, 2, 3, 4
local HORIZONTAL, VERTICAL = 1, 2

-- Debug Strings
local SIDES = {
	[TOP] = "TOP",
	[RIGHT] = "RIGHT",
	[BOTTOM] = "BOTTOM",
	[LEFT] = "LEFT"
}

local ORIENTATIONS = {
	[HORIZONTAL] = "HORIZONTAL",
	[VERTICAL] = "VERTICAL"
}

local print_grid

-- NODE OBJECT

local node_mt = {}
node_mt.__index = node_mt

-- Updates the count field of the node and completes
-- the node if the count matches the value
function node_mt:UpdateCount()
	self.count = 0
	
	for side, link in pairs(self.links) do
		self.count = self.count + link.count
	end
	
	if not self.complete and self.count == self.value then
		self.complete = true
		
		for side, link in pairs(self.links) do
			if not link.complete then
				self:SetLink(side, link.count, true)
			end
		end
	end
end

-- Returns how many links are missing
function node_mt:Missing()
	return self.value - self.count
end

-- Changes the maximum number of links possible on a given side
function node_mt:SetLinkPossible(side, possible)
	local link = self.links[side]
	assert(link, "link is undefined")
	assert(not link.complete, "link is already competed")
	
	if possible == link.possible then
		return false
	end
	
	assert(link.count <= possible)
	assert(possible <= link.possible, "attempting to assign a greater possible value ")
	
	if possible == link.count then
		-- The minimum equals the maximum, so this link is defined
		self:SetLink(side, possible, true)
	else
		link.possible = possible
	end
	
	return true
end

-- Removes a link from a node (dead-link)
function node_mt:RemoveLink(l)
	assert(l.count == 0, "cannot remove a used link")
	
	for side, link in pairs(self.links) do
		if link == l then
			self.links[side] = nil
			self.linksNode[side] = nil
			return
		end
	end
end

-- Changes the minimum number of links possible on a given side
-- If exact is given, the maximum is also updated and the node is completed
function node_mt:SetLink(side, count, exact)
	local link = self.links[side]
	assert(link, "link is undefined")
	assert(not link.complete, "link is already competed")
	
	if not exact and count == link.count then
		return false
	end
	
	assert(count <= link.possible)
	assert(count >= link.count, "attempting to assign a lesser count value ")
	link.count = count
	
	-- Update linked nodes count
	link.a:UpdateCount()
	link.b:UpdateCount()
	
	if count > 0 then
		-- We must removes all crossing links
		for i, link in pairs(link.crossing) do
			assert(link.count == 0, "a crossing link is already used")
			link.a:RemoveLink(link)
			link.b:RemoveLink(link)
		end
	else
		-- This is a dead link, removes it
		link.a:RemoveLink(link)
		link.b:RemoveLink(link)
	end
	
	-- Closing the link if the link is defined
	if exact or link.count == link.possible then
		link.possible = count
		link.complete = true
	end
	
	return true
end

-- PARSE

do
	-- Create a link object
	local function makeLink(a, b, orientation)
		local link = {
			a = a,            -- First linked node
			b = b,            -- Second linked node
			count = 0,        -- Bridge count
			possible = 2,     -- Maximum number of possible bridge
			complete = false, -- Is this link completed?
			crossing = {}     -- List of all crossing links
		}
		
		-- Add the link in node objects
		local aSide = (orientation == VERTICAL) and BOTTOM or RIGHT
		local bSide = (orientation == VERTICAL) and TOP or LEFT
		
		a.links[aSide] = link
		b.links[bSide] = link
		
		a.linksNode[aSide] = b
		b.linksNode[bSide] = a
		
		return link
	end
	
	-- Look for a node on the top of the current node
	local function traceUp(r, c)
		r = r - 1
		if r < 1 then
			return false
		elseif grid[r][c] and grid[r][c].node then
			return grid[r][c]
		else
			return traceUp(r, c)
		end
	end
	
	-- Look for a node on the left of the current node
	local function traceLeft(r, c)
		c = c - 1
		if c < 1 then
			return false
		elseif grid[r][c] and grid[r][c].node then
			return grid[r][c]
		else
			return traceLeft(r, c)
		end
	end
	
	-- Look for nodes around the current node
	-- This function only look backward because 
	-- the grid is only partially parsed
	local function trace(r, c, node)
		
		local up = traceUp(r, c)
		if up then
			local link = makeLink(up, node, VERTICAL)
			
			for rr = r - 1, up.row + 1, -1 do
				local cell = grid[rr][c]
				if not cell then
					grid[rr][c] = {
						links = true,
						[VERTICAL] = link
					}
				elseif not cell.node then
					local cross = grid[rr][c][HORIZONTAL]
					if cross then
						cross.crossing[#cross.crossing + 1] = link
						link.crossing[#link.crossing + 1] = cross
					end
					grid[rr][c][VERTICAL] = link
				end
			end
		end
		
		local left = traceLeft(r, c)
		if left then
			local link = makeLink(left, node, HORIZONTAL)
			
			for cc = c - 1, left.col + 1, -1 do
				local cell = grid[r][cc]
				if not cell then
					grid[r][cc] = {
						links = true,
						[HORIZONTAL] = link
					}
				end
				-- Note: You cannot cross a link on the left!
			end
		end
	end
	
	-- Create a node object
	local function makeNode(r, c, v)
		local node = {
			node = true,      -- Used to identify a node object
			complete = false, -- Is this node completed?
			value = v,        -- How many bridges this node requires
			count = 0,        -- Bridge count
			row = r,          -- The row of this node
			col = c,          -- The column of this node
			links = {},       -- A list of all links from this node
			linksNode = {}    -- A list of linked node from this node
		}
		
		setmetatable(node, node_mt)
		trace(r, c, node)
		
		-- Add this node in the nodes list
		nodes[#nodes + 1] = node
		return node
	end
	
	-- Parse input
	-- This script reads from stdin
	local function parse()
		local r = 1
		for line in io.lines() do
			if r > gridH then
				gridH = r
			end
		
			grid[r] = {}
		
			local c = 1
			for char in line:gmatch(".") do
				-- The '.' char can be used to stop the parsing
				if char == "." then
					return
				end
			
				local v = tonumber(char)
				
				if c > gridW then
					gridW = c
				end
				
				if v and v > 0 and v < 9 then
					grid[r][c] = makeNode(r, c, v)
				end
			
				c = c + 1
			end
		
			r = r + 1
		end
	end
	
	parse()
end

-- PRINT

do
	-- A list of circled number
	-- NOT USED
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
	
	-- Prints the grid to stdout
	function print_grid()
		for r = 1, gridH do
			for c = 1, gridW do
				local cell = grid[r][c]
				if cell then
					if cell.node then
						io.write((cell.complete and "[" or " "), cell.value, (cell.complete and "]" or " "))
					elseif cell.links then
						local h = cell[HORIZONTAL]
						local v = cell[VERTICAL]
						
						if h and h.count > 0 then
							io.write(h.count == 2 and "═══" or "───")
						elseif v and v.count > 0 then
							io.write(v.count == 2 and " ║ " or " │ ")
						else
							io.write("   ")
						end
					end
				else
					io.write("   ")
				end
			end
			print()
		end
		print()
	end
end

print "Input:"
print_grid()

-- SOLVING

do
	print "Solving..."
	local change_made = true
	
	-- Wrapper function to node:SetLinkPossible
	-- Updates change_made if the function returns true
	local function set_link_possible(node, side, possible)
		if node:SetLinkPossible(side, possible) then
			change_made = true
		end
	end
	
	-- Wrapper function to node:SetLink
	-- Updates change_made if the function returns true
	local function set_link(node, side, count, exact)
		if node:SetLink(side, count, exact) then
			change_made = true
		end
	end

	-- Main solving loop
	while change_made do
		change_made = false
		
		for _, node in next, nodes do
			if not node.complete then
				-- Node with 1 missing link can only be linked once more
				if node:Missing() == 1 then
					for side, link in pairs(node.links) do
						if not link.complete and link.count == 0 and link.possible > 1 then
							set_link_possible(node, side, 1)
						end
					end
				end
				
				-- A node has only the exact bridge count available
				-- So each link is used for its maximum bridge capacity
				if not node.complete then
					local possible = 0
					for side, link in pairs(node.links) do
						possible = possible + link.possible
					end
					
					if possible == node.value then
						for side, link in pairs(node.links) do
							if not link.complete then
								set_link(node, side, link.possible, true)
							end
						end
					end
				end
				
				-- Find required sides
				-- Assuming a side is not used, can the node still be completed?
				-- If not, the excluded side is required to complete the node
				if not node.complete then
					local missing = node:Missing()
					
					for excluded, link in pairs(node.links) do
						if not link.complete then
							local remaining = missing
						
							for side, link in pairs(node.links) do
								if side ~= excluded then
									remaining = remaining - link.possible
								end
							end
						
							if remaining > 0 then
								set_link(node, excluded, link.count + remaining)
							end
						end
					end
				end
				
				-- Closed circuits
				-- If linking two nodes creates a closed completed subset of the grid
				-- then it will be imposible to link this subset with the grid and
				-- complete the puzzle. We must remove one possible bridge from this link.
				if not node.complete then
					local missing = node:Missing()
					
					-- This is only usable if the node is missing 1 or 2 bridges
					if missing == 1 or missing == 2 then
						for side, link in pairs(node.links) do
							local n = node.linksNode[side]
							-- Each nodes requires the same bridge count and can be linked together
							if n:Missing() == missing and (not link.complete) and link.possible == missing then
								-- List of walked node to handle loops and counter
								local walked = { [node] = true, [n] = true }
								local walkedCount = 2
								
								-- Walk the nodes graph and return if this is
								-- a closed circuit or not
								local function walk(node)
									for side, n in pairs(node.linksNode) do
										if node.links[side].count > 0 and not walked[n] then
											if n.complete then
												walked[n] = true
												walkedCount = walkedCount + 1
												
												-- Recursive walk
												if not walk(n) then
													return false
												end
											else
												-- If a node in the circuit is not completed, then
												-- we can hope to link it with other nodes later
												return false
											end
										end
									end
									
									-- All nodes are completed, this is a closed circuit
									return true
								end
								
								-- If both side of the link are closed and the walked node
								-- count is not equal to the total number of nodes, then
								-- this is a closed circuit
								if walk(node) and walk(n) and walkedCount ~= #nodes then
									set_link_possible(node, side, link.possible - 1)
								end
							end
						end
					end
				end
			end
		end
	end
	
	-- Solving done. Print the grid.
	print_grid()
end

-- Check that all nodes are completed...
local completed = 0
for _, node in ipairs(nodes) do
	if node.complete then
		completed = completed + 1
	end
end

-- ... and print the result
print((completed == #nodes) and "Solved!" or "Unable to solve...")

--[[
for side, link in pairs(grid[6][1].links) do
	print(SIDES[side], link.count, link.possible, link.complete)
end
]]
