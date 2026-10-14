#!/usr/bin/env bash
# Pick an entry from cliphist and copy it back to the clipboard.
cliphist list | fuzzel --dmenu --prompt "clip " | cliphist decode | wl-copy
