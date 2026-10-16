-- Dispatch helpers for keybinds: they run a dispatcher and deal with a failure themselves
-- (a notification, or nothing) instead of letting Hyprland show its error.

local M = {}

-- A notification through the shell; -e keeps it out of the history
function M.notify(title, body, icon)
	hl.exec_cmd(string.format("notify-send -e -a Hyprland -i %q -t 2500 %q %q", icon or "dialog-information", title, body or ""))
end

-- A bind function that runs `dsp`; when it fails, `fail` gets the result ({ ok, code, error }),
-- or the failure is ignored when there's no `fail`
function M.try(dsp, fail)
	return function()
		local r = hl.dispatch(dsp)
		if r and r.ok == false and fail then
			fail(r)
		end
	end
end

local beside = { left = "to the left", right = "to the right", up = "above", down = "below" }

-- A monitor's box in layout coordinates (its mode divided by its scale, turned with it)
local function box(m)
	local w, h = m.width / m.scale, m.height / m.scale
	if m.transform % 2 == 1 then
		w, h = h, w
	end
	return { x = m.x, y = m.y, w = w, h = h }
end

-- The monitor on that side of the focused one (overlapping it along that side), if any
local function monitor_towards(dir)
	local current = hl.get_active_monitor()
	if not current then
		return nil
	end
	local a = box(current)
	for _, m in ipairs(hl.get_monitors()) do
		if m.name ~= current.name then
			local b = box(m)
			local across = b.y < a.y + a.h and b.y + b.h > a.y
			local along = b.x < a.x + a.w and b.x + b.w > a.x
			if dir == "left" and across and b.x + b.w <= a.x + 1
				or dir == "right" and across and b.x >= a.x + a.w - 1
				or dir == "up" and along and b.y + b.h <= a.y + 1
				or dir == "down" and along and b.y >= a.y + a.h - 1 then
				return m
			end
		end
	end
	return nil
end

local function no_monitor(dir)
	if #hl.get_monitors() < 2 then
		M.notify("Only one display", "Connect another display to use this shortcut.", "video-display")
	else
		M.notify("No display " .. beside[dir], "There's no display on that side of this one.", "video-display")
	end
end

-- With cursor:no_warps (settings.lua, for the cursor glide) Hyprland doesn't take the pointer
-- along, and the monitor under the pointer keeps the focus; so put it in the middle of that
-- monitor first (CursorGlide then glides it on to the window that gets the focus there)
function M.focus_monitor(dir)
	return function()
		local m = monitor_towards(dir)
		if not m then
			no_monitor(dir)
			return
		end
		local b = box(m)
		hl.dispatch(hl.dsp.cursor.move({ x = math.floor(b.x + b.w / 2), y = math.floor(b.y + b.h / 2) }))
		hl.dispatch(hl.dsp.focus({ monitor = m.name }))
	end
end

function M.move_to_monitor(dir)
	return function()
		if not hl.get_active_window() then
			return
		end
		local m = monitor_towards(dir)
		if m then
			hl.dispatch(hl.dsp.window.move({ monitor = m.name }))
		else
			no_monitor(dir)
		end
	end
end

local function special_name()
	local ws = hl.get_active_special_workspace()
	return ws and ws.name and (ws.name:gsub("^special:", "")) or nil
end

-- Moves the active window to `workspace` without following it. Hyprland shows a special
-- workspace even for a silent move, so hide it again (and bring back the one that was shown).
function M.move_silently(workspace)
	local before = special_name()
	hl.dispatch(hl.dsp.window.move({ workspace = workspace, silent = true }))
	local now = special_name()
	if now and now ~= before then
		hl.dispatch(hl.dsp.workspace.toggle_special(now))
		if before then
			hl.dispatch(hl.dsp.workspace.toggle_special(before))
		end
	end
end

return M
