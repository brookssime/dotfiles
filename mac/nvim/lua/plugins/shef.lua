-- Project-specific formatting for the shef-mono monorepo (and all its worktrees).
-- Runs prettierd (a warm daemon wrapping the repo-local prettier) on TS/JS,
-- falling back to a one-shot prettier, then the vtsls LSP formatter.
--
-- prettierd serves warm formats in ~0.13s, but its daemon cold start (first
-- save of a session, or after the daemon exits) takes ~1.1-1.3s, which busts
-- conform's default 1000ms synchronous format-on-save budget. We raise that
-- ceiling to 3000ms: it only ever caps a cold start (warm saves still return
-- immediately) and also covers the cold one-shot prettier fallback (~0.97s).

local FORMAT_TIMEOUT_MS = 3000

local function shef_ts_js(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name:match "shef%-mono" then return { "prettierd", "prettier", "vtsls", stop_after_first = true } end
end

---@type LazySpec
return {
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
}
