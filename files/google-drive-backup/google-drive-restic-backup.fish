#!/usr/bin/env fish

function print_help
    echo "Usage: "(basename (status filename))" [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --local-path=<path>    (required) local destination path"
    echo "  --config=<path>        (required) path to restic config file"
    echo "  --dry-run              (optional) perform a trial run without making changes"
    echo "  -h/--help              (optional) show this help message"
end

argparse \
    'h/help' \
    'local-path=' \
    'config=' \
    'dry-run' \
    -- $argv
or exit 1

if set -q _flag_help
    print_help
    exit 0
end

if not set -q _flag_local_path
    echo "Error: --local-path is required."
    echo ""
    print_help
    exit 1
end

if not set -q _flag_config
    echo "Error: --config is required."
    echo ""
    print_help
    exit 1
end

# Read and export variables from the config env file
for line in (grep -v '^\s*#' $_flag_config | grep -v '^\s*$')
    set -x (echo $line | cut -d= -f1) (echo $line | cut -d= -f2-)
end

restic backup \
    $_flag_dry_run \
    --no-scan \
    --json \
    --compression=max \
    --quiet \
    $_flag_local_path
