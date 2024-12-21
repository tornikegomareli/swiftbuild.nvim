local swift = {}

-- Function to get project root directory
swift.get_root = function()
	local current_file = vim.fn.expand("%:p")
	local current_dir = vim.fn.fnamemodify(current_file, ":h")
	local root = vim.fn.findfile("Package.swift", current_dir .. ";")
	if root ~= "" then
		return vim.fn.fnamemodify(root, ":h")
	end
	return current_dir
end

-- Function to execute shell command in project root
swift.execute_command = function(cmd)
	local root = swift.get_root()
	vim.cmd("cd " .. root)

	-- Create a new terminal buffer
	vim.cmd("vsplit | terminal")

	-- Instead of using TermOpen autocmd, set window options directly
	local win = vim.api.nvim_get_current_win()
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false

	local buf = vim.api.nvim_get_current_buf()

	-- Send the command to terminal
	vim.api.nvim_chan_send(vim.b.terminal_job_id, cmd .. "\n")

	-- Add autocommand to close terminal on success
	vim.api.nvim_create_autocmd("TermClose", {
		buffer = buf,
		callback = function()
			vim.cmd("bdelete!")
		end,
		once = true,
	})
end

-- Register all commands
local function setup_commands()
	-- Create Neovim commands
	vim.api.nvim_create_user_command("SwiftBuild", function()
		swift.execute_command("swift build")
	end, {
		desc = "Build Swift project",
	})

	vim.api.nvim_create_user_command("SwiftRun", function()
		swift.execute_command("swift run")
	end, {
		desc = "Run Swift project",
	})

	vim.api.nvim_create_user_command("SwiftTest", function()
		swift.execute_command("swift test")
	end, {
		desc = "Run Swift tests",
	})

	vim.api.nvim_create_user_command("SwiftClean", function()
		swift.execute_command("swift package clean")
	end, {
		desc = "Clean Swift project",
	})

	-- Add command abbreviations
	vim.cmd("cnoreabbrev sb SwiftBuild")
	vim.cmd("cnoreabbrev sr SwiftRun")
	vim.cmd("cnoreabbrev st SwiftTest")
	vim.cmd("cnoreabbrev sc SwiftClean")
end

swift.setup = function()
	setup_commands()
end

return swift
