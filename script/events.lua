local cpu = require("cpu")

script.on_event(defines.events.on_built_entity, function(event)
	if event.entity.name == "assembly-combinator" then
		storage.assembly_combinators[event.entity.unit_number] = {
			entity = event.entity,
			cpu = cpu.new(),
			last_process_tick = game.tick,
		}

		local behavior = event.entity.get_control_behavior()

		if behavior.sections_count == 0 then
			behavior.add_section()
		end
		behavior.get_section(1).set_slot(1, {
			value = { type = "item", name = "copper-plate", quality = "normal" },
			count = 1337,
			min = 1,
			max = 2,
		})
	end
end)

local function cleanup_entity(entity)
	if entity and entity.valid then
		storage.assembly_combinators[entity.unit_number] = nil
	end
end

script.on_event(defines.events.on_entity_died, cleanup_entity)
script.on_event(defines.events.on_robot_pre_mined, function(event)
	cleanup_entity(event.entity)
end)
script.on_event(defines.events.on_pre_player_mined_item, function(event)
	cleanup_entity(event.entity)
end)

script.on_event(defines.events.on_tick, function(_event)
	for unit_number, data in pairs(storage.assembly_combinators) do
		local entity = data.entity

		if not entity.valid then
			storage.assembly_combinators[unit_number] = nil
		else
			data.last_process_tick = game.tick
			data.cpu:step()

			local output = data.cpu:get_register("output")
			if output > 0 then
				local behavior = entity.get_control_behavior()

				if behavior.sections_count == 0 then
					behavior.add_section()
				end
				behavior.get_section(1).set_slot(1, {
					value = { type = "item", name = "copper-plate", quality = "normal" },
					min = output,
				})
			end
		end
	end
end)
