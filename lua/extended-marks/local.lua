local utils = require('extended-marks.utils')

--[[
    local_marks file structure
    "buffer path i.e file path": {  -- TODO it's an object for some reason should be an array
        "mark_key with form [a-z]{1,key_length}  [ -- TODO it's an array for some reason should be an object
            number: id of the mark in the namespace,
            number: line number (zero based, api-indexing),
            number: column number (zero based, api-indexing)
        ]
    }
--]]

local locaL = {}
local Opts = {
    data_file = vim.fn.glob("~/.cache/nvim/extended-marks") .. "/local_marks.json",
    namespace = vim.api.nvim_create_namespace("local_marks"),
    key_length = 1,
    sign_column = 1,
}

locaL.Opts = Opts

--- @class LocalOpts
--- @field data_dir? string path to the data directory
--- @field key_length? number max number of characters in the mark (1 to 30)
--- @field sign_column? number 0 for no, 1 or 2 for number of characters

--- sets the options for the local module
--- @param opts LocalOpts
function locaL.set_options(opts)
    assert(opts ~= nil, "Opts cannot be nil")
    assert(type(opts) == 'table', "Opts should be of a type  table")

    if opts.key_length then
        local key_length = opts.key_length
        assert(type(key_length) == 'number', "key_lenth should be of type number")
        assert(key_length > 0 and key_length < 30,
            "key_length should be more than zero and less than 30. Current value is " .. key_length)
        Opts.key_length = key_length
    end

    if opts.data_dir then
        local data_dir = opts.data_dir
        assert(type(data_dir) == 'string', "data_dir should be of type string")
        assert(utils.try_create_file(data_dir .. '/local_marks.json'),
            "Couldn't create or use data file 'local_marks.json' with provided dir: " .. data_dir)
        Opts.data_file = data_dir .. "/local_marks.json"
    end

    if opts.sign_column then
        local sign_column = opts.sign_column
        assert(type(sign_column) == 'number', "sing_text should be of type number")
        assert(sign_column >= 0 and sign_column <= 2, "sing_text can only have values 0, 1 and 2")
        Opts.sign_column = sign_column
    end
end

---@param first_char number represents the first character of the mark that should be in between
--- 65 >= first_char <= 90 or 97 >= first_char <= 122
--- that is equal to the pattern [a-zA-Z] if we convert to a string
function locaL.set_local_mark(first_char)
    assert(first_char ~= nil, "start_char cannot be nil")
    assert(type(first_char) == "number", "start_char should be of type number")
    assert(first_char >= 65 and first_char <= 90 or first_char >= 97 and first_char <= 122,
        "First mark key character value should be [a-zA-Z]")

    local mark_key = utils.get_mark_key(Opts.key_length, first_char)
    if (mark_key == nil) then return end

    local current_buffer_id = vim.api.nvim_get_current_buf()
    local local_buffer_name = vim.api.nvim_buf_get_name(current_buffer_id)
    local buffers = utils.get_json_decoded_data(Opts.data_file, local_buffer_name)


    -- set mark with one or two letters from the mark_key as a sign-column
    local extmark_opts = {}
    if Opts.sign_column ~= 0 then
        extmark_opts = { sign_text = string.sub(mark_key, 1, Opts.sign_column) }
    end

    -- add to extmark_opts an id of the mark in the name_space to edit it
    if buffers[local_buffer_name] and buffers[local_buffer_name][mark_key] then
        extmark_opts.id = buffers[local_buffer_name][mark_key][1]
    end

    local pos = vim.api.nvim_win_get_cursor(0)
    pos[1] = pos[1] - 1 -- zero-based api-indexing
    local marked_line_string = vim.api.nvim_buf_get_lines(
        current_buffer_id, pos[1], pos[1] + 1, true)[1]

    extmark_opts.end_col = string.len(marked_line_string)

    -- place mark at the beginning of the line
    local mark_id = vim.api.nvim_buf_set_extmark(
        current_buffer_id, Opts.namespace, pos[1], 0, extmark_opts)

    buffers[local_buffer_name][mark_key] = { mark_id, pos[1], 0 }

    utils.write_marks(Opts.data_file, buffers)

    print(
        string.format("MarksLocal:[%s:%s] \"%s\"", mark_key, pos[1] + 1, marked_line_string))
