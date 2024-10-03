local global_marks = require('extended-marks.global')
local local_marks = require('extended-marks.local')
local tab_marks = require('extended-marks.tab')
require("extended-marks.config")

local M = {}
local Opts = {
    data_dir = vim.fn.glob("~/.cache/nvim/extended-marks"), -- full path
    module = {
        locaL = {
            max_key_seq = 1,            -- valid from 1 to 30
            sign_column = 1,            -- 0 for no, 1 or 2 for number of characters
            exhaustion_matcher = false, -- if max_key_seq is 1 this parameter will always be false
        },
        global = {
            max_key_seq = 4,
            exhaustion_matcher = false
        },
        tab = {
            max_key_seq = 1,
            exhaustion_matcher = false,
        },
    }
}

M.setup = function(opts)
    if not opts or next(opts) == nil then
        opts = Opts
    else
        opts = vim.tbl_extend("force", Opts, opts)
    end

    assert(type(opts) == 'table', "Opts should be of a type  table")

    if opts.module.global then
        opts.module.global.data_dir = opts.data_dir
        global_marks.set_options(opts.module.global)
    end

    if opts.module.locaL then
        opts.module.locaL.data_dir = opts.data_dir
        local_marks.set_options(opts.module.locaL)
    end

    if opts.module.tab then
        opts.module.tab.data_dir = opts.data_dir
        tab_marks.set_options(opts.module.tab)
    end
end

M.set_mark = function()
    local ch = vim.fn.getchar()

    if (ch >= 97 and ch <= 122) then  --[a-z]
        local_marks.set_local_mark(ch)
    elseif ch >= 65 and ch <= 90 then --[A-Z]
        global_marks.set_global_mark(ch)
    end
end

M.jump_to_mark = function()
    local ch = vim.fn.getchar()

    if (ch >= 97 and ch <= 122) then  --[a-z]
        local_marks.jump_to_local_mark(ch)
    elseif ch >= 65 and ch <= 90 then --[A-Z]
        global_marks.jump_to_global_mark(ch)
    end
end


M.set_tab_mark = function()
    local ch = vim.fn.getchar()

    if (ch >= 97 and ch <= 122) then --[a-z]
        tab_marks.set_mark(ch)
    end
end

M.jump_to_tab_mark = function()
    local ch = vim.fn.getchar()

    if (ch >= 97 and ch <= 122) then --[a-z]
        tab_marks.jump_to_mark(ch)
    end
end

return M
