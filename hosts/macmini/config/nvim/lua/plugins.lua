-- Plugins, pinned in nvim-pack-lock.json next to init.lua. `:lua vim.pack.update()`
-- updates them; commit the lockfile afterwards.

vim.pack.add({
  "https://github.com/nvim-mini/mini.nvim",
  "https://github.com/EdenEast/nightfox.nvim",
  "https://github.com/f-person/auto-dark-mode.nvim",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/b0o/SchemaStore.nvim", -- JSON/YAML schemas for jsonls and yamlls
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/MeanderingProgrammer/render-markdown.nvim",
  "https://github.com/rafamadriz/friendly-snippets", -- snippet collection for mini.snippets
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  -- Only its queries are used, by mini.ai below.
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
  -- The Lua half of herdr-nvim; the herdr side is `herdr plugin install ChmaraX/herdr-nvim`.
  -- Keep this rev in step with `herdr plugin list` so both halves speak the same protocol.
  { src = "https://github.com/ChmaraX/herdr-nvim", version = "e2ec32e7bbbb1eefd64363414b5806f84eedd6bc" },
})

-- Colors: Nightfox when macOS is dark, Dayfox when light. Set once now, so
-- startup doesn't flash the default scheme before auto-dark-mode checks macOS.
vim.cmd.colorscheme("nightfox")
require("auto-dark-mode").setup({
  set_dark_mode = function()
    vim.o.background = "dark"
    vim.cmd.colorscheme("nightfox")
  end,
  set_light_mode = function()
    vim.o.background = "light"
    vim.cmd.colorscheme("dayfox")
  end,
})

-- mini.nvim: one plugin, many small modules.
for _, module in ipairs({
  -- Navigation and UI
  "icons", "pick", "files", "bracketed", "extra", "sessions",
  "statusline", "tabline", "cursorword", "notify", "animate",
  -- Editing
  "pairs", "surround", "comment", "indentscope", "splitjoin",
  "move", "jump", "jump2d", "trailspace", "align", "bufremove",
  -- As-you-type completion; attaches to LSP servers on its own.
  "completion",
  "git",
}) do
  require("mini." .. module).setup()
end

-- Text objects from tree-sitter on top of mini.ai's own (f stays function call):
-- F function definition, c class, o block/loop/conditional, e.g. daF, vic, yio.
local ai = require("mini.ai")
ai.setup({
  custom_textobjects = {
    F = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
    c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
    o = ai.gen_spec.treesitter({
      a = { "@block.outer", "@conditional.outer", "@loop.outer" },
      i = { "@block.inner", "@conditional.inner", "@loop.inner" },
    }),
  },
})

-- Snippets from friendly-snippets, offered in the completion menu by a small
-- built-in server. <C-j> expands, <C-l>/<C-h> jump between fields, <C-c> stops.
local snippets = require("mini.snippets")
snippets.setup({ snippets = { snippets.gen_loader.from_lang() } })
snippets.start_lsp_server()

-- Git signs in the gutter (otherwise it colors line numbers).
require("mini.diff").setup({ view = { style = "sign" } })

-- Start screen: actions, recent files (all and in this folder), sessions.
local starter = require("mini.starter")
starter.setup({
  items = {
    starter.sections.builtin_actions(),
    starter.sections.recent_files(10, false),
    starter.sections.recent_files(10, true),
    starter.sections.sessions(5, true),
  },
})

-- TODO/FIXME/HACK/NOTE markers and hex color previews.
local hipatterns = require("mini.hipatterns")
local function word(text, group)
  return { pattern = "%f[%w]()" .. text .. "()%f[%W]", group = group }
end
hipatterns.setup({
  highlighters = {
    fixme = word("FIXME", "MiniHipatternsFixme"),
    hack = word("HACK", "MiniHipatternsHack"),
    todo = word("TODO", "MiniHipatternsTodo"),
    note = word("NOTE", "MiniHipatternsNote"),
    hex_color = hipatterns.gen_highlighter.hex_color(),
  },
})

-- Format with the filetype's formatter, or the language server's when none is set.
require("conform").setup({
  formatters_by_ft = {
    nix = { "nixfmt" },
    lua = { "stylua" },
    python = { "ruff_format" },
    -- The project's own mix wins inside a devenv/direnv shell.
    elixir = { "mix" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    markdown = { "prettierd" },
    json = { "prettierd" },
    jsonc = { "prettierd" },
    yaml = { "prettierd" },
    html = { "prettierd" },
    css = { "prettierd" },
    javascript = { "prettierd" },
    javascriptreact = { "prettierd" },
    typescript = { "prettierd" },
    typescriptreact = { "prettierd" },
  },
})

-- Markdown rendered in the buffer; still editable, <leader>mp shows the source.
require("render-markdown").setup({})

-- Comment lines to the agent in this herdr workspace, or send it a path:line;
-- maps under <leader>a. Outside herdr it reports that no agent is reachable.
require("herdr-nvim").setup({})

-- Tree-sitter: parsers for the languages in use, compiled once on first start.
local languages = {
  "bash", "elixir", "go", "javascript", "json", "lua", "python", "rust",
  "toml", "tsx", "typescript", "yaml",
  "css", "dockerfile", "html", "markdown", "markdown_inline", "nix",
  "query", "regex", "vim", "vimdoc",
}
require("nvim-treesitter").install(languages)

-- Highlighting, indentation and folds for any buffer with a parser.
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    if not pcall(vim.treesitter.start, args.buf) then
      return
    end
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  end,
})
