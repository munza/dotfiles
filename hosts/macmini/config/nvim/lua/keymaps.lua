-- Keymaps under a space leader, grouped by letter. mini.clue shows a popup
-- of what each prefix can do, using every map's desc.

local function map(modes, key, action, desc, opts)
  vim.keymap.set(modes, key, action, vim.tbl_extend("force", { desc = desc }, opts or {}))
end

-- Find
map("n", "<leader>ff", MiniPick.builtin.files, "Find files")
map("n", "<leader>fg", MiniPick.builtin.grep_live, "Live grep")
map("n", "<leader>fb", MiniPick.builtin.buffers, "Find buffers")
map("n", "<leader>fh", MiniPick.builtin.help, "Help tags")
map("n", "<leader>fo", MiniExtra.pickers.oldfiles, "Recent files")
map("n", "<leader>fe", function()
  -- close() returns nil only when no explorer is open; false means closing was refused.
  if MiniFiles.close() == nil then
    MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
  end
end, "Toggle file explorer")

-- Git: mini.git and mini.diff; ]h and [h jump between hunks.
map("n", "<leader>go", function()
  MiniDiff.toggle_overlay(0)
end, "Toggle diff overlay")
map({ "n", "x" }, "<leader>gs", MiniGit.show_at_cursor, "Show at cursor")
map("n", "<leader>gh", function()
  MiniExtra.pickers.git_hunks({ path = vim.api.nvim_buf_get_name(0) })
end, "Hunks (buffer)")
map("n", "<leader>gH", MiniExtra.pickers.git_hunks, "Hunks (repo)")
map("n", "<leader>gc", MiniExtra.pickers.git_commits, "Commits")
map("n", "<leader>gb", MiniExtra.pickers.git_branches, "Branches")

-- Diagnostics, help, markdown
map("n", "<leader>dd", function()
  MiniExtra.pickers.diagnostics({ scope = "all" })
end, "Diagnostics (all buffers)")
map("n", "<leader>hk", MiniExtra.pickers.keymaps, "Keymaps")
map("n", "<leader>mp", "<cmd>RenderMarkdown toggle<CR>", "Toggle markdown preview")

-- Sessions and buffers
map("n", "<leader>ss", function()
  MiniSessions.write("Session.vim", { force = true })
end, "Save session (cwd)")
map("n", "<leader>sl", MiniSessions.select, "Load session")
map("n", "<leader>bd", MiniBufremove.delete, "Delete buffer")
map("n", "<leader>bw", MiniBufremove.wipeout, "Wipeout buffer")
map("n", "<leader>bn", "<cmd>bnext<CR>", "Next buffer")
map("n", "<leader>bp", "<cmd>bprevious<CR>", "Previous buffer")

-- Windows: <C-w>'s own commands, also under <leader>w. The ones marked
-- repeatable keep the popup open, so <leader>w then hh l jj keeps going.
local windows = {
  { "h", "Focus left", true },
  { "j", "Focus down", true },
  { "k", "Focus up", true },
  { "l", "Focus right", true },
  { "w", "Focus next window", true },
  { "H", "Move to far left", true },
  { "J", "Move to far bottom", true },
  { "K", "Move to far top", true },
  { "L", "Move to far right", true },
  { "+", "Increase height", true },
  { "-", "Decrease height", true },
  { "<", "Decrease width", true },
  { ">", "Increase width", true },
  { "x", "Exchange with next", true },
  { "r", "Rotate down/right", true },
  { "R", "Rotate up/left", true },
  { "=", "Equalize sizes" },
  { "o", "Close all but current" },
  { "c", "Close" },
  { "q", "Quit current" },
  { "p", "Focus last accessed" },
  { "n", "Open new" },
}
local repeatable = {}
for _, w in ipairs(windows) do
  map("n", "<leader>w" .. w[1], "<cmd>wincmd " .. w[1] .. "<CR>", w[2])
  if w[3] then
    table.insert(repeatable, { mode = "n", keys = "<leader>w" .. w[1], postkeys = "<leader>w" })
  end
end
map("n", "<leader>ws", "<cmd>split<CR>", "Split horizontal")
map("n", "<leader>wv", "<cmd>vsplit<CR>", "Split vertical")

-- U redoes, mirroring u (by default it's the rarely used "undo line").
map("n", "U", "<C-r>", "Redo")

-- Visual mode and text objects, reachable from the leader too.
map("n", "<leader>vg", "<cmd>normal! gv<CR>", "Reselect last visual")
map("n", "<leader>vi", "vi", "+Inside textobject", { remap = true })
map("n", "<leader>va", "va", "+Around textobject", { remap = true })

-- Leader aliases into built-in prefixes; remap so mini.clue's popup for the
-- real prefix opens (marks, registers, brackets, folds, surround).
for key, desc in pairs({
  ["'"] = "+Jump",
  ['"'] = "+Yank/Paste",
  ["`"] = "+Jump (exact)",
  ["["] = "+Previous",
  ["]"] = "+Next",
  z = "+Fold/scroll",
  vv = "Visual (charwise)",
  vV = "Visual (linewise)",
  vb = "Visual (blockwise)",
  vs = "+Surround",
}) do
  local target = ({ vv = "v", vV = "V", vb = "<C-v>", vs = "s" })[key] or key
  map({ "n", "x" }, "<leader>" .. key, target, desc, { remap = true })
end

local clue = require("mini.clue")
local triggers = {
  { mode = "i", keys = "<C-r>" },
  { mode = "c", keys = "<C-r>" },
  { mode = "i", keys = "<C-x>" },
  { mode = "n", keys = "<C-w>" },
}
for _, keys in ipairs({ "<leader>", "g", "'", "`", '"', "[", "]", "s", "z" }) do
  table.insert(triggers, { mode = { "n", "x" }, keys = keys })
end

local groups = {}
for key, name in pairs({
  a = "Agent",
  b = "Buffer",
  d = "Diagnostics",
  f = "Find",
  g = "Git",
  h = "Help",
  l = "LSP",
  m = "Markdown",
  s = "Session",
  v = "Visual",
  w = "Window",
}) do
  table.insert(groups, { mode = "n", keys = "<leader>" .. key, desc = "+" .. name })
end

clue.setup({
  window = { delay = 250, config = { width = "auto" } },
  triggers = triggers,
  clues = {
    clue.gen_clues.builtin_completion(),
    clue.gen_clues.g(),
    clue.gen_clues.square_brackets(),
    clue.gen_clues.marks(),
    clue.gen_clues.registers(),
    clue.gen_clues.windows(),
    clue.gen_clues.z(),
    groups,
    repeatable,
  },
})
