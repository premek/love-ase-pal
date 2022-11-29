--[[
MIT License

Copyright (c) 2021 Pedro Lucas (github.com/elloramir)
Copyright (c) 2022 github.com/premek

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

-- sizes in bytes
local BYTE = 1
local WORD = 2
local SHORT = 2
local DWORD = 4
local LONG = 4
local FIXED = 4

return function(data)
    local current = 0

    local function next()
        current = current + 1
        return data:byte(current)
    end
    
-- parse data/text to number
local function read_num(size)
    local n = 0
    for i = 0, size-1 do
        n = n + next() * 256 ^ i
    end
    --print(string.format("%0"..size.."X", n))
	return n;
end

-- return a string by it size
local function read_string()
	local length = read_num(WORD)
	local s = data:sub(current, current+length)
    current = current + length
    --print(s)
    return s
end

local function grab_header()
	local header = {}

	header.file_size = read_num(DWORD)
	header.magic_number = read_num(WORD)

	if header.magic_number ~= 0xA5E0 then
		error("Not a valid aseprite file")
	end

	header.frames_number = read_num(WORD)
	header.width = read_num(WORD)
	header.height = read_num(WORD)
	header.color_depth = read_num(WORD)
	header.opacity = read_num(DWORD)
	header.speed = read_num(WORD)

	-- skip
	read_num(DWORD * 2)

	header.palette_entry = read_num(BYTE)

	-- skip
	read_num(BYTE * 3)

	header.number_color = read_num(WORD)
	header.pixel_width = read_num(BYTE)
	header.pixel_height = read_num(BYTE)
	header.grid_x = read_num(SHORT)
	header.grid_y = read_num(SHORT)
	header.grid_width = read_num(WORD)
	header.grid_height = read_num(WORD)

	-- skip
	read_num(BYTE * 84)

	-- to the future
	header.frames = {}

	return header
end

local function grab_frame_header()
	local frame_header = {}

	frame_header.bytes_size = read_num(DWORD)
	frame_header.magic_number = read_num(WORD)

	if frame_header.magic_number ~= 0xF1FA then
		error("Corrupted file")
	end

	local old_chunks = read_num(WORD)

	frame_header.frame_duration = read_num(WORD)

	-- skip
	read_num(BYTE * 2)

	-- if 0, use old chunks as chunks
	local new_chunks = read_num(DWORD)

	if new_chunks == 0 then
		frame_header.chunks_number = old_chunks
	else
		frame_header.chunks_number = new_chunks
	end

	-- to the future
	frame_header.chunks = {}

	return frame_header
end

local function grab_color_profile()
	local color_profile = {}

	color_profile.type = read_num(WORD)
	color_profile.uses_fixed_gama = read_num(WORD)
	color_profile.fixed_game = read_num(FIXED)

	-- skip
	read_num(BYTE * 8)

	if color_profile.type ~= 1 then
		error("No suported color profile, use sRGB")
	end

	return color_profile
end

local function grab_palette()
	local palette = {}

	palette.entry_size = read_num(DWORD)
	palette.first_color = read_num(DWORD)
	palette.last_color = read_num(DWORD)
	palette.colors = {}

	-- skip
	read_num(BYTE * 8)

	for i = 1, palette.entry_size do
		local has_name = read_num(WORD)

		palette.colors[i] = {
			color = {
				read_num(BYTE),
				read_num(BYTE),
				read_num(BYTE),
				read_num(BYTE)}}

		if has_name == 1 then
			palette.colors[i].name = read_string()
		end
	end

	return palette
end

local function grab_old_palette()
	local palette = {}

	palette.packets = read_num(WORD)
	palette.colors_packet = {}

	for i = 1, palette.packets do
		palette.colors_packet[i] = {
			entries = read_num(BYTE),
			number = read_num(BYTE),
			colors = {}}

		for j = 1, palette.colors_packet[i].number do
			palette.colors_packet[i][j] = {
				read_num(BYTE),
				read_num(BYTE),
				read_num(BYTE)}
		end
	end

	return palette
end

local function grab_layer()
	local layer = {}

	layer.flags = read_num(WORD)
	layer.type = read_num(WORD)
	layer.child_level = read_num(WORD)
	layer.width = read_num(WORD)
	layer.height = read_num(WORD)
	layer.blend = read_num(WORD)
	layer.opacity = read_num(BYTE)

	-- skip
	read_num(BYTE * 3)

	layer.name = read_string()

	return layer
end

local function grab_cel(size)
	local cel = {}

	cel.layer_index = read_num(WORD)
	cel.x = read_num(WORD)
	cel.y = read_num(WORD)
	cel.opacity_level = read_num(BYTE)
	cel.type = read_num(WORD)

	read_num(BYTE * 7)

	if cel.type == 2 then
		cel.width = read_num(WORD)
		cel.height = read_num(WORD)
		cel.data = data:sub(current, current + size - 26)
        current = current + size - 26
	end

	return cel
end

local function grab_tags()
	local tags = {}

	tags.number = read_num(WORD)
	tags.tags = {}

	-- skip
	read_num(BYTE * 8)

	for i = 1, tags.number do
		tags.tags[i] = {
			from = read_num(WORD),
			to = read_num(WORD),
			direction = read_num(BYTE),
			extra_byte = read_num(BYTE),
			color = read_num(BYTE * 3),
			skip_holder = read_num(BYTE * 8),
			name = read_string()}
	end

	return tags
end

local function grab_slice()
	local slice = {}

	slice.key_numbers = read_num(DWORD)
	slice.keys = {}
	slice.flags = read_num(DWORD)

	-- reserved?
	read_num(DWORD)

	slice.name = read_string()

	for i = 1, slice.key_numbers do
		slice.keys[i] = {
			frame = read_num(DWORD),
			x = read_num(DWORD),
			y = read_num(DWORD),
			width = read_num(DWORD),
			height = read_num(DWORD)}

		if slice.flags == 1 then
			slice.keys[i].center_x = read_num(DWORD)
			slice.keys[i].center_y = read_num(DWORD)
			slice.keys[i].center_width = read_num(DWORD)
			slice.keys[i].center_height = read_num(DWORD)
		elseif slice.flags == 2 then
			slice.keys[i].pivot_x = read_num(DWORD)
			slice.keys[i].pivot_y = read_num(DWORD)
		end
	end

	return slice
end

local function grab_user_data()
	local user_data = {}

	user_data.flags = read_num(DWORD)
	
	if user_data.flags == 1 then
		user_data.text = read_string()
	elseif user_data.flags == 2 then
		user_data.colors = read_num(BYTE * 4)
	end

	return user_data
end

local function grab_chunk()
	local chunk = {}
	chunk.size = read_num(DWORD)
	chunk.type = read_num(WORD)

	if chunk.type == 0x2007 then
		chunk.data = grab_color_profile()
	elseif chunk.type == 0x2019 then
		chunk.data = grab_palette()
	elseif chunk.type == 0x0004 then
		chunk.data = grab_old_palette()
	elseif chunk.type == 0x2004 then
		chunk.data = grab_layer()
	elseif chunk.type == 0x2005 then
		chunk.data = grab_cel(chunk.size)
	elseif chunk.type == 0x2018 then
		chunk.data = grab_tags()
	elseif chunk.type == 0x2022 then
		chunk.data = grab_slice()
	elseif chunk.type == 0x2020 then
		chunk.data = grab_user_data()
	end

	return chunk
end



	local ase = {}

	-- parse header
	ase.header = grab_header()

	-- parse frames
	for i = 1, ase.header.frames_number do
		ase.header.frames[i] = grab_frame_header()

		-- parse frames chunks
		for j = 1, ase.header.frames[i].chunks_number do
			ase.header.frames[i].chunks[j] = grab_chunk()
		end
	end

	return ase

end
