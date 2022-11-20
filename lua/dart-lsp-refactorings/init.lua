local api = vim.api
local util = vim.lsp.util
local refactoring_utils = require("dart-lsp-refactorings.utils")
local M = {}

local function will_rename_files(old_name, new_name, callback)
	---@diagnostic disable-next-line: missing-parameter
	local params = vim.lsp.util.make_position_params()
	if not new_name then
		return
	end
	local file_change = {
		newUri = vim.uri_from_fname(new_name),
		oldUri = vim.uri_from_fname(old_name),
	}
	params.files = { file_change }
	vim.lsp.buf_request(0, "workspace/willRenameFiles", params, function(err, result)
		if err then
			vim.notify(err.message or "Error on getting lsp rename results!")
			return
		end
		callback(result)
	end)
end

function M.rename(new_name, options)
	options = options or {}
	local bufnr = options.bufnr or api.nvim_get_current_buf()
	local clients = vim.lsp.get_active_clients({
		bufnr = bufnr,
		name = "dartls",
	})
	local client = clients[1]
	if not client then
		vim.lsp.rename(new_name, options)
		return
	end

	local win = api.nvim_get_current_win()

	-- Compute early to account for cursor movements after going async
	local cword = vim.fn.expand("<cword>")
	local actual_file_name = vim.fn.expand("%:t")
	local old_computed_filename = refactoring_utils.file_name_for_class_name(cword)
	local is_file_rename = old_computed_filename == actual_file_name

	---@private
	local function get_text_at_range(range, offset_encoding)
		return api.nvim_buf_get_text(
			bufnr,
			range.start.line,
			util._get_line_byte_from_position(bufnr, range.start, offset_encoding),
			range["end"].line,
			util._get_line_byte_from_position(bufnr, range["end"], offset_encoding),
			{}
		)[1]
	end

	---@private
	local function rename(name, will_rename_files_result)
		local params = util.make_position_params(win, client.offset_encoding)
		params.newName = name
		local handler = client.handlers["textDocument/rename"] or vim.lsp.handlers["textDocument/rename"]
		client.request("textDocument/rename", params, function(...)
			handler(...)
			if will_rename_files_result then
				-- the `will_rename_files_result` contains all the places we need to update imports
				-- so we apply those edits.
				vim.lsp.util.apply_workspace_edit(will_rename_files_result, client.offset_encoding)
			end
		end, bufnr)
	end

	local function rename_fix_imports(name)
		if is_file_rename then
			local old_file_path = vim.fn.expand("%:p")
			local new_filename = refactoring_utils.file_name_for_class_name(name)
			local actual_file_head = vim.fn.expand("%:p:h")
			local new_file_path = refactoring_utils.path_join(actual_file_head, new_filename)
			will_rename_files(old_file_path, new_file_path, function(result)
				rename(name, result)
			end)
		else
			rename(name)
		end
	end

	if client.supports_method("textDocument/prepareRename") then
		local params = util.make_position_params(win, client.offset_encoding)
		client.request("textDocument/prepareRename", params, function(err, result)
			if err or result == nil then
				local msg = err and ("Error on prepareRename: " .. (err.message or "")) or "Nothing to rename"
				vim.notify(msg, vim.log.levels.INFO)
				return
			end

			if new_name then
				rename_fix_imports(new_name)
				return
			end

			local prompt_opts = {
				prompt = "New Name: ",
			}
			-- result: Range | { range: Range, placeholder: string }
			if result.placeholder then
				prompt_opts.default = result.placeholder
			elseif result.start then
				prompt_opts.default = get_text_at_range(result, client.offset_encoding)
			elseif result.range then
				prompt_opts.default = get_text_at_range(result.range, client.offset_encoding)
			else
				prompt_opts.default = cword
			end
			vim.ui.input(prompt_opts, function(input)
				if not input or #input == 0 then
					return
				end
				rename_fix_imports(input)
			end)
		end, bufnr)
	else
		assert(client.supports_method("textDocument/rename"), "Client must support textDocument/rename")
		if new_name then
			rename_fix_imports(new_name)
			return
		end

		local prompt_opts = {
			prompt = "New Name: ",
			default = cword,
		}
		vim.ui.input(prompt_opts, function(input)
			if not input or #input == 0 then
				return
			end
			rename_fix_imports(input)
		end)
	end
end

return M
