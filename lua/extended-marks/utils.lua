local M = {}

function M.file_exists(file_name)
    local f = io.open(file_name, "rb")
    if f then f:close() end
    return f ~= nil
end

function M.get_data_file(file_path)
    assert(file_path ~= nil, "File path cannot be nil")
    assert(type(file_path) == "string", "File path should be of a type string")

    if not M.file_exists(file_path) then
        local file = io.open(file_path, "w")
        -- if file == nil then
        --     print(vim.inspect(os.execute('mkdir ' .. M.opts.data_dir)))
        --     print("Extended-Marks: data directory was created:", M.opts.data_dir)
        --
        --     file = io.open(file_path, "w")
        -- end

        assert(file ~= nil)

        file:write("{}") -- creating intial JSON object
        file:close()
    end

    return io.open(file_path, "r")
end

-- @working_dir optional
function M.get_json_decoded_data(file_path, working_dir)
    assert(file_path ~= nil, "File path cannot be nil")
    assert(type(file_path) == "string", "File path should be of a type string")
    assert(string.match(file_path, '%.json$'), "File should of type .json")

    if (working_dir ~= nil) then
        assert(type(working_dir) == "string",
            "Working directory name should be of a type string " .. working_dir)
    end

    local file = M.get_data_file(file_path)
    local string_data = file:read("*a")
    file:close()

    local decoded_file = vim.json.decode(string_data, { object = true, array = true })

    if working_dir ~= nil then
        if decoded_file[working_dir] == nil then
            decoded_file[working_dir] = {}
        end
    end

    return decoded_file
end

function M.write_marks(file_path, data)
    assert(file_path ~= nil, "File path cannot be nil")
    assert(string.match(file_path, '%.json$'), "File should of type .json")
    assert(data ~= nil, "Data cannot be nil")
    assert(type(data) == "table", "Data should be of type table")

    local encoded_data = vim.json.encode(data)

    local file = io.open(file_path, "w")
    assert(file ~= nil)
    file:write(encoded_data)
    file:close()
end

-- Removes the values from the table if the value doesn't start with the
-- 'string.* and add a "size" key with current size of the values table
function M.remove_unmatched_values(pattern, values)
    assert(pattern ~= nil or type(pattern) == "string",
        "Matching string should be of a type string and not nil.",
        "String:", pattern)
    assert(values ~= nil, "Values canot be nil")

    local size = 0
    for key, value in pairs(values) do
        assert(value ~= nil, "Value should not be nil")
        assert(type(value) == "string",
            "Values should only contain strings. Value:", value)

        if (pattern.match(value, '^' .. pattern) == nil) then
            values[key] = nil
        else
            size = size + 1;
            values[key] = nil
            table.insert(values, size, value)
        end
    end
    return size
end

--Listens to the pressed keys as long as a new is not a back tick or the total
--number of pressed keys doesn't exceed max_seq_keys
function M.get_mark_key(max_key_seq, first_char)
    assert(max_key_seq ~= nil
        and type(max_key_seq) == "number"
        and max_key_seq > 0
        and max_key_seq < 50)

    assert(first_char ~= nil, "first_char cannot be nil")
    assert(type(first_char) == "number", "first_char should be of type number")
    assert((first_char >= 65 and first_char <= 90
            or (first_char >= 97 and first_char <= 122)),
        "first_char should be [a-zA-Z] character")


    local chars = string.char(first_char)
    if max_key_seq == 1 then return chars end

    local char_counter = 1
    while true do
        local ch = vim.fn.getchar()
        char_counter = char_counter + 1

        -- If ch is not [a-zA-Z] and not a back tick stop markering
        if ((type(ch) ~= "number" or ch < 65 or (ch > 90 and ch < 97)
                or ch > 122) and ch ~= 96) then
            return nil
        end

        -- 96 is a back tick sign "`"
        if (ch == 96) then
            break
        end

        chars = chars .. string.char(ch)

        if (char_counter == max_key_seq) then
            break
        end
    end
    return chars
end

--Listens to the pressed keys as long as a new char is not a back tick or
--the total number of pressed keys doesn't exceed max_seq_keys
--if only one mark key remains, it'll be returned immediately
--if zero mark keys remains, a nil will be returned
function M.get_last_mark_key(max_key_seq, mark_keys, first_char)
    assert(max_key_seq ~= nil
        and type(max_key_seq) == "number"
        and max_key_seq > 0
        and max_key_seq < 50)
    assert(mark_keys ~= nil and type(mark_keys) == "table")
    assert(first_char ~= nil
        and type(first_char) == "number"
        and (first_char >= 65 and first_char <= 90
            or (first_char >= 97 and first_char <= 122))) -- [a-zA-Z]


    local mark_key = ""
    local char_counter = 0
    while true do
        local char = char_counter == 0 and first_char or vim.fn.getchar()
        char_counter = char_counter + 1

        -- If ch is not [a-zA-Z] then stop markering
        if (type(char) ~= "number"
                or (char < 65 or (char > 90 and char < 97) or char > 122)
                and char ~= 96) then
            return
        end
        -- 96 is a back tick sign "`"
        if (char == 96) then
            break
        end

        mark_key = mark_key .. string.char(char)

        if char_counter == max_key_seq then
            break
        end

        local mark_keys_remains = M.remove_unmatched_values(mark_key, mark_keys)
        assert(mark_keys ~= nil, "Mark keys cannot be nil")

        if mark_keys_remains == 1 then
            return table.remove(mark_keys, 1)
        elseif mark_keys_remains == 0 then
            return nil
        end
    end
    return mark_key
end

function M.copy_keys(table)
    assert(table ~= nil and type(table) == "table")

    local keys = {}
    local i = 1
    for key, _ in pairs(table) do
        keys[i] = key
        i = i + 1
    end

    return keys
end
return M

