-- TODO: check if there is a text changes event, if so, redraw the dependencies in the buffer, TextChanged autocmd

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

M.delete = function()
	local delete_action = require("pybumper.actions.delete")
	delete_action.run()
end

M.install = function()
	local install_action = require("pybumper.actions.install")
	install_action.run()
end

M.upadate = function()
	local update_action = require("pybumper.actions.update")
	update_action.run()
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
