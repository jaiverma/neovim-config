local ts_utils = require("nvim-treesitter.ts_utils")

local buf = nil
local win = nil

function render(data)
  -- clear the buffer if it exists
  if buf then
    vim.api.nvim_buf_set_lines(buf, 0, vim.api.nvim_buf_line_count(buf), false, {})
  end

  if #data == 0 then
    return
  end

  if not buf then
    buf = vim.api.nvim_create_buf(false, true)
  end

  local ui = vim.api.nvim_list_uis()[1]
  local opts = {
    relative = "editor",
    width = 30,
    height = math.floor(ui.height / 2),
    row = 0,
    col = ui.width,
    anchor = "NE",
    focusable = false,
    style = "minimal"
  }

  if not win then
    win = vim.api.nvim_open_win(buf, false, opts)
  end

  vim.api.nvim_buf_set_lines(buf, 0, #data, false, data)
end

function get_tsnode_ident(ifdef_node)
  local start_row, start_col, end_row, end_col = ifdef_node:range()
  local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), start_row, end_row + 1, false)

  if start_row ~= end_row then
    -- handle multiline ifdef statement
    if #lines == 0 then
      return {}
    end
    -- fix first line to start from start_col
    -- and last line to end at end_col
    lines[1] = string.sub(lines[1], start_col + 1)
    lines[#lines] = string.sub(lines[#lines], 1, end_col)
  else
    -- we can only have 1 line in this condition
    lines[1] = string.sub(lines[1], start_col + 1, end_col)
  end

  local ifdef_name = table.concat(lines, "\n")
  return ifdef_name
end

-- mode can either be 'if' or 'else'
-- for if/ifdef/ifndef when we encounter an ifdef node,
-- we are referring to the node itself, so 'defined' should
-- be 'true' for these (except ifndef)
--
-- the opposite is true for else/elif based nodes
function parse_ifdef(expr, mode)
  -- child 0 is the ifdef node
  local ifdef_type = expr:child(0):type()

  if expr:child_count() > 1 then
    -- child 1 is the identifier in the ifdef statement
    local ident = expr:child(1)
    local ident_name = get_tsnode_ident(ident)
    if ident:type() == "identifier" then
      -- if #ifdef, then 'defined'
      if ifdef_type == "#ifdef" then
        return {ident = ident_name, defined = (mode == "if")}
      -- if #ifndef, then 'not defined'
      elseif ifdef_type == "#ifndef" then
        return {ident = ident_name, defined = (mode == "else")}
      end
    end
  end
end

function parse_if(expr, mode)
  if expr:child_count() > 1 then
    local node = expr:child(1)
    if node:type() == "identifier" then
      local ident_name = get_tsnode_ident(node)
      return {ident = ident_name, defined = (mode == "if")}
    elseif node:type() == "preproc_defined" then
      -- preproc_defined should have a single child which will be the identifier
      if node:child_count() > 1 then
        local ident_node = node:child(1)
        -- ':type()' is returning '(' when using 'defined(A)'
        -- instead of 'defined A'
        if ident_node:type() == "identifier" then
          local ident_name = get_tsnode_ident(ident_node)
          return {ident = ident_name, defined = (mode == "if")}
        elseif ident_node:type() == "(" then
          local ident_name = get_tsnode_ident(node:child(2))
          return {ident = ident_name, defined = (mode == "if")}
        else
          print("[-] error in preproc_if -> preproc_defined -> identifier", ident_node:type(), string.len(ident_node:type()))
        end
      else
        print("[-] error in preproc_if -> preproc_defined")
      end
    end
  end
end

-- works from current cursor position, and not on whole file contents
function get_ifdef()
  local cur_node = ts_utils.get_node_at_cursor()
  if not cur_node then
    return {}
  end

  local expr = cur_node
  local idents = {}
  local ret = nil

  while expr do
    -- check for preproc_else/preproc_elif first, since that will be a child
    -- of preproc_ifdef/preproc_if
    if expr:type() == "preproc_else" then
      break
    elseif expr:type() == "preproc_elif" then
      ret = parse_if(expr, "if")
      break
    elseif expr:type() == "preproc_ifdef" then
      ret = parse_ifdef(expr, "if")
      break
    elseif expr:type() == "preproc_if" then
      ret = parse_if(expr, "if")
      break
    end
    expr = expr:parent()
  end

  if ret then
    local ident_name = ret["ident"]
    idents[ident_name] = ret["defined"]
  end

  if not expr then
    return {}
  end

  -- handle else/elif
  -- if we have an preproc_else, we want to get the preproc_ifdef statement
  -- and have a flag that identified whether or not that macro is defined or not
  -- we also need all the parent if/elif statements
  local exprs = {}

  if expr:type() == "preproc_else" or expr:type() == "preproc_elif" then
    expr = expr:parent()
    while expr do
      if expr:type() == "preproc_ifdef" or expr:type() == "preproc_if" then
        exprs[#exprs + 1] = expr
        -- ifdef/ifndef/if should be a top node, we should break here
        break
      elseif expr:type() == "preproc_elif" then
        exprs[#exprs + 1] = expr
      else
        print(string.format("[-] error in preproc_else/elif -> parents, found unknown node: %s", expr:type()))
      end
      expr = expr:parent()
    end
  end

  for idx, expr in ipairs(exprs) do
    local ret = nil
    if expr:type() == "preproc_ifdef" then
      ret = parse_ifdef(expr, "else")
    elseif expr:type() == "preproc_if" or expr:type() == "preproc_elif" then
      ret = parse_if(expr, "else")
    else
      print("skipping:", expr:type())
    end

    if ret then
      local ident_name = ret["ident"]
      idents[ident_name] = ret["defined"]
    end
  end

  local ifdefs = {}
  for ident, defined in pairs(idents) do
    local label = ""
    if defined then
      label = "yes"
    else
      label = "no"
    end

    local ifdef = string.format("%s: %s", ident, label)
    ifdefs[#ifdefs + 1] = ifdef
  end

  return ifdefs
end

vim.api.nvim_create_user_command("Ifdef", function(cmd)
  local ifdefs = get_ifdef()
  render(ifdefs)
end, { desc = "View ifdef name" })

vim.api.nvim_create_autocmd({"CursorMoved"}, {
  pattern = {"*.c", "*.h", "*.cpp", "*.hpp", "*.cc"},
  callback = function(x)
    local ifdefs = get_ifdef()
    render(ifdefs)
  end})
