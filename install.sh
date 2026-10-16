#!/usr/bin/env bash
set -e
exec "$(dirname "$(readlink -f "$0")")/config/pikadots/pikadots" install
