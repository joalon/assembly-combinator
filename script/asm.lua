script.on_event(defines.events.on_gui_opened, function(event)
	if event.gui_type == defines.gui_type.entity then
		local entity = event.entity
		if entity and entity.name == "assembly-combinator" then
			game.players[event.player_index].opened = nil
			create_custom_gui(game.get_player(event.player_index), entity)
		end
	end
end)

function create_custom_gui(player, entity)
	if player.gui.screen.assembly_combinator_gui then
		player.gui.screen.assembly_combinator_gui.destroy()
	end

	local frame = player.gui.screen.add({
		type = "frame",
		name = "assembly_combinator_gui",
		direction = "vertical",
	})
	frame.auto_center = true

	local titlebar = frame.add({ type = "flow" })
	titlebar.drag_target = frame
	titlebar.add({
		type = "label",
		style = "frame_title",
		caption = "Assembly combinator",
		ignored_by_interaction = true,
	})
	local filler = titlebar.add({
		type = "empty-widget",
		style = "draggable_space",
		ignored_by_interaction = true,
	})
	filler.style.height = 24
	filler.style.horizontally_stretchable = true
	titlebar.add({
		type = "sprite-button",
		name = "assembly-combinator-close-button",
		style = "frame_action_button",
		sprite = "utility/close",
		hovered_sprite = "utility/close_black",
		clicked_sprite = "utility/close_black",
		tooltip = { "gui.close-instruction" },
	})

	local content = frame.add({
		type = "frame",
		name = "content",
		direction = "vertical",
		style = "inside_deep_frame",
	})
	content.style.padding = 12

	content.add({
		type = "label",
		caption = "Entity ID: " .. tostring(entity.unit_number or "N/A"),
	})

	content.add({
		type = "label",
		caption = "Position: " .. entity.position.x .. ", " .. entity.position.y,
	})
end

script.on_event(defines.events.on_gui_click, function(event)
	if event.element.name == "assembly-combinator-close-button" then
		if event.element.parent.parent.name == "assembly_combinator_gui" then
			event.element.parent.parent.destroy()
		end
	end
end)

script.on_event(defines.events.on_gui_closed, function(event)
	if event.element and event.element.name == "assembly_combinator_gui" then
		event.element.destroy()
	end
end)
