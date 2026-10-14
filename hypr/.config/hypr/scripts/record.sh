#!/usr/bin/env bash
# Toggle screen recording with desktop audio. Usage: record.sh region|full
# Saves to ~/Videos/Recordings.
state="$XDG_RUNTIME_DIR/recording-path"

if pkill -INT -x wf-recorder; then
    notify-send "Recording saved" "$(cat "$state")"
    exit 0
fi

case ${1:-region} in
    region) geom=$(slurp) || exit 0; set -- -g "$geom" ;;
    full)   set -- ;;
esac

dir="$(xdg-user-dir VIDEOS)/Recordings"
mkdir -p "$dir"
file="$dir/$(date +%Y%m%d-%H%M%S).mp4"
echo "$file" > "$state"

exec wf-recorder "$@" --audio="$(pactl get-default-sink).monitor" \
    -c libx264 -p preset=veryfast -p crf=23 -f "$file"
