local swift = {}

-- Store buffer reference
swift.output_buf = nil
swift.output_win = nil

-- Create or reuse output buffer
swift.create_output_buffer = function()
	-- If buffer exists but window was closed, create new window
	if swift.output_buf and vim.api.nvim_buf_is_valid(swift.output_buf) then
		-- Clear existing buffer content
		vim.api.nvim_buf_set_lines(swift.output_buf, 0, -1, false, {})

		-- Create new window
		vim.cmd("vsplit")
		local win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(win, swift.output_buf)

		-- Set window options
		vim.api.nvim_win_set_option(win, "number", false)
		vim.api.nvim_win_set_option(win, "relativenumber", false)

		swift.output_win = win
		return swift.output_buf, win
	end

	-- Create new buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, "Swift-Output-" .. os.time())

	-- Create new window split
	vim.cmd("vsplit")
	local win = vim.api.nvim_get_current_win()

	-- Set buffer in the window
	vim.api.nvim_win_set_buf(win, buf)

	-- Set window options
	vim.api.nvim_win_set_option(win, "number", false)
	vim.api.nvim_win_set_option(win, "relativenumber", false)

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe") -- Buffer will be wiped when hidden

	-- Store references
	swift.output_buf = buf
	swift.output_win = win

	-- Setup buffer local keymaps
	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })

	return buf, win
end

-- Append text to output buffer
swift.append_to_output = function(buf, text)
	if buf and vim.api.nvim_buf_is_valid(buf) then
		local lines = vim.split(text, "\n")
		vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
		-- Auto-scroll to bottom
		if swift.output_win and vim.api.nvim_win_is_valid(swift.output_win) then
			vim.api.nvim_win_set_cursor(swift.output_win, { vim.api.nvim_buf_line_count(buf), 0 })
		end
	end
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
