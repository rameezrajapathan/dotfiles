#!/usr/bin/env bash
set -u

host=https://speed.cloudflare.com
budget=8
chunk=25000000

fail() { echo "error $1"; exit 1; }

best=""
for _ in 1 2 3 4 5; do
    t=$(curl -s -o /dev/null --max-time 5 -w '%{time_pretransfer} %{time_starttransfer}' "$host/__down?bytes=0") || continue
    ms=$(awk '{ printf "%.0f", ($2 - $1) * 1000 }' <<<"$t")
    [ -z "$best" ] || [ "$ms" -lt "$best" ] && best=$ms
done
[ -n "$best" ] || fail "Can't reach speed.cloudflare.com"
echo "ping $best"

measure() {
    local bytes=0 secs=0 out
    local end=$((SECONDS + budget))
    while [ $SECONDS -lt $end ]; do
        if [ "$1" = down ]; then
            out=$(curl -s -o /dev/null --max-time $((end - SECONDS + 1)) \
                -w '%{size_download} %{time_starttransfer} %{time_total}' "$host/__down?bytes=$chunk")
        else
            out=$(head -c $chunk /dev/zero | curl -s -o /dev/null --max-time $((end - SECONDS + 1)) \
                -X POST --data-binary @- -w '%{size_upload} %{time_pretransfer} %{time_total}' "$host/__up")
        fi
        read -r b start total <<<"$out"
        [ -n "${b:-}" ] || break
        bytes=$((bytes + ${b%.*}))
        secs=$(awk -v s="$secs" -v a="$start" -v t="$total" 'BEGIN { print s + t - a }')
    done
    awk -v b="$bytes" -v s="$secs" 'BEGIN { if (s > 0 && b > 0) printf "%.1f", b * 8 / s / 1e6; else print "" }'
}

down=$(measure down)
[ -n "$down" ] || fail "Download test failed"
echo "down $down"

up=$(measure up)
[ -n "$up" ] || fail "Upload test failed"
echo "up $up"
