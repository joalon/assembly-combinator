local M = {}

M.menu = {
    reference = { registers = 1, instructions = 1 },
    tutorial  = { ["hello-signal"] = 1, counter = 1, branching = 1 },
}

M.text_counts = {
    ["assembly-combinator"] = 1,
    reference                = 1,
    registers                = 3,
    instructions             = 12,
    tutorial                 = 1,
    ["hello-signal"]         = 2,
    counter                  = 2,
    branching                = 2,
}

function M.informatron_menu(_data)
    return M.menu
end

function M.informatron_page_content(data)
    local n = M.text_counts[data.page_name]
    if not n then return end
    for i = 1, n do
        data.element.add({
            type    = "label",
            caption = { "assembly-combinator.page_" .. data.page_name .. "_text_" .. i },
        })
    end
end

return M
