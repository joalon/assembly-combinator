local flib = require("__flib__.data-util")

local assembly_combinator =
	flib.copy_prototype(data.raw["constant-combinator"]["constant-combinator"], "assembly-combinator")

local assembly_combinator_item = flib.copy_prototype(data.raw["item"]["constant-combinator"], "assembly-combinator")

local assembly_combinator_recipe = {
	type = "recipe",
	name = "assembly-combinator",
	ingredients = {
		{ type = "item", name = "constant-combinator", amount = 1 },
		{ type = "item", name = "advanced-circuit", amount = 2 },
		{ type = "item", name = "iron-plate", amount = 2 },
	},
	enabled = true,
	results = { {
		type = "item",
		name = "assembly-combinator",
		amount = 1,
	} },
}
data:extend({ assembly_combinator, assembly_combinator_item, assembly_combinator_recipe })
