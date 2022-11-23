local M = {}
function M.before_rename(data)
	vim.pretty_print("Before rename", data)
end

function M.after_rename(data)
	vim.pretty_print("After rename", data)
end
return M
