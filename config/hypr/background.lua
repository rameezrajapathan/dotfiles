local M = {}
local dispatch = require("dispatch")

local function lua_pattern(regex)
	local out, class, escaped = {}, false, false
	for c in regex:gmatch(".") do
		if escaped then
			table.insert(out, "%" .. c)
			escaped = false
		elseif c == "\\" then
			escaped = true
		elseif c == "-" and not class then
			table.insert(out, "%-")
		elseif c == "%" then
			table.insert(out, "%%")
		else
			if c == "[" then
				class = true
			elseif c == "]" then
				class = false
			end
			table.insert(out, c)
		end
	end
	return table.concat(out)
end

M.regexes = {}
M.classes = {}
local list = io.open(os.getenv("HOME") .. "/.config/hypr/background-apps.txt")
if list then
	for line in list:lines() do
		if line:match("%S") then
			table.insert(M.regexes, line)
			table.insert(M.classes, lua_pattern(line))
		end
	end
	list:close()
end

M.workspace = "special:background"

function M.matches(class)
	for _, pattern in ipairs(M.classes) do
		if class and class:match(pattern) then
			return true
		end
	end
	return false
end

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

function M.start(cmds)
	local rules = {}
	for _, regex in ipairs(M.regexes) do
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
