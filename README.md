# mapx.lua [![version](https://img.shields.io/github/v/tag/b0o/mapx.lua?style=flat&color=yellow&label=version&sort=semver)](https://github.com/b0o/mapx.lua/releases) [![license: MIT](https://img.shields.io/github/license/b0o/mapx.lua?style=flat&color=green)](https://mit-license.org)

A Neovim lua plugin to make mapping more manageable.

mapx.lua provides lua helper functions that mimic vim's `:map` family of
commands. Its aim is to make configuring key maps from within lua more
ergonomic.

Before mapx:

```lua
vim.api.nvim_set_keymap("", "<C-z>", "<Nop>")
vim.api.nvim_set_keymap("!", "<C-z>", "<Nop>")

vim.api.nvim_set_keymap("n", "j", "v:count ? 'j' : 'gj'", { noremap = true, expr = true })
vim.api.nvim_set_keymap("n", "k", "v:count ? 'k' : 'gk'", { noremap = true, expr = true })

vim.api.nvim_set_keymap("n", "J", "5j")
vim.api.nvim_set_keymap("n", "K", "5k")

vim.api.nvim_set_keymap("i", "<Tab>", [[pumvisible() ? "\<C-n>" : "\<Tab>"]], { noremap = true, silent = true, expr = true })
vim.api.nvim_set_keymap("i", "<S-Tab>", [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]], { noremap = true, silent = true, expr = true })
```

With mapx:

```lua
require'mapx'.setup{ global = true }

map("<C-z>", "<Nop>")
mapbang("<C-z>", "<Nop>")

nnoremap("j", "v:count ? 'j' : 'gj'", "expr")
nnoremap("k", "v:count ? 'k' : 'gk'", "expr")

nmap("J", "5j")
nmap("K", "5k")

inoremap("<Tab>", [[pumvisible() ? "\<C-n>" : "\<Tab>"]], "silent", "expr")
inoremap("<S-Tab>", [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]], "silent", "expr")

-- Map multiple key combinations to the same action
nnoremap({"<C-f><C-f>", "<C-f>f"}, ":lua require('telescope.builtin').find_files()<Cr>", "silent")
```

Mapx also supports integration with [which-key.nvim](https://github.com/folke/which-key.nvim):

```lua
require'mapx'.setup{ global = true, whichkey = true }

-- Add Which-Key labels to mappings
vnoremap ("<leader>y", '"+y', "Yank to system clipboard")
nnoremap ("<leader>Y", '"+yg_', "Yank until EOL to system clipboard")
```

Adding to the global namespace is optional:

```lua
local mapx = require'mapx'.setup{}
mapx.nmap("J", "5j")
mapx.nmap("K", "5k")
```

See [`:h mapx`](https://github.com/b0o/mapx.lua/blob/main/doc/mapx.txt) for the full documentation.

## Install

[Packer](https://github.com/wbthomason/packer.nvim):

```lua
use "b0o/mapx.lua"
```

## Changelog

```
01 Sep 2021                                                             v0.1.0
   Added `mapx.setup()`
   Added `mapx-whichkey-support`
   Breaking: Deprecated `mapx.globalize()` in favor of `setup({global = true})`

28 Aug 2021                                                             v0.0.2
  Added `mapx.globalize()`

27 Aug 2021                                                             v0.0.1
  Initial Release
```

## License

<!-- LICENSE -->

&copy; 2021 Maddison Hellstrom

Released under the MIT License.

<!-- /LICENSE -->
