#!/usr/bin/env bash
# One snapshot for the bar's system panel (SystemPanel.qml), as "key value..." lines.
# Never wakes a sleeping NVIDIA GPU: nvidia-smi only runs while it's already active.

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
echo "cpu $((user + nice + system + irq + softirq + steal)) $((idle + iowait))"
awk '/^MemTotal/ {t = $2} /^MemAvailable/ {a = $2} END {print "mem", t, a}' /proc/meminfo
df -B1 --output=used,size / | awk 'NR == 2 {print "disk", $1, $2}'

for h in /sys/class/hwmon/hwmon*; do
	case $(<"$h/name") in
		coretemp | k10temp) echo "cputemp $(($(<"$h/temp1_input") / 1000))" ;;
		asus)
			for f in "$h"/fan*_input; do
				echo "fan $(<"${f%_input}_label") $(<"$f")"
			done
			;;
	esac
done

for d in /sys/bus/pci/devices/*; do
	[[ $(<"$d/vendor") == 0x10de && $(<"$d/class") == 0x03* ]] || continue
	state=$(<"$d/power/runtime_status")
	echo "gpustate $state"
	if [[ $state == active ]] && command -v nvidia-smi >/dev/null; then
		nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw \
			--format=csv,noheader,nounits | awk -F', ' '{print "gpu", $2, $3, $4, $5, $6, $1}'
	fi
	break
done

# Busiest processes right now (top's second sample; the first averages since boot)
top -b -n 2 -d 0.4 -o %CPU -w 200 | awk '/^top -/ {n++} n == 2 && $1 ~ /^[0-9]+$/ && $12 != "top" && c < 5 {print "proc", $9, $10, $12; c++}'
