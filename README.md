<div align="center">

# pybumper.nvim

## A wrapper around Python package managers for nvim 🔌

</div>

<div align="center">

![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua&logoColor=white)

</div>

<div align="center">

![License](https://img.shields.io/badge/License-MIT-brightgreen?style=flat-square)
![Status](https://img.shields.io/badge/Status-Beta-informational?style=flat-square)
![Neovim](https://img.shields.io/badge/Neovim-0.9+-green.svg?style=flat-square&logo=Neovim&logoColor=white)

</div>

## ✨ Features

- ✨ Display latest dependency versions as virtual text.
- ✨ Install any available dependency from a drop down list based on a current line.
- ✨ Add any new valid dependency.
- ✨ Upgrade dependency on a current line.
- ✨ Remove any dependency.
- 🏗 Automatic package manager detection (`poetry` and `uv` supported. Support for `requirements.txt` would be added later.).
- 🏗 Loading animation hook (to be placed in status bar or anywhere else).

## 🔌 Available commands

### Display virtual_text with info about the latest versions of dependencies.

<details>
<summary>Click to expand</summary>

![](./media/demo_show.gif)

</details>

### Hide or show available version on demand

<details>
<summary>Click to expand</summary>

![](./media/demo_hide.gif)

</details>

### Install any valid dependency

<details>
<summary>Click to expand</summary>

![](./media/demo_install.gif)

</details>

### Delete any dependency for the current line

<details>
<summary>Click to expand</summary>

![](./media/demo_delete.gif)

</details>

### Change version of any dependency from the current line

<details>
<summary>Click to expand</summary>

![](./media/demo_change_version.gif)

</details>

## ⚡️Requirements

It should work with any fairly modern python tech stack. I tested that for the following:

- neovim >= 0.9 and nightly 0.10-dev releases
- poetry >= 1.5.1 (if using poetry)
- uv >= 0.1.0 (if using uv)
- python >= 3.10.8
- pip >= 23.2.1

## 💻 Installation

Install with your favourite package manager

[Lazy](https://github.com/folke/lazy.nvim)

```lua
  -- Pybumper
  {
    "mgierada/pybumber.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    config = function() require("pybumper").setup {} end,
    event = "BufRead",
  },

```

## ⚙️ Configuration

The `pybumper.nvim` comes up with the following configuration. Any of of those can be easily overridden by providing a config to setup function.

```lua
{
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
	package_manager = constants.PACKAGE_MANAGERS.poetry, -- or constants.PACKAGE_MANAGERS.uv
	hide_up_to_date = false,
	hide_unstable_versions = false,
},

```

## 💡 Inspiration

This plugin is inspired by [`package.info.nvim`](https://github.com/vuki656/package-info.nvim) which is designed to work in the JavaScript/TypeScript environment.
