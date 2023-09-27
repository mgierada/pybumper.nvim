local json_parser = require("pybumper.libs.json_parser")
local state = require("pybumper.state")
local clean_version = require("pybumper.helpers.clean_version")
local logger = require("pybumper.utils.logger")

local function extractDependencies(tomlContent)
    local dependencies = {}
    local insideDependenciesSection = false

    for line in tomlContent:gmatch("[^\r\n]+") do
        -- Trim leading and trailing spaces
        line = line:match("^%s*(.-)%s*$")

        if line:match("^%[tool.poetry.dependencies%]") then
            insideDependenciesSection = true
        elseif insideDependenciesSection and line:match("^%[.-%]") then
            -- We've reached the end of the dependencies section
            break
        elseif insideDependenciesSection and line ~= "" then
            -- Extract key-value pairs within the dependencies section
            local key, value = line:match("^(.-)%s*=%s*(.+)$")
            if key and value then
                dependencies[key] = value
            end
        end
    end

    return next(dependencies) and dependencies or nil, "Dependencies section not found"
end

local M = {}

M.parse_buffer = function()
    local buffer_lines = vim.api.nvim_buf_get_lines(state.buffer.id, 0, -1, false)
    local buffer_content = table.concat(buffer_lines, "\n")
    logger.warn(buffer_content)
    logger.warn("I am here in a parser")

    -- Extract the dependencies section
    local dependencies, err = extractDependencies(buffer_content)

    local installed_dependencies = {}

    if dependencies then
        -- Print the extracted dependencies
        for name, version in pairs(dependencies) do
            print(name, version)
            logger.warn(name .. " : " .. version)
            installed_dependencies[name] = {
                current = clean_version(version),
            }
        end
    else
        -- Handle the error
        print("Error:", err)
        logger.warn("Error: " .. err)
    end

    -- local all_dependencies_json =
    --     vim.tbl_extend("error", {}, buffer_json_value["devDependencies"] or {}, buffer_json_value["dependencies"] or {})
    --
    -- for name, version in pairs(all_dependencies_json) do
    --     installed_dependencies[name] = {
    --         current = clean_version(version),
    --     }
    -- end

    state.buffer.lines = buffer_lines
    state.dependencies.installed = installed_dependencies
end

return M
