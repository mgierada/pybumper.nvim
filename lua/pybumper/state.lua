local M = {
	--- If true, the plugin has detected python project
	is_in_project = false,
	--- If true the current buffer is pyproject.toml, with content and correct format
	is_loaded = false,
	--- If true the virtual text versions are displayed in pyproject.toml
	is_virtual_text_displayed = false,
}

M.dependencies = {
	-- Outdated dependencies from `poetry show --outdated` as a list of
	-- [name]: {
	--     current: string - current dependency version
	--     latest: string - latest dependency version
	-- }
	outdated = {},
	-- Installed dependencies from pyproject.toml as a list of
	-- ["dependency_name"] = {
	--     current: string - current dependency version
	-- }
	installed = {},
}

M.buffer = {
	id = nil,
	-- String value of buffer from vim.api.nvim_buf_get_lines(state.buffer.id, 0, -1, false)
	lines = {},
	--- Set the buffer id to current buffer id
	-- @return nil
	save = function()
		M.buffer.id = vim.fn.bufnr()
	end,
}

M.last_run = {
	time = nil,
	--- Update M.last_run.time to now in milliseconds
	-- @return nil
	update = function()
		M.last_run.time = os.time()
	end,
	--- Determine if the next run should be skipped
	-- Skip if there was a run within the past hour
	-- @return boolean
	should_skip = function()
		local HOUR_IN_SECONDS = 3600

		if M.last_run.time == nil then
			return false
		end

		return os.time() < M.last_run.time + HOUR_IN_SECONDS
	end,
}

M.namespace = {
	id = nil,
	--- Creates plugin specific namespace
	-- @return nil
	create = function()
		M.namespace.id = vim.api.nvim_create_namespace("pybumper")
	end,
}

return M
