local assembly_combinator_tech = {
	type = "technology",
	name = "assembly-combinators",
	icon = "__base__/graphics/technology/circuit-network.png",
	icon_size = 256,
	effects = {
		{
			type = "unlock-recipe",
			recipe = "assembly-combinator",
		},
	},
	prerequisites = { "advanced-combinators" },
	unit = {
		count = 100,
		ingredients = {
			{ "automation-science-pack", 1 },
			{ "logistic-science-pack", 1 },
			{ "chemical-science-pack", 1 },
		},
		time = 30,
	},
	order = "a-d-d",
}

data:extend({ assembly_combinator_tech })
