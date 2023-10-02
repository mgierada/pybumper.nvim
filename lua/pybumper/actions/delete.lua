local prompt = require("pybumper.ui.generic.prompt")
local job = require("pybumper.utils.job")
local config = require("pybumper.config")
local logger = require("pybumper.utils.logger")
local state = require("pybumper.state")
local constants = require("pybumper.utils.constants")
local get_dependency_name_from_current_line = require("pybumper.helpers.get_dependency_name_from_current_line")
local reload = require("pybumper.helpers.reload")

local loading = require("pybumper.ui.generic.loading-status")

local M = {}

--- Returns the delete command based on package manager
-- @param dependency_name: string - dependency for which to get the command
-- @return string
M.__get_command = function(dependency_name)
	if config.options.package_manager == constants.PACKAGE_MANAGERS.poetry then
		return "poetry remove " .. dependency_name
	end
end

--- Runs the delete action
-- @return nil
M.run = function()
	if not state.is_loaded then
		logger.warn("Not in valid pyproject.toml file")
		return
	end
	local dependency_name = get_dependency_name_from_current_line()
	if dependency_name == nil then
		return
	end

	local id = loading.new("|  Deleting " .. dependency_name .. " dependency")

	prompt.new({
		title = " Delete [" .. dependency_name .. "] Dependency ",
		on_submit = function()
			job({
				json = false,
				ignore_error = false,
				command = M.__get_command(dependency_name),
				on_start = function()
					loading.start(id)
				end,
				on_success = function()
					reload()
					loading.stop(id)
				end,
				on_error = function()
					loading.stop(id)
				end,
			})
		end,
		on_cancel = function()
			loading.stop(id)
		end,
	})
	prompt.open({
		on_error = function()
			loading.stop(id)
		end,
	})
end

return M
