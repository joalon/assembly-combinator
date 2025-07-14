local assembly_combinator_recipe = {
	type = "recipe",
	name = "assembly-combinator",
	ingredients = {
		{ type = "item", name = "constant-combinator", amount = 1 },
		{ type = "item", name = "advanced-circuit", amount = 2 },
		{ type = "item", name = "iron-plate", amount = 2 },
	},
	enabled = false,
	results = { {
		type = "item",
		name = "assembly-combinator",
		amount = 1,
	} },
}

data:extend({
	assembly_combinator_recipe,
})
