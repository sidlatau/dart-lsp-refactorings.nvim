local rename_class = require("dart-lsp-refactorings.rename-class")
local rename_file = require("dart-lsp-refactorings.rename-file")
local M = {}

--- Call this function when you want rename class or anything else.
--- If file will be renamed to, this function will update imports.
--- Function has same signature as `vim.lsp.buf.rename()` function.
function M.rename(new_name, options)
	rename_class.rename(new_name, options)
end

--- Hook function for getting LSP result of import changes and
--- applying these changes  after file rename.
--- @param data table {
---   source - 'source file path',
---   destination - 'destination file path'
---   callback - this callback needs to be called to be able to finish file rename
--}
function M.on_rename_file(data)
	rename_file.on_rename(data)
end

return M
