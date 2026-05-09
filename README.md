# latextemplates.nvim

Neovim plugin to create LaTeX documents from saved templates.

## Installation (lazy.nvim)

```lua
{
  "haroun/latextemplates.nvim",
  opts = {
    templates = {
      -- your templates here
    },
  },
}
```

## Template Shape

Each template must contain:

- `documentclass`: string
- `packages`: list of package entries
- `commands`: list of strings

Optional:

- `description`: string shown in picker

Package entries can be either:

- String: `"amsmath"`
- Table:
  - `name`: string (required)
  - `options`: string or list of strings (optional)

## Setup

```lua
require("latextemplates").setup({
  templates = {
    article = {
      description = "General paper/article template",
      documentclass = "article",
      packages = {
        "amsmath",
        {
          name = "geometry",
          options = { "margin=1in", "includehead" },
        },
        {
          name = "hyperref",
          options = "colorlinks=true,linkcolor=blue",
        },
      },
      commands = {
        "\\newcommand{\\R}{\\mathbb{R}}",
      },
    },
    report = {
      documentclass = "report",
      packages = {
        "booktabs",
      },
      commands = {},
    },
  },
})
```

## Command

Run:

```
:LatexTemplatesPick
```

This opens a Snacks picker, lets you choose a template, then prompts for a `.tex` file path.
The plugin writes the generated file to disk (creating parent directories if needed) and opens it.
