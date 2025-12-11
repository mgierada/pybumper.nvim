local state = require("pybumper.state")
local clean_version = require("pybumper.helpers.clean_version")
local logger = require("pybumper.utils.logger")
local config = require("pybumper.config")
local constants = require("pybumper.utils.constants")

-- Parse Poetry-style dependencies: [tool.poetry.dependencies]
local function extractPoetryDependencies(tomlContent)
	local dependencies = {}
	local insideDependenciesSection = false
	local insideDevDependenciesSection = false

	for line in tomlContent:gmatch("[^\r\n]+") do
		-- Trim leading and trailing spaces
		line = line:match("^%s*(.-)%s*$")

		if line:match("^%[tool.poetry.dependencies%]") then
			insideDependenciesSection = true
			insideDevDependenciesSection = false
		elseif line:match("^%[tool.poetry.dev%-dependencies%]") then
			insideDevDependenciesSection = true
			insideDependenciesSection = false
		elseif line:match("^%[.-%]") then
			-- We've reached the end of the current section
			insideDependenciesSection = false
			insideDevDependenciesSection = false
		elseif (insideDependenciesSection or insideDevDependenciesSection) and line ~= "" then
			-- Extract key-value pairs within the dependencies section
			local key, value = line:match('^(.-)%s*=%s*"(.-)"$')
			if key and value then
				dependencies[key] = value
			end
		end
	end
	return dependencies
end

-- Parse UV-style dependencies: dependencies = ["package==version", ...]
local function extractUVDependencies(tomlContent)
	local dependencies = {}
	local inDependenciesArray = false
	local inDevArray = false
	local inOptionalArray = false
	local currentArrayContent = ""

	for line in tomlContent:gmatch("[^\r\n]+") do
		-- Trim leading and trailing spaces
		line = line:match("^%s*(.-)%s*$")

		-- Check for start of dependencies array
		if line:match("^dependencies%s*=%s*%[") then
			inDependenciesArray = true
			currentArrayContent = line
			-- Check if array closes on same line
			if line:match("%]%s*$") then
				inDependenciesArray = false
				-- Parse single-line array
				for pkg in line:gmatch('"([^"]+)"') do
					local name, version = pkg:match("^([^=<>~!]+)[=<>~!]+(.*)$")
					if name and version then
						dependencies[name] = version
					end
				end
				currentArrayContent = ""
			end
		-- Check for dev dependencies in [dependency-groups]
		elseif line:match("^%[dependency%-groups%]") then
			inOptionalArray = false
		elseif line:match("^dev%s*=%s*%[") then
			inDevArray = true
			currentArrayContent = line
			-- Check if array closes on same line
			if line:match("%]%s*$") then
				inDevArray = false
				-- Parse single-line array
				for pkg in line:gmatch('"([^"]+)"') do
					local name, version = pkg:match("^([^=<>~!]+)[=<>~!]+(.*)$")
					if name and version then
						dependencies[name] = version
					end
				end
				currentArrayContent = ""
			end
		-- Check for optional dependencies in [project.optional-dependencies]
		elseif line:match("^%[project%.optional%-dependencies%]") then
			inOptionalArray = true
		-- Handle optional dependency arrays starting (e.g., data = [...])
		elseif inOptionalArray and line:match("^%w+%s*=%s*%[") then
			-- This is a new optional dependency array
			currentArrayContent = line
			-- Check if array closes on same line
			if line:match("%]%s*$") then
				-- Parse single-line optional array
				for pkg in line:gmatch('"([^"]+)"') do
					local name, version = pkg:match("^([^=<>~!]+)[=<>~!]+(.*)$")
					if name and version then
						dependencies[name] = version
					end
				end
				currentArrayContent = ""
			else
				-- Multi-line optional array, will continue in next elseif
				inDevArray = true  -- Reuse the dev array flag for optional deps
			end
		-- If we're in a multi-line array, continue parsing
		elseif inDependenciesArray or inDevArray then
			currentArrayContent = currentArrayContent .. " " .. line

			-- Check if we've reached the end of the array
			if line:match("%]") then
				-- Parse all packages in the array
				for pkg in currentArrayContent:gmatch('"([^"]+)"') do
					local name, version = pkg:match("^([^=<>~!]+)[=<>~!]+(.*)$")
					if name and version then
						dependencies[name] = version
					end
				end
				currentArrayContent = ""
				inDependenciesArray = false
				inDevArray = false
			end
		-- Check for new section (stop parsing optional deps)
		elseif line:match("^%[.-%]") then
			inOptionalArray = false
			inDependenciesArray = false
			inDevArray = false
			currentArrayContent = ""
		end
	end

	return dependencies
end

local function extractDependenciesCurrent(tomlContent)
	local dependencies = {}

	-- Try to determine which package manager format to use
	if config.options.package_manager == constants.PACKAGE_MANAGERS.uv then
		dependencies = extractUVDependencies(tomlContent)
	elseif config.options.package_manager == constants.PACKAGE_MANAGERS.poetry then
		dependencies = extractPoetryDependencies(tomlContent)
	else
		-- Fallback: try both formats
		dependencies = extractPoetryDependencies(tomlContent)
		if not next(dependencies) then
			dependencies = extractUVDependencies(tomlContent)
		end
	end

	return next(dependencies) and dependencies or nil, "Dependencies section not found"
end

local M = {}

M.parse_buffer = function()
	local buffer_lines = vim.api.nvim_buf_get_lines(state.buffer.id, 0, -1, false)
	local buffer_content = table.concat(buffer_lines, "\n")

	-- Extract the dependencies section
	local dependencies, err = extractDependenciesCurrent(buffer_content)

	local installed_dependencies = {}

	if dependencies then
		for name, version in pairs(dependencies) do
			installed_dependencies[name] = {
				current = clean_version(version),
			}
		end
	else
		-- Handle the error
		logger.error("Error: " .. err)
	end

	state.buffer.lines = buffer_lines
	state.dependencies.installed = installed_dependencies
end

M.extract_outdated_dependencies = function(outdated_dependencies)
	local dependencies = {}
	-- split by the _ character
	for line in outdated_dependencies:gmatch("([^_]+)_") do
		-- Extract package name, current version, and new version using patterns
		local packageName, currentVersion, newVersion = line:match("(%S+)%s+(%S+)%s+(%S+)%s+.*")

		-- Add package data to the table
		if packageName and currentVersion and newVersion then
			dependencies[packageName] = {
				current = currentVersion,
				latest = newVersion,
			}
		end
	end
	return dependencies
end

return M
