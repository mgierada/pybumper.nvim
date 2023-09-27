local constants = require("pybumper.utils.constants")

--- Register given command when the event fires
-- @param event: string - event that will trigger the autocommand
-- @param command: string - command to fire when the event is triggered
return function(event, command)
    vim.cmd("autocmd " .. constants.AUTOGROUP .. " " .. event .. " pyproject.toml" .. command)
end
