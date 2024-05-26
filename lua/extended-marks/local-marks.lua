local utils = require('extended-marks.utils')

local M = { opts = {} }
--[[
    local_marks file structure
    "buffer path i.e file path": {  -- TODO it's an object for some reason should be an array
        "mark with then form [a-z]{1,max_key_seq}":  [ -- TODO it's an array for some reason should be an objer
            number: id of the mark in the namespace,
            number: line number (zero based, api-indexing),
            number: column number (zero based, api-indexing)
        ]
    }
--]]

M.opts.data_dir = vim.fn.glob("~/.local/share/nvim") .. "/extended-marks_v2"
M.opts.local_marks_file_path = M.opts.data_dir .. "/local_marks.json"
M.opts.local_marks_name_space = vim.api.nvim_create_namespace("local_marks")
M.opts.max_key_seq = 1

-- @start_char
M.set_local_mark = function(first_char)
    assert(first_char ~= nil, "start_char cannot be nil")
    assert(type(first_char) == "number", "start_char should be of type number")
    assert(first_char >= 97 and first_char <= 122,
        "start_char should be a lowercase ascii character [a-z]")

    local mark_key = utils.get_mark_key(M.opts.max_key_seq, first_char)
    if (mark_key == nil) then return end

    local local_buffer_name = vim.api.nvim_buf_get_name(0)
    local local_buffer_id = vim.api.nvim_get_current_buf()
    local buffers =
        utils.get_json_decoded_data(M.opts.local_marks_file_path, local_buffer_name)

    -- set mark with one or two letters from the mark_key behind the line_numer
    local extmark_opts = { sign_text = string.sub(mark_key, 1, 2) }

    -- if the local mark exists, add to extmark_opts an id of
    -- it in the name_space to edit it
    if buffers[local_buffer_name][mark_key] ~= nil then
        extmark_opts.id = buffers[local_buffer_name][mark_key][1]
    end

    local pos = vim.api.nvim_win_get_cursor(0)
    pos[1] = pos[1] - 1 -- zero-based api-indexing
    local marked_line_string = vim.api.nvim_buf_get_lines(
        local_buffer_id, pos[1], pos[1] + 1, true)[1]

    extmark_opts.end_col = string.len(marked_line_string)

    -- place mark at the beginning of the line
    local mark_id = vim.api.nvim_buf_set_extmark(
        local_buffer_id, M.opts.local_marks_name_space, pos[1], 0,
        extmark_opts)

    buffers[local_buffer_name][mark_key] = { mark_id, pos[1], 0 }

    utils.write_marks(M.opts.local_marks_file_path, buffers)

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
            M.opts.local_marks_file_path, local_buffer_name)[local_buffer_name]

    local mark_key =
        utils.get_last_mark_key(M.opts.max_key_seq,
            utils.copy_keys(local_marks), first_char)

    -- the remaining mark-key wasn't found(it was mistyped apparently) just ignore the jump
    if mark_key == nil then return end
    local mark_id = local_marks[mark_key][1]

    local position = vim.api.nvim_buf_get_extmark_by_id(
        0, M.opts.local_marks_name_space, mark_id, {})

    position[1] = position[1] + 1; -- api`s line and column position is (1,0) based
    vim.api.nvim_win_set_cursor(0, position)
end


function M.show_local_marks()
    local local_buffer_name = vim.api.nvim_buf_get_name(0)
    local local_buffer_id = vim.api.nvim_get_current_buf()
    local marks = utils.get_json_decoded_data(
        M.opts.local_marks_file_path, local_buffer_name)[local_buffer_name]

    table.sort(marks)
    for mark_key, mark in pairs(marks) do
        local pair =
            vim.api.nvim_buf_get_extmark_by_id(
                local_buffer_id, M.opts.local_marks_name_space, mark[1], {})

        assert(pair ~= nil and pair[1] ~= nil)

        marks[mark_key] =
            vim.api.nvim_buf_get_lines(
                local_buffer_id, pair[1], pair[1] + 1, true)[1]
    end

    vim.api.nvim_echo({ { vim.inspect(marks) } },
        false, { verbose = false })
end

-- Shows raw raw data for performance reasons
function M.show_all_local_marks()
    local local_buffer_name = vim.api.nvim_buf_get_name(0)
    local marks = utils.get_json_decoded_data(
        M.opts.local_marks_file_path, local_buffer_name)

    table.sort(marks)

    vim.api.nvim_echo({ { vim.inspect(marks) } },
        false, { verbose = false })
end

function M.delete_local_mark(mark_key)
    assert(mark_key ~= nil, "mark_key cannot be nil")
    assert(type(mark_key) == "string", "mark_key should be of type strin")
    assert(string.len(mark_key) < 10, "mark_key is too long")

    local current_buffer_name = vim.api.nvim_buf_get_name(0)
    local marks = utils.get_json_decoded_data(M.opts.local_marks_file_path, current_buffer_name)

    local mark = marks[current_buffer_name][mark_key]
    if (mark == nil) then
        print("Marks:[" .. mark_key .. "] wasn't found")
        return
    end

    vim.api.nvim_buf_del_extmark(0, M.opts.local_marks_name_space, mark[1])
    marks[current_buffer_name][mark_key] = nil

    utils.write_marks(M.opts.local_marks_file_path, marks)

    print("Marks:[" .. mark_key .. "] was removed")
end

function M.set_max_seq_local_mark(max_seq)
    assert(max_seq ~= nil)

    if (type(max_seq) == "string") then
        max_seq = tonumber(max_seq)
    end

    assert(type(max_seq) == "number" and max_seq > 0 and max_seq < 50)

    M.opts.max_key_seq = max_seq
end

function M.update_local_marks()
    local lcal_buffer_id = vim.api.nvim_get_current_buf()
    local local_buffer_name = vim.api.nvim_buf_get_name(local_buffer_id)
    local marks = utils.get_json_decoded_data(
        M.opts.local_marks_file_path, local_buffer_name)

    for mark_key, mark in pairs(marks[local_buffer_name]) do
        local pair =
            vim.api.nvim_buf_get_extmark_by_id(
                local_buffer_id, M.opts.local_marks_name_space, mark[1], {})

        assert(pair ~= nil and pair[1] ~= nil and pair[2] ~= nil)

        marks[local_buffer_name][mark_key] = { mark[1], pair[1], pair[2] }
    end

    utils.write_marks(M.opts.local_marks_file_path, marks)
end

-- TIME Coplexity: O(N+M)
-- where N is then number of source marks and
-- M is the number of parks that a present in the buffer's name space
function M.restore_local_marks()
    local current_buffer_id = vim.api.nvim_get_current_buf()
    local current_buffer_name = vim.api.nvim_buf_get_name(current_buffer_id)
    local local_marks = utils.get_json_decoded_data(
        M.opts.local_marks_file_path, current_buffer_name)[current_buffer_name]
    local name_space_marks =
        vim.api.nvim_buf_get_extmarks(
            current_buffer_id, M.opts.local_marks_name_space, 0, -1, {})
    local max_lines = vim.api.nvim_buf_line_count(current_buffer_id)

    for mark_key, mark in pairs(local_marks) do
        local was_found = false

        --TODO assert that n_space mark doesn't contain marks
        --that aren't present in the source
        -- reseting the mark that has a position that is out of bounds
        for n_key, n_mark in pairs(name_space_marks) do
            if mark[1] == n_mark[1] then -- found the mark
                was_found = true
                name_space_marks[n_key] = nil
                if n_mark[2] == max_lines then -- then mark is out of the bounds
                    --TODO what if mark[1] id isn't in asceeding order and overlaps with
                    --a newly created one
                    vim.api.nvim_buf_set_extmark(current_buffer_id,
                        M.opts.local_marks_name_space, mark[2], mark[3], {
                            id = mark[1],
                            sign_text = string.sub(mark_key, 1, 2)
                        })
                    break
                end
            end
        end

        -- adding a new mark
        if not was_found then
            vim.api.nvim_buf_set_extmark(current_buffer_id,
                M.opts.local_marks_name_space, mark[2], mark[3],
                { id = mark[1], sign_text = string.sub(mark_key, 1, 2)
                })
        end
    end
end

return M
