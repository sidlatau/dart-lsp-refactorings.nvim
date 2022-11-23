local rename_class = require("dart-lsp-refactorings.rename-class")
local rename_file = require("dart-lsp-refactorings.rename-file")
local M = {}

function M.rename(new_name, options)
	rename_class.rename(new_name, options)
end

function M.before_rename_file(data)
	rename_file.before_rename(data)
end

function M.after_rename_file(data)
	rename_file.after_rename(data)
end

return M
