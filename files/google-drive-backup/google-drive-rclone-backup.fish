#!/usr/bin/env fish

function print_help
    echo "Usage: "(basename (status filename))" [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --remote=<remote>      (required) rclone remote path, e.g. 'myremote:/'"
    echo "  --local-path=<path>    (required) local destination path"
    echo "  --config=<path>        (required) path to rclone config file"
    echo "  --dry-run              (optional) perform a trial run without making changes"
    echo "  -h/--help              (optional) show this help message"
end

argparse \
    'h/help' \
    'remote=' \
    'local-path=' \
    'config=' \
    'dry-run' \
    -- $argv
or exit 1

if set -q _flag_help
    print_help
    exit 0
end

if not set -q _flag_remote
    echo "Error: --remote is required."
    echo ""
    print_help
    exit 1
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

rclone sync \
    $_flag_remote $_flag_local_path \
    --checksum \
    --check-first \
    --fast-list \
    --transfers=4 \
    --checkers=4 \
    --config="$_flag_config" \
    --exclude="/.stfolder/**" \
    --exclude="/.stignore" \
    --exclude="/.Trash-1000" \
    --drive-acknowledge-abuse \
    $_flag_dry_run
