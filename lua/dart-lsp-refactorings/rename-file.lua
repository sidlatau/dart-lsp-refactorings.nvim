local M = {}
local refactoring_utils = require("dart-lsp-refactorings.utils")

function M.on_rename(args)
	if
		not refactoring_utils.ends_with(args.source, ".dart")
		or not refactoring_utils.ends_with(args.destination, ".dart")
	then
		-- If not dart files are renamed  - just return
		args.callback()
		return
	end

	local dartls_client = vim.lsp.get_active_clients({ filter = "dartls" })[1]
	if not dartls_client then
		args.callback()
		return
	end
	local params = {
		files = { {
			oldUri = vim.uri_from_fname(args.source),
			newUri = vim.uri_from_fname(args.destination),
		} },
	}
	dartls_client.request("workspace/willRenameFiles", params, function(err, result)
		if err then
			vim.notify(err.message or "Error on getting lsp rename results!")
		else
			if result then
				vim.lsp.util.apply_workspace_edit(result, dartls_client.offset_encoding)
			end
		end
		args.callback()
	end)
end

return M
