-- TODO max key seq set is lower by one
-- TODO The mark's location moves to the bottom of the file after formatting
-- TODO marks are'nt saved after closing the buffer
-- TODO highlight after the jump?
-- TODO set local hard cup max key seq
-- TODO add data dir creation logic
-- TODO remove empty tables
local utils = require('extended-marks.utils')

local M = {
    opts = {
        data_dir = vim.fn.glob("~/.local/share/nvim") .. "/extended-marks",
        global_marks_file_path =
            vim.fn.glob("~/.local/share/nvim/extended-marks") .. "/global_marks.json",
        local_marks_file_path =
            vim.fn.glob("~/.local/share/nvim/extended-marks") .. "/local_marks.json",
        tab_marks_file_path =
            vim.fn.glob("~/.local/share/nvim/extended-marks") .. "/tab_marks.json",
        max_key_seq = 5,
        local_marks_name_space = vim.api.nvim_create_namespace("local_marks")
    }
}


-- @start_char
--TODO don't create new marks but edit old ones
M.set_local_mark = function(first_char)
    assert(first_char ~= nil, "start_char cannot be nil")
    assert(type(first_char) == "number", "start_char should be of type number")
    assert(first_char >= 97 and first_char <= 122,
        "start_char should be a lowercase ascii character[a-z]")

    local mark_key = utils.get_mark_key(M.opts.max_key_seq, first_char)
    if (mark_key == nil) then return end

    local local_buffer = vim.api.nvim_buf_get_name(0)
    local local_buffer_id = vim.api.nvim_get_current_buf()
    local buffers = utils.get_json_decode_data(M.opts.local_marks_file_path, local_buffer)

    local extmark_opts = { sign_text = string.sub(mark_key, 1, 2) }
    if buffers[local_buffer][mark_key] ~= nil then
        extmark_opts.id = buffers[local_buffer][mark_key][1]
    end

    local pos = vim.api.nvim_win_get_cursor(0)
    local marked_line = vim.api.nvim_buf_get_lines(
        local_buffer_id, pos[1] - 1, pos[1], false)[1]

    extmark_opts.end_col = string.len(marked_line)

    local mark_id = vim.api.nvim_buf_set_extmark(
        local_buffer_id, M.opts.local_marks_name_space, pos[1] - 1, 0,
        extmark_opts)


    buffers[local_buffer][mark_key] = { mark_id, pos[1] - 1, 0 }

    utils.write_marks(M.opts.local_marks_file_path, buffers)

    print(string.format("Marks:[%s:%s] \"%s\"", mark_key, pos[1], marked_line))
end

M.jump_to_local_mark = function(start_char)
    assert(start_char ~= nil, "start_char cannot be nil")
    assert(type(start_char) == "number", "start_char should be of type number")
    assert(start_char >= 97 and start_char <= 122,
        "start_char should be a lowercase ascii character[a-z]")

    local local_buffer_name = vim.api.nvim_buf_get_name(0)
    local local_marks = utils.get_json_decode_data(M.opts.local_marks_file_path, local_buffer_name)
        [local_buffer_name]

    local mark_key =
        utils.get_last_mark_key(M.opts.max_key_seq,
            Copy_keys(local_marks), start_char)

    if mark_key == nil then return end -- key wasn't
    local mark_id = local_marks[mark_key][1]

    local position = vim.api.nvim_buf_get_extmark_by_id(
        0, M.opts.local_marks_name_space, mark_id, {})

    position[1] = position[1] + 1; --api`s line positon is zero-based
    vim.api.nvim_win_set_cursor(0, position)
end

M.set_global_mark = function(first_char)
    local mark_key = utils.get_mark_key(M.opts.max_key_seq, first_char)
    if (mark_key == nil) then return end

    local working_dir = vim.fn.getcwd()
    local marked_file = vim.api.nvim_buf_get_name(0)
    local data = utils.get_json_decode_data(M.opts.global_marks_file_path, working_dir)

    data[working_dir][mark_key] = marked_file

    utils.write_marks(M.opts.global_marks_file_path, data)
    print("Marks:[" .. mark_key .. "]", marked_file)
end

M.open_global_mark = function(first_char)
    assert(first_char ~= nil and type(first_char) == "number",
        "First mark key character value should not be nil and be of a type number")
    assert(first_char >= 65 and first_char <= 90, "First mark key character value should be [A-Z]")

    local working_dir = vim.fn.getcwd()
    local marks = utils.get_json_decode_data(M.opts.global_marks_file_path, working_dir)

    local mark_key =
        utils.get_last_mark_key(
            M.opts.max_key_seq, Copy_keys(marks[working_dir]), first_char)

    if mark_key == nil then return end

    local marked_file = marks[working_dir][mark_key]
    -- No file was marked with this key
    if marked_file == nil then
        return
    end

    assert(vim.fn.bufexists(marked_file))
    vim.cmd(vim.fn.bufadd(marked_file) .. "b")
end

-- Global Functions

function Marks_global()
    local working_dir = vim.fn.getcwd()
    local marks = utils.get_json_decode_data(
        M.opts.global_marks_file_path, working_dir)[working_dir]

    table.sort(marks)
    vim.api.nvim_echo({ { vim.inspect(marks) } },
        false, { verbose = false })
end

function Marks_global_all()
    local marks = utils.get_json_decode_data(M.opts.global_marks_file_path)
    table.sort(marks)

    vim.api.nvim_echo({ { vim.inspect(marks) } },
        false, { verbose = false })
end

function Marks_local()
    local local_buffer_name = vim.api.nvim_buf_get_name(0)
    local local_buffer_id = vim.api.nvim_get_current_buf()
    local marks = utils.get_json_decode_data(
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
function Marks_local_all()
    local local_buffer_name = vim.api.nvim_buf_get_name(0)
    local marks = utils.get_json_decode_data(
        M.opts.local_marks_file_path, local_buffer_name)

    table.sort(marks)

    vim.api.nvim_echo({ { vim.inspect(marks) } },
        false, { verbose = false })
end

function Marks_global_delete(mark_key)
    assert(mark_key ~= nil, "mark_key cannot be nil")
    assert(string.len(mark_key) < 10, "mark_key is too long")

    local working_dir = vim.fn.getcwd()
    local data = utils.get_json_decode_data(M.opts.global_marks_file_path)

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

    utils.write_marks(M.opts.global_marks_file_path, data)

    print("MarksDelete:[" .. mark_key .. "] was removed")
end

function Marks_local_delete(mark_key)
    assert(mark_key ~= nil, "mark_key cannot be nil")
    assert(type(mark_key) == "string", "mark_key should be of type strin")
    assert(string.len(mark_key) < 10, "mark_key is too long")

    local current_buffer_name = vim.api.nvim_buf_get_name(0)
    local marks = utils.get_json_decode_data(M.opts.local_marks_file_path, current_buffer_name)

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

function Marks_set_max_key_seq(max_seq)
    assert(max_seq ~= nil)

    if (type(max_seq) == "string") then
        max_seq = tonumber(max_seq)
    end

    assert(type(max_seq) == "number" and max_seq > 0 and max_seq < 50)

    M.opts.max_key_seq = max_seq
end

function Update_local_marks()
    local local_buffer_id = vim.api.nvim_get_current_buf()
    local local_buffer_name = vim.api.nvim_buf_get_name(local_buffer_id)
    local marks = utils.get_json_decode_data(
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
function Restore_local_marks()
    local current_buffer_id = vim.api.nvim_get_current_buf()
    local current_buffer_name = vim.api.nvim_buf_get_name(current_buffer_id)
    local local_marks = utils.get_json_decode_data(
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

-- Key-binds

vim.keymap.set({ 'n' }, 'm', function()
    local ch = vim.fn.getchar()

    if (ch >= 97 and ch <= 122) then --[a-z]
        vim.api.nvim_feedkeys("m" .. string.char(ch), "n", false)
        -- M.set_local_mark(ch)
        return
    elseif ch >= 65 and ch <= 90 then --[A-Z]
        M.set_global_mark(ch)
        return
    else
        return
    end
end, {})

vim.keymap.set({ 'n' }, '`', function()
    local ch = vim.fn.getchar()

    if (ch >= 97 and ch <= 122) then --[a-z]
        vim.api.nvim_feedkeys("`" .. string.char(ch), "n", false)
        -- M.jump_to_local_mark(ch)
        return
    elseif ch >= 65 and ch <= 90 then --[A-Z]
        M.open_global_mark(ch)
        return
    else
        return
    end
