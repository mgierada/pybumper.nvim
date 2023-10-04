local logger = require("pybumper.utils.logger")
local safe_call = require("pybumper.utils.safe-call")

local clean_and_format_version_list = function(raw_output)
	-- Remove the prefix
	local startIndex = string.find(raw_output, ":") + 1
	local versionString = string.sub(raw_output, startIndex)

	-- Split the remaining string by commas and store in a table
	local versions = {}
	for version in string.gmatch(versionString, "%s*([^,]+)%s*,") do
		table.insert(versions, version)
	end

	-- Add the last version (no trailing comma)
	local lastVersion = string.match(versionString, "%s*([^,]+)%s*$")
	if lastVersion then
		table.insert(versions, lastVersion)
	end

	-- Reverse the table manually
	local reversedVersions = {}
	for i = #versions, 1, -1 do
		table.insert(reversedVersions, versions[i])
	end
	return reversedVersions
end

--- Runs an async job
-- @param props.command - string command to run
-- @param props.on_success - function to invoke with the results
-- @param props.on_error - function to invoke if the command fails
-- @param props.ignore_error?: boolean - ignore non-zero exit codes
-- @param props.on_start?: function - callback to invoke before the job starts
-- @param props.json?: boolean - if output should be parsed as json
-- @return nil
-- TODO: I am not sure I need props.ignore_error
return function(props)
	local value = ""
	safe_call(props.on_start)
	local function on_error()
		logger.error("Error running " .. props.command .. ". Try running manually.")

		if props.on_error ~= nil then
			props.on_error()
		end
	end

	-- Get the current cwd and use it as the value for
	-- cwd in case no pyproject.toml open right now
	local cwd = vim.fn.getcwd()
	-- Get the path of the opened file if there is one
	local file_path = vim.fn.expand("%:p")
	-- If the file is a pyproject.toml then use the directory
	-- of the file as value for cwd
	local file_extension = "pyproject.toml"
	if file_path:sub(-#file_extension) == file_extension then
		cwd = file_path:sub(1, -#file_extension - 1)
	end

	vim.fn.jobstart(props.command, {
		cwd = cwd,
		on_exit = function(_, exit_code)
			if exit_code ~= 0 and not props.ignore_error then
				on_error()
				return
			end
			if props.json then
				local parsed = clean_and_format_version_list(value)
				props.on_success(parsed)
				return
			else
				props.on_success(value)
			end
		end,
		on_stdout = function(_, stdout)
			value = value .. table.concat(stdout)
		end,
	})
end
