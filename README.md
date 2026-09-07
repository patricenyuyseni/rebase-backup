# Rebase Backup

A safe and reliable Bash backup utility that creates compressed, timestamped backups of a directory, manages backup retention, logs operations, and sends webhook alerts when a backup fails.

## Features

- Creates compressed `.tar.gz` backups
- Uses timestamped backup filenames
- Configurable backup retention
- Timestamped INFO, WARN, and ERROR logging
- Optional verbose terminal output
- Optional webhook failure alerts
- Validates user input
- Uses temporary files to prevent incomplete backups
- Cleans up temporary files automatically
- Prevents overwriting existing backups
- Safe to run repeatedly
- Can be scheduled with cron

## Requirements

The script requires:

- Bash
- tar
- gzip
- curl (only required when using webhook alerts)
- coreutils

Check your Bash version:

```bash
bash --version

Check required commands:

command -v bash
command -v tar
command -v gzip
command -v curl
Installation

Clone the repository:

git clone https://github.com/YOUR_USERNAME/rebase-backup.git
cd rebase-backup

Make the script executable:

chmod +x rebase-backup.sh
Usage
./rebase-backup.sh [options]
Options
Option	Description
-s SOURCE_DIR	Directory to back up
-d BACKUP_DIR	Directory where backups are stored
-r RETENTION	Number of backups to keep. Default is 7
-w WEBHOOK_URL	Webhook URL for failure alerts
-v	Enable verbose output
-h	Display help information
Examples
Create a backup
./rebase-backup.sh -s ~/backup-test/source -d ~/backup-test/backups
Create a backup with custom retention
./rebase-backup.sh -s ~/backup-test/source -d ~/backup-test/backups -r 3
Enable verbose output
./rebase-backup.sh -s ~/backup-test/source -d ~/backup-test/backups -v
Enable webhook failure alerts
./rebase-backup.sh \
  -s ~/backup-test/source \
  -d ~/backup-test/backups \
  -w "https://your-webhook-url"
Backup Filename

Backups are created using the following format:

backup-YYYY-MM-DD-HHMMSS.tar.gz

Example:

backup-2026-09-03-101905.tar.gz

The timestamp makes each backup easy to identify and allows retention to keep the newest backups.

Retention

The -r option controls how many backups are kept.

For example:

./rebase-backup.sh -s ~/backup-test/source -d ~/backup-test/backups -r 2

If more than two backups exist, the oldest backups are automatically removed.

Logging

The script creates a log file in the backup directory:

rebase-backup.log

Log messages contain:

Timestamp
Log level
Message

Example:

2026-09-03 10:19:05 [INFO] Creating backup
2026-09-03 10:19:06 [INFO] Backup created successfully
2026-09-03 10:19:06 [INFO] Removed old backup

Supported log levels are:

INFO
WARN
ERROR
Safe Backup Creation

The backup is first created inside a temporary directory.

Only after tar successfully finishes is the completed archive moved into the backup directory.

This prevents incomplete .tar.gz files from being left behind when a backup fails.

Temporary files are automatically removed when the script exits.

Failure Alerts

If a backup operation fails and a webhook URL is provided with -w, the script sends a failure notification to the webhook.

Example:

./rebase-backup.sh \
  -s /path/to/source \
  -d /path/to/backups \
  -w "https://your-webhook-url"

The alert contains information about the backup failure.

Safe Repeated Runs

The script prevents overwriting an existing backup with the same timestamp.

If a backup with the generated filename already exists, the script logs a warning and exits successfully.

Example:

[WARN] Backup already exists, skipping
Cron Scheduling

The script can be scheduled using cron.

Open the user's crontab:

crontab -e

Example: run the backup every day at 2:00 AM:

0 2 * * * /home/user/rebase-backup/rebase-backup.sh -s /home/user/documents -d /home/user/backups -r 7

This runs the backup automatically every day and keeps the newest 7 backups.

Testing
Syntax Check
bash -n rebase-backup.sh
ShellCheck

Run ShellCheck to check the script for common shell scripting problems:

shellcheck rebase-backup.sh

The project should produce zero ShellCheck warnings.

Help Test
./rebase-backup.sh -h
Backup Test
./rebase-backup.sh \
  -s ~/backup-test/source \
  -d ~/backup-test/backups \
  -r 2 \
  -v

Check the generated files:

ls -lh ~/backup-test/backups

Inspect an archive:

tar -tzf ~/backup-test/backups/backup-YYYY-MM-DD-HHMMSS.tar.gz
Project Structure
rebase-backup/
├── rebase-backup.sh
├── README.md
└── DEMO.md
License

This project was created as part of a Week 4 Bash scripting assignment.
EOF


### Then verify

Run:

```bash
wc -l README.md

Then:

tail -15 README.md

The last lines should contain:

## Project Structure

rebase-backup/
├── rebase-backup.sh
├── README.md
└── DEMO.md

## License

This project was created as part of a Week 4 Bash scripting assignment.
