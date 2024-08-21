local utils = require('extended-marks.utils')

local M = {}
local Opts = {
    data_file = vim.fn.glob("~/.local/share/nvim/extended-marks") .. "/global_marks.json",
    max_key_seq = 5,
    exhaustion_matcher = false,
}

M.set_global_mark = function(first_char)
    local mark_key = utils.get_mark_key(Opts.max_key_seq, first_char)
    if (mark_key == nil) then return end

    local working_dir = vim.fn.getcwd()
    local marked_file = vim.api.nvim_buf_get_name(0)
    local data = utils.get_json_decoded_data(Opts.data_file, working_dir)

    data[working_dir][mark_key] = marked_file

    utils.write_marks(Opts.data_file, data)
    print("Marks:[" .. mark_key .. "]", marked_file)
end

M.jump_to_global_mark = function(first_char)
    assert(first_char ~= nil and type(first_char) == "number",
        "First mark key character value should not be nil and be of a type number")
    assert(first_char >= 65 and first_char <= 90, "First mark key character value should be [A-Z]")

    local working_dir = vim.fn.getcwd()
    local marks = utils.get_json_decoded_data(Opts.data_file, working_dir)

    local mark_key
    if Opts.exhaustion_matcher then
        mark_key = utils.get_last_mark_key(
            Opts.max_key_seq, utils.copy_keys(marks[working_dir]), first_char)
    else
        mark_key = utils.get_mark_key(Opts.max_key_seq, first_char)
    end


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

    -- doesn't the file exist or is no treadable?
    if vim.fn.filereadable(marked_file) == 0 then
        print(string.format(
            "Marks: file wasn't found or is not readable \"%s\"", marked_file))
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

    vim.api.nvim_buf_set_option(buf, "buflisted", true)
    assert(vim.fn.buflisted(buf) ~= 0, "buf should be listed")

    vim.cmd(buf .. "b")
end

-- Global Functions

function M.show_global_marks()
    local working_dir = vim.fn.getcwd()
    local marks = utils.get_json_decoded_data(
        Opts.data_file, working_dir)[working_dir]

    table.sort(marks)
    vim.api.nvim_echo({ { vim.inspect(marks) } },
        false, { verbose = false })
end

function M.show_all_global_marks()
    local marks = utils.get_json_decoded_data(Opts.data_file)
    table.sort(marks)

    vim.api.nvim_echo({ { vim.inspect(marks) } },
        false, { verbose = false })
end

function M.delete_global_mark(mark_key)
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
        print("MarksDelete:[" .. mark_key .. "] wasn't found")
        return
    end

    data[working_dir][mark_key] = nil

    if next(data[working_dir]) == nil then
        data[working_dir] = nil
    end

    utils.write_marks(Opts.data_file, data)

    print("MarksDelete:[" .. mark_key .. "] was removed")
end

function M.set_max_seq_global_mark(max_seq)
    assert(max_seq ~= nil)

    if (type(max_seq) == "string") then
        max_seq = tonumber(max_seq)
    end

    assert(type(max_seq) == "number" and max_seq > 0 and max_seq < 50)

    Opts.max_key_seq = max_seq
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

    if opts.data_dir then
        local data_dir = opts.data_dir
        assert(type(data_dir) == 'string', "data_dir should be of type string")
        assert(utils.try_create_data_dir(data_dir .. '/global_marks.json'),
            "Couldn't create or use data file 'global_marks.json' with provided dir: " .. data_dir)
        Opts.data_file = data_dir .. "/global_marks.json"
    end

    if opts.exhaustion_matcher then
        local exhaustion_matcher = opts.exhaustion_matcher
        assert(type(exhaustion_matcher) == 'boolean', "exhaustion_matcher should be of type boolean")
        Opts.exhaustion_matcher = exhaustion_matcher
    end
end

return M
