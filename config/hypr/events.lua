local home = {}

local function selector(w)
	return "address:0x" .. tostring(w.address):gsub("^0x", "")
end

hl.on("window.minimize", function(w, minimized)
	if not w then
		return
	end
	local ws = w.workspace and w.workspace.name or ""
	if minimized then
		if ws == "special:minimized" then
			return
		end
		home[w.address] = ws:match("^special:") and nil or ws
		hl.dispatch(hl.dsp.window.move({ workspace = "special:minimized", window = selector(w), silent = true }))
		return
	end
	if ws ~= "special:minimized" then
		return
	end
	local active = hl.get_active_workspace()
	local target = home[w.address] or (active and active.name)
	home[w.address] = nil
	if target then
		hl.dispatch(hl.dsp.window.move({ workspace = target, window = selector(w) }))
	end
	hl.dispatch(hl.dsp.focus({ window = selector(w) }))
end)

hl.on("window.close", function(w)
	if w then
		home[w.address] = nil
	end
end)
