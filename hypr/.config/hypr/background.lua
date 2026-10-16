-- Background apps: Super + Q hides them in special:background instead of closing, so they keep
-- running and sending notifications. Their icons sit in the bar's tray pill (Tray.qml has the
-- same list); clicking one brings the window back.

local M = {}
local dispatch = require("dispatch")

-- Lua patterns matched against the window class
M.classes = {
	"^org%.mozilla%.Thunderbird$",
	"^thunderbird$",
	"^chrome%-%l+%-.+$", -- Chrome apps (PWAs), e.g. chrome-<app id>-Default
}

M.workspace = "special:background"

function M.matches(class)
	for _, pattern in ipairs(M.classes) do
		if class and class:match(pattern) then
			return true
		end
	end
	return false
end

-- Hyprland leaves the keyboard focus on a window moved away silently; give it to the window used
-- last on the workspace it left
local function focus_after(hidden, workspace)
	local next
	for _, w in ipairs(hl.get_windows()) do
		if w.address ~= hidden and w.mapped and w.workspace and w.workspace.id == workspace
			and (not next or w.focus_history_id < next.focus_history_id) then
			next = w
		end
	end
	if next then
		hl.dispatch(hl.dsp.focus({ window = "address:" .. next.address }))
	end
end

function M.hide_or_close()
	local w = hl.get_active_window()
	if w and M.matches(w.class) then
		local address, workspace = w.address, w.workspace and w.workspace.id
		dispatch.move_silently(M.workspace)
		focus_after(address, workspace)
	else
		hl.dispatch(hl.dsp.window.close())
	end
end

-- Start these hidden at login. A temporary rule rather than exec rules: Chrome hands the second
-- app to the already running browser, so the window doesn't belong to the launched process.
function M.start(cmds)
	local rules = {}
	for _, pattern in ipairs(M.classes) do
		-- Window rules take regexes; the Lua patterns above only use %. and %- escapes
		local regex = pattern:gsub("%%l%+", "[a-p]+"):gsub("%%(.)", "\\%1")
		table.insert(rules, hl.window_rule({ match = { class = regex }, workspace = M.workspace .. " silent" }))
	end
	for _, cmd in ipairs(cmds) do
		hl.exec_cmd(cmd)
	end
	hl.timer(function()
		for _, rule in ipairs(rules) do
			rule:set_enabled(false)
		end
	end, { timeout = 30000, type = "oneshot" })
end

return M
