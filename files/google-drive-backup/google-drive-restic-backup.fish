#!/usr/bin/env fish

function print_help
    echo "Usage: "(basename (status filename))" [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --dry-run              (optional) perform a trial run without making changes"
    echo "  -h/--help              (optional) show this help message"
end

argparse \
    'h/help' \
    'dry-run' \
    -- $argv
or exit 1

if set -q _flag_help
    print_help
    exit 0
end

# Read and export variables from the config env file
for line in (grep -v '^\s*#' /restic.env | grep -v '^\s*$')
    set -x (echo $line | cut -d= -f1) (echo $line | cut -d= -f2-)
end

restic backup \
    $_flag_dry_run \
    --no-scan \
    --json \
    --compression=max \
    --quiet \
    /data
