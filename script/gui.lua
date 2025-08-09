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
        player.gui.screen.gui_name.bring_to_front()
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
        style = "inside_deep_frame",
    })
    content.style.padding = 12

    local cpu = storage.assembly_combinators[entity.unit_number].cpu
    local code = ""
    for i, line in ipairs(cpu:get_code()) do
        if i == 1 then
            code = line
        else
            code = code .. "\n" .. line
        end
    end

    content.add({
        type = "text-box",
        name = "combinator_memory",
        text = code,
    })

    content.add({
        type = "button",
        name = "assembly-combinator-save-button",
        caption = "Save",
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
        -- reset errors
    end
end)

-- TODO: Almost certainly needs updating after introducing multiple windows...
script.on_event(defines.events.on_gui_closed, function(event)
    if event.element and event.element.name == "assembly_combinator_gui" then
        event.element.destroy()
    end
end)
