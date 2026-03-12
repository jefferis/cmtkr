## cmtkr Revision (0.2.3)

cmtkr v0.2.3 addresses a compiler warning noted on the macos-x86_64 platform of
the CRAN checks page for cmtkr v0.2.2

https://cran.r-project.org/web/checks/check_results_cmtkr.html

1) I replaced deprecated `finite(...)` usage in the CMTK C++ sources with
   `std::isfinite(...)`.  This fixes the macosx build failures on CRAN.

2) While preparing this release, I noticed that winbuilder devel checks were now
   failing in a GCC 15.2.0 `mingw32.static.posix`
   environment (`https://win-builder.r-project.org/ukx0p5u2BqeD/00install.out`) with
   MinGW header/toolchain errors during `RcppExports.cpp` compilation. I therefore set
   `CXX_STD = CXX17` in `src/Makevars.win` to
   request the C++17 standard through R's standard configuration path.

### Checks

I re-ran Win Builder checks on:

https://win-builder.r-project.org/pFggblPNAr52/

`Status: 1 NOTE` is reported from CRAN incoming feasibility (`Maintainer: ...`,
`Days since last update: 4`), with no `ERROR` or `WARNING` in the package checks.

All other checks are `OK`, and `used C++ compiler` is reported as
`g++.exe (GCC) 14.3.0` with `checking C++ specification ... INFO specified C++17`.

Thank you very much for valuable contributions to the CRAN ecosystem.

With best wishes, 

Greg Jefferis.
