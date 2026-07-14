local assembly_combinator =
	flib.copy_prototype(data.raw["constant-combinator"]["constant-combinator"], "assembly-combinator")

local sprite = {
	filename = "__assembly-combinator__/graphics/entity/combinator.png",
	width = 256,
	height = 256,
	scale = 0.25,
	shift = { 0, 0 }, -- tune in-game; util.by_pixel(x,y) == {x/32, y/32}
}
assembly_combinator.sprites = { north = sprite, east = sprite, south = sprite, west = sprite }

data:extend({ assembly_combinator })
