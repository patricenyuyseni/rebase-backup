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
ALERT_SENT=false

log() {
    local level="$1"
    local message="$2"
    local timestamp

    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ -n "$LOG_FILE" ]]; then
        printf '%s [%s] %s\n' "$timestamp" "$level" "$message" >> "$LOG_FILE"
    fi

    if [[ "$VERBOSE" == true ]]; then
        printf '%s [%s] %s\n' "$timestamp" "$level" "$message"
    fi
}

send_alert() {
    local message="$1"

    if [[ -n "$WEBHOOK_URL" && "$ALERT_SENT" == false ]]; then
        ALERT_SENT=true

        if ! curl -fsS \
            -X POST \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"rebase-backup failed: ${message}\"}" \
            "$WEBHOOK_URL" \
            >/dev/null; then

            log "WARN" "Failed to send webhook alert"
        fi
    fi
}

fail() {
    local message="$1"

    if [[ -n "$LOG_FILE" ]]; then
        log "ERROR" "$message"
    else
        printf '%s [ERROR] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >&2
    fi

    send_alert "$message"

    printf 'Error: %s\n' "$message" >&2
    exit 1
}

cleanup() {
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        rm -rf -- "$TMP_DIR"
    fi
}

handle_failure() {
    local exit_code="$1"
    local failed_command="$2"

    if [[ -n "$LOG_FILE" ]]; then
        log "ERROR" "Backup failed with exit code $exit_code: $failed_command"
    fi

    send_alert "$failed_command"

    exit "$exit_code"
}

trap cleanup EXIT
trap 'handle_failure "$?" "$BASH_COMMAND"' ERR

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

# Validate webhook URL and curl first
if [[ -n "$WEBHOOK_URL" ]]; then
    if ! [[ "$WEBHOOK_URL" =~ ^https?://[^[:space:]]+$ ]]; then
        echo "Error: Webhook URL must start with http:// or https://." >&2
        exit 1
    fi

    if ! command -v curl >/dev/null 2>&1; then
        echo "Error: curl is required when using a webhook URL." >&2
        exit 1
    fi
fi

# Validate required options
if [[ -z "$SOURCE_DIR" ]]; then
    fail "Source directory is required, use -s."
fi

if [[ -z "$BACKUP_DIR" ]]; then
    fail "Backup directory is required, use -d."
fi

# Validate source directory
if [[ ! -d "$SOURCE_DIR" ]]; then
    fail "Source directory does not exist: $SOURCE_DIR"
fi

if [[ ! -r "$SOURCE_DIR" ]]; then
    fail "Source directory is not readable: $SOURCE_DIR"
fi

# Validate retention
if ! [[ "$RETENTION" =~ ^[1-9][0-9]*$ ]]; then
    fail "Retention must be a positive integer: $RETENTION"
fi

# Create backup directory if it does not exist
if [[ ! -d "$BACKUP_DIR" ]]; then
    mkdir -p "$BACKUP_DIR"
fi

# Set log file
LOG_FILE="${BACKUP_DIR}/rebase-backup.log"

# Validate backup directory is writable
if [[ ! -w "$BACKUP_DIR" ]]; then
    fail "Backup directory is not writable: $BACKUP_DIR"
fi

# Create temporary directory
TMP_DIR=$(mktemp -d)

# Create timestamped backup filename
TIMESTAMP=$(date '+%Y-%m-%d-%H%M%S')
ARCHIVE_NAME="backup-${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_NAME}"
TEMP_ARCHIVE="${TMP_DIR}/${ARCHIVE_NAME}"

# Prevent overwriting an existing backup
if [[ -e "$ARCHIVE_PATH" ]]; then
    log "WARN" "Backup already exists, skipping: $ARCHIVE_PATH"
    exit 0
fi

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