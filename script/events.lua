local cpu = require("cpu")

script.on_event(defines.events.on_built_entity, function(event)
    if event.entity.name == "assembly-combinator" then
        storage.assembly_combinators[event.entity.unit_number] = {
            entity = event.entity,
            cpu = cpu.new(),
            last_process_tick = game.tick,
        }
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
                return
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
    end
end)
