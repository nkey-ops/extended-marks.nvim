local utils = require('extended-marks.utils')

local cwd = {}
local Opts = {
    data_file = vim.fn.glob("~/.cache/nvim/extended-marks") .. "/cwd_marks.json",
    key_length = 5,
}
cwd.Opts = Opts

--- @class Opts
--- @field data_dir? string path to the data directory
--- @field key_length? number max number of characters in the mark (1 to 30)

--- sets the options for the cwd module
--- @param opts Opts
function cwd.set_options(opts)
    assert(opts ~= nil, "Opts cannot be nil")
    assert(type(opts) == 'table', "Opts should be of a type  table")

    if opts.key_length then
        local key_length = opts.key_length
        assert(type(key_length) == 'number', "key_length should be of type number")
        assert(key_length > 0 and key_length < 30,
            "key_length should be more than 0 and less than 30. Current value is " .. key_length)

        Opts.key_length = key_length
    end

    if opts.data_dir then
        local data_dir = opts.data_dir
        assert(type(data_dir) == 'string', "data_dir should be of type string")

        Opts.data_file = data_dir:gsub('/$', '') .. '/cwd_marks.json'
    end

    if not io.open(Opts.data_file, 'r') then
        assert(io.open(Opts.data_file, 'w')):close()
    end
end

function cwd.set_cwd_mark(first_char)
    local mark_key = utils.get_mark_key(Opts.key_length, first_char)
    if (mark_key == nil) then return end

    local working_dir = vim.fn.getcwd()
    local marked_file = vim.api.nvim_buf_get_name(0)
    local data = utils.get_json_decoded_data(Opts.data_file, working_dir)

    data[working_dir][mark_key] = marked_file

    utils.write_marks(Opts.data_file, data)
    print("MarksCwd:[" .. mark_key .. "]", marked_file)
end

---Jumps to the cwd mark (i.e. buffer if possible) using first_char as the
---first character of the mark key and requesting from the client more characters
---to input as long as 'key_length' allows to create a complete mark key.
---The mark key is used to locate the file attached to it and if it is present
---the buffer will be opened using the located file in the current window
---otherwise nothing will happen
---@param first_char number represents the first character of the mark that should be in between
--- 65 >= first_char <= 90 or 97 >= first_char <= 122
--- that is equal to the pattern [a-zA-Z] if we convert to a string
function cwd.jump_to_cwd_mark(first_char)
    assert(first_char ~= nil and type(first_char) == "number",
        "First mark key character value should not be nil and be of a type number")
    assert(first_char >= 65 and first_char <= 90 or first_char >= 97 and first_char <= 122,
        "First mark key character value should be [a-zA-Z]")

    local working_dir = vim.fn.getcwd()
    local marks = utils.get_json_decoded_data(Opts.data_file, working_dir)

    local mark_key = utils.get_mark_key(Opts.key_length, first_char)

    if mark_key == nil then return end

    local marked_file = marks[working_dir][mark_key]
    -- No file was marked with this key
    if marked_file == nil then
        return
    end

    -- if the buffer is present, open it
    if vim.fn.bufexists(marked_file) == 1 then
        vim.cmd(vim.fn.bufadd(marked_file) .. "b")
        return
    end

    -- the file doesn't exist or is no readable
    if vim.fn.filereadable(marked_file) == 0 then
        print(string.format(
            "MarksCwd: file wasn't found or is not readable \"%s\"", marked_file))
        return
    end

    -- if the file exist and is readable
    -- 1. add the file as a buffer
    -- 2. load the buffer
    -- 3. set 'buflisted' option to true
    -- 4. open the buffer
    local buf = vim.fn.bufadd(marked_file)
    vim.fn.bufload(buf)
    assert(vim.api.nvim_buf_is_loaded(buf), "buf should be loaded")

    vim.api.nvim_set_option_value("buflisted", true, { buf = buf })
    assert(vim.fn.buflisted(buf) ~= 0, "buf should be listed")

    vim.api.nvim_set_current_buf(buf)
end

-- Cwd Functions
--- displays a list of all cwd marks related to the current working directory (cwd)
function cwd.show_cwd_marks()
    local working_dir = vim.fn.getcwd()
    local marks = utils.get_json_decoded_data(
        Opts.data_file, working_dir)[working_dir]

    table.sort(marks)
    vim.api.nvim_echo({ { vim.inspect(marks) } },
        false, { verbose = false })
end

--- displays a list of all cwd marks and their related current working directories (cwd)
function cwd.show_all_cwd_marks()
    local marks = utils.get_json_decoded_data(Opts.data_file)
    table.sort(marks)

    vim.api.nvim_echo({ { vim.inspect(marks) } },
        false, { verbose = false })
end

--- deletes the cwd mark withing the current working directory (cwd)
--- @param mark_key string of the mark to be deleted
function cwd.delete_cwd_mark(mark_key)
    assert(mark_key ~= nil, "mark_key cannot be nil")
    assert(string.len(mark_key) < 10, "mark_key is too long")

    local working_dir = vim.fn.getcwd()
    local data = utils.get_json_decoded_data(Opts.data_file)

    if data[working_dir] == nil then
        data[working_dir] = {}
        return
    end

    local mark = data[working_dir][mark_key]
    if (mark == nil) then
        print("MarksCwd: Couldn't delete because [" .. mark_key .. "] wasn't found")
        return
    end

    data[working_dir][mark_key] = nil

    if next(data[working_dir]) == nil then
        data[working_dir] = nil
    end

    utils.write_marks(Opts.data_file, data)

    print("MarksCwd:[" .. mark_key .. "] was removed")
end

function cwd.get_key_length()
    return Opts.key_length
end

return cwd
