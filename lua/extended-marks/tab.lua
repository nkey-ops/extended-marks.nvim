local utils = require('extended-marks.utils')
local M = { opts = {} }
M.opts.max_key_seq = 1


local api = vim.api
M.set_mark = function(first_char)
    local mark_key = utils.get_mark_key(Opts.max_key_seq, first_char)
    if (mark_key == nil) then return end

    local win = api.nvim_get_current_win()
    local tabpage = api.nvim_win_get_tabpage(win);
    vim.api.nvim_tabpage_set_var(tabpage, "mark_key", mark_key)

    print(string.format("Marks:[%s:%s]", mark_key, tabpage))
end

M.jump_to_mark = function(first_char)
    assert(first_char ~= nil and type(first_char) == "number",
        "First mark key character value should not be nil and be of a type number")
    assert(first_char >= 65 and first_char <= 90 or first_char >= 97 and first_char <= 122,
        "First mark key character value should be [a-zA-Z]")

    local mark_key = utils.get_mark_key(M.opts.max_key_seq, first_char)
    if mark_key == nil then return end

    for _, tab_id in pairs(api.nvim_list_tabpages()) do
        if vim.t[tab_id]["mark_key"] == mark_key then
            api.nvim_set_current_win(api.nvim_tabpage_get_win(tab_id))
            break
        end
    end
end

return M
