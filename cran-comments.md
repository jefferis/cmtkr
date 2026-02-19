## Resubmission

This resubmission addresses the issues raised in the CRAN review email from
Konstanze Lauseker for cmtkr v0.2, a new submission.

### 1) References in `DESCRIPTION`

I added a reference in the `Description` field using the requested format:

Rohlfing T and Maurer CR (2003) <doi:10.1109/titb.2003.808506>.

as well as an inst/CITATION file.

### 2) Missing `value` documentation

I updated `streamxform` documentation to provide an explicit `value` section.

## Checks

I re-ran Winbuilder devel checks:

https://win-builder.r-project.org/VBnyz40zp0GZ/

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
