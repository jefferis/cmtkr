# Plan: Reusable CMTK `XformList` Object (S3 vs R6)

## Goal
Avoid re-reading transform files on repeated calls by loading a `cmtk::XformList` once and reusing it.

## Shared Native Core (used by both S3 and R6)
Implement this once in C++ and expose with `.Call`:

1. `_cmtkr_xformlist_load(reglist, inversionTolerance, affineonly) -> externalptr`
2. `_cmtkr_streamxform_ptr(points, xform_ptr) -> matrix`
3. `_cmtkr_xformlist_set_epsilon(xform_ptr, inversionTolerance)` (optional)
4. `_cmtkr_xformlist_is_valid(xform_ptr) -> logical` (optional)
5. C finalizer for `externalptr` that `delete`s `cmtk::XformList` and clears ptr

### C++ skeleton
```cpp
// [[Rcpp::export]]
SEXP xformlist_load_cpp(CharacterVector reglist, double inversionTolerance = 1e-8,
                        bool affineonly = false) {
  auto* xp = new cmtk::XformList(cmtk::XformListIO::MakeFromStringList(as<std::vector<std::string>>(reglist)));
  xp->SetEpsilon(cmtk::Types::Coordinate(inversionTolerance));
  if (affineonly) *xp = xp->MakeAllAffine();
  SEXP ptr = PROTECT(R_MakeExternalPtr(xp, R_NilValue, R_NilValue));
  R_RegisterCFinalizerEx(ptr, xformlist_finalizer, TRUE);
  UNPROTECT(1);
  return ptr;
}

// [[Rcpp::export]]
NumericMatrix streamxform_ptr_cpp(NumericMatrix points, SEXP ptr) {
  // validate ptr, cast, apply transform list to points
}
```

## Option A (Recommended): S3 Wrapper
Lightweight, dependency-free, idiomatic for opaque native handles.

### Files to add
- `R/xformlist.R`
- `src/xformlist.cpp`
- update `NAMESPACE` and regenerate `R/RcppExports.R`, `src/RcppExports.cpp`
- add tests in `tests/testthat/test-xformlist.R`

### R skeleton
```r
xformlist_load <- function(reglist, inversionTolerance = 1e-8, affineonly = FALSE) {
  ptr <- .Call(`_cmtkr_xformlist_load`, reglist, inversionTolerance, affineonly)
  structure(
    list(ptr = ptr, reglist = reglist, affineonly = affineonly, inversionTolerance = inversionTolerance),
    class = "cmtk_xformlist"
  )
}

is.cmtk_xformlist <- function(x) inherits(x, "cmtk_xformlist")

print.cmtk_xformlist <- function(x, ...) {
  cat("<cmtk_xformlist>", length(x$reglist), "entries\n")
  invisible(x)
}

streamxform <- function(points, reglist, inversionTolerance = 1e-8, affineonly = FALSE) {
  if (is.cmtk_xformlist(reglist)) {
    return(.Call(`_cmtkr_streamxform_ptr`, points, reglist$ptr))
  }
  .Call(`_cmtkr_streamxform`, points, reglist, inversionTolerance, affineonly)
}
```

### S3 notes
- Keep current API fully backward compatible (`reglist` as character vector still works).
- The wrapper stores metadata for printing/debugging; C++ pointer remains source of truth.

## Option B: R6 Wrapper
Useful only if an OO method-driven API is desired.

### Additional dependency
- `R6` in `Imports`

### Files to add
- `R/xformlist_r6.R`
- same C++ files as above
- tests for class behavior

