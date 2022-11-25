local M = {}
local refactoring_utils = require("dart-lsp-refactorings.utils")

local pending_results = {}

local function get_dartls_client()
	return vim.lsp.get_active_clients({ filter = "dartls" })[1]
end

local function data_key(data)
	return data.source .. ":" .. data.destination
end

function M.on_rename(data)
	if
		not refactoring_utils.ends_with(data.source, ".dart")
		or not refactoring_utils.ends_with(data.destination, ".dart")
	then
		-- If not dart files are renamed  - just return
		data.callback()
		return
	end

	local dartls_client = get_dartls_client()
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
		pending_results[data_key(data)] = result
		data.callback()
	end)
end

function M.after_rename(data)
	local key = data_key(data)
	local rename_results = pending_results[key]
	if rename_results ~= nil then
		pending_results[key] = nil
		local dartls_client = get_dartls_client()
		if not dartls_client then
			return
		end
		vim.lsp.util.apply_workspace_edit(rename_results, dartls_client.offset_encoding)
	end
end
return M
