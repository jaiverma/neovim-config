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
      is_defined = true
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
    end
    expr = expr:parent()
  end

  print(expr)
  local start_row, _, _ = expr:start()
  local ifdef_line = vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), start_row, start_row + 1, true)
  x = table.concat(ifdef_line, "\n")

  local label = ""
  if is_defined then
    label = "yes"
  else
    label = "no"
  end

  print(string.format("%s: %s", x, label))
  return x
end

vim.api.nvim_create_user_command("Ifdef", function(cmd)
  get_ifdef()
end, { desc = "View ifdef name" })
