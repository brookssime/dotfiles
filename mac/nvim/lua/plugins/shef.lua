-- Formatting and linting for the shef-mono monorepo and its worktrees.
-- prettier formats TS/JS, eslint reports diagnostics.
--

local FORMAT_TIMEOUT_MS = 3000

local function shef_ts_js(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name:match "shef%-mono" then return { "prettierd", "prettier", "vtsls", stop_after_first = true } end
end

-- Only start vscode-eslint inside shef-mono. yarn.lock sits at the worktree
-- root. Every workspace package has its own .eslintrc.json and package.json,
-- which would root the server at the package and start one server per
-- workspace. One server handles the whole monorepo and resolves each file's
-- config itself. Returning nil instead of falling back to lspconfig's root_dir
-- keeps this config off every other JS project. Loosen the shef%-mono guard to
-- lint everywhere.
local function shef_eslint_root(bufnr, on_dir)
  if not vim.api.nvim_buf_get_name(bufnr):match "shef%-mono" then return end
  local root = vim.fs.root(bufnr, "yarn.lock")
  if root then on_dir(root) end
end

---@type LazySpec
return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.typescript = shef_ts_js
      opts.formatters_by_ft.typescriptreact = shef_ts_js
      opts.formatters_by_ft.javascript = shef_ts_js
      opts.formatters_by_ft.javascriptreact = shef_ts_js

      opts.format_on_save = function(bufnr)
        if vim.F.if_nil(vim.b[bufnr].autoformat, vim.g.autoformat, true) then
          return { lsp_format = "fallback", timeout_ms = FORMAT_TIMEOUT_MS }
        end
      end
    end,
  },

  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      config = {
        eslint = {
          root_dir = shef_eslint_root,
          -- lspconfig sets cmd to a function, which spawns the server without
          -- cmd_env. A table is what makes NODE_OPTIONS below apply. shef-mono
          -- uses nodeLinker: node-modules and has no local copy of the server,
          -- so skipping lspconfig's node_modules/.bin probe costs nothing.
          cmd = { "vscode-eslint-language-server", "--stdio" },
          cmd_env = { NODE_OPTIONS = "--max-old-space-size=8192" },
          settings = {
            -- airbnb-typescript/base resolves parserOptions.project against the
            -- cwd, and every workspace has its own tsconfig.json. "auto" uses
            -- the nearest package.json, matching the repo's own
            -- `yarn workspace <pkg> lint`. From the worktree root, every TS file
            -- fails with "Cannot read file '<root>/tsconfig.json'".
            workingDirectory = { mode = "auto" },
            run = "onSave",
            format = false,
            experimental = { useFlatConfig = false },
          },
        },
      },
      mappings = {
        n = {
          ["<Leader>lE"] = {
            "<Cmd>LspEslintFixAll<CR>",
            desc = "ESLint fix all (buffer)",
            cond = function(client) return client.name == "eslint" end,
          },
        },
      },
    },
  },
}
