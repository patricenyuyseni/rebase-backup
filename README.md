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
- `tar`
- `gzip`
- `curl` (only required when using webhook alerts)
- `coreutils`

Check your Bash version:

```bash
bash --version
