#!/usr/bin/env bash

set -euo pipefail

PROGRAM_NAME="rebase-backup.sh"
RETENTION=7
WEBHOOK_URL=""
VERBOSE=false
SOURCE_DIR=""
BACKUP_DIR=""

usage() {
    cat <<EOF
Usage: $PROGRAM_NAME [options]

Backup a directory into a timestamped compressed archive

Options:
    -s SOURCE_DIR  Directory to back up
    -d BACKUP_DIR  Directory where backups are stored
    -r RETENTION   Number of backups to keep (default: 7)
    -w WEBHOOK_URL Webhook URL for failure alerts
    -v             Enable verbose output
    -h             Show this help message   

Example:
    $PROGRAM_NAME -s /home/user/documents -d /backups

EOF
}

while getopts ":s:d:r:w:vh" opt; do
    case "$opt" in
        s)
            SOURCE_DIR="$OPTARG"
            ;;
        d)
            BACKUP_DIR="$OPTARG"
            ;;
        r)
            RETENTION="$OPTARG"
            ;;
        w)
            WEBHOOK_URL="$OPTARG"
            ;;
        v)
            VERBOSE=true
            ;;
        h)
            usage
            exit 0
            ;;
        :)
            echo "Error: Option -$OPTARG requires an argument." >&2
            usage >&2
            exit 1
            ;;
        \?)
            echo "Error: Invalid option -$OPTARG" >&2
            usage >&2
            exit 1
            ;;
    esac
done