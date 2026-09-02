#!/usr/bin/env bash

set -euo pipefail

PROGRAM_NAME="rebase-backup.sh"
RETENTION=7
WEBHOOK_URL=""
VERBOSE=false
SOURCE_DIR=""
BACKUP_DIR=""
LOG_FILE=""
TMP_DIR=""

log() {
    local level="$1"
    local message="$2"
    local timestamp

    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    printf '%s [%s] %s\n' "$timestamp" "$level" "$message" >> "$LOG_FILE"

    if [[ "$VERBOSE" == true ]]; then
        printf '%s [%s] %s\n' "$timestamp" "$level" "$message"
    fi
}

cleanup() {
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        rm -rf -- "$TMP_DIR"
    fi
}

trap cleanup EXIT

usage() {
    cat <<EOF
Usage: $PROGRAM_NAME [options]

Backup a directory into a timestamped compressed backup.

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

# Validate required options
if [[ -z "$SOURCE_DIR" ]]; then
    echo "Error: Source directory is required, use -s." >&2
    exit 1
fi

if [[ -z "$BACKUP_DIR" ]]; then
    echo "Error: Backup directory is required, use -d." >&2
    exit 1
fi

# Validate source directory
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Source directory does not exist: $SOURCE_DIR" >&2
    exit 1
fi

if [[ ! -r "$SOURCE_DIR" ]]; then
    echo "Error: Source directory is not readable: $SOURCE_DIR" >&2
    exit 1
fi

# Validate retention
if ! [[ "$RETENTION" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: Retention must be a positive integer: $RETENTION" >&2
    exit 1
fi

# Create backup directory if it does not exist
if [[ ! -d "$BACKUP_DIR" ]]; then
    mkdir -p "$BACKUP_DIR"
fi

# Set log file
LOG_FILE="${BACKUP_DIR}/rebase-backup.log"

# Validate backup directory is writable
if [[ ! -w "$BACKUP_DIR" ]]; then
    echo "Error: Backup directory is not writable: $BACKUP_DIR" >&2
    exit 1
fi

# Create temporary directory
TMP_DIR=$(mktemp -d)

# Create timestamped backup filename
TIMESTAMP=$(date '+%Y-%m-%d-%H%M%S')
ARCHIVE_NAME="backup-${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_NAME}"
TEMP_ARCHIVE="${TMP_DIR}/${ARCHIVE_NAME}"

# Get source directory components
SOURCE_PARENT=$(dirname "$SOURCE_DIR")
SOURCE_NAME=$(basename "$SOURCE_DIR")

# Create compressed backup in temporary directory
log "INFO" "Creating backup: $ARCHIVE_PATH"

tar -czf "$TEMP_ARCHIVE" -C "$SOURCE_PARENT" "$SOURCE_NAME"

# Move completed backup into backup directory
mv -- "$TEMP_ARCHIVE" "$ARCHIVE_PATH"

log "INFO" "Backup created successfully: $ARCHIVE_PATH"

# Apply backup retention
shopt -s nullglob
backups=("$BACKUP_DIR"/backup-*.tar.gz)
shopt -u nullglob

# Sort backups from newest to oldest
mapfile -t backups < <(printf '%s\n' "${backups[@]}" | sort -r)

# Keep only the newest RETENTION backups
if (( ${#backups[@]} > RETENTION )); then
    for ((i=RETENTION; i<${#backups[@]}; i++)); do
        rm -- "${backups[i]}"
        log "INFO" "Removed old backup: ${backups[i]}"
    done
fi