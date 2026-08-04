{
  description = "dec265 (libde265 H.265/HEVC decoder) as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # libde265 ships one user-facing CLI, `dec265`: it decodes a raw H.265/HEVC
  # bitstream (or length-prefixed NAL stream) to YUV/Y4M and can dump headers,
  # check hashes and measure PSNR. The library itself (used by heif/ffmpeg/
  # gstreamer to read HEIC) is not user-facing, so the package is named after
  # the tool (`dec265`), like xmllint/fpcalc — CI resolves result/bin/<name>.
  #
  # Single binary, no multicall: the canonical bin is already `dec265`. The
  # other in-tree apps stay off — enc265 (ENABLE_ENCODER) and sherlock265 (a Qt
  # visual inspector) are default-OFF, and we drop SDL so dec265 builds without
  # a display dep (it writes YUV; the optional SDL preview is irrelevant for a
  # headless single-binary tool and would otherwise pull SDL2 into the closure).
  #
  # libde265 is portable CMake C++ with no external library deps, so the static
  # build is tiny and crosses cleanly. BUILD_SHARED_LIBS=OFF is the load-bearing
  # flag: it builds libde265 as a `.a` that folds into dec265 (otherwise the
  # frontend links a companion .so/.dylib → portability fail, the libsox/lame
  # trap) AND it makes the top CMakeLists add -DLIBDE265_STATIC_BUILD, so the
  # in-tree dec265.cc sees de265.h's API without __declspec(dllimport) on mingw
  # (the __imp_de265_* thunk problem heif hit consuming libde265 externally).
  # pkgsStatic/mingwStaticCross already set it for static builds, but we pass it
  # explicitly so the macro is defined on every target (incl. darwin).
  #
  # dec265 has no man page (libde265 ships none) → embedMan = false.
  outputs = { self, unpins-lib }:
    let
      ulib = unpins-lib.lib;

      # Build dec265 from the static package set for the target (pkgsStatic or
      # mingwStaticCross). libde265 is C++ (a std::thread worker pool), so the
      # toolchain runtime needs folding in: on mingw `-static` pulls
      # libstdc++/libgcc/libwinpthread into the .exe (only system DLLs remain);
      # on darwin the link would import /usr/lib/libc++.1.dylib, which the unpins
      # allowlist rejects, so -search_paths_first + a static-libc++ shim fold it
      # in (the same recipe fpcalc — also C++ — uses).
      mk = sp:
        let
          host = sp.stdenv.hostPlatform;
          isWindows = host.isWindows or false;
          isDarwin = host.isDarwin or false;
        in
        sp.libde265.overrideAttrs (old: {
          pname = "dec265";
          meta = (old.meta or { }) // {
            platforms = sp.lib.platforms.all;
            broken = false;
            mainProgram = "dec265";
          };
          cmakeFlags = (old.cmakeFlags or [ ])
            ++ [
            "-DBUILD_SHARED_LIBS=OFF"   # static libde265.a folds into dec265 + defines LIBDE265_STATIC_BUILD
            "-DENABLE_SDL=OFF"          # headless: no SDL2 preview/dep
            "-DENABLE_ENCODER=OFF"
            "-DENABLE_SHERLOCK265=OFF"
          ]
            ++ (if isWindows then [ "-DCMAKE_EXE_LINKER_FLAGS=-static" ] else [ ])
            ++ (if isDarwin then [ "-DCMAKE_EXE_LINKER_FLAGS=-Wl,-search_paths_first" ] else [ ]);
          preConfigure = (old.preConfigure or "") + (if isDarwin then ''
            # Expose static libc++/libc++abi as libc++.a/libstdc++.a/libc++abi.a
            # ahead of the dylib dirs so dec265 folds libc++ in instead of
            # importing /usr/lib/libc++.1.dylib (same shim fpcalc uses).
            mkdir -p "$TMPDIR/cxx-static"
            ln -sf ${sp.libcxx}/lib/libc++.a    "$TMPDIR/cxx-static/libc++.a"
            ln -sf ${sp.libcxx}/lib/libc++.a    "$TMPDIR/cxx-static/libstdc++.a"
            ln -sf ${sp.libcxx}/lib/libc++abi.a "$TMPDIR/cxx-static/libc++abi.a"
            export NIX_LDFLAGS="-L$TMPDIR/cxx-static $NIX_LDFLAGS"
          '' else "");
        });
    in
    ulib.mkStandaloneFlake {
      inherit self;
      name = "dec265";

      # Build via the unpin-llvm engine + emit a bitcode multicall module.
      engine = "unpin-llvm";
      multicall = {
        programs = [{ name = "dec265"; }];
      };
      # Upstream nixpkgs attr is `libde265` (CLI is `dec265`); pkgsAttr names it
      # so the engine's stdenv override targets the attr `build` actually uses.
      pkgsAttr = "libde265";
      embedMan = false;
      # dec265 has no --version; `-h` prints the ` dec265  vX.Y.Z` banner + usage
      # and exits 0 (other recognized flags exit 5 when no input file follows).
      smoke = [ "-h" ];
      smokePattern = "dec265  v1\\.0";
      build = pkgs: mk pkgs.pkgsStatic;
      windowsBuild = pkgs: mk (ulib.mingwStaticCross pkgs);
    };
}
