local constants = require("pybumper.utils.constants")
local register_highlight_group = require("pybumper.utils.register-highlight-group")
local register_autocmd = require("pybumper.utils.register-autocmd")
local state = require("pybumper.state")
local job = require("pybumper.utils.job")
local logger = require("pybumper.utils.logger")

local M = {
    __DEFAULT_OPTIONS = {
        colors = {
            up_to_date = "#3C4048",
            outdated = "#d19a66",
        },
        icons = {
            enable = true,
            style = {
                up_to_date = "|  ",
                outdated = "|  ",
            },
        },
        autostart = true,
        package_manager = constants.PACKAGE_MANAGERS.poetry,
        hide_up_to_date = false,
        hide_unstable_versions = false,
    },
}

-- Initialize default options
M.options = M.__DEFAULT_OPTIONS

--- Register namespace for usage for virtual text
-- @return nil
M.__register_namespace = function()
    state.namespace.create()
    logger.warn("Namespace created")
end

-- Check which lock file exists and set package manager accordingly
-- @return nil
-- TODO: Add support for requirements.txt apprach with pip
M.__register_package_manager = function()
    logger.warn("Checking for poetry.lock")
    local poetry_lock = io.open("poetry.lock", "r")

    if poetry_lock ~= nil then
        M.options.package_manager = constants.PACKAGE_MANAGERS.poetry

        io.close(poetry_lock)
        state.is_in_project = true

        return
    end
end

--- Clone options and replace empty ones with default ones
-- @param user_options: M.__DEFAULT_OPTIONS - all the options user can provide in the plugin config
-- @return nil
M.__register_user_options = function(user_options)
    M.options = vim.tbl_deep_extend("keep", user_options or {}, M.__DEFAULT_OPTIONS)
end

--- Prepare a clean augroup for the plugin to use
-- @return nil
M.__prepare_augroup = function()
    vim.cmd("augroup " .. constants.AUTOGROUP)
    vim.cmd("autocmd!")
    vim.cmd("augroup end")
end

--- Register autocommand for loading the plugin
-- @return nil
M.__register_start = function()
    register_autocmd("BufEnter", "lua require('pybumper.core').load_plugin()")
end

--- Register autocommand for auto-starting plugin
-- @return nil
M.__register_autostart = function()
    if M.options.autostart then
        register_autocmd("BufEnter", "lua require('pybumper').show()")
    end
end

--- Sets the plugin colors after the user colorscheme is loaded
-- @return nil
M.__register_colorscheme_initialization = function()
    local colorscheme = vim.api.nvim_exec("colorscheme", true)

    -- If user has no colorscheme(colorscheme is "default"), set the colors manually
    if colorscheme == "default" then
        M.__register_highlight_groups()

        return
    end

    register_autocmd("ColorScheme", "lua require('pybumper.config').__register_highlight_groups()")
end

--- Register all highlight groups
-- @return nil
M.__register_highlight_groups = function()
    local colors = {
        up_to_date = M.options.colors.up_to_date,
        outdated = M.options.colors.outdated,
    }

    -- 256 color support
    if not vim.o.termguicolors then
        colors = {
            up_to_date = constants.LEGACY_COLORS.up_to_date,
            outdated = constants.LEGACY_COLORS.outdated,
        }
    end

    register_highlight_group(constants.HIGHLIGHT_GROUPS.outdated, colors.outdated)
    register_highlight_group(constants.HIGHLIGHT_GROUPS.up_to_date, colors.up_to_date)
end

--- Register all plugin commands
-- @return nil
M.__register_commands = function()
    vim.cmd("command! " .. constants.COMMANDS.show .. " lua require('pybumper').show()")
    vim.cmd("command! " .. constants.COMMANDS.hide .. " lua require('pybumper').hide()")
end

--- Take all user options and setup the config
-- @param user_options: default M table - all options user can provide in the plugin config
-- @return nil
M.setup = function(user_options)
    logger.warn("Setting up pybumper")
    M.__register_user_options(user_options)
    M.__register_package_manager()
    M.__register_namespace()
    M.__prepare_augroup()
    M.__register_start()
    M.__register_colorscheme_initialization()
    M.__register_autostart()
    M.__register_commands()
end

return M
