local json_parser = require("pybumper.libs.json_parser")
local state = require("pybumper.state")
local clean_version = require("pybumper.helpers.clean_version")
local logger = require("pybumper.utils.logger")

local function extractDependenciesCurrent(tomlContent)
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
			local key, value = line:match('^(.-)%s*=%s*"(.-)"$')
			if key and value then
				dependencies[key] = value
			end
		end
	end
	return next(dependencies) and dependencies or nil, "Dependencies section not found"
end

local function extractDevDependenciesCurrent(tomlContent)
	local devDependencies = {}
	local insideDevDependenciesSection = false

	for line in tomlContent:gmatch("[^\r\n]+") do
		-- Trim leading and trailing spaces
		line = line:match("^%s*(.-)%s*$")

		if line:match("^%[tool.poetry.dev%-dependencies%]") then
			insideDevDependenciesSection = true
		elseif insideDevDependenciesSection and line:match("^%[.-%]") then
			-- We've reached the end of the dev dependencies section
			break
		elseif insideDevDependenciesSection and line ~= "" then
			-- Extract key-value pairs within the dev dependencies section
			local key, value = line:match('^(.-)%s*=%s*"(.-)"$')
			if key and value then
				devDependencies[key] = value
			end
		end
	end

	return next(devDependencies) and devDependencies or nil, "Dev dependencies section not found"
end

local M = {}

M.parse_buffer = function()
	local buffer_lines = vim.api.nvim_buf_get_lines(state.buffer.id, 0, -1, false)
	local buffer_content = table.concat(buffer_lines, "\n")

	-- Extract the dependencies section
	local dependencies, err = extractDependenciesCurrent(buffer_content)
	print(vim.inspect(dependencies))
	-- local devDependencies, err = extractDevDependenciesCurrent(buffer_content)
	-- print(vim.inspect(devDependencies))

	local installed_dependencies = {}

	if dependencies then
		for name, version in pairs(dependencies) do
			installed_dependencies[name] = {
				-- current = clean_version(version),
				current = version,
			}
		end
	else
		-- Handle the error
		logger.error("Error: " .. err)
	end

	-- Log installed dependencies
	-- logger.warn("Installed dependencies:" .. vim.inspect(installed_dependencies))
	state.buffer.lines = buffer_lines
	state.dependencies.installed = installed_dependencies
	-- logger.warn("Installed dependencies from state:" .. vim.inspect(state.dependencies.installed))
end

M.parse_buffer_outdated = function()
	local buffer_lines = vim.api.nvim_buf_get_lines(state.buffer.id, 0, -1, false)
	local buffer_content = table.concat(buffer_lines, "\n")

	-- Extract the dependencies section
	-- local dependencies, err = extractDependencies(buffer_content)
	--
	-- local installed_dependencies = {}
	--
	-- if dependencies then
	--     for name, version in pairs(dependencies) do
	--         installed_dependencies[name] = {
	--             current = clean_version(version),
	--         }
	--     end
	-- else
	--     -- Handle the error
	--     logger.error("Error: " .. err)
	-- end
	--
	-- -- Log installed dependencies
	-- logger.warn("Installed dependencies:" .. vim.inspect(installed_dependencies))
	-- state.buffer.lines = buffer_lines
	-- state.dependencies.installed = installed_dependencies
end

return M
