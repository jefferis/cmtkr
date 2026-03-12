# cmtkr 0.2.3

* Replaced deprecated `finite(...)` checks with `std::isfinite(...)` across 
  CMTK C++ source and wrapper code to address macOS compiler warnings.
* Pinned Windows builds to C++17 in `src/Makevars.win` to avoid a MinGW 
  `static.posix` header/toolchain incompatibility observed on Win Builder.

# cmtkr 0.2.2

* Updated software/API quoting in `DESCRIPTION` to use CRAN-preferred single
  quotes (e.g. `'R'`, `'C++'`, `'CMTK'`).
* Replaced `\\dontrun{}` with `\\donttest{}` in `streamxform` examples.

# cmtkr 0.2.1

* Added a methods reference to `DESCRIPTION` in CRAN-compliant format.
* Expanded `streamxform` return-value documentation to describe output structure.
* Added `inst/CITATION` entry for the core CMTK methods paper.

# cmtkr 0.2

* First public release after including enough of the CMTK library source code
  to support point transforms using the `streamxform()` function
