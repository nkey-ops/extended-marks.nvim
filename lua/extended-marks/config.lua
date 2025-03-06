local cwd_marks = require('extended-marks.cwd')
local local_marks = require('extended-marks.local')
local tab_marks = require('extended-marks.tab')
local utils = require('extended-marks.utils')

-- CWD MARKS
local marks_cwd_delete_completion = function(_, _, _)
    local working_dir = vim.fn.getcwd()
    local marks =
        utils.get_json_decoded_data(cwd_marks.Opts.data_file)

    table.sort(marks[working_dir])

    local mark_keys = {}
    local i = 1;
    for key, _ in pairs(marks[working_dir]) do
        mark_keys[i] = key
        i = i + 1
    end

    return mark_keys
end


vim.api.nvim_create_user_command("MarksCwd", function()
        cwd_marks.show_cwd_marks()
    end,
    { desc = "Lists marked files for current dirrectory" })
vim.api.nvim_create_user_command("MarksCwdAll", function()
        cwd_marks.show_all_cwd_marks()
    end,
    { desc = "Lists all marked files with their current dirrectories" })
vim.api.nvim_create_user_command("MarksCwdDelete",
    function(opts) cwd_marks.delete_cwd_mark(opts.args) end, {
        nargs = 1,
        complete = marks_cwd_delete_completion,
        desc = "Deletes a cwd mark using the mark's key"
    })


-- LOCAL MARKS
local marks_local_delete_completion = function(_, _, _)
    local current_buffer = vim.api.nvim_buf_get_name(0)
    local marks =
        utils.get_json_decoded_data(
            local_marks.Opts.data_file, current_buffer)

    table.sort(marks[current_buffer])

    local mark_keys = {}
    local i = 1;
    for key, _ in pairs(marks[current_buffer]) do
        mark_keys[i] = key
        i = i + 1
    end

    return mark_keys
end

local function set_key_length(args)
    assert(type(args) == "table", "args shoulbe be of a type table")

    if args[1] == nil then
        local module_key_length = {
            cwd_marks = cwd_marks.get_key_length(),
            local_marks = local_marks.get_key_length(),
            tab_marks = tab_marks.get_key_length(),
        }
        vim.api.nvim_echo({ { vim.inspect(module_key_length) } },
            false, { verbose = false })
        return
    end
    assert(args[1] ~= nil and args[2] ~= nil,
        "args should contain 'module'(cwd|local|tab) and 'key length'")
    assert(type(args[1]) == "string" and (args[1] == 'cwd' or args[1] == 'local' or args[1] == 'tab'),
        "first argumet should be a string and equal to 'cwd', 'local', or 'tab'")
    assert(tonumber(args[2]), "the second argument shoulbe be a number")

    local module = args[1]
    local key_length = tonumber(args[2])

    assert(key_length > 0 and key_length < 30,
        "key length should be more than zero and less than 30. "
        .. "Current value is " .. key_length)

    if module == 'cwd' then
        cwd_marks.set_options({ key_length = key_length })
        print("MarksCwd: set key_length to: " .. key_length)
    elseif module == 'local' then
        local_marks.set_options({ key_length = key_length })
        print("MarksLocal: set key_length to: " .. key_length)
    elseif module == 'tab' then
        tab_marks.set_options({ key_length = key_length })
        print("MarksTab: set key_length to: " .. key_length)
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

vim.api.nvim_create_user_command("MarksTab", function()
        tab_marks.show_tab_marks()
    end,
    { desc = "Lists tab marks" })


vim.api.nvim_create_user_command("MarksKeyLength",
    function(opts) set_key_length(opts.fargs) end,
    {
        desc = "Sets a max sequens of characters of the mark-key for a specific module",
        nargs = "*",
        complete = function(_, b, _)
            return b:match('cwd') or b:match('local') or b:match('tab')
                and {} or { "cwd", "local", "tab" }
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
    callback = function(args)
        -- Uses nested autocmd because `vim.api.nvim_buf_line_count(args.buf)` would return zero
        vim.api.nvim_create_autocmd({ "BufEnter" }, {
            once = true,
            -- Too many data files were opened on a big project that lead to major issues because
            -- his event called not once but multiple times despite "once" property,
            -- maybe a concurrency issue.
            -- Linking this event to the buffer that created fixes it.
            buffer = args.buf,

            callback = function()
                local_marks.restore()
            end
        })
    end
})
