---@type LazySpec
return {
  {
    "windwp/nvim-autopairs",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.nvim-autopairs"(plugin, opts) -- include the default astronvim config that calls the setup call
      -- add more custom autopairs configuration such as custom rules
      local npairs = require "nvim-autopairs"
      local Rule = require "nvim-autopairs.rule"
      local cond = require "nvim-autopairs.conds"
      npairs.add_rules(
        {
          Rule("$", "$", { "tex", "latex" })
            -- don't add a pair if the next character is %
            :with_pair(cond.not_after_regex "%%")
            -- don't add a pair if  the previous character is xxx
            :with_pair(
              cond.not_before_regex("xxx", 3)
            )
            -- don't move right when repeat character
            :with_move(cond.none())
            -- don't delete if the next character is xx
            :with_del(cond.not_after_regex "xx")
            -- disable adding a newline when you press <cr>
            :with_cr(cond.none()),
        },
        -- disable for .vim files, but it work for another filetypes
        Rule("a", "a", "-vim")
      )
    end,
  },

  {
    "ThePrimeagen/vim-be-good",
    branch = "master",
  },

  {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html", -- if you have `nvim-treesitter` installed
    dependencies = {
      -- include a picker of your choice, see picker section for more details
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      -- configuration goes here
      lang = "python3",
    },
  },

  {
    "kylechui/nvim-surround",
    version = "^4.0.0", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    -- Optional: See `:h nvim-surround.configuration` and `:h nvim-surround.setup` for details
    -- config = function()
    --     require("nvim-surround").setup({
    --         -- Put your configuration here
    --     })
    -- end
  },

  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require "dap"

      dap.adapters["pwa-node"] = {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = {
          command = "node",
          args = {
            -- NOTE that we don't need to hardcode the path, but can instead use the location from the Mason-installed version via `:MasonInstall js-debug-adapter`
            vim.fn.stdpath "data" .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
            -- NOTE that there's an issue with nvim-dap calling this if you DO NOT specify a port and the host as `127.0.0.1`
            "${port}",
            "127.0.0.1",
          },
        },
      }

      for _, language in ipairs { "typescript", "javascript" } do
        dap.configurations[language] = {
          -- at a minimum, it's nice to be able to interactively pick the process
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
          -- ...
        }
      end
    end,
  },

  {
    "akinsho/toggleterm.nvim",
    opts = {
      direction = "vertical",
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
    },
  },

  {
    "folke/which-key.nvim",
    opts = {
      preset = "classic",
    },
  },

  {
    "chrisgrieser/nvim-lsp-endhints",
    event = "LspAttach",
    opts = {},
  },

  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
    },
  },

  {
    "tpope/vim-fugitive",
  },

  {
    "tpope/vim-rhubarb",
  },

  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    dependencies = { "saghen/blink.cmp" },
  },

  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewFocusFiles",
      "DiffviewToggleFiles",
      "DiffviewRefresh",
    },
    --[[ `<Leader>g` is AstroNvim's Git group; v/V/f/F are the letters it
         leaves free (b, c, C, d, g, l, L, o, p, r, R, s, S, t, T are taken) ]]
    keys = {
      { "<Leader>gv", "<Cmd>DiffviewOpen<CR>", desc = "Diff working tree" },
      { "<Leader>gV", "<Cmd>DiffviewClose<CR>", desc = "Close Diffview" },
      { "<Leader>gf", "<Cmd>DiffviewFileHistory --follow %<CR>", desc = "File history (current file)" },
      { "<Leader>gF", "<Cmd>DiffviewFileHistory<CR>", desc = "File history (branch)" },
      --[[ `:h :range` -- the marks are only set once visual mode is left ]]
      {
        "<Leader>gf",
        "<Esc><Cmd>'<,'>DiffviewFileHistory --follow<CR>",
        mode = "v",
        desc = "File history (selection)",
      },
    },
    --[[ a function so `require("diffview.actions")` runs on load, not at
         startup (requiring it eagerly would pull the plugin in and defeat `cmd`) ]]
    opts = function(_, opts)
      local actions = require "diffview.actions"

      --[[ Diffview's merge-tool picks default to `<leader>c{o,t,b,a}` (ours /
           theirs / base / all; capitals apply to the whole file). AstroNvim
           owns `<Leader>c` as Close buffer, so inside a Diffview the prefix
           hangs on 'timeoutlen' and then closes the diff buffer. Rehome them
           under `<Leader>m` (merge), which nothing else claims; a `false` rhs
           drops a default. `view` gets both scopes, `file_panel` only ships
           the whole-file ones ]]
      local function conflict_maps(scopes)
        local maps = {}
        for key, version in pairs { o = "ours", t = "theirs", b = "base", a = "all" } do
          if scopes.hunk then
            table.insert(maps, { "n", "<leader>c" .. key, false })
            table.insert(maps, {
              "n",
              "<Leader>m" .. key,
              actions.conflict_choose(version),
              { desc = ("Choose %s for this conflict"):format(version:upper()) },
            })
          end
          table.insert(maps, { "n", "<leader>c" .. key:upper(), false })
          table.insert(maps, {
            "n",
            "<Leader>m" .. key:upper(),
            actions.conflict_choose_all(version),
            { desc = ("Choose %s for the whole file"):format(version:upper()) },
          })
        end
        return maps
      end

      --[[ default `q` only hides the panel; these tear the whole tab down.
           Diffview scopes them to its own tabpage, so `q` is untouched elsewhere ]]
      local close = { "n", "q", "<Cmd>DiffviewClose<CR>", { desc = "Close Diffview" } }

      --[[ Diffview's file-panel keys default to `<leader>b` toggle / `<leader>e`
           focus. `<Leader>b` is AstroNvim's Buffers group, so it hangs the same
           way `<Leader>c` did. Mirror AstroNvim's explorer pair instead:
           `<Leader>e` toggles, `<Leader>o` focuses. Both are leaf maps globally
           (Neo-tree toggle / focus), so the buffer-local override is exact and
           the panel simply stands in for the explorer inside a Diffview.
           Lowercase `<leader>` on purpose: diffview merges by the literal lhs
           string, so `<Leader>e` would sit beside its default, not replace it ]]
      local panel = {
        { "n", "<leader>b", false },
        { "n", "<leader>e", actions.toggle_files, { desc = "Toggle file panel" } },
        { "n", "<leader>o", actions.focus_files, { desc = "Focus file panel" } },
      }

      local function join(...)
        local out = {}
        for _, list in ipairs { ... } do
          vim.list_extend(out, list)
        end
        return out
      end

      return require("astrocore").extend_tbl(opts, {
        enhanced_diff_hl = true, -- brighter add/delete highlights inside changed lines
        view = {
          default = { winbar_info = true },
          file_history = { winbar_info = true },
          --[[ OURS | THEIRS side by side over the working copy you actually
               edit. `g<C-x>` cycles layouts; diff4_mixed adds a BASE pane ]]
          merge_tool = { layout = "diff4_mixed", disable_diagnostics = true, winbar_info = true },
        },
        keymaps = {
          view = join({ close }, panel, conflict_maps { hunk = true }),
          file_panel = join({ close }, panel, conflict_maps {}),
          file_history_panel = { close },
        },
      })
    end,
  },

  {
    "nvim-pack/nvim-spectre",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },

  { "axelvc/template-string.nvim" },
}
