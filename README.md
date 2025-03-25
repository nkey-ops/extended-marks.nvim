# extended-marks.nvim
Still in development process...


# Features
- Global, Cwd, and Tab mark-keys can have an arbitrary length. 
- Cwd marks allow to mark files relatively to a current working directory.
- Local marks are persisted between sessions.
- Tab marks allow quickly navigate between tabs without looking at them.

# Global Marks
`Global marks` can mark a file and using the mark, a jump to the file can be made from any point of the system.

#### How to Use
Hit `M` (default config) to start writing a first letter of the mark, If the first letter is capital it will be a [#Global Marks](#global-marks), otherwise a [#Tab Marks](#tab-marks) 

At most you can have `Global.key_length` letters in the mark (including the first one).

> 1. If you exhaust your max number of letters, the mark will be set.
> 2. If you don't want to use all the allowed letters for the mark, you can hit `'` (single-quote) to mark the file with the currently provided set of letters.
> 3. If you want to interrupt marking process, hit any key except for `'` and `[a-zA-Z]`

In order to open the file under a certain mark you should hit `'` and then `[A-Z][a-zA-Z]*`: first uppercase letter to use a [#Global Marks](#global-marks) and then, if your mark has more then one letter, the remaining ones.

    :MarksGlobal                     - to check all the global marks
    :MarksGlobalDelete [mark]        - to delete the global mark

    :MarksKeyLength                  - shows the max number of letters for global, cwd, local and tab marks
    :MarksKeyLength global [num]     - to set the max number of letters for global marks
                                       (it is not persited between sessions use the config for that)

# CWD Marks | Current Working Directory Marks
`Cwd marks` mark a file relatively to the current working directory. See `:help current-directory`. It's logic is similar to global marks of vim but the available set of marks is based on the current working directory. It's useful for modular projects or just different projects in general where you want to have a set of marked files for each project separately.

#### How to Use
Hit `m` (default config) to start writing a first letter of the mark.  If the first letter is capital it will be a `cwd mark`, otherwise a [#Local Marks](#local-marks). 

At most you can have `Cwd.key_length` letters in the mark (including the first one). 

> 1. If you exhaust your max number of letters, the mark will be set.
> 2. If you don't want to use all the allowed letters for the mark, you can hit `` ` `` (back-tick) to mark the file with the currently provided set of letters.
> 3. If you want to interrupt marking process, hit any key except for `` ` `` and `[a-zA-Z]`

In order to open the file under a certain mark you should hit `` ` `` and then `[A-Z][a-zA-Z]*`: first uppercase letter to use a `cwd mark` and then, if your mark has more then one letter, the remaining ones.

Supported letters for the mark are `[a-zA-Z]` only the case of the first letter of the mark is important.

    :MarksCwd                     - to check cwd marks for the current working directory
    :MarksCwdAll                  - to check all cwd marks for all directories
    :MarksCwdDelete [mark]        - to delete the mark

    :MarksKeyLength               - shows the max number of letters for global, cwd, local and tab marks
    :MarksKeyLength cwd [num]     - to set the max number of letters for cwd marks
                                    (it is not persited between sessions use the config for that)

<details> 
<summary><b> Example of use </b></summary>

## Example of use 
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

If we open the pom file at `root/pom.xml` and hit `` mP` `` (default config) the file is marked with the `P` letter. You will see a message like this `MarksCwd:[P] /your-path-to-root-directory/root/pom.xml`. Now from any point of neovim (if the cwd is the same) we can open this file by hitting `` `P` `` (backtick, letter P, backtick). 

To see the list of all the marks set for this current working directory call `:MarksCwd`

Because there are multiple `pom` files, we can  assign to them different mark-keys. For example we can mark `root/auth-server/pom` with something like `mAp`, the mark-key is `Ap` first letter signals that it's an `auth-server` module and `p` that it's a `pom` file. But there can be plenty of files with the same goal in different modules and we would have to prepand our mark-key with extra letter to discern them.  

The solution is we can open neovim at the path of these module and make them a current directory or we can use tabs (see `:h tabs`). For example call `:tabe` and in a new tab set its cwd to (by default a new tab will have a cwd of the previous tab) using `:tcd auth-server` (see `:h tcd`). Now the call to `:pwd` shows something like `/your-path-to-root-directory/root/auth-server`

We can create 4 tabs for `root`, `auth-server`, `client-server`, and `resource-server` directories and mark their `pom` files after we set the cwd accordingly, the hit to `` `P` `` will result in opening a `pom` file that is relevant to that current working directory. 
</details>

# Local Marks
To be filled

# Tab Marks
`Tab Marks` mark a tab (see: h:tab-page-intro) you have currently opened. 

#### How to Use
Hit `M` (default config) to mark a file. With the default configuration it will be enough to mark the current tab, if necessary the number of letters in the mark can be increased.

At most you can have `Tab.key_length` letters in the mark.

> 1. If you exhaust your max number of letters, the mark will be set.
> 2. If you don't want to use all the allowed letters for the mark, you can hit `'` (single quote) to mark the current tab with the currently provided set of letters.
> 3. If you want to interrupt marking process, hit any key except for `'` and `[a-zA-Z]`

> In order to open a tab under a certain mark you should hit `'` and then `[a-zA-Z]+`

    :MarksTab                   - to check all the tab marks
    :MarksTabDelete             - to delete tab mark by its key

    :MarksKeyLength               - shows the max number of letters for global, cwd, local and tab marks
    :MarksKeyLength tab [num]   - to set the max number of letters for tab marks 
                                  (it is not persited between sessions use the config for that)

# Configurations
## Lazy.nvim
```lua
{
    "nkey-ops/extended-marks.nvim",
    --- @type ExtendedMarksOpts
    opts =
    {
        -- this is the default configurations for setup function
        data_dir = "~/.cache/nvim/", -- Here extended-marks directory will be created to store data
        Global = {
            key_length = 4           -- valid from 1 to 30
        },
        Cwd = {
            key_length = 4,
        },
        Local = {
            key_length = 1,
            sign_column = 1,         -- 0 for no, 1 or 2 for number of characters
        },
        Tab = {
            key_length = 1,
        },
    },
    init = function()
        -- keymaps should be defined by you, they are not set by default
        local marks = require('extended-marks')
        vim.keymap.set("n", "m", marks.set_cwd_or_local_mark)
        vim.keymap.set("n", "`", marks.jump_to_cwd_or_local_mark)
        vim.keymap.set("n", "M", marks.set_global_or_tab_mark)
        vim.keymap.set("n", "'", marks.jump_to_global_or_tab_mark)
    end,
},
