# CMTK Apps Wrapping Plan (`dof2mat`, `mat2dof`, `statistics`)

## Scope
Add native `cmtkr` wrappers for three `nat` CMTK-tooling functions:

1. `nat::cmtk.dof2mat`
2. `nat::cmtk.mat2dof`
3. `nat::cmtk.statistics`

Goal: eliminate external `system2()` tool dependency for these operations (at least for affine tools first), while preserving R-level behavior as closely as practical.

## Compatibility Targets

- Keep existing `streamxform` behavior unchanged.
- Preserve `nat`-style defaults where sensible:
  - transpose defaults (`TRUE` at R level)
  - returned object shapes
  - parsing conventions and column names
- Prefer strict, explicit R errors rather than silent partial output.

## High-Level Architecture

### New C++ entry points
- `cmtk_dof2mat_cpp(...)`
- `cmtk_mat2dof_cpp(...)`
- `cmtk_statistics_cpp(...)` (phase 2/3)

Expose via `Rcpp::export` and call from thin R wrappers.

### New R API in `cmtkr`
- `cmtk_dof2mat(...)`
- `cmtk_mat2dof(...)`
- `cmtk_statistics(...)` (staged)

Optional aliases for `nat` parity:
- `cmtk.dof2mat <- cmtk_dof2mat`
- `cmtk.mat2dof <- cmtk_mat2dof`
- `cmtk.statistics <- cmtk_statistics`

## Detailed Implementation: `dof2mat` and `mat2dof`

## 1) `dof2mat` (dof/list -> 4x4 matrix)

### Source behavior reference
- Upstream app: `core/apps/dof2mat.cxx`
- `nat` wrapper:
  - accepts path or numeric params
  - optional transpose
  - returns 4x4 numeric matrix

### Proposed `cmtkr` interface
```r
cmtk_dof2mat <- function(reg, transpose = TRUE, matrix3x3 = FALSE)
```

### Input handling
- `reg` can be:
  - character scalar path to CMTK xform/list
  - numeric vector/matrix representing CMTK affine params:
    - 15-length vector OR 5x3 matrix

### C++ strategy
- If input is path:
  - `XformIO::Read(path)`
  - dynamic cast to `AffineXform`
  - error if non-affine
- If input is params:
  - construct `AffineXform` directly from parameter vector
  - avoid temp files entirely
- Emit either:
  - 4x4 (`matrix3x3 = FALSE`)
  - 3x3 (`matrix3x3 = TRUE`)
- Apply transpose toggle exactly like app.

### Return
- Numeric matrix (`3x3` or `4x4`)
- Row/col names optional; omit initially for parity with existing wrappers.

### Validation/tests
- Path-based output equals current `streamxform` affine component for simple known transform.
- Param-based roundtrip with `mat2dof` within numeric tolerance.
- Errors:
  - non-affine xform
  - malformed param lengths

## 2) `mat2dof` (4x4 matrix -> params and/or list output)

### Source behavior reference
- Upstream app: `core/apps/mat2dof.cxx`
- `nat` wrapper:
  - matrix in, optional center, optional output list path
  - transpose default TRUE
  - return either 5x3 params matrix or logical for file write

### Proposed `cmtkr` interface
```r
cmtk_mat2dof <- function(
  m,
  f = NULL,
  centre = NULL,
  transpose = TRUE,
  matrix3x3 = FALSE,
  pixel_size = NULL,
  offset = NULL,
  xlate = NULL,
  inverse = FALSE,
  append = FALSE
)
```

### Phase 1 (core parity with `nat`)
- Required:
  - `m` as `4x4` numeric matrix
  - `centre` optional length-3 numeric
  - `transpose`
  - `f` optional list output path
- Return:
  - if `f is NULL`: 5x3 numeric matrix with rownames
    - `xlate`, `rotate`, `scale`, `shear`, `center`
  - if `f` set: logical success

### C++ strategy
1. Copy matrix into CMTK `Types::Coordinate[4][4]`.
2. Optional transpose in-place.
3. Construct `AffineXform(matrix)`; propagate singular-matrix error.
4. If `centre` present: `xform->ChangeCenter(...)`.
5. If `inverse` present:
   - mimic app order (invert after modifiers).
6. Output mode:
   - no file: `GetParamVector(v)`, reshape 15 -> 5x3.
   - list output (`f`): create `StudyList` with default reference/floating labels and write with `ClassStreamStudyList::Write`.
   - (optional later) direct single xform file output.

### Phase 2 (advanced options from app)
- `matrix3x3`
- `pixel_size`
- `offset`
- `xlate`
- `append`
- optional single-file output mode

### Validation/tests
- `mat -> dof -> mat` close-to-identity on representative transforms.
- `centre` changes decomposition as expected.
- `transpose=TRUE/FALSE` parity checks.
- list output creates expected archive structure.

## 3) `statistics` (image volume stats)

### Source behavior reference
- Upstream app: `core/apps/statistics.cxx`
- `nat` wrapper currently shells out and parses text output.

### Why this is harder
- Requires oriented volume loading and mask handling:
  - `VolumeIO::ReadOriented`
  - label and grayscale branches
  - mask grid matching
  - histogram/entropy/percentiles
- Some IO/registration components were intentionally trimmed from vendored build.

### Dependency impact assessment
Current `src/Makevars` includes many `Base` and some `IO` units, but not full volume IO stack (notably `IO/cmtkVolumeIO.cxx` and associated image-format readers and codec plumbing).

Likely needed additions include:
- `cmtk/IO/cmtkVolumeIO.cxx`
- plus its transitive dependencies (NIfTI/NRRD/path/image backend readers used by `ReadOriented`)

Risk:
- Large compile footprint increase
- platform portability regressions
- potential new system requirements

### Proposed staged approach
1. Stage A: affine wrappers (`dof2mat`/`mat2dof`) first.
2. Stage B: feasibility spike for in-package `statistics`:
   - compile just enough IO to read a narrow set (e.g. NRRD only)
   - expose `cmtk_statistics(..., backend = c("native","system"))`
3. Stage C: broaden format support and retire system fallback only when parity confidence is high.

### Possible fallback design
- Provide native implementation when build has required IO features.
- Otherwise explicit fallback to command-line wrapper (or clear error if binary unavailable).

## File-Level Work Plan

## New files (planned)
- `src/cmtk_affine_tools.cpp` (or split into `dof2mat.cpp`, `mat2dof.cpp`)
- `R/cmtk-affine-tools.R`
- `tests/testthat/test-cmtk-affine-tools.R`

## Files to update
- `NAMESPACE`
- `DESCRIPTION` (if any new deps)
- `src/Makevars`, `src/Makevars.win` (if adding IO for `statistics`)
- generated:
  - `R/RcppExports.R`
  - `src/RcppExports.cpp`

## Milestones

1. Implement + test `cmtk_dof2mat`.
2. Implement + test `cmtk_mat2dof` phase 1 parity.
3. Add nat-compatible aliases and docs.
4. Benchmark and roundtrip tests.
5. `statistics` feasibility spike with exact dependency list and build impact estimate.

## Open Decisions

1. Naming: snake_case only vs also dot aliases for `nat` compatibility.
2. How strict to be about output parity (column names/formatting).
3. Whether `cmtk_statistics` should be gated behind a compile-time capability flag.

## Recommended Next Coding Step

Implement milestone 1+2 first (`dof2mat`, `mat2dof` phase 1) in one PR; keep `statistics` as a separate follow-up PR after dependency spike.
