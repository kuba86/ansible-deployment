#!/bin/bash

# Usage:
# ./systemd_stats.sh                  # Runs journalctl automatically
# journalctl ... | ./systemd_stats.sh # Reads from pipe

process_log() {
    awk '
    function parse_time(t_str,    val, parts, i, sum) {
        sum = 0
        n = split(t_str, parts, " ")
        for (i = 1; i <= n; i++) {
            val = parseFloat(parts[i])
            if (parts[i] ~ /h$/)        sum += val * 3600
            else if (parts[i] ~ /min$/) sum += val * 60
            else if (parts[i] ~ /ms$/)  sum += val * 0.001
            else if (parts[i] ~ /s$/)   sum += val
        }
        return sum
    }

    function parse_mem(m_str,    val) {
        val = parseFloat(m_str)
        if (m_str ~ /G$/)      return val * 1024
        if (m_str ~ /M$/)      return val
        if (m_str ~ /K$/)      return val / 1024
        if (m_str ~ /B$/)      return val / 1024 / 1024
        return val
    }

    function parseFloat(str) {
        sub(/[a-zA-Z]+$/, "", str)
        return str + 0
    }

    function fmt_time(s) {
        if (s >= 3600) return sprintf("%.2fh", s/3600)
        if (s >= 60)   return sprintf("%.2fm", s/60)
        return sprintf("%.2fs", s)
    }

    function fmt_mem(m) {
        if (m >= 1024) return sprintf("%.2fG", m/1024)
        return sprintf("%.2fM", m)
    }

    {
        if (match($0, /([a-zA-Z0-9@\._-]+): Consumed (.*) CPU time, (.*) memory peak/, arr)) {
            unit = arr[1]

            # --- FILTERING & GROUPING LOGIC START ---

            # 1. Exclude libpod-*.scope
            if (unit ~ /^libpod-.*\.scope$/) next

            # 2. Exclude podman-*.scope
            if (unit ~ /^podman-.*\.scope$/) next

            # 3. Group session-*.scope
            if (unit ~ /^session-.*\.scope$/) {
                unit = "session-*.scope (grouped)"
            }

            # 4. Exclude Other
            if (unit ~ /^systemd-coredump/) next
            if (unit ~ /^x2d/) next
            if (unit ~ /^app-/) next
            if (unit ~ /^drkonqi-coredump-/) next
            if (unit ~ /^plasma-/) next

            # --- FILTERING & GROUPING LOGIC END ---

            raw_cpu = arr[2]
            raw_mem = arr[3]

            cpu_sec = parse_time(raw_cpu)
            mem_mb = parse_mem(raw_mem)

            count[unit]++

            # CPU Stats
            sum_cpu[unit] += cpu_sec
            if (count[unit] == 1 || cpu_sec < min_cpu[unit]) min_cpu[unit] = cpu_sec
            if (count[unit] == 1 || cpu_sec > max_cpu[unit]) max_cpu[unit] = cpu_sec

            # Mem Stats
            sum_mem[unit] += mem_mb
            if (count[unit] == 1 || mem_mb < min_mem[unit]) min_mem[unit] = mem_mb
            if (count[unit] == 1 || mem_mb > max_mem[unit]) max_mem[unit] = mem_mb
        }
    }

    END {
        printf "%-35s | %-5s | %-24s | %-24s\n", "UNIT", "CNT", "CPU (Min/Avg/Max)", "MEM (Min/Avg/Max)"
        print "------------------------------------|-------|--------------------------|--------------------------"

        for (u in count) {
            avg_c = sum_cpu[u] / count[u]
            avg_m = sum_mem[u] / count[u]

            printf "%-35s | %-5d | %6s / %6s / %6s | %6s / %6s / %6s\n", \
                substr(u, 1, 35), count[u], \
                fmt_time(min_cpu[u]), fmt_time(avg_c), fmt_time(max_cpu[u]), \
                fmt_mem(min_mem[u]), fmt_mem(avg_m), fmt_mem(max_mem[u])
        }
    }
    '
}

execute() {
    if [ -t 0 ]; then
        sudo journalctl --grep "Consumed" | process_log
    else
        cat - | process_log
    fi
}

output=$(execute)
header=$(echo "$output" | head -n 2)
body=$(echo "$output" | tail -n +3)

echo "$header"
# Current Sort: Alphabetical by UNIT Name
echo "$body" | sort -t '|' -k 1,1
