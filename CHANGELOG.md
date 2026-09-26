# Changelog

## [Unreleased]

## [1.1.2-1] - 2026-09-26

### Fixed

- Reading a bitstream from standard input no longer loses most of the video on
  Windows. Windows opens standard input in text mode, and a text-mode read
  stops at the first 0x1A byte — a byte that occurs freely in a compressed
  stream. Measured on Windows 10: a five-frame clip decoded from standard input
  produced **one** frame, printed a stream warning, and exited 0. Four fifths of
  the video went missing with a success status.

- Writing frames to standard output (`-o -`) no longer corrupts them on
  Windows, for the same reason in the other direction: every line-feed byte in
  the picture data was written as carriage-return plus line-feed, so the same
  clip came out as 30736 bytes instead of 30720.

  Both paths now produce output byte-identical to Linux and macOS. Named input
  and output files were never affected.

### Changed

- Updated to libde265 1.1.1.
- The Windows binary is now built by the same compiler as the Linux and macOS
  ones, and is 55% smaller (1.78 MB to 801 KB). Checked on Windows 10: it
  decodes a 416x240 clip to the same frames as the previous binary, with one
  thread and with eight.

  It now uses the Universal C Runtime, which is part of Windows 10 and later.
  On Windows 7 or 8.1 that runtime has to be installed first — it comes through
  Windows Update. The previous binary did not need it.
