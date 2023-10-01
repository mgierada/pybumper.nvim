local state = require("pybumper.state")
local parser = require("pybumper.parser")
local job = require("pybumper.utils.job")
local virtual_text = require("pybumper.virtual_text")
local reload = require("pybumper.helpers.reload")
local loading = require("pybumper.ui.generic.loading-status")
local logger = require("pybumper.utils.logger")

-- local extract_outdated_dependencies = function(outdated_dependencies)
-- 	local dependencies = {}
-- 	-- split by the _ character
-- 	for line in outdated_dependencies:gmatch("([^_]+)_") do
-- 		-- Extract package name, current version, and new version using patterns
-- 		local packageName, currentVersion, newVersion = line:match("(%S+)%s+(%S+)%s+(%S+)%s+.*")
--
-- 		-- Add package data to the table
-- 		if packageName and currentVersion and newVersion then
-- 			dependencies[packageName] = {
-- 				current = currentVersion,
-- 				latest = newVersion,
-- 			}
-- 		end
-- 	end
-- 	return dependencies
-- end

local M = {}

--- Runs the show outdated dependencies action
-- @return nil
M.run = function(options)
	if not state.is_loaded then
		logger.warn("Not a valid pyproject.toml file")
		return
	end

	reload()

	options = options or { force = false }

	if state.last_run.should_skip() and not options.force then
		virtual_text.display()
		reload()

		return
	end

	local id = loading.new("|  Fetching latest versions")

	job({
		json = false,
		command = "poetry show -o | awk -F' +' '{print $1, $2, $3 \" _ \" ;}'",
		ignore_error = false,
		on_start = function()
			loading.start(id)
		end,
		on_success = function(outdated_dependencies)
			local extracted_dependencies = parser.extract_outdated_dependencies(outdated_dependencies)

			state.dependencies.outdated = extracted_dependencies
			virtual_text.display()

			reload()

			loading.stop(id)
			state.last_run.update()
		end,
		on_error = function()
			loading.stop(id)
		end,
	})
end

return M
