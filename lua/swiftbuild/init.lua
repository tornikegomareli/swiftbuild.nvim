local swift = {}

-- Create a dedicated output buffer
swift.create_output_buffer = function()
	-- Create a new buffer
	local buf = vim.api.nvim_create_buf(false, true)

	-- Set buffer name
	vim.api.nvim_buf_set_name(buf, "Swift Output")

	-- Create a new window split
	vim.cmd("vsplit")
	local win = vim.api.nvim_get_current_win()

	-- Set buffer in the window
	vim.api.nvim_win_set_buf(win, buf)

	-- Set window options
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false

	return buf, win
end

-- Append text to output buffer
swift.append_to_output = function(buf, text)
	local lines = vim.split(text, "\n")
	vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
end

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

	-- Create output buffer and window
	local buf, win = swift.create_output_buffer()

	-- Add header to output
	swift.append_to_output(buf, "Executing: " .. cmd)
	swift.append_to_output(buf, string.rep("-", 40))

	-- Create job
	local job_id = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if data then
				vim.schedule(function()
					swift.append_to_output(buf, table.concat(data, "\n"))
				end)
			end
		end,
		on_stderr = function(_, data)
			if data then
				vim.schedule(function()
					swift.append_to_output(buf, table.concat(data, "\n"))
				end)
			end
		end,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				swift.append_to_output(buf, string.rep("-", 40))
				if exit_code == 0 then
					swift.append_to_output(buf, "Command completed successfully")
				else
					swift.append_to_output(buf, "Command failed with exit code: " .. exit_code)
				end
			end)
		end,
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
