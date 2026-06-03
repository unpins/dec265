# dec265

Standalone build of [dec265](https://github.com/strukturag/libde265) — the
[libde265](https://github.com/strukturag/libde265) H.265/HEVC decoder CLI.

[![CI](https://github.com/unpins/dec265/actions/workflows/dec265.yml/badge.svg)](https://github.com/unpins/dec265/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Decodes a raw H.265/HEVC bitstream (or a length-prefixed NAL stream) to YUV/Y4M,
dumps stream headers, checks frame hashes and measures PSNR against a reference —
the decoder library that libheif/FFmpeg/GStreamer use to read HEIC, as a single
self-contained binary.

Part of the [unpins](https://unpins.org) project — native single-binary builds with no third-party runtime dependencies.

## Usage

```bash
dec265 -o out.yuv video.265        # decode a raw bitstream to YUV
dec265 -n -o out.yuv stream.bin    # input is length-prefixed NAL units
dec265 -d video.265                # dump headers only
dec265 -c video.265                # verify frame hashes
```

Run `dec265 -h` for the full option list.

To install it onto your PATH:

```bash
unpin install dec265
```

## Build locally

```bash
nix build github:unpins/dec265
./result/bin/dec265 -h
```

Or run directly:

```bash
nix run github:unpins/dec265 -- -d video.265
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/dec265/releases) page has standalone binaries for manual download.

## Build notes

- Single upstream CLI (`dec265`); the `libde265` library is not user-facing, so
  it is linked in statically rather than shipped. The package is named after the
  tool. The other in-tree apps stay off — `enc265` and the Qt `sherlock265`
  inspector are upstream-default-OFF, and SDL preview support is dropped so the
  decoder builds headless with no SDL2 in the closure.
- `BUILD_SHARED_LIBS=OFF` is load-bearing: it folds `libde265` into the binary
  as a static archive (no companion `.so`/`.dylib`) and defines
  `LIBDE265_STATIC_BUILD`, so the API header isn't decorated with
  `__declspec(dllimport)` on Windows.
- **Windows:** `mingw` cross, single `.exe`, no companion DLLs — the C++/thread
  runtime (libstdc++/libgcc/libwinpthread) is folded in statically.
- **macOS:** the static `libc++` is folded in so the binary links only
  `libSystem`, never `/usr/lib/libc++.1.dylib`.
- No man page upstream, so none is embedded.
