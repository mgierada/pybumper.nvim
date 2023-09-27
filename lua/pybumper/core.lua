-- TODO: if you have invalid json, then fix it, plugin still wont run

local json_parser = require("pybumper.libs.json_parser")
local parser = require("pybumper.parser")
local state = require("pybumper.state")
local to_boolean = require("pybumper.utils.to-boolean")

local M = {}

--- Checks if the currently opened file
---    - Is a file named pyproject.toml
---    - Has content
-- @return boolean
M.__is_valid_package_json = function()
    local buffer_name = vim.api.nvim_buf_get_name(0)
    local is_package_json = to_boolean(string.match(buffer_name, "pyproject.toml$"))

    if not is_package_json then
        return false
    end

    local has_content = to_boolean(vim.api.nvim_buf_get_lines(0, 0, -1, false))

    if not has_content then
        return false
    end

    -- TODO: For now we don't check if the json is valid
    --
    -- local buffer_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    --
    -- if pcall(function()
    --         json_parser.decode(table.concat(buffer_content))
    --     end) then
    --     return true
    -- end
    --

    return false
end

--- Parser current buffer if valid
-- @return nil
M.load_plugin = function()
    if not M.__is_valid_package_json() then
        state.is_loaded = false

        return nil
    end

    state.buffer.save()
    state.is_loaded = true

    parser.parse_buffer()
end

return M
