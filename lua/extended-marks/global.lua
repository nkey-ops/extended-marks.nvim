local utils = require('extended-marks.utils')

--[[
    global marks file structure
    mark_key: with form [a-Z]{1, key_length}, default config allows
               only [A-Z][a-Z]{key_length} but current implementation is broader on the first letter
    path: is just a constant key to signal it's a file_path property
    file_path: full path to the file to be marked

    [
        "mark_key" : {
            "path" : "file_path"
        }
    ]
--]]

--- @class GlobalMark an object of the json array within the data_file
--- @field path string full path to a marked file

local global = {}

--- @class GlobalOpts manages configuration of the glob module
--- @field data_file string path to the data directory
--- @field key_length integer default:4 | max number of characters in the mark [1 to 30)
local GlobalOpts = {
    data_file = vim.fn.glob("~/.cache/nvim/extended-marks") .. "/global_marks.json",
    key_length = 4,
}

--- @class GlobalSetOpts defines which options can be set to configure this module
--- @field data_dir string a path to the data directory
--- @field key_length integer? default:4 | max number of characters in the mark [1 to 30)

--- sets the options for the global module
--- @param opts GlobalSetOpts
function global.set_options(opts)
    assert(opts ~= nil, "opts cannot be nil")
    assert(type(opts) == 'table', "opts should be of a type  table")
    assert(opts.data_dir, "opts.data_dir cannot be nil")
    assert(type(opts.data_dir) == 'string', "data_dir should be of type string")

    GlobalOpts.data_file = opts.data_dir:gsub('/$', '') .. '/global_marks.json'

    if not io.open(GlobalOpts.data_file, 'r') then
        assert(io.open(GlobalOpts.data_file, 'w')):close()
    end

    if opts.key_length then
        global.set_key_length(opts.key_length)
    end
end

--- @param key_length integer max number of characters in the mark [1 to 30)
function global.set_key_length(key_length)
    assert(key_length, "key_length cannot be nil")
    assert(type(key_length) == 'number', "key_length should be of type number")
    assert(key_length > 0 and key_length < 30,
        "key_length should be more than 0 and less than 30. Current value is " .. key_length)

    GlobalOpts.key_length = key_length
end

--- @return integer mark's max key length
function global.get_key_length()
    return GlobalOpts.key_length
end

--- @param first_char integer first character of the mark key
function global.set_mark(first_char)
    local mark_key = utils.get_mark_key(GlobalOpts.key_length, first_char)
    if (mark_key == nil) then return end

    --- @type string
    local marked_file = vim.api.nvim_buf_get_name(0)

    --- @type {[string]:GlobalMark}
    local marks = utils.get_json_decoded_data(GlobalOpts.data_file)

    marks[mark_key] = { path = marked_file }

    utils.write_marks(GlobalOpts.data_file, marks)
    print(string.format("MarksGlobal:[%s] - '%s'", mark_key, marked_file))
end

--- Jumps to the global mark (i.e. buffer if possible) using first_char as the
--- first character of the mark key and requesting from the client more characters
--- to input as long as 'key_length' allows to create a complete mark key.
--- The mark key is used to locate the file attached to it and if it is present
--- the buffer will be opened using the located file in the current window
--- otherwise nothing will happen
---
--- @param first_char number represents the first character of the mark that should be in between
---                          65 >= first_char <= 90 or 97 >= first_char <= 122
---                          that is equal to the pattern [a-zA-Z] if we convert to a string
function global.jump_to_mark(first_char)
    assert(first_char ~= nil and type(first_char) == "number",
        "First mark key character value should not be nil and be of a type number")
    assert(first_char >= 65 and first_char <= 90 or first_char >= 97 and first_char <= 122,
        "First mark key character value should be [a-zA-Z]")

    --- @type {[string]:GlobalMark}
    local marks = utils.get_json_decoded_data(GlobalOpts.data_file)
    local mark_key = utils.get_mark_key(GlobalOpts.key_length, first_char)

    if mark_key == nil then return end

    local global_mark = marks[mark_key]
    -- No file was marked with this key
    if global_mark == nil then
        return
    end

    local path = global_mark.path;

    -- if the buffer is present, open it
    if vim.fn.bufexists(path) == 1 then
        vim.cmd(vim.fn.bufadd(path) .. "b")
        return
    end

    vim.cmd("e " .. path)
end

-- Global Functions
--- displays a list of all global marks
function global.show_marks()
    --- @type {[string]:GlobalMark}"
    local marks = utils.get_json_decoded_data(GlobalOpts.data_file)

    assert(marks)

    table.sort(marks)
    vim.api.nvim_echo({ { vim.inspect(marks) } },
        false, { verbose = false })
end

--- deletes the global mark
--- @param mark_key string of the mark to be deleted
function global.delete_mark(mark_key)
    assert(mark_key ~= nil, "mark_key cannot be nil")
    assert(string.len(mark_key) < 30, "mark_key is too long")

    --- @type {[string]:GlobalMark}
    local marks = utils.get_json_decoded_data(GlobalOpts.data_file)

    local mark = marks[mark_key]
    if (mark == nil) then
        print("MarksGlobalDelete: Couldn't delete because [" .. mark_key .. "] wasn't found")
        return
    end

    local log_path = marks[mark_key].path
    marks[mark_key] = nil

    utils.write_marks(GlobalOpts.data_file, marks)

    print(string.format("MarksGlobalDelete:[%s] - '%s'", mark_key, log_path))
end

--- @return {[string]:GlobalMark}
function global.get_marks()
    return utils.get_json_decoded_data(GlobalOpts.data_file)
end

return global
