local cwd_marks = require('extended-marks.cwd')
local local_marks = require('extended-marks.local')
local tab_marks = require('extended-marks.tab')
local utils = require('extended-marks.utils')

local M = {}


--- @class PubCwdOpts allows external code to manage some configurations of
---                   the cwd module
--- @field key_length integer? default:1 | max number of characters in the mark [1 to 30)
local PubCwdOpts = {
    key_length = 1
}

--- @class PubLocalOpts allows external code to manage some configurations of
---                     the local module
--- @field key_length integer? default:1 | max number of characters in the mark [1 to 30)
--- @field sign_column 0|1|2|nil default:1 | 0 for no, 1 or 2 for number of characters
local PubLocalOpts = {
    key_length = 1,
    sign_column = 1,
}

--- @class PubTabOpts allows external code to manage some configurations of
---                   the tab module
--- @field key_length integer? default:1 | max number of characters in the mark [1 to 30)
local PubTabOpts = {
    key_length = 1,
}

--- @class Opts configurations for extended-marks
--- @field data_dir string? directory where "extended-marks" directory
---                         will be created and store all the data
--- @field Cwd PubCwdOpts? options that cofigure the cwd module
--- @field Local PubLocalOpts? options that cofigure the local module
--- @field Tab PubTabOpts? options that cofigure the tab module
local Opts = {
    data_dir = vim.fn.glob("~/.cache/nvim/"), -- the path to data files
    Cwd = PubCwdOpts,
    Local = PubLocalOpts,
    Tab = PubTabOpts,
}

--- @param opts Opts?;
M.setup = function(opts)
    if not opts then
        opts = Opts
    else
        assert(type(opts) == 'table', "opts should be of a type table")
        opts = vim.tbl_extend("force", Opts, opts)
    end

    opts.data_dir = utils.handle_data_dir(opts.data_dir)

    if opts.Cwd then
        --- @type CwdSetOpts
        local CwdSetOpts = {
            data_dir = opts.data_dir,
            key_length = opts.Cwd.key_length,
        }

        cwd_marks.set_options(CwdSetOpts)
    end

    if opts.Local then
        --- @type LocalSetOpts
        local LocalSetOpts = {
            data_dir = opts.data_dir,
            key_length = opts.Local.key_length,
            sign_column = opts.Local.sign_column
        }

        local_marks.set_options(LocalSetOpts)
    end

    if opts.Tab then
        --- @type TabSetOpts
        local TabSetOpts = {
            key_length = opts.Tab.key_length
        }
        tab_marks.set_options(TabSetOpts)
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
