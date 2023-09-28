local state = require("pybumper.state")
local parser = require("pybumper.parser")
local job = require("pybumper.utils.job")
local virtual_text = require("pybumper.virtual_text")
local reload = require("pybumper.helpers.reload")
local loading = require("pybumper.ui.generic.loading-status")
local logger = require("pybumper.utils.logger")

local extract_outdated_dependencies = function(outdated_dependencies)
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

local M = {}

--- Runs the show outdated dependencies action
-- @return nil
M.run = function(options)
	if not state.is_loaded then
		logger.warn("Not a valid pyproject.toml file")
		logger.warn("State is_loaded: " .. tostring(state.is_loaded))
		logger.warn("State is in project: " .. tostring(state.is_in_project))
		logger.warn("State is virtual_text displed: " .. tostring(state.is_virtual_text_displayed))
		return
	end

	reload()

	options = options or { force = false }

	if state.last_run.should_skip() and not options.force then
		virtual_text.display()
		reload()

		return
	end

	logger.warn("Executing job")

	local id = loading.new("|  Fetching latest versions")

	job({
		json = false,
		command = "poetry show -o | awk -F' +' '{print $1, $2, $3 \" _ \" ;}'",
		-- command = "poetry show --outdated | jq -R -n '[inputs | split("==") | {(.[0]): .[1]}] | add' ",
		ignore_error = false,
		on_start = function()
			loading.start(id)
		end,
		on_success = function(outdated_dependencies)
			logger.warn("Inside on_success")
			-- Add a newline character to the end of the string if it's missing
			local extracted_dependencies = extract_outdated_dependencies(outdated_dependencies)
			-- logger.warn("Extracted dependencies")
			-- print(extracted_dependencies.current_version)
			-- Iterate through the table and print its contents
			-- for key, value in pairs(extracted_dependencies) do
			-- 	print(key, value)
			-- end

			state.dependencies.outdated = extracted_dependencies
			virtual_text.display()
			reload()

			loading.stop(id)

			state.last_run.update()

			-- state.dependencies.outdated = outdated_dependencies

			-- parser.parse_buffer_outdated()
			-- virtual_text.display()
			-- reload()
			--
			-- loading.stop(id)
			--
			-- state.last_run.update()
		end,
		on_error = function()
			loading.stop(id)
		end,
	})
end

return M
