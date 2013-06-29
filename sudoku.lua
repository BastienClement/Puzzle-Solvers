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

local function printf(s, ...)
	return io.write(s:format(...))
end

for l = 1, 9 do
	grid[l] = {}
	
	printf("Line %d:  ", l)
	local line = io.read()
	
	local i = 1
	for m in line:gmatch("(%S+)") do
		grid[l][i] = tonumber(m) or 0
		i = i + 1
		if i > 9 then
			break
		end
	end
	
	for j = i, 9 do
		grid[l][j] = 0
	end
end

print()

local function print_grid()
	print("┏━━━┯━━━┯━━━┳━━━┯━━━┯━━━┳━━━┯━━━┯━━━┓")
	for r = 1, 9 do
		io.write("┃")
		for c = 1, 9 do
			if grid[r][c] == 0 then
				io.write("   ")
			else
				printf(" %d ", grid[r][c])
			end
			if c % 3 == 0 then
				io.write("┃")
			else
				io.write("│")
			end
		end
		print()
		if r % 3 == 0 then
			if r == 9 then
				print("┗━━━┷━━━┷━━━┻━━━┷━━━┷━━━┻━━━┷━━━┷━━━┛")
			else
				print("┣━━━┿━━━┿━━━╋━━━┿━━━┿━━━╋━━━┿━━━┿━━━┫")
			end
		else
			print("┠───┼───┼───╂───┼───┼───╂───┼───┼───┨")
		end
	end
	print()
end

--------------------------------------------------------------------------------

local seen = {}
local conflict = false

local function reset()
	for i = 1, 9 do seen[i] = false end
	conflict = false
end

local function check(v)
	if v > 0 then
		if seen[v] then
			conflict = true
		else
			seen[v] = true
		end
	end
end

local function validate()
	-- blocks
	for r = 1, 7, 3 do
		for c = 1, 7, 3 do
			reset()
			for i = 0, 2 do
				for j = 0, 2 do
					check(grid[r+i][c+j])
				end
			end
			if conflict then return false end
		end
	end
	
	-- rows
	for r = 1, 9 do
		reset()
		for c = 1, 9 do
			check(grid[r][c])
		end
		if conflict then return false end
	end
	
	-- cols
	for c = 1, 9 do
		reset()
		for r = 1, 9 do
			check(grid[r][c])
		end
		if conflict then return false end
	end
	
	return true
end

local function next(r, c)
	c = c + 1
	if c > 9 then
		c = 1
		r = r + 1
	end
	
	if r > 9 then
		return nil
	end
	
	if grid[r][c] ~= 0 then
		return next(r, c)
	else
		return r, c
	end
end

local function solve(r, c)
	if not r then
		return true
	end
	
	while grid[r][c] < 10 do
		grid[r][c] = grid[r][c] + 1
		if validate() and solve(next(r, c)) then
			return true
		end
	end
	
	grid[r][c] = 0
	return false
end

print "Input:"
print_grid()

solve(next(1, 0))

print "Solved:"
print_grid()

