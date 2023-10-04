local Menu = require("nui.menu")

local config = require("pybumper.config")
local loading = require("pybumper.ui.generic.loading-status")
local job = require("pybumper.utils.job")
local logger = require("pybumper.utils.logger")
local state = require("pybumper.state")
local constants = require("pybumper.utils.constants")
local get_dependency_name_from_current_line = require("pybumper.helpers.get_dependency_name_from_current_line")
local reload = require("pybumper.helpers.reload")

local dependency_version_select = require("pybumper.ui.dependency-version-select")

local M = {}

--- Returns the change version command based on package manager
-- @param dependency_name: string - dependency for which to get the command
-- @param version: string - used to denote the version to be installed
-- @return string
M.__get_change_version_command = function(dependency_name, version)
	if config.options.package_manager == constants.PACKAGE_MANAGERS.poetry then
		return "poetry add " .. dependency_name .. "@" .. version
	end
end

--- Returns available package versions command based on package manager
-- @param dependency_name: string - dependency for which to get the command
-- @return string
M.__get_version_list_command = function(dependency_name)
	if config.options.package_manager == constants.PACKAGE_MANAGERS.poetry then
		return ("pip index versions " .. dependency_name)
	end
end

--- Display dependency version select UI
-- @param version_list: Menu.item[] - items to be rendered in the menu
-- @param dependency_name: string - dependency for which to run change version command
-- @return nil
M.__display_dependency_version_select = function(version_list, dependency_name)
	dependency_version_select.new({
		version_list = version_list,
		on_submit = function(selected_version)
			local id = loading.new("|  Installing " .. dependency_name .. "@" .. selected_version)

			job({
				command = M.__get_change_version_command(dependency_name, selected_version),
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
	})

	dependency_version_select.open()
end

--- Maps output from command to menu items
-- @param versions: string[] - versions to map to menu items
-- @return Menu.item[] - versions mapped to menu items
M.__create_select_items = function(versions)
	local version_list = {}

	-- Iterate versions from the end to show the latest versions first
	for index = #versions, 1, -1 do
		local version = versions[index]
		local is_unstable = string.match(version, "-")

		--  Skip unstable version e.g next@11.1.0-canary
		if is_unstable then
			if not config.options.hide_unstable_versions then
				table.insert(version_list, Menu.item(version))
			end
		else
			table.insert(version_list, Menu.item(version))
		end
	end

	return version_list
end

--- Runs the change version action
-- @return nil
M.run = function()
	if not state.is_loaded then
		logger.warn("Not in valid package.json file")
		return
	end

	local dependency_name = get_dependency_name_from_current_line()

	if not dependency_name then
		return
	end

	local id = loading.new("|  Fetching " .. dependency_name .. " versions")
	local command = M.__get_version_list_command(dependency_name)

	job({
		json = true,
		command = command,
		on_start = function()
			loading.start(id)
		end,
		on_success = function(versions)
			loading.stop(id)

			local version_list = M.__create_select_items(versions)

			M.__display_dependency_version_select(version_list, dependency_name)
		end,
		on_error = function()
			loading.stop(id)
		end,
	})
end

return M
