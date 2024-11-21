local utils = require('extended-marks.utils')

local M = {}
local Opts = {
    max_key_seq = 1,
}

local api = vim.api

M.show_tab_marks = function()
    local marks = {}
    for i, tab_id in pairs(api.nvim_list_tabpages()) do
        local mark_key = vim.t[tab_id]["mark_key"]
        if mark_key then
            marks[i .. ""] = mark_key
        end
    end
    vim.api.nvim_echo({ { vim.inspect(marks) } }, false, { verbose = false })
end


M.set_mark = function(first_char)
    local mark_key = utils.get_mark_key(Opts.max_key_seq, first_char)
    if (mark_key == nil) then return end

    local win = api.nvim_get_current_win()
    local tabpage = api.nvim_win_get_tabpage(win);
    api.nvim_tabpage_set_var(tabpage, "mark_key", mark_key)

    print(string.format("MarksTab:[%s:%s]", mark_key, tabpage))
end

M.jump_to_mark = function(first_char)
    assert(first_char ~= nil and type(first_char) == "number",
        "First mark key character value should not be nil and be of a type number")
    assert(first_char >= 65 and first_char <= 90 or first_char >= 97 and first_char <= 122,
        "First mark key character value should be [a-zA-Z]")

    local mark_key = utils.get_mark_key(Opts.max_key_seq, first_char)

    if mark_key == nil then return end

    for _, tab_id in pairs(api.nvim_list_tabpages()) do
        if vim.t[tab_id]["mark_key"] == mark_key then
            api.nvim_set_current_win(api.nvim_tabpage_get_win(tab_id))
            break
        end
    end
end


function M.set_options(opts)
    assert(opts ~= nil, "Opts cannot be nil")
    assert(type(opts) == 'table', "Opts should be of a type  table")

    if opts.max_key_seq then
        local max_key_seq = opts.max_key_seq
        assert(type(max_key_seq) == 'number', "max_key_seq should be of type number")
        assert(max_key_seq > 0 and max_key_seq < 30,
            "max_key_seq should be more than zero and less than 30. Current value is " .. max_key_seq)
        Opts.max_key_seq = max_key_seq
    end
end

return M
