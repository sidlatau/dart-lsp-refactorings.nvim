# dart-lsp-refactorings.nvim

[Dart language server](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/tool/lsp_spec/README.md) has setting to `renameFilesWithClasses` and to update imports `updateImportsOnRename` after files was renamed. But now imports are not updated. LSP server support `workspace/willRenameFiles` client request to get import changes. But Neovim LSP does not have support for this request. This plugin modifies `lsp.buf.rename` function to call `workspace/willRenameFiles` request before file rename and apply these changes after rename is done.

## Installation

Using `packer.nvim`

```lua
use {'sidlatau/dart-lsp-refactorings.nvim' }
```

## Usage

Call this function when you want rename class or anything else. If file will be renamed to, this function will update imports.

```lua
    require("dart-lsp-refactorings").rename()

```
