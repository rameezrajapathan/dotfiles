hl.monitor({
	output = "eDP-2",
	mode = "2560x1600@240.00Hz",
	position = "0x0",
	scale = 1.33,
	cm = "srgb",
})

hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = 1,
})

pcall(dofile, os.getenv("HOME") .. "/.local/state/pikadots/monitors.lua")
