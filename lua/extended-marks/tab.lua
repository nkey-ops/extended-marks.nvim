local utils = require('extended-marks.utils')

local tab = {}
local Opts = {
    key_length = 1,
}

local api = vim.api

tab.show_tab_marks = function()
    local marks = {}
    for i, tab_id in pairs(api.nvim_list_tabpages()) do
        local mark_key = vim.t[tab_id]["mark_key"]
        if mark_key then
            marks[i .. ""] = mark_key
        end
    end
    vim.api.nvim_echo({ { vim.inspect(marks) } }, false, { verbose = false })
end


tab.set_mark = function(first_char)
    local mark_key = utils.get_mark_key(Opts.key_length, first_char)
    if (mark_key == nil) then return end

    local win = api.nvim_get_current_win()
    local tabpage = api.nvim_win_get_tabpage(win);
    api.nvim_tabpage_set_var(tabpage, "mark_key", mark_key)

    print(string.format("MarksTab:[%s:%s]", mark_key, tabpage))
end

tab.jump_to_mark = function(first_char)
    assert(first_char ~= nil and type(first_char) == "number",
        "First mark key character value should not be nil and be of a type number")
    assert(first_char >= 65 and first_char <= 90 or first_char >= 97 and first_char <= 122,
        "First mark key character value should be [a-zA-Z]")

    local mark_key = utils.get_mark_key(Opts.key_length, first_char)

    if mark_key == nil then return end

    for _, tab_id in pairs(api.nvim_list_tabpages()) do
        if vim.t[tab_id]["mark_key"] == mark_key then
            api.nvim_set_current_win(api.nvim_tabpage_get_win(tab_id))
            break
        end
    end
end


function tab.set_options(opts)
    assert(opts ~= nil, "Opts cannot be nil")
    assert(type(opts) == 'table', "Opts should be of a type  table")

    if opts.key_length then
        local key_length = opts.key_length
        assert(type(key_length) == 'number', "key_length should be of type number")
        assert(key_length > 0 and key_length < 30,
            "key_length should be more than zero and less than 30. Current value is " .. key_length)
        Opts.key_length = key_length
    end
end

function tab.get_key_length()
    return Opts.key_length
end

return tab
