local utils = require('extended-marks.utils')

local M = { opts = {} }

M.opts.data_dir = vim.fn.glob("~/.local/share/nvim") .. "/extended-marks"
M.opts.global_marks_file_path = M.opts.data_dir .. "/global_marks.json"
M.opts.max_key_seq = 5

M.set_global_mark = function(first_char)
    local mark_key = utils.get_mark_key(M.opts.max_key_seq, first_char)
    if (mark_key == nil) then return end

    local working_dir = vim.fn.getcwd()
    local marked_file = vim.api.nvim_buf_get_name(0)
    local data = utils.get_json_decoded_data(M.opts.global_marks_file_path, working_dir)

    data[working_dir][mark_key] = marked_file

    utils.write_marks(M.opts.global_marks_file_path, data)
    print("Marks:[" .. mark_key .. "]", marked_file)
end

M.jump_to_global_mark = function(first_char)
    assert(first_char ~= nil and type(first_char) == "number",
        "First mark key character value should not be nil and be of a type number")
    assert(first_char >= 65 and first_char <= 90, "First mark key character value should be [A-Z]")

    local working_dir = vim.fn.getcwd()
    local marks = utils.get_json_decoded_data(M.opts.global_marks_file_path, working_dir)

    local mark_key =
        utils.get_last_mark_key(
            M.opts.max_key_seq, utils.copy_keys(marks[working_dir]), first_char)

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
        M.opts.global_marks_file_path, working_dir)[working_dir]

    table.sort(marks)
    vim.api.nvim_echo({ { vim.inspect(marks) } },
        false, { verbose = false })
end

function M.show_all_global_marks()
    local marks = utils.get_json_decoded_data(M.opts.global_marks_file_path)
    table.sort(marks)

    vim.api.nvim_echo({ { vim.inspect(marks) } },
        false, { verbose = false })
end

function M.delete_global_mark(mark_key)
    assert(mark_key ~= nil, "mark_key cannot be nil")
    assert(string.len(mark_key) < 10, "mark_key is too long")

    local working_dir = vim.fn.getcwd()
    local data = utils.get_json_decoded_data(M.opts.global_marks_file_path)

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

    utils.write_marks(M.opts.global_marks_file_path, data)

    print("MarksDelete:[" .. mark_key .. "] was removed")
end

function M.set_max_seq_global_mark(max_seq)
    assert(max_seq ~= nil)

    if (type(max_seq) == "string") then
        max_seq = tonumber(max_seq)
    end

    assert(type(max_seq) == "number" and max_seq > 0 and max_seq < 50)

    M.opts.max_key_seq = max_seq
end

return M
