# Rebase Backup Demo

This document demonstrates the main features and tests performed for the `rebase-backup.sh` utility.

## 1. Help / CLI Options

Command:

```bash
./rebase-backup.sh -h

Expected result:

Usage: rebase-backup.sh [options]

Backup a directory into a timestamped compressed backup.

Options:
    -s SOURCE_DIR  Directory to back up
    -d BACKUP_DIR  Directory where backups are stored
    -r RETENTION   Number of backups to keep (default: 7)
    -w WEBHOOK_URL Webhook URL for failure alerts
    -v             Enable verbose output
    -h             Show this help message

The help command displays the available options and usage information.

2. Successful Backup

Test source directory:

~/backup-test/source

Test backup directory:

~/backup-test/backups

Command:

./rebase-backup.sh \
  -s ~/backup-test/source \
  -d ~/backup-test/backups \
  -r 2 \
  -v

Example result:

2026-09-04 14:40:00 [INFO] Creating backup: /home/user/backup-test/backups/backup-2026-09-04-144000.tar.gz
2026-09-04 14:40:01 [INFO] Backup created successfully: /home/user/backup-test/backups/backup-2026-09-04-144000.tar.gz

The compressed backup was created successfully.

Check the backup directory:

ls -lh ~/backup-test/backups

Expected files include:

backup-2026-09-04-144000.tar.gz
rebase-backup.log
3. Backup Archive Verification

The generated archive can be inspected using:

tar -tzf ~/backup-test/backups/backup-YYYY-MM-DD-HHMMSS.tar.gz

The command lists the files contained inside the compressed backup.

4. Retention Test

Retention was tested using:

./rebase-backup.sh \
  -s ~/backup-test/source \
  -d ~/backup-test/backups \
  -r 2 \
  -v

The -r 2 option instructs the script to keep only the newest two backup archives.

After multiple backup runs, the backup directory contained only the newest two .tar.gz files.

Example log:

2026-09-04 14:45:00 [INFO] Removed old backup: /home/user/backup-test/backups/backup-2026-09-01-120000.tar.gz

This confirms that older backups are automatically removed.

5. Logging Test

The script creates:

rebase-backup.log

inside the backup directory.

Example log entries:

2026-09-04 14:40:00 [INFO] Creating backup
2026-09-04 14:40:01 [INFO] Backup created successfully
2026-09-04 14:45:00 [INFO] Removed old backup

The script supports the following log levels:

INFO
WARN
ERROR
6. Temporary File Cleanup

The backup archive is first created in a temporary directory.

If the tar operation succeeds, the completed archive is moved into the backup directory.

If the operation fails, the temporary directory is automatically removed.

The script uses:

trap cleanup EXIT

to ensure temporary files are cleaned up when the script exits.

7. Failure Test

An unreadable or invalid source directory was tested.

Example:

./rebase-backup.sh \
  -s /tmp/nonexistent-source \
  -d ~/backup-test/backups

Expected result:

[ERROR] Source directory does not exist: /tmp/nonexistent-source

The script exits with a non-zero status.

8. Unwritable Backup Directory Test

An unwritable backup directory was tested using:

rm -rf /tmp/t6
mkdir -p /tmp/t6/src /tmp/t6/bk
chmod 555 /tmp/t6/bk

./rebase-backup.sh \
  -s /tmp/t6/src \
  -d /tmp/t6/bk \
  -v

Result:

2026-09-04 14:45:48 [ERROR] Backup directory is not writable: /tmp/t6/bk

The script exits with status code 1.

This confirms that the script handles an unwritable backup directory with a clear error instead of producing an uncontrolled permission error.

Restore permissions after testing:

chmod 755 /tmp/t6/bk
9. Webhook Failure Alert

The script supports optional webhook notifications using the -w option.

Example:

./rebase-backup.sh \
  -s /path/to/source \
  -d /path/to/backups \
  -w "https://your-webhook-url"

When a backup failure occurs, the script sends a failure notification to the configured webhook.

The webhook test confirmed that a failure notification was received.

The actual webhook URL is intentionally not included in this document.

10. Safe Repeated Runs

The script prevents an existing backup from being overwritten when the generated timestamp matches an existing backup.

Example warning:

[WARN] Backup already exists, skipping

The script exits successfully without overwriting the existing archive.

11. Input Validation Tests

The following invalid inputs were tested:

Missing source directory
Missing backup directory
Non-existent source directory
Invalid retention value
Zero retention value
Invalid command-line option
Missing option argument
Invalid webhook URL

The script returned clear error messages and non-zero exit codes for invalid input.

12. Syntax and ShellCheck Tests

Syntax check:

bash -n rebase-backup.sh

Result:

No output / no syntax errors

ShellCheck:

shellcheck rebase-backup.sh

Result:

No warnings

The script passes ShellCheck with zero warnings.

13. Cron Scheduling

The script can be scheduled with cron.

Open the crontab:

crontab -e

Example:

0 2 * * * /home/user/rebase-backup/rebase-backup.sh -s /home/user/documents -d /home/user/backups -r 7

This runs the backup every day at 2:00 AM and keeps the newest seven backups.

14. Summary

The demo verifies:

Help and CLI options
Successful compressed backups
Timestamped backup filenames
Backup retention
Timestamped logging
Temporary file cleanup
Failure handling
Unwritable backup directory handling
Webhook failure alerts
Safe repeated runs
Input validation
Cron scheduling
Bash syntax validation
Zero ShellCheck warnings