end)


local marks_global_delete_completion = function(arg_lead, cmd_line, cursor_pos)
    local working_dir = vim.fn.getcwd()
    local marks = utils.get_json_decode_data(M.opts.global_marks_file_path)

    table.sort(marks[working_dir])

    local mark_keys = {}
    local i = 1;
    for key, _ in pairs(marks[working_dir]) do
        mark_keys[i] = key
        i = i + 1
    end

    return mark_keys
end

local marks_local_delete_completion = function(arg_lead, cmd_line, cursor_pos)
    local current_buffer = vim.api.nvim_buf_get_name(0)
    local marks = utils.get_json_decode_data(M.opts.local_marks_file_path, current_buffer)

    table.sort(marks[current_buffer])

    local mark_keys = {}
    local i = 1;
    for key, _ in pairs(marks[current_buffer]) do
        mark_keys[i] = key
        i = i + 1
    end

    return mark_keys
end



vim.api.nvim_create_user_command("MarksGlobal", function() Marks_global() end,
    { desc = "Lists marked files for current dirrectory" })
vim.api.nvim_create_user_command("MarksLocal", function() Marks_local() end,
    { desc = "Lists buffer local marks" })

vim.api.nvim_create_user_command("MarksGlobalAll", function() Marks_global_all() end,
    { desc = "Lists all marked files with their current dirrectories" })
vim.api.nvim_create_user_command("MarksLocalAll", function() Marks_local_all() end,
    { desc = "Lists all local marks with their buffer names" })

vim.api.nvim_create_user_command("MarksGlobalDelete",
    function(opts) Marks_global_delete(opts.args) end, {
        nargs = 1,
        complete = marks_global_delete_completion,
        desc = "Deletes a global mark using the mark's key"
    })
vim.api.nvim_create_user_command("MarksLocalDelete",
    function(opts) Marks_local_delete(opts.args) end, {
        nargs = 1,
        complete = marks_local_delete_completion,
        desc = "Deletes a local mark using the mark's key"
    })

vim.api.nvim_create_user_command("MarksMaxKeySequence",
    function(opts) Marks_set_max_key_seq(opts.args) end,
    { desc = "Sets a max sequens of characters of the mark-key", nargs = 1 })


vim.api.nvim_create_user_command("Mark",
    function(opts)
        print(
            vim.inspect(
                vim.api.nvim_buf_get_extmarks(
                    0, M.opts.local_marks_name_space, 0, -1, {})
            )
        )
    end, {})


-- Autocmds
-- vim.api.nvim_create_autocmd({ "BufWrite" }, {
--     -- pattern = "*",
--     -- callback = function()
--     --     Update_local_marks()
--     -- end
-- })

--TODO fix
-- vim.api.nvim_create_autocmd({ "BufNew" }, {
--     pattern = "*",
--     callback = function()
--         Restore_local_marks()
--     end
-- })
--



