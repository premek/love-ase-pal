local loader = require 'palease'

function love.load()
  local data = love.filesystem.read('pal1.ase')
  for k,v in pairs(loader(data).header.frames[1].chunks[1].data.colors[1].color) do
    print (k,v)
  end
end

function love.update(delta)
end

function love.draw()
end
