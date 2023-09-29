-- TODO: check if there is a text changes event, if so, redraw the dependencies in the buffer, TextChanged autocmd

local logger = require("pybumper.utils.logger")
local M = {}

M.setup = function(options)
	local config = require("pybumper.config")

	config.setup(options)
end

M.show = function(options)
	local show_action = require("pybumper.actions.show")

	show_action.run(options)
end

M.hide = function()
	local hide_action = require("pybumper.actions.hide")

	hide_action.run()
end

M.toggle = function(options)
	local state = require("pybumper.state")

	if state.is_virtual_text_displayed then
		M.hide()
	else
		M.show(options)
	end
end

M.get_status = function()
	local loading = require("pybumper.ui.generic.loading-status")

	return loading.get()
end

return M
