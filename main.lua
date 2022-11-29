local paleAse = require 'palease'
local palette = paleAse.load(love.filesystem.read('pal1.ase'))

--or: local palette = require('palease').load(love.filesystem.read('pal1.ase'))

local a = 80
local row = math.floor(love.graphics.getWidth()/a)

function love.draw()

  for i, color in pairs(palette) do
    local x = (i%row) * a
    local y = math.floor(i/row)*a

    love.graphics.setColor(color)
    -- or: love.graphics.setColor(color[1], color[2], color[3])
    -- color[1] is red,
    -- color[2] is green,
    -- color[3] is blue
    -- color[4] is alpha

    love.graphics.rectangle("fill", x,y, a,a)
    love.graphics.setColor(0,0,0)
    love.graphics.printf(i, x, y+5, a, "center")
    love.graphics.setColor(1,1,1)
    love.graphics.printf(i, x+1, y+5+1, a, "center")
  end

end
