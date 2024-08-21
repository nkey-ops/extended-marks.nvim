local utils = require('extended-marks.utils')

--[[
    local_marks file structure
    "buffer path i.e file path": {  -- TODO it's an object for some reason should be an array
        "mark_key with form [a-z]{1,max_key_seq}":  [ -- TODO it's an array for some reason should be an object
            number: id of the mark in the namespace,
            number: line number (zero based, api-indexing),
            number: column number (zero based, api-indexing)
        ]
    }
--]]

local M = {}
local Opts = {
    local_marks_file_path = vim.fn.glob("~/.cache/nvim/extended-marks") .. "/local_marks.json",
    local_marks_namespace = vim.api.nvim_create_namespace("local_marks"),
    max_key_seq = 1,
    sign_text = 0,
    exhaustion_matcher = false,
}

-- @start_char
M.set_local_mark = function(first_char)
    assert(first_char ~= nil, "start_char cannot be nil")
    assert(type(first_char) == "number", "start_char should be of type number")
    assert(first_char >= 97 and first_char <= 122,
        "start_char should be a lowercase ascii character [a-z]")

    local mark_key = utils.get_mark_key(Opts.max_key_seq, first_char)
    if (mark_key == nil) then return end

    local current_buffer_id = vim.api.nvim_get_current_buf()
    local local_buffer_name = vim.api.nvim_buf_get_name(current_buffer_id)
    local buffers =
        utils.get_json_decoded_data(Opts.local_marks_file_path, local_buffer_name)

    -- set mark with one or two letters from the mark_key behind the line_numer
    local extmark_opts = {}
    if Opts.sign_text ~= 0 then
        extmark_opts = { sign_text = string.sub(mark_key, 1, Opts.sign_text) }
    end

    -- if the local mark exists, add to extmark_opts an id of
    -- it in the name_space to edit it
    if buffers[local_buffer_name][mark_key] ~= nil then
        extmark_opts.id = buffers[local_buffer_name][mark_key][1]
    end

    local pos = vim.api.nvim_win_get_cursor(0)
    pos[1] = pos[1] - 1 -- zero-based api-indexing
    local marked_line_string = vim.api.nvim_buf_get_lines(
        current_buffer_id, pos[1], pos[1] + 1, true)[1]

    extmark_opts.end_col = string.len(marked_line_string)

    -- place mark at the beginning of the line
    local mark_id = vim.api.nvim_buf_set_extmark(
        current_buffer_id, Opts.local_marks_namespace, pos[1], 0,
        extmark_opts)

    buffers[local_buffer_name][mark_key] = { mark_id, pos[1], 0 }

    utils.write_marks(Opts.local_marks_file_path, buffers)

    print(
        string.format("Marks:[%s:%s] \"%s\"", mark_key, pos[1] + 1, marked_line_string))
end

