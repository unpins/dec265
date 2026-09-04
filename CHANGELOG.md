# Changelog

## [Unreleased]

### Changed

- The Windows binary is now built by the same compiler as the Linux and macOS
  ones, and is 55% smaller (1.78 MB to 801 KB). Checked on Windows 10: it
  decodes a 416x240 clip to the same frames as the previous binary, with one
  thread and with eight.

  It now uses the Universal C Runtime, which is part of Windows 10 and later.
  On Windows 7 or 8.1 that runtime has to be installed first — it comes through
  Windows Update. The previous binary did not need it.
