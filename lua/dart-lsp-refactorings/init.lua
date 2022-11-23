local rename_class = require("dart-lsp-refactorings.rename_class")
local M = {}

function M.rename(new_name, options)
	return rename_class.rename(new_name, options)
end

return M
