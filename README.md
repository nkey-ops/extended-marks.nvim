# extended-marks.nvim
Still in development process...


# Features
- Mark-keys can have arbitrary length. 
- Cwd marks allow to mark files relatively to a current working directory.
- Local marks are persisted between sessions.
- Tab marks allow quickly navigate between tabs without looking at them.

# CWD Marks | Current Working Directory Marks
`Cwd marks` mark a file relatively to the current working directory. See `:help current-directory`. It's logic is similar to global marks of vim but the available set of marks is based on the current working directory. It's useful for modular projects or just different projects in general where you want to have a set of marked files for each project separately.

## How to Use
Hit `m` (default config) to start writing a first letter of the mark.  If the first letter is capital it will be a `cwd mark`, otherwise a `local mark`. 

At most you can have `cwd.key_length` letters in the mark (including the first one). 

1. If you exhaust your max number of letters the mark will be set.
2. If you don't want to use all the allowed letters for the mark you can hit `` ` `` (default config) to mark the file with the current provided letters for the mark.
3. If you want to interrupt marking process, hit any key apart from `` ` `` and `[a-zA-Z]`

In order to open the file under a certain mark you should hit `` ` `` and then `[A-Z][a-z]*`: first uppercase letter to use a `cwd mark` and then, if your mark has more then one letter, the remaining ones.

Supported letters for the mark are `[a-zA-Z]` only the case of the first letter of the mark is important.

    :MarksCwd                     - to check cwd marks for the current working directory
    :MarksCwdAll                  - to check all cwd marks for all directories
    :MarksCwdDelete [mark]        - to delete the mark

    :MarksKeyLength               - shows the max number of letters for cwd, local and tab marks 
    :MarksKeyLength cwd [num]     - to set the max number of letters for cwd marks 
                                    (it is not persited between sessions use the config for that)
    

## Relevant Example of Use 
Here is an example of the modular project directory tree: 

     root ─┐
           ├── auth-server
           │   └── pom.xml
           ├── client-server
           │   └── pom.xml
           ├── resource-server
           │   └── pom.xml
           └── pom.xml

When neovim is opened at the path of the root directory the result of the call `:pwd`  (see `:h pwd`) will look like this `/your-path-to-root-directory/root`. Now every file we mark will be accessible only in case if our current working directory (cwd) is equal to that path.

If we open the pom file at `root/pom.xml` and hit `mP` (default config) the file is marked with the `P` letter. You will see a message like this `MarksCwd:[P] /your-path-to-root-directory/root/pom.xml`. Now from any point of neovim (if the cwd is the same) we can open this file by hitting `` `P` ``. 

To see the list of all the marks set for this current working directory call `:MarksCwd`

Because there are multiple `pom` files, we can  assign to them different mark-keys. For example we can mark `root/auth-server/pom` with something like `mAp`, the mark-key is `Ap` first letter signals that it's an `auth-server` module and `p` that it's a `pom` file. But there can be plenty of files with the same goal in different modules and we would have to prepand our mark-key with extra letter to discern them.  

The solution is we can open neovim at the path of these module and make them a current directory or we can use tabs (see `:h tabs`). For example call `:tabe` and in a new tab set its cwd to (by default a new tab will have a cwd of the previous tab) using `:tcd auth-server` (see `:h tcd`). Now the call to `:pwd` shows something like `/your-path-to-root-directory/root/auth-server`

We can create 4 tabs for `root`, `auth-server`, `client-server`, and `resource-server` directories and mark their `pom` files after we set the cwd accordingly, the hit to `` `P` `` will result in opening a `pom` file that is relevant to that current working directory. 


# Local Marks
To be filled

# Tab Marks
To be filled

# Configurations

Lazy.nvim
```lua
{
    "nkey-ops/extended-marks.nvim",
    config = function()
        require('extended-marks').setup({
            -- this is the default configurations for setup function
            data_dir = vim.fn.glob("~/.cache/nvim/"), -- Here extended-marks dir will be created to store data
            locaL = { -- don't confuse with 'local'
                key_length = 1,             -- valid from 1 to 30
                sign_column = 1,            -- 0 for no, 1 or 2 for number of characters 
            },
            cwd = {
                key_length = 4,
            },
            tab = {
                key_length = 1,
            },
        })
    end,
    init = function()
        -- keymaps should be defined by you, they are not set by default
        local marks = require('extended-marks')
        vim.keymap.set("n", "m", marks.set_mark)
        vim.keymap.set("n", "`", marks.jump_to_mark)
        vim.keymap.set("n", "M", marks.set_tab_mark)
        vim.keymap.set("n", "'", marks.jump_to_tab_mark)
    end,
},
```
