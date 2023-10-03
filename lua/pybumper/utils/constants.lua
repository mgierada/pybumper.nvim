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
	hide = "PybumperHide",
	delete = "PybumperDelete",
	install = "PybumperInstall",
	update = "PybumperUpdate",
	change_version = "PybumperChangeVersion",
}

M.AUTOGROUP = "PybumperAutogroup"

return M
