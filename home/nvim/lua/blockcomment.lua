-- Block comments for languages that support them.
--
-- `gb{motion}` / `gbc` / visual `gb` wrap a range in the filetype's block comment.
-- Any line comment markers inside the range are stripped first, so running it on a
-- run of `// foo` lines converts them into a single `/* ... */` block.
--
-- A single content line collapses to the one-line form (`/* foo */`); multiple lines
-- expand with aligned continuation markers. Set `M.collapse_single = false` to always
-- use the multi-line form.

local M = {}

M.collapse_single = true

---@class BlockCommentSpec
---@field start string opening delimiter
---@field prefix string continuation prefix for interior lines
---@field finish string closing delimiter
---@field line? string line comment marker, when `commentstring` can't supply it

local c_style = { start = "/*", prefix = " *", finish = " */", line = "//" }
local xml_style = { start = "<!--", prefix = "   ", finish = "-->" }

---@type table<string, BlockCommentSpec>
local specs = {
  c = c_style,
  cpp = c_style,
  cs = c_style,
  css = c_style,
  cuda = c_style,
  dart = c_style,
  glsl = c_style,
  go = c_style,
  groovy = c_style,
  java = c_style,
  javascript = c_style,
  javascriptreact = c_style,
  json5 = c_style,
  jsonc = c_style,
  kotlin = c_style,
  less = c_style,
  objc = c_style,
  php = c_style,
  proto = c_style,
  rust = c_style,
  scala = c_style,
  scss = c_style,
  sql = { start = "/*", prefix = " *", finish = " */", line = "--" },
  swift = c_style,
  typescript = c_style,
  typescriptreact = c_style,

  html = xml_style,
  markdown = xml_style,
  svelte = xml_style,
  vue = xml_style,
  xml = xml_style,

  lua = { start = "--[[", prefix = "", finish = "]]", line = "--" },
  haskell = { start = "{-", prefix = " ", finish = "-}", line = "--" },
  ocaml = { start = "(*", prefix = " *", finish = " *)" },
  ruby = { start = "=begin", prefix = "", finish = "=end", line = "#" },
}

---@param ft string
---@return BlockCommentSpec?
local function spec_for(ft) return specs[ft] end

--- The line comment marker for the current buffer, preferring `commentstring` so that
--- filetype plugins and embedded languages stay authoritative.
---@param spec BlockCommentSpec
---@return string?
local function line_marker(spec)
  local cs = vim.bo.commentstring
  -- only match commentstrings with nothing after `%s`, so `/* %s */` doesn't yield `/*`
  local marker = cs ~= "" and cs:match "^(.-)%s*%%s%s*$" or nil
  if marker and marker ~= "" then return marker end
  return spec.line
end

--- Shortest leading whitespace across non-blank lines.
---@param lines string[]
---@return string
local function common_indent(lines)
  local indent
  for _, line in ipairs(lines) do
    if line:match "%S" then
      local ws = line:match "^%s*"
      if not indent or #ws < #indent then indent = ws end
    end
  end
  return indent or ""
end

--- Replace lines `srow`..`erow` (1-indexed, inclusive) with a block comment.
---@param srow integer
---@param erow integer
function M.block(srow, erow)
  local ft = vim.bo.filetype
  local spec = spec_for(ft)
  if not spec then
    vim.notify("No block comment syntax known for filetype '" .. ft .. "'", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
  if #lines == 0 then return end

  local indent = common_indent(lines)
  local marker = line_marker(spec)
  local pattern = marker and ("^" .. vim.pesc(marker) .. "%s?") or nil

  -- strip the common indent and any line comment marker from each line
  local content = {}
  for _, line in ipairs(lines) do
    local body = line:sub(#indent + 1):gsub("%s+$", "")
    if pattern then body = body:gsub(pattern, "") end
    table.insert(content, body)
  end

  -- drop leading/trailing blank lines so the delimiters hug the text
  while #content > 0 and content[1] == "" do
    table.remove(content, 1)
  end
  while #content > 0 and content[#content] == "" do
    table.remove(content)
  end
  if #content == 0 then return end

  -- bail rather than nest, or produce a comment that terminates early
  local closer = vim.trim(spec.finish)
  if vim.startswith(content[1], spec.start) then
    vim.notify("Already a block comment", vim.log.levels.WARN)
    return
  end
  for _, body in ipairs(content) do
    if body:find(closer, 1, true) then
      vim.notify("Range already contains '" .. closer .. "'; not wrapping", vim.log.levels.WARN)
      return
    end
  end

  local out = {}
  if #content == 1 and M.collapse_single then
    table.insert(out, indent .. spec.start .. " " .. content[1] .. " " .. closer)
  else
    table.insert(out, indent .. spec.start)
    for _, body in ipairs(content) do
      -- keep the prefix aligned on blank interior lines, but without trailing whitespace
      local prefixed = indent .. spec.prefix .. (body == "" and "" or " " .. body)
      table.insert(out, (prefixed:gsub("%s+$", "")))
    end
    table.insert(out, indent .. spec.finish)
  end

  vim.api.nvim_buf_set_lines(0, srow - 1, erow, false, out)
end

--- Grow a single line into the contiguous run of line comments around it.
---@param row integer
---@return integer srow, integer erow
local function expand_comment_run(row)
  local spec = spec_for(vim.bo.filetype)
  local marker = spec and line_marker(spec)
  if not marker then return row, row end

  local pattern = "^%s*" .. vim.pesc(marker)
  local function is_comment(n)
    local line = vim.api.nvim_buf_get_lines(0, n - 1, n, false)[1]
    return line ~= nil and line:match(pattern) ~= nil
  end
  if not is_comment(row) then return row, row end

  local srow, erow = row, row
  while srow > 1 and is_comment(srow - 1) do
    srow = srow - 1
  end
  local last = vim.api.nvim_buf_line_count(0)
  while erow < last and is_comment(erow + 1) do
    erow = erow + 1
  end
  return srow, erow
end

--- `gbc`: block comment the current line, expanding to the whole run of line
--- comments when the cursor sits on one.
function M.current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  M.block(expand_comment_run(row))
end

--- `operatorfunc` target for `gb{motion}` and visual `gb`.
function M.opfunc()
  M.block(vim.fn.line "'[", vim.fn.line "']")
end

--- `gb{motion}` — set up the operator and wait for a motion.
---@return string
function M.operator()
  vim.o.operatorfunc = "v:lua.require'blockcomment'.opfunc"
  return "g@"
end

vim.api.nvim_create_user_command("BlockComment", function(args)
  if args.range > 0 then
    M.block(args.line1, args.line2)
  else
    M.current_line()
  end
end, { range = true, desc = "Convert range to a block comment" })

return M
