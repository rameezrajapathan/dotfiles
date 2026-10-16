#!/usr/bin/env bash
state="$XDG_RUNTIME_DIR/recording-path"

if pkill -INT -x wf-recorder; then
    notify-send "Recording saved" "$(cat "$state")"
    exit 0
fi

case ${1:-region} in
    region) geom=$(slurp) || exit 0; set -- -g "$geom" ;;
    full)   set -- -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" ;;
esac

dir="$(xdg-user-dir VIDEOS)/Recordings"
mkdir -p "$dir"
file="$dir/$(date +%Y%m%d-%H%M%S).mp4"
echo "$file" > "$state"

log="$XDG_RUNTIME_DIR/recording.log"
wf-recorder "$@" --audio="$(pactl get-default-sink).monitor" \
    -c libx264 -p preset=veryfast -p crf=23 -f "$file" </dev/null >"$log" 2>&1
status=$?
if ((status != 0 && status != 130)); then
    rm -f "$file"
    notify-send -a "Screen recorder" -i dialog-error "Recording failed" "$(tail -n 3 "$log")"
fi
