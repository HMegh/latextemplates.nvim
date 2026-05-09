if vim.g.loaded_latextemplates then
  return
end

vim.g.loaded_latextemplates = 1

vim.api.nvim_create_user_command("LatexTemplatesPick", function()
  require("latextemplates").pick_template()
end, {
  desc = "Pick and create a LaTeX template",
})
