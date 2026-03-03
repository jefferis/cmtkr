## Resubmission (0.2.2)

This resubmission addresses the issues raised in the CRAN review email from
Benjamin Altmann for cmtkr v0.2.1, a new submission.

### 1) Quoting software/API names in title and description

I updated `DESCRIPTION` to use single quotes around additional software names as
requested (e.g. `'C++'`).

### 2) `\\dontrun{}` in examples

I removed `\\dontrun{}` for 2 `streamxform` examples.

## Checks

I re-ran Winbuilder devel checks:

https://win-builder.r-project.org/7CS1Y92Gstux/

The CRAN incoming spell-check NOTE reports the following words:

- `Rohlfing`
- `Maurer`
- `Morphometry`

These are expected false positives:

- `Rohlfing` and `Maurer` are author surnames from the cited methods paper.
- `Morphometry` is part of the library name, Computational Morphometry
  Toolkit (CMTK).

Thank you very much for valuable contributions to the CRAN ecosystem.

With best wishes, 

Greg Jefferis.
