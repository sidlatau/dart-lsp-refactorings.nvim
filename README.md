# dart-lsp-refactorings.nvim

[Dart language server](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/tool/lsp_spec/README.md) has setting to `renameFilesWithClasses` and to update imports `updateImportsOnRename` after files was renamed. But now imports are not updated. LSP server support `workspace/willRenameFiles` client request to get import changes. But Neovim LSP does not have support for this request. This plugin modifies `lsp.buf.rename` function to call `workspace/willRenameFiles` request before file rename and apply these changes after rename is done.

## Installation

Using `packer.nvim`

```lua
use {'sidlatau/dart-lsp-refactorings.nvim' }
```

## Usage

```lua
require("dart-lsp-refactorings").rename()

```

Call this function when you want rename class or anything else. If file will be renamed too, this function will update imports.

---

```lua
require("dart-lsp-refactorings").on_rename_file({
  source = "/source_file_path.dart",
  destination = "/destination_file_path.dart",
  callback = function()
    -- function to be called to finish file rename
  end
})
```

Hook function that get import changes and applies these changes before file rename.
Example of using with [neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim)

```lua
neo_tree.setup {
  ...
  event_handlers = {
    {
      event = "before_file_rename",
      handler = function(args)
        local ok, refact = pcall(require, "dart-lsp-refactorings")
        if ok then
          refact.on_rename_file(args)
          return { handled = true }
        end
      end,
    },
    {
      event = "before_file_move",
      handler = function(args)
        local ok, refact = pcall(require, "dart-lsp-refactorings")
        if ok then
          refact.on_rename_file(args)
          return { handled = true }
        end
      end,
    },
  },
}
```
