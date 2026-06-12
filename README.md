# Homebrew Tap

This is the [Homebrew](https://brew.sh) tap for [jmerhar/scripts](https://github.com/jmerhar/scripts) — a collection of shell and Perl scripts for macOS and Linux.

## Available scripts

<!-- BEGIN TABLE -->
| Formula | Description |
|---------|-------------|
| `local-backup` | A generic script to create and automatically prune rsync-based system backups. |
| `prune-orphaned-torrents` | Finds orphaned media files left by *arr hard-linking and interactively removes the corresponding torrents from Deluge. |
| `photo-backup` | A robust script for backing up photo collections from multiple sources to a remote server using rsync. |
| `remove-sidecars` | A script to find and delete "sidecar" files when a corresponding RAW photo file exists. |
| `compare-dirs` | Recursively compares two directories and reports differences in existence, size, timestamps, and checksums. |
| `subtitle-report` | Reports on subtitle coverage for a media library, detecting embedded tracks and sidecar files and breaking down counts by language and source. |
| `unlock-pdf` | Decrypts a password-protected PDF file using the 'qpdf' command-line tool. |

<!-- END TABLE -->

## Installation

First, add the tap:

```bash
brew tap jmerhar/scripts
```

Then install any script by name:

```bash
brew install jmerhar/scripts/unlock-pdf
```

For more details on each script, see the [main repository](https://github.com/jmerhar/scripts).
