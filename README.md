# Asprite / LibreSprite palette loader for Lua / Love 2d

Reads palette files saved from Aseprite or LibreSprite to be used in LOVE.
A palette file could be saved from Aseprite or LibreSprite using Save Palette command from the Options menu (above the palette on the left hand side).

Based on [elloramir/love-ase](https://github.com/elloramir/love-ase) but this tool only loads the palette information and ignores any other Aseprite file types.


## Usage

Put `palease.lua` file in your project and require it:

```
local paleAse = require 'palease'
```

Use it like this:
```
local palette = paleAse.load(love.filesystem.read('pal1.ase'))

```

`load` returns the palette (a table with individual colors). The table is 0-based to keep the indexes the same as the ones displayed in aseprite. For example aseprite color `Idx-4` will be `palette[4]`. Each color is a table of `{r, g, b, a}` (each component value is 0..1) and it could be used directly like this:

```
love.graphics.setColor(palette[4])
```

or using the individual color components:
```
love.graphics.setColor(color[1], color[2], color[3])
```
`color[1]` is red, `color[2]` is green, `color[3]` is blue, `color[4]` is alpha.

For LOVE example see the `main.lua` file.

## Supported versions

Tested with LibreSprite (which should be based on Aseprite around v1.1.7) but based on the current (2022/12) 
[Aseprite File Format (.ase/.aseprite) Specification](https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md)
 it should work with current versions of Aseprite too. You can let me know if it does or if it doesn't.

 




