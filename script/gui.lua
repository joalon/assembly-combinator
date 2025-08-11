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
    local gui_name = "assembly_combinator_gui_" .. entity.unit_number
    if player.gui.screen[gui_name] then
        -- following code crashes with "gui_name is nil" error
        -- player.gui.screen.gui_name.bring_to_front()
        return
    end

    local frame = player.gui.screen.add({
        type = "frame",
        name = gui_name,
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
        style = "entity_frame",
    })
    content.style.horizontally_stretchable = true

    local connected = content.add({
        type = "frame",
        name = "connected",
        direction = "horizontal",
        style = "subheader_frame",
    })
    connected.style.horizontally_stretchable = true
    connected.style.horizontally_squashable = true
    connected.style.top_margin = -8
    connected.style.left_margin = -12
    connected.style.right_margin = -12

    local green_network = entity.get_circuit_network(defines.wire_type.green)
    local red_network = entity.get_circuit_network(defines.wire_type.red)

    local connected_label_caption = ""
    if green_network or red_network then
        connected_label_caption = "Connected to circuit network"
    else
        connected_label_caption = "Not connected"
    end

    connected.add({
        type = "label",
        name = "connected_label",
        caption = connected_label_caption,
        style = "subheader_label",
    })

    local working = content.add({
        type = "flow",
        name = "working",
        direction = "horizontal",
    })
    working.style.vertical_align = "center"

    local cpu = storage.assembly_combinators[entity.unit_number].cpu

    local working_sprite = "utility/"
    local working_label = ""
    if cpu:is_halted() then
        working_sprite = working_sprite .. "status_not_working"
        working_label = working_label .. "Halted"
    elseif #cpu:get_errors() ~= 0 then
        working_sprite = working_sprite .. "status_yellow"
        working_label = working_label .. "Error"
    else
        working_sprite = working_sprite .. "status_working"
        working_label = working_label .. "Working"
    end
    working.add {
        type = "sprite",
        name = "working_icon",
        sprite = working_sprite,
        style = "status_image"
    }
    local working_label = working.add({
        type = "label",
        name = "working_label",
        caption = working_label
    })

    local code = ""
    for i, line in ipairs(cpu:get_code()) do
        if i == 1 then
            code = line
        else
            code = code .. "\n" .. line
        end
    end

    local textbox = content.add({
        type = "text-box",
        name = "combinator_memory",
        text = code,
    })
    textbox.style.size = { 300, 300 }

    content.add({
        type = "button",
        name = "assembly-combinator-save-button",
        caption = "Save",
    })

    content.add({
        type = "line"
    })

    local errors = cpu:get_errors()
    local errors_text = ""
    for i, err in ipairs(errors) do
        if i == 1 then
            errors_text = err
        else
            errors_text = errors_text .. "\n" .. err
        end
    end
    content.add({
        type = "label",
        name = "errors",
        caption = errors_text
    })
end

script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "assembly-combinator-close-button" then
        event.element.parent.parent.destroy()
    elseif event.element.name == "assembly-combinator-save-button" then
        local unit_number = tonumber(string.match(event.element.parent.parent.name, "%d+"))

        local updated_code = {}
        for line in string.gmatch(event.element.parent["combinator_memory"].text, "[^\r\n]+") do
            table.insert(updated_code, line)
        end
        storage.assembly_combinators[unit_number].cpu:update_code(updated_code)

        -- reset errors label in GUI
        for _, player in pairs(game.players) do
            local gui_name = "assembly_combinator_gui_" .. unit_number
            local gui = player.gui.screen[gui_name]
            if gui and gui.content and gui.content.errors then
                gui.content.errors.caption = ""
            end
        end
    end
end)

-- TODO: Almost certainly needs updating after introducing multiple windows...
script.on_event(defines.events.on_gui_closed, function(event)
    if event.element and event.element.name == "assembly_combinator_gui" then
        event.element.destroy()
    end
end)
