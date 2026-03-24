local cpu = require("cpu")

local function clear_output_sections(entity)
    local behavior = entity.get_control_behavior()
    if behavior then
        for i = behavior.sections_count, 1, -1 do
            behavior.remove_section(i)
        end
    end
end

local function register_entity(entity, code)
    if entity.name == "assembly-combinator" then
        storage.assembly_combinators[entity.unit_number] = {
            entity = entity,
            cpu = cpu.new(code),
            last_process_tick = game.tick,
        }
        clear_output_sections(entity)
    end
end

local function get_code_from_tags(tags)
    if tags and tags.assembly_combinator_code then
        return tags.assembly_combinator_code
    end
    return nil
end

script.on_event(defines.events.on_built_entity, function(event)
    register_entity(event.entity, get_code_from_tags(event.tags))
end)
script.on_event(defines.events.on_robot_built_entity, function(event)
    register_entity(event.entity, get_code_from_tags(event.tags))
end)
script.on_event(defines.events.on_entity_cloned, function(event)
    local source = storage.assembly_combinators[event.source.unit_number]
    local code = source and source.cpu:get_code() or nil
    register_entity(event.destination, code)
end)
script.on_event(defines.events.script_raised_built, function(event)
    register_entity(event.entity, get_code_from_tags(event.tags))
end)
script.on_event(defines.events.on_entity_settings_pasted, function(event)
    if event.destination.name == "assembly-combinator" then
        local source = storage.assembly_combinators[event.source.unit_number]
        local code = source and source.cpu:get_code() or nil
        local dest = storage.assembly_combinators[event.destination.unit_number]
        if dest then
            dest.cpu:update_code(code or {"HLT"})
            clear_output_sections(event.destination)
        end
    end
end)

script.on_event(defines.events.on_player_setup_blueprint, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    local blueprint = player.blueprint_to_setup
    if not blueprint or not blueprint.valid_for_read then
        blueprint = player.cursor_stack
    end
    if not blueprint or not blueprint.valid_for_read then return end

    local mapping = event.mapping.get()
    for blueprint_index, entity in pairs(mapping) do
        if entity.valid and entity.name == "assembly-combinator" then
            local data = storage.assembly_combinators[entity.unit_number]
            if data then
                blueprint.set_blueprint_entity_tag(blueprint_index, "assembly_combinator_code", data.cpu:get_code())
            end
        end
    end
end)

local function cleanup_entity(entity)
    if entity and entity.valid and entity.unit_number then
        storage.assembly_combinators[entity.unit_number] = nil
    end
end

script.on_event(defines.events.on_entity_died, function(event)
    cleanup_entity(event.entity)
end)
script.on_event(defines.events.on_robot_pre_mined, function(event)
    cleanup_entity(event.entity)
end)
script.on_event(defines.events.on_pre_player_mined_item, function(event)
    cleanup_entity(event.entity)
end)

script.on_event(defines.events.on_tick, function(event)
    for unit_number, data in pairs(storage.assembly_combinators) do
        local entity = data.entity

        if not entity.valid then
            storage.assembly_combinators[unit_number] = nil
        else
            data.last_process_tick = game.tick
            data.cpu:step()

            -- Handle errors
            if #data.cpu:get_errors() ~= 0 then
                for _, player in pairs(game.players) do
                    local gui_name = "assembly_combinator_gui_" .. data.entity.unit_number
                    local gui = player.gui.screen[gui_name]
                    if gui and gui.content and gui.content.errors then
                        gui.content.errors.caption = data.cpu:get_errors()[1]
                    end
                end
                goto continue
            end

            -- Update GUI icons
            for _, player in pairs(game.players) do
                local gui_name = "assembly_combinator_gui_" .. data.entity.unit_number
                local gui = player.gui.screen[gui_name]
                if gui and gui.content and gui.content.working then
                    local working_sprite = "utility/"
                    local working_label = ""
                    if data.cpu:is_halted() then
                        working_sprite = working_sprite .. "status_not_working"
                        working_label = working_label .. "Halted"
                    elseif #data.cpu:get_errors() ~= 0 then
                        working_sprite = working_sprite .. "status_yellow"
                        working_label = working_label .. "Error"
                    else
                        working_sprite = working_sprite .. "status_working"
                        working_label = working_label .. "Working"
                    end
                    gui.content.working.working_icon.sprite = working_sprite
                    gui.content.working.working_label.caption = working_label
                end
            end

            -- Update "connected" GUI element
            local green_network = entity.get_circuit_network(defines.wire_type.green)
            local red_network = entity.get_circuit_network(defines.wire_type.red)

            local connected_label_caption = ""
            if green_network or red_network then
                connected_label_caption = "Connected to circuit network"
            else
                connected_label_caption = "Not connected"
            end

            for _, player in pairs(game.players) do
                local gui_name = "assembly_combinator_gui_" .. data.entity.unit_number
                local gui = player.gui.screen[gui_name]
                if gui and gui.content
                    and gui.content.connected
                    and gui.content.connected.connected_label
                then
                    gui.content.connected.connected_label.caption = connected_label_caption
                end
            end

            -- Handle outputs
            for i = 0, 3 do
                local output = data.cpu:get_register("o" .. i)
                if output.count > 0 and output.name ~= nil then
                    local behavior = entity.get_control_behavior()

                    if behavior.sections_count == 0 then
                        behavior.add_section()
                    end
                    behavior.get_section(1).set_slot(1, {
                        value = { type = "item", name = output.name, quality = "normal" },
                        min = output.count,
                    })
                end
            end
        end
        ::continue::
    end
end)
