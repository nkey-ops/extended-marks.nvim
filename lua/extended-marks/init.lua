local cwd_marks = require('extended-marks.cwd')
local local_marks = require('extended-marks.local')
local tab_marks = require('extended-marks.tab')
local utils = require('extended-marks.utils')

local M = {}
local Opts = {
    data_dir = vim.fn.glob("~/.cache/nvim/"), -- the path to data files
    locaL = {
        key_length = 1,                       -- valid from 1 to 30, max length of the mark
        sign_column = 1,                      -- 0 for no, 1 or 2 for number of characters
    },
    cwd = {
        key_length = 4,
    },
    tab = {
        key_length = 1,
    },
}

M.setup = function(opts)
    if not opts or next(opts) == nil then
        opts = Opts
    else
        opts = vim.tbl_extend("force", Opts, opts)
    end

    assert(type(opts) == 'table', "Opts should be of a type table")

    if opts.data_dir then
        utils.validate_dir(opts.data_dir)
        opts.data_dir = opts.data_dir:gsub('/$', '')

        opts.data_dir = opts.data_dir .. '/extended-marks'
        if (vim.fn.isdirectory(opts.data_dir) == 0) then
            os.execute("mkdir " .. opts.data_dir)
        end

        utils.validate_dir(opts.data_dir)
    end

    if opts.cwd then
        opts.cwd.data_dir = opts.data_dir
        cwd_marks.set_options(opts.cwd)
    end

    if opts.locaL then
        opts.locaL.data_dir = opts.data_dir
        local_marks.set_options(opts.locaL)
    end

    if opts.tab then
        opts.tab.data_dir = opts.data_dir
        tab_marks.set_options(opts.tab)
    end

    require("extended-marks.config")
end

M.set_mark = function()
    local ch = vim.fn.getchar()

    if (type(ch) == 'string') then
        return
    end
    assert(type(ch) == 'number')

    if (ch >= 97 and ch <= 122) then  --[a-z]
        local_marks.set_local_mark(ch)
    elseif ch >= 65 and ch <= 90 then --[A-Z]
        cwd_marks.set_cwd_mark(ch)
    end
end

M.jump_to_mark = function()
    local ch = vim.fn.getchar()

    if (type(ch) == 'string') then
        return
    end
    assert(type(ch) == 'number')

    if (ch >= 97 and ch <= 122) then  --[a-z]
        local_marks.jump_to_local_mark(ch)
    elseif ch >= 65 and ch <= 90 then --[A-Z]
        cwd_marks.jump_to_cwd_mark(ch)
    elseif ch == string.byte('<') then
        vim.cmd("'<")
    elseif ch == string.byte('>') then
        vim.cmd("'>")
    elseif ch == string.byte('`') then
        vim.cmd("''")
    elseif ch == string.byte('"') then
        vim.cmd("'\"")
    elseif ch == string.byte('^') then
        vim.cmd("'^")
    elseif ch == string.byte('.') then
        vim.cmd("'.")
    elseif ch == string.byte('(') then
        vim.cmd("'(")
    elseif ch == string.byte(')') then
        vim.cmd("')")
    elseif ch == string.byte('{') then
        vim.cmd("'{")
    elseif ch == string.byte('}') then
        vim.cmd("'}")
    elseif ch == string.byte(']') then
        vim.cmd("']")
    elseif ch == string.byte('[') then
        vim.cmd("'[")
    end
end


M.set_tab_mark = function()
    local ch = vim.fn.getchar()

    if (type(ch) == 'string') then
        return
    end
    assert(type(ch) == 'number')

    if (ch >= 97 and ch <= 122) then --[a-z]
        tab_marks.set_mark(ch)
    end
end

M.jump_to_tab_mark = function()
    local ch = vim.fn.getchar()

    if (type(ch) == 'string') then
        return
    end

    assert(type(ch) == 'number')

    if (ch >= 97 and ch <= 122) then --[a-z]
        tab_marks.jump_to_mark(ch)
    elseif (ch == string.byte("'")) then
        vim.cmd("tabnext #") -- last accessed tab
    elseif (ch == string.byte("$")) then
        vim.cmd("tabnext $") -- last tab
    elseif (ch == string.byte("1")) then
        vim.cmd("1tabnext")  -- first tab
    end
end

return M
