local M = {}

M.config = {
  templates = {},
}

local function is_string_list(value)
  if type(value) ~= "table" then
    return false
  end

  for _, item in ipairs(value) do
    if type(item) ~= "string" then
      return false
    end
  end

  return true
end

local function validate_package_entry(name, index, package)
  if type(package) == "string" then
    return true
  end

  if type(package) ~= "table" then
    return false,
      string.format("Template '%s'.packages[%d] must be a string or table", name, index)
  end

  if type(package.name) ~= "string" then
    return false,
      string.format("Template '%s'.packages[%d].name must be a string", name, index)
  end

  if package.options ~= nil then
    local options_type = type(package.options)
    if options_type ~= "string" and not is_string_list(package.options) then
      return false,
        string.format(
          "Template '%s'.packages[%d].options must be a string or list of strings",
          name,
          index
        )
    end
  end

  return true
end

local function validate_template(name, template)
  if type(template) ~= "table" then
    return false, string.format("Template '%s' must be a table", name)
  end

  if type(template.documentclass) ~= "string" then
    return false, string.format("Template '%s'.documentclass must be a string", name)
  end

  if type(template.description) ~= "nil" and type(template.description) ~= "string" then
    return false, string.format("Template '%s'.description must be a string", name)
  end

  if type(template.packages) ~= "table" then
    return false,
      string.format("Template '%s'.packages must be a list of strings or package tables", name)
  end

  if type(template.commands) ~= "table" then
    return false, string.format("Template '%s'.commands must be a list of strings", name)
  end

  for i, package in ipairs(template.packages) do
    local ok, err = validate_package_entry(name, i, package)
    if not ok then
      return false, err
    end
  end

  for i, command in ipairs(template.commands) do
    if type(command) ~= "string" then
      return false, string.format("Template '%s'.commands[%d] must be a string", name, i)
    end
  end

  return true
end

local function render_package(package)
  if type(package) == "string" then
    return "\\usepackage{" .. package .. "}"
  end

  local options = package.options
  local options_text = ""

  if type(options) == "string" and options ~= "" then
    options_text = "[" .. options .. "]"
  elseif type(options) == "table" and #options > 0 then
    options_text = "[" .. table.concat(options, ",") .. "]"
  end

  return "\\usepackage" .. options_text .. "{" .. package.name .. "}"
end

local function build_template_lines(template)
  local lines = {
    "\\documentclass{" .. template.documentclass .. "}",
    "",
  }

  for _, package in ipairs(template.packages) do
    table.insert(lines, render_package(package))
  end

  if #template.packages > 0 then
    table.insert(lines, "")
  end

  for _, command in ipairs(template.commands) do
    table.insert(lines, command)
  end

  if #template.commands > 0 then
    table.insert(lines, "")
  end

  table.insert(lines, "\\begin{document}")
  table.insert(lines, "")
  table.insert(lines, "\\end{document}")

  return lines
end

local function default_filename_for(template_name)
  -- return template_name:gsub("%s+", "_"):lower() .. ".tex"
  return "main.tex"
end

local function write_template_to_file(template_name, template)
  local default_name = default_filename_for(template_name)
  local path = vim.fn.input("New TeX file path: ", default_name, "file")

  if path == nil or path == "" then
    vim.notify("Template creation cancelled", vim.log.levels.INFO)
    return
  end

  local absolute_path = vim.fn.fnamemodify(path, ":p")
  local parent = vim.fn.fnamemodify(absolute_path, ":h")

  if parent ~= "" then
    vim.fn.mkdir(parent, "p")
  end

  if vim.fn.filereadable(absolute_path) == 1 then
    local replace = vim.fn.confirm("File exists. Overwrite?", "&Yes\n&No", 2)
    if replace ~= 1 then
      vim.notify("Template creation cancelled", vim.log.levels.INFO)
      return
    end
  end

  local lines = build_template_lines(template)
  vim.fn.writefile(lines, absolute_path)
  vim.cmd.edit(vim.fn.fnameescape(absolute_path))
  vim.bo.filetype = "tex"
  vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(0) - 1, 0 })
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  for name, template in pairs(M.config.templates) do
    local ok, err = validate_template(name, template)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end

function M.pick_template()
  local templates = M.config.templates or {}
  local items = {}

  for name, template in pairs(templates) do
    local ok = validate_template(name, template)
    if ok then
      table.insert(items, {
        text = name,
        description = template.description,
        value = name,
      })
    end
  end

  table.sort(items, function(a, b)
    return a.text < b.text
  end)

  if #items == 0 then
    vim.notify("No valid templates configured", vim.log.levels.WARN)
    return
  end

  local function format_item(item)
    if item.description and item.description ~= "" then
      return string.format("%s - %s", item.text, item.description)
    end
    return item.text
  end

  local function on_choice(choice)
    if not choice then
      return
    end

    local template_name = choice.value or choice.text
    local template = templates[template_name]
    if not template then
      return
    end

    write_template_to_file(template_name, template)
  end

  local snacks_ok, snacks = pcall(require, "snacks")
  if snacks_ok and snacks.picker and type(snacks.picker.select) == "function" then
    snacks.picker.select(items, {
      prompt = "Select LaTeX template",
      format_item = format_item,
    }, on_choice)
    return
  end

  vim.ui.select(items, {
    prompt = "Select LaTeX template",
    format_item = format_item,
  }, on_choice)
end

return M
