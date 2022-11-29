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

local load = function(data)
  local current = 0
  local palette = {}

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


  local function grab_palette()
    local entry_size = read_num(DWORD)
    local first_color = read_num(DWORD)
    local last_color = read_num(DWORD)

    -- skip
    read_num(BYTE * 8)

    -- 0-based to keep the indexes the same as the ones displayed in aseprite
    for i = 0, entry_size-1 do
      local has_name = read_num(WORD)

      -- convert colors from 0..255 to 0..1
      palette[i] = {
        read_num(BYTE) / 255,
        read_num(BYTE) / 255,
        read_num(BYTE) / 255,
        read_num(BYTE) / 255
      }

      if has_name == 1 then
        local name = read_string()
        -- ignore color name, it probably cannot be set from aseprite
      end
    end

  end


  local function grab_chunk()
    local size = read_num(DWORD)
    local type = read_num(WORD)

    if type == 0x2019 then
      grab_palette()
    end
  end


  local function grab_frame_header()
    local bytes_size = read_num(DWORD)
    local magic_number = read_num(WORD)

    if magic_number ~= 0xF1FA then
      error("Corrupted file")
    end

    local old_chunks = read_num(WORD)

    local frame_duration = read_num(WORD)

    -- skip
    read_num(BYTE * 2)

    -- if 0, use old chunks as chunks
    local new_chunks = read_num(DWORD)

    local chunks_number
    if new_chunks == 0 then
      chunks_number = old_chunks
    else
      chunks_number = new_chunks
    end

    -- parse frames chunks
    for i = 1, chunks_number do
      grab_chunk()
    end

  end


  local function load()
    local file_size = read_num(DWORD)
    local magic_number = read_num(WORD)

    if magic_number ~= 0xA5E0 then
      error("Not a valid aseprite file")
    end

    local frames_number = read_num(WORD)
    local width = read_num(WORD)
    local height = read_num(WORD)
    local color_depth = read_num(WORD)
    local opacity = read_num(DWORD)
    local speed = read_num(WORD)

    -- skip
    read_num(DWORD * 2)

    local palette_entry = read_num(BYTE)

    -- skip
    read_num(BYTE * 3)

    local number_color = read_num(WORD)
    local pixel_width = read_num(BYTE)
    local pixel_height = read_num(BYTE)
    local grid_x = read_num(SHORT)
    local grid_y = read_num(SHORT)
    local grid_width = read_num(WORD)
    local grid_height = read_num(WORD)

    -- skip
    read_num(BYTE * 84)

    -- parse frames
    for i = 1, frames_number do
      grab_frame_header()
    end

  end

  load()

  return palette

end


return {
  load = load
}
