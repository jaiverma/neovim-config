local ts_utils = require("nvim-treesitter.ts_utils")

function get_ifdef()
  local cur_node = ts_utils.get_node_at_cursor()
  if not cur_node then
    return ""
  end

  local is_defined = false
  local expr = cur_node

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
    return ""
  end

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
    return ""
  end

  local start_row, start_col, end_row, end_col = ifdef_node:range()
  local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), start_row, end_row + 1, false)

  if start_row ~= end_row then
    -- handle multiline ifdef statement
    if #lines == 0 then
      return ""
    end
    -- fix first line to start from start_col
    -- and last line to end at end_col
    lines[1] = string.sub(lines[1], start_col)
    lines[#lines] = string.sub(lines[#lines], 1, end_col)
  else
    -- we can only have 1 line in this condition
    lines[1] = string.sub(lines[1], start_col, end_col)
  end

  local ifdef_name = table.concat(lines, "\n")

  local label = ""
  if is_defined then
    label = "yes"
  else
    label = "no"
  end

  print(string.format("%s: %s", ifdef_name, label))
  return x
end

vim.api.nvim_create_user_command("Ifdef", function(cmd)
  get_ifdef()
end, { desc = "View ifdef name" })
