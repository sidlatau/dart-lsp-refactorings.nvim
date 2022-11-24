local M = {}
local rename_results

local function get_dartls_client()
	return vim.lsp.get_active_clients({ filter = "dartls" })[1]
end

local function will_rename_files(old_name, new_name, callback)
	local params = {}
	local dartls_client = get_dartls_client()
	if not dartls_client then
		return
	end
	local file_change = {
		newUri = vim.uri_from_fname(new_name),
		oldUri = vim.uri_from_fname(old_name),
	}
	params.files = { file_change }
	dartls_client.request("workspace/willRenameFiles", params, function(err, result)
		if err then
			vim.notify(err.message or "Error on getting lsp rename results!")
			return
		end
		callback(result)
	end)
end

function M.before_rename(data)
	rename_results = nil
	will_rename_files(data.source, data.destination, function(result)
		vim.pretty_print("results!", result)
		rename_results = result
		data.callback()
	end)
end

function M.after_rename(data)
	vim.pretty_print("After rename", data, rename_results)
	if rename_results ~= nil then
		local dartls_client = get_dartls_client()
		if not dartls_client then
			return
		end
		vim.lsp.util.apply_workspace_edit(rename_results, dartls_client.offset_encoding)
	end
end
return M
