local state = require("pybumper.state")
local parser = require("pybumper.parser")
local job = require("pybumper.utils.job")
local virtual_text = require("pybumper.virtual_text")
local reload = require("pybumper.helpers.reload")
local loading = require("pybumper.ui.generic.loading-status")
local logger = require("pybumper.utils.logger")
local config = require("pybumper.config")
local constants = require("pybumper.utils.constants")

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
local id = loading.new("|  Fetching latest versions")

local command
if config.options.package_manager == constants.PACKAGE_MANAGERS.poetry then
command = "poetry show -o | awk -F' +' '{print $1, $2, $3 \" _ \" ;}'"
elseif config.options.package_manager == constants.PACKAGE_MANAGERS.uv then
command = "uv pip list --outdated | tail -n +3 | awk '{print $1, $2, $3 \" _ \" ;}'"
end

job({
json = false,
command = command,
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