M.jump_to_local_mark = function(first_char)
    assert(first_char ~= nil, "first_char cannot be nil")
    assert(type(first_char) == "number", "first_char should be of type number")
    assert(first_char >= 97 and first_char <= 122,
        "first_char should be a lowercase ascii character [a-z]")

    local local_buffer_name = vim.api.nvim_buf_get_name(0)
    local local_marks =
        utils.get_json_decoded_data(
            Opts.local_marks_file_path, local_buffer_name)[local_buffer_name]

    local mark_key
    if Opts.exhaustion_matcher then
        mark_key = utils.get_last_mark_key(Opts.max_key_seq,
            utils.copy_keys(local_marks), first_char)
    else
        mark_key = utils.get_mark_key(Opts.max_key_seq, first_char)
    end


    -- the remaining mark_key wasn't found(it was mistyped apparently) just ignore the jump
    if mark_key == nil then return end
    local mark_id = local_marks[mark_key][1]

    local position = vim.api.nvim_buf_get_extmark_by_id(
        0, Opts.local_marks_namespace, mark_id, {})

    position[1] = position[1] + 1; -- api`s line and column position is (1,0) based
    vim.api.nvim_win_set_cursor(0, position)
end


function M.show_local_marks()
    local local_buffer_name = vim.api.nvim_buf_get_name(0)
    local current_buffer_id = vim.api.nvim_get_current_buf()
    local marks = utils.get_json_decoded_data(
        Opts.local_marks_file_path, local_buffer_name)[local_buffer_name]


    table.sort(marks)
    for mark_key, mark in pairs(marks) do
        local pair =
            vim.api.nvim_buf_get_extmark_by_id(
                current_buffer_id, Opts.local_marks_namespace, mark[1], {})

        assert(pair ~= nil and pair[1] ~= nil, string.format("Nil for [%s:%s]", mark_key, vim.inspect(mark)))

        marks[mark_key] =
            vim.api.nvim_buf_get_lines(
                current_buffer_id, pair[1], pair[1] + 1, true)[1]
    end

    vim.api.nvim_echo({ { vim.inspect(marks) } },
        false, { verbose = false })
end

-- Shows raw raw data for performance reasons
function M.show_all_local_marks()
    local marks = utils.get_json_decoded_data(Opts.local_marks_file_path)

    table.sort(marks)

    vim.api.nvim_echo({ { vim.inspect(marks) } },
        false, { verbose = false })
end

function M.delete_local_mark(mark_key)
    assert(mark_key ~= nil, "mark_key cannot be nil")
    assert(type(mark_key) == "string", "mark_key should be of type strin")
    assert(string.len(mark_key) < 10, "mark_key is too long")

    local current_buffer_name = vim.api.nvim_buf_get_name(0)
    local marks = utils.get_json_decoded_data(Opts.local_marks_file_path, current_buffer_name)

    local mark = marks[current_buffer_name][mark_key]
    if (mark == nil) then
        print(string.format("Marks:[%s] wasn't found", mark_key))
        return
    end

    vim.api.nvim_buf_del_extmark(0, Opts.local_marks_namespace, mark[1])
    marks[current_buffer_name][mark_key] = nil

    if next(marks[current_buffer_name]) == nil then
        marks[current_buffer_name] = nil
    end

    utils.write_marks(Opts.local_marks_file_path, marks)

    print(string.format("Marks:[%s:%s] was removed", mark_key, mark[2]))
end

function M.set_max_seq_local_mark(max_seq)
    assert(max_seq ~= nil)

    if (type(max_seq) == "string") then
        max_seq = tonumber(max_seq)
    end

    assert(type(max_seq) == "number" and max_seq > 0 and max_seq < 50)

    Opts.max_key_seq = max_seq
end

-- Updates marks from the namespace to the data file
function M.update()
    local current_buffer_id = vim.api.nvim_get_current_buf()
    local local_buffer_name = vim.api.nvim_buf_get_name(current_buffer_id)
    local buffers           = utils.get_json_decoded_data(
        Opts.local_marks_file_path, local_buffer_name)

    for mark_key, mark in pairs(buffers[local_buffer_name]) do
        local pair =
            vim.api.nvim_buf_get_extmark_by_id(
                current_buffer_id, Opts.local_marks_namespace, mark[1], {})

        if (pair ~= nil and pair[1] ~= nil and pair[2] ~= nil) then
            buffers[local_buffer_name][mark_key] = { mark[1], pair[1], pair[2] }
        else
            print(string.format("Couldn't find mark in the namespace:[%s:%s]", mark_key, mark))
        end
    end

    if next(buffers[local_buffer_name]) ~= nil then
        utils.write_marks(Opts.local_marks_file_path, buffers)
    end
end

-- Local marks from the data file: local_marks.json into the namespace
--
-- TIME Coplexity: O(N+M)
-- where N is then number of source marks and
-- M is the number of marks present in the namespace
function M.restore()
    local current_buffer_id = vim.api.nvim_get_current_buf()
    local local_buffer_name = vim.api.nvim_buf_get_name(current_buffer_id)

    local local_marks = utils.get_json_decoded_data(
        Opts.local_marks_file_path, local_buffer_name)[local_buffer_name]
    local namespace_marks =
        vim.api.nvim_buf_get_extmarks(
            current_buffer_id, Opts.local_marks_namespace, 0, -1, {})
    local max_lines = vim.api.nvim_buf_line_count(current_buffer_id)

    for s_mark_key, s_mark in pairs(local_marks) do
        local was_found = false

        for n_key, n_mark in pairs(namespace_marks) do
            -- if mark ids are equal
            if s_mark[1] == n_mark[1] then
                -- if mark lines positions (zero based) are equal
                if s_mark[2] == n_mark[2] then
                    was_found = true
                end
                namespace_marks[n_key] = nil
                break
            end
        end

        -- adding mark from the data file if it wasn't found in the namespace
        if not was_found then
            if s_mark[2] <= max_lines then -- isn't out of bounds
                local opts = { id = s_mark[1] }

                if Opts.sign_text ~= 0 then
                    opts.sign_text = string.sub(s_mark_key, 1, Opts.sign_text)
                end

                vim.api.nvim_buf_set_extmark(current_buffer_id,
                    Opts.local_marks_namespace, s_mark[2], s_mark[3], opts)
            else
                print(string.format("Marks: The mark was out of bounds: [%s:%s] max lines %s", s_mark_key, s_mark[2],
                    max_lines))
            end
        end
    end
end

-- temporarily added for dev
function M.wipe()
    local current_buffer_id = vim.api.nvim_get_current_buf()
    local local_buffer_name = vim.api.nvim_buf_get_name(current_buffer_id)
    local local_marks = utils.get_json_decoded_data(
        Opts.local_marks_file_path, local_buffer_name)

    local_marks[local_buffer_name] = nil
    utils.write_marks(Opts.local_marks_file_path, local_marks)
end

function M.space()
    print(vim.inspect(vim.api.nvim_buf_get_extmarks(0, Opts.local_marks_namespace, 0, -1, {})))
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
        assert(utils.try_create_data_dir(data_dir .. '/local_marks.json'),
            "Couldn't create or use data file 'local_marks.json' with provided dir: " .. data_dir)
        Opts.data_file = data_dir .. "/local_marks.json"
    end

    if opts.sign_text then
        local sign_text = opts.sign_text
        assert(type(sign_text) == 'number', "sing_text should be of type number")
        assert(sign_text >= 0 and sign_text <= 2, "sing_text can only have values 0, 1 and 2")
        Opts.sign_text = sign_text
    end

    if opts.exhaustion_matcher then
        local exhaustion_matcher = opts.exhaustion_matcher
        assert(type(exhaustion_matcher) == 'boolean', "exhaustion_matcher should be of type boolean")
        Opts.exhaustion_matcher = exhaustion_matcher
    end
end

return M
