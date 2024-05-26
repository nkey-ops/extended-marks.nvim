local global_marks = require('extended-marks.global-marks')
local local_marks = require('extended-marks.local-marks')
local utils = require('extended-marks.utils')

vim.keymap.set({ 'n' }, 'm', function()
    local ch = vim.fn.getchar()

    if (ch >= 97 and ch <= 122) then --[a-z]
        local_marks.set_local_mark(ch)
        return
    elseif ch >= 65 and ch <= 90 then --[A-Z]
        global_marks.set_global_mark(ch)
        return
    else
        return
    end
end, {})

vim.keymap.set({ 'n' }, '`', function()
    local ch = vim.fn.getchar()

    if (ch >= 97 and ch <= 122) then --[a-z]
        local_marks.jump_to_local_mark(ch)
        return
    elseif ch >= 65 and ch <= 90 then --[A-Z]
        global_marks.open_global_mark(ch)
        return
    else
        return
    end
end)

-- GLOBAL MARKS

local marks_global_delete_completion = function(arg_lead, cmd_line, cursor_pos)
    local working_dir = vim.fn.getcwd()
    local marks =
        utils.get_json_decoded_data(global_marks.opts.global_marks_file_path)

    table.sort(marks[working_dir])

    local mark_keys = {}
    local i = 1;
    for key, _ in pairs(marks[working_dir]) do
        mark_keys[i] = key
        i = i + 1
    end

    return mark_keys
end



vim.api.nvim_create_user_command("MarksGlobal", function()
        global_marks.show_global_marks()
    end,
    { desc = "Lists marked files for current dirrectory" })
vim.api.nvim_create_user_command("MarksGlobalAll", function()
        global_marks.show_all_global_marks()
    end,
    { desc = "Lists all marked files with their current dirrectories" })
vim.api.nvim_create_user_command("MarksGlobalDelete",
    function(opts) global_marks.delete_global_mark(opts.args) end, {
        nargs = 1,
        complete = marks_global_delete_completion,
        desc = "Deletes a global mark using the mark's key"
    })

vim.api.nvim_create_user_command("MarksMaxGlobalKeySeq",
    function(opts) global_marks.set_max_seq_glocal_mark(opts.args) end,
    {
        desc = "Sets a max sequens of characters of the mark-key for global marks",
        nargs = 1
    })


-- LOCAL MARKS

local marks_local_delete_completion = function(arg_lead, cmd_line, cursor_pos)
    local current_buffer = vim.api.nvim_buf_get_name(0)
    local marks =
        utils.get_json_decoded_data(
            local_marks.opts.local_marks_file_path, current_buffer)

    table.sort(marks[current_buffer])

    local mark_keys = {}
    local i = 1;
    for key, _ in pairs(marks[current_buffer]) do
        mark_keys[i] = key
        i = i + 1
    end

    return mark_keys
end

vim.api.nvim_create_user_command("MarksLocal", function()
        local_marks.show_local_marks()
    end,
    { desc = "Lists buffer local marks" })
vim.api.nvim_create_user_command("MarksLocalAll", function()
        local_marks.show_all_local_marks()
    end,
    { desc = "Lists all local marks with their buffer names" })

vim.api.nvim_create_user_command("MarksLocalDelete",
    function(opts) local_marks.delete_local_mark(opts.args) end, {
        nargs = 1,
        complete = marks_local_delete_completion,
        desc = "Deletes a local mark using the mark's key"
    })

vim.api.nvim_create_user_command("MarksMaxLocalKeySeq",
    function(opts) local_marks.set_max_seq_local_mark(opts.args) end,
    {
        desc = "Sets a max sequens of characters of the mark-key for local marks",
        nargs = 1
    })

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
