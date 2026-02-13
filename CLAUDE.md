# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

cmtkr is an R package wrapping the Computational Morphometry Toolkit (CMTK) via Rcpp, enabling direct library calls for 3D point transformations (~100x faster than CLI). Used in neuroscience for brain image registration (fly brains: FAFB, FCWB, JFRC2).

## System Requirement

Only zlib is needed (available on all platforms). CMTK source is vendored in `src/cmtk/`.

## Build & Development Commands

```bash
# Regenerate Rcpp bindings (after editing src/*.cpp)
Rscript -e 'Rcpp::compileAttributes()'

# Regenerate NAMESPACE and man/ pages (after editing roxygen comments)
Rscript -e 'devtools::document()'

# Build and install
R CMD INSTALL .

# Run all tests
Rscript -e 'devtools::test()'

# Run a single test file
Rscript -e 'testthat::test_file("tests/testthat/test-streamxform.r")'

# Full package check
R CMD check .
```

## Architecture

- **Single exported function**: `streamxform(points, reglist, inversionTolerance, affineonly)` — transforms an Nx3 matrix of 3D points through a chain of CMTK registrations.
- **R layer**: `R/RcppExports.R` (auto-generated) and `R/cmtkr-package.r` (package docs). Don't hand-edit `RcppExports.R`; run `Rcpp::compileAttributes()` instead.
- **C++ layer**: `src/streamxform.cpp` is the sole implementation file. It loads CMTK registrations via `XformListIO`, builds an `XformList`, and applies it per-point. Append `--inverse` to a registration path in `reglist` to invert it.
- **Test data**: CMTK registration directories live in `inst/extdata/cmtk/`. Tests compare round-trip (forward+inverse) accuracy and optionally validate against the nat package's CLI-based transforms.