end

function locaL.jump_to_local_mark(first_char)
    assert(first_char ~= nil, "first_char cannot be nil")
    assert(type(first_char) == "number", "first_char should be of type number")
    assert(first_char >= 97 and first_char <= 122,
        "first_char should be a lowercase ascii character [a-z]")

    local local_buffer_name = vim.api.nvim_buf_get_name(0)
    local local_marks =
        utils.get_json_decoded_data(
            Opts.data_file, local_buffer_name)[local_buffer_name]

    local mark_key = utils.get_mark_key(Opts.key_length, first_char)

    -- the remaining mark_key wasn't found(it was miss-typed apparently) just ignore the jump
    if mark_key == nil or local_marks[mark_key] == nil then return end
    local mark_id = local_marks[mark_key][1]

    local position = vim.api.nvim_buf_get_extmark_by_id(
        0, Opts.namespace, mark_id, {})

    position[1] = position[1] + 1; -- api`s line and column position is (1,0) based
    vim.api.nvim_win_set_cursor(0, position)
end

function locaL.show_local_marks()
    local local_buffer_name = vim.api.nvim_buf_get_name(0)
    local current_buffer_id = vim.api.nvim_get_current_buf()
    local marks = utils.get_json_decoded_data(
        Opts.data_file, local_buffer_name)[local_buffer_name]


    table.sort(marks)
    for mark_key, mark in pairs(marks) do
        local pair =
            vim.api.nvim_buf_get_extmark_by_id(
                current_buffer_id, Opts.namespace, mark[1], {})

        assert(pair ~= nil and pair[1] ~= nil, string.format("Nil for [%s:%s]", mark_key, vim.inspect(mark)))

        marks[mark_key] =
            vim.api.nvim_buf_get_lines(
                current_buffer_id, pair[1], pair[1] + 1, true)[1]
    end

    vim.api.nvim_echo({ { vim.inspect(marks) } },
        false, { verbose = false })
end

-- Shows raw raw data for performance reasons
function locaL.show_all_local_marks()
    local marks = utils.get_json_decoded_data(Opts.data_file)

    table.sort(marks)

    vim.api.nvim_echo({ { vim.inspect(marks) } },
        false, { verbose = false })
end

--- deletes the mark for the current buffer
---@param mark_key string of the mark to be deleted from the current buffer
function locaL.delete_mark(mark_key)
    assert(mark_key ~= nil, "mark_key cannot be nil")
    assert(type(mark_key) == "string", "mark_key should be of type strin")
    assert(string.len(mark_key) < 10, "mark_key is too long")

    local current_buffer_name = vim.api.nvim_buf_get_name(0)
    local marks = utils.get_json_decoded_data(Opts.data_file, current_buffer_name)

    local mark = marks[current_buffer_name][mark_key]
    if (mark == nil) then
        print(string.format("MarksLocal:[%s] wasn't found", mark_key))
        return
    end

    vim.api.nvim_buf_del_extmark(0, Opts.namespace, mark[1])
    marks[current_buffer_name][mark_key] = nil

    if next(marks[current_buffer_name]) == nil then
        marks[current_buffer_name] = nil
    end

    utils.write_marks(Opts.data_file, marks)

    print(string.format("MarksLocal:[%s:%s] was removed", mark_key, mark[2]))
end

--- deletes all the local marks for the current buffer
function locaL.delete_all_marks()
    local current_buffer_id = vim.api.nvim_get_current_buf()
    local local_buffer_name = vim.api.nvim_buf_get_name(current_buffer_id)
    local local_marks = utils.get_json_decoded_data(
        Opts.data_file, local_buffer_name)

    local_marks[local_buffer_name] = nil
    utils.write_marks(Opts.data_file, local_marks)
end

-- Updates marks from the namespace to the data file
function locaL.update()
    local current_buffer_id = vim.api.nvim_get_current_buf()
    local local_buffer_name = vim.api.nvim_buf_get_name(current_buffer_id)
    local buffers           = utils.get_json_decoded_data(
        Opts.data_file, local_buffer_name)

    for mark_key, mark in pairs(buffers[local_buffer_name]) do
        assert(mark_key ~= nil and mark ~= nil and
            mark[1] ~= nil and type(mark[1]) == "number" and
            mark[2] ~= nil and type(mark[2]) == "number" and mark[2] >= 0 and
            mark[3] ~= nil and type(mark[3]) == "number" and mark[3] >= 0,
            string.format("Failed assertion for mark: %s: %s", mark_key, vim.inspect(mark)))

        local pair =
            vim.api.nvim_buf_get_extmark_by_id(
                current_buffer_id, Opts.namespace, mark[1], {})

        if (pair ~= nil and pair[1] ~= nil and pair[2] ~= nil) then
            buffers[local_buffer_name][mark_key] = { mark[1], pair[1], pair[2] }
        else
            print(
                string.format(
                    "MarksLocal: Couldn't find mark in the namespace:[%s:%s]",
                    mark_key, vim.inspect(mark)))
        end
    end

    if next(buffers[local_buffer_name]) ~= nil then
        utils.write_marks(Opts.data_file, buffers)
    end
end

-- Local marks from the data file: local_marks.json into the namespace
--
-- TIME Coplexity: O(N+M)
-- where N is then number of source marks and
-- M is the number of marks present in the namespace
function locaL.restore()
    local current_buffer_id = vim.api.nvim_get_current_buf()
    local local_buffer_name = vim.api.nvim_buf_get_name(current_buffer_id)

    local buffers = utils.get_json_decoded_data(Opts.data_file, local_buffer_name)
    local local_marks = buffers[local_buffer_name]

    local namespace_marks =
        vim.api.nvim_buf_get_extmarks(
            current_buffer_id, Opts.namespace, 0, -1, {})
    local max_lines = vim.api.nvim_buf_line_count(current_buffer_id)

    local was_mark_removed = false

    for s_mark_key, s_mark in pairs(local_marks) do
        assert(s_mark_key ~= nil and s_mark ~= nil and
            s_mark[1] ~= nil and type(s_mark[1]) == "number" and
            s_mark[2] ~= nil and type(s_mark[2]) == "number" and s_mark[2] >= 0 and
            s_mark[3] ~= nil and type(s_mark[3]) == "number" and s_mark[3] >= 0,
            string.format("Failed assertion for mark: %s: %s", s_mark_key, vim.inspect(s_mark)))

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
            if s_mark[2] < max_lines then -- isn't out of bounds
                local marked_line_string = vim.api.nvim_buf_get_lines(
                    current_buffer_id, s_mark[2], s_mark[2] + 1, true)[1]

                -- if mark's column is out of bounds of the line
                -- set the column to zero
                if s_mark[3] >= marked_line_string:len() then
                    s_mark[3] = 0
                end

                local opts = { id = s_mark[1] }

                if Opts.sign_column ~= 0 then
                    opts.sign_text = string.sub(s_mark_key, 1, Opts.sign_column)
                end

                vim.api.nvim_buf_set_extmark(current_buffer_id,
                    Opts.namespace, s_mark[2], s_mark[3], opts)
            else
                print(string.format("MarksLocal: The mark was out of bounds: [%s:%s](zero-based) max lines %s",
                    s_mark_key, s_mark[2], max_lines))

                buffers[local_buffer_name][s_mark_key] = nil
                was_mark_removed = true
            end
        end
    end

    -- removing invalid marks
    if was_mark_removed then
        utils.write_marks(Opts.data_file, buffers)
    end
end

function locaL.get_key_length()
    return Opts.key_length
end

function locaL.space()
    print(vim.inspect(vim.api.nvim_buf_get_extmarks(0, Opts.namespace, 0, -1, {})))
end

return locaL
