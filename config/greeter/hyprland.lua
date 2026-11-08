hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

local theme = os.getenv("PIKADOTS_GREETER_DIR") or "/var/lib/pikadots-greeter"
local layout = "us"
do
	local f = io.open(theme .. "/kb_layout")
	if f then
		layout = (f:read("l") or "us"):gsub("%s+", "")
		f:close()
	end
end

hl.config({
	input = { kb_layout = layout, numlock_by_default = true },
	general = { border_size = 0, gaps_in = 0, gaps_out = 0 },
	decoration = { shadow = { enabled = false }, blur = { enabled = false } },
	animations = { enabled = false },
	misc = { disable_hyprland_logo = true, disable_splash_rendering = true, background_color = "rgb(000000)" },
})

hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "28")

hl.on("hyprland.start", function()
	hl.exec_cmd([[sh -c 'qs -p /usr/share/pikadots-greeter; t=$(cat /sys/class/tty/tty0/active 2>/dev/null); [ -n "$t" ] && printf "\033[?25l\033[2J\033[3J\033[H" 2>/dev/null >"/dev/$t"; hyprctl dispatch "hl.dsp.exit()"']])
end)
