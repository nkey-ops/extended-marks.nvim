local utils = require('extended-marks.utils')

--[[
    Marks are stored under vim.t[tab_id][mark_key_var_name]
    A mark can only be assigned to a single tab
    Marks aren't stored only in the session
--]]

local tab = {}

--- @class TabOpts manages configuration of the tab module
--- @field key_length number default:1 | max number of characters in the mark [1 to 30)
local TabOpts = {
    key_length = 1,
}

local mark_key_var_name = "mark_key"
local api = vim.api

--- @class TabSetOpts
--- @field key_length? integer default:1 | max number of characters in the mark [1 to 30)

--- @param opts TabSetOpts
function tab.set_options(opts)
    assert(opts ~= nil, "opts cannot be nil")
    assert(type(opts) == 'table', "opts should be of a type table")

    if opts.key_length then
        local key_length = opts.key_length
        assert(type(key_length) == 'number', "key_length should be of a type number")
        assert(key_length > 0 and key_length < 30,
            "key_length should be more than 0 and less than 30. Current value is " .. key_length)
        TabOpts.key_length = key_length
    end
end

--- Sets a mark on a current opened tab. If the mark key input is correct,
--- the mark will start with the "first_char", contain only [a-zA-Z] characters,
--- and will have the length of no more than @TabOpts.key_length
--- If input is not correct, does nothing
--- @param first_char number represents the first character of the mark that
--- should be in between 65 >= first_char <= 90 or 97 >= first_char <= 122
--- that is equal to the pattern [a-zA-Z] if we convert to a string
tab.set_mark = function(first_char)
    assert(first_char ~= nil and type(first_char) == "number",
        "First mark key character value should not be nil and be of a type number")
    assert(first_char >= 65 and first_char <= 90 or first_char >= 97 and first_char <= 122,
        "First mark key character value should be [a-zA-Z]")

    local mark_key = utils.get_mark_key(TabOpts.key_length, first_char)
    if (mark_key == nil) then return end

    print(mark_key .. " found")
    tab.delete_tab_mark(mark_key) -- removing a previous one, if present
    print(mark_key .. " deleted")
    api.nvim_tabpage_set_var(0, mark_key_var_name, mark_key)

    local tabpage = api.nvim_win_get_tabpage(0);
    print(string.format("MarksTab:[%s:%s]", mark_key, tabpage))
end

--- Jumps to a tab page containing inputted mark. If the mark key input is correct,
--- the mark will start with the "first_char", contain only [a-zA-Z] characters,
--- and will have the length of no more than @TabOpts.key_length.
--- If input is not correct, does nothing
--- @param first_char number represents the first character of the mark that
--- should be in between 65 >= first_char <= 90 or 97 >= first_char <= 122
--- that is equal to the pattern [a-zA-Z] if we convert to a string
tab.jump_to_mark = function(first_char)
    assert(first_char ~= nil and type(first_char) == "number",
        "First mark key character value should not be nil and be of a type number")
    assert(first_char >= 65 and first_char <= 90 or first_char >= 97 and first_char <= 122,
        "First mark key character value should be [a-zA-Z]")

    local mark_key = utils.get_mark_key(TabOpts.key_length, first_char)

    print(mark_key .. " got")
    if mark_key == nil then return end

    for _, tab_id in pairs(api.nvim_list_tabpages()) do
        if vim.t[tab_id][mark_key_var_name] == mark_key then
            api.nvim_set_current_win(api.nvim_tabpage_get_win(tab_id))
            return
        end
    end

    print(string.format("MarksTab: Mark wasn't found: [%s]", mark_key))
end

--- CMD Functions
--- displays a list of all tab marks
tab.show_tab_marks = function()
    local marks = {}
    for i, tab_id in pairs(api.nvim_list_tabpages()) do
        local mark_key = vim.t[tab_id][mark_key_var_name]
        if mark_key then
            marks[i .. ""] = mark_key
        end
    end
    vim.api.nvim_echo({ { vim.inspect(marks) } }, false, { verbose = false })
end

--- If mark_key is present
---     Iterates through all the tab pages and searches for a "mark_key" variable,
---     if present, deletes the variable "mark_key" off the tab page and returns
--- If mark_key is nil:
---    for the current tab page deletes the variable "mark_key"
--- @param mark_key string? mark's key to be deleted, if absent a key assigned
--- to the current tab will be deleted
tab.delete_tab_mark = function(mark_key)
    if mark_key then
        assert(type(mark_key) == "string", "mark_key should be of type string")

        for _, tab_id in pairs(api.nvim_list_tabpages()) do
            local tab_mark = vim.t[tab_id][mark_key_var_name]

            if tab_mark and type(tab_mark) == "string" and tab_mark:match(mark_key) then
                api.nvim_tabpage_del_var(tab_id, mark_key_var_name)
                print(string.format("MarksTabDelete:[%s:%s]", mark_key, tab_id))
                return
            end
        end
    else
        api.nvim_tabpage_del_var(0, mark_key_var_name)
    end
end

function tab.get_key_length()
    return TabOpts.key_length
end

return tab
