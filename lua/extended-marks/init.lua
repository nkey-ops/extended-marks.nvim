local global_marks = require('extended-marks.global')
local cwd_marks = require('extended-marks.cwd')
local local_marks = require('extended-marks.local')
local tab_marks = require('extended-marks.tab')
local utils = require('extended-marks.utils')

local M = {}

--- @class PubGlobalOpts allows external code to manage some configurations of
---                      the global module
--- @field key_length integer? default:4 | max number of characters in the mark [1 to 30)
local PubGlobalOpts = {
    key_length = 4
}

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

--- @class ExtendedMarksOpts configurations for extended-marks
--- @field data_dir string? directory where "extended-marks" directory
---                         will be created and store all the data
--- @field Global PubGlobalOpts? options that configure the global module
--- @field Cwd PubCwdOpts? options that cofigure the cwd module
--- @field Local PubLocalOpts? options that cofigure the local module
--- @field Tab PubTabOpts? options that cofigure the tab module
local Opts = {
    data_dir = vim.fn.glob("~/.cache/nvim/"), -- the path to data files
    Global = PubGlobalOpts,
    Cwd = PubCwdOpts,
    Local = PubLocalOpts,
    Tab = PubTabOpts,
}

--- @param opts ExtendedMarksOpts?;
M.setup = function(opts)
    if not opts then
        opts = Opts
    else
        assert(type(opts) == 'table', "opts should be of a type table")
        opts = vim.tbl_extend("force", Opts, opts)
    end

    opts.data_dir = utils.handle_data_dir(opts.data_dir)

    if opts.Global then
        --- @type GlobalSetOpts
        local GlobalSetOpts = {
            data_dir = opts.data_dir,
            key_length = opts.Global.key_length,
        }

        global_marks.set_options(GlobalSetOpts)
    end

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

--- Waits for [a-zA-Z] keys until max number letters was exceeded.
--- If other key is pressed, silently exits, or if '`' backtick is pressed,
--- creates a mark with the current letters.
--- If a first letter is uppercase [A-Z], a cwd mark will be created
--- If a first letter is lowercase [a-z], a local mark will be created
--- Only Opts.Cwd.key_length number of letters is available for cwd marks
--- Only Opts.Local.key_length number of letters is available for local marks
--- After last letter was used, a mark will be set
M.set_cwd_or_local_mark = function()
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

--- Waits for [a-zA-Z] keys until max number letters was exceeded.
--- If other key is pressed, silently exits,
--- or if '`' backtick is pressed, jumps to a mark that has a key equal the current letters,
--- if not found, silently exist.
--- If a first letter is uppercase [A-Z], a cwd mark will be jumped to
--- If a first letter is lowercase [a-z], a local mark will be jumped to
--- Only Opts.Cwd.key_length number of letters is available for cwd marks
--- Only Opts.Local.key_length number of letters is available for local marks
--- After last letter was used, a jump will be made
M.jump_to_cwd_or_local_mark = function()
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

--- Waits for [a-zA-Z] keys until max number letters was exceeded.
--- If other key is pressed, silently exits, or if '`' backtick is pressed,
--- creates a mark with the current letters.
--- If a first letter is uppercase [A-Z], a global mark will be created
--- If a first letter is lowercase [a-z], a tab mark will be created
--- Only Opts.Glob.key_length number of letters is available for global marks
--- Only Opts.Tab.key_length number of letters is available for tab marks
--- After last letter was used, a mark will be set
M.set_global_or_tab_mark = function()
    local ch = vim.fn.getchar()

    if (type(ch) == 'string') then
        return
    end
    assert(type(ch) == 'number')

    if (ch >= 97 and ch <= 122) then  --[a-z]
        tab_marks.set_mark(ch)
    elseif ch >= 65 and ch <= 90 then --[A-Z]
        global_marks.set_mark(ch)
    end
end

--- Waits for [a-zA-Z] keys until max number letters was exceeded.
--- If other key is pressed, silently exits,
--- or if '`' backtick is pressed, jumps to a mark that has a key equal the current letters,
--- if not found, silently exist.
--- If a first letter is uppercase [A-Z], a global mark will be jumped to
--- If a first letter is lowercase [a-z], a tab mark will be jumped to
--- Only Opts.Glob.key_length number of letters is available for global marks
--- Only Opts.Tab.key_length number of letters is available for tab marks
--- After last letter was used, a jump will be made
M.jump_to_global_or_tab_mark = function()
    local ch = vim.fn.getchar()

    if (type(ch) == 'string') then
        return
    end

    assert(type(ch) == 'number')

    if (ch >= 97 and ch <= 122) then  --[a-z]
        tab_marks.jump_to_mark(ch)
    elseif ch >= 65 and ch <= 90 then --[A-Z]
        global_marks.jump_to_mark(ch)
    elseif (ch == string.byte("'")) then
        vim.cmd("tabnext #") -- last accessed tab
    elseif (ch == string.byte("$")) then
        vim.cmd("tabnext $") -- last tab
    elseif (ch == string.byte("1")) then
        vim.cmd("1tabnext")  -- first tab
    end
end

return M
