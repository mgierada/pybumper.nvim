local M = {}

M.HIGHLIGHT_GROUPS = {
    outdated = "PybumperOutdatedVersion",
    up_to_date = "PybumperUpToDateVersion",
}

M.PACKAGE_MANAGERS = {
    poetry = "poetry",
}

M.DEPENDENCY_TYPE = {
    production = "prod",
    development = "dev",
}

M.LEGACY_COLORS = {
    up_to_date = "237",
    outdated = "173",
}

M.COMMANDS = {
    show = "PybumperShow",
}

M.AUTOGROUP = "PybumperAutogroup"

return M