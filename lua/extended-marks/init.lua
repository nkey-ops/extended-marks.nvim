local cwd_marks = require('extended-marks.cwd')
local local_marks = require('extended-marks.local')
local tab_marks = require('extended-marks.tab')
require("extended-marks.config")

local M = {}
local Opts = {
    data_dir = vim.fn.glob("~/.cache/nvim/extended-marks"), -- full path
    locaL = {
        max_key_seq = 1,                                    -- valid from 1 to 30
        sign_column = 1,                                    -- 0 for no, 1 or 2 for number of characters
        exhaustion_matcher = false,                         -- if max_key_seq is 1 this parameter will always be false
    },
    cwd = {
        max_key_seq = 4,
        exhaustion_matcher = false
    },
    tab = {
        max_key_seq = 1,
        exhaustion_matcher = false,
    },
}

M.setup = function(opts)
    if not opts or next(opts) == nil then
        opts = Opts
    else
        opts = vim.tbl_extend("force", Opts, opts)
    end

    assert(type(opts) == 'table', "Opts should be of a type  table")

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
    elseif ch == string.byte('\'') then
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
