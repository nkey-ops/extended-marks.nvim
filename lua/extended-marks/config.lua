local global_marks = require('extended-marks.global')
local cwd_marks = require('extended-marks.cwd')
local local_marks = require('extended-marks.local')
local tab_marks = require('extended-marks.tab')

-- GLOBAL MARKS
local marks_global_delete_completion = function(_, _, _)
    local marks = global_marks.get_marks()

    table.sort(marks)

    local mark_keys = {}
    local i = 1;
    for key, _ in pairs(marks) do
        mark_keys[i] = key
        i = i + 1
    end

    return mark_keys
end

vim.api.nvim_create_user_command("MarksGlobal",
    function(opts) global_marks.show_marks(opts) end, {
        desc = "Lists global marked files",
        complete = marks_global_delete_completion,
        nargs = "*"
    })

vim.api.nvim_create_user_command("MarksGlobalDelete",
    function(opts) global_marks.delete_mark(opts.args) end, {
        nargs = 1,
        complete = marks_global_delete_completion,
        desc = "Deletes a global mark using the mark's key"
    })

-- CWD MARKS

local marks_cwd_delete_completion = function(_, _, _)
    local working_dir = vim.fn.getcwd()
    local marks = cwd_marks.get_marks()[working_dir]

    if not marks then
        marks = {}
    end

    table.sort(marks)

    local mark_keys = {}
    local i = 1;
    for key, _ in pairs(marks) do
        mark_keys[i] = key
        i = i + 1
    end

    return mark_keys
end


vim.api.nvim_create_user_command("MarksCwd",
    function(opts) cwd_marks.show_marks(opts) end, {
        desc = "Lists marked files for current dirrectory",
        complete = marks_cwd_delete_completion,
        nargs = '*'
    })

vim.api.nvim_create_user_command("MarksCwdAll",
    function() cwd_marks.show_all_cwd_marks() end, {
        desc = "Lists all marked files with their current dirrectories" })

vim.api.nvim_create_user_command("MarksCwdDelete",
    function(opts) cwd_marks.delete_cwd_mark(opts.args) end, {
        nargs = 1,
        complete = marks_cwd_delete_completion,
        desc = "Deletes a cwd mark using the mark's key"
    })


-- LOCAL MARKS
local marks_local_delete_completion = function(_, _, _)
    local current_buffer = vim.api.nvim_buf_get_name(0)
    local marks = local_marks.get_marks()[current_buffer]

    if not marks then
        marks = {}
    end

    table.sort(marks)

    local mark_keys = {}
    local i = 1;
    for key, _ in pairs(marks) do
        mark_keys[i] = key
        i = i + 1
    end

    return mark_keys
end

local function set_key_length(args)
    assert(type(args) == "table", "args shoulbe be of a type table")

    if args[1] == nil then
        local module_key_length = {
            global_marks = global_marks.get_key_length(),
            cwd_marks = cwd_marks.get_key_length(),
            local_marks = local_marks.get_key_length(),
            tab_marks = tab_marks.get_key_length(),
        }
        vim.api.nvim_echo({ { vim.inspect(module_key_length) } },
            false, { verbose = false })
        return
    end
    assert(args[1] ~= nil and args[2] ~= nil,
        "args should contain 'module'(global|cwd|local|tab) and 'key length'")
    assert(type(args[1]) == "string" and
        (args[1] == 'global'
            or args[1] == 'cwd'
            or args[1] == 'local'
            or args[1] == 'tab'),
        "first argumet should be a string and equal to 'global', 'cwd', 'local', or 'tab'")
    assert(tonumber(args[2]), "the second argument should be be a number")

    local module = args[1]
    local key_length = assert(tonumber(args[2]),
        "couldn't parse the second argument " .. args[2])

    assert(key_length > 0 and key_length < 30,
        "key length should be more than zero and less than 30. "
        .. "Current value is " .. key_length)

    if module == 'global' then
        global_marks.set_key_length(key_length)
        print("MarksGlobal: set key_length to: " .. key_length)
    elseif module == 'cwd' then
        cwd_marks.set_key_length(key_length)
        print("MarksCwd: set key_length to: " .. key_length)
    elseif module == 'local' then
        local_marks.set_key_length(key_length)
        print("MarksLocal: set key_length to: " .. key_length)
    elseif module == 'tab' then
        tab_marks.set_options({ key_length = key_length })
        print("MarksTab: set key_length to: " .. key_length)
    end
end


vim.api.nvim_create_user_command("MarksLocal", function(opts)
        local_marks.show_marks(opts)
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


-- TAB MARKS
local marks_tab_delete_completion = function(_, _, _)
    local marks = {}

    local i = 1
    for _, tab_id in pairs(vim.api.nvim_list_tabpages()) do
        local mark_key = vim.t[tab_id]["mark_key"]
        if mark_key then
            assert(mark_key ~= nil)
            marks[i] = mark_key
            i = i + 1
        end
    end

    table.sort(marks)

    return marks
end


vim.api.nvim_create_user_command("MarksTab", function()
        tab_marks.show_tab_marks()
    end,
    { desc = "Lists tab marks" })

vim.api.nvim_create_user_command("MarksTabDelete",
    function(opts) tab_marks.delete_tab_mark(opts.args) end, {
        nargs = 1,
        complete = marks_tab_delete_completion,
        desc = "Deletes a tab mark using the mark's key"
    })

-- OPTIONS
vim.api.nvim_create_user_command("MarksKeyLength",
    function(opts) set_key_length(opts.fargs) end,
    {
        desc = "Sets a max sequens of characters of the mark-key for a specific module",
        nargs = "*",
        complete = function(_, b, _)
            return b:match('cwd') or b:match('local') or b:match('tab')
                and {} or { "global", "cwd", "local", "tab" }
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
