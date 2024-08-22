local global_marks = require('extended-marks.global')
local local_marks = require('extended-marks.local')
local tab_marks = require('extended-marks.tab')
local utils = require('extended-marks.utils')

-- GLOBAL MARKS
local marks_global_delete_completion = function(_, _, _)
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


-- LOCAL MARKS
local marks_local_delete_completion = function(_, _, _)
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

local function set_max_seq(args)
    assert(type(args) == "table", "args shoulbe be of a type table")
    assert(args[1] ~= nil and args[2] ~= nil, "args should contain 'module' and 'max key sequence'")
    assert(type(args[1]) == "string" and (args[1] == 'global' or args[1] == 'local' or args[1] == 'tab'),
        "first argumet should be a string and equal to 'global', 'local', or 'tab'")
    assert(tonumber(args[2]), "shoulbe be a number")

    local module = args[1]
    local max_key_seq = tonumber(args[2])

    if module == 'global' then
        global_marks.set_options({ max_key_seq = max_key_seq })
        print("MarksGlobal: set max_key_seq to: " .. max_key_seq)
    elseif module == 'local' then
        local_marks.set_options({ max_key_seq = max_key_seq })
        print("MarksLocal: set max_key_seq to: " .. max_key_seq)
    elseif module == 'tab' then
        tab_marks.set_options({ max_key_seq = max_key_seq })
        print("MarksTab: set max_key_seq to: " .. max_key_seq)
    end
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
    function(opts) local_marks.delete_mark(opts.args) end, {
        nargs = 1,
        complete = marks_local_delete_completion,
        desc = "Deletes a local mark using the mark's key"
    })

vim.api.nvim_create_user_command("MarksLocalDeleteAll", function()
        local_marks.delete_all_marks()
    end,
    { desc = "Deletes all the local marks for the current buffer" })

vim.api.nvim_create_user_command("MarksSetMaxKeySeq",
    function(opts) set_max_seq(opts.fargs) end,
    {
        desc = "Sets a max sequens of characters of the mark-key for a specific module",
        nargs = "+",
        complete = function(_, b, _)
            return b:match('global') or b:match('local') or b:match('tab')
                and {} or { "global", "local", "tab" }
        end
    })

-- Autocmds
vim.api.nvim_create_autocmd({ "BufWrite" }, {
    pattern = "*",
    callback = function()
        local_marks.update()
    end
})

vim.api.nvim_create_autocmd({ "BufNew" }, {
    nested = true,
    callback = function()
        -- Uses nested autocmd because `vim.api.nvim_buf_line_count(args.buf)` would return zero
        vim.api.nvim_create_autocmd({ "BufEnter" }, {
            once = true,

            callback = function()
                local_marks.restore()
            end
        })
    end
})
