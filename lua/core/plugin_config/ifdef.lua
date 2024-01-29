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

-- works from current cursor position, and not on whole file contents
function get_ifdef()
  local cur_node = ts_utils.get_node_at_cursor()
  if not cur_node then
    return {}
  end

  local is_defined = false
  local expr = cur_node

  -- handles ifdef
  while expr do
    -- check for preproc_else first, since that will be a child
    -- of the preproc_ifdef
    if expr:type() == "preproc_else" then
      break
    elseif expr:type() == "preproc_ifdef" then
      -- child 0 is the ifdef node
      local ifdef_type = expr:child(0):type()
      -- if #ifdef, then 'defined'
      -- if #ifndef, then 'not defined'
      if ifdef_type == "#ifdef" then
        is_defined = true
      elseif ifdef_type == "#ifndef" then
        is_defined = false
      end

      break
    end
    expr = expr:parent()
  end

  if not expr then
    return {}
  end

  -- handle else
  -- if we have an preproc_else, we want to get the preproc_ifdef statement
  -- and have a flag that identified whether or not that macro is defined or not
  if expr:type() == "preproc_else" then
    is_defined = false
    while expr do
      if expr:type() == "preproc_ifdef" then
        break
      end
      expr = expr:parent()
    end
  end

  -- we need to check for this again, since the #else could either correspond to:
  --   - #ifdef
  --   - #if, #elif
  -- The above loop only handles the former
  if not expr then
    return {}
  end

  -- print(expr:type())
  -- if we have a preproc_ifdef TSNode, then it will have a named identifer as a child
  -- which will contain the name of the ifdef
  local ifdef_node = nil
  if expr:child_count() > 1 then
    -- child 1 is the identifier in the ifdef statement
    local ident = expr:child(1)
    if ident:type() == "identifier" then
      ifdef_node = ident
      -- print(ident:type())
    end
  end

  if not ifdef_node then
    return {}
  end

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

  local label = ""
  if is_defined then
    label = "yes"
  else
    label = "no"
  end

  local ifdef = string.format("%s: %s", ifdef_name, label)
  return {ifdef}
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
