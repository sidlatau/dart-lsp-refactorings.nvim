local M = {}
local refactoring_utils = require("dart-lsp-refactorings.utils")

function M.on_rename(data)
	if
		not refactoring_utils.ends_with(data.source, ".dart")
		or not refactoring_utils.ends_with(data.destination, ".dart")
	then
		-- If not dart files are renamed  - just return
		data.callback()
		return
	end

	local dartls_client = vim.lsp.get_active_clients({ filter = "dartls" })[1]
	if not dartls_client then
		data.callback()
		return
	end
	local params = {
		files = { {
			oldUri = vim.uri_from_fname(data.source),
			newUri = vim.uri_from_fname(data.destination),
		} },
	}
	dartls_client.request("workspace/willRenameFiles", params, function(err, result)
		if err then
			vim.notify(err.message or "Error on getting lsp rename results!")
			data.callback()
			return
		end
		vim.lsp.util.apply_workspace_edit(result, dartls_client.offset_encoding)
		data.callback()
	end)
end

return M