### R6 skeleton
```r
CmtkXformList <- R6::R6Class(
  "CmtkXformList",
  private = list(ptr = NULL),
  public = list(
    reglist = NULL,
    affineonly = NULL,
    inversionTolerance = NULL,

    initialize = function(reglist, inversionTolerance = 1e-8, affineonly = FALSE) {
      private$ptr <- .Call(`_cmtkr_xformlist_load`, reglist, inversionTolerance, affineonly)
      self$reglist <- reglist
      self$affineonly <- affineonly
      self$inversionTolerance <- inversionTolerance
    },

    transform = function(points) {
      .Call(`_cmtkr_streamxform_ptr`, points, private$ptr)
    },

    set_epsilon = function(inversionTolerance) {
      .Call(`_cmtkr_xformlist_set_epsilon`, private$ptr, inversionTolerance)
      self$inversionTolerance <- inversionTolerance
      invisible(self)
    }
  )
)
```

### R6 notes
- Better if you expect many mutable methods and user-facing object workflow.
- Heavier maintenance and dependency for limited performance benefit over S3.

## Testing Skeleton (both options)
1. Load once, apply many times; results match current `streamxform(character_reglist)`.
2. Invalid pointer raises clear error.
3. `affineonly=TRUE` behavior preserved.
4. Finalizer path does not crash (`rm(obj); gc()` smoke test).
5. NA behavior on invalid transformed points unchanged.

## Integration With `nat::xform` / `nat::reglist`
`nat` currently routes transformations through S3 dispatch (`xform` -> `xformpoints`) and treats `reglist` as a sequential wrapper that may be simplified into one CMTK call when possible (`simplify_reglist`, `xformpoints.reglist`, `xformpoints.cmtkreg`).

### What should integrate well
1. Add S3 support in `nat` for a new class, e.g. `cmtk_xformlist`:
   - `xformpoints.cmtk_xformlist(reg, points, ...)`
   - Optional `xformimage.cmtk_xformlist` (likely not useful initially for point-only backend)
2. Keep `cmtkr::streamxform()` backward compatible and allow `reglist` argument to be either:
   - character/CMTK paths (current behavior)
   - preloaded `cmtk_xformlist` object (new fast path)
3. In `nat`, allow explicit opt-in preload:
   - user builds a CMTK registration sequence as usual (`reglist(...)`, `simplify_reglist(...)`)
   - convert CMTK-compatible sequence to `cmtkr::xformlist_load(...)`
   - dispatch to `xformpoints.cmtk_xformlist` for repeated transforms

### Where integration is less direct
1. `nat::reglist` can mix matrix/function/CMTK registrations; `cmtk_xformlist` can only represent CMTK-compatible chains.
2. `reglist` uses per-element `swap` semantics; those must be materialized into explicit `--inverse` ordering before loading into native pointer.
3. `simplify_reglist(..., as.cmtk=TRUE)` may create temporary on-disk files; preload objects should either:
   - capture stable paths only, or
   - hold a temp-file lifecycle contract (harder to make robust across package boundaries).
4. External pointers are session-local and non-serializable; `nat` workflows that persist reg objects via `saveRDS` should not expect pointer reusability after reload.

### Practical interoperability design
1. Keep `cmtkr` independent of `nat` (no hard dependency).
2. Provide conversion helpers in `cmtkr`, e.g. `as_cmtk_regargs(reg, swap=...)` to build canonical CMTK arg vectors.
3. In `nat`, optionally add:
   - `as.cmtk_xformlist.reglist()` that first `simplify_reglist(..., as.cmtk=TRUE)`, then loads via `cmtkr`.
4. Fall back automatically:
   - if not fully CMTK-compatible, continue existing `nat` per-step `xformpoints()` behavior.

### Net assessment
- Strong fit for repeated point transforms where a `reglist` is already CMTK-only.
- Weak fit for heterogeneous/persisted `reglist` workflows unless treated as an optional runtime acceleration layer.

## Rollout Plan
1. Implement shared C++ pointer API + finalizer.
2. Implement S3 wrapper and wire `streamxform()` dual input.
3. Add tests and docs.
4. Benchmark repeated calls vs current implementation.
5. Only add R6 if there is a concrete OO use case not served by S3.

## Recommendation
Start with S3 + `externalptr`. It gives the performance win with minimal complexity and no new dependency.
